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

# Create temporary directory for parallel results
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Gather all data in parallel for speed - launch all oc commands simultaneously
{
    # ClusterInstance - get full JSON once in background
    ($OC_CMD get clusterinstance "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o json 2>/dev/null > "$TMPDIR/ci.json" || echo '{}' > "$TMPDIR/ci.json") &

    # BareMetalHost
    ($OC_CMD get baremetalhost "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.operationalStatus}' 2>/dev/null > "$TMPDIR/bmh_status" || echo "N/A" > "$TMPDIR/bmh_status") &
    ($OC_CMD get baremetalhost "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.provisioning.state}' 2>/dev/null > "$TMPDIR/bmh_prov" || echo "N/A" > "$TMPDIR/bmh_prov") &
    ($OC_CMD get baremetalhost "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.poweredOn}' 2>/dev/null > "$TMPDIR/bmh_power" || echo "N/A" > "$TMPDIR/bmh_power") &

    # InfraEnv
    ($OC_CMD get infraenv "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ImageCreated")].status}' 2>/dev/null > "$TMPDIR/infraenv_img" || echo "N/A" > "$TMPDIR/infraenv_img") &
    ($OC_CMD get infraenv "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ImageCreated")].lastTransitionTime}' 2>/dev/null > "$TMPDIR/infraenv_time" || echo "N/A" > "$TMPDIR/infraenv_time") &

    # AgentClusterInstall - get full JSON once
    ($OC_CMD get agentclusterinstall "$CLUSTER_NAME" -n "$CLUSTER_NAME" -o json 2>/dev/null > "$TMPDIR/aci.json" || echo '{}' > "$TMPDIR/aci.json") &

    # Agents
    ($OC_CMD get agents -n "$CLUSTER_NAME" -o json 2>/dev/null > "$TMPDIR/agents.json" || echo '{"items":[]}' > "$TMPDIR/agents.json") &

    # ManagedCluster
    ($OC_CMD get managedcluster "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status}' 2>/dev/null > "$TMPDIR/mc_avail" || echo "N/A" > "$TMPDIR/mc_avail") &
    ($OC_CMD get managedcluster "$CLUSTER_NAME" -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterJoined")].status}' 2>/dev/null > "$TMPDIR/mc_joined" || echo "N/A" > "$TMPDIR/mc_joined") &

    # Wait for all background jobs to complete
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

    # BareMetalHost
    echo -n "BMH_STATUS="
    cat "$TMPDIR/bmh_status"
    echo ""

    echo -n "BMH_PROV_STATE="
    cat "$TMPDIR/bmh_prov"
    echo ""

    echo -n "BMH_POWER="
    cat "$TMPDIR/bmh_power"
    echo ""

    # InfraEnv
    echo -n "INFRAENV_IMAGE="
    cat "$TMPDIR/infraenv_img"
    echo ""

    echo -n "INFRAENV_TIME="
    cat "$TMPDIR/infraenv_time"
    echo ""

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

    # ManagedCluster
    echo -n "MC_AVAILABLE="
    cat "$TMPDIR/mc_avail"
    echo ""

    echo -n "MC_JOINED="
    cat "$TMPDIR/mc_joined"
    echo ""

} 2>&1
