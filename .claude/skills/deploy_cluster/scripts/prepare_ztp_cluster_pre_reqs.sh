#!/bin/bash
# Create required Kubernetes secrets for ZTP cluster deployment
# Checks for backed-up secrets from redeploy before creating new ones
# Usage: ./prepare_ztp_cluster_pre_reqs.sh <namespace> <kubeconfig>

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <namespace> <kubeconfig>"
    exit 1
fi

CLUSTERNS="$1"
KUBECONFIG_PATH="$2"

OC_CMD="oc --kubeconfig $KUBECONFIG_PATH"

# Create namespace if it does not exist
NAMESPACE_CREATED="false"
if ! $OC_CMD get namespace "$CLUSTERNS" &>/dev/null; then
    $OC_CMD create namespace "$CLUSTERNS"
    NAMESPACE_CREATED="true"
fi

# Check if secrets already exist in the cluster (e.g. restored by redeploy)
if $OC_CMD get secret assisted-deployment-pull-secret -n "$CLUSTERNS" &>/dev/null && \
   $OC_CMD get secret "${CLUSTERNS}-bmc-secret" -n "$CLUSTERNS" &>/dev/null; then

    SECRETS_SOURCE="existing"
else
    # Create fresh secrets

    # Pull secret from auth.json
    PULL_SECRET_FILE="$HOME/.config/containers/auth.json"
    if [ ! -f "$PULL_SECRET_FILE" ]; then
        echo "Error: Pull secret file not found at $PULL_SECRET_FILE" >&2
        exit 2
    fi

    PS64=$(cat "$PULL_SECRET_FILE" | base64 -w0)

    cat <<EOF | $OC_CMD apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ${CLUSTERNS}
data:
  .dockerconfigjson: ${PS64}
EOF

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create pull secret" >&2
        exit 3
    fi

    # BMC credentials via zenity dialog
    echo "Requesting BMC credentials via dialog..." >&2
    CREDENTIALS=$(zenity --forms --title="Login" \
        --text="Introduce BMC credentials for ${CLUSTERNS}" \
        --add-entry="Username" \
        --add-password="Password")
    if [ $? -ne 0 ]; then
        echo "Error: Credential input cancelled" >&2
        exit 4
    fi
    IFS='|' read -r RAW_USER RAW_PASS <<< "$CREDENTIALS"
    USERNAME=$(echo -n "$RAW_USER" | base64 -w0)
    PASSWORD=$(echo -n "$RAW_PASS" | base64 -w0)

    cat <<EOF | $OC_CMD apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${CLUSTERNS}-bmc-secret
  namespace: ${CLUSTERNS}
type: Opaque
data:
  username: ${USERNAME}
  password: ${PASSWORD}
EOF

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create BMC secret" >&2
        exit 4
    fi

    SECRETS_SOURCE="new"
fi

# Verify both secrets exist in the cluster
if ! $OC_CMD get secret assisted-deployment-pull-secret -n "$CLUSTERNS" &>/dev/null; then
    echo "Error: Pull secret verification failed - not found in cluster" >&2
    exit 5
fi

if ! $OC_CMD get secret "${CLUSTERNS}-bmc-secret" -n "$CLUSTERNS" &>/dev/null; then
    echo "Error: BMC secret verification failed - not found in cluster" >&2
    exit 5
fi

echo "NAMESPACE_CREATED=$NAMESPACE_CREATED"
echo "PULL_SECRET_APPLIED=true"
echo "BMC_SECRET_APPLIED=true"
echo "SECRETS_VERIFIED=true"
echo "SECRETS_SOURCE=$SECRETS_SOURCE"
