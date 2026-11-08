// Lifecycle: a state/read ledger with the consistency window, and the selected state's detail.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { mono, tag, eyebrow, frame, tabs, hue } from "./ui.js";

const DEFAULT_READ_LABEL = "A concurrent read right now returns";
const TIMINGS_NOTICE = "Illustrative timings — not observed runtime measurements";

function windowSummary(states) {
  const start = states.findIndex((state) => state.inWindow === true);
  if (start === -1) return "No consistency window declared";
  const closure = states.findIndex((state, index) => index > start && state.inWindow !== true);
  const last = states[(closure === -1 ? states.length : closure) - 1];
  return `Consistency window: ${states[start].label} through ${last.label}${closure === -1 ? "" : `; closes at ${states[closure].label}`}`;
}

const windowTag = (t, inWindow) => tag(t, inWindow === true ? "Inside consistency window" : "Outside consistency window", inWindow === true ? "warn" : "neutral");

export default {
  render(ctx, t, section) {
    const states = section.states ?? [];
    const index = Math.min(ctx.get("lc:state", 0), Math.max(0, states.length - 1)), selected = states[index];
    if (!selected) return frame(t, { body: [div().text_size(12).text_color(t.dim).child("No lifecycle states supplied")] });
    const readLabel = section.readLabel ?? DEFAULT_READ_LABEL;
    const hasWindow = states.some((state) => state.inWindow === true);
    const cell = (width, el) => (width ? el.w(width).flex_none() : el.flex_1().min_w(200)).px(8).py(7);
    const head = h_flex().flex_none().border_b(1).border_color(t.border).bg(t.chrome)
      .children([[130, "State"], [0, "What happened"], [0, "Read returns"], [190, "Window"]].map(([width, label]) => cell(width, div()).child(eyebrow(t, label))));
    const rows = states.map((state, row) => {
      const current = row === index;
      return h_flex().flex_none().items_start().border_b(1).border_color(t.border).when(current, (el) => el.bg(t.accent + "12"))
        .child(cell(130, v_flex()).border_l(3).border_color(current ? t.accent : t.surface)
          .child(div().text_size(12).font_semibold().text_color(t.foreground).child(state.label ?? ""))
          .when(state.t !== undefined, (el) => el.child(div().font_family(mono()).text_size(10.5).text_color(t.muted).child(String(state.t)))))
        .child(cell(0, div()).text_size(12).text_color(t.muted).child(state.happened ?? ""))
        .child(cell(0, div()).text_size(12).text_color(t.muted).child(state.readReturns ?? ""))
        .child(cell(190, h_flex()).child(windowTag(t, state.inWindow)));
    });
    const block = (label, text) => v_flex().flex_1().min_w(240).gap(4).child(eyebrow(t, label))
      .child(div().text_size(12.5).text_color(t.foreground).child(text ?? ""));
    const panels = [section.tasks && "Task scopes"].filter(Boolean);
    return frame(t, {
      tabs: states.length > 1
        ? tabs(t, "aqua-lc-states", states.map((state, row) => ({ label: `${state.label}${state.t !== undefined ? ` · ${state.t}` : ""}`, value: row })), index,
          (row, cx) => ctx.set("lc:state", row, cx))
        : null,
      caption: [div().max_w(Math.max(220, ctx.width / 2)).truncate().child(readLabel)],
      body: [
        div().flex_none().w_full().px(10).py(6).rounded(5).bg(t.background).border_l(3).border_color(hasWindow ? hue(t, "0A") : t.background)
          .font_family(mono()).text_size(11).text_color(t.muted).child(windowSummary(states)),
        div().id("aqua-lc-ledger").flex_none().w_full().rounded(6).border(1).border_color(t.border).overflow_x_scrollbar()
          .child(v_flex().w_full().min_w(760).child(head).children(rows)),
        v_flex().flex_none().gap(12).pt(4)
          .child(h_flex().gap(8).items_center().flex_wrap().child(windowTag(t, selected.inWindow))
            .child(div().font_family(mono()).text_size(10.5).text_color(t.muted).child(`State ${index + 1} / ${states.length}`)))
          .child(h_flex().gap(16).items_start().flex_wrap()
            .child(block(`Completed effect · ${selected.label}${selected.t !== undefined ? ` ${selected.t}` : ""}`, selected.happened))
            .child(block("Read returns", selected.readReturns))),
      ],
      footer: [div().child("Authored completed effects and read results — not live responses or execution results"),
        ...panels.map((panel) => div().child(`${panel} panel supplied · shown only in the browser renderer`))],
      notice: TIMINGS_NOTICE,
    });
  },
};
