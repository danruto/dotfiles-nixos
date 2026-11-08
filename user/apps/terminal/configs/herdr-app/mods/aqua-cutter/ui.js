// Shared native pieces of the Aqua Cutter look: tones, tags, frames, rich text, diagrams, diffs.

import { div, image } from "gpui-kit";
import { h_flex, v_flex, TextView, Editor } from "gpui-base";
import { settings, openOverlay } from "herdr";
import { richMarkdown, splitLead } from "./model.js";

export const CODE_FONT = 12;
// GPUI's line height is the font size times phi, rounded.
export const LINE_HEIGHT = Math.round(CODE_FONT * 1.618034);

export const mono = () => String(settings()?.font ?? "JetBrains Mono");

export function tone(t, name) {
  return { add: t.done, added: t.done, high: t.blocked, removed: t.blocked, warn: t.working, moved: t.working, info: t.accent }[name] ?? t.dim;
}

// The renderer's Base16 accent slots, on the Herdr theme's ANSI colours.
export function hue(t, slot) {
  return { "08": t.ansi1, "09": t.ansi9 ?? t.working, "0A": t.ansi3, "0B": t.ansi2, "0C": t.ansi6, "0D": t.ansi4, "0E": t.ansi5 }[slot] ?? t.accent;
}

export const syntax = (t) => ({ keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 });

export function button(t, id, label, action, { pressed = false, ghost = false, disabled = false } = {}) {
  return h_flex().id(id).h(26).px(9).flex_none().items_center().justify_center().rounded(6).text_size(11)
    .border(1).border_color(pressed ? t.accent : ghost ? t.background : t.border)
    .bg(pressed ? t.raised : t.background).text_color(pressed ? t.foreground : disabled ? t.dim : t.muted)
    .when(!disabled, (el) => el.cursor_pointer().hover((h) => h.bg(t.hover).text_color(t.foreground))
      .on_click((_event, cx) => action(cx)))
    .child(label);
}

export function tag(t, label, name) {
  const colour = tone(t, name);
  return div().flex_none().px(6).py(1).rounded(4).border(1).border_color(colour).text_size(10)
    .font_medium().text_color(colour).whitespace_nowrap().child(label);
}

export const eyebrow = (t, text) => div().flex_none().text_size(10).font_semibold().text_color(t.dim).child(String(text).toUpperCase());

export function rich(id, text, size = 12.5) {
  return TextView.markdown(id, richMarkdown(text)).w_full().text_size(size).scrollable(false).selectable(true);
}

// Numbered "Lead — detail" items: a quiet number, a bold lead and the detail after it.
export function stepList(t, id, items) {
  return v_flex().flex_none().gap(8).children((items ?? []).map((item, index) => {
    const { lead, detail } = splitLead(item);
    const markdown = detail === undefined ? richMarkdown(lead) : `**${richMarkdown(lead)}** — ${richMarkdown(detail)}`;
    return h_flex().flex_none().gap(10).items_start()
      .child(div().w(18).flex_none().pt(2).font_family(mono()).text_size(10).text_color(t.dim).child(String(index + 1).padStart(2, "0")))
      .child(div().flex_1().min_w(0).child(TextView.markdown(`${id}-${index}`, markdown).w_full().text_size(12).scrollable(false).selectable(true)));
  }));
}

// The renderer's ReaderFrame: a bar (tabs left, caption right), the body, and a quiet footer.
export function frame(t, { tabs = null, caption = null, body = [], footer = null, notice = "" } = {}) {
  return v_flex().flex_none().w_full().rounded(9).border(1).border_color(t.border).bg(t.surface).overflow_hidden()
    .when(Boolean(tabs || caption), (el) => el.child(h_flex().flex_none().min_h(38).px(10).py(6).gap(8).items_center().flex_wrap()
      .border_b(1).border_color(t.border).bg(t.chrome)
      .child(h_flex().flex_1().min_w(0).gap(5).items_center().flex_wrap().when(Boolean(tabs), (bar) => bar.child(tabs)))
      .when(Boolean(caption), (bar) => bar.child(h_flex().flex_none().gap(6).items_center().text_size(10).text_color(t.dim).children([caption].flat())))))
    .child(v_flex().flex_none().w_full().p(14).gap(12).children(body))
    .when(Boolean(footer || notice), (el) => el.child(v_flex().flex_none().px(14).py(8).gap(4).border_t(1).border_color(t.border)
      .font_family(mono()).text_size(10).text_color(t.dim)
      .when(Boolean(footer), (foot) => foot.children(footer))
      .when(Boolean(notice), (foot) => foot.child(div().text_color(t.dim).child(notice)))));
}

export function tabs(t, id, choices, selected, choose, { monospace = false } = {}) {
  return h_flex().gap(4).items_center().flex_wrap().children(choices.map((choice, index) =>
    button(t, `${id}-${index}`, monospace ? div().font_family(mono()).child(choice.label) : choice.label,
      (cx) => choose(choice.value, cx), { pressed: choice.value === selected })));
}

