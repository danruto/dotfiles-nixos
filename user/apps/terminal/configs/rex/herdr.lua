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

-- `ssh orb` becomes `ssh -t orb 'cd /path && exec $SHELL -l'`, so the new pane
-- lands in the same remote directory. -t goes first because the original args
-- end with the destination. Splitting a pane this made drops its old -t and
-- remote command first.
function herdr.ssh_argv(args, path, command)
  args = args:gsub("^(%S+) %-t ", "%1 "):gsub(" cd '.*' && exec %$SHELL %-l.*$", "")
  local argv = {}
  for word in args:gmatch("%S+") do argv[#argv + 1] = word end
  if #argv < 2 then return nil end
  table.insert(argv, 2, "-t")
  local run = "exec $SHELL -l"
  if command then run = run .. " -c " .. herdr.quote(command) end
  argv[#argv + 1] = "cd " .. herdr.quote(path) .. " && " .. run
  return argv
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
