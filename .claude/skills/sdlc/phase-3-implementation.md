# Phase 3: Implementation

**Performer:** Developer (Manual or Agent-Assisted)

## Objective

Implement features to make all tests pass (TDD green phase), then refactor while keeping tests green.

## TDD Green-Refactor Phases

**Green Phase:**

- Make tests pass with minimal implementation
- Focus on functionality, not perfection
- Keep changes small and incremental
- Commit frequently

**Refactor Phase:**

- Improve code quality while tests stay green
- Extract reusable patterns
- Optimize performance if needed
- Maintain test coverage

## Implementation Checklist

Use the checklist provided from Phase 2's output. Generally includes:

### 1. Database Changes (if needed)

**Create Migrations:**

```bash
mix ash.codegen create_migration_for_resource ResourceName
```

**Review and Run:**

```bash
# Review generated migration
cat priv/repo/migrations/*_create_resource_name.exs

# Run migration
mix ecto.migrate
```

### 2. Ash Resource Modifications

**Common Changes:**

- Add attributes with types and constraints
- Add relationships (belongs_to, has_many, etc.)
- Add aggregates for computed data
- Add calculations for derived values
- Define custom actions
- Add validations (custom business logic)
- Configure policies for authorization

**Example Aggregate:**

```elixir
aggregates do
  count :requirements_count, :requirements
  count :completed_count, :requirements do
    filter expr(status == :completed)
  end
end
```

**Important After Adding Aggregates:**

```bash
# Clean build cache to avoid "not a valid load" errors
rm -rf _build && mix compile
```

### 3. LiveView Implementation

**Follow Form Development Patterns:**

- Load organization context before form init
- Use `AshPhoenix.Form.for_create` or `for_update` with actor/tenant
- Convert to Phoenix form with `to_form()`
- Pass `organization_id` in initial params
- Set `:mode` assign (`:create` or `:edit`)

**Required Event Handlers:**

```elixir
# Validation
def handle_event("validate", %{"form" => params}, socket) do
  params_with_org = Map.put(params, "organization_id", org_id)
  form = AshPhoenix.Form.validate(socket.assigns.form, params_with_org) |> to_form()
  {:noreply, assign(socket, :form, form)}
end

# Submission
def handle_event("save", %{"form" => params}, socket) do
  AshPhoenix.Form.submit(socket.assigns.form,
    params: Map.put(params, "organization_id", org_id),
    action_opts: [actor: user, tenant: org_id]
  )
end
```

### 4. Component Development

**Reusable Components:**

- Keep components focused and single-purpose
- Accept data through assigns
- Emit events for parent handling
- Follow Tailwind CSS conventions
- Document expected assigns

### 5. Background Jobs (Oban)

**Create Worker:**

```elixir
defmodule Catalio.Workers.MyWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # Implementation
    :ok
  end
end
```

**Enqueue Job:**

```elixir
%{arg1: value1}
|> MyWorker.new()
|> Oban.insert()
```

## Development Workflow

### 1. Incremental Development

**Make Small Changes:**

- Implement one test scenario at a time
- Run tests after each change
- Commit when a logical unit is complete

**Example Workflow:**

```bash
# Make a small change
vim lib/catalio/resource.ex

# Run specific test
mix test test/catalio/resource_test.exs:42

# If passing, commit
git add .
git commit -m "WIP: Add validation for field_name (ISSUE-ID)"

# Continue to next change
```

### 2. Run Tests Frequently

```bash
# Run specific test file
mix test test/path/to/test.exs

# Run specific test line
mix test test/path/to/test.exs:42

# Run all tests
mix test

# Run with coverage
mix test --cover

# Run only failed tests
mix test --failed
```

### 3. Monitor Coverage

```bash
# Generate coverage report
mix test --cover

# View detailed coverage
open cover/excoveralls.html  # macOS
xdg-open cover/excoveralls.html  # Linux
```

**Target:** 90%+ overall coverage

### 4. Frequent WIP Commits

**Commit Pattern:**

