import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const root = new URL("../", import.meta.url);
const source = await readFile(new URL("mods/t3-threads/model.js", root), "utf8");
const { threadGroups, statusLabel } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);
const tab = (id, extra = {}) => ({ id, name: id, named: true, settled: false, ...extra });
const spaces = [
  { id: "local", name: "Project", machine: null, branch: "main", tabs: [tab("one"), tab("two"), tab("three"), tab("parked", { settled: true })] },
  { id: "remote", name: "Project", machine: "remote", tabs: [tab("four", { status: "blocked" })] },
];
const groups = (pins = [], query = "", settled = false) => threadGroups(spaces, [], [], pins, query, settled);
assert.deepEqual(groups(["three"])[0].threads.map(thread => thread.tab.id), ["three", "one", "two"]);
assert.equal(groups()[0].threads.length, 3);
assert.equal(groups([], "", true)[0].threads[0].tab.id, "parked");
assert.equal(groups().length, 2, "same-name projects on different machines must stay separate");
assert.equal(groups([], "REMOTE")[0].space.id, "remote");
assert.equal(groups([], "needs you")[0].threads[0].tab.id, "four");
assert.equal(groups([], " main ")[0].threads.length, 3);
assert.equal(groups([], "missing").length, 0);
assert.deepEqual(["working", "blocked", "done", "idle", null].map(statusLabel), ["Working", "Needs you", "Done", "Idle", "Terminal"]);
const auto = [{ id: "auto", name: "Auto", tabs: [tab("automatic", { named: false })] }];
const agent = { tab: "automatic", title: "Fix navigation", program: { name: "PiG" } };
assert.equal(threadGroups(auto, [agent], [], [], "pig")[0].threads[0].title, "Fix navigation");
assert.equal(threadGroups(auto, [], [{ tab: "automatic", title: "Shell", branch: "topic" }], [], "topic")[0].threads[0].title, "Shell");

function nodes(node) { return [node, ...(node.children ?? []).flatMap(nodes)]; }
for (const name of ["herdr-compact", "t3-threads"]) {
  const tree = JSON.parse(await readFile(new URL(`layouts/${name}.json`, root), "utf8"));
  const all = nodes(tree), pane = all.find(node => node.id === "main").content.pane;
  assert.equal(new Set(all.map(node => node.id)).size, all.length, `${name}: unique node IDs`);
  assert.equal(pane.border.width, 0);
  assert.equal(pane.focus.width, 0);
  assert.equal(pane.radius, 0);
  assert.equal(pane.header.reveal, "hover");
  assert.equal(all.find(node => node.id === "panel").hidden, true);
  const panels = all.find(node => node.id === "panel-body").children;
  assert.deepEqual(panels.map(node => node.id), ["files", "changes", "jira"]);
  assert.equal(panels.find(node => node.id === "files").content.mod, "design-files");
  assert.equal(panels.find(node => node.id === "jira").content.mod, "jira-tickets");
  assert.equal(panels.find(node => node.id === "jira").content.props.layoutBlock, "jira");
  if (name === "herdr-compact") assert.equal(all.find(node => node.id === "tabs").content.mod, "review-tabs");
  await readFile(new URL(tree.preview, root));
}
console.log("PASS: thread filtering, stable pins, remote grouping, settled shelf, title fallback, status labels, and both layout contracts");
