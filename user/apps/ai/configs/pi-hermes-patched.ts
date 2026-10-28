import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { patchNpmHermes } from "./pi-hermes-runtime.mjs";

export default async function (pi: ExtensionAPI) {
  const packageRoot = path.join(getAgentDir(), "npm", "node_modules", "pi-hermes-memory");
  const { entryPath } = patchNpmHermes(packageRoot);
  const { default: loadHermes } = await import(pathToFileURL(entryPath).href);
  await loadHermes(pi);
}
