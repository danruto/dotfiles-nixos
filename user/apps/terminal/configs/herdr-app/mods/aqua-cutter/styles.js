/** @typedef {{background: string, foreground: string, muted: string, surface: string, raised: string, border: string, accent: string}} Palette */

export const COLOURS = ["App", "Light", "Dark", "Colourful"];
export const EDGES = ["Document", "Straight", "Curved", "Stepped"];

const light = { background: "#f8fafc", foreground: "#172033", muted: "#526078", surface: "#ffffff", raised: "#e8eef6", border: "#8899b0", accent: "#2563eb" };
const dark = { background: "#151b26", foreground: "#e8edf7", muted: "#a2b1c9", surface: "#222e42", raised: "#2d3b54", border: "#7185a5", accent: "#7eb6ff" };
const nodeColours = [
  { fill: "#dbeafe", stroke: "#2563eb" },
  { fill: "#ede9fe", stroke: "#7c3aed" },
  { fill: "#ccfbf1", stroke: "#0f766e" },
  { fill: "#fef3c7", stroke: "#b45309" },
  { fill: "#ffe4e6", stroke: "#be123c" },
  { fill: "#e0f2fe", stroke: "#0369a1" },
];

/** @param {string} preset @param {Palette} app */
export function diagramStyle(preset, app) {
  if (!COLOURS.includes(preset)) throw new Error("Unknown diagram colour preset");
  return { theme: preset === "App" ? app : preset === "Dark" ? dark : light, nodeColours: preset === "Colourful" ? nodeColours : [] };
}

/** @param {string} preset */
export function edgeCurve(preset) {
  if (!EDGES.includes(preset)) throw new Error("Unknown diagram edge preset");
  return preset === "Straight" ? "linear" : preset === "Curved" ? "rounded" : preset === "Stepped" ? "step" : null;
}
