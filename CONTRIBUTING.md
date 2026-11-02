# Contributing

## Layout

Product files (`skills/deployah/`, `plugin.json`, `.claude-plugin/`) are the
consumer deliverable. Maintainer tooling lives under `nix/`:

```text
nix/
├── packages.nix     # custom skills-ref only
├── validate.nix     # shared validate + check wiring
├── release.nix      # consumer ZIP packaging
├── devshell.nix
├── scripts/         # pure Bash product validation and packaging
└── fixtures/
```

Consumers do not need Nix.

## Versioning

| Kind | Value / source |
|---|---|
| Product (skill / plugin) | Root `plugin.json` `.version` (authoritative) |
| Agent Plugins schema | `1.0.0` (manifest `$schema` URL; independent) |
| Deployah CLI / app schemas | Independent; contracts read from locked `deployah-src` |
| skills-ref (Nix package) | Upstream `skills-ref/pyproject.toml` via `agentskills-src` |

Keep product version aligned in:

- `plugin.json`
- `.claude-plugin/plugin.json`
- `skills/deployah/SKILL.md` `metadata.version`

Validate enforces this. Do not hardcode the product version in scripts.

Author display name: **The Deployah Authors**. Homepage: https://deployah.dev.
Source repository: https://github.com/deployah-dev/skills.

Do not maintain a separate changelog file. Use Git history and GitHub Releases
when you cut a release. Do not invent tags or releases without authorization.

## Validation

`checks.validate` and `apps.validate` share one derivation and the same
mandatory product suite. Default source is immutable flake `self`.

```bash
nix develop
nix run .#validate
nix flake check --print-build-logs
```

Dirty checkout (explicit override):

```bash
DEPLOYAH_SKILLS_ROOT=$PWD nix run .#validate
```

Do not run ad-hoc `pip` / `npm` / `npx` inside mandatory checks.

### Untracked files and Flakes

```bash
git add -N .   # or git add -A without committing
nix flake check --print-build-logs
```

### Updating the Deployah contract pin

`flake.lock` is the only Deployah revision source of truth.

```bash
nix flake update deployah-src
nix run .#validate
```

Update skill docs only when CLI/schema **behavior** consumers need changes
(for example a new current `apiVersion`). Do not paste Git SHAs into
consumer-facing skill files.

### Updating skills-ref

```bash
nix flake update agentskills-src
nix run .#validate
```

Skills CLI comes from locked nixpkgs (`pkgs.skills`).

### Shell quality

```bash
shellcheck -x -e SC1091 nix/scripts/*.sh nix/scripts/lib/*.sh
shfmt -d -i 0 -bn -ci -sr nix/scripts
```

These also run inside `nix run .#validate`.

## Release

GitHub Releases are the canonical binary distribution for the consumer ZIP.
Third-party marketplace submission stays **manual**.

### Product version bump

1. Set `.version` in root `plugin.json`.
2. Match `.claude-plugin/plugin.json` and `SKILL.md` `metadata.version`.
3. Update the Product version line in `README.md` if it still shows the old value.
4. Run `nix flake check --print-build-logs` and `nix run .#validate`.

### Local artifact

```bash
nix flake check --print-build-logs
nix build .#release
unzip -l result/deployah-agent-skills-v*.zip
```

The ZIP root must contain `plugin.json`, `skills/deployah/`, `.claude-plugin/`,
`LICENSE`, and `README.md`. It must not contain `nix/`, flake files, `.github/`,
`evals/`, or `third_party/`.

### Tag and publish

After the release commit is on `main` and explicitly approved:

```bash
# Examples only — do not run without release authorization.
nix flake check --print-build-logs
nix build .#release

git tag -a v0.1.0 -m "Deployah Agent Skills v0.1.0"
git push origin v0.1.0
```

Pushing `vX.Y.Z` runs `.github/workflows/release.yml`, which:

1. Checks the tag is SemVer and matches `plugin.json`
2. Checks the tag commit is reachable from `main`
3. Runs `nix flake check --print-build-logs`
4. Builds `nix build .#release` and verifies the ZIP
5. Creates a GitHub Release titled `Deployah Agent Skills vX.Y.Z` with the ZIP

If a GitHub Release for that tag already exists, publish is skipped (no
overwrite). Fix incomplete releases by hand.

### Marketplaces

Do not automate Claude Directory, Cursor Marketplace, Codex Plugin Directory,
or other third-party submissions from CI. After a GitHub Release:

1. Confirm the ZIP and tag match
2. Follow each marketplace's current submission or refresh process separately
3. Keep `.claude-plugin/marketplace.json` `source: "./"` for the GitHub-hosted
   Claude adapter; clients refresh on their own schedule

## Evals

Author scenarios in `evals/scenarios.json`. Default status is `not_executed`.
Recording agent runs is separate from flake check green.

## Commit policy

No push, PR, tag, or publish without separate authorization.
