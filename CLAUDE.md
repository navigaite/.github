# Navigaite Universal CI/CD Pipeline

> Organization-wide reusable GitHub Actions pipeline (`navigaite/.github`), currently at **v2** (version 2.1.2).

## What This Repo Is

This is **not an application** -- it's a shared CI/CD infrastructure repo. It provides:

- A **reusable workflow** (`universal-pipeline.yaml`) that any repo in the `navigaite` org calls
- **14 composite actions** for security, lint, test, build, deploy, and release
- **Auto-detection** of tech stacks (Node.js, Python, Flutter)
- **Multi-provider deployment** (Vercel, DigitalOcean, Docker/GHCR, Coolify, Render)
- **Release automation** via release-please or semantic-release

Consuming repos integrate by adding a thin workflow caller + a `.github/pipeline.yaml` config file. See `docs/GETTING_STARTED.md` and `docs/CONFIGURATION.md` for the full consumer setup guide.

## Repo Structure

```
.github/
  workflows/
    universal-pipeline.yaml    # Core reusable workflow (consumers call this)
    release.yaml               # This repo's own release process
    create-release-pr.yaml     # Reusable: generate release PRs with changelog
    build-executables.yaml     # Reusable: PyInstaller cross-platform builds
    nightly-maintenance.yaml   # Scheduled: cache cleanup, security audits, dep checks
    test-actions.yaml          # CI: validates the composite actions themselves
  actions/
    setup-environment/         # Stack auto-detection + runtime setup
    install-dependencies/      # Multi-stack dependency installation
    run-lint/                  # Auto-detected linting (eslint, ruff, dartfmt, etc.)
    run-tests/                 # Auto-detected test runner (jest, pytest, flutter test)
    run-build/                 # Build + optional SLSA attestation
    security-scan/             # TruffleHog + dependency review
    release-management/        # release-please or semantic-release
    sync-branches/             # Auto-sync main -> dev after release
    deploy-vercel/
    deploy-digitalocean/
    deploy-docker/
    deploy-coolify/
    deploy-render/
    build-executable/          # PyInstaller single-platform build
  config/
    examples/                  # Example pipeline.yaml files for consumers
docs/                          # Human-readable guides
```

## Pipeline Flow

```
Setup (stack detect + config parse)
  -> Security (TruffleHog, dependency review)
  -> Lint + Test (parallel)
    -> Build (+ SLSA attestation)
      -> Deploy (Vercel | DigitalOcean | Docker | Coolify | Render)
        -> Release (release-please | semantic-release)
          -> Sync to dev (auto-merge version bumps back)
```

Each stage is independently toggleable via the consumer's `.github/pipeline.yaml` config.

## Development Conventions

### Commits

Use **conventional commits** -- this repo uses release-please with commitlint enforced:

- `feat:` -- new feature (minor bump)
- `fix:` -- bug fix (patch bump)
- `feat!:` or footer `BREAKING CHANGE:` -- major bump
- `chore:`, `ci:`, `docs:`, `test:`, `refactor:`, `perf:` -- no version bump (hidden in changelog unless `docs`/`refactor`/`perf`)

### Versioning

- release-please manages versions via `.release-please-manifest.json` and `.github/release-please-config.json`
- The `release.yaml` workflow updates rolling `v{MAJOR}` and `latest` tags so consumers pinned to `@v2` get patches automatically
- **Never manually edit version numbers** -- release-please handles it

### Branching

- `main` is the release branch
- Feature/fix branches are merged to `main` via PR
- After release, version changes auto-sync to `dev` (if it exists in the consuming repo)

## Key Design Decisions

1. **All third-party actions are SHA-pinned** -- never use `@v4` style tags for external actions. Always pin to exact commit SHA with a version comment.

2. **Path traversal protection** -- all actions validate `working-directory` inputs to prevent `../` attacks. The `test-actions.yaml` workflow specifically tests this.

3. **Stack auto-detection order**: `package.json` -> Node.js, `requirements.txt`/`pyproject.toml`/`setup.py`/`Pipfile` -> Python, `pubspec.yaml` -> Flutter.

4. **Environment filtering** -- the setup job filters deployment environments by matching the current GitHub event + branch against each environment's trigger config. Only matching environments proceed to deploy jobs.

5. **Infisical integration** -- secrets can be injected at build time via Infisical. This is optional and configured per-consumer.

## How Consumers Use This

### Minimal caller workflow (`.github/workflows/ci.yaml`):

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

# Caller permissions cap reusable workflow job permissions.
# Include all permissions needed by enabled pipeline stages.
permissions:
  contents: write          # releases, tag updates
  pull-requests: write     # PR comments (deploy URLs, release PRs)
  id-token: write          # OIDC for cloud providers + SLSA attestation
  deployments: write       # deployment status updates
  packages: write          # Docker/GHCR image push
  attestations: write      # SLSA build provenance
  security-events: write   # security scan SARIF uploads

jobs:
  pipeline:
    uses: navigaite/.github/.github/workflows/universal-pipeline.yaml@v2
    with:
      config-file: .github/pipeline.yaml
    secrets: inherit
```

### Minimal pipeline config (`.github/pipeline.yaml`):

```yaml
version: '2.0'

deployment:
  provider: vercel
  environments:
    - name: production
      trigger:
        event: push
        branch: main

release:
  enable: true
  type: node
```

The pipeline auto-detects everything else (stack, runtime version, lint/test/build commands).

## Testing Changes

Run `test-actions.yaml` to validate action changes. It tests:
- actionlint on all workflow definitions
- Invalid stack rejection for each action
- Path traversal prevention

When modifying an action, test it against a real consumer repo before merging.

## Common Tasks

### Adding a new deployment provider

1. Create `.github/actions/deploy-{provider}/action.yaml`
2. Add the deploy job to `universal-pipeline.yaml` (follow existing `deploy-vercel` pattern)
3. Add provider to the setup job's environment filtering logic
4. Add an example config in `.github/config/examples/`
5. Document in `docs/CONFIGURATION.md`

### Modifying pipeline stages

Edit `universal-pipeline.yaml`. Each stage is a separate job with conditional execution based on the setup job's outputs. The `needs` graph enforces ordering.

### Updating a pinned action version

Find the SHA-pinned `uses:` line, update both the SHA and the version comment. Verify the SHA matches the tagged release on the action's repo.
