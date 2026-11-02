#!/usr/bin/env bash
# Structural checks: skills-ref, single skill, relative links.
set -euo pipefail

: "${DEPLOYAH_SKILLS_ROOT:?}"
ROOT="$DEPLOYAH_SKILLS_ROOT"
SKILL_DIR="$ROOT/skills/deployah"
SKILL_MD="$SKILL_DIR/SKILL.md"

command -v skills-ref > /dev/null || {
	echo "skills-ref missing" >&2
	exit 1
}

skills-ref validate "$SKILL_DIR"

skill_count="$(find "$ROOT/skills" -type f -name 'SKILL.md' | wc -l | tr -d ' ')"
if [[ "$skill_count" != "1" ]]; then
	echo "expected exactly 1 SKILL.md under skills/, found $skill_count" >&2
	exit 1
fi

[[ -f "$SKILL_MD" ]] || {
	echo "missing $SKILL_MD" >&2
	exit 1
}

skill_dir_real="$(cd "$SKILL_DIR" && pwd -P)"
missing=0
# Extract markdown link targets: ](path) excluding URLs and mailto.
while IFS= read -r target; do
	[[ -z "$target" ]] && continue
	case "$target" in
		http://* | https://* | mailto:*) continue ;;
	esac
	# Strip fragment.
	target="${target%%#*}"
	[[ -z "$target" ]] && continue
	resolved="$(cd "$SKILL_DIR" && realpath -m -- "$target")"
	case "$resolved" in
		"$skill_dir_real" | "$skill_dir_real"/*) ;;
		*)
			echo "link escapes skill dir: $target" >&2
			missing=1
			continue
			;;
	esac
	if [[ ! -e "$resolved" ]]; then
		echo "missing link target: $target" >&2
		missing=1
	fi
done < <(grep -oE '\]\([^)]+\)' "$SKILL_MD" | sed -E 's/^\]\((.*)\)$/\1/' || true)

if [[ "$missing" -ne 0 ]]; then
	exit 1
fi
