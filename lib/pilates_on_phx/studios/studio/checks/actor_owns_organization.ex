defmodule PilatesOnPhx.Studios.Studio.Checks.ActorOwnsOrganization do
  @moduledoc """
  Policy check to verify if the actor is an owner of the organization specified in the changeset.

  For create actions, checks the organization_id from the changeset arguments.
  """
  use Ash.Policy.SimpleCheck

  require Ash.Query

  @impl true
  def describe(_opts) do
    "actor owns the organization"
  end

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, %{changeset: %Ash.Changeset{} = changeset}, _opts) when is_map(actor) do
    # Get organization_id from changeset attributes or arguments
    organization_id =
      Ash.Changeset.get_attribute(changeset, :organization_id) ||
        Ash.Changeset.get_argument(changeset, :organization_id)

    if organization_id do
      # Check if actor has a membership with owner role in this organization
      # Actor should have memberships loaded from UserAuth
      case Map.get(actor, :memberships) do
        memberships when is_list(memberships) ->
          Enum.any?(memberships, fn m ->
            m.organization_id == organization_id and m.role == :owner
          end)

        _ ->
          false
      end
    else
      false
    end
  end

  def match?(_actor, _context, _opts), do: false
end
