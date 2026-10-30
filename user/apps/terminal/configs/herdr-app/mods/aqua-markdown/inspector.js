import { div, image } from "gpui-kit";
import { h_flex, v_flex, InputState, Input } from "gpui-base";
import { appHome, spaces, panes, focused, theme, shared, exec, readTextFile, writeTextFile, nextCommand, props, closeOverlay } from "herdr";
import { COLOURS, EDGES, diagramStyle } from "./styles.js";
import { DiagramViewport } from "./viewport.js";

/** @typedef {import("gpui-kit").Context} Context */
/** @typedef {import("gpui-kit").Point} Point */
/** @typedef {{path: string, on?: string | null, revision: number}} DocumentSelection */
/** @typedef {{title: string, line: number, path?: string, width?: number, height?: number, type?: string, error?: string}} Diagram */

const DOCUMENT = "aqua.svg.document";
/** @param {Record<string, string>} t */
const palette = t => ({ background: t.background, foreground: t.foreground, muted: t.muted, surface: t.surface, raised: t.raised, border: t.border, accent: t.accent });

export default class DiagramInspector {
  /** @param {unknown} _props @param {import("gpui-kit").AsyncContext} cx */
  init(_props, cx) {
    this.input = InputState.new({ placeholder: "docs/design.md or an absolute Markdown path" });
    this.input.on("submit", (_event, cx) => this.openInput(cx));
    /** @type {Diagram[]} */
    this.diagrams = [];
    /** @type {number} */
    this.selected = 0;
    this.view = new DiagramViewport();
    /** @type {Point | null} */
    this.drag = null;
    const initial = /** @type {{document?: DocumentSelection, line?: number, colours?: string, edges?: string}} */ (props() ?? {});
    this.source = initial.document ?? /** @type {DocumentSelection | null} */ (shared(DOCUMENT));
    this.initialLine = initial.line;
    const colours = initial.colours ?? localStorage.getItem("colours") ?? "App", edges = initial.edges ?? localStorage.getItem("edges") ?? "Document";
    this.colours = COLOURS.includes(colours) ? colours : "App";
    this.edges = EDGES.includes(edges) ? edges : "Document";
    this.message = "Choose a diagram, or enter a Markdown path above. Escape or Close dismisses this inspector.";
    cx.spawn(async cx => {
      for (;;) {
        const command = await nextCommand();
        if (command === "close") this.dismiss();
        if (command === "example") this.example(cx);
        if (command === "refresh") this.openInput(cx);
        if (command === "next") this.select(Math.min(this.selected + 1, this.diagrams.length - 1), cx);
        if (command === "previous") this.select(Math.max(0, this.selected - 1), cx);
      }
    });
  }

  /** @param {Context} cx */
  example(cx) {
    this.source = { path: appHome() + "/mods/aqua-markdown/example.md", on: null, revision: Date.now() };
    cx.notify();
  }

  /** @param {Context} cx */
  openInput(cx) {
    const value = this.input.value().trim();
    if (!value) { this.message = "Enter a Markdown file path."; cx.notify(); return; }
    const space = spaces().find(space => space.active), focus = focused();
    const pane = panes().find(pane => pane.pane === focus?.pane);
    const on = this.document ? this.document.on : space?.machine ?? null;
    const cwd = this.document?.path.slice(0, this.document.path.lastIndexOf("/")) || pane?.cwd || focus?.cwd || space?.folder;
    if (!value.startsWith("/") && !cwd) { this.message = "Use an absolute file path, or open a project first."; cx.notify(); return; }
    const path = value.startsWith("/") ? value : cwd.replace(/\/$/, "") + "/" + value;
    this.source = { path, on, revision: Date.now() };
    cx.notify();
  }

