defmodule PilatesOnPhx.Accounts.User.Checks.OwnerInSameOrgTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.User.Checks.OwnerInSameOrg

  require Ash.Query

  describe "describe/1" do
    test "returns human-readable description" do
      assert OwnerInSameOrg.describe([]) == "owner in same organization"
    end
  end

  describe "match?/3" do
    setup do
      # Create organizations
      {:ok, org1} =
        Accounts.Organization
        |> Ash.Changeset.for_create(:create, %{name: "Org 1"})
        |> Ash.create()

      {:ok, org2} =
        Accounts.Organization
        |> Ash.Changeset.for_create(:create, %{name: "Org 2"})
        |> Ash.create()

      # Create users
      {:ok, owner_user} =
        Accounts.User
        |> Ash.Changeset.for_create(:create, %{
          email: "owner@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })
        |> Ash.create()

      {:ok, member_user} =
        Accounts.User
        |> Ash.Changeset.for_create(:create, %{
          email: "member@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })
        |> Ash.create()

      {:ok, other_user} =
        Accounts.User
        |> Ash.Changeset.for_create(:create, %{
          email: "other@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })
        |> Ash.create()

      # Create memberships
      {:ok, _owner_membership} =
        Accounts.OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          organization_id: org1.id,
          user_id: owner_user.id,
          role: :owner
        })
        |> Ash.create()

      {:ok, _member_membership} =
        Accounts.OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          organization_id: org1.id,
          user_id: member_user.id,
          role: :member
        })
        |> Ash.create()

      {:ok, _other_membership} =
        Accounts.OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          organization_id: org2.id,
          user_id: other_user.id,
          role: :member
        })
        |> Ash.create()

      %{
        org1: org1,
        org2: org2,
        owner_user: owner_user,
        member_user: member_user,
        other_user: other_user
      }
    end

    test "returns false when actor is updating themselves", %{owner_user: actor} do
      context = %{resource: actor}
      refute OwnerInSameOrg.match?(actor, context, [])
    end

    test "returns true when actor is owner in same organization as target user", %{
      owner_user: actor,
      member_user: target_user
    } do
      # Load memberships for actor
      {:ok, actor_with_memberships} = Ash.load(actor, :memberships, domain: Accounts)

      context = %{resource: target_user}
      assert OwnerInSameOrg.match?(actor_with_memberships, context, [])
    end

    test "returns false when actor is not owner in target user's organization", %{
      member_user: actor,
      owner_user: target_user
    } do
      # Load memberships for actor
      {:ok, actor_with_memberships} = Ash.load(actor, :memberships, domain: Accounts)

      context = %{resource: target_user}
      refute OwnerInSameOrg.match?(actor_with_memberships, context, [])
    end

    test "returns false when actor and target user are in different organizations", %{
      owner_user: actor,
      other_user: target_user
    } do
      # Load memberships for actor
      {:ok, actor_with_memberships} = Ash.load(actor, :memberships, domain: Accounts)

      context = %{resource: target_user}
      refute OwnerInSameOrg.match?(actor_with_memberships, context, [])
    end

    test "handles actor with no memberships" do
      # Create a new user with no memberships
      {:ok, actor} =
        Accounts.User
        |> Ash.Changeset.for_create(:create, %{
          email: "nomemberships@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })
        |> Ash.create()

      {:ok, target} =
        Accounts.User
        |> Ash.Changeset.for_create(:create, %{
          email: "target@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })
        |> Ash.create()

      {:ok, actor_with_memberships} = Ash.load(actor, :memberships, domain: Accounts)
      context = %{resource: target}

      refute OwnerInSameOrg.match?(actor_with_memberships, context, [])
    end

    test "handles target user with no memberships", %{owner_user: actor} do
      # Create a new user with no memberships
      {:ok, target} =
        Accounts.User
        |> Ash.Changeset.for_create(:create, %{
          email: "target@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })
        |> Ash.create()

      {:ok, actor_with_memberships} = Ash.load(actor, :memberships, domain: Accounts)
      context = %{resource: target}

      refute OwnerInSameOrg.match?(actor_with_memberships, context, [])
    end

    test "handles actor with unloaded memberships", %{
      owner_user: actor,
      member_user: target_user
    } do
      # The check should load memberships automatically
      context = %{resource: target_user}
      assert OwnerInSameOrg.match?(actor, context, [])
    end

    test "handles target user with unloaded memberships", %{
      owner_user: actor,
      member_user: target_user
    } do
      # Load actor memberships but not target
      {:ok, actor_with_memberships} = Ash.load(actor, :memberships, domain: Accounts)

      context = %{resource: target_user}
      assert OwnerInSameOrg.match?(actor_with_memberships, context, [])
    end
  end
end
