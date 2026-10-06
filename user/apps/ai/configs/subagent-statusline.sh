#!/usr/bin/env bash
# Claude Code subagent task-panel rows: model · status · context · elapsed · label
# Input: single JSON object on stdin with `columns` and `tasks[]`.
# Output: one JSON line per row: {"id": "<task id>", "content": "<ansi row>"}

jq -rc --arg now "$(date +%s)" '
  ($now | tonumber) as $now
  | (.columns // 120) as $cols
  | "\u001b[0m" as $r
  | "\u001b[2m" as $dim
  | "\u001b[36m" as $cyan
  | def fmt_tok:
      if . >= 1000 then (((. / 100) | floor) / 10 | tostring) + "k" else tostring end;
  def pct_color:
      if . >= 80 then "\u001b[31m" elif . >= 60 then "\u001b[33m" else "\u001b[32m" end;
  # "claude-haiku-4-5-20251001" -> "haiku-4-5"
  def short_model: sub("^claude-"; "") | sub("-[0-9]{8}$"; "");
  def status_color:
      if test("run|progress|active|pend"; "i") then "\u001b[33m"
      elif test("complet|done|success"; "i") then "\u001b[32m"
      elif test("fail|error|cancel|kill"; "i") then "\u001b[31m"
      else "\u001b[2m" end;
  # startTime format is undocumented: accept epoch s, epoch ms, or ISO string
  def elapsed:
      (if type == "number" then (if . > 1e12 then . / 1000 else . end)
       elif type == "string" then (try fromdateiso8601 catch null)
       else null end) as $start
      | if $start == null then null else
          (($now - $start) | floor)
          | if . < 0 then null
            elif . >= 3600 then "\(. / 3600 | floor)h\(. % 3600 / 60 | floor)m"
            elif . >= 60 then "\(. / 60 | floor)m\(. % 60)s"
            else "\(.)s" end
        end;
  .tasks[]
  | {
      id: .id,
      content: ([
        "\($cyan)\(.name // (.model | if . then short_model else null end) // .type // "agent")\($r)",
        ((.status // "") | if . == "" then null else "\(status_color)\(.)\($r)" end),
        (if (.tokenCount // 0) == 0 then null
         elif (.contextWindowSize // 0) > 0 then
           ((.tokenCount * 100 / .contextWindowSize) | floor) as $p
           | "\(.tokenCount | fmt_tok) \($p | pct_color)\($p)%\($r)"
         else "\(.tokenCount | fmt_tok) tok" end),
        # no end time in the payload, so elapsed would keep counting after a task ends
        (if (.status // "running") | test("run|progress|active|pend"; "i")
         then (.startTime // null) | elapsed else null end),
        ((.label // .description // "") | if . == "" then null
          else "\($dim)\(.[0:([$cols - 45, 20] | max)])\($r)" end)
      ] | map(select(. != null)) | join("\($dim) · \($r)"))
    }
'
