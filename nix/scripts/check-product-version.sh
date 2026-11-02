#!/usr/bin/env bash
# Ensure product version is consistent across manifests and SKILL metadata.
# Source of truth: root plugin.json .version (not Agent Plugins schema version).
set -euo pipefail

: "${DEPLOYAH_SKILLS_ROOT:?}"
ROOT="$DEPLOYAH_SKILLS_ROOT"

command -v jq > /dev/null || {
	echo "jq missing" >&2
	exit 1
}

fail=0

# SemVer core X.Y.Z with optional pre-release / build metadata (no leading v).
is_semver() {
	[[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-][0-9A-Za-z.-]+)?([+][0-9A-Za-z.-]+)?$ ]]
}

expected="$(jq -r '.version // empty' "$ROOT/plugin.json")"
if [[ -z "$expected" ]]; then
	echo "plugin.json missing .version" >&2
	exit 1
fi
if ! is_semver "$expected"; then
	echo "plugin.json .version is not SemVer: '$expected'" >&2
	exit 1
fi

claude_ver="$(jq -r '.version // empty' "$ROOT/.claude-plugin/plugin.json")"
if [[ -z "$claude_ver" ]]; then
	echo ".claude-plugin/plugin.json missing .version" >&2
	fail=1
elif [[ "$claude_ver" != "$expected" ]]; then
	echo ".claude-plugin/plugin.json version is '$claude_ver', expected $expected (from plugin.json)" >&2
	fail=1
fi

# Agent Plugins schema URL must remain the specification version, not product version.
schema="$(jq -r '."$schema" // empty' "$ROOT/plugin.json")"
case "$schema" in
	*"/schemas/1.0.0/"*) ;;
	*)
		echo "plugin.json \$schema must reference Agent Plugins 1.0.0, got: $schema" >&2
		fail=1
		;;
esac

skill_ver="$(
	awk '
    BEGIN { in_fm=0 }
    /^---[[:space:]]*$/ { if (in_fm) exit; in_fm=1; next }
    in_fm && /^[[:space:]]*version:/ {
      sub(/^[^:]*:[[:space:]]*/, "")
      gsub(/["[:space:]]/, "")
      print
      exit
    }
  ' "$ROOT/skills/deployah/SKILL.md"
)"
if [[ -z "$skill_ver" ]]; then
	echo "SKILL.md missing metadata.version" >&2
	fail=1
elif [[ "$skill_ver" != "$expected" ]]; then
	echo "SKILL.md metadata.version is '$skill_ver', expected $expected (from plugin.json)" >&2
	fail=1
fi

# Fail if deleted maintainer/consumer coupling resurfaces in product/docs.
if grep -R --line-number -E 'deployah_commit|references/compatibility\.md|nix/scripts/regressions\.sh' \
	"$ROOT/skills" "$ROOT/README.md" "$ROOT/CONTRIBUTING.md" "$ROOT/SECURITY.md" \
	"$ROOT/evals" "$ROOT/plugin.json" "$ROOT/.claude-plugin" 2> /dev/null; then
	echo "obsolete pin/compat/regression references found (see above)" >&2
	fail=1
fi

exit "$fail"
