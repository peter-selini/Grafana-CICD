# CLAUDE.md

Guidance for AI coding agents working in this repository.

## What this repo is

Source of truth for Grafana dashboards and alerting configuration, targeting **Grafana v13**. Dashboards are stored as JSON and deployed to Grafana via CI/CD (API push or Git Sync).

## Layout

- `dashboards/<grafana-folder>/<dashboard>.json` — the directory tree mirrors the Grafana UI folder tree. One dashboard per file.
- `alerting/` — alert rules, contact points, notification policies (provisioning YAML/JSON).
- `scripts/` — export/import/deploy tooling.
- `docs/` — conventions and workflow. **Read `docs/dashboard-conventions.md` before creating or editing any dashboard JSON.**

## Rules for editing dashboards

1. **Never hardcode datasource UIDs.** Reference datasources through a template variable or a stable, documented UID (see `docs/dashboard-conventions.md`).
2. **Strip instance-specific noise before committing** exported JSON: top-level `id` must be `null`, remove `version`, `iteration`, and `meta` blocks. Keep the `uid` — it is the stable identity used for upserts.
3. **File name matches the dashboard `uid`** where practical (`<uid>.json`), or a kebab-case slug of the title. Never two dashboards with the same `uid` in the repo.
4. Dashboard JSON is the deliverable, not generated output — edit it directly, keep diffs minimal, and don't reformat whole files (2-space indent, keys in the order Grafana exports them).
5. When adding a new Grafana folder, create the matching directory under `dashboards/` — don't put dashboards at the top level of `dashboards/`.
6. Validate JSON before committing: `python3 -m json.tool < file.json > /dev/null` or `jq . file.json > /dev/null`.

## Grafana v13 notes

- v13 supports both the classic dashboard JSON schema (`schemaVersion` ~41+) and the v2 resource schema (`apiVersion: dashboard.grafana.app/v2...`). This repo uses the **classic schema** unless a dashboard file says otherwise.
- Angular-based panels are removed in recent Grafana — do not introduce panel types like `graph` (old); use `timeseries`, `stat`, `table`, etc.

## What not to do

- Don't commit secrets (API tokens, datasource credentials). Deploy credentials come from CI secrets / environment, never files here.
- Don't edit anything under `dashboards/` and deploy manually without going through the documented workflow in `docs/workflow.md`.
