defmodule PilatesOnPhx.Accounts.UserTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.User
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "user registration (action: register)" do
    test "creates user with valid email and password" do
      attrs = %{
        email: "newuser@example.com",
        password: "SecurePassword123!",
        name: "New User",
        role: :client
      }

      assert {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      assert to_string(user.email) == "newuser@example.com"
      assert user.name == "New User"
      assert user.role == :client
      assert user.hashed_password != nil
      assert user.hashed_password != "SecurePassword123!"
    end

    test "requires email" do
      attrs = %{
        password: "SecurePassword123!",
        name: "No Email User"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :email end)
    end

    test "requires password" do
      attrs = %{
        email: "nopassword@example.com",
        name: "No Password User"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :password end)
    end

    test "validates email format" do
      attrs = %{
        email: "invalid-email-format",
        password: "SecurePassword123!",
        name: "Invalid Email User"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error ->
        error.field == :email and error.message =~ "email"
      end)
    end

    test "enforces unique email addresses" do
      existing_email = "duplicate@example.com"

      # Create first user
      attrs = %{
        email: existing_email,
        password: "SecurePassword123!",
        name: "First User"
      }

      assert {:ok, _user} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      # Attempt to create second user with same email
      duplicate_attrs = %{
        email: existing_email,
        password: "DifferentPassword456!",
        name: "Second User"
      }

      assert {:error, error} =
        User
        |> Ash.Changeset.for_create(:register, duplicate_attrs)
        |> Ash.create(domain: Accounts)

      # Check for unique constraint error which might be in errors list directly
      assert error.__struct__ == Ash.Error.Invalid
      assert Enum.any?(error.errors, fn e ->
        Map.get(e, :field) == :email or
        (Map.get(e, :fields) && :email in e.fields) or
        String.contains?(to_string(e.message || ""), ["unique", "already exists"])
      end)
    end

    test "validates password strength requirements" do
      # Test too short password
      short_attrs = %{
        email: "shortpass@example.com",
        password: "Short1!",
        name: "Short Password User"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, short_attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error ->
        error.field == :password
      end)
    end

    test "hashes password using bcrypt" do
      attrs = %{
        email: "hashtest@example.com",
        password: "SecurePassword123!",
        name: "Hash Test User"
      }

      assert {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      # Password should be hashed
      assert user.hashed_password != attrs.password
      assert String.starts_with?(user.hashed_password, "$2b$")

      # Verify password can be checked
      assert Bcrypt.verify_pass(attrs.password, user.hashed_password)
    end

    test "sets default role to :client when not specified" do
      attrs = %{
        email: "defaultrole@example.com",
        password: "SecurePassword123!",
        name: "Default Role User"
      }

      assert {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      assert user.role == :client
    end

    test "allows setting role during registration" do
      # Test instructor role
      instructor_attrs = %{
        email: "instructor@example.com",
        password: "SecurePassword123!",
        name: "Instructor User",
        role: :instructor
      }

      assert {:ok, instructor} =
        User
        |> Ash.Changeset.for_create(:register, instructor_attrs)
        |> Ash.create(domain: Accounts)

      assert instructor.role == :instructor

      # Test owner role
      owner_attrs = %{
        email: "owner@example.com",
        password: "SecurePassword123!",
        name: "Owner User",
        role: :owner
      }

      assert {:ok, owner} =
        User
        |> Ash.Changeset.for_create(:register, owner_attrs)
        |> Ash.create(domain: Accounts)

      assert owner.role == :owner
    end

    test "normalizes email to lowercase" do
      attrs = %{
        email: "UpperCase@EXAMPLE.COM",
        password: "SecurePassword123!",
        name: "Case Test User"
      }

      assert {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      assert to_string(user.email) == "uppercase@example.com"
    end
  end

  describe "user authentication (action: sign_in_with_password)" do
    test "authenticates user with valid credentials" do
      # Create user
      password = "SecurePassword123!"
      user = create_user(password: password, email: "auth@example.com")

      # Authenticate
      assert {:ok, authenticated_user} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "auth@example.com",
          password: password
        })
        |> Ash.read_one(domain: Accounts)

      assert authenticated_user.id == user.id
      assert to_string(authenticated_user.email) == to_string(user.email)
    end

    test "fails authentication with invalid password" do
      user = create_user(password: "CorrectPassword123!", email: "authfail@example.com")

      assert {:error, %Ash.Error.Query.NotFound{}} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: user.email,
          password: "WrongPassword456!"
        })
        |> Ash.read_one(domain: Accounts)
    end

    test "fails authentication with non-existent email" do
      assert {:error, %Ash.Error.Query.NotFound{}} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "nonexistent@example.com",
          password: "SomePassword123!"
        })
        |> Ash.read_one(domain: Accounts)
    end

    test "authentication is case-insensitive for email" do
      password = "SecurePassword123!"
      user = create_user(password: password, email: "casetest@example.com")

      # Try various case combinations
      assert {:ok, authenticated} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: "CASETEST@EXAMPLE.COM",
          password: password
        })
        |> Ash.read_one(domain: Accounts)

      assert authenticated.id == user.id
    end
  end

  describe "user profile updates (action: update)" do
    test "updates user name" do
      user = create_user()

      assert {:ok, updated} =
        user
        |> Ash.Changeset.for_update(:update, %{name: "Updated Name"}, actor: user)
        |> Ash.update(domain: Accounts)

      assert updated.name == "Updated Name"
      assert updated.id == user.id
    end

    test "updates user role" do
      user = create_user(role: :client)

      assert {:ok, updated} =
        user
        |> Ash.Changeset.for_update(:update, %{role: :instructor}, actor: user)
        |> Ash.update(domain: Accounts)

      assert updated.role == :instructor
    end

    test "prevents changing email to existing email" do
      user1 = create_user(email: "user1@example.com")
      _user2 = create_user(email: "user2@example.com")

      assert {:error, %Ash.Error.Invalid{} = error} =
        user1
        |> Ash.Changeset.for_update(:update, %{email: "user2@example.com"}, actor: user1)
        |> Ash.update(domain: Accounts)

      changeset = error.changeset

      assert changeset.valid? == false
    end

    test "allows user to update their own profile" do
      user = create_user()

      assert {:ok, updated} =
        user
        |> Ash.Changeset.for_update(:update, %{name: "Self Updated"}, actor: user)
        |> Ash.update(domain: Accounts)

      assert updated.name == "Self Updated"
    end
  end

  describe "password change (action: change_password)" do
    test "changes password with valid current password" do
      old_password = "OldPassword123!"
      new_password = "NewPassword456!"
      user = create_user(password: old_password)

      assert {:ok, _updated} =
        user
        |> Ash.Changeset.for_update(:change_password, %{
          current_password: old_password,
          password: new_password,
          password_confirmation: new_password
        }, actor: user)
        |> Ash.update(domain: Accounts)

      # Verify old password no longer works
      assert {:error, %Ash.Error.Query.NotFound{}} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: user.email,
          password: old_password
        })
        |> Ash.read_one(domain: Accounts)

      # Verify new password works
      assert {:ok, authenticated} =
        User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: user.email,
          password: new_password
        })
        |> Ash.read_one(domain: Accounts)

      assert authenticated.id == user.id
    end

    test "fails password change with incorrect current password" do
      user = create_user(password: "CorrectPassword123!")

      assert {:error, %Ash.Error.Invalid{} = error} =
        user
        |> Ash.Changeset.for_update(:change_password, %{
          current_password: "WrongPassword456!",
          password: "NewPassword789!",
          password_confirmation: "NewPassword789!"
        }, actor: user)
        |> Ash.update(domain: Accounts)

      changeset = error.changeset

      assert changeset.valid? == false
    end

    test "requires password confirmation to match" do
      user = create_user(password: "CurrentPassword123!")

      assert {:error, %Ash.Error.Invalid{} = error} =
        user
        |> Ash.Changeset.for_update(:change_password, %{
          current_password: "CurrentPassword123!",
          password: "NewPassword456!",
          password_confirmation: "DifferentPassword789!"
        }, actor: user)
        |> Ash.update(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "multi-organization membership" do
    test "user can belong to multiple organizations" do
      org1 = create_organization(name: "Studio A")
      org2 = create_organization(name: "Studio B")
      org3 = create_organization(name: "Studio C")

      user = create_multi_org_user(organizations: [org1, org2, org3])

      # Load user with memberships
      loaded_user =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.load(:memberships)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert length(loaded_user.memberships) == 3

      membership_org_ids = Enum.map(loaded_user.memberships, & &1.organization_id)
      assert org1.id in membership_org_ids
      assert org2.id in membership_org_ids
      assert org3.id in membership_org_ids
    end

    test "instructor can work at multiple studios" do
      # Real-world scenario: instructor teaches at 3 different studios
      user = create_multi_org_user(
        user_attrs: %{role: :instructor, name: "Multi-Studio Instructor"},
        organization_count: 3
      )

      loaded_user =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.load([:memberships, :organizations])
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert loaded_user.role == :instructor
      assert length(loaded_user.memberships) == 3
      assert length(loaded_user.organizations) == 3
    end

    test "user can have different roles in different organizations" do
      org1 = create_organization(name: "My Studio")
      org2 = create_organization(name: "Other Studio")

      user = create_user()

      # Owner at own studio
      create_organization_membership(user: user, organization: org1, role: :owner)

      # Instructor at another studio
      create_organization_membership(user: user, organization: org2, role: :member)

      loaded_user =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.load(:memberships)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      memberships_by_org = Map.new(loaded_user.memberships, fn m -> {m.organization_id, m} end)

      assert memberships_by_org[org1.id].role == :owner
      assert memberships_by_org[org2.id].role == :member
    end

    test "loading organizations relationship returns all organizations" do
      user = create_multi_org_user(organization_count: 2)

      loaded_user =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.Query.load(:organizations)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert length(loaded_user.organizations) == 2
      assert Enum.all?(loaded_user.organizations, fn org ->
        is_struct(org, PilatesOnPhx.Accounts.Organization)
      end)
    end
  end

  describe "role-based permissions" do
    test "owner role has highest permissions" do
      owner = create_user(role: :owner)
      assert owner.role == :owner
    end

    test "instructor role for teaching staff" do
      instructor = create_user(role: :instructor)
      assert instructor.role == :instructor
    end

    test "client role for class participants" do
      client = create_user(role: :client)
      assert client.role == :client
    end

    test "role enum validates only allowed values" do
      invalid_attrs = %{
        email: "invalidrole@example.com",
        password: "SecurePassword123!",
        name: "Invalid Role User",
        role: :invalid_role
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, invalid_attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "user queries and filtering" do
    test "can query all users" do
      create_user(email: "user1@example.com")
      create_user(email: "user2@example.com")
      create_user(email: "user3@example.com")

      users = User |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(users) >= 3
    end

    test "can filter users by role" do
      create_user(role: :owner, email: "owner@example.com")
      create_user(role: :instructor, email: "instructor1@example.com")
      create_user(role: :instructor, email: "instructor2@example.com")
      create_user(role: :client, email: "client@example.com")

      instructors =
        User
        |> Ash.Query.filter(role == :instructor)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(instructors) >= 2
      assert Enum.all?(instructors, fn user -> user.role == :instructor end)
    end

    test "can filter users by email" do
      user = create_user(email: "findme@example.com")

      found_users =
        User
        |> Ash.Query.filter(email == ^user.email)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(found_users) == 1
      assert hd(found_users).id == user.id
    end

    test "can search users by name pattern" do
      create_user(name: "John Smith", email: "john@example.com")
      create_user(name: "Jane Smith", email: "jane@example.com")
      create_user(name: "Bob Johnson", email: "bob@example.com")

      smith_users =
        User
        |> Ash.Query.filter(contains(name, "Smith"))
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(smith_users) >= 2
      assert Enum.all?(smith_users, fn user -> String.contains?(user.name, "Smith") end)
    end
  end

  describe "user account lifecycle" do
    test "new user has no confirmed_at timestamp" do
      user = create_user()

      assert user.confirmed_at == nil
    end

    test "can mark user as confirmed" do
      user = create_user()

      confirmed_at = DateTime.utc_now()

      assert {:ok, confirmed} =
        user
        |> Ash.Changeset.for_update(:update, %{confirmed_at: confirmed_at}, actor: user)
        |> Ash.update(domain: Accounts)

      assert confirmed.confirmed_at != nil
    end

    test "tracks user creation timestamp" do
      user = create_user()

      assert user.inserted_at != nil
      assert %DateTime{} = user.inserted_at
    end

    test "tracks user update timestamp" do
      user = create_user()
      original_updated_at = user.updated_at

      # Wait a moment to ensure timestamp differs
      Process.sleep(10)

      {:ok, updated} =
        user
        |> Ash.Changeset.for_update(:update, %{name: "Updated"}, actor: user)
        |> Ash.update(domain: Accounts)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end
  end

  describe "authorization policies" do
    test "users can read their own profile" do
      user = create_user()

      assert {:ok, loaded_user} =
        User
        |> Ash.Query.filter(id == ^user.id)
        |> Ash.read_one(domain: Accounts, actor: user)

      assert loaded_user.id == user.id
    end

    test "users in same organization can read each other" do
      organization = create_organization()
      user1 = create_user(organization: organization)
      user2 = create_user(organization: organization)

      # User1 can read User2
      assert {:ok, loaded} =
        User
        |> Ash.Query.filter(id == ^user2.id)
        |> Ash.read_one(domain: Accounts, actor: user1)

      assert loaded.id == user2.id
    end

    test "users cannot access users from different organizations" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      user2 = create_user(organization: org2)

      # User1 cannot read User2 from different org
      assert {:error, %Ash.Error.Forbidden{}} =
        User
        |> Ash.Query.filter(id == ^user2.id)
        |> Ash.read_one(domain: Accounts, actor: user1)
    end

    test "owner can update other users in their organization" do
      organization = create_organization()
      owner = create_user(organization: organization, role: :owner)
      member = create_user(organization: organization, role: :client)

      # Update membership to owner role
      membership = Accounts.OrganizationMembership
      |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^organization.id)
      |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      membership
      |> Ash.Changeset.for_update(:update, %{role: :owner}, actor: bypass_actor())
      |> Ash.update!(domain: Accounts)

      assert {:ok, updated} =
        member
        |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"}, actor: owner)
        |> Ash.update(domain: Accounts)

      assert updated.name == "Updated by Owner"
    end

    test "regular members cannot update other users" do
      organization = create_organization()
      user1 = create_user(organization: organization, role: :client)
      user2 = create_user(organization: organization, role: :client)

      assert {:error, %Ash.Error.Forbidden{}} =
        user2
        |> Ash.Changeset.for_update(:update, %{name: "Unauthorized Update"}, actor: user1)
        |> Ash.update(domain: Accounts)
    end
  end

  describe "data validation edge cases" do
    test "rejects extremely long email addresses" do
      long_email = String.duplicate("a", 300) <> "@example.com"

      attrs = %{
        email: long_email,
        password: "SecurePassword123!",
        name: "Long Email User"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "rejects email with invalid characters" do
      invalid_attrs = %{
        email: "invalid email@example.com",  # Space is invalid
        password: "SecurePassword123!",
        name: "Invalid Char User"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, invalid_attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "handles unicode in user names" do
      attrs = %{
        email: "unicode@example.com",
        password: "SecurePassword123!",
        name: "José García 李明"
      }

      assert {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      assert user.name == "José García 李明"
    end

    test "rejects empty string as email" do
      attrs = %{
        email: "",
        password: "SecurePassword123!",
        name: "Empty Email User"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        User
        |> Ash.Changeset.for_create(:register, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "concurrent user operations" do
    test "handles concurrent user creation with different emails" do
      # Simulate concurrent registrations
      tasks = Enum.map(1..5, fn i ->
        Task.async(fn ->
          attrs = %{
            email: "concurrent#{i}@example.com",
            password: "SecurePassword123!",
            name: "Concurrent User #{i}"
          }

          User
          |> Ash.Changeset.for_create(:register, attrs)
          |> Ash.create(domain: Accounts)
        end)
      end)

      results = Task.await_many(tasks)

      # All should succeed
      assert Enum.all?(results, fn
        {:ok, _user} -> true
        _ -> false
      end)
    end

    test "prevents concurrent creation with same email (race condition)" do
      email = "race@example.com"

      # Attempt concurrent creation with same email
      tasks = Enum.map(1..3, fn i ->
        Task.async(fn ->
          attrs = %{
            email: email,
            password: "SecurePassword#{i}!",
            name: "Race User #{i}"
          }

          User
          |> Ash.Changeset.for_create(:register, attrs)
          |> Ash.create(domain: Accounts)
        end)
      end)

      results = Task.await_many(tasks)

      # Exactly one should succeed, others should fail with unique constraint
      successful = Enum.filter(results, fn
        {:ok, _} -> true
        _ -> false
      end)

      assert length(successful) == 1
    end
  end
end
