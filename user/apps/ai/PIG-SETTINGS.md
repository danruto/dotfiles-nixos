# PiG settings overlay

Pi uses `configs/pi-settings.json` directly. Nix merges that file with
`configs/pig-settings.json` through `pig-settings.nix` when evaluating the home
configuration. Home Manager activation copies the result into a separate,
writable `~/.pig/agent/settings.json`. There is no launch-time merge.

## Merge rules

- Scalar values and ordinary arrays in the overlay replace base values.
- Objects merge recursively, so overriding one nested setting keeps its siblings.
- `packages`, `extensions`, `skills`, `prompts`, and `themes` append to the base,
  without duplicate entries. Package identity is its exact `source` string;
  an overlay entry with the same source replaces the inherited entry and filters.
- `excludePackages` removes packages by their exact source string, including any
  version suffix. This helper key does not reach PiG's generated settings.
- Resource paths keep PiG's normal resolution relative to its agent directory.

For example, when a native package replaces a TypeScript package:

```json
{
  "excludePackages": ["npm:typescript-package@1.0.0"],
  "packages": ["../../dev/native-package"],
  "extensions": [],
  "retry": { "maxRetries": 2 }
}
```

To retain an inherited package's skills but disable its extensions, add a package
object with the same source and `"extensions": []` instead of excluding it.
PiG-only auto-discovered extensions, such as the native footer, remain separate.

## Native replacements

PiG selects `pig-claude-bridge@0.1.0` instead of `pi-claude-bridge`, using the
shared `claude-bridge.json`. Pi keeps its TypeScript bridge. The PiG wrapper
provides the flake-pinned Go compiler for first-use source builds.

The native bridge has a static model catalog and cannot forward quota headers
through this PiG host. The separate quota-fetching extension remains enabled.
The existing todo-list and web-access packages are still inherited: tasks 0.1.0
uses an incompatible SDK API, and websearch 0.1.1 lacks OpenAI/Codex search and
several fetch capabilities.

## Server compaction

PiG uses the corrected server-compaction integration in `pig-plugins` rather than
loading the inherited `pi-openai-server-compaction` package separately. Regular
Pi keeps its existing package selection.

The integration retains server-side opaque compaction history while preserving
PiG's tool declarations and system/developer updates in outgoing requests. PiG's
native providers own the OpenAI WebSocket/HTTP transport; the old extension's
custom provider is not registered.
Replacing the entire request history without those declarations leaves the model
with no callable tools after compaction. The settings check verifies that PiG
selects the integrated package without the duplicate upstream extension.

## Shared startup patches

Hermes remains a shared TypeScript extension, pinned to `0.9.11` with its npm
entry disabled. `pi-hermes-patched.ts` verifies and applies the local patch
before loading it in either host. Memory initialization stays eager; only the
startup SQLite integrity scan moves to a read-only worker. Worker failure keeps
the synchronous safety/recovery path, and shutdown joins the scan before close.
See `patches/README.md` for regeneration and checks.

## Persistent edits

1. Edit `configs/pi-settings.json` for shared defaults.
2. Edit `configs/pig-settings.json` for PiG-only overrides and native replacements.
3. Rebuild and activate Home Manager for the target host.
4. Run `/reload` or restart PiG to read the activated settings.

PiG's `/settings`, `install`, `remove`, and other global settings writes affect
only the writable copy. They do **not** update either source file and survive
restarts until the next Home Manager activation replaces the copy. Put persistent
choices in the overlay. Project settings keep their normal behavior.

Activation replaces a legacy shared symlink atomically, never writing through
it into Pi's base. The copy has mode `0600`; it is not a symlink to the read-only
Nix store. Invalid input fails Nix evaluation before activation changes anything.
Starting PiG never regenerates settings. Alternate agent directories are not
managed by this activation; `PIG_USE_PI_DIRS=1` still explicitly selects Pi's tree.
Credentials, sessions, and installed package trees stay separate from Pi.

## Check

```sh
nix eval --impure --json --file scripts/ai/test-pig-settings.nix
```
