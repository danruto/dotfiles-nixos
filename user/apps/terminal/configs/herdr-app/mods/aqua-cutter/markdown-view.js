// A Markdown document in the Aqua page, laid out like a walkthrough: the H1 as the title, the
// text before the first H2 as the lead, and each H2 as a collapsible card. Code fences and
// Mermaid diagrams sit in reader frames; diagrams render through the shared diagram cache.

import { div } from "gpui-kit";
import { h_flex, v_flex, TextView, EditorState } from "gpui-base";
import { extractMermaids, prepareMarkdown, splitDocument, referenceDefinitions, chapters } from "./markdown.js";
import { DiagramCache, stylePrefs, setStyle } from "./render.js";
import { COLOURS, EDGES } from "./styles.js";
import { CODE_FONT, mono, syntax, hue, button, tag, eyebrow, frame, tabs, codeBox, diagram, inspectDiagrams } from "./ui.js";

const MAX_EDITORS = 200, CODE_LINES = 400;
const HUES = ["0D", "0B", "0E", "0A", "0C", "08"];
const LANGUAGES = {
  js: "js", javascript: "js", jsx: "js", ts: "js", tsx: "js", typescript: "js", mjs: "js", cjs: "js",
  sh: "bash", bash: "bash", shell: "bash", zsh: "bash", console: "bash", fish: "bash",
  py: "python", python: "python", c: "c", h: "c", go: "go", golang: "go",
  json: "json", jsonc: "json", json5: "json", yaml: "yaml", yml: "yaml", toml: "yaml", html: "html", css: "css",
};
const plain = (text) => text.replace(/[`*_]/g, "");
const plural = (count, noun) => `${count} ${noun}${count === 1 ? "" : "s"}`;

export const isMarkdown = (path) => /\.(?:md|markdown)$/i.test(path ?? "");

export class MarkdownView {
  constructor(text, t) {
    this.diagrams = extractMermaids(prepareMarkdown(text)).map((block) => ({
      title: block.title, line: block.line, source: block.source,
      error: !block.closed ? "Unclosed Mermaid fence" : !block.source.trim() ? "Empty Mermaid block" : "",
    }));
    const sections = splitDocument(text), definitions = referenceDefinitions(sections);
    this.doc = chapters(sections);
    // Each block gets a stable number for element ids; prose shares the reference definitions.
    let id = 0;
    for (const blocks of [this.doc.lead, ...this.doc.chapters.map((chapter) => chapter.blocks)]) {
      blocks.forEach((block, index) => {
        if (block.kind === "markdown" && definitions) blocks[index] = { ...block, markdown: `${block.markdown}\n\n${definitions}` };
        blocks[index].id = id++;
      });
    }
    this.collapsed = new Set();
    this.cache = new DiagramCache();
    this.copied = -1;
    const base = { readonly: true, font_family: mono(), font_size: CODE_FONT, syntax: syntax(t), line_numbers: false, folding: false };
    this.editors = new Map();
    for (const block of this.blocks()) {
      if (block.kind !== "code" || this.editors.size >= MAX_EDITORS) continue;
      const language = LANGUAGES[block.info.toLowerCase()];
      this.editors.set(block.id, EditorState.new({ ...base, ...(language ? { language } : {}), value: block.code }));
    }
  }

  blocks() { return [...this.doc.lead, ...this.doc.chapters.flatMap((chapter) => chapter.blocks)]; }

  release() {
    for (const editor of this.editors.values()) editor.release();
    this.editors.clear();
  }

  summary() {
    const errors = this.diagrams.filter((item) => item.error || this.cache.get(item.source)?.error).length;
    return `${plural(this.diagrams.length, "diagram")}${errors ? ` · ${errors} with errors` : ""}`;
  }

  inspect(index) {
    inspectDiagrams(this.diagrams.filter((item) => !item.error).map(({ title, line, source }) => ({ title, line, source })),
      this.diagrams.slice(0, index).filter((item) => !item.error).length);
  }

  copy(id, code, cx) {
    cx.write_to_clipboard(code);
    this.copied = id;
    cx.notify();
    cx.timer.after(1500, (cx) => { if (this.copied === id) { this.copied = -1; cx.notify(); } });
  }

  block(t, block, width, page, follow) {
    if (block.kind === "markdown") return TextView.markdown(`aqua-md-text-${page}-${block.id}`, block.markdown)
      .w_full().text_size(13).scrollable(false).selectable(true).on_link_click((href, cx) => follow(href, cx));
    if (block.kind === "code") return frame(t, {
      tabs: tag(t, block.info || "text", "info"),
      caption: [button(t, `aqua-md-copy-${page}-${block.id}`, this.copied === block.id ? "Copied" : "Copy", (cx) => this.copy(block.id, block.code, cx), { pressed: this.copied === block.id })],
      body: [codeBox(t, `aqua-md-code-${page}-${block.id}`, this.editors.get(block.id), block.code, CODE_LINES)],
    });
    const item = this.diagrams[block.index], rendered = item.error ? { error: item.error } : this.cache.get(item.source);
    return frame(t, {
      tabs: h_flex().gap(8).items_center().min_w(0)
        .child(tag(t, rendered?.type ?? "mermaid", rendered?.error ? "high" : "info"))
        .child(div().min_w(0).truncate().text_size(12).font_medium().text_color(t.foreground).child(plain(item.title))),
      caption: [div().font_family(mono()).child(`line ${item.line}`),
        ...(item.error ? [] : [button(t, `aqua-md-inspect-${page}-${block.index}`, "Inspect ↗", () => this.inspect(block.index))])],
      body: [diagram(t, rendered, width - 30, { inspect: false })],
    });
  }

  toolbar(t, back) {
    const style = stylePrefs(), many = this.doc.chapters.length > 1, drawn = this.diagrams.some((item) => !item.error);
    const group = (label, id, list, value, kind) => h_flex().flex_none().gap(6).items_center()
      .child(eyebrow(t, label))
      .child(tabs(t, id, list.map((entry) => ({ label: entry, value: entry })), value, (choice) => setStyle(kind, choice)));
    return h_flex().flex_none().gap(14).items_center().flex_wrap()
      .when(Boolean(back), (el) => el.child(button(t, "aqua-back", "‹ Back", back)))
      .when(drawn, (el) => el
        .child(group("Colour", "aqua-md-colour", COLOURS, style.colours, "colours"))
        .child(group("Edges", "aqua-md-edges", EDGES, style.edges, "edges")))
      .child(div().flex_1())
      .child(h_flex().flex_none().gap(6).items_center()
        .when(drawn, (el) => el.child(button(t, "aqua-md-inspect-all", "Inspect diagrams ↗", () => this.inspect(0))))
        .when(many, (el) => el
          .child(button(t, "aqua-md-expand", "Expand all", (cx) => { this.collapsed = new Set(); cx.notify(); }, { ghost: true }))
          .child(button(t, "aqua-md-collapse", "Collapse all", (cx) => { this.collapsed = new Set(this.doc.chapters.map((_chapter, index) => index)); cx.notify(); }, { ghost: true }))));
  }

  card(t, chapter, index, width, page, follow) {
    const open = !this.collapsed.has(index);
    const counts = { diagram: 0, code: 0 };
    for (const block of chapter.blocks) if (block.kind in counts) counts[block.kind]++;
    const head = h_flex().id(`aqua-md-chapter-${page}-${index}`).gap(10).items_center().cursor_pointer()
      .on_click((_event, cx) => { open ? this.collapsed.add(index) : this.collapsed.delete(index); cx.notify(); })
      .child(div().w(10).flex_none().text_size(10).text_color(t.dim).child(open ? "▾" : "▸"))
      .child(div().flex_none().font_family(mono()).text_size(11).text_color(hue(t, HUES[index % HUES.length])).child(String(index + 1).padStart(2, "0")))
      .child(div().flex_1().min_w(0).text_size(14).font_semibold().text_color(t.foreground).child(plain(chapter.title)))
      .when(counts.diagram > 0, (el) => el.child(tag(t, plural(counts.diagram, "diagram"), "info")))
      .when(counts.code > 0, (el) => el.child(tag(t, plural(counts.code, "snippet"), "neutral")));
    return v_flex().flex_none().gap(10).p(14).rounded(10).bg(t.surface).border(1).border_color(t.border)
      .child(head)
      .when(open && chapter.blocks.length > 0, (el) => el.child(v_flex().pl(20).gap(12)
        .children(chapter.blocks.map((block) => this.block(t, block, width - 70, page, follow)))));
  }

  // The page's content below its meta line. `back` is the page's Back action, or null.
  render(t, width, page, follow, back, cx) {
    this.cache.ensure(this.diagrams.filter((item) => !item.error).map((item) => item.source), cx);
    const lead = v_flex().flex_none().gap(10).children(this.doc.lead.map((block) => block.kind === "markdown"
      ? TextView.markdown(`aqua-md-text-${page}-${block.id}`, block.markdown).w_full().text_size(14).scrollable(false).selectable(true).on_link_click((href, cx) => follow(href, cx))
      : this.block(t, block, width, page, follow)));
    return [
      ...(this.doc.title ? [div().text_size(22).font_semibold().text_color(t.foreground).child(plain(this.doc.title))] : []),
      ...(this.doc.lead.length ? [lead] : []),
      this.toolbar(t, back),
      ...this.doc.chapters.map((chapter, index) => this.card(t, chapter, index, width, page, follow)),
    ];
  }
}
