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
