export function percent(used, total) {
  if (!Number.isFinite(used) || !Number.isFinite(total) || total <= 0) return null;
  return Math.max(0, Math.min(100, Math.round((used / total) * 100)));
}

export function parseLinux(text) {
  const lines = text.trim().split("\n");
  const load = parseFloat(lines[0]?.trim().split(/\s+/)[0]);
  const cores = parseInt(lines[1]?.trim(), 10) || 1;
  const mem = lines[3]?.trim().split(/\s+/) ?? [];
  const disk = lines[4]?.trim().split(/\s+/) ?? [];
  return {
    cpu: Number.isFinite(load) ? Math.max(0, Math.min(100, Math.round((load / cores) * 100))) : null,
    mem: percent(Number(mem[2]), Number(mem[1])),
    disk: percent(Number(disk[2]), Number(disk[1])),
  };
}

export function parseWindows(text) {
  const data = JSON.parse(text);
  return {
    cpu: Number.isFinite(data.cpu) ? Math.max(0, Math.min(100, Math.round(data.cpu))) : null,
    mem: percent(data.memUsed, data.memTotal),
    disk: percent(data.diskUsed, data.diskTotal),
  };
}

export function compact(info) {
  if (!info) return null;
  const part = (label, value) => (value == null ? null : `${label} ${value}%`);
  return [part("CPU", info.cpu), part("MEM", info.mem), part("DSK", info.disk)].filter(Boolean).join("  ·  ");
}
