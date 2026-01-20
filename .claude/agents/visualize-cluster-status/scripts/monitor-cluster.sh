#!/bin/bash
# Continuous cluster status monitor
# Usage: ./monitor-cluster.sh <cluster-name> [kubeconfig-path] [interval-seconds]

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <cluster-name> [kubeconfig-path] [interval-seconds]"
    exit 1
fi

CLUSTER_NAME="$1"
KUBECONFIG_PATH="${2:-${KUBECONFIG:-}}"
INTERVAL="${3:-5}"  # Default 5 seconds

if [ -z "$KUBECONFIG_PATH" ]; then
    echo "Error: KUBECONFIG not provided and not set in environment"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GET_STATUS_SCRIPT="$SCRIPT_DIR/get-cluster-status.sh"

# Determine project root (3 levels up from .claude/agents/visualize-cluster-status)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEMP_BASE="$PROJECT_ROOT/.temp/visualize-cluster-status-$CLUSTER_NAME"

# Create temp directory if it doesn't exist (includes cluster name to avoid conflicts)
mkdir -p "$TEMP_BASE"

if [ ! -x "$GET_STATUS_SCRIPT" ]; then
    echo "Error: get-cluster-status.sh not found or not executable"
    exit 1
fi

# Function to display formatted status
display_status() {
    local data_file="$1"

    # Source the data file to get variables
    source "$data_file"

    # Clear screen and show header
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 Cluster: $CLUSTER_NAME | Updated: $(date '+%H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Determine overall status icon
    local overall_icon="⏳"
    if [ "$ACI_COMPLETED" = "True" ]; then
        overall_icon="✅"
    elif [ "$ACI_FAILED" = "True" ]; then
        overall_icon="❌"
    elif [ "$ACI_STATE" = "installing" ]; then
        overall_icon="🚀"
    fi

    # Core Resources Table
    printf "%-25s | %-8s | %-25s | %-20s\n" "Resource" "Status" "State/Info" "Details"
    echo "─────────────────────────┼──────────┼───────────────────────────┼──────────────────────"

    # BareMetalHost
    local bmh_icon="✅"
    [ "$BMH_STATUS" = "N/A" ] && bmh_icon="⏳"
    [ "$BMH_STATUS" = "error" ] && bmh_icon="❌"
    printf "%-25s | %-8s | %-25s | %-20s\n" \
        "📦 BareMetalHost" "$bmh_icon" "$BMH_PROV_STATE/$BMH_STATUS" "Power: $BMH_POWER"

    # InfraEnv
    local ie_icon="✅"
    [ "$INFRAENV_IMAGE" != "True" ] && ie_icon="⏳"
    local ie_time="${INFRAENV_TIME:11:5}"  # Extract HH:MM
    printf "%-25s | %-8s | %-25s | %-20s\n" \
        "💿 InfraEnv" "$ie_icon" "Image: $INFRAENV_IMAGE" "Updated: ${ie_time}Z"

    # AgentClusterInstall
    local aci_icon="$overall_icon"
    local progress_str=""
    if [ "$ACI_PROGRESS" != "N/A" ] && [ -n "$ACI_PROGRESS" ]; then
        progress_str=" ($ACI_PROGRESS%)"
    fi
    printf "%-25s | %-8s | %-25s | %-20s\n" \
        "🚀 AgentClusterInstall" "$aci_icon" "$ACI_STATE$progress_str" "$ACI_INFO"

    # ManagedCluster
    local mc_icon="⏳"
    [ "$MC_AVAILABLE" = "True" ] && [ "$MC_JOINED" = "True" ] && mc_icon="✅"
    [ "$MC_AVAILABLE" = "N/A" ] && mc_icon="⏳"
    printf "%-25s | %-8s | %-25s | %-20s\n" \
        "🎮 ManagedCluster" "$mc_icon" "Avail: $MC_AVAILABLE, Join: $MC_JOINED" "Ready: $mc_icon"

    echo ""

    # Agents Section
    echo "Agents: $AGENT_COUNT total ($AGENT_APPROVED approved)"
    if [ "$AGENT_COUNT" != "0" ] && [ "$AGENT_DETAILS" != "[]" ]; then
        echo "$AGENT_DETAILS" | jq -r '.[] | "  ...\(.id) | \(.role) | \(.state) | Approved: \(.approved)"'
    fi

    echo ""

    # Conditions inline
    local val_icon="⏳"; [ "$ACI_VALIDATED" = "True" ] && val_icon="✅"
    local req_icon="⏳"; [ "$ACI_REQS" = "True" ] && req_icon="✅"
    local cmp_icon="⏳"; [ "$ACI_COMPLETED" = "True" ] && cmp_icon="✅"
    local fai_icon="✅"; [ "$ACI_FAILED" = "True" ] && fai_icon="❌"

    echo "Conditions: ${val_icon} Validated  ${req_icon} Requirements  ${cmp_icon} Completed  ${fai_icon} Not Failed"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Press Ctrl+C to stop monitoring | Refresh interval: ${INTERVAL}s"
}

# Main monitoring loop
echo "Starting cluster monitor for $CLUSTER_NAME (refresh every ${INTERVAL}s)..."
echo "Press Ctrl+C to stop"
sleep 2

while true; do
    # Get fresh data
    DATA_FILE=$(mktemp "$TEMP_BASE/monitor-data-$$-XXXXXX")
    "$GET_STATUS_SCRIPT" "$CLUSTER_NAME" "$KUBECONFIG_PATH" > "$DATA_FILE" 2>&1

    # Display formatted output
    display_status "$DATA_FILE"

    # Cleanup
    rm -f "$DATA_FILE"

    # Wait for next refresh
    sleep "$INTERVAL"
done
