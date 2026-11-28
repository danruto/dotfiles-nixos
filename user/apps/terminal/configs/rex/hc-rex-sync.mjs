#!/usr/bin/env node
// Two-way sync between herdr-app's layout docs and the Rex server here. Each hc
// core keeps its own "herdr-app" document, so the local core's doc and every
// machine the core knows are read and mirrored together. herdr spaces are Rex
// sessions, tabs are windows, panes are blocks running `hc attach`. Each doc is
// the truth for its own machine:
//   - Rex changes (new session, tab or split, close, rename, rearrange) are
//     written into the doc they belong to; a plain shell that appears in Rex is
//     swapped for an hc terminal started where it was.
//   - The doc is then laid out in Rex; a tab whose shape differs is rebuilt.
// Closing a pane in Rex kills its hc terminal, as closing it in herdr does.
// With no state file (first run), Rex sessions it doesn't know are destroyed.
// An unreadable machine is left alone, so its sessions survive an outage and
// reattach when the machine returns.
//
//   node hc-rex-sync.mjs           run until stopped
//   node hc-rex-sync.mjs --dry-run one pass, printing changes instead of making them

import { execFile, spawn } from "node:child_process";
import { promisify } from "node:util";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as tree from "./hc-rex-tree.mjs";
import { eventLines } from "./hc-rex-events.mjs";
import { helpersOf, helperLabel, helperTree } from "./hc-rex-helpers.mjs";
import { bareLabel, withGlyphOf } from "./hc-rex-labels.mjs";
import { paneState, cmdlineOf } from "./hc-rex-heal.mjs";

const DRY = process.argv.includes("--dry-run");
const DOC = "herdr-app";
const FLAVOR = "com.superlogical.terminal.shell";
const ATTACH = path.join(path.dirname(fileURLToPath(import.meta.url)), "hc-rex-attach");
const BRIDGE = path.join(path.dirname(fileURLToPath(import.meta.url)), "hc-rex-bridge.lua");
const STATE = path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local/state"), "hc-rex-sync.json");
const execp = promisify(execFile);
const log = (...a) => console.error(new Date().toISOString(), ...a);
const newId = (prefix) => prefix + crypto.randomBytes(16).toString("hex");

// A doc names its own terminals; everywhere else a terminal or a doc id on
// another machine carries that machine as a prefix, as hc addresses do.
const qual = tree.qualify;
const unqual = tree.unqualify;

// hc --------------------------------------------------------------------------

class Hc {
  constructor() {
    this.next = 0;
    this.waiting = new Map();
    this.proc = spawn("hc", ["connect"], { stdio: ["pipe", "pipe", "inherit"] });
    let buf = "";
    this.proc.stdout.on("data", (chunk) => {
      buf += chunk;
      let i;
      while ((i = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, i);
        buf = buf.slice(i + 1);
        let msg;
        try { msg = JSON.parse(line); } catch { continue; }
        const w = this.waiting.get(msg.id);
        if (!w) continue;
        this.waiting.delete(msg.id);
        if (msg.error) {
          const e = new Error(`hc ${w.method}: ${msg.error.message}`);
          e.kind = msg.error.data?.kind;
          w.reject(e);
        } else {
          w.resolve(msg.result);
        }
      }
    });
    this.proc.on("exit", (code) => {
      log(`hc connect exited (${code})`);
      process.exit(1);
    });
  }

  call(method, params = {}) {
    const id = ++this.next;
    return new Promise((resolve, reject) => {
      this.waiting.set(id, { resolve, reject, method });
      this.proc.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
    });
  }
}

const hc = new Hc();
const hcBin = (await execp("sh", ["-c", "command -v hc"])).stdout.trim();

async function hcMutate(method, params) {
  if (DRY) {
    log("dry-run hc", method, JSON.stringify(params).slice(0, 200));
    return method === "terminal.run" ? { address: newId("dry-t").slice(0, 10) } : {};
  }
  return hc.call(method, params);
}

