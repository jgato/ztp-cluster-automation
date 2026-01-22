# Synch ZTP clusters

Sync an ArgoCD application on a hub instance.

Takes #$ARGUMENTS:
1. ArgoCD endpoint (required)
2. Application name (required)
3. Prune flag (optional) - if present, sync with `--prune`

## Steps

1. Show details: hub endpoint, application name, prune option.

2. Check ArgoCD login status. If not logged in, use `argocd login --sso --insecure` to authenticate.

3. Refresh and sync the application:
   - Use `--insecure` for all argocd commands
   - If prune option: sync with `--prune` param
   - If prune: wait up to 5 minutes for sync to complete, checking periodically
