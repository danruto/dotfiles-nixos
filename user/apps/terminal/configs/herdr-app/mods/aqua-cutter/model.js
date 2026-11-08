// Pure walkthrough helpers, ported from aqua-cutter-render (section_brief.ts, code_rows.ts,
// rich_text.tsx). No Herdr imports, so the checks can run them under Node.

const plural = (count, noun) => `${count} ${noun}${count === 1 ? "" : "s"}`;
const delta = (added, removed) => `+${added} −${removed}`;

export const SEVERITY = { high: ["High", "high"], med: ["Med", "warn"], low: ["Low", "neutral"] };
const TYPE_LABEL = {
  "trace-diff": "TraceDiff", "code-lens": "CodeLens", trace: "Trace", "what-breaks": "WhatBreaks", tour: "Tour",
  c4: "C4", "event-model": "EventModel", "decision-table": "Decision Table", "data-flow": "DataFlow",
};
export const typeLabel = (type) => TYPE_LABEL[type]
  ?? String(type ?? "section").split("-").map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(" ");

function lineDelta(hunks) {
  let added = 0, removed = 0;
  for (const hunk of hunks) for (const line of String(hunk ?? "").split("\n")) {
    if (line.startsWith("+")) added++;
    else if (line.startsWith("-")) removed++;
  }
  return { added, removed };
}

// Tone is one of add | high | warn | info | neutral; hue is the renderer's Base16 slot.
export function brief(section) {
  switch (section.type) {
    case "trace-diff": {
      const before = section.before ?? {}, after = section.after ?? {};
      const count = (changes, status) => changes.filter((change) => change.status === status).length;
      const added = count([...(after.nodeChanges ?? []), ...(after.edgeChanges ?? [])], "added");
      const removed = count([...(before.nodeChanges ?? []), ...(before.edgeChanges ?? [])], "removed");
      return { summary: `Before / after · ${(before.steps ?? []).length} → ${plural((after.steps ?? []).length, "step")}`, tag: { label: delta(added, removed), tone: "add" }, hue: "0D" };
    }
    case "code-lens": {
      const entries = section.entries ?? [];
      const files = [...new Set(entries.map((entry) => String(entry.file ?? "").split("/").pop()))];
      const { added, removed } = lineDelta(entries.map((entry) => entry.hunk));
      const total = section.coverage?.total ?? entries.length;
      return { summary: `${entries.length} of ${plural(total, "hunk")} · ${files.join(", ")}`, tag: { label: delta(added, removed), tone: "add" }, hue: "0D" };
    }
    case "trace":
      return { summary: (section.paths ?? []).map((path) => path.label).join(" · "), tag: { label: plural((section.paths ?? []).length, "path"), tone: "neutral" }, hue: "0D" };
    case "what-breaks": {
      const faults = section.faults ?? [];
      const worst = ["high", "med", "low"].find((level) => faults.some((fault) => fault.severity === level));
      return { summary: `${plural(faults.length, "fault")} · ${faults.map((fault) => fault.title).join(" · ")}`, ...(worst ? { tag: { label: SEVERITY[worst][0], tone: SEVERITY[worst][1] } } : {}), hue: "08" };
    }
    case "tour":
      return { summary: plural((section.chapters ?? []).length, "chapter"), hue: "0D" };
    case "lifecycle": {
      const states = section.states ?? [];
      return { summary: `${plural(states.length, "state")} · ${states.map((state) => state.label).join(" → ")}`, ...(states.some((state) => state.inWindow) ? { tag: { label: "Window", tone: "warn" } } : {}), hue: "0A" };
    }
    case "c4":
      return { summary: `${(section.levels ?? []).map((level) => String(level.altitude ?? "").toUpperCase()).join(" → ")}${section.mode === "diff" ? " · Before / After" : ""}`, tag: { label: "C4", tone: "info" }, hue: "0D" };
    case "event-model": {
      const flows = section.flows ?? [], blocks = flows.reduce((total, flow) => total + (flow.blocks ?? []).length, 0);
      return { summary: `${plural(flows.length, "flow")} · ${plural((section.scenarios ?? []).length, "scenario")}`, tag: { label: plural(blocks, "block"), tone: "neutral" }, hue: "0B" };
    }
    case "contracts":
      return { summary: (section.contracts ?? []).map((contract) => contract.title).join(" · "), tag: { label: plural((section.contracts ?? []).length, "contract"), tone: "neutral" }, hue: "0C" };
    case "corpus":
      return { summary: (section.entries ?? []).map((entry) => entry.title).join(" · "), tag: { label: plural((section.entries ?? []).length, "case"), tone: "neutral" }, hue: "0B" };
    case "decision-table":
      return { summary: plural((section.tables ?? []).length, "table"), tag: { label: "Decision Table", tone: "neutral" }, hue: "0C" };
    case "recovery":
      return { summary: plural((section.operations ?? []).length, "operation"), tag: { label: "Recovery", tone: "neutral" }, hue: "09" };
    case "identity": {
      const count = (section.identities ?? []).length;
      return { summary: `${count} ${count === 1 ? "identity" : "identities"}`, tag: { label: "Identity", tone: "neutral" }, hue: "0B" };
    }
    case "rollout":
      return { summary: plural((section.rollouts ?? []).length, "rollout"), tag: { label: "Rollout", tone: "neutral" }, hue: "0D" };
    case "data-flow": {
      const crossings = section.crossings ?? [];
      const present = [["untrusted", "Untrusted", "high"], ["pii", "PII", "warn"], ["token", "Token", "info"], ["internal", "Internal", "neutral"]]
        .filter(([kind]) => crossings.some((crossing) => crossing.classification === kind));
      return { summary: `${plural(crossings.length, "crossing")} · ${present.map(([, label]) => label).join(", ")}`, ...(present[0] ? { tag: { label: present[0][1], tone: present[0][2] } } : {}), hue: "0E" };
    }
    case "impact": {
      const hits = section.hits ?? [], changed = hits.filter((hit) => hit.ring === "changed").length;
      return { summary: `${changed} changed · ${hits.length - changed} downstream`, tag: { label: plural(hits.length, "node"), tone: "neutral" }, hue: "0E" };
    }
    case "telemetry": {
      const entries = section.entries ?? [], count = (status) => entries.filter((entry) => entry.status === status).length;
      const parts = ["added", "changed", "removed"].filter((status) => count(status) > 0).map((status) => `${count(status)} ${status}`);
      return { summary: `${plural(entries.length, "signal")} · ${parts.join(" · ")}`, tag: { label: delta(count("added"), count("removed")), tone: "add" }, hue: "09" };
    }
    case "tradeoffs":
      return { summary: (section.decisions ?? []).map((decision) => decision.question).join(" · "), tag: { label: plural((section.decisions ?? []).length, "decision"), tone: "info" }, hue: "0C" };
    default:
      return { summary: section.reason ?? "", tag: { label: typeLabel(section.type), tone: "neutral" }, hue: "0D" };
  }
}

