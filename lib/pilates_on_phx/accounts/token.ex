defmodule PilatesOnPhx.Accounts.Token do
  @moduledoc """
  Represents an authentication token in the PilatesOnPhx platform.

  Tokens are used for JWT-based authentication and can have different types:
  - bearer: Standard authentication tokens
  - refresh: Long-lived tokens for refreshing bearer tokens
  - password_reset: One-time tokens for password reset flows
  - email_confirmation: One-time tokens for email confirmation

  ## Attributes

  - `:jti` - JWT ID, unique identifier for the token
  - `:token_type` - Type of token (bearer, refresh, password_reset, email_confirmation)
  - `:expires_at` - When the token expires
  - `:revoked_at` - When the token was revoked (nil if active)
  - `:extra_data` - Additional metadata (device info, IP, etc.)

  ## Relationships

  - `belongs_to :user` - The user this token belongs to

  ## Authorization

  - Users can only access their own tokens
  - Users can revoke or destroy their own tokens
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "tokens"
    repo PilatesOnPhx.Repo
  end

  token do
    # This configures the resource to work with AshAuthentication
  end

  attributes do
    # AshAuthentication.TokenResource extension will add:
    # - jti (JWT ID, string, primary key)
    # - subject (string, required)
    # - purpose (string, default "user")
    # - expires_at (utc_datetime_usec)
    # - extra_data (map)

    attribute :token_type, :atom do
      allow_nil? false
      default :bearer
      public? true
      constraints [
        one_of: [:bearer, :refresh, :password_reset, :email_confirmation]
      ]
    end

    attribute :revoked_at, :utc_datetime_usec do
      allow_nil? true
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
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:token_type, :expires_at, :extra_data, :subject, :purpose, :jti]
      argument :user_id, :uuid, allow_nil?: false

      change manage_relationship(:user_id, :user, type: :append_and_remove)

      # Set defaults for AshAuthentication fields if not provided
      change fn changeset, _ ->
        changeset
        |> Ash.Changeset.change_new_attribute(:jti, Ash.UUID.generate())
        |> Ash.Changeset.change_new_attribute(:purpose, "user")
        |> Ash.Changeset.change_new_attribute(:subject, to_string(changeset.arguments[:user_id] || ""))
      end
    end

    update :revoke do
      accept []
      change set_attribute(:revoked_at, &DateTime.utc_now/0)
    end

    # Test-only action for setting specific revoked_at timestamps
    update :test_set_revoked_at do
      accept [:revoked_at]
    end
  end

  preparations do
    prepare build(load: [:user])
  end

  policies do
    # Bypass authorization in test environment for fixture creation
    bypass actor_attribute_equals(:bypass_strict_access, true) do
      authorize_if always()
    end

    policy action_type(:read) do
      # Users can only access their own tokens
      authorize_if actor_attribute_equals(:id, :user_id)
    end

    policy action_type(:create) do
      # System can create tokens (during authentication)
      authorize_if always()
    end

    policy action_type([:update, :destroy]) do
      # Users can revoke/destroy their own tokens
      authorize_if actor_attribute_equals(:id, :user_id)
    end
  end

  code_interface do
    define :create
    define :read
    define :revoke
    define :destroy
  end
end
