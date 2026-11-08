// Telemetry: the authored operational change, then each signal grouped Metric → Span → Log field
// as its own frame: status, what it powers, dashboard and alert consequences, and the emitting
// C4 node, which "Inspect emitter" outlines in the bound C4 reader. Ported from lenses/telemetry.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { blend } from "./model.js";
import { mono, button, hue } from "./ui.js";
import { ALTITUDES, ancestry } from "./c4.js";

const NOTICE = "Authored signal definitions — no live measurements or telemetry collection";
const SIGNALS = [["metric", "Metric", "0E"], ["span", "Span", "0C"], ["log", "Log field", "09"]];
const STATUSES = { added: "Added", changed: "Changed", removed: "Removed" };

const plain = (text) => String(text ?? "").replace(/\r\n?/g, "\n");
const lab = (t, text) => div().flex_none().font_family(mono()).text_size(10).font_semibold().text_color(t.muted).child(String(text).toUpperCase());

function address(section, architecture, entry) {
  const level = (architecture?.levels ?? []).find((candidate) => candidate.id === entry.level);
  if (!architecture || !level) return `${section.architecture ?? "?"} · ${entry.level} · ${entry.pane} · Node ${entry.node} — not found in this walkthrough`;
  const chain = ancestry(architecture, level.id).map((ancestor) => `${ancestor.id}: ${ancestor.title ?? ""}`).join(" → ");
  return `${architecture.id}: ${architecture.title ?? ""} · ${ALTITUDES[level.altitude] ?? level.altitude} · ${chain} · ${entry.pane} · Node ${entry.node}`;
}

function status(t, value) {
  const colour = { added: t.done, removed: t.blocked, changed: hue(t, "0D") }[value] ?? t.muted;
  return div().flex_none().px(6).py(1).rounded(4).border(1).border_color(colour).text_size(10).font_medium().text_color(colour)
    .whitespace_nowrap().child(STATUSES[value] ?? String(value ?? "unknown"));
}

function signal(ctx, t, section, architecture, entry, index, label, slot, last) {
  const wide = ctx.width >= 700;
  const level = (architecture?.levels ?? []).find((candidate) => candidate.id === entry.level);
  const where = address(section, architecture, entry);
  const argument = (name, text, missing) => v_flex().flex_1().min_w(0).gap(3).child(lab(t, name))
    .child(div().w_full().min_w(0).text_size(13).text_color(text ? t.foreground : t.dim).child(plain(text ?? missing)));
  const bar = h_flex().flex_none().min_h(38).px(10).py(6).gap(8).items_center().border_b(1).border_color(t.border)
    .bg(blend(hue(t, slot), t.background, 0.12))
    .child(div().flex_none().text_size(12).font_bold().text_color(t.foreground).whitespace_nowrap().child(label))
    .child(div().flex_1().min_w(0).font_family(mono()).text_size(12).text_color(t.foreground).child(plain(entry.name)))
    .child(status(t, entry.status));
  const facts = `Entry ID: ${entry.id}${entry.signal === "metric" ? ` · Metric kind: ${entry.kind ?? "No metric kind supplied"}` : ""}`;
  return v_flex().flex_none().w_full().rounded(9).border(1).border_color(t.border).bg(t.surface).overflow_hidden()
    .child(bar)
    .child((wide ? h_flex().gap(16).items_start() : v_flex().gap(12)).flex_none().w_full().px(14).py(12)
      .child(argument("What it is used for", entry.powers, "No operational use supplied"))
      .child(argument("Dashboard and alert changes", entry.affects, "No dashboard or alert consequence supplied")))
    .child(v_flex().flex_none().px(14).py(8).gap(4).border_t(1).border_color(t.border).font_family(mono()).text_size(10).text_color(t.dim)
      .child(h_flex().w_full().gap(12).items_center().flex_wrap()
        .child(v_flex().flex_1().min_w(0).gap(2).child(div().child(facts)).child(div().min_w(0).child(`Emitter: ${where}`)))
        .child(button(t, `aqua-te-inspect-${index}`, "Inspect emitter", () => ctx.inspect(section.architecture,
          { architecture: section.architecture, level: entry.level, pane: entry.pane, target: { kind: "node", node: entry.node } }), { disabled: !level })))
      .when(last, (foot) => foot.child(div().child(NOTICE))));
}

export default {
  render(ctx, t, section) {
    const architecture = (ctx.doc?.sections ?? []).find((entry) => entry.id === section.architecture && entry.type === "c4");
    const entries = section.entries ?? [];
    const groups = SIGNALS.map(([kind, label, slot]) => ({ label, slot, entries: entries.filter((entry) => entry.signal === kind) }))
      .filter((group) => group.entries.length);
    const lastEntry = groups.at(-1)?.entries.at(-1);
    let index = 0;
    return v_flex().flex_none().w_full().min_w(0).gap(10)
      .child(div().w_full().min_w(0).text_size(13).text_color(t.muted)
        .child(h_flex().gap(6).items_start().flex_wrap().child(lab(t, "Operational change").pt(2))
          .child(div().flex_1().min_w(0).child(plain(section.operationalChange ?? "No operational change supplied")))))
      .when(!architecture, (el) => el.child(div().p(8).rounded(6).bg(t.raised).border_l(3).border_color(t.working).text_size(11).text_color(t.muted)
        .child(`Bound architecture ${section.architecture ?? "?"} is not a C4 section in this walkthrough; emitters cannot be inspected.`)))
      .children(groups.length ? groups.map((group) => v_flex().w_full().min_w(0).gap(10)
        .children(group.entries.map((entry) => signal(ctx, t, section, architecture, entry, index++, group.label, group.slot, entry === lastEntry))))
        : [div().text_size(12).text_color(t.dim).child("No signals supplied"), div().font_family(mono()).text_size(10).text_color(t.dim).child(NOTICE)]);
  },
};
