# Phase 2: TDD Setup

**Agent:** `catalio-test-strategist`

## Objective

Create comprehensive failing tests (TDD red phase) that cover all acceptance criteria and target 90%+ code coverage.

## TDD Philosophy

**Test-Driven Development Cycle:**

1. **Red** - Write failing tests first (this phase)
2. **Green** - Implement code to make tests pass (Phase 3)
3. **Refactor** - Improve code while keeping tests green (Phase 3)

## Tasks

### 1. Analyze Test Requirements

**Review from Phase 1:**

- User story and acceptance criteria
- Files to test (resources, LiveViews, workers, etc.)
- Test files to create
- Complexity and edge cases

**Identify Test Types:**

- Resource tests (CRUD, validations, relationships, policies)
- LiveView tests (rendering, events, authentication)
- Component tests (display logic, interactivity)
- Integration tests (cross-resource workflows)
- Worker tests (job enqueueing, execution)

### 2. Create Comprehensive Test Suite

**For Each Acceptance Criterion:**

- Write at least one test scenario
- Include happy path
- Include error/validation scenarios
- Cover edge cases

**Test Coverage Goals:**

- **90%+ overall coverage** (REQUIRED)
- 100% of custom business logic
- 100% of authorization policies
- 100% of validations
- All acceptance criteria

### 3. Follow Testing Best Practices

**What to Test (Catalio Business Logic):**

- Action inputs and parameter validation
- Custom action invocations and business outcomes
- Custom validations and business rules
- Authorization policies and multi-tenant isolation
- Relationships with business constraints
- Calculations and aggregates (test independently)
- Complex workflows and cross-domain scenarios

**What NOT to Test (Ash Framework):**

- Basic CRUD operations (Ash handles this)
- Sorting/filtering mechanics (framework feature)
- Pagination (framework feature)
- Timestamp management (framework feature)
- Basic relationship loading (framework feature)
- Standard validation mechanics (framework feature)

**Exception - Coverage Goals:**
When maintaining 90%+ coverage, it's acceptable to test:

- Oban workers/schedulers (integration behavior)
- Generated modules from AshOban
- Framework integration points
- Thin wrapper modules

### 4. Test Structure and Patterns

**AshAuthentication Patterns:**

```elixir
# Test helpers
def create_test_user(attrs \\ %{}) do
  %{email: "test@example.com", password: "password123"}
  |> Map.merge(attrs)
  |> AshAuthentication.Strategy.Password.sign_up(User, :password)
end

def register_and_log_in_user(context, attrs \\ %{}) do
  {:ok, user} = create_test_user(attrs)
  conn = log_in_user(context[:conn], user)
  %{conn: conn, user: user}
end
```

**Multi-Tenant Patterns:**

```elixir
# Always test tenant isolation
test "cannot access resources from other organizations" do
  org_a_user = create_test_user(%{organization_id: org_a.id})
  org_b_resource = create_resource(%{organization_id: org_b.id})

  refute Domain.can?({Resource, :read}, org_b_resource, actor: org_a_user)
end
```

**LiveView Test Patterns:**

```elixir
describe "create mode - business logic" do
  setup :register_and_log_in_user

  test "creates resource with proper multi-tenant context", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, @path_new)

    view
    |> form("#resource-form", form: %{"title" => "Test"})
    |> render_submit()

    # Verify business outcome
    created = Ash.Query.filter(Resource, title == "Test") |> Ash.read_one!(actor: user)
    assert created.organization_id == user.organization_id
  end
end
```

### 5. Create Test Files

**Write tests to all specified test file paths from Phase 1.**

For each test file:

1. Set up proper test case inheritance (DataCase, ConnCase, etc.)
2. Add `require Ash.Query` if using filter functions
3. Create test generators if needed
4. Write comprehensive describe blocks
5. Ensure all tests FAIL initially (TDD red phase)

### 6. Commit Test Files

```bash
git add test/
git commit -m "WIP: Add comprehensive failing tests for {ISSUE-ID}

- Created test files for [list files]
- Coverage targets: 90%+
- All acceptance criteria covered
- TDD red phase complete"
```

### 7. Return Coordination Instructions

**Format your response as:**

```markdown
## Phase 2 Complete: TDD Setup Finished

Created comprehensive failing test suite for {ISSUE-ID}.

### Test Files Created
- [File 1] - [What it tests]
- [File 2] - [What it tests]

### Coverage Analysis
- Total test scenarios: [count]
- Acceptance criteria covered: [count/total]
- Expected coverage after implementation: [percentage]%

### Current Test Status
All tests are currently failing (TDD red phase). This is expected and correct.

---

## NEXT STEP: Implementation (Phase 3)

Now implement the features to make these tests pass:

**Implementation Checklist:**
1. [Specific implementation task 1]
2. [Specific implementation task 2]
3. [Specific implementation task 3]

**Files to Modify/Create:**
[List implementation files from Phase 1]

**Development Guidelines:**
- Follow CLAUDE.md and AGENTS.md conventions
- Make incremental WIP commits
- Run tests frequently with `mix test`
- Keep tests green after initial implementation
- Refactor while maintaining green tests
- Hooks will run automatically (auto-format, test-enforcer)

**Testing During Implementation:**
```bash
# Run specific test file
mix test test/path/to/test_file.exs

# Run all tests
mix test

# Run with coverage
mix test --cover
```

After implementation is complete and all tests pass, proceed to Phase 4 (Quality Gate).

## Best Practices

### Test Design

- **Be comprehensive:** Cover all scenarios, not just happy paths
- **Be specific:** Each test should verify one specific behavior
- **Be clear:** Test names should describe what they verify
- **Be isolated:** Tests should not depend on each other

### TDD Discipline

- **Tests first:** Write tests BEFORE implementation
- **Fail first:** Verify tests fail before implementing
- **One step:** Don't implement ahead of tests
- **Red-Green-Refactor:** Follow the cycle strictly

### Coverage Strategy

- **Focus on business logic:** Test what matters
- **Don't test frameworks:** Trust Ash, Phoenix, Ecto
- **Integration over unit:** Test real behaviors
- **Generators for data:** Use test generators for consistency

## Common Pitfalls to Avoid

- Writing tests that pass immediately (not TDD)
- Testing Ash framework features instead of business logic
- Missing multi-tenant isolation tests
- Not testing authorization policies
- Forgetting to test error scenarios
- Weak validation testing
- Not using test generators for complex data
- Invoking next agent (causes nesting)

## Success Criteria

Phase 2 complete when:

- All test files created as specified in Phase 1
- All tests are currently FAILING (TDD red phase)
- Every acceptance criterion has test coverage
- Multi-tenant isolation tested
- Authorization policies tested
- Edge cases and error scenarios tested
- Test coverage target: 90%+ (after implementation)
- WIP commit made with test files
- Coordination instructions provided for Phase 3
- NO nested agent invocations made
