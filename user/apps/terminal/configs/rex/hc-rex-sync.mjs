#!/usr/bin/env node
// Two-way sync between herdr-app's layout on this machine (the hc document
// "herdr-app") and the Rex server here. herdr spaces are Rex sessions, tabs are
// windows, panes are blocks running `hc attach`. The document is the truth:
//   - Rex changes (new session, tab or split, close, rename, rearrange) are
//     written into the document; a plain shell that appears in Rex is swapped
//     for an hc terminal started where it was.
//   - The document is then laid out in Rex; a tab whose shape differs is rebuilt.
// Closing a pane in Rex kills its hc terminal, as closing it in herdr does.
// With no state file (first run), Rex sessions it doesn't know are destroyed.
//
//   node hc-rex-sync.mjs           run until stopped
//   node hc-rex-sync.mjs --dry-run one pass, printing changes instead of making them

import { execFile, spawn } from "node:child_process";
import { promisify } from "node:util";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import * as tree from "./hc-rex-tree.mjs";

const DRY = process.argv.includes("--dry-run");
const DOC = "herdr-app";
const FLAVOR = "com.superlogical.terminal.shell";
const ATTACH = path.join(path.dirname(new URL(import.meta.url).pathname), "hc-rex-attach");
const STATE = path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local/state"), "hc-rex-sync.json");
const execp = promisify(execFile);
const log = (...a) => console.error(new Date().toISOString(), ...a);
const newId = (prefix) => prefix + crypto.randomBytes(16).toString("hex");

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

