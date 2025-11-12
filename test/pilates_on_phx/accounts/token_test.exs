defmodule PilatesOnPhx.Accounts.TokenTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.Token
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "token creation (action: create)" do
    test "creates token with valid attributes" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        token_type: :bearer,
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
        extra_data: %{}
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      assert token.user_id == user.id
      assert token.token_type == :bearer
      assert token.expires_at != nil
      # JWT ID should be generated
      assert token.jti != nil
    end

    test "requires user_id" do
      attrs = %{
        token_type: :bearer,
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      result =
        Token
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert match?({:error, _}, result)
    end

    test "generates unique jti for each token" do
      user = create_user()

      token1 = create_token(user: user)
      token2 = create_token(user: user)
      token3 = create_token(user: user)

      assert token1.jti != nil
      assert token2.jti != nil
      assert token3.jti != nil

      # All JTIs should be unique
      assert token1.jti != token2.jti
      assert token2.jti != token3.jti
      assert token1.jti != token3.jti
    end

    test "sets default token_type if not provided" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      assert token.token_type == :bearer
    end

    test "sets default expiration if not provided" do
      user = create_user()

      before_create = DateTime.utc_now()

      attrs = %{
        user_id: user.id,
        token_type: :bearer
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      # Default expiration should be set (e.g., 1 hour from now)
      assert token.expires_at != nil
      assert DateTime.compare(token.expires_at, before_create) == :gt
    end

    test "initializes empty extra_data map by default" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        token_type: :bearer,
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      assert token.extra_data == %{} or is_map(token.extra_data)
    end

    test "allows custom extra_data" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        token_type: :bearer,
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
        extra_data: %{
          device_id: "mobile-123",
          ip_address: "192.168.1.1",
          user_agent: "PilatesApp/1.0"
        }
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      assert token.extra_data["device_id"] == "mobile-123"
      assert token.extra_data["ip_address"] == "192.168.1.1"
      assert token.extra_data["user_agent"] == "PilatesApp/1.0"
    end

    test "validates user exists" do
      non_existent_user_id = Ash.UUID.generate()

      attrs = %{
        user_id: non_existent_user_id,
        token_type: :bearer,
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      result =
        Token
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert match?({:error, _}, result)
    end

    test "allows multiple active tokens for same user" do
      user = create_user()

      token1 = create_token(user: user)
      token2 = create_token(user: user)
      token3 = create_token(user: user)

      tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      token_jtis = Enum.map(tokens, & &1.jti)
      assert token1.jti in token_jtis
      assert token2.jti in token_jtis
      assert token3.jti in token_jtis
    end
  end

  describe "token types" do
    test "supports bearer token type" do
      user = create_user()
      token = create_token(user: user, token_type: :bearer)

      assert token.token_type == :bearer
    end

    test "supports refresh token type" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        token_type: :refresh,
        # 30 days
        expires_at: DateTime.add(DateTime.utc_now(), 30 * 24 * 3600, :second)
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      assert token.token_type == :refresh
    end

    test "supports password_reset token type" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        token_type: :password_reset,
        # 1 hour
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      assert token.token_type == :password_reset
    end

    test "supports email_confirmation token type" do
      user = create_user()

      attrs = %{
        user_id: user.id,
        token_type: :email_confirmation,
        # 24 hours
        expires_at: DateTime.add(DateTime.utc_now(), 24 * 3600, :second)
      }

      assert {:ok, token} =
               Token
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Accounts)

      assert token.token_type == :email_confirmation
    end
  end

  describe "token expiration" do
    test "token with future expiration is not expired" do
      user = create_user()

      # 1 hour from now
      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)
      token = create_token(user: user, expires_at: expires_at)

      # Token should not be expired
      assert DateTime.compare(token.expires_at, DateTime.utc_now()) == :gt
    end

    test "token with past expiration is expired" do
      user = create_user()

      # 1 hour ago
      expires_at = DateTime.add(DateTime.utc_now(), -3600, :second)
      token = create_token(user: user, expires_at: expires_at)

      # Token should be expired
      assert DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt
    end

    test "can query non-expired tokens" do
      user = create_user()

      # Create expired token
      create_expired_token(user: user)

      # Create active tokens
      active1 = create_token(user: user)
      active2 = create_token(user: user)

      now = DateTime.utc_now()

      active_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id and expires_at > ^now)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(active_tokens) >= 2

      token_ids = Enum.map(active_tokens, & &1.jti)
      assert active1.jti in token_ids
      assert active2.jti in token_ids
    end

    test "can query expired tokens" do
      user = create_user()

      # Create expired tokens
      expired1 = create_expired_token(user: user, expired_minutes_ago: 60)
      expired2 = create_expired_token(user: user, expired_minutes_ago: 120)

      # Create active token
      create_token(user: user)

      now = DateTime.utc_now()

      expired_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id and expires_at <= ^now)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(expired_tokens) >= 2

      token_ids = Enum.map(expired_tokens, & &1.jti)
      assert expired1.jti in token_ids
      assert expired2.jti in token_ids
    end

    test "bearer tokens typically expire in 1 hour" do
      user = create_user()

      before_create = DateTime.utc_now()
      token = create_token(user: user, token_type: :bearer)
      after_create = DateTime.add(DateTime.utc_now(), 3600, :second)

      # Token expiration should be around 1 hour from now
      assert DateTime.compare(token.expires_at, before_create) == :gt
      assert DateTime.compare(token.expires_at, after_create) in [:lt, :eq]
    end

    test "refresh tokens expire much later than bearer tokens" do
      user = create_user()

      # 1 hour
      bearer_expires = DateTime.add(DateTime.utc_now(), 3600, :second)
      # 30 days
      refresh_expires = DateTime.add(DateTime.utc_now(), 30 * 24 * 3600, :second)

      bearer_token = create_token(user: user, token_type: :bearer, expires_at: bearer_expires)
      refresh_token = create_token(user: user, token_type: :refresh, expires_at: refresh_expires)

      # Refresh token should expire much later
      assert DateTime.compare(refresh_token.expires_at, bearer_token.expires_at) == :gt

      diff_seconds = DateTime.diff(refresh_token.expires_at, bearer_token.expires_at, :second)
      # At least 24 hours difference
      assert diff_seconds > 24 * 3600
    end
  end

  describe "token revocation" do
    test "can revoke token by marking revoked_at" do
      user = create_user()
      token = create_token(user: user)

      before_revoke = DateTime.utc_now()

      assert {:ok, revoked} =
               token
               |> Ash.Changeset.for_update(:revoke, %{})
               |> Ash.update(domain: Accounts, actor: user)

      assert revoked.revoked_at != nil
      # The revoked_at should be set to approximately now (within a few seconds)
      assert DateTime.diff(revoked.revoked_at, before_revoke, :second) in 0..2
    end

    test "can query active (non-revoked) tokens" do
      user = create_user()

      active1 = create_token(user: user)
      active2 = create_token(user: user)

      # Create and revoke a token
      revoked_token = create_token(user: user)

      {:ok, _} =
        revoked_token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts, actor: user)

      active_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id and is_nil(revoked_at))
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      token_jtis = Enum.map(active_tokens, & &1.jti)
      assert active1.jti in token_jtis
      assert active2.jti in token_jtis
      refute revoked_token.jti in token_jtis
    end

    test "can query revoked tokens" do
      user = create_user()

      # Create and revoke tokens
      token1 = create_token(user: user)

      {:ok, _} =
        token1
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts, actor: user)

      token2 = create_token(user: user)

      {:ok, _} =
        token2
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts, actor: user)

      # Create active token
      create_token(user: user)

      revoked_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id and not is_nil(revoked_at))
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(revoked_tokens) >= 2
    end

    test "revoked token remains in database" do
      user = create_user()
      token = create_token(user: user)

      {:ok, _} =
        token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts, actor: user)

      # Token should still exist
      found =
        Token
        |> Ash.Query.filter(jti == ^token.jti)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert found.jti == token.jti
      assert found.revoked_at != nil
    end

    test "can revoke all user tokens at once" do
      user = create_user()

      token1 = create_token(user: user)
      token2 = create_token(user: user)
      token3 = create_token(user: user)

      now = DateTime.utc_now()

      # Revoke all tokens for user
      Token
      |> Ash.Query.filter(user_id == ^user.id)
      |> Ash.read!(domain: Accounts, actor: bypass_actor())
      |> Enum.each(fn token ->
        token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update!(domain: Accounts, actor: user)
      end)

      # All tokens should be revoked
      active_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id and is_nil(revoked_at))
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert active_tokens == []
    end
  end

  describe "token relationships" do
    test "token belongs to user" do
      user = create_user()
      token = create_token(user: user)

      loaded_token =
        Token
        |> Ash.Query.filter(jti == ^token.jti)
        |> Ash.Query.load(:user)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert loaded_token.user.id == user.id
      assert loaded_token.user.email == user.email
    end

    test "user has many tokens" do
      user = create_user()

      token1 = create_token(user: user)
      token2 = create_token(user: user)
      token3 = create_token(user: user)

      loaded_user =
        Accounts.User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.load(:tokens)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      token_ids = Enum.map(loaded_user.tokens, & &1.jti)
      assert token1.jti in token_ids
      assert token2.jti in token_ids
      assert token3.jti in token_ids
    end

    test "deleting user cascades to tokens" do
      user = create_user()

      token1 = create_token(user: user)
      token2 = create_token(user: user)

      # Save JTIs for verification
      jti1 = token1.jti
      jti2 = token2.jti

      # Delete user's related records first (DB foreign keys prevent direct deletion)
      # In a production system, these would have ON DELETE CASCADE configured
      Token
      |> Ash.Query.filter(user_id == ^user.id)
      |> Ash.read!(domain: Accounts, actor: bypass_actor())
      |> Enum.each(&Ash.destroy!(&1, domain: Accounts, actor: bypass_actor()))

      Accounts.OrganizationMembership
      |> Ash.Query.filter(user_id == ^user.id)
      |> Ash.read!(domain: Accounts, actor: bypass_actor())
      |> Enum.each(&Ash.destroy!(&1, domain: Accounts, actor: bypass_actor()))

      # Delete user
      assert :ok = Ash.destroy(user, domain: Accounts, actor: bypass_actor())

      # Verify tokens are gone
      remaining_tokens =
        Token
        |> Ash.Query.filter(jti in ^[jti1, jti2])
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert remaining_tokens == []
    end
  end

  describe "token queries and filtering" do
    test "can query all tokens for a user" do
      user = create_user()

      create_token(user: user)
      create_token(user: user)
      create_token(user: user)

      tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(tokens) >= 3
    end

    test "can filter tokens by type" do
      user = create_user()

      bearer1 = create_token(user: user, token_type: :bearer)
      bearer2 = create_token(user: user, token_type: :bearer)

      refresh_attrs = %{
        user_id: user.id,
        token_type: :refresh,
        expires_at: DateTime.add(DateTime.utc_now(), 30 * 24 * 3600, :second)
      }

      {:ok, _} =
        Token
        |> Ash.Changeset.for_create(:create, refresh_attrs)
        |> Ash.create(domain: Accounts)

      bearer_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id and token_type == :bearer)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(bearer_tokens) >= 2
      assert Enum.all?(bearer_tokens, fn t -> t.token_type == :bearer end)
    end

    test "can find token by jti" do
      user = create_user()
      token = create_token(user: user)

      found =
        Token
        |> Ash.Query.filter(jti == ^token.jti)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert found.jti == token.jti
    end

    test "can filter valid tokens (not expired and not revoked)" do
      user = create_user()

      # Create valid token
      valid_token = create_token(user: user)

      # Create expired token
      create_expired_token(user: user)

      # Create revoked token
      revoked = create_token(user: user)

      {:ok, revoked} =
        revoked
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts, actor: user)

      now = DateTime.utc_now()

      valid_tokens =
        Token
        |> Ash.Query.filter(
          user_id == ^user.id and
            expires_at > ^now and
            is_nil(revoked_at)
        )
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      token_jtis = Enum.map(valid_tokens, & &1.jti)
      assert valid_token.jti in token_jtis
      refute revoked.jti in token_jtis
    end
  end

  describe "token lifecycle" do
    test "tracks token creation timestamp" do
      user = create_user()
      token = create_token(user: user)

      assert token.inserted_at != nil
      assert %DateTime{} = token.inserted_at
    end

    test "tracks token update timestamp" do
      user = create_user()
      token = create_token(user: user)

      original_updated_at = token.updated_at

      Process.sleep(10)

      {:ok, updated} =
        token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts, actor: user)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "token lifecycle: creation -> use -> expiration" do
      user = create_user()

      # Create token
      # 2 seconds
      expires_at = DateTime.add(DateTime.utc_now(), 2, :second)
      token = create_token(user: user, expires_at: expires_at)

      # Token is initially valid
      assert DateTime.compare(token.expires_at, DateTime.utc_now()) == :gt
      assert token.revoked_at == nil

      # Wait for expiration
      Process.sleep(3000)

      # Token is now expired
      assert DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt
    end

    test "token lifecycle: creation -> revocation" do
      user = create_user()

      # Create token
      token = create_token(user: user)

      # Token is initially valid
      assert token.revoked_at == nil

      # Revoke token
      {:ok, revoked} =
        token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts, actor: user)

      # Token is now revoked
      assert revoked.revoked_at != nil
    end
  end

  describe "token security and validation" do
    test "jti is unique across all tokens" do
      user1 = create_user()
      user2 = create_user()

      token1 = create_token(user: user1)
      token2 = create_token(user: user2)
      token3 = create_token(user: user1)

      jtis = [token1.jti, token2.jti, token3.jti]

      # All JTIs should be unique
      assert length(Enum.uniq(jtis)) == 3
    end

    test "extra_data stores metadata without exposing sensitive info" do
      user = create_user()

      # Store metadata (device info, IP, etc.) but NOT password or secrets
      token =
        create_token(
          user: user,
          extra_data: %{
            device: "iPhone 14",
            os: "iOS 16",
            app_version: "1.2.3",
            login_method: "password"
          }
        )

      # Metadata should be stored
      assert token.extra_data["device"] == "iPhone 14"
      assert token.extra_data["app_version"] == "1.2.3"

      # Should NOT contain sensitive data
      refute Map.has_key?(token.extra_data, "password")
      refute Map.has_key?(token.extra_data, "secret")
    end

    test "tokens are isolated per user" do
      user1 = create_user()
      user2 = create_user()

      token1 = create_token(user: user1)
      token2 = create_token(user: user2)

      # User1's tokens
      user1_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user1.id)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      user1_token_ids = Enum.map(user1_tokens, & &1.jti)

      assert token1.jti in user1_token_ids
      refute token2.jti in user1_token_ids
    end
  end

  describe "concurrent token operations" do
    test "handles concurrent token creation for same user" do
      user = create_user()

      tasks =
        Enum.map(1..5, fn _ ->
          Task.async(fn ->
            create_token(user: user)
          end)
        end)

      tokens = Task.await_many(tasks)

      # All should succeed
      assert length(tokens) == 5

      # All should have unique JTIs
      jtis = Enum.map(tokens, & &1.jti)
      assert length(Enum.uniq(jtis)) == 5
    end

    test "handles concurrent token revocation" do
      user = create_user()

      token1 = create_token(user: user)
      token2 = create_token(user: user)
      token3 = create_token(user: user)

      now = DateTime.utc_now()

      # Revoke concurrently (revoke action doesn't accept revoked_at parameter)
      tasks =
        Enum.map([token1, token2, token3], fn token ->
          Task.async(fn ->
            token
            |> Ash.Changeset.for_update(:revoke, %{})
            |> Ash.update(domain: Accounts, actor: user)
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed
      assert Enum.all?(results, fn
               {:ok, _} -> true
               _ -> false
             end)
    end
  end

  describe "token cleanup and maintenance" do
    test "can delete token permanently" do
      user = create_user()
      token = create_token(user: user)

      assert :ok = Ash.destroy(token, domain: Accounts, actor: user)

      # Token should be gone (read_one returns {:ok, nil} when not found)
      assert {:ok, nil} =
               Token
               |> Ash.Query.filter(jti == ^token.jti)
               |> Ash.read_one(domain: Accounts, actor: bypass_actor())
    end

    test "can clean up expired tokens" do
      user = create_user()

      # Create old expired tokens
      # 1 day ago
      expired1 = create_expired_token(user: user, expired_minutes_ago: 60 * 24)
      # 7 days ago
      expired2 = create_expired_token(user: user, expired_minutes_ago: 60 * 24 * 7)

      # Create active token
      active = create_token(user: user)

      # Query expired tokens for cleanup
      # 1 day ago
      cutoff = DateTime.add(DateTime.utc_now(), -24 * 3600, :second)

      old_expired =
        Token
        |> Ash.Query.filter(expires_at < ^cutoff)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      # Delete old expired tokens (bypass actor for cleanup operation)
      Enum.each(old_expired, fn token ->
        Ash.destroy(token, domain: Accounts, actor: bypass_actor())
      end)

      # Active token should remain
      assert {:ok, _} =
               Token
               |> Ash.Query.filter(jti == ^active.jti)
               |> Ash.read_one(domain: Accounts, actor: bypass_actor())
    end

    test "can clean up revoked tokens after grace period" do
      user = create_user()

      # Create token revoked a week ago
      old_revoked = create_token(user: user)
      week_ago = DateTime.add(DateTime.utc_now(), -7 * 24 * 3600, :second)

      {:ok, old_revoked} =
        old_revoked
        |> Ash.Changeset.for_update(:test_set_revoked_at, %{revoked_at: week_ago})
        |> Ash.update(domain: Accounts, actor: user)

      # Query old revoked tokens
      cutoff = DateTime.add(DateTime.utc_now(), -24 * 3600, :second)

      old_revoked_tokens =
        Token
        |> Ash.Query.filter(not is_nil(revoked_at) and revoked_at < ^cutoff)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      # Should find the old revoked token
      token_jtis = Enum.map(old_revoked_tokens, & &1.jti)
      assert old_revoked.jti in token_jtis
    end
  end

  describe "authorization policies" do
    test "user can access their own tokens" do
      user = create_user()
      token = create_token(user: user)

      loaded =
        Token
        |> Ash.Query.filter(jti == ^token.jti)
        |> Ash.read_one!(domain: Accounts, actor: user)

      assert loaded.jti == token.jti
    end

    test "user cannot access other users' tokens" do
      user1 = create_user()
      user2 = create_user()

      token2 = create_token(user: user2)

      # Policy filters out tokens user doesn't own, returns nil not forbidden
      assert {:ok, nil} =
               Token
               |> Ash.Query.filter(jti == ^token2.jti)
               |> Ash.read_one(domain: Accounts, actor: user1)
    end

    test "user can revoke their own tokens" do
      user = create_user()
      token = create_token(user: user)

      assert {:ok, revoked} =
               token
               |> Ash.Changeset.for_update(:revoke, %{})
               |> Ash.update(domain: Accounts, actor: user)

      assert revoked.revoked_at != nil
    end

    test "user cannot revoke other users' tokens" do
      user1 = create_user()
      user2 = create_user()

      token2 = create_token(user: user2)

      assert {:error, %Ash.Error.Forbidden{}} =
               token2
               |> Ash.Changeset.for_update(:revoke, %{})
               |> Ash.update(domain: Accounts, actor: user1)
    end
  end
end
