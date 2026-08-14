# CLAUDE.md

Guidance for AI coding agents working in this repository.

## What this repo is

Source of truth for Grafana dashboards and alerting configuration, targeting **Grafana v13**. Dashboards are stored as JSON and deployed by **Grafana Git Sync** (folderless target): Grafana polls `main` and applies `dashboards/` to the instance. CI only validates.

## Layout

- `dashboards/<grafana-folder>/<dashboard>.json` — the directory tree mirrors the Grafana UI folder tree. One dashboard per file. Files at the top level of `dashboards/` are General/root dashboards.
- `dashboards/<grafana-folder>/_folder.json` — folder metadata (kind: Folder) pinning the folder's stable uid and title. Don't delete these.
- `alerting/` — alert rules, contact points, notification policies (provisioning YAML/JSON).
- `scripts/` — export/import/deploy tooling.
- `docs/` — conventions and workflow. **Read `docs/dashboard-conventions.md` before creating or editing any dashboard JSON.**

## Rules for editing dashboards

1. **Never hardcode datasource UIDs.** Reference datasources through a template variable or a stable, documented UID (see `docs/dashboard-conventions.md`).
2. **Strip instance-specific noise before committing** exported JSON. Resource files (`apiVersion: dashboard.grafana.app/...`) keep only `metadata.name` in `metadata`; classic files need top-level `id: null` and no `version`/`iteration`/`meta` blocks. The uid (`metadata.name` / `uid`) is the stable identity — keep it.
3. **File name matches the dashboard uid** (`<uid>.json`). Never two dashboards with the same uid in the repo.
4. Dashboard JSON is the deliverable, not generated output — edit it directly, keep diffs minimal, and don't reformat whole files (2-space indent, keys in the order Grafana exports them).
5. When adding a new Grafana folder, create the matching directory under `dashboards/` with a `_folder.json`. Top-level `*.json` files in `dashboards/` are General-folder dashboards (allowed — folderless sync).
6. **Never add a file whose uid matches a dashboard that exists unmanaged in Grafana** — sync errors on the conflict; takeover goes through a migrate job (`docs/gitsync-migration.md`).
7. Validate before committing: `./scripts/validate.sh` (CI runs it on every PR).

## Grafana v13 notes

- v13 supports both the classic dashboard JSON schema (`schemaVersion` ~41+) and the v2 resource schema (`apiVersion: dashboard.grafana.app/v2...`). This repo uses the **v2 resource wrapper** (what Git Sync writes; see `docs/dashboard-conventions.md`); classic-schema files are accepted but get rewritten to v2 when saved from the Grafana UI.
- Angular-based panels are removed in recent Grafana — do not introduce panel types like `graph` (old); use `timeseries`, `stat`, `table`, etc.

## What not to do

- Don't commit secrets (API tokens, datasource credentials). Deploy credentials come from CI secrets / environment, never files here.
- Don't edit anything under `dashboards/` and deploy manually without going through the documented workflow in `docs/workflow.md`.
