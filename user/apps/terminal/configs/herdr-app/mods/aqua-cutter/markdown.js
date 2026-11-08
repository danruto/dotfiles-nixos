// Pure Markdown helpers shared by the page (native sections) and render.mjs (Mermaid blocks).
// No Herdr or Node imports, so both runtimes and the checks can load it.

export function extractMermaids(markdown) {
  const diagrams = [];
  let fence = null, heading = "Mermaid diagram";
  const lines = markdown.replace(/\r\n?/g, "\n").split("\n");
  const finish = closed => {
    if (fence.mermaid) {
      diagrams.push({ title: fence.heading, line: fence.line, source: fence.lines.join("\n"), closed });
      if (diagrams.length > 32) throw new Error("This viewer supports at most 32 Mermaid blocks per document");
    }
    fence = null;
  };
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (fence) {
      const closing = /^ {0,3}(`{3,}|~{3,})\s*$/.exec(line);
      if (closing && closing[1][0] === fence.char && closing[1].length >= fence.length) finish(true);
      else {
        let removed = 0;
        while (removed < fence.indent && line[removed] === " ") removed++;
        fence.lines.push(line.slice(removed));
      }
      continue;
    }
    const opening = /^( {0,3})(`{3,}|~{3,})(.*)$/.exec(line);
    if (opening && !(opening[2][0] === "`" && opening[3].includes("`"))) {
      fence = { char: opening[2][0], length: opening[2].length, indent: opening[1].length, mermaid: /^mermaid(?:\s|$)/i.test(opening[3].trim()), heading, line: i + 1, lines: [] };
      continue;
    }
    const title = /^ {0,3}#{1,6}\s+(.+?)(?:\s+#+)?\s*$/.exec(line);
    if (title) heading = title[1];
  }
  if (fence) finish(false);
  return diagrams;
}

/** @typedef {{kind: 'markdown', markdown: string, line: number} | {kind: 'diagram', index: number} | {kind: 'code', info: string, code: string, line: number}} Section */

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
  return sections.flatMap(section => section.kind === 'markdown' ? splitFences(section.markdown, section.line) : [section]);
}

// Only fences at column 0 leave the prose: an indented one may belong to a list item.
/** @param {string} markdown @param {number} line @returns {Section[]} */
export function splitFences(markdown, line) {
  const lines = markdown.split('\n');
  /** @type {Section[]} */
  const sections = [];
  let cursor = 0;
  for (let index = 0; index < lines.length; index++) {
    const opening = /^(`{3,}|~{3,})(.*)$/.exec(lines[index]);
    if (!opening || (opening[1][0] === '`' && opening[2].includes('`'))) continue;
    let end = index + 1;
    for (; end < lines.length; end++) {
      const closing = /^ {0,3}(`{3,}|~{3,})\s*$/.exec(lines[end]);
      if (closing && closing[1][0] === opening[1][0] && closing[1].length >= opening[1].length) break;
    }
    const prose = lines.slice(cursor, index).join('\n');
    if (prose.trim()) sections.push({ kind: 'markdown', markdown: prose, line: line + cursor });
    sections.push({ kind: 'code', info: opening[2].trim().split(/\s+/)[0] ?? '', code: lines.slice(index + 1, end).join('\n'), line: line + index });
    cursor = end + 1;
    index = end;
  }
  const prose = lines.slice(cursor).join('\n');
  if (prose.trim()) sections.push({ kind: 'markdown', markdown: prose, line: line + cursor });
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

// Groups splitDocument's sections for the page: the first H1 before any H2 becomes the title,
// what precedes the first H2 the lead, and each H2 a chapter of its own blocks. Headings inside
// fences that stay in the prose (indented ones) are left alone.
/** @param {Section[]} sections */
export function chapters(sections) {
  let title = '';
  const lead = [], list = [];
  let target = lead;
  for (const section of sections) {
    if (section.kind !== 'markdown') { target.push(section); continue; }
    const lines = section.markdown.split('\n');
    let fence = '', start = 0;
    const flush = (end) => {
      const text = lines.slice(start, end).join('\n');
      if (text.trim()) target.push({ kind: 'markdown', markdown: text, line: section.line + start });
    };
    for (let index = 0; index < lines.length; index++) {
      const marker = /^\s*(`{3,}|~{3,})/.exec(lines[index]);
      if (marker) { if (!fence) fence = marker[1]; else if (marker[1][0] === fence[0] && marker[1].length >= fence.length) fence = ''; continue; }
      if (fence) continue;
      const h1 = /^ {0,3}#\s+(.+?)(?:\s+#+)?\s*$/.exec(lines[index]);
      if (h1 && !title && !list.length) {
        flush(index);
        title = h1[1];
        start = index + 1;
        continue;
      }
      const h2 = /^ {0,3}##\s+(.+?)(?:\s+#+)?\s*$/.exec(lines[index]);
      if (h2) {
        flush(index);
        list.push({ title: h2[1], line: section.line + index, blocks: [] });
        target = list.at(-1).blocks;
        start = index + 1;
      }
    }
    flush(lines.length);
  }
  return { title, lead, chapters: list };
}
