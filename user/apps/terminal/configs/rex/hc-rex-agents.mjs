// The agent view's pure helpers: which live hc terminals are agents or their
// subthreads, how to label their tabs, and the priority order herdr uses.
// Kept apart so the checks can exercise them without hc or Rex.

const AGENTS = /claude|codex|opencode|gemini|aider|cursor|goose|amp|pig/i;
const GLYPHS = ["🟡", "🔴", "🟢", "🔵"];
const RANK = { blocked: 0, error: 1, working: 2, done: 3, idle: 4 };

// A terminal is an agent when it reports an agent program, or when something
// started it as a helper (herdr's indented rows).
export function isAgent(term) {
  return Boolean(term?.parent) || AGENTS.test(term?.agent || "");
}

// The herdr tab a terminal belongs to, without the status emoji herdr puts in
// front of a renamed tab.
function tabName(where) {
  let name = (where || "").split(" / ").pop().trim();
  for (const g of GLYPHS) if (name.startsWith(g + " ")) name = name.slice(g.length + 1);
  return name;
}

export function agentLabel(term) {
  const tab = tabName(term?.where);
  if (term?.parent) {
    const base = term.name || term.agent || "task";
    const short = (term.address || "").split("/").pop();
    return term.name ? `↳ ${base}` : `↳ ${base} ${short}`;
  }
  return term.name || tab || term.agent || term.address || "agent";
}

export function agentRank(term) {
  return RANK[term?.status] ?? 5;
}

export function agentOrder(terms) {
  return [...terms].sort((a, b) => agentRank(a) - agentRank(b)
    || agentLabel(a).localeCompare(agentLabel(b)));
}
