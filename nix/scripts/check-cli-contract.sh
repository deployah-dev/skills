#!/usr/bin/env bash
# Source-backed CLI/schema/behavioral contract checks against DEPLOYAH_SRC.
set -euo pipefail

: "${DEPLOYAH_SKILLS_ROOT:?}"
: "${DEPLOYAH_SRC:?}"

command -v jq > /dev/null || {
	echo "jq missing" >&2
	exit 1
}
command -v yq > /dev/null || {
	echo "yq missing" >&2
	exit 1
}
command -v check-jsonschema > /dev/null || {
	echo "check-jsonschema missing" >&2
	exit 1
}

ROOT="$DEPLOYAH_SKILLS_ROOT"
DEPLOYAH="$DEPLOYAH_SRC"
SKILL="$ROOT/skills/deployah"
REFS="$SKILL/references"
CLI_DOC="$REFS/cli-commands.md"
ASSETS="$SKILL/assets/minimal-app"
if [[ -n "${DEPLOYAH_FIXTURES:-}" ]]; then
	FIXTURES="$DEPLOYAH_FIXTURES"
elif [[ -n "${VALIDATE_SCRIPTS_ROOT:-}" && -f "$VALIDATE_SCRIPTS_ROOT/../fixtures/behavioral-contracts.yaml" ]]; then
	FIXTURES="$VALIDATE_SCRIPTS_ROOT/../fixtures/behavioral-contracts.yaml"
else
	FIXTURES="$ROOT/nix/fixtures/behavioral-contracts.yaml"
fi

errors=()
err() { errors+=("$1"); }

# --- Command registration from root.go ---
root_go="$DEPLOYAH/internal/cmd/root.go"
[[ -f "$root_go" ]] || err "missing $root_go"

mapfile -t registered < <(grep -E '^\s+\w+\.Register\(app\)$' "$root_go" | sed -E 's/^\s+([A-Za-z0-9_]+)\.Register\(app\)$/\1/' | sort -u)

expected=(cluster delete deploy initialize list logs planCmd resolve run shell status validate)
expected_sorted="$(printf '%s\n' "${expected[@]}" | sort | tr '\n' ' ')"
got_sorted="$(printf '%s\n' "${registered[@]}" | sort | tr '\n' ' ')"
if [[ "$expected_sorted" != "$got_sorted" ]]; then
	err "unexpected Register set in root.go: ${registered[*]}"
fi

cli_alias() {
	case "$1" in
		planCmd) echo plan ;;
		initialize) echo init ;;
		*) echo "$1" ;;
	esac
}

[[ -f "$CLI_DOC" ]] || err "missing $CLI_DOC"
for pkg in "${registered[@]}"; do
	name="$(cli_alias "$pkg")"
	if ! grep -Eq "\\b${name}\\b" "$CLI_DOC"; then
		err "cli-commands.md missing command $name"
	fi
done

# --- Cluster subcommands ---
cluster_go="$DEPLOYAH/internal/cmd/cluster/cluster.go"
[[ -f "$cluster_go" ]] || err "missing $cluster_go"
for pair in "up:registerUp" "down:registerDown" "status:registerStatus" "kubeconfig:registerKubeconfig"; do
	sub="${pair%%:*}"
	fn="${pair##*:}"
	if ! grep -Fq "$fn" "$cluster_go"; then
		err "cluster.go missing $fn"
	fi
	if ! grep -Eq "\\b${sub}\\b" "$CLI_DOC"; then
		err "cli-commands.md missing cluster $sub"
	fi
done

# --- Schema versions ---
constants="$DEPLOYAH/internal/spec/constants.go"
platform_loader="$DEPLOYAH/internal/spec/platform_loader.go"
manifest_ver="$(grep -E 'CurrentManifestVersion\s*=\s*"' "$constants" | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
platform_ver="$(grep -E 'CurrentPlatformVersion\s*=\s*"' "$platform_loader" | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
[[ -n "$manifest_ver" ]] || err "CurrentManifestVersion not found"
[[ -n "$platform_ver" ]] || err "CurrentPlatformVersion not found"

corpus_files=("$SKILL/SKILL.md")
while IFS= read -r -d '' f; do
	corpus_files+=("$f")
done < <(find "$REFS" -type f -name '*.md' -print0 | sort -z)

corpus="$(cat "${corpus_files[@]}")"
if [[ -n "$manifest_ver" && "$corpus" != *"$manifest_ver"* ]]; then
	err "skill corpus missing current manifest version $manifest_ver"
fi
if [[ -n "$platform_ver" && "$corpus" != *"$platform_ver"* ]]; then
	err "skill corpus missing current platform version $platform_ver"
fi

# v1alpha1 mentions must appear with rejection context on the same line.
for path in "${corpus_files[@]}"; do
	mapfile -t lines < "$path"
	for line in "${lines[@]}"; do
		[[ "$line" == *v1alpha1* ]] || continue
		if ! grep -Eiq 'reject|not current|unsupported|wrong|bad|do not|never' <<< "$line"; then
			err "$(basename "$path"): v1alpha1 without rejection context: ${line:0:100}"
		fi
	done
done

# --- Global flags ---
for flag in debug spec platform-file namespace kubeconfig context timeout cwd; do
	if ! grep -Fq -- "$flag" "$CLI_DOC"; then
		err "cli-commands.md missing global flag $flag"
	fi
done

# --- Behavioral markers from Deployah source ---
deploy_go="$DEPLOYAH/internal/cmd/deploy/deploy.go"
init_go="$DEPLOYAH/internal/cmd/initialize/init.go"
resolve_go="$DEPLOYAH/internal/cmd/resolve/resolve.go"
grep -Fq 'always upgraded' "$deploy_go" || err "deploy.go missing always-upgraded marker text"
grep -Fq 'errNotInteractive' "$init_go" || err "init.go missing errNotInteractive"
grep -Fq 'secret-safe' "$resolve_go" || err "resolve.go missing secret-safe warning"

