# Phase 3 Implementation Guide - PHX-2 Accounts Domain Resources

## Overview

This guide provides detailed instructions for implementing the Accounts domain resources (User, Organization, Token, OrganizationMembership) for Linear issue PHX-2.

**Status**: Phase 2 (TDD Setup) Complete ✅

All test files have been created following production-ready TDD principles. Tests are comprehensive, focus on business logic, and demonstrate real user workflows.

## Test Files Created

### Core Test Suites

1. **`test/support/accounts_fixtures.ex`**
   - Domain-driven test factory helpers
   - Creates resources through proper Ash domain actions
   - Supports multi-organization scenarios
   - Helper functions: `create_user/1`, `create_organization/1`, `create_token/2`, `create_multi_org_user/1`, etc.

2. **`test/pilates_on_phx/accounts/user_test.exs`** (477 lines)
   - User registration and authentication
   - Password management and security
   - Multi-organization membership
   - Role-based permissions
   - Data validation edge cases
   - Concurrent operations

3. **`test/pilates_on_phx/accounts/organization_test.exs`** (644 lines)
   - Organization creation and lifecycle
   - Settings management (JSON storage)
   - Multi-tenant isolation
   - Timezone handling
   - Activation/deactivation flows
   - Authorization policies

4. **`test/pilates_on_phx/accounts/organization_membership_test.exs`** (588 lines)
   - Many-to-many relationship management
   - Role management (owner, admin, member)
   - Multi-organization scenarios
   - Cascade deletion behavior
   - Authorization policies

5. **`test/pilates_on_phx/accounts/token_test.exs`** (571 lines)
   - Token lifecycle (creation, expiration, revocation)
   - Multiple token types (bearer, refresh, password_reset, email_confirmation)
   - JWT ID (jti) uniqueness
   - Security and isolation
   - Token cleanup strategies

6. **`test/pilates_on_phx/accounts/authentication_integration_test.exs`** (507 lines)
   - End-to-end authentication flows
   - Registration → Organization → Membership → Token
   - Login flows with token generation
   - Token refresh flows
   - Password reset workflows
   - Email confirmation flows
   - Multi-organization authentication context

7. **`test/pilates_on_phx/accounts/authorization_policies_test.exs`** (620 lines)
   - Multi-tenant data isolation
   - Role-based access control (RBAC)
   - Cross-organization access prevention
   - Self-service user operations
   - Edge cases and security

## Implementation Order

### Step 1: OrganizationMembership Resource (JOIN TABLE FIRST!)

**Critical**: Implement the join table BEFORE the many-to-many relationships to avoid circular dependencies.

**File**: `lib/pilates_on_phx/accounts/organization_membership.ex`

**Required Attributes**:
```elixir
uuid_primary_key :id

attributes do
  attribute :role, :atom do
    constraints one_of: [:owner, :admin, :member]
    default :member
    allow_nil? false
  end

  attribute :joined_at, :utc_datetime_usec do
    default &DateTime.utc_now/0
    allow_nil? false
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**Required Relationships**:
```elixir
relationships do
  belongs_to :user, PilatesOnPhx.Accounts.User do
    allow_nil? false
  end

  belongs_to :organization, PilatesOnPhx.Accounts.Organization do
    allow_nil? false
  end
end
```

**Required Actions**:
- `:create` - Standard create with user_id, organization_id, role, joined_at
- `:update` - Allow role changes
- `:destroy` - For removing memberships

**Required Policies**:
```elixir
policies do
  # Users can read their own memberships
  policy action_type(:read) do
    authorize_if actor_attribute_equals(:id, :user_id)
  end

  # Organization owners can manage memberships
  policy action_type([:update, :destroy]) do
    authorize_if relates_to_actor_via([:organization, :memberships], expr(role == :owner))
  end
end
```

**Identity Constraint**:
```elixir
identities do
  identity :unique_user_organization, [:user_id, :organization_id]
end
```

**Run tests**: `mix test test/pilates_on_phx/accounts/organization_membership_test.exs`

---

### Step 2: Organization Resource

**File**: `lib/pilates_on_phx/accounts/organization.ex`

**Required Attributes**:
```elixir
uuid_primary_key :id

