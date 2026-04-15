#!/usr/bin/env bash
# Bootstrap org-wide maintenance automation into every navigaite repo.
#
# What it does, per repo:
#   1. Writes .github/dependabot.yml from templates/dependabot.yml
#   2. Writes .github/workflows/trunk-upgrade-scheduled.yaml from
#      templates/trunk-upgrade-scheduled.yaml with a staggered cron
#      (hashed by repo name, Mon–Fri, 04:00–10:00 UTC). Distinct filename
#      so it can coexist with the reusable `trunk-upgrade.yaml` inside
#      navigaite/.github itself.
#   3. Writes .github/workflows/claude-code-fix.yaml from
#      templates/claude-code-fix.yaml (thin caller that delegates to the
#      reusable claude-code workflow in navigaite/.github).
#   4. Removes any legacy caller-style workflows at
#      .github/workflows/claude-code.yaml and
#      .github/workflows/trunk-upgrade.yaml (files that are NOT reusable
#      workflow definitions — i.e. don't contain `workflow_call:`).
#   5. Opens a PR titled "chore(ci): bootstrap org maintenance automation"
#      targeting the repo's default branch.
#
# Idempotent: if the files already match the templates, no PR is opened.
# Respects an open existing bootstrap PR (skips that repo).
#
# Requirements:
#   - gh CLI, authenticated as an org admin or via the workflow App
#   - jq
#   - Run from the root of navigaite/.github
#
# Usage:
#   scripts/bootstrap-maintenance.sh                 # dry run, prints plan
#   scripts/bootstrap-maintenance.sh --audit-only    # read-only AGENTS.md
#                                                    # compliance report per
#                                                    # repo, no changes
#   scripts/bootstrap-maintenance.sh --apply         # actually open PRs
#   scripts/bootstrap-maintenance.sh --apply --only repo1,repo2
#   scripts/bootstrap-maintenance.sh --org my-org    # override org name
#
# Every --apply PR body embeds a per-repo pipeline compliance audit derived
# from navigaite/.github/AGENTS.md §4. The audit is read-only — it flags
# deviations for human follow-up but never mutates caller workflows or
# pipeline.yaml.

set -euo pipefail

ORG="navigaite"
APPLY=false
ONLY=""
AUDIT_ONLY=false
# No repos are skipped — every caller-template now uses a distinct
# filename (`claude-code-fix.yaml`, `trunk-upgrade-scheduled.yaml`),
# so they no longer collide with the reusable workflows' paths inside
# navigaite/.github itself.
SKIP_REPOS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --audit-only) AUDIT_ONLY=true; shift ;;
    --org) ORG="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v gh >/dev/null || { echo "gh CLI required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPENDABOT_TEMPLATE="$REPO_ROOT/.github/config/templates/dependabot.yml"
TRUNK_TEMPLATE="$REPO_ROOT/.github/config/templates/trunk-upgrade-scheduled.yaml"
CLAUDE_TEMPLATE="$REPO_ROOT/.github/config/templates/claude-code-fix.yaml"

[[ -f "$DEPENDABOT_TEMPLATE" ]] || { echo "Missing $DEPENDABOT_TEMPLATE" >&2; exit 1; }
[[ -f "$TRUNK_TEMPLATE" ]] || { echo "Missing $TRUNK_TEMPLATE" >&2; exit 1; }
[[ -f "$CLAUDE_TEMPLATE" ]] || { echo "Missing $CLAUDE_TEMPLATE" >&2; exit 1; }

