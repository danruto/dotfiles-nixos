/** @param {string} href @param {string} current */
export function linkTarget(href, current) {
  const value = href.trim();
  if (/^https?:\/\/[^\s]+$/i.test(value)) return { kind: "external", url: value };
  if (value.startsWith("#")) return { kind: "anchor" };
  if (!value || /^[a-z][a-z0-9+.-]*:/i.test(value) || value.startsWith("//")) return { kind: "unsupported" };
  const target = value.split(/[?#]/)[0];
  let decoded;
  try { decoded = decodeURIComponent(target); }
  catch { return { kind: "unsupported" }; }
  if (!/\.(?:md|markdown)$/i.test(decoded) || /[\x00-\x1f]/.test(decoded)) return { kind: "unsupported" };
  const parts = (decoded.startsWith("/") ? decoded : current.slice(0, current.lastIndexOf("/") + 1) + decoded).split("/");
  const path = [];
  for (const part of parts) {
    if (part === "..") path.pop();
    else if (part && part !== ".") path.push(part);
  }
  return { kind: "document", path: "/" + path.join("/") };
}
