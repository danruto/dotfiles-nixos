// Aqua Cutter walkthroughs, read natively: the authored JSON as cards, with
// diagrams as source (Herdr has no web view), code lenses as hunks and the
// tour/what-breaks sections as they were written.

import { View, div, svg, image } from "gpui-kit";
import { h_flex, v_flex, InputState, Input } from "gpui-base";
import {
  spaces, panes, focused, theme, props, readTextFile, writeTextFile, appHome, exec, window, settings,
} from "herdr";

const ABS = /^([/\\]|[A-Za-z]:[\\/])/;

export default class AquaCutter extends View {
  init(_props, cx) {
    this.doc = null;
    this.path = "";
    this.on = null;
    this.error = "";
    this.loading = false;
    this.refsOpen = false;
    this.diagrams = new Map();
    this.diagramsLoading = false;
    this.diagramsError = "";
    this.input = InputState.new({ placeholder: "Path to a walkthrough JSON..." });
    this.input.on("submit", (_event, cx) => this.open(this.input.value().trim(), this.on, cx));
    const initial = props() ?? {};
    if (typeof initial.file === "string") {
      this.open(initial.file, typeof initial.on === "string" ? initial.on : null, cx, false);
    } else {
      const saved = localStorage.getItem("aqua-cutter.file");
      if (saved) this.open(saved, localStorage.getItem("aqua-cutter.on") || null, cx, false);
      else this.latest(cx);
    }
  }

  where() {
    const space = spaces().find((candidate) => candidate.active);
    const f = focused();
    const cwd = f?.cwd ?? panes().find((pane) => pane.focused)?.cwd ?? space?.folder ?? "";
    return { cwd, on: space?.machine ?? null };
  }

  absolute(path, cwd) {
    if (ABS.test(path)) return path;
    return `${cwd.replace(/[\\/]+$/, "")}/${path}`;
  }

  latest(cx) {
    const { cwd, on } = this.where();
    if (!cwd) { this.error = "Open a space first; the walkthrough lives under docs/pr."; cx.notify(); return; }
    cx.spawn(async (cx) => {
      try {
        const windows = !on && window()?.platform === "windows";
        const result = windows
          ? await exec("powershell", ["-NoProfile", "-Command",
            "Get-ChildItem -Path 'docs/pr/*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName"], { cwd })
          : await exec("sh", ["-c", "ls -t docs/pr/*.json 2>/dev/null | head -1"], { cwd, on });
        const found = result.stdout.trim().split("\n").filter(Boolean)[0];
        if (!found) throw new Error("No walkthrough JSON under docs/pr.");
        this.open(this.absolute(found.trim(), cwd), on, cx, false);
      } catch (error) {
        this.error = String(error?.message ?? error);
        cx.notify();
      }
    });
  }

