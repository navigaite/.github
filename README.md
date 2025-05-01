# Navigaite CI/CD Workflows

This repository contains reusable GitHub Actions workflows for Navigaite's CI/CD pipeline. These workflows provide standardized processes for linting, testing, building, and deploying NextJS applications to Vercel.

## Features

- Automated CI/CD pipeline for NextJS projects
- Integration with Vercel for seamless deployments
- Security scanning for secrets with TruffleHog
- AI-powered code quality checks with Trunk
- Automated draft releases with Release Drafter
- Standardized commit messages with Open Commits and Commitlint
- Automated changelog generation and release management
- Full GitFlow support for branch management

## How to Use These Workflows

### 1. Create a workflow file in your project

In your project repository, create a file at `.github/workflows/ci-cd.yml` with the following content:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [develop, main, "feature/**", "hotfix/**", "release/**"]
  pull_request:
    branches: [develop, main]
  workflow_dispatch:

jobs:
  call-navigaite-workflow:
    uses: navigaite/workflow-test/.github/workflows/nextjs-pipeline.yml@main
    with:
      # Configure your project specifics here
      node-version: "18" # or your desired Node.js version
      vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

### 2. Set up required secrets in your repository

- `VERCEL_TOKEN`: Your Vercel deployment token
- `VERCEL_PROJECT_ID`: Your Vercel project ID

### 3. Install recommended dev dependencies

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

### 4. Add configuration files to your project (optional)

Copy the configuration files from the `config/` directory of this repository to your project root.

## Workflows Available

- `nextjs-pipeline.yml` - Complete CI/CD pipeline for NextJS projects
- `lint.yml` - Standalone linting workflow using Trunk Check
- `release.yml` - Automated release workflow for GitFlow
- `security-scan.yml` - Secret detection using TruffleHog
- `release-drafter.yml` - Automatically drafts new releases based on merged PRs

## Branch Model

This pipeline supports the GitFlow branching model:

- `feature/*` branches for new features
- `develop` branch for integration
- `release/*` branches for release preparation
- `main` branch for production code
- `hotfix/*` branches for urgent fixes

## License

[MIT](LICENSE)
