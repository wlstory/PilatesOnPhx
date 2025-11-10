# SDLC Workflow Command

Execute the complete Software Development Life Cycle workflow for the Linear issue: **$ARGUMENTS**

This command invokes the `sdlc` skill, which coordinates a comprehensive SDLC process through agent chaining.

## Quick Reference

The SDLC skill orchestrates:

1. **Phase 1** - Requirements Analysis (catalio-sdlc-orchestrator)
2. **Phase 2** - TDD Setup (catalio-test-strategist)
3. **Phase 3** - Implementation (Developer)
4. **Phase 4** - Quality Gate (catalio-debugger)
5. **Phase 5** - Completion (PR & Linear update)

## Detailed Documentation

For comprehensive documentation, see the skill files:

- **[SKILL.md](.claude/skills/sdlc/SKILL.md)** - Overview and workflow
- **[phase-1-requirements.md](.claude/skills/sdlc/phase-1-requirements.md)** - Orchestrator instructions
- **[phase-2-tdd.md](.claude/skills/sdlc/phase-2-tdd.md)** - Test strategist instructions
- **[phase-3-implementation.md](.claude/skills/sdlc/phase-3-implementation.md)** - Implementation guide
- **[phase-4-quality.md](.claude/skills/sdlc/phase-4-quality.md)** - Quality gate instructions
- **[phase-5-completion.md](.claude/skills/sdlc/phase-5-completion.md)** - PR creation steps
- **[agent-coordination.md](.claude/skills/sdlc/agent-coordination.md)** - Agent chaining best practices

## Usage

### With Slash Command

```bash
/sdlc CDEV-123
```

### With Natural Language

```text
Start SDLC workflow for CDEV-123
Implement feature from Linear issue CDEV-456
```

## Key Principles

**Agent Chaining (Not Nesting):**

- Each agent completes its work and returns coordination instructions
- Main context invokes next agent based on instructions
- Prevents tool name collisions and nesting issues

**Quality Standards:**

- TDD approach (tests before implementation)
- 90%+ test coverage required
- All `mix precommit` checks must pass
- Frequent WIP commits

**Success Criteria:**

- ✅ All tests passing
- ✅ Coverage ≥ 90%
- ✅ Quality gate clean
- ✅ PR created and linked
- ✅ Linear issue in "In Review"

---

**Now invoking the SDLC skill for Linear issue: $ARGUMENTS**

Please start by invoking the **catalio-sdlc-orchestrator** agent for Phase 1 (Requirements Analysis) with the Linear issue ID: $ARGUMENTS
