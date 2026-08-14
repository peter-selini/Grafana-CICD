#!/usr/bin/env bash
# Export one dashboard from Grafana as a Git Sync-style resource file.
#
# Usage: GRAFANA_URL=... GRAFANA_TOKEN=... scripts/export.sh <dashboard-uid> [output-dir]
#
# Writes <output-dir>/<uid>.json in the dashboard.grafana.app/v2 resource
# format (what Git Sync itself writes), with instance metadata stripped.
set -euo pipefail

DASH_UID=${1:?usage: export.sh <dashboard-uid> [output-dir]}
OUTDIR=${2:-.}
: "${GRAFANA_URL:?set GRAFANA_URL (e.g. http://selini-grafana-v13.selini.tech:3000)}"
TOKEN=${GRAFANA_TOKEN:-${GRAFANA_API_KEY:-}}
[ -n "$TOKEN" ] || { echo "set GRAFANA_TOKEN (service account token)" >&2; exit 1; }

curl -fsS -H "Authorization: Bearer $TOKEN" \
  "$GRAFANA_URL/apis/dashboard.grafana.app/v2/namespaces/default/dashboards/$DASH_UID" \
  | jq '{apiVersion: "dashboard.grafana.app/v2", kind, metadata: {name: .metadata.name}, spec}' \
  > "$OUTDIR/$DASH_UID.json"

echo "wrote $OUTDIR/$DASH_UID.json"