  /** @param {DocumentSelection} document @param {Context} cx */
  load(document, cx) {
    const request = this.generation = (this.generation ?? 0) + 1;
    const selected = this.document?.path === document.path && this.document?.on === document.on ? this.selected : 0;
    const initialLine = this.documentKey ? undefined : this.initialLine;
    const preserveView = this.documentKey === JSON.stringify(document);
    this.drag = null;
    this.document = document;
    this.documentKey = JSON.stringify(document);
    const colours = palette(theme());
    this.paletteKey = JSON.stringify(colours);
    const preferences = { colours: this.colours, edges: this.edges };
    this.styleKey = JSON.stringify(preferences);
    this.input.set_value(document.path);
    this.loading = true;
    this.diagrams = [];
    this.message = "Loading Markdown and generating SVGs…";
    cx.spawn(async cx => {
      try {
        const markdown = await readTextFile(document.path, { on: document.on });
        if (request !== this.generation) return;
        if (markdown === null) throw new Error("Markdown file could not be read (missing, non-text, or larger than 1 MiB).");
        const inputPath = appHome() + `/data/aqua-svg-input-${Date.now()}-${request}-${Math.random().toString(36).slice(2)}.json`;
        await writeTextFile(inputPath, JSON.stringify({ markdown, theme: colours, ...preferences }), null);
        const response = await exec("node", [appHome() + "/mods/aqua-markdown/render.mjs", inputPath]);
        if (request !== this.generation) return;
        const result = JSON.parse(response.stdout || "{}");
        if (response.code !== 0 || !result.ok) throw new Error(result.error || response.stderr || "SVG generation failed");
        this.diagrams = result.diagrams;
        const initial = typeof initialLine === "number" ? this.diagrams.findIndex(diagram => diagram.line === initialLine) : -1;
        this.selected = Math.max(0, Math.min(initial >= 0 ? initial : selected, this.diagrams.length - 1));
        if (!preserveView) this.view.reset();
        this.elapsedMs = result.elapsedMs;
        const rendered = this.diagrams.filter(diagram => !diagram.error).length;
        this.message = this.diagrams.length ? `${rendered}/${this.diagrams.length} diagrams · ${result.engine} · generated in ${result.elapsedMs} ms` : "No fenced Mermaid blocks found in this Markdown file.";
      } catch (error) { if (request === this.generation) this.message = error instanceof Error ? error.message : String(error); }
      finally { if (request === this.generation) { this.loading = false; cx.notify(); } }
    });
  }

  /** @param {number} index @param {Context} cx */
  select(index, cx) {
    if (index < 0 || index >= this.diagrams.length) return;
    this.selected = index;
    this.drag = null;
    this.view.reset();
    cx.notify();
  }

  /** @param {number} multiplier @param {Context} cx @param {Point} [anchor] */
  changeZoom(multiplier, cx, anchor) {
    const diagram = this.diagrams[this.selected];
    if (!diagram || diagram.error) return;
    this.view.changeZoom(multiplier, anchor);
    cx.notify();
  }

  /** @param {number} x @param {number} y @param {Context} cx */
  pan(x, y, cx) {
    this.view.move(x, y);
    cx.notify();
  }

  /** @param {string} colours @param {string} edges @param {Context} cx */
  setStyle(colours, edges, cx) {
    this.colours = colours;
    this.edges = edges;
    localStorage.setItem("colours", colours);
    localStorage.setItem("edges", edges);
    cx.notify();
  }

  dismiss() {
    const overlay = props()?.overlay;
    if (typeof overlay === "string") closeOverlay(overlay);
  }

  close() { this.input.release(); }

