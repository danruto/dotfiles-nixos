import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex, InputState, Input } from "gpui-base";
import { spaces, agents, panes, focused, theme, run, props, window, layout, shared, setShared, setAgentOrder, openOverlay } from "herdr";
import { threadGroups, statusLabel } from "./model.js";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const stop = (_event, cx) => cx.stop_propagation();

export default class Threads extends View {
  init(_props, cx) {
    this.query = "";
    this.settled = false;
    if (!props()?.part) {
      this.input = InputState.new({ placeholder: "Search threads…" });
      this.input.on("change", (_event, cx) => { this.query = this.input.value(); cx.notify(); });
      this.input.on("submit", () => {
        const first = this.groups(false)[0]?.threads[0] ?? this.groups(true)[0]?.threads[0];
        if (first) run("tab.select", { id: first.tab.id });
      });
    }
  }

  groups(settled) {
    return threadGroups(spaces(), agents(), panes(), shared("t3-threads.pins") ?? [], this.query, settled);
  }

  button(id, label, action, active = false, hint = "") {
    const t = theme();
    return h_flex().id(id).h(28).px(8).gap(5).flex_none().items_center().justify_center().rounded(6)
      .text_size(12).text_color(active ? t.accent : t.muted).when(active, el => el.bg(t.selected))
      .hover(el => el.bg(t.hover).text_color(t.foreground)).cursor_pointer()
      .when(Boolean(hint), el => el.tooltip(hint).accessibility_label(hint))
      .on_mouse_down("left", stop).on_click((event, cx) => { cx.stop_propagation(); action(); }).child(label);
  }

  icon(name, size = 14) {
    const path = { jira: "jira-tickets/ticket", changes: "changes/changes", split: "pane/split-down", settle: "workspace-chrome/archive", restore: "workspace-chrome/chevron-left" }[name] ?? `workspace-chrome/${name}`;
    return svg(`mods/${path}.svg`).size(size).flex_none();
  }

  status(status) {
    const t = theme();
    return status === "working"
      ? svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(1000)
      : div().size(6).mx(3).flex_none().rounded_full().bg(t[status] ?? t.dim);
  }

  newThread(space) {
    if (space) run("space.select", { id: space.id });
    openOverlay({ mod: "new-menu", kind: "popup", width: 250, height: 512 });
  }

  pin(id) {
    const pins = shared("t3-threads.pins") ?? [];
    setShared("t3-threads.pins", pins.includes(id) ? pins.filter(pin => pin !== id) : [...pins, id]);
  }

