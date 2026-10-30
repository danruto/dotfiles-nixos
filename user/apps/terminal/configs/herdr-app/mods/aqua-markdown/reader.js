import { div, image } from "gpui-kit";
import { h_flex, v_flex, TextView } from "gpui-base";
import { appHome, props, shared, setShared, theme, readTextFile, writeTextFile, exec, openOverlay, nextCommand, window as appWindow } from "herdr";
import { linkTarget } from "./links.js";

/** @typedef {import("gpui-kit").Context} Context */
/** @typedef {{path: string, on: string | null, revision?: number}} Document */
/** @typedef {import("./render.mjs").RenderedDiagram} Diagram */
/** @typedef {{kind: 'markdown', markdown: string, line: number} | {kind: 'diagram', diagram: Diagram}} Section */
const COLOURS = ["App", "Light", "Dark", "Colourful"];
const EDGES = ["Document", "Straight", "Curved", "Stepped"];
const DOCUMENT = "aqua.svg.document";
/** @param {Record<string, string>} t */
const palette = t => ({ background: t.background, foreground: t.foreground, muted: t.muted, surface: t.surface, raised: t.raised, border: t.border, accent: t.accent });

export default class MarkdownReader {
  /** @param {unknown} _props @param {import("gpui-kit").AsyncContext} cx */
  init(_props, cx) {
    /** @type {Section[]} */
    this.sections = [];
    /** @type {Document | null} */
    this.document = null;
    /** @type {Document[]} */
    this.history = [];
    this.generation = 0;
    this.page = 0;
    /** @type {number} */
    this.width = 800;
    this.message = "Select a Markdown file in Files and choose Read Markdown, or open Example.";
    const colours = localStorage.getItem("colours") ?? "App", edges = localStorage.getItem("edges") ?? "Document";
    this.colours = COLOURS.includes(colours) ? colours : "App";
    this.edges = EDGES.includes(edges) ? edges : "Document";
    this.background = theme().background;
    const initial = props() ?? {};
    if (typeof initial.file === "string") this.open({ path: initial.file, on: typeof initial.on === "string" ? initial.on : null }, cx, false);
    else this.useLast(cx);
    cx.spawn(async cx => {
      for (;;) {
        const command = await nextCommand();
        if (command === "inspect") this.inspect();
        if (command === "refresh" && this.document) this.open(this.document, cx, false);
      }
    });
  }

  /** @param {Context} cx */
  useLast(cx) {
    const selected = /** @type {Document | null} */ (shared(DOCUMENT));
    if (selected?.path) this.open(selected, cx);
  }

  /** @param {Document} document @param {Context} cx @param {boolean} [remember] */
  open(document, cx, remember = true) {
    if (!document.path.startsWith("/")) { this.message = "Use an absolute Markdown path."; cx.notify(); return; }
    const changed = this.document?.path !== document.path || this.document?.on !== document.on;
    if (changed) {
      if (remember && this.document) this.history.push(this.document);
      this.sections = [];
      this.page++;
    }
    this.document = { path: document.path, on: document.on ?? null };
    setShared(DOCUMENT, { ...this.document, revision: Date.now() });
    const source = this.document, request = ++this.generation, colours = palette(theme());
    const preferences = { colours: this.colours, edges: this.edges };
    this.paletteKey = JSON.stringify(colours);
    this.loading = true;
    this.message = "Reading Markdown and rendering diagrams…";
    cx.spawn(async cx => {
      let input = "", helperFinished = false;
      try {
        const markdown = await readTextFile(source.path, { on: source.on });
        if (request !== this.generation) return;
        if (markdown === null || markdown.includes("\0")) throw new Error("The Markdown file is missing, too large, or not text.");
        input = appHome() + `/data/aqua-markdown-input-${Date.now()}-${request}-${Math.random().toString(36).slice(2)}.json`;
        await writeTextFile(input, JSON.stringify({ markdown, theme: colours, ...preferences }), null);
        const response = await exec("node", [appHome() + "/mods/aqua-markdown/document.mjs", input]);
        helperFinished = true;
        if (request !== this.generation) return;
        const result = JSON.parse(response.stdout || "{}");
        if (response.code !== 0 || !result.ok) throw new Error(result.error || response.stderr || "Document rendering failed");
        this.sections = result.sections;
        this.background = result.background;
        const errors = result.diagrams.filter((/** @type {Diagram} */ diagram) => diagram.error).length;
        this.message = `${result.diagrams.length} diagram${result.diagrams.length === 1 ? "" : "s"}${errors ? ` · ${errors} diagram error${errors === 1 ? "" : "s"}` : ""} · ${result.engine} · ${result.elapsedMs} ms · read-only`; 
      } catch (error) { if (request === this.generation) this.message = error instanceof Error ? error.message : String(error); }
      finally {
        if (input && !helperFinished) await exec("rm", ["-f", input]).catch(() => false);
        if (request === this.generation) { this.loading = false; cx.notify(); }
      }
    });
    cx.notify();
  }

  /** @param {Context} cx */
  back(cx) {
    const previous = this.history.pop();
    if (previous) this.open(previous, cx, false);
  }

  /** @param {string} colours @param {string} edges @param {Context} cx */
  setStyle(colours, edges, cx) {
    this.colours = colours;
    this.edges = edges;
    localStorage.setItem("colours", colours);
    localStorage.setItem("edges", edges);
    if (this.document) this.open(this.document, cx, false);
    else cx.notify();
  }

  /** @param {number} [line] */
  inspect(line) {
    if (!this.document) return;
    openOverlay({ mod: "aqua-markdown", kind: "dialog", width: 1000, height: 780, props: { view: "inspector", document: { ...this.document, revision: Date.now() }, line, colours: this.colours, edges: this.edges } });
  }