// Machines are added and removed rarely; the list only needs to be fresh
// enough for a new one to show up without a restart.
let knownMachines = null;
let knownAt = 0;
async function machines() {
  if (knownMachines && Date.now() - knownAt < 30000) return knownMachines;
  try {
    const got = await hc.call("machine.list", {});
    knownMachines = (got.machines ?? [])
      .filter((m) => m.state === "connected")
      .map((m) => m.name);
    knownAt = Date.now();
  } catch (e) {
    log("machine.list failed:", e.message);
    knownMachines ??= [];
  }
  return knownMachines;
}

// Every readable herdr-app doc, local first. A machine that can't be read is
// skipped rather than treated as empty, so its Rex sessions are left alone.
async function loadDocs() {
  const local = await hc.call("doc.get", { name: DOC });
  const docs = [{ machine: null, value: local.value ?? { spaces: [] }, version: local.version }];
  for (const name of await machines()) {
    try {
      const got = await hc.call("doc.get", { name: DOC, on: name });
      docs.push({ machine: name, value: got.value ?? { spaces: [] }, version: got.version });
    } catch (e) {
      log(`leaving ${name} alone: ${e.message}`);
    }
  }
  for (const d of docs) d.value.spaces ??= [];
  return docs;
}

// Rex -------------------------------------------------------------------------

const REX_READS = new Set(["session.list", "session.view", "block.method"]);

function fakeRex(method, args) {
  const count = (l) => (!l ? 0 : l.block ? 1 : count(l.split.before) + count(l.split.after));
  const blocks = (l) => Array.from({ length: count(l) }, () => newId("dry-b"));
  if (method === "session.create") {
    return {
      session_id: newId("dry-s"),
      initial_windows: (args.initial_windows || []).map((w) => ({ window_id: newId("dry-w"), block_ids: blocks(w.layout) })),
    };
  }
  return { window_id: newId("dry-w"), block_ids: blocks(args.layout) };
}

// Rex calls go through one `rex do` bridge (hc-rex-bridge.lua) rather than a
// process per call. Lua has no empty array, so an empty list arrives as {};
// every field the sync reads is a list or an object it only reads properties
// of, so an empty object is taken as an empty list.
const listy = (v) => {
  if (Array.isArray(v)) return v.map(listy);
  if (v && typeof v === "object") {
    const keys = Object.keys(v);
    if (keys.length === 0) return [];
    for (const k of keys) v[k] = listy(v[k]);
  }
  return v;
};

class RexBridge {
  constructor() {
    this.next = 0;
    this.waiting = new Map();
    this.proc = spawn("rex", ["do", BRIDGE], { stdio: ["pipe", "pipe", "inherit"] });
    let buf = "";
    this.proc.stdout.on("data", (chunk) => {
      buf += chunk;
      let i;
      while ((i = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, i);
        buf = buf.slice(i + 1);
        let msg;
        try { msg = JSON.parse(line); } catch { continue; }
        const w = this.waiting.get(msg.id);
        if (!w) continue;
        this.waiting.delete(msg.id);
        if (msg.error !== undefined) w.reject(new Error(`rex ${w.method}: ${msg.error}`));
        else w.resolve(msg.result === undefined ? null : listy(msg.result));
      }
    });
    this.proc.on("exit", (code) => {
      log(`rex bridge exited (${code})`);
      process.exit(1);
    });
  }

  call(method, args) {
    const id = ++this.next;
    return new Promise((resolve, reject) => {
      this.waiting.set(id, { resolve, reject, method });
      this.proc.stdin.write(JSON.stringify({ id, method, args }) + "\n");
    });
  }
}

const rexBridge = new RexBridge();

async function rex(method, args = {}) {
  if (DRY && !REX_READS.has(method)) {
    log("dry-run rex", method, JSON.stringify(args).slice(0, 200));
    return fakeRex(method, args);
  }
  return rexBridge.call(method, args);
}

const attachBlock = (term) => ({ flavor: FLAVOR, options: { command: ["/bin/sh", ATTACH, hcBin, term], shell: "none" } });

function tiled(win) {
  return win.layers?.find((l) => l.kind === "tiled")?.layout ?? null;
}

async function snapshotRex() {
  const list = (await rex("session.list")).sessions || [];
  const sessions = new Map();
  for (const s of list) {
    sessions.set(s.session_id, await rex("session.view", { session_id: s.session_id }));
  }
  return { order: list.map((s) => s.session_id), sessions };
}

