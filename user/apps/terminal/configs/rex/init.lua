-- Rex config — herdr-style keys and navigation, mirroring configs/herdr/config.toml.
-- Rex draws its sidebar natively, so this can't restyle it. It covers what Lua
-- can reach: herdr's keymap, splits that open where the focused pane is (ssh
-- included), a priority-sorted agent jump, and an accordion session list.
-- Apply edits with `rex config reload`; check them with `rex config check`.

local terminal = "com.superlogical.terminal"
local herdr = require("herdr")

-- Splits ---------------------------------------------------------------------

local sides = {
  right = { direction = "horizontal", side = "after" },
  left  = { direction = "horizontal", side = "before" },
  down  = { direction = "vertical",   side = "after" },
  up    = { direction = "vertical",   side = "before" },
}

-- A pane Rex started with a command (such as one split_here made) shows the
-- root-owned /usr/bin/login as its foreground; ssh is its child, named "-ssh".
local function ssh_args(fg)
  local pid = fg.pid
  if fg.name == "login" then
    local kids = rex.exec({ "pgrep", "-P", tostring(fg.pid) })
    pid = kids and kids.ok and kids.stdout:match("%d+")
  elseif fg.name ~= "ssh" then
    return nil
  end
  if not pid then return nil end
  local ps = rex.exec({ "ps", "-o", "args=", "-p", tostring(pid) })
  local args = ps and ps.ok and ps.stdout:gsub("^%-", "")
  if args and args:match("^%S*ssh%s") then return args end
end

-- Local panes use the foreground process's real cwd. An ssh pane uses the
-- directory the remote shell reported, but only if that ssh session reported it.
local function here(block_id)
  local proc = rex.block.call(terminal, "process", { block_id = block_id })
  local fg = proc and proc.foreground
  if not fg then return {} end
  local ssh = ssh_args(fg)
  if not ssh then return { cwd = fg.cwd } end

  local reported = rex.block.call(terminal, "pwd", { block_id = block_id })
  local path = reported and reported.owner and reported.owner.pid == fg.pid
    and herdr.pwd_path(reported.pwd)
  if path then return { ssh = ssh, path = path } end
  return {}
end

local function split_here(ctx, dir, command)
  local at = here(ctx.block_id)
  local options = {}
  if at.ssh then
    options.command = herdr.ssh_argv(at.ssh, at.path, command)
    options.shell = "none"
  else
    options.cwd = at.cwd
    if command then options.command = { command } end
  end
  if not (options.cwd or options.command) then
    rex.client.queue("pane.split", { direction = dir })
    return
  end

  local _, err = rex.session.new_split{
    anchor_id = ctx.block_id,
    direction = sides[dir].direction,
    side      = sides[dir].side,
    focus     = true,
    layout    = rex.layout.block{ flavor = "com.superlogical.terminal.shell", options = options },
  }
  if err then error(err, 0) end
end

rex.action{
  name     = "split_here",
  title    = "Split Pane Here",
  category = "Pane",
  args     = { direction = "string" },
  run      = function(ctx, args) split_here(ctx, args.direction) end,
}

-- herdr's [[keys.command]] panes: run a tool beside you, close when it exits.
rex.action{
  name     = "run_here",
  title    = "Run in Split Here",
  category = "Pane",
  args     = { command = "string" },
  run      = function(ctx, args) split_here(ctx, "right", args.command) end,
}

-- Sessions (herdr spaces) ----------------------------------------------------

-- Accordion: only the shown session stays expanded in the sidebar.
local function show_session(session_id, window_id)
  rex.client.queue("session.select", { session_id = session_id, window_id = window_id })
  rex.client.queue("session.collapse_others", { session_id = session_id })
end

for _, step in ipairs({ "next", "previous" }) do
  rex.action{
    name     = "space_" .. step,
    title    = "Space: " .. step,
    category = "Session",
    run      = function()
      rex.client.queue("session." .. step)
      rex.client.queue("session.collapse_others")
    end,
  }
end

-- Agents ---------------------------------------------------------------------

