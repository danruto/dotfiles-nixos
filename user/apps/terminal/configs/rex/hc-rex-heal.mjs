// A Rex server that restarts brings its panes back with the same block IDs but
// a fresh login shell in place of `hc-rex-attach`. The state file still maps
// those blocks to hc terminals, so the pane and herdr's terminal drift apart.
// Each mirrored pane is checked for the attach command that should be in it.

import fs from "node:fs";

// What to do with a mirrored pane, from its `process` info and the command
// line of its child: "ok", "reattach" (a plain shell at its prompt, safe to
// replace), "busy" (a plain shell running something: leave it until it's
// idle), or "unknown" (couldn't tell).
export function paneState(proc, cmdline) {
  const child = proc?.child;
  if (!child || cmdline == null) return "unknown";
  if (cmdline.includes("hc-rex-attach")) return "ok";
  const fg = proc.foreground;
  if (fg && fg.pid !== child.pid) return "busy";
  return "reattach";
}

// /proc/PID/cmdline with its NUL separators as spaces; null where there's no
// /proc (the Mac) or the process is gone.
export function cmdlineOf(pid) {
  try {
    return fs.readFileSync(`/proc/${pid}/cmdline`, "utf8").replaceAll("\0", " ");
  } catch {
    return null;
  }
}
