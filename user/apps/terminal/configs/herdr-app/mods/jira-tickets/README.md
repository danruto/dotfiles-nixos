# My Jira

A read-only Herdr ticket feed backed by `acli` on a connected machine. It includes all tickets currently assigned to the authenticated account, plus exact account mentions in comments within an explicitly configured project/history scope.

## Setup

1. Apply Home Manager to install the `herdr-jira` launcher. It uses Nix's Node and `acli` binaries, independent of the GUI's command path. Install the same source checkout on the helper machine.
2. Authenticate there with `acli jira auth login`.
3. Create `~/.config/herdr-jira/config.json` on that machine, outside this repository:

   ```json
   {"projects":["DEMO"],"days":90}
   ```

   Replace the example project key with the projects you approve for comment scanning. Assigned tickets are not restricted to these projects or this history window. If you have no assigned tickets to identify your account, also provide your Atlassian `accountId` in this private file.

4. Create `~/.config/herdr-app/jira-tickets.json` on the computer running the window:

   ```json
   {"on":"your-vm"}
   ```

   Use the machine name shown by `hc machine ls`, or `null` for local execution. No requests run until this file or explicit pane props identify the helper machine.

5. Click **Jira** beside **Files** and **Changes** in either personal layout. Clicking again closes the right sidebar. To show it from a command:

   ```sh
   herdr-app do layout.select '{"stack":"panel-body","child":"jira"}'
   herdr-app do layout.show '{"id":"panel"}'
   ```

## Behaviour

- All, Assigned and @mentions filters share one date-sorted feed. A ticket in both groups appears once.
- **All statuses** opens a multi-select list of exact status names. **All statuses** inside the list clears that restriction.
- **Hide done** removes tickets whose actual Jira status category is `done`, including differently named terminal statuses. It does not guess from the status name. Unknown categories remain visible while their metadata loads.
- Filter choices are shared between copies and persisted locally by Herdr. Counts reflect the current status/done filters.
- The main date is the ticket's latest update, newest first. Mentioned rows also show the matching comment's creation date, not a guaranteed time the mention was inserted during an edit.
- Comment matching uses structured Atlassian account IDs or account-ID mention markup, never a display-name text search.
- The history window applies to ticket update dates. An old mention on a recently updated ticket is included; an old ticket outside the window is not scanned unless assigned to you.
- Initial discovery and comment scanning resume across short requests. Assigned tickets appear first; unknown dates and incomplete scans are explicitly labelled.
- Partial embedded comment lists trigger a fully paginated comment request. Unreadable tickets are counted as incomplete and retried on the next search cycle.
- Automatic refresh runs only while the configured Jira layout block is visible. Hiding/collapsing the sidebar, selecting Files/Changes, or hiding an ancestor pauses it. A due refresh resumes within ten seconds of reopening. After indexing, refreshes are two minutes apart.
- Changed-ticket searches overlap their watermark to cover minute-level query precision. The Refresh button can request a continuation immediately. Copies opened outside a layout block use manual refresh unless given a valid `layoutBlock` prop.
- A failed connection keeps the last successful feed visible. Clicking a ticket opens its Jira Cloud URL in the window computer's browser.

## Privacy and limits

Credentials remain in `acli` on the helper machine. `~/.cache/herdr-jira/feed.json` stores ticket summaries, dates, matching flags, and scan progress there with private permissions. It does not retain comment bodies. Jira data is read only; there are no ticket/comment write commands.

Scope configuration, account identity, cache, screenshot evidence and the active VM name are not committed. The window receives only the rows and progress needed to render the feed. Another helper copy shares the same cache and refresh lock.

The helper uses 22-second batches, three concurrent ticket-detail reads, and one-shot CLI processes; no server or background daemon is installed. A lightweight local timer checks visibility, but it starts no helper requests while hidden. A request already in progress can finish; closing the mod stops new requests. This is polling, not a real-time notification inbox, and it does not discover mentions outside its stated project/history scope.

## Deferred CLI limitations

True board membership and column filters, and status-change controls, are not implemented. `acli` board details omit column mappings and membership, and it cannot list the allowed transitions for a ticket. A column can contain several statuses, so status filters are not labelled as board-column filters. No API token or REST adapter is installed.

## Checks

From the shared configuration root:

```sh
node tests/check-jira.mjs
node tests/check-jira-sidebar.mjs
herdr-app check "$HOME/.config/herdr-app/mods/jira-tickets"
herdr-app status
```
