import assert from 'node:assert/strict';
import { readFile, writeFile, mkdtemp, mkdir, access, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { runInNewContext } from 'node:vm';
import { fileURLToPath } from 'node:url';
import { prepareMarkdown, splitDocument, referenceDefinitions, buildDocument } from '../mods/aqua-markdown/document.mjs';
import { linkTarget } from '../mods/aqua-markdown/links.js';

const theme = { background: '#17171b', foreground: '#eeedf2', muted: '#aaa6b5', surface: '#24242b', raised: '#302b40', border: '#68636f', accent: '#c4b5fd' };
const fenced = '```mermaid\nflowchart LR\n A-->B\n```';
const mixed = '# Before\r\n\r\n' + fenced.replaceAll('\n', '\r\n') + '\r\n\r\n## After\r\n\r\nText stays after the picture.';
const split = splitDocument(mixed);
assert.deepEqual(split.map(section => section.kind), ['markdown', 'diagram', 'markdown']);
assert.match(split[0].markdown, /# Before/);
assert.match(split[2].markdown, /## After/);
assert.equal(split[2].line, 7);
assert.deepEqual(splitDocument('```mermaid\n```\nAfter').map(section => section.kind), ['diagram', 'markdown']);
assert.deepEqual(splitDocument('~~~~mermaid\nflowchart LR\n A-->B\n~~~\n~~~~\nAfter').map(section => section.kind), ['diagram', 'markdown']);
assert.deepEqual(splitDocument('````text\n```mermaid\nnot a diagram\n```\n````').map(section => section.kind), ['markdown']);
assert.deepEqual(splitDocument('# Before\n```mermaid\nunfinished').map(section => section.kind), ['markdown', 'diagram']);
const metadata = '---\nartifact: synthetic\nstatus: draft\n---\n# Title\n' + fenced;
assert.equal(prepareMarkdown(metadata).split('\n').length, metadata.split('\n').length);
assert.doesNotMatch(prepareMarkdown(metadata), /artifact:|status:/);
assert.equal(prepareMarkdown('---\nunclosed'), '---\nunclosed');
assert.equal(prepareMarkdown('\uFEFF# Title\r\nText'), '# Title\nText');
assert.equal(splitDocument(metadata).find(section => section.kind === 'markdown').line, 1);
const references = '# Start\n\n[Across][shared]\n\n' + fenced + '\n\n[shared]: https://example.invalid\n  "Shared title"\n\n```text\n[fake]: javascript:bad\n```';
const definitions = referenceDefinitions(splitDocument(references));
assert.match(definitions, /\[shared\]: https:\/\/example.invalid\n  "Shared title"/);
assert.doesNotMatch(definitions, /fake|javascript/);
for (const [href, expected] of [
  ['../other%20doc.md#section', { kind: 'document', path: '/project/other doc.md' }],
  ['/docs/./guide.MD', { kind: 'document', path: '/docs/guide.MD' }],
  ['README.markdown', { kind: 'document', path: '/project/docs/README.markdown' }],
  ['https://example.invalid/docs', { kind: 'external', url: 'https://example.invalid/docs' }],
  ['#heading', { kind: 'anchor' }],
  ['javascript:alert(1)', { kind: 'unsupported' }],
  ['file:///etc/passwd', { kind: 'unsupported' }],
  ['//example.invalid/doc.md', { kind: 'unsupported' }],
  ['bad%xx.md', { kind: 'unsupported' }],
  ['image.png', { kind: 'unsupported' }],
]) assert.deepEqual(linkTarget(href, '/project/docs/start.md'), expected, href);

const directory = await mkdtemp(join(tmpdir(), 'aqua-markdown-check-'));
try {
  const example = await readFile(new URL('../mods/aqua-markdown/example.md', import.meta.url), 'utf8');
  const result = await buildDocument({ markdown: example, theme }, join(directory, 'cache'));
  assert.equal(result.diagrams.length, 3);
  assert.ok(result.diagrams.every(diagram => !diagram.error));
  assert.deepEqual(result.sections.filter(section => section.kind === 'diagram').map(section => section.diagram.type), ['flowchart', 'sequence', 'er']);
  for (const section of result.sections) {
    if (section.kind === 'markdown') assert.doesNotMatch(section.markdown, /^```mermaid/m);
    else await access(join(directory, 'cache', section.diagram.file));
  }
  const resolved = await buildDocument({ markdown: references, theme }, join(directory, 'cache'));
  assert.ok(resolved.sections.filter(section => section.kind === 'markdown').every(section => section.markdown.includes('[shared]: https://example.invalid')));
  const invalid = await buildDocument({ markdown: '# Before\n```mermaid\ninvalid diagram\n```\n# After', theme }, join(directory, 'cache'));
  assert.match(invalid.sections[1].diagram.error, /diagram/i);
  assert.match(invalid.sections[2].markdown, /# After/);
  const front = await buildDocument({ markdown: metadata, theme }, join(directory, 'cache'));
  assert.equal(front.diagrams[0].line, 6);
  assert.doesNotMatch(front.sections[0].markdown, /artifact:|status:/);
  const plain = await buildDocument({ markdown: '# Plain\n\nNo diagrams.', theme }, join(directory, 'cache'));
  assert.equal(plain.diagrams.length, 0);
  assert.equal(plain.sections.length, 1);
  await assert.rejects(buildDocument({ markdown: '---\n' + 'x'.repeat(1048576) + '\n---\n# Small visible body', theme }, join(directory, 'cache')), /1 MiB/);
  const data = join(directory, '.config/herdr-app/data');
  await mkdir(data, { recursive: true });
  const input = join(data, 'aqua-markdown-input-test.json');
  await writeFile(input, JSON.stringify({ markdown: mixed, theme, colours: 'Colourful', edges: 'Straight' }));
  const helper = fileURLToPath(new URL('../mods/aqua-markdown/document.mjs', import.meta.url));
  const generated = spawnSync(process.execPath, [helper, input], { env: { ...process.env, HOME: directory }, encoding: 'utf8' });
  assert.equal(generated.status, 0, generated.stderr);
  assert.equal(JSON.parse(generated.stdout).sections[1].diagram.type, 'flowchart');
  await assert.rejects(access(input), /ENOENT/);
  const untouched = join(directory, 'not-owned.json');
  await writeFile(untouched, 'synthetic input');
  const refused = spawnSync(process.execPath, [helper, untouched], { env: { ...process.env, HOME: directory }, encoding: 'utf8' });
  assert.equal(refused.status, 1);
  assert.equal(await readFile(untouched, 'utf8'), 'synthetic input');
} finally { await rm(directory, { recursive: true, force: true }); }

function element() {
  const node = { children: [], handlers: {} };
  const builder = new Proxy(node, { get(target, name) {
    if (name === '_node') return target;
    if (name === 'id') return id => { target.id = id; return builder; };
    if (name === 'child') return child => { target.children.push(child); return builder; };
    if (name === 'children') return children => { target.children.push(...children); return builder; };
    if (name === 'when') return (condition, callback) => { if (condition) callback(builder); return builder; };
    if (String(name).startsWith('on_')) return (...args) => { target.handlers[name] = args.at(-1); return builder; };
    return () => builder;
  } });
  return builder;
}
const tasks = [], reads = [], writes = [], overlays = [], sharedWrites = [], commands = [];
let payload, platform = 'linux', selected = { path: '/project/docs/start.md', on: 'remote' };
const storage = new Map();
const cx = { spawn: callback => tasks.push(callback), notify() {} };
const source = await readFile(new URL('../mods/aqua-markdown/reader.js', import.meta.url), 'utf8');
const Viewer = runInNewContext(source.replace(/^import .*;\n/gm, '').replace('export default class MarkdownReader', 'class MarkdownReader') + '\nMarkdownReader;' , {
  View: class {}, div: element, h_flex: element, v_flex: element, image: element,
  TextView: { markdown: (id, text) => { const item = element().id(id); item._node.markdown = text; return item; } },
  props: () => null, shared: () => selected, nextCommand: () => new Promise(() => {}), theme: () => theme, appHome: () => '/app', appWindow: () => ({ platform }), linkTarget,
  localStorage: { getItem: key => storage.get(key) ?? null, setItem: (key, value) => storage.set(key, value) },
  readTextFile: async (path, options) => { reads.push({ path, options }); return '# ' + path; },
  writeTextFile: async (path, text) => { writes.push(path); payload = JSON.parse(text); },
  exec: async (command, args) => {
    commands.push({ command, args });
    return { code: 0, stdout: JSON.stringify({ ok: true, diagrams: [], sections: [{ kind: 'markdown', markdown: payload.markdown, line: 1 }], background: theme.background, engine: 'Synthetic', elapsedMs: 1 }) };
  },
  setShared: (key, value) => sharedWrites.push({ key, value }), openOverlay: options => overlays.push(options), Date,
});
const viewer = new Viewer();
viewer.init({}, cx);
await tasks.shift()(cx);
void tasks.shift()(cx);
assert.equal(reads[0].options.on, 'remote');
assert.equal(commands[0].command, 'node', 'Resolve Node through PATH on every machine');
const root = viewer.render(cx);
const find = (item, id) => {
  if (!item || typeof item !== 'object') return null;
  const node = item._node;
  if (node.id === id) return node;
  for (const child of node.children) { const match = find(child, id); if (match) return match; }
  return null;
};
assert.ok(find(root, 'aqua-md-use'));
assert.ok(find(root, 'aqua-md-example'));
assert.ok(find(root, 'aqua-md-refresh'));
assert.ok(find(root, 'aqua-md-text-1-0').markdown.includes('/project/docs/start.md'));
assert.ok(writes.every(path => /^\/app\/data\/aqua-markdown-input-/.test(path)), 'Only viewer-owned temporary inputs are written');
viewer.follow('../next.md', cx);
await tasks.shift()(cx);
assert.equal(viewer.document.path, '/project/next.md');
assert.equal(viewer.document.on, 'remote');
assert.equal(viewer.history.length, 1);
viewer.back(cx);
await tasks.shift()(cx);
assert.equal(viewer.document.path, '/project/docs/start.md');
const page = viewer.page;
viewer.setStyle('Colourful', 'Curved', cx);
await tasks.shift()(cx);
assert.equal(viewer.page, page, 'A style change keeps the current document scroll identity');
assert.equal(payload.colours, 'Colourful');
assert.equal(payload.edges, 'Curved');
viewer.open({ path: '/project/older.md', on: null }, cx);
viewer.open({ path: '/project/newer.md', on: 'other' }, cx);
await tasks.shift()(cx);
await tasks.shift()(cx);
assert.ok(viewer.sections[0].markdown.includes('newer.md'), 'An older request cannot overwrite the selected document');
viewer.inspect(17);
assert.equal(sharedWrites.at(-1).key, 'aqua.svg.document');
assert.equal(sharedWrites.at(-1).value.on, 'other');
assert.equal(overlays.at(-1).mod, 'aqua-markdown');
assert.equal(overlays.at(-1).kind, 'dialog', 'Use native dialog Escape dismissal, not a persistent window');
assert.equal(overlays.at(-1).props.view, 'inspector');
assert.equal(overlays.at(-1).props.line, 17);
assert.equal(overlays.at(-1).props.document.on, 'other');
assert.equal(overlays.at(-1).props.colours, 'Colourful');
assert.equal(overlays.at(-1).props.edges, 'Curved');
const before = commands.length;
viewer.follow('javascript:bad', cx);
viewer.follow('#heading', cx);
assert.equal(commands.length, before);
assert.match(viewer.message, /Heading jumps/);
for (const [system, opener] of [['linux', 'xdg-open'], ['macos', 'open']]) {
  platform = system;
  viewer.follow('https://example.invalid/docs', cx);
  await tasks.shift()(cx);
  assert.equal(commands.at(-1).command, opener);
  assert.deepEqual(Array.from(commands.at(-1).args), ['https://example.invalid/docs']);
}
const routed = [], disposed = [];
let mode = null;
class ReaderMode {
  init() { routed.push('reader'); }
  render() { return 'reader'; }
  close() { disposed.push('reader'); }
}
class InspectorMode {
  init() { routed.push('inspector'); }
  render() { return 'inspector'; }
  close() { disposed.push('inspector'); }
}
const wrapperSource = await readFile(new URL('../mods/aqua-markdown/main.js', import.meta.url), 'utf8');
const Wrapper = runInNewContext(wrapperSource.replace(/^import .*;\n/gm, '').replace('export default class AquaMarkdown', 'class AquaMarkdown') + '\nAquaMarkdown;', {
  View: class {}, props: () => mode, MarkdownReader: ReaderMode, DiagramInspector: InspectorMode,
});
for (const view of [null, { view: 'inspector' }]) {
  mode = view;
  const wrapped = new Wrapper();
  wrapped.init({}, cx);
  assert.equal(wrapped.render(cx), view ? 'inspector' : 'reader');
  wrapped.close();
}
assert.deepEqual(routed, ['reader', 'inspector']);
assert.deepEqual(disposed, ['reader', 'inspector']);
await assert.rejects(access(new URL('../mods/aqua-svg/', import.meta.url)), /ENOENT/, 'The retired mod folder must not remain a runtime dependency');
console.log('PASS: Markdown/diagram order, fence/frontmatter/reference handling, local/remote navigation, read-only inputs, stale-load protection, style/selection handoff, Escape-dismissable inspector routing, mode cleanup, retired-mod removal, and helper cleanup');
