# Prepare ZTP cluster
Some pre-requirements before deploying a new cluster.
It takes #$ARGUMENTS with a SINGLE cluster name. Only one cluster can be prepared per request.

Following steps only if we are in the context of cluster deployment (including if in the context of a cluster
redeployment).
1. The following steps implies to use the Openshift client to create some CRs. The Openshift command has to be invoked
   with the --kubeconfig param pointing to the selected kubeconfig.
2. Check if there is a Namespace created with the name of the cluster to be prepared. If not, create it.
3. Invoke the script `.claude/commands/scripts/prepare_ztp_cluster_pre_reqs.sh` and pass the name of the cluster.
4. Check that in the Namespace with the name of the cluster, there have been created two secrets. One of them a Secret
   called `assisted-deployment-pull-secret`, and the other a Secret with a name that is the result of concatenating
   clustername-bmc-secret
5. If any of the steps fails, abort the process and explain why.
6. if everything went oka, exit this prepare_clusters command immediately and return control to the calling command

If we are in the context of cluster removal do the following steps:
1. Do nothing - no preparation is needed for cluster removal
2. Exit this prepare_clusters command immediately and return control to the calling command
3. The calling command will continue with its next step