```bash
git add .
git commit -m "WIP: [Description of change] (ISSUE-ID)"
```

**Benefits:**

- Easy rollback to working states
- Track progress
- Debug complex issues
- Recover from mistakes

**Examples:**

```bash
git commit -m "WIP: Add Product resource with validations (CDEV-123)"
git commit -m "WIP: Implement dashboard health score component (CDEV-123)"
git commit -m "WIP: Fix multi-tenant isolation in queries (CDEV-123)"
```

## Automatic Hooks

These run automatically via configured hooks:

### auto-format Hook

- Runs on every commit
- Formats Elixir, JavaScript, Markdown
- Amends commit if changes made
- No manual intervention needed

### test-enforcer Hook

- Runs on every commit
- Ensures tests pass before committing
- Blocks commit if tests fail
- Run `mix test` manually to debug

## Following Conventions

### From CLAUDE.md

**Critical Requirements:**

- Use IEX for testing, not temporary files
- Make frequent WIP commits
- Never simplify tests to make them pass
- Maintain 85%+ test coverage (aim for 90%+)
- Handle complex scenarios with enterprise patterns

**Testing Focus:**

- Test Catalio business logic, not Ash framework
- Focus on custom validations, actions, policies
- Test multi-tenant isolation thoroughly
- Test authorization policies comprehensively

### From AGENTS.md

**Phoenix/Elixir Patterns:**

- Use `~p` sigil for route paths
- Proper LiveView lifecycle (`mount`, `handle_event`, `handle_info`)
- Stream collections with `stream/3` and `stream_insert/3`
- Atoms for domain concepts, strings for user input
- Pattern matching in function heads

**Ash Patterns:**

- Always pass `actor:` and `tenant:` in operations
- Use `Ash.Changeset.for_create/for_update` with actor
- Require `Ash.Query` before using filter functions
- Clean build after adding aggregates

## Common Implementation Tasks

### Adding Aggregate to Resource

```elixir
aggregates do
  count :related_count, :related_records do
    filter expr(status == :active)
  end
end
```

**After adding:**

```bash
rm -rf _build && mix compile
```

### Adding Custom Action

```elixir
actions do
  update :activate do
    accept [:activated_at]
    change set_attribute(:status, :active)
    change fn changeset, _ ->
      Ash.Changeset.force_change_attribute(changeset, :activated_at, DateTime.utc_now())
    end
  end
end
```

### Adding Policy

```elixir
policies do
  policy action_type(:read) do
    authorize_if expr(organization_id == ^actor(:organization_id))
  end

  policy action_type([:create, :update, :destroy]) do
    authorize_if actor_attribute_equals(:role, :admin)
  end
end
```

## Refactoring Guidelines

**After Tests Pass:**

- Extract repeated code into functions
- Improve naming for clarity
- Optimize queries if needed
- Add documentation comments
- Keep tests green throughout

**Before Refactoring:**

```bash
# Ensure all tests pass
mix test

# Make incremental refactoring changes
# Run tests after each refactoring step
```

## When Implementation is Complete

**Verify:**

- All tests passing (`mix test`)
- Coverage meets 90%+ target
- No compiler warnings
- Code follows conventions
- WIP commits made throughout

**Proceed to Phase 4:**

- Run `mix precommit` to check quality
- If issues found, proceed to Phase 4 (Quality Gate)
- catalio-debugger will fix all warnings/errors

## Common Pitfalls to Avoid

- Making large changes without testing
- Not committing frequently
- Simplifying tests to make them pass (forbidden)
- Forgetting actor/tenant in Ash operations
- Not cleaning build after adding aggregates
- Testing Ash framework instead of business logic
- Not following multi-tenant patterns
- Skipping authorization policy implementation

## Success Criteria

Phase 3 complete when:

- All tests passing
- Coverage ≥ 90%
- All acceptance criteria implemented
- Frequent WIP commits made
- Code follows CLAUDE.md and AGENTS.md conventions
- Ready for quality gate (mix precommit)
