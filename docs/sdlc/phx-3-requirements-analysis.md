# PHX-3: Studios Domain Implementation - Requirements Analysis

**SDLC Phase 1: Requirements Analysis**
**Date:** 2025-11-15
**Linear Issue:** [PHX-3](https://linear.app/wlstory/issue/PHX-3/)
**Status:** Requirements Analysis Complete

---

## Executive Summary

PHX-3 implements the Studios domain with 4 core resources: Studio, StudioStaff, Room, and Equipment. This domain manages physical Pilates studio locations, staff assignments, facility management, and equipment inventory. The Studios domain is the critical path blocker for both Classes (PHX-4) and Bookings (PHX-5) domains.

**Scope:** Implement all 4 Studios domain resources with comprehensive test coverage (85%+), multi-tenant policies, and cross-domain relationships to Accounts.

**Dependencies:**
- ✅ PHX-1 (Architecture Design) - Complete
- ✅ PHX-2 (Accounts Domain) - Complete with 100% test coverage

**Blocks:**
- ❌ PHX-4 (Classes Domain) - Needs Studio + Room resources
- ❌ PHX-5 (Bookings Domain) - Needs Studio resource

---

## Business Requirements

### User Stories

**Primary User Story (from PHX-3):**
> As a studio owner, I can manage multiple studio locations with their own configurations and settings, so that each physical location can operate independently while being part of my organization.

**Additional User Stories:**

1. **Staff Management**
   > As a studio owner, I can assign instructors and staff to specific studios with defined roles and permissions

2. **Facility Management**
   > As a studio owner, I can define rooms within my studios and track their capacity and availability

3. **Equipment Inventory**
   > As a studio owner, I can manage equipment inventory across studios and rooms for maintenance and scheduling

### Use Cases

```gherkin
Feature: Studio Management

Scenario: [Happy Path] Owner creates a new studio location
  Given an authenticated user with "owner" role
  And their organization has id "org-123"
  When they create a studio with:
    | name              | "Downtown Pilates Studio"          |
    | address           | "123 Main St, New York, NY 10001"  |
    | timezone          | "America/New_York"                 |
    | max_capacity      | 50                                  |
    | operating_hours   | {"mon": "6:00-20:00", ...}         |
  Then a Studio resource is created linked to organization "org-123"
  And the studio has default settings applied
  And the studio is marked as active
  And the owner has full access to the studio

Scenario: [Happy Path] Owner assigns instructor to studio
  Given a studio "Downtown Pilates Studio"
  And a user with email "instructor@example.com" in the organization
  When the owner creates a StudioStaff assignment:
    | role        | "instructor" |
    | permissions | ["teach", "view_schedule"] |
  Then the instructor is assigned to the studio
  And the instructor can access the studio's schedule
  And the instructor cannot modify studio settings

Scenario: [Happy Path] Owner creates rooms within studio
  Given a studio "Downtown Pilates Studio"
  When the owner creates rooms:
    | name          | capacity | equipment_required     |
    | "Studio A"    | 12       | ["reformers"]          |
    | "Mat Room"    | 20       | ["mats", "blocks"]     |
  Then 2 Room resources are created
  And each room is linked to the studio
  And rooms can be used for class scheduling

Scenario: [Edge Case] Organization has multiple studio locations
  Given an organization with 3 studio locations:
    | "Downtown Studio" | "Uptown Studio" | "Brooklyn Studio" |
  When a user views studios for the organization
  Then all studios are listed with their details
  And each studio maintains separate class schedules
  And data isolation is enforced between studios

Scenario: [Edge Case] Equipment shared across multiple rooms
  Given a studio with 2 rooms
  And equipment items marked as "portable"
  When the owner assigns equipment:
    | name       | location   | portable |
    | "Reformer" | "Studio A" | false    |
    | "Mat"      | "Mobile"   | true     |
  Then portable equipment can be scheduled in any room
  And fixed equipment is room-specific
```

---

## Technical Specification

### Resource 1: Studio

**Purpose:** Manages physical Pilates studio locations with configuration, settings, and operating parameters.

**Attributes:**

```elixir
attributes do
  uuid_primary_key :id

  attribute :name, :string do
    allow_nil? false
    public? true
    constraints min_length: 1, max_length: 255, trim?: true
  end

  attribute :address, :string do
    allow_nil? false
    public? true
    constraints min_length: 1, max_length: 500
  end

  attribute :timezone, :string do
    allow_nil? false
    default "America/New_York"
    public? true
    # Validate against IANA timezone list (reuse pattern from Organization)
  end

  attribute :max_capacity, :integer do
    allow_nil? false
    default 50
    public? true
    constraints min: 1, max: 500
  end

  attribute :operating_hours, :map do
    allow_nil? false
    default %{
      "mon" => "6:00-20:00",
      "tue" => "6:00-20:00",
      "wed" => "6:00-20:00",
      "thu" => "6:00-20:00",
      "fri" => "6:00-20:00",
      "sat" => "8:00-18:00",
      "sun" => "8:00-16:00"
    }
    public? true
  end

  attribute :settings, :map do
    allow_nil? false
    default %{}
    public? true
    # Studio-specific settings (branding, policies, etc.)
  end

  attribute :active, :boolean do
    allow_nil? false
    default true
    public? true
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**Relationships:**

```elixir
relationships do
  # Cross-domain relationship to Accounts
  belongs_to :organization, PilatesOnPhx.Accounts.Organization do
    allow_nil? false
    attribute_writable? true
  end

  # Within Studios domain
  has_many :staff_assignments, PilatesOnPhx.Studios.StudioStaff do
    destination_attribute :studio_id
  end

  has_many :rooms, PilatesOnPhx.Studios.Room do
    destination_attribute :studio_id
  end

  has_many :equipment, PilatesOnPhx.Studios.Equipment do
    destination_attribute :studio_id
  end
end
```

**Actions:**

```elixir
actions do
  defaults [:read]

  create :create do
    accept [:name, :address, :timezone, :max_capacity, :operating_hours, :settings, :active, :organization_id]
  end

  update :update do
    primary? true
    require_atomic? false
    accept [:name, :address, :timezone, :max_capacity, :operating_hours, :settings, :active]
  end

  update :activate do
    accept []
    change set_attribute(:active, true)
    require_atomic? false
  end

  update :deactivate do
    accept []
    change set_attribute(:active, false)
    require_atomic? false
  end

  destroy :destroy do
    primary? true
    require_atomic? false
  end
end
```

**Authorization Policies:**

```elixir
policies do
  bypass expr(^actor(:bypass_strict_access) == true) do
    authorize_if always()
  end

  policy action_type(:read) do
    # All organization members can read studios in their organization
    authorize_if actor_present()
  end

  policy action_type(:create) do
    # Only organization owners can create studios
    authorize_if expr(exists(organization.memberships, user_id == ^actor(:id) and role == :owner))
  end

  policy action_type([:update, :destroy]) do
    # Only organization owners can manage studios
    authorize_if expr(exists(organization.memberships, user_id == ^actor(:id) and role == :owner))
  end
end
```

**Preparations:**

```elixir
preparations do
  prepare fn query, context ->
    require Ash.Query
    actor = Map.get(context, :actor)

    if actor && !Map.get(actor, :bypass_strict_access, false) do
      # Get actor's organization IDs from memberships
      actor_org_ids = get_actor_organization_ids(actor)

      if Enum.empty?(actor_org_ids) do
        Ash.Query.filter(query, false)
      else
        Ash.Query.filter(query, organization_id in ^actor_org_ids)
      end
    else
      query
    end
  end
end
```

**Validations:**

- Timezone must be valid IANA timezone (reuse Organization validation)
- Operating hours must be valid time ranges
- Max capacity must be positive integer

---

### Resource 2: StudioStaff

**Purpose:** Manages staff assignments and permissions for studio operations.

**Attributes:**

```elixir
attributes do
  uuid_primary_key :id

  attribute :role, :atom do
    allow_nil? false
    public? true
    constraints one_of: [:instructor, :front_desk, :manager]
  end

  attribute :permissions, {:array, :string} do
    allow_nil? false
    default []
    public? true
    # ["teach", "view_schedule", "manage_equipment", etc.]
  end

  attribute :notes, :string do
    allow_nil? true
    public? true
    constraints max_length: 1000
  end

  attribute :active, :boolean do
    allow_nil? false
    default true
    public? true
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**Relationships:**

```elixir
relationships do
  belongs_to :studio, PilatesOnPhx.Studios.Studio do
    allow_nil? false
    attribute_writable? true
  end

  # Cross-domain relationship to Accounts
  belongs_to :user, PilatesOnPhx.Accounts.User do
    allow_nil? false
    attribute_writable? true
  end
end
```

**Identities:**

```elixir
identities do
  identity :unique_staff_assignment, [:studio_id, :user_id]
end
```

**Actions:**

```elixir
actions do
  defaults [:read]

  create :assign do
    accept [:studio_id, :user_id, :role, :permissions, :notes, :active]
  end

  update :update do
    primary? true
    require_atomic? false
    accept [:role, :permissions, :notes, :active]
  end

  destroy :remove do
    primary? true
    require_atomic? false
  end
end
```

**Authorization Policies:**

```elixir
policies do
  bypass expr(^actor(:bypass_strict_access) == true) do
    authorize_if always()
  end

  policy action_type(:read) do
    # Staff can read their own assignments
    authorize_if expr(user_id == ^actor(:id))
    # Organization members can read staff in their studios
    authorize_if actor_present()
  end

  policy action_type([:create, :update, :destroy]) do
    # Only organization owners can manage staff assignments
    authorize_if expr(exists(studio.organization.memberships, user_id == ^actor(:id) and role == :owner))
  end
end
```

---

### Resource 3: Room

**Purpose:** Manages physical spaces within studios where classes are held.

**Attributes:**

```elixir
attributes do
  uuid_primary_key :id

  attribute :name, :string do
    allow_nil? false
    public? true
    constraints min_length: 1, max_length: 100
  end

  attribute :capacity, :integer do
    allow_nil? false
    public? true
    constraints min: 1, max: 100
  end

  attribute :settings, :map do
    allow_nil? false
    default %{}
    public? true
    # Room-specific settings (temperature, lighting, etc.)
  end

  attribute :active, :boolean do
    allow_nil? false
    default true
    public? true
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**Relationships:**

```elixir
relationships do
  belongs_to :studio, PilatesOnPhx.Studios.Studio do
    allow_nil? false
    attribute_writable? true
  end

  has_many :equipment, PilatesOnPhx.Studios.Equipment do
    destination_attribute :room_id
  end
end
```

**Identities:**

```elixir
identities do
  identity :unique_room_name_per_studio, [:studio_id, :name]
end
```

**Actions:**

```elixir
actions do
  defaults [:read]

  create :create do
    accept [:studio_id, :name, :capacity, :settings, :active]
  end

  update :update do
    primary? true
    require_atomic? false
    accept [:name, :capacity, :settings, :active]
  end

  destroy :destroy do
    primary? true
    require_atomic? false
  end
end
```

**Authorization Policies:**

```elixir
policies do
  bypass expr(^actor(:bypass_strict_access) == true) do
    authorize_if always()
  end

  policy action_type(:read) do
    # All organization members can read rooms
    authorize_if actor_present()
  end

  policy action_type([:create, :update, :destroy]) do
    # Only organization owners can manage rooms
    authorize_if expr(exists(studio.organization.memberships, user_id == ^actor(:id) and role == :owner))
  end
end
```

---

### Resource 4: Equipment

**Purpose:** Manages equipment inventory and availability tracking.

**Attributes:**

```elixir
attributes do
  uuid_primary_key :id

  attribute :name, :string do
    allow_nil? false
    public? true
    constraints min_length: 1, max_length: 100
  end

  attribute :equipment_type, :string do
    allow_nil? false
    public? true
    # "reformer", "mat", "cadillac", "chair", "barrel", etc.
  end

  attribute :serial_number, :string do
    allow_nil? true
    public? true
  end

  attribute :portable, :boolean do
    allow_nil? false
    default false
    public? true
    # Can equipment be moved between rooms?
  end

  attribute :maintenance_notes, :string do
    allow_nil? true
    public? true
    constraints max_length: 1000
  end

  attribute :active, :boolean do
    allow_nil? false
    default true
    public? true
  end

  create_timestamp :inserted_at
  update_timestamp :updated_at
end
```

**Relationships:**

```elixir
relationships do
  belongs_to :studio, PilatesOnPhx.Studios.Studio do
    allow_nil? false
    attribute_writable? true
  end

  belongs_to :room, PilatesOnPhx.Studios.Room do
    allow_nil? true
    attribute_writable? true
    # NULL if portable/unassigned
  end
end
```

**Actions:**

```elixir
actions do
  defaults [:read]

  create :create do
    accept [:studio_id, :room_id, :name, :equipment_type, :serial_number, :portable, :maintenance_notes, :active]
  end

  update :update do
    primary? true
    require_atomic? false
    accept [:room_id, :name, :equipment_type, :serial_number, :portable, :maintenance_notes, :active]
  end

  destroy :destroy do
    primary? true
    require_atomic? false
  end
end
```

**Authorization Policies:**

```elixir
policies do
  bypass expr(^actor(:bypass_strict_access) == true) do
    authorize_if always()
  end

  policy action_type(:read) do
    # All organization members can read equipment
    authorize_if actor_present()
  end

  policy action_type([:create, :update, :destroy]) do
    # Only organization owners can manage equipment
    authorize_if expr(exists(studio.organization.memberships, user_id == ^actor(:id) and role == :owner))
  end
end
```

---

## Database Schema

### Tables

**studios**
```sql
CREATE TABLE studios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(500) NOT NULL,
  timezone VARCHAR(100) NOT NULL DEFAULT 'America/New_York',
  max_capacity INTEGER NOT NULL DEFAULT 50 CHECK (max_capacity >= 1 AND max_capacity <= 500),
  operating_hours JSONB NOT NULL DEFAULT '{}',
  settings JSONB NOT NULL DEFAULT '{}',
  active BOOLEAN NOT NULL DEFAULT true,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX studios_organization_id_index ON studios(organization_id);
CREATE INDEX studios_active_index ON studios(active);
```

**studio_staff**
```sql
CREATE TABLE studio_staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL CHECK (role IN ('instructor', 'front_desk', 'manager')),
  permissions TEXT[] NOT NULL DEFAULT '{}',
  notes TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  CONSTRAINT unique_staff_assignment UNIQUE (studio_id, user_id)
);

