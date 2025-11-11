# Linear Issue Template for Phoenix/Elixir/Ash Stories

This template should be used for all PilatesOnPhx (AltBuild-PHX team) user stories extracted from NextJS (Wlstory) or Rails (AltBuild-Rails) requirements.

---

## Issue Fields (REQUIRED)

### Title
`[Feature Name] - [Brief Description]`

Example: `Studio Basic Information Capture - Onboarding Step 1`

### Priority (REQUIRED - DO NOT SKIP)
- **Critical**: Blocking, must be done for MVP
- **High**: Important for user experience
- **Medium**: Nice to have, enhances value
- **Low**: Future enhancement
- **Todo**: Default if unsure

### Labels (REQUIRED - AT LEAST ONE)
- `feature` - New functionality
- `bug` - Bug fix
- `enhancement` - Improvement to existing feature
- `technical-debt` - Code quality improvement
- `documentation` - Documentation update
- `epic` - Large feature with multiple stories

### Project (REQUIRED)
- **Foundational Setup** - For Sprint 1 issues
- **Sprint 2: Core Workflows** - For onboarding, scheduling, booking
- **Sprint 3: Automation** - For Oban jobs, reminders, attendance
- **Sprint 4: Integrations** - For payments, reporting, mobile

### Milestone (RECOMMENDED)
Group related features:
- `Sprint 1 - Foundation`
- `Sprint 2 - MVP Features`
- `Sprint 3 - Automation`
- `Sprint 4 - Polish`

### Assignee (LEAVE BLANK)
Do NOT set assignee - leave for manual assignment by team lead

### Cycle (LEAVE BLANK)
Do NOT set cycle - leave for sprint planning by team lead

### Parent (IF APPLICABLE)
Link to parent epic if this is a user story under an epic

---

## Issue Description Template

```markdown
## Original Requirement

**Source**: [WLS-XXX](linear-url) or [RAILS-XXX](linear-url)

**Original Team**: NextJS (Wlstory) or Rails (AltBuild-Rails)

**Original Description**: 
[Brief summary of original requirement]

---

## User Story

As a [role/persona]
I want to [activity]
So that [business benefit]

**Persona Reference**: [Link to persona resource if exists, or suggest creating new persona]

---

## Use Cases (Gherkin Format)

### Happy Path

```gherkin
Scenario: [Happy Path] Descriptive scenario title
  Given initial state or precondition
  When user action or event occurs
  Then expected outcome
  And additional validation or side effect
```

### Edge Cases

```gherkin
Scenario: [Edge Case] Alternative flow title
  Given alternative initial state
  When different action occurs
  Then alternative expected outcome
  And edge case handled correctly
```

### Error Cases

```gherkin
Scenario: [Error Case] Error handling title
  Given invalid or error-triggering state
  When error-triggering action occurs
  Then error handled gracefully
  And appropriate error message shown
  And user can recover from error
```

---

## Acceptance Criteria

1. [Criterion 1 - testable and specific]
2. [Criterion 2 - testable and specific]
3. [Criterion 3 - testable and specific]
4. [Criterion 4 - testable and specific]
5. [Criterion 5 - testable and specific]

**Success Metrics**:
- [Metric 1: e.g., "95% of users complete this step"]
- [Metric 2: e.g., "Average completion time < 2 minutes"]

---

## Phoenix/Elixir/Ash Implementation

### Domain Assignment

**Primary Domain**: [Accounts | Studios | Classes | Bookings]

**Secondary Domains** (if cross-domain):
- [List any other domains involved]

---

### Resources & Actions

#### Resource 1: [Domain.ResourceName]

**Action**: `:action_name`

**Attributes**:
- `field_name` (`:field_type`) - Description
- `another_field` (`:field_type`) - Description

**Relationships**:
- `belongs_to :related_resource, Domain.RelatedResource`
- `has_many :collection, Domain.CollectionResource`

**Validations**:
- `validate present([:required_field])`
- `validate match(:email, ~r/@/)`
- `validate custom_validation_fn()`

**Example Action Definition**:
```elixir
# lib/pilates_on_phx/[domain]/[resource].ex
create :action_name do
  accept [:field1, :field2]
  
  argument :arg_name, :arg_type, allow_nil?: false
  
  change set_attribute(:field, value)
  change relate_actor(:relationship)
  
  validate present([:required_fields])
  validate custom_validation()
  
  # After action hook (if needed)
  change after_action(&callback_fn/2)
