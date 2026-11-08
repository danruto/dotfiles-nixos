// C4 addressing shared by the C4 reader and the lenses that inspect it.

export const ALTITUDES = { c1: "C1 · Context", c2: "C2 · Containers", c3: "C3 · Components" };

/** A level's chain of parents (by declared drills), root first; cycles stop. */
export function ancestry(c4, id) {
  const levels = new Map((c4.levels ?? []).map((level) => [level.id, level]));
  const parents = new Map((c4.levels ?? []).flatMap((level) => (level.drills ?? []).map((drill) => [drill.level, level.id])));
  const result = [], seen = new Set();
  for (let current = levels.get(id); current && !seen.has(current.id); current = levels.get(parents.get(current.id) ?? "")) {
    seen.add(current.id);
    result.unshift(current);
  }
  return result;
}

export function targetLabel(target) {
  if (target?.kind === "node") return `Node ${target.node}`;
  const edge = target?.edge ?? {};
  return `Edge ${edge.from} → ${edge.to}, label ${JSON.stringify(edge.label ?? "")}, occurrence ${edge.occurrence ?? 0}`;
}
