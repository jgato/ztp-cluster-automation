# ClusterInstances dir/repository

This directory contains a set of different ClusterInstance CRs to manage your infrastructure.
These CRs are part of an Openshift/Kubernetes API that you learn more [here](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.14/html/multicluster_engine_operator_with_red_hat_advanced_cluster_management/siteconfig-intro). The API is proveded by the RHACM Siteconfig Operator.

There is a `kustomization.yaml` that is used by Openshift GitOps operator (that is basically ArgoCD), to do
the different GitOps tasks. Adding/removing entries to the `kustomization.yaml` to manage your existing
infrastructure with the GitOps way.

## ArgoCD instances

During the GitOps tasks, these would be done over different ArgoCD instances, installed
in the different RHACM hubs.

By the moment we have:
 * hub-2: openshift-gitops-server-openshift-gitops.apps.hub-2.el8k.se-lab.eng.rdu2.dc.redhat.com
 * hub-1: openshift-gitops-server-openshift-gitops.apps.hub-2.el8k.se-lab.eng.rdu2.dc.redhat.com
 * multinode-1: openshift-gitops-server-openshift-gitops.apps.multinode-1.spoke-mno.el8k.se-lab.eng.rdu2.dc.redhat.com/

Use these endpoint together with the argocd cli to interact with the proper GitOps server
ArgoCD cli always use the --insecure param to access the endpoint witn a self-signed certificate

## Openshift interaction

Whatever interaction with an `oc` command will use the `--kubeconfig` param. The value for the param is comming from the
kubeconfig path from an env variable or from the context.

## Claude commands and scripts

The `.claude/commands/` directory contains custom commands and scripts to automate ZTP cluster management tasks. These commands are integrated with Claude Code to streamline GitOps operations.

### Available Commands

#### configure_environment
Configures the environment for ZTP operations by setting up KUBECONFIG and hub selection.
- **Arguments:** None

#### prepare_clusters
Prepares cluster pre-requirements before deployment. Creates namespaces and required secrets (pull-secret and BMC credentials).
- **Arguments:** One or more cluster names (space-separated)
- **Note:** In removal context, exits immediately

#### deploy_clusters
Complete GitOps workflow to deploy ZTP clusters. Prepares clusters, updates kustomization.yaml, commits, pushes, and syncs ArgoCD.
- **Arguments:** One or more cluster names (space-separated)

#### remove_clusters
Complete GitOps workflow to remove ZTP clusters. Comments out entries in kustomization.yaml, commits, pushes, and syncs with prune.
- **Arguments:** One or more cluster names (space-separated)

#### synch_clusters
Synchronizes an ArgoCD application on a specific hub instance using SSO authentication.
- **Arguments:** ArgoCD endpoint, application name, optional prune flag

#### redeploy_clusters
Complete workflow to redeploy a ZTP cluster. Removes cluster, waits for cleanup, restores secrets, and redeploys.
- **Arguments:** Single cluster name (one at a time)

#### telco_hub_rds_status
Displays comprehensive status of a Telco Hub RDS cluster including operator versions and CR statuses.
- **Arguments:** Cluster name

### Skills

#### visualize-cluster-status
This skill is key and it always used to show the current status of any cluster, in any moment, or during installation,
or removal, etc.
Displays comprehensive status of ZTP/RHACM clusters including ClusterInstance, installation progress, agents, and related resources.
- **Triggers:** "show cluster status", "check cluster", "monitor cluster", "cluster installation progress"
- **Scripts:** Uses `get-cluster-status.sh` for one-time checks or `monitor-cluster.sh` for continuous monitoring

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
Located in `.claude/skills/visualize-cluster-status/`:
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

- When executing and script never use `cd` command to move to the directory of the script. Execute including the path
- All ArgoCD commands use `--insecure` and `--grpc-web` parameters
- All `oc` commands use `--kubeconfig <path>` parameter with configured KUBECONFIG. The configured KUBECONFIG exists in
  the context or as an env variable
- GitOps operations follow the pattern: modify kustomization.yaml → commit → push → sync ArgoCD app
- Cluster operations are namespace-scoped (one namespace per cluster)
- Commands are context-aware and validate state before executing operations
- Failed operations abort immediately with explanatory messages
