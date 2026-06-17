#!/usr/bin/env bash
# Reconcile a dev (prerelease/beta) release-please manifest against the
# just-released stable manifest after a stable release reaches `main`.
#
# Why this exists
# ---------------
# Profile B repos run a dual-track release-please setup with two decoupled
# manifests:
#   - prerelease manifest (dev/beta channel, `versioning: prerelease`)
#   - stable manifest (main channel)
#
# When a stable release is cut on `main` (e.g. 0.5.0), only the stable manifest
# advances. The dev manifest stays at its `X.Y.Z-beta.N` cursor. Because
# release-please's PrereleaseMinorVersionUpdate only bumps the beta counter
# while the cursor is a prerelease with patch === 0, the dev base never
# advances on its own — so new betas (0.5.0-beta.5/.6) end up semver-LOWER than
# the released stable. This recurs every release cycle.
#
# This script strips the prerelease suffix off each dev manifest entry and sets
# its base to the corresponding just-released stable version, so the next dev
# release computes correctly (feat -> X.(Y+1).0-beta.1, fix -> X.Y.(Z+1)-beta.1).
#
# Safety: an entry is only reset when the dev cursor is a prerelease whose BASE
# version is <= the stable version. A dev package that legitimately raced ahead
# of stable (e.g. dev already at 0.6.0-beta.2 while main released 0.5.0) is left
# untouched — we never downgrade dev.
#
# Usage:
#   reconcile-prerelease-manifest.sh <dev-manifest> <stable-manifest> [single-stable-version]
#
# - <dev-manifest>            path to the prerelease manifest (mutated in place)
# - <stable-manifest>         path to the stable manifest (read-only; may be absent)
# - [single-stable-version]   fallback stable version for the "." root key when
#                             no stable manifest entry is found (e.g. the
#                             release-please release-version output)
#
# The dev manifest is mutated in place only when a change is needed. The caller
# decides whether to commit by inspecting `git diff`. Always exits 0 on success;
# exits non-zero only on malformed input.
set -euo pipefail

DEV_MANIFEST="${1:?dev manifest path required}"
STABLE_MANIFEST="${2:-}"
SINGLE_STABLE="${3:-}"

if [[ ! -f "$DEV_MANIFEST" ]]; then
  echo "reconcile: dev manifest '$DEV_MANIFEST' not found — nothing to do"
  exit 0
fi

if ! jq empty "$DEV_MANIFEST" 2>/dev/null; then
  echo "reconcile: dev manifest '$DEV_MANIFEST' is not valid JSON" >&2
  exit 1
fi

SEMVER_CORE='^[0-9]+\.[0-9]+\.[0-9]+$'

# Return the lower of two semver core versions (X.Y.Z) using version sort.
semver_min() {
  printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1
}

work=$(mktemp)
cp "$DEV_MANIFEST" "$work"
changed=0

# Iterate dev manifest keys (monorepo-safe: one entry per package path).
while IFS= read -r key; do
  devv=$(jq -r --arg k "$key" '.[$k]' "$work")

  # Only prerelease cursors need reconciling (must contain a `-` suffix).
  [[ "$devv" == *-* ]] || continue

  base="${devv%%-*}"

  # Resolve the stable version for this package key.
  stable=""
  if [[ -n "$STABLE_MANIFEST" && -f "$STABLE_MANIFEST" ]]; then
    stable=$(jq -r --arg k "$key" '.[$k] // empty' "$STABLE_MANIFEST")
  fi
  if [[ -z "$stable" && "$key" == "." ]]; then
    stable="$SINGLE_STABLE"
  fi
  [[ -n "$stable" ]] || continue

  # Guard against malformed input: only act when both the dev base and the
  # resolved stable target are plain X.Y.Z cores. This rejects empty/garbage
  # stable-version passthroughs (never writes an empty string into the
  # manifest) and keeps `sort -V` comparing well-formed versions only.
  if ! [[ "$base" =~ $SEMVER_CORE ]]; then
    echo "reconcile: '$key' dev base '$base' is not a core semver — skipping"
    continue
  fi
  if ! [[ "$stable" =~ $SEMVER_CORE ]]; then
    echo "reconcile: '$key' stable target '$stable' is not a core semver — skipping"
    continue
  fi

  # Never downgrade: skip if the dev base is already ahead of stable.
  if [[ "$base" != "$stable" && "$(semver_min "$base" "$stable")" == "$stable" ]]; then
    echo "reconcile: '$key' dev base $base is ahead of stable $stable — leaving $devv untouched"
    continue
  fi

  # Already reconciled (cursor equals stable with no suffix would not match the
  # prerelease guard above, so reaching here means a real change).
  if [[ "$devv" == "$stable" ]]; then
    continue
  fi

  jq --arg k "$key" --arg v "$stable" '.[$k] = $v' "$work" > "$work.next"
  mv "$work.next" "$work"
  changed=1
  echo "reconcile: '$key' $devv -> $stable"
done < <(jq -r 'keys[]' "$work")

if [[ "$changed" == "1" ]]; then
  mv "$work" "$DEV_MANIFEST"
  echo "reconcile: dev manifest '$DEV_MANIFEST' updated"
else
  rm -f "$work"
  echo "reconcile: no changes needed for '$DEV_MANIFEST'"
fi
