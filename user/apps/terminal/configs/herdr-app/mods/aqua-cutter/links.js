/** @param {string} href @param {string} current */
export function linkTarget(href, current) {
  const value = href.trim();
  if (/^https?:\/\/[^\s]+$/i.test(value)) return { kind: "external", url: value };
  if (value.startsWith("#")) return { kind: "anchor" };
  if (!value || (/^[a-z][a-z0-9+.-]*:/i.test(value) && !/^[a-z]:[\\/]/i.test(value)) || value.startsWith("//")) return { kind: "unsupported" };
  const target = value.split(/[?#]/)[0];
  let decoded;
  try { decoded = decodeURIComponent(target); }
  catch { return { kind: "unsupported" }; }
  if (!/\.(?:md|markdown)$/i.test(decoded) || /[\x00-\x1f]/.test(decoded)) return { kind: "unsupported" };
  const windows = /^[A-Za-z]:[\\/]/.test(current) || current.startsWith("\\\\");
  const separator = windows ? "\\" : "/";
  const base = windows ? current.replace(/\//g, "\\") : current;
  const relative = windows ? decoded.replace(/\//g, "\\") : decoded;
  const absolute = windows ? /^[A-Za-z]:\\/.test(relative) || relative.startsWith("\\\\") : relative.startsWith("/");
  const cut = Math.max(base.lastIndexOf("/"), windows ? base.lastIndexOf("\\") : -1);
  const combined = absolute ? relative : base.slice(0, cut + 1) + relative;
  const parts = combined.split(separator), path = [];
  for (const part of parts) {
    if (part === "..") path.pop();
    else if (part && part !== ".") path.push(part);
  }
  if (windows) {
    const unc = combined.startsWith("\\\\");
    return { kind: "document", path: (unc ? "\\\\" : "") + path.join("\\") };
  }
  return { kind: "document", path: "/" + path.join("/") };
}
