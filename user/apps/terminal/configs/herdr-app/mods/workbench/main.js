// The workbench sidebar: cockpit's shape (search, view strip, agents grouped by
// space, spaces by machine) without cockpit's hub. It also switches the center
// stack and carries the per-machine system readout and the workspace footer.

import { View, div, svg, image } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import {
  spaces, agents, panes, terminals, machines, focused, theme, run, shared, hc,
  openOverlay, layout, window, exec,
} from "herdr";
import { parseLinux, parseWindows } from "./sysinfo.mjs";

const LINUX = "cat /proc/loadavg; nproc; free -b | head -2; df -B1 / | tail -1";
const WINDOWS = "$c=(Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average; $o=Get-CimInstance Win32_OperatingSystem; $d=Get-PSDrive C; [pscustomobject]@{cpu=[math]::Round($c); memUsed=($o.TotalVisibleMemorySize-$o.FreePhysicalMemory)*1KB; memTotal=$o.TotalVisibleMemorySize*1KB; diskUsed=$d.Used; diskTotal=($d.Used+$d.Free)} | ConvertTo-Json -Compress";
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };
const VIEWS = [
  { id: "terminal", label: "Terminal", icon: "wb-icons/terminal.svg" },
  { id: "jira", label: "Jira", icon: "wb-icons/jira.svg" },
  { id: "github", label: "GitHub issues", icon: "wb-icons/github.svg" },
  { id: "aqua", label: "Aqua Cutter", icon: "wb-icons/aqua.svg" },
  { id: "files", label: "Files", icon: "mods/files/file.svg" },
  { id: "changes", label: "Changes", icon: "mods/changes/changes.svg" },
];

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

const short = (ms) => {
  if (!Number.isFinite(ms)) return "";
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
};

const machineLabel = (name) => name ?? "This computer";

export default class Workbench extends View {
  init(_props, cx) {
    this.folded = new Set(JSON.parse(localStorage.getItem("workbench.folded") ?? "[]"));
    this.sys = {};
    this.sampling = false;
    this.foreground = {};
    this.busySampling = false;
    this.place = null;
    this.sample(cx);
    this.sampleBusy(cx);
    cx.timer.every(10000, (cx) => this.sample(cx));
    cx.timer.every(5000, (cx) => this.sampleBusy(cx));
  }

  view() {
    return find(layout(), "center")?.active ?? "terminal";
  }

  show(view) {
    run("layout.select", { stack: "center", child: view });
  }

  fold(key, cx) {
    if (this.folded.has(key)) this.folded.delete(key); else this.folded.add(key);
    localStorage.setItem("workbench.folded", JSON.stringify([...this.folded]));
    cx.notify();
  }

  async readMachine(name) {
    if (!name) {
      if (window()?.platform === "windows") {
        const r = await exec("powershell", ["-NoProfile", "-Command", WINDOWS]);
        return parseWindows(r.stdout.trim());
      }
      const r = await exec("sh", ["-c", LINUX]);
      return parseLinux(r.stdout);
    }
    const r = await exec("sh", ["-c", LINUX], { on: name });
    return parseLinux(r.stdout);
  }

  sample(cx) {
    if (this.sampling) return;
    this.sampling = true;
    cx.spawn(async (cx) => {
      for (const machine of machines()) {
        const key = machine.name ?? "";
        if (machine.layout === "unavailable") { this.sys[key] = null; continue; }
        try { this.sys[key] = await this.readMachine(machine.name); }
        catch { this.sys[key] = null; }
      }
      this.sampling = false;
      cx.notify();
    });
  }

  sampleBusy(cx) {
    if (this.busySampling) return;
    this.busySampling = true;
    cx.spawn(async (cx) => {
      const list = agents();
      const shells = new Set(["fish", "bash", "zsh", "sh", "pwsh", "powershell", "cmd", "nu", "elvish", "xonsh"]);
      const agentish = /claude|codex|opencode|gemini|aider|cursor|goose|amp/;
      for (const agent of list) {
        try {
          const result = await hc(["get", agent.address]);
          const data = JSON.parse(result.stdout || "{}");
          const foreground = data.foreground ?? null;
          const raw = foreground?.name || foreground?.argv?.[0] || "";
          const name = String(raw).split(/[\\/]/).pop() || "";
          const key = name.toLowerCase().replace(/\.(exe|sh|cmd)$/, "");
          this.foreground[agent.address] = {
            name,
            shell: shells.has(key),
            agent: agentish.test(key),
            at: Date.now(),
          };
        } catch {
          delete this.foreground[agent.address];
        }
      }
      this.busySampling = false;
      cx.notify();
    });
  }


