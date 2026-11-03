#!/usr/bin/env bash
# Verify a packaged release artifact against expected consumer layout.
# Usage: verify-release-artifact.sh <zip-path> <repo-root-for-schema>
#
# repo-root supplies third_party schema only; it is not added to the artifact.
set -euo pipefail

ZIP="${1:?usage: verify-release-artifact.sh <zip> <repo-root>}"
REPO="${2:?usage: verify-release-artifact.sh <zip> <repo-root>}"

command -v jq > /dev/null || {
	echo "jq missing" >&2
	exit 1
}
command -v unzip > /dev/null || {
	echo "unzip missing" >&2
	exit 1
}
command -v check-jsonschema > /dev/null || {
	echo "check-jsonschema missing" >&2
	exit 1
}

base="$(basename "$ZIP")"
if [[ ! "$base" =~ ^deployah-agent-skills-v.+\.zip$ ]]; then
	echo "unexpected release artifact name: $base" >&2
	exit 1
fi
tag_version="${base#deployah-agent-skills-v}"
tag_version="${tag_version%.zip}"

# Reject unsafe / maintainer-only archive members before extract.
while IFS= read -r member; do
	[[ -n "$member" ]] || continue
	case "$member" in
		/* | *..*)
			echo "unsafe archive member: $member" >&2
			exit 1
			;;
		nix | nix/* | flake.nix | flake.lock | .github | .github/* | evals | evals/* | third_party | third_party/* | .git | .git/*)
			echo "maintainer-only path in artifact: $member" >&2
			exit 1
			;;
	esac
done < <(unzip -Z1 "$ZIP")

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
unzip -q "$ZIP" -d "$tmp"

# Expected top-level consumer layout only.
while IFS= read -r entry; do
	[[ -n "$entry" ]] || continue
	case "$entry" in
		plugin.json | LICENSE | README.md | skills | .claude-plugin) ;;
		*)
			echo "unexpected top-level path in artifact: $entry" >&2
			exit 1
			;;
	esac
done < <(find "$tmp" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort)

required=(
	plugin.json
	LICENSE
	README.md
	skills/deployah/SKILL.md
	.claude-plugin/plugin.json
	.claude-plugin/marketplace.json
)
for f in "${required[@]}"; do
	if [[ ! -f "$tmp/$f" ]]; then
		echo "release artifact missing $f" >&2
		exit 1
	fi
done

# Single canonical skill body.
skill_count="$(find "$tmp/skills" -type f -name 'SKILL.md' | wc -l | tr -d ' ')"
if [[ "$skill_count" != "1" ]]; then
	echo "expected exactly one SKILL.md, found $skill_count" >&2
	exit 1
fi

plugin_ver="$(jq -r '.version // empty' "$tmp/plugin.json")"
claude_ver="$(jq -r '.version // empty' "$tmp/.claude-plugin/plugin.json")"
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
  ' "$tmp/skills/deployah/SKILL.md"
)"

if [[ -z "$plugin_ver" || "$plugin_ver" != "$tag_version" ]]; then
	echo "artifact name version '$tag_version' does not match plugin.json '$plugin_ver'" >&2
	exit 1
fi
if [[ "$claude_ver" != "$plugin_ver" ]]; then
	echo "claude plugin version '$claude_ver' != plugin.json '$plugin_ver'" >&2
	exit 1
fi
if [[ "$skill_ver" != "$plugin_ver" ]]; then
	echo "SKILL.md version '$skill_ver' != plugin.json '$plugin_ver'" >&2
	exit 1
fi

schema="$(jq -r '."$schema" // empty' "$tmp/plugin.json")"
case "$schema" in
	*"/schemas/1.0.0/"*) ;;
	*)
		echo "packaged plugin.json \$schema must reference Agent Plugins 1.0.0, got: $schema" >&2
		exit 1
		;;
esac

schema_file="$REPO/third_party/agent-plugins/plugin.schema.json"
if [[ ! -f "$schema_file" ]]; then
	echo "missing schema file: $schema_file" >&2
	exit 1
fi
check-jsonschema --schemafile "$schema_file" "$tmp/plugin.json"

# Relative reference paths mentioned in SKILL.md should exist in the archive.
while IFS= read -r ref; do
	[[ -n "$ref" ]] || continue
	if [[ ! -e "$tmp/skills/deployah/$ref" ]]; then
		echo "SKILL.md references missing path: $ref" >&2
		exit 1
	fi
done < <(
	grep -oE 'references/[A-Za-z0-9._-]+\.md|assets/[A-Za-z0-9./_-]+' \
		"$tmp/skills/deployah/SKILL.md" | sort -u || true
)

echo "release artifact ok: $base"
