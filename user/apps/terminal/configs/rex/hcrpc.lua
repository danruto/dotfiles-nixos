-- hc as init.lua and the agents board reach it.
local hcrpc = {}

hcrpc.RECENT_MS = 3600 * 1000

-- The Rex server runs with a bare PATH (/usr/local/bin:/usr/bin under
-- systemd), so programs are looked for where they get installed.
function hcrpc.find(name, extra)
  local home = os.getenv("HOME") or ""
  local paths = { home .. "/.nix-profile/bin/" .. name, home .. "/.local/bin/" .. name,
    "/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/bin/" .. name,
    "/run/current-system/sw/bin/" .. name, "/opt/homebrew/bin/" .. name }
  for _, path in ipairs(extra or {}) do paths[#paths + 1] = path end
  for _, path in ipairs(paths) do
    local fh = io.open(path, "r")
    if fh then
      fh:close()
      return path
    end
  end
  return name
end

function hcrpc.bin()
  return hcrpc.find("hc")
end

-- terminal.list carries each terminal's status and foreground, which
-- `hc ls` leaves out.
function hcrpc.terminals(hc)
  local req = rex.json.encode{ jsonrpc = "2.0", id = 1, method = "terminal.list", params = { all = true } }
  local got, err = rex.exec({ hc, "connect" }, { stdin = req .. "\n", timeout = 20 })
  local line = got and got.ok and got.stdout:match("[^\n]+")
  local ok, msg = pcall(rex.json.decode, line or "")
  if not (ok and msg and msg.result) then
    rex.log("warn", "hc agents: " .. hc .. " terminal.list failed: "
      .. tostring(err or (got and (got.stderr ~= "" and got.stderr or got.stdout))))
    return {}
  end
  return msg.result.terminals or {}
end

return hcrpc
