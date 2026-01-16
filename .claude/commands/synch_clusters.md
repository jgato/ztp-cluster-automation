# Synch ZTP clusters
To sync an ArgoCD application on a proper hub. More in concrete, in the ArgoCD
instance of the selected hub.
It takes two mandatory arguments (#$ARGUMENTS), one the endpoing for the ArgoCd instance, and a second one
with the name of the ArgoCD application to sync. If some of the mandatory params are not there, exit and explain
the reason.
There is a third argument that would indicate if we have to prune. That means, that the sync process needs the argocd
command to use the prune option.

Show the user the hub and the app seelected.

For all the argocd commands use `--insecure` param.

Follow these steps:
1. Show the details of what we are going to do, in which hub, which application, and if prune.
2. Check if we are already loged in to the ArgoCD Instance. If not use argocd login command to login in the ArgoCD instance of the hub. The login command needs the `--sso` param to open
   an interactive login into a webpage.
3. Refresh and sync the selected application. If we have the prune option, sync the app with the `--prune` param. If we
   sync with prune, the removal of a ClusterIntance would take several minutes. Ideally, not more than 5 minutes. Check
   from time to time an wait until sync. After 5 minutes give an error and exit
