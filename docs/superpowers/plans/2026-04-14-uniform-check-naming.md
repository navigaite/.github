# Uniform CI Check Naming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize CI status check names across all Navigaite repos so the org ruleset enforces exactly 2 checks: `Navigaite Pipeline / Check Gate` and `Branch Guard`.

**Architecture:** Replace individual Lint/Test/Build required checks with a single `Check Gate` aggregator job in the universal pipeline. Update the org ruleset. Migrate all repos to use `name: Navigaite Pipeline` as their caller workflow name. Legacy repos get a full migration to the universal pipeline.

**Tech Stack:** GitHub Actions, GitHub org rulesets (via `gh api`)

---

## Naming Convention

| Layer | Name | Notes |
|-------|------|-------|
| Caller workflow `name:` | `Navigaite Pipeline` | All consumer repos must use this exact name |
| Calling job key | `pipeline` | No explicit `name:` — inherits the key as display name |
| Gate job `name:` | `Check Gate` | Aggregator — the only pipeline-level required check |
| Branch guard job `name:` | `Branch Guard` | Standalone job, separate required check |
| Reusable workflow internal jobs | `🧹 Lint`, `🧪 Test`, `🏗️ Build`, etc. | Not in required checks — emoji OK |

**Resulting GitHub check names:**
- `Navigaite Pipeline / Check Gate` (required)
- `Navigaite Pipeline / Branch Guard` (required)
- `Navigaite Pipeline / 🧹 Lint` (informational)
- `Navigaite Pipeline / 🧪 Test` (informational)
- `Navigaite Pipeline / 🏗️ Build` (informational)

