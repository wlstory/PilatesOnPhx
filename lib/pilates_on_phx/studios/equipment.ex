defmodule PilatesOnPhx.Studios.Equipment do
  @moduledoc """
  Represents equipment at a studio in the PilatesOnPhx platform.

  Equipment tracks physical items like reformers, chairs, cadillacs, and props.
  Equipment can be assigned to a specific room or marked as portable.

  ## Attributes

  - `:name` - Equipment name (e.g., "Reformer #1", "Mat #5")
  - `:equipment_type` - Type of equipment (e.g., "reformer", "chair", "cadillac", "mat")
  - `:serial_number` - Optional serial number for tracking
  - `:portable` - Whether equipment can be moved between rooms (default: false)
  - `:maintenance_notes` - Optional notes about maintenance history and schedules
  - `:active` - Whether the equipment is currently active

  ## Relationships

  - `belongs_to :studio` - The studio where this equipment is located
  - `belongs_to :room` - The room where equipment is assigned (optional for portable equipment)

  ## Authorization

  - Organization members can read equipment
  - Organization owners can create/update/deactivate equipment
  - Multi-tenant isolation enforced via studio's organization

  ## Business Rules

  - Non-portable equipment must be assigned to a room
  - Portable equipment can have room_id set to nil
  - Equipment types: reformer, cadillac, chair, barrel, mat, prop, springboard, or custom
  - Maintenance notes track service history and upcoming maintenance needs
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Studios,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "equipment"
    repo PilatesOnPhx.Repo

    references do
      reference :studio, on_delete: :delete
      reference :room, on_delete: :nilify
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

    attribute :equipment_type, :string do
      allow_nil? false
      public? true

      constraints min_length: 1,
                  max_length: 100,
                  trim?: true
    end

    attribute :serial_number, :string do
      allow_nil? true
      public? true

      constraints max_length: 255,
                  trim?: true
    end

    attribute :portable, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :maintenance_notes, :string do
      allow_nil? true
      public? true

      constraints max_length: 5000
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

    belongs_to :room, PilatesOnPhx.Studios.Room do
      allow_nil? true
      attribute_writable? true
    end
  end

  validations do
    # Validate that non-portable equipment has a room assigned
    validate fn changeset, _context ->
      portable = Ash.Changeset.get_attribute(changeset, :portable)
      room_id = Ash.Changeset.get_attribute(changeset, :room_id)

      cond do
        # If portable is true, room_id can be nil
        portable == true ->
          :ok

        # If portable is false or nil, room_id must be present
        portable == false && is_nil(room_id) ->
          {:error, field: :room_id, message: "non-portable equipment must be assigned to a room"}

        # All other cases are valid
        true ->
          :ok
      end
    end
  end

  actions do
    defaults [:read]

    create :create do
      accept [
        :name,
        :equipment_type,
        :serial_number,
        :portable,
        :maintenance_notes,
        :active,
        :studio_id,
        :room_id
      ]
    end

    destroy :destroy do
      primary? true
      require_atomic? false
    end

    update :update do
      accept [
        :name,
        :equipment_type,
        :serial_number,
        :portable,
        :maintenance_notes,
        :active,
        :room_id
      ]

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
    # Filter equipment to only those in studios within organizations the actor is a member of
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
          # If actor has no organizations, they can't see any equipment
          Ash.Query.filter(query, false)
        else
          # Filter to equipment in studios belonging to actor's organizations
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
      # Members can read equipment in their organization (filtering done in preparations)
      authorize_if actor_present()
    end

    policy action_type(:create) do
      # Organization owners can create equipment
      authorize_if expr(
                     exists(
                       studio.organization.memberships,
                       user_id == ^actor(:id) and role == :owner
                     )
                   )
    end

    policy action_type([:update, :destroy]) do
      # Organization owners can manage equipment
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
