const KEY = /^[A-Z][A-Z0-9_]*-\d+$/;

export function validateConfig(config) {
  if (!Array.isArray(config.projects) || !config.projects.length || !config.projects.every(project => /^[A-Z][A-Z0-9_]*$/.test(project))) throw new Error('Configure the approved mention project keys');
  if (!Number.isInteger(config.days) || config.days < 1 || config.days > 365) throw new Error('Mention history must be between 1 and 365 days');
  return { projects: [...new Set(config.projects)].sort(), days: config.days, accountId: config.accountId || null };
}

export function identity(text) {
  const clean = text.replace(/\x1b\[[0-9;]*m/g, '');
  const site = clean.match(/^\s*Site:\s*(\S+)/m)?.[1];
  const email = clean.match(/^\s*Email:\s*(\S+)/m)?.[1];
  if (!site || !email) throw new Error('Run acli jira auth login on the configured machine');
  const url = new URL(site.includes('://') ? site : `https://${site}`);
  if (url.protocol !== 'https:' || url.username || url.password || url.pathname !== '/' || !url.hostname.endsWith('.atlassian.net')) throw new Error('Expected an HTTPS Jira Cloud site');
  return { site: url.origin, email };
}

export function hasMention(body, accountId) {
  if (!accountId) return false;
  if (typeof body === 'string') return body.includes(`[~accountid:${accountId}]`);
  if (!body || typeof body !== 'object') return false;
  if (body.type === 'mention' && body.attrs?.id === accountId) return true;
  return Array.isArray(body.content) && body.content.some(node => hasMention(node, accountId));
}

export function commentsFrom(value) {
  const comments = Array.isArray(value) ? value : value?.comments;
  if (!Array.isArray(comments)) throw new Error('Unexpected comment JSON from acli');
  if (!Array.isArray(value) && Number.isFinite(value.total) && comments.length < value.total) throw new Error('Comment response was not fully paginated');
  return comments;
}

function issuesFrom(value) {
  if (!Array.isArray(value) || !value.every(issue => KEY.test(issue?.key) && issue.fields && typeof issue.fields.summary === 'string')) throw new Error('Unexpected ticket JSON from acli');
  return value;
}

function statusFields(status) {
  return { status: status?.name || '', statusId: status?.id || null, statusCategory: status?.statusCategory?.key || null };
}

function latestMention(comments, accountId) {
  return comments.filter(comment => hasMention(comment.body, accountId)).map(comment => comment.created).filter(date => Number.isFinite(Date.parse(date))).sort().at(-1) || null;
}

export async function updateFeed({ config, state, account, cli, now = Date.now(), deadline = Infinity, clock = Date.now, concurrency = 3, save = async () => {} }) {
  config = validateConfig(config);
  const scope = JSON.stringify({ account, config });
  if (state?.scope !== scope || state.version !== 1) state = { version: 1, scope, rows: {}, pending: [], failures: {}, assigned: [], searchedAt: 0, candidates: 0, total: 0, checkedAt: null };
  const enqueue = keys => { state.pending = [...new Set([...state.pending, ...keys])]; };
  if (state.discovery || !state.searchedAt || now - state.searchedAt >= 120000) {
    if (!state.discovery) {
      const assigned = issuesFrom(await cli(['workitem', 'search', '--jql', 'assignee = currentUser() ORDER BY updated DESC', '--fields', 'key,summary,status,assignee', '--paginate', '--json']));
      const ids = [...new Set(assigned.map(issue => issue.fields.assignee?.accountId).filter(Boolean))];
      if (ids.length > 1 || (config.accountId && ids.length && ids[0] !== config.accountId)) throw new Error('Assigned tickets do not match one configured account');
      const accountId = ids[0] || config.accountId || state.accountId;
      if (!accountId) throw new Error('No assigned ticket can identify your account; set accountId in the private VM config');
      state.accountId = accountId;
      state.assigned = assigned.map(issue => issue.key);
      const assignedKeys = new Set(state.assigned);
      for (const [key, row] of Object.entries(state.rows)) {
        row.assigned = assignedKeys.has(key);
        if (!row.assigned && (!row.mentioned || Date.parse(row.updated) < now - config.days * 86400000)) delete state.rows[key];
      }
      const missing = [];
      for (const issue of assigned) {
        if (!state.rows[issue.key]?.updated) missing.push(issue.key);
        state.rows[issue.key] ??= { key: issue.key, summary: issue.fields.summary, status: issue.fields.status?.name || '', updated: null, mentioned: false, mentionAt: null };
        Object.assign(state.rows[issue.key], statusFields(issue.fields.status), { assigned: true, url: `${account.site}/browse/${issue.key}` });
      }
      enqueue([...missing, ...Object.keys(state.rows).filter(key => !state.rows[key].statusCategory)]);
      state.total = state.pending.length;
      state.discovery = { startedAt: now };
      state.checkedAt = new Date(now).toISOString();
      await save(state);
    }
    if (clock() + 15000 > deadline) return state;
    const minutes = Math.max(2, Math.ceil((now - state.searchedAt) / 60000) + 2);
    const changed = state.searchedAt ? ` AND updated >= -${Math.min(config.days * 1440, minutes)}m` : '';
    const jql = `(project IN (${config.projects.map(project => JSON.stringify(project)).join(',')}) OR assignee = currentUser()) AND updated >= -${config.days}d${changed} ORDER BY updated DESC`;
    const recent = issuesFrom(await cli(['workitem', 'search', '--jql', jql, '--fields', 'key,summary,status,assignee', '--paginate', '--json']));
    enqueue([...recent.map(issue => issue.key), ...Object.keys(state.failures)]);
    state.failures = {};
    state.candidates = state.searchedAt ? state.candidates : recent.length;
    state.total = state.pending.length;
    state.searchedAt = state.discovery.startedAt;
    delete state.discovery;
    await save(state);
  }

  const batch = [...state.pending];
  let next = 0;
  const assigned = new Set(state.assigned);
  const inspect = async key => {
    const issue = await cli(['workitem', 'view', key, '--fields', 'summary,status,assignee,updated,comment', '--json']);
    if (issue.key !== key || typeof issue.fields?.summary !== 'string' || !Number.isFinite(Date.parse(issue.fields?.updated))) throw new Error('Ticket details are missing a valid update date');
    const fields = issue.fields, project = key.replace(/-\d+$/, '');
    const eligible = config.projects.includes(project) && Date.parse(fields.updated) >= now - config.days * 86400000;
    let mentionAt = null;
    if (eligible) {
      let comments = fields.comment?.comments;
      if (!Array.isArray(comments) || comments.length < (fields.comment?.total ?? 0)) comments = commentsFrom(await cli(['workitem', 'comment', 'list', '--key', key, '--paginate', '--json']));
      else comments = commentsFrom(fields.comment);
      mentionAt = latestMention(comments, state.accountId);
    }
    if (assigned.has(key) || mentionAt) state.rows[key] = { key, summary: fields.summary, ...statusFields(fields.status), updated: fields.updated, assigned: assigned.has(key), mentioned: Boolean(mentionAt), mentionAt, url: `${account.site}/browse/${key}` };
    else delete state.rows[key];
  };
  await Promise.all(Array.from({ length: concurrency }, async () => {
    while (next < batch.length && clock() < deadline) {
      const key = batch[next++];
      try { await inspect(key); delete state.failures[key]; }
      catch (error) {
        if (error.code === 'REFRESH_BUDGET') continue;
        state.failures[key] = String(error.message || error).slice(0, 160);
      }
      state.pending = state.pending.filter(item => item !== key);
    }
  }));
  state.checkedAt = new Date(now).toISOString();
  await save(state);
  return state;
}

export function snapshot(state, config, now = Date.now()) {
  const rows = Object.values(state.rows).filter(row => row.assigned || (row.mentioned && Date.parse(row.updated) >= now - config.days * 86400000));
  rows.sort((a, b) => (Date.parse(b.updated) || 0) - (Date.parse(a.updated) || 0) || a.key.localeCompare(b.key));
  return { ok: true, rows, scope: { projects: config.projects, days: config.days }, checkedAt: state.checkedAt, searching: Boolean(state.discovery) || state.pending.length > 0, progress: { discovering: Boolean(state.discovery), remaining: state.pending.length, total: state.total, candidates: state.candidates }, failed: Object.keys(state.failures).length };
}
