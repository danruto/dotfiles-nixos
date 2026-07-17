# Global Instructions

## Communication Style

- No sycophancy — no praise openers, filler, or preambles; get straight to the point
- Simple answers: 1-2 sentences. Requested deliverables (reviews, plans, explanations): the length the content needs, still no filler
- Don't repeat back what I said unless clarifying ambiguity

## Coding Style

- Don't add comments unless they explain non-obvious logic
- Don't add docstrings, type annotations, or logging to code you didn't change
- Don't over-engineer or add features beyond what was asked
- Don't refactor surrounding code when fixing a bug — keep changes minimal

## Fixes & Decisions

- Recommend the fix that keeps clean architecture; mention a quick fix as a non-recommended option only when a meaningful one exists
- Ask before assuming — when requirements are vague or scope is unclear, ask rather than expand beyond what was requested
- When multiple valid approaches exist, present the options with your recommendation — I decide

## Commits

- No AI attribution or Co-Authored-By footers; never push unless asked

## gh-stack (stacked PRs)

`/pb:work --stack` freezes phases onto local stacked branches. The finish cycle is:
`gh stack submit --auto` (create the PRs) → merge on GitHub → `gh stack sync` (fast-forwards
trunk, retires merged branches) → `gh stack trunk` (checkout main) → rebuild the repo's
pbtk graph index if one exists (`pbtk graph build`).
`submit` creates the PRs as drafts with empty bodies — after it, finish each PR: write a
useful description of its contents (`gh pr edit --body-file`), fix any stub title, and mark
it ready for review (`gh pr ready`).
`sync` never switches branches, and it pushes every stack branch even when no PRs exist yet —
don't run it as a "finish" command before `submit`.

## Agent Model Selection

- **Haiku** (`model: "haiku"`) — code exploration subagents: file searches, grep/glob tasks, code reading
- **Sonnet** (`model: "sonnet"`) — insights, explanations, web research, and mid-tier reasoning
- **Omit `model`** (inherits the session model) — architectural decisions, writing code, and any other major decisions requiring maximum reasoning

## Graph MCP

`pbtk-graph` is a per-repo MCP that indexes code symbols (`mcp__pbtk-graph__graph_*`)
and markdown docs (`mcp__pbtk-graph__doc_*`). When it is available in the
current repo:

**Before any Grep/Glob/Read-scan for code, stop and check: is this a symbol,
caller/callee, definition, or concept lookup? If yes, you MUST use a
`pbtk-graph` tool first. Grep is the fallback, not the default — use it only
for unindexed content (string literals, comments, log messages, SQL, struct
tags, config keys) or when the graph query returns nothing.**

Routing:

- Definition by qualified name → `graph_definition`; by substring → `graph_search`.
- Callers / callees → `graph_callers` / `graph_callees`.
- File symbols → `graph_outline`; imports → `graph_imports`.
- Diff blast radius → `graph_diff_affected`.
- Docs → `doc_search` / `doc_outline` before any Grep over `*.md`.
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

