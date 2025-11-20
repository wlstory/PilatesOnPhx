defmodule PilatesOnPhx.Studios.Room.Checks.ActorOwnsStudioOrganization do
  @moduledoc """
  Policy check to verify if the actor is an owner of the organization that owns the studio
  specified in the changeset.

  For create actions, checks the studio_id from the changeset arguments and verifies
  the actor is an owner of that studio's organization.
  """
  use Ash.Policy.SimpleCheck

  require Ash.Query

  @impl true
  def describe(_opts) do
    "actor owns the studio's organization"
  end

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, %{changeset: %Ash.Changeset{} = changeset}, _opts) when is_map(actor) do
    # Get studio_id from changeset arguments
    studio_id = Ash.Changeset.get_argument(changeset, :studio_id)

    if studio_id do
      # Load the studio with its organization and memberships
      case PilatesOnPhx.Studios.Studio
           |> Ash.Query.filter(id == ^studio_id)
           |> Ash.Query.load(organization: :memberships)
           |> Ash.read_one(domain: PilatesOnPhx.Studios) do
        {:ok, studio} when not is_nil(studio) ->
          # Check if actor is an owner in this studio's organization
          Enum.any?(studio.organization.memberships, fn m ->
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
