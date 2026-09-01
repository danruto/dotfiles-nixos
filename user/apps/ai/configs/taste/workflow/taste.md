# Workflow

- When trialing new apps: prefers non-permanent setups in a temp dir (e.g., appimage-run) over installing; download everything first, then run them all afterwards. If the apps are rejected, wants all caches and files cleaned out completely. Confidence: 0.8
- Keeps the machine tidy: wants leftover artifacts created by tried-and-rejected tools removed (agent CLIs, skills, hooks); OK with using jq to help locate them. Confidence: 0.7
- Never pushes unless asked. No AI attribution or Co-Authored-By footers in commits. Doesn't commit unless asked — edits in place first. Confidence: 1.0
- gh-stack (`/pb:work --stack`) freezes phases onto local stacked branches; the finish cycle is: `gh stack submit --auto` (creates draft PRs with empty bodies) → finish each PR: write a useful description (`gh pr edit --body-file`), fix stub titles, mark ready (`gh pr ready`) → merge on GitHub → `gh stack sync` (fast-forwards trunk, retires merged branches; never switches branches and pushes every stack branch even without PRs, so never run it as a "finish" command before `submit`) → `gh stack trunk` → rebuild the repo's pbtk graph index if one exists. Confidence: 0.95
