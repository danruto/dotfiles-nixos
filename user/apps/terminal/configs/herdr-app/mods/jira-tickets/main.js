import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { appHome, exec, props, readTextFile, shared, setShared, theme, window, layout } from "herdr";
import { normalizeFilters, filterRows, statusOptions } from "./filters.mjs";
import { isBlockVisible } from "./visibility.mjs";

const FILTERS = "jira-tickets.filters";

function dateLabel(value) {
  return Number.isFinite(Date.parse(value)) ? new Date(value).toISOString().slice(0, 16).replace("T", " ") + " UTC" : "Indexing date…";
}

export default class JiraTickets extends View {
  init(_props, cx) {
    this.rows = [];
    this.error = "";
    this.closed = false;
    this.loading = false;
    this.showStatuses = false;
    this.nextRefresh = Infinity;
    cx.spawn(async cx => {
      try {
        const initial = props() ?? {};
        this.config = Object.hasOwn(initial, "on") ? initial : JSON.parse(await readTextFile(appHome() + "/jira-tickets.json") || "null");
        if (!this.config || !(this.config.on === null || typeof this.config.on === "string")) throw new Error("Configure jira-tickets.json with the helper machine before refreshing.");
        this.nextRefresh = 0;
        this.refresh(cx, true);
      } catch (error) { this.error = String(error.message || error); cx.notify(); }
    });
    cx.timer.every(10000, cx => { if (Date.now() >= this.nextRefresh) this.refresh(cx, true); });
  }

  refresh(cx, automatic = false) {
    if (!this.config || this.loading || this.closed || (automatic && !isBlockVisible(layout(), props()?.layoutBlock))) return;
    this.loading = true;
    cx.notify();
    cx.spawn(async cx => {
      try {
        if (this.closed || (automatic && !isBlockVisible(layout(), props()?.layoutBlock))) return;
        const response = await exec("herdr-jira", ["refresh"], { on: this.config.on });
        if (this.closed) return;
        const data = JSON.parse(response.stdout || "{}");
        if (response.code !== 0 || !data.ok) throw new Error(data.error || response.stderr || "Jira refresh failed");
        if (!Array.isArray(data.rows) || !data.scope || !data.progress || !data.rows.every(row => /^[A-Z][A-Z0-9_]*-\d+$/.test(row.key) && typeof row.summary === "string")) throw new Error("Unexpected ticket feed format");
        this.rows = data.rows;
        this.feed = data;
        this.error = "";
        this.nextRefresh = Date.now() + (data.searching ? 1000 : 120000);
      } catch (error) {
        if (!this.closed) this.error = String(error.message || error);
        this.nextRefresh = Date.now() + 120000;
      } finally { this.loading = false; if (!this.closed) cx.notify(); }
    });
  }

  setFilters(patch) {
    setShared(FILTERS, normalizeFilters({ ...normalizeFilters(shared(FILTERS)), ...patch }));
  }

  toggleStatus(status) {
    const selected = normalizeFilters(shared(FILTERS)).statuses;
    this.setFilters({ statuses: selected.includes(status) ? selected.filter(value => value !== status) : [...selected, status] });
  }

  openTicket(row, cx) {
    if (!/^https:\/\/[a-z0-9-]+\.atlassian\.net\/browse\/[A-Z][A-Z0-9_]*-\d+$/.test(row.url)) { this.error = "Ticket link is not a Jira Cloud URL"; cx.notify(); return; }
    cx.spawn(async cx => {
      try {
        const response = await exec(window().platform === "macos" ? "open" : "xdg-open", [row.url]);
        if (response.code !== 0) throw new Error(response.stderr || "Could not open Jira");
      } catch (error) { if (!this.closed) { this.error = String(error.message || error); cx.notify(); } }
    });
  }

  close() { this.closed = true; }

