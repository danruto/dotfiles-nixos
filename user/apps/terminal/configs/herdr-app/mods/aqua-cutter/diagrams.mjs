import { readFile } from "node:fs/promises";
import { join } from "node:path";

process.env.AQUA_PYTHON ||= process.platform === "win32" ? "python" : "python3";
const { renderDocument } = await import("../aqua-markdown/render.mjs");

const input = process.argv[2];
const payload = JSON.parse(await readFile(input, "utf8"));
const home = process.env.HOME ?? process.env.USERPROFILE;
const output = join(home, ".config/herdr-app/data/aqua-svg");
const markdown = (payload.sources ?? []).map((source) => "```mermaid\n" + source + "\n```").join("\n\n");
try {
  const result = await renderDocument({ markdown, theme: payload.theme, colours: "App", edges: "Document" }, output);
  console.log(JSON.stringify({ ok: true, diagrams: result.diagrams }));
} catch (error) {
  console.log(JSON.stringify({ ok: false, error: String(error?.message ?? error) }));
  process.exitCode = 1;
}
