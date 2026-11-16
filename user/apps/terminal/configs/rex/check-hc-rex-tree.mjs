// node ~/dotfiles-nixos/user/apps/terminal/configs/rex/check-hc-rex-tree.mjs
import assert from "node:assert/strict";
import * as tree from "./hc-rex-tree.mjs";

const block = (t, w) => ({ type: "block", id: "p" + t, content: { terminal: t }, ...(w ? { size: { weight: w } } : {}) });

const nested = {
  type: "row",
  id: "tb1",
  children: [
    { type: "column", id: "s1", size: { weight: 0.3 }, children: [block("t1"), block("t2")] },
    block("t3", 0.7),
  ],
};
const n = tree.fromHerdr(nested);
assert.equal(tree.sig(n), "row(column(t1,t2),t3)", "fromHerdr keeps shape");
assert.deepEqual(tree.leaves(n).map((l) => l.term), ["t1", "t2", "t3"], "leaves in order");

assert.equal(tree.sig(tree.fromHerdr({ type: "row", id: "tb", children: [block("t9")] })), "t9", "single pane tab");
assert.equal(
  tree.sig(tree.fromHerdr({ type: "row", id: "tb", children: [{ type: "row", id: "s", children: [block("a"), block("b")] }, block("c")] })),
  "row(a,b,c)",
  "same-direction nesting flattens",
);

const rex = tree.toRex(n, (t) => ({ t }));
assert.equal(rex.split.direction, "horizontal");
assert.ok(Math.abs(rex.split.ratio - 0.3) < 1e-9, "ratio from weights");
assert.equal(rex.split.before.split.direction, "vertical");
assert.deepEqual(rex.split.after, { block: { t: "t3" } });

const three = tree.toRex(tree.fromHerdr({ type: "row", id: "tb", children: [block("a", 1), block("b", 1), block("c", 2)] }), (t) => t);
assert.ok(Math.abs(three.split.ratio - 0.25) < 1e-9, "first of three");
assert.ok(Math.abs(three.split.after.split.ratio - 1 / 3) < 1e-9, "rest of three");

// A Rex layout as session.view reports it, after the blocks were made from toRex.
const ids = { a: "t1", b: "t2", c: "t3" };
const view = {
  rect: [0, 0, 1, 1],
  split: {
    direction: "horizontal", ratio: 0.3,
    before: { split: { direction: "vertical", ratio: 0.5, before: { block_id: "a" }, after: { block_id: "b" } } },
    after: { block_id: "c" },
  },
};
const back = tree.fromRex(view, (b) => ids[b] ?? null);
assert.equal(tree.sig(back), tree.sig(n), "round trip through Rex keeps the signature");
assert.equal(tree.sig(tree.fromRex(view, (b) => (b === "c" ? null : ids[b]))), "row(column(t1,t2),?)", "unmapped block shows as ?");

let next = 0;
const root = tree.toHerdr(back, "tb1", (t) => "p" + t, (p) => p + ++next);
assert.equal(root.type, "row");
assert.equal(root.id, "tb1");
assert.equal(tree.sig(tree.fromHerdr(root)), tree.sig(n), "toHerdr round trip");
assert.equal(root.children[0].type, "column");
assert.equal(root.children[1].id, "pt3", "pane ids kept");

const col = tree.toHerdr(tree.fromHerdr({ type: "row", id: "tb", children: [{ type: "column", id: "s", children: [block("x"), block("y")] }] }), "tb", (t) => t, (p) => p);
assert.equal(col.type, "row", "a column-only tab still has a row root");
assert.equal(col.children.length, 1);
assert.equal(col.children[0].type, "column");

console.log("ok");
