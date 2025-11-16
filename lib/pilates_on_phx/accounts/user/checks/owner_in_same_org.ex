defmodule PilatesOnPhx.Accounts.User.Checks.OwnerInSameOrg do
  @moduledoc """
  Authorization check to verify if the actor is an owner in the same organization as the target user.

  This is a runtime-only check that cannot be converted to a filter.
  """

  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "owner in same organization"
  end

  @impl true
  def match?(actor, %{resource: user}, _opts) do
    require Ash.Query

    # Don't run this check if actor is updating themselves (covered by other policy)
    if actor.id == user.id do
      false
    else
      # Get actor's memberships - load with bypass to avoid auth recursion
      actor_memberships =
        case Map.get(actor, :memberships) do
          %Ash.NotLoaded{} ->
            case Ash.load(actor, :memberships,
                   domain: PilatesOnPhx.Accounts,
                   authorize?: false
                 ) do
              {:ok, loaded} -> loaded.memberships
              _ -> []
            end

          memberships when is_list(memberships) ->
            memberships

          _ ->
            []
        end

      # Get user's memberships - load with bypass to avoid auth recursion
      user_memberships =
        case Map.get(user, :memberships) do
          %Ash.NotLoaded{} ->
            case Ash.load(user, :memberships,
                   domain: PilatesOnPhx.Accounts,
                   authorize?: false
                 ) do
              {:ok, loaded} -> loaded.memberships
              _ -> []
            end

          memberships when is_list(memberships) ->
            memberships

          _ ->
            []
        end

      # Find shared organizations where actor is owner
      actor_owner_org_ids =
        actor_memberships
        |> Enum.filter(fn m -> m.role == :owner end)
        |> Enum.map(& &1.organization_id)

      user_org_ids = Enum.map(user_memberships, & &1.organization_id)

      # Check if there's any overlap
      not Enum.empty?(
        MapSet.intersection(MapSet.new(actor_owner_org_ids), MapSet.new(user_org_ids))
      )
    end
  end
end
