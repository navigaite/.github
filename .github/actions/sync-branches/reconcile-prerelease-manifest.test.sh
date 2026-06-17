#!/usr/bin/env bash
# Self-contained tests for reconcile-prerelease-manifest.sh.
# Run: .github/actions/sync-branches/reconcile-prerelease-manifest.test.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/reconcile-prerelease-manifest.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

# run_case <name> <dev-json> <stable-json|-> <single-version|-> <expected-dev-json>
run_case() {
  local name="$1" dev_json="$2" stable_json="$3" single="$4" expected="$5"
  local dev="$TMP/dev.json" stable="$TMP/stable.json"
  printf '%s' "$dev_json" > "$dev"
  local stable_arg=""
  if [[ "$stable_json" != "-" ]]; then
    printf '%s' "$stable_json" > "$stable"
    stable_arg="$stable"
  else
    stable_arg="$TMP/does-not-exist.json"
    rm -f "$stable_arg"
  fi
  local single_arg=""
  [[ "$single" != "-" ]] && single_arg="$single"

  bash "$SCRIPT" "$dev" "$stable_arg" "$single_arg" >/dev/null

  local got expect
  got="$(jq -S -c . "$dev")"
  expect="$(printf '%s' "$expected" | jq -S -c .)"
  if [[ "$got" == "$expect" ]]; then
    echo "ok   - $name"
    pass=$((pass + 1))
  else
    echo "FAIL - $name"
    echo "       expected: $expect"
    echo "       got:      $got"
    fail=$((fail + 1))
  fi
}

# 1. The core bug: stuck beta on the same minor line as the released stable.
run_case "stuck beta resets to stable" \
  '{".":"0.5.0-beta.5"}' '{".":"0.5.0"}' - '{".":"0.5.0"}'

# 2. Dev legitimately ahead of stable (next minor) — must NOT downgrade.
run_case "dev ahead not downgraded" \
  '{".":"0.6.0-beta.2"}' '{".":"0.5.0"}' - '{".":"0.6.0-beta.2"}'

# 3. Dev ahead on patch line — must NOT downgrade.
run_case "dev patch ahead not downgraded" \
  '{".":"0.5.1-beta.1"}' '{".":"0.5.0"}' - '{".":"0.5.1-beta.1"}'

# 4. Monorepo: every prerelease entry reconciled from its stable counterpart.
run_case "monorepo multi-package" \
  '{".":"0.5.0-beta.3","packages/api":"1.2.0-beta.1"}' \
  '{".":"0.5.0","packages/api":"1.2.0"}' - \
  '{".":"0.5.0","packages/api":"1.2.0"}'

# 5. Non-prerelease cursor: no-op.
run_case "already stable no-op" \
  '{".":"0.5.0"}' '{".":"0.5.0"}' - '{".":"0.5.0"}'

# 6. Single-version fallback for root when no stable manifest present.
run_case "single-version fallback for root" \
  '{".":"0.5.0-beta.5"}' - 0.5.0 '{".":"0.5.0"}'

# 7. Non-root key with no stable entry and no fallback: untouched.
run_case "non-root no stable entry untouched" \
  '{"packages/x":"1.0.0-beta.2"}' '{}' - '{"packages/x":"1.0.0-beta.2"}'

# 8. Mixed: one resets, one ahead stays.
run_case "mixed reset and ahead" \
  '{".":"0.5.0-beta.4","packages/api":"2.0.0-beta.1"}' \
  '{".":"0.5.0","packages/api":"1.9.0"}' - \
  '{".":"0.5.0","packages/api":"2.0.0-beta.1"}'

# 9. Empty stable-version + no stable manifest: must NOT write an empty string.
run_case "empty stable target no-op" \
  '{".":"0.5.0-beta.5"}' - - '{".":"0.5.0-beta.5"}'

# 10. JSON null dev value: skipped (no prerelease suffix), untouched.
run_case "null dev value untouched" \
  '{".":null}' '{".":"0.5.0"}' - '{".":null}'

# 11. Non-semver dev base: skipped, untouched.
run_case "non-semver dev base untouched" \
  '{".":"nightly-beta.1"}' '{".":"0.5.0"}' - '{".":"nightly-beta.1"}'

# 12. Idempotency: running again is a no-op.
dev="$TMP/idem.json"
printf '%s' '{".":"0.5.0-beta.5"}' > "$dev"
stable="$TMP/idem-stable.json"
printf '%s' '{".":"0.5.0"}' > "$stable"
bash "$SCRIPT" "$dev" "$stable" >/dev/null
first="$(jq -S -c . "$dev")"
bash "$SCRIPT" "$dev" "$stable" >/dev/null
second="$(jq -S -c . "$dev")"
if [[ "$first" == '{".":"0.5.0"}' && "$second" == "$first" ]]; then
  echo "ok   - idempotent"
  pass=$((pass + 1))
else
  echo "FAIL - idempotent (first=$first second=$second)"
  fail=$((fail + 1))
fi

echo ""
echo "passed: $pass  failed: $fail"
[[ "$fail" -eq 0 ]]
