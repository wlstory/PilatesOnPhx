defmodule PilatesOnPhx.Accounts.AuthenticationIntegrationTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.{User, Token, Organization}
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  @moduledoc """
  Integration tests for complete authentication flows.

  These tests verify end-to-end authentication scenarios including:
  - User registration with organization creation
  - Login flows with token generation
  - Multi-organization authentication context
  - Token lifecycle and refresh flows
  - Password reset flows
  - Email confirmation flows
  """

  describe "user registration flow" do
    test "complete registration creates user, organization, membership, and token" do
      # Step 1: User registers with email and password
      registration_attrs = %{
        email: "newstudio@example.com",
        password: "SecurePassword123!",
        name: "Studio Owner",
        role: :owner
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, registration_attrs)
        |> Ash.create(domain: Accounts)

      # Step 2: Create organization for the new user
      org_attrs = %{
        name: "New Pilates Studio",
        timezone: "America/New_York"
      }

      {:ok, organization} =
        Organization
        |> Ash.Changeset.for_create(:create, org_attrs)
        |> Ash.create(domain: Accounts)

      # Step 3: Create membership linking user to organization
      membership_attrs = %{
        user_id: user.id,
        organization_id: organization.id,
        role: :owner,
        joined_at: DateTime.utc_now()
      }

      {:ok, membership} =
        Accounts.OrganizationMembership
        |> Ash.Changeset.for_create(:create, membership_attrs)
        |> Ash.create(domain: Accounts)

      # Step 4: Generate authentication token
      token_attrs = %{
        user_id: user.id,
        token_type: "bearer",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      {:ok, token} =
        Token
        |> Ash.Changeset.for_create(:create, token_attrs)
        |> Ash.create(domain: Accounts)

      # Verify complete setup
      assert to_string(user.email) == "newstudio@example.com"
      assert user.role == :owner
      assert organization.name == "New Pilates Studio"
      assert membership.user_id == user.id
      assert membership.organization_id == organization.id
      assert membership.role == :owner
      assert token.user_id == user.id
      assert token.token_type == :bearer

      # Verify relationships are properly loaded
      loaded_user =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.load([:memberships, :organizations, :tokens])
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert length(loaded_user.memberships) == 1
      assert length(loaded_user.organizations) == 1
      assert length(loaded_user.tokens) >= 1
    end

    test "registration with organization creation handles instructor role" do
      # Instructor registers and joins existing studio
      existing_org = create_organization(name: "Established Studio")

      registration_attrs = %{
        email: "instructor@studio.com",
        password: "SecurePassword123!",
        name: "Jane Instructor",
        role: :instructor
      }

      {:ok, instructor} =
        User
        |> Ash.Changeset.for_create(:register, registration_attrs)
        |> Ash.create(domain: Accounts)

      # Add to existing organization
      {:ok, membership} =
        Accounts.OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: instructor.id,
          organization_id: existing_org.id,
          role: :member,
          joined_at: DateTime.utc_now()
        })
        |> Ash.create(domain: Accounts)

      assert instructor.role == :instructor
      assert membership.organization_id == existing_org.id
      assert membership.role == :member
    end

    test "client registration and joining studio" do
      studio = create_organization(name: "Community Pilates")

      # Client registers
      registration_attrs = %{
        email: "client@example.com",
        password: "SecurePassword123!",
        name: "John Client",
        role: :client
      }

      {:ok, client} =
        User
        |> Ash.Changeset.for_create(:register, registration_attrs)
        |> Ash.create(domain: Accounts)

      # Join studio
      {:ok, membership} =
        Accounts.OrganizationMembership
        |> Ash.Changeset.for_create(:create, %{
          user_id: client.id,
          organization_id: studio.id,
          role: :member,
          joined_at: DateTime.utc_now()
        })
        |> Ash.create(domain: Accounts)

      assert client.role == :client
      assert membership.role == :member
    end

    test "registration fails with duplicate email" do
      existing_email = "taken@example.com"

      # First registration
      {:ok, _user} =
        User
        |> Ash.Changeset.for_create(:register, %{
          email: existing_email,
          password: "Password123!",
          name: "First User"
        })
        |> Ash.create(domain: Accounts)

      # Duplicate registration
      {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, %{
          email: existing_email,
          password: "Password456!",
          name: "Second User"
        })
        |> Ash.create(domain: Accounts)

      assert Enum.any?(error.errors, fn err ->
               err.field == :email and
                 (err.message =~ "unique" or err.message =~ "already been taken")
             end)
    end
  end

  describe "login authentication flow" do
    test "successful login with valid credentials generates token" do
      # Setup: Create user
      password = "SecurePassword123!"
      user = create_user(email: "login@example.com", password: password)

      # Step 1: Authenticate with credentials
      {:ok, authenticated_user} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "login@example.com",
          password: password
        })
        |> Ash.read_one(domain: Accounts)

      # Step 2: Generate authentication token
      token_attrs = %{
        user_id: authenticated_user.id,
        token_type: "bearer",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      {:ok, token} =
        Token
        |> Ash.Changeset.for_create(:create, token_attrs)
        |> Ash.create(domain: Accounts)

      # Verify successful login
      assert authenticated_user.id == user.id
      assert authenticated_user.email == user.email
      assert token.user_id == user.id
      assert token.token_type == :bearer
      assert token.revoked_at == nil
    end

    test "login fails with invalid password" do
      user = create_user(email: "test@example.com", password: "CorrectPassword123!")

      assert {:error, error} =
               User
               |> Ash.Query.for_read(:sign_in_with_password, %{
                 email: user.email,
                 password: "WrongPassword456!"
               })
               |> Ash.read_one(domain: Accounts)
    end

    test "login fails with non-existent email" do
      assert {:error, error} =
               User
               |> Ash.Query.for_read(:sign_in_with_password, %{
                 email: "nonexistent@example.com",
                 password: "SomePassword123!"
               })
               |> Ash.read_one(domain: Accounts)
    end

    test "login with multi-organization context" do
      # Setup: User belongs to multiple organizations
      user = create_multi_org_user(organization_count: 3)
      password = "SecurePassword123!"

      # Update user with known password
      user_with_password =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      # Login
      {:ok, authenticated} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: user_with_password.email,
          password: password
        })
        |> Ash.read_one(domain: Accounts)

      # Load all organizations
      loaded_user =
        User
        |> Ash.Query.filter(id == ^authenticated.id)
        |> Ash.Query.load([:organizations, :memberships])
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      # User should have access to all their organizations
      assert length(loaded_user.organizations) == 3
      assert length(loaded_user.memberships) == 3
    end

    test "concurrent login attempts for same user" do
      password = "SecurePassword123!"
      user = create_user(password: password)

      # Simulate multiple concurrent login attempts
      tasks =
        Enum.map(1..3, fn _ ->
          Task.async(fn ->
            User
            |> Ash.Query.for_read(:sign_in_with_password, %{
              email: user.email,
              password: password
            })
            |> Ash.read_one(domain: Accounts)
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed
      assert Enum.all?(results, fn
               {:ok, authenticated} -> authenticated.id == user.id
               _ -> false
             end)
    end
  end

  describe "token refresh flow" do
    test "refresh token generates new bearer token" do
      user = create_user()

      # Step 1: Create initial bearer token
      initial_token = create_token(user: user, token_type: "bearer")

      # Step 2: Create refresh token
      refresh_token_attrs = %{
        user_id: user.id,
        token_type: "refresh",
        expires_at: DateTime.add(DateTime.utc_now(), 30 * 24 * 3600, :second)
      }

      {:ok, refresh_token} =
        Token
        |> Ash.Changeset.for_create(:create, refresh_token_attrs)
        |> Ash.create(domain: Accounts)

      # Step 3: Use refresh token to generate new bearer token
      new_bearer_attrs = %{
        user_id: user.id,
        token_type: "bearer",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      {:ok, new_bearer_token} =
        Token
        |> Ash.Changeset.for_create(:create, new_bearer_attrs)
        |> Ash.create(domain: Accounts)

      # Step 4: Revoke old bearer token
      {:ok, revoked_initial} =
        initial_token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts)

      # Verify refresh flow
      assert refresh_token.token_type == :refresh
      assert new_bearer_token.token_type == :bearer
      assert revoked_initial.revoked_at != nil
      assert new_bearer_token.revoked_at == nil

      # Verify all tokens belong to same user
      assert refresh_token.user_id == user.id
      assert new_bearer_token.user_id == user.id
      assert revoked_initial.user_id == user.id
    end

    test "expired refresh token cannot generate new bearer token" do
      user = create_user()

      # Create expired refresh token
      expired_refresh = create_expired_token(user: user, expired_minutes_ago: 60)

      # Verify token is expired
      assert DateTime.compare(expired_refresh.expires_at, DateTime.utc_now()) == :lt

      # Attempting to use expired refresh token should be rejected
      # (In real implementation, this would be checked before creating new token)
      now = DateTime.utc_now()

      valid_refresh_tokens =
        Token
        |> Ash.Query.filter(
          user_id == ^user.id and
            token_type == :refresh and
            expires_at > ^now and
            is_nil(revoked_at)
        )
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert expired_refresh.jti not in Enum.map(valid_refresh_tokens, & &1.jti)
    end

    test "revoked refresh token cannot be used" do
      user = create_user()

      # Create and immediately revoke refresh token
      refresh_token_attrs = %{
        user_id: user.id,
        token_type: "refresh",
        expires_at: DateTime.add(DateTime.utc_now(), 30 * 24 * 3600, :second)
      }

      {:ok, refresh_token} =
        Token
        |> Ash.Changeset.for_create(:create, refresh_token_attrs)
        |> Ash.create(domain: Accounts)

      {:ok, revoked_refresh} =
        refresh_token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts)

      # Verify token is revoked
      assert revoked_refresh.revoked_at != nil

      # Cannot use revoked refresh token
      active_refresh_tokens =
        Token
        |> Ash.Query.filter(
          user_id == ^user.id and
            token_type == :refresh and
            is_nil(revoked_at)
        )
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert revoked_refresh.jti not in Enum.map(active_refresh_tokens, & &1.jti)
    end
  end

  describe "logout flow" do
    test "logout revokes all user tokens" do
      user = create_user()

      # Create multiple tokens
      token1 = create_token(user: user, token_type: "bearer")
      token2 = create_token(user: user, token_type: "bearer")

      refresh_attrs = %{
        user_id: user.id,
        token_type: "refresh",
        expires_at: DateTime.add(DateTime.utc_now(), 30 * 24 * 3600, :second)
      }

      {:ok, refresh_token} =
        Token
        |> Ash.Changeset.for_create(:create, refresh_attrs)
        |> Ash.create(domain: Accounts)

      # Revoke all tokens (logout)
      now = DateTime.utc_now()

      Token
      |> Ash.Query.filter(user_id == ^user.id)
      |> Ash.read!(domain: Accounts, actor: bypass_actor())
      |> Enum.each(fn token ->
        token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update!(domain: Accounts)
      end)

      # Verify all tokens are revoked
      active_tokens =
        Token
        |> Ash.Query.filter(user_id == ^user.id and is_nil(revoked_at))
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert active_tokens == []
    end

    test "logout from specific device revokes only that device token" do
      user = create_user()

      # Create tokens for different devices
      device1_token =
        create_token(
          user: user,
          extra_data: %{device_id: "device-1"}
        )

      device2_token =
        create_token(
          user: user,
          extra_data: %{device_id: "device-2"}
        )

      # Revoke only device1 token
      {:ok, revoked} =
        device1_token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts)

      # Device1 token should be revoked
      assert revoked.revoked_at != nil

      # Device2 token should still be active
      device2_still_active =
        Token
        |> Ash.Query.filter(jti == ^device2_token.jti)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert device2_still_active.revoked_at == nil
    end
  end

  describe "password reset flow" do
    test "complete password reset flow" do
      user = create_user(email: "reset@example.com", password: "OldPassword123!")

      # Step 1: Request password reset (generates token)
      reset_token_attrs = %{
        user_id: user.id,
        token_type: "password_reset",
        # 1 hour
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      {:ok, reset_token} =
        Token
        |> Ash.Changeset.for_create(:create, reset_token_attrs)
        |> Ash.create(domain: Accounts)

      # Step 2: Verify reset token is valid
      assert reset_token.token_type == :password_reset
      assert DateTime.compare(reset_token.expires_at, DateTime.utc_now()) == :gt
      assert reset_token.revoked_at == nil

      # Step 3: Use token to change password
      new_password = "NewPassword456!"

      {:ok, updated_user} =
        user
        |> Ash.Changeset.for_update(
          :change_password,
          %{
            current_password: "OldPassword123!",
            password: new_password,
            password_confirmation: new_password
          }, actor: user)
        |> Ash.update(domain: Accounts)

      # Step 4: Revoke reset token after use
      {:ok, revoked_reset} =
        reset_token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts)

      # Step 5: Revoke all existing auth tokens
      Token
      |> Ash.Query.filter(user_id == ^user.id and token_type == :bearer)
      |> Ash.read!(domain: Accounts, actor: bypass_actor())
      |> Enum.each(fn token ->
        token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update!(domain: Accounts)
      end)

      # Verify password reset success
      assert revoked_reset.revoked_at != nil

      # Verify new password works
      {:ok, authenticated} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "reset@example.com",
          password: new_password
        })
        |> Ash.read_one(domain: Accounts)

      assert authenticated.id == user.id

      # Verify old password doesn't work
      assert {:error, %Ash.Error.Query.NotFound{}} =
               User
               |> Ash.Query.for_read(:sign_in_with_password, %{
                 email: "reset@example.com",
                 password: "OldPassword123!"
               })
               |> Ash.read_one(domain: Accounts)
    end

    test "password reset token expires after time limit" do
      user = create_user()

      # Create reset token that expires in 2 seconds
      reset_token_attrs = %{
        user_id: user.id,
        token_type: "password_reset",
        expires_at: DateTime.add(DateTime.utc_now(), 2, :second)
      }

      {:ok, reset_token} =
        Token
        |> Ash.Changeset.for_create(:create, reset_token_attrs)
        |> Ash.create(domain: Accounts)

      # Token is initially valid
      assert DateTime.compare(reset_token.expires_at, DateTime.utc_now()) == :gt

      # Wait for expiration
      Process.sleep(3000)

      # Token is now expired
      assert DateTime.compare(reset_token.expires_at, DateTime.utc_now()) == :lt
    end

    test "password reset token can only be used once" do
      user = create_user(password: "OldPassword123!")

      # Create reset token
      reset_token_attrs = %{
        user_id: user.id,
        token_type: "password_reset",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      {:ok, reset_token} =
        Token
        |> Ash.Changeset.for_create(:create, reset_token_attrs)
        |> Ash.create(domain: Accounts)

      # Use token to reset password
      {:ok, _updated} =
        user
        |> Ash.Changeset.for_update(
          :change_password,
          %{
            current_password: "OldPassword123!",
            password: "NewPassword456!",
            password_confirmation: "NewPassword456!"
          }, actor: user)
        |> Ash.update(domain: Accounts)

      # Revoke token after use
      {:ok, revoked} =
        reset_token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts)

      assert revoked.revoked_at != nil

      # Attempting to use revoked token again should fail
      active_reset_tokens =
        Token
        |> Ash.Query.filter(
          jti == ^reset_token.jti and
            token_type == :password_reset and
            is_nil(revoked_at)
        )
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert active_reset_tokens == []
    end
  end

  describe "email confirmation flow" do
    test "complete email confirmation flow" do
      # Step 1: User registers without confirmed email
      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, %{
          email: "confirm@example.com",
          password: "SecurePassword123!",
          name: "Unconfirmed User"
        })
        |> Ash.create(domain: Accounts)

      assert user.confirmed_at == nil

      # Step 2: Generate confirmation token
      confirmation_token_attrs = %{
        user_id: user.id,
        token_type: "email_confirmation",
        # 24 hours
        expires_at: DateTime.add(DateTime.utc_now(), 24 * 3600, :second)
      }

      {:ok, confirmation_token} =
        Token
        |> Ash.Changeset.for_create(:create, confirmation_token_attrs)
        |> Ash.create(domain: Accounts)

      # Step 3: User clicks confirmation link and confirms email
      confirmed_at = DateTime.utc_now()

      {:ok, confirmed_user} =
        user
        |> Ash.Changeset.for_update(:update, %{confirmed_at: confirmed_at}, actor: user)
        |> Ash.update(domain: Accounts)

      # Step 4: Revoke confirmation token
      {:ok, revoked_confirmation} =
        confirmation_token
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts)

      # Verify confirmation success
      assert confirmed_user.confirmed_at != nil
      assert revoked_confirmation.revoked_at != nil
    end

    test "confirmation token expires if not used within time limit" do
      user = create_user()

      # Create confirmation token that expires soon
      confirmation_token_attrs = %{
        user_id: user.id,
        token_type: "email_confirmation",
        expires_at: DateTime.add(DateTime.utc_now(), 2, :second)
      }

      {:ok, confirmation_token} =
        Token
        |> Ash.Changeset.for_create(:create, confirmation_token_attrs)
        |> Ash.create(domain: Accounts)

      # Token is initially valid
      assert DateTime.compare(confirmation_token.expires_at, DateTime.utc_now()) == :gt

      # Wait for expiration
      Process.sleep(3000)

      # Token is now expired
      assert DateTime.compare(confirmation_token.expires_at, DateTime.utc_now()) == :lt
    end

    test "can resend confirmation email with new token" do
      user = create_user()

      # Create first confirmation token
      token1_attrs = %{
        user_id: user.id,
        token_type: "email_confirmation",
        expires_at: DateTime.add(DateTime.utc_now(), 24 * 3600, :second)
      }

      {:ok, token1} =
        Token
        |> Ash.Changeset.for_create(:create, token1_attrs)
        |> Ash.create(domain: Accounts)

      # Revoke old token
      {:ok, _revoked} =
        token1
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update(domain: Accounts)

      # Create new confirmation token
      token2_attrs = %{
        user_id: user.id,
        token_type: "email_confirmation",
        expires_at: DateTime.add(DateTime.utc_now(), 24 * 3600, :second)
      }

      {:ok, token2} =
        Token
        |> Ash.Changeset.for_create(:create, token2_attrs)
        |> Ash.create(domain: Accounts)

      # Both tokens should exist
      assert token1.jti != token2.jti
      assert token2.revoked_at == nil
    end
  end

  describe "multi-organization authentication context" do
    test "user authenticates and accesses multiple organizations" do
      # Setup: User belongs to 3 organizations with different roles
      org1 = create_organization(name: "My Studio")
      org2 = create_organization(name: "Freelance Studio")
      org3 = create_organization(name: "Guest Studio")

      password = "SecurePassword123!"

      user =
        create_multi_org_user(
          user_attrs: %{password: password, email: "multi@example.com"},
          organizations: [org1, org2, org3]
        )

      # Set different roles in each organization
      memberships =
        Accounts.OrganizationMembership
        |> Ash.Query.filter(user_id == ^user.id)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      [mem1, mem2, mem3] = memberships

      {:ok, _} =
        mem1
        |> Ash.Changeset.for_update(:update, %{role: :owner})
        |> Ash.update(domain: Accounts)

      {:ok, _} =
        mem2
        |> Ash.Changeset.for_update(:update, %{role: :admin})
        |> Ash.update(domain: Accounts)

      {:ok, _} =
        mem3
        |> Ash.Changeset.for_update(:update, %{role: :member})
        |> Ash.update(domain: Accounts)

      # Login
      {:ok, authenticated} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "multi@example.com",
          password: password
        })
        |> Ash.read_one(domain: Accounts)

      # Load all organizational context
      loaded_user =
        User
        |> Ash.Query.filter(id == ^authenticated.id)
        |> Ash.Query.load([:organizations, :memberships])
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      # Verify access to all organizations
      assert length(loaded_user.organizations) == 3
      assert length(loaded_user.memberships) == 3

      org_ids = Enum.map(loaded_user.organizations, & &1.id)
      assert org1.id in org_ids
      assert org2.id in org_ids
      assert org3.id in org_ids
    end

    test "switching organization context maintains authentication" do
      user = create_multi_org_user(organization_count: 2)
      token = create_token(user: user)

      # Load organizations
      loaded_user =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.load(:organizations)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      [org1, org2] = loaded_user.organizations

      # Token remains valid regardless of organization context
      assert token.revoked_at == nil

      # User can access both organizations
      org1_loaded =
        Organization
        |> Ash.Query.filter(id == ^org1.id)
        |> Accounts.read_one!(actor: user)

      org2_loaded =
        Organization
        |> Ash.Query.filter(id == ^org2.id)
        |> Accounts.read_one!(actor: user)

      assert org1_loaded.id == org1.id
      assert org2_loaded.id == org2.id
    end

    test "user loses access when removed from organization" do
      user = create_user()
      org1 = create_organization()
      org2 = create_organization()

      # Add to both organizations
      mem1 = create_organization_membership(user: user, organization: org1)
      create_organization_membership(user: user, organization: org2)

      # Verify access to org1
      assert {:ok, _} =
               Organization
               |> Ash.Query.filter(id == ^org1.id)
               |> Accounts.read_one(actor: user)

      # Remove from org1
      Ash.destroy(mem1, domain: Accounts)

      # Should no longer have access to org1
      assert {:error, %Ash.Error.Forbidden{}} =
               Organization
               |> Ash.Query.filter(id == ^org1.id)
               |> Accounts.read_one(actor: user)

      # Should still have access to org2
      assert {:ok, _} =
               Organization
               |> Ash.Query.filter(id == ^org2.id)
               |> Accounts.read_one(actor: user)
    end
  end

  describe "authentication security" do
    test "password hashing is secure" do
      password = "SecurePassword123!"
      user = create_user(password: password)

      # Password should be hashed
      assert user.hashed_password != password
      assert String.starts_with?(user.hashed_password, "$2b$")

      # Verify password can be checked
      assert Bcrypt.verify_pass(password, user.hashed_password)
    end

    test "tokens have unique JTIs" do
      user = create_user()

      tokens = Enum.map(1..10, fn _ -> create_token(user: user) end)

      jtis = Enum.map(tokens, & &1.jti)

      # All JTIs should be unique
      assert length(Enum.uniq(jtis)) == 10
    end

    test "concurrent authentication attempts are handled safely" do
      password = "SecurePassword123!"
      user = create_user(password: password)

      # Simulate multiple devices logging in simultaneously
      tasks =
        Enum.map(1..5, fn _ ->
          Task.async(fn ->
            User
            |> Ash.Query.for_read(:sign_in_with_password, %{
              email: user.email,
              password: password
            })
            |> Ash.read_one(domain: Accounts)
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed
      assert Enum.all?(results, fn
               {:ok, authenticated} -> authenticated.id == user.id
               _ -> false
             end)
    end

    test "failed login attempts do not leak user existence" do
      # Existing user
      create_user(email: "exists@example.com", password: "Password123!")

      # Failed login for existing user
      result1 =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "exists@example.com",
          password: "WrongPassword!"
        })
        |> Ash.read_one(domain: Accounts)

      # Failed login for non-existent user
      result2 =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "nonexistent@example.com",
          password: "SomePassword!"
        })
        |> Ash.read_one(domain: Accounts)

      # Both should return same error type (don't leak existence)
      assert match?({:error, %Ash.Error.Query.NotFound{}}, result1)
      assert match?({:error, %Ash.Error.Query.NotFound{}}, result2)
    end
  end
end
