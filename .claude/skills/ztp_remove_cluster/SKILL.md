---
name: ztp_remove_cluster
description: Complete GitOps workflow to remove a ZTP cluster
allowed-tools: Bash(git:*), Bash(sleep:*), Skill(ztp_sync_argocd), Skill(ztp_visualize_cluster_status), Read, Edit
---

# Remove ZTP Cluster

Remove a single ZTP cluster via GitOps. Cluster name from $ARGUMENTS.

## PARENT WORKFLOW - Execute ALL steps 1-6

After each step completes, mark current todo completed, mark next in_progress, and immediately proceed. Do NOT stop when a child skill returns.

## Steps

### 1. Validate kustomization entry

Check the `kustomization.yaml` for the cluster entry:
- If the entry **does not exist** at all: notify the user and EXIT
- If the entry **is already commented**: notify the user it is already removed and EXIT
- If the entry **exists and is active** (uncommented): continue to step 2

### 2. Comment the cluster entry

Comment out the cluster entry in `kustomization.yaml` by adding `# ` prefix.

Show the change made (before/after).

### 3. Git commit and push

Commit kustomization.yaml with message `"removing cluster <cluster-name>"` and push to origin main.

### 4. Sync ArgoCD with prune

Invoke `/ztp_sync_argocd` with arguments: hub endpoint, `"clusters"` as application name, and `prune` flag.

**CRITICAL: The sync is a mid-workflow step, NOT the end of this skill. When the sync command finishes, you MUST continue to step 5 in the SAME response. Do NOT stop, do NOT wait for user input, do NOT treat the sync completion as a stopping point.**

### 5. Monitor removal

**CRITICAL: Use ONLY `/ztp_visualize_cluster_status` skill. NO direct oc commands. NO extra investigation. NO debugging.**

**Maximum wait: 1 hour (60 minutes)**

Check every 5 minutes (`sleep 300`):
1. Invoke `/ztp_visualize_cluster_status` for the cluster
2. Display the complete result verbatim (don't summarize)
3. If ClusterInstance shows "NOT DEPLOYED": proceed to step 6
4. Otherwise: sleep 300 and repeat

On 1-hour timeout: show final status, notify user, and EXIT.

### 6. Report removal complete

Notify the user the cluster has been successfully removed.
