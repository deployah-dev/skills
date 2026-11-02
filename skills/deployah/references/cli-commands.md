# CLI commands

Global persistent flags (from Deployah root):

| Flag | Short | Notes |
|---|---|---|
| `--debug` | `-d` | Verbose logging; keep temp files |
| `--spec` | `-s` | Spec path (default `deployah.yaml`) |
| `--platform-file` | | Platform path override |
| `--namespace` | `-n` | Kubernetes namespace |
| `--kubeconfig` | `-k` | Kubeconfig path |
| `--context` | | Kubernetes context (overrides platform env context) |
| `--timeout` | `-t` | Operation timeout |
| `--cwd` | `-C` | Act as if started in this directory |

## Command map

| Command | Mutating? | Notes |
|---|---|---|
| `init` | writes local files | **TTY required**; agents should write YAML instead |
| `validate` | no | Local schema/contract validation |
| `plan <environment>` | no | Semantic plan; not apply. `-o json`, `--detailed-exitcode` (exit 2 = changes) |
| `deploy <environment>` | **yes** | Always upgrades existing releases; needs explicit approval |
| `resolve` | no (secret risk) | Not secret-safe; avoid dumping in CI/chat |
| `status` | no | Release/pod status |
| `list` | no | List releases/projects |
| `logs` | no | May include secrets from app logs |
| `shell` | interactive / risk | Needs explicit OK |
| `run <task>` | **yes** (Job) | Named task only; confirm first |
| `delete` | **yes** / destructive | Explicit approval; prefer show-resources style flags when available |
| `cluster up` | **yes** | Local Kind cluster `deployah`; context `kind-deployah` |
| `cluster down` | **yes** / destructive | Explicit approval |
| `cluster status` | no | |
| `cluster kubeconfig` | credential risk | Raw kubeconfig is sensitive |

Verify flags with `deployah <command> --help` before use. Do not invent flags.
Do not auto-pass `--yes` / `--force` / `--force-hostname-change` /
`--resize-volumes` / `--skip-crds` unless the user asked for that flag.