// State -----------------------------------------------------------------------
// spaces: machine/id -> { session, label, machine }
// tabs:   machine/id -> { space, window, label, sig }
// blocks: block id    -> hc terminal, machine-qualified
// helpers: machine/tab id -> { session, window, sig }: the tab of helpers
//          beside a herdr tab. A sig whose window is gone was closed in Rex,
//          and stays closed until the helpers change.

function loadState() {
  try {
    return { first: false, ...JSON.parse(fs.readFileSync(STATE, "utf8")) };
  } catch {
    return { first: true, spaces: {}, tabs: {}, blocks: {} };
  }
}

function saveState(state) {
  if (DRY) return;
  const { first: _first, ...rest } = state;
  fs.mkdirSync(path.dirname(STATE), { recursive: true });
  fs.writeFileSync(STATE + ".tmp", JSON.stringify(rest, null, 1));
  fs.renameSync(STATE + ".tmp", STATE);
}

const state = loadState();
for (const map of Object.values(state.spaces)) map.machine ??= null;
state.helpers ??= {};

// Helpers ---------------------------------------------------------------------

const spaceLabel = (space) => (space.name || path.basename(space.folder || "") || "space").slice(0, 128);
const tabLabel = (tab, i) => (bareLabel(tab.name) || String(i + 1)).slice(0, 128);
const defaultWindowLabel = (label) => /^Window [0-9a-f]{8}$/.test(label);
const tabTerms = (tab) => tree.leaves(tree.fromHerdr(tab.root)).map((l) => l.term).filter(Boolean);

// A machine's Rex session is labelled with the machine, because spaces on
// different machines share names. A rename in Rex becomes the doc's name,
// without the prefix, so the next pass shows it prefixed again.
function shownSpace(machine, space) {
  const name = spaceLabel(space);
  return machine ? `${machine} · ${name}` : name;
}

function docSpaceName(machine, label) {
  const prefix = machine ? `${machine} · ` : "";
  return label.startsWith(prefix) ? label.slice(prefix.length) : label;
}

async function blockCwd(sessionId, blockId) {
  try {
    const proc = await rex("block.method", { session_id: sessionId, block_id: blockId, method: "process" });
    return proc?.foreground?.cwd || os.homedir();
  } catch {
    return os.homedir();
  }
}

// A new terminal for a space: on that machine for a remote doc, in the plain
// shell's directory for a local one.
async function startTerminal(cwd, space, tab, machine) {
  const params = {
    keep: true,
    no_parent: true,
    no_notify: true,
    labels: { "herdr.space": space.id, "herdr.tab": tab.id, where: `${shownSpace(machine, space)} / ${tab.name || ""}` },
  };
  if (machine) params.on = machine;
  else if (cwd) params.cwd = cwd;
  const t = await hcMutate("terminal.run", params);
  return qual(machine, t.address);
}

// Swap a plain Rex shell for an hc terminal started in its directory. A split
// beside it that it then leaves fills exactly the space it had.
async function adoptBlock(sessionId, win, leaf, space, tab, machine) {
  const term = await startTerminal(await blockCwd(sessionId, leaf.block), space, tab, machine);
  const res = await rex("session.new_split", {
    session_id: sessionId,
    anchor_id: leaf.block,
    direction: "horizontal",
    side: "after",
    focus: win.focused_block_id === leaf.block,
    layout: { block: attachBlock(term) },
  });
  await rex("block.close", { session_id: sessionId, block_id: leaf.block });
  delete state.blocks[leaf.block];
  state.blocks[res.block_ids[0]] = term;
  leaf.term = term;
  leaf.block = res.block_ids[0];
  log(`adopted a Rex shell as ${term}`);
}

async function killTerms(terms) {
  for (const t of terms) {
    try {
      await hcMutate("terminal.kill", { terminal: t });
      log(`killed ${t}`);
    } catch (e) {
      if (e.kind !== "not_found") log(e.message);
    }
  }
}

// Rex -> document --------------------------------------------------------------
// Returns the edited document and what to commit once it's written.

