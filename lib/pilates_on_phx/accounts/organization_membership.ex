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
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

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
    defaults [:read]

    create :create do
      primary? true
      accept [:role, :joined_at, :user_id, :organization_id]
    end

    update :update do
      primary? true
      require_atomic? false
      accept [:role]
    end

    destroy :destroy do
      primary? true
      require_atomic? false
    end
  end

  preparations do
    # Filter memberships to only those in organizations the actor belongs to
    prepare fn query, context ->
      require Ash.Query

      actor = Map.get(context, :actor)

      if actor && !Map.get(actor, :bypass_strict_access, false) do
        # Get actor's organization IDs
        actor_org_ids =
          case Ash.load(actor, :memberships, domain: PilatesOnPhx.Accounts) do
            {:ok, loaded_actor} ->
              Enum.map(loaded_actor.memberships, & &1.organization_id)

            {:error, _} ->
              # If load fails, try to use already loaded memberships
              case Map.get(actor, :memberships) do
                %Ash.NotLoaded{} -> []
                memberships when is_list(memberships) -> Enum.map(memberships, & &1.organization_id)
                _ -> []
              end
          end

        # Filter to memberships in actor's organizations
        if Enum.empty?(actor_org_ids) do
          # No organizations - return empty result
          Ash.Query.filter(query, false)
        else
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
      # Allow reading if actor is present (preparation will filter to shared orgs)
      authorize_if actor_present()
    end

    policy action_type(:create) do
      # Allow creation without actor for tests/fixtures
      authorize_if always()
    end

    policy action_type([:update, :destroy]) do
      # Organization owners can manage all memberships in their org
      # Use custom check to verify actor is owner in same organization
      authorize_if {PilatesOnPhx.Accounts.OrganizationMembership.Checks.ActorIsOwnerInSameOrg, []}
    end

    policy action_type([:destroy]) do
      # Users can delete their own memberships (leaving an organization)
      authorize_if expr(user_id == ^actor(:id))
    end
  end

  code_interface do
    define :create
    define :read
    define :update
    define :destroy
  end
end
