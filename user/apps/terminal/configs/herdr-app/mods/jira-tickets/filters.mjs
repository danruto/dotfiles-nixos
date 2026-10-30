export function normalizeFilters(value) {
  return {
    source: ['All', 'Assigned', '@mentions'].includes(value?.source) ? value.source : 'All',
    hideDone: value?.hideDone === true,
    statuses: Array.isArray(value?.statuses) ? [...new Set(value.statuses.filter(status => typeof status === 'string' && status))] : [],
  };
}

export function filterRows(rows, value) {
  const filters = normalizeFilters(value);
  return rows.filter(row => (filters.source === 'All' || (filters.source === 'Assigned' ? row.assigned : row.mentioned))
    && (!filters.hideDone || row.statusCategory !== 'done')
    && (!filters.statuses.length || filters.statuses.includes(row.status)));
}

export function statusOptions(rows) {
  return [...new Set(rows.map(row => row.status).filter(Boolean))].sort((a, b) => a.localeCompare(b));
}
