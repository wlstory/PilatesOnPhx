defmodule PilatesOnPhx.Accounts.User.Checks.OwnerInSameOrgTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.User.Checks.OwnerInSameOrg
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "describe/1" do
    test "returns human-readable description" do
      assert OwnerInSameOrg.describe([]) == "owner in same organization"
    end
  end

  describe "match?/3" do
    setup do
      # Create two organizations
      org1 = create_organization(%{name: "Org 1"})
      org2 = create_organization(%{name: "Org 2"})

      # Create users - these will have one organization membership by default
      owner_user = create_user(%{email: "owner@example.com", organization: org1})
      member_user = create_user(%{email: "member@example.com", organization: org1})
      other_user = create_user(%{email: "other@example.com", organization: org2})

      # Update owner's membership to have owner role
      owner_membership =
        Accounts.OrganizationMembership
        |> Ash.Query.filter(user_id == ^owner_user.id and organization_id == ^org1.id)
        |> Ash.read_one!(domain: Accounts, authorize?: false)

      {:ok, _updated_membership} =
        owner_membership
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts, authorize?: false)

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
      # Create a new user and organization, then remove the membership
      org = create_organization()
      actor = create_user(%{email: "nomemberships@example.com", organization: org})

      # Delete the membership
      membership =
        Accounts.OrganizationMembership
        |> Ash.Query.filter(user_id == ^actor.id)
        |> Ash.read_one!(domain: Accounts, authorize?: false)

      Ash.destroy!(membership, domain: Accounts, authorize?: false)

      target = create_user(%{email: "target@example.com"})

      {:ok, actor_with_memberships} = Ash.load(actor, :memberships, domain: Accounts)
      context = %{resource: target}

      refute OwnerInSameOrg.match?(actor_with_memberships, context, [])
    end

    test "handles target user with no memberships", %{owner_user: actor} do
      # Create a new user and remove their membership
      org = create_organization()
      target = create_user(%{email: "target@example.com", organization: org})

      # Delete the membership
      membership =
        Accounts.OrganizationMembership
        |> Ash.Query.filter(user_id == ^target.id)
        |> Ash.read_one!(domain: Accounts, authorize?: false)

      Ash.destroy!(membership, domain: Accounts, authorize?: false)

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
