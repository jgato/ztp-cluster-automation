#! /bin/bash

if [ $# -lt 2 ]
  then
    echo "Usage: ./script.sh <NAMESPACE> <KUBECONFIG>"
    exit 1
fi
export CLUSTERNS=$1
export BMCSECRET=$1
export KUBECONFIG=$2

echo "KUBECONFIG: ${KUBECONFIG}"

export PULLSECRETCONTENT=$(cat ~/.config/containers/auth.json)
export PS64=$(echo -n ${PULLSECRETCONTENT} | base64 -w0)
envsubst <<"EOF" | oc --kubeconfig ${KUBECONFIG} apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ${CLUSTERNS}
data:
  .dockerconfigjson: ${PS64}
EOF

echo "Now introduce the credentials for the BMC"
CREDENTIALS=$(zenity --forms --title="Login" \
    --text="Introduce BMC credentials for ${CLUSTERNS}" \
    --add-entry="Username" \
    --add-password="Password")
if [ $? -ne 0 ]; then
    echo "❌ Operación cancelada por el usuario."
    exit 1
fi
IFS='|' read -r USERNAME PASSWORD <<< "$CREDENTIALS"
export PASSWORD=$(echo -n ${PASSWORD} | base64 -w0)
export USERNAME=$(echo -n ${USERNAME} | base64 -w0)

envsubst <<"EOF" | oc --kubeconfig ${KUBECONFIG} apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${BMCSECRET}-bmc-secret
  namespace: ${CLUSTERNS}
type: Opaque
data:
  username: ${USERNAME}
  password: ${PASSWORD}
EOF
