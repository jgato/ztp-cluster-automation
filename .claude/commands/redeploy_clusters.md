# Redeploy  ZTP clusters by name
The script takes only one ar $ARGUMENT with a cluster name. If more than one
ARGUMENT is proved, exit and explayin the command only allows one cluster removal.
But you can call the command several times with different clusters.

Consider the environment is correctly configured about KUBECONFIG and hub selection. So, do not make
any check on KUBECONFIG variable, neither clusters connectvity.

Follow these steps:
0. Make a temporal directory called "tmp-clustername"
1. Then:
    * Make a copy of the secret 'assisted-deployment-pull-secret'
    * Make a copy of the secret 'clustername-bmc-secret'
    * Secrets exists in the namespace with the name of the cluster.
    * Store the screts in the remporal directory.
2. Invoke /remove_clusters with the cluster name
3. The /remove_clusters command will handle the entire removal process including monitoring until complete.
   When the /remove_clusters command exits/completes successfully, the cluster has been removed.
   If /remove_clusters exits with an error, abort the redeploy and report the error.
4. After /remove_clusters completes successfully, check if the Namespace of the cluster was removed. If yes, create it again and restore the copy of the secrets from step 0.
5. Invoke /deploy_cluster with the cluster name
6. The /deploy_cluster skill will handle the entire deployment process including monitoring until complete.
   When the /deploy_cluster skill exits/completes successfully, the cluster has been deployed.
   **IMPORTANT: Do NOT exit the redeploy command. Immediately continue to step 7.**
   If /deploy_cluster exits with an error, abort the redeploy and report the error.
7. Report successful redeployment completion to the user and exit the redeploy command
