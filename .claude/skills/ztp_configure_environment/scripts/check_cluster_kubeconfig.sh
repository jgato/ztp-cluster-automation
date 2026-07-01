#!/bin/bash

# Script to verify OpenShift connectivity
# Usage: ./check_cluster_kubeconfig.sh <kubeconfig-path>
# Returns:
#   0 - Cluster is reachable
#   1 - Cluster is not reachable

KUBECONFIG_PATH="$1"

if [[ -z "$KUBECONFIG_PATH" ]]; then
    echo "❌ Usage: check_cluster_kubeconfig.sh <kubeconfig-path>"
    exit 1
fi

echo "🔍 Checking connectivity to OpenShift cluster..."
if oc --kubeconfig="$KUBECONFIG_PATH" get --raw='/readyz' --request-timeout=5s >/dev/null 2>&1; then
    echo "✅ Connected to OpenShift cluster"
    exit 0
else
    echo "❌ Failed to connect to OpenShift cluster"
    exit 1
fi