  close() { this.generation++; }

  /** @param {string} href @param {Context} cx */
  follow(href, cx) {
    if (!this.document) return;
    const target = linkTarget(href, this.document.path);
    if (target.kind === "document" && target.path) this.open({ path: target.path, on: this.document.on }, cx);
    else if (target.kind === "external" && target.url) {
      cx.spawn(async cx => {
        try {
          const response = await exec(appWindow().platform === "macos" ? "open" : "xdg-open", [target.url]);
          if (response.code !== 0) throw new Error(response.stderr || "Could not open the link");
        } catch (error) { this.message = error instanceof Error ? error.message : String(error); cx.notify(); }
      });
    } else {
      this.message = target.kind === "anchor" ? "Heading jumps are not available in this prototype yet." : "This prototype opens Markdown files and HTTP(S) links only.";
      cx.notify();
    }
  }

  /** @param {Context} cx */
  render(cx) {
    const t = /** @type {Record<string, `#${string}`>} */ (theme());
    if (this.document && JSON.stringify(palette(t)) !== this.paletteKey) this.open(this.document, cx, false);
    /** @param {string} id @param {string} label @param {(cx: Context) => void} action */
    const button = (id, label, action) => div().id(id).h(28).px(9).flex_none().flex().items_center().rounded(5).text_size(11).text_color(t.muted).hover(el => el.bg(t.hover).text_color(t.foreground)).cursor_pointer().on_click((_event, cx) => action(cx)).child(label);
    return v_flex().size_full().min_h(0).min_w(0).bg(t.background).text_color(t.foreground)
      .child(div().h(36).flex_none().px(12).flex().items_center().bg(t.chrome).text_size(13).font_semibold().child("Markdown + Aqua"))
      .child(h_flex().h(34).flex_none().px(12).gap(5).items_center().bg(t.chrome).border_b(1).border_color(t.border)
        .when(this.history.length > 0, el => el.child(button("aqua-md-back", "← Back", cx => this.back(cx))))
        .child(button("aqua-md-use", "Last document", cx => this.useLast(cx)))
        .child(button("aqua-md-example", "Example", cx => this.open({ path: appHome() + "/mods/aqua-markdown/example.md", on: null }, cx)))
        .when(Boolean(this.document), el => el.child(button("aqua-md-refresh", this.loading ? "Loading…" : "Refresh", cx => this.open(this.document, cx, false)))))
      .child(h_flex().h(36).flex_none().px(12).gap(5).items_center().bg(t.chrome).border_b(1).border_color(t.border)
        .child(button("aqua-md-colour", `Colour: ${this.colours} ↻`, cx => this.setStyle(COLOURS[(COLOURS.indexOf(this.colours) + 1) % COLOURS.length], this.edges, cx)))
        .child(button("aqua-md-edges", `Flowchart edges: ${this.edges} ↻`, cx => this.setStyle(this.colours, EDGES[(EDGES.indexOf(this.edges) + 1) % EDGES.length], cx)))
        .child(div().flex_1())
        .when(Boolean(this.document), el => el.child(button("aqua-md-inspector", "Diagram inspector ↗", () => this.inspect()))))
      .when(Boolean(this.document), el => el.child(div().h(28).flex_none().px(20).flex().items_center().text_size(10).text_color(t.dim).truncate().child(`${this.document.on ? this.document.on + ": " : ""}${this.document.path}`)))
      .child(v_flex().id(`aqua-md-scroll-${this.page}`).flex_1().min_h(0).overflow_y_scrollbar().p(24).items_center()
        .child(v_flex().id("aqua-md-content").w_full().max_w(900).min_w(0).gap(16)
          .on_size_change((size, cx) => { if (size.width > 0 && size.width !== this.width) { this.width = size.width; cx.notify(); } })
          .when(this.sections.length === 0, el => el.child(div().py(20).text_size(14).text_color(t.muted).child(this.message)))
          .children(this.sections.map((section, index) => {
            if (section.kind === "markdown") return TextView.markdown(`aqua-md-text-${this.page}-${index}`, section.markdown).w_full().scrollable(false).selectable(true).on_link_click((href, cx) => this.follow(href, cx));
            const diagram = section.diagram;
            if (diagram.error || !diagram.path || !diagram.width || !diagram.height) return v_flex().w_full().p(14).gap(6).rounded(7).border_1().border_color(t.border).bg(t.surface)
              .child(div().text_size(12).font_semibold().child(`${diagram.title} · Mermaid at line ${diagram.line}`))
              .child(div().text_size(12).text_color(t.blocked).child(diagram.error || "Diagram output unavailable"));
            const scale = Math.min(1, Math.max(1, this.width - 24) / diagram.width);
            return v_flex().w_full().min_w(0).rounded(7).overflow_hidden().border_1().border_color(t.border)
              .child(h_flex().h(30).flex_none().px(10).items_center().bg(t.chrome)
                .child(div().flex_1().min_w(0).truncate().text_size(10).text_color(t.dim).child(`${diagram.title} · ${diagram.type} · line ${diagram.line}`))
                .child(button(`aqua-md-inspect-${index}`, "Inspect diagram ↗", () => this.inspect(diagram.line))))
              .child(div().w_full().py(12).flex().justify_center().bg(/** @type {`#${string}`} */ (this.background))
                .child(image(diagram.path).w(diagram.width * scale).h(diagram.height * scale).flex_none()));
          }))))
      .child(div().h(28).flex_none().px(12).flex().items_center().bg(t.chrome).border_t(1).border_color(t.border).text_size(10).text_color(t.dim).truncate().child(this.message));
  }
}
