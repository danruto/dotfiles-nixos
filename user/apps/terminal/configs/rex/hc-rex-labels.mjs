// status.lua puts an agent-status glyph in front of a Rex tab's label. It's
// Rex-only decoration, so the herdr doc's tab names never carry it. Keep the
// list in step with herdr.glyphs in herdr.lua.
export const GLYPHS = ["🟡", "🔴", "🟢", "🔵"];

const glyphAt = (label) => GLYPHS.find((g) => label.startsWith(g + " ")) ?? null;

export function bareLabel(label) {
  const g = glyphAt(label ?? "");
  return g ? label.slice(g.length + 1) : label ?? "";
}

// A rename from herdr keeps whatever status the tab is showing.
export function withGlyphOf(current, label) {
  const g = glyphAt(current ?? "");
  return g ? `${g} ${label}` : label;
}