# Deterministic stagger: hash(repo) → (day 1–5 Mon–Fri, hour 4–10 UTC, minute 0/15/30/45)
stagger_cron() {
  local repo="$1"
  local hex day hour minute
  hex="$(printf '%s' "$repo" | shasum -a 256 | cut -c1-8)"
  local n=$((16#$hex))
  day=$(( (n % 5) + 1 ))
  hour=$(( ((n / 5) % 7) + 4 ))
  minute=$(( ((n / 35) % 4) * 15 ))
  printf '%d %d * * %d' "$minute" "$hour" "$day"
}

render_trunk_workflow() {
  local repo="$1" cron
  cron="$(stagger_cron "$repo")"
  sed "s|__CRON__|$cron|" "$TRUNK_TEMPLATE"
}

is_skipped() {
  local repo="$1" s
  [[ ${#SKIP_REPOS[@]} -eq 0 ]] && return 1
  for s in "${SKIP_REPOS[@]}"; do
    [[ "$repo" == "$s" ]] && return 0
  done
  return 1
}

list_repos() {
  local all
  if [[ -n "$ONLY" ]]; then
    IFS=',' read -ra all <<< "$ONLY"
  else
    all=()
    while IFS= read -r r; do all+=("$r"); done < <(
      gh repo list "$ORG" --limit 200 --no-archived --json name --jq '.[].name'
    )
  fi
  for r in "${all[@]}"; do
    if is_skipped "$r"; then
      echo "::skip $r" >&2
      continue
    fi
    echo "$r"
  done
}

fetch_remote_file() {
  local repo="$1" path="$2"
  gh api "repos/$ORG/$repo/contents/$path" --jq '.content' 2>/dev/null \
    | base64 -d 2>/dev/null || true
}

is_bespoke_dependabot() {
  # Returns 0 (true) if a non-empty dependabot.yml exists WITHOUT the
  # "Managed by navigaite/.github bootstrap" sentinel header — i.e. it
  # was hand-maintained and the bootstrap should not steamroll it.
  local content="$1"
  [[ -z "$content" ]] && return 1
  if grep -qF 'Managed by navigaite/.github bootstrap' <<< "$content"; then
    return 1
  fi
  return 0
}

is_legacy_caller() {
  # Returns 0 (true) if the file exists and is a caller-style workflow
  # (no `workflow_call:` trigger) — i.e. safe to delete. Returns 1 otherwise.
  local content="$1"
  [[ -z "$content" ]] && return 1
  if grep -qE '^\s*workflow_call\s*:' <<< "$content"; then
    return 1
  fi
  return 0
}

audit_repo() {
  # Reads the repo's default branch, ci.yaml, and pipeline.yaml via gh api
  # (no clone). Emits a Markdown audit report to stdout. Pure read — never
  # mutates the repo. Checks are derived from AGENTS.md §4 "MANDATORY vs
  # OPTIONAL — Consumer Integration Checklist".
  local repo="$1"

  # The .github meta repo itself PROVIDES the universal pipeline; it does
  # not consume it as a caller. Skip the consumer-side audit here and emit
  # a short note instead so the bootstrap PR body still has content.
  if [[ "$repo" == ".github" ]]; then
    cat <<'EOF'
## Pipeline Compliance Audit

Not applicable — this is `navigaite/.github`, the meta repo that *provides* the universal pipeline. Consumer-side checks (caller `ci.yaml` shape, `pipeline.yaml`, etc.) don't apply.

See [AGENTS.md §10](https://github.com/navigaite/.github/blob/main/AGENTS.md) for conventions that govern this repo's own release/versioning workflow.
EOF
    return 0
  fi

  local default_branch ci_yaml pipeline_yaml rp_config rp_config_main rp_manifest
  local profile lines=()

  default_branch="$(gh api "repos/$ORG/$repo" --jq '.default_branch' 2>/dev/null || echo "")"
  ci_yaml="$(fetch_remote_file "$repo" ".github/workflows/ci.yaml")"
  pipeline_yaml="$(fetch_remote_file "$repo" ".github/pipeline.yaml")"
  rp_config="$(fetch_remote_file "$repo" ".github/release-please-config.json")"
  rp_config_main="$(fetch_remote_file "$repo" ".github/release-please-config.main.json")"
  rp_manifest="$(fetch_remote_file "$repo" ".release-please-manifest.json")"

  case "$default_branch" in
    dev) profile="B (dev + main, prereleases)" ;;
    main) profile="A (main only)" ;;
    *) profile="? (default branch: ${default_branch:-unknown})" ;;
  esac

  lines+=("## Pipeline Compliance Audit")
  lines+=("")
  lines+=("Read-only check against [AGENTS.md](https://github.com/$ORG/.github/blob/main/AGENTS.md). No automated fixes — deviations below require a focused follow-up PR.")
  lines+=("")
  lines+=("- **Detected branching profile:** $profile")
  lines+=("")
  lines+=("| Check | Status | Notes |")
  lines+=("| --- | :---: | --- |")

  # --- ci.yaml presence + shape ---
  if [[ -z "$ci_yaml" ]]; then
    lines+=("| \`.github/workflows/ci.yaml\` exists | 🚫 | No caller workflow found — pipeline not wired up |")
    # Skip downstream ci.yaml checks if missing.
    local ci_present=false
  else
    local ci_present=true
    lines+=("| \`.github/workflows/ci.yaml\` exists | ✅ | |")

    if grep -qE '^name:[[:space:]]+Navigaite Pipeline[[:space:]]*$' <<< "$ci_yaml"; then
      lines+=("| Workflow \`name: Navigaite Pipeline\` | ✅ | |")
    else
      local actual_name
      actual_name="$(grep -E '^name:' <<< "$ci_yaml" | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"'"'"'' )"
      lines+=("| Workflow \`name: Navigaite Pipeline\` | ⚠️ | Current: \`${actual_name:-<none>}\` — required for uniform UI grouping |")
    fi

    if grep -qE 'uses:[[:space:]]+navigaite/\.github/\.github/workflows/universal-pipeline\.yaml@v2' <<< "$ci_yaml"; then
      lines+=("| Pipeline delegates to \`universal-pipeline.yaml@v2\` | ✅ | |")
    elif grep -qE 'uses:[[:space:]]+navigaite/\.github/\.github/workflows/universal-pipeline\.yaml@' <<< "$ci_yaml"; then
      local pin
      pin="$(grep -oE 'universal-pipeline\.yaml@[^[:space:]]+' <<< "$ci_yaml" | head -1 | sed 's|.*@||')"
      lines+=("| Pipeline pinned to \`@v2\` rolling tag | ⚠️ | Currently pinned to \`@${pin}\` — drifts from rolling release |")
    else
      lines+=("| Pipeline delegates to \`universal-pipeline.yaml\` | 🚫 | No \`uses:\` of the universal pipeline — caller may be misconfigured |")
    fi

    if grep -qE '^[[:space:]]+name:[[:space:]]+Branch Guard[[:space:]]*$' <<< "$ci_yaml"; then
      lines+=("| \`Branch Guard\` job present (exact name) | ✅ | |")
    else
      lines+=("| \`Branch Guard\` job present (exact name) | 🚫 | Required status check — org ruleset will fail |")
    fi

    if grep -qE '^[[:space:]]+name:[[:space:]]+Check Gate[[:space:]]*$' <<< "$ci_yaml"; then
      lines+=("| \`Check Gate\` job present (exact name) | ✅ | |")
    else
      lines+=("| \`Check Gate\` job present (exact name) | 🚫 | Required status check — org ruleset will fail |")
    fi

    if grep -qE '^[[:space:]]+secrets:[[:space:]]+inherit[[:space:]]*$' <<< "$ci_yaml"; then
      lines+=("| \`secrets: inherit\` on pipeline job | ✅ | |")
    else
      lines+=("| \`secrets: inherit\` on pipeline job | ⚠️ | Not found — reusable workflow may lack deploy/release secrets |")
    fi

    if grep -qE '^permissions:[[:space:]]*$' <<< "$ci_yaml"; then
      lines+=("| Workflow-level \`permissions:\` block | ✅ | |")
    else
      lines+=("| Workflow-level \`permissions:\` block | ⚠️ | Not found — defaults may not cover all enabled stages |")
    fi
  fi

  # --- pipeline.yaml ---
  if [[ -z "$pipeline_yaml" ]]; then
    lines+=("| \`.github/pipeline.yaml\` exists | 🚫 | Required — pipeline cannot configure stages |")
  else
    lines+=("| \`.github/pipeline.yaml\` exists | ✅ | |")
    if grep -qE "^version:[[:space:]]+['\"]?2\.0['\"]?[[:space:]]*$" <<< "$pipeline_yaml"; then
      lines+=("| \`pipeline.yaml\` declares \`version: '2.0'\` | ✅ | |")
    else
      lines+=("| \`pipeline.yaml\` declares \`version: '2.0'\` | ⚠️ | Version line missing or wrong |")
    fi
  fi

  # --- release-please shape per profile ---
  if [[ -z "$rp_manifest" ]]; then
    lines+=("| release-please manifest present | ℹ️ | No \`.release-please-manifest.json\` — release automation likely disabled |")
  else
    lines+=("| release-please manifest present | ✅ | |")
    case "$default_branch" in
      dev)
        if [[ -n "$rp_config" && -n "$rp_config_main" ]]; then
          lines+=("| Profile B dual release-please configs | ✅ | \`release-please-config.json\` (dev/beta) + \`release-please-config.main.json\` (stable) |")
        else
          lines+=("| Profile B dual release-please configs | ⚠️ | Expected both \`release-please-config.json\` AND \`release-please-config.main.json\` for dev+main prereleases |")
        fi
        ;;
      main)
        if [[ -n "$rp_config" && -z "$rp_config_main" ]]; then
          lines+=("| Profile A single release-please config | ✅ | |")
        elif [[ -n "$rp_config_main" ]]; then
          lines+=("| Profile A single release-please config | ⚠️ | Has \`release-please-config.main.json\` but default branch is \`main\` — may be misconfigured |")
        else
          lines+=("| Profile A single release-please config | ℹ️ | No \`release-please-config.json\` — release automation likely disabled |")
        fi
        ;;
    esac
  fi

  # --- items we cannot verify via API ---
  lines+=("| Secrets per deploy provider | ℹ️ | Not auto-checkable — verify in repo Settings → Secrets → Actions (see AGENTS.md §6) |")
  lines+=("| Signed commits enforced | ℹ️ | Controlled by org ruleset \"Protected branches\" |")
  lines+=("| Repo settings (squash/merge/auto-merge) | ℹ️ | Not auto-checkable — see AGENTS.md §7 |")

  lines+=("")
  lines+=("**Legend:** ✅ matches spec · ⚠️ deviation — follow-up PR recommended · 🚫 mandatory item missing — required for org ruleset · ℹ️ informational / manual verification")

  printf '%s\n' "${lines[@]}"
}

plan_repo() {
  local repo="$1"
  local desired_dependabot desired_trunk desired_claude
  local current_dependabot current_trunk current_claude
  local current_trunk_legacy current_claude_legacy
  local changes=()

  desired_dependabot="$(cat "$DEPENDABOT_TEMPLATE")"
  desired_trunk="$(render_trunk_workflow "$repo")"
  desired_claude="$(cat "$CLAUDE_TEMPLATE")"

  current_dependabot="$(fetch_remote_file "$repo" ".github/dependabot.yml")"
  current_trunk="$(fetch_remote_file "$repo" ".github/workflows/trunk-upgrade-scheduled.yaml")"
  current_claude="$(fetch_remote_file "$repo" ".github/workflows/claude-code-fix.yaml")"
  current_trunk_legacy="$(fetch_remote_file "$repo" ".github/workflows/trunk-upgrade.yaml")"
  current_claude_legacy="$(fetch_remote_file "$repo" ".github/workflows/claude-code.yaml")"

  if is_bespoke_dependabot "$current_dependabot"; then
    echo "  [keep] $repo — preserving bespoke dependabot.yml (no bootstrap sentinel)" >&2
  elif [[ "$current_dependabot" != "$desired_dependabot" ]]; then
    changes+=("dependabot.yml")
  fi
  [[ "$current_trunk" != "$desired_trunk" ]] && changes+=("trunk-upgrade-scheduled.yaml")
  [[ "$current_claude" != "$desired_claude" ]] && changes+=("claude-code-fix.yaml")
  if is_legacy_caller "$current_trunk_legacy"; then
    changes+=("delete:trunk-upgrade.yaml (legacy caller)")
  fi
  if is_legacy_caller "$current_claude_legacy"; then
    changes+=("delete:claude-code.yaml (legacy caller)")
  fi

  if [[ ${#changes[@]} -eq 0 ]]; then
    echo "  [skip] $repo — already up to date"
    return 1
  fi

  echo "  [plan] $repo — would update: ${changes[*]}"
  return 0
}

apply_repo() {
  local repo="$1"
  local default_branch branch_name existing_pr
  default_branch="$(gh api "repos/$ORG/$repo" --jq '.default_branch')"
  branch_name="chore/bootstrap-maintenance"

  existing_pr="$(gh pr list -R "$ORG/$repo" --head "$branch_name" --state open --json number --jq 'length' 2>/dev/null || echo 0)"
  if [[ "$existing_pr" != "0" ]]; then
    echo "  [skip] $repo — open bootstrap PR already exists"
    return 0
  fi

  local workdir
  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' RETURN

  git -C "$workdir" clone --depth 1 --branch "$default_branch" "https://github.com/$ORG/$repo.git" . >/dev/null 2>&1
  git -C "$workdir" checkout -b "$branch_name"

  mkdir -p "$workdir/.github/workflows"
  if [[ -f "$workdir/.github/dependabot.yml" ]] \
     && ! grep -qF 'Managed by navigaite/.github bootstrap' "$workdir/.github/dependabot.yml"; then
    echo "  [keep] $repo — bespoke dependabot.yml retained" >&2
  else
    cp "$DEPENDABOT_TEMPLATE" "$workdir/.github/dependabot.yml"
  fi
  render_trunk_workflow "$repo" > "$workdir/.github/workflows/trunk-upgrade-scheduled.yaml"
  cp "$CLAUDE_TEMPLATE" "$workdir/.github/workflows/claude-code-fix.yaml"

  # Remove legacy caller-style workflows at the shared paths, but preserve
  # any reusable workflow definitions (files starting with
  # `on:\n  workflow_call:`).
  local legacy_path
  for legacy_path in \
    .github/workflows/trunk-upgrade.yaml \
    .github/workflows/claude-code.yaml; do
    local legacy_file="$workdir/$legacy_path"
    if [[ -f "$legacy_file" ]] && ! grep -qE '^\s*workflow_call\s*:' "$legacy_file"; then
      git -C "$workdir" rm -q -- "$legacy_path"
    fi
  done

  git -C "$workdir" add \
    .github/dependabot.yml \
    .github/workflows/trunk-upgrade-scheduled.yaml \
    .github/workflows/claude-code-fix.yaml
  if git -C "$workdir" diff --cached --quiet; then
    echo "  [skip] $repo — nothing changed after clone"
    return 0
  fi
  git -C "$workdir" -c user.name="navigaite-workflow-app[bot]" \
                    -c user.email="navigaite-workflow-app[bot]@users.noreply.github.com" \
                    commit -m "chore(ci): bootstrap org maintenance automation" >/dev/null

  git -C "$workdir" push -u origin "$branch_name" >/dev/null 2>&1

  local audit_md
  audit_md="$(audit_repo "$repo")"

  local body_file
  body_file="$(mktemp)"
  {
    cat <<EOF
Automated bootstrap from \`navigaite/.github\`. Installs:

- Weekly Dependabot updates (github-actions ecosystem).
- Staggered \`Trunk Upgrade Scheduled\` caller at \`.github/workflows/trunk-upgrade-scheduled.yaml\` that delegates to the reusable \`trunk-upgrade\` workflow in \`navigaite/.github\`. Auto-merges after CI.
- Thin \`Claude Code Fix\` caller at \`.github/workflows/claude-code-fix.yaml\` that delegates to the reusable \`claude-code\` workflow in \`navigaite/.github\`.

If this repo previously had caller-style \`trunk-upgrade.yaml\` or \`claude-code.yaml\` at those shared paths, they are removed here in favor of the new \`-fix\` / \`-scheduled\` naming. Reusable-workflow definitions (files with \`on: workflow_call\`) are preserved.

Managed by \`scripts/bootstrap-maintenance.sh\` — edits to these files will be overwritten on the next bootstrap run.

---

EOF
    printf '%s\n' "$audit_md"
  } > "$body_file"

  gh pr create -R "$ORG/$repo" \
    --base "$default_branch" \
    --head "$branch_name" \
    --title "chore(ci): bootstrap org maintenance automation" \
    --body-file "$body_file" >/dev/null
  rm -f "$body_file"

  echo "  [done] $repo — PR opened"
}

echo "Scanning $ORG repos…"
REPOS=()
while IFS= read -r r; do REPOS+=("$r"); done < <(list_repos)
echo "Found ${#REPOS[@]} repos"
echo

if $AUDIT_ONLY; then
  echo "Audit-only mode — reading pipeline compliance for each repo, no changes."
  echo
  for r in "${REPOS[@]}"; do
    echo "===================================================================="
    echo "# $r"
    echo "===================================================================="
    audit_repo "$r"
    echo
  done
  exit 0
fi

if ! $APPLY; then
  echo "Dry run — no changes will be made. Pass --apply to open PRs, or --audit-only for pipeline compliance report."
  echo
  for r in "${REPOS[@]}"; do
    plan_repo "$r" || true
  done
  exit 0
fi

for r in "${REPOS[@]}"; do
  if plan_repo "$r"; then
    apply_repo "$r"
  fi
done
