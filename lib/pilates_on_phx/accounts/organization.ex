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

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :timezone, :settings, :active]
    end

    update :update do
      accept [:name, :timezone, :settings, :active]
    end

    update :activate do
      accept []
      change set_attribute(:active, true)
    end

    update :deactivate do
      accept []
      change set_attribute(:active, false)
    end
  end

  policies do
    policy action_type(:read) do
      # Members can read their organization
      authorize_if relates_to_actor_via(:memberships)
    end

    policy action_type(:create) do
      # Anyone can create an organization (during registration)
      authorize_if always()
    end

    policy action_type([:update, :destroy]) do
      # Only owners can manage the organization
      authorize_if relates_to_actor_via(:memberships)
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