CREATE INDEX studio_staff_studio_id_index ON studio_staff(studio_id);
CREATE INDEX studio_staff_user_id_index ON studio_staff(user_id);
CREATE INDEX studio_staff_role_index ON studio_staff(role);
```

**rooms**
```sql
CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  capacity INTEGER NOT NULL CHECK (capacity >= 1 AND capacity <= 100),
  settings JSONB NOT NULL DEFAULT '{}',
  active BOOLEAN NOT NULL DEFAULT true,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  CONSTRAINT unique_room_name_per_studio UNIQUE (studio_id, name)
);

CREATE INDEX rooms_studio_id_index ON rooms(studio_id);
CREATE INDEX rooms_active_index ON rooms(active);
```

**equipment**
```sql
CREATE TABLE equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
  name VARCHAR(100) NOT NULL,
  equipment_type VARCHAR(50) NOT NULL,
  serial_number VARCHAR(100),
  portable BOOLEAN NOT NULL DEFAULT false,
  maintenance_notes TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX equipment_studio_id_index ON equipment(studio_id);
CREATE INDEX equipment_room_id_index ON equipment(room_id) WHERE room_id IS NOT NULL;
CREATE INDEX equipment_type_index ON equipment(equipment_type);
CREATE INDEX equipment_portable_index ON equipment(portable);
```

---

## Test Coverage Requirements

**Target:** 85%+ test coverage for all Studios domain resources

### Test Categories

**1. Resource CRUD Tests** (`test/pilates_on_phx/studios/`)

For each resource (Studio, StudioStaff, Room, Equipment):

- ✅ Create with valid attributes
- ✅ Create with missing required attributes (validation errors)
- ✅ Read individual resource
- ✅ Read list of resources
- ✅ Update with valid attributes
- ✅ Update with invalid attributes
- ✅ Delete resource
- ✅ Soft delete behavior (if using AshArchival)

**2. Authorization Policy Tests** (`test/pilates_on_phx/studios/authorization_policies_test.exs`)

- ✅ Owners can create/update/delete studios
- ✅ Admins cannot create studios
- ✅ Members cannot create studios
- ✅ Staff can read their assigned studios
- ✅ Staff cannot read other studios
- ✅ Multi-tenant isolation enforced (users cannot access other organizations' studios)

**3. Relationship Tests** (`test/pilates_on_phx/studios/relationships_test.exs`)

- ✅ Studio belongs to Organization (cross-domain)
- ✅ Studio has many staff assignments
- ✅ Studio has many rooms
- ✅ Studio has many equipment
- ✅ StudioStaff belongs to User (cross-domain)
- ✅ Room belongs to Studio
- ✅ Equipment belongs to Studio and Room

**4. Validation Tests**

- ✅ Timezone validation (valid IANA timezones)
- ✅ Operating hours format validation
- ✅ Capacity constraints (min/max)
- ✅ Unique constraints (room names per studio, staff assignments)

**5. Integration Tests** (`test/pilates_on_phx/studios/integration_test.exs`)

- ✅ Create studio with rooms and equipment
- ✅ Assign staff to studio
- ✅ Multi-tenant data isolation
- ✅ Cascade deletes

---

## Acceptance Criteria Checklist

From Linear issue PHX-3:

- [ ] 1. Studio resource defined with Ash Postgres data layer
- [ ] 2. Studio attributes: name, address, operating_hours, max_capacity, settings, active, timezone
- [ ] 3. Studio belongs to Organization (cross-domain relationship)
- [ ] 4. Authorization policies enforce organization-based access
- [ ] 5. Operating hours stored as structured data (JSON/map)
- [ ] 6. Capacity limits used for class scheduling validation
- [ ] 7. Soft delete support using AshArchival (if implemented)
- [ ] 8. Migrations generated for studios table
- [ ] 9. Tests cover multi-tenant isolation and authorization
- [ ] 10. Tests cover capacity limit enforcement

**Additional Acceptance Criteria:**

- [ ] 11. StudioStaff resource with unique constraint on studio_id + user_id
- [ ] 12. Room resource with unique constraint on studio_id + name
- [ ] 13. Equipment resource with portable/fixed location support
- [ ] 14. All 4 resources registered in Studios domain
- [ ] 15. Test coverage ≥ 85% for all Studios resources
- [ ] 16. All `mix precommit` checks pass (format, credo, dialyzer, tests)
- [ ] 17. Migrations run successfully
- [ ] 18. Documentation updated in Studios domain moduledoc

---

## Implementation Plan

### Milestone 1: Core Studio Resource (Days 1-2)

**Tasks:**
1. Create `lib/pilates_on_phx/studios/studio.ex`
2. Define attributes, relationships, actions
3. Implement authorization policies
4. Implement timezone validation
5. Create `test/pilates_on_phx/studios/studio_test.exs`
6. Write comprehensive tests (CRUD, authorization, validation)
7. Generate and run migrations
8. Verify multi-tenant isolation

**Success Criteria:**
- Studio resource fully functional
- Tests passing with 85%+ coverage
- Migrations applied successfully

### Milestone 2: StudioStaff Resource (Day 2)

**Tasks:**
1. Create `lib/pilates_on_phx/studios/studio_staff.ex`
2. Define relationships to Studio and User
3. Implement unique constraint
4. Create `test/pilates_on_phx/studios/studio_staff_test.exs`
5. Test staff assignment workflows
6. Generate and run migrations

**Success Criteria:**
- Staff assignments working
- Authorization policies enforced
- Tests passing

### Milestone 3: Room and Equipment Resources (Day 3)

**Tasks:**
1. Create `lib/pilates_on_phx/studios/room.ex`
2. Create `lib/pilates_on_phx/studios/equipment.ex`
3. Implement relationships and constraints
4. Create test files for both resources
5. Test portable vs. fixed equipment
6. Generate and run migrations

**Success Criteria:**
- All 4 resources complete
- Cross-resource relationships working
- Tests passing

### Milestone 4: Integration and Quality Gate (Day 4)

**Tasks:**
1. Create integration test suite
2. Test complete studio setup workflow
3. Verify multi-tenant isolation across all resources
4. Run `mix precommit` and fix any issues
5. Update domain moduledoc
6. Register all resources in `lib/pilates_on_phx/studios.ex`

**Success Criteria:**
- All tests passing (85%+ coverage)
- `mix precommit` clean
- Documentation complete

---

## Cross-Domain Dependencies

### Dependencies on Accounts Domain

**Required Resources:**
- ✅ `Accounts.Organization` - Studios belong to organizations
- ✅ `Accounts.User` - StudioStaff references users
- ✅ `Accounts.OrganizationMembership` - Policy checks for owner role

**Authorization Pattern:**
```elixir
# Check if actor is owner of studio's organization
authorize_if expr(exists(organization.memberships, user_id == ^actor(:id) and role == :owner))
```

### Blocks for Future Domains

**Classes Domain (PHX-4) Dependencies:**
- Studio resource (for studio_id foreign key)
- Room resource (for room_id foreign key)

**Bookings Domain (PHX-5) Dependencies:**
- Studio resource (for studio_id in Client, Package)

---

## Risk Assessment

### Technical Risks

**Risk 1: Cross-Domain Policy Evaluation**
- **Description:** Policy checks referencing Organization.memberships may have timing issues
- **Mitigation:** Use same pattern as Accounts domain, load memberships in preparations
- **Likelihood:** Medium
- **Impact:** High

**Risk 2: Migration Dependencies**
- **Description:** Migrations depend on organizations and users tables existing
- **Mitigation:** Ensure PHX-2 migrations run first, add explicit dependencies
- **Likelihood:** Low
- **Impact:** Medium

**Risk 3: Test Coverage Gaps**
- **Description:** Complex authorization scenarios may be undertested
- **Mitigation:** Follow TDD strictly, write tests before implementation
- **Likelihood:** Medium
- **Impact:** Medium

### Process Risks

**Risk 1: Scope Creep**
- **Description:** Temptation to add features beyond acceptance criteria
- **Mitigation:** Stick to defined acceptance criteria, track new features separately
- **Likelihood:** Medium
- **Impact:** Low

---

## Phase 2 Coordination Instructions

**Status:** Phase 1 (Requirements Analysis) COMPLETE

**Next Phase:** Phase 2 (TDD Setup) - Design comprehensive test suite

**Invoke:** `catalio-test-strategist` agent

**Context to Provide:**
1. This requirements document
2. Reference to Accounts domain test patterns (`test/pilates_on_phx/accounts/`)
3. Test coverage target: 85%+
4. TDD approach: Write tests first, then implementation

**Expected Deliverables from Phase 2:**
1. Test file structure and organization
2. Test fixtures and factories
3. Comprehensive test cases for all 4 resources
4. Authorization policy test scenarios
5. Integration test plan

---

## Appendix A: Example Code Patterns

### Example: Creating a Studio

```elixir
# As owner
studio =
  Studio
  |> Ash.Changeset.for_create(:create, %{
    organization_id: org.id,
    name: "Downtown Pilates Studio",
    address: "123 Main St, New York, NY 10001",
    timezone: "America/New_York",
    max_capacity: 50,
    operating_hours: %{
      "mon" => "6:00-20:00",
      "tue" => "6:00-20:00",
      "wed" => "6:00-20:00",
      "thu" => "6:00-20:00",
      "fri" => "6:00-20:00",
      "sat" => "8:00-18:00",
      "sun" => "8:00-16:00"
    }
  }, actor: owner)
  |> Ash.create!(domain: Studios)
```

### Example: Assigning Staff

```elixir
# As owner
staff_assignment =
  StudioStaff
  |> Ash.Changeset.for_create(:assign, %{
    studio_id: studio.id,
    user_id: instructor.id,
    role: :instructor,
    permissions: ["teach", "view_schedule"]
  }, actor: owner)
  |> Ash.create!(domain: Studios)
```

### Example: Creating Rooms

```elixir
# As owner
room =
  Room
  |> Ash.Changeset.for_create(:create, %{
    studio_id: studio.id,
    name: "Studio A",
    capacity: 12
  }, actor: owner)
  |> Ash.create!(domain: Studios)
```

---

**Requirements Analysis Complete**
**Ready for Phase 2: TDD Setup**
