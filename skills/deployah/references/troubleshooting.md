# Troubleshooting

Order of operations:

1. `deployah status` for the environment/release
2. `deployah logs` (warn that logs may contain secrets)
3. `deployah plan` if intent vs live state is unclear
4. `deployah shell` only with explicit OK

## Common situations

- **Pending revision / failed hooks:** inspect status and Helm revision notes;
  do not blindly redeploy without approval.
- **Wrong context:** confirm platform context vs `--context` before mutate.
- **Validate failures:** fix schema/contract locally before plan/deploy.
- **Expose without platform:** add `deployah.platform.yaml` or pass
  `--platform-file`.

Never “fix” a stuck release by auto-running `delete` or `cluster down`.
