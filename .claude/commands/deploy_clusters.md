# Deploy ZTP clusters by name
The names of the clusters are provided by #$ARGUMENTS.
Show a summary on the clusters list.

Follow these steps:
0. Invoke the prepare_clusters command in the context of clusters preparation for deployment
1. In the `kustomization.yaml` , check if these entries are already there and they are not commented. If so, notify the user about it and do nothing
   and exit.
2. Check the names of the clusters exists, and there is a manifest with these names, that contains a yaml with a Kind
   Clusterinstane
3. For every cluster call the command prepare_clusters to satisfy pre-requirements. This command will create a pull
   secret and the need it bmc credentials, to trigger the installtion by the RHACM Assisted Service.
4. Add the entries for all the names of the clusters, to the kustomization.yaml, or uncomment them if they were
   commented. Pretty printout changes
5. Use git to create a new commit with a message "adding clusters " and the clusters that has been removed
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
    secret called 'clustername-admin-kubeconfig'. Copy the kubeconfig on a local tmp directory, on a file called wit the name
    'kubeconfig-clustername'
11. command finished
