# GitHub Secrets Configuration

This document lists the required GitHub secrets for the workflows in this repository.

## Required Secrets

### Deployment (CD Workflow)

- **FLY_API_TOKEN** ✓ Configured
  - Used for deploying to Fly.io
  - Workflow: `.github/workflows/fly-deploy.yml`

## Adding Secrets

To add a secret to the repository:

```bash
gh secret set SECRET_NAME
```

Or via the GitHub web interface:
1. Go to Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Enter the name and value
4. Click "Add secret"

## Testing Secrets

To verify secrets are configured:

```bash
gh secret list
```

## Environment Variables

The following environment variables are configured in `fly.toml`:
- `PHX_HOST=pilatesonphx.fly.dev`
- `PORT=8080`

Additional runtime secrets should be added to Fly.io via:

```bash
flyctl secrets set SECRET_NAME=value
```
