// DataFlow: authored boundary crossings, ordered Untrusted, Token, PII, Internal (stable within a
// class): classification, bound C4 edge, the data, its named control and crossing note, and
// explicit inspection of that existing edge in a second dialog. Ported from lenses/data_flow.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { mono, button, tag, frame } from "./ui.js";
import { ALTITUDES, ancestry } from "./c4.js";

const NOTICE = "Authored data classifications and controls — not verified security enforcement";
const CONTROL = "Classification describes the data. A named control describes the boundary; neither proves enforcement.";
const CLASSES = { untrusted: ["Untrusted", "high"], token: ["Token", "info"], pii: ["PII", "warn"], internal: ["Internal", "neutral"] };
const ORDER = { untrusted: 0, token: 1, pii: 2, internal: 3 };

const plain = (text) => String(text ?? "").replace(/\r\n?/g, "\n");

function address(c4, crossing) {
  const level = (c4.levels ?? []).find((entry) => entry.id === crossing.level), edge = crossing.edge ?? {};
  const trail = ancestry(c4, crossing.level).map((entry) => `${entry.id}: ${entry.title ?? ""}`).join(" → ");
  return `${c4.id}: ${c4.title ?? ""} · ${ALTITUDES[level?.altitude] ?? crossing.level} · ${trail || crossing.level} · ${crossing.pane} · `
    + `Edge ${edge.from} → ${edge.to}, label ${JSON.stringify(edge.label ?? "")}, occurrence ${edge.occurrence ?? 0}`;
}

const crossings = (section) => (section.crossings ?? []).map((crossing, index) => ({ crossing, index }))
  .sort((left, right) => (ORDER[left.crossing.classification] ?? 4) - (ORDER[right.crossing.classification] ?? 4));

function row(ctx, t, section, c4, crossing, index, first, wide) {
  const [name, toneName] = CLASSES[crossing.classification] ?? [String(crossing.classification ?? "Unclassified"), "neutral"];
  const edge = crossing.edge ?? {};
  const levelFound = (c4?.levels ?? []).some((entry) => entry.id === crossing.level);
  const where = c4 ? address(c4, crossing) : "";
  const pair = (label, value, missing) => (wide ? h_flex().gap(12).items_start() : v_flex().gap(1)).w_full().min_w(0)
    .child(div().flex_none().when(wide, (el) => el.w(100)).text_size(11.5).text_color(t.muted).child(label))
    .child(div().flex_1().min_w(0).overflow_hidden().text_size(11.5).text_color(missing ? t.dim : t.foreground).child(plain(value) || " "));
  const klass = v_flex().flex_none().min_w(0).gap(4).when(wide, (el) => el.w(112))
    .child(h_flex().child(tag(t, name, toneName)))
    .child(div().min_w(0).overflow_hidden().font_family(mono()).text_size(11).text_color(t.muted)
      .when(Boolean(where), (el) => el.tooltip(`${crossing.id ?? ""} · ${where}`))
      .child(`${edge.from ?? "?"} → ${edge.to ?? "?"}${edge.label ? ` · ${edge.label}` : ""}`));
  const detail = v_flex().flex_1().min_w(0).gap(4)
    .child(div().min_w(0).overflow_hidden().text_size(12.5).font_semibold().text_color(t.foreground).child(plain(crossing.data) || " "))
    .child(pair("Named control", crossing.control, false))
    .child(pair("Crossing note", crossing.note ?? "No crossing note supplied", crossing.note === undefined));
  const inspect = div().flex_none().when(Boolean(where), (el) => el.tooltip(`Inspect bound C4 edge: ${crossing.id ?? ""} · ${crossing.data ?? ""} · ${where}`))
    .child(button(t, `aqua-df-inspect-${index}`, "Inspect bound C4 edge",
      () => ctx.inspect(section.architecture, { architecture: section.architecture, level: crossing.level, pane: crossing.pane, target: { kind: "edge", edge } }),
      { disabled: !levelFound || !crossing.edge }));
  return (wide ? h_flex().gap(12).items_start() : v_flex().gap(8)).w_full().min_w(0).py(10).when(!first, (el) => el.border_t(1).border_color(t.border))
    .child(klass).child(detail).child(wide ? inspect : h_flex().child(inspect));
}

export default {
  render(ctx, t, section) {
    const wide = ctx.width >= 640, list = crossings(section);
    const c4 = (ctx.doc?.sections ?? []).find((entry) => entry.id === section.architecture && entry.type === "c4");
    const body = [list.length
      ? v_flex().w_full().min_w(0).children(list.map(({ crossing, index }, at) => row(ctx, t, section, c4, crossing, index, at === 0, wide)))
      : div().text_size(12).text_color(t.dim).child("No crossings supplied")];
    if (!c4) body.push(div().text_size(11).text_color(t.dim).child(`C4 section ${section.architecture ?? "?"} is not in this walkthrough`));
    return frame(t, {
      body,
      footer: [
        h_flex().gap(8).items_start().child(div().flex_none().text_color(t.muted).child("CONTROL")).child(div().flex_1().min_w(0).child(CONTROL)),
        div().child("PII: personally identifiable information"),
      ],
      notice: NOTICE,
    });
  },
};
