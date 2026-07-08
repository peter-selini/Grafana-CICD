# Dashboard conventions

Rules for dashboard JSON committed to this repo (Grafana v13, classic schema).

## Identity

- `uid` is the stable identity — deploys upsert by `uid`. Pick a short, readable, permanent uid when creating a dashboard (e.g. `trading-pnl-overview`). Never change it after deployment, and never duplicate one across files.
- Top-level `id` must be `null` (it's instance-local and meaningless across environments).
- File name: `<uid>.json`, placed under `dashboards/<grafana-folder>/`.

## Sanitizing exports

When exporting from the Grafana UI (Share → Export → *Export for sharing externally* off, since we keep real datasource refs), before committing:

- Set `"id": null`
- Remove `"version"` (Grafana manages it; keeping it causes pointless diffs)
- Remove any `"meta"` wrapper if the export came from the HTTP API (`/api/dashboards/uid/...` returns `{meta, dashboard}` — commit only the `dashboard` object)
- Reset `time` to a sensible default (e.g. `now-6h` to `now`) rather than whatever was on screen
- Remove ad-hoc `templating` variable *values* that were session state, keep the variable definitions

## Datasources

- Reference datasources by stable UID, and define the UIDs once per environment. Prefer a dashboard variable of type `datasource` when a dashboard should work against multiple datasources.
- Document every datasource UID this repo depends on here:

| UID | Type | Purpose |
| --- | ---- | ------- |
| _(add as used)_ | | |

## Panels

- Use current panel types only: `timeseries`, `stat`, `table`, `bargauge`, `gauge`, `heatmap`, `piechart`, `logs`, `text`. No removed Angular panels (`graph`, `singlestat`, old `table-old`).
- Give every panel a title; give queries `refId`s in order (A, B, C…).
- Prefer `$__interval`/`$__rate_interval` over hardcoded group-by intervals in queries.

## Variables

- Kebab-case or camelCase names, no spaces.
- Every variable should have a sane default (`current`) so the dashboard renders on first open.

## Formatting

- 2-space indentation, UTF-8, trailing newline.
- Don't reorder keys or reformat untouched sections — keep diffs reviewable.
- Validate before committing: `jq . dashboards/**/*.json > /dev/null`.
