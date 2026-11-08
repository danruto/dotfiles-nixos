// Tradeoffs: a local decision rail; the chosen decision's supplied options (verdict, label, why),
// the accepted trade-off, its seam and cites, and explicit inspection of the affected C4 node or
// connection in a second dialog. Ported from the renderer's lenses/tradeoffs.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex, TextView } from "gpui-base";
import { blend, richMarkdown, splitLead } from "./model.js";
import { button, tag, eyebrow, rich, frame, tabs, hue } from "./ui.js";
import { ALTITUDES, ancestry, targetLabel } from "./c4.js";

const NOTICE = "Authored decision arguments — not independently verified alternatives or references";

function address(c4, decision) {
  const level = (c4.levels ?? []).find((entry) => entry.id === decision.level);
  const trail = ancestry(c4, decision.level).map((entry) => `${entry.id}: ${entry.title ?? ""}`).join(" → ");
  return `${c4.id}: ${c4.title ?? ""} · ${ALTITUDES[level?.altitude] ?? decision.level} · ${trail || decision.level} · ${decision.pane} · ${targetLabel(decision.target)}`;
}

function option(t, entry, index, wide) {
  const chosen = entry.verdict === "chosen";
  const { lead, detail } = splitLead(`${entry.label ?? ""} — ${entry.why ?? ""}`);
  const text = detail === undefined ? richMarkdown(lead) : `**${richMarkdown(lead)}** — ${richMarkdown(detail)}`;
  return (wide ? h_flex().gap(10).items_start() : v_flex().gap(4)).w_full().min_w(0).py(7).border_t(1).border_color(t.border)
    .child(div().flex_none().when(wide, (el) => el.w(80).pt(1)).child(h_flex().child(tag(t, chosen ? "Chosen" : "Rejected", chosen ? "added" : "neutral"))))
    .child(div().flex_1().min_w(0).child(TextView.markdown(`aqua-tr-option-${index}`, text).w_full().text_size(12.5).scrollable(false).selectable(true)));
}

function selected(ctx, section) {
  const decisions = section.decisions ?? [];
  const initial = Math.max(0, decisions.findIndex((entry) => entry.id === section.initialDecision));
  const index = Math.min(Math.max(0, Number(ctx.get("tr-decision", initial)) || 0), Math.max(0, decisions.length - 1));
  return { decisions, index, decision: decisions[index] };
}

export default {
  render(ctx, t, section) {
    const { decisions, index, decision } = selected(ctx, section), wide = ctx.width >= 640;
    if (!decision) return frame(t, { body: [div().text_size(12).text_color(t.dim).child("No decisions supplied")], notice: NOTICE });
    const c4 = (ctx.doc?.sections ?? []).find((entry) => entry.id === section.architecture && entry.type === "c4");
    const level = (c4?.levels ?? []).find((entry) => entry.id === decision.level);
    const where = c4 ? address(c4, decision) : "";
    const inspect = button(t, "aqua-tr-inspect", `Inspect on ${String(level?.altitude ?? "C4").toUpperCase()}`,
      () => ctx.inspect(section.architecture, { architecture: section.architecture, level: decision.level, pane: decision.pane, target: decision.target }),
      { disabled: !level });
    const head = h_flex().w_full().gap(12).items_center().flex_wrap()
      .child(div().flex_1().min_w(0).text_size(13).font_semibold().text_color(t.foreground).child(String(decision.question ?? decision.id ?? "")))
      .child(div().flex_none().when(Boolean(where), (el) => el.tooltip(`Inspect affected connection: ${decision.question ?? ""} · ${where}`)).child(inspect));
    const options = decision.options ?? [];
    const cost = v_flex().w_full().min_w(0).gap(3).px(10).py(8).rounded(6).bg(blend(hue(t, "09"), t.background, 0.1))
      .child(div().text_size(12).font_semibold().text_color(hue(t, "09")).child("What we give up with this choice."))
      .child(rich(`aqua-tr-cost-${index}`, decision.tradeoff ?? "", 12.5));
    const body = [head, eyebrow(t, "Options considered"),
      v_flex().w_full().min_w(0).children(options.map((entry, at) => option(t, entry, at, wide)))];
    if (options.length === 1) body.push(div().text_size(11.5).text_color(t.muted).child("No rejected alternatives supplied"));
    body.push(cost);
    if (!level) body.push(div().text_size(11).text_color(t.dim)
      .child(c4 ? `Level ${decision.level} is not in C4 section ${section.architecture}` : `C4 section ${section.architecture ?? "?"} is not in this walkthrough`));
    const cites = [decision.source, ...(decision.references ?? [])].filter(Boolean);
    return frame(t, {
      tabs: tabs(t, "aqua-tr-decisions", decisions.map((entry, at) => ({ label: div().max_w(320).truncate().child(String(entry.question ?? entry.id ?? "")), value: at })),
        index, (value, cx) => ctx.set("tr-decision", value, cx)),
      caption: decision.seam ? [div().max_w(260).truncate().child(String(decision.seam))] : null,
      body,
      footer: cites.length ? [TextView.markdown(`aqua-tr-cites-${index}`, `cites ${cites.map(richMarkdown).join(" · ")}`)
        .w_full().text_size(10).text_color(t.dim).scrollable(false).selectable(true)] : null,
      notice: NOTICE,
    });
  },
};
