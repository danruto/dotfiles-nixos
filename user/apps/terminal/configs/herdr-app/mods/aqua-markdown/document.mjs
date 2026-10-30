import { readFile, rm } from 'node:fs/promises';
import nodeProcess from 'node:process';
import { Buffer } from 'node:buffer';
import { dirname, join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { extractMermaids } from './markdown.mjs';
import { renderDocument } from './render.mjs';
import { diagramStyle } from './styles.js';

const runtime = /** @type {{argv: string[], env: Record<string, string>, exitCode: number}} */ (/** @type {unknown} */ (nodeProcess));

/** @typedef {{kind: 'markdown', markdown: string, line: number} | {kind: 'diagram', index: number}} Section */

/** @param {string} markdown */
export function prepareMarkdown(markdown) {
  const lines = markdown.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n').split('\n');
  if (lines[0] === '---') {
    const end = lines.findIndex((line, index) => index > 0 && /^(?:---|\.\.\.)\s*$/.test(line));
    if (end > 0) for (let index = 0; index <= end; index++) lines[index] = '';
  }
  return lines.join('\n');
}

/** @param {string} markdown */
export function splitDocument(markdown) {
  const content = prepareMarkdown(markdown), lines = content.split('\n');
  const diagrams = extractMermaids(content);
  /** @type {Section[]} */
  const sections = [];
  let cursor = 0;
  for (const [index, diagram] of diagrams.entries()) {
    const start = diagram.line - 1;
    const prose = lines.slice(cursor, start).join('\n');
    if (prose.trim()) sections.push({ kind: 'markdown', markdown: prose, line: cursor + 1 });
    const opening = /^ {0,3}(`{3,}|~{3,})/.exec(lines[start]);
    if (!opening) throw new Error('Diagram fence position is invalid');
    let end = start + 1;
    for (; end < lines.length; end++) {
      const closing = /^ {0,3}(`{3,}|~{3,})\s*$/.exec(lines[end]);
      if (closing && closing[1][0] === opening[1][0] && closing[1].length >= opening[1].length) { end++; break; }
    }
    sections.push({ kind: 'diagram', index });
    cursor = end;
  }
  const prose = lines.slice(cursor).join('\n');
  if (prose.trim()) sections.push({ kind: 'markdown', markdown: prose, line: cursor + 1 });
  return sections;
}

/** @param {Section[]} sections */
export function referenceDefinitions(sections) {
  const definitions = [];
  for (const section of sections) {
    if (section.kind !== 'markdown') continue;
    let fence = '';
    const lines = section.markdown.split('\n');
    for (let index = 0; index < lines.length; index++) {
      const line = lines[index];
      const marker = /^( {0,3})(`{3,}|~{3,})(.*)$/.exec(line);
      if (fence) {
        if (marker && marker[2][0] === fence[0] && marker[2].length >= fence.length && !marker[3].trim()) fence = '';
        continue;
      }
      if (marker && !(marker[2][0] === '`' && marker[3].includes('`'))) { fence = marker[2]; continue; }
      if (/^ {0,3}\[(?!\^)(?:\\.|[^\]\\])+\]:[ \t]*\S/.test(line)) {
        let definition = line;
        if (/^ {1,3}(?:"[^"]*"|'[^']*'|\([^)]*\))[ \t]*$/.test(lines[index + 1] ?? '')) definition += '\n' + lines[++index];
        definitions.push(definition);
      }
    }
  }
  return definitions.join('\n');
}

/** @param {Parameters<typeof renderDocument>[0]} payload @param {string} directory */
export async function buildDocument(payload, directory) {
  if (typeof payload.markdown !== 'string' || Buffer.byteLength(payload.markdown) > 1048576) throw new Error('Markdown document must be at most 1 MiB');
  const rendered = await renderDocument({ ...payload, markdown: prepareMarkdown(payload.markdown) }, directory);
  const sections = splitDocument(payload.markdown);
  const definitions = referenceDefinitions(sections);
  return { ...rendered, sections: sections.map(section => section.kind === 'markdown' ? { ...section, markdown: section.markdown + (definitions ? '\n\n' + definitions : '') } : { kind: 'diagram', diagram: rendered.diagrams[section.index] }), background: diagramStyle(payload.colours ?? 'App', payload.theme).theme.background };
}

if (runtime.argv[1] === fileURLToPath(import.meta.url)) {
  const input = runtime.argv[2];
  const data = join(runtime.env.HOME ?? '', '.config/herdr-app/data');
  const allowed = typeof input === 'string' && dirname(input) === data && /^aqua-markdown-input-[A-Za-z0-9-]+\.json$/.test(basename(input));
  try {
    if (!allowed) throw new Error('Expected a viewer-owned temporary input file');
    const payload = JSON.parse(await readFile(input, 'utf8'));
    console.log(JSON.stringify(await buildDocument(payload, join(data, 'aqua-svg'))));
  } catch (error) {
    console.log(JSON.stringify({ ok: false, error: error instanceof Error ? error.message : String(error) }));
    runtime.exitCode = 1;
  } finally { if (allowed) await rm(input, { force: true }); }
}
