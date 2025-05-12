# Navigaite GitHub Actions Workflows

Modern, reusable GitHub Actions workflows for Next.js projects deployed on Vercel.

## Overview

This repository contains a collection of GitHub Actions workflows designed for continuous integration and deployment of Next.js projects.
Our workflows follow a modular architecture pattern that promotes maintainability, consistency, and flexibility.

## Key Features

- **Modular workflow architecture**: Compose workflows from reusable components (action-_ entrypoints, sub-_ reusable jobs)
- **Next.js optimized**: Built specifically for Next.js projects
- **Vercel deployment**: Seamless integration with Vercel deployments
- **Security scanning**: Integrated CodeQL and vulnerability scanning
- **Matrix testing**: Test across multiple Node.js versions
- **Release management**: Automated changelog and release notes

## Workflow Types

Our workflows follow a naming convention that indicates their purpose:

- **action-\***: Entry point workflows triggered by specific GitHub events (PR opened, issue assigned, etc.)
- **sub-\***: Reusable workflow components called by action workflows
- **cron-\***: Scheduled maintenance tasks that run periodically

## Workflows

### Action Workflows (Entry Points)

| Workflow                                                                         | Description                                                   |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| [action-pr-opened.yaml](.github/workflows/action-pr-opened.yaml)                 | Triggered when a PR is opened, reopened, or synchronized      |
| [action-issue-opened.yaml](.github/workflows/action-issue-opened.yaml)           | Creates a new branch when an issue is assigned                |
| [action-man-draft-release.yaml](.github/workflows/action-man-draft-release.yaml) | Prepares a new release branch and PR                          |
| [action-pr-merged-dev.yaml](.github/workflows/action-pr-merged-dev.yaml)         | Deploys to DEV environment when PR is merged                  |
| [action-pr-merged-release.yaml](.github/workflows/action-pr-merged-release.yaml) | Deploys release branch to preview environment                 |
| [action-pr-merged-prod.yaml](.github/workflows/action-pr-merged-prod.yaml)       | Deploys to production and creates release when merged to main |

### Reusable Components

| Workflow                                                                       | Description                                           |
| ------------------------------------------------------------------------------ | ----------------------------------------------------- |
| [sub-setup.yaml](.github/workflows/sub-setup.yaml)                             | **DEPRECATED** - Use setup action instead             |
| [actions/setup](.github/actions/setup/action.yaml)                             | Sets up Node.js environment and installs dependencies |
| [sub-linting.yaml](.github/workflows/sub-linting.yaml)                         | Performs code quality checks using Trunk              |
| [sub-cypress.yaml](.github/workflows/sub-cypress.yaml)                         | Runs Cypress E2E and component tests                  |
| [sub-code-review.yaml](.github/workflows/sub-code-review.yaml)                 | AI-powered code review for pull requests              |
| [sub-pr-title-validation.yaml](.github/workflows/sub-pr-title-validation.yaml) | Validates PR titles follow conventional commit format |
| [sub-trufflehog.yaml](.github/workflows/sub-trufflehog.yaml)                   | Security scanning for leaked credentials              |

### Maintenance Workflows

| Workflow                                                                 | Description                               |
| ------------------------------------------------------------------------ | ----------------------------------------- |
| [cron-cleanup-actions.yaml](.github/workflows/cron-cleanup-actions.yaml) | Cleans up old workflow runs and artifacts |
| [cron-trunk-upgrade.yaml](.github/workflows/cron-trunk-upgrade.yaml)     | Automatically updates Trunk linting tools |

## Getting Started

To use these workflows in your Next.js project:

1. **Quick Start**: Reference the action workflows in your repo:

```yaml
# .github/workflows/ci.yaml
---
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  issues:
    types: [assigned]

jobs:
  # PR validation and deployment
  pr-workflow:
    if: github.event_name == 'pull_request'
    uses: navigaite/github-organization/.github/workflows/action-pr-opened.yaml@main
    secrets: inherit

  # Issue branch creation
  issue-workflow:
    if: github.event_name == 'issues' && github.event.action == 'assigned'
    uses: navigaite/github-organization/.github/workflows/action-issue-opened.yaml@main
    secrets: inherit
```

2. **Using the Setup Action in your workflows**:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Setup Environment
        uses: navigaite/github-organization/.github/actions/setup@main

      - name: Build
        run: npm run build
```

3. **Set up required secrets in your repository**:
   - `VERCEL_TOKEN`
   - `VERCEL_PROJECT_ID` (or as a variable)
   - `VERCEL_ORG_ID` (or as a variable)
   - `WORKFLOW_APP_ID` and `WORKFLOW_APP_PRIVATE_KEY` (for GitHub App authentication)
   - `OPENAI_API_KEY` (optional, for AI code review)

See the [Pipeline Architecture](./docs/PIPELINE_ARCHITECTURE.md) for an overview of the modular structure and
[CodeQL Guide](./docs/CODEQL_GUIDE.md) for security scanning details.

## Documentation

- [Pipeline Architecture](./docs/PIPELINE_ARCHITECTURE.md) - Overview of workflow architecture
- [CodeQL Guide](./docs/CODEQL_GUIDE.md) - Details about CodeQL security scanning
- [Release Please Guide](./docs/RELEASE_PLEASE_GUIDE.md) - Guide for automated release management
- [Migration Guide](./docs/MIGRATION_GUIDE.md) - Guide for migrating from sub-setup workflow to setup action
- [Cross-Repository Usage](./docs/CROSS_REPO_USAGE.md) - Guide for using workflows and actions from other repositories

## Testing Workflows

We provide scripts to test workflows locally:

```bash
# Test a specific workflow
./scripts/test-workflows.sh --workflow action-pr-opened.yaml --event pull_request

# Simulate the entire pipeline
./scripts/simulate-pipeline.sh --workflow pipeline
```

## Compatibility

- **Node.js**: 18.x, 20.x, and 22.x (default: 20.x)
- **Next.js**: 12.x and later
- **GitHub Actions**: Latest runners
- **Vercel**: Latest API
