import { createHash } from 'node:crypto';
import { readFile, writeFile, rename, mkdir, readdir, stat, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { dirname, join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse, render } from './vendor/pele.mjs';
import { extractMermaids } from './markdown.mjs';
import { diagramStyle, edgeCurve } from './styles.js';

const root = dirname(fileURLToPath(import.meta.url));
const SOURCE_BYTES = 8192;
const digest = value => createHash('sha256').update(value).digest('hex');
const provenance = JSON.parse(await readFile(join(root, 'vendor/provenance.json'), 'utf8'));
const adapter = digest(Buffer.concat([await readFile(fileURLToPath(import.meta.url)), await readFile(join(root, 'bake_svg.py')), await readFile(join(root, 'styles.js'))]));
if (digest(await readFile(join(root, 'vendor/pele.mjs'))) !== provenance.sha256) throw new Error('Pinned diagram engine integrity mismatch');

/** @typedef {{title: string, line: number, error?: string, cached?: boolean, file?: string, path?: string, type?: string, width?: number, height?: number}} RenderedDiagram */

/** @param {{markdown: string, theme: import('./styles.js').Palette, colours?: string, edges?: string}} payload @param {string} directory */
export async function renderDocument(payload, directory) {
  if (typeof payload.markdown !== 'string' || Buffer.byteLength(payload.markdown) > 1048576) throw new Error('Markdown document must be at most 1 MiB');
  const style = diagramStyle(payload.colours ?? 'App', payload.theme);
  const curve = edgeCurve(payload.edges ?? 'Document');
  await mkdir(directory, { recursive: true, mode: 0o700 });
  const started = performance.now();
  const diagrams = [];
  for (const block of extractMermaids(payload.markdown)) {
    /** @type {RenderedDiagram} */
    const item = { title: block.title, line: block.line };
    try {
      if (!block.closed) throw new Error('Unclosed Mermaid fence');
      if (!block.source.trim()) throw new Error('Empty Mermaid block');
      if (Buffer.byteLength(block.source) > SOURCE_BYTES || block.source.split('\n').length > 256) throw new Error('Diagram exceeds 8 KiB or 256 lines');
      const key = digest(JSON.stringify({ engine: provenance.sha256, adapter, source: block.source, style, curve }));
      const metadataPath = join(directory, key + '.json');
      let result;
      try {
        result = JSON.parse(await readFile(metadataPath, 'utf8'));
        const info = await stat(join(directory, key + '.svg'));
        if (!info.isFile() || info.size > 524288 || result.file !== key + '.svg' || ![result.width, result.height].every(value => Number.isFinite(value) && value > 0 && value <= 12000)) throw new Error('Invalid SVG cache entry');
        item.cached = true;
      } catch {
        const model = parse(block.source, { limit: SOURCE_BYTES, maxEdges: 512 });
        if (curve && model.type === 'flowchart') {
          model.defaultInterpolate = curve;
          for (const edge of model.edges) edge.interpolate = curve;
        }
        const output = render(model, { fontFamily: 'Arial', fontSize: 14, autoDirection: false, links: false, images: false, outputLimit: 524288, maxEdges: 512 });
        const converted = spawnSync(process.env.AQUA_PYTHON ?? 'python3', [join(root, 'bake_svg.py')], { input: JSON.stringify({ svg: output.svg, width: output.width, height: output.height, ...style }), encoding: 'utf8', timeout: 5000, maxBuffer: 2097152 });
        if (converted.status !== 0) throw new Error(converted.error?.message || converted.stderr?.trim() || 'Native SVG conversion failed');
        const { svg } = JSON.parse(converted.stdout);
        const file = join(directory, key + '.svg');
        const temporary = file + `.${process.pid}.tmp`;
        await writeFile(temporary, svg, { mode: 0o600 });
        await rename(temporary, file);
        result = { width: output.width, height: output.height, file: key + '.svg', type: output.type };
        await writeFile(metadataPath, JSON.stringify(result), { mode: 0o600 });
        item.cached = false;
      }
      Object.assign(item, result, { path: 'data/aqua-svg/' + key + '.svg' });
    } catch (error) { item.error = (error instanceof Error ? error.message : String(error)).slice(0, 400); }
    diagrams.push(item);
  }
  const keep = new Set(diagrams.filter(item => item.file).map(item => item.file));
  const files = await Promise.all((await readdir(directory)).filter(name => /^[a-f0-9]{64}\.svg$/.test(name)).map(async name => ({ name, time: (await stat(join(directory, name))).mtimeMs })));
  files.sort((a, b) => b.time - a.time);
  let excess = files.length - 64;
  for (const file of files.toReversed()) {
    if (excess <= 0) break;
    if (!keep.has(file.name)) {
      await rm(join(directory, file.name), { force: true });
      await rm(join(directory, file.name.replace('.svg', '.json')), { force: true });
      excess--;
    }
  }
  return { ok: true, engine: `Pele ${provenance.version}`, elapsedMs: Math.round(performance.now() - started), diagrams };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const input = process.argv[2];
  const data = join(process.env.HOME, '.config/herdr-app/data');
  const allowed = typeof input === 'string' && dirname(input) === data && /^aqua-svg-input-[A-Za-z0-9-]+\.json$/.test(basename(input));
  try {
    if (!allowed) throw new Error('Expected a viewer-owned temporary input file');
    const payload = JSON.parse(await readFile(input, 'utf8'));
    console.log(JSON.stringify(await renderDocument(payload, join(data, 'aqua-svg'))));
  } catch (error) {
    console.log(JSON.stringify({ ok: false, error: String(error.message ?? error) }));
    process.exitCode = 1;
  } finally { if (allowed) await rm(input, { force: true }); }
}
