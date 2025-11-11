# GitHub Actions Workflows

This document describes the GitHub Actions workflows configured for PilatesOnPhx.

## Workflows

### 1. CD (Continuous Deployment)

**File**: `.github/workflows/fly-deploy.yml`

**Trigger**: Push to `main` branch

**Purpose**: Automatically deploys the application to Fly.io production environment

**Configuration**:
- Environment: production
- URL: https://pilatesonphx.fly.dev
- Uses: `superfly/flyctl-actions/setup-flyctl@master`
- Checkout depth: 1 (shallow clone for faster deployments)

**Required Secrets**:
- `FLY_API_TOKEN` ✓ Configured

**Testing**:
```bash
# Test by merging to main branch
git checkout main
git merge feature-branch
git push origin main
```

### 2. Claude Code Interactive

**File**: `.github/workflows/claude.yml`

**Trigger**:
- Issue comments containing `@claude`
- Pull request review comments containing `@claude`
- Pull request reviews containing `@claude`
- Issues opened/assigned containing `@claude`

**Purpose**: Enables interactive Claude Code assistance on GitHub issues and PRs

**Permissions Required**:
- Only OWNER, MEMBER, or COLLABORATOR can trigger
- Contents: read
- Pull requests: read
- Issues: read
- ID token: write
- Actions: read (for CI results)

**Required Secrets**:
- `ANTHROPIC_API_KEY` ⚠️ Needs to be added

**Testing**:

1. Add the ANTHROPIC_API_KEY secret:
   ```bash
   gh secret set ANTHROPIC_API_KEY
   # Paste your API key when prompted
   ```

2. Create a test issue:
   ```bash
   gh issue create --title "Test Claude Integration" --body "@claude Please help me understand the project structure"
   ```

3. Or comment on a PR:
   ```bash
   gh pr comment <PR_NUMBER> --body "@claude Please review this change"
   ```

4. Check workflow runs:
   ```bash
   gh run list --workflow=claude.yml
   gh run view <RUN_ID> --log
   ```

## Workflow Status

Check all workflow runs:
```bash
gh run list
```

View specific workflow run:
```bash
gh run view <RUN_ID>
```

View workflow logs:
```bash
gh run view <RUN_ID> --log
```

## Best Practices

1. **CD Workflow**: Only triggers on main branch to prevent accidental deployments
2. **Claude Workflow**: Limited to authorized users to prevent abuse
3. **Shallow Clones**: Uses `fetch-depth: 1` for faster checkout
4. **Concurrency**: CD workflow uses `deploy-group` to prevent concurrent deployments

## Troubleshooting

### CD Workflow Fails

1. Check Fly.io token is valid:
   ```bash
   gh secret list | grep FLY_API_TOKEN
   ```

2. Verify Fly.io app configuration:
   ```bash
   flyctl status
   ```

3. Check workflow logs:
   ```bash
   gh run list --workflow=fly-deploy.yml
   gh run view <RUN_ID> --log
   ```

### Claude Workflow Not Triggering

1. Verify ANTHROPIC_API_KEY is set:
   ```bash
   gh secret list | grep ANTHROPIC_API_KEY
   ```

2. Ensure you're using `@claude` in the comment/issue
3. Verify you have OWNER, MEMBER, or COLLABORATOR permissions
4. Check workflow runs for errors:
   ```bash
   gh run list --workflow=claude.yml
   ```

## Next Steps

1. ⚠️ Add ANTHROPIC_API_KEY secret
2. Test Claude workflow by creating an issue with `@claude`
3. Monitor workflow runs to ensure they complete successfully
