---
name: configure_environment
description: Configure environment for ZTP operations by setting up KUBECONFIG and hub selection
allowed-tools: Bash(.claude/skills/configure_environment/scripts/check_cluster_kubeconfig.sh:*), Bash( oc --kubeconfig:** get route:*)
model: haiku
---

# Configure environment for ZTP

Configure environment for GitOps operations over clusters.

## Arguments

Takes one required argument: **KUBECONFIG** path (absolute path, no `~`)

If argument is missing or uses `~`, return **1** with usage instructions.

## Return Codes

- **0**: Success. Environment configured.
- **1**: Error. Missing argument, file not found, or connectivity failed.

## Steps

1. Validate argument:
   - If no KUBECONFIG argument provided: return **1** with message "Usage: configure_environment <kubeconfig-path>"
   - If path contains `~`: return **1** with message "Use absolute path, not ~"

2. Check file exists:
   - If file does not exist: return **1** with message "File not found: <path>"

3. Check connectivity using script:
   - Execute `.claude/skills/configure_environment/scripts/check_cluster_kubeconfig.sh <KUBECONFIG>`
   - If script exits with code != 0: return **1** with message "Cluster not reachable with provided kubeconfig"

4. Get ArgoCD endpoint:
   ```
   oc --kubeconfig <KUBECONFIG> get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'
   ```

5. Return **0**. Environment is configured.