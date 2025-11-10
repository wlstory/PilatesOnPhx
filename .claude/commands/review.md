# Code Review Iteration Command

Execute code review iteration workflow for GitHub PR: **$ARGUMENTS**

## Workflow Overview

This command will iterate on CodeRabbit review comments, making necessary changes, running quality checks, and marking comments as resolved.

The workflow includes:

1. **Fetch Review Comments** - Get all CodeRabbit comments from the PR
2. **Address Comments** - Iterate through and fix each comment
3. **Quality Gate** - Run mix precommit and fix all warnings
4. **Finalization** - Push changes, resolve comments, add summary

## Instructions

Please coordinate the complete code review iteration workflow for GitHub PR: **$ARGUMENTS**

Execute the following phases in order:

### Phase 1: Fetch Review Comments

- Use `gh pr view $ARGUMENTS --json number,title,url,headRefName` to get PR details
- Use `gh api repos/{owner}/{repo}/pulls/$ARGUMENTS/comments` to fetch inline review comments
- Use `gh api repos/{owner}/{repo}/issues/$ARGUMENTS/comments` to fetch general PR comments
- Filter for CodeRabbit comments (check comment author/bot)
- Parse and organize comments by:
  - File path
  - Line number (for inline comments)
  - Comment body/suggestion
  - Comment ID (for resolution tracking)
- Present a summary to the user:
  - Total number of CodeRabbit comments
  - Comments by file
  - Preview of suggestions
- Ask for confirmation before proceeding

### Phase 2: Address Comments Iteratively

For each CodeRabbit comment:

**2.1 Analyze the Comment**

- Read the comment body and suggested change
- Identify the file and line number (if inline comment)
- Understand the issue/improvement requested
- If the suggestion is unclear, ask the user for guidance

**2.2 Make Required Changes**

- Use the `catalio-debugger` agent via the Task tool if the fix is complex
- For simple changes (formatting, naming, docs), make changes directly
- Ensure changes align with project conventions from CLAUDE.md and AGENTS.md
- Test that changes don't break functionality

**2.3 Commit Each Change**

- Create WIP commit with descriptive message:
  - For inline comments: `WIP: Address CodeRabbit comment on {file}:{line} - {brief description}`
  - For general comments: `WIP: Address CodeRabbit suggestion - {brief description}`
- Include comment ID in commit message for traceability

**2.4 Track Progress**

- Update user on progress: "Addressed X of Y comments"
- Continue until all comments are processed

### Phase 3: Quality Gate

**3.1 Run Quality Checks**

- Run `mix precommit` to verify all changes pass quality standards
- This includes:
  - Compilation with warnings as errors
  - Code formatting (Elixir, JS, Markdown)
  - Credo static analysis
  - Sobelow security checks
  - Dependency audit
  - Dialyzer type checking
  - Full test suite with coverage

**3.2 Fix Any Issues**

- If `mix precommit` reports warnings or errors:
  - Invoke the `catalio-debugger` agent using the Task tool
  - Provide the agent with error/warning output
  - Follow debugger's guidance to resolve all issues
  - Per catalio-debugger requirements: all warnings must be resolved
- Create commit: `Fix quality issues from review iteration for PR $ARGUMENTS`

**3.3 Verify Tests**

- Ensure all tests are passing
- Verify coverage still meets 90%+ requirement
- If tests fail or coverage drops:
  - Use `catalio-test-strategist` agent to design additional tests
  - Fix failing tests
  - Commit: `Fix tests after review iteration for PR $ARGUMENTS`

### Phase 4: Finalization

**4.1 Push Changes**

- Get the PR branch name from Phase 1
- Push all commits to the PR branch: `git push origin {branch-name}`
- Verify push succeeded

**4.2 Mark Review Threads as Resolved**

- For each review thread ID collected in Phase 1:
  - Mark as resolved using GraphQL mutation:

    ```bash
    gh api graphql -f query='
      mutation {
        resolveReviewThread(input: {threadId: "{thread_id}"}) {
          thread {
            id
            isResolved
          }
        }
      }'
    ```

  - Extract thread ID from the review comment data structure
  - Track which threads were successfully resolved
  - Log any resolution failures

**4.3 Add Summary Comment**

- Create a comprehensive PR comment summarizing the iteration:

  ```markdown
  ## CodeRabbit Review Iteration Complete

  Addressed {X} CodeRabbit review comments:

  ### Changes Made
  - {Brief summary of each fix}

  ### Quality Checks
  - ✅ All tests passing
  - ✅ Code coverage: {X}% (meets 90%+ requirement)
  - ✅ mix precommit clean (no warnings or errors)

  ### Next Steps
  - Waiting for CodeRabbit re-review
  - Ready for human review

  🤖 Generated via `/review` command
  ```

- Post comment using: `gh pr comment $ARGUMENTS --body "{message}"`

**4.4 Report to User**

- Provide summary of completed work:
  - Number of comments addressed
  - Commits created
  - Quality check results
  - PR URL for reference
- Inform user that CodeRabbit should automatically re-review

## Important Notes

**CodeRabbit Integration:**

- CodeRabbit automatically detects when new commits are pushed
- It will re-review changed files and update/resolve old comments
- This command marks comments as resolved, but CodeRabbit may reopen if issues persist
- Multiple iterations may be needed for complex reviews

**Quality Standards:**

- ALL warnings from `mix precommit` must be fixed
- Follow conventions from CLAUDE.md and AGENTS.md
- Make frequent WIP commits for rollback safety
- Ensure tests remain passing and coverage stays high

**Agent Coordination:**

- Use `catalio-debugger` agent for complex fixes and quality issues
- Use `catalio-test-strategist` agent if tests need updates
- Provide clear context to each agent
- Review agent outputs before committing changes

**GitHub CLI Requirements:**

- Requires `gh` CLI installed and authenticated
- Repository must be on GitHub
- User must have push access to PR branch
- PR must be in the current repository

## Error Handling

If any phase fails:

1. **Comment Fetch Failure:**
   - Verify PR number is correct
   - Check GitHub authentication: `gh auth status`
   - Verify repository access permissions

2. **Code Changes Failure:**
   - Stop iteration and inform user
   - Preserve WIP commits made so far
   - Allow user to fix manually or retry command

3. **Quality Gate Failure:**
   - Present full error output to user
   - Use `catalio-debugger` agent to diagnose
   - Do not proceed to finalization until all issues fixed

4. **Comment Resolution Failure:**
   - Log which comments couldn't be resolved
   - Continue with other comments
   - Inform user of partial success

5. **Push Failure:**
   - Check for merge conflicts
   - Verify branch permissions
   - Guide user to resolve and retry

For any failure:

- Provide clear error information
- Suggest remediation steps
- Allow user to decide whether to continue or abort

## Success Criteria

The workflow is complete when:

- ✅ All CodeRabbit comments have been addressed
- ✅ All tests are passing
- ✅ Code coverage is 90%+
- ✅ `mix precommit` reports no warnings or errors
- ✅ All changes pushed to PR branch
- ✅ CodeRabbit comments marked as resolved
- ✅ Summary comment added to PR
- ✅ User has reviewed and approved the iteration

## Re-running the Command

This command can be run multiple times for the same PR:

- After CodeRabbit re-reviews and adds new comments
- If new review rounds identify additional issues
- To iterate on human reviewer feedback (if they use matching comment format)

Each run will:

- Only process unresolved comments
- Build on previous commits
- Maintain the WIP commit history
- Add a new summary comment

---

**Now proceed with executing the code review iteration workflow for GitHub PR: $ARGUMENTS**
