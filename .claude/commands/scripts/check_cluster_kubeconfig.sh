#!/bin/bash

# Script to check KUBECONFIG variable and verify OpenShift connectivity
# Returns:
#   0 - KUBECONFIG is set and cluster is reachable
#   1 - KUBECONFIG is not set
#   2 - KUBECONFIG is set but cluster is not reachable

# Check if KUBECONFIG is set (from environment or context)
if [[ -z "$KUBECONFIG" ]]; then
    echo "❌ KUBECONFIG is not set"
    exit 1
fi

# Expand ~ to absolute path if present
if [[ "$KUBECONFIG" == *"~"* ]]; then
    KUBECONFIG="${KUBECONFIG/#\~/$HOME}"
    export KUBECONFIG
    echo "ℹ️  Expanded KUBECONFIG to: $KUBECONFIG"
fi

# Verify connectivity to OpenShift cluster
echo "🔍 Checking connectivity to OpenShift cluster..."
if oc --kubeconfig="$KUBECONFIG" get --raw='/readyz' --request-timeout=5s >/dev/null 2>&1; then
    echo "✅ Connected to OpenShift cluster"
    exit 0
else
    echo "❌ Failed to connect to OpenShift cluster"
    exit 2
fi
