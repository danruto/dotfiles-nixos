import fs from "node:fs";
import { createHash, randomUUID } from "node:crypto";
import path from "node:path";

const digest = (bytes) => createHash("sha256").update(bytes).digest("hex");

export function patchNpmPackageFiles(packageRoot, specification, label) {
  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(path.join(packageRoot, "package.json"), "utf8"));
  } catch (cause) {
    throw new Error(`Cannot read ${label} patch/package metadata for ${packageRoot}`, { cause });
  }
  if (manifest.name !== specification.name || manifest.version !== specification.version) {
    throw new Error(`${label} patch requires ${specification.name} ${specification.version}; found ${manifest.name} ${manifest.version}`);
  }

  const plans = specification.files.map((file) => {
    const filePath = path.resolve(packageRoot, file.path);
    const relative = path.relative(path.resolve(packageRoot), filePath);
    if (!relative || path.isAbsolute(file.path) || relative === ".." || relative.startsWith(`..${path.sep}`)) {
      throw new Error(`${label} patch file escapes its package`);
    }
    const original = fs.readFileSync(filePath);
    const hash = digest(original);
    if (hash === file.patchedSha256) return { filePath, file, changed: false };
    if (hash !== file.originalSha256) {
      throw new Error(`${label} ${specification.version} bundle hash mismatch; refusing to patch ${filePath}`);
    }

    const text = original.toString("utf8");
    const parts = [];
    let cursor = 0;
    for (const { start, oldText, newText } of file.edits) {
      if (!Number.isInteger(start) || start < cursor || text.slice(start, start + oldText.length) !== oldText) {
        throw new Error(`${label} runtime patch does not match the verified bundle`);
      }
      parts.push(text.slice(cursor, start), newText);
      cursor = start + oldText.length;
    }
    parts.push(text.slice(cursor));
    const patched = parts.join("");
    if (digest(patched) !== file.patchedSha256) {
      throw new Error(`${label} runtime patch produced an unexpected bundle hash`);
    }
    return { filePath, file, changed: true, patched };
  });

  if (plans.every((plan) => !plan.changed)) {
    return { paths: plans.map((plan) => plan.filePath), changed: false };
  }

  const temporary = [];
  try {
    for (const plan of plans.filter((plan) => plan.changed)) {
      const filePath = `${plan.filePath}.patch-${process.pid}-${randomUUID()}`;
      temporary.push({ filePath, target: plan.filePath });
      const mode = fs.statSync(plan.filePath).mode & 0o777;
      fs.writeFileSync(filePath, plan.patched, { flag: "wx", mode });
      fs.chmodSync(filePath, mode);
    }
    for (const { filePath, file } of plans) {
      const current = digest(fs.readFileSync(filePath));
      if (current !== file.originalSha256 && current !== file.patchedSha256) {
        throw new Error(`${label} bundle changed during patching; replacement cancelled`);
      }
    }
    for (const { filePath, target } of temporary) fs.renameSync(filePath, target);
  } finally {
    for (const { filePath } of temporary) fs.rmSync(filePath, { force: true });
  }
  return { paths: plans.map((plan) => plan.filePath), changed: plans.some((plan) => plan.changed) };
}
