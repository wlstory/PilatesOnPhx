# Agent Coordination Best Practices

## The Problem: Agent Nesting

**Issue:** When agents invoke other agents directly (nesting), tool name conflicts occur because both agents have access to the same tool set.

**Example of Problematic Nesting:**

```text
Main Context
  └─ catalio-sdlc-orchestrator (Agent A)
       └─ catalio-test-strategist (Agent B)  ❌ Tool name collision!
```

**Error Message:**

```text
"tools: Tool names must be unique."
```

## The Solution: Agent Chaining

**Pattern:** Each agent completes its work and returns coordination instructions. The main context invokes the next agent based on these instructions.

**Example of Agent Chaining:**

```text
Main Context
  └─ catalio-sdlc-orchestrator (Phase 1)
       → Returns: "Invoke catalio-test-strategist with [context]"

Main Context  ← Control returns
  └─ catalio-test-strategist (Phase 2)
       → Returns: "Proceed to implementation"

Main Context  ← Control returns
  └─ Developer implements (Phase 3)
       → Ready for quality gate

Main Context  ← Control returns
  └─ catalio-debugger (Phase 4)
       → Returns: "Quality gate passed"

Main Context  ← Control returns
  └─ Developer creates PR (Phase 5)
```

## Agent Chaining Rules

### Rule 1: Never Nest Agents

**DON'T:**

```markdown
# Inside catalio-sdlc-orchestrator agent

Now I'm going to invoke the catalio-test-strategist agent...

[Uses Task tool to invoke nested agent]  ❌ WRONG - causes tool collision
```

**DO:**

```markdown
# Inside catalio-sdlc-orchestrator agent

Analysis complete. Here are the coordination instructions for the next phase.

## NEXT STEP: Invoke catalio-test-strategist

The main context should now invoke catalio-test-strategist with:
- Linear issue: CDEV-123
- User story: [paste story]
- Acceptance criteria: [list]
- Files to test: [list]

[Agent completes and returns to main context]
```

### Rule 2: Provide Complete Coordination Instructions

**Each agent must return:**

1. Summary of work completed
2. Clear "NEXT STEP" section
3. Exact instructions for next agent invocation
4. All context needed for next phase
5. No ambiguity about what to do next

**Template:**

```markdown
## Phase [N] Complete: [Phase Name]

[Summary of what was accomplished]

### Key Outputs
- [Output 1]
- [Output 2]

---

## NEXT STEP: Invoke [next-agent-name]

Provide [next-agent-name] with the following context:

**Context Item 1:** [value]
**Context Item 2:** [value]

**Instructions for [next-agent-name]:**
[Specific, actionable instructions]
```

### Rule 3: Main Context Owns Workflow Control

**Main context responsibilities:**

- Invoke agents based on coordination instructions
- Pass context between agents
- Maintain workflow state
- Allow user to pause/resume
- Enable error recovery

**Agents should NOT:**

- Invoke other agents directly
- Make assumptions about workflow continuation
- Skip coordination instructions
- Proceed without explicit handoff

### Rule 4: Make Handoffs Explicit and Clear

**Good Handoff:**

```markdown
## NEXT STEP: Invoke catalio-test-strategist

Linear Issue: CDEV-184
User Story: As an admin, I want to see documentation health scores
Acceptance Criteria:
1. Dashboard shows health score
2. Score updates daily
3. Visual indicators present

Files to Test:
- lib/catalio/accounts/organization.ex
- lib/catalio_web/live/dashboard_live.ex

Test Files to Create:
- test/catalio/accounts/organization_test.exs
- test/catalio_web/live/dashboard_live_test.exs
```

**Bad Handoff:**

```markdown
Now proceed with testing.  ❌ Vague, no context
```

## Benefits of Agent Chaining

### ✅ No Tool Collisions

Each agent runs in isolation with its own tool scope. No naming conflicts.

### ✅ Clear Workflow Visibility

User can see exactly where they are in the workflow and what's next.

### ✅ Easy Pause/Resume

User can stop after any phase and resume later without losing context.

### ✅ Better Error Recovery

If an agent fails, restart that single phase without redoing earlier work.

### ✅ User Maintains Control

User decides when to proceed to next phase, can review outputs, make adjustments.

### ✅ Simpler Agent Logic

Each agent focuses on its specialty without workflow orchestration concerns.

## Anti-Patterns to Avoid

### ❌ Agent Nesting

