# Phase 5: Completion

**Performer:** Developer (Manual)

## Objective

Create a pull request, link it to the Linear issue, and update the issue status to "In Review".

## Prerequisites

Before starting Phase 5:

- ✅ All tests passing
- ✅ Test coverage ≥ 90%
- ✅ `mix precommit` exit code = 0 (all quality checks passed)
- ✅ All WIP commits made
- ✅ Branch pushed to remote

## Tasks

### 1. Final Review

**Review All Changes:**

```bash
# See all commits
git log main..HEAD --oneline

# See all file changes
git diff main..HEAD

# Review specific files
git diff main..HEAD -- path/to/file.ex
```

**Verify:**

- All changes are intentional
- No debug code or console.logs left
- No commented-out code
- All WIP commit messages are descriptive
- No sensitive data in commits

### 2. Push Branch to Remote

```bash
# If not already pushed
git push -u origin HEAD

# If already pushed and updated
git push
```

### 3. Gather PR Information

**From Phase 1 (Requirements Analysis):**

- Linear issue ID
- Feature summary
- Key requirements
- Implementation approach

**From Current State:**

- Test coverage percentage
- Number of tests created
- Files modified/created
- Any notable implementation decisions

**From Quality Gate:**

- All checks passing
- Any fixes applied during quality gate
- Security scan results

### 4. Create Pull Request

**Using GitHub CLI:**

```bash
gh pr create \
  --title "Feature: [Descriptive Title] (ISSUE-ID)" \
  --body "$(cat <<'EOF'
Closes ISSUE-ID

## Summary
[Brief 1-2 sentence summary of what this PR does]

## Changes
- [Key change 1]
- [Key change 2]
- [Key change 3]

## Implementation Details
[Brief description of approach taken, any notable patterns used]

### Database Changes
[List any migrations, new tables, new fields - or "None"]

### New Resources/Modules
[List any new Ash resources, LiveViews, or major modules - or "None"]

## Testing
- ✅ All tests passing
- ✅ Coverage: [X]% (target: ≥90%)
- ✅ TDD approach: tests written first
- [X] total test scenarios added

### Test Coverage
- [Area 1]: [Description of test coverage]
- [Area 2]: [Description of test coverage]
- Multi-tenant isolation: ✅ Tested
- Authorization policies: ✅ Tested

## Quality Checks
- ✅ `mix precommit` passing
- ✅ No compilation warnings
- ✅ Credo satisfied
- ✅ Sobelow security scan clean
- ✅ Dialyzer type checking passed
- ✅ Dependencies audited

## Development Workflow
- TDD: Red → Green → Refactor
- Frequent WIP commits for rollback safety
- Incremental implementation
- Followed CLAUDE.md and AGENTS.md conventions

## Review Notes
[Any specific areas you want reviewers to focus on, or "Standard review"]

---

🤖 Generated via SDLC workflow with agent coordination
EOF
)"
```

**PR Title Format:**

- For features: `Feature: [Description] (ISSUE-ID)`
- For bug fixes: `Fix: [Description] (ISSUE-ID)`
- For enhancements: `Enhancement: [Description] (ISSUE-ID)`
- For refactoring: `Refactor: [Description] (ISSUE-ID)`

**Examples:**

- `Feature: Add organization documentation health score dashboard (CDEV-184)`
- `Fix: Resolve multi-tenant query isolation issue (CDEV-185)`
- `Enhancement: Improve requirement form validation UX (CDEV-186)`

### 5. Update Linear Issue

**Add Comment:**

```text
Use mcp__linear-server__create_comment with:
- Issue ID: [The Linear issue ID]
- Body:
```

```markdown
✅ **Pull Request Created**

PR: [Link to PR]

## Status
- ✅ Implementation complete
- ✅ All tests passing (Coverage: [X]%)
- ✅ Quality gate passed (mix precommit clean)
- ✅ Ready for code review

## Summary
[Brief summary of implementation]

## Next Steps
- Code review
- Address review feedback if any
- Merge upon approval
```

**Update Issue Status:**

```text
Use mcp__linear-server__update_issue with:
- Issue ID: [The Linear issue ID]
- State: "In Review" (or your team's equivalent status)
```

### 6. Notify Team (Optional)

**If applicable:**

- Post in team chat (Slack, Discord, etc.)
- Notify specific reviewers
- Add to standup notes

## PR Description Template

Use this template structure for comprehensive PR descriptions:

```markdown
Closes [ISSUE-ID]

## Summary
[1-2 sentence summary]

## Changes
- [Bullet list of key changes]

## Implementation Details
[Brief description of approach]

### Database Changes
[Migrations, schema changes, or "None"]

### New Resources/Modules
[New files/resources created, or "None"]

## Testing
- ✅ All tests passing
- ✅ Coverage: X%
- ✅ TDD approach followed
- X test scenarios added

### Test Coverage
[Description of what's tested]

## Quality Checks
- ✅ mix precommit passing
- ✅ All quality gates satisfied

## Development Workflow
- TDD: Red → Green → Refactor
- Frequent WIP commits
- Followed conventions

## Review Notes
[Specific review guidance or "Standard review"]

---
🤖 Generated via SDLC workflow
```

## Common PR Mistakes to Avoid

- Vague or generic PR titles
- Missing Linear issue link
- No test coverage information
- Not mentioning database changes
- Forgetting to update Linear issue status
- Not providing context for reviewers
- Including debug or WIP code
- Missing review focus areas

## Success Criteria

Phase 5 complete when:

- ✅ Branch pushed to remote
- ✅ Pull request created with comprehensive description
- ✅ Linear issue linked in PR body
- ✅ Linear comment added with PR link
- ✅ Linear issue status updated to "In Review"
- ✅ Team notified (if applicable)

## Post-PR Activities

### During Code Review

- Respond to review comments promptly
- Make requested changes in new commits
- Re-run tests after changes
- Update PR description if significant changes made

### After Approval

```bash
# Merge via GitHub interface (usually)
# Or use CLI
gh pr merge --squash  # or --merge or --rebase

# Delete branch after merge
git checkout main
git pull
git branch -d feature-branch
```

### After Merge

**Update Linear:**

```text
Use mcp__linear-server__update_issue with:
- Issue ID: [The Linear issue ID]
- State: "Done" (or your team's equivalent)
```

**Add Final Comment:**

```markdown
✅ **Merged to Main**

PR merged: [Link]
Deployed: [Deployment status if applicable]

Feature now available in [environment].
```

## Verification After Merge

**Verify Deployment (if applicable):**

- Check feature in staging/production
- Verify database migrations ran
- Test feature functionality
- Monitor for errors or issues

**Close Loop:**

- Archive related documents
- Update documentation if needed
- Share learnings with team
- Celebrate completion 🎉

## SDLC Workflow Complete

Congratulations! You've completed the full SDLC workflow:

1. ✅ Requirements analyzed
2. ✅ Tests written (TDD red phase)
3. ✅ Implementation complete (TDD green/refactor)
4. ✅ Quality gate passed
5. ✅ PR created and merged
6. ✅ Linear issue completed

**Next Linear issue? Start the workflow again!**

```bash
/sdlc NEXT-ISSUE-ID
```
