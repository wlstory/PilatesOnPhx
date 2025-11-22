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
      check_owner_in_same_org(actor, user)
    end
  end

  defp check_owner_in_same_org(actor, user) do
    actor_memberships = get_memberships(actor)
    user_memberships = get_memberships(user)

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

  defp get_memberships(user) do
    case Map.get(user, :memberships) do
      %Ash.NotLoaded{} ->
        load_memberships(user)

      memberships when is_list(memberships) ->
        memberships

      _ ->
        []
    end
  end

  defp load_memberships(user) do
    case Ash.load(user, :memberships,
           domain: PilatesOnPhx.Accounts,
           authorize?: false
         ) do
      {:ok, loaded} -> loaded.memberships
      _ -> []
    end
  end
end
