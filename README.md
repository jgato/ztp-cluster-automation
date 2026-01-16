# ZTP Cluster Automation with Claude Code

Automated Zero Touch Provisioning (ZTP) cluster lifecycle management using Claude Code, Red Hat Advanced Cluster Management (RHACM), and GitOps workflows.

---

**⚠️ DISCLAIMER**: This is **NOT** an official tool. This is a personal experiment and proof-of-concept for automating ZTP cluster operations using Claude Code. Use at your own risk.

---

## Overview

This project provides intelligent automation for managing OpenShift cluster deployments through ZTP using ClusterInstance CRs (Custom Resources). It leverages Claude Code's custom commands and skills to streamline cluster operations with GitOps best practices.

### Key Features

- **Automated Cluster Lifecycle**: Deploy, remove, and redeploy clusters with single commands
- **GitOps Integration**: Automatic git commits and ArgoCD synchronization
- **Real-time Monitoring**: Parallel data gathering for fast cluster status visualization
- **Secret Management**: Automatic backup and restoration of cluster credentials
- **Interactive Workflows**: Context-aware commands with pre-requirement validation
- **Comprehensive Status**: Detailed cluster state tracking across all ZTP resources

## Architecture

The automation integrates three key technologies:

- **RHACM Siteconfig Operator**: Provides ClusterInstance API for declarative cluster configuration
- **ArgoCD (OpenShift GitOps)**: Manages GitOps workflows and synchronization
- **Claude Code**: Provides intelligent automation through custom commands and skills

## Prerequisites

### Required Tools

- OpenShift CLI (`oc`) - v4.13+
- ArgoCD CLI (`argocd`) - v2.8+
- Git - v2.30+
- jq - v1.6+
- zenity - For GUI credential input (optional)

### Required Access

- Kubeconfig with access to RHACM hub cluster
- ArgoCD credentials for hub instance
- Git repository write access
- Pull secret from Red Hat (`~/.config/containers/auth.json`)

### Hub Endpoints

Configure your ArgoCD hub endpoint. The format typically follows:

```
openshift-gitops-server-openshift-gitops.apps.<hub-cluster-name>.<base-domain>
```

Example endpoints:
- **hub-prod**: `openshift-gitops-server-openshift-gitops.apps.hub-prod.example.com`
- **hub-dev**: `openshift-gitops-server-openshift-gitops.apps.hub-dev.example.com`

## Installation

### 1. Clone Repository

```bash
git clone <repository-url>
cd clusterinstance
```

### 2. Configure Environment

Set your KUBECONFIG and hub selection:

```bash
export KUBECONFIG=~/path/to/your/hub-kubeconfig
```

Or use the interactive configuration:

```bash
/configure_environment
```

### 3. Verify Setup

```bash
oc get clusterinstances --all-namespaces
argocd app list --server <your-hub-endpoint> --insecure --grpc-web
```

## Usage

### Available Commands

All commands are located in `.claude/commands/`:

#### `/configure_environment`
Configure KUBECONFIG and select target hub for operations.

```bash
/configure_environment
```

#### `/deploy_clusters`
Deploy one or more clusters via GitOps workflow.

```bash
/deploy_clusters vsno5
```

**Workflow:**
1. Validates cluster manifests exist
2. Creates namespace and required secrets
3. Uncomments/adds cluster in `kustomization.yaml`
4. Commits and pushes to git
5. Syncs ArgoCD application
6. Monitors deployment until ManagedCluster is Available & Joined
7. Extracts kubeadmin credentials

#### `/remove_clusters`
Remove one or more clusters via GitOps workflow.

```bash
/remove_clusters vsno5
```

**Workflow:**
1. Comments cluster entry in `kustomization.yaml`
2. Commits and pushes to git
3. Syncs ArgoCD application with `--prune` flag
4. Monitors removal until ClusterInstance is deleted

#### `/redeploy_clusters`
Complete cluster redeployment (remove + deploy).

```bash
/redeploy_clusters vsno5
```

