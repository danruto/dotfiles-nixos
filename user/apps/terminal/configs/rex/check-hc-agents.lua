-- env PATH=/usr/local/bin:/usr/bin rex do -s SESSION ~/.config/rex/check-hc-agents.lua
-- (the server's own PATH, so a bare `hc` in the action fails here too)
-- End-to-end check of the hc_agents action on a server hc-rex-sync mirrors
-- into. SESSION is a Rex session the sync made. Two throwaway helpers are
-- started under one of its hc terminals, the real init.lua is loaded, and the
-- action runs with only the parts that need a person replaced: the picker
-- answers with a chosen row and the app's session switch is recorded. Focus,
-- floating panes and hc are real. Everything it starts is removed at the end.
local home = os.getenv("HOME")
-- The config beside this script is the one checked, so a working tree can be
-- tested before it is applied.
local dir = (debug.getinfo(1, "S").source:match("^@?(.*)/[^/]*$")) or (home .. "/.config/rex")
package.path = dir .. "/?.lua;" .. package.path
package.loaded["herdr"] = nil
local HC = os.getenv("HC") or (home .. "/.nix-profile/bin/hc")

local session = rex.session_id
assert(session, "pass -s SESSION, a session hc-rex-sync mirrors")

local function hc(args)
  local argv = { HC }
  for _, a in ipairs(args) do argv[#argv + 1] = a end
  local got = rex.exec(argv, { timeout = 20 })
  assert(got and got.ok, "hc " .. table.concat(args, " ") .. ": " .. tostring(got and got.stderr))
  return got.stdout
end

-- Lua 5.1 can't yield across pcall and rex.exec yields, so a failed check
-- returns instead of raising, leaving the cleanup below to run.
local failed
local function check(ok, what)
  if not ok then failed = failed or ("FAIL: " .. what) end
  return ok
end

-- A terminal the sync mirrors in this session becomes the helpers' parent.
local fh = assert(io.open(home .. "/.local/state/hc-rex-sync.json", "r"))
local state = rex.json.decode(fh:read("*a"))
fh:close()
local view = rex.session.view{ session_id = session }
local parent, parent_block, parent_window
for _, w in ipairs(view.windows or {}) do
  for _, layer in ipairs(w.layers or {}) do
    if layer.kind == "tiled" then
      for _, b in ipairs(layer.blocks or {}) do
        if not parent and state.blocks[b.block_id] then
          parent, parent_block, parent_window = state.blocks[b.block_id], b.block_id, w.window_id
        end
      end
    end
  end
end
assert(parent, "no mirrored hc pane in this session")

local live = rex.json.decode(hc({ "run", "--bg", "--json", "--name", "rexprobe-live", "--parent", parent,
  "--no-notify", "--", "sleep", "900" })).address
local done = rex.json.decode(hc({ "run", "--bg", "--json", "--name", "rexprobe-done", "--parent", parent,
  "--no-notify", "--", "sh", "-c", "echo rexprobe-output; exit 3" })).address

local results = {}
local function body()
  rex.sleep(1)

  local items, queued, answer = nil, {}, nil
  local real_bind, real_unbind, real_mode = rex.bind, rex.unbind, rex.mode
  rex.bind = function() end
  rex.unbind = function() return 0 end
  rex.mode = function() end
  rex.ui.pick = function(o)
    items = o.items
    if answer then return answer end
    return nil, "cancelled"
  end
  rex.client.queue = function(name, args) queued[#queued + 1] = { name = name, args = args } end
  dofile(dir .. "/init.lua")
  rex.bind, rex.unbind, rex.mode = real_bind, real_unbind, real_mode

  local function run(pick)
    answer, items, queued = pick, nil, {}
    local _, e = rex.invoke("hc_agents")
    if not check(e == nil, "hc_agents raised: " .. tostring(e)) then return end
    return items
  end

  -- The list: the parent leads its group, helpers nested under it.
  local listed = run(nil)
  local at = {}
  for i, it in ipairs(listed or {}) do at[it.id] = i end
  if not check(at[parent], "parent " .. parent .. " missing from the list") then return end
  if not check(at[live] and at[done], "helpers missing from the list") then return end
  if not check(at[live] == at[parent] + 1 or at[done] == at[parent] + 1, "helpers not nested under their parent") then return end
  if not check(listed[at[live]].title == "↳ rexprobe-live", "live helper title: " .. tostring(listed[at[live]].title)) then return end
  if not check(listed[at[done]].detail:match("^Exited 3"), "finished helper detail: " .. tostring(listed[at[done]].detail)) then return end
  results[#results + 1] = "list: " .. #listed .. " rows, parent " .. parent .. " with helpers " .. live .. ", " .. done

  -- A helper opens in a floating pane attached to it.
  local function floating()
    local v = rex.session.view{ session_id = session }
    for _, w in ipairs(v.windows or {}) do
      for _, layer in ipairs(w.layers or {}) do
        if layer.kind ~= "tiled" then
          for _, b in ipairs(layer.blocks or {}) do
            if (b.label or ""):match("rexprobe") then return b end
          end
        end
      end
    end
  end
  -- Rex reports the pane's shell as its foreground, so the program is found
  -- among that shell's children.
  local function runs(block, pattern)
    local proc = rex.block.call("com.superlogical.terminal", "process", { session_id = session, block_id = block })
    local pid = proc and proc.foreground and proc.foreground.pid
    if not pid then return nil end
    local got = rex.exec({ "ps", "-o", "args=", "--ppid", tostring(pid) })
    for line in ((got and got.stdout) or ""):gmatch("[^\n]+") do
      if line:find(pattern) then return line end
    end
  end
  for _, case in ipairs({ { live, "hc attach .*" .. live }, { done, "less" } }) do
    run(case[1])
    local b = floating()
    if not check(b, "no floating pane for " .. case[1]) then return end
    rex.sleep(1)
    local line = runs(b.block_id, case[2])
    rex.call("block.close", { session_id = session, block_id = b.block_id })
    if not check(line, case[1] .. " floating pane isn't running " .. case[2]) then return end
    results[#results + 1] = "pick " .. case[1] .. ": floating pane runs " .. line
  end

  -- An agent with a pane is focused there and its session shown.
  local before = rex.session.view{ session_id = session }
  local before_focus
  for _, w in ipairs(before.windows or {}) do
    if w.window_id == parent_window then before_focus = w.focused_block_id end
  end
  run(parent)
  local after = rex.session.view{ session_id = session }
  local focused
  for _, w in ipairs(after.windows or {}) do
    if w.window_id == parent_window then focused = w.focused_block_id end
  end
  if before_focus and before_focus ~= parent_block then
    rex.session.focus_block{ session_id = session, block_id = before_focus }
  end
  if not check(focused == parent_block, "parent pane not focused") then return end
  if not check(queued[1] and queued[1].name == "session.select" and queued[1].args.session_id == session
    and queued[1].args.window_id == parent_window, "app not asked to show the parent's session and tab") then return end
  results[#results + 1] = "pick " .. parent .. ": focused its pane, app asked to show session and tab"
end
body()

for _, t in ipairs({ live, done }) do
  rex.exec({ HC, "kill", t }, { timeout = 10 })
  rex.exec({ HC, "rm", t }, { timeout = 10 })
end
if failed then error(failed, 0) end
results[#results + 1] = "PASS"
return results
