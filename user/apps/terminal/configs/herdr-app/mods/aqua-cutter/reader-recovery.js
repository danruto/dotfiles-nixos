// Recovery: one tab per operation, its intent and pinned identity, then the ordered ledger of
// recovery points: the attempt and observation, known/unknown/retained evidence, retry budget,
// conditional alternatives and prohibited effects. Ported from the renderer's lenses/recovery.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { mono, tag, frame, tabs } from "./ui.js";

const NOTICE = "Authored recovery model — not live status or an execution result";
const OBSERVATION = { "confirmed-success": "added", "confirmed-failure": "removed", unknown: "warn", "not-attempted": "neutral" };
const OUTCOME = { continue: "info", complete: "added", refuse: "removed", skip: "neutral", park: "warn" };

const plain = (text) => String(text ?? "").replace(/\r\n?/g, "\n");
const para = (t, text, colour = t.foreground) => div().w_full().min_w(0).overflow_hidden().text_size(12).text_color(colour).child(plain(text) || " ");
const lab = (t, text) => div().flex_none().font_family(mono()).text_size(10).text_color(t.muted).child(String(text).toUpperCase());

function field(t, name, value, wide) {
  return (wide ? h_flex().gap(12).items_start() : v_flex().gap(2)).flex_none().w_full().min_w(0)
    .child(lab(t, name).when(wide, (el) => el.w(104).pt(2)))
    .child(div().flex_1().min_w(0).child(typeof value === "string" ? para(t, value) : value));
}

function bullets(t, entries) {
  if (!entries?.length) return para(t, "None supplied", t.dim);
  return v_flex().w_full().gap(3).children(entries.map((entry) => h_flex().w_full().gap(7).items_start()
    .child(div().flex_none().text_size(12).text_color(t.dim).child("•"))
    .child(div().flex_1().min_w(0).child(para(t, entry)))));
}

const group = (t, name, content) => v_flex().w_full().min_w(0).gap(4).child(lab(t, name)).child(content);

function alternative(t, entry, wide) {
  return v_flex().w_full().min_w(0).gap(4).p(9).rounded(6).bg(t.background)
    .child(div().text_size(12).font_semibold().text_color(t.foreground).child(`${entry.id} — ${plain(entry.action)}`))
    .child(field(t, "When", entry.when ?? "", wide))
    .child(field(t, "Owner", entry.owner ?? "", wide))
    .child(field(t, "Outcome", h_flex().child(tag(t, String(entry.outcome ?? "unknown"), OUTCOME[entry.outcome] ?? "neutral")), wide))
    .child(field(t, "Result", entry.result ?? "", wide));
}

function point(t, entry, index, wide) {
  const evidence = v_flex().gap(12)
    .child(group(t, "Known", bullets(t, entry.known)))
    .child(group(t, "Unknown", bullets(t, entry.unknown)))
    .child(group(t, "Retained", bullets(t, entry.retained)));
  const actions = v_flex().gap(12)
    .child(group(t, "Retry budget", para(t, entry.budget ?? "No retry budget supplied", entry.budget ? t.foreground : t.dim)))
    .child(group(t, "Alternatives", (entry.alternatives ?? []).length
      ? v_flex().gap(6).children(entry.alternatives.map((option) => alternative(t, option, wide)))
      : para(t, "None supplied", t.dim)))
    .child(group(t, "Prohibited effects", bullets(t, entry.prohibited)));
  return h_flex().w_full().min_w(0).gap(10).items_start().py(12).when(index > 0, (el) => el.border_t(1).border_color(t.border))
    .child(div().w(22).flex_none().pt(1).font_family(mono()).text_size(10.5).text_color(t.dim).child(String(index + 1).padStart(2, "0")))
    .child(v_flex().flex_1().min_w(0).gap(8)
      .child(div().text_size(13).font_semibold().text_color(t.foreground).child(`${entry.id} — ${plain(entry.title)}`))
      .child(field(t, "Attempt", entry.attempt ?? "", wide))
      .child(field(t, "Observation", h_flex().child(tag(t, String(entry.observation ?? "unknown"), OBSERVATION[entry.observation] ?? "neutral")), wide))
      .child(wide ? h_flex().w_full().gap(20).items_start().child(evidence.flex_1().min_w(0))
        .child(actions.flex_1().min_w(0).pl(16).border_l(1).border_color(t.border))
        : v_flex().gap(12).child(evidence).child(actions)));
}

export default {
  render(ctx, t, section) {
    const operations = section.operations ?? [], wide = ctx.width >= 760;
    const selected = operations.find((entry) => entry.id === ctx.get("rc-operation", section.initialOperation)) ?? operations[0];
    if (!selected) return frame(t, { body: [para(t, "No operations supplied", t.dim)], notice: NOTICE });
    return frame(t, {
      tabs: tabs(t, "aqua-rc-operations", operations.map((entry) => ({ label: `${entry.id} — ${entry.title ?? ""}`, value: entry.id })),
        selected.id, (id, cx) => ctx.set("rc-operation", id, cx), { monospace: true }),
      caption: [div().child(`Current operation: ${selected.id} — ${selected.title ?? ""}`)],
      body: [
        v_flex().w_full().gap(8).p(12).rounded(7).border(1).border_color(t.border).bg(t.raised)
          .child(field(t, "Intent", selected.intent ?? "", wide))
          .child(field(t, "Pinned identity", selected.identity ?? "", wide)),
        v_flex().w_full().min_w(0).children((selected.points ?? []).map((entry, index) => point(t, entry, index, wide))),
      ],
      notice: NOTICE,
    });
  },
};