export const sourceBox = (t, text) => v_flex().flex_none().w_full().p(8).rounded(6).bg(t.background).gap(1)
  .children(String(text ?? "").split("\n").map((line) => div().font_family(mono()).text_size(10.5).text_color(t.muted).child(line || " ")));

const hash = (text) => { let h = 0; for (let i = 0; i < text.length; i++) h = (h * 31 + text.charCodeAt(i)) | 0; return (h >>> 0).toString(36); };

/** Opens the pan/zoom diagram inspector on `diagrams` ({title, source}[]), starting at `selected`. */
export function inspectDiagrams(diagrams, selected = 0) {
  openOverlay({ mod: "aqua-cutter", kind: "dialog", width: 0.86, height: 0.88, props: { view: "diagram", diagrams, selected } });
}

/** A rendered diagram scaled to `width`, or its state while it renders or after it failed.
 *  `inspect` replaces the default Inspect action (the pan/zoom inspector on this diagram alone). */
export function diagram(t, rendered, width, { height = 0, title = "Diagram", inspect = null } = {}) {
  if (!rendered) return div().flex_none().h(height ?? 120).w_full().flex().items_center().justify_center().rounded(7).bg(t.background)
    .text_size(10.5).text_color(t.dim).child("Rendering diagram…");
  if (rendered.error || !rendered.path) return div().flex_none().w_full().p(10).rounded(7).bg(t.background)
    .text_size(10.5).text_color(t.blocked).child(rendered.error || "Diagram output unavailable");
  const raw = rendered.width || 720, scale = Math.min(1, Math.max(120, width) / raw, height ? height / (rendered.height || 400) : 1);
  const open = inspect ?? (rendered.source ? () => inspectDiagrams([{ title, source: rendered.source }]) : null);
  return div().flex_none().w_full().relative().py(10).flex().justify_center().rounded(7).bg(rendered.background ?? t.background)
    .child(image(rendered.path).w(Math.round(raw * scale)).h(Math.round((rendered.height || 400) * scale)).flex_none())
    .when(Boolean(open), (el) => el.child(div().absolute().top(6).right(6)
      .child(button(t, `aqua-zoom-${hash(rendered.source ?? rendered.path)}`, "Inspect ↗", () => open()))));
}

// Exact text in a read-only Editor: up to `max` lines tall and clipped to its text, so short
// bodies never scroll themselves; longer ones scroll inside the box like the browser's pre.
export function codeBox(t, id, editor, text, max = 28) {
  if (!editor) return sourceBox(t, text);
  const lines = String(text ?? "").split(/\r\n|\r|\n/).length, height = Math.min(lines, max) * LINE_HEIGHT;
  const inner = lines > max ? height : height + Math.max(height, 3 * LINE_HEIGHT);
  return div().id(id).flex_none().w_full().px(8).py(6).rounded(7).bg(t.background).border(1).border_color(t.border)
    .child(div().w_full().h(height).relative().overflow_hidden().child(div().w_full().h(inner).child(Editor.new(editor).size_full())));
}

// A unified diff: old/new line numbers and marker in a gutter beside one read-only, highlighted
// Editor. The Editor is laid out taller than its text inside a box clipped to the text, so it
// never scrolls itself and the wheel reaches the dialog.
export function diff(t, id, rows, editor) {
  const text = rows.length * LINE_HEIGHT, slack = Math.max(text, 3 * LINE_HEIGHT);
  const tint = (row) => row.marker === "+" ? t.done + "24" : row.marker === "-" ? t.blocked + "24" : null;
  const gutter = v_flex().flex_none().font_family(mono()).text_size(10.5).text_color(t.dim).children(rows.map((row) =>
    h_flex().h(LINE_HEIGHT).flex_none().items_center().when(Boolean(tint(row)), (el) => el.bg(tint(row)))
      .child(div().w(38).pr(6).text_right().child(row.oldLine === null ? "" : String(row.oldLine)))
      .child(div().w(38).pr(6).text_right().child(row.newLine === null ? "" : String(row.newLine)))
      .child(div().w(16).text_color(row.marker === "+" ? t.done : row.marker === "-" ? t.blocked : t.dim)
        .child(row.marker === "+" ? "+" : row.marker === "-" ? "−" : ""))));
  const runs = rows.map((row, index) => ({ index, colour: tint(row) })).filter((run) => run.colour);
  return h_flex().id(id).flex_none().w_full().py(6).rounded(7).bg(t.background).border(1).border_color(t.border).overflow_hidden()
    .child(gutter)
    .child(div().flex_1().min_w(0).h(text).relative().overflow_hidden()
      .child(div().w_full().h(text + slack).child(Editor.new(editor).size_full()))
      .children(runs.map((run) => div().absolute().left(0).right(0).top(run.index * LINE_HEIGHT).h(LINE_HEIGHT).bg(run.colour))));
}
