// Helpers are hc terminals another terminal started (subagents, review loops).
// herdr's layout doc has no place for them, so the sync shows a tab's live
// helpers in a Rex tab of their own beside it. Addresses are qualified
// (`orb/t7`) the way hc's terminal.list reports them.

// Live descendants of `roots`, oldest first, leaving out any terminal a tab
// already shows.
export function helpersOf(terminals, roots, shown) {
  const kids = new Map();
  for (const t of terminals) {
    if (t.state !== "live" || !t.parent || t.parent === t.address) continue;
    if (!kids.has(t.parent)) kids.set(t.parent, []);
    kids.get(t.parent).push(t);
  }
  const out = [];
  const seen = new Set(roots);
  const queue = [...roots];
  while (queue.length) {
    for (const k of kids.get(queue.shift()) ?? []) {
      if (seen.has(k.address)) continue;
      seen.add(k.address);
      queue.push(k.address);
      if (!shown.has(k.address)) out.push(k);
    }
  }
  return out.sort((a, b) => (a.created_ms ?? 0) - (b.created_ms ?? 0)).map((t) => t.address);
}

export const helperLabel = (tabLabel) => `↳ ${tabLabel}`.slice(0, 128);

// Side by side, in the tree form hc-rex-tree converts to a Rex layout.
export function helperTree(terms) {
  if (terms.length === 1) return { term: terms[0] };
  return { dir: "row", kids: terms.map((term) => ({ n: { term }, w: 1 })) };
}
