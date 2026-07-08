# Grafana-CICD

Version-controlled Grafana dashboards and alerting config (Grafana v13), deployed via CI/CD.

## Layout

```
dashboards/    Dashboard JSON, one subfolder per Grafana folder
alerting/      Alert rules, contact points, notification policies
scripts/       Export / import / deploy tooling
docs/          Conventions and workflow docs (also used by AI agents)
CLAUDE.md      Instructions for AI coding agents
```

## Quick start

- Dashboards live under `dashboards/<grafana-folder>/<dashboard>.json`. The path mirrors the folder structure in the Grafana UI.
- Before committing an exported dashboard, sanitize it — see [docs/dashboard-conventions.md](docs/dashboard-conventions.md).
- Deployment workflow: see [docs/workflow.md](docs/workflow.md).
