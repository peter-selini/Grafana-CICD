# Git Sync folderless migration runbook

One-time migration of every dashboard on `selini-grafana-v13.selini.tech:3000` to Git Sync
management from this repo (branch `main`, path `dashboards/`, sync target `folderless`).

Planned 2026-08. Requires: Grafana ≥ 13.1.0 (folderless target + selective migrate job),
a service account token with **Admin** (temporarily), GitHub App connection `cafriapc93435se`.

## Exclusions

- **Alerts reduction** (`ffnxhybru8we8d`, folder Peter) stays UI-owned. It is excluded from the
  migrate job's resource list; with no file in git, Git Sync's unmanaged-resource protection
  leaves it alone (folderless repositories skip all cleanup of unmanaged resources).
- **Shared with me** (`sharedwithme`) — pseudo-folder, not a real resource.
- Empty folders (no dashboards) are not migrated and stay unmanaged: Haowei, Matt B, Rahul,
  SRS, Evan, Daniel, Kyle, NGI/scratch.

## Why a migrate job (not pre-committed files)

Git Sync cannot adopt an existing unmanaged dashboard from a repo file — sync errors on the
uid conflict. The migrate job is the built-in non-destructive takeover: it exports unmanaged
dashboards to git (Grafana authors the commit), allowlists exactly those uids, then pulls and
adopts them in place. Originals are never deleted. `generateNewFolderIDs: false` preserves
existing folder UIDs, so folder permissions and links survive.

## Pre-flight (done)

1. Full classic-API backup of all 299 dashboards → `/tmp/grafana-migration/backup/classic/`
   on the machine running the migration (plus v2 exports in `v2clean/` for post-migration diff).
2. Folder/dashboard manifest → `/tmp/grafana-migration/{folders,dashboards}.json`.
3. This tooling PR merged; `validate` workflow green on `main`.
4. Warn dashboard owners: after migration, UI saves round-trip through git (branch workflow).

## Steps

`B=$GRAFANA_URL/apis/provisioning.grafana.app/v0alpha1/namespaces/default`

1. **Delete the pilot repository** `rpmg5dc` (folder target — target cannot be changed in place):
   `DELETE $B/repositories/rpmg5dc`
   The `cleanup` finalizer removes its 2 managed dashboards and the wrapper folder
   `peter-selini/Grafana-CICD`; they are recreated from git by the first folderless sync.
2. **Create the folderless repository**:
   `POST $B/repositories` with

   ```json
   {
     "apiVersion": "provisioning.grafana.app/v0alpha1",
     "kind": "Repository",
     "metadata": {"generateName": "rp"},
     "spec": {
       "title": "peter-selini/Grafana-CICD",
       "type": "github",
       "github": {"url": "https://github.com/peter-selini/Grafana-CICD", "branch": "main", "path": "dashboards/"},
       "connection": {"name": "cafriapc93435se"},
       "workflows": ["branch"],
       "sync": {"enabled": true, "target": "folderless", "intervalSeconds": 60}
     }
   }
   ```
3. **Wait for the first sync** to go green (`GET $B/repositories/<name>` → `status.sync`).
   It recreates the two recon dashboards from `dashboards/Peter/` and creates `uiserver-usage`.
4. **Run the selective migrate job**:
   `POST $B/repositories/<name>/jobs` with body built from the manifest —

   ```json
   {"spec": {"action": "migrate", "migrate": {"generateNewFolderIDs": false, "resources": [
     {"name": "<uid>", "kind": "Dashboard", "group": "dashboard.grafana.app"}, ...
   ]}}}
   ```

   listing every unmanaged dashboard uid **except** `ffnxhybru8we8d`.
5. **Poll job status** (`GET $B/repositories/<name>/jobs`) until `success`/`warning`.
6. **Verify**:
   - repo `status.stats` ≈ 299 dashboards + folders;
   - spot-check `grafana.app/managedBy: repo` annotations on migrated dashboards;
   - `ffnxhybru8we8d` still has no manager annotation and no file in git;
   - `git pull` and diff Grafana-authored files against `/tmp/grafana-migration/v2clean/`;
   - folder UIDs unchanged (`_folder.json` files match the manifest);
   - `validate` workflow green on the Grafana-authored commit.
7. **Post**: drop the service account back to Editor; update `docs/workflow.md` env table if
   the repository name changed.

## Rollback

- Single dashboard: re-import from `/tmp/grafana-migration/backup/classic/<uid>.json` via
  `POST /api/dashboards/db` (or from git history).
- Whole migration: **remove the repository's finalizers before deleting it** — orphaned
  resources revert to unmanaged (they keep working, just UI-owned again). Deleting *with* the
  `cleanup` finalizer would instead delete every managed dashboard — do not do that as rollback.