  icon(path, size = 14, color = null) {
    const file = path.endsWith(".svg") ? path : `mods/${path}.svg`;
    const node = svg(file).size(size).flex_none();
    return color ? node.text_color(color) : node;
  }

  dot(status) {
    const t = theme();
    return status === "working"
      ? svg("mods/workspace-chrome/spinner.svg").size(11).flex_none().text_color(t.working).spin(1000)
      : div().size(6).flex_none().rounded_full().bg(t[status] ?? t.dim);
  }

  chevron(open, t) {
    return this.icon(open ? "workspace-chrome/chevron-down" : "workspace-chrome/chevron-right", 12, t.dim);
  }

  header(id, label, count, open, extra, t, sectionIcon) {
    const row = h_flex().id(id).h(34).flex_1().px(9).gap(8).items_center().rounded(8)
      .bg(t.surface).cursor_pointer().hover((el) => el.bg(t.raised))
      .child(this.chevron(open, t))
      .when(Boolean(sectionIcon), (el) => el.child(this.icon(sectionIcon, 13, t.muted)))
      .child(div().text_size(11.5).font_semibold().text_color(t.muted).child(label))
      .child(h_flex().h(18).min_w(18).px(5).items_center().justify_center().rounded(9)
        .bg(t.raised).text_size(10).font_semibold().text_color(t.dim).child(String(count)));
    return h_flex().children(extra ? [row, div().flex_1(), extra] : [row]);
  }

