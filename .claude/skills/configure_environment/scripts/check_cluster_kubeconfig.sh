#!/bin/bash

# Script to check KUBECONFIG and verify OpenShift connectivity
# Usage: ./check_cluster_kubeconfig.sh [kubeconfig-path]
# Returns:
#   0 - KUBECONFIG is set and cluster is reachable
#   1 - KUBECONFIG is not set
#   2 - KUBECONFIG is set but cluster is not reachable

# Get KUBECONFIG from parameter or fall back to environment variable
KUBECONFIG_PATH="${1:-${KUBECONFIG:-}}"

# Check if KUBECONFIG is set
if [[ -z "$KUBECONFIG_PATH" ]]; then
    echo "❌ KUBECONFIG not found, or not correctly set"
    exit 1
fi

# Expand ~ to absolute path if present
if [[ "$KUBECONFIG_PATH" == *"~"* ]]; then
    KUBECONFIG_PATH="${KUBECONFIG_PATH/#\~/$HOME}"
    echo "ℹ️  Expanded KUBECONFIG to: $KUBECONFIG_PATH"
fi

# Check if file exists
if [[ ! -f "$KUBECONFIG_PATH" ]]; then
    echo "❌ KUBECONFIG file not found: $KUBECONFIG_PATH"
    exit 1
fi

echo "📁 Using KUBECONFIG: $KUBECONFIG_PATH"

# Verify connectivity to OpenShift cluster
echo "🔍 Checking connectivity to OpenShift cluster..."
if oc --kubeconfig="$KUBECONFIG_PATH" get --raw='/readyz' --request-timeout=5s >/dev/null 2>&1; then
    echo "✅ Connected to OpenShift cluster"
    exit 0
else
    echo "❌ Failed to connect to OpenShift cluster"
    exit 2
fi
