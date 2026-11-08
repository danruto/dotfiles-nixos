import { readFile, rm } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";

process.env.AQUA_PYTHON ||= process.platform === "win32" ? "python" : "python3";
const { renderDocument } = await import("./render.mjs");
const { parse } = await import("./vendor/pele.mjs");
const { diagramStyle } = await import("./styles.js");

// `%% aqua-edge {from,to,label,occurrence,style}` becomes `linkStyle <index>`, where the index
// counts edges in the parser's order and occurrence counts earlier edges with the same ends and label.
function resolveEdges(source) {
  const marks = [];
  const kept = source.split("\n").filter((line) => {
    const match = /^%% aqua-edge (\{.*\})$/.exec(line);
    if (match) marks.push(JSON.parse(match[1]));
    return !match;
  }).join("\n");
  if (!marks.length) return source;
  let edges = [];
  try { edges = parse(kept).edges ?? []; } catch { return kept; }
  const seen = new Map();
  const keyed = edges.map((edge, index) => {
    const base = JSON.stringify([edge.start, edge.end, edge.text ?? ""]);
    const occurrence = seen.get(base) ?? 0;
    seen.set(base, occurrence + 1);
    return { key: JSON.stringify([edge.start, edge.end, edge.text ?? "", occurrence]), index };
  });
  const lines = marks.flatMap((mark) => {
    const found = keyed.find((edge) => edge.key === JSON.stringify([mark.from, mark.to, mark.label ?? "", mark.occurrence ?? 0]));
    return found && /^[\w:#.,\s-]+$/.test(mark.style) ? [`linkStyle ${found.index} ${mark.style}`] : [];
  });
  return lines.length ? `${kept}\n${lines.join("\n")}` : kept;
}

const input = process.argv[2];
const home = process.env.HOME ?? process.env.USERPROFILE ?? "";
const data = join(home, ".config/herdr-app/data");
const owned = typeof input === "string" && resolve(dirname(input)) === resolve(data) && /^aqua-cutter-input-[A-Za-z0-9-]+\.json$/.test(basename(input));
try {
  if (!owned) throw new Error("Expected a viewer-owned temporary input file");
  const payload = JSON.parse(await readFile(input, "utf8"));
  const markdown = (payload.sources ?? []).map((source) => "```mermaid\n" + resolveEdges(String(source)) + "\n```").join("\n\n");
  const colours = payload.colours ?? "App", edges = payload.edges ?? "Document";
  const result = await renderDocument({ markdown, theme: payload.theme, colours, edges }, join(data, "aqua-svg"));
  console.log(JSON.stringify({ ok: true, diagrams: result.diagrams, background: diagramStyle(colours, payload.theme).theme.background }));
} catch (error) {
  console.log(JSON.stringify({ ok: false, error: String(error?.message ?? error) }));
  process.exitCode = 1;
} finally {
  if (owned) await rm(input, { force: true });
}
