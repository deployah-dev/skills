#!/usr/bin/env bash
# Product version consistency. Source of truth: root plugin.json .version.
# Agent Plugins $schema version is independent and is not derived from product version.
set -euo pipefail

: "${DEPLOYAH_SKILLS_ROOT:?}"
ROOT="$DEPLOYAH_SKILLS_ROOT"

command -v jq > /dev/null || {
	echo "jq missing" >&2
	exit 1
}

fail=0

# SemVer 2.0.0 (no leading zeros in numeric identifiers).
is_semver() {
	[[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$ ]]
}

expected="$(jq -r '.version // empty' "$ROOT/plugin.json")"
if [[ -z "$expected" ]]; then
	echo "plugin.json missing .version" >&2
	exit 1
fi
if ! is_semver "$expected"; then
	echo "plugin.json .version is not SemVer 2.0.0: '$expected'" >&2
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
