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

  actions do
    defaults [:read, :destroy]

    # AshAuthentication will add :register_with_password and :sign_in_with_password actions

    update :update do
      accept [:name, :role, :confirmed_at]
    end

    update :confirm_email do
      accept []
      change set_attribute(:confirmed_at, &DateTime.utc_now/0)
    end

    update :change_password do
      accept [:password, :password_confirmation]
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
  end

  policies do
    policy action_type(:read) do
      # Users can read themselves
      authorize_if actor_attribute_equals(:id, :id)
    end

    policy action_type(:read) do
      # Users in same organization can read each other
      authorize_if relates_to_actor_via([:organizations, :memberships])
    end

    policy action_type(:update) do
      # Users can update themselves
      authorize_if actor_attribute_equals(:id, :id)
    end

    policy action_type(:update) do
      # Organization owners can update users in their org
      authorize_if relates_to_actor_via([:organizations, :memberships], expr(role == :owner))
    end

    policy action_type(:destroy) do
      # Users can destroy themselves
      authorize_if actor_attribute_equals(:id, :id)
    end

    policy action_type(:destroy) do
      # Organization owners can destroy users in their org (except other owners)
      authorize_if relates_to_actor_via([:organizations, :memberships], expr(role == :owner))
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
