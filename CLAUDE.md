# ClusterInstances dir/repository


## Project Overview

This directory contains a set of different ClusterInstance CRs to manage your infrastructure.
These CRs are part of an Openshift/Kubernetes API that you learn more [here](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.14/html/multicluster_engine_operator_with_red_hat_advanced_cluster_management/siteconfig-intro). The API is proveded by the RHACM Siteconfig Operator.

There is a `kustomization.yaml` that is used by Openshift GitOps operator (that is basically ArgoCD), to do
the different GitOps tasks. Adding/removing entries to the `kustomization.yaml` to manage your existing
infrastructure with the GitOps way.

## ArgoCD interaction

The ArgoCD endpoint is automatically configured by the `configure_environment` skill, which extracts it from the `openshift-gitops-server` Route in the `openshift-gitops` namespace.

All ArgoCD commands should use `--insecure` and `--grpc-web` parameters.

## Openshift interaction

**CRITICAL:** All `oc` commands MUST use the `--kubeconfig` parameter as the FIRST parameter immediately after `oc`.

The value for the param is coming from the kubeconfig path from an env variable or from the context.

**Correct format:** `oc --kubeconfig <path> <VERB> <arguments>`
**Example:** `oc --kubeconfig /path/to/kubeconfig get pods -n namespace`

## Claude commands and scripts

The `.claude/commands/` directory contains custom commands and scripts to automate ZTP cluster management tasks. These commands are integrated with Claude Code to streamline GitOps operations.

### Available Skills

Skills are located in `.claude/skills/<skill-name>/SKILL.md`.

#### configure_environment
Configures the environment for ZTP operations by setting up KUBECONFIG and automatically extracting the ArgoCD endpoint from the cluster.
- **Arguments:** None
- **Location:** `.claude/skills/configure_environment/`

#### sync_argocd
Synchronizes an ArgoCD application on a hub instance using SSO authentication.
- **Arguments:** ArgoCD endpoint, application name, optional prune flag
- **Location:** `.claude/skills/sync_argocd/`

#### deploy_cluster
Complete GitOps workflow to deploy a ZTP cluster. Prepares cluster, updates kustomization.yaml, commits, pushes, and syncs ArgoCD.
- **Arguments:** Single cluster name (one cluster per request)
- **Location:** `.claude/skills/deploy_cluster/`

### Available Commands

#### remove_clusters
Complete GitOps workflow to remove a ZTP cluster. Comments out entry in kustomization.yaml, commits, pushes, and syncs with prune.
- **Arguments:** Single cluster name (one cluster per request)

#### redeploy_clusters
Complete workflow to redeploy a ZTP cluster. Removes cluster, waits for cleanup, restores secrets, and redeploys.
- **Arguments:** Single cluster name (one cluster per request)

### Subagents

#### visualize-cluster-status
This subagent is key and it's always used to show the current status of any cluster, in any moment, or during installation,
or removal, etc.
Displays comprehensive status of ZTP/RHACM clusters including ClusterInstance, installation progress, agents, and related resources.
- **Type:** Specialized read-only subagent with restricted permissions
- **Triggers:** "show cluster status", "check cluster", "monitor cluster", "cluster installation progress"
- **Scripts:** Uses `get-cluster-status.sh` for one-time checks or `monitor-cluster.sh` for continuous monitoring
- **Location:** `.claude/agents/visualize-cluster-status/`

#### telco-hub-rds-status
This subagent displays comprehensive status of Telco Hub RDS clusters configured via GitOps.
Shows operator versions and CR statuses with parallel data collection for maximum performance.
- **Type:** Specialized read-only subagent with restricted permissions
- **Triggers:** "show hub status", "check hub", "telco hub status", "hub rds status"
- **Scripts:** Uses `get-operator-versions.sh` and `get-cr-statuses.sh` in parallel
- **Location:** `.claude/agents/telco-hub-rds-status/`

### Helper Scripts

#### prepare_ztp_cluster_pre_reqs.sh
Creates required Kubernetes secrets for ZTP cluster deployment (pull-secret and BMC credentials).
- **Location:** `.claude/skills/deploy_cluster/scripts/prepare_ztp_cluster_pre_reqs.sh`
- **Usage:** `./prepare_ztp_cluster_pre_reqs.sh <NAMESPACE> <KUBECONFIG>`

#### get-operator-versions.sh
Collects operator versions in parallel for Telco Hub RDS (ACM, TALM, GitOps). Outputs JSON files.
- **Usage:** `./get-operator-versions.sh <kubeconfig-path> [output-dir]`

#### get-cr-statuses.sh
Collects CR statuses in parallel for Telco Hub RDS (MultiClusterHub, MultiClusterEngine, MultiClusterObservability, AgentServiceConfig).
- **Usage:** `./get-cr-statuses.sh <kubeconfig-path> [output-dir]`

#### check_cluster_kubeconfig.sh
Checks KUBECONFIG variable and verifies OpenShift connectivity. Expands `~` to absolute path.
- **Location:** `.claude/skills/configure_environment/scripts/check_cluster_kubeconfig.sh`
- **Exit codes:** 0 (success), 1 (KUBECONFIG not set), 2 (cluster unreachable)

#### Visualize Cluster Status Scripts
Located in `.claude/agents/visualize-cluster-status/scripts/`:
- **get-cluster-status.sh** - One-time status check with parallel data gathering
- **monitor-cluster.sh** - Continuous monitoring for installation progress
- **collect-resource-data.sh** - Low-level data collection utility


### Usage Notes
- **CRITICAL: All cluster operations accept ONLY ONE cluster per request. Never attempt to process multiple clusters in a single command invocation.**
- When executing any script never use `cd` command to move to the directory of the script. Execute including the path
- When executing script never call with env variables as prefix
- **CRITICAL: All `oc` commands MUST have `--kubeconfig <path>` as the FIRST parameter immediately after `oc`**
  - The configured KUBECONFIG exists in the context or as an env variable
  - **Correct format:** `oc --kubeconfig <path> <VERB> <arguments>`
  - **NEVER use:** `oc get --kubeconfig <path>` or `oc <VERB> --kubeconfig <path>`
- GitOps operations follow the pattern: modify kustomization.yaml → commit → push → sync ArgoCD app
- Cluster operations are namespace-scoped (one namespace per cluster)