**Workflow:**
1. Backs up cluster secrets
2. Removes cluster completely
3. Waits for full removal
4. Recreates namespace and restores secrets
5. Deploys cluster fresh
6. Extracts new credentials

#### `/prepare_clusters`
Prepare cluster pre-requirements (secrets and namespace).

```bash
/prepare_clusters vsno5
```

Creates:
- Namespace with cluster name
- `assisted-deployment-pull-secret` (from `~/.config/containers/auth.json`)
- `<clustername>-bmc-secret` (BMC credentials via zenity prompt)

#### `/synch_clusters`
Manually sync ArgoCD application.

```bash
/synch_clusters <hub-endpoint> <app-name> [prune]
```

Example:
```bash
/synch_clusters openshift-gitops-server-openshift-gitops.apps.hub-prod.example.com clusters prune
```

### Available Skills

#### `/visualize-cluster-status`
Display comprehensive cluster status with parallel data gathering.

```bash
/visualize-cluster-status vsno5
```

**Monitored Resources:**
- ClusterInstance (primary CR)
- BareMetalHost
- InfraEnv
- AgentClusterInstall
- Agents
- ManagedCluster


## Configuration

### Default Context

Configure your environment context using `/configure_environment` or by setting:

- **KUBECONFIG**: Path to your hub cluster kubeconfig
  Example: `~/kubeconfigs/hub-prod-kubeconfig`

- **ArgoCD Hub**: Your hub cluster name
  Example: `hub-prod`

- **ArgoCD Endpoint**: Your hub's ArgoCD server URL
  Example: `openshift-gitops-server-openshift-gitops.apps.hub-prod.example.com`

These settings are vital for ZTP operations and should match your target RHACM/ArgoCD hub cluster.

### Cluster Definitions

ClusterInstance manifests are YAML files in the root directory (e.g., `vsno5.yaml`).

To add a new cluster:
1. Create `<clustername>.yaml` with ClusterInstance CR
2. Add entry to `kustomization.yaml` resources section
3. Deploy using `/deploy_clusters <clustername>`

## Examples

### Deploy a New Cluster

```bash
# Configure environment
/configure_environment

# Deploy cluster
/deploy_clusters vsno5

# Wait for completion (automatic monitoring)
# Credentials are displayed when ready
```

### Check Cluster Status

```bash
/visualize-cluster-status vsno5
```

Output:
```
# 🎯 vsno5 | Status: ✅ INSTALLED | Duration: 25m

## ClusterInstance Status (Primary CR)
**Created:** 10:25Z | **Phase:** Deployed
- ✅ ClusterInstanceValidated - Validated
- ✅ RenderedTemplatesApplied - All manifests applied
- ✅ ClusterProvisioned - Provisioning complete

## Core Resources
+---------------------+--------+--------------------+----------------------+
| Resource            | Status | State/Info         | Details              |
+---------------------+--------+--------------------+----------------------+
| 📦 BareMetalHost    | ✅     | provisioned/det.   | Power: Off           |
| 💿 InfraEnv         | ✅     | Image ready        | Created: 10:15Z      |
| 🚀 AgentClusterInst | ✅     | adding-hosts       | Cluster is installed |
| 🎮 ManagedCluster   | ✅     | Available & Joined | Ready                |
+---------------------+--------+--------------------+----------------------+
```

### Redeploy Cluster (Full Lifecycle)

```bash
/redeploy_clusters vsno5
```

This performs a complete removal and fresh deployment with secret preservation.

### Access Deployed Cluster

After deployment completes:

```bash
# Use extracted kubeconfig
export KUBECONFIG=/tmp/kubeconfig-vsno5

# Or use kubeadmin password
oc login -u kubeadmin -p <password-from-output>

# Verify cluster
oc get nodes
oc get clusterversion
```


## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

```
Copyright 2026

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Authors

- Project maintained by: Jose Gato Luis <jgato@redhat.com>,<jgato.luis@gmail.com>
- Automation powered by: Claude Code (Anthropic)