async function pullRex(doc, rx, stale) {
  const machine = doc.machine;
  const key = (id) => qual(machine, id);
  const bare = (id) => unqual(machine, id);
  const pending = [];
  const kills = [];
  let dirty = false;
  const termOf = (b) => state.blocks[b] ?? null;
  const knownSessions = new Set(Object.values(state.spaces).map((s) => s.session));
  const knownWindows = new Set([
    ...Object.values(state.tabs).map((t) => t.window),
    ...Object.values(state.helpers).map((h) => h.window),
  ]);

  const adoptWindow = async (sessionId, win, space, index) => {
    const label = bareLabel(win.label);
    const tab = { id: newId("tb"), name: defaultWindowLabel(label) ? String(index + 1) : label };
    const n = tree.fromRex(tiled(win), termOf);
    if (!n) return null;
    for (const leaf of tree.leaves(n)) {
      if (!leaf.term) await adoptBlock(sessionId, win, leaf, space, tab, machine);
      leaf.term = bare(leaf.term);
    }
    tab.root = tree.toHerdr(n, tab.id, () => newId("p"), newId);
    pending.push(() => {
      state.tabs[key(tab.id)] = { space: key(space.id), window: win.window_id, label, sig: tree.sig(n) };
    });
    return tab;
  };

  for (const sessionId of rx.order) {
    if (knownSessions.has(sessionId)) continue;
    if (state.first) {
      stale.push(sessionId);
      continue;
    }
    // A Rex session the docs don't know yet belongs to the local doc; remote
    // docs only describe the spaces they already list.
    if (machine) continue;
    const view = rx.sessions.get(sessionId);
    const space = { id: newId("sp"), name: view.label, folder: "", tabs: [] };
    for (const [i, win] of (view.windows || []).entries()) {
      const tab = await adoptWindow(sessionId, win, space, i);
      if (tab) space.tabs.push(tab);
    }
    doc.value.spaces.push(space);
    pending.push(() => {
      state.spaces[key(space.id)] = { session: sessionId, label: shownSpace(machine, space), machine };
    });
    dirty = true;
    log(`new Rex session ${view.label} -> space ${space.id}`);
  }

  for (const [spaceKey, map] of Object.entries(state.spaces)) {
    if ((map.machine ?? null) !== machine) continue;
    const space = doc.value.spaces.find((s) => key(s.id) === spaceKey);
    if (!space) continue;
    const view = rx.sessions.get(map.session);
    if (!view) {
      kills.push(...space.tabs.flatMap((tab) => tabTerms(tab).map((t) => key(t))));
      doc.value.spaces = doc.value.spaces.filter((s) => s !== space);
      pending.push(() => {
        delete state.spaces[spaceKey];
        for (const [id, t] of Object.entries(state.tabs)) if (t.space === spaceKey) delete state.tabs[id];
      });
      dirty = true;
      log(`Rex session for ${space.name} closed -> space removed`);
      continue;
    }
    if (view.label !== map.label) {
      space.name = docSpaceName(machine, view.label);
      pending.push(() => { map.label = view.label; });
      dirty = true;
    }

    for (const [i, win] of (view.windows || []).entries()) {
      if (knownWindows.has(win.window_id)) continue;
      const tab = await adoptWindow(map.session, win, space, i);
      if (tab) {
        space.tabs.splice(Math.min(i, space.tabs.length), 0, tab);
        dirty = true;
        log(`new Rex window in ${space.name} -> tab ${tab.id}`);
      }
    }

    for (const [tabKey, tmap] of Object.entries(state.tabs)) {
      if (tmap.space !== spaceKey) continue;
      const tab = space.tabs.find((t) => key(t.id) === tabKey);
      if (!tab) continue;
      const win = view.windows?.find((w) => w.window_id === tmap.window);
      if (!win) {
        kills.push(...tabTerms(tab).map((t) => key(t)));
        space.tabs = space.tabs.filter((t) => t !== tab);
        pending.push(() => { delete state.tabs[tabKey]; });
        dirty = true;
        log(`Rex window closed -> tab ${tab.name || tabKey} removed`);
        continue;
      }
      const label = bareLabel(win.label);
      if (label !== tmap.label) {
        if (!defaultWindowLabel(label)) tab.name = label;
        pending.push(() => { tmap.label = label; });
        dirty = true;
      }
      const n = tree.fromRex(tiled(win), termOf);
      if (!n) continue;
      for (const leaf of tree.leaves(n)) {
        if (!leaf.term) await adoptBlock(map.session, win, leaf, space, tab, machine);
        leaf.term = bare(leaf.term);
      }
      const now = tree.sig(n);
      if (now === tmap.sig) continue;
      const before = tree.leaves(tree.fromHerdr(tab.root));
      const panes = new Map(before.map((l) => [l.term, l.pane]));
      const kept = new Set(tree.leaves(n).map((l) => l.term));
      kills.push(...before.map((l) => l.term).filter((t) => t && !kept.has(t)).map((t) => key(t)));
      tab.root = tree.toHerdr(n, tab.id, (t) => panes.get(t) ?? newId("p"), newId);
      pending.push(() => { tmap.sig = now; });
      dirty = true;
      log(`Rex layout of ${space.name} / ${tab.name || tabKey} changed -> ${now}`);
    }
  }

  return { dirty, pending, kills };
}

