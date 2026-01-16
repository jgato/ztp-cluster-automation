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
**Path:** `.claude/commands/configure_environment.md`

Configures the environment for ZTP operations by setting up KUBECONFIG and hub selection.

- **Arguments:** None (ignores any provided arguments)
- **Workflow:**
  1. Checks for KUBECONFIG environment variable or in context
  2. If found, verifies connectivity: `oc --kubeconfig="$KUBECONFIG" get --raw='/readyz'`
  3. If not found, prompts user to provide KUBECONFIG path
  4. Converts paths with `~` to absolute paths
  5. Prompts user to select target hub from available options
- **Result:** All subsequent `oc` commands use `--kubeconfig` parameter with the configured path

#### prepare_clusters
**Path:** `.claude/commands/prepare_clusters.md`

Prepares cluster pre-requirements before deployment or removal operations.

- **Arguments:** One or more cluster names (space-separated)
- **Context-aware behavior:**
  - **Deployment context:** Executes full preparation workflow
  - **Removal context:** Exits immediately and continues
- **Workflow (deployment only):**
  1. Uses configured KUBECONFIG with `--kubeconfig` parameter
  2. For each cluster:
     - Checks if namespace exists, creates if needed
     - Executes `prepare_ztp_cluster_pre_reqs.sh <cluster-name>`
     - Verifies two secrets were created:
       - `assisted-deployment-pull-secret` (pull secret)
       - `<clustername>-bmc-secret` (BMC credentials)
  3. Aborts entire process if any step fails

#### deploy_clusters
**Path:** `.claude/commands/deploy_clusters.md`

Complete GitOps workflow to deploy ZTP clusters.

- **Arguments:** One or more cluster names (space-separated)
- **Workflow:**
  1. Invokes `prepare_clusters` in deployment context
  2. Verifies ClusterInstance manifests exist for each cluster (YAML files with `kind: ClusterInstance`)
  3. Checks if clusters are already active in `kustomization.yaml` (uncommented entries)
     - If already active, notifies user and exits
  4. Adds or uncomments cluster entries in `kustomization.yaml`
  5. Creates git commit: `"adding clusters <cluster-names>"`
  6. Pushes to `origin/main`
  7. Invokes `synch_clusters` with hub endpoint and "clusters" application

#### remove_clusters
**Path:** `.claude/commands/remove_clusters.md`

Complete GitOps workflow to remove ZTP clusters.

- **Arguments:** One or more cluster names (space-separated)
- **Workflow:**
  1. Invokes `prepare_clusters` in removal context (exits immediately)
  2. Verifies cluster entries exist in `kustomization.yaml` resources section
  3. Checks if entries are already commented
     - If all already commented, notifies user and exits
  4. Comments out cluster entries in `kustomization.yaml`
  5. Creates git commit: `"removing clusters <cluster-names>"`
  6. Pushes to `origin/main`
  7. Invokes `synch_clusters` with hub endpoint, "clusters" application, and prune flag

#### synch_clusters
**Path:** `.claude/commands/synch_clusters.md`

Synchronizes an ArgoCD application on a specific hub instance.

- **Arguments:**
  - (Required) ArgoCD endpoint
  - (Required) ArgoCD application name
  - (Optional) Prune flag
- **Workflow:**
  1. Displays sync details (hub, application, prune status)
  2. Checks ArgoCD login status
     - If not logged in: executes `argocd login <endpoint> --insecure --sso`
  3. Refreshes application
  4. Syncs application:
     - Without prune: `argocd app sync <app> --insecure`
     - With prune: `argocd app sync <app> --insecure --prune`
  5. If pruning, monitors sync completion (timeout: 5 minutes)
- **Notes:**
  - All argocd commands use `--insecure` and `--grpc-web` parameters
  - SSO login opens interactive browser authentication

### Helper Scripts

#### prepare_ztp_cluster_pre_reqs.sh
**Path:** `.claude/commands/prepare_ztp_cluster_pre_reqs.sh`

Bash script that creates required Kubernetes secrets for ZTP cluster deployment.

- **Usage:** `./prepare_ztp_cluster_pre_reqs.sh <NAMESPACE>`
- **Requirements:**
  - KUBECONFIG environment variable must be set
  - `zenity` for GUI credential input
  - Pull secret at `~/.config/containers/auth.json`
- **Operations:**
  1. Creates `assisted-deployment-pull-secret`:
     - Source: `~/.config/containers/auth.json`
     - Type: Secret with `.dockerconfigjson` data
     - Namespace: `<NAMESPACE>`
  2. Prompts for BMC credentials via zenity forms dialog
  3. Creates `<NAMESPACE>-bmc-secret`:
     - Data: base64-encoded username and password
     - Type: Opaque
     - Namespace: `<NAMESPACE>`
- **Exit codes:**
  - 0: Success
  - 1: Missing namespace argument or user cancelled credential input

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

### Usage Notes

- All ArgoCD commands use `--insecure` and `--grpc-web` parameters
- All `oc` commands use `--kubeconfig <path>` parameter with configured KUBECONFIG
- GitOps operations follow the pattern: modify kustomization.yaml → commit → push → sync ArgoCD app
- Cluster operations are namespace-scoped (one namespace per cluster)
- Commands are context-aware and validate state before executing operations
- Failed operations abort immediately with explanatory messages
