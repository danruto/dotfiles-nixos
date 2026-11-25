-- rex do ~/.config/rex/hc-rex-bridge.lua
-- One Rex connection for hc-rex-sync. Starting `rex api call` for every call
-- cost the sync about half a second of CPU per pass; this reads one JSON
-- request per line, { id, method, args }, and answers each with one line,
-- { id, result } or { id, error }.
-- Session methods need the connection attached to the session, so a call
-- refused for that is attached and tried once more.
local attached = {}

local function call(method, args)
  local res, err = rex.call(method, args)
  local sid = args.session_id
  if res == nil and err and sid and not attached[sid] and tostring(err):find("not attached", 1, true) then
    attached[sid] = true
    rex.call("session.attach", { session_id = sid })
    res, err = rex.call(method, args)
  end
  return res, err
end

for line in io.stdin:lines() do
  local ok, req = pcall(rex.json.decode, line)
  if ok and type(req) == "table" and req.method then
    local res, err = call(req.method, req.args or {})
    local reply = { id = req.id }
    if err ~= nil then reply.error = tostring(err) else reply.result = res end
    io.stdout:write(rex.json.encode(reply) .. "\n")
    io.stdout:flush()
  end
end
