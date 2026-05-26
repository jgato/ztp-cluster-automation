---
name: configure_environment
description: Configure environment for ZTP operations by setting up KUBECONFIG and hub selection
allowed-tools: Bash(.claude/skills/configure_environment/scripts/*:*), Bash(oc --kubeconfig *), Bash(argocd:*)
---

# Configure Environment for ZTP

Configure the environment for GitOps operations over clusters. Takes one required argument from $ARGUMENTS: the KUBECONFIG path (absolute path, no `~`).

## Return Codes

- **0**: Success. Environment configured.
- **1**: Error. Missing argument, file not found, or connectivity failed.

## Steps

### 1. Validate argument

- If no argument provided: return **1** with message "Usage: configure_environment <kubeconfig-path>"
- If path contains `~`: return **1** with message "Use absolute path, not ~"
- If file does not exist: return **1** with message "File not found: <path>"

### 2. Check cluster connectivity

```bash
.claude/skills/configure_environment/scripts/check_cluster_kubeconfig.sh <kubeconfig-path>
```

If exit code != 0: return **1** with message "Cluster not reachable with provided kubeconfig".

### 3. Extract ArgoCD endpoint

```bash
oc --kubeconfig <kubeconfig-path> get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'
```

Store the result as the ArgoCD endpoint for use by other skills.

### 4. Authenticate ArgoCD

Check if already logged in. If not, authenticate via SSO:

```bash
argocd login <endpoint> --sso --insecure --grpc-web
```

### 5. Report success

Return **0**. Environment is configured.
