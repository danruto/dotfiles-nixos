// Browse: a lazy file tree of the focused session's repository (its Git top level, or the
// session folder outside Git), on whichever machine the session runs. Walkthrough JSON and
// Markdown open in the page; other files are shown for orientation only.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { exec, window } from "herdr";

const PER_FOLDER = 500;
export const openable = (name) => /\.(?:md|markdown|json)$/i.test(name);

// The listing script from Herdr's Files mod: name and kind per entry, .git skipped.
async function directory(path, on) {
  if (!on && window()?.platform === "windows") {
    const r = await exec("powershell", ["-NoProfile", "-Command", "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); & { param($p) @(Get-ChildItem -LiteralPath $p -Force -ErrorAction Stop | Where-Object Name -ne '.git' | Select-Object -First 501 | ForEach-Object { @{ name=$_.Name; dir=[bool]$_.PSIsContainer } }) | ConvertTo-Json -Compress } '" + path.replace(/['‘’‚‛]/g, "$&$&") + "'"]);
    if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
    const result = JSON.parse(r.stdout || "[]");
    return Array.isArray(result) ? result : [result];
  }
  const script = 'n=0; for p in "$1"/* "$1"/.[!.]* "$1"/..?*; do [ -e "$p" ] || [ -L "$p" ] || continue; name=${p##*/}; [ "$name" = .git ] && continue; if [ -d "$p" ]; then kind=d; else kind=f; fi; printf "%s\\0%s\\0" "$kind" "$name"; n=$((n+1)); [ "$n" -gt 500 ] && break; done; test -d "$1"';
  const r = await exec("sh", ["-c", script, "browse", path], { on });
  if (r.code !== 0) throw new Error(r.stderr || "Cannot list this folder");
  const fields = r.stdout.split("\0"), out = [];
  for (let i = 0; i + 1 < fields.length; i += 2) out.push({ name: fields[i + 1], dir: fields[i] === "d" });
  return out;
}

export class RepoBrowser {
  constructor(cwd, on) {
    this.cwd = cwd;
    this.on = on;
    this.root = null;
    this.entries = new Map();
    this.folders = new Set();
    this.pending = new Set();
    this.error = "";
  }

  // Finds the repository root, lists it, and opens the folders on the way to `current`.
  start(current, cx) {
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd: this.cwd, on: this.on }).catch(() => null);
        this.root = (top?.code === 0 && top.stdout.trim()) || this.cwd;
        const inside = current && current.startsWith(this.root + "/") ? current.slice(this.root.length + 1).split("/").slice(0, -1) : ["docs", "pr"];
        await this.load("");
        for (let depth = 1; depth <= inside.length; depth++) {
          const path = inside.slice(0, depth).join("/");
          if (!this.entries.get(inside.slice(0, depth - 1).join("/"))?.some((entry) => entry.dir && entry.name === inside[depth - 1])) break;
          this.folders.add(path);
          await this.load(path);
        }
      } catch (error) {
        this.error = String(error?.message ?? error);
      }
      cx.notify();
    });
  }

  async load(path) {
    const list = await directory(path ? `${this.root}/${path}` : this.root, this.on);
    this.entries.set(path, list.slice(0, PER_FOLDER).sort((a, b) => Number(b.dir) - Number(a.dir) || a.name.localeCompare(b.name)));
  }

  toggle(path, cx) {
    if (this.folders.has(path)) {
      for (const folder of [...this.folders]) if (folder === path || folder.startsWith(path + "/")) this.folders.delete(folder);
      cx.notify();
      return;
    }
    this.folders.add(path);
    if (!this.entries.has(path) && !this.pending.has(path)) {
      this.pending.add(path);
      cx.spawn(async (cx) => {
        try { await this.load(path); } catch (error) { this.error = String(error?.message ?? error); }
        this.pending.delete(path);
        cx.notify();
      });
    }
    cx.notify();
  }

  rows(t, prefix, depth, current, choose, out) {
    for (const entry of this.entries.get(prefix) ?? []) {
      const path = prefix ? `${prefix}/${entry.name}` : entry.name, full = `${this.root}/${path}`, open = this.folders.has(path);
      const usable = entry.dir || openable(entry.name);
      out.push(h_flex().id(`aqua-browse-${path}`).h(26).flex_none().pl(8 + depth * 16).pr(8).gap(6).items_center().rounded(6)
        .when(usable, (el) => el.cursor_pointer().hover((h) => h.bg(t.hover))
          .on_click((_event, cx) => entry.dir ? this.toggle(path, cx) : choose(full, cx)))
        .child(div().w(10).flex_none().text_size(10).text_color(t.dim).child(entry.dir ? (open ? "▾" : "▸") : ""))
        .child(div().flex_1().min_w(0).truncate().text_size(11.5)
          .text_color(full === current ? t.accent : entry.dir ? t.foreground : usable ? t.foreground : t.dim).child(entry.name))
        .when(this.pending.has(path), (el) => el.child(div().text_size(10).text_color(t.dim).child("…"))));
      if (entry.dir && open) this.rows(t, path, depth + 1, current, choose, out);
    }
    return out;
  }

  // A full-height panel down the page's left side.
  render(t, current, choose) {
    const name = this.root ? this.root.split(/[\\/]/).filter(Boolean).pop() : "";
    const list = v_flex().id("aqua-browse").flex_1().min_h(0).p(6).gap(1).overflow_y_scrollbar();
    if (this.error) list.child(div().p(8).text_size(11).text_color(t.blocked).child(this.error));
    else if (!this.root) list.child(div().p(8).text_size(11).text_color(t.dim).child("Finding the repository…"));
    else if (!this.entries.get("")?.length) list.child(div().p(8).text_size(11).text_color(t.dim).child("Empty folder"));
    else list.children(this.rows(t, "", 0, current, choose, []));
    return v_flex().w(300).flex_none().h_full().min_h(0).bg(t.chrome).border_r(1).border_color(t.border)
      .child(v_flex().flex_none().px(12).py(8).gap(2).border_b(1).border_color(t.border)
        .child(div().truncate().text_size(12.5).font_semibold().text_color(t.foreground).child(name || "Files"))
        .child(div().truncate().text_size(10).text_color(t.dim).child(this.root ? `${this.on ? `${this.on}: ` : ""}${this.root}` : ""))
        .child(div().text_size(10).text_color(t.dim).child("Markdown and JSON open in the page")))
      .child(list);
  }

}
