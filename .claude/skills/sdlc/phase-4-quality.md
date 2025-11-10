# Phase 4: Quality Gate

**Agent:** `catalio-debugger`

## Objective

Ensure code meets all quality standards by fixing ALL warnings, errors, and issues found by `mix precommit`.

## Quality Standards

All checks in `mix precommit` must pass:

- ✅ Compilation with warnings as errors
- ✅ No unused dependencies
- ✅ Code formatting (Elixir, JS, Markdown)
- ✅ Credo static analysis
- ✅ Sobelow security checks
- ✅ Dependencies audit
- ✅ Dialyzer type checking
- ✅ Test suite passing
- ✅ Test coverage ≥ 90%

## Tasks

### 1. Run Quality Checks

```bash
mix precommit
```

**Expected Output if Passing:**

```text
==> Running precommit checks...
✓ Compilation with warnings as errors
✓ Checking for unused dependencies
✓ Formatting Elixir code
✓ Formatting JavaScript
✓ Formatting Markdown
✓ Running Credo
✓ Running Sobelow
✓ Auditing dependencies
✓ Running Dialyzer
✓ Running tests with coverage
✓ All checks passed!
```

**If ANY check fails, proceed to debugging.**

### 2. Invoke catalio-debugger

**When to Invoke:**

- Any `mix precommit` check fails
- Compilation errors occur
- Tests are failing
- Coverage below 90%
- Security issues found
- Type errors from Dialyzer

**What to Provide:**

```text
Context: Quality gate for {ISSUE-ID}

Full output from mix precommit:
[Paste complete output including all errors and warnings]

Requirements:
- Fix ALL warnings and errors
- Ensure test coverage ≥ 90%
- Loop until mix precommit exit code = 0
```

### 3. Agent Debugging Loop

**catalio-debugger will:**

1. Analyze all errors and warnings
2. Prioritize fixes (blocking errors first)
3. Fix issues systematically
4. Make WIP commits after each fix
5. Re-run `mix precommit`
6. Loop until exit code = 0

**Do NOT proceed to Phase 5 until quality gate passes completely.**

## Common Issues and Fixes

### Compilation Warnings

**Issue:** Unused variables, unused imports, unused aliases

**Fix:**

```elixir
# Remove unused imports
# import Unused.Module  # Remove this

# Prefix unused variables with underscore
def my_function(_unused_param, actual_param) do
  # ...
end
```

### Credo Warnings

**Issue:** Code style violations, complexity issues

**Fix:**

- Refactor complex functions
- Add documentation
- Improve naming
- Extract helper functions

### Dialyzer Type Errors

**Issue:** Type mismatches, incorrect specs

**Fix:**

```elixir
# Add or correct type specs
@spec my_function(String.t(), integer()) :: {:ok, map()} | {:error, term()}
def my_function(name, age) do
  # ...
end
```

### Test Coverage Below 90%

**Issue:** Insufficient test coverage

**Fix:**

- Identify untested code paths
- Add missing test scenarios
- Test error cases and edge cases
- Ensure all business logic tested

**Check coverage:**

```bash
mix test --cover
open cover/excoveralls.html
```

### Security Issues (Sobelow)

**Issue:** SQL injection, XSS, insecure configs

**Fix:**

- Use parameterized queries
- Sanitize user input
- Follow security best practices
- Update vulnerable dependencies

### Formatting Issues

**Issue:** Code not formatted consistently

**Fix:**

```bash
mix format
git add .
git commit --amend --no-edit
```

## Debugging Strategy

### 1. Prioritize Fixes

**Order of Priority:**

1. **Blocking compilation errors** - Can't proceed without fixing
2. **Test failures** - Core functionality broken
3. **Security issues** - Critical vulnerabilities
4. **Coverage gaps** - Below 90% requirement
5. **Type errors** - Dialyzer issues
6. **Code quality** - Credo warnings
7. **Formatting** - Style consistency

### 2. Incremental Fixes

**Pattern:**

```bash
# Fix one category of issues
vim lib/file.ex

# Verify fix
mix precommit

# If improved, commit
git add .
git commit -m "WIP: Fix compilation warnings (ISSUE-ID)"

# Continue to next issue category
```

### 3. Test-Driven Fixes

**For test failures:**

```bash
# Run specific failing test
mix test test/path/to/test.exs:42

# Fix implementation
vim lib/implementation.ex

# Verify fix
mix test test/path/to/test.exs:42

# Run full suite
mix test

# Commit
git add .
git commit -m "WIP: Fix test failure in feature_test (ISSUE-ID)"
```

## Loop Until Clean

**The Loop:**

```bash
# 1. Run precommit
mix precommit

# 2. If failed, analyze output
# 3. Fix issues
# 4. Commit fixes
# 5. Go to step 1

# Loop until:
# mix precommit
# => exit code 0 (all checks passed)
```

**Never proceed to Phase 5 with failing checks.**

## Success Criteria

Phase 4 complete when:

- `mix precommit` exit code = 0
- ALL checks passing:
  - ✅ Compilation clean
  - ✅ No unused dependencies
  - ✅ All code formatted
  - ✅ Credo satisfied
  - ✅ Sobelow clean
  - ✅ Dependencies secure
  - ✅ Dialyzer happy
  - ✅ All tests passing
  - ✅ Coverage ≥ 90%

## Return Coordination Instructions

**When quality gate passes:**

```markdown
## Phase 4 Complete: Quality Gate Passed

All `mix precommit` checks passing:
- ✅ Compilation with warnings as errors
- ✅ No unused dependencies
- ✅ Code formatting
- ✅ Credo static analysis
- ✅ Sobelow security checks
- ✅ Dependencies audit
- ✅ Dialyzer type checking
- ✅ All tests passing
- ✅ Coverage: [X]% (≥ 90%)

### Fixes Applied
- [Fix 1]
- [Fix 2]
- [Fix 3]

### Current Status
- Branch: [branch-name]
- Total commits: [count]
- All WIP commits made
- Ready for PR creation

---

## NEXT STEP: PR Creation (Phase 5)

Proceed with creating the pull request:

**Instructions:**
1. Review all changes one final time
2. Create PR with comprehensive description
3. Link Linear issue in PR body
4. Document test coverage and quality checks
5. Update Linear issue status to "In Review"

See [phase-5-completion.md](phase-5-completion.md) for detailed PR creation steps.
```

## Common Pitfalls to Avoid

- Proceeding to Phase 5 with warnings
- Ignoring security issues
- Accepting coverage below 90%
- Not testing fixes thoroughly
- Suppressing warnings instead of fixing
- Skipping Dialyzer errors
- Not committing incremental fixes

## Tips for Success

**Be Thorough:**

- Fix every single warning
- Don't skip "minor" issues
- Test fixes completely

**Be Systematic:**

- Fix one category at a time
- Commit after each logical fix
- Re-run checks frequently

**Be Patient:**

- Quality takes time
- Loop until completely clean
- Don't rush to Phase 5

**Quality gate is non-negotiable. ALL checks must pass.**
