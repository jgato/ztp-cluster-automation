#! /bin/bash

if [ $# -lt 1 ]
  then
    echo "Usage: ./script.sh <NAMESPACE>"
    exit 1
fi
export CLUSTERNS=$1
export BMCSECRET=$1
echo ${CLUSTERNS}

export PULLSECRETCONTENT=$(cat ~/.config/containers/auth.json)
export PS64=$(echo -n ${PULLSECRETCONTENT} | base64 -w0)
envsubst <<"EOF" | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: assisted-deployment-pull-secret
  namespace: ${CLUSTERNS}
data:
  .dockerconfigjson: ${PS64}
EOF

echo "Now introduce the credentials for the BMC"
#USERNAME=$(read -p 'Username: ' tmp; printf $tmp | base64)
#PASSWORD=`read -s -p 'Password: ' tmp; printf $tmp | base64`
#export PASSWORD=$(zenity --password --title="Auth"| base64)
CREDENTIALS=$(zenity --forms --title="Login" \
    --text="Introduce BMC credentials for ${CLUSTERNS}" \
    --add-entry="Username" \
    --add-password="Password")
if [ $? -ne 0 ]; then
    echo "❌ Operación cancelada por el usuario."
    exit 1
fi
echo ${CREDENTIALS}
IFS='|' read -r USERNAME PASSWORD <<< "$CREDENTIALS"
PASSWORD=$(echo ${PASSWORD} | base64)
USERNAME=$(echo ${USERNAME} | base64)

oc apply -f - <<EOF
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
