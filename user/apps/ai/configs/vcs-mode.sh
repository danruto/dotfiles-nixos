#!/usr/bin/env bash
dir="${1:-${CLAUDE_PROJECT_DIR:-$PWD}}"
git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || exit 0

branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || echo "detached HEAD")
# --git-common-dir so a linked worktree still sees the main repo's gitbutler state
common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)

if [ "$branch" = "gitbutler/workspace" ]; then
  echo "VCS: GitButler workspace mode"
elif [ -d "$common/gitbutler" ]; then
  echo "VCS: GitButler single-branch mode on $branch"
else
  echo "VCS: plain git on $branch"
fi
