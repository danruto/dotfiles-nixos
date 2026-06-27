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

## Offering Fixes

- When offering a fix, always recommend the proper fix that keeps clean architecture — this is the default
- Still provide the short-term/quick fix as an option, but never recommend it
- The short fix only makes sense for brownfield projects; clean architecture wins the rest of the time

## Agent Model Selection

- **Haiku** (`model: "haiku"`) — Use for code exploration subagents: file searches, codebase exploration, grep/glob tasks, code reading
- **Sonnet** (`model: "sonnet"`) — Use for insights, explanations, web research, and mid-tier reasoning tasks
- **Opus** (default) — Reserve for architectural decisions, writing code, and any other major decisions requiring maximum reasoning

## Clarification & Decision-Making

- Ask before assuming — when requirements are vague or scope is unclear, ask rather than expand beyond what was requested
- When multiple valid approaches exist, present the options and let me decide — propose, don't prescribe

## Graph MCP

`pbtk-graph` is a per-repo MCP that indexes code symbols (`mcp__pbtk-graph__graph_*`)
and markdown docs (`mcp__pbtk-graph__doc_*`). Prefer it over grep for symbol- or
concept-shaped queries; fall back to grep for content that isn't indexed — string
literals, comments, log messages, SQL, struct tags, config keys.

Routing:

- Definition by qualified name → `graph_definition`; by substring → `graph_search`.
- Callers / callees → `graph_callers` / `graph_callees`.
- File symbols → `graph_outline`; imports → `graph_imports`.
- Diff blast radius → `graph_diff_affected`.
- Docs → `doc_search` / `doc_outline`.
- Intent/concept when you don't know names → `graph_semantic_search`.
- "Find code like this" from a `file:line` → `graph_find_related`.
- One symbol + 1-hop neighbors in a single call → `graph_context`.
- Latest session-continuity snapshot → `session_resume` (same as `/pbtk-resume`).

The two indexes are built separately — `graph_*` tools need the graph index,
`doc_*` tools need the doc index. When either goes stale after a refactor or
large file batch, rebuild (one-shot `build`, or `watch` to auto-refresh on
changes):

- `pbtk graph build` / `pbtk graph watch` — graph index.
- `pbtk doc build` / `pbtk doc watch` — doc index.

