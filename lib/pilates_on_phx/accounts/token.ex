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
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table "tokens"
    repo PilatesOnPhx.Repo
  end

  token do
    # This configures the resource to work with AshAuthentication
  end

  attributes do
    uuid_primary_key :id

    attribute :jti, :string do
      allow_nil? false
      default &Ash.UUID.generate/0
      public? true
    end

    attribute :token_type, :string do
      allow_nil? false
      default "bearer"
      public? true
      constraints [
        one_of: ["bearer", "refresh", "password_reset", "email_confirmation"]
      ]
    end

    attribute :expires_at, :utc_datetime_usec do
      allow_nil? false
      public? true
      default fn ->
        DateTime.add(DateTime.utc_now(), 3600, :second)  # 1 hour default
      end
    end

    attribute :revoked_at, :utc_datetime_usec do
      allow_nil? true
      public? true
    end

    attribute :extra_data, :map do
      allow_nil? false
      default %{}
      public? true
    end

    # AshAuthentication.TokenResource adds these fields:
    # - subject (required by token resource)
    # - purpose (required by token resource)

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, PilatesOnPhx.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end
  end

  identities do
    identity :unique_jti, [:jti]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:token_type, :expires_at, :extra_data, :jti]
      argument :user_id, :uuid, allow_nil?: false

      change manage_relationship(:user_id, :user, type: :append_and_remove)
    end

    update :revoke do
      accept []
      change set_attribute(:revoked_at, &DateTime.utc_now/0)
    end
  end

  preparations do
    prepare build(load: [:user])
  end

  policies do
    policy action_type(:read) do
      # Users can only access their own tokens
      authorize_if actor_attribute_equals(:id, :user_id)
    end

    policy action_type(:create) do
      # System can create tokens (during authentication)
      authorize_if always()
    end

    policy action_type([:revoke, :destroy]) do
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
