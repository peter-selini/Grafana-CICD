# Workflow

How dashboards move between this repo and Grafana.

## Environments

| Environment | Grafana URL | Notes |
| ----------- | ----------- | ----- |
| selini-grafana-v13 | http://selini-grafana-v13.selini.tech:3000 | Grafana 13.1.0, on-prem. Git Sync repository `rpcfxr6` → this repo, branch `main`, path `dashboards/`, target `folderless`, 60s interval |

Script credentials are provided via environment variables (`GRAFANA_URL`, `GRAFANA_TOKEN` — a service account token). Never commit tokens. Git Sync itself authenticates through Grafana's GitHub App connection, so no Grafana credential lives in GitHub.

## How changes flow

Dashboards are **deployed by Grafana Git Sync**, not pushed by CI: Grafana polls `main` every
60 s and applies changes under `dashboards/` to the instance (folderless target — top-level
directories are top-level Grafana folders, files at the path root are General/root dashboards).

- **Edit in git**: branch → PR → `validate` workflow green → merge → Grafana picks it up within a minute.
- **Edit in the Grafana UI**: managed dashboards use the *branch workflow* — the UI save
  pushes a branch to this repo instead of writing to the database. From there it's
  hands-off: `auto-pr.yml` opens the PR for bot-pushed branches, and PRs touching **only
  `dashboards/`** get auto-merge enabled (squash, branch deleted), landing once the
  `validate` check passes. The "Open pull request in GitHub" link Grafana shows can be
  ignored. Requires: "Allow auto-merge" in repo settings, `validate` as a required status
  check on `main`. PRs touching anything outside `dashboards/` need a human merge
  (human-opened dashboard-only PRs are auto-merged too, via `auto-merge.yml`).
- One-time takeover of pre-existing dashboards: see [gitsync-migration.md](gitsync-migration.md).

## Pulling a dashboard into the repo (export)

For a dashboard not yet managed (or a manual re-export):

1. `scripts/export.sh <uid> <dir>` — fetches via the v2 resource API and strips instance metadata.
2. Save under `dashboards/<grafana-folder>/<uid>.json`, review the diff, commit.

Note: adding a file for a dashboard that already exists **unmanaged** in Grafana will make sync
error on the uid conflict — that takeover needs a migrate job (see the migration runbook).

## CI/CD

1. **Validate** on every PR and on pushes to `main` (including Grafana-authored Git Sync
   commits) — JSON parses, uid present and unique, filenames match uids, no removed Angular
   panel types, no secrets. Implemented in `scripts/validate.sh` + `.github/workflows/validate.yml`.
2. **Deploy** — Git Sync pull, no CI step. Emergency manual upserts via
   `POST $GRAFANA_URL/api/dashboards/db` still work but will be overwritten by the next sync
   if the file in git differs.

## Alerting

Alert rules, contact points, and notification policies live in `alerting/` in Grafana provisioning format and deploy via the provisioning HTTP API (`/api/v1/provisioning/...`). Same export → sanitize → commit → deploy loop applies.
