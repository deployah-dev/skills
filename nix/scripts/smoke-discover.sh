#!/usr/bin/env bash
# Offline Skills CLI discovery against a local tree (store path or checkout).
# Must use the packaged `skills` binary. Does NOT treat filesystem existence alone as success.
set -euo pipefail

: "${DEPLOYAH_SKILLS_ROOT:?}"

command -v skills > /dev/null || {
	echo "skills CLI missing" >&2
	exit 1
}

# Isolated HOME is expected to be set by the validate wrapper.
: "${HOME:?HOME must be set to an isolated temp directory}"

out="$(mktemp)"
err="$(mktemp)"
trap 'rm -f "$out" "$err"' EXIT

set +e
skills add "$DEPLOYAH_SKILLS_ROOT" --list > "$out" 2> "$err"
code=$?
set -e

if [[ $code -ne 0 ]]; then
	echo "skills add --list failed (exit $code)" >&2
	cat "$err" >&2
	exit 1
fi

if ! grep -Eqi '(^|[[:space:]])deployah([[:space:]]|$)' "$out"; then
	echo "discovery output did not list skill name deployah" >&2
	echo "--- stdout ---" >&2
	cat "$out" >&2
	echo "--- stderr ---" >&2
	cat "$err" >&2
	exit 1
fi

echo "discovery ok: deployah listed"
