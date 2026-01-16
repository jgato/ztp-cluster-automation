#!/bin/bash
# Example: Parallel data collection for multiple clusters
# This demonstrates how to use collect-resource-data.sh for custom workflows

set -euo pipefail

# Configuration
CLUSTERS="${1:-vsno5}"  # Default to vsno5, or pass cluster names as arguments
KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
OUTPUT_BASE_DIR="/tmp/ztp-cluster-data"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTOR="$SCRIPT_DIR/collect-resource-data.sh"

if [ ! -x "$COLLECTOR" ]; then
    echo "Error: Collector script not found or not executable: $COLLECTOR"
    exit 1
fi

echo "=============================================="
echo "Parallel Cluster Data Collection Example"
echo "=============================================="
echo "Clusters: $CLUSTERS"
echo "KUBECONFIG: $KUBECONFIG_PATH"
echo "Output directory: $OUTPUT_BASE_DIR"
echo ""

# Process each cluster
for cluster in $CLUSTERS; do
    echo "Collecting data for cluster: $cluster"

    # Create output directory for this cluster
    OUTPUT_DIR="$OUTPUT_BASE_DIR/$cluster"
    mkdir -p "$OUTPUT_DIR"

    # Record start time
    START_TIME=$(date +%s)

    echo "  Launching parallel collectors..."

    # Launch all resource collectors in parallel
    "$COLLECTOR" clusterinstance "$cluster" "$KUBECONFIG_PATH" "$OUTPUT_DIR/clusterinstance.json" &
    pid_ci=$!

    "$COLLECTOR" baremetalhost "$cluster" "$KUBECONFIG_PATH" "$OUTPUT_DIR/baremetalhost.json" &
    pid_bmh=$!

    "$COLLECTOR" infraenv "$cluster" "$KUBECONFIG_PATH" "$OUTPUT_DIR/infraenv.json" &
    pid_ie=$!

    "$COLLECTOR" agentclusterinstall "$cluster" "$KUBECONFIG_PATH" "$OUTPUT_DIR/agentclusterinstall.json" &
    pid_aci=$!

    "$COLLECTOR" agents "$cluster" "$KUBECONFIG_PATH" "$OUTPUT_DIR/agents.json" &
    pid_agents=$!

    "$COLLECTOR" managedcluster "$cluster" "$KUBECONFIG_PATH" "$OUTPUT_DIR/managedcluster.json" &
    pid_mc=$!

    "$COLLECTOR" events "$cluster" "$KUBECONFIG_PATH" "$OUTPUT_DIR/events.json" &
    pid_events=$!

    # Wait for all collectors to complete
    wait $pid_ci $pid_bmh $pid_ie $pid_aci $pid_agents $pid_mc $pid_events

    # Record end time and calculate duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "  ✅ Collection complete in ${DURATION}s"
    echo ""
    echo "  Collected data:"

    # Display collected files and their sizes
    for file in "$OUTPUT_DIR"/*.json; do
        if [ -f "$file" ]; then
            size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
            filename=$(basename "$file")
            printf "    %-30s %8s bytes\n" "$filename" "$size"
        fi
    done

    echo ""
    echo "  Quick summary:"

    # Extract some key information from collected data
    if [ -f "$OUTPUT_DIR/clusterinstance.json" ]; then
        ci_created=$(jq -r '.metadata.creationTimestamp // "N/A"' "$OUTPUT_DIR/clusterinstance.json")
        echo "    ClusterInstance created: $ci_created"
    fi

    if [ -f "$OUTPUT_DIR/agentclusterinstall.json" ]; then
        aci_state=$(jq -r '.status.debugInfo.state // "N/A"' "$OUTPUT_DIR/agentclusterinstall.json")
        aci_progress=$(jq -r '.status.debugInfo.totalPercentage // "N/A"' "$OUTPUT_DIR/agentclusterinstall.json")
        echo "    Installation state: $aci_state ($aci_progress%)"
    fi

    if [ -f "$OUTPUT_DIR/agents.json" ]; then
        agent_count=$(jq -r '.items | length' "$OUTPUT_DIR/agents.json")
        agent_approved=$(jq -r '[.items[] | select(.spec.approved==true)] | length' "$OUTPUT_DIR/agents.json")
        echo "    Agents: $agent_count total, $agent_approved approved"
    fi

    if [ -f "$OUTPUT_DIR/managedcluster.json" ]; then
        mc_available=$(jq -r '.available // "N/A"' "$OUTPUT_DIR/managedcluster.json")
        mc_joined=$(jq -r '.joined // "N/A"' "$OUTPUT_DIR/managedcluster.json")
        echo "    ManagedCluster: Available=$mc_available, Joined=$mc_joined"
    fi

    echo ""
    echo "  Data saved to: $OUTPUT_DIR"
    echo ""
done

echo "=============================================="
echo "All collections complete!"
echo "=============================================="
echo ""
echo "To view collected data:"
echo "  jq '.' $OUTPUT_BASE_DIR/<cluster-name>/<resource>.json"
echo ""
echo "Example analysis:"
echo "  # View ClusterInstance conditions"
echo "  jq '.status.conditions' $OUTPUT_BASE_DIR/vsno5/clusterinstance.json"
echo ""
echo "  # View agent states"
echo "  jq '.items[] | {name: .metadata.name, state: .status.debugInfo.state}' \\"
echo "    $OUTPUT_BASE_DIR/vsno5/agents.json"
echo ""
