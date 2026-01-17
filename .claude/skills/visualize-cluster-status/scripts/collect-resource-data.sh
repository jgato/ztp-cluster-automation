#!/bin/bash
# Parallel resource data collector for ZTP clusters
# Usage: ./collect-resource-data.sh <resource-type> <cluster-name> <kubeconfig-path> <output-file>
#
# Resource types:
#   clusterinstance, baremetalhost, infraenv, agentclusterinstall, agents, managedcluster
#
# This script is designed to be called in parallel for different resource types

set -euo pipefail

if [ $# -lt 4 ]; then
    echo "Usage: $0 <resource-type> <cluster-name> <kubeconfig-path> <output-file>"
    echo "Resource types: clusterinstance, baremetalhost, infraenv, agentclusterinstall, agents, managedcluster"
    exit 1
fi

RESOURCE_TYPE="$1"
CLUSTER_NAME="$2"
KUBECONFIG_PATH="$3"
OUTPUT_FILE="$4"

OC_CMD="oc --kubeconfig $KUBECONFIG_PATH"

# Collect data based on resource type
case "$RESOURCE_TYPE" in
    clusterinstance)
        # Get full ClusterInstance JSON
        $OC_CMD get clusterinstance "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o json 2>/dev/null > "$OUTPUT_FILE" || echo '{}' > "$OUTPUT_FILE"
        ;;

    baremetalhost)
        # Get BareMetalHost data as JSON
        {
            echo -n '{"operationalStatus":"'
            $OC_CMD get baremetalhost "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.operationalStatus}' 2>/dev/null || echo -n "N/A"
            echo -n '","provisioningState":"'
            $OC_CMD get baremetalhost "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.provisioning.state}' 2>/dev/null || echo -n "N/A"
            echo -n '","poweredOn":"'
            $OC_CMD get baremetalhost "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.poweredOn}' 2>/dev/null || echo -n "N/A"
            echo -n '","lastUpdated":"'
            $OC_CMD get baremetalhost "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.lastUpdated}' 2>/dev/null || echo -n "N/A"
            echo '"}'
        } > "$OUTPUT_FILE" 2>/dev/null || echo '{"operationalStatus":"N/A","provisioningState":"N/A","poweredOn":"N/A","lastUpdated":"N/A"}' > "$OUTPUT_FILE"
        ;;

    infraenv)
        # Get InfraEnv data as JSON
        {
            echo -n '{"imageCreated":"'
            $OC_CMD get infraenv "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ImageCreated")].status}' 2>/dev/null || echo -n "N/A"
            echo -n '","imageCreatedTime":"'
            $OC_CMD get infraenv "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ImageCreated")].lastTransitionTime}' 2>/dev/null || echo -n "N/A"
            echo -n '","createdTime":"'
            $OC_CMD get infraenv "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.createdTime}' 2>/dev/null || echo -n "N/A"
            echo '"}'
        } > "$OUTPUT_FILE" 2>/dev/null || echo '{"imageCreated":"N/A","imageCreatedTime":"N/A","createdTime":"N/A"}' > "$OUTPUT_FILE"
        ;;

    agentclusterinstall)
        # Get full AgentClusterInstall JSON
        $OC_CMD get agentclusterinstall "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o json 2>/dev/null > "$OUTPUT_FILE" || echo '{}' > "$OUTPUT_FILE"
        ;;

    agents)
        # Get all Agents in the namespace as JSON array
        $OC_CMD get agents -n "$CLUSTER_NAME" -o json 2>/dev/null > "$OUTPUT_FILE" || echo '{"items":[]}' > "$OUTPUT_FILE"
        ;;

    managedcluster)
        # Get ManagedCluster data as JSON
        {
            echo -n '{"available":"'
            $OC_CMD get managedcluster "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status}' 2>/dev/null || echo -n "N/A"
            echo -n '","joined":"'
            $OC_CMD get managedcluster "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterJoined")].status}' 2>/dev/null || echo -n "N/A"
            echo -n '","creationTimestamp":"'
            $OC_CMD get managedcluster "$CLUSTER_NAME" -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo -n "N/A"
            echo '"}'
        } > "$OUTPUT_FILE" 2>/dev/null || echo '{"available":"N/A","joined":"N/A","creationTimestamp":"N/A"}' > "$OUTPUT_FILE"
        ;;

    events)
        # Get recent events from the cluster namespace
        $OC_CMD get events -n "$CLUSTER_NAME" --sort-by='.lastTimestamp' -o json 2>/dev/null | \
            jq -c '[.items[-5:] | .[] | {type: .type, reason: .reason, message: .message, timestamp: .lastTimestamp}]' > "$OUTPUT_FILE" || \
            echo '[]' > "$OUTPUT_FILE"
        ;;

    *)
        echo "Error: Unknown resource type: $RESOURCE_TYPE" >&2
        echo '{"error":"unknown_resource_type"}' > "$OUTPUT_FILE"
        exit 1
        ;;
esac

exit 0
