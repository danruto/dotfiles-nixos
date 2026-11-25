// node ~/dotfiles-nixos/user/apps/terminal/configs/rex/check-hc-rex-helpers.mjs
import assert from "node:assert/strict";
import { helpersOf, helperLabel, helperTree } from "./hc-rex-helpers.mjs";
import * as tree from "./hc-rex-tree.mjs";

const terms = [
  { address: "orb/t1", state: "live" },
  { address: "orb/t2", state: "live", parent: "orb/t1", created_ms: 20 },
  { address: "orb/t3", state: "live", parent: "orb/t1", created_ms: 10 },
  { address: "orb/t4", state: "live", parent: "orb/t2", created_ms: 30 },
  { address: "orb/t5", state: "finished", parent: "orb/t1" },
  { address: "orb/t6", state: "live", parent: "orb/t1", created_ms: 5 },
  { address: "orb/t7", state: "live", parent: "orb/t9" },
  { address: "orb/t8", state: "live", parent: "orb/t8" },
];

assert.deepEqual(helpersOf(terms, ["orb/t1"], new Set()), ["orb/t6", "orb/t3", "orb/t2", "orb/t4"],
  "live descendants, oldest first, finished ones dropped");
assert.deepEqual(helpersOf(terms, ["orb/t1"], new Set(["orb/t6"])), ["orb/t3", "orb/t2", "orb/t4"],
  "a helper a tab already shows stays out");
assert.deepEqual(helpersOf(terms, ["orb/t9"], new Set()), ["orb/t7"], "a parent that isn't listed still has helpers");
assert.deepEqual(helpersOf(terms, ["orb/t8"], new Set()), [], "a terminal isn't its own helper");
assert.deepEqual(helpersOf(terms, [], new Set()), [], "no roots, no helpers");

assert.equal(helperLabel("api"), "↳ api");
assert.equal(helperLabel("x".repeat(200)).length, 128, "labels fit Rex's limit");

assert.deepEqual(tree.toRex(helperTree(["t1"]), (t) => t), { block: "t1" }, "one helper fills the tab");
assert.equal(tree.sig(helperTree(["t1", "t2", "t3"])), "row(t1,t2,t3)", "several sit side by side");

console.log("PASS: hc helpers");
