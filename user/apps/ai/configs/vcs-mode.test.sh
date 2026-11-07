#!/usr/bin/env bash
set -u
script="$(dirname "$0")/vcs-mode.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0

expect() {
  local got
  got=$(bash "$script" "$1")
  if [ "$got" = "$2" ]; then echo "ok   $3"; else echo "FAIL $3: got '$got', want '$2'"; fail=1; fi
}

git init -q -b main "$tmp/plain"
expect "$tmp/plain" "VCS: plain git on main" "plain git"

git init -q -b feat "$tmp/single"
mkdir "$tmp/single/.git/gitbutler"
expect "$tmp/single" "VCS: GitButler single-branch mode on feat" "gitbutler single-branch"

git init -q -b gitbutler/workspace "$tmp/ws"
mkdir "$tmp/ws/.git/gitbutler"
expect "$tmp/ws" "VCS: GitButler workspace mode" "gitbutler workspace"

mkdir "$tmp/none"
expect "$tmp/none" "" "not a repo prints nothing"

exit $fail
