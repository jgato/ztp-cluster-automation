#!/bin/bash
# Extract kubeadmin password and kubeconfig from deployed cluster secrets
# Usage: ./extract-credentials.sh <cluster-name> <kubeconfig-path>

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <cluster-name> <kubeconfig-path>"
    exit 1
fi

CLUSTER_NAME="$1"
KUBECONFIG_PATH="$2"

PROJECT_ROOT="$(pwd)"
OUTPUT_DIR="$PROJECT_ROOT/.temp/deploy-cluster-$CLUSTER_NAME"
OC_CMD="oc --kubeconfig $KUBECONFIG_PATH"

mkdir -p "$OUTPUT_DIR"

# Extract kubeadmin password
if ! $OC_CMD get secret "${CLUSTER_NAME}-admin-password" -n "$CLUSTER_NAME" &>/dev/null; then
    echo "Error: Secret ${CLUSTER_NAME}-admin-password not found in namespace $CLUSTER_NAME" >&2
    exit 2
fi

KUBEADMIN_PASSWORD=$($OC_CMD get secret "${CLUSTER_NAME}-admin-password" -n "$CLUSTER_NAME" \
    -o jsonpath='{.data.password}' | base64 -d)
echo -n "$KUBEADMIN_PASSWORD" > "$OUTPUT_DIR/kubeadmin-password"

# Extract kubeconfig
if ! $OC_CMD get secret "${CLUSTER_NAME}-admin-kubeconfig" -n "$CLUSTER_NAME" &>/dev/null; then
    echo "Error: Secret ${CLUSTER_NAME}-admin-kubeconfig not found in namespace $CLUSTER_NAME" >&2
    exit 3
fi

$OC_CMD get secret "${CLUSTER_NAME}-admin-kubeconfig" -n "$CLUSTER_NAME" \
    -o jsonpath='{.data.kubeconfig}' | base64 -d > "$OUTPUT_DIR/kubeconfig"

echo "KUBEADMIN_PASSWORD=$KUBEADMIN_PASSWORD"
echo "KUBEADMIN_PASSWORD_FILE=$OUTPUT_DIR/kubeadmin-password"
echo "KUBECONFIG_FILE=$OUTPUT_DIR/kubeconfig"
