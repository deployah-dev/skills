#!/usr/bin/env bash
# Orchestrator for the mandatory product validation suite.
# Invoked only via the Nix validate package (or an equivalent PATH).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh disable=SC1091
source "$SCRIPT_DIR/lib/common.sh"

export VALIDATE_SCRIPTS_ROOT="$SCRIPT_DIR"
if [[ -f "$SCRIPT_DIR/../fixtures/behavioral-contracts.yaml" ]]; then
	export DEPLOYAH_FIXTURES="$SCRIPT_DIR/../fixtures/behavioral-contracts.yaml"
elif [[ -f "$ROOT/nix/fixtures/behavioral-contracts.yaml" ]]; then
	export DEPLOYAH_FIXTURES="$ROOT/nix/fixtures/behavioral-contracts.yaml"
fi

require_cmd skills-ref
require_cmd skills
require_cmd check-jsonschema
require_cmd jq
require_cmd yq

run_check() {
	local name="$1" kind="$2"
	shift 2
	local out err code
	out="$(mktemp)"
	err="$(mktemp)"
	set +e
	"$@" > "$out" 2> "$err"
	code=$?
	set -e
	if [[ $code -eq 0 ]]; then
		record "$name" "$kind" "passed" "$(tr '\n' ' ' < "$out" | head -c 200)"
	else
		record "$name" "$kind" "failed" "$(tr '\n' ' ' < "$err" | head -c 400)"
		cat "$err" >&2 || true
	fi
	rm -f "$out" "$err"
}

echo "Deployah skills validate"
echo "  ROOT=$ROOT"
echo "  DEPLOYAH_SRC=$DEPLOYAH_SRC"
echo "  HOME=$HOME"
echo "  SCRIPTS=$SCRIPT_DIR"

run_check "skills-structure" "mandatory" bash "$SCRIPT_DIR/validate-skill.sh"
run_check "plugin-manifests" "mandatory" bash "$SCRIPT_DIR/validate-plugin-manifests.sh"
run_check "product-version" "mandatory" bash "$SCRIPT_DIR/check-product-version.sh"
run_check "cli-contract" "mandatory" bash "$SCRIPT_DIR/check-cli-contract.sh"
run_check "discovery-smoke" "mandatory" bash "$SCRIPT_DIR/smoke-discover.sh"

shell_files=(
	"$SCRIPT_DIR/validate-all.sh"
	"$SCRIPT_DIR/validate-skill.sh"
	"$SCRIPT_DIR/validate-plugin-manifests.sh"
	"$SCRIPT_DIR/check-product-version.sh"
	"$SCRIPT_DIR/check-cli-contract.sh"
	"$SCRIPT_DIR/smoke-discover.sh"
	"$SCRIPT_DIR/package-release.sh"
	"$SCRIPT_DIR/verify-release-artifact.sh"
	"$SCRIPT_DIR/lib/common.sh"
)

if command -v shellcheck > /dev/null 2>&1; then
	run_check "shellcheck" "mandatory" shellcheck -x -e SC1091 "${shell_files[@]}"
else
	record "shellcheck" "mandatory" "failed" "shellcheck not on PATH"
fi

if command -v shfmt > /dev/null 2>&1; then
	run_check "shfmt" "mandatory" shfmt -d -i 0 -bn -ci -sr "${shell_files[@]}"
else
	record "shfmt" "mandatory" "failed" "shfmt not on PATH"
fi

write_report "$REPORT_JSON"

if mandatory_all_passed; then
	echo "all mandatory checks passed"
	exit 0
fi

echo "one or more mandatory checks did not pass" >&2
exit 1