For repos with additional caller jobs (e.g., edilio's `generate-token`, `sentry-release`, deploy jobs), those appear as `Navigaite Pipeline / <job name>` — not required.

## File Map

### Task 1: Add Check Gate to universal pipeline
- Modify: `~/projects/Navigaite/internal/nvgt-github/.github/workflows/universal-pipeline.yaml` (add `check-gate` job at end)

### Task 2: Fix `.github` repo self-CI
- Modify: `~/projects/Navigaite/internal/nvgt-github/.github/workflows/ci.yaml` (rename workflow, simplify job names, add Check Gate)

### Task 3: Update org ruleset
- API call: `gh api --method PUT orgs/navigaite/rulesets/13405188`

### Task 4: Migrate `nvgt-trunk-plugin`
- Modify: `~/projects/Navigaite/internal/nvgt-trunk-plugin/.github/workflows/ci.yaml`

### Task 5: Migrate `edilio`
- Modify: `~/projects/Navigaite/customers/edilio/.github/workflows/ci.yaml`

### Task 6: Migrate `maimaldrei-mietkatalog`
- Replace: `~/projects/Navigaite/customers/maimaldrei/maimaldrei-mietkatalog/.github/workflows/ci-pull-request.yaml` and `ci-release.yaml` with single `ci.yaml`

### Task 7: Migrate legacy repos (maimaldrei-website, maimaldrei-dispoplaner, nvgt-website)
- Replace: all `action-*.yaml` workflows with single `ci.yaml` + `pipeline.yaml`

### Task 8: Migrate remaining repos (nvgt-repo-template, abonate-webapp, eslint-config)
- Replace: legacy workflows with `ci.yaml` + `pipeline.yaml`

### Task 9: Handle no-workflow repos
- Create: `ci.yaml` + `pipeline.yaml` for repos that currently have no CI

### Task 10: Document in AGENTS.md
- Create: `~/projects/Navigaite/internal/nvgt-github/AGENTS.md`

### Task 11: Update CLAUDE.md
- Modify: `~/projects/Navigaite/internal/nvgt-github/CLAUDE.md` (update naming convention docs)

---

## Task 1: Add Check Gate to Universal Pipeline

**Files:**
- Modify: `.github/workflows/universal-pipeline.yaml` (in `~/projects/Navigaite/internal/nvgt-github/`)

The Check Gate job runs after all pipeline stages and reports a single pass/fail. It uses `if: always()` so it runs even when upstream jobs fail or are skipped.

- [ ] **Step 1: Add Check Gate job at end of universal-pipeline.yaml**

Add after the `pipeline-summary` job (last job in the file). The job depends on ALL stage jobs:

```yaml
  # =============================================================================
  # CHECK GATE — single aggregator for org ruleset required status checks
  # =============================================================================
  check-gate:
    name: Check Gate
    if: always()
    needs: [setup, security, lint, test, build, deploy-vercel, deploy-digitalocean, deploy-docker, release, sync-to-dev]
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
          # Fail if any required job failed (skipped is OK — means the stage was disabled)
          FAILURES=$(echo "$RESULTS" | jq -r 'map(select(. == "failure" or . == "cancelled")) | length')
          if [[ "$FAILURES" -gt 0 ]]; then
            echo "::error::Pipeline failed — ${FAILURES} job(s) failed or were cancelled"
            exit 1
          fi
          echo "✅ All pipeline jobs passed or were skipped"
```

- [ ] **Step 2: Verify actionlint passes**

Run: `cd ~/projects/Navigaite/internal/nvgt-github && actionlint .github/workflows/universal-pipeline.yaml`
Expected: No errors (warnings about `${{ }}` in `run:` are OK)

- [ ] **Step 3: Commit**

```bash
cd ~/projects/Navigaite/internal/nvgt-github
git add .github/workflows/universal-pipeline.yaml
git commit -m "feat: add Check Gate aggregator job to universal pipeline

Adds a single gate job that aggregates all pipeline stage results.
This replaces individual Lint/Test/Build required checks in the org
ruleset with a single 'Check Gate' check, making the pipeline more
resilient to stage additions/removals."
```

---

## Task 2: Fix `.github` Repo Self-CI

**Files:**
- Modify: `.github/workflows/ci.yaml` (in `~/projects/Navigaite/internal/nvgt-github/`)

This repo is standalone (doesn't call the reusable workflow). It needs to:
1. Rename workflow to `Navigaite Pipeline`
2. Simplify job names (remove redundant prefix)
3. Add its own Check Gate job
4. Keep Branch Guard

- [ ] **Step 1: Rewrite ci.yaml**

Replace the entire file with:

```yaml
---
name: Navigaite Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch: {}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

permissions: {}

jobs:
  # ---------------------------------------------------------------------------
  # Branch guard — this repo has no dev branch, so all PRs to main are allowed.
  # The job exists to satisfy the org ruleset's required "Branch Guard" check.
  # ---------------------------------------------------------------------------
  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Check PR target
        run: echo "✅ PR targets main — allowed (no dev branch in this repo)"

  # ---------------------------------------------------------------------------
  # Lint — validate all workflow and action definitions with actionlint
  # ---------------------------------------------------------------------------
  lint:
    name: 🧹 Lint
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      - name: Install actionlint
        shell: bash
        run: |
          set -euo pipefail
          ACTIONLINT_VERSION="1.7.7"
          curl -fsSL -o /tmp/actionlint.tar.gz \
            "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz"
          tar xzf /tmp/actionlint.tar.gz -C /tmp
          sudo mv /tmp/actionlint /usr/local/bin/
      - name: Run actionlint
        shell: bash
        run: |
          set -euo pipefail
          actionlint -shellcheck="" -color

  # ---------------------------------------------------------------------------
  # Test — validate composite actions reject invalid inputs and block traversal
  # ---------------------------------------------------------------------------
  test:
    name: 🧪 Test
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - name: Test install-dependencies rejects invalid stack
        id: test-install
        continue-on-error: true
        uses: ./.github/actions/install-dependencies
        with:
          stack: invalid
          package-manager: npm
      - name: Assert install-dependencies failure
        shell: bash
        env:
          OUTCOME: ${{ steps.test-install.outcome }}
        run: |
          set -euo pipefail
          if [[ "$OUTCOME" != "failure" ]]; then
            echo "::error::Expected install-dependencies to fail with invalid input but got: $OUTCOME"
            exit 1
          fi
          echo "✅ install-dependencies correctly rejected invalid input"

      - name: Test run-lint rejects invalid stack
        id: test-lint
        continue-on-error: true
        uses: ./.github/actions/run-lint
        with:
          stack: invalid
      - name: Assert run-lint failure
        shell: bash
        env:
          OUTCOME: ${{ steps.test-lint.outcome }}
        run: |
          set -euo pipefail
          if [[ "$OUTCOME" != "failure" ]]; then
            echo "::error::Expected run-lint to fail with invalid input but got: $OUTCOME"
            exit 1
          fi
          echo "✅ run-lint correctly rejected invalid input"

      - name: Test run-build rejects invalid stack
        id: test-build
        continue-on-error: true
        uses: ./.github/actions/run-build
        with:
          stack: invalid
      - name: Assert run-build failure
        shell: bash
        env:
          OUTCOME: ${{ steps.test-build.outcome }}
        run: |
          set -euo pipefail
          if [[ "$OUTCOME" != "failure" ]]; then
            echo "::error::Expected run-build to fail with invalid input but got: $OUTCOME"
            exit 1
          fi
          echo "✅ run-build correctly rejected invalid input"

      - name: Test run-tests rejects invalid stack
        id: test-tests
        continue-on-error: true
        uses: ./.github/actions/run-tests
        with:
          stack: invalid
      - name: Assert run-tests failure
        shell: bash
        env:
          OUTCOME: ${{ steps.test-tests.outcome }}
        run: |
          set -euo pipefail
          if [[ "$OUTCOME" != "failure" ]]; then
            echo "::error::Expected run-tests to fail with invalid input but got: $OUTCOME"
            exit 1
          fi
          echo "✅ run-tests correctly rejected invalid input"

      - name: Test path traversal is rejected
        id: test-traversal
        continue-on-error: true
        uses: ./.github/actions/run-build
        with:
          stack: nodejs
          working-directory: "../../etc"
      - name: Assert path traversal failure
        shell: bash
        env:
          OUTCOME: ${{ steps.test-traversal.outcome }}
        run: |
          set -euo pipefail
          if [[ "$OUTCOME" != "failure" ]]; then
            echo "::error::Expected path traversal to be rejected"
            exit 1
          fi
          echo "✅ Path traversal correctly rejected"

  # ---------------------------------------------------------------------------
  # Build — no application to build; pass-through to satisfy pipeline stages
  # ---------------------------------------------------------------------------
  build:
    name: 🏗️ Build
    needs: [lint, test]
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - run: echo "✅ No application build — this repo contains only GitHub Actions"

  # ---------------------------------------------------------------------------
  # Check Gate — aggregator for org ruleset required status check
  # ---------------------------------------------------------------------------
  check-gate:
    name: Check Gate
    if: always()
    needs: [lint, test, build]
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

  # ---------------------------------------------------------------------------
  # Auto-merge — enable auto-merge for dependabot PRs
  # ---------------------------------------------------------------------------
  auto-merge:
    name: 🤖 Auto-merge
    if: github.event_name == 'pull_request' && github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Enable auto-merge
        env:
          GH_TOKEN: ${{ github.token }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
        run: |
          if ! gh pr merge "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --squash --auto; then
            echo "::warning::Failed to enable auto-merge for PR #$PR_NUMBER; continuing because this is best-effort automation."
          fi
```

- [ ] **Step 2: Verify actionlint passes**

Run: `cd ~/projects/Navigaite/internal/nvgt-github && actionlint .github/workflows/ci.yaml`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yaml
git commit -m "fix: standardize CI check naming for org ruleset compliance

Rename workflow to 'Navigaite Pipeline', simplify job names, and add
Check Gate aggregator. Produces check names that match the org ruleset:
- 'Navigaite Pipeline / Check Gate' (required)
- 'Navigaite Pipeline / Branch Guard' (required)"
```

---

## Task 3: Update Org Ruleset

**No files — API call only.**

Update the org ruleset to require only `Check Gate` and `Branch Guard` instead of individual Lint/Test/Build checks.

- [ ] **Step 1: Read current ruleset for reference**

```bash
gh api orgs/navigaite/rulesets/13405188 --jq '.rules[] | select(.type == "required_status_checks")'
```

- [ ] **Step 2: Update required status checks**

```bash
gh api --method PUT orgs/navigaite/rulesets/13405188 \
  --input <(jq -n '{
    "rules": [
      {
        "type": "required_status_checks",
        "parameters": {
          "strict_required_status_checks_policy": false,
          "do_not_enforce_on_create": false,
          "required_status_checks": [
            {"context": "Check Gate"},
            {"context": "Branch Guard"}
          ]
        }
      }
    ]
  }')
```

**Important:** The PUT replaces the `rules` array. We need to include ALL existing rules, not just status checks. First fetch the full ruleset, modify only the status checks rule, and PUT back the complete rules array.

- [ ] **Step 3: Verify the update**

```bash
gh api orgs/navigaite/rulesets/13405188 --jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks'
```

Expected: `[{"context": "Check Gate"}, {"context": "Branch Guard"}]`

---

## Task 4: Migrate `nvgt-trunk-plugin`

**Files:**
- Modify: `~/projects/Navigaite/internal/nvgt-trunk-plugin/.github/workflows/ci.yaml`

- [ ] **Step 1: Update ci.yaml**

Change workflow name from `Navigaite CI/CD Pipeline` to `Navigaite Pipeline`. Remove explicit `name:` from pipeline job (let it use key). Add Branch Guard inside the same workflow (it's already there). Add Check Gate.

```yaml
---
name: Navigaite Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  merge_group: {}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

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
    uses: navigaite/.github/.github/workflows/universal-pipeline.yaml@v2
    with:
      config-file: .github/pipeline.yaml
      skip-security: ${{ github.event_name != 'pull_request' }}
    secrets: inherit

  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request' || github.event_name == 'merge_group'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: ✅ Allow PR
        run: echo "✅ Single-branch repo — all PRs target main directly"

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

- [ ] **Step 2: Commit**

```bash
cd ~/projects/Navigaite/internal/nvgt-trunk-plugin
git add .github/workflows/ci.yaml
git commit -m "ci: standardize workflow naming to Navigaite Pipeline convention

Rename workflow, add Check Gate aggregator, align with org-wide
naming convention for required status checks."
```

---

## Task 5: Migrate `edilio`

**Files:**
- Modify: `~/projects/Navigaite/customers/edilio/.github/workflows/ci.yaml`

Edilio is a large repo (dev + main). It has custom jobs (generate-token, sentry-release, deploy-production-*). The pipeline job currently has `name: Navigaite CI/CD Pipeline` — remove that explicit name. Rename the workflow.

- [ ] **Step 1: Update ci.yaml**

Key changes:
- `name: Navigaite CI/CD` → `name: Navigaite Pipeline`
- Remove `name: Navigaite CI/CD Pipeline` from the pipeline job (let it use the key `pipeline`)
- Remove `name: Generate App Token` from generate-token job (let it use the key)
- Add Check Gate that depends on `[pipeline]`

```yaml
---
name: Navigaite Pipeline

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' && github.ref != 'refs/heads/dev' }}

permissions:
  contents: write
  pull-requests: write
  packages: write
  deployments: write
  id-token: write
  attestations: write

jobs:
  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Check PR target branch
        env:
          GH_TOKEN: ${{ github.token }}
          PR_BASE: ${{ github.event.pull_request.base.ref }}
          PR_HEAD: ${{ github.event.pull_request.head.ref }}
          PR_HEAD_REPO: ${{ github.event.pull_request.head.repo.full_name }}
          PR_BASE_REPO: ${{ github.repository }}
          PR_AUTHOR: ${{ github.event.pull_request.user.login }}
        run: |
          if [[ "$PR_BASE" != "main" ]]; then
            echo "✅ PR targets $PR_BASE — allowed"
            exit 0
          fi
          if [[ "$PR_HEAD_REPO" != "$PR_BASE_REPO" ]]; then
            echo "::error::❌ Fork PRs cannot target main. Please open a PR to dev instead."
            exit 1
          fi
          DEV_EXISTS=$(gh api "repos/$PR_BASE_REPO/branches/dev" --jq '.name' 2>/dev/null || echo "")
          if [[ -z "$DEV_EXISTS" ]]; then
            echo "✅ No dev branch — direct-to-main workflow, allowed"
            exit 0
          fi
          if [[ "$PR_HEAD" == "dev" ]]; then
            echo "ℹ️  Promotion PR from dev → main"
            OPEN_RP=$(gh api "repos/$PR_BASE_REPO/pulls" \
              --paginate \
              --jq '[.[] | select(
                .state=="open" and .base.ref=="dev" and
                (.head.ref | startswith("release-please"))
              )] | length')
            if [[ "$OPEN_RP" -gt 0 ]]; then
              echo "::error::❌ There is an open release-please PR on dev. Merge or close it before promoting to main."
              exit 1
            fi
            echo "✅ Promotion allowed — no open release-please PR on dev"
            exit 0
          fi
          if [[ "$PR_HEAD" == release-please--* ]]; then
            if [[ "$PR_AUTHOR" == "github-actions[bot]" || "$PR_AUTHOR" == "navigaite-workflow-app[bot]" ]]; then
              echo "✅ Release-please PR from bot — allowed"
              exit 0
            fi
            echo "::error::❌ Branch name matches release-please pattern but author is '$PR_AUTHOR', not a bot."
            exit 1
          fi
          if [[ "$PR_HEAD" == hotfix/* ]]; then
            echo "⚠️  Hotfix PR targeting main — allowed"
            echo "::warning::Remember to cherry-pick this hotfix back to dev after merging."
            exit 0
          fi
          echo "::error::❌ PRs targeting main must come from:"
          echo "::error::  dev (promotion), release-please (bot), or hotfix/* (emergency)."
          echo "::error::Please retarget this PR to dev instead."
          exit 1

  generate-token:
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    outputs:
      token: ${{ steps.app-token.outputs.token }}
    steps:
      - name: Generate GitHub App token
        id: app-token
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ secrets.WORKFLOW_APP_ID }}
          private-key: ${{ secrets.WORKFLOW_APP_PRIVATE_KEY }}

  pipeline:
    needs: [generate-token]
    if: ${{ needs.generate-token.result == 'success' || needs.generate-token.result == 'skipped' }}
    uses: navigaite/.github/.github/workflows/universal-pipeline.yaml@main
    with:
      config-file: .github/pipeline.yaml
      skip-security: ${{ github.event_name == 'push' }}
      skip-lint: ${{ github.event_name == 'push' }}
      skip-test: ${{ github.event_name == 'push' }}
      skip-build: ${{ github.event_name == 'push' }}
      skip-deploy:
        ${{ !(github.event_name == 'push' && (github.ref == 'refs/heads/dev' || github.ref == 'refs/heads/main')) }}
    secrets:
      GH_TOKEN: ${{ needs.generate-token.outputs.token || '' }}
      INFISICAL_CLIENT_ID: ${{ secrets.INFISICAL_CLIENT_ID }}
      INFISICAL_CLIENT_SECRET: ${{ secrets.INFISICAL_CLIENT_SECRET }}
      INFISICAL_PROJECT_SLUG: ${{ secrets.INFISICAL_PROJECT_SLUG }}
      INFISICAL_ENV_SLUG: ${{ secrets.INFISICAL_ENV_SLUG }}
      INFISICAL_DOMAIN: ${{ secrets.INFISICAL_DOMAIN }}
      INFISICAL_SECRET_PATH: ${{ secrets.INFISICAL_SECRET_PATH }}

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

  sentry-release:
    name: Sentry Release
    needs: [pipeline]
    if: >-
      github.event_name == 'push' && !startsWith(github.event.head_commit.message, 'chore(dev): release') &&
      !startsWith(github.event.head_commit.message, 'chore(main): release')
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - name: Check Infisical credentials
        id: infisical-check
        env:
          INFISICAL_CLIENT_ID: ${{ secrets.INFISICAL_CLIENT_ID }}
          INFISICAL_CLIENT_SECRET: ${{ secrets.INFISICAL_CLIENT_SECRET }}
        run: |
          if [[ -n "$INFISICAL_CLIENT_ID" && -n "$INFISICAL_CLIENT_SECRET" ]]; then
            echo "available=true" >> "$GITHUB_OUTPUT"
          else
            echo "available=false" >> "$GITHUB_OUTPUT"
            echo "::notice::Infisical credentials not configured, skipping Sentry release"
          fi
      - name: Inject secrets
        if: steps.infisical-check.outputs.available == 'true'
        uses: Infisical/secrets-action@v1.0.15
        with:
          method: universal
          client-id: ${{ secrets.INFISICAL_CLIENT_ID }}
          client-secret: ${{ secrets.INFISICAL_CLIENT_SECRET }}
          domain: https://infisical.navigaite.de
          env-slug: ${{ github.ref == 'refs/heads/main' && 'prod' || 'staging' }}
          project-slug: edilio
      - run: pnpm turbo run build
      - name: Create Sentry release
        if: env.SENTRY_AUTH_TOKEN != ''
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
        run: |
          npx @sentry/cli releases new "${{ github.sha }}"
          npx @sentry/cli releases set-commits "${{ github.sha }}" --auto
          npx @sentry/cli sourcemaps upload --release "${{ github.sha }}" \
            apps/consultant/.output/ apps/portal/.output/
          npx @sentry/cli releases finalize "${{ github.sha }}"

  deploy-production-consultant:
    name: Deploy Production / consultant
    needs: [pipeline]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: Trigger Render deploy
        run: |
          curl -sf "${{ secrets.RENDER_CONSULTANT_PROD_HOOK }}" \
            || (echo "::error::Render deploy hook failed for consultant" && exit 1)

  deploy-production-portal:
    name: Deploy Production / portal
    needs: [pipeline]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: Trigger Render deploy
        run: |
          curl -sf "${{ secrets.RENDER_PORTAL_PROD_HOOK }}" \
            || (echo "::error::Render deploy hook failed for portal" && exit 1)
```

- [ ] **Step 2: Commit**

```bash
cd ~/projects/Navigaite/customers/edilio
git add .github/workflows/ci.yaml
git commit -m "ci: standardize workflow naming to Navigaite Pipeline convention

Rename workflow, remove explicit job names (use keys), add Check Gate
aggregator. Aligns with org-wide naming convention."
```

---

## Task 6: Migrate `maimaldrei-mietkatalog`

**Files:**
- Delete: `.github/workflows/ci-pull-request.yaml`
- Delete: `.github/workflows/ci-release.yaml`
- Create: `.github/workflows/ci.yaml`

This repo currently splits PR and release into separate workflows. Consolidate into a single `ci.yaml` like other repos. This is a large repo (dev + main).

- [ ] **Step 1: Create unified ci.yaml**

```yaml
---
name: Navigaite Pipeline

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
  issues: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' && github.ref != 'refs/heads/dev' }}

jobs:
  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Check PR target branch
        env:
          GH_TOKEN: ${{ github.token }}
          PR_BASE: ${{ github.event.pull_request.base.ref }}
          PR_HEAD: ${{ github.event.pull_request.head.ref }}
          PR_HEAD_REPO: ${{ github.event.pull_request.head.repo.full_name }}
          PR_BASE_REPO: ${{ github.repository }}
          PR_AUTHOR: ${{ github.event.pull_request.user.login }}
        run: |
          if [[ "$PR_BASE" != "main" ]]; then
            echo "✅ PR targets $PR_BASE — allowed"
            exit 0
          fi
          if [[ "$PR_HEAD_REPO" != "$PR_BASE_REPO" ]]; then
            echo "::error::❌ Fork PRs cannot target main."
            exit 1
          fi
          DEV_EXISTS=$(gh api "repos/$PR_BASE_REPO/branches/dev" --jq '.name' 2>/dev/null || echo "")
          if [[ -z "$DEV_EXISTS" ]]; then
            echo "✅ No dev branch — allowed"
            exit 0
          fi
          if [[ "$PR_HEAD" == "dev" ]]; then
            OPEN_RP=$(gh api "repos/$PR_BASE_REPO/pulls" --paginate \
              --jq '[.[] | select(.state=="open" and .base.ref=="dev" and (.head.ref | startswith("release-please")))] | length')
            if [[ "$OPEN_RP" -gt 0 ]]; then
              echo "::error::❌ Open release-please PR on dev. Merge it first."
              exit 1
            fi
            echo "✅ Promotion allowed"
            exit 0
          fi
          if [[ "$PR_HEAD" == release-please--* ]]; then
            if [[ "$PR_AUTHOR" == "github-actions[bot]" || "$PR_AUTHOR" == "navigaite-workflow-app[bot]" ]]; then
              echo "✅ Release-please PR — allowed"
              exit 0
            fi
            echo "::error::❌ release-please branch but author is '$PR_AUTHOR'"
            exit 1
          fi
          if [[ "$PR_HEAD" == hotfix/* ]]; then
            echo "⚠️  Hotfix PR — allowed"
            exit 0
          fi
          echo "::error::❌ PRs to main must come from dev, release-please, or hotfix/*."
          exit 1

  pipeline:
    uses: navigaite/.github/.github/workflows/universal-pipeline.yaml@main
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

- [ ] **Step 2: Delete old workflow files**

```bash
cd ~/projects/Navigaite/customers/maimaldrei/maimaldrei-mietkatalog
rm .github/workflows/ci-pull-request.yaml .github/workflows/ci-release.yaml
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/
git commit -m "ci: migrate to Navigaite Pipeline convention

Replace split ci-pull-request.yaml / ci-release.yaml with unified
ci.yaml. Add Branch Guard and Check Gate for org ruleset compliance."
```

---

## Task 7: Migrate Legacy Repos

**Repos:** `maimaldrei-website`, `maimaldrei-dispoplaner`, `nvgt-website`

These all use the old `🔄 PR Changed` pattern calling deleted `sub-*.yaml` workflows. They need a complete replacement.

For each repo:

- [ ] **Step 1: Delete all old `action-*.yaml` workflow files**

- [ ] **Step 2: Create `.github/workflows/ci.yaml`**

Template (adjust branches based on whether repo has dev):

For repos with dev + main (`maimaldrei-website`, `maimaldrei-dispoplaner`):

```yaml
---
name: Navigaite Pipeline

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

permissions:
  contents: write
  pull-requests: write
  deployments: write
  packages: write
  id-token: write
  attestations: write
  security-events: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' && github.ref != 'refs/heads/dev' }}

jobs:
  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Check PR target branch
        env:
          GH_TOKEN: ${{ github.token }}
          PR_BASE: ${{ github.event.pull_request.base.ref }}
          PR_HEAD: ${{ github.event.pull_request.head.ref }}
          PR_HEAD_REPO: ${{ github.event.pull_request.head.repo.full_name }}
          PR_BASE_REPO: ${{ github.repository }}
          PR_AUTHOR: ${{ github.event.pull_request.user.login }}
        run: |
          if [[ "$PR_BASE" != "main" ]]; then
            echo "✅ PR targets $PR_BASE — allowed"
            exit 0
          fi
          if [[ "$PR_HEAD_REPO" != "$PR_BASE_REPO" ]]; then
            echo "::error::❌ Fork PRs cannot target main."
            exit 1
          fi
          DEV_EXISTS=$(gh api "repos/$PR_BASE_REPO/branches/dev" --jq '.name' 2>/dev/null || echo "")
          if [[ -z "$DEV_EXISTS" ]]; then
            echo "✅ No dev branch — allowed"
            exit 0
          fi
          if [[ "$PR_HEAD" == "dev" ]]; then
            OPEN_RP=$(gh api "repos/$PR_BASE_REPO/pulls" --paginate \
              --jq '[.[] | select(.state=="open" and .base.ref=="dev" and (.head.ref | startswith("release-please")))] | length')
            if [[ "$OPEN_RP" -gt 0 ]]; then
              echo "::error::❌ Open release-please PR on dev. Merge it first."
              exit 1
            fi
            echo "✅ Promotion allowed"
            exit 0
          fi
          if [[ "$PR_HEAD" == release-please--* ]]; then
            if [[ "$PR_AUTHOR" == "github-actions[bot]" || "$PR_AUTHOR" == "navigaite-workflow-app[bot]" ]]; then
              echo "✅ Release-please PR — allowed"
              exit 0
            fi
            echo "::error::❌ release-please branch but author is '$PR_AUTHOR'"
            exit 1
          fi
          if [[ "$PR_HEAD" == hotfix/* ]]; then
            echo "⚠️  Hotfix PR — allowed"
            exit 0
          fi
          echo "::error::❌ PRs to main must come from dev, release-please, or hotfix/*."
          exit 1

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

For `nvgt-website` (main only):

Same as above but `branches: [main]` only, and simpler branch-guard (no dev check).

- [ ] **Step 3: Create `.github/pipeline.yaml`** for each repo

Basic config — stack auto-detection handles the rest:

```yaml
---
version: '2.0'

deployment:
  provider: none

release:
  enable: false
```

Adjust per repo if they have Vercel deploys, release config, etc.

- [ ] **Step 4: Commit each repo**

```bash
git add .github/
git commit -m "ci: migrate from legacy workflows to Navigaite Pipeline

Replace old action-*.yaml workflows with unified ci.yaml calling
the universal pipeline. Adds Branch Guard and Check Gate for org
ruleset compliance."
```

---

## Task 8: Migrate Remaining Repos

**Repos:** `nvgt-repo-template`, `abonate-webapp`, `eslint-config`

Same pattern as Task 7. These repos also use legacy workflows.

- `nvgt-repo-template` (dev branch): full ci.yaml with branch guard
- `abonate-webapp` (dev branch): full ci.yaml with branch guard
- `eslint-config` (main only, release-only workflow): add ci.yaml + pipeline.yaml

- [ ] **Step 1-4: Same process as Task 7 for each repo**

---

## Task 9: Handle No-Workflow Repos

**Repos:** `maimaldrei-directus`, `maimaldrei-directus-types`, `maimaldrei-importer`

These repos have no workflows. Add minimal CI so the org ruleset doesn't block PRs.

- [ ] **Step 1: Create `.github/workflows/ci.yaml`** for each

Minimal workflow that just satisfies the required checks:

```yaml
---
name: Navigaite Pipeline

on:
  pull_request:
    branches: [main, dev]
  push:
    branches: [main, dev]

permissions: {}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - run: echo "✅ PR allowed"

  check-gate:
    name: Check Gate
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - run: echo "✅ No CI configured — pass-through"
```

- [ ] **Step 2: Commit each repo**

---

## Task 10: Document in AGENTS.md

**Files:**
- Create: `~/projects/Navigaite/internal/nvgt-github/AGENTS.md`

- [ ] **Step 1: Write AGENTS.md**

```markdown
# Navigaite Universal CI/CD Pipeline — AI Agent Instructions

## CI Check Naming Convention

All repos in the `navigaite` org MUST follow this naming convention for GitHub Actions workflows.

### Required Check Names (Org Ruleset)

The org-level ruleset "Protected branches" requires exactly two status checks:

| Check Name     | Purpose                                              |
| -------------- | ---------------------------------------------------- |
| `Check Gate`   | Aggregator — passes only when all pipeline stages pass |
| `Branch Guard` | Enforces branch targeting rules (dev/main flow)      |

### Caller Workflow Convention

Every repo's `.github/workflows/ci.yaml` MUST use:

```yaml
name: Navigaite Pipeline  # EXACT — this becomes the check name prefix
```

The calling job MUST use the key `pipeline` with NO explicit `name:` field:

```yaml
jobs:
  pipeline:  # No 'name:' — GitHub uses the key, producing "Navigaite Pipeline / pipeline"
    uses: navigaite/.github/.github/workflows/universal-pipeline.yaml@v2
    with:
      config-file: .github/pipeline.yaml
    secrets: inherit
```

### Check Gate Job

Every caller workflow MUST include a Check Gate job:

```yaml
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

### Branch Guard Job

Every caller workflow MUST include a Branch Guard job. Two variants:

**Small repos (main only):**
```yaml
  branch-guard:
    name: Branch Guard
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - run: echo "✅ Single-branch repo — all PRs target main directly"
```

**Large repos (dev + main):**
See the full branch guard implementation in the edilio or maimaldrei-mietkatalog ci.yaml files. It enforces:
- Feature PRs must target `dev`, not `main`
- Only `dev` (promotion), `release-please--*` (bot), and `hotfix/*` branches can target `main`
- Blocks promotion if dev has an open release-please PR

### Resulting Check Names

For a consumer repo calling the universal pipeline, GitHub produces these check names:

- `Navigaite Pipeline / Check Gate` — **required by org ruleset**
- `Navigaite Pipeline / Branch Guard` — **required by org ruleset**
- `Navigaite Pipeline / pipeline / 🧹 Lint` — informational
- `Navigaite Pipeline / pipeline / 🧪 Test` — informational
- `Navigaite Pipeline / pipeline / 🏗️ Build` — informational
- `Navigaite Pipeline / pipeline / 🔧 Setup & Configuration` — informational
- (other pipeline stages as configured)

### Why This Convention

1. **No emoji in required check names** — emoji encoding varies across editors and can silently break exact-match enforcement.
2. **Single gate check** — adding/removing pipeline stages (e.g., E2E tests) doesn't require updating the org ruleset.
3. **Uniform prefix** — all repos produce `Navigaite Pipeline / ...` checks, making the GitHub UI consistent.
4. **Branch Guard is separate** — it runs outside the reusable workflow as a top-level job, ensuring it always reports regardless of pipeline configuration.

### Do NOT

- Use a different workflow `name:` (e.g., `CI/CD Pipeline`, `CI`, `Build`)
- Add an explicit `name:` to the `pipeline` job (this changes the check name prefix)
- Remove the Check Gate or Branch Guard jobs
- Add individual pipeline stages (Lint, Test, Build) to the org ruleset's required checks
```

- [ ] **Step 2: Commit**

```bash
cd ~/projects/Navigaite/internal/nvgt-github
git add AGENTS.md
git commit -m "docs: add AGENTS.md with CI check naming convention for AI agents"
```

---

## Task 11: Update CLAUDE.md

**Files:**
- Modify: `~/projects/Navigaite/internal/nvgt-github/CLAUDE.md`

Update the "Setting Up the Pipeline in a Consumer Repo" section and the "Org-Level GitHub Rulesets" section to reflect the new naming convention.

- [ ] **Step 1: Update naming convention references**

In the "Setting Up the Pipeline" section, change the example caller workflow to use `name: Navigaite Pipeline` and add the Check Gate job. Update the "Naming conventions" list.

In the "Org-Level GitHub Rulesets" section, update required status checks from `Lint, Test, Build, Branch Guard` to `Check Gate, Branch Guard`.

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with new check naming convention"
```