end
```

---

### LiveView Components

#### LiveView: `PilatesOnPhxWeb.[Context]Live.[ComponentName]`

**Purpose**: [What this LiveView does]

**Mount Logic**:
- Load initial data
- Set up form assigns
- Configure authorization

**Event Handlers**:
- `handle_event("event_name", params, socket)` - Description

**Assigns**:
- `@form` - Form struct from `to_form/2`
- `@data` - Loaded data
- `@current_user` - Actor from session

**Template Structure**:
```heex
<Layouts.app flash={@flash} current_user={@current_user}>
  <.form for={@form} id="unique-form-id" phx-submit="save">
    <.input field={@form[:field]} type="text" label="Label" />
    <.button>Submit</.button>
  </.form>
</Layouts.app>
```

---

### Background Jobs (Oban)

**If this feature requires background processing:**

#### Worker: `PilatesOnPhx.[Domain].Workers.[WorkerName]`

**Purpose**: [What this job does]

**Queue**: `:queue_name` (e.g., `:default`, `:mailers`, `:high_priority`)

**Schedule** (if recurring): 
- Cron: `"0 2 * * *"` (daily at 2am)
- OR Manual trigger on specific events

**Implementation**:
```elixir
# lib/pilates_on_phx/[domain]/workers/[worker_name].ex
defmodule PilatesOnPhx.[Domain].Workers.[WorkerName] do
  use Oban.Worker, queue: :queue_name, max_attempts: 3
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"key" => value}}) do
    # Job logic here
    :ok
  end
end
```

**Job Enqueue**:
```elixir
%{key: value}
|> PilatesOnPhx.[Domain].Workers.[WorkerName].new()
|> Oban.insert()
```

---

### PubSub Events (Real-Time Updates)

**If this feature broadcasts real-time updates:**

**Topic**: `"[domain]:[entity_id]:[event_type]"`

Example: `"studios:#{studio_id}:classes"`

**Events**:
- `:class_booked` - When class booking created
- `:capacity_changed` - When class capacity updated
- `:waitlist_promoted` - When client moved from waitlist

**Broadcast**:
```elixir
Phoenix.PubSub.broadcast(
  PilatesOnPhx.PubSub,
  "studios:#{studio_id}:classes",
  {:class_booked, booking}
)
```

**Subscribe** (in LiveView):
```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(
      PilatesOnPhx.PubSub,
      "studios:#{studio_id}:classes"
    )
  end
  {:ok, socket}
end

def handle_info({:class_booked, booking}, socket) do
  # Update UI
  {:noreply, socket}
