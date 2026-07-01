---
name: ztp_sync_argocd
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
