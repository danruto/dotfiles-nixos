// node ~/dotfiles-nixos/user/apps/terminal/configs/rex/check-hc-rex-agents.mjs
import assert from "node:assert/strict";
import { isAgent, agentLabel, agentRank, agentOrder } from "./hc-rex-agents.mjs";

assert.equal(isAgent({ agent: "fish" }), false, "shells are not agents");
assert.equal(isAgent({ agent: "claude-code" }), true, "claude is an agent");
assert.equal(isAgent({ agent: "pig" }), true, "pig is an agent");
assert.equal(isAgent({ agent: "fish", parent: "t1" }), true, "children are agents");

assert.equal(agentLabel({ agent: "claude-code", where: "pb / 🟢 pbfb" }), "pbfb", "label is the herdr tab, without herdr's glyph");
assert.equal(agentLabel({ name: "review", parent: "t1", where: "pb / dot" }), "↳ review", "children are marked");
assert.equal(agentLabel({ agent: "pig", parent: "t12", where: "pb2 / stoodie", address: "pb2/t2j7" }), "↳ pig t2j7", "unnamed children carry their address");
assert.equal(agentLabel({ agent: "claude-code", where: "pb / dot" }), "dot", "the tab name wins over the program");
assert.equal(agentLabel({ agent: "claude-code" }), "claude-code", "the program is the fallback");

assert.equal(agentRank({ status: "blocked" }), 0, "blocked first");
assert.equal(agentRank({ status: "working" }), 2, "working next");
assert.equal(agentRank({}), 5, "unknown last");

assert.deepEqual(
  agentOrder([
    { agent: "claude-code", name: "b", status: "working" },
    { agent: "claude-code", name: "a", status: "working" },
    { agent: "claude-code", name: "c", status: "blocked" },
  ]).map(agentLabel),
  ["c", "a", "b"],
  "urgency, then name",
);

console.log("ok");
