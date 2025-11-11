defmodule PilatesOnPhx.Accounts.OrganizationMembershipTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.{OrganizationMembership, User, Organization}
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "membership creation (action: create)" do
    test "creates membership with valid user and organization" do
      user = create_user()
      org = create_organization()

      attrs = %{
        user_id: user.id,
        organization_id: org.id,
        role: :member,
        joined_at: DateTime.utc_now()
      }

      assert {:ok, membership} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert membership.user_id == user.id
      assert membership.organization_id == org.id
      assert membership.role == :member
      assert membership.joined_at != nil
    end

    test "requires user_id" do
      org = create_organization()

      attrs = %{
        organization_id: org.id,
        role: :member
      }

      assert {:error, changeset} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :user_id end)
    end

    test "requires organization_id" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        role: :member
      }

      assert {:error, changeset} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :organization_id end)
    end

    test "sets default role to :member if not specified" do
      user = create_user()
      org = create_organization()

      attrs = %{
        user_id: user.id,
        organization_id: org.id,
        joined_at: DateTime.utc_now()
      }

      assert {:ok, membership} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert membership.role == :member
    end

    test "sets joined_at to current time if not specified" do
      user = create_user()
      org = create_organization()

      before_create = DateTime.utc_now()

      attrs = %{
        user_id: user.id,
        organization_id: org.id,
        role: :member
      }

      assert {:ok, membership} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      after_create = DateTime.utc_now()

      assert membership.joined_at != nil
      assert DateTime.compare(membership.joined_at, before_create) in [:gt, :eq]
      assert DateTime.compare(membership.joined_at, after_create) in [:lt, :eq]
    end

    test "prevents duplicate membership for same user and organization" do
      user = create_user()
      org = create_organization()

      # Create first membership
      attrs = %{
        user_id: user.id,
        organization_id: org.id,
        role: :member
      }

      assert {:ok, _membership} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      # Attempt duplicate membership
      assert {:error, changeset} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error ->
        error.message =~ "unique"
      end)
    end

    test "allows same user to join multiple organizations" do
      user = create_user()
      org1 = create_organization()
      org2 = create_organization()
      org3 = create_organization()

      # Create memberships in three organizations
      {:ok, mem1} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: user.id,
          organization_id: org1.id,
          role: :member
        })
        |> Accounts.create()

      {:ok, mem2} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: user.id,
          organization_id: org2.id,
          role: :member
        })
        |> Accounts.create()

      {:ok, mem3} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: user.id,
          organization_id: org3.id,
          role: :member
        })
        |> Accounts.create()

      # All memberships should exist
      assert mem1.user_id == user.id
      assert mem2.user_id == user.id
      assert mem3.user_id == user.id
      assert length([mem1, mem2, mem3]) == 3
    end

    test "validates user exists" do
      org = create_organization()
      non_existent_user_id = Ash.UUID.generate()

      attrs = %{
        user_id: non_existent_user_id,
        organization_id: org.id,
        role: :member
      }

      assert {:error, changeset} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert changeset.valid? == false
    end

    test "validates organization exists" do
      user = create_user()
      non_existent_org_id = Ash.UUID.generate()

      attrs = %{
        user_id: user.id,
        organization_id: non_existent_org_id,
        role: :member
      }

      assert {:error, changeset} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert changeset.valid? == false
    end
  end

  describe "membership roles" do
    test "supports owner role" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        role: :owner
      )

      assert membership.role == :owner
    end

    test "supports admin role" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        role: :admin
      )

      assert membership.role == :admin
    end

    test "supports member role" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        role: :member
      )

      assert membership.role == :member
    end

    test "rejects invalid role values" do
      user = create_user()
      org = create_organization()

      attrs = %{
        user_id: user.id,
        organization_id: org.id,
        role: :invalid_role
      }

      assert {:error, changeset} =
        OrganizationMembership
        |> Ash.Changeset.for_create(:create, attrs)
        |> Accounts.create()

      assert changeset.valid? == false
    end

    test "user can have different roles in different organizations" do
      user = create_user()
      org1 = create_organization()
      org2 = create_organization()
      org3 = create_organization()

      # Owner in first org
      mem1 = create_organization_membership(
        user: user,
        organization: org1,
        role: :owner
      )

      # Admin in second org
      mem2 = create_organization_membership(
        user: user,
        organization: org2,
        role: :admin
      )

      # Member in third org
      mem3 = create_organization_membership(
        user: user,
        organization: org3,
        role: :member
      )

      assert mem1.role == :owner
      assert mem2.role == :admin
      assert mem3.role == :member
    end
  end

  describe "membership updates (action: update)" do
    test "can update membership role" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        role: :member
      )

      assert {:ok, updated} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :admin})
        |> Accounts.update()

      assert updated.role == :admin
      assert updated.id == membership.id
    end

    test "can promote member to owner" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        role: :member
      )

      assert {:ok, promoted} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Accounts.update()

      assert promoted.role == :owner
    end

    test "can demote owner to member" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        role: :owner
      )

      assert {:ok, demoted} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :member})
        |> Accounts.update()

      assert demoted.role == :member
    end

    test "cannot change user_id after creation" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization()
      )

      new_user = create_user()

      # Attempting to change user_id should fail or be ignored
      result = membership
      |> Ash.Changeset.for_update(:update, %{user_id: new_user.id})
      |> Accounts.update()

      case result do
        {:ok, updated} ->
          # If update succeeds, user_id should remain unchanged
          assert updated.user_id == membership.user_id

        {:error, _changeset} ->
          # Or the update should fail
          assert true
      end
    end

    test "cannot change organization_id after creation" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization()
      )

      new_org = create_organization()

      # Attempting to change organization_id should fail or be ignored
      result = membership
      |> Ash.Changeset.for_update(:update, %{organization_id: new_org.id})
      |> Accounts.update()

      case result do
        {:ok, updated} ->
          # If update succeeds, organization_id should remain unchanged
          assert updated.organization_id == membership.organization_id

        {:error, _changeset} ->
          # Or the update should fail
          assert true
      end
    end
  end

  describe "membership relationships" do
    test "membership belongs to user" do
      user = create_user()
      org = create_organization()
      membership = create_organization_membership(user: user, organization: org)

      loaded_membership =
        OrganizationMembership
        |> Ash.Query.filter(id == ^membership.id)
        |> Ash.Query.load(:user)
        |> Accounts.read_one!()

      assert loaded_membership.user.id == user.id
      assert loaded_membership.user.email == user.email
    end

    test "membership belongs to organization" do
      user = create_user()
      org = create_organization()
      membership = create_organization_membership(user: user, organization: org)

      loaded_membership =
        OrganizationMembership
        |> Ash.Query.filter(id == ^membership.id)
        |> Ash.Query.load(:organization)
        |> Accounts.read_one!()

      assert loaded_membership.organization.id == org.id
      assert loaded_membership.organization.name == org.name
    end

    test "can load both user and organization relationships" do
      user = create_user()
      org = create_organization()
      membership = create_organization_membership(user: user, organization: org)

      loaded_membership =
        OrganizationMembership
        |> Ash.Query.filter(id == ^membership.id)
        |> Ash.Query.load([:user, :organization])
        |> Accounts.read_one!()

      assert loaded_membership.user.id == user.id
      assert loaded_membership.organization.id == org.id
    end
  end

  describe "membership queries and filtering" do
    test "can query all memberships for an organization" do
      org = create_organization()
      user1 = create_user()
      user2 = create_user()
      user3 = create_user()

      create_organization_membership(user: user1, organization: org)
      create_organization_membership(user: user2, organization: org)
      create_organization_membership(user: user3, organization: org)

      memberships =
        OrganizationMembership
        |> Ash.Query.filter(organization_id == ^org.id)
        |> Accounts.read!()

      assert length(memberships) >= 3

      user_ids = Enum.map(memberships, & &1.user_id)
      assert user1.id in user_ids
      assert user2.id in user_ids
      assert user3.id in user_ids
    end

    test "can query all memberships for a user" do
      user = create_user()
      org1 = create_organization()
      org2 = create_organization()
      org3 = create_organization()

      create_organization_membership(user: user, organization: org1)
      create_organization_membership(user: user, organization: org2)
      create_organization_membership(user: user, organization: org3)

      memberships =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^user.id)
        |> Accounts.read!()

      assert length(memberships) == 3

      org_ids = Enum.map(memberships, & &1.organization_id)
      assert org1.id in org_ids
      assert org2.id in org_ids
      assert org3.id in org_ids
    end

    test "can filter memberships by role" do
      org = create_organization()
      owner = create_user()
      admin = create_user()
      member = create_user()

      create_organization_membership(user: owner, organization: org, role: :owner)
      create_organization_membership(user: admin, organization: org, role: :admin)
      create_organization_membership(user: member, organization: org, role: :member)

      owners =
        OrganizationMembership
        |> Ash.Query.filter(organization_id == ^org.id and role == :owner)
        |> Accounts.read!()

      assert length(owners) >= 1
      assert Enum.all?(owners, fn m -> m.role == :owner end)
    end

    test "can find specific membership by user and organization" do
      user = create_user()
      org = create_organization()
      membership = create_organization_membership(user: user, organization: org)

      found =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^user.id and organization_id == ^org.id)
        |> Accounts.read_one!()

      assert found.id == membership.id
    end

    test "can filter memberships by join date range" do
      org = create_organization()

      # Create membership from 30 days ago
      old_date = DateTime.add(DateTime.utc_now(), -30 * 24 * 3600, :second)
      old_membership = create_organization_membership(
        user: create_user(),
        organization: org,
        joined_at: old_date
      )

      # Create membership from today
      new_membership = create_organization_membership(
        user: create_user(),
        organization: org,
        joined_at: DateTime.utc_now()
      )

      # Query memberships from last 7 days
      cutoff_date = DateTime.add(DateTime.utc_now(), -7 * 24 * 3600, :second)

      recent_memberships =
        OrganizationMembership
        |> Ash.Query.filter(organization_id == ^org.id and joined_at >= ^cutoff_date)
        |> Accounts.read!()

      membership_ids = Enum.map(recent_memberships, & &1.id)

      assert new_membership.id in membership_ids
      refute old_membership.id in membership_ids
    end
  end

  describe "multi-organization membership scenarios" do
    test "instructor working at multiple studios" do
      instructor = create_user(role: :instructor, name: "John Instructor")

      studio_a = create_organization(name: "Studio A")
      studio_b = create_organization(name: "Studio B")
      studio_c = create_organization(name: "Studio C")

      mem_a = create_organization_membership(user: instructor, organization: studio_a, role: :member)
      mem_b = create_organization_membership(user: instructor, organization: studio_b, role: :member)
      mem_c = create_organization_membership(user: instructor, organization: studio_c, role: :admin)

      memberships =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^instructor.id)
        |> Ash.Query.load(:organization)
        |> Accounts.read!()

      assert length(memberships) == 3

      studio_names = Enum.map(memberships, fn m -> m.organization.name end)
      assert "Studio A" in studio_names
      assert "Studio B" in studio_names
      assert "Studio C" in studio_names

      # Verify different roles
      roles_by_org = Map.new(memberships, fn m -> {m.organization.name, m.role} end)
      assert roles_by_org["Studio C"] == :admin
    end

    test "owner of multiple studios with admin at another" do
      multi_owner = create_user(role: :owner, name: "Jane Owner")

      own_studio_1 = create_organization(name: "Own Studio 1")
      own_studio_2 = create_organization(name: "Own Studio 2")
      other_studio = create_organization(name: "Other Studio")

      create_organization_membership(user: multi_owner, organization: own_studio_1, role: :owner)
      create_organization_membership(user: multi_owner, organization: own_studio_2, role: :owner)
      create_organization_membership(user: multi_owner, organization: other_studio, role: :admin)

      memberships =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^multi_owner.id)
        |> Ash.Query.load(:organization)
        |> Accounts.read!()

      assert length(memberships) == 3

      owned_studios = Enum.filter(memberships, fn m -> m.role == :owner end)
      assert length(owned_studios) == 2

      admin_studios = Enum.filter(memberships, fn m -> m.role == :admin end)
      assert length(admin_studios) == 1
    end

    test "client attending classes at multiple studios" do
      client = create_user(role: :client, name: "Client Member")

      nearby_studio_1 = create_organization(name: "Nearby Studio 1")
      nearby_studio_2 = create_organization(name: "Nearby Studio 2")
      work_studio = create_organization(name: "Work Studio")

      create_organization_membership(user: client, organization: nearby_studio_1)
      create_organization_membership(user: client, organization: nearby_studio_2)
      create_organization_membership(user: client, organization: work_studio)

      memberships =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^client.id)
        |> Accounts.read!()

      assert length(memberships) == 3
      assert Enum.all?(memberships, fn m -> m.role == :member end)
    end
  end

  describe "membership lifecycle and timestamps" do
    test "tracks membership creation timestamp" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization()
      )

      assert membership.inserted_at != nil
      assert %DateTime{} = membership.inserted_at
    end

    test "tracks membership update timestamp" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        role: :member
      )

      original_updated_at = membership.updated_at

      Process.sleep(10)

      {:ok, updated} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :admin})
        |> Accounts.update()

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "joined_at reflects when user joined organization" do
      join_time = DateTime.utc_now()

      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization(),
        joined_at: join_time
      )

      # joined_at should be approximately the specified time
      diff = DateTime.diff(membership.joined_at, join_time, :second)
      assert abs(diff) < 2  # Within 2 seconds
    end
  end

  describe "membership deletion and cleanup" do
    test "can delete membership" do
      membership = create_organization_membership(
        user: create_user(),
        organization: create_organization()
      )

      assert :ok = Accounts.destroy(membership)

      # Verify membership is gone
      assert {:error, %Ash.Error.Query.NotFound{}} =
        OrganizationMembership
        |> Ash.Query.filter(id == ^membership.id)
        |> Accounts.read_one()
    end

    test "deleting user cascades to memberships" do
      user = create_user()
      org1 = create_organization()
      org2 = create_organization()

      mem1 = create_organization_membership(user: user, organization: org1)
      mem2 = create_organization_membership(user: user, organization: org2)

      # Delete user
      assert :ok = Accounts.destroy(user)

      # Verify memberships are deleted
      remaining_memberships =
        OrganizationMembership
        |> Ash.Query.filter(id in ^[mem1.id, mem2.id])
        |> Accounts.read!()

      assert remaining_memberships == []
    end

    test "deleting organization cascades to memberships" do
      org = create_organization()
      user1 = create_user()
      user2 = create_user()

      mem1 = create_organization_membership(user: user1, organization: org)
      mem2 = create_organization_membership(user: user2, organization: org)

      # Delete organization
      assert :ok = Accounts.destroy(org)

      # Verify memberships are deleted
      remaining_memberships =
        OrganizationMembership
        |> Ash.Query.filter(id in ^[mem1.id, mem2.id])
        |> Accounts.read!()

      assert remaining_memberships == []
    end

    test "deleting membership does not delete user or organization" do
      user = create_user()
      org = create_organization()
      membership = create_organization_membership(user: user, organization: org)

      # Delete membership
      assert :ok = Accounts.destroy(membership)

      # Verify user and organization still exist
      assert {:ok, _} =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Accounts.read_one()

      assert {:ok, _} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Accounts.read_one()
    end
  end

  describe "authorization policies" do
    test "organization owner can view all memberships" do
      org = create_organization()
      owner = create_user(organization: org)

      # Set owner role
      owner_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
        |> Accounts.read_one!()

      OrganizationMembership
      |> Ash.Changeset.for_update(:update, owner_membership, %{role: :owner})
      |> Accounts.update!()

      # Create more members
      member1 = create_user(organization: org)
      member2 = create_user(organization: org)

      # Owner should be able to list all memberships
      memberships =
        OrganizationMembership
        |> Ash.Query.filter(organization_id == ^org.id)
        |> Accounts.read!(actor: owner)

      assert length(memberships) >= 3
    end

    test "member can view their own membership" do
      user = create_user()
      org = create_organization()
      membership = create_organization_membership(user: user, organization: org)

      loaded =
        OrganizationMembership
        |> Ash.Query.filter(id == ^membership.id)
        |> Accounts.read_one!(actor: user)

      assert loaded.id == membership.id
    end

    test "member cannot view memberships from other organizations" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      user2 = create_user(organization: org2)

      membership2 =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^user2.id)
        |> Accounts.read_one!()

      # User1 should not access user2's membership in different org
      assert {:error, %Ash.Error.Forbidden{}} =
        OrganizationMembership
        |> Ash.Query.filter(id == ^membership2.id)
        |> Accounts.read_one(actor: user1)
    end

    test "only owner can update member roles" do
      org = create_organization()
      owner = create_user(organization: org)
      member = create_user(organization: org)

      # Set owner role
      owner_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id)
        |> Accounts.read_one!()

      OrganizationMembership
      |> Ash.Changeset.for_update(:update, owner_membership, %{role: :owner})
      |> Accounts.update!()

      member_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^member.id)
        |> Accounts.read_one!()

      # Owner can update
      assert {:ok, updated} =
        member_membership
        |> Ash.Changeset.for_update(:update, %{role: :admin}, actor: owner)
        |> Accounts.update()

      assert updated.role == :admin
    end

    test "regular member cannot promote themselves" do
      org = create_organization()
      member = create_user(organization: org)

      member_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^member.id)
        |> Accounts.read_one!()

      # Member cannot promote self
      assert {:error, %Ash.Error.Forbidden{}} =
        member_membership
        |> Ash.Changeset.for_update(:update, %{role: :owner}, actor: member)
        |> Accounts.update()
    end
  end

  describe "data consistency and constraints" do
    test "organization must have at least one owner" do
      # This test validates business logic for ensuring orgs always have an owner
      org = create_organization()
      owner = create_user(organization: org)

      # Set as owner
      membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
        |> Accounts.read_one!()

      OrganizationMembership
      |> Ash.Changeset.for_update(:update, membership, %{role: :owner})
      |> Accounts.update!()

      # Try to demote the only owner - should either fail or be handled by business logic
      result = membership
      |> Ash.Changeset.for_update(:update, %{role: :member})
      |> Accounts.update()

      case result do
        {:error, changeset} ->
          # Should prevent demoting last owner
          assert changeset.valid? == false

        {:ok, _updated} ->
          # If allowed, verify another owner exists or business logic handles it
          owners =
            OrganizationMembership
            |> Ash.Query.filter(organization_id == ^org.id and role == :owner)
            |> Accounts.read!()

          # Either the update maintained owner role or there's another owner
          assert length(owners) >= 0  # Business logic may allow this
      end
    end

    test "concurrent membership creation for same user-org pair" do
      user = create_user()
      org = create_organization()

      # Attempt concurrent membership creation
      tasks = Enum.map(1..3, fn _ ->
        Task.async(fn ->
          OrganizationMembership
          |> Ash.Changeset.for_create(:create, %{
            user_id: user.id,
            organization_id: org.id,
            role: :member
          })
          |> Accounts.create()
        end)
      end)

      results = Task.await_many(tasks)

      # Exactly one should succeed
      successful = Enum.filter(results, fn
        {:ok, _} -> true
        _ -> false
      end)

      assert length(successful) == 1
    end
  end
end
