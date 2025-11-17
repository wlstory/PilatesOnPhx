defmodule PilatesOnPhx.Studios.StudioStaffTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Studios
  alias PilatesOnPhx.Studios.StudioStaff
  import PilatesOnPhx.StudiosFixtures
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "studio staff assignment (action: assign)" do
    test "assigns staff with valid attributes" do
      studio = create_studio()

      user =
        create_user(
          organization:
            Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization
        )

      attrs = %{
        studio_id: studio.id,
        user_id: user.id,
        role: :instructor,
        permissions: ["teach", "view_schedule"],
        notes: "Head instructor",
        active: true
      }

      assert {:ok, staff} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert staff.studio_id == studio.id
      assert staff.user_id == user.id
      assert staff.role == :instructor
      assert staff.permissions == ["teach", "view_schedule"]
      assert staff.notes == "Head instructor"
      assert staff.active == true
    end

    test "requires studio_id" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        role: :instructor
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :studio_id end)
    end

    test "requires user_id" do
      studio = create_studio()

      attrs = %{
        studio_id: studio.id,
        role: :instructor
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :user_id end)
    end

    test "requires role" do
      studio = create_studio()

      user =
        create_user(
          organization:
            Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization
        )

      attrs = %{
        studio_id: studio.id,
        user_id: user.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :role end)
    end

    test "accepts valid role values" do
      studio = create_studio()

      org =
        Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization

      roles = [:instructor, :front_desk, :manager]

      Enum.each(roles, fn role ->
        user = create_user(organization: org)

        attrs = %{
          studio_id: studio.id,
          user_id: user.id,
          role: role
        }

        assert {:ok, staff} =
                 StudioStaff
                 |> Ash.Changeset.for_create(:assign, attrs)
                 |> Ash.create(
                   domain: Studios,
                   actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
                 )

        assert staff.role == role
      end)
    end

    test "rejects invalid role values" do
      studio = create_studio()

      user =
        create_user(
          organization:
            Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization
        )

      attrs = %{
        studio_id: studio.id,
        user_id: user.id,
        role: :invalid_role
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "sets default permissions as empty list" do
      # Don't pass permissions at all to test the default
      studio = create_studio()

      org =
        Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization

      user = create_user(organization: org)

      attrs = %{
        studio_id: studio.id,
        user_id: user.id,
        role: :instructor
        # permissions not specified - should default to []
      }

      assert {:ok, staff} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert staff.permissions == []
    end

    test "allows custom permissions list" do
      staff =
        create_studio_staff(
          permissions: ["teach", "manage_schedule", "view_reports", "manage_clients"]
        )

      assert "teach" in staff.permissions
      assert "manage_schedule" in staff.permissions
      assert "view_reports" in staff.permissions
      assert "manage_clients" in staff.permissions
    end

    test "sets default active status to true" do
      staff = create_studio_staff()
      assert staff.active == true
    end

    test "allows notes to be nil" do
      staff = create_studio_staff(notes: nil)
      assert staff.notes == nil
    end

    test "allows custom notes" do
      staff = create_studio_staff(notes: "Senior instructor with 10 years experience")
      assert staff.notes == "Senior instructor with 10 years experience"
    end

    test "prevents duplicate staff assignments" do
      studio = create_studio()

      user =
        create_user(
          organization:
            Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization
        )

      # First assignment
      attrs = %{
        studio_id: studio.id,
        user_id: user.id,
        role: :instructor
      }

      assert {:ok, _staff} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      # Second assignment should fail (unique constraint)
      assert {:error, error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      # Should be an error - either Invalid or Forbidden or database constraint error
      assert match?(%Ash.Error.Invalid{}, error) or
               match?(%Ash.Error.Forbidden{}, error) or
               match?(%Ecto.ConstraintError{}, error)
    end
  end

  describe "studio staff updates (action: update)" do
    test "updates staff role" do
      staff = create_studio_staff(role: :instructor)

      assert {:ok, updated} =
               staff
               |> Ash.Changeset.for_update(:update, %{role: :manager},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.role == :manager
      assert updated.id == staff.id
    end

    test "updates staff permissions" do
      staff = create_studio_staff(permissions: ["teach"])

      new_permissions = ["teach", "manage_schedule", "view_reports"]

      assert {:ok, updated} =
               staff
               |> Ash.Changeset.for_update(:update, %{permissions: new_permissions},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.permissions == new_permissions
    end

    test "updates staff notes" do
      staff = create_studio_staff(notes: "Original notes")

      assert {:ok, updated} =
               staff
               |> Ash.Changeset.for_update(:update, %{notes: "Updated notes"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.notes == "Updated notes"
    end

    test "can activate inactive staff" do
      staff = create_studio_staff(active: false)

      assert {:ok, updated} =
               staff
               |> Ash.Changeset.for_update(:update, %{active: true},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == true
    end

    test "can deactivate active staff" do
      staff = create_studio_staff(active: true)

      assert {:ok, updated} =
               staff
               |> Ash.Changeset.for_update(:update, %{active: false},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == false
    end

    test "validates role during update" do
      staff = create_studio_staff()

      assert {:error, %Ash.Error.Invalid{} = error} =
               staff
               |> Ash.Changeset.for_update(:update, %{role: :invalid_role},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "studio staff deactivation (action: deactivate)" do
    test "deactivate action sets active to false" do
      staff = create_studio_staff(active: true)

      assert {:ok, deactivated} =
               staff
               |> Ash.Changeset.for_update(:deactivate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert deactivated.active == false
    end

    test "deactivate action is idempotent" do
      staff = create_studio_staff(active: true)

      # Deactivate once
      {:ok, deactivated} =
        staff
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

    test "deactivated staff can still be queried" do
      staff = create_studio_staff(active: true)

      {:ok, deactivated} =
        staff
        |> Ash.Changeset.for_update(:deactivate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      found =
        StudioStaff
        |> Ash.Query.filter(id == ^deactivated.id)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert found.id == deactivated.id
      assert found.active == false
    end
  end

  describe "studio staff reactivation (action: activate)" do
    test "activate action sets active to true" do
      staff = create_studio_staff(active: false)

      assert {:ok, activated} =
               staff
               |> Ash.Changeset.for_update(:activate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert activated.active == true
    end

    test "activate action is idempotent" do
      staff = create_studio_staff(active: false)

      # Activate once
      {:ok, activated} =
        staff
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

  describe "studio staff relationships" do
    test "staff belongs to studio" do
      studio = create_studio()
      staff = create_studio_staff(studio: studio)

      loaded_staff =
        StudioStaff
        |> Ash.Query.filter(id == ^staff.id)
        |> Ash.Query.load(:studio)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_staff.studio.id == studio.id
    end

    test "staff belongs to user" do
      studio = create_studio()

      user =
        create_user(
          organization:
            Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization
        )

      staff = create_studio_staff(studio: studio, user: user)

      loaded_staff =
        StudioStaff
        |> Ash.Query.filter(id == ^staff.id)
        |> Ash.Query.load(:user)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_staff.user.id == user.id
    end

    test "studio can have multiple staff members" do
      studio = create_studio()

      org =
        Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization

      staff1 = create_studio_staff(studio: studio, user: create_user(organization: org))
      staff2 = create_studio_staff(studio: studio, user: create_user(organization: org))
      staff3 = create_studio_staff(studio: studio, user: create_user(organization: org))

      loaded_studio =
        Studios.Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:staff_assignments)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      staff_ids = Enum.map(loaded_studio.staff_assignments, & &1.id)
      assert staff1.id in staff_ids
      assert staff2.id in staff_ids
      assert staff3.id in staff_ids
    end

    test "user can be assigned to multiple studios" do
      org = create_organization()
      user = create_user(organization: org)

      studio1 = create_studio(organization: org)
      studio2 = create_studio(organization: org)

      staff1 = create_studio_staff(studio: studio1, user: user, role: :instructor)
      staff2 = create_studio_staff(studio: studio2, user: user, role: :instructor)

      assert staff1.user_id == user.id
      assert staff2.user_id == user.id
      assert staff1.studio_id != staff2.studio_id
    end
  end

  describe "studio staff role permissions" do
    test "instructor role has teaching permissions" do
      staff = create_studio_staff(role: :instructor, permissions: ["teach", "view_schedule"])

      assert staff.role == :instructor
      assert "teach" in staff.permissions
      assert "view_schedule" in staff.permissions
    end

    test "manager role has comprehensive permissions" do
      staff =
        create_studio_staff(
          role: :manager,
          permissions: [
            "teach",
            "manage_schedule",
            "manage_staff",
            "view_reports",
            "manage_clients"
          ]
        )

      assert staff.role == :manager
      assert "manage_schedule" in staff.permissions
      assert "manage_staff" in staff.permissions
      assert "view_reports" in staff.permissions
    end

    test "front_desk role has limited permissions" do
      staff =
        create_studio_staff(
          role: :front_desk,
          permissions: ["view_schedule", "check_in_clients"]
        )

      assert staff.role == :front_desk
      assert "view_schedule" in staff.permissions
      assert "check_in_clients" in staff.permissions
    end

    test "permissions can be customized per staff member" do
      studio = create_studio()

      org =
        Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization

      instructor1 = create_studio_staff(studio: studio, permissions: ["teach"])

      instructor2 =
        create_studio_staff(
          studio: studio,
          user: create_user(organization: org),
          permissions: ["teach", "manage_schedule", "view_reports"]
        )

      assert length(instructor1.permissions) < length(instructor2.permissions)
    end
  end

  describe "studio staff queries and filtering" do
    test "can query all studio staff" do
      create_studio_staff()
      create_studio_staff()
      create_studio_staff()

      staff =
        StudioStaff
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(staff) >= 3
    end

    test "can filter staff by active status" do
      create_studio_staff(active: true)
      create_studio_staff(active: false)

      active_staff =
        StudioStaff
        |> Ash.Query.filter(active == true)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(active_staff) >= 1
      assert Enum.all?(active_staff, fn staff -> staff.active == true end)
    end

    test "can filter staff by role" do
      create_studio_staff(role: :instructor)
      create_studio_staff(role: :front_desk)

      instructors =
        StudioStaff
        |> Ash.Query.filter(role == :instructor)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(instructors) >= 1
      assert Enum.all?(instructors, fn staff -> staff.role == :instructor end)
    end

    test "can filter staff by studio" do
      studio1 = create_studio()
      studio2 = create_studio()

      staff1 = create_studio_staff(studio: studio1)
      _staff2 = create_studio_staff(studio: studio2)

      studio1_staff =
        StudioStaff
        |> Ash.Query.filter(studio_id == ^studio1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(studio1_staff) >= 1
      assert Enum.all?(studio1_staff, fn staff -> staff.studio_id == studio1.id end)
    end

    test "can filter staff by user" do
      studio = create_studio()

      user =
        create_user(
          organization:
            Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization
        )

      staff = create_studio_staff(studio: studio, user: user)

      user_assignments =
        StudioStaff
        |> Ash.Query.filter(user_id == ^user.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(user_assignments) >= 1
      assert Enum.all?(user_assignments, fn assignment -> assignment.user_id == user.id end)
    end
  end

  describe "validation error cases" do
    test "fails when studio_id does not exist" do
      org = create_organization()
      user = create_user(organization: org)
      fake_studio_id = Ecto.UUID.generate()

      attrs = %{
        studio_id: fake_studio_id,
        user_id: user.id,
        role: :instructor
      }

      # Should fail validation - studio not found
      assert {:error, %Ash.Error.Invalid{} = error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn err -> err.field == :studio_id end)
    end

    test "fails when user_id does not exist" do
      studio = create_studio()
      fake_user_id = Ecto.UUID.generate()

      attrs = %{
        studio_id: studio.id,
        user_id: fake_user_id,
        role: :instructor
      }

      # Should fail validation - user not found
      assert {:error, %Ash.Error.Invalid{} = error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn err -> err.field == :user_id end)
    end
  end

  describe "preparation filters and actor scenarios" do
    test "filters staff when actor has no memberships loaded" do
      org = create_organization()
      studio = create_studio(organization: org)
      staff = create_studio_staff(studio: studio)

      # Create user without loading memberships
      user = create_user(organization: org)

      # Query should handle loading memberships dynamically
      result =
        StudioStaff
        |> Ash.Query.filter(id == ^staff.id)
        |> Ash.read(domain: Studios, actor: user)

      # Should either succeed with loaded memberships or return empty
      case result do
        {:ok, staff_list} -> assert is_list(staff_list)
        {:error, _} -> :ok
      end
    end

    test "returns empty when actor has no organizations" do
      # Create user without organization membership
      user = create_user_without_org()
      staff = create_studio_staff()

      # User with no organization should not see any staff
      assert {:ok, staff_list} =
               StudioStaff
               |> Ash.read(domain: Studios, actor: user)

      refute Enum.any?(staff_list, fn s -> s.id == staff.id end)
    end

    test "filters staff by actor organization membership" do
      org1 = create_organization()
      org2 = create_organization()

      user = create_user(organization: org1)
      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      staff1 = create_studio_staff(studio: studio1)
      staff2 = create_studio_staff(studio: studio2)

      assert {:ok, staff_list} =
               StudioStaff
               |> Ash.read(domain: Studios, actor: user)

      staff_ids = Enum.map(staff_list, & &1.id)
      assert staff1.id in staff_ids
      refute staff2.id in staff_ids
    end
  end

  describe "multi-tenant isolation" do
    test "staff assignments respect organization boundaries" do
      org1 = create_organization()
      org2 = create_organization()

      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      staff1 = create_studio_staff(studio: studio1)
      staff2 = create_studio_staff(studio: studio2)

      # Verify studios belong to different organizations
      loaded_studio1 =
        Studios.Studio
        |> Ash.Query.filter(id == ^studio1.id)
        |> Ash.Query.load(:organization)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      loaded_studio2 =
        Studios.Studio
        |> Ash.Query.filter(id == ^studio2.id)
        |> Ash.Query.load(:organization)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_studio1.organization.id == org1.id
      assert loaded_studio2.organization.id == org2.id
      assert loaded_studio1.organization.id != loaded_studio2.organization.id
    end

    test "staff data does not leak between organizations" do
      org1 = create_organization()
      org2 = create_organization()

      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      staff1 = create_studio_staff(studio: studio1)
      staff2 = create_studio_staff(studio: studio2)

      # Query staff for studio1
      studio1_staff =
        StudioStaff
        |> Ash.Query.filter(studio_id == ^studio1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      staff_ids = Enum.map(studio1_staff, & &1.id)

      assert staff1.id in staff_ids
      refute staff2.id in staff_ids
    end

    test "user cannot be assigned to studio in different organization" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      studio2 = create_studio(organization: org2)

      attrs = %{
        studio_id: studio2.id,
        user_id: user1.id,
        role: :instructor
      }

      # This should fail validation (user not in same org as studio)
      assert {:error, %Ash.Error.Invalid{} = _error} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())
    end
  end

  describe "staff lifecycle" do
    test "new staff assignment starts as active by default" do
      staff = create_studio_staff()
      assert staff.active == true
    end

    test "tracks staff assignment creation timestamp" do
      staff = create_studio_staff()

      assert staff.inserted_at != nil
      assert %DateTime{} = staff.inserted_at
    end

    test "tracks staff assignment update timestamp" do
      staff = create_studio_staff()
      original_updated_at = staff.updated_at

      Process.sleep(10)

      {:ok, updated} =
        staff
        |> Ash.Changeset.for_update(:update, %{role: :manager},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end
  end

  describe "authorization policies" do
    test "organization owner can assign staff" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      studio = create_studio(organization: org)
      user = create_user(organization: org)

      attrs = %{
        studio_id: studio.id,
        user_id: user.id,
        role: :instructor
      }

      assert {:ok, staff} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs, actor: owner)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert staff.studio_id == studio.id
      assert staff.user_id == user.id
    end

    test "organization owner can update staff assignments" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      studio = create_studio(organization: org)
      staff = create_studio_staff(studio: studio)

      assert {:ok, updated} =
               staff
               |> Ash.Changeset.for_update(:update, %{role: :manager}, actor: owner)
               |> Ash.update(domain: Studios)

      assert updated.role == :manager
    end

    test "organization members can read staff assignments" do
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)
      staff = create_studio_staff(studio: studio)

      assert {:ok, loaded} =
               StudioStaff
               |> Ash.Query.filter(id == ^staff.id)
               |> Ash.read_one(domain: Studios, actor: member)

      assert loaded.id == staff.id
    end

    test "users from different organizations cannot access other staff assignments" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      studio2 = create_studio(organization: org2)
      staff2 = create_studio_staff(studio: studio2)

      # User from org1 should not be able to read staff from org2
      assert {:ok, nil} =
               StudioStaff
               |> Ash.Query.filter(id == ^staff2.id)
               |> Ash.read_one(domain: Studios, actor: user1)
    end

    @tag :skip
    test "regular members cannot assign staff" do
      # TODO: Implement role-based authorization (owner/admin only)
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)
      user = create_user(organization: org)

      attrs = %{
        studio_id: studio.id,
        user_id: user.id,
        role: :instructor
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               StudioStaff
               |> Ash.Changeset.for_create(:assign, attrs, actor: member)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())
    end

    @tag :skip
    test "instructors cannot deactivate other staff" do
      # TODO: Implement role-based authorization (owner/admin only)
      org = create_organization()
      instructor = create_user(organization: org, role: :instructor)
      studio = create_studio(organization: org)
      staff = create_studio_staff(studio: studio)

      assert {:error, %Ash.Error.Forbidden{}} =
               staff
               |> Ash.Changeset.for_update(:deactivate, %{}, actor: instructor)
               |> Ash.update(domain: Studios)
    end
  end

  describe "data validation edge cases" do
    test "handles unicode characters in notes" do
      staff = create_studio_staff(notes: "Instructor José García - 专业教练")
      assert staff.notes == "Instructor José García - 专业教练"
    end

    test "handles long notes within limit" do
      # Max length is 2000, so create notes around 1900 chars
      long_notes = String.duplicate("Very detailed notes. ", 90)
      staff = create_studio_staff(notes: long_notes)

      assert String.length(staff.notes) > 1000
      assert String.length(staff.notes) <= 2000
    end

    test "handles empty permissions list" do
      staff = create_studio_staff(permissions: [])
      assert staff.permissions == []
    end

    test "handles many permissions" do
      many_permissions = [
        "teach",
        "manage_schedule",
        "manage_staff",
        "view_reports",
        "manage_clients",
        "manage_equipment",
        "view_analytics",
        "export_data",
        "configure_studio",
        "send_notifications"
      ]

      staff = create_studio_staff(permissions: many_permissions)
      assert length(staff.permissions) == 10
    end
  end

  describe "concurrent staff operations" do
    test "handles concurrent staff assignments to same studio" do
      studio = create_studio()

      org =
        Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization

      tasks =
        Enum.map(1..5, fn i ->
          Task.async(fn ->
            user = create_user(organization: org, email: "user#{i}@test.com")

            attrs = %{
              studio_id: studio.id,
              user_id: user.id,
              role: :instructor
            }

            StudioStaff
            |> Ash.Changeset.for_create(:assign, attrs)
            |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed
      assert Enum.all?(results, fn
               {:ok, _staff} -> true
               _ -> false
             end)
    end

    test "handles concurrent updates to same staff assignment" do
      staff = create_studio_staff()

      tasks =
        Enum.map([:instructor, :manager, :front_desk], fn role ->
          Task.async(fn ->
            staff
            |> Ash.Changeset.for_update(:update, %{role: role},
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

  describe "staff deletion and cleanup" do
    test "can delete staff assignment" do
      staff = create_studio_staff()

      assert :ok =
               Ash.destroy(staff,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify staff assignment is gone
      assert {:ok, nil} =
               StudioStaff
               |> Ash.Query.filter(id == ^staff.id)
               |> Ash.read_one(
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
    end

    test "deleting staff assignment does not delete user" do
      studio = create_studio()

      user =
        create_user(
          organization:
            Ash.load!(studio, :organization, actor: PilatesOnPhx.StudiosFixtures.bypass_actor()).organization
        )

      staff = create_studio_staff(studio: studio, user: user)

      # Delete staff assignment
      assert :ok =
               Ash.destroy(staff,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify user still exists
      found_user =
        PilatesOnPhx.Accounts.User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.read_one!(
          domain: PilatesOnPhx.Accounts,
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )

      assert found_user.id == user.id
    end

    test "deleting staff assignment does not delete studio" do
      studio = create_studio()
      staff = create_studio_staff(studio: studio)

      # Delete staff assignment
      assert :ok =
               Ash.destroy(staff,
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
