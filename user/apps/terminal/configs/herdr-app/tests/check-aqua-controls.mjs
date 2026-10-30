import assert from "node:assert/strict";
import { readFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runInNewContext } from "node:vm";
import { spawnSync } from "node:child_process";
import { DiagramViewport } from "../mods/aqua-markdown/viewport.js";
import { COLOURS, EDGES, diagramStyle } from "../mods/aqua-markdown/styles.js";
import { renderDocument } from "../mods/aqua-markdown/render.mjs";

const theme = { background: "#17171b", foreground: "#eeedf2", muted: "#aaa6b5", surface: "#24242b", raised: "#302b40", border: "#68636f", accent: "#c4b5fd" };
const viewport = new DiagramViewport();
viewport.size = { width: 600, height: 500 };
viewport.content = { width: 1000, height: 800 };
assert.equal(viewport.scale(), 0.58);
assert.deepEqual(viewport.position(), { x: 10, y: 18.00000000000003 });
viewport.reset(false);
viewport.move(60, -40);
assert.deepEqual(viewport.position(), { x: -140, y: -190 });
const anchor = { x: 180, y: 220 }, before = viewport.position();
const point = { x: (anchor.x - before.x) / viewport.scale(), y: (anchor.y - before.y) / viewport.scale() };
viewport.changeZoom(1.25, anchor);
assert.equal(viewport.scale(), 1.25);
assert.equal(viewport.position().x + point.x * viewport.scale(), anchor.x);
assert.equal(viewport.position().y + point.y * viewport.scale(), anchor.y);
viewport.move(1e6, -1e6);
assert.ok(viewport.position().x < viewport.size.width);
assert.ok(viewport.position().y + viewport.content.height * viewport.scale() > 0);
viewport.centre();
assert.equal(viewport.scale(), 1.25);
assert.deepEqual(viewport.pan, { x: 0, y: 0 });
viewport.changeZoom(100);
assert.equal(viewport.scale(), 4);
viewport.changeZoom(0.0001);
assert.equal(viewport.scale(), 0.1);
viewport.reset();
assert.equal(viewport.fit, true);
assert.deepEqual(viewport.pan, { x: 0, y: 0 });

