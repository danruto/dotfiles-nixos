// Converts between herdr-app's layout tree and Rex's, through one normal form:
//   leaf:      { term, pane?, block? }
//   container: { dir: "row" | "column", kids: [{ n, w }] }
// Containers always have two or more kids, none sharing their direction, and
// weights are relative. herdr nests n-ary rows/columns; Rex nests binary splits.

const DIRS = { horizontal: "row", vertical: "column" };

function container(dir, kids) {
  const flat = [];
  for (const k of kids) {
    if (k.n.dir === dir) {
      const sum = total(k.n.kids);
      for (const kk of k.n.kids) flat.push({ n: kk.n, w: (k.w * kk.w) / sum });
    } else {
      flat.push(k);
    }
  }
  if (flat.length === 1) return flat[0].n;
  return { dir, kids: flat };
}

function total(kids) {
  return kids.reduce((s, k) => s + k.w, 0) || 1;
}

export function fromHerdr(node) {
  if (node.type === "block") return { term: node.content?.terminal ?? null, pane: node.id };
  const kids = (node.children || []).map((c) => ({ n: fromHerdr(c), w: c.size?.weight ?? 1 }));
  if (kids.length === 0) return null;
  return container(node.type, kids);
}

// termOf(block_id) gives the hc terminal a Rex block shows, or null.
export function fromRex(layout, termOf) {
  if (!layout) return null;
  if (layout.block_id) return { term: termOf(layout.block_id), block: layout.block_id };
  const s = layout.split;
  const r = s.ratio ?? 0.5;
  return container(DIRS[s.direction], [
    { n: fromRex(s.before, termOf), w: r },
    { n: fromRex(s.after, termOf), w: 1 - r },
  ]);
}

// Shape and terminals, not sizes: dragging a divider isn't a structural change.
export function sig(n) {
  if (!n) return "";
  if (!n.dir) return n.term ?? "?";
  return `${n.dir}(${n.kids.map((k) => sig(k.n)).join(",")})`;
}

export function leaves(n, out = []) {
  if (!n) return out;
  if (!n.dir) out.push(n);
  else for (const k of n.kids) leaves(k.n, out);
  return out;
}

// blockFor(term) gives the Rex block spec for a terminal. Leaves come out in
// the order Rex reports block_ids: before sides ahead of after sides.
export function toRex(n, blockFor) {
  if (!n.dir) return { block: blockFor(n.term) };
  const [first, ...rest] = n.kids;
  const ratio = Math.min(0.95, Math.max(0.05, first.w / total(n.kids)));
  const after = rest.length === 1 ? rest[0].n : { dir: n.dir, kids: rest };
  return {
    split: {
      direction: n.dir === "row" ? "horizontal" : "vertical",
      ratio,
      before: toRex(first.n, blockFor),
      after: toRex(after, blockFor),
    },
  };
}

// paneFor(term) keeps a terminal's existing herdr pane id; newId(prefix)
// mints ids in herdr's format. herdr's tab root is always a row whose id is
// the tab's.
export function toHerdr(n, tabId, paneFor, newId) {
  const build = (node, weight) => {
    if (!node.dir) {
      return { type: "block", id: paneFor(node.term), content: { terminal: node.term }, size: { weight } };
    }
    const sum = total(node.kids);
    return {
      type: node.dir,
      id: newId("s"),
      children: node.kids.map((k) => build(k.n, k.w / sum)),
      size: { weight },
    };
  };
  const top = n.dir === "row" ? n.kids : [{ n, w: 1 }];
  const sum = total(top);
  return { type: "row", id: tabId, children: top.map((k) => build(k.n, k.w / sum)) };
}
