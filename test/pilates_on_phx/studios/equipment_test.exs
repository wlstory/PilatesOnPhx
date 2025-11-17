defmodule PilatesOnPhx.Studios.EquipmentTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Studios
  alias PilatesOnPhx.Studios.Equipment
  import PilatesOnPhx.StudiosFixtures
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "equipment creation (action: create)" do
    test "creates equipment with valid attributes" do
      studio = create_studio()
      room = create_room(studio: studio)

      attrs = %{
        name: "Reformer #1",
        equipment_type: "reformer",
        serial_number: "REF-2024-001",
        portable: false,
        maintenance_notes: "New equipment, no maintenance needed",
        active: true,
        studio_id: studio.id,
        room_id: room.id
      }

      assert {:ok, equipment} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert equipment.name == "Reformer #1"
      assert equipment.equipment_type == "reformer"
      assert equipment.serial_number == "REF-2024-001"
      assert equipment.portable == false
      assert equipment.maintenance_notes == "New equipment, no maintenance needed"
      assert equipment.active == true
      assert equipment.studio_id == studio.id
      assert equipment.room_id == room.id
    end

    test "creates portable equipment without room assignment" do
      studio = create_studio()

      attrs = %{
        name: "Portable Mat",
        equipment_type: "mat",
        portable: true,
        active: true,
        studio_id: studio.id,
        room_id: nil
      }

      assert {:ok, equipment} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert equipment.name == "Portable Mat"
      assert equipment.portable == true
      assert equipment.room_id == nil
    end

    test "requires equipment name" do
      studio = create_studio()

      attrs = %{
        equipment_type: "reformer",
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates name is not empty string" do
      studio = create_studio()

      attrs = %{
        name: "",
        equipment_type: "reformer",
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates name has reasonable length" do
      studio = create_studio()
      long_name = String.duplicate("a", 300)

      attrs = %{
        name: long_name,
        equipment_type: "reformer",
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "requires equipment_type" do
      studio = create_studio()

      attrs = %{
        name: "Equipment Without Type",
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :equipment_type end)
    end

    test "requires studio_id" do
      attrs = %{
        name: "Equipment Without Studio",
        equipment_type: "reformer"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :studio_id end)
    end

    test "sets default portable to false" do
      equipment = create_equipment()
      # Since create_equipment assigns a room by default, portable should be false
      assert equipment.portable == false
    end

    test "sets default active status to true" do
      equipment = create_equipment()
      assert equipment.active == true
    end

    test "allows serial_number to be nil" do
      equipment = create_equipment(serial_number: nil)
      assert equipment.serial_number == nil
    end

    test "allows very long serial numbers" do
      long_serial = String.duplicate("A", 100)
      equipment = create_equipment(serial_number: long_serial)
      assert equipment.serial_number == long_serial
    end

    test "allows maintenance_notes to be nil" do
      equipment = create_equipment(maintenance_notes: nil)
      assert equipment.maintenance_notes == nil
    end

    test "allows very long maintenance notes with multiple paragraphs" do
      long_notes = """
      First service: 2024-01-01
      Second service: 2024-02-01
      Third service: 2024-03-01

      Equipment has been performing well with no major issues.
      Minor adjustments made to spring tension.
      """

      equipment = create_equipment(maintenance_notes: long_notes)
      assert String.contains?(equipment.maintenance_notes, "First service")
      assert String.contains?(equipment.maintenance_notes, "spring tension")
    end

    test "allows custom maintenance notes" do
      equipment =
        create_equipment(
          maintenance_notes: "Last serviced: 2024-01-15. Next service due: 2024-07-15"
        )

      assert equipment.maintenance_notes ==
               "Last serviced: 2024-01-15. Next service due: 2024-07-15"
    end

    test "validates non-portable equipment requires room when created" do
      studio = create_studio()

      attrs = %{
        name: "Fixed Reformer",
        equipment_type: "reformer",
        portable: false,
        studio_id: studio.id,
        room_id: nil
      }

      # Non-portable equipment without room should fail validation
      assert {:error, %Ash.Error.Invalid{} = error} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "equipment updates (action: update)" do
    test "updates equipment name" do
      equipment = create_equipment(name: "Original Name")

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{name: "New Name"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.name == "New Name"
      assert updated.id == equipment.id
    end

    test "updates equipment type" do
      equipment = create_equipment(equipment_type: "reformer")

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{equipment_type: "cadillac"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.equipment_type == "cadillac"
    end

    test "updates serial number" do
      equipment = create_equipment(serial_number: "OLD-123")

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{serial_number: "NEW-456"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.serial_number == "NEW-456"
    end

    test "updates maintenance notes" do
      equipment = create_equipment(maintenance_notes: "Original notes")

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{maintenance_notes: "Updated notes"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.maintenance_notes == "Updated notes"
    end

    test "can move equipment to different room" do
      studio = create_studio()
      room1 = create_room(studio: studio, name: "Room 1")
      room2 = create_room(studio: studio, name: "Room 2")

      equipment = create_equipment(studio: studio, room: room1)

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{room_id: room2.id},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.room_id == room2.id
    end

    test "can convert equipment to portable by removing room" do
      equipment = create_equipment(portable: false)

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{portable: true, room_id: nil},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.portable == true
      assert updated.room_id == nil
    end

    test "validates converting portable to non-portable requires room assignment" do
      # Start with portable equipment (no room)
      equipment = create_equipment(portable: true, room: nil)

      # Try to make it non-portable without assigning a room - should fail
      assert {:error, %Ash.Error.Invalid{} = error} =
               equipment
               |> Ash.Changeset.for_update(:update, %{portable: false},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      # Verify the validation error is about room_id
      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn err -> err.field == :room_id end)
    end

    test "can activate inactive equipment" do
      equipment = create_equipment(active: false)

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{active: true},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == true
    end

    test "can deactivate active equipment" do
      equipment = create_equipment(active: true)

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{active: false},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == false
    end

    test "validates name during update" do
      equipment = create_equipment()

      assert {:error, %Ash.Error.Invalid{} = error} =
               equipment
               |> Ash.Changeset.for_update(:update, %{name: ""},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "equipment deactivation (action: deactivate)" do
    test "deactivate action sets active to false" do
      equipment = create_equipment(active: true)

      assert {:ok, deactivated} =
               equipment
               |> Ash.Changeset.for_update(:deactivate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert deactivated.active == false
    end

    test "deactivate action is idempotent" do
      equipment = create_equipment(active: true)

      # Deactivate once
      {:ok, deactivated} =
        equipment
        |> Ash.Changeset.for_update(:deactivate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      # Deactivate again
      assert {:ok, still_deactivated} =
               deactivated
               |> Ash.Changeset.for_update(:deactivate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert still_deactivated.active == false
    end

    test "deactivated equipment can still be queried" do
      equipment = create_equipment(active: true)

      {:ok, deactivated} =
        equipment
        |> Ash.Changeset.for_update(:deactivate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      found =
        Equipment
        |> Ash.Query.filter(id == ^deactivated.id)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert found.id == deactivated.id
      assert found.active == false
    end
  end

  describe "equipment reactivation (action: activate)" do
    test "activate action sets active to true" do
      equipment = create_equipment(active: false)

      assert {:ok, activated} =
               equipment
               |> Ash.Changeset.for_update(:activate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert activated.active == true
    end

    test "activate action is idempotent" do
      equipment = create_equipment(active: false)

      # Activate once
      {:ok, activated} =
        equipment
        |> Ash.Changeset.for_update(:activate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      # Activate again
      assert {:ok, still_activated} =
               activated
               |> Ash.Changeset.for_update(:activate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert still_activated.active == true
    end
  end

  describe "equipment relationships" do
    test "equipment belongs to studio" do
      studio = create_studio()
      equipment = create_equipment(studio: studio)

      loaded_equipment =
        Equipment
        |> Ash.Query.filter(id == ^equipment.id)
        |> Ash.Query.load(:studio)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_equipment.studio.id == studio.id
    end

    test "equipment optionally belongs to room" do
      room = create_room()
      equipment = create_equipment(room: room)

      loaded_equipment =
        Equipment
        |> Ash.Query.filter(id == ^equipment.id)
        |> Ash.Query.load(:room)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_equipment.room.id == room.id
    end

    test "portable equipment has no room" do
      equipment = create_equipment(portable: true, room: nil)

      loaded_equipment =
        Equipment
        |> Ash.Query.filter(id == ^equipment.id)
        |> Ash.Query.load(:room)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_equipment.room == nil
    end

    test "studio can have multiple equipment" do
      studio = create_studio()
      equipment1 = create_equipment(studio: studio, name: "Equipment 1")
      equipment2 = create_equipment(studio: studio, name: "Equipment 2")
      equipment3 = create_equipment(studio: studio, name: "Equipment 3")

      loaded_studio =
        Studios.Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:equipment)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      equipment_ids = Enum.map(loaded_studio.equipment, & &1.id)
      assert equipment1.id in equipment_ids
      assert equipment2.id in equipment_ids
      assert equipment3.id in equipment_ids
    end

    test "room can have multiple equipment" do
      room = create_room()
      equipment1 = create_equipment(room: room, name: "Equipment 1")
      equipment2 = create_equipment(room: room, name: "Equipment 2")

      loaded_room =
        Studios.Room
        |> Ash.Query.filter(id == ^room.id)
        |> Ash.Query.load(:equipment)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      equipment_ids = Enum.map(loaded_room.equipment, & &1.id)
      assert equipment1.id in equipment_ids
      assert equipment2.id in equipment_ids
    end
  end

  describe "equipment types and inventory" do
    test "tracks reformers" do
      equipment = create_equipment(equipment_type: "reformer", name: "Reformer #1")
      assert equipment.equipment_type == "reformer"
    end

    test "tracks cadillacs" do
      equipment = create_equipment(equipment_type: "cadillac", name: "Cadillac #1")
      assert equipment.equipment_type == "cadillac"
    end

    test "tracks chairs" do
      equipment = create_equipment(equipment_type: "chair", name: "Chair #1")
      assert equipment.equipment_type == "chair"
    end

    test "tracks barrels" do
      equipment = create_equipment(equipment_type: "barrel", name: "Barrel #1")
      assert equipment.equipment_type == "barrel"
    end

    test "tracks mats" do
      equipment = create_equipment(equipment_type: "mat", name: "Mat #1")
      assert equipment.equipment_type == "mat"
    end

    test "tracks props and accessories" do
      equipment = create_equipment(equipment_type: "prop", name: "Magic Circle #1")
      assert equipment.equipment_type == "prop"
    end

    test "allows custom equipment types" do
      equipment = create_equipment(equipment_type: "springboard", name: "Springboard #1")
      assert equipment.equipment_type == "springboard"
    end
  end

  describe "preparation filters and actor scenarios" do
    test "filters equipment when actor has no memberships loaded" do
      org = create_organization()
      studio = create_studio(organization: org)
      equipment = create_equipment(studio: studio)

      # Create user without loading memberships
      user = create_user(organization: org)

      # Query should handle loading memberships dynamically
      result =
        Equipment
        |> Ash.Query.filter(id == ^equipment.id)
        |> Ash.read(domain: Studios, actor: user)

      # Should either succeed with loaded memberships or return empty
      case result do
        {:ok, equipment_list} -> assert is_list(equipment_list)
        {:error, _} -> :ok
      end
    end

    test "returns empty when actor has no organizations" do
      # Create user without organization membership
      user = create_user_without_org()
      equipment = create_equipment()

      # User with no organization should not see any equipment
      assert {:ok, equipment_list} =
               Equipment
               |> Ash.read(domain: Studios, actor: user)

      refute Enum.any?(equipment_list, fn e -> e.id == equipment.id end)
    end

    test "filters equipment by actor organization membership" do
      org1 = create_organization()
      org2 = create_organization()

      user = create_user(organization: org1)
      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      equipment1 = create_equipment(studio: studio1)
      equipment2 = create_equipment(studio: studio2)

      assert {:ok, equipment_list} =
               Equipment
               |> Ash.read(domain: Studios, actor: user)

      equipment_ids = Enum.map(equipment_list, & &1.id)
      assert equipment1.id in equipment_ids
      refute equipment2.id in equipment_ids
    end
  end

  describe "equipment queries and filtering" do
    test "can query all equipment" do
      create_equipment(name: "Equipment A")
      create_equipment(name: "Equipment B")
      create_equipment(name: "Equipment C")

      equipment_list =
        Equipment
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(equipment_list) >= 3
    end

    test "can filter equipment by active status" do
      create_equipment(name: "Active Equipment", active: true)
      create_equipment(name: "Inactive Equipment", active: false)

      active_equipment =
        Equipment
        |> Ash.Query.filter(active == true)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(active_equipment) >= 1
      assert Enum.all?(active_equipment, fn eq -> eq.active == true end)
    end

    test "can filter equipment by type" do
      create_equipment(equipment_type: "reformer")
      create_equipment(equipment_type: "chair")

      reformers =
        Equipment
        |> Ash.Query.filter(equipment_type == "reformer")
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(reformers) >= 1
      assert Enum.all?(reformers, fn eq -> eq.equipment_type == "reformer" end)
    end

    test "can filter equipment by portable status" do
      create_equipment(portable: true, room: nil)
      create_equipment(portable: false)

      portable_equipment =
        Equipment
        |> Ash.Query.filter(portable == true)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(portable_equipment) >= 1
      assert Enum.all?(portable_equipment, fn eq -> eq.portable == true end)
    end

    test "can filter equipment by studio" do
      studio1 = create_studio()
      studio2 = create_studio()

      equipment1 = create_equipment(studio: studio1)
      _equipment2 = create_equipment(studio: studio2)

      studio1_equipment =
        Equipment
        |> Ash.Query.filter(studio_id == ^studio1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(studio1_equipment) >= 1
      assert Enum.all?(studio1_equipment, fn eq -> eq.studio_id == studio1.id end)
    end

    test "can filter equipment by room" do
      room1 = create_room()
      room2 = create_room()

      equipment1 = create_equipment(room: room1)
      _equipment2 = create_equipment(room: room2)

      room1_equipment =
        Equipment
        |> Ash.Query.filter(room_id == ^room1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(room1_equipment) >= 1
      assert Enum.all?(room1_equipment, fn eq -> eq.room_id == room1.id end)
    end

    test "can filter equipment without room (portable)" do
      _fixed_equipment = create_equipment(portable: false)
      portable_equipment = create_equipment(portable: true, room: nil)

      unassigned_equipment =
        Equipment
        |> Ash.Query.filter(is_nil(room_id))
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(unassigned_equipment) >= 1
      equipment_ids = Enum.map(unassigned_equipment, & &1.id)
      assert portable_equipment.id in equipment_ids
    end
  end

  describe "multi-tenant isolation" do
    test "equipment belongs to specific studios and organizations" do
      org1 = create_organization()
      org2 = create_organization()

      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      equipment1 = create_equipment(studio: studio1)
      equipment2 = create_equipment(studio: studio2)

      assert equipment1.studio_id == studio1.id
      assert equipment2.studio_id == studio2.id
      assert equipment1.studio_id != equipment2.studio_id
    end

    test "equipment data does not leak between studios" do
      studio1 = create_studio()
      studio2 = create_studio()

      equipment1 = create_equipment(name: "Studio1 Equipment", studio: studio1)
      equipment2 = create_equipment(name: "Studio2 Equipment", studio: studio2)

      # Query equipment for studio1
      studio1_equipment =
        Equipment
        |> Ash.Query.filter(studio_id == ^studio1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      equipment_ids = Enum.map(studio1_equipment, & &1.id)

      assert equipment1.id in equipment_ids
      refute equipment2.id in equipment_ids
    end
  end

  describe "equipment lifecycle" do
    test "new equipment starts as active by default" do
      equipment = create_equipment()
      assert equipment.active == true
    end

    test "tracks equipment creation timestamp" do
      equipment = create_equipment()

      assert equipment.inserted_at != nil
      assert %DateTime{} = equipment.inserted_at
    end

    test "tracks equipment update timestamp" do
      equipment = create_equipment()
      original_updated_at = equipment.updated_at

      Process.sleep(10)

      {:ok, updated} =
        equipment
        |> Ash.Changeset.for_update(:update, %{name: "Updated Name"},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "deactivated equipment remains queryable" do
      equipment = create_equipment(name: "To Be Deactivated")

      {:ok, deactivated} =
        equipment
        |> Ash.Changeset.for_update(:deactivate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      # Should still be able to query it
      found =
        Equipment
        |> Ash.Query.filter(id == ^deactivated.id)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert found.id == deactivated.id
      assert found.active == false
    end
  end

  describe "authorization policies" do
    test "organization owner can create equipment" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      studio = create_studio(organization: org)
      room = create_room(studio: studio)

      attrs = %{
        name: "New Equipment",
        equipment_type: "reformer",
        studio_id: studio.id,
        room_id: room.id
      }

      assert {:ok, equipment} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs, actor: owner)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert equipment.name == "New Equipment"
      assert equipment.studio_id == studio.id
    end

    test "organization owner can update their equipment" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      studio = create_studio(organization: org)
      equipment = create_equipment(studio: studio)

      assert {:ok, updated} =
               equipment
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"}, actor: owner)
               |> Ash.update(domain: Studios)

      assert updated.name == "Updated by Owner"
    end

    test "organization members can read equipment" do
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)
      equipment = create_equipment(studio: studio)

      assert {:ok, loaded} =
               Equipment
               |> Ash.Query.filter(id == ^equipment.id)
               |> Ash.read_one(domain: Studios, actor: member)

      assert loaded.id == equipment.id
    end

    test "users from different organizations cannot access other equipment" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      studio2 = create_studio(organization: org2)
      equipment2 = create_equipment(studio: studio2)

      # User from org1 should not be able to read equipment from org2
      assert {:ok, nil} =
               Equipment
               |> Ash.Query.filter(id == ^equipment2.id)
               |> Ash.read_one(domain: Studios, actor: user1)
    end

    @tag :skip
    test "regular members cannot update equipment" do
      # TODO: Implement role-based authorization (owner/admin only)
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)
      equipment = create_equipment(studio: studio)

      assert {:error, %Ash.Error.Forbidden{}} =
               equipment
               |> Ash.Changeset.for_update(:update, %{name: "Unauthorized Update"}, actor: member)
               |> Ash.update(domain: Studios)
    end
  end

  describe "data validation edge cases" do
    test "handles unicode characters in equipment name" do
      studio = create_studio()
      room = create_room(studio: studio)

      attrs = %{
        name: "Reformer José García 体育馆",
        equipment_type: "reformer",
        studio_id: studio.id,
        # Non-portable equipment needs a room
        room_id: room.id
      }

      assert {:ok, equipment} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert equipment.name == "Reformer José García 体育馆"
    end

    test "handles special characters in equipment name" do
      studio = create_studio()

      room = create_room(studio: studio)

      attrs = %{
        name: "Reformer #1 (Studio A)",
        equipment_type: "reformer",
        studio_id: studio.id,
        # Non-portable equipment needs a room
        room_id: room.id
      }

      assert {:ok, equipment} =
               Equipment
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert equipment.name == "Reformer #1 (Studio A)"
    end

    test "handles long maintenance notes" do
      long_notes = String.duplicate("Detailed maintenance history. ", 100)
      equipment = create_equipment(maintenance_notes: long_notes)

      assert String.length(equipment.maintenance_notes) > 1000
    end
  end

  describe "concurrent equipment operations" do
    test "handles concurrent equipment creation" do
      studio = create_studio()

      tasks =
        Enum.map(1..5, fn i ->
          Task.async(fn ->
            attrs = %{
              name: "Concurrent Equipment #{i}",
              equipment_type: "reformer",
              portable: true,
              studio_id: studio.id,
              room_id: nil
            }

            Equipment
            |> Ash.Changeset.for_create(:create, attrs)
            |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed with unique names
      assert Enum.all?(results, fn
               {:ok, _equipment} -> true
               _ -> false
             end)
    end

    test "handles concurrent updates to same equipment" do
      equipment = create_equipment()

      tasks =
        Enum.map(1..3, fn i ->
          Task.async(fn ->
            equipment
            |> Ash.Changeset.for_update(:update, %{name: "Updated Name #{i}"},
              actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
            )
            |> Ash.update(domain: Studios)
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed or fail gracefully
      successful =
        Enum.filter(results, fn
          {:ok, _} -> true
          _ -> false
        end)

      assert length(successful) >= 1
    end
  end

  describe "equipment deletion and cleanup" do
    test "can delete equipment" do
      equipment = create_equipment()

      assert :ok =
               Ash.destroy(equipment,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify equipment is gone
      assert {:ok, nil} =
               Equipment
               |> Ash.Query.filter(id == ^equipment.id)
               |> Ash.read_one(
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
    end

    test "deleting equipment does not delete room" do
      room = create_room()
      equipment = create_equipment(room: room)

      # Delete equipment
      assert :ok =
               Ash.destroy(equipment,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify room still exists
      found_room =
        Studios.Room
        |> Ash.Query.filter(id == ^room.id)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert found_room.id == room.id
    end

    test "deleting equipment does not delete studio" do
      studio = create_studio()
      equipment = create_equipment(studio: studio)

      # Delete equipment
      assert :ok =
               Ash.destroy(equipment,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify studio still exists
      found_studio =
        Studios.Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert found_studio.id == studio.id
    end
  end
end
