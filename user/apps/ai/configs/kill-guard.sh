#!/usr/bin/env bash
# Runs every shell command Claude Code spawns with a `kill` that refuses to
# signal PID 1, any systemd manager, or every process at once (-1). The checks
# run on the real PIDs at run time, so `kill $(ps -o ppid= ...)` is caught even
# when an orphan was reparented to `systemd --user`.

kill() {
  local a n comm targets=0
  for a in "$@"; do
    if [ "$targets" = 0 ]; then
      case $a in
      --)
        targets=1
        continue
        ;;
      -s | -n)
        targets=skip
        continue
        ;;
      -l | -L)
        builtin kill "$@"
        return
        ;;
      -1) ;;
      -*) continue ;;
      esac
    elif [ "$targets" = skip ]; then
      targets=0
      continue
    fi
    if [ "$a" = -1 ]; then
      if [ "$#" = 1 ]; then
        builtin kill "$@"
        return
      fi
      echo "kill-guard: refusing to signal every process (-1)" >&2
      return 1
    fi
    n=${a#-}
    case $n in '' | *[!0-9]*) continue ;; esac
    comm=$(cat "/proc/$n/comm" 2>/dev/null)
    if [ "$n" = 1 ] || [ "$comm" = systemd ]; then
      echo "kill-guard: refusing to signal PID $n ($comm); it is a systemd manager, likely an orphan's reparented parent" >&2
      return 1
    fi
  done
  builtin kill "$@"
}
export -f kill

exec bash -c "$1"
