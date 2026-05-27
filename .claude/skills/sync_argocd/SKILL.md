---
name: sync_argocd
description: Synchronize an ArgoCD application on a hub instance using SSO authentication
allowed-tools: Bash(argocd:*), Bash(sleep:*)
---

# Sync ArgoCD Application

Sync an ArgoCD application. Takes $ARGUMENTS:
1. ArgoCD endpoint (required)
2. Application name (required)
3. Prune flag (optional) - if present, sync with `--prune`

## Steps

### 1. Sync the application

Without prune:

```bash
argocd app sync <app-name> --insecure --grpc-web
```

With prune:

```bash
argocd app sync <app-name> --insecure --grpc-web --prune
```

### 2. Wait for sync completion (prune only)

If prune flag was set, wait up to 5 minutes for the sync to complete:

```bash
argocd app wait <app-name> --insecure --grpc-web --timeout 300
```

If the wait times out, report the timeout and EXIT.
