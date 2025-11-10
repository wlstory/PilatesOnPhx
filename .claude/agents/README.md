# Catalio Custom Agents

This directory contains specialized Claude Code agents that provide expert guidance for specific domains and workflows in the Catalio platform.

## Available Agents

### 1. `catalio-test-strategist`

**Purpose:** Comprehensive testing strategy and implementation for the Catalio platform

**When to use:**

- Designing tests for new Ash resources
- Reviewing and improving test coverage
- Debugging failing LiveView tests
- Optimizing test suite performance

**Key capabilities:**

- Domain-driven test design (always through domain interfaces)
- Property testing for diverse input scenarios
- Multi-tenant isolation testing
- Authorization policy testing with `Domain.can_*` functions
- 90%+ coverage strategy

**Model:** Opus (requires deep testing expertise)

### 2. `catalio-debugger`

**Purpose:** Debug errors, investigate issues, and enforce code quality standards

**When to use:**

- Ash resource validation failures
- Phoenix LiveView issues
- Database query problems
- Authentication flow debugging
- Running `mix precommit` with enforcement

**Key capabilities:**

- Systematic error analysis
- Multi-tenant debugging
- Stack-aware investigation (Ash/Phoenix/Elixir)
- **CRITICAL:** ALL warnings from `mix precommit` must be fixed
- Root cause analysis

**Model:** Opus (requires deep debugging skills)

### 3. `catalio-product-manager`

**Purpose:** Analyze code and create well-defined Linear issues with user stories

**When to use:**

- Extracting requirements from code
- Creating user stories in Linear
- Defining acceptance criteria
- Bridging technical and business perspectives

**Key capabilities:**

- Code analysis and requirement extraction
- Business Systems Analyst approach
- Linear issue creation with proper fields
- User story formatting (As a [role], I want [feature], so that [benefit])
- Comprehensive acceptance criteria

**Model:** Sonnet (good balance for analysis)

**Linear Integration:**

- Full MCP Linear server access
- Creates issues with proper project/label assignment
- NEVER sets assignee or cycle (manual assignment)
- ALWAYS sets priority and labels

### 4. `catalio-sdlc-orchestrator` ⭐ NEW

**Purpose:** Orchestrate complete Software Development Life Cycle workflows from Linear issue to PR

**When to use:**

- Starting development on a Linear issue
- Need structured TDD workflow
- Want automated quality gates
- Coordinating multiple development phases

**Key capabilities:**

- 7-phase SDLC coordination:
  1. Requirements Analysis
  2. TDD Setup (red phase)
  3. Implementation (green phase)
  4. Refactoring (refactor phase)
  5. Testing & Validation
  6. Quality Gate
  7. PR Creation & Completion
- Coordinates catalio-test-strategist and catalio-debugger
- Updates Linear issue throughout workflow
- Creates WIP commits at checkpoints
- Enforces 90%+ coverage and zero warnings
- Creates comprehensive PRs

**Model:** Opus (requires coordination intelligence)

**Linear Integration:**

- Fetches issues with `mcp__linear-server__get_issue`
- Updates issues with comments at each phase
- Links PRs to issues
- Transitions issue status to "In Review"

**Invocation:**
Use the `/sdlc` slash command:

```bash
/sdlc ISSUE-123
```

## Agent Coordination Patterns

### Single Agent Usage

Invoke an agent directly for focused tasks:

```text
User: "Can you help me design tests for the new Requirement resource?"
→ Invokes catalio-test-strategist directly
```

### Multi-Agent Orchestration

The SDLC orchestrator coordinates multiple agents:

```text
User: "/sdlc CAT-456"
→ catalio-sdlc-orchestrator starts
  → Phase 2: Invokes catalio-test-strategist for test design
  → Phase 6: Invokes catalio-debugger if quality issues found
→ Linear issue updated throughout
→ PR created at completion
```

## Integration with Hooks

Agents work seamlessly with [Claude Code hooks](../hooks/README.md):

- **auto-format.sh**: Runs after agent edits files
- **test-enforcer.sh**: Validates tests after agent creates/modifies them
- **quality-gate.sh**: Runs mix precommit when agents complete work
- **safety-commit.sh**: Creates WIP commits before agent operations

## Agent Development Guidelines

When creating new agents:

### File Structure

```markdown
---
name: agent-name
description: Brief description with usage examples
model: opus | sonnet
tools: (optional) Specific tool restrictions
---

[Agent instructions and behavior]
```

### Naming Conventions

