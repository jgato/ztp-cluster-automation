#!/bin/bash
# Parallel CR status collector for Telco Hub RDS
# Usage: ./get-cr-statuses.sh <kubeconfig-path> [output-dir]
#
# Collects status for mandatory Telco Hub RDS CRs in parallel:
#   - MultiClusterHub (open-cluster-management namespace)
#   - MultiClusterEngine (cluster-scoped)
#   - MultiClusterObservability (open-cluster-management-observability namespace)
#   - AgentServiceConfig (cluster-scoped)

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <kubeconfig-path> [output-dir]"
    echo "Collects CR statuses in parallel and outputs to separate JSON files"
    echo "If output-dir not provided, uses .tmp-hub-status in project directory"
    exit 1
fi

KUBECONFIG_PATH="$1"

# Use local project directory for temp data if not specified
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${2:-$PROJECT_DIR/.tmp-hub-status}"

OC_CMD="oc --kubeconfig $KUBECONFIG_PATH"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Collect MultiClusterHub status - only most recent condition
collect_mch() {
    $OC_CMD get multiclusterhub multiclusterhub -n open-cluster-management -o json 2>/dev/null | \
        jq '{name: .metadata.name, namespace: "open-cluster-management", phase: .status.phase, condition: (.status.conditions | sort_by(.lastTransitionTime) | last | {type: .type, status: .status, reason: .reason, message: .message, lastTransitionTime: .lastTransitionTime})}' \
        > "$OUTPUT_DIR/multiclusterhub.json" 2>/dev/null || \
        echo '{"name":"multiclusterhub","namespace":"open-cluster-management","error":"not found"}' > "$OUTPUT_DIR/multiclusterhub.json"
}

# Collect MultiClusterEngine status - only most recent condition
collect_mce() {
    $OC_CMD get multiclusterengine multiclusterengine -o json 2>/dev/null | \
        jq '{name: .metadata.name, scope: "cluster", phase: .status.phase, condition: (.status.conditions | sort_by(.lastTransitionTime) | last | {type: .type, status: .status, reason: .reason, message: .message, lastTransitionTime: .lastTransitionTime})}' \
        > "$OUTPUT_DIR/multiclusterengine.json" 2>/dev/null || \
        echo '{"name":"multiclusterengine","scope":"cluster","error":"not found"}' > "$OUTPUT_DIR/multiclusterengine.json"
}

# Collect MultiClusterObservability status - only most recent condition
collect_mco() {
    $OC_CMD get multiclusterobservability observability -n open-cluster-management-observability -o json 2>/dev/null | \
        jq '{name: .metadata.name, namespace: "open-cluster-management-observability", condition: (.status.conditions | sort_by(.lastTransitionTime) | last | {type: .type, status: .status, reason: .reason, message: .message, lastTransitionTime: .lastTransitionTime})}' \
        > "$OUTPUT_DIR/multiclusterobservability.json" 2>/dev/null || \
        echo '{"name":"observability","namespace":"open-cluster-management-observability","error":"not found"}' > "$OUTPUT_DIR/multiclusterobservability.json"
}

# Collect AgentServiceConfig status
collect_asc() {
    $OC_CMD get agentserviceconfig agent -o json 2>/dev/null | \
        jq '{name: .metadata.name, scope: "cluster", conditions: [.status.conditions[] | {type: .type, status: .status, reason: .reason, message: .message}]}' \
        > "$OUTPUT_DIR/agentserviceconfig.json" 2>/dev/null || \
        echo '{"name":"agent","scope":"cluster","error":"not found"}' > "$OUTPUT_DIR/agentserviceconfig.json"
}

# Launch all collectors in parallel
collect_mch &
pid_mch=$!

collect_mce &
pid_mce=$!

collect_mco &
pid_mco=$!

collect_asc &
pid_asc=$!

# Wait for all collectors to complete
wait $pid_mch $pid_mce $pid_mco $pid_asc

exit 0
