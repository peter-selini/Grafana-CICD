# alerting/

Grafana alerting resources in provisioning format:

- `rules/` — alert rule groups
- `contact-points/` — contact points
- `policies/` — notification policies

Deployed via the Grafana provisioning HTTP API (`/api/v1/provisioning/...`).
See [docs/workflow.md](../docs/workflow.md).
