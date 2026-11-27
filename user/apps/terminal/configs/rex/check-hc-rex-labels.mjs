// node ~/dotfiles-nixos/user/apps/terminal/configs/rex/check-hc-rex-labels.mjs
import assert from "node:assert/strict";
import fs from "node:fs";
import { GLYPHS, bareLabel, withGlyphOf } from "./hc-rex-labels.mjs";

assert.equal(bareLabel("🔵 rem"), "rem", "status glyph is dropped");
assert.equal(bareLabel("🟢 🔵 rem"), "🔵 rem", "only the one status.lua adds");
assert.equal(bareLabel("rem"), "rem", "a plain label is left alone");
assert.equal(bareLabel("🔵rem"), "🔵rem", "a glyph that is part of the name stays");
assert.equal(bareLabel(undefined), "", "no label");
assert.equal(withGlyphOf("🟡 old", "new"), "🟡 new", "a rename keeps the status");
assert.equal(withGlyphOf("old", "new"), "new", "no status, no glyph");

const lua = fs.readFileSync(new URL("./herdr.lua", import.meta.url), "utf8");
const luaGlyphs = lua.match(/herdr\.glyphs = \{([^}]*)\}/)[1].match(/"([^"]+)"/g).map((s) => s.slice(1, -1));
assert.deepEqual(GLYPHS, luaGlyphs, "same glyphs as herdr.lua");
console.log("ok");
