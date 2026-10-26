import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";
import { patchNpmLens } from "../user/apps/ai/configs/pi-lens-runtime.mjs";

const digest = (text) => createHash("sha256").update(text).digest("hex");

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "dotfiles-lens-runtime-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, "dist"));
  const manifestPath = path.join(root, "package.json");
  fs.writeFileSync(manifestPath, JSON.stringify({ name: "pi-lens", version: "4.4.5" }));
  const entryPath = path.join(root, "dist", "index.js");
  const original = 'export const mode = "original";\n';
  const patched = 'export const mode = "on-demand";\n';
  fs.writeFileSync(entryPath, original, { mode: 0o640 });
  const specification = {
    version: "4.4.5",
    originalSha256: digest(original),
    patchedSha256: digest(patched),
    edits: [{ start: original.indexOf("original"), oldText: "original", newText: "on-demand" }],
  };
  return { root, manifestPath, entryPath, original, patched, specification };
}

test("patches the expected bundle and preserves permissions", (t) => {
  const f = fixture(t);
  assert.equal(patchNpmLens(f.root, f.specification).changed, true);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.patched);
  assert.equal(fs.statSync(f.entryPath).mode & 0o777, 0o640);
  assert.deepEqual(fs.readdirSync(path.dirname(f.entryPath)), ["index.js"]);
});

test("an already patched bundle is not rewritten", (t) => {
  const f = fixture(t);
  patchNpmLens(f.root, f.specification);
  t.mock.method(fs, "renameSync", () => assert.fail("rewrote an already patched bundle"));
  assert.equal(patchNpmLens(f.root, f.specification).changed, false);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.patched);
});

test("reapplies after a reinstall restores the original bundle", (t) => {
  const f = fixture(t);
  patchNpmLens(f.root, f.specification);
  fs.writeFileSync(f.entryPath, f.original);
  assert.equal(patchNpmLens(f.root, f.specification).changed, true);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.patched);
});

test("refuses another package or version without changing its bundle", (t) => {
  const f = fixture(t);
  for (const manifest of [{ name: "other", version: "4.4.5" }, { name: "pi-lens", version: "4.4.6" }]) {
    fs.writeFileSync(f.manifestPath, JSON.stringify(manifest));
    assert.throws(() => patchNpmLens(f.root, f.specification), /requires pi-lens 4\.4\.5/);
    assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.original);
  }
});

test("refuses unknown bundle bytes without overwriting them", (t) => {
  const f = fixture(t);
  fs.writeFileSync(f.entryPath, "unknown bundle");
  assert.throws(() => patchNpmLens(f.root, f.specification), /bundle hash mismatch/);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), "unknown bundle");
});

test("reports malformed package metadata before changing the bundle", (t) => {
  const f = fixture(t);
  fs.writeFileSync(f.manifestPath, "{broken");
  assert.throws(() => patchNpmLens(f.root, f.specification), /Cannot read Lens patch\/package metadata/);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.original);
});

test("refuses mismatching edits and a corrupted replacement", (t) => {
  const f = fixture(t);
  const mismatch = structuredClone(f.specification);
  mismatch.edits[0].oldText = "absent";
  assert.throws(() => patchNpmLens(f.root, mismatch), /does not match/);
  const corrupted = structuredClone(f.specification);
  corrupted.edits[0].newText = "different";
  assert.throws(() => patchNpmLens(f.root, corrupted), /unexpected bundle hash/);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.original);
});

test("rejects overlapping edit ranges", (t) => {
  const f = fixture(t);
  f.specification.edits.push({ ...f.specification.edits[0] });
  assert.throws(() => patchNpmLens(f.root, f.specification), /does not match/);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.original);
});

test("does not replace an installer’s changed bundle during publication", (t) => {
  const f = fixture(t);
  const write = fs.writeFileSync;
  t.mock.method(fs, "writeFileSync", (file, ...args) => {
    write(file, ...args);
    if (String(file).startsWith(`${f.entryPath}.patch-`)) write(f.entryPath, "installer replacement");
  });
  assert.throws(() => patchNpmLens(f.root, f.specification), /changed during patching/);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), "installer replacement");
  assert.deepEqual(fs.readdirSync(path.dirname(f.entryPath)), ["index.js"]);
});

test("accepts a concurrent application of the same verified patch", (t) => {
  const f = fixture(t);
  const write = fs.writeFileSync;
  t.mock.method(fs, "writeFileSync", (file, ...args) => {
    write(file, ...args);
    if (String(file).startsWith(`${f.entryPath}.patch-`)) write(f.entryPath, f.patched);
  });
  patchNpmLens(f.root, f.specification);
  assert.equal(fs.readFileSync(f.entryPath, "utf8"), f.patched);
  assert.deepEqual(fs.readdirSync(path.dirname(f.entryPath)), ["index.js"]);
});
