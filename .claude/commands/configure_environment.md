# Configure environment for ZTP
Configure environment to later do whatever other GitOps operations over
the clusters. This command makes you to select the proper Kubeconfig to use,
the hub endpoint.
It takes no arguments. If arguments are provided  exist, and notify that the
command does not use argumetns.

if in the context we have kubeconfig with a path including '~', conver it to a absolute path

Follow these steps
1. Check there exists a KUBECONFIG enviroment variable. Or, if we have the KUBECONFIG in the context. If exists make a check with the following command: `[[ -n
   "$KUBECONFIG" ]] && oc --kubeconfig="$KUBECONFIG" get --raw='/readyz' --request-timeout=5s >/dev/null 2>&1 && echo
   "✅ Connected" || echo "❌ Failed/Unset"`
2. If there is no KUBECONFIG, neither env variable, nor context. Pprompt the user to introduce the path before continuing. Dont check the file exists. Then, it just use the previous
   check command.
3. No more checks about connection to Openshift cluster are needed
2. Check if in the context we have a hub selected. Show the user the hub that is going to be used, and prompt the user to select a different one. Use the list of
   available ones.

From now on, whatever `oc` command will use the KUBECONFIG from the env variable or the context.
From now on, whatever `oc` command will be invoked with `--kubeconfig` param and that KUBECONFIG information.
