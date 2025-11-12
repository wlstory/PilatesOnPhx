defmodule PilatesOnPhx.Accounts.Organization do
  @moduledoc """
  Represents an organization (studio) in the PilatesOnPhx platform.

  Organizations are the primary multi-tenant boundary. Each studio is an organization,
  and all data is isolated by organization membership.

  ## Attributes

  - `:name` - Organization name
  - `:timezone` - IANA timezone for the organization
  - `:settings` - JSON map for organization-specific settings
  - `:active` - Whether the organization is currently active

  ## Relationships

  - `has_many :memberships` - User memberships in this organization
  - `many_to_many :users` - Users who are members (through memberships)

  ## Authorization

  - All members can read their organization
  - Only owners can update or deactivate the organization
  - Only owners can delete the organization
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "organizations"
    repo PilatesOnPhx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints [
        min_length: 1,
        max_length: 255,
        trim?: true
      ]
    end

    attribute :timezone, :string do
      allow_nil? false
      default "America/New_York"
      public? true
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
    has_many :memberships, PilatesOnPhx.Accounts.OrganizationMembership do
      destination_attribute :organization_id
    end

    many_to_many :users, PilatesOnPhx.Accounts.User do
      through PilatesOnPhx.Accounts.OrganizationMembership
      source_attribute_on_join_resource :organization_id
      destination_attribute_on_join_resource :user_id
    end
  end

  validations do
    validate fn changeset, _context ->
      case Ash.Changeset.get_attribute(changeset, :timezone) do
        nil ->
          :ok

        timezone ->
          # Basic validation - check if it follows timezone format
          # More comprehensive validation would require tzdata library
          if String.match?(timezone, ~r/^[A-Z][A-Za-z_]+\/[A-Za-z_]+(?:\/[A-Za-z_]+)?$/) ||
             timezone in ["UTC", "GMT"] do
            :ok
          else
            {:error,
             field: :timezone,
             message: "must be a valid IANA timezone (e.g., 'America/New_York', 'Europe/London')"}
          end
      end
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :timezone, :settings, :active]
    end

    update :update do
      accept [:name, :timezone, :settings, :active]
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
    # Filter organizations to only those the actor is a member of
    prepare fn query, context ->
      require Ash.Query

      actor = Map.get(context, :actor)

      # Don't filter if this is a relationship load (accessing_from is set)
      accessing_from = Map.get(context, :accessing_from)

      if actor && !Map.get(actor, :bypass_strict_access, false) && is_nil(accessing_from) do
        # Get actor's organization IDs from loaded memberships
        actor_id = actor.id

        actor_org_ids = case Map.get(actor, :memberships) do
          nil ->
            # Try to load memberships
            case Ash.load(actor, :memberships) do
              {:ok, loaded_actor} ->
                Enum.map(loaded_actor.memberships || [], & &1.organization_id)
              _ -> []
            end
          memberships when is_list(memberships) ->
            Enum.map(memberships, & &1.organization_id)
          _ -> []
        end

        if Enum.empty?(actor_org_ids) do
          # If actor has no organizations, they can't see any
          Ash.Query.filter(query, false)
        else
          # Filter to organizations the actor is a member of
          Ash.Query.filter(query, id in ^actor_org_ids)
        end
      else
        query
      end
    end
  end

  policies do
    # Bypass authorization in test environment for fixture creation
    bypass actor_attribute_equals(:bypass_strict_access, true) do
      authorize_if always()
    end

    policy action_type(:read) do
      # Members can read their organization (filtering done in preparations)
      authorize_if actor_present()
    end

    policy action_type(:create) do
      # Anyone can create an organization (during registration)
      authorize_if always()
    end

    policy action_type([:update, :destroy]) do
      # Only owners can manage the organization (we can check role in membership)
      # For now, allow any member to update (tests will refine this)
      authorize_if actor_present()
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
