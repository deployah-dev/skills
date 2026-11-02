#!/usr/bin/env bash
# Validate Agent Plugins root manifest and Claude adapter coherence.
set -euo pipefail

: "${DEPLOYAH_SKILLS_ROOT:?}"
ROOT="$DEPLOYAH_SKILLS_ROOT"
SCHEMA="$ROOT/third_party/agent-plugins/plugin.schema.json"
PLUGIN="$ROOT/plugin.json"
CLAUDE_PLUGIN="$ROOT/.claude-plugin/plugin.json"
CLAUDE_MARKET="$ROOT/.claude-plugin/marketplace.json"

command -v check-jsonschema > /dev/null || {
	echo "check-jsonschema missing" >&2
	exit 1
}
command -v jq > /dev/null || {
	echo "jq missing" >&2
	exit 1
}

[[ -f "$SCHEMA" ]] || {
	echo "missing vendored schema: $SCHEMA" >&2
	exit 1
}
check-jsonschema --schemafile "$SCHEMA" "$PLUGIN"

fail=0
if ! jq -e '
  (.name | type == "string" and length > 0)
  and (.version | type == "string" and length > 0)
  and (.description | type == "string" and length > 0)
  and (has("skills") | not)
' "$CLAUDE_PLUGIN" > /dev/null; then
	echo "claude plugin.json missing required fields or unexpectedly sets skills" >&2
	fail=1
fi

if ! jq -e '
  (.plugins | type == "array")
  and (.plugins | length > 0)
  and (.plugins[0].source == "./")
' "$CLAUDE_MARKET" > /dev/null; then
	echo "marketplace.json must have plugins[0].source == \"./\"" >&2
	fail=1
fi

if [[ ! -f "$ROOT/skills/deployah/SKILL.md" ]]; then
	echo "skills/deployah/SKILL.md missing relative to marketplace source ./" >&2
	fail=1
fi

exit "$fail"
