// The inspection dialog: one section's complete reader, opened from a story stop on the page.
// TraceDiff, Trace, WhatBreaks and CodeLens live here; other types come from READERS
// (readers.js), and anything still unported shows its authored JSON.

import { div } from "gpui-kit";
import { h_flex, v_flex, Editor, EditorState } from "gpui-base";
import { props, theme, readTextFile, closeOverlay, nextCommand, openOverlay } from "herdr";
import { DiagramCache, stylePrefs, cycleStyle } from "./render.js";
import { READERS } from "./readers.js";
import { codeRows, markDiagram, traceMarks, changeMarks, fileLanguage, typeLabel, brief } from "./model.js";
import { CODE_FONT, mono, syntax, button, tag, eyebrow, rich, frame, tabs, sourceBox, diagram, diff, hue } from "./ui.js";

const WHAT_BREAKS_NOTICE = "Authored counterfactual — not executed fault injection or test results";
const CODE_NOTICE = "Curated snippets, not complete source or test evidence";

export default class AquaCutterInspector {
  init(_props, cx) {
    const initial = props() ?? {};
    this.file = initial.file;
    this.on = initial.on ?? null;
    this.sectionId = initial.section;
    this.request = initial.request ?? null;
    this.doc = null;
    this.section = null;
    this.error = "";
    this.width = 900;
    this.diagrams = new DiagramCache();
    this.editors = new Map();
    this.sourceOpen = false;
    this.diagramShown = true;
    this.load(cx);
    cx.spawn(async () => {
      for (;;) if (await nextCommand() === "close") this.dismiss();
    });
  }

