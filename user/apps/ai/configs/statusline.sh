#!/usr/bin/env bash
# Claude Code statusline: model │ duration │ cost │ context % │ usage limits
# Input: JSON on stdin (see https://code.claude.com/docs/en/statusline)

input=$(cat)

eval "$(jq -r '
  @sh "model=\(.model.display_name // "?")",
  @sh "dur_ms=\(.cost.total_duration_ms // 0)",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "ctx=\(.context_window.used_percentage // "")",
  @sh "rl5=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "rl7=\(.rate_limits.seven_day.used_percentage // "")"
' <<<"$input")"

RESET=$'\033[0m'
DIM=$'\033[2m'
CYAN=$'\033[36m'

# green < 60, yellow < 80, red >= 80
pct_color() {
  local p=${1%%.*}
  if (( p >= 80 )); then printf '\033[31m'
  elif (( p >= 60 )); then printf '\033[33m'
  else printf '\033[32m'; fi
}

mins=$(( dur_ms / 60000 ))
if (( mins >= 60 )); then
  dur="$(( mins / 60 ))h$(( mins % 60 ))m"
else
  dur="${mins}m"
fi

segments=()
segments+=("${CYAN}${model}${RESET}")
segments+=("${dur}")
segments+=("$(printf '$%.2f' "$cost")")

if [[ -n "$ctx" ]]; then
  segments+=("${DIM}ctx${RESET} $(pct_color "$ctx")${ctx%%.*}%${RESET}")
fi
if [[ -n "$rl5" ]]; then
  segments+=("${DIM}5h${RESET} $(pct_color "$rl5")${rl5%%.*}%${RESET}")
fi
if [[ -n "$rl7" ]]; then
  segments+=("${DIM}wk${RESET} $(pct_color "$rl7")${rl7%%.*}%${RESET}")
fi

out="${segments[0]}"
for seg in "${segments[@]:1}"; do
  out+=" ${DIM}│${RESET} ${seg}"
done
printf '%s\n' "$out"
