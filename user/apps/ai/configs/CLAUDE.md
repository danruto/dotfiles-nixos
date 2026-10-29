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
- Before writing new code, reuse what exists, in this order: this codebase, the standard library, native platform features, already-installed dependencies. Don't add a dependency for what a few lines can do
- Before changing a shared function, grep every caller. Fix it once where all callers route through, not in each caller
- Non-trivial logic (a branch, parser, money or security path) leaves one small runnable check behind. Trivial one-liners need none
- Comments never reference other docs, file paths, hostnames, or issue numbers. A comment describes only the code it sits on
- Before adding state or storage, check whether the database or an existing cache already holds it. Prefer one shared component over per-page copies
- Semver: breaking → major, feature → minor, fix → patch. Pin versions, never `latest`

## Fixes & Decisions

- Recommend the fix that keeps clean architecture; mention a quick fix as a non-recommended option only when a meaningful one exists
- Ask only about requirements, product choices, or anything touching staging, billing, or tenant data
- Routine reversible execution (run a check, commit when asked, merge when checks are green, close a verified issue, run an approved script) is done and reported, never confirmed first
- Open decisions go at the top of the message as one numbered list, each with a recommendation. Answers arrive as `N: option` or "recommended"
- Never state that something runs, is deployed, or is set until you ran a check in this session and can quote its output
- When multiple valid approaches exist, present the options with your recommendation — I decide
- Prefer fixes that stay correct as the surrounding code changes. Never narrow an assertion, weaken a spec, special-case the current input, or patch only the named symptom. If such a fix is out of scope, say so rather than shipping an expedient one silently.

## Commits & pull requests

- No AI attribution or Co-Authored-By footers; never push unless asked
- Don't commit unless asked. Edit in place first.
- NEVER create a pull request (including a draft) unless I explicitly ask for one or explicitly authorise its creation. Permission to implement, commit, push, deploy, or follow a workflow is not permission to create a PR.

## Machine & privacy

- Never write private identifiers (private repo names, private issue numbers) into tracked or public files. Never commit a gitignored file
- Disk is scarce: no worktrees for repos with large build dirs (Rust `target/`); pull only the samples needed; tear down every container, server, or process you start before finishing
- If the harness blocks a file edit, write the change as a script under `scripts/` and run it. Do not stop and ask

## Agent Model Selection

- **Cheap model** — code exploration subagents: file searches, grep tasks, code reading
- **Mid model** — insights, explanations, web research, and mid-tier reasoning
- **Frontier model** (or omit the override so it inherits the session model) — architectural decisions, writing code, and any other major decisions requiring maximum reasoning