attributes do
  attribute :name, :string do
    allow_nil? false
    constraints [
      min_length: 1,
      max_length: 255,
      trim: true
    ]
  end

  attribute :timezone, :string do
    default "America/New_York"
    allow_nil? false
    constraints [
      one_of: Tzdata.zone_list()  # Validate IANA timezone
    ]
  end

  attribute :settings, :map do
    default %{}
    allow_nil? false
  end

  attribute :active, :boolean do
    default true
    allow_nil? false
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**Required Relationships**:
```elixir
relationships do
  has_many :memberships, PilatesOnPhx.Accounts.OrganizationMembership do
    destination_attribute :organization_id
  end

  many_to_many :users, PilatesOnPhx.Accounts.User do
    through PilatesOnPhx.Accounts.OrganizationMembership
    source_attribute_on_join_resource :organization_id
    destination_attribute_on_join_resource :user_id
  end
end
```

**Required Actions**:
- `:create` - Standard create
- `:read` - With organization isolation policy
- `:update` - Update name, timezone, settings, active
- `:activate` - Set active to true
- `:deactivate` - Set active to false
- `:destroy` - Delete organization (cascade to memberships)

**Required Policies**:
```elixir
policies do
  # Members can read their organization
  policy action_type(:read) do
    authorize_if relates_to_actor_via(:memberships)
  end

  # Only owners can update
  policy action_type([:update, :activate, :deactivate]) do
    authorize_if relates_to_actor_via(:memberships, expr(role == :owner))
  end

  # Only owners can destroy
  policy action_type(:destroy) do
    authorize_if relates_to_actor_via(:memberships, expr(role == :owner))
  end
end
```

**Run tests**: `mix test test/pilates_on_phx/accounts/organization_test.exs`

---

### Step 3: User Resource (with AshAuthentication)

**File**: `lib/pilates_on_phx/accounts/user.ex`

**Required Extensions**:
```elixir
use Ash.Resource,
  data_layer: AshPostgres.DataLayer,
  extensions: [AshAuthentication],
  domain: PilatesOnPhx.Accounts
```

**Required Attributes**:
```elixir
uuid_primary_key :id

attributes do
  attribute :email, :ci_string do  # Case-insensitive string
    allow_nil? false
    public? true
  end

  attribute :hashed_password, :string do
    allow_nil? false
    sensitive? true
    private? true
  end

  attribute :name, :string do
    allow_nil? false
    constraints [
      min_length: 1,
      max_length: 255
    ]
  end

  attribute :role, :atom do
    constraints one_of: [:owner, :instructor, :client]
    default :client
    allow_nil? false
  end

  attribute :confirmed_at, :utc_datetime_usec do
    allow_nil? true
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**AshAuthentication Configuration**:
```elixir
authentication do
  strategies do
    password :password do
      identity_field :email
      hashed_password_field :hashed_password
      hash_provider AshAuthentication.BcryptProvider

      sign_in_tokens_enabled? true

      resettable do
        sender fn user, token ->
          # Send password reset email
          # Implementation depends on email provider
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
```

**Required Relationships**:
```elixir
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
```

**Required Actions**:
- `:register` - AshAuthentication registration action
- `:sign_in_with_password` - AshAuthentication sign-in action
- `:read` - With organization isolation
- `:update` - Update name, role
- `:change_password` - Custom password change with verification
- `:destroy` - Delete user (cascade to tokens and memberships)

**Required Policies**:
```elixir
policies do
  # Users can read themselves
  policy action_type(:read) do
    authorize_if actor_attribute_equals(:id, :id)
  end

  # Users in same organization can read each other
  policy action_type(:read) do
    authorize_if relates_to_actor_via([:organizations, :memberships])
  end

  # Users can update themselves
  policy action_type(:update) do
    authorize_if actor_attribute_equals(:id, :id)
  end

  # Organization owners can update users in their org
  policy action_type(:update) do
    authorize_if relates_to_actor_via([:organizations, :memberships], expr(role == :owner))
  end
end
```

**Identity Constraint**:
```elixir
identities do
  identity :unique_email, [:email]
end
```

**Run tests**: `mix test test/pilates_on_phx/accounts/user_test.exs`

---

### Step 4: Token Resource

**File**: `lib/pilates_on_phx/accounts/token.ex`

**Required Attributes**:
```elixir
uuid_primary_key :id

attributes do
  attribute :jti, :string do
    allow_nil? false
    default &Ash.UUID.generate/0
    public? true
  end

  attribute :token_type, :string do
    default "bearer"
    allow_nil? false
    constraints [
      one_of: ["bearer", "refresh", "password_reset", "email_confirmation"]
    ]
  end

  attribute :expires_at, :utc_datetime_usec do
    allow_nil? false
    default fn ->
      DateTime.add(DateTime.utc_now(), 3600, :second)  # 1 hour default
    end
  end

  attribute :revoked_at, :utc_datetime_usec do
    allow_nil? true
  end

  attribute :extra_data, :map do
    default %{}
    allow_nil? false
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**Required Relationships**:
```elixir
relationships do
  belongs_to :user, PilatesOnPhx.Accounts.User do
    allow_nil? false
  end
end
```

