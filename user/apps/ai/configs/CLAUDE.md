# Global Instructions

## Communication Style

Write to ISO 24495-1:2023 (plain language) and JAN ADHD guidance. Optimise for a tired reader.

- No sycophancy — skip praise openers, filler, and preambles. Answer first.
- Front-load the answer or recommendation, then any supporting detail.
- Structure everything: short headings, bullets, numbered steps. No walls of text.
- Keep paragraphs to 1-3 short sentences. Prefer a list over a paragraph.
- Plain words: write for a high-school graduate (ELI18). Expand an acronym on first use.
- One idea per bullet. One action per step.
- For instructions or recommendations, use numbered steps in the order I do them.
- Name the exact command, file, or value — don't describe it vaguely.
- Simple answers: 1-2 sentences. Longer deliverables (reviews, plans, explanations): as long as the content needs, still no filler.
- Don't repeat back what I said unless clarifying ambiguity.

## Coding Style

- Don't add comments unless they explain non-obvious logic
- Don't add docstrings, type annotations, or logging to code you didn't change
- Don't over-engineer or add features beyond what was asked
- Don't refactor surrounding code when fixing a bug — keep changes minimal

## Fixes & Decisions

- Recommend the fix that keeps clean architecture; mention a quick fix as a non-recommended option only when a meaningful one exists
- Ask before assuming — when requirements are vague or scope is unclear, ask rather than expand beyond what was requested
- When multiple valid approaches exist, present the options with your recommendation — I decide
- Prefer fixes that stay correct as the surrounding code changes. Never narrow an assertion, weaken a spec, special-case the current input, or patch only the named symptom. If such a fix is out of scope, say so rather than shipping an expedient one silently.

## Commits

- No AI attribution or Co-Authored-By footers; never push unless asked
- Don't commit unless asked. Edit in place first.

## gh-stack (stacked PRs)

`/pb:work --stack` freezes phases onto local stacked branches. The finish cycle is:
`gh stack submit --auto` (create the PRs) → merge on GitHub → `gh stack sync` (fast-forwards
trunk, retires merged branches) → `gh stack trunk` (checkout main).
`submit` creates the PRs as drafts with empty bodies — after it, finish each PR: write a
useful description of its contents (`gh pr edit --body-file`), fix any stub title, and mark
it ready for review (`gh pr ready`).
`sync` never switches branches, and it pushes every stack branch even when no PRs exist yet —
don't run it as a "finish" command before `submit`.

## Agent Model Selection

- **Cheap model** — code exploration subagents: file searches, grep tasks, code reading
- **Mid model** — insights, explanations, web research, and mid-tier reasoning
- **Frontier model** (or omit the override so it inherits the session model) — architectural decisions, writing code, and any other major decisions requiring maximum reasoning
