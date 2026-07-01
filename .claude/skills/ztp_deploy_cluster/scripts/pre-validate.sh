#!/bin/bash
# Pre-validation for ZTP cluster deployment
# Usage: ./pre-validate.sh <cluster-name> <kubeconfig-path>

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <cluster-name> <kubeconfig-path>"
    exit 1
fi

CLUSTER_NAME="$1"
KUBECONFIG_PATH="$2"

PROJECT_ROOT="$(pwd)"
KUSTOMIZATION="$PROJECT_ROOT/kustomization.yaml"
OC_CMD="oc --kubeconfig $KUBECONFIG_PATH"

# Check kustomization.yaml exists
if [ ! -f "$KUSTOMIZATION" ]; then
    echo "Error: kustomization.yaml not found at $KUSTOMIZATION" >&2
    exit 2
fi

# Check if cluster entry is already active (uncommented) in resources section
if grep -qE "^[[:space:]]*-[[:space:]]+${CLUSTER_NAME}/?" "$KUSTOMIZATION"; then
    echo "ENTRY_STATUS=active"
    echo "CLUSTER_NAME=$CLUSTER_NAME"
    echo "Error: Cluster $CLUSTER_NAME is already active in kustomization.yaml" >&2
    exit 3
fi

# Check if cluster entry is commented
if grep -qE "^[[:space:]]*#[[:space:]]*-[[:space:]]+${CLUSTER_NAME}/?" "$KUSTOMIZATION"; then
    ENTRY_STATUS="commented"
else
    ENTRY_STATUS="missing"
fi

# Check cluster manifest file exists in project root
MANIFEST_FILE=""
for f in "$PROJECT_ROOT/${CLUSTER_NAME}.yaml" "$PROJECT_ROOT/${CLUSTER_NAME}.yml"; do
    if [ -f "$f" ]; then
        MANIFEST_FILE="$f"
        break
    fi
done

if [ -z "$MANIFEST_FILE" ]; then
    echo "Error: Cluster manifest not found (looked for ${CLUSTER_NAME}.yaml / ${CLUSTER_NAME}.yml)" >&2
    exit 4
fi

# Check manifest contains a ClusterInstance kind
if ! grep -q "kind:[[:space:]]*ClusterInstance" "$MANIFEST_FILE"; then
    echo "Error: No ClusterInstance kind found in $MANIFEST_FILE" >&2
    exit 5
fi

# Check namespace existence on cluster
NAMESPACE_EXISTS="false"
if $OC_CMD get namespace "$CLUSTER_NAME" &>/dev/null; then
    NAMESPACE_EXISTS="true"
fi

echo "CLUSTER_NAME=$CLUSTER_NAME"
echo "ENTRY_STATUS=$ENTRY_STATUS"
echo "MANIFEST_FILE=$MANIFEST_FILE"
echo "MANIFEST_FILE=$MANIFEST_FILE"
echo "NAMESPACE_EXISTS=$NAMESPACE_EXISTS"
