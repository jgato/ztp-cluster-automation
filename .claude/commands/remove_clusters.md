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
7. Show the status of the cluster using the skill `visualize-cluster-status`. Refresh the visualization information every 5 minutes until the
   ClusterInstance CR has been removed. If the removal is taking too long, don't make any special extra checks. Just show
   the status and wait.
8. Exit command.

