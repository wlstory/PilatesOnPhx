# Phase 1: Requirements Analysis

**Agent:** `catalio-sdlc-orchestrator`

## Objective

Analyze the Linear issue, create an implementation plan, and provide coordination instructions for Phase 2 (TDD Setup).

## Tasks

### 1. Fetch and Analyze Linear Issue

```text
Use mcp__linear-server__get_issue to fetch the issue details
```

**Extract:**

- User story and description
- Acceptance criteria
- Technical requirements
- Referenced code files or modules
- Related issues and dependencies
- Current status and assignee

**Analyze:**

- Complexity assessment (simple, moderate, complex)
- Required skills or domain knowledge
- Potential risks or blockers
- Dependencies on other features or systems

### 2. Create Implementation Plan

**Identify:**

- Database changes needed (new tables, migrations, new Ash resources)
- Existing code that needs modification (resources, LiveViews, components)
- New files or modules to create
- Test files required (resource tests, LiveView tests, integration tests)

**Break Down:**

- Feature into testable components
- Acceptance criteria into specific test scenarios
- Implementation into logical steps

**Document:**

- Step-by-step implementation approach
- Expected file changes
- Potential edge cases
- Testing strategy

### 3. Initial Setup

**Create WIP Commit:**

```bash
git add . && git commit -m "WIP: Start SDLC for {ISSUE-ID}"
```

**Add Linear Comment:**

```text
Use mcp__linear-server__create_comment with:
- Issue ID from the request
- Body: "🚀 SDLC workflow started - Requirements analyzed

## Implementation Plan
[Brief summary]

## Next Steps
- Creating comprehensive test suite (TDD)
- Implementation to follow test completion
"
```

### 4. Return Coordination Instructions

**CRITICAL:** Do NOT invoke catalio-test-strategist yourself. Instead, provide detailed instructions for the main context to invoke it.

**Format your response as:**

```markdown
## Phase 1 Complete: Requirements Analyzed

[Summary of Linear issue]

### Key Requirements
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

### Implementation Approach
[Brief description of implementation strategy]

### Files to Modify/Create
- [File 1] - [Purpose]
- [File 2] - [Purpose]

---

## NEXT STEP: Invoke catalio-test-strategist

Provide the test strategist with the following context:

**Linear Issue:** {ISSUE-ID}

**User Story:**
[Copy user story from Linear]

**Acceptance Criteria:**
[List all acceptance criteria]

**Files to Test:**
[List specific modules/resources/LiveViews]

**Test Files to Create:**
[List specific test file paths needed]

**Complexity Notes:**
[Any special testing considerations, edge cases, or complex scenarios]

**Instructions for Test Strategist:**
Create comprehensive failing tests (TDD red phase) covering:
1. All acceptance criteria
2. Happy path scenarios
3. Error cases and validation failures
4. Multi-tenant isolation
5. Authorization policies
6. Edge cases identified in analysis

Target 90%+ code coverage.
```

## Best Practices

### Requirements Analysis

- **Be thorough:** Don't skip edge cases or error scenarios
- **Think multi-tenant:** Always consider organization isolation
- **Check authorization:** Identify required policies and permissions
- **Review existing patterns:** Look for similar features in the codebase

### Communication

- **Be specific:** Provide exact file paths and module names
- **Be clear:** Write acceptance criteria in testable terms
- **Be complete:** Include all information needed for Phase 2

### Coordination

- **Never nest agents:** Return instructions, don't invoke next agent
- **Clear handoffs:** Make next steps obvious and actionable
- **Maintain context:** Include all relevant information for next phase

## Common Pitfalls to Avoid

- Invoking catalio-test-strategist directly (causes nesting issues)
- Missing multi-tenant considerations in analysis
- Overlooking authorization requirements
- Not considering existing patterns and conventions
- Vague or ambiguous acceptance criteria
- Forgetting to create WIP commit
- Not adding Linear comment for tracking

## Example Output

```markdown
## Phase 1 Complete: Requirements Analyzed

Analyzed CDEV-184: Dashboard Enhancement - Organization Documentation Health Score

### Key Requirements
- Add documentation health aggregate to Organization resource
- Create dashboard component showing health score
- Implement background job to recalculate scores daily
- Add visual indicators (color-coded badges)

### Implementation Approach
1. Add aggregate to Organization resource with Ash calculations
2. Create LiveView component for dashboard card
3. Set up Oban worker for daily recalculation
4. Test multi-tenant isolation and authorization

### Files to Modify/Create
- lib/catalio/accounts/organization.ex - Add health_score aggregate
- lib/catalio_web/live/dashboard_live.ex - Add health card component
- lib/catalio_web/components/health_score.ex - New component
- lib/catalio/workers/update_health_scores.ex - New Oban worker
- test/catalio/accounts/organization_test.exs - Test aggregate
- test/catalio_web/live/dashboard_live_test.exs - Test component
- test/catalio/workers/update_health_scores_test.exs - Test worker

---

## NEXT STEP: Invoke catalio-test-strategist

[Detailed context as shown above...]
```

## Success Criteria

Phase 1 complete when:

- Linear issue fully analyzed and understood
- Implementation plan is clear and complete
- WIP commit created
- Linear comment added
- Coordination instructions provided for Phase 2
- NO nested agent invocations made
