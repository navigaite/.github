# Org-wide Maintenance Automation

This repo bootstraps three kinds of automatic upkeep into every `navigaite` org repo:

1. **Dependabot** for the `github-actions` ecosystem (third-party action version bumps).
2. **`trunk upgrade`** on a weekly schedule, staggered per repo, auto-merging after CI.
3. **Claude Code caller** — a thin workflow that defines triggers, gating, and permissions, then delegates execution to the reusable `claude-code.yaml` in `maxbec/pipeline` (the pipeline's home since 2026-08-14). Replaces any inline copy; future filter/diagnostic changes land via `v3` retag in `maxbec/pipeline`, not a per-repo edit.

It does **not** manage bumps of the reusable pipeline itself — consumers pin the universal pipeline to a full commit SHA (`maxbec/pipeline/.github/workflows/universal-pipeline.yaml@<sha> # vX.Y.Z`, repinned by fleet tooling on stable releases; keep the pin comment short for yamllint's 120-char limit), while the maintenance callers here use the rolling `@v3` tag that release-please retargets on every release. That gives zero-maintenance patch updates without producing a PR on every change.

Because the reusable workflows live under a different owner (`maxbec`, not `navigaite`), **`secrets: inherit` silently drops org-level secrets at the owner boundary**. Every rendered caller therefore forwards its secrets explicitly (`CLAUDE_CODE_OAUTH_TOKEN`, `WORKFLOW_APP_ID`, `WORKFLOW_APP_PRIVATE_KEY`; the pipeline `ci.yaml` additionally forwards `CF_ACCESS_CLIENT_ID/SECRET`, `NPM_TOKEN`, `VERCEL_TOKEN/ORG_ID/PROJECT_ID`). Absent secrets resolve empty and the callee treats them as unset. Reference implementation: `.github/workflows/ci.yaml` in `navigaite/nvgt-repo-template`.

## Architecture

| Piece                                          | Location                                                     | Role                                                                       |
| ---------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Reusable `trunk-upgrade.yaml`                  | `.github/workflows/trunk-upgrade.yaml` (`maxbec/pipeline`)   | Runs `trunk upgrade`, opens a PR, enables auto-merge via the workflow App. |
| Trunk Upgrade caller                           | `.github/workflows/trunk-upgrade-scheduled.yaml` (every repo) | Scheduled caller with a staggered cron; delegates to the reusable workflow at `maxbec/pipeline/...@v3` with an explicit secrets block. Distinct filename so it never collides with a reusable of the same name. |
| Dependabot config                              | `.github/dependabot.yml` (each consumer repo)                | Weekly grouped github-actions updates. Ignores `maxbec/pipeline/*` (and the legacy `navigaite/.github/*`). **Skipped if a bespoke `dependabot.yml` (no `Managed by navigaite/.github bootstrap` header) already exists** — bootstrap will not overwrite hand-maintained configs that may include npm/pip/etc. |
| Reusable `claude-code.yaml`                    | `.github/workflows/claude-code.yaml` (`maxbec/pipeline`)     | Runs the `claude-code-action` with diagnostics + permissive bot filter.    |
| Claude Code caller                             | `.github/workflows/claude-code-fix.yaml` (every repo)        | Thin caller that defines triggers + gating and delegates execution to the reusable workflow at `maxbec/pipeline/...@v3` with an explicit secrets block. Distinct filename so the caller never collides with a reusable of the same name. |
| Bootstrap script                               | `scripts/bootstrap-maintenance.sh` (this repo)               | Pushes the three caller files into every org repo via PRs. Deletes legacy caller-style `trunk-upgrade.yaml` and `claude-code.yaml` (preserves reusable definitions). Idempotent. |

## Why this shape

- **Rolling `@v3` over SHA pinning (maintenance callers only).** Letting Dependabot SHA-pin `maxbec/pipeline` would create a PR on every pipeline patch across all 20 repos. The rolling tag solves this without noise. (The universal pipeline `ci.yaml` caller is the exception: it is SHA-pinned deliberately and repinned by fleet tooling on stable releases.)
- **Pull-based, not push-based.** Each repo owns its own schedule and `trunk upgrade` run. A central cron iterating all repos would be brittle and harder to debug.
- **Staggered crons.** The bootstrap script deterministically hashes the repo name to a weekday + hour + minute window (Mon–Fri, 04:00–10:00 UTC) to spread PR creation across the week.
- **App-owned auto-merge.** PRs auto-merge via `navigaite-workflow-app` after `Check Gate` passes. No human approval needed for routine linter bumps.
- **Idempotent bootstrap.** Re-running the script is safe — it compares desired files against remote and opens a PR only when they differ.

## Running the bootstrap

```bash
# Dry run (default)
scripts/bootstrap-maintenance.sh

# Apply across the whole org
scripts/bootstrap-maintenance.sh --apply

# Just two repos
scripts/bootstrap-maintenance.sh --apply --only edilio,nvgt-github
```

Requires `gh` authenticated as an org admin (or a token generated from the workflow App with repo write) and `jq`.

## What consumers see

On merge of the bootstrap PR, the consumer repo gets:

- **Weekly Monday morning Dependabot PR** grouping all `github-actions` bumps. Review + merge manually.
- **Weekly `trunk upgrade` PR** on the repo's assigned day. Auto-merges after CI.

Neither touches `.release-please-manifest.json`, `package.json`, or anything outside `.github/`.

## Troubleshooting

- **Trunk upgrade PRs stuck unmerged.** Check that the repo can resolve `WORKFLOW_APP_ID` + `WORKFLOW_APP_PRIVATE_KEY` (org-level secrets, forwarded explicitly by the rendered caller — `secrets: inherit` would NOT deliver them across the owner boundary). Without them the workflow falls back to `GITHUB_TOKEN` and cannot enable auto-merge.
- **Silent `startup_failure`, no logs, no run.** The repo restricts Actions (`allowed_actions: selected` or `local_only`) without allowing `maxbec/pipeline/*`. Add `maxbec/pipeline/*` to `patterns_allowed` (Settings → Actions → General, or `gh api repos/navigaite/<repo>/actions/permissions/selected-actions`). The audit embedded in every bootstrap PR flags this.
- **Dependabot PRs for `maxbec/pipeline/*` or `navigaite/.github/*`.** Check the `ignore:` block in `.github/dependabot.yml`. The template excludes both explicitly.
- **PR storm from the scheduled runs.** Staggering is across 140 slots (5 days × 7 hours × 4 quarter-hours). With ~20 repos, a few collisions are normal; since each PR lands in its own repo there's no actual conflict — at most a reviewer sees two trunk-upgrade PRs open at once. Not worth fixing.