**Required Actions**:
- `:create` - Create token with user_id, token_type, expires_at, extra_data
- `:read` - With user isolation
- `:revoke` - Set revoked_at to current time
- `:destroy` - Delete token

**Required Policies**:
```elixir
policies do
  # Users can only access their own tokens
  policy action_type(:read) do
    authorize_if actor_attribute_equals(:id, :user_id)
  end

  policy action_type([:revoke, :destroy]) do
    authorize_if actor_attribute_equals(:id, :user_id)
  end
end
```

**Identity Constraint**:
```elixir
identities do
  identity :unique_jti, [:jti]
end
```

**Run tests**: `mix test test/pilates_on_phx/accounts/token_test.exs`

---

### Step 5: Register Resources in Domain

**File**: `lib/pilates_on_phx/accounts.ex`

Update the domain module to register all resources:

```elixir
defmodule PilatesOnPhx.Accounts do
  use Ash.Domain

  resources do
    resource PilatesOnPhx.Accounts.User
    resource PilatesOnPhx.Accounts.Organization
    resource PilatesOnPhx.Accounts.Token
    resource PilatesOnPhx.Accounts.OrganizationMembership
  end
end
```

---

### Step 6: Generate and Run Migrations

```bash
# Generate migrations for all resources
mix ash_postgres.generate_migrations --name add_accounts_domain_resources

# Review the generated migration file in priv/repo/migrations/

# Run migrations
mix ecto.migrate

# If there are issues, rollback and regenerate
mix ecto.rollback
mix ash_postgres.drop_migration --name add_accounts_domain_resources
# Fix issues, then regenerate
```

---

### Step 7: Run All Tests

```bash
# Run all Accounts domain tests
mix test test/pilates_on_phx/accounts/

# Run with coverage
mix test --cover test/pilates_on_phx/accounts/

# Run specific test suites
mix test test/pilates_on_phx/accounts/user_test.exs
mix test test/pilates_on_phx/accounts/organization_test.exs
mix test test/pilates_on_phx/accounts/organization_membership_test.exs
mix test test/pilates_on_phx/accounts/token_test.exs
mix test test/pilates_on_phx/accounts/authentication_integration_test.exs
mix test test/pilates_on_phx/accounts/authorization_policies_test.exs
```

**Target**: 90%+ test coverage

---

## Critical Implementation Notes

### 1. Multi-Organization Membership (CRITICAL!)

**Users MUST support multiple organization memberships** via the `OrganizationMembership` join table:

- User → has_many → OrganizationMemberships
- Organization → has_many → OrganizationMemberships
- User ← many_to_many → Organization (through OrganizationMembership)

**DO NOT** use a simple `belongs_to :organization` on User!

### 2. Password Security

- Use `AshAuthentication.BcryptProvider` for password hashing
- Never store plain-text passwords
- Use `sensitive? true` and `private? true` on `hashed_password`
- Implement proper password strength validation

### 3. Token Security

- Generate unique `jti` (JWT ID) for every token using `Ash.UUID.generate/0`
- Support multiple token types: bearer, refresh, password_reset, email_confirmation
- Implement proper expiration and revocation
- Store metadata in `extra_data` (device info, IP, etc.)

### 4. Multi-Tenant Authorization

**Every query must include actor context**:
```elixir
# ✅ CORRECT
User
|> Ash.Query.filter(role == :instructor)
|> Accounts.read!(actor: current_user)

# ❌ WRONG - No actor, bypasses authorization
User
|> Ash.Query.filter(role == :instructor)
|> Accounts.read!()
```

### 5. Ash 3.0+ API Patterns

Always use modern Ash 3.0+ patterns:

```elixir
# ✅ CORRECT: Actor in changeset
User
|> Ash.Changeset.for_create(:register, attrs)
|> Accounts.create()

# ✅ CORRECT: Actor in operation
User
|> Ash.Changeset.for_update(:update, user, attrs, actor: current_user)
|> Accounts.update()

# ✅ CORRECT: require Ash.Query for filtering
require Ash.Query

User
|> Ash.Query.filter(email == ^email)
|> Accounts.read_one!(actor: current_user)
```

### 6. Testing Strategy

**DO TEST** (Business Logic):
- Custom validations (email format, password strength, timezone validation)
- Authorization policies (multi-tenant isolation, RBAC)
- Business workflows (registration, authentication, token refresh)
- Multi-organization scenarios
- Edge cases and error handling

