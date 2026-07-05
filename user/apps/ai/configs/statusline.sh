#!/usr/bin/env bash
# Claude Code statusline: model │ duration │ cost │ context % │ usage limits
# Input: JSON on stdin (see https://code.claude.com/docs/en/statusline)

input=$(cat)

eval "$(jq -r '
  @sh "model=\(.model.display_name // "?")",
  @sh "dur_ms=\(.cost.total_duration_ms // 0)",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "ctx=\(.context_window.used_percentage // "")",
  @sh "effort=\(.effort.level // "")",
  @sh "cache_read=\(.context_window.current_usage.cache_read_input_tokens // "")",
  @sh "cache_write=\(.context_window.current_usage.cache_creation_input_tokens // "")",
  @sh "fresh_in=\(.context_window.current_usage.input_tokens // "")",
  @sh "rl5=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "rl5_reset=\(.rate_limits.five_hour.resets_at // "")",
  @sh "rl7=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "rl7_reset=\(.rate_limits.seven_day.resets_at // "")",
  @sh "pr=\(.pr.number // "")"
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

# epoch seconds -> "2h13m" / "3d4h" / "42m" until then
until_reset() {
  local s=$(( ${1%%.*} - $(date +%s) ))
  (( s <= 0 )) && return
  if (( s >= 86400 )); then printf '%dd%dh' $(( s / 86400 )) $(( s % 86400 / 3600 ))
  elif (( s >= 3600 )); then printf '%dh%dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
  else printf '%dm' $(( s / 60 )); fi
}

mins=$(( dur_ms / 60000 ))
if (( mins >= 60 )); then
  dur="$(( mins / 60 ))h$(( mins % 60 ))m"
else
  dur="${mins}m"
fi

segments=()
if [[ -n "$effort" ]]; then
  segments+=("${CYAN}${model}${RESET} ${DIM}${effort}${RESET}")
else
  segments+=("${CYAN}${model}${RESET}")
fi
segments+=("${dur}")
segments+=("$(printf '$%.2f' "$cost")")

if [[ -n "$ctx" ]]; then
  segments+=("${DIM}ctx${RESET} $(pct_color "$ctx")${ctx%%.*}%${RESET}")
fi

# cache hit ratio: read / (read + write + fresh input) of the last API call
cache_total=$(( ${cache_read:-0} + ${cache_write:-0} + ${fresh_in:-0} ))
if (( cache_total > 0 )); then
  hit=$(( cache_read * 100 / cache_total ))
  segments+=("${DIM}cache${RESET} ${hit}%")
fi

if [[ -n "$rl5" ]]; then
  seg="${DIM}5h${RESET} $(pct_color "$rl5")${rl5%%.*}%${RESET}"
  [[ -n "$rl5_reset" ]] && r=$(until_reset "$rl5_reset") && [[ -n "$r" ]] && seg+=" ${DIM}${r}${RESET}"
  segments+=("$seg")
fi
if [[ -n "$rl7" ]]; then
  seg="${DIM}wk${RESET} $(pct_color "$rl7")${rl7%%.*}%${RESET}"
  [[ -n "$rl7_reset" ]] && r=$(until_reset "$rl7_reset") && [[ -n "$r" ]] && seg+=" ${DIM}${r}${RESET}"
  segments+=("$seg")
fi

if [[ -n "$pr" ]]; then
  segments+=("${CYAN}PR#${pr}${RESET}")
fi

out="${segments[0]}"
for seg in "${segments[@]:1}"; do
  out+=" ${DIM}│${RESET} ${seg}"
done
printf '%s\n' "$out"