  spaceMenu(space) {
    openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "space", target: { id: space.id } } });
  }

  tabMenu(space, tab) {
    openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: { id: tab.id, space: space.id } } });
  }

  agentRow(agent, t) {
    const space = spaces().find((candidate) => candidate.id === agent.space);
    const tab = space?.tabs.find((candidate) => candidate.id === agent.tab);
    const children = terminals().filter((term) => term.parent === agent.address && term.state === "live" && term.address !== agent.address);
    const since = short(Date.now() - ((agent.status === "working" ? tab?.working_since : null) ?? tab?.changed_at));
    const title = (tab?.named && tab.name) || agent.title || tab?.name || agent.program?.name || agent.tab_name || "agent";
    const program = agent.program;
    const glyph = program?.icon
      ? (program.tint ? svg(program.icon).size(12).flex_none().text_color(t.dim) : image(program.icon).w(12).h(12).flex_none())
      : null;
    const foreground = this.foreground[agent.address];
    const busy = agent.status !== "blocked" && foreground && !foreground.agent;
    const state = busy ? (foreground.shell ? "waiting" : "working") : agent.status;
    const label = state === "waiting" ? "Waiting"
      : state === "working" ? "Working"
        : { blocked: "Needs you", done: "Ready", idle: "Idle" }[agent.status] ?? "Idle";
    const tone = busy ? t.working : t[agent.status] ?? t.dim;
    const row = v_flex().id(`wb-agent-${agent.address}`).py(5).px(8).gap(2).flex_none().rounded(6)
      .when(tab?.active && space?.active, (el) => el.bg(t.selected))
      .hover((el) => el.bg(t.hover)).cursor_pointer()
      .tooltip(foreground ? `Foreground: ${foreground.name}` : title)
      .on_click(() => {
        run("agent.focus", { terminal: agent.address });
        if (panes().some((candidate) => candidate.terminal === agent.address)) run("pane.focus", { terminal: agent.address });
        this.show("terminal");
      })
      .on_mouse_down("right", () => tab && space && this.tabMenu(space, tab))
      .child(h_flex().gap(7).items_center().min_w(0)
        .child(this.dot(busy ? "working" : agent.status))
        .when(Boolean(glyph), (el) => el.child(glyph))
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.foreground).child(title))
        .when(Boolean(since), (el) => el.child(div().flex_none().text_size(10).text_color(t.dim).child(since))))
      .child(h_flex().gap(5).items_center().min_w(0).pl(16)
        .child(div().flex_none().text_size(10).text_color(tone).child(label))
        .when(busy && Boolean(foreground?.name), (el) => el.child(div().flex_none().text_size(10).text_color(t.dim).child("-"))
          .child(div().min_w(0).truncate().text_size(10).text_color(t.dim).child(foreground.name))));
    return v_flex().flex_none().gap(1)
      .child(row)
      .children(children.map((child) => h_flex().id(`wb-child-${child.address}`).h(24).pl(30).pr(8)
        .gap(6).flex_none().items_center().rounded(6).hover((el) => el.bg(t.hover)).cursor_pointer()
        .tooltip("Peek at this agent")
        .on_click(() => run("terminal.peek", { terminal: child.address }))
        .child(div().flex_none().text_size(10).text_color(t.dim).child("↳"))
        .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim)
          .child(child.name || child.agent || "task"))
        .child(div().flex_none().text_size(9.5).text_color(t[child.status] ?? t.dim)
          .child(child.status === "working" ? "Working" : child.status ?? ""))));
  }

  agentsSection(t) {
    const all = agents();
    const order = { blocked: 0, working: 1, done: 2, idle: 3 };
    const rows = [...all].sort((a, b) => (order[a.status] ?? 4) - (order[b.status] ?? 4)
      || (a.space ?? "").localeCompare(b.space ?? "")
      || a.tab_index - b.tab_index);
    const open = !this.folded.has("agents");
    const blocked = all.filter((agent) => agent.status === "blocked").length;
    const extra = blocked
      ? h_flex().flex_none().gap(4).items_center().text_size(10).text_color(t.blocked)
          .child(div().size(6).rounded_full().bg(t.blocked)).child(String(blocked))
      : null;
    return v_flex().flex_none().gap(1)
      .child(this.header("wb-agents", "Agents", all.length, open, extra, t, "workspace-chrome/layers")
        .on_click((_e, cx) => { this.fold("agents", cx); }))
      .when(open, (el) => el.children(rows.map((agent) => this.agentRow(agent, t)))
        .when(!rows.length, (inner) => inner.child(div().px(8).py(8).text_size(11).text_color(t.dim)
          .child("No agents running."))));
  }

  machineRow(machine, mine, t) {
    const key = machine.name ?? "local";
    const open = !this.folded.has(`m:${key}`);
    const info = this.sys[machine.name ?? ""];
    const ready = machine.layout !== "unavailable";
    const stats = info
      ? [["CPU", info.cpu], ["MEM", info.mem], ["DSK", info.disk]]
        .filter(([, value]) => value != null)
        .map(([label, value]) => h_flex().gap(4).items_center()
          .child(div().text_size(10).text_color(t.dim).child(label))
          .child(div().text_size(10.5).font_semibold()
            .text_color(value >= 85 ? t.blocked : value >= 65 ? t.working : t.done).child(`${value}%`)))
      : [];
    const row = h_flex().id(`wb-machine-${key}`).py(5).px(10).gap(6).flex_none().items_center().rounded(6)
      .hover((el) => el.bg(t.hover))
      .child(h_flex().flex_1().min_w(0).gap(6).items_center().cursor_pointer()
        .on_click((_e, cx) => { this.fold(`m:${key}`, cx); })
        .child(this.chevron(open, t))
        .child(this.icon(machine.name ? "workspace-chrome/server" : "workspace-chrome/monitor", 12, t.dim))
        .child(v_flex().flex_1().min_w(0).gap(2)
          .child(div().text_size(12).text_color(t.muted).truncate().child(machineLabel(machine.name)))
          .when(stats.length > 0, (el) => el.child(h_flex().gap(9).items_center().children(stats)))
          .when(!ready, (el) => el.child(div().text_size(9.5).text_color(t.blocked).child("offline")))))
      .child(div().id(`wb-new-${key}`).size(22).flex_none().flex().items_center().justify_center()
        .rounded(6).text_color(t.dim).cursor_pointer().hover((style) => style.bg(t.raised).text_color(t.foreground))
        .tooltip(`New space on ${machineLabel(machine.name)}`)
        .on_click(() => run("space.new", { machine: machine.name ?? "" })).child("+"));
    return v_flex().flex_none().gap(1).mb(1)
      .child(row)
      .when(open, (el) => el.children(mine.map((space) => h_flex().id(`wb-space-${space.id}`)
        .h(30).pl(30).pr(10).gap(8).flex_none().items_center().rounded(6)
        .when(space.active, (style) => style.bg(t.selected))
        .hover((style) => style.bg(t.hover)).cursor_pointer()
        .on_click(() => {
          run("space.select", { id: space.id });
          this.show("terminal");
        })
        .on_mouse_down("right", () => this.spaceMenu(space))
        .child(div().size(6).flex_none().rounded_full().bg(this.spaceColor(space, t)))
        .child(div().flex_1().min_w(0).truncate().text_size(12)
          .text_color(space.active ? t.foreground : t.muted).child(space.name))
        .when(Boolean(space.status), (el) => el.child(this.dot(space.status))))));
  }

  spaceColor(space, t) {
    const color = (shared("space.colors") ?? {})[space.id] ?? "ansi6";
    return color.startsWith("#") ? color : (MARK[color] ?? t[color]);
  }

  spacesSection(t) {
    const list = machines();
    if (!list.some((machine) => machine.name === null)) list.unshift({ name: null, layout: "ready" });
    const all = spaces();
    const open = !this.folded.has("spaces");
    return v_flex().flex_none().gap(1).mb(8)
      .child(this.header("wb-spaces", "Spaces", all.length, open, null, t, "workspace-chrome/monitor")
        .on_click((_e, cx) => { this.fold("spaces", cx); }))
      .when(open, (el) => el.children(list.map((machine) => {
        const mine = all.filter((space) => (space.machine ?? null) === machine.name);
        return this.machineRow(machine, mine, t);
      })));
  }

  footer(t) {
    const space = spaces().find((candidate) => candidate.active);
    const host = spaces().filter((candidate) => (candidate.machine ?? null) === (space?.machine ?? null)).length;
    return v_flex().flex_none().gap(2)
      .child(h_flex().px(8).pt(6).gap(2).items_center()
        .child(div().id("wb-add-machine").flex_1().px(6).py(4).rounded(6).text_size(10.5)
          .text_color(t.muted).cursor_pointer().hover((el) => el.bg(t.raised).text_color(t.foreground))
          .on_click(() => run("mod.open", { name: "machine-add" })).child("+ Add machine"))
        .child(div().id("wb-manage").px(6).py(4).rounded(6).text_size(10.5).text_color(t.dim)
          .cursor_pointer().hover((el) => el.bg(t.raised).text_color(t.foreground))
          .on_click(() => run("app.settings", { section: "machines" })).child("Manage")))
      .child(h_flex().id("wb-space-card").m(8).mt(2).px(10).h(48).flex_none().gap(9).items_center()
        .rounded(12).bg(t.surface).border(1).border_color(t.border).cursor_pointer()
        .hover((el) => el.bg(t.raised))
        .on_click(() => run("mod.open", { name: "picker" }))
        .child(div().size(26).flex_none().rounded(8).bg(t.raised).flex().items_center().justify_center()
          .child(this.icon("workspace-chrome/folder", 13, t.muted)))
        .child(v_flex().flex_1().min_w(0).gap(2)
          .child(div().text_size(12.5).font_semibold().text_color(t.foreground).truncate()
            .child(space?.name ?? "Workspace"))
          .child(div().text_size(10).text_color(t.dim).truncate()
            .child(`${machineLabel(space?.machine ?? null)} · ${host} workspace${host === 1 ? "" : "s"}`))));
  }

  render() {
    const t = theme();
    const current = this.view();
    const f = focused();
    const place = f ? `${f.space}/${f.tab}` : null;
    if (this.place !== null && place !== this.place && current !== "terminal") this.show("terminal");
    this.place = place;

    const search = h_flex().id("wb-search").h(32).flex_none().mb(8).px(10).gap(8).items_center().rounded(8)
      .border(1).border_color(t.input).bg(t.background).cursor_pointer()
      .hover((el) => el.border_color(t.accent))
      .on_click(() => run("app.palette"))
      .child(this.icon("workspace-chrome/search", 13, t.dim))
      .child(div().flex_1().text_size(12).text_color(t.dim).child("Search or run..."))
      .child(div().px(5).py(2).rounded(4).bg(t.raised).text_size(9.5).text_color(t.dim)
        .child(window()?.platform === "macos" ? "Cmd P" : "Ctrl P"));

    const strip = h_flex().id("wb-views").gap(2).p(3).flex_none().mb(8).rounded(10).bg(t.surface)
      .children(VIEWS.map((view) => {
        const on = current === view.id;
        return h_flex().id(`wb-view-${view.id}`).flex_1().h(30).relative().items_center().justify_center()
          .rounded(7).cursor_pointer().text_color(on ? t.foreground : t.muted)
          .when(on, (el) => el.bg(t.background))
          .when(!on, (el) => el.hover((style) => style.bg(t.hover).text_color(t.foreground)))
          .tooltip(view.label)
          .on_click(() => this.show(view.id))
          .child(this.icon(view.icon, 18, on ? t.foreground : t.muted));
      }));

    return v_flex().id("wb-root").size_full().min_h(0).bg(t.chrome).text_size(12)
      .px(8).pt(6)
      .child(search)
      .child(strip)
      .child(div().h(1).flex_none().mb(6).bg(t.border))
      .child(v_flex().id("wb-scroll").flex_1().min_h(0).gap(2).overflow_y_scrollbar()
        .child(this.agentsSection(t)))
      .child(div().h(1).flex_none().my(4).bg(t.border))
      .child(this.spacesSection(t))
      .child(this.footer(t));
  }
}