```text
Agent A invokes Agent B directly
→ Tool name collisions
→ Complex error handling
→ Loss of workflow control
```

### ❌ Implicit Handoffs

```text
Agent completes work but doesn't provide next step instructions
→ User confused about what to do next
→ Workflow stalls
→ Context lost
```

### ❌ Incomplete Context Transfer

```text
Agent returns "Now run tests" without specifying which tests or context
→ Next agent lacks information
→ Work must be repeated
→ Inefficient workflow
```

### ❌ Autonomous Continuation

```text
Agent tries to proceed to next phase automatically
→ User loses control
→ Can't review intermediate outputs
→ Harder to debug issues
```

## Example: Correct Agent Chaining Flow

### Phase 1: Orchestrator Returns

```markdown
## Phase 1 Complete: Requirements Analyzed

Analyzed CDEV-184 for organization documentation health score feature.

### Implementation Plan
- Add aggregate to Organization resource
- Create dashboard component
- Set up daily recalculation job

### Files Identified
- lib/catalio/accounts/organization.ex (modify)
- lib/catalio_web/live/dashboard_live.ex (modify)
- lib/catalio/workers/health_score_worker.ex (create)

---

## NEXT STEP: Invoke catalio-test-strategist

**Linear Issue:** CDEV-184

**User Story:**
As an admin user, I want to see documentation health scores on the dashboard
so that I can quickly assess our organization's documentation quality.

**Acceptance Criteria:**
1. Dashboard displays health score aggregate from Organization
2. Score includes visual indicator (color-coded badge)
3. Score updates daily via background job
4. Multi-tenant: users only see their organization's score

**Files to Test:**
- lib/catalio/accounts/organization.ex (health_score aggregate)
- lib/catalio_web/live/dashboard_live.ex (dashboard display)
- lib/catalio/workers/health_score_worker.ex (daily job)

**Test Files to Create:**
- test/catalio/accounts/organization_test.exs
- test/catalio_web/live/dashboard_live_test.exs
- test/catalio/workers/health_score_worker_test.exs

**Complexity Notes:**
- Aggregate calculation involves multiple joined tables
- Multi-tenant isolation critical for security
- Background job needs to handle large organization counts
- Visual indicator logic has conditional color mapping

**Instructions:**
Create comprehensive failing tests covering all acceptance criteria,
multi-tenant isolation, and edge cases. Target 90%+ coverage.
```

### Main Context Invokes Phase 2

```markdown
Based on the orchestrator's instructions, I'm now invoking the
catalio-test-strategist to create the test suite.

[Invokes catalio-test-strategist with provided context]
```

### Phase 2: Test Strategist Returns

```markdown
## Phase 2 Complete: TDD Setup Finished

Created comprehensive failing test suite for CDEV-184.

### Test Files Created
- test/catalio/accounts/organization_test.exs (15 tests)
- test/catalio_web/live/dashboard_live_test.exs (8 tests)
- test/catalio/workers/health_score_worker_test.exs (6 tests)

Total: 29 test scenarios

### Current Status
All tests currently failing (TDD red phase). This is expected.

---

## NEXT STEP: Implementation (Phase 3)

Implement features to make tests pass. See phase-3-implementation.md for guidance.

[Phase continues with implementation...]
```

## Debugging Agent Coordination Issues

### Issue: Tool Name Collision

**Symptom:** Error "tools: Tool names must be unique"

**Cause:** Agent nesting - one agent invoked another

**Fix:** Refactor to use agent chaining with coordination instructions

### Issue: Lost Context Between Phases

**Symptom:** Next agent lacks information from previous phase

**Cause:** Incomplete coordination instructions

**Fix:** Ensure all relevant context included in handoff

### Issue: Workflow Stalls

**Symptom:** User unsure what to do after agent completes

**Cause:** Missing or vague "NEXT STEP" instructions

**Fix:** Always provide explicit, actionable next steps

### Issue: Repeated Work

**Symptom:** Agents re-analyzing or re-doing previous work

**Cause:** Context not preserved in coordination instructions

**Fix:** Include all relevant outputs and decisions in handoff

## Summary

**Agent chaining solves tool collision issues while providing:**

- Clear workflow visibility
- User control and flexibility
- Easy error recovery
- Maintainable agent logic
- Explicit handoffs with complete context

**Key principle:** Each agent completes its specialized work and returns coordination instructions. The main context invokes the next agent based on these instructions.

**Never nest agents. Always chain them.
