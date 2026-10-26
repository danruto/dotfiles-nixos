import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { patchNpmLens } from "./pi-lens-runtime.mjs";

export default async function (pi: ExtensionAPI) {
  const packageRoot = path.join(getAgentDir(), "npm", "node_modules", "pi-lens");
  const { entryPath } = patchNpmLens(packageRoot);
  const { default: loadLens } = await import(pathToFileURL(entryPath).href);
  await loadLens(pi);
}
