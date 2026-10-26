# Lens npm runtime patch

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
node --test scripts/test-pi-lens-runtime.mjs
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
python3 scripts/build-pi-lens-runtime-patch.py ORIGINAL_INDEX_JS PATCHED_INDEX_JS
```

The generator refuses an original bundle whose hash differs from the pinned
release. When upgrading, update the npm version, source patch, generator pin,
and loader data together, then rerun the upstream regressions and real Pi
startup/tool checks. Never generate from an already-patched npm installation.
