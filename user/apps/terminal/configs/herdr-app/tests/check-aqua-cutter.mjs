// Renders the Aqua Cutter page and every section's inspector reader against mock gpui/herdr
// modules. Elements reject anything but an element or a string as a child, which is the rule the
// real runtime enforces. Usage: node check-aqua-cutter.mjs [walkthrough.json ...]
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { register } from "node:module";

const mods = new URL("../mods/aqua-cutter/", import.meta.url);
const fixtures = new URL("./fixtures/aqua-cutter/", import.meta.url);

const isElement = (value) => value && value.__element;
function element(kind) {
  const node = { __element: true, kind, kids: [], attached: false };
  const attach = (value) => {
    if (!(isElement(value) || typeof value === "string")) throw new Error(`${kind}.child(${typeof value}: ${JSON.stringify(value)?.slice(0, 80)})`);
    if (isElement(value)) {
      if (value.attached) throw new Error(`${value.kind} was already added to a parent; elements are single-use`);
      value.attached = true;
    }
    node.kids.push(value);
  };
  const proxy = new Proxy(node, { get(target, key) {
    if (key in target) return target[key];
    if (key === "child") return (value) => { if (target.attached) throw new Error(`${kind} changed after it was added to a parent`); attach(value); return proxy; };
    if (key === "children") return (list) => { if (!Array.isArray(list)) throw new Error(`${kind}.children(${typeof list})`); if (target.attached) throw new Error(`${kind} changed after it was added to a parent`); list.forEach(attach); return proxy; };
    if (key === "when") return (condition, then) => (condition ? then(proxy) : proxy);
    if (key === "id") return (value) => { target.elementId = value; return proxy; };
    if (key === "on_click") return (handler) => { target.onClick = handler; return proxy; };
    return () => proxy;
  } });
  return proxy;
}

const theme = {
  background: "#17171b", foreground: "#eeedf2", muted: "#aaa6b5", dim: "#777777", surface: "#24242b", raised: "#302b40",
  border: "#68636f", accent: "#c4b5fd", chrome: "#111111", hover: "#333333", done: "#4ade80", blocked: "#f87171", working: "#fbbf24",
  ansi1: "#ff5555", ansi2: "#55ff55", ansi3: "#ffff55", ansi4: "#5555ff", ansi5: "#ff55ff", ansi6: "#55ffff", ansi9: "#ff8855",
};
const state = { doc: "", props: {} };
const released = [];
globalThis.__aquaMocks = {
  "gpui-kit": { View: class {}, div: () => element("div"), svg: () => element("svg"), image: () => element("image") },
  "gpui-base": {
    h_flex: () => element("h_flex"), v_flex: () => element("v_flex"),
    TextView: { markdown: () => element("text") }, Editor: { new: () => element("editor") },
    EditorState: { new: (options) => ({ options, release() { released.push(options); } }) },
    InputState: { new: () => ({ on() {}, set_value() {}, value: () => "" }) }, Input: { new: () => element("input") },
  },
  herdr: {
    settings: () => ({ font: "Mono" }), theme: () => theme, props: () => state.props,
    readTextFile: async () => state.doc, writeTextFile: async () => {},
    exec: async (...args) => state.exec ? state.exec(...args) : ({ stdout: JSON.stringify({ ok: true, diagrams: Array.from({ length: 32 }, () => ({ path: "data/aqua-svg/x.svg", width: 800, height: 300 })) }) }),
    appHome: () => "/app", spaces: () => state.spaces ?? [], panes: () => state.panes ?? [], focused: () => state.focused ?? null, window: () => ({ platform: "macos" }),
    openOverlay: (options) => { (state.overlays ??= []).push(options); return ""; }, closeOverlay: () => null, nextCommand: () => Promise.reject(new Error("no commands")),
    shared: (key) => state.shared?.[key], setShared: (key, value) => { state.shared = { ...state.shared, [key]: value }; },
  },
};
globalThis.localStorage = { getItem: () => null, setItem() {} };
register("data:text/javascript," + encodeURIComponent(`
  const names = ["gpui-kit", "gpui-base", "herdr"];
  export async function resolve(specifier, context, next) {
    return names.includes(specifier) ? { url: "aqua-mock:" + specifier, shortCircuit: true } : next(specifier, context);
  }
  export async function load(url, context, next) {
    if (!url.startsWith("aqua-mock:")) return next(url, context);
    const name = url.slice(10);
    const keys = { "gpui-kit": ["View", "div", "svg", "image"], "gpui-base": ["h_flex", "v_flex", "TextView", "Editor", "EditorState", "InputState", "Input"],
      herdr: ["settings", "theme", "props", "readTextFile", "writeTextFile", "exec", "appHome", "spaces", "panes", "focused", "window", "openOverlay", "closeOverlay", "nextCommand", "shared", "setShared"] }[name];
    return { format: "module", shortCircuit: true, source: keys.map((key) => "export const " + key + " = globalThis.__aquaMocks[" + JSON.stringify(name) + "]." + key + ";").join("\\n") };
  }
`));

