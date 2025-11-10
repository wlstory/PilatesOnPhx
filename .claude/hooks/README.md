# Claude Code Hooks for Catalio

This directory contains custom hooks that enforce development standards and automate quality checks during Claude Code sessions.

## Overview

Hooks are shell scripts that execute automatically at specific points in the Claude Code workflow, providing deterministic control over code quality, testing, and safety practices.

## Available Hooks

### 1. `auto-format.sh` (PostToolUse Hook)

**Triggers:** After Edit/Write operations on code files

**Purpose:** Automatically formats code according to project standards

**Supported Formats:**

- Elixir (`.ex`, `.exs`) - via `mix format`
- JavaScript/TypeScript (`.js`, `.jsx`, `.ts`, `.tsx`) - via Prettier
- Markdown (`.md`) - via markdownlint-cli2

**Behavior:**

- Runs appropriate formatter based on file extension
- Logs formatting activity to `hooks.log`
- Non-blocking (continues even if formatter unavailable)

### 2. `test-enforcer.sh` (PostToolUse Hook)

**Triggers:** After Edit/Write operations on files in `lib/` or `test/` directories

**Purpose:** Enforce TDD by running tests and checking coverage

**Behavior:**

- Detects corresponding test file for modified code
- Runs tests with coverage enabled
- Warns if no test file exists (suggests using `catalio-test-strategist` agent)
- Checks coverage against 90% threshold
- Shows test failures with actionable feedback
- Non-blocking but provides clear warnings

**Example Output:**

```text
⚠️  MISSING TESTS - No test file found
File modified: lib/catalio/foo/bar.ex

Recommended action:
  1. Consider using the catalio-test-strategist agent to design tests
  2. Create test file with proper coverage of business logic
```

### 3. `quality-gate.sh` (Stop Hook)

**Triggers:** When Claude finishes responding

**Purpose:** Run comprehensive quality checks via `mix precommit`

**Checks Performed:**

- Code formatting (Elixir, JS, Markdown)
- Unused dependencies
- Compilation warnings (warnings-as-errors)
- Credo static analysis
- Sobelow security analysis
- Hex dependency audit
- Dialyzer type checking

**Enforcement:**
Per `catalio-debugger` requirements: **ALL warnings must be fixed**

**Example Output:**

```text
⚠️  QUALITY GATE FAILURE - Warnings Detected

Per catalio-debugger requirements:
ALL warnings from mix precommit must be fixed.

Issues found:
📋 Compilation Warnings:
  warning: unused variable "foo"
    lib/catalio/example.ex:42

To fix these issues:
  1. Review the warnings above
  2. Run 'mix precommit' locally to see full details
  3. Fix all issues
```

**Note:** Ensure hooks are executable: `chmod +x ./.claude/hooks/*.sh`

**Important:** With multiple PreToolUse hooks, order matters; keep safety-commit.sh first to ensure WIP commits happen before other checks.

### 4. `pr-quality-gate.sh` (PreToolUse Hook)

**Triggers:** Before any `gh pr create` Bash command

**Purpose:** Enforce `mix precommit` quality checks before PR creation

**Enforcement Level:** **BLOCKING** - Will prevent PR creation if quality checks fail

**Behavior:**

- Intercepts all `gh pr create` commands
- Runs `mix precommit` with deterministic exit code capture
- **Blocks PR creation** if exit code != 0
- Shows detailed error messages with specific issues
- Only allows PR creation after all quality checks pass

**Checks Enforced:**

- All tests pass
- Code formatting (Elixir, JS, Markdown)
- No compilation warnings
- No Credo issues
- No Sobelow security warnings
- No Dialyzer type warnings
- No unused dependencies

**Example Output (Failure):**

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚫 PR CREATION BLOCKED - Quality Gate Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The PR Quality Gate has BLOCKED this PR creation because
mix precommit reported warnings or errors.

Per project requirements: ALL warnings must be fixed before
creating a Pull Request.

Issues detected in mix precommit:

📋 Compilation Warnings:
  warning: unused variable "foo"
    lib/catalio/example.ex:42

Required Actions:
  1. Run 'mix precommit' locally to see full error details
  2. Fix ALL warnings and errors
  3. Re-run 'mix precommit' to verify fixes (exit code must be 0)
  4. Only then retry PR creation
