---
description: Create a git commit for staged changes without pushing or AI attribution
---

# Quick Commit (No Push, No AI Attribution)

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
2. Include a **body** with bullet points summarizing the key changes for context
3. Focus on the "why" rather than the "what"
4. Execute the commit using a HEREDOC for multi-line message:

```bash
git commit -m "$(cat <<'EOF'
type(scope): subject

- bullet point 1
- bullet point 2
- bullet point 3
EOF
)"
```

IMPORTANT:
- **Do NOT run `git add`, `git stage`, or modify the staging area in any way. ONLY commit what is already staged.**
- Do NOT push to remote
- Do NOT include any AI attribution or Co-Authored-By lines
- Do NOT add any "Generated with..." footer
- Just create a clean, simple commit message
