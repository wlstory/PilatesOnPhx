defmodule PilatesOnPhx.Studios.StudioStaff do
  @moduledoc """
  Represents a staff member's assignment to a studio in the PilatesOnPhx platform.

  StudioStaff is a join resource that connects users to studios with specific roles
  and permissions. A user can be assigned to multiple studios, and a studio can have
  multiple staff members.

  ## Attributes

  - `:role` - Staff role (:instructor, :front_desk, :manager)
  - `:permissions` - List of permission strings (e.g., ["teach", "view_schedule"])
  - `:notes` - Optional notes about this staff assignment
  - `:active` - Whether this assignment is currently active

  ## Relationships

  - `belongs_to :studio` - The studio where this person is assigned
  - `belongs_to :user` - The user who is assigned to the studio

  ## Authorization

  - Organization members can read staff assignments
  - Organization owners can create/update/deactivate staff assignments
  - Multi-tenant isolation enforced via studio's organization

  ## Business Rules

  - Each user can only be assigned to a studio once (unique constraint on studio_id + user_id)
  - User must be a member of the same organization as the studio
  - Role determines base permissions, but can be customized per assignment
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Studios,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "studio_staff"
    repo PilatesOnPhx.Repo

    references do
      reference :studio, on_delete: :delete
      reference :user, on_delete: :delete
    end

    custom_indexes do
      # Ensure a user can only be assigned to a studio once
      index [:studio_id, :user_id], unique: true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      allow_nil? false
      public? true

      constraints one_of: [:instructor, :front_desk, :manager]
    end

    attribute :permissions, {:array, :string} do
      allow_nil? false
      default []
      public? true
    end

    attribute :notes, :string do
      allow_nil? true
      public? true

      constraints max_length: 2000
    end

    attribute :active, :boolean do
      allow_nil? false
      default true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :studio, PilatesOnPhx.Studios.Studio do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :user, PilatesOnPhx.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end
  end

  validations do
    # Validate that user belongs to the same organization as the studio
    validate fn changeset, _context ->
      require Ash.Query

      studio_id = Ash.Changeset.get_attribute(changeset, :studio_id)
      user_id = Ash.Changeset.get_attribute(changeset, :user_id)

      # Skip validation if either ID is missing (will be caught by allow_nil? false)
      if is_nil(studio_id) || is_nil(user_id) do
        :ok
      else
        # Load studio with organization (bypass authorization for validation)
        case PilatesOnPhx.Studios.Studio
             |> Ash.Query.filter(id == ^studio_id)
             |> Ash.Query.load(:organization)
             |> Ash.read_one(domain: PilatesOnPhx.Studios, authorize?: false) do
          {:ok, nil} ->
            {:error, field: :studio_id, message: "studio not found"}

          {:ok, studio} ->
            studio_org_id = studio.organization_id

            # Load user's memberships (bypass authorization for validation)
            case PilatesOnPhx.Accounts.User
                 |> Ash.Query.filter(id == ^user_id)
                 |> Ash.Query.load(:memberships)
                 |> Ash.read_one(domain: PilatesOnPhx.Accounts, authorize?: false) do
              {:ok, nil} ->
                {:error, field: :user_id, message: "user not found"}

              {:ok, user} ->
                user_org_ids = Enum.map(user.memberships || [], & &1.organization_id)

                if studio_org_id in user_org_ids do
                  :ok
                else
                  {:error,
                   field: :user_id, message: "user must be a member of the studio's organization"}
                end

              {:error, _} ->
                {:error, field: :user_id, message: "could not verify user organization"}
            end

          {:error, _} ->
            {:error, field: :studio_id, message: "could not verify studio organization"}
        end
      end
    end
  end

  actions do
    defaults [:read]

    create :assign do
      accept [:studio_id, :user_id, :role, :permissions, :notes, :active]
    end

    destroy :destroy do
      primary? true
      require_atomic? false
    end

    update :update do
      accept [:role, :permissions, :notes, :active]
      require_atomic? false
    end

    update :activate do
      accept []
      change set_attribute(:active, true)
      require_atomic? false
    end

    update :deactivate do
      accept []
      change set_attribute(:active, false)
      require_atomic? false
    end
  end

  preparations do
    # Filter staff to only those in studios within organizations the actor is a member of
    prepare fn query, context ->
      require Ash.Query

      actor = Map.get(context, :actor)

      # Don't filter if this is a relationship load
      accessing_from = Map.get(context, :accessing_from)

      if actor && !Map.get(actor, :bypass_strict_access, false) && is_nil(accessing_from) do
        # Get actor's organization IDs from memberships
        actor_org_ids =
          case Map.get(actor, :memberships) do
            nil ->
              # Try to load memberships
              case Ash.load(actor, :memberships, domain: PilatesOnPhx.Accounts) do
                {:ok, loaded_actor} ->
                  Enum.map(loaded_actor.memberships || [], & &1.organization_id)

                _ ->
                  []
              end

            memberships when is_list(memberships) ->
              Enum.map(memberships, & &1.organization_id)

            _ ->
              []
          end

        if Enum.empty?(actor_org_ids) do
          # If actor has no organizations, they can't see any staff
          Ash.Query.filter(query, false)
        else
          # Filter to staff in studios belonging to actor's organizations
          Ash.Query.filter(query, studio.organization_id in ^actor_org_ids)
        end
      else
        query
      end
    end
  end

  policies do
    # Bypass authorization in test environment for fixture creation
    bypass expr(^actor(:bypass_strict_access) == true) do
      authorize_if always()
    end

    policy action_type(:read) do
      # Members can read staff in their organization (filtering done in preparations)
      authorize_if actor_present()
    end

    policy action_type(:create) do
      # Organization owners can assign staff
      authorize_if expr(
                     exists(
                       studio.organization.memberships,
                       user_id == ^actor(:id) and role == :owner
                     )
                   )
    end

    policy action_type([:update, :destroy]) do
      # Organization owners can manage staff assignments
      authorize_if expr(
                     exists(
                       studio.organization.memberships,
                       user_id == ^actor(:id) and role == :owner
                     )
                   )
    end
  end

  code_interface do
    define :assign
    define :read
    define :update
    define :activate
    define :deactivate
    define :destroy
  end
end
