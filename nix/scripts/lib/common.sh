#!/usr/bin/env bash
# Shared helpers for validation scripts. Sourced only; not executed.

set -euo pipefail

: "${DEPLOYAH_SKILLS_ROOT:?DEPLOYAH_SKILLS_ROOT must be set}"
: "${DEPLOYAH_SRC:?DEPLOYAH_SRC must be set}"

ROOT="$DEPLOYAH_SKILLS_ROOT"
# Exported for sourced scripts that want a stable skill path.
export SKILL_DIR="$ROOT/skills/deployah"
REPORT_DIR="${REPORT_DIR:-$(mktemp -d)}"
REPORT_JSON="${REPORT_JSON:-$REPORT_DIR/validation-report.json}"

mkdir -p "$REPORT_DIR"

declare -a CHECK_NAMES=()
declare -a CHECK_KINDS=()
declare -a CHECK_STATUSES=()
declare -a CHECK_DETAILS=()

record() {
	local name="$1" kind="$2" status="$3" detail="${4:-}"
	CHECK_NAMES+=("$name")
	CHECK_KINDS+=("$kind")
	CHECK_STATUSES+=("$status")
	CHECK_DETAILS+=("$detail")
	printf '[%s/%s] %s%s\n' "$kind" "$status" "$name" "${detail:+: $detail}"
}

require_cmd() {
	local cmd="$1"
	if ! command -v "$cmd" > /dev/null 2>&1; then
		echo "mandatory tool missing: $cmd" >&2
		exit 1
	fi
}

# Encode a Bash string array as a JSON array via jq.
json_string_array() {
	jq -n '$ARGS.positional' --args -- "$@"
}

write_report() {
	local out="$1"
	local names_json statuses_json kinds_json details_json
	names_json="$(json_string_array "${CHECK_NAMES[@]}")"
	kinds_json="$(json_string_array "${CHECK_KINDS[@]}")"
	statuses_json="$(json_string_array "${CHECK_STATUSES[@]}")"
	details_json="$(json_string_array "${CHECK_DETAILS[@]}")"

	jq -n \
		--argjson names "$names_json" \
		--argjson kinds "$kinds_json" \
		--argjson statuses "$statuses_json" \
		--argjson details "$details_json" \
		--arg deployah_src "${DEPLOYAH_SRC:-}" \
		--arg skills_root "${DEPLOYAH_SKILLS_ROOT:-}" \
		'
    ($names | length) as $n
    | [
        range(0; $n)
        | {
            name: $names[.],
            kind: $kinds[.],
            status: $statuses[.],
            detail: $details[.]
          }
      ] as $checks
    | ($checks | map(select(.kind == "mandatory" and .status != "passed"))) as $bad
    | {
        schema_version: 1,
        deployah_src: $deployah_src,
        skills_root: $skills_root,
        checks: $checks,
        mandatory_not_passed: ($bad | length),
        ok: (($bad | length) == 0)
      }
    ' > "$out"
	echo "report: $out"
}

# Succeed only when every mandatory check has status passed.
mandatory_all_passed() {
	local i
	for i in "${!CHECK_STATUSES[@]}"; do
		if [[ "${CHECK_KINDS[$i]}" == "mandatory" && "${CHECK_STATUSES[$i]}" != "passed" ]]; then
			return 1
		fi
	done
	return 0
}
