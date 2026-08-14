# scripts/

Export / validate tooling. Deploys are **not** scripted — Grafana pulls this repo via Git Sync
(see `docs/workflow.md`).

- `export.sh <uid> [outdir]` — fetch a dashboard from Grafana via the v2 resource API,
  strip instance metadata, write `<uid>.json` in the Git Sync resource format
- `validate.sh` — JSON parses, uid present/unique, filenames match uids, no removed Angular
  panel types, no committed secrets (run in CI on PRs and pushes to `main`)

Scripts read `GRAFANA_URL` and `GRAFANA_TOKEN` (or `GRAFANA_API_KEY`) from the environment —
no credentials in this repo.
