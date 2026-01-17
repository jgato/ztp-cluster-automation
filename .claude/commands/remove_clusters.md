# Remove ZTP clusters by name
The names of the clusters are provided by #$ARGUMENTS.
Show a summary on the clusters list.

Follow these steps:
0. Invoke the prepare_clusters command in the context of clusters preparation for removal
1. Check the provided names exists in the `kustomization.yaml` in the section resources.
2. Check these entries are not already commented. If all of them are commented. Notify the user about it and do nothing
   and exit.
3. Comment the entries for all the names of the clusters. Pretty printout changes
4. Use git to create a new commit with a message "removing clusters " and the clusters that has been removed
5. Do a git push over origin and main branch
6. Synch ArgoCD "clusters" application in the proper hub, pass the command the arguments: 1st one the hub endpoint, 2nd
   one the ArgoCD application that is called "clusters" by default.
7. show me the status of cluster using the skill `visualize-cluster-status` . Refresh the visualization information every 5 minutes. Until the
   ClusterInstance CR has been removed. If the removal is taking too long, dont make any special extra checks. Just show
   the status and wait.
8. Exist command.