  render() {
    const t = theme(), feed = this.feed, filters = normalizeFilters(shared(FILTERS));
    const rows = filterRows(this.rows, filters), statuses = statusOptions(this.rows);
    const chip = (text, colour = t.muted) => div().text_size(10).text_color(colour).child(text);
    const button = (id, text, action, active = false) => div().id(id).h(28).px(9).flex_none().flex().items_center().rounded(5).text_size(11).bg(active ? t.selected : t.chrome).text_color(active ? t.foreground : t.muted).cursor_pointer().hover(el => el.bg(t.hover)).on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_click((_e, cx) => action(cx)).child(text);
    const progress = !feed ? this.loading ? "Loading tickets…" : "Not connected" : feed.searching ? feed.progress.discovering ? "Finding recent tickets · partial results" : `Indexing ${Math.max(0, feed.progress.total - feed.progress.remaining)}/${feed.progress.total} · partial results` : feed.failed ? "Scan incomplete" : "Newest ticket update first";
    return v_flex().id("jira-tickets").size_full().min_w(0).min_h(0).bg(t.background).text_color(t.foreground)
      .child(h_flex().h(42).flex_none().px(12).gap(8).items_center().bg(t.chrome)
        .child(div().font_semibold().text_size(14).child("My Jira"))
        .child(div().flex_1().min_w(0).text_size(10).text_color(t.dim).truncate().child(this.config?.on || "This computer"))
        .child(button("jira-refresh", this.loading ? "Refreshing…" : "Refresh", cx => this.refresh(cx))))
      .child(h_flex().h(36).flex_none().px(8).gap(3).items_center().bg(t.chrome)
        .children(["All", "Assigned", "@mentions"].map(source => button(`jira-filter-${source}`, `${source} ${filterRows(this.rows, { ...filters, source }).length}`, () => this.setFilters({ source }), filters.source === source))))
      .child(h_flex().h(36).flex_none().px(8).gap(6).items_center().bg(t.chrome).border_b(1).border_color(t.border)
        .child(button("jira-statuses", `${filters.statuses.length ? `${filters.statuses.length} status${filters.statuses.length === 1 ? "" : "es"}` : "All statuses"} ${this.showStatuses ? "▴" : "▾"}`, cx => { this.showStatuses = !this.showStatuses; cx.notify(); }, this.showStatuses || filters.statuses.length > 0))
        .child(button("jira-hide-done", `${filters.hideDone ? "☑" : "☐"} Hide done`, () => this.setFilters({ hideDone: !filters.hideDone }), filters.hideDone)))
      .when(this.showStatuses, el => el.child(v_flex().id("jira-status-list").max_h(180).flex_none().overflow_y_scrollbar().p(6).gap(2).bg(t.chrome)
        .child(button("jira-all-statuses", "All statuses", () => this.setFilters({ statuses: [] }), !filters.statuses.length))
        .children(statuses.map((status, index) => button(`jira-status-${index}`, `${filters.statuses.includes(status) ? "☑" : "☐"} ${status}`, () => this.toggleStatus(status), filters.statuses.includes(status))))))
      .child(v_flex().flex_none().px(12).py(8).gap(4)
        .child(div().text_size(10).text_color(t.muted).child(feed ? `Mentions: ${feed.scope.projects.join(", ")} · ${feed.scope.days}-day ticket window` : "Assigned tickets and exact account @mentions"))
        .child(div().id("jira-progress").text_size(10).text_color(t.dim).child(`${progress}${feed?.failed ? ` · ${feed.failed} unreadable tickets` : ""}`))
        .when(filters.hideDone && this.rows.some(row => !row.statusCategory), el => el.child(div().text_size(10).text_color(t.blocked).child("Some status categories are still loading; those tickets stay visible."))))
      .when(Boolean(this.error), el => el.child(div().id("jira-error").px(12).py(8).text_size(11).text_color(t.blocked).child(`Refresh failed: ${this.error}${this.rows.length ? " · showing the last successful results" : ""}`)))
      .child(v_flex().id("jira-list").flex_1().min_h(0).overflow_y_scrollbar().px(8).gap(5)
        .children(rows.map(row => v_flex().id(`jira-ticket-${row.key}`).h(row.mentioned ? 110 : 90).flex_none().px(10).py(9).gap(6).rounded(7).bg(t.surface).cursor_pointer().hover(el => el.bg(t.hover)).on_click((_e, cx) => this.openTicket(row, cx))
          .child(h_flex().gap(7).items_center().child(div().text_size(11).font_semibold().text_color(t.accent).child(row.key))
            .child(div().flex_1().min_w(0).truncate().text_size(10).text_color(t.muted).child(row.status))
            .when(row.assigned, el => el.child(chip("Assigned", t.working))).when(row.mentioned, el => el.child(chip("@", t.blocked))))
          .child(div().text_size(12).truncate().child(row.summary))
          .child(div().text_size(9).text_color(t.dim).child(`Updated ${dateLabel(row.updated)}`))
          .when(row.mentioned, el => el.child(div().text_size(9).text_color(t.dim).child(`Mention comment ${dateLabel(row.mentionAt)}`)))))
        .when(!rows.length, el => el.child(div().p(12).text_size(11).text_color(t.dim).child(this.loading || feed?.searching ? "Results will appear as the scan progresses." : "No tickets match these filters."))))
      .child(div().h(26).flex_none().px(12).flex().items_center().text_size(9).text_color(t.dim).truncate().child(feed ? `${rows.length}/${this.rows.length} tickets · checked ${dateLabel(feed.checkedAt)}` : "Credentials and cache stay on the helper machine"));
  }
}
