# Telco Hub RDS status visualization

The name of the cluster is provided by #$ARGUMENT.

This command acts only over cluster that has been configured as a Telco Hub RDS.
The cluster has been configured following the GitOps approach for the Telco Hub RDS.

Follow these steps:
0. Notice the user that we need to ensure, the cluster context is pointing to a hub cluster
1. Invoke the prepare_clusters command in the context of clusters preparation for deployment
2. Check there is an ArgoCD application called "hub-config" and show the status. Should be "synched"
3. If the status is "synching", shows the user that the hub cluster is been configured. Wait and re-check after 5
   minutes.
4. if the application dont reach the "synched" status, shows an error that the hub is not properly configured
5. If the application is "synched", proceed to gather operator versions and CR statuses in parallel
6. Execute BOTH scripts in parallel using background processes to maximize speed:
   - Run `.claude/commands/scripts/get-operator-versions.sh <kubeconfig-path> .tmp-hub-status` in background
   - Run `.claude/commands/scripts/get-cr-statuses.sh <kubeconfig-path> .tmp-hub-status` in background
   - Wait for both scripts to complete before proceeding

   The get-operator-versions.sh script collects (internally in parallel):
   - Advanced Cluster Management version
   - TALM version
   - OpenShift GitOps version
   - Outputs: acm.json, talm.json, gitops.json

   The get-cr-statuses.sh script collects (internally in parallel):
   - MultiClusterHub CR status (open-cluster-management namespace) - latest condition only
   - MultiClusterEngine CR status (cluster-scoped) - latest condition only
   - MultiClusterObservability CR status (open-cluster-management-observability namespace) - latest condition only
   - AgentServiceConfig CR status (cluster-scoped) - all conditions
   - Outputs: multiclusterhub.json, multiclusterengine.json, multiclusterobservability.json, agentserviceconfig.json

   All output files are stored in `.tmp-hub-status` directory in project root
7. Gather and summarize all collected data:
   - Read all JSON files from the output directory
   - Present operator versions in a table format
   - Present CR statuses with phase and key conditions
   - Highlight any errors or issues found
   - Provide overall health assessment
8. Command finished
