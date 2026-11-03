# Application spec (`deployah.yaml`)

Current apiVersion: **`v1-alpha.5`** only. Reject `v1alpha1` and other spellings
as current.

## Core fields

- `apiVersion`, `project`, `components` (map)
- Component basics: `image`, `port`, `environments`, `expose`, role/kind
- Workers: follow field bans in the schema (no HTTP expose patterns that the
  schema rejects)
- Stateful: persistence rules; volume grow may need `--resize-volumes` with
  explicit approval; shrink is forbidden
- Autoscaling: replicas XOR HPA patterns per schema
- Health probes, command/args, resources requests

## Unsupported / incomplete (do not teach as working)

- **`configFile` mounts** as container volume mounts: not implemented
  (`TODO(#114)` class work). Do not tell users Deployah mounts config files.
- **Resource `limits`:** requests may apply; limits are not applied as
  Kubernetes limits in the current renderer. Say so if asked.
- **Secrets-from-env / inventing Secret objects from dotenv:** not a Deployah
  secret store. Do not claim dotenv becomes a Secret.

Keep examples minimal and valid. See `assets/minimal-app/deployah.yaml`.