-- Agents report program-status records to Rex; herdr.urgency ranks them the
-- way herdr's agent panel sorts.
local function blocks_of(session_id)
  local blocks = rex.session.list_blocks{ session_id = session_id }
  if not blocks then
    rex.session.attach{ session_id = session_id }
    blocks = rex.session.list_blocks{ session_id = session_id }
  end
  return blocks and blocks.blocks or {}
end

local function agents()
  local list = {}
  local sessions = rex.call("session.list")
  for _, s in ipairs(sessions and sessions.sessions or {}) do
    for _, b in ipairs(blocks_of(s.session_id)) do
      if b.creator_name == terminal and b.placement == "placed" then
        local status = rex.block.call(terminal, "program_status",
          { session_id = s.session_id, block_id = b.block_id })
        local n = herdr.urgency(status and status.records)
        if n then
          list[#list + 1] = {
            session_id = s.session_id, window_id = b.window_id,
            block_id = b.block_id, rank = n, order = #list,
          }
        end
      end
    end
  end
  return herdr.sort_agents(list)
end

for name, step in pairs({ next = 1, previous = -1 }) do
  rex.action{
    name     = "agent_" .. name,
    title    = "Agent: " .. name,
    category = "Session",
    keywords = "herdr attention blocked",
    run      = function(ctx)
      local list = agents()
      if #list == 0 then return end
      local current = 0
      for i, a in ipairs(list) do
        if a.block_id == ctx.block_id then current = i end
      end
      local target = list[herdr.step(#list, current, step)]
      rex.session.focus_block{ session_id = target.session_id, block_id = target.block_id }
      show_session(target.session_id, target.window_id)
    end,
  }
end

-- Keys -----------------------------------------------------------------------
-- alt+letters are owned by aerospace on the Mac, same as under herdr; the
-- ctrl+a prefix forms are the reliable path.

local p = "ctrl+a>"
rex.bind(p .. "ctrl+a", "pane.send_key", { key = "ctrl+a" })

local function bind(keys, action, args)
  for _, key in ipairs(keys) do rex.bind(key, action, args) end
end

bind({ p .. "h", "alt+h" }, "pane.focus.left")
bind({ p .. "j", "alt+j" }, "pane.focus.down")
bind({ p .. "k", "alt+k" }, "pane.focus.up")
bind({ p .. "l", "alt+l" }, "pane.focus.right")

bind({ "cmd+d", p .. "v", "alt+n" }, "split_here", { direction = "right" })
bind({ "cmd+shift+d", p .. "-", "alt+m" }, "split_here", { direction = "down" })

bind({ "alt+[" }, "space_previous")
bind({ "alt+]" }, "space_next")
bind({ p .. "w" }, "session.switch")

bind({ p .. "p", "alt+left" }, "client.tab.previous")
bind({ p .. "n", "alt+right" }, "client.tab.next")

bind({ "alt+up" }, "agent_previous")
bind({ "alt+down" }, "agent_next")
bind({ p .. "a" }, "client.sidebar.activity.toggle")
bind({ p .. "b" }, "client.sidebar.toggle")

bind({ p .. "c" }, "client.tab.new")
bind({ p .. "shift+n" }, "session.new")

bind({ p .. "r" }, "client.tab.rename")
bind({ p .. "shift+w" }, "session.rename")

bind({ p .. "x" }, "pane.close")
bind({ p .. "shift+x" }, "client.tab.close")
bind({ p .. "shift+d" }, "session.close")

bind({ p .. "z", "alt+z" }, "pane.zoom")
bind({ p .. "ctrl+r" }, "client.config.reload")

bind({ "alt+g" }, "run_here", { command = "gitui" })
bind({ "alt+f" }, "run_here", { command = "elio" })

rex.mode("resize", { exclusive = true })
bind({ p .. "shift+r" }, "client.mode.enter", { name = "resize" })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("resize/" .. key, "pane.resize", { direction = dir })
end
rex.bind("resize/escape", "client.mode.exit")
rex.bind("resize/enter", "client.mode.exit")
