# Herdr app customisation

Personal layouts and mods for the Herdr desktop app. This is separate from the Herdr terminal client's `configs/herdr/config.toml`.

## Included

- **workbench**: a cockpit-shaped sidebar (search, view tiles, agents, spaces pinned at the bottom with a per-machine load/memory/disk readout, workspace footer) over herdr-compact's tab bar and terminal. The view tiles switch the center between Terminal, Jira, GitHub issues, Aqua Cutter, Files and Changes. Agents are one priority-sorted list: tool icon, thread name, state and age, with a foreground-process check that shows Working/Waiting when the terminal is running something other than the agent itself. Spaces sit at the bottom with coloured CPU/MEM/DSK values. Jira and GitHub are the vendored `mission-control-*` mods from CiprianSpiridon/herdr-mission-control (NOTICE files included) and have their own setup/credentials. Files and Changes are Herdr's shipped views.
- **aqua-cutter**: a native reader for Aqua Cutter walkthrough JSON: title, changes, references, trace rails, what-breaks faults, code-lens hunks and diagrams. Diagrams render through `aqua-markdown`'s Mermaid pipeline; the reader finds the newest `docs/pr/*.json` in the focused space or takes a pinned path.
- **workbench/sysinfo**: parses per-machine CPU, memory and disk locally (PowerShell) and remotely (Linux `/proc` + `df`).
- **herdr-compact**: compact workspace chrome, review tabs and a Files/Changes/Jira panel.
- **t3-threads**: a thread sidebar with filtering, pins and settled tabs.
- **review-tabs**: the custom tab bar used by **herdr-compact** and **workbench**.
- **design-files**: a file panel with **Read Markdown** for local or remote files.
- **aqua-markdown**: a native Markdown reader with inline Mermaid diagrams and a pan/zoom inspector. The vendored Pele engine includes its licence and provenance.
- **keys.json**: keybindings ported from the Herdr terminal client's direct Alt keys (alt-hjkl panes, alt-n/m splits, alt-z zoom, alt-[ ] spaces, alt-left/right tabs, alt-up/down agents).
- **settings.json**: app settings (font, zoom, sounds, `option_as_alt: "on"` so Option acts as Alt on non-US layouts like Australian). The app writes through the symlink, so Settings UI changes land in this repo.
- **jira-tickets**: a VM-backed ticket sidebar with exact @mentions, status filters and Hide done. See its README for private per-machine setup.

## Install on another computer

1. Check out this repository at `~/dotfiles-nixos`.
2. On Linux the module installs the Herdr desktop app from the release tarball. On macOS install it separately and start it once to create its shipped files.
3. Apply your normal Home Manager configuration. `user/apps/terminal/herdr-app.nix` is imported directly by a desktop host's `home.nix`, not through `hosts/shared.nix`.
4. Select a layout:

   ```sh
   herdr-app do layout.switch --name workbench
   # Or: herdr-app do layout.switch --name herdr-compact
   ```

   In workbench the view tiles switch the center; Jira and GitHub issues are Mission Control's views (open one for its setup), Aqua Cutter reads `docs/pr` walkthroughs for the focused space, and Files/Changes are the shipped views. `spaces`, the previous two-list layout, is gone.

Home Manager creates direct out-of-store symlinks from each custom mod directory and layout asset under `~/.config/herdr-app/` to this live checkout, like the settings activation in `llm.nix`. Edits through either location change the repository copy without a rebuild. Adding another custom mod directory or layout JSON/SVG requires another Home Manager activation to create its link.

The workbench's view icons live in `workbench-icons/` and are copied to `~/.config/herdr-app/wb-icons/` by activation: Herdr's asset loader does not resolve SVGs behind a link on Windows.

Node and Python 3 are installed for the renderer; Linux also gets `xdg-open` and the Herdr app itself. The app is pinned to a release tarball in `user/apps/terminal/herdr-app-desktop.nix`; bump `version` and the per-architecture `sha256` values to upgrade it, since the Nix build does not self-update. The `herdr-jira` launcher uses explicit Nix paths for Node and `acli`, so it does not rely on an interactive shell's command path. The app's shipped mods, layouts and type files remain app-managed. Mod type files and editor configuration generated at runtime are ignored by Git.

Activation keeps matching symlinks. Other existing files, directories or symlinks are moved into a unique folder under `~/.config/herdr-app-backups/` before linking. Keep those backups until the layouts have been checked.

## Reload after editing

Herdr may not notice changes behind symlinks. On the computer running the window, refresh the owned link entries without changing their targets:

```sh
python3 ~/dotfiles-nixos/user/apps/terminal/configs/herdr-app/reload.py
```

New assets must be linked by Home Manager before this check can pass. Shipped files and app state are not touched.

## Kept local

Active layout selection, spaces, tabs, machine addresses, pane state, layout click state, shared mod state, generated diagrams, caches and screenshots are not shared. No app-wide directory is symlinked.

## Checks

From this directory:

```sh
bash tests/check-links.sh
python3 tests/check-reload.py
node mods/aqua-markdown/check.mjs
for check in tests/check-*.mjs; do node "$check" || exit; done
for mod in aqua-markdown design-files jira-tickets review-tabs t3-threads; do
  herdr-app check "$HOME/.config/herdr-app/mods/$mod" || exit
done
herdr-app status
```

The copied checks cover only the owned files; shipped app assets are supplied by each computer's Herdr installation.
