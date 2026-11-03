# Local cluster

`deployah cluster` manages a single local Kind cluster:

| Item | Value |
|---|---|
| Cluster name | `deployah` (fixed) |
| Kubernetes context | `kind-deployah` |

## Commands

- `cluster up` — create/start; may scaffold a platform snippet; mutating
- `cluster down` — destructive; explicit approval
- `cluster status` — read-only
- `cluster kubeconfig` — credential-sensitive; never paste raw kubeconfig into
  chat/logs

Point environments at `kind-deployah` via platform `context` or `--context`.
Cluster lifecycle is independent of Deployah environments.
