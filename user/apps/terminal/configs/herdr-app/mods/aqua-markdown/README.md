# Markdown + Aqua

One read-only Herdr mod for Markdown with inline Mermaid diagrams and a full-size diagram inspector. The old standalone Aqua sidebar is no longer needed.

## Use

1. Select a `.md` or `.markdown` file in **Files**, then click **Read Markdown**.
2. Scroll through the prose and inline diagrams. The reader stays pinned to that file and its machine.
3. **Colour** cycles App, Light, Dark and Colourful. **Flowchart edges** cycles Document, Straight, Curved and Stepped. These preview settings never change the source.
4. Click **Inspect diagram** to open that diagram with the same palette and routing, or **Diagram inspector** to browse every diagram in the document.
5. In the inspector, drag, scroll, or use the Pan arrows. Ctrl/Cmd-scroll zooms around the pointer; Fit, 1:1 and Centre reset the view as labelled.
6. **Escape** or **Close × · Esc** closes the inspector and leaves the reader tab open. Cmd+W keeps its existing tab-closing meaning.
7. Relative Markdown links open in the reader on the source machine. **Back** returns to the previous document. HTTP(S) links open in the system browser only when clicked.
8. **Last document** opens the most recently read document. **Example** opens a synthetic fixture. **Refresh** rereads the current source; no watcher or background polling runs.

To open another reader tab:

```sh
herdr-app do tab.new '{"name":"Markdown + Aqua","mod":"aqua-markdown"}'
```

Add `"props":{"file":"/absolute/path/document.md","on":"machine-name"}` to pin a source. Omit `on` for a file on this computer.

## Implementation

- `main.js` routes each mod copy to `reader.js` or `inspector.js` through its props and forwards cleanup.
- `document.mjs` composes native Markdown sections and Mermaid images. Closed YAML frontmatter is hidden without shifting source line numbers. Simple reference definitions are shared across sections.
- `render.mjs`, `markdown.mjs`, `styles.js`, `viewport.js`, `bake_svg.py`, and `vendor/` contain the shared bounded renderer and native inspection controls. The pinned Pele engine and licence are retained.
- The reader passes its source, machine, selected diagram line, palette and routing directly to an inspector copy of this same mod. The popup does not change other readers or depend on a separate plugin.
- SVGs keep using the existing private `data/aqua-svg/` cache so the consolidation does not discard cached diagrams. It is limited to 64 entries. Refresh regenerates an evicted preview.
- The local renderer uses the installed Node/Python helpers. It never starts a browser, web server, or screenshot stream.

## Current limits

- Prose, headings, tables, ordinary lists, and other code fences use Herdr's native Markdown renderer.
- Mermaid fences nested inside lists or blockquotes are not supported. The shared renderer allows 1 MiB per document, 32 diagrams, and 8 KiB / 256 source lines per diagram, with bounded edges and native-safe SVG output.
- Complex multiline reference definitions, footnotes, and lists spanning diagram blocks are not fully qualified.
- Embedded Markdown images and heading jumps are not supported. Relative links containing a heading fragment open the target document at the top.
- Text selection stays within each native Markdown section, not across diagrams.
- Diagram errors appear inline without hiding surrounding prose or valid diagrams.

## Checks

```sh
node ~/.config/herdr-app/mods/aqua-markdown/check.mjs
node ~/dotfiles-nixos/user/apps/terminal/configs/herdr-app/tests/check-aqua-controls.mjs
node ~/dotfiles-nixos/user/apps/terminal/configs/herdr-app/tests/check-aqua-markdown.mjs
node ~/dotfiles-nixos/user/apps/terminal/configs/herdr-app/tests/check-files.mjs
node ~/dotfiles-nixos/user/apps/terminal/configs/herdr-app/tests/check-layouts.mjs
herdr-app check ~/.config/herdr-app/mods/aqua-markdown
```

Node and Python 3 are resolved through `PATH`; Home Manager installs both. `AQUA_PYTHON` can override the Python executable. No workspace screenshots or cached documents are shared.

## Remove

Close the reader tabs and inspector dialogs, remove `mods/aqua-markdown/`, and remove the **Read Markdown** action from the personal `design-files` mod. No shipped layout or mod needs restoring.
