# ClusterInstances dir/repository

## Welcome Message

**IMPORTANT:** At the start of each new conversation session, you MUST:
1. Display a brief welcome message explaining this is a ZTP (Zero Touch Provisioning) cluster automation project using GitOps
2. Check and display the current environment status:
   - Execute `check_cluster_kubeconfig.sh` to verify KUBECONFIG is set and accessible
   - Display the KUBECONFIG path if set (from environment variable)
   - Indicate which hub is currently configured (if detectable from context)
3. If KUBECONFIG is not set or cluster is unreachable, strongly suggest running `/configure_environment` to set up the environment
4. Provide a brief reminder that all cluster operations (deploy, remove, redeploy) accept ONLY ONE cluster per request

## Project Overview

This directory contains a set of different ClusterInstance CRs to manage your infrastructure.
These CRs are part of an Openshift/Kubernetes API that you learn more [here](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.14/html/multicluster_engine_operator_with_red_hat_advanced_cluster_management/siteconfig-intro). The API is proveded by the RHACM Siteconfig Operator.

There is a `kustomization.yaml` that is used by Openshift GitOps operator (that is basically ArgoCD), to do
the different GitOps tasks. Adding/removing entries to the `kustomization.yaml` to manage your existing
infrastructure with the GitOps way.

## ArgoCD instances

During the GitOps tasks, these would be done over different ArgoCD instances, installed
in the different RHACM hubs.

### Hub Configuration File

**IMPORTANT:** Users should create a file named `ARGOCD_HUBS.md` in the project root directory to configure available ArgoCD hub instances. This file is **optional** but highly recommended as it helps the automation tools display default available hubs and their endpoints.

**Example ARGOCD_HUBS.md structure:**

```markdown
# ArgoCD Hub Instances

This file defines the available ArgoCD/OpenShift GitOps instances for this ZTP environment.

## Available Hubs

- **hub-1**
  - Endpoint: openshift-gitops-server-openshift-gitops.apps.hub-1.example.com
  - Description: Primary production hub

- **hub-2**
  - Endpoint: openshift-gitops-server-openshift-gitops.apps.hub-2.example.com
  - Description: Secondary production hub

- **multinode-1**
  - Endpoint: openshift-gitops-server-openshift-gitops.apps.multinode-1.example.com
  - Description: Multi-node test environment

## Usage

These endpoints are used with the ArgoCD CLI for GitOps operations.
All ArgoCD commands should use `--insecure` and `--grpc-web` parameters.
```

**Note:** If `ARGOCD_HUBS.md` exists, automation tools will parse it to provide hub selection options and default values. If the file doesn't exist, users will need to manually specify hub endpoints.

Use these endpoints together with the argocd cli to interact with the proper GitOps server.
ArgoCD cli always use the --insecure param to access the endpoint witn a self-signed certificate

## Openshift interaction

**CRITICAL:** All `oc` commands MUST use the `--kubeconfig` parameter as the FIRST parameter immediately after `oc`.

The value for the param is coming from the kubeconfig path from an env variable or from the context.

**Correct format:** `oc --kubeconfig <path> <VERB> <arguments>`
**Example:** `oc --kubeconfig /path/to/kubeconfig get pods -n namespace`

## Claude commands and scripts

The `.claude/commands/` directory contains custom commands and scripts to automate ZTP cluster management tasks. These commands are integrated with Claude Code to streamline GitOps operations.

### Available Commands

#### configure_environment
Configures the environment for ZTP operations by setting up KUBECONFIG and hub selection.
- **Arguments:** None

#### prepare_clusters
Prepares cluster pre-requirements before deployment. Creates namespace and required secrets (pull-secret and BMC credentials).
- **Arguments:** Single cluster name (one cluster per request)
- **Note:** In removal context, exits immediately

#### deploy_clusters
Complete GitOps workflow to deploy a ZTP cluster. Prepares cluster, updates kustomization.yaml, commits, pushes, and syncs ArgoCD.
- **Arguments:** Single cluster name (one cluster per request)

#### remove_clusters
Complete GitOps workflow to remove a ZTP cluster. Comments out entry in kustomization.yaml, commits, pushes, and syncs with prune.
- **Arguments:** Single cluster name (one cluster per request)

#### synch_clusters
Synchronizes an ArgoCD application on a specific hub instance using SSO authentication.
- **Arguments:** ArgoCD endpoint, application name, optional prune flag

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
- **Usage:** `./prepare_ztp_cluster_pre_reqs.sh <NAMESPACE>`

#### get-operator-versions.sh
Collects operator versions in parallel for Telco Hub RDS (ACM, TALM, GitOps). Outputs JSON files.
- **Usage:** `./get-operator-versions.sh <kubeconfig-path> [output-dir]`

#### get-cr-statuses.sh
Collects CR statuses in parallel for Telco Hub RDS (MultiClusterHub, MultiClusterEngine, MultiClusterObservability, AgentServiceConfig).
- **Usage:** `./get-cr-statuses.sh <kubeconfig-path> [output-dir]`

#### check_cluster_kubeconfig.sh
Checks KUBECONFIG variable and verifies OpenShift connectivity. Expands `~` to absolute path.
- **Location:** `.claude/commands/scripts/check_cluster_kubeconfig.sh`
- **Exit codes:** 0 (success), 1 (KUBECONFIG not set), 2 (cluster unreachable)

#### Visualize Cluster Status Scripts
Located in `.claude/agents/visualize-cluster-status/scripts/`:
- **get-cluster-status.sh** - One-time status check with parallel data gathering
- **monitor-cluster.sh** - Continuous monitoring for installation progress
- **collect-resource-data.sh** - Low-level data collection utility

### Command Workflow Examples

**Deploying a cluster:**
```bash
# 1. Configure environment
/configure_environment
# 2. Deploy cluster (includes preparation)
/deploy_clusters vsno5
```

**Removing a cluster:**
```bash
# 1. Ensure environment is configured
# 2. Remove cluster
/remove_clusters vsno5
```

**Manual sync:**
```bash
/synch_clusters
# Will prompt for application and prune option
```

**Redeploying a cluster:**
```bash
/redeploy_clusters multinode-1
```

**Checking hub status:**
```bash
/telco_hub_rds_status hub-2
```

**Monitoring cluster installation:**
```bash
/visualize-cluster-status vsno5
```

### Usage Notes

- **CRITICAL: All cluster operations accept ONLY ONE cluster per request. Never attempt to process multiple clusters in a single command invocation.**
- When executing any script never use `cd` command to move to the directory of the script. Execute including the path
- When executing script never call with env variables as prefix
- All ArgoCD commands use `--insecure` and `--grpc-web` parameters
- **CRITICAL: All `oc` commands MUST have `--kubeconfig <path>` as the FIRST parameter immediately after `oc`**
  - The configured KUBECONFIG exists in the context or as an env variable
  - **Correct format:** `oc --kubeconfig <path> <VERB> <arguments>`
  - **NEVER use:** `oc get --kubeconfig <path>` or `oc <VERB> --kubeconfig <path>`
- GitOps operations follow the pattern: modify kustomization.yaml → commit → push → sync ArgoCD app
- Cluster operations are namespace-scoped (one namespace per cluster)
- Commands are context-aware and validate state before executing operations
- Failed operations abort immediately with explanatory messages
