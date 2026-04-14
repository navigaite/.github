# Navigaite Universal CI/CD Pipeline

> Organization-wide reusable GitHub Actions pipeline (`navigaite/.github`), currently at **v2** (version 2.3.2). <!-- x-release-please-version -->

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
    claude-code.yaml           # Reusable: Claude Code AI for PR reviews + @claude mentions
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

### Branching & Release Strategy

The `navigaite` org enforces a consistent branching strategy via org-level GitHub rulesets. Two profiles exist:

**Profile A — Small repos** (feature → main):

- `main` is the only long-lived branch, and the default branch
- Feature branches squash-merge to `main` via PR
- Release-please produces stable versions (`v1.0.0`, `v1.1.0`)
- No `dev` branch, no prerelease versions

**Profile B — Large repos** (feature → dev → main):

- `dev` is the integration branch and the **default branch** (PRs target `dev` by default)
- `main` is the production branch
- Feature branches squash-merge to `dev` via PR
- Release-please on `dev` produces beta versions (`v0.4.0-beta.1`)
- Promotion: merge-commit PR from `dev → main` (preserves conventional commit history)
- Release-please on `main` produces stable versions (`v1.0.0`)
- Pipeline auto-syncs `main` back to `dev` after promotion (`sync_to_dev: true`)
- A CI branch guard job prevents feature PRs from targeting `main`

**Merge methods:**

- Feature PRs: squash (enforced via repo-level rulesets for large repos)
- Release-please PRs: squash
- dev → main promotions: merge commit (enforced via repo-level ruleset on `main`)

**Promotion preconditions (large repos):**

1. No open release-please PR on `dev`
2. All CI checks pass
3. Merge commit method (enforced by ruleset)

**Pipeline config for large repos with prerelease:**

```yaml
release:
  enable: true
  strategy: release-please
  config_file: release-please-config.json            # prerelease for dev
  config_file_stable: release-please-config.main.json # stable for main
  manifest_file: .release-please-manifest.json
  sync_to_dev: true
  prerelease_branches:
    - branch: dev
      label: beta
```

### Org-Level GitHub Rulesets

Two org rulesets apply to ALL `navigaite` repos:

**"Protected branches"** — targets `main` (default branch) + `dev`:

- PR required: 1 approval, dismiss stale reviews, resolve conversations
- Merge methods: squash + merge (repo-level rulesets narrow per branch)
- Required status checks (ruleset contexts): `Check Gate`, `Branch Guard` — matched by GitHub against the job `name:` field; the PR UI displays them as `Navigaite Pipeline / Check Gate` and `Navigaite Pipeline / Branch Guard`
- Signed commits, no force push, no deletion
- Copilot code review: auto-review on push
- Bypass: org admins + `navigaite-workflow-app` bot

**"Tag protection"** — targets `v*` tags:

- No deletion, no force push, restrict creation
- Bypass: org admins + `navigaite-workflow-app` bot

### Repo-Level Rulesets (Large Repos Only)

Large repos add overlay rulesets that restrict merge methods per branch:

- **"dev: squash only"** — forces squash on `dev`
- **"main: merge only (promotions)"** — forces merge commits on `main`

### Default Branch

- **Large repos** (with `dev`): default = `dev` — PRs naturally target where feature work belongs
- **Small repos** (no `dev`): default = `main`

The org ruleset explicitly targets `~DEFAULT_BRANCH`, `refs/heads/main`, and `refs/heads/dev` so both branches are
protected regardless of which is the default.

### Repo Settings (All Repos)

- Default branch: `dev` (large) or `main` (small)
- Squash merge: enabled (title = PR title, body = PR body)
- Merge commit: enabled
- Rebase: disabled
- Delete branch on merge: yes
- Auto-merge: yes

## Key Design Decisions

1. **All third-party actions are SHA-pinned** -- never use `@v4` style tags for external actions. Always pin to exact commit SHA with a version comment.

2. **Path traversal protection** -- all actions validate `working-directory` inputs to prevent `../` attacks. The `test-actions.yaml` workflow specifically tests this.

3. **Stack auto-detection order**: `package.json` -> Node.js, `requirements.txt`/`pyproject.toml`/`setup.py`/`Pipfile` -> Python, `pubspec.yaml` -> Flutter.

4. **Environment filtering** -- the setup job filters deployment environments by matching the current GitHub event + branch against each environment's trigger config. Only matching environments proceed to deploy jobs.

5. **Infisical integration** -- secrets can be injected at build time via Infisical. This is optional and configured per-consumer.

6. **GitHub App for workflow triggers** -- `GITHUB_TOKEN` merges don't trigger subsequent workflow runs (GitHub's anti-loop protection). This repo uses a GitHub App (`WORKFLOW_APP_ID` + `WORKFLOW_APP_PRIVATE_KEY` org secrets) via `actions/create-github-app-token` to generate tokens for release-please and auto-merge, so merging a release PR triggers the release publish workflow.

## Setting Up the Pipeline in a Consumer Repo