  /** @param {Context} cx */
  render(cx) {
    const t = /** @type {Record<string, `#${string}`>} */ (theme());
    const document = this.source;
    if (document && (JSON.stringify(document) !== this.documentKey || JSON.stringify(palette(t)) !== this.paletteKey || JSON.stringify({ colours: this.colours, edges: this.edges }) !== this.styleKey)) this.load(document, cx);
    const diagram = this.diagrams[this.selected];
    if (diagram && !diagram.error) this.view.content = { width: diagram.width, height: diagram.height };
    const scale = this.view.scale(), position = this.view.position();
    const canvas = /** @type {`#${string}`} */ (diagramStyle(this.colours, palette(t)).theme.background);
    /** @param {string} id @param {string} label @param {(cx: Context) => void} action @param {boolean} [active] */
    const button = (id, label, action, active = false) => div().id(id).h(28).px(8).flex_none().flex().items_center().justify_center().rounded(5).text_size(11).bg(active ? t.selected : t.chrome).text_color(active ? t.foreground : t.muted).hover(el => el.bg(t.hover).text_color(t.foreground)).cursor_pointer().on_click((_event, cx) => action(cx)).child(label);
    return v_flex().size_full().min_h(0).min_w(0).bg(t.background).text_color(t.foreground).text_size(12)
      .child(h_flex().h(38).flex_none().px(10).gap(7).items_center().bg(t.chrome).border_b(1).border_color(t.border)
        .child(div().flex_1().min_w(0).truncate().font_semibold().child("Diagram inspector"))
        .child(button("aqua-svg-example", "Example", cx => this.example(cx)))
        .child(button("aqua-svg-refresh", "Refresh", cx => this.openInput(cx)))
        .when(Boolean(props()?.overlay), el => el.child(button("aqua-inspector-close", "Close × · Esc", () => this.dismiss()))))
      .child(h_flex().h(45).flex_none().px(8).gap(6).items_center().border_b(1).border_color(t.border)
        .child(div().flex_1().min_w(0).h(30).px(7).flex().items_center().border_1().border_color(t.border).rounded(5).child(Input.new(this.input).h_full().text_size(11).text_color(t.foreground)))
        .child(button("aqua-svg-load", this.loading ? "Loading…" : "Load", cx => this.openInput(cx))))
      .child(h_flex().h(36).flex_none().px(8).gap(6).items_center().bg(t.chrome)
        .child(button("aqua-svg-colours", `Colour: ${this.colours} ↻`, cx => this.setStyle(COLOURS[(COLOURS.indexOf(this.colours) + 1) % COLOURS.length], this.edges, cx)))
        .when(!diagram || diagram.type === "flowchart", el => el.child(button("aqua-svg-edges", `Edges: ${this.edges} ↻`, cx => this.setStyle(this.colours, EDGES[(EDGES.indexOf(this.edges) + 1) % EDGES.length], cx))))
        .when(Boolean(diagram) && diagram.type !== "flowchart", el => el.child(div().text_size(10).text_color(t.dim).child("Edges: flowcharts only"))))
      .when(this.diagrams.length > 0, el => el.child(v_flex().id("aqua-svg-blocks").h(Math.min(130, this.diagrams.length * 30 + 8)).flex_none().p(4).overflow_y_scrollbar()
        .children(this.diagrams.map((item, index) => button(`aqua-svg-block-${index}`, `${index + 1}. ${item.title} · line ${item.line}${item.error ? " · error" : ""}`, cx => this.select(index, cx), index === this.selected).w_full().min_w(0).justify_start().truncate()))))
      .when(Boolean(diagram) && !diagram.error, el => el.child(h_flex().h(36).flex_none().px(8).gap(4).items_center().bg(t.chrome)
        .child(button("aqua-svg-fit", "Fit", cx => { this.view.reset(); cx.notify(); }, this.view.fit))
        .child(button("aqua-svg-one", "1:1", cx => { this.view.reset(false); cx.notify(); }))
        .child(button("aqua-svg-minus", "−", cx => this.changeZoom(1 / 1.25, cx)))
        .child(button("aqua-svg-plus", "+", cx => this.changeZoom(1.25, cx)))
        .child(div().text_size(10).text_color(t.dim).child(`${Math.round(scale * 100)}%`))))
      .when(Boolean(diagram) && !diagram.error, el => el.child(h_flex().h(36).flex_none().px(8).gap(4).items_center().bg(t.chrome)
        .child(div().text_size(10).text_color(t.dim).child("Pan"))
        .child(button("aqua-svg-left", "←", cx => this.pan(-60, 0, cx)))
        .child(button("aqua-svg-up", "↑", cx => this.pan(0, -60, cx)))
        .child(button("aqua-svg-down", "↓", cx => this.pan(0, 60, cx)))
        .child(button("aqua-svg-right", "→", cx => this.pan(60, 0, cx)))
        .child(button("aqua-svg-centre", "Centre", cx => { this.view.centre(); cx.notify(); }))))
      .child(div().id("aqua-svg-viewport").flex_1().min_h(0).min_w(0).relative().overflow_hidden().bg(canvas)
        .on_size_change((size, cx) => { if (size.width > 0 && size.height > 0 && (size.width !== this.view.size.width || size.height !== this.view.size.height)) { this.view.size = size; this.view.move(0, 0); cx.notify(); } })
        .when(Boolean(diagram) && !diagram.error, el => el.cursor_grab().when(Boolean(this.drag), el => el.cursor_grabbing())
          .on_mouse_down("left", (event, cx) => { this.drag = event.position; cx.stop_propagation(); cx.notify(); })
          .on_mouse_up("left", (_event, cx) => { this.drag = null; cx.notify(); })
          .on_hover((hovered, cx) => { if (!hovered && this.drag) { this.drag = null; cx.notify(); } })
          .on_mouse_move((event, cx) => { if (this.drag) { this.view.move(event.position.x - this.drag.x, event.position.y - this.drag.y); this.drag = event.position; cx.notify(); } })
          .on_scroll_wheel((event, cx) => {
            cx.stop_propagation();
            if (event.modifiers.control || event.modifiers.platform) this.changeZoom(Math.exp(-Math.max(-240, Math.min(240, event.delta.y)) * 0.005), cx, event.local_position);
            else this.pan(event.delta.x, event.delta.y, cx);
          })
          .child(image(diagram.path).absolute().left(position.x).top(position.y).w(diagram.width * scale).h(diagram.height * scale)))
        .when(!diagram || Boolean(diagram.error), el => el.child(v_flex().size_full().p(18).gap(12).items_center().justify_center().text_color(t.muted)
          .child(div().max_w(420).child(diagram?.error ?? this.message))
          .when(!this.document, el => el.child(button("aqua-svg-empty-example", "Show example", cx => this.example(cx)))))))
      .child(v_flex().h(44).flex_none().px(10).py(5).gap(3).bg(t.chrome).border_t(1).border_color(t.border)
        .child(div().truncate().text_size(10).text_color(t.muted).child(this.message))
        .child(div().text_size(9).text_color(t.dim).child(`${this.document?.on ? "File from " + this.document.on + " · " : ""}drag / scroll to pan · Ctrl/Cmd-scroll to zoom`)));
  }
}
