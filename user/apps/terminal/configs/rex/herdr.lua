-- Pure helpers for init.lua, kept apart so check.lua can test them.
local herdr = {}

function herdr.quote(s)
  return "'" .. (s:gsub("'", "'\\''")) .. "'"
end

function herdr.pwd_path(url)
  local path = url and url:match("^file://[^/]*(/.*)$")
  if not path then return nil end
  return (path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

-- The ssh invocation behind a pane, without the remote command a previous
-- split appended and without a pty. A pty rewrites bytes, so copies of a file
-- have to run without one.
function herdr.ssh_base(args)
  args = args:gsub("^(%S+) %-t ", "%1 ")
    :gsub(" cd '.*' && exec %$SHELL %-l.*$", "")
  local argv = {}
  for word in args:gmatch("%S+") do argv[#argv + 1] = word end
  if #argv < 2 then return nil end
  return argv
end

-- `ssh orb` becomes `ssh -t orb 'cd /path && exec $SHELL -l'`, so the new pane
-- lands in the same remote directory. -t goes first because the original args
-- end with the destination.
function herdr.ssh_argv(args, path, command)
  local argv = herdr.ssh_base(args)
  if not argv then return nil end
  table.insert(argv, 2, "-t")
  local run = "exec $SHELL -l"
  if command then run = run .. " -c " .. herdr.quote(command) end
  argv[#argv + 1] = "cd " .. herdr.quote(path) .. " && " .. run
  return argv
end

-- ssh argv that runs `command` on the pane's host, with no pty, for piping
-- bytes through standard input.
function herdr.ssh_copy_argv(args, command)
  local base = herdr.ssh_base(args)
  if not base then return nil end
  local argv = { base[1] }
  for i = 2, #base do
    if base[i] ~= "-t" and base[i] ~= "-T" then argv[#argv + 1] = base[i] end
  end
  argv[#argv + 1] = command
  return argv
end

-- The hc invocation behind a pane: `hc attach --history 2000 t7` becomes
-- { hc = "/path/to/hc", term = "t7" }. A terminal on another machine is
-- `machine/t7`, which is also the address hc attach takes.
function herdr.hc_attach(args)
  local hc, term = (args or ""):match("^(%S+) attach .-(%S+)%s*$")
  if not hc then return nil end
  return { hc = hc, term = term }
end

-- A balanced row for a list of layouts, in order. Rex nests binary splits, so
-- an N-up board is a tree; the before side is always the earlier item.
function herdr.columns(specs, join)
  if #specs == 1 then return specs[1] end
  local mid = math.ceil(#specs / 2)
  local before, after = {}, {}
  for i = 1, mid do before[#before + 1] = specs[i] end
  for i = mid + 1, #specs do after[#after + 1] = specs[i] end
  return join(mid / #specs, herdr.columns(before, join), herdr.columns(after, join))
end

-- herdr sorts its agent panel by who needs you: blocked, then failed, done,
-- working and idle.
local rank = { blocked = 1, error = 2, done = 3, working = 4, idle = 5 }

-- The agents board ------------------------------------------------------------
-- herdr's agents list, from hc's terminal.list: agents sorted by who needs
-- you, each followed by the helpers it started. Fields come from the RPC
-- (labels.where) or the CLI (where), so both are read.

local agentish = { "claude", "codex", "opencode", "gemini", "aider", "cursor", "goose", "amp" }
local words = { blocked = "Needs you", error = "Failed", done = "Ready", working = "Working", idle = "Idle" }

function herdr.short_age(ms)
  local s = math.max(0, math.floor(ms / 1000))
  if s < 60 then return s .. "s" end
  if s < 3600 then return math.floor(s / 60) .. "m" end
  if s < 86400 then return math.floor(s / 3600) .. "h" end
  return math.floor(s / 86400) .. "d"
end

local function where(t)
  return t.where or (t.labels and t.labels.where) or nil
end

local function program(t)
  return t.foreground and t.foreground.name or nil
end

local function is_agent(t)
  if t.status then return true end
  local name = (program(t) or ""):lower()
  for _, a in ipairs(agentish) do
    if name:find(a, 1, true) then return true end
  end
  return false
end

local function nonempty(s)
  if s and s ~= "" then return s end
end

local function title_of(t)
  local tab = where(t) and where(t):match("/%s*(.-)%s*$")
  return nonempty(t.name)
    or (t.status and nonempty(t.status.title))
    or (is_agent(t) and nonempty(t.title))
    or nonempty(tab)
    or program(t)
    or t.address
end

local function join(...)
  local out = {}
  for i = 1, select("#", ...) do
    local s = select(i, ...)
    if s and s ~= "" then out[#out + 1] = s end
  end
  return table.concat(out, " · ")
end

local function state_of(t, now)
  if t.state ~= "live" then
    local how = t.exit_code and ("Exited " .. t.exit_code) or (t.reason or "Finished")
    return how, t.finished_ms and herdr.short_age(now - t.finished_ms)
  end
  local word = t.status and t.status.state
  local age = t.status_ms and t.status and herdr.short_age(now - t.status_ms)
  return words[word] or (word and word:gsub("^%l", string.upper)) or "Running", age
end

local function row(t, now, kind, parent)
  local label, age = state_of(t, now)
  local name = title_of(t)
  return {
    term     = t.address,
    live     = t.state == "live",
    kind     = kind,
    name     = name,
    title    = kind == "sub" and ("↳ " .. name) or name,
    subtitle = join(kind == "sub" and parent and ("from " .. title_of(parent)) or nil,
      where(t), program(t)),
    detail   = join(label, age),
    icon     = kind == "sub" and (t.state == "live" and "terminal" or "clock") or "person",
  }
end

-- Rows for the board. Helpers that finished within `recent` ms stay listed so
-- their output can still be read. The `first` terminal's group leads.
function herdr.agent_rows(terminals, now, recent, first)
  local by, kids = {}, {}
  for _, t in ipairs(terminals or {}) do
    if t.address then by[t.address] = t end
  end
  local function fresh(t)
    return t.state == "live" or (t.finished_ms and now - t.finished_ms <= recent)
  end
  local function child(t)
    return t.parent and t.parent ~= t.address and by[t.parent] and by[t.parent].state == "live"
  end

  local tops = {}
  for _, t in ipairs(terminals or {}) do
    if child(t) then
      if fresh(t) then
        kids[t.parent] = kids[t.parent] or {}
        table.insert(kids[t.parent], t)
      end
    end
  end
  for _, t in ipairs(terminals or {}) do
    if not child(t) and t.state == "live" and (is_agent(t) or kids[t.address] or t.parent) then
      tops[#tops + 1] = t
    end
  end

  local function rank_of(t)
    if t.address == first then return 0 end
    return rank[t.status and t.status.state] or 6
  end
  table.sort(tops, function(a, b)
    local ra, rb = rank_of(a), rank_of(b)
    if ra ~= rb then return ra < rb end
    return (where(a) or a.address) < (where(b) or b.address)
  end)

  local out = {}
  for _, t in ipairs(tops) do
    out[#out + 1] = row(t, now, "agent")
    local list = kids[t.address] or {}
    table.sort(list, function(a, b)
      if (a.state == "live") ~= (b.state == "live") then return a.state == "live" end
      return (a.created_ms or 0) > (b.created_ms or 0)
    end)
    for _, k in ipairs(list) do out[#out + 1] = row(k, now, "sub", t) end
  end
  return out
end

function herdr.urgency(records)
  local best
  for _, r in ipairs(records or {}) do
    local n = rank[r.state]
    if n and (not best or n < best) then best = n end
  end
  return best
end

-- Drops done and error records already seen, so a finished agent stops
-- standing out once you've visited its tab. `seen_at` is the newest
-- updated_at seen for that terminal; the timestamps share one format.
function herdr.unseen(records, seen_at)
  if not seen_at then return records or {} end
  local out = {}
  for _, r in ipairs(records or {}) do
    local finished = r.state == "done" or r.state == "error"
    if not (finished and r.updated_at and r.updated_at <= seen_at) then out[#out + 1] = r end
  end
  return out
end

-- Indexed by urgency: blocked, error, done, working. Idle gets none.
herdr.glyphs = { "🟡", "🔴", "🟢", "🔵" }

function herdr.label(label, rank)
  for _, g in ipairs(herdr.glyphs) do
    if label:sub(1, #g + 1) == g .. " " then
      label = label:sub(#g + 2)
      break
    end
  end
  local glyph = rank and herdr.glyphs[rank]
  if glyph then return glyph .. " " .. label end
  return label
end

function herdr.sort_agents(list)
  table.sort(list, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.order < b.order
  end)
  return list
end

-- Index of the agent `step` places after `current`, wrapping. From a pane that
-- isn't an agent, next is the most urgent and previous the least.
function herdr.step(count, current, step)
  if current == 0 and step < 0 then current = count + 1 end
  return (current - 1 + step) % count + 1
end

return herdr
