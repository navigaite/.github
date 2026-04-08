# Universal CI/CD Pipeline v2

**A modern, configuration-driven GitHub Actions pipeline that works with any tech stack and deployment target.**

## Overview

The Universal CI/CD Pipeline v2 is a reusable workflow system designed to be:

- **Technology Agnostic**: Auto-detects and supports Node.js, Python, Flutter, and more
- **Deployment Flexible**: Deploy to Vercel, DigitalOcean, Docker registries, Coolify, or anywhere
- **Configuration-Driven**: Simple YAML configuration file controls everything
- **Secure by Default**: Built-in secret scanning, dependency checks, and shell injection prevention
- **Release Automation**: Automatic semantic versioning and changelog generation
- **Fast & Efficient**: Smart caching, parallel execution, and optimized workflows

## Quick Start

### 1. Create a Workflow File

Create `.github/workflows/ci.yaml` in your project:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]
  merge_group: {}

permissions:
  contents: write
  pull-requests: write
  deployments: write
  packages: write
  id-token: write
  attestations: write
  security-events: write

jobs:
  pipeline:
    uses: navigaite/github-organization/.github/workflows/universal-pipeline.yaml@v2
    with:
      config-file: .github/pipeline.yaml
    secrets:
      VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
      VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
      VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

### 2. Create a Configuration File

Create `.github/pipeline.yaml` in your project:

```yaml
version: "2.0"

deployment:
  provider: vercel
  environments:
    - name: preview
      trigger:
        event: pull_request
    - name: production
      trigger:
        event: push
        branch: main

release:
  enable: true
  type: node
```

### 3. Configure Secrets

Add required secrets to your repository depending on your deployment provider:

| Provider | Secrets |
|----------|---------|
| **Vercel** | `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` |
| **DigitalOcean** | `DIGITALOCEAN_TOKEN` |
| **Docker** | `DOCKER_REGISTRY_PASSWORD` (or use `GITHUB_TOKEN` for GHCR) |
| **Coolify** | `COOLIFY_TOKEN` |

### 4. Push and Deploy

The pipeline will automatically:

1. Auto-detect your tech stack and package manager
2. Run security scans (TruffleHog, dependency review)
3. Lint your code (Trunk or custom)
4. Run tests with coverage
5. Build your project
6. Deploy to your environments
7. Create releases via release-please
8. Sync version changes back to dev

## Pipeline Architecture

```
Push / PR
    |
    v
 [Setup] ── auto-detect stack, parse config
    |
    ├──> [Security] ── TruffleHog + dependency review
    ├──> [Lint] ── Trunk / custom + React Doctor
    └──> [Test] ── stack-specific tests + coverage
            |
            v
         [Build] ── compile + SLSA attestation
            |
            ├──> [Deploy Vercel]
            ├──> [Deploy DigitalOcean]
            ├──> [Deploy Docker] (multi-image, multi-arch)
            └──> [Release] ── release-please / semantic-release
                    |
                    v
              [Sync to Dev] ── auto-merge version changes
```

## Supported Tech Stacks

| Stack | Package Managers | Auto-Detection |
|-------|-----------------|----------------|
| **Node.js** | npm, pnpm, yarn | `package.json` |
| **Python** | pip, poetry, pipenv | `requirements.txt`, `pyproject.toml` |
| **Flutter** | pub, FVM | `pubspec.yaml` |

## Deployment Providers

| Provider | Preview | Staging | Production | PR Previews |
|----------|---------|---------|------------|-------------|
| **Vercel** | Yes | Yes | Yes | Yes |
| **DigitalOcean** | Yes | Yes | Yes | Yes |
| **Docker** | - | - | Yes | - |
| **Coolify** | - | - | Yes | - |

Docker supports multi-platform builds (amd64/arm64) and multiple registries (GHCR, Docker Hub, GCR, ECR).

## Release Management

### For Consuming Repos

