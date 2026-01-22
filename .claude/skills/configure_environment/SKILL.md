---
name: configure_environment
description: Configure environment for ZTP operations by setting up KUBECONFIG and hub selection
allowed-tools: Bash, Read, AskUserQuestion
model: haiku
---

# Configure environment for ZTP

Configure environment to later do whatever other GitOps operations over
the clusters. This command makes you to select the proper Kubeconfig to use,
the hub endpoint.

It takes no arguments. If arguments are provided, notify that the
command does not use arguments.

If in the context we have kubeconfig with a path including '~', convert it to an absolute path.
When the user is prompted to provide a KUBECONFIG show some example and instruct it to only use absolute paths. It cannot use '~'.

Follow these steps:

1. Execute the `check_cluster_kubeconfig.sh` script from the `scripts` directory within this skill
   - If script exits with code 1 (KUBECONFIG not set): Prompt the user to provide the KUBECONFIG path, set it, then re-run the script
   - If script exits with code 2 (connectivity failed): Notify the user that the cluster is not reachable. Prompt the user to provide a new KUBECONFIG path, set it, then re-run the script.
   - If script exits with code 0: Continue to next step

2. Now we will configure the argocd endpoint that we will use to interact with any argocd command. 
   ```
     oc  get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'
   ```

