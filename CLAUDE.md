# ZTP Cluster Automation

## Project Overview

This repository manages OpenShift cluster infrastructure via GitOps using ClusterInstance CRs from the [RHACM Siteconfig Operator](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.14/html/multicluster_engine_operator_with_red_hat_advanced_cluster_management/siteconfig-intro). A `kustomization.yaml` drives OpenShift GitOps (ArgoCD) to reconcile cluster state. Adding or removing entries in `kustomization.yaml` triggers cluster lifecycle operations.

## Conventions

### OpenShift commands

All `oc` commands MUST use `--kubeconfig` as the FIRST parameter after `oc`.

- **Correct:** `oc --kubeconfig <path> get pods -n namespace`
- **Wrong:** `oc get --kubeconfig <path> pods`
- **Wrong:** `oc get pods --kubeconfig <path>`

The kubeconfig path comes from the environment variable or the context set by `ztp_configure_environment`.

### ArgoCD commands

All ArgoCD commands use `--insecure` and `--grpc-web`. The endpoint is auto-configured by the `ztp_configure_environment` skill from the `openshift-gitops-server` Route.

### Script execution

- Use relative paths from project root: `.claude/skills/ztp_deploy_cluster/scripts/script.sh`
- Never `cd` to the script directory
- Never export KUBECONFIG before calling a script (pass it as a parameter)
- Never prefix script calls with environment variables

### Cluster operations

- One cluster per request. Never process multiple clusters in a single skill invocation.
- Each cluster has its own namespace matching the cluster name.
- Cluster manifests are YAML files in the project root (e.g., `sno1.yaml`) containing `kind: ClusterInstance`.
- GitOps pattern: modify `kustomization.yaml` -> commit -> push -> sync ArgoCD -> monitor

### Temporal directories and files

All temporary data goes under `.temp/` in the project root (git-ignored, never committed).

**Naming pattern:** `.temp/<skill-name>-<cluster-name>/`

| Directory | Purpose |
|-----------|---------|
| `.temp/deploy-cluster-<name>/` | Deployed cluster credentials (kubeadmin password, kubeconfig) |
| `.temp/redeploy-<name>/` | Backed-up secrets during redeploy |
| `.temp/visualize-cluster-status-<name>/` | Status data collection (transient) |
| `.temp/telco-hub-rds-status-<name>/` | Hub status data (transient) |

- Scripts create their dirs via `mkdir -p`
- Transient data is cleaned up via `trap "rm -rf $TMPDIR" EXIT`
- Persistent data (credentials, backups) is NOT auto-cleaned

## Skills

All skills are in `.claude/skills/<skill-name>/SKILL.md`. Scripts are in `.claude/skills/<skill-name>/scripts/`.

### ztp_configure_environment

Sets up the environment for all ZTP operations. Must be run first in any session.

- **Args:** `<kubeconfig-path>` (absolute path, no `~`)
- **What it does:** Validates kubeconfig, checks cluster connectivity, extracts ArgoCD endpoint from the `openshift-gitops-server` Route, and authenticates ArgoCD via SSO.
- **Return codes:** 0 (success), 1 (error)

### ztp_deploy_cluster

Complete GitOps workflow to deploy a ZTP cluster. Parent workflow with 7 steps.

- **Args:** `<cluster-name>` (single cluster only)
- **What it does:** Pre-validates manifests and kustomization state, creates namespace and secrets (from backup or fresh via zenity), updates kustomization.yaml, commits and pushes, syncs ArgoCD, monitors installation up to 3 hours, and extracts cluster credentials on success.
- **Scripts:** `pre-validate.sh`, `prepare_ztp_cluster_pre_reqs.sh`, `extract-credentials.sh`
- **Calls:** `ztp_sync_argocd`, `ztp_visualize_cluster_status`

### ztp_remove_cluster

Complete GitOps workflow to remove a ZTP cluster. Parent workflow with 8 steps.

