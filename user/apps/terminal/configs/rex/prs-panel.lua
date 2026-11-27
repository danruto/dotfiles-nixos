-- rex do ~/.config/rex/prs-panel.lua
-- The body of the PRs panel (init.lua's prs_panel action): open pull requests
-- waiting on your review, then your own, redrawn every minute. Titles are
-- links. It only reads, so closing it is safe.
package.path = os.getenv("HOME") .. "/.config/rex/?.lua;" .. package.path
local herdr = require("herdr")
local hcrpc = require("hcrpc")

local gh = hcrpc.find("gh")
local FIELDS = "number,title,repository,isDraft,updatedAt,url"

local function search(filter)
  local got = rex.exec({ gh, "search", "prs", filter, "--state=open", "--sort=updated",
    "--json", FIELDS, "--limit", "30" }, { timeout = 30 })
  if not (got and got.ok) then return nil, got and got.stderr or "gh failed" end
  local ok, list = pcall(rex.json.decode, got.stdout)
  if not ok then return nil, "unreadable gh output" end
  return list
end

io.stdout:write("\27[?25l\27[?7l")
while true do
  local review, err1 = search("--review-requested=@me")
  local mine, err2 = search("--author=@me")
  local lines = herdr.pr_lines(review, mine, os.time(), os.date("%H:%M"), err1 or err2)
  local out = {}
  for _, line in ipairs(lines) do out[#out + 1] = line .. "\27[K" end
  io.stdout:write("\27[H" .. table.concat(out, "\r\n") .. "\27[J")
  io.stdout:flush()
  rex.sleep(60)
end
