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
8. Monitor cluster installation status by using the skill `visualize-cluster-status` every 5 minutes until the
   ManagedCluster CR status is available and joined.
   **CRITICAL: You MUST use ONLY the visualize-cluster-status skill to check status. DO NOT use direct oc commands.**
   **IMPORTANT: Wait for a MAXIMUM of 3 hours (180 minutes) for the cluster to become available.**
   - Track elapsed time from when monitoring starts
   - Every 5 minutes: Invoke the visualize-cluster-status skill with the cluster name
   - Check the skill output to determine if ManagedCluster is Available=True and Joined=True
   - If 3 hours is reached and cluster is NOT available and joined:
     * Abort the wait immediately
     * Use visualize-cluster-status skill one final time to show final cluster status
     * Notify user that deployment timeout was reached (3 hours)
     * Skip steps 9-10 (password and kubeconfig extraction)
     * Immediately invoke the redeploy_clusters command for this cluster
     * Exit the deploy command
9. Print out the kubeadmin password for the just created cluster. This is store in the namespace of the cluster, in a
   secret calle clustername-admin-password.
10. Extract the kubeconfig file for the just created cluster. This is stored in the namespace of the cluster, in a
    secret called 'clustername-admin-kubeconfig'.

    **IMPORTANT: Always use a cluster-specific temporary directory in the project root:**

    Execute these commands in order:
    ```bash
    # Create temporary directory for this cluster (safe if already exists)
    mkdir -p .tmp-<clustername>

    # Extract kubeconfig from secret and save to temp directory
    oc --kubeconfig $KUBECONFIG get secret <clustername>-admin-kubeconfig -n <clustername> \
      -o jsonpath='{.data.kubeconfig}' | base64 -d > .tmp-<clustername>/kubeconfig
    ```

    Confirm to user: "✅ Kubeconfig saved to: .tmp-<clustername>/kubeconfig"

    **Note:** Temporary directories follow the pattern `.tmp-<clustername>` and are gitignored.

11. command finished
