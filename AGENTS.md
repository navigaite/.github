# Navigaite Universal CI/CD Pipeline — AI Agent Instructions

## CI Check Naming Convention

All repos in the `navigaite` org MUST follow this naming convention for GitHub Actions workflows.

### Required Check Names (Org Ruleset)

The org-level ruleset "Protected branches" requires exactly two status checks, matched by GitHub on the job `name:` field (the bare `check_run.name`, NOT the workflow-prefixed path shown in the PR UI):

| Ruleset context | Job `name:` | Purpose                                                |
| --------------- | ----------- | ------------------------------------------------------ |
| `Check Gate`    | `Check Gate`   | Aggregator — passes only when all pipeline stages pass |
| `Branch Guard`  | `Branch Guard` | Enforces branch targeting rules (dev/main flow)        |

GitHub's PR UI displays these as `Navigaite Pipeline / Check Gate` and `Navigaite Pipeline / Branch Guard` (the workflow name is a visual grouping prefix), but the ruleset `context` field matches the bare job name. Do not include the `Navigaite Pipeline /` prefix in ruleset configuration — it will fail to match.

### Caller Workflow Convention

Every repo's `.github/workflows/ci.yaml` MUST use:

```yaml
name: Navigaite Pipeline  # EXACT — this becomes the check name prefix
```

The calling job MUST use the key `pipeline` with NO explicit `name:` field:

```yaml
jobs:
  pipeline:  # No 'name:' — GitHub uses the key
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

The branch guard enforces:

- Feature PRs must target `dev`, not `main`
- Only `dev` (promotion), `release-please--*` (bot), and `hotfix/*` branches can target `main`
- Blocks promotion if dev has an open release-please PR

See the edilio or maimaldrei-mietkatalog `ci.yaml` files for the full implementation.

### Resulting Check Names (PR UI Display)

For a consumer repo calling the universal pipeline, GitHub's PR UI displays these check paths:

- `Navigaite Pipeline / Check Gate` — **required** (ruleset context: `Check Gate`)
- `Navigaite Pipeline / Branch Guard` — **required** (ruleset context: `Branch Guard`)
- `Navigaite Pipeline / pipeline / 🧹 Lint` — informational
- `Navigaite Pipeline / pipeline / 🧪 Test` — informational
- `Navigaite Pipeline / pipeline / 🏗️ Build` — informational
- `Navigaite Pipeline / pipeline / 🔧 Setup & Configuration` — informational
- (other pipeline stages as configured)

The `Navigaite Pipeline /` prefix is GitHub's UI grouping, not part of the ruleset context. The ruleset matches the bare job `name:` field.

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
