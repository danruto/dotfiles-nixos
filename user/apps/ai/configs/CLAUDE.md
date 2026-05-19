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
- Prefer simple, readable code over clever abstractions

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

In any git-indexed directory, prefer fff MCP tools over built-in Grep/Glob/Read-then-scan:

- `fffind` — locate files by path or filename. Frecency-aware; files you've recently opened rank higher.
- `ffgrep` — search file contents. Auto-detects regex; falls back to fuzzy match when an exact pattern has zero hits.
- `fff-multi-grep` — run several content queries in a single call (use this when scanning for 2+ patterns instead of looping ffgrep).

Fall back to Grep/Glob when fff doesn't fit: outside a git repo, when you need git-specific search (`git log -S`, `git grep --cached`), or when the agent has already been told the path is outside fff's index.

## Symbol & doc graph (per-repo MCP)

When a repo configures a graph MCP (per-repo, namespaced like `mcp__<name>__graph_*` / `mcp__<name>__doc_*`), prefer it over Grep / fff / Read-then-scan for **symbol-shaped** or **concept-shaped** queries — the index understands code structure and ranks docs by relevance, not just text matches.

### When to use which tool

- **"Where is symbol X defined?"** → `graph_definition` with a qualified name; `graph_search` with a substring. Fallback: `Grep "fn X"` / `Grep "func X"` / `Grep "def X"`. Graph hits the definition site without false-positive matches in comments or call sites.
- **"Who calls function X?" / "What does X call?"** → `graph_callers` / `graph_callees`. Fallback: `Grep "X("` — noisy, mixes declarations and string matches. Graph returns true call edges; consider raising `min_confidence` (default 0.5) in interface-heavy code.
- **"What symbols are in file Y?"** → `graph_outline` first, then `Read` specific line ranges only for the bodies you need. Cheap structural view; saves a full-file read on large files.
- **"What does this diff touch, and who depends on it?"** → `graph_diff_affected` first, then `graph_callers` on each touched symbol for blast radius. Reach for this **before** plain `git diff` when reviewing changes — nothing else answers it in one call.
- **"What imports or is imported by file Y?"** → `graph_imports` with `direction: "out"` (deps) or `direction: "in"` (reverse deps). Reverse-imports are painful to grep.
- **"Search the markdown docs by concept"** → `doc_search` for natural-language / concept queries (BM25 ranks by relevance); `doc_outline` to scan a single file's headings. Fallback: `Grep` over `**/*.md` for exact phrases.
- **"Free-text grep — literal string, TODO, log message, config key"** → `ffgrep` / `Grep` (see Code searches above). The graph index does not store string literals or comments. Do **not** route these to `graph_search` or `doc_search`.

### Filter gotchas

- `lang` is **case-sensitive lowercase**: `"go"`, `"rust"`, `"typescript"` work; `"Go"`, `"rs"`, `"ts"` return `[]` silently. Empty results on a known-good symbol usually mean a bad filter, not a missing symbol.
- `kind` discriminates usefully — values like `"Function"`, `"Method"`, `"Struct"`, `"Trait"`, `"Const"` let you narrow noisy searches.

### When NOT to use graph_* / doc_*

- Searching for string literals, comments, log messages, embedded SQL, struct-tag values, or config keys — none are in the symbol or doc index.
- Right after a large refactor or new-file batch the index may be stale; if `graph_definition` fails for a symbol visible in the working tree, run the repo's graph rebuild command (often a `<repo> graph build` / `<repo> graph watch` pair — check the project's CLAUDE.md) and retry.
- For unindexed languages or generated/vendored files, fall back to `Grep` directly.
