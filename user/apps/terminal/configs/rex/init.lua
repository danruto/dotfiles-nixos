-- Rex config — herdr-style keys and navigation, mirroring configs/herdr/config.toml.
-- Rex draws its sidebar natively, so this can't restyle it. It covers what Lua
-- can reach: herdr's keymap, splits that open where the focused pane is (ssh
-- included), a priority-sorted agent jump, and an accordion session list.
-- Apply edits with `rex config reload`; check them with `rex config check`.

local terminal = "com.superlogical.terminal"
-- Rex reloads init.lua in the same Lua state, so require would keep the herdr
-- module from the first load; drop it so a reload picks up herdr.lua edits.
package.loaded["herdr"] = nil
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

-- A pane hc-rex-sync mirrors from herdr runs `hc attach tN`; the directory
-- that counts is the hc terminal's foreground process's.
local function hc_attached(fg)
  local ps = rex.exec({ "ps", "-o", "args=", "-p", tostring(fg.pid) })
  return ps and ps.ok and herdr.hc_attach(ps.stdout)
end

local function hc_cwd(fg)
  local at = hc_attached(fg)
  if not at then return nil end
  local got = rex.exec({ at.hc, "get", at.term, "--json" })
  local info = got and got.ok and rex.json.decode(got.stdout)
  return info and ((info.foreground and info.foreground.cwd) or info.cwd)
end

local function foreground(block_id)
  local proc = rex.block.call(terminal, "process", { block_id = block_id })
  return proc and proc.foreground
end

-- Local panes use the foreground process's real cwd. An ssh pane uses the
-- directory the remote shell reported, but only if that ssh session reported it.
local function here(block_id)
  local fg = foreground(block_id)
  if not fg then return {} end
  if fg.name == "hc" or fg.name == "herdr-core" then return { cwd = hc_cwd(fg) } end
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

-- Image paste ----------------------------------------------------------------
-- The clipboard lives wherever the person is, which is rarely where the pane
-- runs: a pane on orb can't see the Mac clipboard, and an ssh pane can't see
-- orb's. So the image is saved on the machine that holds it (OrbStack's `mac`
-- reaches the Mac from orb), then the pane is handed a path it can open,
-- uploading first when the pane is an ssh session.
--
-- ctrl+v is Claude's own image paste, so this binding takes it over. Without
-- an image (or when nothing can read the clipboard) ctrl+v goes through as a
-- key. Panes whose host is unreachable from this server (a remote Rex server,
-- or an hc pane on another machine) use ctrl+shift+v instead: pane.insert_file
-- runs on the client, uploads the screenshot and types its path there.

-- pngpaste is macOS, native or through `mac`; Wayland and X11 have their own
-- readers. Prints the saved path and exits non-zero when there is no image.
local save_image = [[
PATH="$HOME/.nix-profile/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if [ -d /private/tmp ]; then d=/private/tmp/rex-paste; else d="${TMPDIR:-/tmp}/rex-paste"; fi
mkdir -p "$d" 2>/dev/null || exit 1
f="$d/rex-$(date +%Y%m%d-%H%M%S)-$$.png"
if command -v pngpaste >/dev/null 2>&1; then
  pngpaste "$f" >/dev/null 2>&1
elif command -v wl-paste >/dev/null 2>&1; then
  wl-paste --type image/png >"$f" 2>/dev/null
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard -t image/png -o >"$f" 2>/dev/null
else
  exit 1
fi
[ -s "$f" ] || { rm -f "$f"; exit 1; }
echo "$f"
]]

-- Saves the clipboard image and returns a path this server can read. OrbStack
-- exposes the Mac at /mnt/mac, so the Mac's /private/tmp lands there.
local function capture_image()
  local got = rex.exec({ "/usr/local/bin/mac", "sh", "-c", save_image },
    { timeout = 10 })
  local file = got and got.ok and got.stdout:match("%S+")
  if file then return "/mnt/mac" .. file end
  got = rex.exec({ "sh", "-c", save_image }, { timeout = 10 })
  file = got and got.ok and got.stdout:match("%S+")
  return file
end

-- Sends the saved image to the ssh host the pane runs on, at the same path, so
-- the path pasted into the pane names a file that exists there. Returns the
-- remote path, or nil if the copy failed.
local function upload_image(ssh, path)
  local remote = "/tmp/rex-paste/" .. path:match("[^/]+$")
  local argv = herdr.ssh_copy_argv(ssh,
    "mkdir -p /tmp/rex-paste && cat > " .. herdr.quote(remote))
  local fh = argv and io.open(path, "rb")
  if not fh then return nil end
  local bytes = fh:read("*a")
  fh:close()
  local got = rex.exec(argv, { stdin = bytes, timeout = 30 })
  if got and got.ok then return remote end
  rex.log("warn", "paste image: " .. (got and got.stderr or "ssh failed"))
end