```

**Recommended Workflow:**

Instead of using `gh pr create` directly, use the safe wrapper script:

```bash
./scripts/create_pr.sh --title "Feature" --body "Description"
```

This wrapper:

- Runs `mix precommit` automatically
- Shows clear pass/fail status
- Only creates PR if checks pass
- Provides actionable error messages

**Integration with SDLC:**

The `catalio-sdlc-orchestrator` agent uses this enforcement to ensure:

- No PR is created without passing quality checks
- Exit codes are captured deterministically
- No assumptions or guessing - actual verification occurs

### 5. `safety-commit.sh` (PreToolUse Hook)

**Triggers:** Before potentially destructive Bash operations

**Purpose:** Create WIP commits for easy rollback

**Creates Commits For:**

- `rm` commands
- `rm -rf` operations
- `git reset` commands
- Large file modification operations

**Commit Message Format:**

```text
WIP: [automated safety checkpoint] before <operation>

Changes: 3 modified, 2 new

This is an automated safety commit created by Claude Code hooks
to enable easy rollback if needed.
```

**Rollback Instructions:**

```bash
# Undo last safety commit
git reset --soft HEAD~1
```

**Prevention:**

- Won't create duplicate commits (checks last commit message)
- Won't commit during git operations (prevents loops)
- Only commits if there are actual changes

### 6. `notify.sh` (Notification Hook)

**Triggers:** When Claude Code sends notifications

**Purpose:** Send desktop notifications for important events

**Platform Support:**

- **Linux:** Uses `notify-send`
- **macOS:** Uses `osascript`
- **Windows:** Uses PowerShell

**Notification Triggers:**
Keywords: "complete", "finished", "done", "ready", "failed", "error", "success", "test", "build", "check"

**Example:**

```text
Title: Claude Code
Message: Tests completed with 95% coverage
```

### 7. `smart-dispatcher.sh`

**Purpose:** Central routing logic for hooks (internal use)

**Behavior:**

- Routes hook events to appropriate specialized handlers
- Logs all hook invocations
- Provides unified logging infrastructure

## Safe PR Creation Script

In addition to the hooks, the project provides a wrapper script for safe PR creation:

### `scripts/create_pr.sh`

**Purpose:** Enforce quality checks before PR creation with user-friendly output

**Usage:**

```bash
# Simple usage
./scripts/create_pr.sh --title "Feature title" --body "Description"

# With heredoc for multi-line body
./scripts/create_pr.sh --title "Feature" --body "$(cat <<'EOF'
## Description
Closes ISSUE-123

### Implementation
...
EOF
)"

# All gh pr create arguments are supported
./scripts/create_pr.sh --title "Title" --body "Body" --draft --reviewer username
```

**Behavior:**

1. Runs `mix precommit` with clear progress indication
2. Captures exit code deterministically
3. If checks pass: Creates PR using `gh pr create`
4. If checks fail: Shows detailed errors and blocks PR creation

**Example Output (Success):**

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Running Quality Checks (mix precommit)...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[mix precommit output]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Quality Gate Passed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating Pull Request...

✅ Pull Request created successfully!
```

**Why Use This Script:**

- ✅ **Deterministic** - No assumptions, actual exit code verification
- ✅ **User-friendly** - Clear colored output and progress indication
- ✅ **Blocking** - Impossible to create PR if quality checks fail
- ✅ **Integrated** - Works seamlessly with hooks and SDLC workflow
- ✅ **Flexible** - Supports all `gh pr create` arguments

**Integration:**

The `catalio-sdlc-orchestrator` agent uses this script instead of direct `gh pr create` commands to ensure quality enforcement.

## Configuration

Hooks are configured in `.claude/settings.local.json`:

**Note:** Ensure all hook scripts are executable before use: `chmod +x ./.claude/hooks/*.sh`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/auto-format.sh"
          },
          {
            "type": "command",
            "command": "./.claude/hooks/test-enforcer.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/safety-commit.sh"
          },
          {
            "type": "command",
            "command": "./.claude/hooks/pr-quality-gate.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/quality-gate.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/notify.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": ".*commit.*|.*git.*",
        "hooks": [
          {
            "type": "command",
            "command": "mix precommit"
          }
        ]
      }
    ]
  }
}
```

## Integration with Custom Agents

### catalio-test-strategist

- **Triggered by:** `test-enforcer.sh` when tests are missing
- **Purpose:** Design comprehensive test strategies
- **Usage:** Hook suggests using this agent for missing tests

### catalio-debugger

- **Enforces:** ALL warnings from `mix precommit` must be fixed
- **Triggered by:** `quality-gate.sh` failures
- **Purpose:** Debug and resolve quality issues

## Logging

All hooks log to `.claude/hooks/hooks.log`:

```bash
# View recent hook activity
tail -f .claude/hooks/hooks.log