end
```

---

### Database Migrations

**If schema changes required:**

**Migration Type**: [Create table | Add column | Add index | Add constraint]

**Tables Affected**:
- `[table_name]` - [Description of changes]

**Example Migration**:
```elixir
# priv/repo/migrations/[timestamp]_create_[table].exs
defmodule PilatesOnPhx.Repo.Migrations.Create[Table] do
  use Ecto.Migration

  def change do
    create table(:table_name, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :field, :type, null: false
      
      timestamps()
    end
    
    create index(:table_name, [:field])
  end
end
```

---

## Testing Strategy

### Test Coverage Requirements

**Target**: 85%+ coverage on business logic

### Test Types

#### 1. Resource Action Tests

**File**: `test/pilates_on_phx/[domain]/[resource]_test.exs`

**Test Cases**:
- ✅ Create action with valid attributes
- ✅ Create action with invalid attributes (validation errors)
- ✅ Update action with valid changes
- ✅ Custom validations enforced
- ✅ Multi-tenant isolation (belongs to correct studio)
- ✅ Actor authorization (correct permissions)

**Example**:
```elixir
test "creates resource with valid attributes", %{actor: actor} do
  attrs = %{field: "value"}
  
  assert {:ok, resource} = 
    ResourceName
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.create()
  
  assert resource.field == "value"
end

test "fails validation with missing required field", %{actor: actor} do
  attrs = %{field: nil}
  
  assert {:error, changeset} = 
    ResourceName
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.create()
  
  assert "is required" in errors_on(changeset).field
end
```

#### 2. LiveView Tests

**File**: `test/pilates_on_phx_web/live/[context]/[component]_live_test.exs`

**Test Cases**:
- ✅ Page renders correctly
- ✅ Form submission with valid data
- ✅ Form validation errors displayed
- ✅ Authorization (unauthorized users redirected)
- ✅ Real-time updates (PubSub events)
- ✅ User interactions (buttons, links)

**Example**:
```elixir
test "submits form with valid data", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/path")
  
  view
  |> form("#unique-form-id", resource: %{field: "value"})
  |> render_submit()
  
  assert_redirect(view, "/success-path")
end
```

#### 3. Oban Job Tests

**File**: `test/pilates_on_phx/[domain]/workers/[worker]_test.exs`

**Test Cases**:
- ✅ Job performs successfully with valid args
- ✅ Job handles errors gracefully
- ✅ Job retries on failure (if applicable)
- ✅ Side effects occur (emails sent, records created)

**Example**:
```elixir
test "performs job successfully" do
  args = %{"key" => "value"}
  
  assert :ok = perform_job(WorkerName, args)
  
  # Assert side effects
  assert_enqueued worker: EmailWorker
end
```

#### 4. Integration Tests

**File**: `test/pilates_on_phx/integration/[feature]_test.exs`

**Test Cases**:
- ✅ Complete user workflow end-to-end
- ✅ Cross-domain interactions
- ✅ Authorization across multiple operations
- ✅ Data consistency maintained

**Example**:
```elixir
test "complete booking workflow" do
  # Create client
  client = create_client()
  
  # Purchase package
  package = purchase_package(client)
  
  # Book class
  booking = book_class(client, package, class_session)
  
  # Verify credit deduction
  assert package.credits_remaining == package.total_credits - 1
end
```

---

## Reusable Modules & Patterns

### Existing Modules to Leverage

**From AGENTS.md (Lines X-Y)**:
- [Pattern 1]: [Description]
- [Pattern 2]: [Description]

**From CLAUDE.md (Lines X-Y)**:
- [Domain pattern]: [Description]
- [Testing pattern]: [Description]

### Similar Implementations

**Reference Issues**:
- PHX-X: [Similar feature] - [What to reuse]
- PHX-Y: [Related feature] - [What to adapt]

### Code References

**Files to reference**:
- `lib/pilates_on_phx/[domain]/[similar_resource].ex` (Lines X-Y)
- `test/pilates_on_phx/[domain]/[similar_test].exs` (Lines X-Y)

---

## Dependencies

### Blocking Dependencies

**Must be completed before starting**:
- PHX-X: [Dependency description]
- PHX-Y: [Dependency description]

### Related Issues

**Should be coordinated with**:
- PHX-X: [Related work]
- PHX-Y: [Related work]

### External Dependencies

**Third-party integrations**:
- [Service name]: [Integration requirement]
- [Library name]: [Version requirement]

---

## Security Considerations

### Authentication & Authorization

- ✅ Actor-based authorization enforced
- ✅ Multi-tenant isolation verified
- ✅ Role-based access control applied
- ✅ Sensitive data protected

### Data Validation

- ✅ Input sanitization
- ✅ SQL injection prevention (Ash handles this)
- ✅ XSS prevention (Phoenix handles this)
- ✅ CSRF protection (Phoenix handles this)

### Multi-Tenant Isolation

**Policy Example**:
```elixir
policies do
  policy action_type(:read) do
    authorize_if actor_attribute_equals(:studio_id, :studio_id)
  end
  
  policy action_type(:create) do
    authorize_if actor_has_role(:owner)
  end
end
```

---

## Performance Considerations

### Query Optimization

- Eager load associations: `Ash.Query.load([:association])`
- Use indexes on frequently queried fields
- Limit result sets appropriately

### Caching Strategy

- Cache static data (class types, studio settings)
- Cache duration: [X minutes/hours]
- Cache invalidation on: [specific events]

### Background Job Performance

- Job timeout: [X seconds]
- Max attempts: [X retries]
- Backoff strategy: [exponential/linear]

---

## Documentation Updates

### Files to Update

- [ ] `CLAUDE.md` - [Section to update]
- [ ] `README.md` - [Section to update]
- [ ] `docs/[domain]/[file].md` - [New or updated documentation]

### API Documentation

- [ ] Ash resource documented with @doc attributes
- [ ] Action parameters documented
- [ ] Example usage provided

---

## Definition of Done

- [ ] All acceptance criteria met
- [ ] 85%+ test coverage on business logic
- [ ] All tests passing (`mix test`)
- [ ] Code formatted (`mix format`)
- [ ] No credo warnings (`mix credo`)
- [ ] No security issues (`mix sobelow`)
- [ ] Dialyzer passes (`mix dialyzer`)
- [ ] Documentation updated
- [ ] PR created and linked to this issue
- [ ] Code reviewed and approved
- [ ] Merged to main branch
- [ ] Deployed to staging
- [ ] Manual QA passed

---

## References

### Original Requirements
- WLS-XXX: [Link to NextJS requirement]
- RAILS-XXX: [Link to Rails requirement]

### Documentation
- CLAUDE.md: Lines X-Y ([Topic])
- AGENTS.md: Lines X-Y ([Pattern])
- Domain Architecture: [Link to architecture doc]

### Related Resources
- [External documentation]
- [API reference]
- [Design mockups]

```

---

## Example: Completed Issue

See PHX-10 in `sprint-planning-epics.md` for a fully-worked example following this template.

