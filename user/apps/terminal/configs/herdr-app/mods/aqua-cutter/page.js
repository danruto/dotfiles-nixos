// The Aqua page: a walkthrough (overview, tour and the story's stop cards, ported from the
// renderer's walkthrough_page.tsx; each stop's Inspect buttons open that section's reader in a
// dialog) or a Markdown document (markdown-view.js), whichever file the path names.

import { div, svg } from "gpui-kit";
import { h_flex, v_flex, InputState, Input } from "gpui-base";
import { spaces, panes, focused, theme, props, readTextFile, appHome, exec, window, openOverlay, shared } from "herdr";
import { MarkdownView, isMarkdown } from "./markdown-view.js";
import { linkTarget } from "./links.js";
import { RepoBrowser } from "./browse.js";
import { brief, stops, typeLabel } from "./model.js";
import { mono, hue, button, tag, eyebrow, rich, stepList, sourceBox } from "./ui.js";

const ABS = /^([/\\]|[A-Za-z]:[\\/])/;
const TOUR_NOTICE = "Manual authored walkthrough — not execution, verification or review approval";

export default class AquaCutterPage {
  init(_props, cx) {
    this.doc = null;
    this.markdown = null;
    this.page = 0;
    this.history = [];
    this.path = "";
    this.on = null;
    this.error = "";
    this.loading = false;
    this.refsOpen = false;
    this.collapsed = new Set();
    this.tour = null;
    this.width = 1000;
    this.browsing = null;
    // A request from the Files view; one left over from an earlier session doesn't override props.
    const request = shared("aqua-cutter.open");
    this.seen = request && Date.now() - request.at > 10000 ? request.at : null;
    // Checked on the view's own timer: opening during render would notify mid-render and stall.
    cx.timer.every(300, (cx) => { this.takeRequest(cx); this.track(cx); });
    this.input = InputState.new({ placeholder: "Path to a walkthrough JSON or Markdown file..." });
    this.input.on("submit", (_event, cx) => this.open(this.input.value().trim(), this.on, cx));
    const initial = props() ?? {};
    if (typeof initial.file === "string") {
      this.open(initial.file, typeof initial.on === "string" ? initial.on : null, cx, false);
    } else {
      const saved = localStorage.getItem("aqua-cutter.file");
      if (saved) this.open(saved, localStorage.getItem("aqua-cutter.on") || null, cx, false);
      else this.latest(cx);
    }
    if (initial.browse === true) this.browse(cx);
  }

  close() { this.markdown?.release(); }

  // The session's folder in the active space: the focused terminal's when focus is in that
  // space, else a terminal's in its active tab, then anywhere in it (an Aqua Cutter tab has no
  // terminal of its own), then the space's start folder.
  where() {
    const space = spaces().find((candidate) => candidate.active), f = focused();
    const here = f && f.space === space?.id ? f : null;
    const tabs = new Set((space?.tabs ?? []).map((tab) => tab.id)), current = space?.tabs?.find((tab) => tab.active)?.id;
    const live = panes().filter((pane) => pane.cwd && tabs.has(pane.tab));
    const near = live.find((pane) => pane.pane === here?.pane) ?? live.find((pane) => pane.tab === (here?.tab ?? current)) ?? live[0];
    return { cwd: here?.cwd || near?.cwd || space?.folder || "", on: space?.machine ?? null };
  }



  absolute(path, cwd) {
    if (ABS.test(path)) return path;
    return `${cwd.replace(/[\\/]+$/, "")}/${path}`;
  }

  async walkthroughs() {
    const { cwd, on } = this.where();
    if (!cwd) throw new Error("Open a space first; the walkthrough lives under docs/pr.");
    const windows = !on && window()?.platform === "windows";
    const result = windows
      ? await exec("powershell", ["-NoProfile", "-Command",
        "Get-ChildItem -Path 'docs/pr/*.json' -Exclude '*.renderer.json' | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName"], { cwd })
      : await exec("sh", ["-c", "ls -t docs/pr/*.json 2>/dev/null | grep -v '\\.renderer\\.json$'"], { cwd, on });
    return { on, files: result.stdout.split("\n").map((line) => line.trim()).filter(Boolean).map((file) => this.absolute(file, cwd)) };
  }

