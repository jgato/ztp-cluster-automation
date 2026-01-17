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
5. If the application is "synched", proceed to gather operator versions and CR statuses
6. Use the script `.claude/commands/scrips/get-operator-versions.sh` to collect operator versions in parallel:
   - Script usage: `./get-operator-versions.sh <kubeconfig-path> [output-dir]`
   - If output-dir not provided, uses `.tmp-hub-status` directory in project root
   - Collects: Advanced Cluster Management, TALM, and OpenShift GitOps versions
   - Outputs JSON files: acm.json, talm.json, gitops.json
7. Use the script `.claude/commands/scripts/get-cr-statuses.sh` to collect CR statuses in parallel:
   - Script usage: `./get-cr-statuses.sh <kubeconfig-path> [output-dir]`
   - If output-dir not provided, uses `.tmp-hub-status` directory in project root (same as step 6)
   - Collects status for:
     * MultiClusterHub CR (open-cluster-management namespace) - latest condition only
     * MultiClusterEngine CR (cluster-scoped) - latest condition only
     * MultiClusterObservability CR (open-cluster-management-observability namespace) - latest condition only
     * AgentServiceConfig CR (cluster-scoped) - all conditions
   - Outputs JSON files: multiclusterhub.json, multiclusterengine.json, multiclusterobservability.json, agentserviceconfig.json
8. Gather and summarize all collected data:
   - Read all JSON files from the output directory
   - Present operator versions in a table format
   - Present CR statuses with phase and key conditions
   - Highlight any errors or issues found
   - Provide overall health assessment
9. Command finished
