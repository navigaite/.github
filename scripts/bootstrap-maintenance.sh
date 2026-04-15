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
#   scripts/bootstrap-maintenance.sh --apply         # actually open PRs
#   scripts/bootstrap-maintenance.sh --apply --only repo1,repo2
#   scripts/bootstrap-maintenance.sh --org my-org    # override org name

set -euo pipefail

ORG="navigaite"
APPLY=false
ONLY=""
# No repos are skipped — every caller-template now uses a distinct
# filename (`claude-code-fix.yaml`, `trunk-upgrade-scheduled.yaml`),
# so they no longer collide with the reusable workflows' paths inside
# navigaite/.github itself.
SKIP_REPOS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
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

  [[ "$current_dependabot" != "$desired_dependabot" ]] && changes+=("dependabot.yml")
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
  cp "$DEPENDABOT_TEMPLATE" "$workdir/.github/dependabot.yml"
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

  gh pr create -R "$ORG/$repo" \
    --base "$default_branch" \
    --head "$branch_name" \
    --title "chore(ci): bootstrap org maintenance automation" \
    --body "Automated bootstrap from \`navigaite/.github\`. Installs:

- Weekly Dependabot updates (github-actions ecosystem).
- Staggered \`Trunk Upgrade Scheduled\` caller at \`.github/workflows/trunk-upgrade-scheduled.yaml\` that delegates to the reusable \`trunk-upgrade\` workflow in \`navigaite/.github\`. Auto-merges after CI.
- Thin \`Claude Code Fix\` caller at \`.github/workflows/claude-code-fix.yaml\` that delegates to the reusable \`claude-code\` workflow in \`navigaite/.github\`.

If this repo previously had caller-style \`trunk-upgrade.yaml\` or \`claude-code.yaml\` at those shared paths, they are removed here in favor of the new \`-fix\` / \`-scheduled\` naming. Reusable-workflow definitions (files with \`on: workflow_call\`) are preserved.

Managed by \`scripts/bootstrap-maintenance.sh\` — edits to these files will be overwritten on the next bootstrap run." >/dev/null

  echo "  [done] $repo — PR opened"
}

echo "Scanning $ORG repos…"
REPOS=()
while IFS= read -r r; do REPOS+=("$r"); done < <(list_repos)
echo "Found ${#REPOS[@]} repos"
echo

if ! $APPLY; then
  echo "Dry run — no changes will be made. Pass --apply to open PRs."
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
