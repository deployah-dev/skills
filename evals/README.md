# Evaluations

`scenarios.json` lists **24** agent evaluation scenarios. Authoring them is not
the same as executing them.

## Status values

| Status | Meaning |
|---|---|
| `passed` | Executed against an agent with recorded evidence |
| `failed` | Executed and did not meet `pass_criteria` |
| `skipped` | Intentionally not run |
| `not_executed` | Default for newly authored scenarios |

Mandatory `nix flake check` / `nix run .#validate` does **not** require the 24
manual agent runs. It only checks scenario shape and completeness.

Do not claim agent-verified support in the README until results are recorded
with `passed`/`failed` evidence (use `results.template.json`).
