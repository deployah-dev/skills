#!/usr/bin/env bash
# Assemble the release artifact (ZIP) for Agent Plugins / Claude Code layout.
# Usage: package-release.sh <skills-repo-root> <output-dir>
#
# Writes only: deployah-agent-skills-v<version>.zip (plugin.json at archive root).
set -euo pipefail

ROOT="${1:?usage: package-release.sh <root> <out-dir>}"
OUT="${2:?usage: package-release.sh <root> <out-dir>}"

command -v jq > /dev/null || {
	echo "jq missing" >&2
	exit 1
}
command -v zip > /dev/null || {
	echo "zip missing" >&2
	exit 1
}

version="$(jq -r '.version // empty' "$ROOT/plugin.json")"
if [[ -z "$version" ]]; then
	echo "plugin.json missing .version" >&2
	exit 1
fi

zip_name="deployah-agent-skills-v${version}.zip"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

mkdir -p "$stage/skills"

cp "$ROOT/plugin.json" "$stage/plugin.json"
cp "$ROOT/LICENSE" "$stage/LICENSE"
cp "$ROOT/README.md" "$stage/README.md"
cp -a "$ROOT/skills/deployah" "$stage/skills/deployah"
cp -a "$ROOT/.claude-plugin" "$stage/.claude-plugin"

# Deterministic archive metadata.
export SOURCE_DATE_EPOCH=0
find "$stage" -exec touch -d "@${SOURCE_DATE_EPOCH}" {} +
find "$stage" -type d -exec chmod 755 {} +
find "$stage" -type f -exec chmod 644 {} +

mkdir -p "$OUT"
rm -f "$OUT/$zip_name"

(
	cd "$stage"
	find . -type f | sed 's|^\./||' | LC_ALL=C sort | zip -X -@ "$OUT/$zip_name"
)

unzip -Z1 "$OUT/$zip_name" | grep -qx 'plugin.json' || {
	echo "release artifact missing root plugin.json" >&2
	exit 1
}

echo "$OUT/$zip_name"
