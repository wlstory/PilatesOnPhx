# PilatesOnPhx Domain Architecture (4 Strategic Domains)

## Overview

This document defines the **4-domain architecture** for PilatesOnPhx, a strategic simplification from the initial 5-domain design. This architecture optimizes for domain cohesion, reduces cross-domain dependencies, and aligns with the core business workflows.

## Strategic Domain Breakdown

```elixir
# config/config.exs
config :pilates_on_phx, :ash_domains, [
  PilatesOnPhx.Accounts,  # Authentication & Multi-Tenant
  PilatesOnPhx.Studios,   # Studio Management
  PilatesOnPhx.Classes,   # Class Management + Scheduling + Attendance
  PilatesOnPhx.Bookings   # THE CORE WORKFLOW: Client + Package + Booking + Waitlist
]
```

---

## Domain 1: Accounts (Authentication & Multi-Tenant Foundation)

**Purpose**: Security boundary and authentication foundation for the entire system.

### Resources

- **User** - Authentication, roles (owner, instructor, client)
- **Organization** - Top-level tenant or Studio relationship
- **Token** - Auth tokens (managed by AshAuthentication)

### Key Responsibilities

- User authentication and session management
- Role-based access control (RBAC)
- Multi-tenant security boundary
- Token lifecycle management
- Password reset and account recovery

### Why Separate?

- **Security boundary**: Authentication logic must be isolated
- **Different access patterns**: Auth flows vs business operations
- **Framework integration**: AshAuthentication requires dedicated domain
- **Cross-domain concern**: Every domain depends on Accounts for actor context

### Key Business Rules

- Users can have multiple roles across different studios (owner, instructor, client)
- Organization provides top-level tenant isolation
- All domain operations require authenticated actor
- Token expiration and refresh handled automatically

---

## Domain 2: Studios (Studio Management & Configuration)

**Purpose**: Studio entity management and administrative configuration.

### Resources

- **Studio** - Studio profile, settings, configuration
- **StudioStaff** - Staff assignments and permissions
- **Room** - Physical spaces within studio
- **Equipment** - Studio equipment inventory

### Key Responsibilities

- Studio profile and settings management
- Staff onboarding and permission management
- Physical resource tracking (rooms, equipment)
- Studio-level configuration (hours, policies, branding)
- Multi-location support for studio chains

### Why Separate?

- **Distinct lifecycle**: Studio setup happens before classes/bookings
- **Admin-focused**: Different user personas (owners/admins)
- **Configuration layer**: Provides context for other domains
- **Infrequent changes**: Studio data changes less frequently than bookings

### Key Business Rules

- Studios are multi-tenant isolated
- Staff can have different roles per studio
- Rooms and equipment belong to specific studios
- Studio settings control class and booking behavior

---

## Domain 3: Classes (Class Management + Scheduling + Attendance + Instructors)

**Purpose**: Everything related to class types, schedules, sessions, and attendance tracking.

### Resources

- **ClassType** - Reformer, Mat, Barre, Duet, Private, etc.
- **ClassSchedule** - Recurring schedule templates (e.g., "Reformer every Monday 9am")
- **ClassSession** - Specific instances of scheduled classes (e.g., "Reformer on 2025-01-15 9am")
- **Attendance** - Check-ins, no-shows, late cancellations
- **Instructor** - Instructor profiles (could be User with role)

### Key Responsibilities

- Defining class types and their properties
- Creating recurring class schedules
- Generating individual class sessions
- Managing instructor assignments
- Tracking attendance and check-ins
- Capacity management per session
- Automated class generation (via Oban)

### Why Combined?

- **High cohesion**: Schedules, sessions, and attendance are inseparable
- **Shared lifecycle**: Changes to schedules affect sessions and attendance
- **Common queries**: "Show me all sessions for this schedule" or "attendance for this session"
- **Reduced complexity**: Fewer cross-domain calls

### Key Business Rules

- ClassSchedule templates generate ClassSession instances
- Sessions have capacity limits tied to studio rooms
- Attendance records require valid bookings
- Instructors can only be assigned to sessions at their studio
- Recurring class generation runs nightly via Oban

---

## Domain 4: Bookings (THE CORE WORKFLOW)

**Purpose**: The primary user-facing workflow - clients purchasing packages, booking classes, and managing waitlists.

### Resources

- **Client** - Client profiles, preferences, medical history
- **Package** - Credit packages and membership definitions
- **ClientPackage** - Client's purchased package instance with remaining credits
- **Booking** - Class reservations linked to sessions
- **Waitlist** - Waitlist entries when classes are full
- **Payment** - Payment records (start simple, expand with Stripe)

### Key Responsibilities

