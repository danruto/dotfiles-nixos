#!/usr/bin/env bash
# Claude Code subagent task-panel rows: name · status · tokens · elapsed · label
# Input: single JSON object on stdin with `columns` and `tasks[]`.
# Output: one JSON line per row: {"id": "<task id>", "content": "<ansi row>"}

jq -rc --arg now "$(date +%s)" '
  ($now | tonumber) as $now
  | (.columns // 120) as $cols
  | "[0m" as $r
  | "[2m" as $dim
  | "[36m" as $cyan
  | def fmt_tok:
      if . >= 1000 then (((. / 100) | floor) / 10 | tostring) + "k" else tostring end;
  def status_color:
      if test("run|progress|active|pend"; "i") then "[33m"
      elif test("complet|done|success"; "i") then "[32m"
      elif test("fail|error|cancel|kill"; "i") then "[31m"
      else "[2m" end;
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
        "\($cyan)\(.name // .type // "agent")\($r)",
        ((.status // "") | if . == "" then null else "\(status_color)\(.)\($r)" end),
        ((.tokenCount // 0) | if . > 0 then "\(fmt_tok) tok" else null end),
        ((.startTime // null) | elapsed),
        ((.label // .description // "") | if . == "" then null
          else "\($dim)\(.[0:([$cols - 45, 20] | max)])\($r)" end)
      ] | map(select(. != null)) | join("\($dim) · \($r)"))
    }
'
