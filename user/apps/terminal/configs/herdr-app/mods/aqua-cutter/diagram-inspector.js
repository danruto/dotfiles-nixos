// The pan/zoom diagram inspector: a dialog over the diagrams it was handed ({title, source}),
// rendered through the same cache and shared Colour / Edges style as the page.

import { div, image } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme, nextCommand, props, closeOverlay } from "herdr";
import { DiagramCache, stylePrefs, cycleStyle } from "./render.js";
import { DiagramViewport } from "./viewport.js";
import { button } from "./ui.js";

export default class DiagramInspector {
  init(_props, cx) {
    const initial = props() ?? {};
    this.items = (Array.isArray(initial.diagrams) ? initial.diagrams : []).filter((item) => typeof item?.source === "string");
    this.selected = Math.max(0, Math.min(Number(initial.selected) || 0, this.items.length - 1));
    this.cache = new DiagramCache();
    this.view = new DiagramViewport();
    this.drag = null;
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "close") this.dismiss();
        if (command === "next") this.select(this.selected + 1, cx);
        if (command === "previous") this.select(this.selected - 1, cx);
      }
    });
  }

  select(index, cx) {
    if (index < 0 || index >= this.items.length) return;
    this.selected = index;
    this.drag = null;
    this.view.reset();
    cx.notify();
  }

  changeZoom(multiplier, cx, anchor) {
    this.view.changeZoom(multiplier, anchor);
    cx.notify();
  }

  pan(x, y, cx) {
    this.view.move(x, y);
    cx.notify();
  }

  dismiss() {
    const overlay = props()?.overlay;
    if (typeof overlay === "string") closeOverlay(overlay);
  }

  close() {}

  render(cx) {
    const t = theme(), style = stylePrefs();
    this.cache.ensure(this.items.map((item) => item.source), cx);
    const item = this.items[this.selected], rendered = item ? this.cache.get(item.source) : null;
    const ready = Boolean(rendered && !rendered.error && rendered.path);
    if (ready) this.view.content = { width: rendered.width, height: rendered.height };
    const scale = this.view.scale(), position = this.view.position();
    const status = !item ? "No diagram to inspect." : !rendered ? "Rendering diagram…" : rendered.error || "";
    return v_flex().size_full().min_h(0).min_w(0).bg(t.background).text_color(t.foreground).text_size(12)
      .child(h_flex().h(46).flex_none().px(14).gap(8).items_center().bg(t.chrome).border_b(1).border_color(t.border)
        .child(div().w(3).h(20).flex_none().rounded(2).bg(t.accent))
        .child(v_flex().flex_1().min_w(0)
          .child(div().truncate().text_size(13.5).font_semibold().child(item?.title ?? "Diagram"))
          .child(div().truncate().text_size(10).text_color(t.dim).child(`${this.items.length > 1 ? `${this.selected + 1} of ${this.items.length} · ` : ""}drag / scroll to pan · Ctrl/Cmd-scroll to zoom`)))
        .child(button(t, "aqua-svg-colours", `Colour: ${style.colours} ↻`, () => cycleStyle("colours")))
        .when(!ready || rendered.type === "flowchart", (el) => el.child(button(t, "aqua-svg-edges", `Edges: ${style.edges} ↻`, () => cycleStyle("edges"))))
        .child(button(t, "aqua-inspector-close", "Close × · Esc", () => this.dismiss())))
      .when(this.items.length > 1, (el) => el.child(h_flex().id("aqua-svg-blocks").flex_none().px(10).py(6).gap(4).flex_wrap().border_b(1).border_color(t.border)
        .children(this.items.map((entry, index) => button(t, `aqua-svg-block-${index}`, `${index + 1}. ${entry.title ?? "Diagram"}${entry.line ? ` · line ${entry.line}` : ""}`,
          (cx) => this.select(index, cx), { pressed: index === this.selected })))))
      .when(ready, (el) => el.child(h_flex().h(40).flex_none().px(10).gap(4).items_center().border_b(1).border_color(t.border)
        .child(button(t, "aqua-svg-fit", "Fit", (cx) => { this.view.reset(); cx.notify(); }, { pressed: this.view.fit }))
        .child(button(t, "aqua-svg-one", "1:1", (cx) => { this.view.reset(false); cx.notify(); }))
        .child(button(t, "aqua-svg-minus", "−", (cx) => this.changeZoom(1 / 1.25, cx)))
        .child(button(t, "aqua-svg-plus", "+", (cx) => this.changeZoom(1.25, cx)))
        .child(div().w(44).text_size(10).text_color(t.dim).child(`${Math.round(scale * 100)}%`))
        .child(div().text_size(10).text_color(t.dim).child("Pan"))
        .child(button(t, "aqua-svg-left", "←", (cx) => this.pan(-60, 0, cx)))
        .child(button(t, "aqua-svg-up", "↑", (cx) => this.pan(0, -60, cx)))
        .child(button(t, "aqua-svg-down", "↓", (cx) => this.pan(0, 60, cx)))
        .child(button(t, "aqua-svg-right", "→", (cx) => this.pan(60, 0, cx)))
        .child(button(t, "aqua-svg-centre", "Centre", (cx) => { this.view.centre(); cx.notify(); }))))
      .child(div().id("aqua-svg-viewport").flex_1().min_h(0).min_w(0).relative().overflow_hidden().bg(rendered?.background ?? t.background)
        .on_size_change((size, cx) => { if (size.width > 0 && size.height > 0 && (size.width !== this.view.size.width || size.height !== this.view.size.height)) { this.view.size = size; this.view.move(0, 0); cx.notify(); } })
        .when(ready, (el) => el.cursor_grab().when(Boolean(this.drag), (el) => el.cursor_grabbing())
          .on_mouse_down("left", (event, cx) => { this.drag = event.position; cx.stop_propagation(); cx.notify(); })
          .on_mouse_up("left", (_event, cx) => { this.drag = null; cx.notify(); })
          .on_hover((hovered, cx) => { if (!hovered && this.drag) { this.drag = null; cx.notify(); } })
          .on_mouse_move((event, cx) => { if (this.drag) { this.view.move(event.position.x - this.drag.x, event.position.y - this.drag.y); this.drag = event.position; cx.notify(); } })
          .on_scroll_wheel((event, cx) => {
            cx.stop_propagation();
            if (event.modifiers.control || event.modifiers.platform) this.changeZoom(Math.exp(-Math.max(-240, Math.min(240, event.delta.y)) * 0.005), cx, event.local_position);
            else this.pan(event.delta.x, event.delta.y, cx);
          })
          .child(image(rendered.path).absolute().left(position.x).top(position.y).w(rendered.width * scale).h(rendered.height * scale)))
        .when(!ready, (el) => el.child(div().size_full().p(18).flex().items_center().justify_center()
          .text_color(rendered?.error ? t.blocked : t.muted).child(status))));
  }
}
