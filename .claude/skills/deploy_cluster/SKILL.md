---
name: deploy_cluster
description: Complete GitOps workflow to deploy a ZTP cluster
allowed-tools: Bash(.claude/skills/deploy_cluster/scripts/*:*), Bash(git:*), Bash(sleep:*), Skill(sync_argocd), Skill(visualize_cluster_status)
---

# Deploy ZTP Cluster

Deploy a single ZTP cluster via GitOps. Cluster name from $ARGUMENTS.

## PARENT WORKFLOW - Execute ALL steps 1-7

After each step completes, mark current todo completed, mark next in_progress, and immediately proceed. Do NOT stop when a child skill returns.

## Steps

### 1. Pre-validate

```bash
.claude/skills/deploy_cluster/scripts/pre-validate.sh <cluster-name> <kubeconfig-path>
```

| Exit code | Meaning | Action |
|-----------|---------|--------|
| 0 | Preconditions met | Continue to step 2 |
| 3 | Already active in kustomization.yaml | Notify user and EXIT |
| 2, 4, 5 | Missing kustomization/manifests | Report error and EXIT |

Parse output: `ENTRY_STATUS` tells whether step 3 should `add` or `uncomment`.

### 2. Prepare secrets

```bash
.claude/skills/deploy_cluster/scripts/prepare_ztp_cluster_pre_reqs.sh <cluster-name> <kubeconfig-path>
```

The script handles credentials automatically:
- If both secrets already exist in the cluster (e.g. restored by a redeploy), it skips creation (`SECRETS_SOURCE=existing`)
- Otherwise, it creates the pull secret from `~/.config/containers/auth.json` and opens a zenity dialog for BMC credentials (`SECRETS_SOURCE=new`)

| Exit code | Meaning | Action |
|-----------|---------|--------|
| 0 | Secrets ready | Continue to step 3 |
| 2 | auth.json not found | Report error and EXIT |
| 3-5 | Secret creation/verification failed | Report error and EXIT |

### 3. Update kustomization.yaml

Based on `ENTRY_STATUS` from step 1:
- If `commented`: uncomment the cluster entry in kustomization.yaml
- If `missing`: add `  - <cluster-name>/` to the resources section

Show the change made (before/after).

### 4. Git commit and push

Commit kustomization.yaml with message `"adding cluster <cluster-name>"` and push to origin main.

### 5. Sync ArgoCD

Invoke `/sync_argocd` with arguments: hub endpoint, `"clusters"` as application name.

**CRITICAL: The sync is a mid-workflow step, NOT the end of this skill. When the sync command finishes, you MUST continue to step 6 in the SAME response. Do NOT stop, do NOT wait for user input, do NOT treat the sync completion as a stopping point.**

### 6. Monitor installation

**CRITICAL: Use ONLY `/visualize_cluster_status` skill. NO direct oc commands. NO extra investigation.**

**Maximum wait: 3 hours (180 minutes)**

Adaptive check intervals based on elapsed time:
- **0-20 min**: check every 5 minutes (`sleep 300`)
- **20-50 min**: check every 15 minutes (`sleep 900`)
- **50+ min**: check every 5 minutes (`sleep 300`)

At each check:
1. Invoke `/visualize_cluster_status` for the cluster
2. Display the complete result verbatim (don't summarize)
3. If ManagedCluster shows Available=True AND Joined=True: proceed to step 7
4. Otherwise: sleep the appropriate interval and repeat

On 3-hour timeout: show final status, notify user, and EXIT.

### 7. Extract credentials and report

```bash
.claude/skills/deploy_cluster/scripts/extract-credentials.sh <cluster-name> <kubeconfig-path>
```

Display the kubeadmin password and file locations from output. Report deployment complete.
