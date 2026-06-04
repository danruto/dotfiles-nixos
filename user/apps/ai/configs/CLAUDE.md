# Global Instructions

## Communication Style

- No sycophancy — don't open with praise, filler, or "Great question!"
- Keep responses concise and direct - limit to 2 sentences
- Don't repeat back what I said unless clarifying ambiguity
- Skip unnecessary preambles — get to the point

## Coding Style

- Don't add comments unless they explain non-obvious logic
- Don't add docstrings, type annotations, or logging to code you didn't change
- Don't over-engineer or add features beyond what was asked
- Don't refactor surrounding code when fixing a bug — keep changes minimal

## Agent Model Selection

- **Haiku** (`model: "haiku"`) — Use for code exploration subagents: file searches, codebase exploration, grep/glob tasks, code reading
- **Sonnet** (`model: "sonnet"`) — Use for insights, explanations, web research, and mid-tier reasoning tasks
- **Opus** (default) — Reserve for architectural decisions, writing code, and any other major decisions requiring maximum reasoning

## Clarification & Decision-Making

- Always ask questions when requirements are vague or ambiguous — don't assume
- When multiple valid approaches exist, present the options and let me choose
- The ultimate decision is always up to me — propose, don't prescribe
- If unsure about scope, ask before expanding beyond what was requested

## Code searches

In git-indexed dirs, prefer fff MCP over Grep/Glob/Read-then-scan: `fffind` (locate files by path/name, frecency-aware), `ffgrep` (search contents; auto-regex, fuzzy fallback on zero hits), `fff-multi-grep` (2+ content queries in one call). Fall back to Grep/Glob outside git repos, for git-specific search (`git log -S`, `git grep --cached`), or when told the path is outside fff's index.

## Symbol & doc graph (per-repo MCP)

When a repo configures a graph MCP (namespaced `mcp__<name>__graph_*` / `mcp__<name>__doc_*`), prefer it over Grep/fff for **symbol-** or **concept-shaped** queries — it understands code structure and ranks docs by relevance, not text matches.

- Definition: `graph_definition` (qualified name) / `graph_search` (substring). Callers/callees: `graph_callers` / `graph_callees` (raise `min_confidence` in interface-heavy code). File symbols: `graph_outline`, then `Read` specific ranges. Diff blast radius: `graph_diff_affected`, then `graph_callers` per touched symbol. Imports: `graph_imports` (`direction: "out"` deps / `"in"` reverse-deps). Docs by concept: `doc_search` (BM25) / `doc_outline`.
- `lang` is case-sensitive lowercase (`"go"`, `"rust"`, `"typescript"` — not `"Go"`/`"rs"`/`"ts"`); `kind` narrows (`"Function"`, `"Method"`, `"Struct"`, …). Empty results on a known symbol usually mean a bad filter.
- **Not in the index** — use `ffgrep`/`Grep`: string literals, comments, log messages, embedded SQL, struct tags, config keys. After a large refactor the index may be stale (rebuild via the repo's graph build/watch — check the project's CLAUDE.md); fall back to `Grep` for unindexed/generated files.
