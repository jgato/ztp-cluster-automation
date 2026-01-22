---
name: redeploy_cluster
description: Complete workflow to redeploy a ZTP cluster with secret preservation
allowed-tools: Bash(oc:*, mkdir:*), Read, Write, Skill
model: sonnet
---

# Redeploy ZTP cluster by name

The skill takes only one $ARGUMENT with a cluster name. If more than one
ARGUMENT is provided, exit and explain the skill only allows one cluster redeployment.
But you can call the skill several times with different clusters.

Consider the environment is correctly configured about KUBECONFIG and hub selection. So, do not make
any check on KUBECONFIG variable, neither clusters connectivity.

## THIS IS A PARENT WORKFLOW

**You MUST execute ALL steps 0-7. Do NOT stop when a skill/sub-command/sub-agent completes.**

After any skill completes, I must immediately check my todo list:
  - Mark the current todo as completed
  - Mark the next todo as in_progress
  - Immediately execute the next step

## Steps

0. Make a temporal directory called "tmp-clustername"

1. Then:
    * Make a copy of the secret 'assisted-deployment-pull-secret'
    * Make a copy of the secret 'clustername-bmc-secret'
    * Secrets exist in the namespace with the name of the cluster.
    * Store the secrets in the temporal directory.

2. Invoke /remove_cluster with the cluster name

3. The /remove_cluster skill will handle the entire removal process including monitoring until complete.
   When the /remove_cluster skill exits/completes successfully, the cluster has been removed.
   If /remove_cluster exits with an error, abort the redeploy and report the error.

4. After /remove_cluster completes successfully, check if the Namespace of the cluster was removed. If yes, create it again and restore the copy of the secrets from step 0.

5. Invoke /deploy_cluster with the cluster name

6. The /deploy_cluster skill will handle the entire deployment process including monitoring until complete.
   When the /deploy_cluster skill exits/completes successfully, the cluster has been deployed.
   **IMPORTANT: Do NOT exit the redeploy skill. Immediately continue to step 7.**
   If /deploy_cluster exits with an error, abort the redeploy and report the error.

7. Report successful redeployment completion to the user and exit the redeploy skill.
