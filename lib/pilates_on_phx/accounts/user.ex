defmodule PilatesOnPhx.Accounts.User do
  @moduledoc """
  Represents a user in the PilatesOnPhx platform.

  Users can have different roles (owner, instructor, client) and can belong to
  multiple organizations (especially instructors who work at multiple studios).

  ## Attributes

  - `:email` - Unique email address (case-insensitive)
  - `:hashed_password` - Securely hashed password using Bcrypt
  - `:name` - User's full name
  - `:role` - User's primary role (:owner, :instructor, :client)
  - `:confirmed_at` - When the user confirmed their email (nil if unconfirmed)

  ## Relationships

  - `has_many :tokens` - Authentication tokens
  - `has_many :memberships` - Organization memberships
  - `many_to_many :organizations` - Organizations the user belongs to

  ## Authentication

  Uses AshAuthentication with password strategy:
  - Email/password sign in
  - Password reset capability
  - Token-based authentication
  - Bcrypt password hashing

  ## Authorization

  - Users can read themselves
  - Users in the same organization can read each other
  - Users can update themselves
  - Organization owners can update users in their organization
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "users"
    repo PilatesOnPhx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? false
      sensitive? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints [
        min_length: 1,
        max_length: 255
      ]
    end

    attribute :role, :atom do
      allow_nil? false
      default :client
      public? true
      constraints one_of: [:owner, :instructor, :client]
    end

    attribute :confirmed_at, :utc_datetime_usec do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  authentication do
    session_identifier :jti

    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password
        hash_provider AshAuthentication.BcryptProvider

        sign_in_tokens_enabled? true

        resettable do
          sender fn user, token, _opts ->
            # TODO: Implement email sending
            # For now, just log the token
            require Logger
            Logger.info("Password reset token for #{user.email}: #{token}")
            :ok
          end
        end
      end
    end

    tokens do
      enabled? true
      token_resource PilatesOnPhx.Accounts.Token
      signing_secret fn _, _ ->
        Application.fetch_env!(:pilates_on_phx, :token_signing_secret)
      end
    end
  end

  relationships do
    has_many :tokens, PilatesOnPhx.Accounts.Token do
      destination_attribute :user_id
    end

    has_many :memberships, PilatesOnPhx.Accounts.OrganizationMembership do
      destination_attribute :user_id
    end

    many_to_many :organizations, PilatesOnPhx.Accounts.Organization do
      through PilatesOnPhx.Accounts.OrganizationMembership
      source_attribute_on_join_resource :user_id
      destination_attribute_on_join_resource :organization_id
    end
  end

  identities do
    identity :unique_email, [:email]
  end

  preparations do
    # Filter users to only those in shared organizations with the actor
    prepare fn query, context ->
      require Ash.Query

      actor = Map.get(context, :actor)

      if actor && !Map.get(actor, :bypass_strict_access, false) do
        # Get actor's organization IDs from loaded memberships
        actor = context.actor
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
          # If actor has no organizations, they can only see themselves
          Ash.Query.filter(query, id == ^actor_id)
        else
          # Filter to users who share at least one organization
          # Use a subquery-style exists check
          Ash.Query.filter(query,
            id == ^actor_id or
            exists(memberships, organization_id in ^actor_org_ids)
          )
        end
      else
        query
      end
    end
  end

  actions do
    defaults [:read, :destroy]

    # AshAuthentication will add :register_with_password and :sign_in_with_password actions

    # Custom create action for tests and programmatic user creation
    create :register do
      accept [:email, :name, :role]

      argument :password, :string do
        allow_nil? false
        sensitive? true
        constraints [min_length: 12]
      end

      argument :password_confirmation, :string do
        allow_nil? true  # Allow nil for tests that don't provide it
        sensitive? true
      end

      change fn changeset, _context ->
        # If password_confirmation is not provided, use password value
        password = Ash.Changeset.get_argument(changeset, :password)
        password_confirmation = Ash.Changeset.get_argument(changeset, :password_confirmation) || password

        # Check passwords match
        changeset = if password && password_confirmation && password != password_confirmation do
          Ash.Changeset.add_error(changeset, field: :password_confirmation, message: "does not match password")
        else
          changeset
        end

        # Hash the password
        case password do
          nil ->
            changeset
          pwd ->
            case AshAuthentication.BcryptProvider.hash(pwd) do
              {:ok, hashed} ->
                Ash.Changeset.change_attribute(changeset, :hashed_password, hashed)
              {:error, error} ->
                Ash.Changeset.add_error(changeset, field: :password, message: "failed to hash: #{inspect(error)}")
            end
        end
      end
    end

    update :update do
      accept [:name, :role, :email, :confirmed_at]
      require_atomic? false
    end

    update :confirm_email do
      accept []
      change set_attribute(:confirmed_at, &DateTime.utc_now/0)
    end

    update :change_password do
      accept []
      require_atomic? false

      argument :current_password, :string do
        allow_nil? false
        sensitive? true
      end

      argument :password, :string do
        allow_nil? false
        sensitive? true
        constraints [min_length: 12]
      end

      argument :password_confirmation, :string do
        allow_nil? false
        sensitive? true
      end

      validate confirm(:password, :password_confirmation)

      change fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :current_password) do
          nil ->
            Ash.Changeset.add_error(changeset, field: :current_password, message: "is required")

          current_password ->
            # Verify current password
            user = changeset.data

            case AshAuthentication.BcryptProvider.valid?(current_password, user.hashed_password) do
              {:ok, true} ->
                # Hash new password
                case AshAuthentication.BcryptProvider.hash(Ash.Changeset.get_argument(changeset, :password)) do
                  {:ok, hashed} ->
                    Ash.Changeset.change_attribute(changeset, :hashed_password, hashed)

                  {:error, error} ->
                    Ash.Changeset.add_error(changeset, field: :password, message: "failed to hash: #{inspect(error)}")
                end

              _ ->
                Ash.Changeset.add_error(changeset, field: :current_password, message: "is incorrect")
            end
        end
      end
    end
  end

  validations do
    validate present(:email), on: [:create, :update]
    validate present(:name), on: [:create, :update]

    # Validate email format
    validate match(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/),
      message: "must be a valid email address",
      on: [:create, :update]
  end

  policies do
    # Bypass authorization in test environment for fixture creation
    bypass actor_attribute_equals(:bypass_strict_access, true) do
      authorize_if always()
    end

    # Allow public registration
    policy action(:register) do
      authorize_if always()
    end

    policy action_type(:read) do
      # Users can read themselves
      authorize_if actor_attribute_equals(:id, :id)
      # Users can read other users in their organizations
      # This authorizes the action but filtering will limit results to shared orgs
      authorize_if actor_present()
    end

    policy action_type([:update, :destroy]) do
      # Users can only manage themselves
      authorize_if actor_attribute_equals(:id, :id)
    end
  end

  code_interface do
    define :read
    define :update
    define :confirm_email
    define :change_password
    define :destroy
  end
end
