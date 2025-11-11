# GitHub Actions Workflows

This document describes the GitHub Actions workflows configured for PilatesOnPhx.

## Workflows

### CD (Continuous Deployment)

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
2. **Shallow Clones**: Uses `fetch-depth: 1` for faster checkout
3. **Concurrency**: CD workflow uses `deploy-group` to prevent concurrent deployments

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

## Monitoring

Monitor workflow runs to ensure they complete successfully:
```bash
gh run list
gh run watch  # Watch the latest run
```
