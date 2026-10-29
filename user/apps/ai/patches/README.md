# Runtime patches

The npm loaders share a version- and hash-checked patch runner. It preflights
all files before replacing any, skips already-patched files, preserves file
permissions and refuses unexpected installer changes. Package updates remain
explicit: update each version pin and verified patch together.

Maintenance scripts live under `scripts/ai/<extension>/`; checks shared by
extensions live under `scripts/ai/shared/`. Add future extension scripts to their
own directory rather than the top-level `scripts/` list.

## PiG 0.5.3

`pi-pig.nix` builds the fixed-hash `v0.5.3` source archive with Go 1.27.3 and applies `pig-0.5.3-event-bus-cleanup.patch`. The upstream source commit is `526c86df885eba5e214355e7f70205e06d59bfa2`. The diagnostic build identity ends in `event-bus-cleanup`.

The patch registers migrated Node event listeners with the same runtime-owned cleanup mechanism as new listeners. This preserves explicit unsubscribe, repeated unsubscribe, reload and connection-close behavior when a native extension moves the Node bus onto the shared host registry. It does not disable extensions or hide panic diagnostics.

The patch includes mixed Go/Node regression tests. The Nix check phase runs the migrated-listener unsubscribe/idempotence case, reload guard and existing subscription-lifetime owners with disposable home and agent roots. The package retains the existing runtime tools, default agent directory and Herdr reporter.

Git-backed flake references omit untracked patch files. Until a new patch is tracked, use a `path:$PWD` flake reference so builds include it.

A temporary PiG-only activation adds a `pig` Nix profile entry at priority 4. After a Home Manager switch includes the fixed package, inspect `nix profile list` and remove that temporary entry with `nix profile remove pig` so it cannot mask later updates. Restart PiG after changing its package; `/reload` does not replace a running host binary.

When a later upstream release includes the equivalent lifetime fix, remove the patch while retaining the regression checks and return to the upstream packaging path only after mixed-extension shutdown passes. Source and module hashes must change explicitly with the release pin.

## Hermes 0.9.11

The shared Pi settings disable the npm extension entry and load
`pi-hermes-patched.ts` instead. PiG inherits this choice. Both hosts retain eager
memory initialization, automatic learning, indexing, recovery and final saves.

The patch moves startup `quick_check` onto a read-only SQLite connection in a
Node worker. A failed worker or failed check falls back to the active connection
and the existing corruption-recovery path. Closing cancels stale workers;
normal shutdown joins the scan before checkpointing and closing SQLite.
Bun keeps the original synchronous check. No integrity check is disabled.

`pi-hermes-0.9.11-runtime.json` patches the published source from
`71cf5ab7d909318a383bf52bb3ad3cf83a9efc03`. Regenerate it from untouched npm source
and a tested patched copy:

```sh
python3 scripts/ai/hermes/build-runtime-patch.py ORIGINAL_PACKAGE PATCHED_PACKAGE
node --test scripts/ai/shared/test-package-runtime.mjs scripts/ai/lens/test-runtime.mjs
HERMES_PACKAGE=PATCHED_PACKAGE node --import tsx --test scripts/ai/hermes/test-integrity.mjs
```

The integrity checks need a TypeScript loader such as `tsx` and the package's
production dependencies. They use disposable databases, not personal memory.
Run the matching upstream regressions and normal Pi/PiG launches before
updating the deployed patch.

## Lens 4.4.5

Pi installs `npm:pi-lens@4.4.5` normally. No source checkout, fork publication,
or development dependencies are needed on other machines.

The npm package's extension entry is disabled in Pi settings. The adjacent
`pi-lens-patched.ts` entry is a small loader, not another Lens distribution:

1. Check the installed package name and version.
2. Accept an already-patched bundle without rewriting it.
3. Otherwise require the exact original npm bundle hash.
4. Apply the runtime edits and verify the resulting hash.
5. Atomically replace the bundle, then load its extension factory.

After an install or reinstall restores the original bundle, the next Pi
startup reapplies the patch before loading Lens. A version or hash mismatch
reports an extension error and leaves Lens unloaded rather than loading an
unpatched or unknown version. Skills still come from the npm package.

## Behavior

- Quick startup restores export and rule metadata, not the heavy word index.
- Queries and mutation analysis load the shared index when needed.
- Existing live indexes stay in place, preserving search freshness after edits.
- Diagnostics, formatting, navigation, freshness checks, and full startup remain available.
- `PI_LENS_WARMUP_DELAY_MS` explicitly opts into eager warmup; leave it unset for demand loading.

First use still pays the deferred indexing cost.

## Checks

```sh
node --test scripts/ai/lens/test-runtime.mjs
```

The checks cover idempotence, reinstall recovery, version/hash refusal,
corrupted edits, permissions, and concurrent publication changes.

## Updating the patch

`pi-lens-4.4.5-runtime.json` is the deployed patch. The corresponding TypeScript
source changes and upstream regression tests remain in
`pi-lens-4.4.5-demand-startup.patch` for review and rebuilding only.
Their upstream base is `3778663223c70ccabb11c352840817bb8fb9fb4e` (Lens 4.4.5).

To regenerate the runtime data, build the patched source, obtain the untouched
bundle from the published npm tarball, then run:

```sh
python3 scripts/ai/lens/build-runtime-patch.py ORIGINAL_INDEX_JS PATCHED_INDEX_JS
```

The generator refuses an original bundle whose hash differs from the pinned
release. When upgrading, update the npm version, source patch, generator pin,
and loader data together, then rerun the upstream regressions and real Pi
startup/tool checks. Never generate from an already-patched npm installation.