// Document -> Rex --------------------------------------------------------------

async function newWindow(sessionId, tab, i, focus, machine) {
  const n = tree.fromHerdr(tab.root);
  if (!n) return null;
  const terms = tree.leaves(n).map((l) => qual(machine, l.term));
  const res = await rex("session.new_window", {
    session_id: sessionId,
    window_label: tabLabel(tab, i),
    focus,
    layout: tree.toRex(n, (term) => attachBlock(qual(machine, term))),
  });
  res.block_ids.forEach((b, j) => { state.blocks[b] = terms[j]; });
  return { window: res.window_id, sig: tree.sig(n), blocks: res.block_ids, terms };
}

function forgetBlocks(view, windowId) {
  const win = view?.windows?.find((w) => w.window_id === windowId);
  for (const layer of win?.layers || []) for (const b of layer.blocks || []) delete state.blocks[b.block_id];
}

async function pushDoc(docs, rx) {
  for (const doc of docs) {
    const machine = doc.machine;
    const key = (id) => qual(machine, id);
    for (const space of doc.value.spaces) {
      const spaceKey = key(space.id);
      const map = state.spaces[spaceKey];
      const view = map && rx.sessions.get(map.session);

      if (!view) {
        const windows = space.tabs
          .map((tab, i) => ({ tab, i, n: tree.fromHerdr(tab.root) }))
          .filter((w) => w.n);
        if (windows.length === 0) continue;
        const label = shownSpace(machine, space);
        const res = await rex("session.create", {
          label,
          initial_windows: windows.map((w) => ({
            window_label: tabLabel(w.tab, w.i),
            layout: tree.toRex(w.n, (term) => attachBlock(qual(machine, term))),
          })),
        });
        state.spaces[spaceKey] = { session: res.session_id, label, machine };
        res.initial_windows.forEach((r, j) => {
          const { tab, i, n } = windows[j];
          const terms = tree.leaves(n).map((l) => qual(machine, l.term));
          r.block_ids.forEach((b, k) => { state.blocks[b] = terms[k]; });
          state.tabs[key(tab.id)] = { space: spaceKey, window: r.window_id, label: tabLabel(tab, i), sig: tree.sig(n) };
        });
        log(`space ${label} -> new Rex session`);
        continue;
      }

      const label = shownSpace(machine, space);
      if (label !== map.label) {
        await rex("session.set_label", { session_id: map.session, label });
        map.label = label;
      }

      const wanted = new Set();
      for (const [i, tab] of space.tabs.entries()) {
        const tabKey = key(tab.id);
        wanted.add(tabKey);
        const tmap = state.tabs[tabKey];
        const win = tmap && view.windows?.find((w) => w.window_id === tmap.window);
        if (!win) {
          const made = await newWindow(map.session, tab, i, false, machine);
          if (made) {
            state.tabs[tabKey] = { space: spaceKey, window: made.window, label: tabLabel(tab, i), sig: made.sig };
            log(`tab ${tabLabel(tab, i)} -> new Rex window`);
          }
          continue;
        }
        if (tabLabel(tab, i) !== tmap.label) {
          await rex("session.set_window_label", { session_id: map.session, window_id: win.window_id, label: withGlyphOf(win.label, tabLabel(tab, i)) });
          tmap.label = tabLabel(tab, i);
        }
        const docSig = tree.sig(tree.fromHerdr(tab.root));
        if (docSig === tmap.sig) continue;

        // Rebuild the tab beside the old window, keeping its place and focus.
        const active = view.active_window_id === win.window_id;
        const focusedTerm = state.blocks[win.focused_block_id];
        const made = await newWindow(map.session, tab, i, active, machine);
        if (!made) continue;
        await rex("session.move_window", { session_id: map.session, window_id: made.window, before_window_id: win.window_id });
        forgetBlocks(view, win.window_id);
        await rex("session.close_window", { session_id: map.session, window_id: win.window_id });
        const focusBlock = made.blocks[made.terms.indexOf(focusedTerm)];
        if (active && focusBlock) await rex("session.focus_block", { session_id: map.session, block_id: focusBlock });
        Object.assign(tmap, { window: made.window, sig: made.sig, label: tabLabel(tab, i) });
        log(`tab ${tabLabel(tab, i)} rebuilt: ${made.sig}`);
      }

      for (const [tabKey, tmap] of Object.entries(state.tabs)) {
        if (tmap.space !== spaceKey || wanted.has(tabKey)) continue;
        if (view.windows?.some((w) => w.window_id === tmap.window)) {
          forgetBlocks(view, tmap.window);
          await rex("session.close_window", { session_id: map.session, window_id: tmap.window });
        }
        delete state.tabs[tabKey];
        log(`tab ${tmap.label} gone from herdr -> Rex window closed`);
      }
    }
  }

  // Only a space from a doc that was read can have gone away. A machine that
  // couldn't be read keeps its sessions.
  const seen = new Set(docs.map((d) => d.machine));
  const live = new Set(docs.flatMap((d) => d.value.spaces.map((s) => qual(d.machine, s.id))));
  for (const [spaceKey, map] of Object.entries(state.spaces)) {
    if (!seen.has(map.machine ?? null)) continue;
    if (live.has(spaceKey)) continue;
    if (rx.sessions.has(map.session)) await rex("session.destroy", { session_id: map.session });
    for (const [id, t] of Object.entries(state.tabs)) if (t.space === spaceKey) delete state.tabs[id];
    delete state.spaces[spaceKey];
    log(`space ${map.label} gone from herdr -> Rex session destroyed`);
  }
}