### Step 1: Create the caller workflow

Create `.github/workflows/ci.yaml`. The workflow name **must** be `Navigaite Pipeline` (exact match required by org ruleset). The calling job **must** use the key `pipeline` with no explicit `name:` field. Every workflow must include `Branch Guard` and `Check Gate` jobs:

```yaml
name: Navigaite Pipeline

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
  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - run: echo "✅ Single-branch repo — all PRs target main directly"

  pipeline:
    uses: navigaite/.github/.github/workflows/universal-pipeline.yaml@v2
    with:
      config-file: .github/pipeline.yaml
    secrets: inherit

  check-gate:
    name: Check Gate
    if: always()
    needs: [pipeline]
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Evaluate pipeline result
        shell: bash
        env:
          RESULTS: ${{ toJSON(needs.*.result) }}
        run: |
          set -euo pipefail
          command -v jq >/dev/null || { echo "::error::jq not available"; exit 1; }
          echo "Job results: $RESULTS"
          FAILURES=$(echo "$RESULTS" | jq -r 'map(select(. == "failure" or . == "cancelled")) | length')
          if [[ "$FAILURES" -gt 0 ]]; then
            echo "::error::Pipeline failed — ${FAILURES} job(s) failed or were cancelled"
            exit 1
          fi
          echo "✅ All pipeline jobs passed"
```

**Important:**
- The workflow name `Navigaite Pipeline` is required — the org ruleset matches the bare job names `Check Gate` and `Branch Guard` (not the full `Navigaite Pipeline / ...` path shown in the PR UI). See `AGENTS.md` for the full naming convention.
- Pin to `@v2` (rolling tag, gets patches automatically). Use `@main` only for testing unreleased changes.
- `secrets: inherit` passes all repo/org secrets to the pipeline.
- The `permissions` block is required for releases, PR comments, and OIDC-based deployments.
- For large repos (dev + main), use the full branch guard implementation — see edilio's `ci.yaml` for reference.

### Step 2: Create the pipeline config

Create `.github/pipeline.yaml`. This controls what the pipeline does:

```yaml
version: '2.0'

# Stack is auto-detected from project files. Override if needed:
# stack: nodejs
# runtime:
#   node_version: '22'

# Customize commands only if auto-detection doesn't work:
# lint:
#   command: 'trunk check --ci --no-fix'
# test:
#   command: 'pnpm turbo run test'
# build:
#   command: 'pnpm turbo run build'

deployment:
  provider: vercel  # or: digitalocean, docker, none
  environments:
    - name: preview
      trigger:
        event: pull_request
    - name: staging
      trigger:
        event: push
        branch: dev
    - name: production
      trigger:
        event: push
        branch: main

release:
  enable: true
  type: node  # or: python, simple
```

### Step 3: Add secrets

Based on your deployment provider, add secrets to the repo (Settings > Secrets > Actions):

- **Vercel:** `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
- **DigitalOcean:** `DIGITALOCEAN_TOKEN`
- **Docker/GHCR:** uses `GITHUB_TOKEN` by default, or `DOCKER_REGISTRY_USERNAME` + `DOCKER_REGISTRY_PASSWORD`
- **Workflow automation (this repo only):** `WORKFLOW_APP_ID` + `WORKFLOW_APP_PRIVATE_KEY` (org-level GitHub App) -- **not needed for consumer repos**. Only used by this repo's `release.yaml` to auto-merge release PRs and trigger follow-up workflows. Falls back to `GITHUB_TOKEN` if not configured.

### Adding custom jobs alongside the pipeline

If the pipeline's built-in deploy doesn't fit (e.g. Render webhooks, Coolify, custom deploy logic), set `deployment.provider: none` and add your own jobs that depend on `pipeline`:

```yaml
jobs:
  pipeline:
    uses: navigaite/.github/.github/workflows/universal-pipeline.yaml@v2
    with:
      config-file: .github/pipeline.yaml
    secrets: inherit

  deploy-production:
    name: Deploy Production
    needs: [pipeline]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: curl -sf "${{ secrets.DEPLOY_HOOK }}"
```

### Naming conventions

- **Workflow file:** `.github/workflows/ci.yaml`
- **Workflow name:** `Navigaite Pipeline`
- **Config file:** `.github/pipeline.yaml`
- **Commit style:** conventional commits (`feat:`, `fix:`, `chore:`, etc.)
- **Branch strategy:** `main` (production) + `dev` (staging) + feature branches

See `docs/CONFIGURATION.md` for the full config reference and `docs/GETTING_STARTED.md` for a 5-minute quickstart.

## Known Limitations

- **Skipped deploy jobs show `${{ matrix.environment }}`** in the GitHub Actions sidebar. This is a GitHub Actions UI limitation: when a matrix job is skipped (e.g. deploy-vercel when provider is `none`), the matrix expression is never resolved so GitHub shows it raw. There's no fix short of splitting each deploy provider into its own reusable workflow. It's cosmetic only -- the jobs are properly skipped and don't affect the pipeline result.

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
