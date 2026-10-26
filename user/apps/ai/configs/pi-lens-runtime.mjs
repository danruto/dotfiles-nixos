import fs from "node:fs";
import { createHash, randomUUID } from "node:crypto";
import path from "node:path";

const specificationURL = new URL("../patches/pi-lens-4.4.5-runtime.json", import.meta.url);
const digest = (bytes) => createHash("sha256").update(bytes).digest("hex");

export function patchNpmLens(packageRoot, specification) {
  let manifest;
  try {
    specification ??= JSON.parse(fs.readFileSync(specificationURL, "utf8"));
    manifest = JSON.parse(fs.readFileSync(path.join(packageRoot, "package.json"), "utf8"));
  } catch (cause) {
    throw new Error(`Cannot read Lens patch/package metadata for ${packageRoot}`, { cause });
  }
  if (manifest.name !== "pi-lens" || manifest.version !== specification.version) {
    throw new Error(`Lens patch requires pi-lens ${specification.version}; found ${manifest.name} ${manifest.version}`);
  }

  const entryPath = path.join(packageRoot, "dist", "index.js");
  const original = fs.readFileSync(entryPath);
  const hash = digest(original);
  if (hash === specification.patchedSha256) return { entryPath, changed: false };
  if (hash !== specification.originalSha256) {
    throw new Error(`Lens ${specification.version} bundle hash mismatch; refusing to patch ${entryPath}`);
  }

  const text = original.toString("utf8");
  const parts = [];
  let cursor = 0;
  for (const { start, oldText, newText } of specification.edits) {
    if (!Number.isInteger(start) || start < cursor || text.slice(start, start + oldText.length) !== oldText) {
      throw new Error("Lens runtime patch does not match the verified bundle");
    }
    parts.push(text.slice(cursor, start), newText);
    cursor = start + oldText.length;
  }
  parts.push(text.slice(cursor));
  const patched = parts.join("");
  if (digest(patched) !== specification.patchedSha256) {
    throw new Error("Lens runtime patch produced an unexpected bundle hash");
  }

  const temporary = `${entryPath}.patch-${process.pid}-${randomUUID()}`;
  try {
    fs.writeFileSync(temporary, patched, { flag: "wx", mode: fs.statSync(entryPath).mode & 0o777 });
    const current = digest(fs.readFileSync(entryPath));
    if (current !== specification.originalSha256 && current !== specification.patchedSha256) {
      throw new Error("Lens bundle changed during patching; replacement cancelled");
    }
    fs.renameSync(temporary, entryPath);
  } finally {
    fs.rmSync(temporary, { force: true });
  }
  return { entryPath, changed: true };
}