Releases are managed by [release-please](https://github.com/googleapis/release-please) based on conventional commits:

| Commit Type | Version Bump | Example |
|-------------|-------------|---------|
| `fix:` | Patch (1.0.0 → 1.0.1) | `fix: resolve login timeout` |
| `feat:` | Minor (1.0.0 → 1.1.0) | `feat: add dark mode` |
| `feat!:` / `BREAKING CHANGE:` | Major (1.0.0 → 2.0.0) | `feat!: redesign API` |

Configure in your `.github/pipeline.yaml`:

```yaml
release:
  enable: true
  strategy: release-please  # or semantic-release
  type: node                # or python, simple
  sync_to_dev: true         # sync version changes back to dev
  prerelease_branches:
    - branch: next
      label: beta
```

### For This Repo

This repo uses release-please with semantic versioning. On merge to `main`:

1. Release-please analyzes commits and creates/updates a release PR
2. Merging the release PR creates a GitHub release with changelog
3. The major version tag (`v2`) is automatically updated to point to the latest `v2.x.x`

**Consumers pinned to `@v2` always get the latest patch automatically.**

## Configuration Reference

### Pipeline Config (`.github/pipeline.yaml`)

```yaml
version: "2.0"

# Override auto-detection
stack: nodejs
runtime:
  node_version: "20"

# Toggle pipeline stages
security:
  enable: true
  fail_on_secrets: true
lint:
  enable: true
test:
  enable: true
  coverage: true
build:
  enable: true

# Deployment
deployment:
  provider: vercel  # vercel | digitalocean | docker
  environments:
    - name: preview
      trigger:
        event: pull_request
    - name: production
      trigger:
        event: push
        branch: main

# Docker-specific (multi-image support)
  docker:
    images:
      - name: api
        dockerfile: Dockerfile.api
        platforms: linux/amd64,linux/arm64
      - name: worker
        dockerfile: Dockerfile.worker

# Release
release:
  enable: true
  strategy: release-please
  type: node
  sync_to_dev: true
  sync_target_branch: dev
```

### Examples

See [`.github/config/examples/`](.github/config/examples/) for complete configurations:

- [Next.js + Vercel](.github/config/examples/nextjs-vercel-pipeline.yaml)
- [Python + DigitalOcean](.github/config/examples/python-digitalocean-pipeline.yaml)
- [Flutter](.github/config/examples/flutter-pipeline.yaml)
- [Docker Only](.github/config/examples/docker-only-pipeline.yaml)

## Security

- **TruffleHog** scans for leaked secrets and credentials
- **Dependency Review** checks for vulnerable dependencies in PRs
- **Shell injection prevention** — all composite actions use `env:` blocks (semgrep compliant)
- **Pinned action versions** — all third-party actions pinned to SHA
- **Least-privilege permissions** — each job declares only the permissions it needs
- **Nightly maintenance** — automated security audits, workflow linting, dependency checks

## Reusable Actions

This repo provides 12 composite actions in [`.github/actions/`](.github/actions/):

| Action | Purpose |
|--------|---------|
| `setup-environment` | Stack detection + runtime caching |
| `install-dependencies` | npm/pip/pub installation |
| `run-lint` | Multi-language linting |
| `run-tests` | Test execution with coverage |
| `run-build` | Build compilation + SLSA attestations |
| `security-scan` | TruffleHog + dependency review |
| `deploy-vercel` | Vercel deployment |
| `deploy-digitalocean` | DigitalOcean App Platform |
| `deploy-docker` | Docker build + registry push |
| `deploy-coolify` | Coolify webhook deployment |
| `build-executable` | PyInstaller cross-platform builds |
| `release-management` | Release-please / semantic-release |
| `sync-branches` | Post-release branch synchronization |

## Nightly Maintenance

A scheduled workflow runs daily at 2 AM UTC:

- Cleans up workflow runs older than 30 days
- Removes caches older than 7 days
- Runs Trivy security audit with SARIF upload
- Checks for outdated dependencies
- Lints all workflow definitions with actionlint

See [`.github/workflows/nightly-maintenance.yaml`](.github/workflows/nightly-maintenance.yaml).

## Documentation

- [Getting Started](./docs/GETTING_STARTED.md)
- [Configuration Reference](./docs/CONFIGURATION.md)
- [Branching Strategy](./docs/BRANCHING_STRATEGY.md)
- [Versioning Guide](./docs/VERSIONING_GUIDE.md)
- [GitHub Actions Marketplace](./docs/GITHUB_ACTIONS_MARKETPLACE.md)
- [Auto Sync Feature](./docs/AUTO_SYNC_FEATURE.md)
- [GitHub Settings Guide](./docs/GITHUB_SETTINGS_GUIDE.md)

## Contributing

1. Create a feature branch from `main`
2. Make changes following [conventional commits](https://www.conventionalcommits.org/)
3. Open a PR — the test-actions workflow validates all actions and workflows
4. Merge to `main` — release-please handles versioning

## License

MIT License - see LICENSE file for details.

---

**Made with care by [Navigaite](https://navigaite.com)**