  open(path, on, cx, remember = true) {
    if (!path) return;
    const { cwd } = this.where();
    const absolute = this.absolute(path, cwd);
    this.input.set_value(absolute);
    this.loading = true;
    this.error = "";
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(absolute, { on });
        if (text === null) throw new Error("Walkthrough JSON not found.");
        const doc = JSON.parse(text);
        if (!doc || !Array.isArray(doc.sections)) throw new Error("Not an Aqua Cutter walkthrough (no sections).");
        this.doc = doc;
        this.path = absolute;
        this.on = on;
        if (remember) {
          localStorage.setItem("aqua-cutter.file", absolute);
          localStorage.setItem("aqua-cutter.on", on ?? "");
        }
        this.renderDiagrams(doc, cx);
      } catch (error) {
        this.error = String(error?.message ?? error);
      }
      this.loading = false;
      cx.notify();
    });
  }

  renderDiagrams(doc, cx) {
    const sources = [];
    for (const section of doc.sections ?? []) {
      const source = section.diagram?.source;
      if (source && !sources.includes(source)) sources.push(source);
    }
    this.diagrams = new Map();
    if (!sources.length) return;
    this.diagramsLoading = true;
    this.diagramsError = "";
    cx.notify();
    const input = `${appHome()}/data/aqua-cutter-input.json`;
    cx.spawn(async (cx) => {
      try {
        const prior = await readTextFile(input);
        await writeTextFile(input, JSON.stringify({ sources, theme: theme() }), prior);
        const result = await exec("node", [`${appHome()}/mods/aqua-cutter/diagrams.mjs`, input]);
        const data = JSON.parse(result.stdout || "{}");
        if (!data.ok) throw new Error(data.error || "Diagram renderer failed");
        (data.diagrams ?? []).forEach((diagram, index) => {
          if (sources[index]) this.diagrams.set(sources[index], diagram);
        });
      } catch (error) {
        this.diagramsError = String(error?.message ?? error);
      }
      this.diagramsLoading = false;
      cx.notify();
    });
  }

  button(id, label, action) {
    const t = theme();
    return h_flex().id(id).h(26).px(8).flex_none().items_center().justify_center().rounded(6)
      .text_size(11).text_color(t.muted).cursor_pointer().border(1).border_color(t.border)
      .hover((el) => el.bg(t.hover).text_color(t.foreground))
      .on_click((_event, cx) => action(cx)).child(label);
  }

  mono(text, color, size = 11) {
    return div().flex_none().font_family(settings()?.font ?? "JetBrains Mono").text_size(size)
      .text_color(color).child(text);
  }

  card(child) {
    const t = theme();
    return v_flex().flex_none().gap(6).p(12).rounded(10).bg(t.surface).border(1).border_color(t.border).child(child);
  }

  lines(text, t, cap = 400) {
    const list = String(text ?? "").split("\n").slice(0, cap);
    return v_flex().flex_none().gap(1).p(8).rounded(7).bg(t.background)
      .children(list.map((line) => this.mono(line, line.startsWith("+") ? t.done
        : line.startsWith("-") ? t.blocked
          : line.startsWith("@") ? t.accent : t.muted, 10.5)));
  }

  diagram(block, t) {
    const rendered = this.diagrams.get(block?.source);
    const picture = rendered?.file && !rendered.error
      ? (() => {
          const raw = rendered.width || 720;
          const scale = Math.min(1, 720 / raw);
          const width = Math.round(raw * scale);
          const height = Math.round((rendered.height || 400) * scale);
          return image(rendered.path).w(width).h(height);
        })()
      : null;
    return v_flex().flex_none().gap(6)
      .when(Boolean(picture), (el) => el.child(picture))
      .when(!picture, (el) => el.child(this.lines(block?.source ?? "", t, 120)))
      .when(this.diagramsLoading && !picture, (el) => el.child(div().text_size(10.5).text_color(t.dim).child("Rendering diagram...")))
      .when(Boolean(rendered?.error), (el) => el.child(div().text_size(10.5).text_color(t.blocked).child(rendered.error)))
      .when(Boolean(this.diagramsError) && !picture, (el) => el.child(div().text_size(10.5).text_color(t.blocked).child(this.diagramsError)))
      .when(Boolean(block?.description), (el) => el.child(div().text_size(11).text_color(t.muted).child(block.description)));
  }

  steps(steps, t) {
    return v_flex().flex_none().gap(5).children((steps ?? []).map((step) => h_flex().flex_none().gap(8).items_start()
      .child(div().min_w(42).flex_none().px(4).py(1).rounded(4).bg(t.raised).font_family(settings()?.font ?? "JetBrains Mono")
        .text_size(9.5).text_color(t.accent).child(step.node ?? "-"))
      .child(v_flex().flex_1().min_w(0).gap(2)
        .child(div().text_size(11.5).font_semibold().text_color(t.foreground).child(step.title ?? ""))
        .when(Boolean(step.narration), (el) => el.child(div().text_size(10.5).text_color(t.dim).child(step.narration))))));
  }

  section(section, t) {
    const head = h_flex().gap(7).items_center().min_w(0)
      .child(div().flex_none().px(5).py(1).rounded(4).bg(t.raised).text_size(9).font_semibold()
        .text_color(t.accent).child(String(section.type ?? "section").toUpperCase()))
      .child(div().flex_1().min_w(0).text_size(12.5).font_semibold().text_color(t.foreground)
        .child(section.title ?? section.id ?? ""));
    const body = v_flex().flex_none().gap(8).child(head)
      .when(Boolean(section.reason), (el) => el.child(div().text_size(11).text_color(t.muted).child(section.reason)))
      .when(Boolean(section.diagram), (el) => el.child(this.diagram(section.diagram, t)));
    for (const path of section.paths ?? []) {
      body.child(v_flex().flex_none().gap(4)
        .child(div().text_size(10.5).font_semibold().text_color(t.muted).child(path.label ?? path.id ?? "path"))
        .child(this.steps(path.steps, t)));
    }
    for (const fault of section.faults ?? []) {
      const tone = fault.severity === "high" ? t.blocked : fault.severity === "med" ? t.working : t.dim;
      body.child(v_flex().flex_none().gap(3).p(8).rounded(7).bg(t.background)
        .child(h_flex().gap(6).items_center()
          .child(div().flex_none().text_size(9).font_semibold().text_color(tone).child(String(fault.severity ?? "").toUpperCase()))
          .child(div().flex_1().text_size(11.5).font_semibold().text_color(t.foreground).child(fault.title ?? "")))
        .when(Boolean(fault.breaks), (el) => el.child(div().text_size(10.5).text_color(t.muted).child(fault.breaks)))
        .when(Boolean(fault.becomes), (el) => el.child(div().text_size(10.5).text_color(t.dim).child(fault.becomes)))
        .when(Boolean(fault.brokenRule), (el) => el.child(div().text_size(10).text_color(t.accent).child(fault.brokenRule))));
    }
    for (const entry of section.entries ?? []) {
      body.child(v_flex().flex_none().gap(3)
        .child(h_flex().gap(6).items_center()
          .child(this.mono(entry.file ?? entry.id ?? "", t.accent, 10.5))
          .child(div().flex_none().text_size(9.5).text_color(t.dim)
            .child(`+${entry.newStart ?? 0} / -${entry.oldStart ?? 0}`)))
        .child(this.lines(entry.hunk ?? "", t)));
    }
    for (const chapter of section.chapters ?? []) {
      body.child(v_flex().flex_none().gap(2).p(8).rounded(7).bg(t.background)
        .child(h_flex().gap(6).items_center()
          .child(div().flex_1().text_size(11.5).font_semibold().text_color(t.foreground).child(chapter.title ?? ""))
          .when(Boolean(chapter.target), (el) => el.child(this.mono(chapter.target, t.dim, 9.5))))
        .when(Boolean(chapter.body), (el) => el.child(div().text_size(10.5).text_color(t.muted).child(chapter.body)))
        .when(Boolean(chapter.hint), (el) => el.child(div().text_size(10).text_color(t.dim).child(chapter.hint))));
    }
    return this.card(body);
  }

  render() {
    const t = theme();
    const doc = this.doc;
    const refs = doc?.references ?? [];
    const head = h_flex().h(42).flex_none().px(10).gap(7).items_center().bg(t.chrome)
      .border_b(1).border_color(t.border)
      .child(svg("mods/workspace-chrome/layers.svg").size(14).flex_none().text_color(t.accent))
      .child(div().flex_none().text_size(12.5).font_semibold().text_color(t.foreground).child("Aqua Cutter"))
      .child(h_flex().flex_1().min_w(0).h(28).px(7).items_center().rounded(6).bg(t.background)
        .border(1).border_color(t.border)
        .child(Input.new(this.input).flex_1().text_size(10.5).text_color(t.muted)))
      .child(this.button("aqua-refresh", "Refresh", (cx) => this.open(this.path || this.input.value(), this.on, cx)))
      .child(this.button("aqua-latest", "Latest", (cx) => this.latest(cx)));

    const body = v_flex().id("aqua-body").flex_1().min_h(0).gap(10).p(14).overflow_y_scrollbar();
    if (this.loading) body.child(div().p(20).text_size(12).text_color(t.dim).child("Reading walkthrough..."));
    else if (this.error) body.child(v_flex().gap(6).p(12).rounded(8).bg(t.surface).border(1).border_color(t.border)
      .child(div().text_size(12).text_color(t.blocked).child(this.error))
      .child(div().text_size(10.5).text_color(t.dim).child("Put a walkthrough under docs/pr/ in the focused space, or paste its path above.")));
    else if (!doc) body.child(div().p(20).text_size(12).text_color(t.dim).child("No walkthrough loaded."));
    else {
      body.child(v_flex().flex_none().gap(6)
        .child(div().text_size(18).font_semibold().text_color(t.foreground).child(doc.title ?? "Walkthrough"))
        .when(Boolean(doc.lead), (el) => el.child(div().text_size(12).text_color(t.muted).child(doc.lead)))
        .child(div().text_size(10).text_color(t.dim).child(this.path)));
      if (Array.isArray(doc.changes) && doc.changes.length) {
        body.child(this.card(v_flex().flex_none().gap(5)
          .child(div().text_size(10.5).font_semibold().text_color(t.muted).child("CHANGES"))
          .children(doc.changes.map((change) => h_flex().gap(6).items_start()
            .child(div().flex_none().text_color(t.dim).child("•"))
            .child(div().flex_1().text_size(11).text_color(t.muted).child(String(change)))))));
      }
      if (refs.length) {
        body.child(this.card(v_flex().flex_none().gap(5)
          .child(h_flex().id("aqua-refs").gap(6).items_center().cursor_pointer()
            .on_click((_e, cx) => { this.refsOpen = !this.refsOpen; cx.notify(); })
            .child(div().flex_none().text_size(10).text_color(t.dim).child(this.refsOpen ? "▾" : "▸"))
            .child(div().text_size(10.5).font_semibold().text_color(t.muted).child("REFERENCES"))
            .child(div().text_size(10).text_color(t.dim).child(String(refs.length))))
          .when(this.refsOpen, (el) => el.children(refs.map((ref) => h_flex().gap(8).items_start()
            .child(div().min_w(140).w(180).flex_none().text_size(10.5).text_color(t.muted).child(ref.label ?? ""))
            .child(div().flex_1().text_size(10).text_color(t.dim).child(ref.value ?? "")))))));
      }
      body.children(doc.sections.map((section) => this.section(section, t)));
    }

    return v_flex().size_full().min_h(0).bg(t.background).child(head).child(body);
  }
}
