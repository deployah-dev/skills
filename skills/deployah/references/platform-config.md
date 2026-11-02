# Platform config (`deployah.platform.yaml`)

Current apiVersion: **`platform/v1-alpha.3`**.

The platform file owns the **environment registry**: named environments,
Kubernetes `context`, domains, TLS modes, and profiles. Application specs
reference environment names; they do not redefine the registry.

## Ownership boundary

| Concerns | Where |
|---|---|
| Environment names, context, domains, TLS, profiles | Platform file |
| Components, tasks, project-level app config | Application spec |

Expose/TLS often needs a platform file. Deploy fails closed when components use
`expose` and no platform file is found.

`--context` on the CLI overrides the platform environment context and warns
when they differ.

See `assets/minimal-app/deployah.platform.yaml`.
