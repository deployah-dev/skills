# Contributing

## Layout

Product files (`skills/deployah/`, `plugin.json`, `.claude-plugin/`) are what
consumers install. Maintainer tooling lives under `nix/`:

```text
nix/
├── packages.nix     # custom skills-ref only
├── validate.nix     # product validate + check
├── release.nix      # release artifact + check
├── devshell.nix
├── scripts/
└── fixtures/
```

Consumers do not need Nix.

## Versioning

| Kind | Source |
|---|---|
| Product (skill / plugin) | Root `plugin.json` `.version` |
| Agent Plugins schema | `1.0.0` (`$schema` URL; independent) |
| Deployah CLI / app schemas | Locked `deployah-src` in `flake.lock` |
| skills-ref | Upstream `skills-ref/pyproject.toml` via `agentskills-src` |

Keep product version aligned in `plugin.json`, `.claude-plugin/plugin.json`,
and `SKILL.md` `metadata.version`. `check-product-version.sh` enforces this
(including SemVer 2.0.0). Do not hardcode the product version in scripts.

Author display name: **The Deployah Authors**. Homepage: https://deployah.dev.
Source: https://github.com/deployah-dev/skills.

No changelog file. Use Git history and GitHub Releases. Do not invent tags or
releases without authorization.

## Validation

`checks.validate` / `apps.validate` share one suite. `checks.release` builds
and verifies the release artifact. Both run under `nix flake check`.

```bash
nix develop
nix run .#validate
nix flake check --print-build-logs
```

Dirty checkout:

```bash
DEPLOYAH_SKILLS_ROOT=$PWD nix run .#validate
```

Do not run ad-hoc `pip` / `npm` / `npx` inside mandatory checks.

Untracked files need to be visible to Flakes (`git add -N .` or `git add -A`).

### Pins

```bash
nix flake update deployah-src    # Deployah contract source
nix flake update agentskills-src # skills-ref upstream
nix run .#validate
```

Update skill docs only when CLI/schema **behavior** changes for consumers.
Do not paste Git SHAs into consumer-facing skill files.

Skills CLI comes from locked nixpkgs (`pkgs.skills`).

### Shell quality

```bash
shellcheck -x -e SC1091 nix/scripts/*.sh nix/scripts/lib/*.sh
shfmt -d -i 0 -bn -ci -sr nix/scripts
```

These also run inside `nix run .#validate`.

## Release

Flow: merge to `main` → annotated tag `vX.Y.Z` → workflow prepares a **draft**
GitHub Release with the release artifact → human reviews notes and publishes.
Marketplace submission stays **manual** and is never triggered by CI.

### Version bump

1. Set `.version` in root `plugin.json`.
2. Match `.claude-plugin/plugin.json` and `SKILL.md` `metadata.version`.
3. Update the Product version line in `README.md` if needed.
4. Run `nix flake check --print-build-logs`.

### Local artifact

```bash
nix flake check --print-build-logs
nix build .#release
unzip -l result/deployah-agent-skills-v*.zip
```

The archive root must contain `plugin.json`, `skills/deployah/`,
`.claude-plugin/`, `LICENSE`, and `README.md`. It must not contain `nix/`,
flake files, `.github/`, `evals/`, or `third_party/`.

### Tag (examples only; needs explicit authorization)

```bash
nix flake check --print-build-logs
nix build .#release

git tag -a v0.1.0 -m "Deployah Agent Skills v0.1.0"
git push origin v0.1.0
```

The tag must equal `v` + `plugin.json` version and point at a commit reachable
from `main`. The workflow then:

1. Runs `nix flake check` (product suite + release artifact verification)
2. Builds `nix build .#release`
3. Creates a **draft** GitHub Release with generated notes and the versioned ZIP
4. Marks SemVer prereleases (`X.Y.Z-…`) as GitHub prereleases

If a GitHub Release for that tag already exists, creation is skipped (no
overwrite). Incomplete drafts need a manual fix.

After review, publish the draft in the GitHub UI. Publishing does **not**
update Claude Directory, Cursor Marketplace, Codex Plugin Directory, or other
third-party marketplaces. Submit those separately if needed. The GitHub-hosted
Claude adapter keeps `.claude-plugin/marketplace.json` `source: "./"`; clients
refresh on their own schedule.

## Evals

Author scenarios in `evals/scenarios.json`. Default status is `not_executed`.
Recording agent runs is separate from flake check green.

## Commit policy

No push, PR, tag, or publish without separate authorization.
