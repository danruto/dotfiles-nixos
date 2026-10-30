import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { runInNewContext } from "node:vm";

function element() {
  const node = { children: [] };
  const builder = new Proxy(node, {
    get(target, name) {
      if (name === "_node") return target;
      if (name === "id") return id => { target.id = id; return builder; };
      if (name === "child") return child => { target.children.push(child); return builder; };
      if (name === "when") return (condition, callback) => { if (condition) callback(builder); return builder; };
      if (name === "on_click") return callback => { target.click = callback; return builder; };
      return () => builder;
    },
  });
  return builder;
}

const events = [];
const source = await readFile(new URL("../mods/design-files/main.js", import.meta.url), "utf8");
const Files = runInNewContext(source.replace(/^import .*;\n/gm, "").replace("export default class Files", "class Files") + "\nFiles;", {
  View: class {}, div: element, h_flex: element, v_flex: element,
  spaces: () => [], focused: () => null, theme: () => ({}),
  setShared: (key, value) => events.push({ key, value }),
  run: (name, args) => events.push({ name, args }),
  Date,
});
const files = new Files();
files.context = '{"on":null}';
files.root = "/project with spaces";
files.entries = new Map();

for (const on of [null, "remote"]) {
  files.on = on;
  for (const file of ["docs/design.md", "DESIGN.MD", "design.markdown", "design.txt", "design.md.txt", null]) {
    files.file = file;
    const tree = files.render({});
    const find = (node, id) => {
      if (!node || typeof node !== "object") return null;
      if (node._node.id === id) return node._node;
      for (const child of node._node.children) { const found = find(child, id); if (found) return found; }
      return null;
    };
    const action = find(tree, "files-mermaid-diagrams");
    const reader = find(tree, "files-read-markdown");
    const markdown = /\.(?:md|markdown)$/i.test(file ?? "");
    assert.equal(action, null, "The retired standalone Aqua Cutter action must be absent");
    assert.equal(Boolean(reader), markdown, String(file));
    if (!reader) continue;
    const actions = find(tree, "files-markdown-actions");
    assert.deepEqual(actions.children.map(child => child._node.id), ["files-read-markdown"]);
    assert.ok(reader.children.includes("Read Markdown"));
    events.length = 0;
    reader.click();
    assert.equal(events.length, 1, "Opening a reader tab must not invoke the retired standalone inspector");
    assert.equal(events[0].name, "tab.new");
    assert.equal(events[0].args.name, file.split("/").pop());
    assert.equal(events[0].args.mod, "aqua-markdown");
    assert.equal(events[0].args.props.file, `${files.root}/${file}`);
    assert.equal(events[0].args.props.on, on);
  }
}
console.log("PASS: Markdown reader action, retired standalone action absent, local/remote file handoff, and an isolated reader tab");
