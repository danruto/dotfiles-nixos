// Corpus: one supplied case at a time, its exact input beside its expected output, and metadata.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { detectLanguage } from "./model.js";
import { mono, eyebrow, frame, tabs, codeBox } from "./ui.js";

const NOTICE = "Supplied case material — not captured, replayed or verified by this renderer";

const selectedOf = (ctx, section) => {
  const entries = section.entries ?? [], id = ctx.get("cp:case", section.initialCase);
  return entries.find((entry) => entry.id === id) ?? entries[0];
};

export default {
  editors(section) {
    return (section.entries ?? []).flatMap((entry) => ["input", "expected"].map((side) => {
      const lang = detectLanguage(entry[side]);
      return { key: `corpus:${entry.id}:${side}`, value: entry[side] ?? "", ...(lang ? { language: lang } : {}) };
    }));
  },

  render(ctx, t, section) {
    const entries = section.entries ?? [], selected = selectedOf(ctx, section);
    if (!selected) return frame(t, { body: [div().text_size(12).text_color(t.dim).child("No cases supplied")] });
    const index = entries.indexOf(selected), wide = ctx.width >= 760;
    const pane = (side, label) => v_flex().flex_1().min_w(0).gap(6)
      .child(div().flex_none().px(8).py(4).rounded(5).bg(t.chrome).child(eyebrow(t, label)))
      .when(selected[side] === "", (el) => el.child(div().text_size(11.5).text_color(t.muted).child(`Empty ${side} (0 UTF-8 bytes)`)))
      .child(codeBox(t, `aqua-cp-${side}-${index}`, ctx.editor(`corpus:${selected.id}:${side}`), selected[side]));
    const maps = selected.maps ?? [];
    const meta = [
      ["Supplied provenance", selected.provenance],
      ["Supplied dependency pin", selected.dependency],
      ["Declared normalization", selected.normalise],
      ["Cited scenarios", maps.length ? maps.join(" · ") : "No scenario references supplied"],
    ];
    return frame(t, {
      tabs: entries.length > 1
        ? tabs(t, "aqua-cp-cases", entries.map((entry, row) => ({ label: div().max_w(260).truncate().child(String(entry.id)), value: row })), index,
          (row, cx) => ctx.set("cp:case", entries[row].id, cx), { monospace: true })
        : null,
      caption: [div().max_w(Math.max(220, ctx.width / 2)).truncate().child(`Current case: ${selected.id} — ${selected.title ?? ""}`)],
      body: [
        (wide ? h_flex().items_start().gap(12) : v_flex().gap(12)).children([pane("input", "Input"), pane("expected", "Expected")]),
        v_flex().flex_none().gap(6).pt(4).border_t(1).border_color(t.border).children(meta.map(([label, value]) =>
          h_flex().flex_none().gap(12).items_start()
            .child(div().w(wide ? 190 : 140).flex_none().pt(1).font_family(mono()).text_size(10).text_color(t.dim).child(label.toUpperCase()))
            .child(div().flex_1().min_w(0).text_size(12).text_color(t.foreground).child(String(value ?? ""))))),
      ],
      footer: section.reachability ? [div().child("Test reachability panel supplied · shown only in the browser renderer")] : null,
      notice: NOTICE,
    });
  },
};
