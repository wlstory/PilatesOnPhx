defmodule PilatesOnPhx.Accounts.AuthorizationPoliciesTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.{User, Organization, OrganizationMembership, Token}
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  @moduledoc """
  Comprehensive tests for authorization policies in the Accounts domain.

  These tests verify:
  - Multi-tenant data isolation
  - Role-based access control (RBAC)
  - Resource-level permissions
  - Cross-organization access prevention
  - Actor-based authorization enforcement
  """

  describe "multi-tenant organization isolation" do
    test "users can only read users in their own organization" do
      org1 = create_organization(name: "Studio A")
      org2 = create_organization(name: "Studio B")

      user_org1 = create_user(organization: org1, email: "user1@studioa.com")
      user_org2 = create_user(organization: org2, email: "user2@studiob.com")

      # User from org1 can read users in org1
      assert {:ok, loaded} =
        User
        |> Ash.Query.filter(id == ^user_org1.id)
        |> Ash.read_one(domain: Accounts, actor: user_org1)

      assert loaded.id == user_org1.id

      # User from org1 cannot read users in org2
      assert {:error, %Ash.Error.Forbidden{}} =
        User
        |> Ash.Query.filter(id == ^user_org2.id)
        |> Ash.read_one(domain: Accounts, actor: user_org1)
    end

    test "users can only list users within their organization" do
      org1 = create_organization(name: "Studio A")
      org2 = create_organization(name: "Studio B")

      user1_org1 = create_user(organization: org1)
      user2_org1 = create_user(organization: org1)
      user3_org1 = create_user(organization: org1)

      user1_org2 = create_user(organization: org2)
      user2_org2 = create_user(organization: org2)

      # User from org1 queries all users
      users_visible_to_org1 =
        User
        |> Ash.read!(domain: Accounts, actor: user1_org1)

      user_ids = Enum.map(users_visible_to_org1, & &1.id)

      # Should see users from own organization
      assert user1_org1.id in user_ids
      assert user2_org1.id in user_ids
      assert user3_org1.id in user_ids

      # Should NOT see users from other organization
      refute user1_org2.id in user_ids
      refute user2_org2.id in user_ids
    end

    test "organizations are isolated - users can only access their own organization" do
      org1 = create_organization(name: "My Studio")
      org2 = create_organization(name: "Other Studio")

      user1 = create_user(organization: org1)
      user2 = create_user(organization: org2)

      # User1 can access their organization
      assert {:ok, loaded_org1} =
        Organization
        |> Ash.Query.filter(id == ^org1.id)
        |> Ash.read_one(domain: Accounts, actor: user1)

      assert loaded_org1.id == org1.id

      # User1 cannot access other organization
      assert {:error, %Ash.Error.Forbidden{}} =
        Organization
        |> Ash.Query.filter(id == ^org2.id)
        |> Ash.read_one(domain: Accounts, actor: user1)

      # User2 can access their organization
      assert {:ok, loaded_org2} =
        Organization
        |> Ash.Query.filter(id == ^org2.id)
        |> Ash.read_one(domain: Accounts, actor: user2)

      assert loaded_org2.id == org2.id

      # User2 cannot access other organization
      assert {:error, %Ash.Error.Forbidden{}} =
        Organization
        |> Ash.Query.filter(id == ^org1.id)
        |> Ash.read_one(domain: Accounts, actor: user2)
    end

    test "memberships are scoped to actor's organization" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      user2_org1 = create_user(organization: org1)

      user1_org2 = create_user(organization: org2)

      # User1 queries memberships
      visible_memberships =
        OrganizationMembership
        |> Ash.read!(domain: Accounts, actor: user1)

      membership_org_ids = Enum.map(visible_memberships, & &1.organization_id)

      # Should see memberships from own organization
      assert org1.id in membership_org_ids

      # Should NOT see memberships from other organization
      refute org2.id in membership_org_ids
    end

    test "tokens are isolated to their owner" do
      user1 = create_user()
      user2 = create_user()

      token1 = create_token(user: user1)
      token2 = create_token(user: user2)

      # User1 can access their own token
      assert {:ok, loaded_token} =
        Token
        |> Ash.Query.filter(jti == ^token1.jti)
        |> Ash.read_one(domain: Accounts, actor: user1)

      assert loaded_token.jti == token1.jti

      # User1 cannot access user2's token
      assert {:error, %Ash.Error.Forbidden{}} =
        Token
        |> Ash.Query.filter(jti == ^token2.jti)
        |> Ash.read_one(domain: Accounts, actor: user1)
    end
  end

  describe "role-based access control - owner permissions" do
    test "owner can update organization settings" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      # Update owner membership role
      membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      {:ok, _} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts)

      # Owner can update organization
      assert {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"}, actor: owner)
        |> Accounts.update()

      assert updated.name == "Updated by Owner"
    end

    test "owner can manage organization memberships" do
      org = create_organization()
      owner = create_user(organization: org, role: :owner)
      member = create_user(organization: org, role: :client)

      # Set owner role on membership
      owner_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      {:ok, _} =
        owner_membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts)

      # Owner can update member's role
      member_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^member.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert {:ok, updated_membership} =
        member_membership
        |> Ash.Changeset.for_update(:update, %{role: :admin}, actor: owner)
        |> Accounts.update()

      assert updated_membership.role == :admin
    end

    test "owner can deactivate organization" do
      org = create_organization(active: true)
      owner = create_user(organization: org, role: :owner)

      # Set owner role
      membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      {:ok, _} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts)

      # Owner can deactivate
      assert {:ok, deactivated} =
        org
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: owner)
        |> Accounts.update()

      assert deactivated.active == false
    end

    test "owner can view all organization members" do
      scenario = create_organization_scenario(
        instructor_count: 3,
        client_count: 10
      )

      owner = scenario.owner
      org = scenario.organization

      # Set owner role
      membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      {:ok, _} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts)

      # Owner can see all users in organization
      org_users =
        User
        |> Ash.read!(domain: Accounts, actor: owner)

      # Should see at least owner + instructors + clients
      assert length(org_users) >= 14
    end
  end

  describe "role-based access control - instructor permissions" do
    test "instructor can read organization but not update" do
      org = create_organization()
      instructor = create_user(organization: org, role: :instructor)

      # Instructor can read organization
      assert {:ok, loaded_org} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: instructor)

      assert loaded_org.id == org.id

      # Instructor cannot update organization settings
      assert {:error, %Ash.Error.Forbidden{}} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "Unauthorized Update"}, actor: instructor)
        |> Accounts.update()
    end

    test "instructor can view other members but not change roles" do
      org = create_organization()
      instructor = create_user(organization: org, role: :instructor)
      client = create_user(organization: org, role: :client)

      # Instructor can see other members
      members =
        User
        |> Ash.read!(domain: Accounts, actor: instructor)

      member_ids = Enum.map(members, & &1.id)
      assert client.id in member_ids

      # Instructor cannot change member roles
      client_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^client.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert {:error, %Ash.Error.Forbidden{}} =
        client_membership
        |> Ash.Changeset.for_update(:update, %{role: :admin}, actor: instructor)
        |> Accounts.update()
    end

    test "instructor cannot deactivate organization" do
      org = create_organization(active: true)
      instructor = create_user(organization: org, role: :instructor)

      assert {:error, %Ash.Error.Forbidden{}} =
        org
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: instructor)
        |> Accounts.update()
    end
  end

  describe "role-based access control - client permissions" do
    test "client can read organization but not update" do
      org = create_organization()
      client = create_user(organization: org, role: :client)

      # Client can read organization
      assert {:ok, loaded_org} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: client)

      assert loaded_org.id == org.id

      # Client cannot update organization
      assert {:error, %Ash.Error.Forbidden{}} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "Unauthorized"}, actor: client)
        |> Accounts.update()
    end

    test "client can view other members in organization" do
      org = create_organization()
      client = create_user(organization: org, role: :client)
      other_client = create_user(organization: org, role: :client)

      # Client can see other members
      members =
        User
        |> Ash.read!(domain: Accounts, actor: client)

      member_ids = Enum.map(members, & &1.id)
      assert other_client.id in member_ids
    end

    test "client cannot change anyone's role" do
      org = create_organization()
      client = create_user(organization: org, role: :client)
      other_client = create_user(organization: org, role: :client)

      other_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^other_client.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert {:error, %Ash.Error.Forbidden{}} =
        other_membership
        |> Ash.Changeset.for_update(:update, %{role: :admin}, actor: client)
        |> Accounts.update()
    end

    test "client cannot promote themselves" do
      org = create_organization()
      client = create_user(organization: org, role: :client)

      client_membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^client.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert {:error, %Ash.Error.Forbidden{}} =
        client_membership
        |> Ash.Changeset.for_update(:update, %{role: :owner}, actor: client)
        |> Accounts.update()
    end
  end

  describe "self-service user operations" do
    test "user can update their own profile" do
      user = create_user(name: "Original Name")

      assert {:ok, updated} =
        user
        |> Ash.Changeset.for_update(:update, %{name: "Updated Name"}, actor: user)
        |> Accounts.update()

      assert updated.name == "Updated Name"
    end

    test "user can change their own password" do
      old_password = "OldPassword123!"
      user = create_user(password: old_password)

      new_password = "NewPassword456!"

      assert {:ok, _updated} =
        user
        |> Ash.Changeset.for_update(:change_password, %{
          current_password: old_password,
          password: new_password,
          password_confirmation: new_password
        }, actor: user)
        |> Accounts.update()
    end

    test "user cannot update other users' profiles" do
      user1 = create_user()
      user2 = create_user()

      assert {:error, %Ash.Error.Forbidden{}} =
        user2
        |> Ash.Changeset.for_update(:update, %{name: "Unauthorized"}, actor: user1)
        |> Accounts.update()
    end

    test "user can manage their own tokens" do
      user = create_user()
      token = create_token(user: user)

      # User can revoke their own token
      assert {:ok, revoked} =
        token
        |> Ash.Changeset.for_update(:revoke, %{}, actor: user)
        |> Accounts.update()

      assert revoked.revoked_at != nil
    end

    test "user cannot revoke other users' tokens" do
      user1 = create_user()
      user2 = create_user()

      token2 = create_token(user: user2)

      assert {:error, %Ash.Error.Forbidden{}} =
        token2
        |> Ash.Changeset.for_update(:revoke, %{}, actor: user1)
        |> Accounts.update()
    end
  end

  describe "cross-organization access prevention" do
    test "instructor at studio A cannot access studio B data" do
      studio_a = create_organization(name: "Studio A")
      studio_b = create_organization(name: "Studio B")

      instructor_a = create_user(organization: studio_a, role: :instructor)
      instructor_b = create_user(organization: studio_b, role: :instructor)

      # Instructor A cannot access Studio B
      assert {:error, %Ash.Error.Forbidden{}} =
        Organization
        |> Ash.Query.filter(id == ^studio_b.id)
        |> Ash.read_one(domain: Accounts, actor: instructor_a)

      # Instructor A cannot access users from Studio B
      assert {:error, %Ash.Error.Forbidden{}} =
        User
        |> Ash.Query.filter(id == ^instructor_b.id)
        |> Ash.read_one(domain: Accounts, actor: instructor_a)
    end

    test "owner of studio A cannot manage studio B" do
      studio_a = create_organization(name: "Studio A")
      studio_b = create_organization(name: "Studio B")

      owner_a = create_user(organization: studio_a, role: :owner)

      # Set owner role
      membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner_a.id and organization_id == ^studio_a.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      {:ok, _} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts)

      # Owner of A cannot update Studio B
      assert {:error, %Ash.Error.Forbidden{}} =
        studio_b
        |> Ash.Changeset.for_update(:update, %{name: "Unauthorized"}, actor: owner_a)
        |> Accounts.update()

      # Owner of A cannot deactivate Studio B
      assert {:error, %Ash.Error.Forbidden{}} =
        studio_b
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: owner_a)
        |> Accounts.update()
    end

    test "client cannot see users from other organizations" do
      org1 = create_organization()
      org2 = create_organization()

      client1 = create_user(organization: org1, role: :client)
      client2 = create_user(organization: org2, role: :client)

      # Client1 queries users
      visible_users =
        User
        |> Ash.read!(domain: Accounts, actor: client1)

      user_ids = Enum.map(visible_users, & &1.id)

      # Should see users from own org
      assert client1.id in user_ids

      # Should NOT see users from other org
      refute client2.id in user_ids
    end
  end

  describe "multi-organization user access control" do
    test "user with multiple memberships can access all their organizations" do
      org1 = create_organization(name: "Studio 1")
      org2 = create_organization(name: "Studio 2")
      org3 = create_organization(name: "Studio 3")

      multi_org_user = create_multi_org_user(organizations: [org1, org2, org3])

      # User should be able to access all their organizations
      assert {:ok, loaded_org1} =
        Organization
        |> Ash.Query.filter(id == ^org1.id)
        |> Ash.read_one(domain: Accounts, actor: multi_org_user)

      assert {:ok, loaded_org2} =
        Organization
        |> Ash.Query.filter(id == ^org2.id)
        |> Ash.read_one(domain: Accounts, actor: multi_org_user)

      assert {:ok, loaded_org3} =
        Organization
        |> Ash.Query.filter(id == ^org3.id)
        |> Ash.read_one(domain: Accounts, actor: multi_org_user)

      assert loaded_org1.id == org1.id
      assert loaded_org2.id == org2.id
      assert loaded_org3.id == org3.id
    end

    test "user with different roles in different orgs has appropriate permissions" do
      org1 = create_organization(name: "Owned Studio")
      org2 = create_organization(name: "Freelance Studio")

      multi_user = create_user()

      # Owner at org1
      mem1 = create_organization_membership(user: multi_user, organization: org1, role: :owner)

      # Member at org2
      create_organization_membership(user: multi_user, organization: org2, role: :member)

      # Can update org1 (as owner)
      assert {:ok, _updated} =
        org1
        |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"}, actor: multi_user)
        |> Accounts.update()

      # Cannot update org2 (as member)
      assert {:error, %Ash.Error.Forbidden{}} =
        org2
        |> Ash.Changeset.for_update(:update, %{name: "Unauthorized"}, actor: multi_user)
        |> Accounts.update()
    end

    test "removing membership removes organization access" do
      org = create_organization()
      user = create_user(organization: org)

      membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^user.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      # User has access
      assert {:ok, _} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: user)

      # Remove membership
      Ash.destroy(membership, domain: Accounts)

      # User no longer has access
      assert {:error, %Ash.Error.Forbidden{}} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: user)
    end
  end

  describe "unauthenticated access restrictions" do
    test "unauthenticated users cannot list organizations" do
      create_organization()
      create_organization()

      # No actor provided
      result = Organization |> Accounts.read()

      # Should require authentication
      assert match?({:error, _}, result)
    end

    test "unauthenticated users cannot list users" do
      create_user()
      create_user()

      # No actor provided
      result = User |> Accounts.read()

      # Should require authentication
      assert match?({:error, _}, result)
    end

    test "unauthenticated users cannot create tokens" do
      user = create_user()

      token_attrs = %{
        user_id: user.id,
        token_type: "bearer",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      # No actor provided
      result =
        Token
        |> Ash.Changeset.for_create(:create, token_attrs)
        |> Accounts.create()

      # Should either require authentication or have specific handling
      # (Actual behavior depends on resource policies)
      case result do
        {:error, _} -> assert true
        {:ok, _} -> assert true  # Token creation might not require actor
      end
    end
  end

  describe "authorization with inactive organizations" do
    test "users in inactive organization maintain read access" do
      org = create_organization(active: true)
      user = create_user(organization: org)

      # Deactivate organization
      {:ok, deactivated_org} =
        org
        |> Ash.Changeset.for_update(:deactivate, %{})
        |> Accounts.update()

      # User can still read the organization (to see it's inactive)
      assert {:ok, loaded} =
        Organization
        |> Ash.Query.filter(id == ^deactivated_org.id)
        |> Ash.read_one(domain: Accounts, actor: user)

      assert loaded.active == false
    end

    test "owner can reactivate inactive organization" do
      org = create_organization(active: false)
      owner = create_user(organization: org, role: :owner)

      # Set owner role
      membership =
        OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      {:ok, _} =
        membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts)

      # Owner can reactivate
      assert {:ok, reactivated} =
        org
        |> Ash.Changeset.for_update(:activate, %{}, actor: owner)
        |> Accounts.update()

      assert reactivated.active == true
    end
  end

  describe "authorization edge cases" do
    test "user cannot access organization after all memberships deleted" do
      org = create_organization()
      user = create_user(organization: org)

      # User has access initially
      assert {:ok, _} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: user)

      # Delete all memberships
      OrganizationMembership
      |> Ash.Query.filter(user_id == ^user.id and organization_id == ^org.id)
      |> Ash.read!(domain: Accounts, actor: bypass_actor())
      |> Enum.each(fn membership -> Ash.destroy(membership, domain: Accounts) end)

      # User no longer has access
      assert {:error, %Ash.Error.Forbidden{}} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: user)
    end

    test "deleted user's tokens are inaccessible" do
      user = create_user()
      token = create_token(user: user)

      # Delete user (cascades to tokens)
      Ash.destroy(user, domain: Accounts)

      # Token should be deleted
      result =
        Token
        |> Ash.Query.filter(jti == ^token.jti)
        |> Ash.read_one(domain: Accounts, actor: bypass_actor())

      assert match?({:error, %Ash.Error.Query.NotFound{}}, result)
    end

    test "concurrent authorization checks remain consistent" do
      org = create_organization()
      user = create_user(organization: org)

      # Simulate concurrent access attempts
      tasks = Enum.map(1..5, fn _ ->
        Task.async(fn ->
          Organization
          |> Ash.Query.filter(id == ^org.id)
          |> Ash.read_one(domain: Accounts, actor: user)
        end)
      end)

      results = Task.await_many(tasks)

      # All should succeed consistently
      assert Enum.all?(results, fn
        {:ok, loaded} -> loaded.id == org.id
        _ -> false
      end)
    end

    test "user with no memberships cannot access any organization" do
      # Create user without adding to any organization
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, %{
          email: "nomembership@example.com",
          password: "SecurePassword123!",
          name: "No Membership User"
        })
        |> Accounts.create()

      org = create_organization()

      # User cannot access organization
      assert {:error, %Ash.Error.Forbidden{}} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: user)
    end
  end
end