  latest(cx) {
    cx.spawn(async (cx) => {
      try {
        const { on, files } = await this.walkthroughs();
        if (!files.length) throw new Error("No walkthrough JSON under docs/pr.");
        this.open(files[0], on, cx, false);
      } catch (error) {
        this.error = String(error?.message ?? error);
        cx.notify();
      }
    });
  }

  // An open Browse panel follows the session: a new space, tab or folder re-roots it.
  track(cx) {
    if (!this.browsing) return;
    const { cwd, on } = this.where();
    if (!cwd || (cwd === this.browsing.cwd && on === this.browsing.on)) return;
    this.browsing = new RepoBrowser(cwd, on);
    this.browsing.start("", cx);
    cx.notify();
  }

  takeRequest(cx) {
    const request = shared("aqua-cutter.open");
    if (!request?.file || request.at === this.seen) return;
    this.seen = request.at;
    this.browsing = null;
    this.open(request.file, request.on ?? null, cx);
  }

  browse(cx) {
    if (this.browsing) { this.browsing = null; cx.notify(); return; }
    const { cwd, on } = this.where();
    if (!cwd) { this.error = "Open a space first; Browse shows the session's repository."; cx.notify(); return; }
    this.browsing = new RepoBrowser(cwd, on);
    this.browsing.start(this.on === on ? this.path : "", cx);
    cx.notify();
  }

  // The panel stays open, so several files can be read in turn.
  choose(file, cx) {
    this.open(file, this.browsing.on, cx);
  }