- Use lowercase with hyphens: `catalio-feature-name`
- Start with `catalio-` prefix for project-specific agents
- Use descriptive, action-oriented names

### Description Format

Include clear examples of when to use the agent:

```markdown
description: Use this agent when [conditions]. Examples: <example>Context: [situation] user: "[user request]" assistant: "[response]" <commentary>[reasoning]</commentary></example>
```

### Model Selection

- **Opus**: Complex coordination, deep analysis, debugging, testing strategy
- **Sonnet**: Balanced tasks, code analysis, documentation
- **Haiku**: Simple, focused tasks (rarely needed for our platform)

### Tool Access

Most agents need full tool access. Specify `tools:` only if restricting:

```yaml
tools: Bash, Read, Write, Edit  # Restricted set
```

For agent-specific MCP access:

```yaml
tools: Bash, Read, mcp__linear-server__get_issue, mcp__linear-server__create_comment
```

## Testing Agents

Test agents manually before committing:

```bash
# Test by invoking in Claude Code session
# Example with catalio-test-strategist:

User: "I need comprehensive tests for the Organization resource"

# Agent should:
# 1. Analyze the resource
# 2. Design test strategy
# 3. Create test files
# 4. Follow domain-driven testing patterns
```

## Agent Best Practices

### Critical Thinking

All agents must follow these principles from CLAUDE.md:

- **Always** Be extraordinarily skeptical of assumptions
- **Always** Live in constant fear of being wrong
- **When appropriate** Broaden inquiry beyond stated assumptions
- **Always** Red team everything before declaring complete

### Domain-Driven Testing

For test-related agents, **ALWAYS**:

- Test through domain interfaces (`Catalio.Accounts.create/1`)
- NEVER bypass domains (`Ash.create/2` without domain)
- Use proper actor and tenant parameters
- Test business logic, not framework features

### Quality Standards

All agents must enforce:

- 90%+ code coverage requirement
- Zero warnings from `mix precommit`
- Comprehensive error handling
- Multi-tenant data isolation
- Proper authorization testing

### Communication

Agents should:

- Provide clear, actionable guidance
- Show progress and next steps
- Ask clarifying questions when needed
- Reference specific files with line numbers (e.g., `lib/catalio/accounts.ex:42`)

## Common Agent Workflows

### Workflow 1: New Feature Development

```text
1. User creates Linear issue (using web or catalio-product-manager)
2. User: /sdlc ISSUE-123
3. catalio-sdlc-orchestrator:
   - Fetches issue
   - Invokes catalio-test-strategist for tests
   - Guides implementation
   - Invokes catalio-debugger for quality
   - Creates PR
4. Result: Feature complete with tests, quality gates passed, PR ready
```

### Workflow 2: Debugging Production Issue

```text
1. User: "We have failing tests in LiveView - can you debug?"
2. System invokes catalio-debugger
3. catalio-debugger:
   - Analyzes error logs
   - Identifies root cause
   - Proposes fixes
   - Verifies fix with mix precommit
4. Result: Issue resolved, quality gates passed
```

### Workflow 3: Test Coverage Improvement

```text
1. User: "Our test coverage dropped to 85%, need to improve"
2. User manually invokes catalio-test-strategist
3. catalio-test-strategist:
   - Analyzes coverage report
   - Identifies gaps
   - Designs additional tests
   - Implements tests
   - Verifies 90%+ coverage
4. Result: Coverage above threshold
```

## Troubleshooting

### Agent Not Found

```bash
# Verify agent file exists
ls -la .claude/agents/

# Verify agent has proper frontmatter
cat .claude/agents/agent-name.md | head -5
```

### Agent Not Invoked

Check the description field has clear usage examples. Claude Code uses descriptions to determine when to invoke agents.

### Agent Fails to Complete

- Check if agent has required tool access
- Verify MCP servers are configured if using Linear tools
- Review agent logs in Claude Code UI

## Further Reading

- [Claude Code Agents Documentation](https://docs.claude.com/en/docs/claude-code/agents)
- [SDLC Workflow Guide](../commands/sdlc.md)
- [Hooks Integration](../hooks/README.md)
- [Project Development Guidelines](../../CLAUDE.md)
- [Framework Patterns](../../AGENTS.md)

## Contributing

To contribute a new agent:

1. Create agent file in `.claude/agents/`
2. Follow naming conventions and structure
3. Test thoroughly before committing
4. Update this README with agent documentation
5. Submit PR for review

**Quality Standards:**

- Clear description with usage examples
- Proper model selection
- Integration with existing systems
- Follows critical thinking principles
- Comprehensive error handling
