---
name: remove_cluster
description: Complete GitOps workflow to remove a ZTP cluster
allowed-tools: Bash(git:*), Read, Edit, Skill(sync_argocd), Skill(visualize_cluster_status)
model: sonnet
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

7. Monitor cluster removal status by using the `visualize_cluster_status` skill.
   **CRITICAL: You MUST use ONLY the visualize-cluster-status skill to check status. DO NOT use direct oc commands.NEVER try to investigate what could be happening. NEVER do extra task if there are errors during the removal process**
   ### Monitoring Process:
   - Check every **5 minutes**:
     1. Show cluster status
     2. Wait for the skill to complete and return its result
     3. **IMMEDIATELY output the skill's complete result to the user** - this is your ONLY response for this check
     4. After displaying the output, check if the ClusterInstance CR still exists
        - If it shows "NOT DEPLOYED": the removal is complete, proceed to step 8
        - If it still exists: wait 5 minutes and repeat
   - If the removal is taking too long, don't make any special extra checks. Just show the status and wait.

8. Exit command.
