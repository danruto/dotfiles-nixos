import fs from "node:fs";
import { patchNpmPackageFiles } from "./pi-package-runtime.mjs";

const specificationURL = new URL("../patches/pi-lens-4.4.5-runtime.json", import.meta.url);

export function patchNpmLens(packageRoot, specification) {
  try {
    specification ??= JSON.parse(fs.readFileSync(specificationURL, "utf8"));
  } catch (cause) {
    throw new Error(`Cannot read Lens patch/package metadata for ${packageRoot}`, { cause });
  }
  const result = patchNpmPackageFiles(packageRoot, {
    name: "pi-lens",
    version: specification.version,
    files: [{ ...specification, path: "dist/index.js" }],
  }, "Lens");
  return { entryPath: result.paths[0], changed: result.changed };
}