const { default: AquaCutterPage } = await import(new URL("page.js", mods));
const { default: AquaCutterInspector } = await import(new URL("inspector.js", mods));
const { READERS } = await import(new URL("readers.js", mods));
const { stops } = await import(new URL("model.js", mods));

const tasks = [], timers = [];
const cx = { spawn: (task) => tasks.push(task), notify() {}, timer: { after() {}, every(ms, handler) { timers.push(handler); } }, write_to_clipboard() {} };
async function settle() {
  while (tasks.length) {
    try { await tasks.shift()(cx); } catch (error) { if (error.message !== "no commands") throw error; }
  }
}

const files = process.argv.slice(2).length ? process.argv.slice(2)
  : [new URL("example.json", mods).pathname, ...readdirSync(fixtures).filter((name) => name.endsWith(".json")).map((name) => new URL(name, fixtures).pathname)];
const counts = new Map();
for (const file of files) {
  state.doc = readFileSync(file, "utf8");
  const doc = JSON.parse(state.doc);
  state.props = { file };
  const page = new AquaCutterPage();
  page.init({}, cx);
  await settle();
  assert.ok(page.doc, `${file}: page loaded`);
  page.render(cx);
  page.collapsed = new Set();
  page.refsOpen = true;
  page.width = 1400;
  page.render(cx);
  assert.equal(stops(doc).length > 0, true, `${file}: has stops`);
  for (const section of doc.sections) {
    state.props = { view: "inspector", file, section: section.id };
    const view = new AquaCutterInspector();
    view.init({}, cx);
    await settle();
    assert.ok(view.section, `${file}#${section.id}: inspector loaded`);
    try {
      view.render(cx);
      view.sourceOpen = true;
      view.width = 600;
      view.render(cx);
      await settle();
      view.width = 1300;
      view.render(cx);
    } catch (error) {
      error.message = `${file.split("/").pop()}#${section.id} (${section.type}): ${error.message}`;
      throw error;
    }
    view.close();
    counts.set(section.type, (counts.get(section.type) ?? 0) + 1);
  }
  // C4 opened at an address another reader requested: a node and an edge target on each level.
  for (const section of doc.sections.filter((entry) => entry.type === "c4")) {
    for (const level of section.levels ?? []) {
      const pane = section.mode === "diff" ? "before" : "single";
      for (const target of [{ kind: "node", node: "API" }, { kind: "edge", edge: { from: "API", to: "Queue", label: "publish", occurrence: 0 } }]) {
        state.props = { view: "inspector", file, section: section.id, request: { architecture: section.id, level: level.id, pane, target } };
        const view = new AquaCutterInspector();
        view.init({}, cx);
        await settle();
        view.render(cx);
        assert.equal(view.context().request.level, level.id);
        view.close();
      }
    }
  }
}
// Browse is a lazy tree of the session's repository; a Files request opens once, from the
// view's timer and never from render.
{
  const file = files[0];
  state.doc = readFileSync(file, "utf8");
  state.props = { file };
  state.shared = { "aqua-cutter.open": { file: "/old.json", on: null, at: Date.now() - 60000 } };
  timers.length = 0;
  const page = new AquaCutterPage();
  page.init({}, cx);
  await settle();
  timers.forEach((tick) => tick(cx));
  await settle();
  assert.equal(page.path, file, "a stale Files request must not override props");
  const find = (node, id) => {
    if (!node || typeof node !== "object") return null;
    if (node.elementId === id) return node;
    for (const child of node.kids ?? []) { const found = find(child, id); if (found) return found; }
    return null;
  };
  const listings = [];
  const tree = { "/repo": [["d", "docs"], ["d", "src"], ["f", "README.md"], ["f", "notes.txt"]], "/repo/docs": [["d", "pr"]], "/repo/docs/pr": [["f", "walk.json"]], "/repo/src": [["f", "main.ts"]] };
  state.exec = async (command, args, options) => {
    if (command === "git") { assert.equal(options.on, "remote"); return { code: 0, stdout: options.cwd.startsWith("/other") ? "/other\n" : "/repo\n" }; }
    listings.push(args.at(-1));
    assert.equal(options.on, "remote", "listings run on the session's machine");
    return { code: 0, stdout: (tree[args.at(-1)] ?? []).flatMap(([kind, name]) => [kind, name]).join("\0") + "\0" };
  };
  page.where = () => ({ cwd: "/repo/src", on: "remote" });
  page.browse(cx);
  await settle();
  assert.equal(page.browsing.root, "/repo", "Browse roots at the Git top level");
  assert.deepEqual(listings, ["/repo", "/repo/docs", "/repo/docs/pr"], "docs/pr opens by default");
  let view = page.render(cx);
  assert.ok("onClick" in find(view, "aqua-browse-README.md"), "Markdown is openable");
  assert.ok(!("onClick" in find(view, "aqua-browse-notes.txt")), "other files are shown but not openable");
  find(view, "aqua-browse-src").onClick({}, cx);
  await settle();
  assert.ok(find(page.render(cx), "aqua-browse-src/main.ts"), "folders expand lazily");
  find(page.render(cx), "aqua-browse-docs/pr/walk.json").onClick({}, cx);
  assert.ok(page.browsing, "the file panel stays open after opening a file");
  await settle();
  tree["/other"] = [["f", "notes.md"]];
  page.where = () => ({ cwd: "/other", on: "remote" });
  timers.forEach((tick) => tick(cx));
  await settle();
  assert.equal(page.browsing.root, "/other", "the open panel follows a new space or tab");
  delete page.where;
  state.spaces = [
    { id: "s1", active: false, folder: "/one", machine: null, tabs: [{ id: "t1", active: true }] },
    { id: "s2", active: true, folder: "", machine: "orb", tabs: [{ id: "t2", active: false }, { id: "t3", active: true }] },
  ];
  state.panes = [{ pane: "p1", tab: "t1", cwd: "/one/repo" }, { pane: "p2", tab: "t2", cwd: "/two/a" }, { pane: "p3", tab: "t3", cwd: "/two/b" }, { pane: "p4", tab: "t3", cwd: null }];
  state.focused = { space: "s1", tab: "t1", pane: "p1", cwd: "/one/repo" };
  assert.deepEqual({ ...page.where() }, { cwd: "/two/b", on: "orb" }, "focus left in another space is ignored; the active tab's terminal wins");
  state.focused = { space: "s2", tab: "t2", pane: "p2", cwd: null };
  assert.equal(page.where().cwd, "/two/a", "the focused terminal in this space wins");
  state.focused = { space: "s2", tab: "t3", pane: "p4", cwd: null };
  assert.equal(page.where().cwd, "/two/b", "a mod pane uses a terminal in its tab");
  state.spaces = state.panes = state.focused = undefined;
  state.exec = undefined;
  assert.equal(page.on, "remote");
  state.shared = { "aqua-cutter.open": { file, on: null, at: Date.now() } };
  page.render(cx);
  assert.equal(tasks.length, 0, "render never starts a load");
  timers.forEach((tick) => tick(cx));
  await settle();
  assert.equal(page.path, file);
  assert.equal(page.on, null, "a fresh Files request opens its file on the next tick");
  timers.forEach((tick) => tick(cx));
  assert.equal(tasks.length, 0, "a request opens once");
  state.shared = undefined;
}
// Markdown opens in the same page: native sections, fences in Editors, diagrams through the
// shared cache with Inspect into the pan/zoom inspector, relative links with Back, and the
// shared Colour / Edges style.
{
  const find = (node, id) => {
    if (!node || typeof node !== "object") return null;
    if (node.elementId === id) return node;
    for (const child of node.kids ?? []) { const found = find(child, id); if (found) return found; }
    return null;
  };
  const markdown = readFileSync(new URL("example.md", mods), "utf8");
  state.doc = markdown;
  state.props = { file: "/p/docs/a.md", on: "remote" };
  state.shared = undefined;
  state.overlays = [];
  const page = new AquaCutterPage();
  page.init({}, cx);
  await settle();
  assert.ok(page.markdown && !page.doc, "a .md path opens as Markdown");
  assert.equal(page.on, "remote");
  assert.equal(page.markdown.diagrams.length, 3);
  assert.ok(page.markdown.editors.size > 0, "code fences get read-only Editors");
  assert.equal(page.markdown.doc.title, "Markdown + Aqua", "the H1 is the title");
  assert.deepEqual(page.markdown.doc.chapters.map((chapter) => chapter.title), ["A small workflow", "A conversation", "A small data model", "Links and formatting"], "each H2 is a card");
  page.render(cx);
  await settle();
  assert.ok(page.markdown.diagrams.every((item) => page.markdown.cache.get(item.source)?.path), "every diagram rendered through the cache");
  find(page.render(cx), "aqua-md-inspect-all").onClick({}, cx);
  const overlay = state.overlays.at(-1);
  assert.equal(overlay.mod, "aqua-cutter");
  assert.equal(overlay.kind, "dialog");
  assert.equal(overlay.props.view, "diagram");
  assert.equal(overlay.props.diagrams.length, 3);
  find(page.render(cx), "aqua-md-chapter-1-0").onClick({}, cx);
  assert.ok(page.markdown.collapsed.has(0), "a card collapses");
  find(page.render(cx), "aqua-md-expand").onClick({}, cx);
  assert.equal(page.markdown.collapsed.size, 0);
  assert.ok(find(page.render(cx), "aqua-md-inspect-1-0"), "a framed diagram has Inspect in its bar");
  find(page.render(cx), "aqua-md-colour-1").onClick({}, cx);
  assert.equal(state.shared["aqua-cutter.style"].colours, "Light", "Colour cycles the shared style");
  page.render(cx);
  assert.equal(tasks.length, 1, "a style change renders the diagrams again");
  await settle();
  page.follow("../other.md#part", cx);
  await settle();
  assert.equal(page.path, "/p/other.md");
  assert.equal(page.on, "remote", "links stay on the source machine");
  assert.equal(page.history.length, 1);
  find(page.render(cx), "aqua-back").onClick({}, cx);
  await settle();
  assert.equal(page.path, "/p/docs/a.md");
  page.open("/p/first.md", null, cx);
  page.open("/p/second.md", null, cx);
  await settle();
  assert.equal(page.path, "/p/second.md", "an older load cannot replace a newer one");
  const editors = [...page.markdown.editors.values()];
  state.doc = readFileSync(files[0], "utf8");
  page.open(files[0], null, cx);
  await settle();
  assert.ok(page.doc && !page.markdown, "a walkthrough replaces the Markdown");
  assert.equal(released.filter((options) => editors.some((editor) => editor.options === options)).length, editors.length, "Markdown editors are released");
  state.shared = undefined;
}
const native = [...counts.keys()].filter((type) => READERS[type] || ["trace-diff", "trace", "what-breaks", "code-lens"].includes(type));
console.log(`PASS: ${files.length} walkthroughs, ${[...counts.values()].reduce((a, b) => a + b, 0)} sections rendered; native readers: ${native.join(", ")}`);
