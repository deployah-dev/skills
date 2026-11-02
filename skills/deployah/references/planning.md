# Planning

`deployah plan` is read-only. It compares **Previous / Live / Desired** release
state using Helm lifecycle semantics (see Deployah ADRs 0004–0016). Plan
describes intent and drift; it does **not** apply changes.

## Rules agents must follow

- Plan success is not apply success.
- Plan output never authorizes `deploy`. Ask for an explicit deploy approval.
- An empty plan / no effects must **not** trigger deploy. If the user still
  wants deploy, warn that Deployah **always upgrades** existing releases
  (new Helm revision, upgrade hooks) even when nothing changed.
- Drift is reported separately from planned effects; do not conflate them.
- Use `plan -o json` for structured parsing.
- Use `--detailed-exitcode` when the question is “are there changes?” (exit `2`
  means changes present; that is not a failure banner path for agents to treat
  as apply).

Planning is not Terraform and not raw `helm diff`. Stay within Deployah’s
semantic plan model.
