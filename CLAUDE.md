# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PilatesOnPhx is a comprehensive Pilates studio management application built with Phoenix/Elixir/Ash. This project is structurally based on the Catalio application and follows the same architectural patterns and development standards.

## Related Documentation

- **[README.md](README.md)** - Project overview, setup, and getting started guide
- **[AGENTS.md](AGENTS.md)** - Detailed Phoenix/Elixir/Ash development patterns and conventions

## Essential Development Commands

### Project Setup

- `mix setup` - Install dependencies, run migrations, setup assets, and seed database
- `mix phx.server` - Start Phoenix development server on <http://localhost:4000>
- `iex -S mix phx.server` - Start server with interactive Elixir shell

### Interactive Development and Testing

- **ALWAYS** use IEX for testing and experimentation instead of creating temporary files
- `iex -S mix` - Load project context for testing resources and functions
- `iex -S mix phx.server` - Load with Phoenix server for web testing
- Test functions directly: `MyModule.my_function(args)`
- Create resources: `MyResource |> Ash.Changeset.for_create(:create, attrs) |> Ash.create!()`
- Query data: `MyResource |> Ash.read!()`
- Import modules: `import MyModule`
- Reload code after changes: `r(MyModule)`
- **NEVER** create temporary test files that clutter the repository

### Development Workflow

- `mix precommit` - Run comprehensive quality checks before committing: compile with warnings as errors, check unused deps, format code, credo, sobelow, deps audit, dialyzer, and run tests with coverage
- `mix test` - Run all tests with coverage enabled
- `mix test test/specific_test.exs` - Run specific test file
- `mix test --failed` - Re-run only previously failed tests
- `mix format` - Format Elixir code according to project standards

### Git Workflow - WIP Commits

- **ALWAYS** make frequent WIP (Work In Progress) commits during development
- Use descriptive WIP commit messages: `WIP: Implement class scheduling feature`
- Make WIP commits after each significant change or fix attempt
- This enables easy rollback to working states during complex debugging
- Example pattern:

  ```bash
  git add . && git commit -m "WIP: Add explicit create action to Class resource"
  git add . && git commit -m "WIP: Fix class scheduling with proper tenant handling"
  git add . && git commit -m "WIP: Remove stale references from codebase"
  ```

- **NEVER** rewrite tests to make them simple just to get basic tests working
- **ALWAYS** maintain comprehensive test coverage targeting 90%+
- **FOCUS ON BUSINESS LOGIC** - Test PilatesOnPhx's custom validations, actions, policies, and domain rules
- **DO NOT TEST ASH FRAMEWORK** - Skip testing basic Ash features like sorting, filtering, pagination
- **TEST PILATESONPHX-SPECIFIC FEATURES**: Custom validations, business rules, domain actions, authorization policies
- **ALWAYS** handle complex scenarios properly using enterprise patterns
- Tests must demonstrate production-ready quality, not simplified workarounds

### Assets and Building

- `mix assets.setup` - Install Tailwind CSS and esbuild if missing
- `mix assets.build` - Build CSS and JavaScript assets for development
- `mix assets.deploy` - Build and minify assets for production

### Database Operations

- `mix ash.setup` - Setup Ash resources and run migrations
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop, recreate, and migrate database

## Critical Thinking and Quality Standards

### Development Mindset - CRITICAL REQUIREMENT

- **Always** Be extraordinarily skeptical of your own correctness or stated assumptions
- **Always** Live in constant fear of being wrong while maintaining productive output
- **When appropriate** Broaden inquiry beyond stated assumptions for unconventional solutions
- **Always** Red team everything - take a critical second look before declaring anything complete
- **Never** accept first solutions without exploring alternatives and edge cases
- **Always** Question whether the approach truly solves the root problem

### Agent Collaboration Guidelines

When working with sub agents, ensure they follow these same critical thinking principles:

- Extreme skepticism of assumptions and stated requirements
- Broad inquiry beyond conventional solutions to find better approaches
- Red team analysis before declaring any work complete or functional
- Self-doubt tempered with productive problem-solving

## Architecture Overview

This is a Phoenix web application built with the **Ash Framework** for resource management and authentication. The application follows Ash's domain-driven design patterns.

### Core Technology Stack

- **Phoenix 1.8** with LiveView for real-time web interfaces
- **Ash Framework 3.0+** for declarative resource definitions and business logic
- **Ash Authentication** for user management and auth flows
- **Ash Admin** for administrative interfaces (dev only)
- **Oban** for background job processing
- **PostgreSQL** with Ash Postgres data layer
- **Tailwind CSS** for styling
- **esbuild** for JavaScript bundling

### Key Architectural Components

#### Ash Domains

The application uses strategic domain organization:

- `PilatesOnPhx.Accounts` - User authentication, organization management, and tokens
- `PilatesOnPhx.Studios` - Studio management and configuration
- `PilatesOnPhx.Classes` - Class scheduling, types, and management
- `PilatesOnPhx.Clients` - Client management and profiles
- `PilatesOnPhx.Bookings` - Class bookings and waitlists
- Domain configuration in `config/config.exs` under `:ash_domains`

**Note:** The architecture is designed for future expansion. Additional domains may be added as features are implemented.

#### Authentication System

