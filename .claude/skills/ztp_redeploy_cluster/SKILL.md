---
name: ztp_redeploy_cluster
description: Complete workflow to redeploy a ZTP cluster with secret preservation
allowed-tools: Bash(mkdir:*), Bash(oc --kubeconfig *), Bash(sleep:*), Skill(ztp_remove_cluster), Skill(ztp_deploy_cluster)
---

# Redeploy ZTP Cluster

Remove and redeploy a single ZTP cluster while preserving secrets. Cluster name from $ARGUMENTS.

## PARENT WORKFLOW - Execute ALL steps 1-7

After each step completes, mark current todo completed, mark next in_progress, and immediately proceed. Do NOT stop when a child skill returns.

## Steps

### 1. Backup secrets

Create directory `.temp/redeploy-<cluster-name>/` and save both secrets from the cluster namespace:

```bash
mkdir -p .temp/redeploy-<cluster-name>
oc --kubeconfig <path> get secret assisted-deployment-pull-secret -n <cluster-name> -o yaml > .temp/redeploy-<cluster-name>/assisted-deployment-pull-secret.yaml
oc --kubeconfig <path> get secret <cluster-name>-bmc-secret -n <cluster-name> -o yaml > .temp/redeploy-<cluster-name>/<cluster-name>-bmc-secret.yaml
```

If either secret does not exist, report the error and EXIT.

### 2. Remove cluster

Invoke `/ztp_remove_cluster` with the cluster name.

When the remove skill completes, immediately continue to step 3. If it exits with an error, report and EXIT.

### 3. Monitor removal

**CRITICAL: Use ONLY `/ztp_visualize_cluster_status` skill. NO direct oc commands. NO extra investigation.**

Verify the cluster is fully removed before proceeding:
1. Invoke `/ztp_visualize_cluster_status` for the cluster
2. If ClusterInstance shows "NOT DEPLOYED": proceed to step 4
3. Otherwise: `sleep 300` and repeat

### 4. Ensure namespace exists

After removal, the namespace may have been deleted. If namespace `<cluster-name>` does not exist, create it:

```bash
oc --kubeconfig <path> create namespace <cluster-name>
```

### 5. Restore secrets from backup

Restore both secrets into the namespace from the backup files:

```bash
oc --kubeconfig <path> apply -f .temp/redeploy-<cluster-name>/assisted-deployment-pull-secret.yaml
oc --kubeconfig <path> apply -f .temp/redeploy-<cluster-name>/<cluster-name>-bmc-secret.yaml
```

### 6. Deploy cluster

Invoke `/ztp_deploy_cluster` with the cluster name.

The secrets are already in place. The `ztp_deploy_cluster` prepare script will verify they exist and continue without asking for credentials.

When the deploy skill completes successfully, immediately continue to step 7. If it exits with an error, report and EXIT.

### 7. Report redeployment complete

Notify the user the cluster has been successfully redeployed.
