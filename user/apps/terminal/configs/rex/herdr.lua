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

-- Live terminals started by another terminal, the rows herdr shows indented
-- under an agent. `term` limits them to one parent. Each is paired with its
-- parent's entry, which may be missing.
function herdr.hc_children(terminals, term)
  local by = {}
  for _, t in ipairs(terminals or {}) do
    if t.address then by[t.address] = t end
  end
  local out = {}
  for _, t in ipairs(terminals or {}) do
    local parent = t.parent
    if t.state == "live" and parent and parent ~= t.address
        and (not term or parent == term) then
      out[#out + 1] = { terminal = t, parent = by[parent] }
    end
  end
  return out
end

-- herdr sorts its agent panel by who needs you: blocked, then failed, done,
-- working and idle.
local rank = { blocked = 1, error = 2, done = 3, working = 4, idle = 5 }

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
