# Prepare ZTP clusters
Some pre-requirements before deploying new clusters
It takes #$ARGUMENTS, with different names of clusters to be deployed.

Following steps only if we are in the context of clusters deployement (including if in the context of a clusters
redeployment).
4. The following steps implies to use the Openshift client to create some CRs. The Openshift command has to be invoked
   with the --kubeconfig param pointing to the selected kubeconfig.
5. check if there is a Namespace created with the name of the different clusters to be prepared their pre-requirements.
   If not, create them.
6. for every cluster: invoke the script `.claude/commands/skills/prepare_ztp_cluster_pre_reqs.sh` and pass the name of the cluster. The script
   exists on the same directory than this commando. So, it is not needed it to find it.
7. check that in the Namespace with the name of the cluster, there has been created two secrets. One of the a Secret
   called `assisted-deployment-pull-secret`, and the other a Secret with a name that is the result of concatenate
   clustername-bmc-secret
8. If some of the steps fails, abort the the process and explain why.

If we are in the context of cluster removal do the following steps:
1. Exit and continue
