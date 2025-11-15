defmodule PilatesOnPhx.Studios.Room do
  @moduledoc """
  Represents a room within a studio in the PilatesOnPhx platform.

  Rooms are physical spaces within a studio where classes are held. Each room
  has a capacity and can have equipment assigned to it.

  ## Attributes

  - `:name` - Room name (e.g., "Studio A", "Reformer Room")
  - `:capacity` - Maximum number of people the room can hold (default: 12)
  - `:settings` - JSON map for room-specific settings (floor type, mirrors, amenities)
  - `:active` - Whether the room is currently active

  ## Relationships

  - `belongs_to :studio` - The studio where this room is located
  - `has_many :equipment` - Equipment located in this room

  ## Authorization

  - Organization members can read rooms
  - Organization owners can create/update/deactivate rooms
  - Multi-tenant isolation enforced via studio's organization

  ## Business Rules

  - Capacity must be between 1 and 100
  - Room names should be unique within a studio (business logic, not enforced by DB)
  - Settings can store physical attributes, amenities, accessibility features
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Studios,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "rooms"
    repo PilatesOnPhx.Repo

    references do
      reference :studio, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true

      constraints min_length: 1,
                  max_length: 255,
                  trim?: true
    end

    attribute :capacity, :integer do
      allow_nil? false
      default 12
      public? true

      constraints min: 1, max: 100
    end

    attribute :settings, :map do
      allow_nil? false
      default %{}
      public? true
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

    has_many :equipment, PilatesOnPhx.Studios.Equipment do
      destination_attribute :room_id
    end
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name, :capacity, :settings, :active, :studio_id]
    end

    destroy :destroy do
      primary? true
      require_atomic? false
    end

    update :update do
      accept [:name, :capacity, :settings, :active]
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
    # Filter rooms to only those in studios within organizations the actor is a member of
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
              case Ash.load(actor, :memberships) do
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
          # If actor has no organizations, they can't see any rooms
          Ash.Query.filter(query, false)
        else
          # Filter to rooms in studios belonging to actor's organizations
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
      # Members can read rooms in their organization (filtering done in preparations)
      authorize_if actor_present()
    end

    policy action_type(:create) do
      # Organization owners can create rooms
      authorize_if expr(
                     exists(
                       studio.organization.memberships,
                       user_id == ^actor(:id) and role == :owner
                     )
                   )
    end

    policy action_type([:update, :destroy]) do
      # Organization owners can manage rooms
      authorize_if expr(
                     exists(
                       studio.organization.memberships,
                       user_id == ^actor(:id) and role == :owner
                     )
                   )
    end
  end

  code_interface do
    define :create
    define :read
    define :update
    define :activate
    define :deactivate
    define :destroy
  end
end