  thread(space, thread) {
    const t = theme(), { tab, title, branch, pinned } = thread;
    const active = space.active && tab.active;
    return h_flex().id(`thread-${tab.id}`).min_h(54).px(9).py(7).gap(9).items_center().rounded(8)
      .bg(active ? t.selected : t.chrome).hover(el => el.bg(t.hover)).cursor_pointer()
      .on_hover((hovered, cx) => { this.hovered = hovered ? tab.id : null; cx.notify(); })
      .on_click(() => run("tab.select", { id: tab.id }))
      .on_mouse_down("right", () => openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: { id: tab.id, space: space.id } } }))
      .child(this.status(tab.status))
      .child(v_flex().flex_1().min_w(0).gap(5)
        .child(div().text_size(13).text_color(active ? t.foreground : t.muted).truncate().child(title))
        .child(h_flex().gap(5).items_center().text_size(10.5).text_color(t.dim)
          .child(div().text_color(t[tab.status] ?? t.dim).child(statusLabel(tab.status)))
          .when(Boolean(branch), el => el.child(div().child("·")).child(div().flex_1().min_w(0).truncate().child(branch)))))
      .when(pinned || active || this.hovered === tab.id, el => el.child(this.button(`pin-${tab.id}`, this.icon("pin", 12), () => this.pin(tab.id), pinned, pinned ? "Unpin thread" : "Pin thread")))
      .when(active || this.hovered === tab.id, el => el.child(this.button(`settle-${tab.id}`, this.icon(tab.settled ? "restore" : "settle", 13), () => run(tab.settled ? "tab.unsettle" : "tab.settle", { id: tab.id }), false, tab.settled ? "Unsettle thread" : "Settle thread")));
  }

  group(group) {
    const t = theme(), { space, threads } = group;
    const key = `${space.id}-${threads[0].tab.settled ? "settled" : "open"}`;
    return v_flex().gap(2).mb(12)
      .child(h_flex().id(`project-${key}`).h(30).px(8).gap(7).items_center().text_size(11).text_color(t.muted)
        .on_mouse_down("right", () => openOverlay({ mod: "menu", kind: "popup", width: 230, props: { tab: "space", target: { id: space.id } } }))
        .child(this.icon("folder", 13))
        .child(div().id(`select-${key}`).flex_1().min_w(0).truncate().font_semibold().cursor_pointer().on_click(() => run("space.select", { id: space.id })).child(space.name))
        .when(Boolean(space.machine), el => el.child(div().max_w(66).truncate().text_size(10).text_color(t.dim).child(space.machine)))
        .child(this.button(`new-${key}`, "+", () => this.newThread(space), false, "New thread in this project")))
      .children(threads.map(thread => this.thread(space, thread)));
  }

  heading() {
    const t = theme(), space = spaces().find(space => space.active), tab = space?.tabs.find(tab => tab.active);
    const current = this.groups(Boolean(tab?.settled)).find(group => group.space.id === space?.id)?.threads.find(thread => thread.tab.id === tab?.id);
    const panel = find(layout(), "panel"), body = find(layout(), "panel-body");
    const panelButton = (id, label, icon) => {
      const on = panel && !panel.hidden && body?.active === id;
      return this.button(`show-${id}`, h_flex().gap(5).items_center().child(this.icon(icon)).child(label), () => {
        if (on) run("layout.hide", { id: "panel" });
        else {
          run("layout.select", { stack: "panel-body", child: id });
          run("layout.show", { id: "panel" });
        }
      }, on);
    };
    return h_flex().size_full().min_w(0).px(12).gap(8).items_center().bg(t.background).border_b(1).border_color(t.border)
      .when(window()?.platform === "macos" && find(layout(), "sidebar")?.hidden, el => el.pl(80))
      .child(this.button("toggle-sidebar", this.icon("sidebar"), () => run("layout.toggle", { id: "sidebar" }), false, "Toggle sidebar"))
      .child(h_flex().flex_1().min_w(0).gap(8).items_center().text_size(12.5)
        .child(div().max_w(180).truncate().text_color(t.muted).child(space?.name ?? "Herdr"))
        .child(div().text_color(t.dim).child("/"))
        .child(div().min_w(0).truncate().font_semibold().text_color(t.foreground).child(current?.title ?? tab?.name ?? "Terminal")))
      .when(Boolean(tab?.status), el => el.child(this.status(tab.status)))
      .child(panelButton("files", "Files", "folder"))
      .child(panelButton("changes", "Changes", "changes"))
      .child(panelButton("jira", "Jira", "jira"))
      .when(Boolean(focused()?.pane), el => el.child(this.button("split", this.icon("split"), () => run("pane.split", { direction: "down" }), false, "Split terminal below")))
      .when(window()?.buttons, el => el.child(this.button("minimize", "−", () => run("window.minimize")))
        .child(this.button("maximize", "□", () => run("window.maximize")))
        .child(this.button("close-window", "×", () => run("window.close"))));
  }

  render() {
    const t = theme(), part = props()?.part;
    if (part === "brand") {
      return h_flex().size_full().pl(window()?.platform === "macos" ? 80 : 16).pr(10).gap(8).items_center().bg(t.chrome)
        .child(div().text_size(14).font_semibold().text_color(t.foreground).child("Herdr"))
        .child(div().flex_1().text_size(11).text_color(t.dim).child("/ threads"))
        .child(this.button("palette", this.icon("search"), () => run("app.palette"), false, "Command palette"));
    }
    if (part === "head") return this.heading();
    if (part === "footer") {
      return h_flex().size_full().px(8).gap(4).items_center().bg(t.chrome).border_t(1).border_color(t.border)
        .child(this.button("settings", h_flex().gap(6).items_center().child(this.icon("settings")).child("Settings"), () => run("app.settings")))
        .child(div().flex_1())
        .child(this.button("layouts", "Layouts", () => run("app.settings", { section: "look" })))
        .child(this.button("help", "?", () => run("app.help")));
    }
    const open = this.groups(false), settled = this.groups(true), all = spaces().flatMap(space => space.tabs);
    const count = all.filter(tab => !tab.settled).length, needs = all.filter(tab => tab.status === "blocked").length;
    const ordered = [...open, ...(this.settled || this.query ? settled : [])].flatMap(group => group.threads.flatMap(thread => thread.agents.map(agent => agent.address)));
    setAgentOrder(ordered);
    return v_flex().size_full().min_h(0).bg(t.chrome).px(10).gap(10)
      .child(h_flex().id("new-thread").h(36).px(10).gap(8).flex_none().items_center().rounded(8).bg(t.selected).text_color(t.accent).text_size(12.5).font_semibold()
        .hover(el => el.bg(t.hover)).cursor_pointer().on_click(() => this.newThread()).child("+").child("New thread")
        .child(div().flex_1()).child(div().text_size(10).text_color(t.dim).child("agent or shell")))
      .child(h_flex().h(32).flex_none().px(8).gap(7).items_center().rounded(7).border(1).border_color(t.border).text_color(t.dim)
        .child(this.icon("search", 13)).child(Input.new(this.input).flex_1().text_size(12).text_color(t.foreground)))
      .child(h_flex().px(7).items_center().justify_between().text_size(10.5).text_color(t.dim)
        .child(`${count} open thread${count === 1 ? "" : "s"}`)
        .when(needs > 0, el => el.child(div().text_color(t.blocked).child(`${needs} need you`))))
      .child(v_flex().id("thread-list").flex_1().min_h(0).gap(2).overflow_y_scrollbar()
        .children(open.map(group => this.group(group)))
        .when(!open.length, el => el.child(div().px(8).py(18).text_size(12).text_color(t.dim).child(this.query ? "No matching open threads" : "No open threads. Start something new.")))
        .when(settled.length > 0, el => el.child(h_flex().id("settled-shelf").h(32).px(8).gap(7).items_center().text_size(11).text_color(t.dim).hover(el => el.text_color(t.foreground)).cursor_pointer()
          .on_click((_event, cx) => { this.settled = !this.settled; cx.notify(); })
          .child(this.settled || this.query ? "▾" : "▸").child(`Settled · ${settled.reduce((count, group) => count + group.threads.length, 0)}`)))
        .when(this.settled || Boolean(this.query), el => el.children(settled.map(group => this.group(group)))))
      .child(this.button("add-project", h_flex().gap(7).items_center().child(this.icon("folder")).child("Add project"), () => run("space.new")))
      .child(div().h(2).flex_none());
  }
}
