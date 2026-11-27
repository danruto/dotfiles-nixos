// node ~/dotfiles-nixos/user/apps/terminal/configs/rex/check-hc-rex-heal.mjs
import assert from "node:assert/strict";
import { paneState, cmdlineOf } from "./hc-rex-heal.mjs";

const shell = { pid: 407, name: "fish" };
const attach = "/bin/sh /home/me/.config/rex/hc-rex-attach /bin/hc t5 ";

assert.equal(paneState({ child: { pid: 9 }, foreground: { pid: 12, name: "hc" } }, attach), "ok", "attach pane");
assert.equal(paneState({ child: shell, foreground: shell }, "-fish "), "reattach", "idle plain shell");
assert.equal(paneState({ child: shell, foreground: { pid: 803525, name: "claude" } }, "-fish "), "busy", "agent in a plain shell");
assert.equal(paneState({ child: shell }, "-fish "), "reattach", "no foreground reported is the shell itself");
assert.equal(paneState(null, "-fish "), "unknown", "no process info");
assert.equal(paneState({ child: shell, foreground: shell }, null), "unknown", "no command line");
assert.equal(cmdlineOf(2 ** 31 - 1), null, "a missing process");
console.log("ok");
