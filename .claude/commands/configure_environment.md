# Configure environment for ZTP
Configure environment to later do whatever other GitOps operations over
the clusters. This command makes you to select the proper Kubeconfig to use,
the hub endpoint.
It takes no arguments. If arguments are provided  exist, and notify that the
command does not use argumetns.

if in the context we have kubeconfig with a path including '~', conver it to a absolute path
When the user is promt to provide a KUBECONFIG show some example and instruct it to only use absolute paths. It cannot
use '~'.

Follow these steps
1. Execute the `check_cluster_kubeconfig.sh` script from the `.claude/commands/scripts` directory
   - If script exits with code 1 (KUBECONFIG not set): Prompt the user to provide the KUBECONFIG path, set it, then re-run the script
   - If script exits with code 2 (connectivity failed): Notify the user that the cluster is not reachable. Promt the
     user to provide a new KUBECONFIG path, set it, then re-run the script.
   - If script exits with code 0: Continue to next step
2. Check if in the context we have a hub selected. Show the user the hub that is going to be used, and prompt the user to select a different one. Use the list of
   available ones.

From now on, whatever `oc` command will use the KUBECONFIG from the env variable or the context.
From now on, whatever `oc` command will be invoked with `--kubeconfig` param and that KUBECONFIG information.