function element() {
  const node = { children: [], handlers: {} };
  const builder = new Proxy(node, { get(target, name) {
    if (name === "_node") return target;
    if (name === "id") return id => { target.id = id; return builder; };
    if (name === "child") return child => { target.children.push(child); return builder; };
    if (name === "children") return children => { target.children.push(...children); return builder; };
    if (name === "when") return (condition, callback) => { if (condition) callback(builder); return builder; };
    if (String(name).startsWith("on_")) return (...args) => { target.handlers[name] = args.at(-1); return builder; };
    return () => builder;
  } });
  return builder;
}
const storage = new Map();
let tasks = 0, notifications = 0, stopped = 0;
const closed = [];
let inspectorProps = { overlay: "synthetic-inspector" };
const cx = { spawn: () => tasks++, notify: () => notifications++, stop_propagation: () => stopped++ };
const source = await readFile(new URL("../mods/aqua-markdown/inspector.js", import.meta.url), "utf8");
const Viewer = runInNewContext(source.replace(/^import .*;\n/gm, "").replace("export default class DiagramInspector", "class DiagramInspector") + "\nDiagramInspector;", {
  View: class {}, div: element, h_flex: element, v_flex: element, image: element,
  InputState: { new: () => ({ on() {}, set_value() {} }) }, Input: { new: element },
  localStorage: { getItem: key => storage.get(key) ?? null, setItem: (key, value) => storage.set(key, value) },
  theme: () => theme, shared: () => null, props: () => inspectorProps, closeOverlay: id => closed.push(id), DiagramViewport, COLOURS, EDGES, diagramStyle,
  appHome: () => "/app", readTextFile: async () => "# Synthetic", writeTextFile: async () => {},
  exec: async command => {
    assert.equal(command, "node", "Resolve Node through PATH on every machine");
    return { code: 0, stdout: JSON.stringify({ ok: true, diagrams: [{ title: "First", line: 10 }, { title: "Second", line: 30 }], elapsedMs: 1, engine: "Synthetic" }) };
  },
});
const viewer = new Viewer();
viewer.init({}, cx);
viewer.diagrams = [{ path: "synthetic.svg", type: "flowchart", width: 1000, height: 800, title: "Synthetic", line: 1 }];
const find = (element, id) => {
  if (!element || typeof element !== "object") return null;
  const node = element._node;
  if (node.id === id) return node;
  for (const child of node.children) { const found = find(child, id); if (found) return found; }
  return null;
};
const click = id => {
  const button = find(viewer.render(cx), id);
  assert.ok(button, id);
  button.handlers.on_click({}, cx);
};
click("aqua-svg-one");
click("aqua-svg-right");
assert.equal(viewer.view.pan.x, 60);
click("aqua-svg-up");
assert.equal(viewer.view.pan.y, -60);
click("aqua-svg-centre");
assert.deepEqual(viewer.view.pan, { x: 0, y: 0 });
let canvas = find(viewer.render(cx), "aqua-svg-viewport");
canvas.handlers.on_mouse_down({ position: { x: 100, y: 100 } }, cx);
canvas.handlers.on_mouse_move({ position: { x: 130, y: 140 } }, cx);
assert.deepEqual(viewer.view.pan, { x: 30, y: 40 });
canvas.handlers.on_mouse_up({}, cx);
canvas.handlers.on_mouse_move({ position: { x: 180, y: 180 } }, cx);
assert.deepEqual(viewer.view.pan, { x: 30, y: 40 });
canvas.handlers.on_mouse_down({ position: { x: 100, y: 100 } }, cx);
canvas.handlers.on_hover(false, cx);
assert.equal(viewer.drag, null);
canvas.handlers.on_scroll_wheel({ delta: { x: -10, y: -20 }, modifiers: {} }, cx);
assert.deepEqual(viewer.view.pan, { x: 20, y: 20 });
const previousScale = viewer.view.scale();
canvas.handlers.on_scroll_wheel({ delta: { x: 0, y: -20 }, modifiers: { control: true }, local_position: { x: 200, y: 150 } }, cx);
assert.ok(viewer.view.scale() > previousScale);
assert.equal(tasks, 1, "Pan and zoom never run a helper or start async work");
assert.ok(notifications > 0 && stopped > 0);
click("aqua-svg-fit");
assert.equal(viewer.view.fit, true);
click("aqua-svg-colours");
assert.equal(viewer.colours, "Light");
assert.equal(storage.get("colours"), "Light");
click("aqua-svg-edges");
assert.equal(viewer.edges, "Straight");
assert.equal(storage.get("edges"), "Straight");
viewer.diagrams[0].type = "sequence";
assert.equal(find(viewer.render(cx), "aqua-svg-edges"), null, "Non-flowcharts must not offer an inert routing control");
const restored = new Viewer();
restored.init({}, cx);
assert.equal(restored.colours, "Light");
assert.equal(restored.edges, "Straight");
click("aqua-inspector-close");
assert.deepEqual(closed, ["synthetic-inspector"], "The Close button closes only its own overlay");
inspectorProps = { overlay: "selected-inspector", document: { path: "/project/design.md", on: "remote", revision: 1 }, line: 30, colours: "Colourful", edges: "Curved" };
const selected = new Viewer(), pending = [], loadContext = { spawn: task => pending.push(task), notify() {} };
selected.init({}, loadContext);
selected.load(inspectorProps.document, loadContext);
await pending[1](loadContext);
assert.equal(selected.selected, 1, "Inspect diagram selects the clicked source line");
assert.equal(selected.document.on, "remote");
assert.equal(selected.colours, "Colourful");
assert.equal(selected.edges, "Curved");
selected.select(0, loadContext);
selected.load(inspectorProps.document, loadContext);
await pending[2](loadContext);
assert.equal(selected.selected, 0, "Refresh keeps a subsequent user selection rather than forcing the initial diagram again");
selected.dismiss();
assert.equal(closed.at(-1), "selected-inspector");