// Helpers ---------------------------------------------------------------------

async function liveTerminals() {
  try {
    return (await hc.call("terminal.list", {})).terminals ?? [];
  } catch (e) {
    log("terminal.list failed:", e.message);
    return null;
  }
}

async function pushHelpers(docs, terminals, rx) {
  const shown = new Set(docs.flatMap((d) => d.value.spaces.flatMap((s) => s.tabs.flatMap((t) => tabTerms(t).map((x) => qual(d.machine, x))))));
  const wanted = new Set();
  for (const doc of docs) {
    for (const space of doc.value.spaces) {
      const map = state.spaces[qual(doc.machine, space.id)];
      const view = map && rx.sessions.get(map.session);
      if (!view) continue;
      for (const [i, tab] of space.tabs.entries()) {
        const tabKey = qual(doc.machine, tab.id);
        const terms = helpersOf(terminals, tabTerms(tab).map((t) => qual(doc.machine, t)), shown);
        const h = state.helpers[tabKey];
        const win = h && view.windows?.find((w) => w.window_id === h.window);
        if (terms.length === 0) continue;
        wanted.add(tabKey);
        const sig = terms.join(",");
        if (h && h.sig === sig) continue;
        if (win) await rex("session.close_window", { session_id: map.session, window_id: win.window_id });
        const res = await rex("session.new_window", {
          session_id: map.session,
          window_label: helperLabel(tabLabel(tab, i)),
          focus: false,
          layout: tree.toRex(helperTree(terms), attachBlock),
        });
        state.helpers[tabKey] = { session: map.session, window: res.window_id, sig };
        log(`helpers of ${tabLabel(tab, i)}: ${sig}`);
      }
    }
  }
  for (const [tabKey, h] of Object.entries(state.helpers)) {
    if (wanted.has(tabKey)) continue;
    const view = rx.sessions.get(h.session);
    if (view?.windows?.some((w) => w.window_id === h.window)) {
      await rex("session.close_window", { session_id: h.session, window_id: h.window });
    }
    delete state.helpers[tabKey];
    log(`helpers of ${tabKey} gone -> Rex window closed`);
  }
}

