-- rex do ~/dotfiles-nixos/user/apps/terminal/configs/rex/check.lua
local herdr = dofile(os.getenv("HOME") .. "/dotfiles-nixos/user/apps/terminal/configs/rex/herdr.lua")

local function eq(got, want, what)
  if rex.json.encode(got) ~= rex.json.encode(want) then
    error(what .. ": got " .. rex.json.encode(got) .. ", want " .. rex.json.encode(want), 0)
  end
end

eq(herdr.pwd_path("file://orb/home/me/my%20repo"), "/home/me/my repo", "pwd_path decodes")
eq(herdr.pwd_path("not a url"), nil, "pwd_path rejects")

eq(herdr.ssh_argv("ssh orb\n", "/home/me/it's"), {
  "ssh", "-t", "orb", "cd '/home/me/it'\\''s' && exec $SHELL -l",
}, "ssh_argv shell")
eq(herdr.ssh_argv("ssh -p 22 orb", "/x", "gitui"), {
  "ssh", "-t", "-p", "22", "orb", "cd '/x' && exec $SHELL -l -c 'gitui'",
}, "ssh_argv command")
eq(herdr.ssh_argv("ssh", "/x"), nil, "ssh_argv needs a destination")
eq(herdr.ssh_argv("ssh -t orb cd '/tmp' && exec $SHELL -l -c 'gitui'\n", "/y"), {
  "ssh", "-t", "orb", "cd '/y' && exec $SHELL -l",
}, "ssh_argv replaces its own remote command")

eq(herdr.urgency({ { state = "working" }, { state = "blocked" } }), 1, "urgency picks blocked")
eq(herdr.urgency({}), nil, "urgency without records")

local done = { state = "done", updated_at = "2026-10-30T20:00:00+11:00" }
local working = { state = "working", updated_at = "2026-10-30T19:00:00+11:00" }
eq(#herdr.unseen({ done, working }, nil), 2, "unseen keeps all without a visit")
eq(herdr.unseen({ done, working }, "2026-10-30T20:00:00+11:00"), { working }, "unseen drops a seen done")
eq(#herdr.unseen({ done }, "2026-10-30T19:30:00+11:00"), 1, "unseen keeps a newer done")

eq(herdr.label("api", 4), "🔵 api", "label adds a glyph")
eq(herdr.label("🔵 api", 3), "🟢 api", "label swaps a glyph")
eq(herdr.label("🟢 api", 5), "api", "label drops a glyph for idle")
eq(herdr.label("🟢 api", nil), "api", "label drops a glyph without agents")

local sorted = herdr.sort_agents({
  { rank = 4, order = 0 }, { rank = 1, order = 1 }, { rank = 4, order = 2 },
})
eq({ sorted[1].order, sorted[2].order, sorted[3].order }, { 1, 0, 2 }, "sort_agents")

eq(herdr.step(3, 0, 1), 1, "next from a non-agent pane")
eq(herdr.step(3, 0, -1), 3, "previous from a non-agent pane")
eq(herdr.step(3, 3, 1), 1, "next wraps")
eq(herdr.step(3, 1, -1), 3, "previous wraps")

return "ok"