# --- Assets apiVersion + JSON Schema ---
tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

check_asset() {
	local name="$1" want_ver="$2" schema_path="$3" label="$4"
	local path="$ASSETS/$name"
	if [[ ! -f "$path" ]]; then
		err "missing asset $name"
		return
	fi
	local got
	got="$(yq -r '.apiVersion // ""' "$path")"
	if [[ "$got" != "$want_ver" ]]; then
		err "asset $name apiVersion '$got' != '$want_ver'"
	fi
	if [[ ! -f "$schema_path" ]]; then
		err "missing schema $schema_path"
		return
	fi
	yq -o=json "$path" > "$tmp_json"
	if ! check-jsonschema --schemafile "$schema_path" "$tmp_json" > /dev/null 2> "$tmp_json.err"; then
		err "$label asset schema validate: $(tr '\n' ' ' < "$tmp_json.err" | head -c 300)"
	fi
	rm -f "$tmp_json.err"
}

if [[ -n "$manifest_ver" ]]; then
	check_asset "deployah.yaml" "$manifest_ver" \
		"$DEPLOYAH/internal/spec/schema/$manifest_ver/manifest.json" "manifest"
fi
if [[ -n "$platform_ver" ]]; then
	plat_dir="${platform_ver#platform/}"
	check_asset "deployah.platform.yaml" "$platform_ver" \
		"$DEPLOYAH/internal/spec/schema/platform/$plat_dir/platform.json" "platform"
fi

# --- Behavioral fixtures ---
[[ -f "$FIXTURES" ]] || err "missing behavioral fixtures: $FIXTURES"
if [[ -f "$FIXTURES" ]]; then
	assertion_count="$(yq -r '.assertions | length' "$FIXTURES")"
	i=0
	while [[ "$i" -lt "$assertion_count" ]]; do
		aid="$(yq -r ".assertions[$i].id" "$FIXTURES")"
		blob=""
		glob_count="$(yq -r ".assertions[$i].skill_glob | length" "$FIXTURES")"
		g=0
		while [[ "$g" -lt "$glob_count" ]]; do
			pattern="$(yq -r ".assertions[$i].skill_glob[$g]" "$FIXTURES")"
			if [[ "$pattern" == */**/*.md ]]; then
				base="${pattern%/**/*.md}"
				while IFS= read -r -d '' md; do
					blob+="$(cat "$md")"$'\n'
				done < <(find "$ROOT/$base" -type f -name '*.md' -print0)
			else
				blob+="$(cat "$ROOT/$pattern")"$'\n'
			fi
			g=$((g + 1))
		done

		must_count="$(yq -r ".assertions[$i].must_match // [] | length" "$FIXTURES")"
		m=0
		while [[ "$m" -lt "$must_count" ]]; do
			pat="$(yq -r ".assertions[$i].must_match[$m]" "$FIXTURES")"
			if ! grep -Eiq -- "$pat" <<< "$blob"; then
				err "behavioral $aid: must_match failed: $pat"
			fi
			m=$((m + 1))
		done

		must_not_count="$(yq -r ".assertions[$i].must_not_match // [] | length" "$FIXTURES")"
		m=0
		while [[ "$m" -lt "$must_not_count" ]]; do
			pat="$(yq -r ".assertions[$i].must_not_match[$m]" "$FIXTURES")"
			if grep -Eiq -- "$pat" <<< "$blob"; then
				err "behavioral $aid: must_not_match hit: $pat"
			fi
			m=$((m + 1))
		done
		i=$((i + 1))
	done
fi

# --- Eval scenarios ---
scenarios_path="$ROOT/evals/scenarios.json"
[[ -f "$scenarios_path" ]] || err "missing $scenarios_path"
if [[ -f "$scenarios_path" ]]; then
	if ! jq -e '(.scenarios | type == "array") or (type == "array")' "$scenarios_path" > /dev/null; then
		err "evals/scenarios.json must be a list or {scenarios: [...]}"
	else
		count="$(jq -r 'if type == "array" then length else (.scenarios | length) end' "$scenarios_path")"
		if [[ "$count" != "24" ]]; then
			err "expected 24 scenarios, found $count"
		fi
		# Validate each scenario object keys and status.
		bad="$(
			jq -r '
        (if type == "array" then . else .scenarios end) as $items
        | $items
        | to_entries[]
        | .key as $idx
        | .value as $sc
        | (
            ["id","prompt","expect_activation","expect_behavior","forbidden",
             "validation_method","pass_criteria","layer","status"]
            | map(. as $k | select(($sc | has($k)) | not) | $k)
          ) as $missing
        | (
            if ($missing | length) > 0 then
              "scenario[\($idx)] (\($sc.id // "?")): missing keys \($missing)"
            else
              ($sc.status // "") as $st
              | if ($st == "passed" or $st == "failed" or $st == "skipped" or $st == "not_executed") then
                  empty
                else
                  "scenario \($sc.id): bad status \($st|tostring)"
                end
            end
          )
      ' "$scenarios_path"
		)"
		while IFS= read -r line; do
			[[ -z "$line" ]] && continue
			err "$line"
		done <<< "$bad"
	fi
fi

# Deployah source contracts come from DEPLOYAH_SRC (locked Flake input).
# Do not duplicate that revision in consumer skill docs.

if [[ "${#errors[@]}" -gt 0 ]]; then
	for e in "${errors[@]}"; do
		echo "$e" >&2
	done
	exit 1
fi

echo "cli-contract ok"