rex.action{
  name        = "paste_image",
  title       = "Paste Clipboard Image",
  category    = "Pane",
  description = "Pastes a screenshot as a path, uploading it to the pane's host over ssh",
  run         = function(ctx)
    local path = capture_image()
    local fg = path and foreground(ctx.block_id)
    local ssh = fg and ssh_args(fg)
    if ssh then path = upload_image(ssh, path) or path end
    if not path then
      rex.client.queue("pane.send_key", { key = "ctrl+v" })
      return
    end
    rex.call("block.event", {
      session_id = ctx.session_id,
      block_id   = ctx.block_id,
      event      = { type = "paste", payload = { text = path } },
    })
  end,
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

-- hc subthreads ---------------------------------------------------------------
-- An hc terminal can start helpers (subagents, review loops) that live beside
-- it and name it as their parent. herdr shows them indented under the agent;
-- the layout doc the sync mirrors has no room for them, so Rex lists them here
-- instead. Picking one attaches it in a floating pane, which the sync leaves
-- alone because it only mirrors tiled panes. Closing the pane ends the view,
-- not the helper. A client that can't show prompts (the Windows app) gets a
-- board of every live subthread instead of a picker.

local function attach_command(hc, term)
  local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
  local wrapper = home .. "/.config/rex/hc-rex-attach"
  local fh = io.open(wrapper, "r")
  if not fh then return { hc, "attach", "--history", "2000", term } end
  fh:close()
  return { "/bin/sh", wrapper, hc, term }
end

rex.action{
  name     = "hc_subthreads",
  title    = "hc: Subthreads",
  category = "Agent",
  keywords = "hc herdr children subagents helpers threads",
  run      = function(ctx)
    local me = foreground(ctx.block_id)
    local here = me and hc_attached(me)
    local hc = here and here.hc or "hc"
    local got = rex.exec({ hc, "ls", "--json" }, { timeout = 20 })
    local list = got and got.ok and rex.json.decode(got.stdout)
    local terminals = list and list.terminals or {}

    -- The focused pane's own children when it has any (that is the agent you
    -- are looking at), otherwise every live subthread on this server.
    local children = herdr.hc_children(terminals, here and here.term)
    if #children == 0 then children = herdr.hc_children(terminals) end
    if #children == 0 then return end

    table.sort(children, function(a, b)
      local an = a.terminal.name or a.terminal.agent or a.terminal.address
      local bn = b.terminal.name or b.terminal.agent or b.terminal.address
      return an:lower() < bn:lower()
    end)

    local items = {}
    for _, c in ipairs(children) do
      local t = c.terminal
      local subtitle = c.parent and (c.parent.name or c.parent.agent or c.parent.address)
      if t.where then
        subtitle = (subtitle and subtitle .. " · " or "") .. t.where
      end
      items[#items + 1] = {
        id       = t.address,
        title    = t.name or t.agent or t.address,
        subtitle = subtitle,
        icon     = "terminal",
        detail   = t.status,
      }
    end

    local picks = {}
    local chosen, why = rex.ui.pick{
      title       = "hc subthreads",
      placeholder = "Filter subthreads",
      items       = items,
    }
    if chosen ~= nil then
      for _, item in ipairs(items) do
        if item.id == chosen then picks = { item } end
      end
    elseif why ~= "cancelled" and why ~= "timeout" and why ~= "busy" then
      -- The connected app can't show prompts (the Windows client doesn't), so
      -- open a board of the live ones rather than doing nothing.
      rex.log("info", "hc subthreads: no prompt (" .. tostring(why) .. "), opening all")
      for i = 1, math.min(#items, 6) do picks[#picks + 1] = items[i] end
    end
    if #picks == 0 then return end

    local specs = {}
    for _, p in ipairs(picks) do
      specs[#specs + 1] = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        options = { command = attach_command(hc, p.id), shell = "none" },
      }
    end

    local made = rex.session.new_layer{
      session_id = ctx.session_id,
      bounds     = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
      focus      = true,
      layout     = herdr.columns(specs, rex.layout.horizontal),
    }
    for i, block in ipairs(made and made.block_ids or {}) do
      if picks[i] then
        rex.session.set_block_label{
          session_id = ctx.session_id,
          block_id   = block,
          label      = "↳ " .. picks[i].title,
        }
      end
    end
  end,
}

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
bind({ p .. "t", "alt+t" }, "hc_subthreads")
bind({ p .. "a" }, "client.sidebar.activity.toggle")
bind({ p .. "b" }, "client.sidebar.toggle")

bind({ p .. "c" }, "client.tab.new")
bind({ p .. "shift+n" }, "session.new")

bind({ p .. "r" }, "client.tab.rename")
bind({ p .. "shift+w" }, "session.rename")

bind({ p .. "x" }, "pane.close")
bind({ p .. "shift+x" }, "client.tab.close")
bind({ p .. "shift+d" }, "session.close")

bind({ "ctrl+v" }, "paste_image")
-- Client-side fallback for hosts this server can't copy to; needs the file on
-- disk, so it suits screenshots saved to the Desktop. pane.insert_file is
-- Mac-only, so ask the client first and let the key through where it isn't.
rex.bind("ctrl+shift+v", function(ctx)
  if not ctx.client_id then return false end
  local got = rex.call("client.inspect", { client_id = ctx.client_id })
  for _, action in ipairs(got and got.actions or {}) do
    if action.name == "pane.insert_file" then
      rex.client.queue("pane.insert_file")
      return true
    end
  end
  return false
end)
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