// 2.x walkthroughs author a story; 1.x ones don't, so each non-tour section becomes its own stop.
export function stops(doc) {
  const sections = doc.sections ?? [];
  if (Array.isArray(doc.story?.stops) && doc.story.stops.length) return doc.story.stops;
  return sections.filter((section) => section.type !== "tour").map((section) => ({
    section: section.id, title: section.title ?? section.id, takeaway: section.reason ?? "",
    inspections: [{ section: section.id, label: `Inspect ${section.title ?? section.id}` }],
  }));
}

export function codeRows(entry) {
  let oldLine = entry.oldStart ?? 0, newLine = entry.newStart ?? 0;
  return String(entry.hunk ?? "").split(/\r\n|\r|\n/).map((line) => {
    const marker = line.charAt(0);
    return {
      marker,
      text: line.slice(1),
      oldLine: marker === "+" ? null : oldLine++,
      newLine: marker === "-" ? null : newLine++,
    };
  });
}

// Order matters: earlier alternatives win where patterns overlap (a URL contains a path).
const PATTERNS = [
  ["code", "`[^`\n]+`"],
  ["url", String.raw`https?://[^\s<>"'),;]+`],
  ["route", String.raw`\b(?:GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+/[^\s,;]*`],
  ["id", String.raw`\b[a-z][a-z0-9]*~[A-Za-z0-9._-]+~\d+\b`],
  ["path", String.raw`(?:[\w.-]+/){2,}[\w.-]+|\b[\w.-]+/[\w-]+\.[a-z]{1,5}\b`],
  ["issue", String.raw`\b[A-Z][A-Z0-9]+-\d+\b`],
  ["hash", String.raw`\b(?=[0-9a-f]*[a-f])(?=[0-9a-f]*\d)[0-9a-f]{7,40}\b`],
  ["pr", String.raw`(?<![\w&])#\d+\b`],
];
const MATCHER = new RegExp(PATTERNS.map(([, source]) => `(${source})`).join("|"), "g");
const escapeMarkdown = (text) => text.replace(/([\\*_[\]<>#|~])/g, "\\$1");

// The renderer's RichText as Markdown: URLs become links and every other reference a code chip.
export function richMarkdown(text) {
  const value = String(text ?? "");
  let out = "", last = 0;
  for (const match of value.matchAll(MATCHER)) {
    const group = match.slice(1).findIndex((part) => part !== undefined);
    const kind = PATTERNS[group]?.[0];
    const chunk = kind === "code" ? match[0] : match[0].replace(/[.:]+$/, "");
    if (!kind || !chunk) continue;
    out += escapeMarkdown(value.slice(last, match.index));
    if (kind === "url") out += `[${chunk.replace(/^https?:\/\//, "")}](${chunk})`;
    else out += "`" + (kind === "code" ? chunk.slice(1, -1) : chunk) + "`";
    last = match.index + chunk.length;
  }
  return out + escapeMarkdown(value.slice(last));
}

// "Lead — detail": the renderer bolds the lead and mutes the detail.
export function splitLead(text) {
  const value = String(text ?? ""), at = value.indexOf(" — ");
  return at < 0 ? { lead: value } : { lead: value.slice(0, at), detail: value.slice(at + 3) };
}

const SAFE_ID = /^[A-Za-z_][\w-]*$/;
/** @param {string} hex @param {string} over @param {number} weight */
export function blend(hex, over, weight) {
  const channel = (value, index) => parseInt(value.slice(1 + index * 2, 3 + index * 2), 16);
  if (!/^#[\da-f]{6}/i.test(hex) || !/^#[\da-f]{6}/i.test(over)) return hex.slice(0, 7);
  return "#" + [0, 1, 2].map((index) => Math.round(channel(hex, index) * weight + channel(over, index) * (1 - weight)).toString(16).padStart(2, "0")).join("");
}

// Highlights are Mermaid `style` lines appended to the authored flowchart; Pele keeps them in
// the baked SVG. A mark is { node | edge, colour, width?, dashed?, fill? }. A `linkStyle` needs
// the edge's index, which only the parser knows, so edge marks travel as `%% aqua-edge` comments
// that diagrams.mjs resolves. Unsafe node ids are dropped.
export function markDiagram(source, marks, background) {
  const text = String(source ?? "");
  if (!/^\s*(?:flowchart|graph)\b/.test(text)) return text;
  const paint = (mark) => {
    const parts = [`stroke:${mark.colour}`, `stroke-width:${mark.width ?? 2}px`];
    if (mark.fill) parts.unshift(`fill:${blend(mark.colour, background, 0.22)}`);
    if (mark.dashed) parts.push("stroke-dasharray:4 4");
    return parts.join(",");
  };
  const lines = marks.flatMap((mark) => {
    if (mark.edge) {
      const { from, to, label = "", occurrence = 0 } = mark.edge;
      return [`%% aqua-edge ${JSON.stringify({ from, to, label, occurrence, style: paint({ ...mark, fill: false }) })}`];
    }
    return SAFE_ID.test(mark.node ?? "") ? [`style ${mark.node} ${paint(mark)}`] : [];
  });
  return lines.length ? `${text.replace(/\s+$/, "")}\n${lines.join("\n")}` : text;
}

/** Trace marks for one path at one step: completed, active and (on reject) not reached. */
export function traceMarks(path, index, colours) {
  const steps = path?.steps ?? [];
  const marks = steps.slice(0, index).flatMap((step) => [{ node: step.node, colour: colours.done, width: 2 },
    ...(step.incoming ? [{ edge: step.incoming, colour: colours.done, width: 2 }] : [])]);
  const active = steps[index];
  if (active) marks.push({ node: active.node, colour: colours.accent, width: 3, fill: true },
    ...(active.incoming ? [{ edge: active.incoming, colour: colours.accent, width: 3 }] : []));
  if (index === steps.length - 1 && path.outcome === "reject") {
    for (const node of path.notReached?.nodes ?? []) marks.push({ node, colour: colours.dim, width: 2, dashed: true });
    for (const edge of path.notReached?.edges ?? []) marks.push({ edge, colour: colours.dim, width: 2, dashed: true });
  }
  return marks;
}

/** Node and edge change markers for one side of a TraceDiff. */
export function changeMarks(side, colours) {
  const colour = { added: colours.done, removed: colours.blocked, moved: colours.working };
  return [
    ...(side?.nodeChanges ?? []).filter((change) => colour[change.status])
      .map((change) => ({ node: change.node, colour: colour[change.status], width: 3, fill: true })),
    ...(side?.edgeChanges ?? []).filter((change) => colour[change.status] && change.edge)
      .map((change) => ({ edge: change.edge, colour: colour[change.status], width: 3 })),
  ];
}

const LANGUAGES = {
  js: "js", jsx: "js", ts: "js", tsx: "js", mjs: "js", cjs: "js", mts: "js", cts: "js",
  sh: "bash", bash: "bash", zsh: "bash", fish: "bash", py: "python", c: "c", h: "c", go: "go",
  json: "json", yaml: "yaml", yml: "yaml", toml: "yaml", html: "html", css: "css",
};
// The renderer auto-detects JSON / YAML / XML where nothing names the grammar.
export function detectLanguage(text) {
  const trimmed = String(text ?? "").trim();
  if (/^[[{]/.test(trimmed)) try { JSON.parse(trimmed); return "json"; } catch { /* not JSON */ }
  return trimmed.startsWith("<") ? "html" : null;
}

export const fileLanguage = (file) => LANGUAGES[String(file ?? "").split(".").pop()?.toLowerCase() ?? ""] ?? null;
