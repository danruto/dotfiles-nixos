import assert from 'node:assert/strict';
import { readFile, writeFile, mkdtemp, mkdir, access, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { runInNewContext } from 'node:vm';
import { fileURLToPath } from 'node:url';
import { prepareMarkdown, splitDocument, referenceDefinitions, extractMermaids, chapters } from '../mods/aqua-cutter/markdown.js';
import { linkTarget } from '../mods/aqua-cutter/links.js';

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
assert.deepEqual(splitDocument('````text\n```mermaid\nnot a diagram\n```\n````').map(section => section.kind), ['code']);
const fences = splitDocument('# Code\n\n```js title\nconst x = 1;\n```\nAfter\n- item\n  ```py\n  x\n  ```');
assert.deepEqual(fences.map(section => section.kind), ['markdown', 'code', 'markdown']);
assert.deepEqual([fences[1].info, fences[1].code, fences[1].line, fences[2].line], ['js', 'const x = 1;', 3, 6]);
assert.match(fences[2].markdown, /```py/, 'Indented fences stay in list items');
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

const grouped = chapters(splitDocument('Intro before title\n# Title\nLead\n\n## One\nText\n' + fenced + '\n- item\n  ```md\n  ## not a heading\n  ```\n## Two ##\n# Late H1\n```js\nx\n```'));
assert.equal(grouped.title, 'Title');
assert.deepEqual(grouped.lead.map(block => block.kind), ['markdown', 'markdown']);
assert.deepEqual(grouped.chapters.map(chapter => chapter.title), ['One', 'Two'], 'Headings inside indented fences stay prose');
assert.deepEqual(grouped.chapters[0].blocks.map(block => block.kind), ['markdown', 'diagram', 'markdown']);
assert.deepEqual(grouped.chapters[1].blocks.map(block => block.kind), ['markdown', 'code'], 'A later H1 stays in its chapter');
assert.equal(grouped.chapters[0].line, 5);
assert.deepEqual(chapters(splitDocument('Just prose')), { title: '', lead: [{ kind: 'markdown', markdown: 'Just prose', line: 1 }], chapters: [] });

const directory = await mkdtemp(join(tmpdir(), 'aqua-markdown-check-'));
try {
  const example = await readFile(new URL('../mods/aqua-cutter/example.md', import.meta.url), 'utf8');
  const blocks = extractMermaids(prepareMarkdown(example));
  assert.equal(blocks.length, 3);
  assert.equal(splitDocument(example).filter(section => section.kind === 'diagram').length, 3, 'Every Mermaid block becomes a diagram section');
  assert.equal(extractMermaids(prepareMarkdown(metadata))[0].line, 6, 'Frontmatter keeps diagram line numbers');
  const data = join(directory, '.config/herdr-app/data');
  await mkdir(data, { recursive: true });
  const helper = fileURLToPath(new URL('../mods/aqua-cutter/diagrams.mjs', import.meta.url));
  const run = async (payload) => {
    const input = join(data, `aqua-cutter-input-${Math.random().toString(36).slice(2)}.json`);
    await writeFile(input, JSON.stringify(payload));
    const result = spawnSync(process.execPath, [helper, input], { env: { ...process.env, HOME: directory }, encoding: 'utf8' });
    await assert.rejects(access(input), /ENOENT/, 'The helper removes its own input');
    return result;
  };
  const sources = blocks.map(block => block.source);
  const generated = await run({ sources, theme, colours: 'Colourful', edges: 'Straight' });
  assert.equal(generated.status, 0, generated.stderr);
  const output = JSON.parse(generated.stdout);
  assert.deepEqual(output.diagrams.map(diagram => diagram.type), ['flowchart', 'sequence', 'er']);
  for (const diagram of output.diagrams) await access(join(data, 'aqua-svg', diagram.file));
  assert.equal(output.background, '#f8fafc', 'The chosen colour preset sets the diagram background');
  const app = JSON.parse((await run({ sources: sources.slice(0, 1), theme })).stdout);
  assert.equal(app.background, theme.background, 'No style means the App preset');
  assert.notEqual(app.diagrams[0].file, output.diagrams[0].file, 'Style is part of the cache identity');
  const invalid = JSON.parse((await run({ sources: ['invalid diagram'], theme })).stdout);
  assert.match(invalid.diagrams[0].error, /diagram/i);
  assert.equal((await run({ sources, theme, colours: 'unknown' })).status, 1, 'Unknown presets are refused');
  const untouched = join(directory, 'not-owned.json');
  await writeFile(untouched, 'synthetic input');
  const refused = spawnSync(process.execPath, [helper, untouched], { env: { ...process.env, HOME: directory }, encoding: 'utf8' });
  assert.equal(refused.status, 1);
  assert.equal(await readFile(untouched, 'utf8'), 'synthetic input');
} finally { await rm(directory, { recursive: true, force: true }); }

const routed = [], disposed = [];
let mode = null;
const modeClass = (name) => class { init() { routed.push(name); } render() { return name; } close() { disposed.push(name); } };
const wrapperSource = await readFile(new URL('../mods/aqua-cutter/main.js', import.meta.url), 'utf8');
const Wrapper = runInNewContext(wrapperSource.replace(/^import .*;\n/gm, '').replace('export default class AquaCutter', 'class AquaCutter') + '\nAquaCutter;', {
  View: class {}, props: () => mode, AquaCutterPage: modeClass('page'), AquaCutterInspector: modeClass('inspector'), DiagramInspector: modeClass('diagram'),
});
for (const view of [null, { view: 'inspector' }, { view: 'diagram' }, { view: 'unknown' }]) {
  mode = view;
  const wrapped = new Wrapper();
  wrapped.init({}, {});
  wrapped.render({});
  wrapped.close();
}
assert.deepEqual(routed, ['page', 'inspector', 'diagram', 'page']);
assert.deepEqual(disposed, routed);
await assert.rejects(access(new URL('../mods/aqua-markdown/', import.meta.url)), /ENOENT/, 'aqua-markdown is merged into aqua-cutter');
console.log('PASS: Markdown/diagram order, title/lead/H2 grouping, fence/frontmatter/reference handling, link targets, styled diagram helper with owned-input cleanup, view routing, and the merged mod');
