---
description: Create a git commit for staged changes without pushing or Claude attribution
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(rtk git status:*), Bash(rtk git diff:*), Bash(rtk git log:*), Bash(rtk git commit:*)
model: haiku
---

# Quick Commit (No Push, No Claude Attribution)

## Current Staged Changes

!`git status`

!`git diff --cached`

## Recent Commit Style

!`git log -3 --pretty=format:"%s"`

## Instructions

Based on the staged changes above:

1. Analyze the changes and create a commit message in **Conventional Commits (cz) format**: `<type>(<scope>): <subject>`
   - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
   - Scope is optional but encouraged
   - Subject should be concise, imperative mood, no period at end
2. Focus on the "why" rather than the "what"
3. Execute the commit with:

```bash
git commit -m "type(scope): subject"
```

IMPORTANT:
- Do NOT push to remote
- Do NOT include any Claude attribution or Co-Authored-By lines
- Do NOT add the "Generated with Claude Code" footer
- Just create a clean, simple commit message
