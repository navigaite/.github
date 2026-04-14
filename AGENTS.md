# Navigaite Universal CI/CD Pipeline — AI Agent Instructions

## CI Check Naming Convention

All repos in the `navigaite` org MUST follow this naming convention for GitHub Actions workflows.

### Required Check Names (Org Ruleset)

The org-level ruleset "Protected branches" requires exactly two status checks:

| Check Name     | Purpose                                                |
| -------------- | ------------------------------------------------------ |
| `Check Gate`   | Aggregator — passes only when all pipeline stages pass |
| `Branch Guard` | Enforces branch targeting rules (dev/main flow)        |

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
        env:
          RESULTS: ${{ toJSON(needs.*.result) }}
        run: |
          echo "Job results: $RESULTS"
          if echo "$RESULTS" | jq -e 'map(select(. == "failure" or . == "cancelled")) | length > 0' > /dev/null 2>&1; then
            echo "::error::Pipeline failed"
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
