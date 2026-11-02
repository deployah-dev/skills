# Tasks and hooks

Tasks live in the application spec (`on`: preDeploy, postDeploy, manual,
schedule, and related semantics).

- **Hooks:** pre/post deploy tasks participate in planning (`WillRun` style
  semantics). Plan still does not authorize deploy.
- **`deployah run <task>`:** creates a Job for a named task; does not run
  `after` dependents automatically. Mutating: require approval.
- **Schedule:** CronJob-style tasks; validate cron fields via Deployah, do not
  invent Kubernetes CronJob YAML by hand unless extras require it.
- **`after`:** ordering constraints; respect schema errors on cycles and
  cross-phase edges.

Confirm environment and task name before `run`.
