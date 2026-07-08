# Workflow

How dashboards move between this repo and Grafana.

## Environments

| Environment | Grafana URL | Notes |
| ----------- | ----------- | ----- |
| _(fill in)_ | | |

Deploy credentials are provided via environment variables / CI secrets (e.g. `GRAFANA_URL`, `GRAFANA_TOKEN` — a service account token with dashboard write scope). Never commit tokens.

## Pulling a dashboard into the repo (export)

1. Fetch by uid: `GET $GRAFANA_URL/api/dashboards/uid/<uid>` (or export from the UI).
2. Keep only the `dashboard` object from the API response.
3. Sanitize per [dashboard-conventions.md](dashboard-conventions.md) (null `id`, drop `version`, etc.).
4. Save to `dashboards/<grafana-folder>/<uid>.json`, review the diff, commit.

## Pushing to Grafana (deploy)

Upsert by uid: `POST $GRAFANA_URL/api/dashboards/db` with body

```json
{
  "dashboard": { ...file contents... },
  "folderUid": "<folder-uid>",
  "overwrite": true,
  "message": "<git commit sha>"
}
```

The target `folderUid` is derived from the file's directory under `dashboards/` (mapping maintained in the deploy script).

## CI/CD

Intended pipeline (implement in `scripts/` + CI config):

1. **Validate** on every PR — JSON parses, `uid` present and unique, `id` is null, no banned panel types, no secrets.
2. **Deploy** on merge to `main` — push changed dashboard files to the target Grafana, and changed alerting files via the provisioning API.

Manual one-off deploys should still go through the same script so behavior stays identical.

## Alerting

Alert rules, contact points, and notification policies live in `alerting/` in Grafana provisioning format and deploy via the provisioning HTTP API (`/api/v1/provisioning/...`). Same export → sanitize → commit → deploy loop applies.
