-- rex do --all ~/.config/rex/status.lua
-- Puts a coloured emoji in front of each tab's label for the most urgent agent
-- in it: 🟡 blocked, 🔴 error, 🟢 done, 🔵 working. Visiting a tab clears its
-- 🟢 and 🔴. Event handlers only work in scripts, so launchd keeps this running.
package.path = os.getenv("HOME") .. "/.config/rex/?.lua;" .. package.path
local herdr = require("herdr")

local terminal = "com.superlogical.terminal"
local seen = {}

local function windows_of(session_id)
  local view = rex.session.view{ session_id = session_id }
  if not view then
    rex.session.attach{ session_id = session_id }
    view = rex.session.view{ session_id = session_id }
  end
  return view and view.windows or {}
end

local function terminals_in(window)
  local ids = {}
  for _, layer in ipairs(window.layers or {}) do
    for _, b in ipairs(layer.blocks or {}) do
      if b.creator_name == terminal then ids[#ids + 1] = b.block_id end
    end
  end
  return ids
end

local function records(session_id, block_id)
  local status = rex.block.call(terminal, "program_status",
    { session_id = session_id, block_id = block_id })
  return status and status.records or {}
end

-- Unnamed tabs show a title Rex generates; labelling one would freeze it.
local function refresh(session_id)
  for _, w in ipairs(windows_of(session_id)) do
    if w.label and w.label ~= "" then
      local best
      for _, id in ipairs(terminals_in(w)) do
        local n = herdr.urgency(herdr.unseen(records(session_id, id), seen[id]))
        if n and (not best or n < best) then best = n end
      end
      local label = herdr.label(w.label, best)
      if label ~= w.label then
        rex.session.set_window_label{ session_id = session_id, window_id = w.window_id, label = label }
      end
    end
  end
end

local function visit(session_id, window_id)
  for _, w in ipairs(windows_of(session_id)) do
    if w.window_id == window_id then
      for _, id in ipairs(terminals_in(w)) do
        for _, r in ipairs(records(session_id, id)) do
          if r.updated_at and (not seen[id] or r.updated_at > seen[id]) then seen[id] = r.updated_at end
        end
      end
    end
  end
  refresh(session_id)
end

rex.on("terminal.program_status_changed", function(ctx) refresh(ctx.session_id) end)
rex.on("terminal.program_status_removed", function(ctx) refresh(ctx.session_id) end)
rex.on("active_window_changed", function(ctx, ev) visit(ctx.session_id, ev.window_id) end)

for _, s in ipairs(rex.call("session.list").sessions) do refresh(s.session_id) end
