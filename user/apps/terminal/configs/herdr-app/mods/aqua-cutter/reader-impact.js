// Impact: an authored dependency altitude ledger. Hits regroup depth-first under their declared
// parents; each row names its C4 address and inspects it in the bound C4 reader, which outlines
// that exact node or edge occurrence. Ported from the renderer's lenses/impact.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { mono, frame, button } from "./ui.js";
import { ALTITUDES, targetLabel } from "./c4.js";

const NOTICE = "Authored impact dependencies — not discovered propagation or a risk score";

const plain = (text) => String(text ?? "").replace(/\r\n?/g, "\n");
const lab = (t, text) => div().flex_none().font_family(mono()).text_size(10).font_semibold().text_color(t.muted).child(String(text).toUpperCase());
const small = (t, text) => div().w_full().min_w(0).font_family(mono()).text_size(11).text_color(t.muted).child(plain(text));

// Depth-first from the roots in supplied order. Valid documents have no dangling parents; any
// hit the walk cannot reach is appended as a root rather than hidden.
function rows(hits) {
  const result = [], seen = new Set();
  const visit = (parent, parents) => {
    for (const hit of hits.filter((entry) => entry.parent === parent && !seen.has(entry))) {
      seen.add(hit);
      result.push({ hit, parents });
      visit(hit.id, [...parents, hit]);
    }
  };
  visit(undefined, []);
  for (const hit of hits) if (!seen.has(hit)) {
    seen.add(hit);
    result.push({ hit, parents: [], dangling: true });
    visit(hit.id, [hit]);
  }
  return result;
}

const relation = (t, ring) => div().flex_none().px(6).py(1).rounded(4).border(1).border_color(ring === "changed" ? t.done : t.muted)
  .text_size(10).font_medium().text_color(ring === "changed" ? t.done : t.muted).child(ring === "changed" ? "Directly changed" : "Downstream");

export default {
  render(ctx, t, section) {
    const architecture = (ctx.doc?.sections ?? []).find((entry) => entry.id === section.architecture && entry.type === "c4");
    const levels = architecture?.levels ?? [];
    const width = Math.max(320, ctx.width - 80), wide = width >= 640;
    const ledger = rows(section.hits ?? []);

    const cells = ledger.map(({ hit, parents, dangling }, index) => {
      const level = levels.find((entry) => entry.id === hit.level);
      const depth = Math.min(parents.length, 3);
      const address = `${architecture ? `${architecture.id}: ${architecture.title ?? ""}` : section.architecture} · ${level ? `${ALTITUDES[level.altitude] ?? level.altitude} · ${level.id}: ${level.title ?? ""}` : hit.level} · ${hit.pane} · ${targetLabel(hit.target)}`;
      const ancestry = dangling ? `Parent ${hit.parent} not found` : parents.length
        ? parents.map((parent) => `${parent.id}: ${parent.title ?? ""}`).join(" → ") : "Root (no parent)";
      const node = v_flex().id(`aqua-im-node-${index}`).min_w(0).gap(2).pl(depth * (wide ? 22 : 12)).tooltip(`Parent ancestry: ${ancestry}`)
        .child(div().w_full().min_w(0).text_size(12.5).font_semibold().text_color(t.foreground).child(plain(hit.title)))
        .child(small(t, `${parents.length ? `${"↳ ".repeat(depth)}depth ${parents.length} · ` : ""}${[...parents, hit].map((entry) => entry.id).join(" → ")}${dangling ? ` · parent ${hit.parent} not found` : ""}`));
      const altitude = v_flex().id(`aqua-im-address-${index}`).min_w(0).gap(2).tooltip(address)
        .child(div().text_size(12).text_color(t.foreground).child(level ? ALTITUDES[level.altitude] ?? String(level.altitude ?? "") : "Level not found"))
        .child(small(t, `${level?.title ?? hit.level} · ${hit.pane} · ${targetLabel(hit.target)}`));
      const why = div().w_full().min_w(0).text_size(12).text_color(hit.why ? t.foreground : t.dim).child(plain(hit.why ?? "No rationale supplied"));
      const inspect = button(t, `aqua-im-inspect-${index}`, "Inspect", () => ctx.inspect(section.architecture,
        { architecture: section.architecture, level: hit.level, pane: hit.pane, target: hit.target }), { disabled: !level });
      return { node, altitude, rel: h_flex().child(relation(t, hit.ring)), why, inspect };
    });

    const columns = [width * 0.26, width * 0.17, 140, null, 90];
    const row = (parts, head) => h_flex().w_full().min_w(0).gap(12).px(10).py(head ? 6 : 9).items_start()
      .when(!head, (el) => el.border_t(1).border_color(t.border))
      .children(parts.map((part, index) => (columns[index] === null ? div().flex_1() : div().w(Math.round(columns[index])).flex_none()).min_w(0).child(part)));
    const table = wide
      ? v_flex().w_full().min_w(0)
        .child(row([lab(t, "Node"), lab(t, "Altitude"), lab(t, "Relation"), lab(t, "Why"), div()], true))
        .children(cells.map((cell) => row([cell.node, cell.altitude, cell.rel, cell.why, cell.inspect], false)))
      : v_flex().w_full().min_w(0).children(cells.map((cell, index) => v_flex().w_full().min_w(0).gap(5).py(9)
        .when(index > 0, (el) => el.border_t(1).border_color(t.border))
        .child(h_flex().w_full().gap(10).items_start().child(div().flex_1().min_w(0).child(cell.node)).child(cell.rel))
        .child(cell.altitude).child(cell.why).child(h_flex().child(cell.inspect))));

    return frame(t, {
      body: [ledger.length ? table : div().text_size(12).text_color(t.dim).child("No impact hits supplied")],
      footer: [div().child(architecture ? `bound to ${architecture.id}: ${plain(architecture.title)}`
        : `bound to ${section.architecture ?? "?"} — that C4 section is not in this walkthrough; inspection is unavailable`)],
      notice: NOTICE,
    });
  },
};
