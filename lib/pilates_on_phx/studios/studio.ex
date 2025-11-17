defmodule PilatesOnPhx.Studios.Studio do
  @moduledoc """
  Represents a physical studio location in the PilatesOnPhx platform.

  Studios are physical locations where classes are held. Each studio belongs to an organization
  and can have multiple rooms, staff assignments, and equipment.

  ## Attributes

  - `:name` - Studio name (e.g., "Downtown Pilates")
  - `:address` - Physical address of the studio
  - `:timezone` - IANA timezone for scheduling (default: "America/New_York")
  - `:max_capacity` - Maximum total capacity across all rooms (default: 50)
  - `:operating_hours` - Map of day-of-week to hours (e.g., %{"mon" => "6:00-20:00"})
  - `:settings` - JSON map for studio-specific settings (wifi, parking, amenities)
  - `:active` - Whether the studio is currently active

  ## Relationships

  - `belongs_to :organization` - The organization that owns this studio
  - `has_many :staff_assignments` - Staff assigned to this studio
  - `has_many :rooms` - Rooms within this studio
  - `has_many :equipment` - Equipment at this studio

  ## Authorization

  - Organization members can read studios
  - Organization owners can create/update/deactivate studios
  - Multi-tenant isolation enforced via organization_id
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Studios,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "studios"
    repo PilatesOnPhx.Repo

    references do
      reference :organization, on_delete: :delete
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

    attribute :address, :string do
      allow_nil? false
      public? true

      constraints min_length: 1,
                  max_length: 500,
                  trim?: true
    end

    attribute :timezone, :string do
      allow_nil? false
      default "America/New_York"
      public? true
    end

    attribute :max_capacity, :integer do
      allow_nil? false
      default 50
      public? true

      constraints min: 1, max: 500
    end

    attribute :operating_hours, :map do
      allow_nil? false

      default %{
        "mon" => "6:00-20:00",
        "tue" => "6:00-20:00",
        "wed" => "6:00-20:00",
        "thu" => "6:00-20:00",
        "fri" => "6:00-20:00",
        "sat" => "8:00-18:00",
        "sun" => "8:00-16:00"
      }

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
    belongs_to :organization, PilatesOnPhx.Accounts.Organization do
      allow_nil? false
      attribute_writable? true
    end

    has_many :staff_assignments, PilatesOnPhx.Studios.StudioStaff do
      destination_attribute :studio_id
    end

    has_many :rooms, PilatesOnPhx.Studios.Room do
      destination_attribute :studio_id
    end

    has_many :equipment, PilatesOnPhx.Studios.Equipment do
      destination_attribute :studio_id
    end
  end

  validations do
    validate fn changeset, _context ->
      case Ash.Changeset.get_attribute(changeset, :timezone) do
        nil ->
          :ok

        timezone ->
          # Validate against a list of common IANA timezones
          valid_timezones = [
            "UTC",
            "GMT",
            # Americas
            "America/New_York",
            "America/Chicago",
            "America/Denver",
            "America/Los_Angeles",
            "America/Phoenix",
            "America/Anchorage",
            "America/Honolulu",
            "America/Toronto",
            "America/Vancouver",
            "America/Mexico_City",
            "America/Sao_Paulo",
            "America/Buenos_Aires",
            # Europe
            "Europe/London",
            "Europe/Paris",
            "Europe/Berlin",
            "Europe/Rome",
            "Europe/Madrid",
            "Europe/Amsterdam",
            "Europe/Brussels",
            "Europe/Vienna",
            "Europe/Stockholm",
            "Europe/Copenhagen",
            "Europe/Dublin",
            "Europe/Lisbon",
            "Europe/Athens",
            "Europe/Prague",
            "Europe/Warsaw",
            "Europe/Moscow",
            # Asia
            "Asia/Tokyo",
            "Asia/Seoul",
            "Asia/Shanghai",
            "Asia/Hong_Kong",
            "Asia/Singapore",
            "Asia/Bangkok",
            "Asia/Dubai",
            "Asia/Kolkata",
            "Asia/Jerusalem",
            "Asia/Tehran",
            # Pacific
            "Pacific/Auckland",
            "Pacific/Sydney",
            "Pacific/Melbourne",
            "Pacific/Fiji",
            "Pacific/Guam",
            # Australia
            "Australia/Sydney",
            "Australia/Melbourne",
            "Australia/Brisbane",
            "Australia/Perth",
            "Australia/Adelaide"
          ]

          if timezone in valid_timezones do
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
    defaults [:read]

    create :create do
      accept [
        :name,
        :address,
        :timezone,
        :max_capacity,
        :operating_hours,
        :settings,
        :active,
        :organization_id
      ]
    end

    destroy :destroy do
      primary? true
      require_atomic? false
    end

    update :update do
      accept [:name, :address, :timezone, :max_capacity, :operating_hours, :settings, :active]
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
    # Filter studios to only those in organizations the actor is a member of
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
          # If actor has no organizations, they can't see any studios
          Ash.Query.filter(query, false)
        else
          # Filter to studios in organizations the actor is a member of
          Ash.Query.filter(query, organization_id in ^actor_org_ids)
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
      # Members can read studios in their organization (filtering done in preparations)
      authorize_if actor_present()
    end

    policy action_type(:create) do
      # Organization owners can create studios
      # Verify the actor is an owner of the organization being assigned
      authorize_if expr(
                     exists(
                       organization.memberships,
                       user_id == ^actor(:id) and role == :owner
                     )
                   )
    end

    policy action_type([:update, :destroy]) do
      # Organization owners can manage studios
      authorize_if expr(
                     exists(
                       organization.memberships,
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