async function orderRex(docs) {
  const rx = await snapshotRex();
  const sessions = [];
  for (const doc of docs) {
    for (const space of doc.value.spaces) {
      const id = state.spaces[qual(doc.machine, space.id)]?.session;
      if (id && rx.sessions.has(id)) sessions.push(id);
    }
  }
  const current = rx.order.filter((id) => sessions.includes(id));
  if (current.join() !== sessions.join()) {
    for (const id of sessions) await rex("session.move", { session_id: id });
  }
  for (const doc of docs) {
    for (const space of doc.value.spaces) {
      const sessionId = state.spaces[qual(doc.machine, space.id)]?.session;
      const view = rx.sessions.get(sessionId);
      if (!view) continue;
      const windows = space.tabs
        .flatMap((t) => [state.tabs[qual(doc.machine, t.id)]?.window, state.helpers[qual(doc.machine, t.id)]?.window])
        .filter((w) => view.windows?.some((v) => v.window_id === w));
      const now = (view.windows || []).map((w) => w.window_id).filter((w) => windows.includes(w));
      if (now.join() === windows.join()) continue;
      for (const w of windows) await rex("session.move_window", { session_id: sessionId, window_id: w });
    }
  }
}

// Panes a Rex restart left as plain shells -----------------------------------
// An idle one is put back on its hc terminal where it sits. A busy one goes on
// the hold list (HELD: block id -> where) and stays as it is, idle or not.
// Removing its entry from that file releases it: it's put back on its hc
// terminal on the next check, ending whatever runs in it.
// Checking every pane is a call each, so it's done at most every 15 seconds.

const HELD = path.join(path.dirname(STATE), "hc-rex-held.json");
let healedAt = 0;
let lastHeld = {};

function loadHeld() {
  try {
    return JSON.parse(fs.readFileSync(HELD, "utf8"));
  } catch {
    return {};
  }
}

async function healPanes(rx) {
  if (Date.now() - healedAt < 15000) return;
  healedAt = Date.now();
  const held = loadHeld();
  const before = JSON.stringify(held);
  const released = new Set(Object.keys(lastHeld).filter((id) => !held[id]));
  const live = new Set();
  for (const sessionId of rx.order) {
    const view = rx.sessions.get(sessionId);
    for (const win of view?.windows || []) {
      for (const b of tiled(win) ? (win.layers.find((l) => l.kind === "tiled")?.blocks || []) : []) {
        const term = state.blocks[b.block_id];
        live.add(b.block_id);
        if (!term || held[b.block_id]) continue;
        let proc;
        try {
          proc = await rex("block.method", { session_id: sessionId, block_id: b.block_id, method: "process" });
        } catch {
          continue;
        }
        const what = paneState(proc, proc?.child ? cmdlineOf(proc.child.pid) : null);
        if (what === "busy" && !released.has(b.block_id)) {
          held[b.block_id] = `${view.label} / ${bareLabel(win.label)}: ${proc.foreground?.name}, not ${term}`;
          log(`held ${held[b.block_id]}`);
          continue;
        }
        if (what !== "reattach" && !(what === "busy" && released.has(b.block_id))) continue;
        const res = await rex("session.new_split", {
          session_id: sessionId,
          anchor_id: b.block_id,
          direction: "horizontal",
          side: "after",
          focus: win.focused_block_id === b.block_id,
          layout: { block: attachBlock(term) },
        });
        await rex("block.close", { session_id: sessionId, block_id: b.block_id });
        delete state.blocks[b.block_id];
        state.blocks[res.block_ids[0]] = term;
        log(`${view.label} / ${win.label}: plain shell put back on ${term}`);
      }
    }
  }
  for (const id of Object.keys(held)) if (!live.has(id)) delete held[id];
  lastHeld = { ...held };
  if (!DRY && JSON.stringify(held) !== before) {
    fs.mkdirSync(path.dirname(HELD), { recursive: true });
    fs.writeFileSync(HELD, JSON.stringify(held, null, 1));
  }
}

