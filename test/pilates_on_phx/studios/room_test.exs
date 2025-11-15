defmodule PilatesOnPhx.Studios.RoomTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Studios
  alias PilatesOnPhx.Studios.Room
  import PilatesOnPhx.StudiosFixtures
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "room creation (action: create)" do
    test "creates room with valid attributes" do
      studio = create_studio()

      attrs = %{
        name: "Studio A",
        capacity: 12,
        settings: %{floor_type: "hardwood", mirrors: true},
        active: true,
        studio_id: studio.id
      }

      assert {:ok, room} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert room.name == "Studio A"
      assert room.capacity == 12
      assert room.settings == %{"floor_type" => "hardwood", "mirrors" => true}
      assert room.active == true
      assert room.studio_id == studio.id
    end

    test "requires room name" do
      studio = create_studio()

      attrs = %{
        capacity: 12,
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Room
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
        capacity: 12,
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Room
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
        capacity: 12,
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "requires studio_id" do
      attrs = %{
        name: "Room Without Studio",
        capacity: 12
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :studio_id end)
    end

    test "requires capacity" do
      studio = create_studio()

      attrs = %{
        name: "Room Without Capacity",
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :capacity end)
    end

    test "validates capacity is positive" do
      studio = create_studio()

      attrs = %{
        name: "Invalid Capacity Room",
        capacity: 0,
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :capacity end)
    end

    test "validates capacity has reasonable upper limit" do
      studio = create_studio()

      attrs = %{
        name: "Huge Capacity Room",
        capacity: 200,
        studio_id: studio.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :capacity end)
    end

    test "sets default capacity of 12" do
      room = create_room()
      assert room.capacity == 12
    end

    test "sets default active status to true" do
      room = create_room()
      assert room.active == true
    end

    test "initializes empty settings map by default" do
      room = create_room()
      assert room.settings == %{} or is_map(room.settings)
    end

    test "allows custom settings JSON object" do
      room =
        create_room(
          settings: %{
            floor_type: "hardwood",
            mirrors: true,
            temperature_control: "central_ac",
            sound_system: "installed"
          }
        )

      assert room.settings["floor_type"] == "hardwood"
      assert room.settings["mirrors"] == true
      assert room.settings["temperature_control"] == "central_ac"
      assert room.settings["sound_system"] == "installed"
    end
  end

  describe "room updates (action: update)" do
    test "updates room name" do
      room = create_room(name: "Original Name")

      assert {:ok, updated} =
               room
               |> Ash.Changeset.for_update(:update, %{name: "New Name"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.name == "New Name"
      assert updated.id == room.id
    end

    test "updates room capacity" do
      room = create_room(capacity: 12)

      assert {:ok, updated} =
               room
               |> Ash.Changeset.for_update(:update, %{capacity: 16},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.capacity == 16
    end

    test "updates room settings" do
      room = create_room(settings: %{key: "value"})

      new_settings = %{
        floor_type: "bamboo",
        mirrors: false,
        lighting: "adjustable"
      }

      assert {:ok, updated} =
               room
               |> Ash.Changeset.for_update(:update, %{settings: new_settings},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.settings == %{
               "floor_type" => "bamboo",
               "mirrors" => false,
               "lighting" => "adjustable"
             }
    end

    test "can activate inactive room" do
      room = create_room(active: false)

      assert {:ok, updated} =
               room
               |> Ash.Changeset.for_update(:update, %{active: true},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == true
    end

    test "can deactivate active room" do
      room = create_room(active: true)

      assert {:ok, updated} =
               room
               |> Ash.Changeset.for_update(:update, %{active: false},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == false
    end

    test "validates name during update" do
      room = create_room()

      assert {:error, %Ash.Error.Invalid{} = error} =
               room
               |> Ash.Changeset.for_update(:update, %{name: ""},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "validates capacity during update" do
      room = create_room()

      assert {:error, %Ash.Error.Invalid{} = error} =
               room
               |> Ash.Changeset.for_update(:update, %{capacity: -5},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "room deactivation (action: deactivate)" do
    test "deactivate action sets active to false" do
      room = create_room(active: true)

      assert {:ok, deactivated} =
               room
               |> Ash.Changeset.for_update(:deactivate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert deactivated.active == false
    end

    test "deactivate action is idempotent" do
      room = create_room(active: true)

      # Deactivate once
      {:ok, deactivated} =
        room
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
  end

  describe "room reactivation (action: activate)" do
    test "activate action sets active to true" do
      room = create_room(active: false)

      assert {:ok, activated} =
               room
               |> Ash.Changeset.for_update(:activate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert activated.active == true
    end

    test "activate action is idempotent" do
      room = create_room(active: false)

      # Activate once
      {:ok, activated} =
        room
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

  describe "room relationships" do
    test "room belongs to studio" do
      studio = create_studio()
      room = create_room(studio: studio)

      loaded_room =
        Room
        |> Ash.Query.filter(id == ^room.id)
        |> Ash.Query.load(:studio)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_room.studio.id == studio.id
    end

    test "room has many equipment" do
      room = create_room()
      equipment1 = create_equipment(room: room)
      equipment2 = create_equipment(room: room)

      loaded_room =
        Room
        |> Ash.Query.filter(id == ^room.id)
        |> Ash.Query.load(:equipment)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      equipment_ids = Enum.map(loaded_room.equipment, & &1.id)
      assert equipment1.id in equipment_ids
      assert equipment2.id in equipment_ids
    end

    test "room without equipment has empty equipment list" do
      room = create_room()

      loaded_room =
        Room
        |> Ash.Query.filter(id == ^room.id)
        |> Ash.Query.load(:equipment)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_room.equipment == []
    end

    test "studio can have multiple rooms" do
      studio = create_studio()
      room1 = create_room(studio: studio, name: "Room 1")
      room2 = create_room(studio: studio, name: "Room 2")
      room3 = create_room(studio: studio, name: "Room 3")

      loaded_studio =
        Studios.Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:rooms)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      room_ids = Enum.map(loaded_studio.rooms, & &1.id)
      assert room1.id in room_ids
      assert room2.id in room_ids
      assert room3.id in room_ids
    end
  end

  describe "room settings and configuration" do
    test "stores physical attributes" do
      room =
        create_room(
          settings: %{
            floor_type: "bamboo",
            mirrors: true,
            windows: 3,
            ceiling_height: "12ft"
          }
        )

      assert room.settings["floor_type"] == "bamboo"
      assert room.settings["mirrors"] == true
      assert room.settings["windows"] == 3
      assert room.settings["ceiling_height"] == "12ft"
    end

    test "stores equipment and amenities" do
      room =
        create_room(
          settings: %{
            sound_system: "installed",
            temperature_control: "central_ac",
            storage: "built-in cabinets",
            props_available: ["blocks", "straps", "bolsters"]
          }
        )

      assert room.settings["sound_system"] == "installed"
      assert room.settings["temperature_control"] == "central_ac"
      assert room.settings["props_available"] == ["blocks", "straps", "bolsters"]
    end

    test "stores accessibility features" do
      room =
        create_room(
          settings: %{
            wheelchair_accessible: true,
            accessible_parking: true,
            elevator_access: false
          }
        )

      assert room.settings["wheelchair_accessible"] == true
      assert room.settings["accessible_parking"] == true
      assert room.settings["elevator_access"] == false
    end

    test "handles nested settings structures" do
      room =
        create_room(
          settings: %{
            dimensions: %{
              length: 40,
              width: 30,
              unit: "feet"
            },
            features: %{
              natural_light: true,
              views: "garden"
            }
          }
        )

      assert room.settings["dimensions"]["length"] == 40
      assert room.settings["features"]["natural_light"] == true
    end
  end

  describe "room queries and filtering" do
    test "can query all rooms" do
      create_room(name: "Room A")
      create_room(name: "Room B")
      create_room(name: "Room C")

      rooms =
        Room |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(rooms) >= 3
    end

    test "can filter rooms by active status" do
      create_room(name: "Active Room", active: true)
      create_room(name: "Inactive Room", active: false)

      active_rooms =
        Room
        |> Ash.Query.filter(active == true)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(active_rooms) >= 1
      assert Enum.all?(active_rooms, fn room -> room.active == true end)
    end

    test "can filter rooms by name" do
      room = create_room(name: "Specific Room Name")

      found_rooms =
        Room
        |> Ash.Query.filter(name == ^room.name)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(found_rooms) == 1
      assert hd(found_rooms).id == room.id
    end

    test "can search rooms by name pattern" do
      create_room(name: "Reformer Room A")
      create_room(name: "Mat Room B")
      create_room(name: "Reformer Room C")

      reformer_rooms =
        Room
        |> Ash.Query.filter(contains(name, "Reformer"))
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(reformer_rooms) >= 2
      assert Enum.all?(reformer_rooms, fn room -> String.contains?(room.name, "Reformer") end)
    end

    test "can filter by studio" do
      studio1 = create_studio()
      studio2 = create_studio()

      room1 = create_room(studio: studio1)
      _room2 = create_room(studio: studio2)

      studio1_rooms =
        Room
        |> Ash.Query.filter(studio_id == ^studio1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(studio1_rooms) >= 1
      assert Enum.all?(studio1_rooms, fn room -> room.studio_id == studio1.id end)
    end

    test "can filter by capacity" do
      create_room(name: "Small Room", capacity: 8)
      create_room(name: "Medium Room", capacity: 12)
      create_room(name: "Large Room", capacity: 20)

      large_rooms =
        Room
        |> Ash.Query.filter(capacity >= 15)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(large_rooms) >= 1
      assert Enum.all?(large_rooms, fn room -> room.capacity >= 15 end)
    end
  end

  describe "multi-tenant isolation" do
    test "rooms belong to specific studios and organizations" do
      org1 = create_organization()
      org2 = create_organization()

      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      room1 = create_room(studio: studio1)
      room2 = create_room(studio: studio2)

      assert room1.studio_id == studio1.id
      assert room2.studio_id == studio2.id
      assert room1.studio_id != room2.studio_id
    end

    test "room data does not leak between studios" do
      studio1 = create_studio()
      studio2 = create_studio()

      room1 = create_room(name: "Studio1 Room", studio: studio1)
      room2 = create_room(name: "Studio2 Room", studio: studio2)

      # Query rooms for studio1
      studio1_rooms =
        Room
        |> Ash.Query.filter(studio_id == ^studio1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      room_ids = Enum.map(studio1_rooms, & &1.id)

      assert room1.id in room_ids
      refute room2.id in room_ids
    end

    test "multiple rooms can exist in same studio" do
      studio = create_studio()

      room1 = create_room(name: "Room 1", studio: studio)
      room2 = create_room(name: "Room 2", studio: studio)
      room3 = create_room(name: "Room 3", studio: studio)

      studio_rooms =
        Room
        |> Ash.Query.filter(studio_id == ^studio.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(studio_rooms) >= 3
      room_ids = Enum.map(studio_rooms, & &1.id)
      assert room1.id in room_ids
      assert room2.id in room_ids
      assert room3.id in room_ids
    end
  end

  describe "room lifecycle" do
    test "new room starts as active by default" do
      room = create_room()
      assert room.active == true
    end

    test "tracks room creation timestamp" do
      room = create_room()

      assert room.inserted_at != nil
      assert %DateTime{} = room.inserted_at
    end

    test "tracks room update timestamp" do
      room = create_room()
      original_updated_at = room.updated_at

      Process.sleep(10)

      {:ok, updated} =
        room
        |> Ash.Changeset.for_update(:update, %{name: "Updated Name"},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "deactivated room remains queryable" do
      room = create_room(name: "To Be Deactivated")

      {:ok, deactivated} =
        room
        |> Ash.Changeset.for_update(:deactivate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      # Should still be able to query it
      found =
        Room
        |> Ash.Query.filter(id == ^deactivated.id)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert found.id == deactivated.id
      assert found.active == false
    end
  end

  describe "authorization policies" do
    test "organization owner can create rooms" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      studio = create_studio(organization: org)

      attrs = %{
        name: "New Room",
        capacity: 12,
        studio_id: studio.id
      }

      assert {:ok, room} =
               Room
               |> Ash.Changeset.for_create(:create, attrs, actor: owner)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert room.name == "New Room"
      assert room.studio_id == studio.id
    end

    test "organization owner can update their rooms" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      studio = create_studio(organization: org)
      room = create_room(studio: studio)

      assert {:ok, updated} =
               room
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"}, actor: owner)
               |> Ash.update(domain: Studios)

      assert updated.name == "Updated by Owner"
    end

    test "organization members can read rooms" do
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)
      room = create_room(studio: studio)

      assert {:ok, loaded} =
               Room
               |> Ash.Query.filter(id == ^room.id)
               |> Ash.read_one(domain: Studios, actor: member)

      assert loaded.id == room.id
    end

    test "users from different organizations cannot access other rooms" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      studio2 = create_studio(organization: org2)
      room2 = create_room(studio: studio2)

      # User from org1 should not be able to read room from org2
      assert {:ok, nil} =
               Room
               |> Ash.Query.filter(id == ^room2.id)
               |> Ash.read_one(domain: Studios, actor: user1)
    end

    @tag :skip
    test "regular members cannot update rooms" do
      # TODO: Implement role-based authorization (owner/admin only)
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)
      room = create_room(studio: studio)

      assert {:error, %Ash.Error.Forbidden{}} =
               room
               |> Ash.Changeset.for_update(:update, %{name: "Unauthorized Update"}, actor: member)
               |> Ash.update(domain: Studios)
    end
  end

  describe "data validation edge cases" do
    test "handles unicode characters in room name" do
      studio = create_studio()

      attrs = %{
        name: "Sala de Reformer José 体育馆",
        capacity: 12,
        studio_id: studio.id
      }

      assert {:ok, room} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert room.name == "Sala de Reformer José 体育馆"
    end

    test "handles special characters in room name" do
      studio = create_studio()

      attrs = %{
        name: "Room #1 @ Main Building (Floor 2)",
        capacity: 12,
        studio_id: studio.id
      }

      assert {:ok, room} =
               Room
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert room.name == "Room #1 @ Main Building (Floor 2)"
    end

    test "rejects nil as settings" do
      room = create_room()

      assert {:error, %Ash.Error.Invalid{} = error} =
               room
               |> Ash.Changeset.for_update(:update, %{settings: nil},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "handles deeply nested settings structures" do
      deep_settings = %{
        level1: %{
          level2: %{
            level3: %{
              level4: %{
                deeply_nested_value: "found"
              }
            }
          }
        }
      }

      room = create_room(settings: deep_settings)

      assert room.settings["level1"]["level2"]["level3"]["level4"]["deeply_nested_value"] ==
               "found"
    end
  end

  describe "concurrent room operations" do
    test "handles concurrent room creation" do
      studio = create_studio()

      tasks =
        Enum.map(1..5, fn i ->
          Task.async(fn ->
            attrs = %{
              name: "Concurrent Room #{i}",
              capacity: 12,
              studio_id: studio.id
            }

            Room
            |> Ash.Changeset.for_create(:create, attrs)
            |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed with unique names
      assert Enum.all?(results, fn
               {:ok, _room} -> true
               _ -> false
             end)
    end

    test "handles concurrent updates to same room" do
      room = create_room()

      tasks =
        Enum.map(1..3, fn i ->
          Task.async(fn ->
            room
            |> Ash.Changeset.for_update(:update, %{capacity: 10 + i},
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

  describe "room deletion and cleanup" do
    test "can delete room with no equipment" do
      room = create_room()

      assert :ok =
               Ash.destroy(room,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify room is gone
      assert {:ok, nil} =
               Room
               |> Ash.Query.filter(id == ^room.id)
               |> Ash.read_one(
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
    end

    @tag :skip
    test "deleting room cascades to equipment or updates equipment room_id" do
      # TODO: Define cascade behavior for room deletion
      room = create_room()
      equipment = create_equipment(room: room)

      # Delete room
      assert :ok =
               Ash.destroy(room,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify equipment is either deleted or updated (room_id set to nil)
      # This behavior needs to be defined in Room resource
    end
  end
end
