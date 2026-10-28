import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";
import { patchNpmPackageFiles } from "../../../user/apps/ai/configs/pi-package-runtime.mjs";

const digest = (text) => createHash("sha256").update(text).digest("hex");

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pi-package-patch-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.writeFileSync(path.join(root, "package.json"), JSON.stringify({ name: "fixture", version: "1.0.0" }));
  const files = ["first.js", "second.js"].map((name) => {
    fs.writeFileSync(path.join(root, name), "original");
    return {
      path: name,
      originalSha256: digest("original"),
      patchedSha256: digest("patched"),
      edits: [{ start: 0, oldText: "original", newText: "patched" }],
    };
  });
  return { root, specification: { name: "fixture", version: "1.0.0", files } };
}

test("patches multiple files and resumes from a partially applied known patch", (t) => {
  const { root, specification } = fixture(t);
  fs.writeFileSync(path.join(root, "first.js"), "patched");
  assert.equal(patchNpmPackageFiles(root, specification, "Fixture").changed, true);
  for (const file of specification.files) assert.equal(fs.readFileSync(path.join(root, file.path), "utf8"), "patched");
  assert.equal(patchNpmPackageFiles(root, specification, "Fixture").changed, false);
});

test("preserves source permissions even under a restrictive process umask", (t) => {
  const { root, specification } = fixture(t);
  for (const file of specification.files) fs.chmodSync(path.join(root, file.path), 0o640);
  const previous = process.umask(0o077);
  try {
    patchNpmPackageFiles(root, specification, "Fixture");
  } finally {
    process.umask(previous);
  }
  for (const file of specification.files) assert.equal(fs.statSync(path.join(root, file.path)).mode & 0o777, 0o640);
});

test("reads each already patched file only once", (t) => {
  const { root, specification } = fixture(t);
  patchNpmPackageFiles(root, specification, "Fixture");
  const read = fs.readFileSync;
  const targets = new Set(specification.files.map((file) => path.join(root, file.path)));
  let reads = 0;
  t.mock.method(fs, "readFileSync", (file, ...args) => {
    if (targets.has(String(file))) reads++;
    return read(file, ...args);
  });
  assert.equal(patchNpmPackageFiles(root, specification, "Fixture").changed, false);
  assert.equal(reads, targets.size);
});

test("preflights every file before replacing any file", (t) => {
  const { root, specification } = fixture(t);
  fs.writeFileSync(path.join(root, "second.js"), "unknown");
  assert.throws(() => patchNpmPackageFiles(root, specification, "Fixture"), /hash mismatch/);
  assert.equal(fs.readFileSync(path.join(root, "first.js"), "utf8"), "original");
  assert.equal(fs.readFileSync(path.join(root, "second.js"), "utf8"), "unknown");
});

test("checks installer changes to every file before publication and cleans temporary files", (t) => {
  const { root, specification } = fixture(t);
  const write = fs.writeFileSync;
  t.mock.method(fs, "writeFileSync", (file, ...args) => {
    write(file, ...args);
    if (String(file).includes(".patch-")) write(path.join(root, "second.js"), "installer");
  });
  assert.throws(() => patchNpmPackageFiles(root, specification, "Fixture"), /changed during patching/);
  assert.equal(fs.readFileSync(path.join(root, "first.js"), "utf8"), "original");
  assert.equal(fs.readFileSync(path.join(root, "second.js"), "utf8"), "installer");
  assert.deepEqual(fs.readdirSync(root).sort(), ["first.js", "package.json", "second.js"]);
});

test("refuses absolute paths and parent traversal", (t) => {
  const { root, specification } = fixture(t);
  for (const filePath of ["../outside.js", path.resolve(root, "first.js")]) {
    const invalid = structuredClone(specification);
    invalid.files[0].path = filePath;
    assert.throws(() => patchNpmPackageFiles(root, invalid, "Fixture"), /escapes its package/);
  }
  assert.equal(fs.readFileSync(path.join(root, "first.js"), "utf8"), "original");
});