- Uses AshAuthentication with token-based auth
- Tokens stored in `PilatesOnPhx.Accounts.Token` resource
- User resource in `PilatesOnPhx.Accounts.User`
- Authentication routes and controllers in `lib/pilates_on_phx_web/`
- Auth overrides in `PilatesOnPhxWeb.AuthOverrides`

#### Background Jobs

- Oban configured for job processing
- Ash Oban integration for domain-aware job handling
- Web dashboard available at `/oban` in development

#### Development Tools

- LiveDashboard at `/dev/dashboard`
- Ash Admin interface at `/admin` (development only)
- Swoosh mailbox preview at `/dev/mailbox`

### Project Structure Conventions

- Resources in `lib/pilates_on_phx/` organized by domain
- Web components in `lib/pilates_on_phx_web/`
- Authentication-related modules use AshAuthentication conventions
- Database migrations in `priv/repo/migrations/`
- Asset source files in `assets/` directory

### Important Configuration

- Ash formatter rules in `.formatter.exs` with extensive import_deps
- Spark formatter configuration for Ash resources in `config/config.exs`
- Ash global settings configured for keysets, policies, and atomic actions
- Phoenix endpoint uses Bandit adapter

### Development Guidelines

This project includes comprehensive development guidelines in `AGENTS.md` covering:

- Phoenix 1.8 patterns and LiveView best practices
- Elixir language conventions and common pitfalls
- Ecto/database interaction patterns
- Form handling with Phoenix Components
- LiveView streams for collections
- Testing approaches with LiveViewTest

When working with this codebase, always reference the detailed guidelines in `AGENTS.md` for framework-specific patterns and conventions.

## Ash Framework 3.0+ API Patterns

### Actor Management (CRITICAL API CHANGE)

**NEW API (Ash 3.0+):**

```elixir
# For create actions
Ash.Changeset.for_create(Resource, :action, attrs, actor: actor)

# For update actions
Ash.Changeset.for_update(resource, :action, attrs, actor: actor)

# For direct operations
Ash.create(changeset, actor: actor, domain: Domain)
Ash.update(changeset, actor: actor, domain: Domain)
```

### Query Filtering

**Requirement:** Always add `require Ash.Query` at the top of modules using filter functions.

```elixir
defmodule MyTest do
  require Ash.Query

  # Now you can use filter functions
  Resource
  |> Ash.Query.filter(field: value)
  |> Domain.read!()
end
```

## Testing Philosophy

### What to Test vs What NOT to Test

#### ✅ DO TEST (PilatesOnPhx Business Logic)

- **Action Inputs**: Custom action parameter validation and business constraint enforcement
- **Action Invocation**: Domain-specific actions like `book_class`, `cancel_booking` and their business outcomes
- **Custom Validations**: Business constraints, domain-specific validations
- **Authorization Policies**: Multi-tenant security, role-based access, business authorization rules
- **Business Rules**: Class capacity management, booking workflows, instructor permissions
- **Relationships**: Domain-specific relationship constraints, cascade behaviors
- **Calculations**: Custom computed fields, business metrics, domain aggregates
- **Complex Scenarios**: Cross-domain workflows, audit trails, proper authorization handling

#### ❌ DO NOT TEST (Ash Framework Features)

- **Basic CRUD**: Standard create/read/update/delete operations (Ash handles this)
- **Sorting/Filtering**: `Ash.Query.sort()`, `Ash.Query.filter()` functionality (framework feature)
- **Pagination**: Offset/limit, keyset pagination (framework feature)
- **Timestamps**: `inserted_at`, `updated_at` automatic management (framework feature)
- **Basic Relationships**: `belongs_to`, `has_many` loading (framework feature)
- **Standard Validations**: `present()`, `match()` validation mechanics (framework feature)

### Test Coverage Requirements

- Target 90%+ code coverage
- Focus tests on business logic validation
- Test real user workflows end-to-end
- Test authorization and multi-tenant isolation
- Test error scenarios and edge cases

## Business Domain: Pilates Studio Management

### Core Concepts

- **Studios**: Physical locations offering Pilates classes
- **Classes**: Scheduled sessions with capacity limits and instructor assignments
- **Clients**: Users who book and attend classes
- **Instructors**: Staff who teach classes
- **Bookings**: Reservations for specific class sessions
- **Packages**: Credit-based systems for class access
- **Waitlists**: Queue system when classes are full

### Key Business Rules

- Classes have capacity limits
- Bookings consume package credits
- Waitlist management when classes full
- Multi-tenant isolation by studio
- Role-based permissions (owner, instructor, client)
- Automated reminder system
- Attendance tracking and check-in

## Linear Integration

This project uses Linear for issue tracking and project management. The `.claude` directory includes:

- MCP Linear server configuration
- SDLC orchestrator agent for structured development workflows
- Hooks for quality gates and automated commits

Use the `/sdlc` command with a Linear issue ID to initiate a structured development workflow.

## Git & GitHub Setup

- GitHub repository: `https://github.com/YOUR_USERNAME/PilatesOnPhx`
- Main branch: `main`
- Use descriptive commit messages
- Create PRs for all features
- Link PRs to Linear issues

## Remember

You are building a production-grade Pilates studio management system. Every feature must be:

- Thoroughly tested before implementation
- Meet all acceptance criteria
- Pass all quality gates
- Ready for production deployment
- Properly documented and tracked

Take your time, be thorough, and maintain the highest standards.
