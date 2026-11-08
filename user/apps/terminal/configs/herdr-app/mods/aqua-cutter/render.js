// Renders Mermaid sources through the shared Pele engine (render.mjs), a batch per call, and
// keeps the results by source text. The engine's own SVG cache makes a repeated source cheap.
// The Colour / Edges style is shared, so the page, every dialog and the diagram inspector agree.

import { appHome, exec, theme, writeTextFile, shared, setShared } from "herdr";
import { COLOURS, EDGES } from "./styles.js";

const BATCH = 32;
const STYLE = "aqua-cutter.style";

export function stylePrefs() {
  const style = /** @type {{colours?: string, edges?: string} | null} */ (shared(STYLE)) ?? {};
  return { colours: COLOURS.includes(style.colours) ? style.colours : "App", edges: EDGES.includes(style.edges) ? style.edges : "Document" };
}

/** Sets Colour or Edges to one preset. */
export function setStyle(kind, value) {
  setShared(STYLE, { ...stylePrefs(), [kind]: value });
}

/** Moves Colour or Edges to its next preset. */
export function cycleStyle(kind) {
  const style = stylePrefs(), list = kind === "colours" ? COLOURS : EDGES;
  setShared(STYLE, { ...style, [kind]: list[(list.indexOf(style[kind]) + 1) % list.length] });
}

export class DiagramCache {
  constructor() {
    this.results = new Map();
    this.pending = new Set();
    this.key = "";
  }

  get(source) { return this.results.get(source); }

  ensure(sources, cx) {
    const style = stylePrefs(), key = JSON.stringify([theme(), style]);
    if (key !== this.key) { this.key = key; this.results.clear(); this.pending.clear(); }
    const missing = [...new Set(sources.filter((source) => source && !this.results.has(source) && !this.pending.has(source)))];
    for (let start = 0; start < missing.length; start += BATCH) this.batch(missing.slice(start, start + BATCH), style, cx);
  }

  batch(sources, style, cx) {
    const key = this.key;
    for (const source of sources) this.pending.add(source);
    const input = `${appHome()}/data/aqua-cutter-input-${Date.now()}-${Math.random().toString(36).slice(2)}.json`;
    cx.spawn(async (cx) => {
      let results;
      try {
        await writeTextFile(input, JSON.stringify({ sources, theme: theme(), ...style }), null);
        const result = await exec("node", [`${appHome()}/mods/aqua-cutter/diagrams.mjs`, input]);
        const data = JSON.parse(result.stdout || "{}");
        if (!data.ok) throw new Error(data.error || result.stderr || "Diagram renderer failed");
        results = sources.map((source, index) => ({ ...(data.diagrams?.[index] ?? { error: "Diagram output unavailable" }), source, background: data.background }));
      } catch (error) {
        results = sources.map((source) => ({ error: String(error?.message ?? error), source }));
      }
      // A style or theme change while this batch ran makes its results stale.
      if (key === this.key) results.forEach((result) => { this.results.set(result.source, result); this.pending.delete(result.source); });
      cx.notify();
    });
  }
}
