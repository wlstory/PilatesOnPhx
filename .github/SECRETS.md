# GitHub Secrets Documentation

This document lists all GitHub secrets required for the CI/CD pipeline to function properly.

## Required Secrets

### Core Secrets

| Secret Name | Description | Where to Get | Required For |
|-------------|-------------|--------------|--------------|
| `FLY_API_TOKEN` | Fly.io API authentication token | Run `flyctl auth token` after logging in | CD, Staging deployments |
| `ANTHROPIC_API_KEY` | Anthropic API key for Claude integration | [Anthropic Console](https://console.anthropic.com/) | Claude workflows (optional) |

### Staging Environment Secrets (Optional)

These are only needed if you want staging-specific configurations that differ from production:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `STAGING_AUTH0_DOMAIN` | Auth0 domain for staging | `your-app-staging.auth0.com` |
| `STAGING_AUTH0_CLIENT_ID` | Auth0 client ID for staging | Generated in Auth0 dashboard |
| `STAGING_AUTH0_CLIENT_SECRET` | Auth0 client secret for staging | Generated in Auth0 dashboard |
| `STAGING_RESEND_API_KEY` | Resend API key for staging emails | From Resend dashboard |

### GitHub App Secrets (Optional)

These are only needed if you want automatic cleanup of deployment environments:

| Secret Name | Description | Where to Get |
|-------------|-------------|--------------|
| `APP_ID` | GitHub App ID for deployment cleanup | GitHub App settings |
| `PRIVATE_KEY` | GitHub App private key | GitHub App settings |

## Setting Up Secrets

### Via GitHub UI

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with its name and value

### Via GitHub CLI

```bash
# Install GitHub CLI if not already installed
# brew install gh (macOS)
# or see https://cli.github.com/

# Authenticate with GitHub
gh auth login

# Set secrets
gh secret set FLY_API_TOKEN --body="$(flyctl auth token)"

# For multiline secrets (like private keys)
gh secret set PRIVATE_KEY < private-key.pem
```

## Environment Variables

### Repository Variables

These are non-sensitive configuration values that can be set as repository variables:

| Variable Name | Description | Example |
|---------------|-------------|---------|
| `PLATFORM_ADMIN_EMAILS` | Comma-separated list of admin emails | `admin@example.com,support@example.com` |

To set repository variables:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click on the **Variables** tab
3. Click **New repository variable**

## Fly.io Setup

### Get Your Fly.io API Token

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Login to Fly.io
flyctl auth login

# Get your API token
flyctl auth token
```

### Set Up Fly.io Organization

1. Create a Fly.io account at [fly.io](https://fly.io)
2. Create an organization (or use your personal organization)
3. Update the `FLY_ORG` variable in `.github/workflows/staging.yaml` to match your organization name

## Production Configuration

The production deployment workflow expects the Fly.io app to already exist. Create it with:

```bash
fly launch --name pilatesonphx --region dfw --no-deploy
```

Then configure production secrets directly on Fly.io:

```bash
fly secrets set SECRET_KEY_BASE="$(mix phx.gen.secret)"
fly secrets set DATABASE_URL="your-production-database-url"
fly secrets set PHX_HOST="pilatesonphx.fly.dev"
```

## Security Best Practices

1. **Rotate secrets regularly** - Update API tokens and keys periodically
2. **Use different secrets for different environments** - Don't share production secrets with staging
3. **Limit secret access** - Only give repository access to trusted contributors
4. **Monitor secret usage** - Review GitHub Actions logs for any suspicious activity
5. **Never commit secrets** - Always use GitHub Secrets, never hardcode values

## Troubleshooting

### "FLY_API_TOKEN is not set"
- Ensure you've added the secret to your repository
- Check that the secret name matches exactly (case-sensitive)

### "Authentication failed"
- Regenerate your Fly.io token with `flyctl auth token`
- Update the GitHub secret with the new token

### Staging deployment fails
- Check that your Fly.io organization exists and matches `FLY_ORG` in the workflow
- Ensure you have sufficient resources in your Fly.io account
- Review the workflow logs for specific error messages