- Client profile and preference management
- Package purchase and credit tracking
- Class booking with credit redemption
- Waitlist management and auto-promotion
- Payment processing (initially simple, then Stripe integration)
- Booking cancellations and refunds
- No-show and late cancellation penalties

### Why Combined?

- **Inseparable workflow**: Booking requires client + package + class session
- **Atomic operations**: Credit deduction and booking creation must be atomic
- **Business rules span resources**: "Client with valid package can book if credits available"
- **Common queries**: "Show client's bookings and remaining credits"

### Key Business Rules

- Clients purchase packages (one-time or recurring)
- Bookings consume credits from client packages
- Waitlist auto-promotes when spots open
- Cancellation policies based on time before class
- No-shows result in credit deduction
- Package expiration and renewal automation

---

## Cross-Domain Interactions

### Accounts → All Domains
- Every operation requires `actor` from Accounts.User
- Multi-tenant isolation enforced via actor's organization/studio context

### Studios → Classes
- Classes.ClassSession belongs to Studios.Studio
- Classes.Instructor belongs to Studios.Studio (via StudioStaff)

### Classes → Bookings
- Bookings.Booking references Classes.ClassSession
- Bookings checks Classes.ClassSession capacity

### Studios → Bookings
- Bookings.Client belongs to Studios.Studio
- Package purchases tied to specific studios

---

## Migration from 5-Domain to 4-Domain Architecture

### Changes from Original Design

**Merged Domains:**
- **Clients** + **Bookings** → **Bookings** (single domain)
  - Rationale: Client and booking operations are inseparable in practice

**Retained Domains:**
- **Accounts** (unchanged)
- **Studios** (unchanged)
- **Classes** (unchanged, includes instructors and attendance)

### Impact on Sprint 1 Issues

**Issues Requiring Updates:**

1. **PHX-1**: Design Ash Domain Architecture
   - Update from 5 domains to 4 domains
   - Revise domain descriptions
   - Update resource allocation

2. **PHX-5 + PHX-6**: Merge into single issue
   - New Title: "Define Core Resources for Bookings Domain"
   - Covers: Client, Package, ClientPackage, Booking, Waitlist, Payment

**Issues Unchanged:**
- PHX-2: Accounts Domain (no changes)
- PHX-3: Studios Domain (no changes)
- PHX-4: Classes Domain (no changes)
- PHX-7: Multi-tenant policies (minor updates to reflect 4 domains)
- PHX-8: Testing strategy (minor updates)

---

## Benefits of 4-Domain Architecture

### Reduced Complexity
- Fewer domain boundaries to manage
- Fewer cross-domain authorization checks
- Simpler mental model for developers

### Improved Cohesion
- Bookings domain contains the complete booking workflow
- Classes domain owns the complete class lifecycle
- Natural aggregation boundaries

### Better Performance
- Fewer cross-domain queries
- Atomic operations within single domain
- Reduced network/query overhead

### Clearer Ownership
- Each domain has clear business purpose
- Less ambiguity about where features belong
- Easier onboarding for new developers

---

## Implementation Roadmap

### Sprint 1: Foundation
- PHX-1: Domain architecture design (4 domains)
- PHX-2: Accounts domain resources
- PHX-3: Studios domain resources
- PHX-4: Classes domain resources
- PHX-5+6 (merged): Bookings domain resources
- PHX-7: Multi-tenant policies
- PHX-8: Testing strategy

### Sprint 2: Core Workflows
- Studio onboarding wizard
- Class scheduling and recurring templates
- Basic booking workflow
- Client dashboards

### Sprint 3: Automation & Advanced Features
- Recurring class generation (Oban)
- Attendance tracking and check-in
- Waitlist automation
- Email/SMS reminders

### Sprint 4: Integrations & Polish
- Stripe payment integration
- Advanced reporting
- Mobile PWA features
- Analytics dashboards

---

## Domain Design Principles

### 1. Multi-Tenant Isolation
Every domain enforces studio-level isolation via Ash policies:

```elixir
policies do
  policy action_type(:read) do
    authorize_if actor_attribute_equals(:studio_id, :studio_id)
  end
end
```

### 2. Actor-Based Authorization
All operations require authenticated actor:

```elixir
Ash.Changeset.for_create(Resource, :action, attrs, actor: current_user)
```

### 3. Domain-Driven Design
- Resources organized by domain
- Business logic encapsulated in actions
- Cross-domain queries minimized

### 4. Testability
- Each domain independently testable
- Business logic tests focus on domain rules
- Integration tests for cross-domain workflows

---

## References

- **CLAUDE.md**: Lines 113-124 (Ash Domains section)
- **AGENTS.md**: Phoenix/Ash patterns and conventions
- **config/config.exs**: Domain configuration under `:ash_domains`

