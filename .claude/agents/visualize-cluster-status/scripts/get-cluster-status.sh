#!/bin/bash
# Fast cluster status data gathering script
# Usage: ./get-cluster-status.sh <cluster-name> [kubeconfig-path]

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <cluster-name> [kubeconfig-path]"
    exit 1
fi

CLUSTER_NAME="$1"
KUBECONFIG_PATH="${2:-${KUBECONFIG:-}}"

if [ -z "$KUBECONFIG_PATH" ]; then
    echo "Error: KUBECONFIG not provided and not set in environment"
    exit 1
fi

OC_CMD="oc --kubeconfig $KUBECONFIG_PATH"

# Pre-check: Verify ClusterInstance exists before gathering other data
if ! $OC_CMD get clusterinstance "$CLUSTER_NAME" -n "$CLUSTER_NAME" &>/dev/null; then
    echo "CLUSTER_NOT_DEPLOYED=true"

    # Check if namespace exists
    if $OC_CMD get namespace "$CLUSTER_NAME" &>/dev/null; then
        echo "NAMESPACE_EXISTS=true"
    else
        echo "NAMESPACE_EXISTS=false"
    fi

    exit 0
fi

echo "CLUSTER_NOT_DEPLOYED=false"

# Get script directory to locate the collector script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTOR_SCRIPT="$SCRIPT_DIR/collect-resource-data.sh"

# Determine project root (3 levels up from .claude/agents/visualize-cluster-status)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEMP_BASE="$PROJECT_ROOT/.temp/visualize-cluster-status-$CLUSTER_NAME"

if [ ! -x "$COLLECTOR_SCRIPT" ]; then
    echo "Error: collect-resource-data.sh not found or not executable at $COLLECTOR_SCRIPT" >&2
    exit 1
fi

# Create temporary directory for parallel results with unique name including cluster name
mkdir -p "$TEMP_BASE"
TMPDIR=$(mktemp -d "$TEMP_BASE/get-status-$$-XXXXXX")
trap "rm -rf $TMPDIR" EXIT

# Gather all data in parallel using the modular collector script
# Launch all collectors simultaneously for maximum performance
{
    # Launch parallel data collectors for each resource type
    "$COLLECTOR_SCRIPT" clusterinstance "$CLUSTER_NAME" "$KUBECONFIG_PATH" "$TMPDIR/ci.json" &
    "$COLLECTOR_SCRIPT" baremetalhost "$CLUSTER_NAME" "$KUBECONFIG_PATH" "$TMPDIR/bmh.json" &
    "$COLLECTOR_SCRIPT" infraenv "$CLUSTER_NAME" "$KUBECONFIG_PATH" "$TMPDIR/infraenv.json" &
    "$COLLECTOR_SCRIPT" agentclusterinstall "$CLUSTER_NAME" "$KUBECONFIG_PATH" "$TMPDIR/aci.json" &
    "$COLLECTOR_SCRIPT" agents "$CLUSTER_NAME" "$KUBECONFIG_PATH" "$TMPDIR/agents.json" &
    "$COLLECTOR_SCRIPT" managedcluster "$CLUSTER_NAME" "$KUBECONFIG_PATH" "$TMPDIR/mc.json" &

    # Wait for all background collectors to complete
    wait

    # Now parse and output all results from ClusterInstance JSON
    echo -n "CI_CREATED="
    jq -r '.metadata.creationTimestamp // "N/A"' "$TMPDIR/ci.json"

    echo -n "CI_GENERATION="
    jq -r '.metadata.generation // "N/A"' "$TMPDIR/ci.json"

    echo -n "CI_OBSERVED_GEN="
    jq -r '.status.observedGeneration // "N/A"' "$TMPDIR/ci.json"

    echo -n "CI_CONDITIONS="
    jq -c '.status.conditions // []' "$TMPDIR/ci.json"

    echo -n "CI_MANIFESTS_RENDERED="
    jq -c '.status.manifestsRendered // []' "$TMPDIR/ci.json"

    # BareMetalHost - parse from JSON
    echo -n "BMH_STATUS="
    jq -r '.operationalStatus // "N/A"' "$TMPDIR/bmh.json"

    echo -n "BMH_PROV_STATE="
    jq -r '.provisioningState // "N/A"' "$TMPDIR/bmh.json"

    echo -n "BMH_POWER="
    jq -r '.poweredOn // "N/A"' "$TMPDIR/bmh.json"

    echo -n "BMH_LAST_UPDATED="
    jq -r '.lastUpdated // "N/A"' "$TMPDIR/bmh.json"

    # InfraEnv - parse from JSON
    echo -n "INFRAENV_IMAGE="
    jq -r '.imageCreated // "N/A"' "$TMPDIR/infraenv.json"

    echo -n "INFRAENV_TIME="
    jq -r '.imageCreatedTime // "N/A"' "$TMPDIR/infraenv.json"

    echo -n "INFRAENV_CREATED_TIME="
    jq -r '.createdTime // "N/A"' "$TMPDIR/infraenv.json"

    # AgentClusterInstall - parse from JSON
    echo -n "ACI_STATE="
    jq -r '.status.debugInfo.state // "N/A"' "$TMPDIR/aci.json"

    echo -n "ACI_INFO="
    jq -r '.status.debugInfo.stateInfo // "N/A"' "$TMPDIR/aci.json"

    echo -n "ACI_PROGRESS="
    jq -r '.status.debugInfo.totalPercentage // ""' "$TMPDIR/aci.json"

    echo -n "ACI_COMPLETED="
    jq -r '.status.conditions[] | select(.type=="Completed") | .status // "N/A"' "$TMPDIR/aci.json" | head -1 || echo "N/A"

    echo -n "ACI_FAILED="
    jq -r '.status.conditions[] | select(.type=="Failed") | .status // "N/A"' "$TMPDIR/aci.json" | head -1 || echo "N/A"

    echo -n "ACI_VALIDATED="
    jq -r '.status.conditions[] | select(.type=="Validated") | .status // "N/A"' "$TMPDIR/aci.json" | head -1 || echo "N/A"

    echo -n "ACI_REQS="
    jq -r '.status.conditions[] | select(.type=="RequirementsMet") | .status // "N/A"' "$TMPDIR/aci.json" | head -1 || echo "N/A"

    # Agents
    echo -n "AGENT_COUNT="
    jq -r '.items | length' "$TMPDIR/agents.json"

    echo -n "AGENT_APPROVED="
    jq -r '[.items[] | select(.spec.approved==true)] | length' "$TMPDIR/agents.json"

    echo -n "AGENT_DETAILS="
    jq -c '[.items[] | {id: (.metadata.name[-4:]), approved: .spec.approved, state: .status.debugInfo.state, role: .status.role}]' "$TMPDIR/agents.json"

    # ManagedCluster - parse from JSON
    echo -n "MC_AVAILABLE="
    jq -r '.available // "N/A"' "$TMPDIR/mc.json"

    echo -n "MC_JOINED="
    jq -r '.joined // "N/A"' "$TMPDIR/mc.json"

    echo -n "MC_CREATED="
    jq -r '.creationTimestamp // "N/A"' "$TMPDIR/mc.json"

} 2>&1
