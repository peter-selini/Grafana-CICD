# scripts/

Export / validate / deploy tooling. Planned:

- `export.sh <uid>` — fetch a dashboard from Grafana, sanitize, write to `dashboards/`
- `validate.sh` — JSON parses, uid unique, `id` null, no banned panel types (run in CI on PRs)
- `deploy.sh [files...]` — upsert dashboards and alerting config to the target Grafana (run in CI on merge)

All scripts read `GRAFANA_URL` and `GRAFANA_TOKEN` from the environment — no credentials in this repo.
