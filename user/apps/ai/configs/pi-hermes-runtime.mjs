import fs from "node:fs";
import path from "node:path";
import { patchNpmPackageFiles } from "./pi-package-runtime.mjs";

const specificationURL = new URL("../patches/pi-hermes-0.9.11-runtime.json", import.meta.url);

export function patchNpmHermes(packageRoot) {
  let specification;
  try {
    specification = JSON.parse(fs.readFileSync(specificationURL, "utf8"));
  } catch (cause) {
    throw new Error(`Cannot read Hermes patch metadata for ${packageRoot}`, { cause });
  }
  const result = patchNpmPackageFiles(packageRoot, specification, "Hermes");
  return { entryPath: path.join(packageRoot, "src/index.ts"), changed: result.changed };
}