  load(cx) {
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(this.file, { on: this.on });
        if (text === null) throw new Error("Walkthrough JSON not found.");
        const doc = JSON.parse(text);
        const section = (doc.sections ?? []).find((entry) => entry.id === this.sectionId);
        if (!section) throw new Error(`Section ${this.sectionId} is not in this walkthrough.`);
        this.doc = doc;
        this.section = section;
        this.pathIndex = 0;
        this.stepIndex = 0;
        this.fault = section.initialFault ?? section.faults?.[0]?.id;
        this.hunk = section.initialHunk ?? section.entries?.[0]?.id;
        this.state = new Map();
        this.build();
        this.diagrams.ensure(this.sources(), cx);
      } catch (error) {
        this.error = String(error?.message ?? error);
      }
      cx.notify();
    });
  }

  // EditorStates are made here, never while rendering.
  build() {
    const section = this.section, base = { readonly: true, font_family: mono(), font_size: CODE_FONT, syntax: syntax(theme()), line_numbers: false, folding: false };
    const plugin = READERS[section.type];
    if (plugin) {
      for (const entry of plugin.editors?.(section) ?? []) {
        this.editors.set(entry.key, EditorState.new({ ...base, ...(entry.language ? { language: entry.language } : {}),
          line_numbers: Boolean(entry.lineNumbers), soft_wrap: Boolean(entry.wrap), value: String(entry.value ?? "") }));
      }
    } else if (section.type === "code-lens") {
      for (const entry of section.entries ?? []) {
        const language = fileLanguage(entry.file);
        this.editors.set(entry.id, EditorState.new({ ...base, ...(language ? { language } : {}), value: codeRows(entry).map((row) => row.text).join("\n") }));
      }
    } else if (!["trace-diff", "trace", "what-breaks"].includes(section.type)) {
      this.editors.set("json", EditorState.new({ ...base, language: "json", line_numbers: true, folding: true, value: JSON.stringify(section, null, 2) }));
    }
  }

  close() {
    for (const editor of this.editors.values()) editor.release();
    this.editors.clear();
  }

  dismiss() { if (props()?.overlay) closeOverlay(props().overlay); }

  colours() {
    const t = theme();
    return { accent: t.accent, done: t.done, blocked: t.blocked, working: t.working, dim: t.dim, background: t.background };
  }

  // Every source the current selection shows, so a choice renders before it is needed.
  sources() {
    const section = this.section, colours = this.colours();
    if (!section) return [];
    if (section.type === "trace-diff") return [
      markDiagram(section.before?.source, changeMarks(section.before, colours), colours.background),
      markDiagram(section.after?.source, changeMarks(section.after, colours), colours.background),
    ];
    if (section.type === "trace") return (section.paths ?? []).flatMap((path) =>
      (path.steps ?? []).map((_step, index) => markDiagram(section.diagram?.source, traceMarks(path, index, colours), colours.background)));
    if (section.type === "what-breaks") return (section.faults ?? []).map((fault) => this.faultSource(fault));
    const plugin = READERS[section.type];
    if (plugin) return plugin.sources?.(section, this.context()) ?? [];
    return section.diagram?.source ? [section.diagram.source] : [];
  }

  // What a READERS plugin may use: selection state, rendered diagrams, its EditorStates and helpers.
  // `request` is the address another reader asked this one to open at; `inspect` opens another
  // section's dialog with such a request.
  context() {
    return {
      width: this.width,
      doc: this.doc,
      request: this.request,
      inspect: (section, request) => openOverlay({ mod: "aqua-cutter", kind: "dialog", width: 0.86, height: 0.88,
        props: { view: "inspector", file: this.file, on: this.on, section, ...(request ? { request } : {}) } }),
      colours: this.colours(),
      diagram: (source) => this.diagrams.get(source),
      editor: (key) => this.editors.get(key),
      get: (key, fallback) => (this.state.has(key) ? this.state.get(key) : fallback),
      set: (key, value, cx) => { this.state.set(key, value); cx.notify(); },
      sourceToggle: (t, entries) => this.sourceToggle(t, entries),
    };
  }

  faultSource(fault) {
    const colours = this.colours();
    return markDiagram(this.section.diagram?.source, [{ node: fault.node, colour: colours.blocked, width: 3, fill: true }], colours.background);
  }

  sourceToggle(t, sources) {
    return v_flex().gap(6)
      .child(h_flex().id("aqua-source").gap(5).items_center().cursor_pointer().hover((el) => el.text_color(t.muted))
        .on_click((_event, cx) => { this.sourceOpen = !this.sourceOpen; cx.notify(); })
        .child(this.sourceOpen ? "▾" : "▸").child("diagram source"))
      .when(this.sourceOpen, (el) => el.children(sources.flatMap(([label, description, source]) => [
        ...(label ? [div().text_color(t.muted).child(label)] : []),
        ...(description ? [div().child(description)] : []),
        sourceBox(t, source),
      ])));
  }

  traceDiff(t, section) {
    const colours = this.colours(), wide = this.width >= 860;
    const pane = (label, side) => v_flex().flex_1().min_w(0).gap(8)
      .child(div().text_size(12).font_semibold().text_color(t.foreground).child(label))
      .child(diagram(t, this.diagrams.get(markDiagram(side?.source, changeMarks(side, colours), colours.background)), wide ? (this.width - 120) / 2 : this.width - 80, { height: 320 }))
      .when(Boolean(side?.description), (el) => el.child(rich(`aqua-td-${label}-desc`, side.description, 11.5)))
      .child(v_flex().gap(3).children((side?.steps ?? []).map((step, index) => h_flex().gap(8).items_start()
        .child(div().w(18).flex_none().font_family(mono()).text_size(10).text_color(t.dim).child(String(index + 1).padStart(2, "0")))
        .child(div().flex_1().min_w(0).text_size(11.5).text_color(t.muted).child(step)))));
    const panes = [pane("Before", section.before), pane("After", section.after)];
    return frame(t, {
      body: [(wide ? h_flex().items_start().gap(16) : v_flex().gap(16)).children(panes),
        h_flex().gap(10).flex_wrap().children(["added", "removed", "moved"].map((status) => tag(t, status.charAt(0).toUpperCase() + status.slice(1), status)))],
      footer: [div().child("authored change markers · not an inferred diff"),
        this.sourceToggle(t, [["Before · source", "", section.before?.source], ["After · source", "", section.after?.source]])],
    });
  }

  trace(t, section) {
    const paths = section.paths ?? [], path = paths[this.pathIndex] ?? paths[0];
    if (!path) return this.fallback(t, section);
    const steps = path.steps ?? [], step = steps[this.stepIndex] ?? steps[0], last = this.stepIndex === steps.length - 1;
    const notReached = path.outcome === "reject" ? path.notReached?.nodes ?? [] : [];
    const rail = v_flex().w(this.width >= 760 ? 260 : 200).flex_none().gap(2)
      .children(steps.map((entry, index) => {
        const current = index === this.stepIndex, done = index < this.stepIndex;
        return h_flex().id(`aqua-step-${index}`).gap(8).px(8).py(6).rounded(6).items_start().cursor_pointer()
          .bg(current ? t.raised : t.surface).hover((el) => el.bg(t.hover))
          .on_click((_event, cx) => { this.stepIndex = index; cx.notify(); })
          .child(div().size(9).mt(4).flex_none().rounded_full().border_2()
            .border_color(current ? t.accent : done ? t.done : t.border).when(done, (el) => el.bg(t.done)))
          .child(div().flex_1().min_w(0).text_size(11.5).text_color(current ? t.foreground : t.muted).child(entry.title ?? ""));
      }))
      .children(notReached.map((node) => h_flex().gap(8).px(8).py(4).items_center()
        .child(div().size(9).flex_none().rounded_full().border(1).border_dashed().border_color(t.dim))
        .child(div().text_size(11).text_color(t.dim).child(`Not reached: ${node}`))));
    const instruction = v_flex().flex_1().min_w(0).gap(6)
      .child(eyebrow(t, `Step ${this.stepIndex + 1} / ${steps.length}`))
      .child(div().text_size(14).font_semibold().text_color(t.foreground).child(step?.title ?? ""))
      .when(Boolean(step?.narration), (el) => el.child(rich(`aqua-trace-narration-${this.pathIndex}-${this.stepIndex}`, step.narration)))
      .when(last, (el) => el.child(h_flex().gap(8).items_start()
        .child(tag(t, path.outcome === "ok" ? "OK outcome" : "Reject outcome", path.outcome === "ok" ? "added" : "removed"))
        .when(Boolean(path.outcomeDescription) && path.outcomeDescription !== step?.narration,
          (row) => row.child(div().flex_1().min_w(0).child(rich(`aqua-trace-outcome-${this.pathIndex}`, path.outcomeDescription, 11.5))))));
    const source = markDiagram(section.diagram?.source, traceMarks(path, this.stepIndex, this.colours()), t.background);
    return frame(t, {
      tabs: paths.length > 1
        ? tabs(t, "aqua-paths", paths.map((entry, index) => ({ label: entry.label, value: index })), this.pathIndex,
          (index, cx) => { this.pathIndex = index; this.stepIndex = 0; cx.notify(); })
        : div().text_size(12).font_semibold().text_color(t.foreground).child(path.label ?? ""),
      caption: [div().child("authored · not executed"),
        button(t, "aqua-diagram-toggle", this.diagramShown ? "Hide diagram" : "Show diagram", (cx) => { this.diagramShown = !this.diagramShown; cx.notify(); }, { ghost: true })],
      body: [h_flex().items_start().gap(16).child(rail).child(instruction),
        ...(this.diagramShown && section.diagram ? [diagram(t, this.diagrams.get(source), this.width - 80, { height: 360 })] : [])],
      footer: section.diagram ? [this.sourceToggle(t, [["", section.diagram.description, section.diagram.source]])] : [],
    });
  }

  whatBreaks(t, section) {
    const faults = section.faults ?? [], fault = faults.find((entry) => entry.id === this.fault) ?? faults[0];
    if (!fault) return this.fallback(t, section);
    const severity = fault.severity === "high" ? "High" : fault.severity === "med" ? "Watch" : "Low";
    const block = (id, label, text) => v_flex().flex_1().min_w(220).gap(4).child(eyebrow(t, label)).child(rich(id, text ?? "", 12));
    const cites = [fault.invariant, fault.corpus].filter(Boolean);
    const missing = [!fault.invariant && "No invariant reference supplied", !fault.corpus && "No case reference supplied"].filter(Boolean);
    return frame(t, {
      tabs: faults.length > 1
        ? tabs(t, "aqua-faults", faults.map((entry) => ({ label: entry.title, value: entry.id })), fault.id, (id, cx) => { this.fault = id; cx.notify(); })
        : div().text_size(12).font_semibold().text_color(t.foreground).child(fault.title ?? ""),
      caption: [div().child("counterfactual · not fault injection")],
      body: [
        h_flex().gap(8).items_center()
          .child(tag(t, `${severity} severity`, fault.severity === "high" ? "high" : fault.severity === "med" ? "warn" : "neutral"))
          .child(div().font_family(mono()).text_size(10.5).text_color(t.dim).child(`marks ${fault.node}`)),
        h_flex().gap(16).items_start().flex_wrap()
          .child(block(`aqua-breaks-${fault.id}`, "What breaks", fault.breaks))
          .child(block(`aqua-becomes-${fault.id}`, "Response becomes", fault.becomes)),
        block(`aqua-rule-${fault.id}`, "Broken rule", fault.brokenRule),
        ...(section.diagram ? [diagram(t, this.diagrams.get(this.faultSource(fault)), this.width - 80, { height: 300 })] : []),
      ],
      footer: [
        ...(cites.length ? [div().child(`cites ${cites.join(" · ")}`)] : []),
        ...(missing.length ? [div().child(missing.join(" · "))] : []),
        ...(section.diagram ? [this.sourceToggle(t, [["", section.diagram.description, section.diagram.source]])] : []),
      ],
      notice: WHAT_BREAKS_NOTICE,
    });
  }

  codeLens(t, section) {
    const entries = section.entries ?? [], selected = entries.find((entry) => entry.id === this.hunk) ?? entries[0];
    if (!selected) return this.fallback(t, section);
    const files = [...new Set(entries.map((entry) => entry.file))];
    const hunks = entries.filter((entry) => entry.file === selected.file);
    const rows = codeRows(selected);
    const additions = rows.filter((row) => row.marker === "+").length, removals = rows.filter((row) => row.marker === "-").length;
    const range = `@@ -${selected.oldStart},${rows.length - additions} +${selected.newStart},${rows.length - removals} @@`;
    const total = section.coverage?.total ?? entries.length;
    const categories = (section.coverage?.omitted ?? []).map((category) => `${category.label} ${category.count}`).join(", ");
    const references = selected.references ?? [];
    const editor = this.editors.get(selected.id);
    return frame(t, {
      tabs: files.length > 1
        ? tabs(t, "aqua-files", files.map((file) => ({ label: file, value: file })), selected.file,
          (file, cx) => { this.hunk = entries.find((entry) => entry.file === file)?.id; cx.notify(); }, { monospace: true })
        : div().font_family(mono()).text_size(11).text_color(t.foreground).child(selected.file),
      caption: [div().child(`Authored coverage · Showing ${entries.length} of ${total} changed hunks · ${total - entries.length} omitted${categories ? ` (${categories})` : ""}`)],
      body: [
        ...(hunks.length > 1 ? [tabs(t, "aqua-hunks", hunks.map((entry) => ({ label: entry.title ?? entry.id, value: entry.id })), selected.id, (id, cx) => { this.hunk = id; cx.notify(); })] : []),
        h_flex().gap(10).items_center().flex_wrap()
          .child(div().text_size(13).font_semibold().text_color(t.foreground).child(selected.title ?? selected.id))
          .child(div().font_family(mono()).text_size(10.5).text_color(t.dim).child(range))
          .child(div().font_family(mono()).text_size(10.5).text_color(t.done).child(`+${additions}`))
          .child(div().font_family(mono()).text_size(10.5).text_color(t.blocked).child(`−${removals}`)),
        editor ? diff(t, `aqua-diff-${selected.id}`, rows, editor) : sourceBox(t, selected.hunk),
        ...(selected.why ? [h_flex().gap(10).items_start().child(div().pt(2).child(eyebrow(t, "Why"))).child(div().flex_1().min_w(0).child(rich(`aqua-why-${selected.id}`, selected.why)))] : []),
      ],
      footer: [div().child(`Cited references: ${references.length ? references.join(" · ") : "No cited references supplied"}`)],
      notice: CODE_NOTICE,
    });
  }

  fallback(t, section) {
    const editor = this.editors.get("json");
    return frame(t, {
      caption: [div().child(`${typeLabel(section.type)} isn't ported to the native reader yet`)],
      body: [
        ...(section.diagram ? [diagram(t, this.diagrams.get(section.diagram.source), this.width - 80, { height: 360 })] : []),
        editor ? div().w_full().h(420).rounded(7).overflow_hidden().border(1).border_color(t.border).child(Editor.new(editor).size_full())
          : sourceBox(t, JSON.stringify(section, null, 2)),
      ],
    });
  }

  reader(t, section) {
    if (section.type === "trace-diff") return this.traceDiff(t, section);
    if (section.type === "trace") return this.trace(t, section);
    if (section.type === "what-breaks") return this.whatBreaks(t, section);
    if (section.type === "code-lens") return this.codeLens(t, section);
    const plugin = READERS[section.type];
    if (plugin) return plugin.render(this.context(), t, section);
    return this.fallback(t, section);
  }

  render(cx) {
    const t = theme(), section = this.section;
    // A theme change clears the cache and changes the highlight colours: render those again.
    if (section) this.diagrams.ensure(this.sources(), cx);
    const info = section ? brief(section) : null;
    const head = h_flex().h(46).flex_none().px(14).gap(10).items_center().bg(t.chrome).border_b(1).border_color(t.border)
      .child(div().w(3).h(20).flex_none().rounded(2).bg(info ? hue(t, info.hue) : t.accent))
      .child(v_flex().flex_1().min_w(0)
        .child(div().truncate().text_size(13.5).font_semibold().text_color(t.foreground).child(section?.title ?? "Inspection"))
        .child(div().truncate().text_size(10).text_color(t.dim).child("Complete supporting reader · closing returns to the story")))
      .when(Boolean(section), (el) => el.child(tag(t, typeLabel(section.type), "info")))
      .child(button(t, "aqua-inspect-colours", `Colour: ${stylePrefs().colours} ↻`, () => cycleStyle("colours")))
      .child(button(t, "aqua-inspect-edges", `Edges: ${stylePrefs().edges} ↻`, () => cycleStyle("edges")))
      .child(button(t, "aqua-inspect-close", "Close × · Esc", () => this.dismiss()));
    const body = v_flex().id("aqua-inspect-body").flex_1().min_h(0).p(18).gap(12).overflow_y_scrollbar();
    if (this.error) body.child(div().text_size(12).text_color(t.blocked).child(this.error));
    else if (!section) body.child(div().text_size(12).text_color(t.dim).child("Reading section…"));
    else body.when(Boolean(section.reason), (el) => el.child(rich("aqua-inspect-reason", section.reason, 13))).child(this.reader(t, section));
    return v_flex().size_full().min_h(0).bg(t.background).text_color(t.foreground)
      .on_size_change((size, cx) => { if (size.width > 0 && Math.abs(size.width - this.width) > 4) { this.width = size.width; cx.notify(); } })
      .child(head).child(body);
  }
}