  open(path, on, cx, remember = true) {
    if (!path) return;
    const { cwd } = this.where();
    const absolute = this.absolute(path, cwd);
    this.input.set_value(absolute);
    const request = this.generation = (this.generation ?? 0) + 1;
    this.loading = true;
    this.error = "";
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(absolute, { on });
        if (request !== this.generation) return;
        if (text === null) throw new Error("File not found, or larger than 1 MiB.");
        if (text.includes("\0")) throw new Error("Not a text file.");
        if (isMarkdown(absolute)) {
          const markdown = new MarkdownView(text, theme());
          this.markdown?.release();
          this.markdown = markdown;
          this.doc = null;
          this.page++;
        } else {
          const doc = JSON.parse(text);
          if (!doc || !Array.isArray(doc.sections)) throw new Error("Not an Aqua Cutter walkthrough (no sections).");
          if (absolute !== this.path) { this.collapsed = new Set(); this.tour = null; }
          this.markdown?.release();
          this.markdown = null;
          this.doc = doc;
        }
        this.path = absolute;
        this.on = on;
        if (remember) {
          localStorage.setItem("aqua-cutter.file", absolute);
          localStorage.setItem("aqua-cutter.on", on ?? "");
        }
      } catch (error) {
        if (request !== this.generation) return;
        this.error = String(error?.message ?? error);
      }
      this.loading = false;
      cx.notify();
    });
  }

  // Relative Markdown links open here on the same machine; Back returns. HTTP(S) opens outside.
  follow(href, cx) {
    const target = linkTarget(href, this.path);
    if (target.kind === "document" && target.path) {
      this.history.push({ path: this.path, on: this.on });
      this.open(target.path, this.on, cx);
    } else if (target.kind === "external" && target.url) {
      const platform = window()?.platform;
      const [command, args] = platform === "macos" ? ["open", [target.url]] : platform === "windows" ? ["cmd", ["/c", "start", "", target.url]] : ["xdg-open", [target.url]];
      cx.spawn(async (cx) => {
        const result = await exec(command, args).catch((error) => ({ code: 1, stderr: String(error?.message ?? error) }));
        if (result.code !== 0) { this.error = result.stderr || "Could not open the link"; cx.notify(); }
      });
    }
  }

  back(cx) {
    const previous = this.history.pop();
    if (previous) this.open(previous.path, previous.on, cx);
  }

  inspect(section) {
    openOverlay({ mod: "aqua-cutter", kind: "dialog", width: 0.86, height: 0.88, props: { view: "inspector", file: this.path, on: this.on, section } });
  }

  // Jumping collapses every other stop, so the chosen one sits near the top of a short page.
  focusStop(id, cx) {
    this.collapsed = new Set(stops(this.doc).map((stop) => stop.section).filter((section) => section !== id));
    cx.notify();
  }

  showChapter(tourSection, index, cx) {
    const chapter = tourSection.chapters?.[index];
    if (!chapter) { this.tour = null; cx.notify(); return; }
    this.tour = { section: tourSection, index };
    if (chapter.target) this.focusStop(chapter.target, cx);
    else cx.notify();
  }

  overview(t) {
    const doc = this.doc, refs = doc.references ?? [], wide = this.width >= 980;
    const main = v_flex().flex_1().min_w(0).gap(10)
      .when(Boolean(doc.lead), (el) => el.child(rich("aqua-lead", doc.lead, 14)))
      .when(refs.length > 0, (el) => el.child(v_flex().gap(6)
        .child(h_flex().id("aqua-refs").gap(6).items_center().cursor_pointer().text_size(11).text_color(t.muted)
          .hover((h) => h.text_color(t.foreground))
          .on_click((_event, cx) => { this.refsOpen = !this.refsOpen; cx.notify(); })
          .child(this.refsOpen ? "▾" : "▸").child("Exact references").child(div().text_color(t.dim).child(String(refs.length))))
        .when(this.refsOpen, (list) => list.child(v_flex().gap(6).p(10).rounded(8).bg(t.surface).border(1).border_color(t.border)
          .children(refs.map((ref, index) => h_flex().gap(12).items_start()
            .child(div().w(150).flex_none().text_size(10.5).font_semibold().text_color(t.muted).child(ref.label ?? ""))
            .child(div().flex_1().min_w(0).child(rich(`aqua-ref-${index}`, ref.value ?? "", 11)))))))));
    const changes = (doc.changes ?? []).length
      ? v_flex().gap(10).p(14).rounded(10).bg(t.surface).border(1).border_color(t.border)
        .when(wide, (el) => el.w(360).flex_none())
        .child(eyebrow(t, "What changed")).child(stepList(t, "aqua-change", doc.changes))
      : null;
    return v_flex().flex_none().gap(12)
      .child(div().text_size(22).font_semibold().text_color(t.foreground).child(doc.title ?? "Walkthrough"))
      .child((wide ? h_flex().items_start() : v_flex()).gap(18).child(main).when(Boolean(changes), (el) => el.child(changes)));
  }

  legend(t) {
    return h_flex().flex_none().gap(8).items_center().flex_wrap()
      .children(["added", "removed", "moved", "same"].map((status) => tag(t, status.charAt(0).toUpperCase() + status.slice(1), status === "same" ? "neutral" : status)));
  }

  tourCard(t, section) {
    const running = this.tour?.section.id === section.id;
    return v_flex().flex_none().gap(8).p(14).rounded(10).bg(t.surface).border(1).border_color(running ? t.accent : t.border)
      .child(h_flex().gap(8).items_center()
        .child(div().flex_1().min_w(0).text_size(14).font_semibold().text_color(t.foreground).child(section.title ?? "Tour"))
        .child(tag(t, typeLabel(section.type), "info")))
      .when(Boolean(section.reason), (el) => el.child(rich(`aqua-tour-${section.id}`, section.reason, 12)))
      .child(div().text_size(11).text_color(t.dim).child(`${(section.chapters ?? []).length} chapters · opens each section in order`))
      .child(div().text_size(10).text_color(t.dim).child(TOUR_NOTICE))
      .child(h_flex().gap(6).child(button(t, `aqua-tour-start-${section.id}`, running ? "Restart" : "Start", (cx) => this.showChapter(section, 0, cx))));
  }

  tourNote(t, chapter) {
    return v_flex().flex_none().gap(4).p(12).rounded(8).bg(t.raised).border_l(3).border_color(t.accent)
      .child(div().text_size(12.5).font_semibold().text_color(t.foreground).child(chapter.title ?? ""))
      .when(Boolean(chapter.hint), (el) => el.child(div().text_size(10.5).text_color(t.dim).child(chapter.hint)))
      .when(Boolean(chapter.body), (el) => el.child(rich(`aqua-chapter-${chapter.id ?? chapter.target}`, chapter.body, 12)));
  }

  visual(t, visual, id) {
    if (visual?.type === "compare") return h_flex().flex_none().gap(10).items_start().flex_wrap()
      .children((visual.panes ?? []).map((pane, index) => v_flex().flex_1().min_w(200).gap(6).p(10).rounded(8).bg(t.background).border(1).border_color(t.border)
        .child(eyebrow(t, pane.label ?? ""))
        .child(stepList(t, `aqua-visual-${id}-${index}`, pane.lines ?? []))));
    return div().text_size(11).text_color(t.dim).child(`${visual?.label ?? "Figure"} · story figures aren't ported yet`);
  }

  stopCard(t, stop, index, sections) {
    const id = stop.section, open = !this.collapsed.has(id), section = sections.get(id);
    const info = section ? brief(section) : null;
    const chapter = this.tour ? this.tour.section.chapters?.[this.tour.index] : null;
    const head = h_flex().id(`aqua-stop-${id}`).gap(10).items_center().cursor_pointer()
      .on_click((_event, cx) => { open ? this.collapsed.add(id) : this.collapsed.delete(id); cx.notify(); })
      .child(div().w(10).flex_none().text_size(10).text_color(t.dim).child(open ? "▾" : "▸"))
      .child(div().flex_none().font_family(mono()).text_size(11).text_color(info ? hue(t, info.hue) : t.dim).child(String(index + 1).padStart(2, "0")))
      .child(div().flex_1().min_w(0).text_size(14).font_semibold().text_color(t.foreground).child(stop.title ?? id))
      .when(Boolean(section), (el) => el.child(div().flex_none().text_size(10).text_color(t.dim).child(typeLabel(section.type))))
      .when(Boolean(info?.tag), (el) => el.child(tag(t, info.tag.label, info.tag.tone)));
    const card = v_flex().flex_none().gap(8).p(14).rounded(10).bg(t.surface).border(1)
      .border_color(chapter?.target === id ? t.accent : t.border)
      .child(head)
      .when(Boolean(stop.takeaway), (el) => el.child(div().pl(20).text_size(12).text_color(t.muted).child(stop.takeaway)));
    if (!open) return card;
    return card.child(v_flex().pl(20).gap(10)
      .when(Boolean(info?.summary), (el) => el.child(div().font_family(mono()).text_size(10.5).text_color(t.dim).child(info.summary)))
      .when(chapter?.target === id, (el) => el.child(this.tourNote(t, chapter)))
      .when(Boolean(stop.visual), (el) => el.child(this.visual(t, stop.visual, id)))
      .when(Boolean(stop.body), (el) => el.child(rich(`aqua-stop-body-${id}`, stop.body, 12)))
      .child(h_flex().gap(6).flex_wrap()
        .children((stop.inspections ?? []).map((entry, at) => button(t, `aqua-inspect-${id}-${at}`, `${entry.label} ↗`, () => this.inspect(entry.section))))
        .child(button(t, `aqua-collapse-${id}`, "Collapse", (cx) => { this.collapsed.add(id); cx.notify(); }, { ghost: true }))));
  }

  outline(t, list) {
    return v_flex().w(230).flex_none().h_full().min_h(0).border_r(1).border_color(t.border).bg(t.chrome)
      .child(v_flex().id("aqua-outline").flex_1().min_h(0).p(10).gap(1).overflow_y_scrollbar()
        .children(list.map((stop, index) => h_flex().id(`aqua-nav-${stop.section}`).gap(8).px(8).py(5).rounded(6).items_start().cursor_pointer()
          .hover((el) => el.bg(t.hover))
          .on_click((_event, cx) => this.focusStop(stop.section, cx))
          .child(div().w(18).flex_none().font_family(mono()).text_size(10).text_color(t.dim).child(String(index + 1).padStart(2, "0")))
          .child(div().flex_1().min_w(0).text_size(11.5).text_color(this.collapsed.has(stop.section) ? t.dim : t.muted).child(stop.title ?? stop.section)))))
      .child(h_flex().flex_none().p(10).gap(6).border_t(1).border_color(t.border)
        .child(button(t, "aqua-expand-all", "Expand all", (cx) => { this.collapsed = new Set(); cx.notify(); }))
        .child(button(t, "aqua-collapse-all", "Collapse all", (cx) => { this.collapsed = new Set(list.map((stop) => stop.section)); cx.notify(); })));
  }

  dock(t) {
    const { section, index } = this.tour, count = (section.chapters ?? []).length, chapter = section.chapters[index], last = index === count - 1;
    return h_flex().h(48).flex_none().px(14).gap(10).items_center().bg(t.chrome).border_t(1).border_color(t.accent)
      .child(button(t, "aqua-tour-back", "‹ Back", (cx) => this.showChapter(section, index - 1, cx), { disabled: index === 0 }))
      .child(v_flex().flex_1().min_w(0).gap(4)
        .child(div().truncate().text_size(11).text_color(t.muted).child(`${index + 1} / ${count} · ${chapter?.title ?? ""}`))
        .child(div().w_full().h(3).rounded_full().bg(t.border)
          .child(div().w(`${Math.round(((index + 1) / count) * 100)}%`).h(3).rounded_full().bg(t.accent))))
      .child(button(t, "aqua-tour-next", last ? "Finish" : "Next ›", (cx) => last ? (this.tour = null, cx.notify()) : this.showChapter(section, index + 1, cx), { pressed: true }))
      .child(button(t, "aqua-tour-exit", "Exit", (cx) => { this.tour = null; cx.notify(); }));
  }

  render(cx) {
    const t = theme();
    const doc = this.doc;
    const head = h_flex().h(42).flex_none().px(10).gap(7).items_center().bg(t.chrome)
      .border_b(1).border_color(t.border)
      .child(svg("mods/workspace-chrome/layers.svg").size(14).flex_none().text_color(t.accent))
      .child(div().flex_none().text_size(12.5).font_semibold().text_color(t.foreground).child("Aqua Cutter"))
      .child(h_flex().flex_1().min_w(0).h(28).px(7).items_center().rounded(6).bg(t.background)
        .border(1).border_color(t.border)
        .child(Input.new(this.input).flex_1().text_size(10.5).text_color(t.muted)))
      .child(button(t, "aqua-refresh", "Refresh", (cx) => this.open(this.path || this.input.value(), this.on, cx)))
      .child(button(t, "aqua-browse-toggle", "Browse", (cx) => this.browse(cx), { pressed: Boolean(this.browsing) }))
      .child(button(t, "aqua-latest", "Latest", (cx) => this.latest(cx)))
      .child(button(t, "aqua-example", "Example", (cx) => this.open(`${appHome()}/mods/aqua-cutter/example.json`, null, cx)));

    const content = v_flex().w_full().max_w(1000).min_w(0).gap(14);
    let list = [];
    if (this.loading) content.child(div().p(20).text_size(12).text_color(t.dim).child("Reading..."));
    else if (this.error) content.child(v_flex().gap(6).p(12).rounded(8).bg(t.surface).border(1).border_color(t.border)
      .child(div().text_size(12).text_color(t.blocked).child(this.error))
      .child(div().text_size(10.5).text_color(t.dim).child("Put a walkthrough under docs/pr/ in the focused space, paste its path above, or open Example.")));
    else if (this.markdown) {
      const markdown = this.markdown;
      content
        .child(div().text_size(10).text_color(t.dim).child(`Markdown · ${markdown.summary()} · ${this.on ? `${this.on}: ` : ""}${this.path}`))
        .children(markdown.render(t, Math.min(this.width - 40, 1000), this.page, (href, cx) => this.follow(href, cx),
          this.history.length ? (cx) => this.back(cx) : null, cx));
    }
    else if (!doc) content.child(div().p(20).text_size(12).text_color(t.dim).child("No walkthrough loaded."));
    else {
      const sections = new Map(doc.sections.map((section) => [section.id, section]));
      list = stops(doc);
      content
        .child(div().text_size(10).text_color(t.dim).child(`Walkthrough · schema ${doc.schemaVersion ?? "unknown"} · ${this.on ? `${this.on}: ` : ""}${this.path}`))
        .child(this.overview(t))
        .child(this.legend(t))
        .children(doc.sections.filter((section) => section.type === "tour").map((section) => this.tourCard(t, section)))
        .children(list.map((stop, index) => this.stopCard(t, stop, index, sections)));
      if (!list.length) content.child(sourceBox(t, "This walkthrough has no story stops or readable sections."));
    }
    const scroll = v_flex().id("aqua-body").flex_1().min_h(0).min_w(0).p(20).items_center().overflow_y_scrollbar().child(content);
    const wide = this.width >= 1100 && list.length > 0;
    return v_flex().size_full().min_h(0).bg(t.background).text_color(t.foreground)
      .on_size_change((size, cx) => { if (size.width > 0 && Math.abs(size.width - this.width) > 4) { this.width = size.width; cx.notify(); } })
      .child(head)
      .child(h_flex().flex_1().min_h(0)
        .when(Boolean(this.browsing), (el) => el.child(this.browsing.render(t, this.path, (file, cx) => this.choose(file, cx))))
        .when(wide && !this.browsing, (el) => el.child(this.outline(t, list)))
        .child(scroll))
      .when(Boolean(this.tour), (el) => el.child(this.dock(t)));
  }
}
