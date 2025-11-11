defmodule PilatesOnPhx.Accounts.OrganizationMembership do
  @moduledoc """
  Represents a user's membership in an organization.

  This resource establishes the many-to-many relationship between users and organizations,
  allowing users (especially instructors) to belong to multiple organizations.

  ## Attributes

  - `:role` - The user's role within the organization (:owner, :admin, :member)
  - `:joined_at` - When the user joined the organization

  ## Relationships

  - `belongs_to :user` - The user who is a member
  - `belongs_to :organization` - The organization they belong to

  ## Authorization

  - Users can read their own memberships
  - Organization owners can manage memberships in their organization
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organization_memberships"
    repo PilatesOnPhx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      allow_nil? false
      default :member
      constraints one_of: [:owner, :admin, :member]
      public? true
    end

    attribute :joined_at, :utc_datetime_usec do
      allow_nil? false
      default &DateTime.utc_now/0
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, PilatesOnPhx.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :organization, PilatesOnPhx.Accounts.Organization do
      allow_nil? false
      attribute_writable? true
    end
  end

  identities do
    identity :unique_user_organization, [:user_id, :organization_id]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:role, :joined_at]
      argument :user_id, :uuid, allow_nil?: false
      argument :organization_id, :uuid, allow_nil?: false

      change manage_relationship(:user_id, :user, type: :append_and_remove)
      change manage_relationship(:organization_id, :organization, type: :append_and_remove)
    end

    update :update do
      accept [:role]
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if actor_attribute_equals(:id, :user_id)
    end

    policy action_type(:create) do
      # Organization owners can add members
      authorize_if relates_to_actor_via([:organization, :memberships], expr(role == :owner))
    end

    policy action_type([:update, :destroy]) do
      # Organization owners can manage memberships
      authorize_if relates_to_actor_via([:organization, :memberships], expr(role == :owner))
    end

    policy action_type([:update, :destroy]) do
      # Users can remove their own memberships (except owners)
      authorize_if expr(actor_attribute_equals(:id, :user_id) and role != :owner)
    end
  end

  code_interface do
    define :create
    define :read
    define :update
    define :destroy
  end
end
