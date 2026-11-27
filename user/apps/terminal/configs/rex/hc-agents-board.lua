-- rex do ~/.config/rex/hc-agents-board.lua
-- The body of the agents board pane (init.lua's agents_board action): herdr's
-- agents list, redrawn every two seconds. It only reads, so closing it is safe.
package.path = os.getenv("HOME") .. "/.config/rex/?.lua;" .. package.path
local herdr = require("herdr")
local hcrpc = require("hcrpc")

local hc = hcrpc.bin()
-- Hide the cursor and turn off line wrap, so long rows are clipped.
io.stdout:write("\27[?25l\27[?7l")
while true do
  local rows = herdr.agent_rows(hcrpc.terminals(hc), os.time() * 1000, hcrpc.RECENT_MS)
  local out = {}
  for _, line in ipairs(herdr.board_lines(rows, os.date("%H:%M"))) do out[#out + 1] = line .. "\27[K" end
  io.stdout:write("\27[H" .. table.concat(out, "\r\n") .. "\27[J")
  io.stdout:flush()
  rex.sleep(2)
end