// Loop ------------------------------------------------------------------------

let docVersions = new Map();
let helperSig = null;
const sigOfHelpers = (terminals) => terminals.filter((t) => t.parent).map((t) => t.address).sort().join(",");

async function reconcile() {
  for (let attempt = 0; attempt < 5; attempt++) {
    const docs = await loadDocs();
    const rx = await snapshotRex();
    const stale = [];
    let conflict = false;

    for (const doc of docs) {
      const { dirty, pending, kills } = await pullRex(doc, rx, stale);
      if (dirty && !DRY) {
        try {
          const wrote = await hc.call("doc.set", {
            name: DOC,
            ...(doc.machine ? { on: doc.machine } : {}),
            value: doc.value,
            version: doc.version,
          });
          doc.version = wrote.version;
        } catch (e) {
          if (e.kind === "conflict") {
            conflict = true;
            break;
          }
          throw e;
        }
      } else if (dirty) {
        log("dry-run hc doc.set", doc.machine ?? "local");
      }
      for (const f of pending) f();
      await killTerms(kills);
    }
    if (conflict) continue;

    for (const id of new Set(stale)) {
      log(`first run: destroying Rex session ${id}`);
      if (!DRY) await rex("session.destroy", { session_id: id });
    }
    state.first = false;

    await pushDoc(docs, await snapshotRex());
    const terminals = await liveTerminals();
    if (terminals) {
      await pushHelpers(docs, terminals, await snapshotRex());
      helperSig = sigOfHelpers(terminals);
    }
    await orderRex(docs);
    await healPanes(await snapshotRex());
    docVersions = new Map(docs.map((d) => [d.machine ?? "", d.version]));
    saveState(state);
    return;
  }
  log("gave up after repeated document conflicts; retrying on the next change");
}

let running = false;
let again = false;
async function kick() {
  if (running) {
    again = true;
    return;
  }
  running = true;
  try {
    do {
      again = false;
      await reconcile();
    } while (again);
  } catch (e) {
    log("reconcile failed:", e.stack || e.message);
  } finally {
    running = false;
  }
}

if (DRY) {
  await reconcile();
  process.exit(0);
}

let timer = null;
const soon = () => {
  clearTimeout(timer);
  timer = setTimeout(kick, 150);
};

// Every `rex api call` opens a client for the length of one call, so this
// script's own reads emit client_connected and client_disconnected. Reconciling
// on those would let each pass schedule the next one.
const nextEvents = eventLines();

const events = spawn("rex", ["events", "--json"], { stdio: ["ignore", "pipe", "inherit"] });
events.stdout.on("data", (chunk) => {
  if (nextEvents(chunk).length) soon();
});
events.on("exit", (code) => {
  log(`rex events exited (${code})`);
  process.exit(1);
});

// The local doc is the one edited most, so it is checked every second; the
// machines' docs over ssh every five.
setInterval(async () => {
  try {
    const { version } = await hc.call("doc.get", { name: DOC });
    if (docVersions.get("") !== version) soon();
  } catch (e) {
    log(e.message);
  }
}, 1000);

setInterval(async () => {
  for (const name of await machines()) {
    try {
      const { version } = await hc.call("doc.get", { name: DOC, on: name });
      if (docVersions.get(name) !== version) soon();
    } catch {}
  }
}, 5000);
// Helpers start and end without touching a doc or Rex.
setInterval(async () => {
  const terminals = await liveTerminals();
  if (terminals && sigOfHelpers(terminals) !== helperSig) soon();
}, 2000);
setInterval(soon, 10000);

await kick();
log("hc-rex-sync running");
