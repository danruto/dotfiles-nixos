export function statusLabel(status) {
  return { working: "Working", blocked: "Needs you", done: "Done", idle: "Idle" }[status] ?? "Terminal";
}

export function threadGroups(spaces, agents, panes, pins, query, settled = false) {
  const search = query.trim().toLowerCase();
  return spaces.map(space => ({
    space,
    threads: space.tabs.filter(tab => Boolean(tab.settled) === settled).map(tab => {
      const mine = agents.filter(agent => agent.tab === tab.id);
      const pane = panes.find(pane => pane.tab === tab.id && pane.focused) ?? panes.find(pane => pane.tab === tab.id);
      const title = tab.named ? tab.name : mine[0]?.title || mine[0]?.program?.name || pane?.title || `Terminal ${tab.index}`;
      return { tab, title, agents: mine, branch: pane?.branch ?? space.branch, pinned: pins.includes(tab.id) };
    }).filter(thread => !search || [space.name, space.machine, thread.title, thread.branch, statusLabel(thread.tab.status), ...thread.agents.map(agent => agent.program?.name)].join(" ").toLowerCase().includes(search))
      .sort((a, b) => Number(b.pinned) - Number(a.pinned)),
  })).filter(group => group.threads.length);
}
