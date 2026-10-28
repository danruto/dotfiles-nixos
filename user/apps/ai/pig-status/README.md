# PiG status footer

A compact, single-line Go subprocess footer for PiG 0.5.3. The editor, transcript, selectors and working indicator stay native.

## Display

- Context gauge, with warning at 70% and error at 90%; unknown usage stays `--`.
- Model/provider and thinking level, space permitting.
- Working directory, cached Git branch, session name and time open in this process.
- Input/output tokens, cost and remaining subscription quota; `left` applies to every quota window.
- Other extension statuses, including Lens, sorted by key.

The footer has two groups with flexible space between them:

- **Left:** project directory, Git branch, remaining quota, session name and time open.
- **Right:** context gauge, model, thinking level, tokens, cost, provider and other extension statuses.

The right group stays against the terminal's right edge. The footer never wraps; lower-priority fields disappear as the pane narrows. Context, remaining quota, model, thinking, tokens and cost retain priority over metadata. Below 70 columns the gauge becomes a plain percentage. Width measurement, spacing and truncation use the SDK's Unicode/ANSI-aware helpers. Theme, resize and status changes use the SDK's cached footer renderer.

Context and thinking refresh on session, model, compaction and turn events. Elapsed time updates when the footer renders, not from a background timer. Git information is the host's cached branch, not a separate dirty-file scan.

This extension reuses the existing usage adapter and installed usage provider. The adapter publishes structured `pig-status:usage` events containing `input`, `output`, `cost` and quota `windows`; the footer does not parse display strings. Pi keeps its original text status. The Go process does not inspect history, poll quota endpoints, read credentials or spawn background workers. Accounting remains the adapter's responsibility.

## Build and load

`pi-pig.nix` builds and tests the executable against the SDK from the same pinned PiG release. Home Manager links its package directory into PiG's extension directory only. The package manifest explicitly selects `bin/pig-status`; a bare executable link is not automatically discovered. Normal startup needs neither Go nor Node for this footer; the existing usage provider still uses Node.

For development with Go on PATH:

```sh
scripts/check-pig-status.sh
pig install ./user/apps/ai/pig-status --validate-only --json
pig --no-extensions -e ./user/apps/ai/pig-status
```

The last command intentionally excludes the usage provider, so only native metadata appears on the line. Use the normal configured PiG session to see token, cost, quota and other statuses. After rebuilding the package and updating its link, use `/reload` in PiG. Verify that `pig status --json` lists an enabled `pig-status` extension; binary validation alone does not prove discovery. Pi remains on its native footer.
