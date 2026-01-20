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
3. Wait the /remove_clusters to finish. Do nothing until it finishes. When it finishes, it means the cluster was
   removed. So go to the next step. If it was not removed correctly, return with the error.
4. If the Namespace of the cluster was removed, create it again, and restore there the copy of the secrets from step 0.
5. Invoke /deploy_clusters with the cluster name
6. Wait the /deploy_clusters to finish. Do nothing until it finishes. When it finishes, it means the cluster was installed. If it was not, return with the error.
7. Exit command
