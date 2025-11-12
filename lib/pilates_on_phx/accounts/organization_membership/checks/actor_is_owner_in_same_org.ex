defmodule PilatesOnPhx.Accounts.OrganizationMembership.Checks.ActorIsOwnerInSameOrg do
  @moduledoc """
  Policy check to verify if the actor is an owner in the same organization as the membership being updated.

  NOTE: This check currently doesn't work correctly due to Ash policy evaluation timing.
  The actor's memberships list needs to be loaded before policy evaluation, but this
  happens after policies are checked in some scenarios.

  This is a known limitation affecting 2 tests:
  - "owner can manage organization memberships"
  - "only owner can update member roles"
  """
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "actor is owner in same organization"
  end

  @impl true
  def match?(nil, _context, _opts), do: false
  def match?(_actor, %{data: nil}, _opts), do: false

  def match?(actor, %{data: membership}, _opts) when is_map(actor) and is_map(membership) do
    # Check if actor has loaded memberships
    case Map.get(actor, :memberships) do
      nil -> false
      %Ash.NotLoaded{} -> false

      memberships when is_list(memberships) ->
        # Check if actor has an owner membership in the same organization
        Enum.any?(memberships, fn m ->
          m.organization_id == membership.organization_id and m.role == :owner
        end)

      _ -> false
    end
  end

  def match?(_actor, _context, _opts), do: false
end
