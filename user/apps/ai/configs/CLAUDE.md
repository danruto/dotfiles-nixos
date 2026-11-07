# Global Instructions

## Version control

A session-start hook prints the repo's mode as a `VCS:` line: GitButler workspace mode, GitButler single-branch mode, or plain git.

- Before any Git write (commit, branch, pull, push, reset), re-check the mode with `bash ~/dotfiles-nixos/user/apps/ai/configs/vcs-mode.sh`. It can change mid-session
- GitButler, either mode: use `but` for commits, branches, updates and pushes, never `git commit`, `git switch`, `git checkout`, `git rebase`, `git pull` or `git reset`
- Commit only when asked or via a skill; never push unless asked. Edit in place first. On `main` in a GitButler mode, start work with `but branch new <name>`
- No AI attribution or Co-Authored-By footers
- NEVER create a pull request, including a draft, unless I explicitly ask for one. Permission to implement, commit, push, or follow a workflow is not permission to open a PR
- After a branch's PR is squash-merged: don't pull into that branch. Switch to `main`, update it, delete the old branch, then start a new one

## Communication Style

Write to ISO 24495-1:2023 (plain language) and JAN ADHD guidance. Optimise for a tired reader.

- No sycophancy — skip praise openers, filler, and preambles. Answer first
- Front-load the answer or recommendation, then any supporting detail
- Prefer bullets and numbered steps over paragraphs. Headings only in long deliverables (reviews, plans, explanations)
- Keep paragraphs to 1-3 short sentences. One idea per bullet. One action per step
- Plain words: write for a high-school graduate. Expand an acronym on first use
- For instructions, use numbered steps in the order I do them
- Name the exact command, file, or value, in a code block — don't describe it vaguely
- Simple answers: 1-2 sentences. Longer deliverables: as long as the content needs, no filler
- Don't repeat back what I said unless clarifying ambiguity

## Coding Style

- Don't add comments unless they explain non-obvious logic. A comment describes only the code it sits on, never other docs, paths, hostnames, or issue numbers
- Don't add docstrings, type annotations, or logging to code you didn't change
- The ask is the scope: no extra features, no refactoring surrounding code when fixing a bug
- Before writing new code, reuse what exists, in this order: this codebase, the standard library, native platform features, already-installed dependencies. Don't add a dependency for what a few lines can do
- Before changing a shared function, grep every caller. Fix it once where all callers route through
- Non-trivial logic (a branch, parser, money or security path) leaves one small runnable check behind
- Before adding state or storage, check whether the database or an existing cache already holds it
- Pin versions, never `latest`

## Fixes & Decisions

- Recommend one fix, the one that keeps clean architecture, and build it. Stop for my decision only when the fork touches requirements, product choices, staging, billing, or tenant data
- Open decisions go at the top of the message as one numbered list, each with a recommendation. Answers arrive as `N: option` or "recommended"
- Routine reversible execution (run a check, commit when asked, merge when checks are green, close a verified issue, run an approved script) is done and reported, never confirmed first
- Never state that something runs, is deployed, or is set until you ran a check in this session and can quote its output
- Prefer fixes that stay correct as the surrounding code changes. Never narrow an assertion, weaken a spec, special-case the current input, or patch only the named symptom. If the proper fix is out of scope, say so rather than shipping an expedient one silently

## Machine & privacy

- Never write private identifiers (private repo names, private issue numbers) into tracked or public files. Never commit a gitignored file
- Disk is scarce: no worktrees for repos with large build dirs (Rust `target/`); pull only the samples needed; tear down every container, server, or process you start before finishing

## Agent Model Selection

- Cheapest available model (Claude: `haiku`) — code exploration subagents: file searches, grep tasks, code reading
- Mid-tier model (Claude: `sonnet`) — insights, explanations, web research, mid-tier reasoning
- No override, inherit the session model — architectural decisions, writing code, major decisions
