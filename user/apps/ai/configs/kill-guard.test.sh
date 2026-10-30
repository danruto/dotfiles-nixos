#!/usr/bin/env bash
# Uses signal 0 throughout, so a broken guard cannot hurt the session.
set -u
guard="$(dirname "$(readlink -f "$0")")/kill-guard.sh"
fail=0

expect() {
  local want=$1 cmd=$2
  if "$guard" "$cmd" >/dev/null 2>&1; then got=allow; else got=block; fi
  if [ "$got" = "$want" ]; then echo "ok   $want: $cmd"; else
    echo "FAIL $want (got $got): $cmd"
    fail=1
  fi
}

sleep 30 &
victim=$!
mgr=$(pgrep -u "$(id -u)" -x systemd | head -1)

expect allow "kill -0 $victim"
expect allow "kill -s 0 $victim"
expect allow "kill -n 0 -- $victim"
expect allow "kill -l"
expect block "kill -0 1"
expect block "kill -0 -- -1"
expect block "kill -s 0 -1"
[ -n "$mgr" ] && expect block "p=$mgr; kill -0 \$p"
[ -n "$mgr" ] && expect block "kill -0 $victim $mgr"
expect block "bash -c 'kill -0 1'"

builtin kill "$victim"
exit $fail
