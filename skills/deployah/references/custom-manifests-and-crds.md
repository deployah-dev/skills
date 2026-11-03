# Custom manifests and CRDs

Deployah extras live under `.deployah/`:

- `.deployah/manifests/` — additional manifests (no Deployah templating engine;
  do not invent Go template syntax)
- `.deployah/crds/` — CRDs

## CRD lifecycle

CRDs are install-oriented. Do not assume Deployah upgrades or deletes CRDs the
way it upgrades application releases. `--skip-crds` is a deliberate, user-requested
escape hatch only.

Keep extras environment-aware when the tree uses env subdirectories; follow
existing Deployah examples rather than inventing layouts.
