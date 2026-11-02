# Deployah Agent Skills

Official Deployah-maintained AI skills and plugins for configuring, deploying,
and managing applications with [Deployah](https://deployah.dev).

This repository follows the open [Agent Skills](https://agentskills.io) and
[Agent Plugins](https://agent-plugins.org) specifications, and ships a Claude Code
plugin adapter where that client needs its own packaging format. It is
**not** a certification or endorsement by the organizations that publish those
specifications.

Consumers install the skill or plugin **without Nix**. Nix is for maintainers
and CI only.

**Product version:** `0.1.0` (early release; cross-agent behavior is not fully
verified yet).

Source: [github.com/deployah-dev/skills](https://github.com/deployah-dev/skills).

## What the Deployah skill can do

| Capability | Description |
|---|---|
| Application configuration | Author and maintain `deployah.yaml` |
| Platform configuration | Configure `deployah.platform.yaml` |
| Validation | Validate Deployah configuration |
| Planning | Inspect proposed release changes with `deployah plan` |
| Deployment | Assist with controlled `deployah deploy` (explicit approval required) |
| Environments and secrets | Configure environments; respect resolve/secret limits |
| Tasks | Work with hooks and `deployah run` for named tasks |
| Local development | Work with Deployah's local Kind cluster |
| Troubleshooting | Inspect status, logs, and common failures |
| Custom manifests | Work with supported `.deployah` manifests and CRDs |

Mutating and sensitive operations stay under **explicit user authorization**.
Plan output never authorizes deploy.

Current schemas: application `v1-alpha.5`, platform `platform/v1-alpha.3`.

## Supported AI agents

Statuses describe evidence for **this** repository, not general product marketing.

Evidence levels:

- **Documented** — install path written from public client docs or packaging layout
- **Skills CLI discovery** — maintainer check that the generic Skills CLI lists `deployah` from this repo (not a client install test)
- **Not agent-tested** — no recorded install or multi-turn run in that client
- **Not tested** — no evidence beyond possible spec compatibility

| Agent | Agent Skills | Agent Plugins / packaging | Install path | Status |
|---|---|---|---|---|
| Claude Code | Yes (via plugin skills discovery) | Claude Code plugin (`.claude-plugin/`) | Local / GitHub-hosted marketplace adapter | Documented — not agent-tested |
| Cursor | Yes | Agent Plugins root `plugin.json` | Skills CLI or local AP plugin | Documented — not agent-tested |
| OpenAI Codex | Typical Skills install paths | — | Documented Skills CLI / local skills dir | Documented — not agent-tested |
| GitHub Copilot | Where Copilot loads Agent Skills | — | Documented when path is known | Not tested |
| Gemini CLI | Experimental / client-dependent | — | Documented when path is known | Not tested |
| OpenCode | Where OpenCode loads Agent Skills | — | Documented Skills-style install | Not tested |

Maintainer validation includes Skills CLI discovery for this repository. That
check is **not** attributed to any single AI client. Manual scenarios in
`evals/` remain `not_executed` until someone records runs. Marketplace
publication is separate and is not claimed here.

## Plugin distributions

| Distribution | Location | Purpose |
|---|---|---|
| Agent Skills | `skills/deployah/SKILL.md` | Portable skill instructions (one canonical body) |
| Agent Plugins | `plugin.json` | Open plugin packaging (schema `1.0.0`) |
| Claude Code plugin | `.claude-plugin/` | Claude-specific marketplace / plugin adapter |

`.claude-plugin/` does **not** duplicate the skill. It points Claude Code at
the same `skills/` tree. Cursor uses the root Agent Plugins manifest; there is
no `.cursor-plugin/`.

## Installation

### Skills CLI

```bash
npx skills add deployah-dev/skills
```

List without installing:

```bash
npx skills add deployah-dev/skills --list
```

### Claude Code

Add this repository as a Claude Code marketplace or local plugin using the
official [Claude Code plugins](https://code.claude.com/docs/en/plugins) flow.
Install the `deployah` plugin; skills load from `skills/` by default.

### Cursor

Use the Skills CLI above, or load the repo as a local Agent Plugins package
per [Cursor plugins](https://cursor.com/docs/plugins) documentation (for
example a temporary copy under the local plugins directory). Do not create
outbound symlinks from this repository into Cursor config.

### Other agents

Follow each client's Agent Skills install docs when available. Treat those
paths as **documented**, not fully tested, until recorded in `evals/`.

## Usage

Typical agent workflow:

1. Confirm `deployah` is installed (`deployah version`).
2. Author or edit `deployah.yaml` / `deployah.platform.yaml` for `v1-alpha.5` /
   `platform/v1-alpha.3`.
3. Run `deployah validate`, then `deployah plan <environment>`.
4. Ask before any mutate (`deploy`, `run`, `delete`, `cluster up/down`).

See `skills/deployah/SKILL.md` and `skills/deployah/references/` for detail.

## Requirements and limitations

- Deployah CLI that supports the schemas and commands this skill documents
- Kubernetes access for cluster operations (plan/deploy/status/logs/…)
- Agents must not treat empty plans as deploy approval
- `deployah init` needs a TTY; non-interactive agents should write YAML
- `resolve` and secret-bearing outputs are not safe to dump into CI or chat
- Some schema fields exist but are unfinished in Deployah (for example
  `configFile` mounts; resource `limits` not applied as Kubernetes limits)

## Development

Maintainer tooling (Nix):

```bash
nix develop
nix flake check --print-build-logs
nix run .#validate
nix build .#release
# dirty local tree (explicit):
DEPLOYAH_SKILLS_ROOT=$PWD nix run .#validate
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for pins, validation, versioning, and
cutting a GitHub Release. Consumers do not need Nix.

## License

[Apache-2.0](LICENSE)
