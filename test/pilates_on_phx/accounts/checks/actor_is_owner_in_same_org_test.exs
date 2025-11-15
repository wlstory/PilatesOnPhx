defmodule PilatesOnPhx.Accounts.OrganizationMembership.Checks.ActorIsOwnerInSameOrgTest do
  use ExUnit.Case, async: true

  alias PilatesOnPhx.Accounts.OrganizationMembership.Checks.ActorIsOwnerInSameOrg

  describe "describe/1" do
    test "returns human-readable description" do
      assert ActorIsOwnerInSameOrg.describe([]) == "actor is owner in same organization"
    end
  end

  describe "match?/3" do
    test "returns false when actor is nil" do
      context = %{data: %{organization_id: 1}}
      refute ActorIsOwnerInSameOrg.match?(nil, context, [])
    end

    test "returns false when data is nil" do
      actor = %{id: 1}
      context = %{data: nil}
      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns false when actor has no memberships key" do
      actor = %{id: 1}
      membership = %{organization_id: 1, role: :member}
      context = %{data: membership}

      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns false when actor memberships are not loaded" do
      actor = %{id: 1, memberships: %Ash.NotLoaded{}}
      membership = %{organization_id: 1, role: :member}
      context = %{data: membership}

      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns false when actor has empty memberships list" do
      actor = %{id: 1, memberships: []}
      membership = %{organization_id: 1, role: :member}
      context = %{data: membership}

      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns false when actor has no owner membership in same organization" do
      actor = %{
        id: 1,
        memberships: [
          %{organization_id: 2, role: :owner},  # Different org
          %{organization_id: 1, role: :member}  # Same org but not owner
        ]
      }
      membership = %{organization_id: 1, role: :member}
      context = %{data: membership}

      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns true when actor is owner in same organization" do
      actor = %{
        id: 1,
        memberships: [
          %{organization_id: 1, role: :owner},
          %{organization_id: 2, role: :member}
        ]
      }
      membership = %{organization_id: 1, role: :member}
      context = %{data: membership}

      assert ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns true when actor has multiple owner memberships including target org" do
      actor = %{
        id: 1,
        memberships: [
          %{organization_id: 1, role: :owner},
          %{organization_id: 2, role: :owner},
          %{organization_id: 3, role: :member}
        ]
      }
      membership = %{organization_id: 2, role: :member}
      context = %{data: membership}

      assert ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns false when actor memberships is not a list" do
      actor = %{id: 1, memberships: "invalid"}
      membership = %{organization_id: 1, role: :member}
      context = %{data: membership}

      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns false when actor is not a map" do
      actor = "not a map"
      membership = %{organization_id: 1, role: :member}
      context = %{data: membership}

      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end

    test "returns false when membership is not a map" do
      actor = %{id: 1, memberships: []}
      context = %{data: "not a map"}

      refute ActorIsOwnerInSameOrg.match?(actor, context, [])
    end
  end
end
