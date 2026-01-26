---
name: deploy_cluster
description: Complete GitOps workflow to deploy a ZTP cluster
allowed-tools: Bash(git:*), Bash(oc --kubeconfig get secret:*), Bash(.claude/skills/deploy_cluster/scripts/prepare_ztp_cluster_pre_reqs.sh:*), Skill(sync_argocd),Read, Edit
model: sonnet
---

# Deploy ZTP cluster by name

The name of the cluster is provided by $ARGUMENTS. Only one cluster can be deployed per request.
Show a summary of the cluster to be deployed.

## THIS IS A PARENT WORKFLOW

**You MUST execute ALL steps 1-11. Do NOT stop when a skill/sub-command/sub-agent completes.**

After any skill/sub-command/sub-agent completes, I must immediately check my todo list:
  - Mark the current todo as completed
  - Mark the next todo as in_progress
  - Immediately execute the next step

## Steps

1. In the `kustomization.yaml`, check if this entry is already there and not commented. If so, notify the user and finish this workflow.

2. Check the cluster manifest exists and contains a ClusterInstance Kind.

3. Gather secret information to inject for the cluster creation:
   - Check the Namespace with the clustername exists. If not, create it.
   - Invoke script `.claude/skills/deploy_cluster/scripts/prepare_ztp_cluster_pre_reqs.sh <clustername> <kubeconfig>`.
   - Verify two secrets exist in the cluster namespace:
      - `assisted-deployment-pull-secret`
      - `<clustername>-bmc-secret`

4. Add/uncomment the cluster entry in kustomization.yaml. Pretty printout changes.

5. Git commit with message "adding cluster <clustername>".

6. Git push to origin main.

7. Use the skill `/sync_argocd` to sync argocd application. Use the params: hub endpoint and "clusters" as application name. When finishes continue to next step.

8. Monitor installation using `visualize-cluster-status` skill until ManagedCluster is available and joined.

   **CRITICAL: Use ONLY the visualize-cluster-status subagent. DO NOT use direct oc commands.NEVER try to investigate what could be happening. NEVER do extra task if there are errors during the installation process**

   **Maximum wait: 3 hours (180 minutes)**

   Adaptive check intervals based on elapsed time from ClusterInstance creation:
   - **0-20 min**: Check every 5 minutes
   - **20-50 min**: Check every 15 minutes
   - **50+ min**: Check every 5 minutes

   At each check:
   - Invoke skill for cluster status
   - Output the skill's complete result directly (don't summarize)
   - Check if ManagedCluster shows Available=True and Joined=True
   - If yes: proceed to step 9
   - If no: wait and repeat

   On 3-hour timeout:
   - Show final status, notify user of timeout
   - Skip steps 9-10, invoke `/redeploy_cluster` and exit

9. Extract kubeadmin password from secret `<clustername>-admin-password` in cluster namespace.
   Save to `.temp/deploy-cluster-<clustername>/kubeadmin-password`. Display password and file location.

10. Extract kubeconfig from secret `<clustername>-admin-kubeconfig` in cluster namespace.
    Save to `.temp/deploy-cluster-/kubeconfig`. Confirm file location.

11. Report deployment complete.
