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
    # Get organization_id from changeset arguments
    organization_id = Ash.Changeset.get_argument(changeset, :organization_id)

    if organization_id do
      # Load the organization and check if actor is an owner
      case PilatesOnPhx.Accounts.Organization
           |> Ash.Query.filter(id == ^organization_id)
           |> Ash.Query.load(:memberships)
           |> Ash.read_one(domain: PilatesOnPhx.Accounts) do
        {:ok, organization} when not is_nil(organization) ->
          # Check if actor is an owner in this organization
          Enum.any?(organization.memberships, fn m ->
            m.user_id == actor.id and m.role == :owner
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