async function rex(method, args = {}) {
  if (DRY && !REX_READS.has(method)) {
    log("dry-run rex", method, JSON.stringify(args).slice(0, 200));
    return fakeRex(method, args);
  }
  const { stdout } = await execp("rex", ["api", "call", method, JSON.stringify(args)], { maxBuffer: 64 << 20 });
  return stdout.trim() ? JSON.parse(stdout) : null;
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
// spaces: space id -> { session, label }
// tabs:   tab id   -> { space, window, label, sig }
// blocks: block id -> hc terminal

function loadState() {
  try {
    return { first: false, ...JSON.parse(fs.readFileSync(STATE, "utf8")) };
  } catch {
    return { first: true, spaces: {}, tabs: {}, blocks: {} };
  }
}

function saveState(state) {
  if (DRY) return;
  const { first, ...rest } = state;
  fs.mkdirSync(path.dirname(STATE), { recursive: true });
  fs.writeFileSync(STATE + ".tmp", JSON.stringify(rest, null, 1));
  fs.renameSync(STATE + ".tmp", STATE);
}

const state = loadState();

// Helpers ---------------------------------------------------------------------

const spaceLabel = (space) => (space.name || path.basename(space.folder || "") || "space").slice(0, 128);
const tabLabel = (tab, i) => (tab.name || String(i + 1)).slice(0, 128);
const defaultWindowLabel = (label) => /^Window [0-9a-f]{8}$/.test(label);
const tabTerms = (tab) => tree.leaves(tree.fromHerdr(tab.root)).map((l) => l.term).filter(Boolean);

async function blockCwd(sessionId, blockId) {
  try {
    const proc = await rex("block.method", { session_id: sessionId, block_id: blockId, method: "process" });
    return proc?.foreground?.cwd || os.homedir();
  } catch {
    return os.homedir();
  }
}

async function startTerminal(cwd, space, tab) {
  const t = await hcMutate("terminal.run", {
    cwd,
    keep: true,
    no_parent: true,
    no_notify: true,
    labels: { "herdr.space": space.id, "herdr.tab": tab.id, where: `${spaceLabel(space)} / ${tab.name || ""}` },
  });
  return t.address;
}

// Swap a plain Rex shell for an hc terminal started in its directory. A split
// beside it that it then leaves fills exactly the space it had.
async function adoptBlock(sessionId, win, leaf, space, tab) {
  const term = await startTerminal(await blockCwd(sessionId, leaf.block), space, tab);
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

async function pullRex(doc, rx) {
  const pending = [];
  const kills = [];
  let dirty = false;
  const termOf = (b) => state.blocks[b] ?? null;
  const knownSessions = new Set(Object.values(state.spaces).map((s) => s.session));
  const knownWindows = new Set(Object.values(state.tabs).map((t) => t.window));

  const adoptWindow = async (sessionId, win, space, index) => {
    const tab = { id: newId("tb"), name: defaultWindowLabel(win.label) ? String(index + 1) : win.label };
    const n = tree.fromRex(tiled(win), termOf);
    if (!n) return null;
    for (const leaf of tree.leaves(n)) if (!leaf.term) await adoptBlock(sessionId, win, leaf, space, tab);
    tab.root = tree.toHerdr(n, tab.id, () => newId("p"), newId);
    pending.push(() => {
      state.tabs[tab.id] = { space: space.id, window: win.window_id, label: win.label, sig: tree.sig(n) };
    });
    return tab;
  };

  for (const sessionId of rx.order) {
    if (knownSessions.has(sessionId)) continue;
    const view = rx.sessions.get(sessionId);
    if (state.first) {
      log(`first run: destroying Rex session ${view.label}`);
      await rex("session.destroy", { session_id: sessionId });
      continue;
    }
    const space = { id: newId("sp"), name: view.label, folder: "", tabs: [] };
    for (const [i, win] of (view.windows || []).entries()) {
      const tab = await adoptWindow(sessionId, win, space, i);
      if (tab) space.tabs.push(tab);
    }
    doc.spaces.push(space);
    pending.push(() => { state.spaces[space.id] = { session: sessionId, label: view.label }; });
    dirty = true;
    log(`new Rex session ${view.label} -> space ${space.id}`);
  }

  for (const [spaceId, map] of Object.entries(state.spaces)) {
    const space = doc.spaces.find((s) => s.id === spaceId);
    if (!space) continue;
    const view = rx.sessions.get(map.session);
    if (!view) {
      kills.push(...space.tabs.flatMap(tabTerms));
      doc.spaces = doc.spaces.filter((s) => s !== space);
      pending.push(() => {
        delete state.spaces[spaceId];
        for (const [id, t] of Object.entries(state.tabs)) if (t.space === spaceId) delete state.tabs[id];
      });
      dirty = true;
      log(`Rex session for ${space.name} closed -> space removed`);
      continue;
    }
    if (view.label !== map.label) {
      space.name = view.label;
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

    for (const [tabId, tmap] of Object.entries(state.tabs)) {
      if (tmap.space !== spaceId) continue;
      const tab = space.tabs.find((t) => t.id === tabId);
      if (!tab) continue;
      const win = view.windows?.find((w) => w.window_id === tmap.window);
      if (!win) {
        kills.push(...tabTerms(tab));
        space.tabs = space.tabs.filter((t) => t !== tab);
        pending.push(() => { delete state.tabs[tabId]; });
        dirty = true;
        log(`Rex window closed -> tab ${tab.name || tabId} removed`);
        continue;
      }
      if (win.label !== tmap.label) {
        if (!defaultWindowLabel(win.label)) tab.name = win.label;
        pending.push(() => { tmap.label = win.label; });
        dirty = true;
      }
      const n = tree.fromRex(tiled(win), termOf);
      if (!n) continue;
      for (const leaf of tree.leaves(n)) if (!leaf.term) await adoptBlock(map.session, win, leaf, space, tab);
      const now = tree.sig(n);
      if (now === tmap.sig) continue;
      const before = tree.leaves(tree.fromHerdr(tab.root));
      const panes = new Map(before.map((l) => [l.term, l.pane]));
      const kept = new Set(tree.leaves(n).map((l) => l.term));
      kills.push(...before.map((l) => l.term).filter((t) => t && !kept.has(t)));
      tab.root = tree.toHerdr(n, tab.id, (t) => panes.get(t) ?? newId("p"), newId);
      pending.push(() => { tmap.sig = now; });
      dirty = true;
      log(`Rex layout of ${space.name} / ${tab.name || tabId} changed -> ${now}`);
    }
  }

  return { dirty, pending, kills };
}

// Document -> Rex --------------------------------------------------------------

async function newWindow(sessionId, tab, i, focus) {
  const n = tree.fromHerdr(tab.root);
  if (!n) return null;
  const terms = tree.leaves(n).map((l) => l.term);
  const res = await rex("session.new_window", {
    session_id: sessionId,
    window_label: tabLabel(tab, i),
    focus,
    layout: tree.toRex(n, attachBlock),
  });
  res.block_ids.forEach((b, j) => { state.blocks[b] = terms[j]; });
  return { window: res.window_id, sig: tree.sig(n), blocks: res.block_ids, terms };
}

function forgetBlocks(view, windowId) {
  const win = view?.windows?.find((w) => w.window_id === windowId);
  for (const layer of win?.layers || []) for (const b of layer.blocks || []) delete state.blocks[b.block_id];
}

async function pushDoc(doc, rx) {
  for (const space of doc.spaces) {
    let map = state.spaces[space.id];
    let view = map && rx.sessions.get(map.session);

    if (!view) {
      const windows = space.tabs
        .map((tab, i) => ({ tab, i, n: tree.fromHerdr(tab.root) }))
        .filter((w) => w.n);
      if (windows.length === 0) continue;
      const res = await rex("session.create", {
        label: spaceLabel(space),
        initial_windows: windows.map((w) => ({ window_label: tabLabel(w.tab, w.i), layout: tree.toRex(w.n, attachBlock) })),
      });
      state.spaces[space.id] = { session: res.session_id, label: spaceLabel(space) };
      res.initial_windows.forEach((r, j) => {
        const { tab, i, n } = windows[j];
        const terms = tree.leaves(n).map((l) => l.term);
        r.block_ids.forEach((b, k) => { state.blocks[b] = terms[k]; });
        state.tabs[tab.id] = { space: space.id, window: r.window_id, label: tabLabel(tab, i), sig: tree.sig(n) };
      });
      log(`space ${spaceLabel(space)} -> new Rex session`);
      continue;
    }

    if (spaceLabel(space) !== map.label) {
      await rex("session.set_label", { session_id: map.session, label: spaceLabel(space) });
      map.label = spaceLabel(space);
    }

    const wanted = new Set();
    for (const [i, tab] of space.tabs.entries()) {
      wanted.add(tab.id);
      const tmap = state.tabs[tab.id];
      const win = tmap && view.windows?.find((w) => w.window_id === tmap.window);
      if (!win) {
        const made = await newWindow(map.session, tab, i, false);
        if (made) {
          state.tabs[tab.id] = { space: space.id, window: made.window, label: tabLabel(tab, i), sig: made.sig };
          log(`tab ${tabLabel(tab, i)} -> new Rex window`);
        }
        continue;
      }
      if (tabLabel(tab, i) !== tmap.label) {
        await rex("session.set_window_label", { session_id: map.session, window_id: win.window_id, label: tabLabel(tab, i) });
        tmap.label = tabLabel(tab, i);
      }
      const docSig = tree.sig(tree.fromHerdr(tab.root));
      if (docSig === tmap.sig) continue;

      // Rebuild the tab beside the old window, keeping its place and focus.
      const active = view.active_window_id === win.window_id;
      const focusedTerm = state.blocks[win.focused_block_id];
      const made = await newWindow(map.session, tab, i, active);
      if (!made) continue;
      await rex("session.move_window", { session_id: map.session, window_id: made.window, before_window_id: win.window_id });
      forgetBlocks(view, win.window_id);
      await rex("session.close_window", { session_id: map.session, window_id: win.window_id });
      const focusBlock = made.blocks[made.terms.indexOf(focusedTerm)];
      if (active && focusBlock) await rex("session.focus_block", { session_id: map.session, block_id: focusBlock });
      Object.assign(tmap, { window: made.window, sig: made.sig, label: tabLabel(tab, i) });
      log(`tab ${tabLabel(tab, i)} rebuilt: ${made.sig}`);
    }

    for (const [tabId, tmap] of Object.entries(state.tabs)) {
      if (tmap.space !== space.id || wanted.has(tabId)) continue;
      if (view.windows?.some((w) => w.window_id === tmap.window)) {
        forgetBlocks(view, tmap.window);
        await rex("session.close_window", { session_id: map.session, window_id: tmap.window });
      }
      delete state.tabs[tabId];
      log(`tab ${tmap.label} gone from herdr -> Rex window closed`);
    }
  }

  const live = new Set(doc.spaces.map((s) => s.id));
  for (const [spaceId, map] of Object.entries(state.spaces)) {
    if (live.has(spaceId)) continue;
    if (rx.sessions.has(map.session)) await rex("session.destroy", { session_id: map.session });
    for (const [id, t] of Object.entries(state.tabs)) if (t.space === spaceId) delete state.tabs[id];
    delete state.spaces[spaceId];
    log(`space ${map.label} gone from herdr -> Rex session destroyed`);
  }
}

async function orderRex(doc) {
  const rx = await snapshotRex();
  const sessions = doc.spaces.map((s) => state.spaces[s.id]?.session).filter((id) => rx.sessions.has(id));
  const current = rx.order.filter((id) => sessions.includes(id));
  if (current.join() !== sessions.join()) {
    for (const id of sessions) await rex("session.move", { session_id: id });
  }
  for (const space of doc.spaces) {
    const sessionId = state.spaces[space.id]?.session;
    const view = rx.sessions.get(sessionId);
    if (!view) continue;
    const windows = space.tabs.map((t) => state.tabs[t.id]?.window).filter((w) => view.windows?.some((v) => v.window_id === w));
    const now = (view.windows || []).map((w) => w.window_id).filter((w) => windows.includes(w));
    if (now.join() === windows.join()) continue;
    for (const w of windows) await rex("session.move_window", { session_id: sessionId, window_id: w });
  }
}

// Loop ------------------------------------------------------------------------

let docVersion = -1;

async function reconcile() {
  for (let attempt = 0; attempt < 5; attempt++) {
    const got = await hc.call("doc.get", { name: DOC });
    const doc = got.value ?? { spaces: [] };
    doc.spaces ??= [];

    const { dirty, pending, kills } = await pullRex(doc, await snapshotRex());
    let version = got.version;
    if (dirty && !DRY) {
      try {
        version = (await hc.call("doc.set", { name: DOC, value: doc, version: got.version })).version;
      } catch (e) {
        if (e.kind === "conflict") continue;
        throw e;
      }
    }
    for (const f of pending) f();
    await killTerms(kills);
    state.first = false;

    await pushDoc(doc, await snapshotRex());
    await orderRex(doc);
    docVersion = version;
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

const events = spawn("rex", ["events", "--json"], { stdio: ["ignore", "pipe", "inherit"] });
events.stdout.on("data", soon);
events.on("exit", (code) => {
  log(`rex events exited (${code})`);
  process.exit(1);
});

setInterval(async () => {
  try {
    const { version } = await hc.call("doc.get", { name: DOC });
    if (version !== docVersion) soon();
  } catch (e) {
    log(e.message);
  }
}, 1000);
setInterval(soon, 10000);

await kick();
log("hc-rex-sync running");
