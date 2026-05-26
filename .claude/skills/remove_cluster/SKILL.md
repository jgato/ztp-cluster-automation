---
name: remove_cluster
description: Complete GitOps workflow to remove a ZTP cluster
---

# Remove ZTP cluster by name

The name of the cluster is provided by $ARGUMENTS. Only one cluster can be removed per request.
Show a summary of the cluster to be removed.

## THIS IS A PARENT WORKFLOW

**You MUST execute ALL steps 1-8. Do NOT stop when a skill/sub-command/sub-agent completes.**

After any skill/sub-command/sub-agent completes, I must immediately check my todo list:
  - Mark the current todo as completed
  - Mark the next todo as in_progress
  - Immediately execute the next step

## Steps

1. Check the provided name exists in the `kustomization.yaml` in the section resources.

2. Check this entry is not already commented. If it is commented, notify the user about it and do nothing and exit.

3. Comment the entry for the cluster. Pretty printout changes.

4. Use git to create a new commit with a message "removing cluster " and the cluster name that has been removed.

5. Do a git push over origin and main branch.

6. Use the skill `sync_argocd` to sync the "clusters" application in the proper hub. Pass the arguments: 1st one the hub endpoint, 2nd
   one the ArgoCD application that is called "clusters" by default.

7. Monitor cluster removal status using `visualize_cluster_status` skill.
   
   **CRITICAL: Use ONLY visualize_cluster_status skill. NO direct oc commands. NO extra investigation.**
   
   Loop until removal complete:
   a. Call `visualize_cluster_status` skill for the cluster
   b. Output the skill's complete result to the user
   c. Check if ClusterInstance shows "NOT DEPLOYED"
      - If "NOT DEPLOYED": removal complete, proceed to step 8
      - If still exists: run `sleep 300` (5 minutes, foreground, NOT background) then repeat from (a)
   d. Never analyze, debug or do whatever other extra action. Just wait.

8. Exit command.
