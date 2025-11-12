defmodule PilatesOnPhx.AccountsFixtures do
  @moduledoc """
  Test fixtures for Accounts domain resources.

  These fixtures create test data through proper Ash domain actions, ensuring:
  - All business logic is exercised
  - Authorization policies are respected (with test bypass for fixture creation)
  - Multi-tenant boundaries are enforced
  - Resources are created in valid states

  CRITICAL: Always use domain actions, never bypass domain layer.
  """

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.{User, Organization, Token, OrganizationMembership}

  require Ash.Query

  @doc """
  Returns a bypass actor for test fixtures that bypasses authorization policies.
  This allows test setup to create resources without complex authorization chains.
  """
  def bypass_actor do
    %{bypass_strict_access: true}
  end

  @doc """
  Creates an organization with valid attributes.

  ## Options
    * `:name` - Organization name (default: generated unique name)
    * `:timezone` - Timezone (default: "America/New_York")
    * `:settings` - JSON settings (default: %{})
    * `:active` - Active status (default: true)
    * `:owner` - User to set as owner (creates one if not provided)

  ## Examples

      iex> create_organization()
      %Organization{name: "Test Organization 1", active: true}

      iex> create_organization(name: "My Studio")
      %Organization{name: "My Studio", active: true}
  """
  def create_organization(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    org_attrs =
      %{
        name: "Test Organization #{unique_id}",
        timezone: "America/New_York",
        settings: %{},
        active: true
      }
      |> Map.merge(Enum.into(attrs, %{}))

    # Create organization - owner will be set via membership
    Organization
    |> Ash.Changeset.for_create(:create, org_attrs)
    |> Ash.create!(domain: Accounts, actor: bypass_actor())
  end

  @doc """
  Creates a user with valid attributes.

  ## Options
    * `:email` - Email address (default: generated unique email)
    * `:password` - Password (default: "SecurePassword123!")
    * `:name` - Full name (default: generated name)
    * `:role` - Role (:owner, :instructor, :client) (default: :client)
    * `:organization` - Organization to join (creates one if not provided)
    * `:confirmed_at` - Email confirmation timestamp (default: nil)

  ## Examples

      iex> create_user()
      %User{email: "user_1@example.com", role: :client}

      iex> create_user(role: :instructor, email: "instructor@studio.com")
      %User{email: "instructor@studio.com", role: :instructor}

      iex> create_user(organization: my_org)
      %User{email: "user_2@example.com", memberships: [%{organization_id: my_org.id}]}
  """
  def create_user(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    # Handle organization - create if not provided
    organization = attrs[:organization] || create_organization()

    user_attrs =
      %{
        email: "user_#{unique_id}@example.com",
        password: "SecurePassword123!",
        name: "Test User #{unique_id}",
        role: :client
      }
      |> Map.merge(Enum.into(attrs, %{}))
      |> Map.delete(:organization)

    # Create user through registration action
    user =
      User
      |> Ash.Changeset.for_create(:register, user_attrs)
      |> Ash.create!(domain: Accounts, actor: bypass_actor())

    # Create organization membership
    create_organization_membership(user: user, organization: organization)

    # Reload user with memberships and organizations for policy checks
    User
    |> Ash.Query.filter(id == ^user.id)
    |> Ash.Query.load([:memberships, :organizations])
    |> Ash.read_one!(domain: Accounts, actor: bypass_actor())
  end

  @doc """
  Creates a user with multiple organization memberships.

  ## Options
    * `:user_attrs` - Attributes for user creation
    * `:organization_count` - Number of organizations to create (default: 3)
    * `:organizations` - Specific organizations to join (overrides count)

  ## Examples

      iex> create_multi_org_user(organization_count: 2)
      %User{memberships: [%{...}, %{...}]}

      iex> create_multi_org_user(organizations: [org1, org2, org3])
      %User{memberships: [%{organization_id: org1.id}, ...]}
  """
  def create_multi_org_user(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    user_attrs = Map.get(attrs, :user_attrs, %{})

    # Create base user without organization membership
    unique_id = System.unique_integer([:positive])

    base_attrs =
      %{
        email: "multi_org_user_#{unique_id}@example.com",
        password: "SecurePassword123!",
        name: "Multi Org User #{unique_id}",
        # Instructors commonly work at multiple studios
        role: :instructor
      }
      |> Map.merge(user_attrs)

    user =
      User
      |> Ash.Changeset.for_create(:register, base_attrs)
      |> Ash.create!(domain: Accounts, actor: bypass_actor())

    # Create organization memberships
    organizations =
      if orgs = attrs[:organizations] do
        orgs
      else
        count = Map.get(attrs, :organization_count, 3)
        Enum.map(1..count, fn _ -> create_organization() end)
      end

    Enum.each(organizations, fn org ->
      create_organization_membership(user: user, organization: org)
    end)

    # Reload user with all memberships and organizations for policy checks
    User
    |> Ash.Query.filter(id == ^user.id)
    |> Ash.Query.load([:memberships, :organizations])
    |> Ash.read_one!(domain: Accounts, actor: bypass_actor())
  end

  @doc """
  Creates an organization membership (join record).

  ## Options
    * `:user` - User to add (required)
    * `:organization` - Organization to join (required)
    * `:role` - Role in organization (:owner, :admin, :member) (default: :member)
    * `:joined_at` - Join timestamp (default: now)

  ## Examples

      iex> create_organization_membership(user: user, organization: org)
      %OrganizationMembership{user_id: user.id, organization_id: org.id}

      iex> create_organization_membership(user: user, organization: org, role: :owner)
      %OrganizationMembership{role: :owner}
  """
  def create_organization_membership(attrs) do
    user = Keyword.fetch!(attrs, :user)
    organization = Keyword.fetch!(attrs, :organization)

    membership_attrs = %{
      user_id: user.id,
      organization_id: organization.id,
      role: Keyword.get(attrs, :role, :member),
      joined_at: Keyword.get(attrs, :joined_at, DateTime.utc_now())
    }

    OrganizationMembership
    |> Ash.Changeset.for_create(:create, membership_attrs)
    |> Ash.create!(domain: Accounts, actor: bypass_actor())
  end

  @doc """
  Creates an authenticated user with a valid token.

  ## Options
    * `:user_attrs` - Attributes for user creation
    * `:token_type` - Token type (default: "bearer")
    * `:expires_at` - Token expiration (default: 1 hour from now)

  ## Examples

      iex> create_authenticated_user()
      {%User{...}, %Token{token: "jwt_token_here"}}

      iex> create_authenticated_user(user_attrs: %{role: :owner})
      {%User{role: :owner}, %Token{...}}
  """
  def create_authenticated_user(attrs \\ %{}) do
    user_attrs = Map.get(attrs, :user_attrs, %{})
    user = create_user(user_attrs)

    token_attrs = %{
      user_id: user.id,
      token_type: Map.get(attrs, :token_type, "bearer"),
      expires_at: Map.get(attrs, :expires_at, DateTime.add(DateTime.utc_now(), 3600, :second))
    }

    token =
      Token
      |> Ash.Changeset.for_create(:create, token_attrs)
      |> Ash.create!(domain: Accounts, actor: bypass_actor())

    {user, token}
  end

  @doc """
  Creates a token for a given user.

  ## Options
    * `:user` - User to create token for (required)
    * `:token_type` - Token type (default: :bearer)
    * `:expires_at` - Token expiration (default: 1 hour from now)
    * `:extra_data` - Additional token metadata (default: %{})

  ## Examples

      iex> create_token(user: user)
      %Token{user_id: user.id, token_type: :bearer}

      iex> create_token(user: user, token_type: :refresh)
      %Token{token_type: :refresh}
  """
  def create_token(attrs) do
    user = Keyword.fetch!(attrs, :user)

    token_attrs = %{
      user_id: user.id,
      token_type: Keyword.get(attrs, :token_type, :bearer),
      expires_at:
        Keyword.get(attrs, :expires_at, DateTime.add(DateTime.utc_now(), 3600, :second)),
      extra_data: Keyword.get(attrs, :extra_data, %{})
    }

    Token
    |> Ash.Changeset.for_create(:create, token_attrs)
    |> Ash.create!(domain: Accounts, actor: bypass_actor())
  end

  @doc """
  Creates an expired token for testing token lifecycle.

  ## Options
    * `:user` - User to create token for (required)
    * `:expired_minutes_ago` - How many minutes ago token expired (default: 60)

  ## Examples

      iex> create_expired_token(user: user)
      %Token{expires_at: ~U[...past timestamp...]}
  """
  def create_expired_token(attrs) do
    user = Keyword.fetch!(attrs, :user)
    minutes_ago = Keyword.get(attrs, :expired_minutes_ago, 60)

    expires_at = DateTime.add(DateTime.utc_now(), -minutes_ago * 60, :second)

    create_token(user: user, expires_at: expires_at)
  end

  @doc """
  Creates a complete test scenario with organization, owner, and members.

  Returns a map with:
    * `:organization` - The created organization
    * `:owner` - User with owner role
    * `:instructors` - List of instructor users
    * `:clients` - List of client users

  ## Options
    * `:instructor_count` - Number of instructors (default: 2)
    * `:client_count` - Number of clients (default: 5)

  ## Examples

      iex> scenario = create_organization_scenario()
      iex> scenario.organization
      %Organization{...}
      iex> length(scenario.instructors)
      2
      iex> length(scenario.clients)
      5
  """
  def create_organization_scenario(attrs \\ %{}) do
    instructor_count = Map.get(attrs, :instructor_count, 2)
    client_count = Map.get(attrs, :client_count, 5)

    # Create organization
    organization = create_organization()

    # Create owner
    owner =
      create_user(
        role: :owner,
        organization: organization,
        name: "Studio Owner"
      )

    # Update membership to owner role
    membership =
      OrganizationMembership
      |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^organization.id)
      |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

    membership
    |> Ash.Changeset.for_update(:update, %{role: :owner}, actor: bypass_actor())
    |> Ash.update!(domain: Accounts)

    # Create instructors
    instructors =
      Enum.map(1..instructor_count, fn i ->
        create_user(
          role: :instructor,
          organization: organization,
          name: "Instructor #{i}"
        )
      end)

    # Create clients
    clients =
      Enum.map(1..client_count, fn i ->
        create_user(
          role: :client,
          organization: organization,
          name: "Client #{i}"
        )
      end)

    %{
      organization: organization,
      owner: owner,
      instructors: instructors,
      clients: clients
    }
  end
end