**DO NOT TEST** (Framework Features):
- Basic Ash CRUD operations
- Sorting and filtering mechanics
- Pagination
- Automatic timestamps

---

## Common Pitfalls to Avoid

### ❌ Circular Dependency in Relationships

**Problem**: Defining many_to_many before join table exists causes compilation errors.

**Solution**: Always implement OrganizationMembership FIRST, then add many_to_many relationships.

### ❌ Missing `require Ash.Query`

**Problem**: Using `Ash.Query.filter/2` without requiring the module causes compile errors.

**Solution**: Add `require Ash.Query` at the top of any module using query filters.

### ❌ No Actor in Policies

**Problem**: Policies that don't check actor context allow unauthorized access.

**Solution**: Always use `authorize_if actor_attribute_equals/2` or `relates_to_actor_via/2`.

### ❌ Weak Password Validation

**Problem**: Allowing weak passwords compromises security.

**Solution**: Implement strong password requirements:
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, symbols
- Use `AshAuthentication.BcryptProvider` with proper cost factor

### ❌ Token Reuse

**Problem**: Not revoking tokens after use allows replay attacks.

**Solution**: Always revoke tokens after critical operations (password reset, email confirmation).

---

## Validation Checklist

Before marking Phase 3 complete, verify:

- [ ] All 4 resources implemented (User, Organization, Token, OrganizationMembership)
- [ ] All resources registered in `PilatesOnPhx.Accounts` domain
- [ ] Migrations generated and applied successfully
- [ ] Multi-organization membership works (users can join multiple orgs)
- [ ] AshAuthentication properly configured
- [ ] Password hashing uses Bcrypt
- [ ] All authorization policies enforce multi-tenant isolation
- [ ] Tokens have unique JTIs
- [ ] All test suites pass (90%+ coverage)
- [ ] Integration tests verify end-to-end flows
- [ ] Authorization tests prove security boundaries
- [ ] No circular dependencies
- [ ] All queries use `actor:` parameter
- [ ] `require Ash.Query` added where needed

---

## Next Steps (Phase 4)

After all tests pass:

1. **Update Linear issue PHX-2** with test results
2. **Verify with `mix test` and `mix precommit`**
3. **Create WIP commit**: `git add . && git commit -m "WIP: PHX-2 - Implement Accounts domain resources (User, Organization, Token, OrganizationMembership)"`
4. **Run full test suite**: `mix test --cover`
5. **Move to Phase 4**: Implementation verification and acceptance criteria validation

---

## Resources and References

### Ash Framework Documentation
- [Ash Domains](https://hexdocs.pm/ash/domains.html)
- [Ash Resources](https://hexdocs.pm/ash/resources.html)
- [Ash Policies](https://hexdocs.pm/ash/policies.html)
- [AshAuthentication](https://hexdocs.pm/ash_authentication)
- [AshPostgres](https://hexdocs.pm/ash_postgres)

### Project-Specific Documentation
- `/Users/wlstory/src/PilatesOnPhx/README.md` - Project setup and overview
- `/Users/wlstory/src/PilatesOnPhx/CLAUDE.md` - Development guidelines
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Detailed patterns and conventions

### Test Files Location
- `/Users/wlstory/src/PilatesOnPhx/test/support/accounts_fixtures.ex`
- `/Users/wlstory/src/PilatesOnPhx/test/pilates_on_phx/accounts/user_test.exs`
- `/Users/wlstory/src/PilatesOnPhx/test/pilates_on_phx/accounts/organization_test.exs`
- `/Users/wlstory/src/PilatesOnPhx/test/pilates_on_phx/accounts/organization_membership_test.exs`
- `/Users/wlstory/src/PilatesOnPhx/test/pilates_on_phx/accounts/token_test.exs`
- `/Users/wlstory/src/PilatesOnPhx/test/pilates_on_phx/accounts/authentication_integration_test.exs`
- `/Users/wlstory/src/PilatesOnPhx/test/pilates_on_phx/accounts/authorization_policies_test.exs`

---

## Questions or Issues?

If you encounter problems during implementation:

1. **Check test output** - Tests provide detailed failure messages
2. **Review Ash documentation** - Many issues are covered in official docs
3. **Verify Ash 3.0+ API** - Ensure using modern patterns with `actor:` parameter
4. **Check circular dependencies** - Implement OrganizationMembership first
5. **Validate migrations** - Review generated SQL before running
6. **Use IEX for debugging** - `iex -S mix phx.server` to test resources interactively

**Remember**: Tests are comprehensive and production-ready. If all tests pass, the implementation is correct. Don't simplify tests to make them pass - fix the implementation instead.