- **Args:** `<cluster-name>` (single cluster only)
- **What it does:** Verifies cluster exists in kustomization.yaml and is not already commented, comments the entry, commits and pushes, syncs ArgoCD with prune, monitors removal until ClusterInstance shows "NOT DEPLOYED" (5-minute check intervals).
- **Calls:** `ztp_sync_argocd`, `ztp_visualize_cluster_status`

### ztp_redeploy_cluster

Complete workflow to remove and redeploy a cluster while preserving secrets. Parent workflow with 7 steps.

- **Args:** `<cluster-name>` (single cluster only)
- **What it does:** Backs up `assisted-deployment-pull-secret` and `<cluster>-bmc-secret` to `.temp/redeploy-<name>/`, invokes `ztp_remove_cluster`, waits for removal, recreates namespace and restores secrets if needed, then invokes `ztp_deploy_cluster`.
- **Calls:** `ztp_remove_cluster`, `ztp_deploy_cluster`

### ztp_sync_argocd

Synchronizes an ArgoCD application. Simple child skill.

- **Args:** `<endpoint> <app-name> [prune]`
- **Model:** haiku (cost-optimized)
- **What it does:** Refreshes and syncs the named ArgoCD application. If prune flag is set, syncs with `--prune` and waits up to 5 minutes for completion.

### ztp_visualize_cluster_status

Displays comprehensive status of a ZTP cluster. Read-only child skill.

- **Args:** `<cluster-name>`
- **Model:** haiku (cost-optimized)
- **What it does:** Runs `get-cluster-status.sh` for parallel data collection of ClusterInstance, BareMetalHost, InfraEnv, AgentClusterInstall, Agents, and ManagedCluster. Formats output as ANSI-colored ASCII tables with status icons.
- **Scripts:** `get-cluster-status.sh`, `collect-resource-data.sh`, `monitor-cluster.sh`

### ztp_telco_hub_status

Displays status of Telco Hub RDS operators and CRs. Read-only skill.

- **Args:** none
- **What it does:** Verifies hub cluster context and ArgoCD `hub-config` app sync status. Collects operator versions (ACM, TALM, GitOps) and CR statuses (MultiClusterHub, MultiClusterEngine, MultiClusterObservability, AgentServiceConfig) in parallel. Formats as ASCII tables.
- **Scripts:** `get-operator-versions.sh`, `get-cr-statuses.sh`

## Workflows

### Deploy a new cluster

```
User: ztp_configure_environment /path/to/kubeconfig
User: ztp_deploy_cluster sno1
```

Flow: `ztp_configure_environment` -> `ztp_deploy_cluster` -> `pre-validate.sh` -> `prepare_ztp_cluster_pre_reqs.sh` -> edit kustomization.yaml -> git commit/push -> `ztp_sync_argocd` -> monitor via `ztp_visualize_cluster_status` (up to 3h) -> `extract-credentials.sh`

### Remove a cluster

```
User: ztp_configure_environment /path/to/kubeconfig
User: ztp_remove_cluster sno1
```

Flow: `ztp_configure_environment` -> `ztp_remove_cluster` -> comment kustomization.yaml -> git commit/push -> `ztp_sync_argocd` (with prune) -> monitor via `ztp_visualize_cluster_status` until NOT DEPLOYED

### Redeploy a cluster

```
User: ztp_configure_environment /path/to/kubeconfig
User: ztp_redeploy_cluster sno1
```

Flow: `ztp_configure_environment` -> `ztp_redeploy_cluster` -> backup secrets -> `ztp_remove_cluster` (full removal flow) -> restore namespace + secrets -> `ztp_deploy_cluster` (full deploy flow)

The redeploy workflow preserves BMC and pull-secret credentials so the user does not need to re-enter them. The `ztp_deploy_cluster` script detects backed-up secrets in `.temp/redeploy-<name>/` and restores them automatically instead of opening the zenity dialog.

### Check cluster status

```
User: show me the status of sno1
```

Triggers `ztp_visualize_cluster_status` which runs parallel data collection and displays a formatted status report.

### Check hub status

```
User: show hub status
```

Triggers `ztp_telco_hub_status` which collects operator versions and CR statuses in parallel and displays formatted tables.
