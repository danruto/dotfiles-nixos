import assert from 'node:assert/strict';
import { mkdtemp, rm, readFile, writeFile, readdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { extractMermaids } from './markdown.mjs';
import { renderDocument } from './render.mjs';

assert.equal(typeof globalThis.document, 'undefined');
const mixed = '# Example\r\n\r\n```mermaid\r\nflowchart LR\r\n A --> B\r\n```\r\n~~~~text\n```mermaid\nnot a diagram\n```\n~~~~\n## Second\n  ~~~mermaid\n  sequenceDiagram\n    A->>B: Hi\n  ~~~';
const blocks = extractMermaids(mixed);
assert.equal(blocks.length, 2);
assert.equal(blocks[0].line, 3);
assert.equal(blocks[0].title, 'Example');
assert.equal(blocks[1].title, 'Second');
assert.equal(blocks[1].source, 'sequenceDiagram\n  A->>B: Hi');
assert.equal(extractMermaids('```mermaid\nflowchart LR\n A-->B')[0].closed, false);
assert.equal(extractMermaids('    ```mermaid\n    A-->B\n    ```').length, 0);
assert.throws(() => extractMermaids(('```mermaid\nflowchart LR\n A-->B\n```\n').repeat(33)), /32/);
const theme = { background: '#17171b', foreground: '#eeedf2', muted: '#aaa6b5', surface: '#24242b', raised: '#302b40', border: '#68636f', accent: '#c4b5fd' };
const directory = await mkdtemp(join(tmpdir(), 'aqua-svg-check-'));
try {
  const markdown = await readFile(new URL('./example.md', import.meta.url), 'utf8');
  const result = await renderDocument({ markdown, theme }, directory);
  assert.equal(result.diagrams.length, 3);
  assert.deepEqual(result.diagrams.map(diagram => diagram.error), [undefined, undefined, undefined]);
  assert.deepEqual(result.diagrams.map(diagram => diagram.type), ['flowchart', 'sequence', 'er']);
  for (const diagram of result.diagrams) {
    const svg = await readFile(join(directory, diagram.file), 'utf8');
    assert.ok(svg.startsWith('<svg'));
    assert.ok(svg.includes(theme.background));
    assert.ok(diagram.width > 0 && diagram.height > 0);
    assert.doesNotMatch(svg, /<script|<foreignObject|<image|\shref=|\son\w+=|="[^"]*var\(/i);
  }
  const longBlocks = extractMermaids(markdown).map(block => block.source + '\n%% ' + 'padding '.repeat(40));
  const longer = await renderDocument({ markdown: longBlocks.map(source => '```mermaid\n' + source + '\n```').join('\n'), theme }, directory);
  assert.deepEqual(longer.diagrams.map(diagram => 'error' in diagram ? diagram.error : undefined), [undefined, undefined, undefined], 'Valid diagrams over 256 characters render across supported families');
  const prefix = 'flowchart LR\n A-->B\n%% ';
  const boundary = prefix + 'é'.repeat(Math.floor((8192 - Buffer.byteLength(prefix)) / 2)) + 'x'.repeat((8192 - Buffer.byteLength(prefix)) % 2);
  assert.equal(Buffer.byteLength(boundary), 8192);
  const limits = await renderDocument({ markdown: [boundary, boundary + 'x', 'flowchart LR\n A-->B' + '\n%%'.repeat(254), 'flowchart LR\n A-->B' + '\n%%'.repeat(255)].map(source => '```mermaid\n' + source + '\n```').join('\n'), theme }, directory);
  assert.ok(!('error' in limits.diagrams[0]), '8 KiB UTF-8 source is accepted');
  assert.ok('error' in limits.diagrams[1]);
  assert.match(String(limits.diagrams[1].error), /8 KiB/, 'The byte limit is still enforced');
  assert.ok(!('error' in limits.diagrams[2]), '256 source lines are accepted');
  assert.ok('error' in limits.diagrams[3]);
  assert.match(String(limits.diagrams[3].error), /256 lines/, 'The line limit is still enforced');
  const cached = await renderDocument({ markdown, theme }, directory);
  assert.ok(cached.diagrams.every(diagram => diagram.cached));
  const labelled = await renderDocument({ markdown: '```mermaid\nflowchart LR\n A["var(--literal) & text"] --> B["Done"]\n```', theme }, directory);
  const svg = await readFile(join(directory, labelled.diagrams[0].file), 'utf8');
  assert.ok(svg.includes('var(--literal)'));
  assert.ok(svg.includes('&amp;'));
  const errors = await renderDocument({ markdown: '```mermaid\ninvalid diagram\n```\n```mermaid\nflowchart LR\n A-->B\n```\n```mermaid\nflowchart LR\n A-->B', theme }, directory);
  assert.ok(errors.diagrams[0].error);
  assert.equal(errors.diagrams[1].error, undefined);
  assert.match(errors.diagrams[2].error, /Unclosed/);
  const malicious = await renderDocument({ markdown: '```mermaid\nflowchart LR\n A[Safe]-->B[End]\n click A "https://example.invalid"\n```', theme }, directory);
  if (!malicious.diagrams[0].error) assert.doesNotMatch(await readFile(join(directory, malicious.diagrams[0].file), 'utf8'), /href=|<a\s|<script/i);
  const python = process.env.AQUA_PYTHON;
  try {
    process.env.AQUA_PYTHON = '/nonexistent-aqua-python';
    const unavailable = await renderDocument({ markdown: '```mermaid\nflowchart LR\n A-->UniqueTarget\n```', theme }, directory);
    assert.match(unavailable.diagrams[0].error, /ENOENT/);
  } finally {
    if (python === undefined) delete process.env.AQUA_PYTHON;
    else process.env.AQUA_PYTHON = python;
  }
  for (const content of ['<script/>', '<rect fill="url(https://example.invalid/x)"/>', '<text onclick="run()">test</text>']) {
    const rejected = spawnSync(process.env.AQUA_PYTHON ?? 'python3', [new URL('./bake_svg.py', import.meta.url).pathname], { input: JSON.stringify({ svg: `<svg xmlns="http://www.w3.org/2000/svg">${content}</svg>`, width: 10, height: 10, theme }), encoding: 'utf8' });
    assert.equal(rejected.status, 1);
  }
  await writeFile(join(directory, result.diagrams[0].file.replace('.svg', '.json')), JSON.stringify({ width: -1, height: 10, file: result.diagrams[0].file }));
  const repaired = await renderDocument({ markdown, theme }, directory);
  assert.equal(repaired.diagrams[0].cached, false);
  await Promise.all(Array.from({ length: 66 }, (_, index) => writeFile(join(directory, index.toString(16).padStart(64, '0') + '.svg'), '<svg/>')));
  await renderDocument({ markdown, theme }, directory);
  assert.ok((await readdir(directory)).filter(file => file.endsWith('.svg')).length <= 64);
  for (const diagram of result.diagrams) await readFile(join(directory, diagram.file));
  console.log('PASS: Markdown fences, indentation/CRLF, literal labels, native-safe flow/sequence/ER SVG, sources over 256 characters, UTF-8 byte/line boundaries, cache reuse/repair/bounds, per-block errors, converter failure, and rejected active/external SVG; no browser globals');
} finally { await rm(directory, { recursive: true, force: true }); }
