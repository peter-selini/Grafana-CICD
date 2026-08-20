#!/usr/bin/env bash
# Validate everything under dashboards/ (run by CI on PRs and pushes to main).
#
# Handles both file formats in this repo:
#   - resource files: {apiVersion: dashboard.grafana.app/*, kind: Dashboard|Folder, metadata.name, spec}
#     (what Git Sync writes; folders are _folder.json)
#   - classic dashboard JSON (uid/id/panels at top level; accepted by Git Sync)
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "ERROR: $*" >&2; fail=1; }

# Angular panel types removed from recent Grafana
BANNED='graph|singlestat|table-old|flot'

declare -A seen_uids

mapfile -t files < <(find dashboards -name '*.json' | sort)
for f in "${files[@]}"; do
  if ! jq empty "$f" 2>/dev/null; then
    err "$f: invalid JSON"
    continue
  fi
  base=$(basename "$f" .json)
  kind=$(jq -r '.kind // empty' "$f")
  uid=""
  if [ -n "$(jq -r '.apiVersion // empty' "$f")" ]; then
    name=$(jq -r '.metadata.name // empty' "$f")
    [ -n "$name" ] || err "$f: resource file missing metadata.name"
    case "$kind" in
      Folder)
        [ "$(basename "$f")" = "_folder.json" ] || err "$f: Folder resource must be named _folder.json"
        [ -n "$(jq -r '.spec.title // empty' "$f")" ] || err "$f: folder missing spec.title"
        ;;
      Dashboard)
        # Git Sync's own exports are named by title slug, not uid — advisory only.
        [ "$base" = "$name" ] || echo "note: $f: filename differs from metadata.name '$name'"
        uid=$name
        ;;
      *) err "$f: unexpected kind '$kind'" ;;
    esac
  else
    uid=$(jq -r '.uid // empty' "$f")
    [ -n "$uid" ] || err "$f: classic dashboard missing uid"
    [ "$(jq -r '.id' "$f")" = "null" ] || err "$f: classic dashboard 'id' must be null"
    [ "$base" = "$uid" ] || err "$f: filename should match uid '$uid'"
  fi

  if [ -n "$uid" ]; then
    if [ -n "${seen_uids[$uid]:-}" ]; then
      err "$f: duplicate uid '$uid' (also in ${seen_uids[$uid]})"
    else
      seen_uids[$uid]=$f
    fi
  fi

  # Banned panel types: classic panels carry type+gridPos; v2 panels carry
  # the plugin id in spec.elements[].spec.vizConfig.group.
  banned_hits=$(jq -r --arg banned "$BANNED" '
      [ (.. | objects | select(has("type") and has("gridPos")) | .type),
        (.spec.elements? // {} | to_entries[]? | .value.spec.vizConfig.group // empty) ]
      | .[] | select(test("^(" + $banned + ")$"))' "$f" 2>/dev/null | sort -u)
  [ -z "$banned_hits" ] || err "$f: banned panel type(s): $(echo "$banned_hits" | tr '\n' ' ')"
done

# Secrets must never be committed (tokens come from CI secrets / environment).
if grep -rInE 'glsa_[A-Za-z0-9]{25,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----' \
    --include='*.json' --include='*.yml' --include='*.yaml' --include='*.sh' --include='*.md' .; then
  err "possible secret committed (see matches above)"
fi

if [ "$fail" -ne 0 ]; then
  echo "validation FAILED" >&2
  exit 1
fi
echo "validation OK (${#files[@]} files)"
