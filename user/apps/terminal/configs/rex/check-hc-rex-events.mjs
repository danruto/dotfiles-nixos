// node ~/dotfiles-nixos/user/apps/terminal/configs/rex/check-hc-rex-events.mjs
import assert from "node:assert/strict";
import { eventLines, isOwnClientEvent } from "./hc-rex-events.mjs";

const client = (type) => ({ type: "session_event", payload: { session_id: "s1", event: { type } } });

assert.ok(isOwnClientEvent(client("client_connected")), "a connect is this script's own read");
assert.ok(isOwnClientEvent(client("client_disconnected")), "and so is the disconnect");
assert.ok(!isOwnClientEvent({ type: "session_event", payload: { event: { type: "block_created" } } }), "layout events count");
assert.ok(!isOwnClientEvent({ type: "session_created", payload: {} }), "unwrapped events count");
assert.ok(!isOwnClientEvent(null), "no payload is not noise");

const lines = [
  client("client_connected"),
  client("client_disconnected"),
  { type: "session_event", payload: { event: { type: "window_created" } } },
  { type: "session_removed", payload: { session_id: "s1" } },
].map((ev) => JSON.stringify(ev) + "\n");
const stream = lines.join("");

const once = eventLines();
assert.deepEqual(once(stream).map((ev) => ev.type), ["session_event", "session_removed"], "noise is dropped, the rest kept");

// Chunks split anywhere, including mid-line, and a partial line waits for its newline.
const split = eventLines();
assert.deepEqual(split(stream.slice(0, 37)), [], "a partial line yields nothing yet");
assert.deepEqual(split(stream.slice(37, 41)), [], "still mid-line");
const rest = split(stream.slice(41));
assert.equal(rest.length, 2, "the completes arrive once their newline does");

const junk = eventLines();
assert.deepEqual(
  junk("not json\n" + lines[2] + lines[3]).map((ev) => ev.type),
  ["session_event", "session_removed"],
  "junk lines are skipped, the events around them kept",
);

console.log("ok");
