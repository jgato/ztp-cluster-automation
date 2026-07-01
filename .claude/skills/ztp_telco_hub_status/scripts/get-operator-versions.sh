#!/bin/bash
# Parallel operator version collector for Telco Hub RDS
# Usage: ./get-operator-versions.sh <kubeconfig-path> [output-dir]
#
# Collects versions for mandatory Telco Hub RDS operators in parallel:
#   - Advanced Cluster Management (ACM)
#   - Topology Aware Lifecycle Manager (TALM)
#   - OpenShift GitOps

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <kubeconfig-path> [output-dir]"
    echo "Collects operator versions in parallel and outputs to separate JSON files"
    echo "If output-dir not provided, uses .tmp-hub-status in project directory"
    exit 1
fi

KUBECONFIG_PATH="$1"

# Use local project directory for temp data if not specified
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="${2:-$PROJECT_DIR/.temp/telco-hub-rds-status}"

OC_CMD="oc --kubeconfig $KUBECONFIG_PATH"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Collect ACM version
collect_acm() {
    {
        echo -n '{"name":"Advanced Cluster Management","version":"'
        $OC_CMD get csv -n open-cluster-management -o json 2>/dev/null | \
            jq -r '.items[] | select(.metadata.name | startswith("advanced-cluster-management")) | .spec.version' || echo -n "N/A"
        echo '","namespace":"open-cluster-management"}'
    } > "$OUTPUT_DIR/acm.json" 2>/dev/null || \
        echo '{"name":"Advanced Cluster Management","version":"N/A","namespace":"open-cluster-management","error":"not found"}' > "$OUTPUT_DIR/acm.json"
}

# Collect TALM version
collect_talm() {
    {
        echo -n '{"name":"TALM","version":"'
        $OC_CMD get csv -n openshift-operators -o json 2>/dev/null | \
            jq -r '.items[] | select(.metadata.name | contains("topology-aware-lifecycle")) | .spec.version' || echo -n "N/A"
        echo '","namespace":"openshift-operators"}'
    } > "$OUTPUT_DIR/talm.json" 2>/dev/null || \
        echo '{"name":"TALM","version":"N/A","namespace":"openshift-operators","error":"not found"}' > "$OUTPUT_DIR/talm.json"
}

# Collect OpenShift GitOps version
collect_gitops() {
    {
        echo -n '{"name":"OpenShift GitOps","version":"'
        $OC_CMD get csv -n openshift-gitops-operator -o json 2>/dev/null | \
            jq -r '.items[] | select(.metadata.name | contains("openshift-gitops-operator")) | .spec.version' || echo -n "N/A"
        echo '","namespace":"openshift-gitops-operator"}'
    } > "$OUTPUT_DIR/gitops.json" 2>/dev/null || \
        echo '{"name":"OpenShift GitOps","version":"N/A","namespace":"openshift-gitops-operator","error":"not found"}' > "$OUTPUT_DIR/gitops.json"
}

# Launch all collectors in parallel
collect_acm &
pid_acm=$!

collect_talm &
pid_talm=$!

collect_gitops &
pid_gitops=$!

# Wait for all collectors to complete
wait $pid_acm $pid_talm $pid_gitops

exit 0
