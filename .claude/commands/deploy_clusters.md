# Deploy ZTP cluster by name
The name of the cluster is provided by #$ARGUMENTS. Only one cluster can be deployed per request.
Show a summary of the cluster to be deployed.

Follow these steps:
0. Invoke the prepare_clusters command in the context of cluster preparation for deployment
1. In the `kustomization.yaml`, check if this entry is already there and it is not commented. If so, notify the user about it and do nothing
   and exit.
2. Check the name of the cluster exists, and there is a manifest with this name, that contains a yaml with a Kind
   ClusterInstance
3. Call the command prepare_clusters to satisfy pre-requirements. This command will create a pull
   secret and the needed bmc credentials, to trigger the installation by the RHACM Assisted Service.
4. Add the entry for the cluster to the kustomization.yaml, or uncomment it if it was
   commented. Pretty printout changes
5. Use git to create a new commit with a message "adding cluster " and the cluster name that has been added
6. Do a git push over origin and main branch
7. Synch ArgoCD "clusters" application in the proper hub, pass the command the arguments: 1st one the hub endpoint, 2nd
   one the ArgoCD application that is called "clusters" by default.
8. Monitor cluster installation status by using the `visualize-cluster-status` subagent with adaptive check intervals until the
   ManagedCluster CR status is available and joined.
   **CRITICAL: You MUST use ONLY the visualize-cluster-status subagent to check status. DO NOT use direct oc commands.**
   **IMPORTANT: Wait for a MAXIMUM of 3 hours (180 minutes) for the cluster to become available.**

   ### Adaptive Monitoring Process:
   - Calculate elapsed time from the **ClusterInstance creation timestamp** (shown in subagent output as "Created:")
     * This gives accurate installation time, not just monitoring time
   - Use adaptive check intervals based on elapsed time since ClusterInstance creation:
     * **0-20 minutes** (Early phase: provisioning, agents): Check every **5 minutes**
     * **20-50 minutes** (Middle phase: ISO download, disk writing): Check every **15 minutes**
     * **50+ minutes** (Final phase: cluster configuration): Check every **5 minutes**

   - At each check interval:
     1. Invoke the Task tool with subagent_type="Explore" and prompt="visualize cluster status for <cluster-name>"
     2. Wait for the subagent to complete and return its result
     3. **IMMEDIATELY output the subagent's complete result to the user** - this is your ONLY response for this check
        - The subagent returns beautifully formatted ASCII tables and status information
        - DO NOT parse, interpret, or summarize this output
        - DO NOT say "The cluster is installing" or similar - just show what the subagent returned
        - The subagent's formatted output IS your answer to the user
     4. After displaying the output:
        - Extract the ClusterInstance "Created:" timestamp from the output
        - Calculate elapsed time from that creation timestamp to now
        - Check if ManagedCluster shows Available=True and Joined=True
        - If yes: proceed to step 9
        - If no: wait according to the adaptive interval schedule based on elapsed time and repeat

   - If 3 hours is reached and cluster is NOT available and joined:
     * Abort the wait immediately
     * Use visualize-cluster-status subagent one final time and display its output
     * Then notify user that deployment timeout was reached (3 hours)
     * Skip steps 9-10 (password and kubeconfig extraction)
     * Immediately invoke the redeploy_clusters command for this cluster
     * Exit the deploy command
9. Extract and save the kubeadmin password for the just created cluster. This is stored in the namespace of the cluster, in a
   secret called 'clustername-admin-password'.

   **IMPORTANT:** Create a temporary directory following the pattern `.tmp-<clustername>` in the project root (use `mkdir -p` to ensure it exists). The temporal directory is never created out
   of the project scope.
   Extract the password from the secret and save it to `.tmp-<clustername>/kubeadmin-password`.
   Display the password to the user and confirm the file location.
10. Extract the kubeconfig file for the just created cluster. This is stored in the namespace of the cluster, in a
    secret called 'clustername-admin-kubeconfig'.

    Extract the kubeconfig from the secret and save it to `.tmp-<clustername>/kubeconfig`.
    Confirm to the user the file location.

11. command finished