const directory = await mkdtemp(join(tmpdir(), "aqua-controls-check-"));
try {
  const graph = 'flowchart TB\n A[Start] --> B[Left]\n A --> C[Right]\n B --> D[Done]\n C --> D';
  const markdown = '```mermaid\n' + graph + '\n```';
  const paths = new Set(), files = new Set();
  for (const edges of EDGES) {
    const result = await renderDocument({ markdown, theme, edges }, directory);
    const diagram = result.diagrams[0];
    assert.ok(!('error' in diagram), `${edges}: ${JSON.stringify(diagram)}`);
    const svg = await readFile(join(directory, diagram.file), 'utf8');
    if (edges !== 'Document') paths.add([...svg.matchAll(/<path\b[^>]*\bd="([^"]*)"/g)].map(match => match[1]).join('|'));
    files.add(diagram.file);
  }
  assert.equal(paths.size, 3, 'Straight, curved and stepped paths differ');
  assert.equal(files.size, 4, 'Routing is included in cache identity');
  for (const colours of COLOURS) {
    const result = await renderDocument({ markdown, theme, colours }, directory);
    const diagram = result.diagrams[0];
    assert.ok(!('error' in diagram), colours);
    const svg = await readFile(join(directory, diagram.file), 'utf8');
    const style = diagramStyle(colours, theme);
    assert.ok(svg.includes(style.theme.background));
    for (const colour of style.nodeColours.slice(0, 4)) assert.ok(svg.includes(colour.fill) && svg.includes(colour.stroke));
    assert.doesNotMatch(svg, /<script|<foreignObject|\shref=|\son\w+=|="[^"]*var\(/i);
    const cached = await renderDocument({ markdown, theme, colours }, directory);
    assert.equal(cached.diagrams[0].cached, true);
  }
  const explicit = await renderDocument({ markdown: '```mermaid\n' + graph + '\nstyle A fill:#123456,stroke:#abcdef\n```', theme, colours: 'Colourful' }, directory);
  const svg = await readFile(join(directory, explicit.diagrams[0].file), 'utf8');
  assert.ok(svg.includes('#123456') && svg.includes('#abcdef'), 'Explicit source colours are preserved');
  const configured = await renderDocument({ markdown: '```mermaid\n---\nconfig:\n  flowchart:\n    curve: linear\n---\n' + graph + '\n```', theme, edges: 'Curved' }, directory);
  const configuredSvg = await readFile(join(directory, configured.diagrams[0].file), 'utf8');
  assert.match(configuredSvg, /d="[^"]*C/, 'An explicit viewer routing choice overrides document defaults without rewriting source');
  for (const colours of ['Light', 'Dark', 'Colourful']) {
    const result = await renderDocument({ markdown: await readFile(new URL('../mods/aqua-markdown/example.md', import.meta.url), 'utf8'), theme, colours }, directory);
    assert.ok(result.diagrams.every(diagram => !('error' in diagram)), `${colours}: every supported family renders`);
  }
  await assert.rejects(renderDocument({ markdown, theme, colours: 'unknown' }, directory), /colour preset/);
  await assert.rejects(renderDocument({ markdown, theme, edges: 'unknown' }, directory), /edge preset/);
  const rejected = spawnSync(process.env.AQUA_PYTHON ?? 'python3', [new URL('../mods/aqua-markdown/bake_svg.py', import.meta.url).pathname], {
    input: JSON.stringify({ svg: '<svg xmlns="http://www.w3.org/2000/svg"/>', width: 10, height: 10, theme, nodeColours: [{ fill: 'url(https://example.invalid)', stroke: '#123456' }] }), encoding: 'utf8',
  });
  assert.equal(rejected.status, 1, 'Colour palettes cannot introduce SVG resource URLs');
} finally { await rm(directory, { recursive: true, force: true }); }
console.log('PASS: pan arrows/drag/wheel/cancel/centre, anchored bounded zoom, saved style controls, all colour presets, distinct flowchart routing, cache identity/reuse, source styles, and safe SVG');