# View specific hook logs
grep "\[auto-format\]" .claude/hooks/hooks.log

# View today's activity
grep "$(date '+%Y-%m-%d')" .claude/hooks/hooks.log
```

## Hook Execution Flow

### Example 1: Editing a File

```text
1. User: Edit lib/catalio/foo.ex
   ↓
2. Edit Tool: Makes changes to file
   ↓
3. PostToolUse Hook: auto-format.sh
   → Runs mix format on lib/catalio/foo.ex
   ↓
4. PostToolUse Hook: test-enforcer.sh
   → Runs test/catalio/foo_test.exs
   → Checks coverage
   ↓
5. Stop Hook: quality-gate.sh
   → Runs mix precommit
   → Reports any warnings
```

### Example 2: Destructive Bash Operation

```text
1. User: Bash command "rm -rf old_directory"
   ↓
2. PreToolUse Hook: safety-commit.sh
   → Creates WIP commit if changes exist
   → Provides rollback point
   ↓
3. Bash Tool: Executes rm -rf old_directory
   ↓
4. Stop Hook: quality-gate.sh
   → Runs mix precommit
   → Reports any warnings
```

**Note:** safety-commit.sh only triggers before Bash operations (matcher: "Bash"), not before Edit/Write operations. It creates safety checkpoints before potentially destructive commands like `rm`, `git reset`, etc.

## Troubleshooting

### Hooks Not Running

```bash
# Check if hooks are enabled
grep -A5 '"hooks"' .claude/settings.local.json

# Check if scripts are executable
ls -la .claude/hooks/*.sh

# Make scripts executable if needed
chmod +x .claude/hooks/*.sh
```

### Hook Errors

```bash
# View error logs
tail -50 .claude/hooks/hooks.log

# Test hook manually
echo '{"file_path": "lib/catalio/test.ex"}' | ./.claude/hooks/auto-format.sh
```

### Disable Specific Hook

Edit `.claude/settings.local.json` to set the hook type to an empty array:

```json
{
  "hooks": {
    "PostToolUse": [],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/safety-commit.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/hooks/quality-gate.sh"
          }
        ]
      }
    ]
  }
}
```

This example disables all PostToolUse hooks (auto-format and test-enforcer) while keeping other hooks active.

### Disable All Hooks

Add to `.claude/settings.local.json`:

```json
{
  "disableAllHooks": true
}
```

## Development Workflow Integration

### With mix precommit

When you mention "commit" or "git" in prompts, the `UserPromptSubmit` hook automatically runs `mix precommit`, which includes:

- Compilation with warnings-as-errors
- Dependency cleanup
- Full formatting (Elixir + JS + Markdown)
- Test suite with coverage

### With WIP Commits

Safety commits follow the project's WIP commit convention from CLAUDE.md:

```bash
WIP: [automated safety checkpoint] before rm operations
WIP: Fix validation issues in product generator
WIP: Add explicit create action to Product resource
```

### With TDD Requirements

The test enforcer aligns with CLAUDE.md requirements:

- 90%+ coverage target
- Focus on business logic, not framework features
- Integration with `catalio-test-strategist` agent
- Comprehensive test scenarios

## Performance Considerations

- Hooks run asynchronously when possible
- Most hooks complete in < 2 seconds
- `mix precommit` takes 30-60 seconds (quality-gate includes full test suite)

## Security

**Important:** Hooks run with your current environment credentials. Review all hook scripts before use.

All hooks in this directory:

- Are open source and auditable
- Log all operations
- Don't send data externally
- Respect git ignored files
- Follow least-privilege principle

## Benefits

✅ **Automatic Code Quality** - Format and check on every change
✅ **TDD Enforcement** - Tests run automatically, coverage validated
✅ **Safety Net** - WIP commits before destructive operations
✅ **Fast Feedback** - Immediate quality issues surfaced
✅ **Agent Integration** - Leverages existing test-strategist & debugger
✅ **Zero Overhead** - Hooks run automatically, no manual intervention
✅ **Rollback Capability** - Easy recovery from problematic changes

## Further Reading

- [Claude Code Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks-guide)
- [Catalio Development Guidelines](../../CLAUDE.md)
- [Ash Framework Testing Patterns](../../AGENTS.md)
