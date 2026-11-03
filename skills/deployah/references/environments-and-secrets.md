# Environments and secrets

## Substitution vs runtime env

- **Substitution** (`${...}`): driven by spec `variables` and `DPY_VAR_*`
  process env. Dotenv files do **not** feed substitution.
- **Runtime env:** component `env`, dotenv/ConfigMap delivery paths. Separate
  from substitution.

## Resolve exposure

`deployah resolve` prints resolved configuration. Deployah warns that those
maps are **not a secret store** and resolve output is **not secret-safe** CI
output.

Agent rules:

- Do not casually dump `resolve` into chat, tickets, or CI logs.
- Require explicit OK for `resolve`, `plan --show-secrets`, and raw kubeconfig.
- Prefer redacted plan output by default.
