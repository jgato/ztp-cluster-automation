# Remove ZTP cluster by name
The name of the cluster is provided by #$ARGUMENTS. Only one cluster can be removed per request.
Show a summary of the cluster to be removed.

Follow these steps:
0. Invoke the prepare_clusters command in the context of cluster preparation for removal
1. Check the provided name exists in the `kustomization.yaml` in the section resources.
2. Check this entry is not already commented. If it is commented, notify the user about it and do nothing
   and exit.
3. Comment the entry for the cluster. Pretty printout changes
4. Use git to create a new commit with a message "removing cluster " and the cluster name that has been removed
5. Do a git push over origin and main branch
6. Synch ArgoCD "clusters" application in the proper hub, pass the command the arguments: 1st one the hub endpoint, 2nd
   one the ArgoCD application that is called "clusters" by default.
7. Show the status of the cluster using the `visualize-cluster-status` subagent with adaptive check intervals until the
   ClusterInstance CR has been removed.

   ### Adaptive Monitoring Process:
   - Track elapsed removal time from when this monitoring step begins (after GitOps sync that triggers removal)
   - Use adaptive check intervals based on elapsed removal time:
     * **0-10 minutes** (Early phase: resource cleanup): Check every **5 minutes**
     * **10-30 minutes** (Middle phase: agent cleanup, BMH deprovisioning): Check every **15 minutes**
     * **30+ minutes** (Late phase: finalizers, stuck resources): Check every **5 minutes**

   - At each check interval:
     1. Invoke the Task tool with subagent_type="Explore" and prompt="visualize cluster status for <cluster-name>"
     2. Wait for the subagent to complete and return its result
     3. **IMMEDIATELY output the subagent's complete result to the user** - this is your ONLY response for this check
        - The subagent returns beautifully formatted ASCII tables and status information
        - DO NOT parse, interpret, or summarize this output
        - DO NOT say "The cluster is being removed" or similar - just show what the subagent returned
        - The subagent's formatted output IS your answer to the user
     4. After displaying the output:
        - Calculate elapsed removal time from when monitoring started
        - Check if the ClusterInstance CR still exists
        - If it shows "NOT DEPLOYED": the removal is complete, proceed to step 8
        - If it still exists: wait according to the adaptive interval schedule based on elapsed removal time and repeat

   - If the removal is taking too long, don't make any special extra checks. Just show the status and wait.
8. Exit command.

