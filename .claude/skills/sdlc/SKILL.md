---
name: sdlc
description: Complete Software Development Life Cycle workflow for Linear issues. Coordinates requirements analysis, TDD setup, implementation, testing, and PR creation through agent chaining. Use when starting work on Linear issues, implementing features from Linear, or when user mentions SDLC workflow, Linear issue development, test-driven development, or feature implementation workflow.
---

# SDLC Workflow Skill

Execute a comprehensive Software Development Life Cycle workflow for Linear issues using agent chaining coordination.

## Overview

This skill orchestrates a complete SDLC workflow through multiple specialized agents:

1. **Requirements Analysis** (catalio-sdlc-orchestrator)
2. **TDD Setup** (catalio-test-strategist)
3. **Implementation** (Manual or Agent)
4. **Quality Gate** (catalio-debugger)
5. **Completion** (PR Creation & Linear Update)

## How to Use

### With Slash Command

```bash
/sdlc CDEV-123
```

### With Natural Language

```text
Start SDLC workflow for CDEV-123
Implement feature from Linear issue CDEV-456
Begin development for CDEV-789
```

## Workflow Phases

### Phase 1: Requirements Analysis

See [phase-1-requirements.md](phase-1-requirements.md) for detailed orchestrator instructions.

**What happens:**

- Fetch Linear issue details
- Analyze user story and acceptance criteria
- Create implementation plan
- Make initial WIP commit
- Add Linear comment
- Return coordination instructions for Phase 2

### Phase 2: TDD Setup

See [phase-2-tdd.md](phase-2-tdd.md) for detailed test strategist instructions.

**What happens:**

- Create comprehensive failing tests (TDD red phase)
- Cover all acceptance criteria
- Target 90%+ coverage
- Make WIP commit with test files
- Return instructions for implementation

### Phase 3: Implementation

See [phase-3-implementation.md](phase-3-implementation.md) for implementation guidance.

**What happens:**

- Implement features to make tests pass (TDD green phase)
- Refactor while keeping tests green
- Follow CLAUDE.md and AGENTS.md conventions
- Make incremental WIP commits
- Hooks run automatically (auto-format, test-enforcer)

### Phase 4: Quality Gate

See [phase-4-quality.md](phase-4-quality.md) for debugger quality gate instructions.

**What happens:**

- Run `mix precommit`
- Fix ALL warnings and errors
- Loop until clean (exit code 0)
- Ensure test coverage meets 90%+ requirement

### Phase 5: Completion

See [phase-5-completion.md](phase-5-completion.md) for PR creation steps.

**What happens:**

- Create PR with comprehensive description
- Link to Linear issue
- Document test coverage
- Update Linear issue to "In Review"

## Agent Coordination Pattern

This skill uses **agent chaining** to avoid tool nesting issues. See [agent-coordination.md](agent-coordination.md) for detailed best practices.

**Key Principle:** Each agent completes its work and returns coordination instructions for the next agent. The main context invokes the next agent based on these instructions.

**Why This Works:**

- No tool name collisions (agents don't nest)
- Clear handoffs between phases
- User maintains control of workflow
- Each agent focuses on its specialty
- Easy to pause/resume
- Better error recovery

## Quality Standards

- Tests written BEFORE implementation (TDD)
- 90%+ test coverage required
- ALL `mix precommit` warnings must be fixed
- Follow CLAUDE.md and AGENTS.md conventions
- Frequent WIP commits for rollback safety

## Success Criteria

Workflow complete when:

- All tests passing
- Coverage ≥ 90%
- `mix precommit` clean (exit code 0)
- PR created and linked
- Linear issue in "In Review"

## Troubleshooting

**Tool nesting errors:** Ensure you're using agent chaining, not nested agent invocations. Each agent returns instructions; main context invokes next agent.

**Coverage not met:** Use catalio-test-strategist to add more comprehensive tests before moving to quality gate.

**Quality gate fails:** Invoke catalio-debugger with full `mix precommit` output to resolve all issues systematically.

## Required Context

Before starting, ensure you have:

- Linear issue ID (e.g., CDEV-123)
- Access to Linear workspace
- Clean working directory (or committed changes)
- All tests passing in current state
