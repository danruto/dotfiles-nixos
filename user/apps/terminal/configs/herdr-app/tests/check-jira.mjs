import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir, mkdtemp, rm, stat, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, delimiter } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { runInNewContext } from 'node:vm';
import { validateConfig, identity, hasMention, commentsFrom, updateFeed, snapshot } from '../mods/jira-tickets/feed.mjs';
import { normalizeFilters, filterRows, statusOptions } from '../mods/jira-tickets/filters.mjs';
import { isBlockVisible } from '../mods/jira-tickets/visibility.mjs';

const config = { projects: ['DEMO', 'CORE'], days: 90 };
const account = { site: 'https://example.atlassian.net', email: 'person@example.invalid' };
const now = Date.parse('2026-01-20T12:00:00Z');
const mention = id => ({ type: 'doc', content: [{ type: 'paragraph', content: [{ type: 'mention', attrs: { id, text: '@Person' } }] }] });
const comment = (body, created = '2026-01-19T09:00:00Z') => ({ body, created });
const issue = (key, updated = '2026-01-19T12:00:00Z', comments = [], total = comments.length) => ({ key, fields: { summary: `Synthetic ${key}`, status: { id: '1', name: 'Open', statusCategory: { key: 'new' } }, assignee: { accountId: 'user-1' }, updated, comment: { comments, total } } });
assert.deepEqual(validateConfig({ projects: ['CORE', 'CORE', 'DEMO'], days: 90 }).projects, ['CORE', 'DEMO']);
for (const invalid of [{ projects: [], days: 90 }, { projects: ['DEMO) OR true'], days: 90 }, { projects: ['DEMO'], days: 0 }]) assert.throws(() => validateConfig(invalid));
assert.deepEqual(identity('✓ Authenticated\n Site: example.atlassian.net\n Email: person@example.invalid\n'), account);
for (const site of ['http://example.atlassian.net', 'example.invalid', 'https://user:pass@example.atlassian.net', 'https://example.atlassian.net/path']) assert.throws(() => identity(`Site: ${site}\nEmail: person@example.invalid`));
assert.equal(hasMention(mention('user-1'), 'user-1'), true);
assert.equal(hasMention(mention('user-2'), 'user-1'), false);
assert.equal(hasMention('@Person', 'user-1'), false);
assert.equal(hasMention('[~accountid:user-1]', 'user-1'), true);
assert.equal(hasMention('[~accountid:user-10]', 'user-1'), false);
assert.throws(() => commentsFrom({ comments: [], total: 1 }), /paginated/);

const assigned = [issue('DEMO-1'), issue('OTHER-4', '2025-01-01T00:00:00Z')];
let recent = [issue('DEMO-1'), issue('CORE-2'), issue('CORE-3'), issue('CORE-5'), issue('CORE-6')];
const views = new Map([
  ['DEMO-1', issue('DEMO-1', '2026-01-19T12:00:00Z', [comment(mention('user-1'))])],
  ['OTHER-4', assigned[1]],
  ['CORE-2', issue('CORE-2', '2026-01-20T11:00:00Z', [], 2)],
  ['CORE-3', issue('CORE-3', '2026-01-19T10:00:00Z', [comment('@Person'), comment(mention('other'))])],
  ['CORE-5', issue('CORE-5', '2025-01-01T00:00:00Z', [comment(mention('user-1'))])],
  ['CORE-6', issue('CORE-6', 'invalid')],
]);
const calls = [];
const cli = async args => {
  calls.push(args);
  assert.ok(args[0] === 'workitem' && (['search', 'view'].includes(args[1]) || (args[1] === 'comment' && args[2] === 'list')), 'No write commands');
  if (args[1] === 'search') return args[args.indexOf('--jql') + 1].startsWith('assignee') ? assigned : recent;
  if (args[1] === 'view') return views.get(args[2]);
  assert.ok(args.includes('--paginate'));
  return { comments: [comment('Not a mention'), comment(mention('user-1'))], total: 2 };
};
let ticks = 0;
let state = await updateFeed({ config, account, cli, now, concurrency: 1, clock: () => ticks++, deadline: 1 });
assert.ok(state.pending.length > 0, 'A time-bounded run leaves resumable work');
assert.equal(snapshot(state, config, now).rows.length, 2, 'All assigned tickets appear before dates finish indexing');
assert.equal(snapshot(state, config, now).progress.discovering, true, 'Slow discovery resumes across short remote executions');
state = await updateFeed({ config, account, cli, state, now: now + 1000 });
assert.equal(calls.filter(args => args[1] === 'search' && args.some(arg => arg.startsWith('assignee ='))).length, 1, 'Resume without repeating the assigned search');
assert.equal(calls.filter(args => args[1] === 'search' && args.some(arg => arg.includes('project IN'))).length, 1, 'Run the deferred candidate search once');
let data = snapshot(state, config, now);
assert.deepEqual(data.rows.map(row => row.key), ['CORE-2', 'DEMO-1', 'OTHER-4']);
assert.equal(data.rows.find(row => row.key === 'DEMO-1').assigned, true);
assert.equal(data.rows.find(row => row.key === 'DEMO-1').mentioned, true);
assert.equal(data.rows.find(row => row.key === 'OTHER-4').mentioned, false);
assert.equal(data.searching, false);
assert.equal(data.rows[0].statusCategory, 'new');
assert.equal(data.rows[0].statusId, '1');
const filterFixtures = [
  { key: '1', status: 'Cancelled', statusCategory: 'done', assigned: true, mentioned: false },
  { key: '2', status: 'Done', statusCategory: 'indeterminate', assigned: false, mentioned: true },
  { key: '3', status: 'Open', statusCategory: 'new', assigned: true, mentioned: true },
  { key: '4', status: 'Open', statusCategory: null, assigned: true, mentioned: false },
];
const originalFilters = JSON.stringify(filterFixtures);
assert.deepEqual(filterRows(filterFixtures, { hideDone: true }).map(row => row.key), ['2', '3', '4'], 'Use the Jira category, not the status name; retain unknown categories');
assert.deepEqual(filterRows(filterFixtures, { statuses: ['Done', 'Open'], source: '@mentions', hideDone: true }).map(row => row.key), ['2', '3']);
assert.deepEqual(filterRows(filterFixtures, { statuses: ['Op'] }), [], 'Status matching is exact');
assert.deepEqual(statusOptions(filterFixtures), ['Cancelled', 'Done', 'Open']);
assert.deepEqual(normalizeFilters({ source: 'invalid', hideDone: 'yes', statuses: ['Open', 'Open', 1] }), { source: 'All', hideDone: false, statuses: ['Open'] });
assert.equal(JSON.stringify(filterFixtures), originalFilters, 'Filtering does not mutate the feed');
assert.equal(data.failed, 1, 'Skipped failures are disclosed, not reported as complete coverage');
assert.equal(JSON.stringify(state).includes('paragraph'), false, 'No comment bodies in the cache');
const paused = structuredClone(state);
paused.pending = ['CORE-3'];
const limited = await updateFeed({ config, account, state: paused, now: now + 1000, cli: async () => { throw Object.assign(new Error('time budget'), { code: 'REFRESH_BUDGET' }); } });
assert.deepEqual(limited.pending, ['CORE-3'], 'A time-budget interruption stays queued instead of being lost');
assert.equal(limited.failures['CORE-3'], undefined, 'A batch time budget is not a failed ticket');
assert.equal(calls.filter(args => args[1] === 'comment').length, 1, 'Fetch full comments when embedded comments are truncated');
assert.ok(!calls.some(args => args[1] === 'comment' && args.includes('OTHER-4')), 'Do not scan comments outside the approved projects');

views.set('DEMO-1', issue('DEMO-1'));
views.set('CORE-6', issue('CORE-6'));
recent = [issue('DEMO-1')];
state = await updateFeed({ config, account, cli, state, now: now + 121000 });
assert.equal(state.rows['DEMO-1'].mentioned, false, 'Removed mentions disappear on the next changed-ticket scan');
assert.ok(calls.filter(args => args[1] === 'search').at(-1).some(arg => arg.includes('updated >= -5m')), 'Use an overlapping incremental search');
assert.equal(state.failures['CORE-6'], undefined, 'Failed tickets are retried');
assert.equal(snapshot(state, config, now + 200 * 86400000).rows.some(row => row.key === 'CORE-2'), false, 'Aging mention-only rows leave the window');
await assert.rejects(updateFeed({ config, account, now, cli: async () => [], state: null }), /accountId/);
let saved;
await assert.rejects(updateFeed({ config, account, now: now + 300000, state, cli: async () => { throw new Error('offline'); }, save: async value => { saved = value; } }), /offline/);
assert.equal(saved, undefined, 'A failed search does not replace the previous snapshot');
const outsideUpdate = '2026-01-20T12:03:00Z';
recent = [issue('OTHER-4', outsideUpdate)];
views.set('OTHER-4', issue('OTHER-4', outsideUpdate, [comment(mention('user-1'))]));
state = await updateFeed({ config, account, cli, state, now: now + 242000 });
assert.equal(state.rows['OTHER-4'].updated, outsideUpdate, 'Refresh assigned ticket dates outside mention projects too');
assert.equal(state.rows['OTHER-4'].mentioned, false, 'Refreshing assigned metadata does not broaden mention scope');
const changedQuery = calls.filter(args => args[1] === 'search').at(-1);
assert.ok(changedQuery.some(arg => arg.includes('OR assignee = currentUser()')), 'Changed-ticket discovery includes all assigned projects');

const directory = await mkdtemp(join(tmpdir(), 'herdr-jira-check-'));
try {
  const bin = join(directory, 'bin'), settings = join(directory, 'config/herdr-jira'), cache = join(directory, 'cache');
  await mkdir(bin); await mkdir(settings, { recursive: true });
  await writeFile(join(settings, 'config.json'), JSON.stringify({ projects: ['DEMO'], days: 90 }), { mode: 0o600 });
  const current = new Date().toISOString();
  const fixture = issue('DEMO-1', current, [comment(mention('user-1'), current)]);
  await writeFile(join(bin, 'acli'), `#!${process.execPath}\nconst args=process.argv.slice(2); const item=${JSON.stringify(fixture)};\nif(args.join(' ')==='jira auth status') console.log('Site: example.atlassian.net\\nEmail: person@example.invalid');\nelse if(args[2]==='search') console.log(JSON.stringify([item]));\nelse if(args[2]==='view') console.log(JSON.stringify(item));\nelse process.exit(42);\n`, { mode: 0o700 });
  const helper = fileURLToPath(new URL('../mods/jira-tickets/helper.mjs', import.meta.url));
  const link = join(bin, 'herdr-jira');
  await symlink(helper, link);
  const env = { ...process.env, HERDR_JIRA_ACLI: join(bin, 'acli'), PATH: `${bin}${delimiter}${process.env.PATH}`, XDG_CONFIG_HOME: join(directory, 'config'), XDG_CACHE_HOME: cache };
  const run = () => spawnSync(process.execPath, [link, 'refresh'], { env, encoding: 'utf8', timeout: 15000 });
  const result = run();
  assert.equal(result.status, 0, result.stderr + result.stdout);
  assert.equal(JSON.parse(result.stdout).rows[0].mentioned, true);
  assert.equal((await stat(join(cache, 'herdr-jira'))).mode & 0o777, 0o700);
  assert.equal((await stat(join(cache, 'herdr-jira/feed.json'))).mode & 0o777, 0o600);
  assert.equal((await readFile(join(cache, 'herdr-jira/feed.json'), 'utf8')).includes('paragraph'), false);
  await mkdir(join(cache, 'herdr-jira/refresh.lock'));
  assert.match(JSON.parse(run().stdout).error, /Another Jira refresh/);
} finally { await rm(directory, { recursive: true, force: true }); }

function element() {
  const node = { children: [] };
  const builder = new Proxy(node, { get(target, name) {
    if (name === '_node') return target;
    if (name === 'id') return id => { target.id = id; return builder; };
    if (name === 'child') return child => { target.children.push(child); return builder; };
    if (name === 'children') return children => { target.children.push(...children); return builder; };
    if (name === 'when') return (condition, callback) => { if (condition) callback(builder); return builder; };
    if (name === 'on_click') return callback => { target.click = callback; return builder; };
    return () => builder;
  } });
  return builder;
}
const tasks = [], commands = [], timers = [];
let fail = false, preferences = null;
const panelStack = { id: 'panel-body', type: 'stack', active: 'jira', children: [{ id: 'jira', type: 'block' }, { id: 'files', type: 'block' }] };
const panelContainer = { id: 'panel', type: 'column', hidden: false, children: [panelStack] };
const shownLayout = { id: 'root', type: 'row', children: [panelContainer] };
const cx = { spawn: callback => tasks.push(callback), notify() {}, timer: { every: (ms, callback) => timers.push({ ms, callback }) } };
const source = await readFile(new URL('../mods/jira-tickets/main.js', import.meta.url), 'utf8');
const Panel = runInNewContext(source.replace(/^import .*;\n/gm, '').replace('export default class JiraTickets', 'class JiraTickets') + '\nJiraTickets;', {
  View: class {}, div: element, h_flex: element, v_flex: element, Date, normalizeFilters, filterRows, statusOptions, isBlockVisible,
  shared: () => preferences, setShared: (_key, value) => { preferences = value; },
  props: () => ({ layoutBlock: 'jira' }), layout: () => shownLayout, appHome: () => '/app', readTextFile: async () => '{"on":"remote"}', theme: () => ({}), window: () => ({ platform: 'macos' }),
  exec: async (command, args, options) => {
    commands.push({ command, args, options });
    if (fail) throw new Error('offline');
    return { code: 0, stdout: JSON.stringify(data) };
  },
});
const panel = new Panel();
panel.init({}, cx);
await tasks.shift()(cx);
await tasks.shift()(cx);
assert.deepEqual(timers.map(timer => timer.ms), [10000]);
assert.equal(commands[0].command, 'herdr-jira');
assert.equal(commands[0].options.on, 'remote');
panel.nextRefresh = 0;
panelContainer.hidden = true;
timers[0].callback(cx);
assert.equal(tasks.length, 0, 'A collapsed sidebar must not queue automatic refreshes');
panelContainer.hidden = false;
panelStack.active = 'files';
timers[0].callback(cx);
assert.equal(tasks.length, 0, 'Selecting another panel must pause automatic refreshes');
panelStack.active = 'jira';
shownLayout.hidden = true;
timers[0].callback(cx);
assert.equal(tasks.length, 0, 'A hidden ancestor must pause automatic refreshes');
shownLayout.hidden = false;
panelContainer.size = { px: 0 };
timers[0].callback(cx);
assert.equal(tasks.length, 0, 'A zero-width sidebar must pause automatic refreshes');
delete panelContainer.size;
panelStack.children[0].hidden = true;
timers[0].callback(cx);
assert.equal(tasks.length, 0, 'A hidden Jira block must pause automatic refreshes');
delete panelStack.children[0].hidden;
assert.equal(isBlockVisible(shownLayout, 'missing'), false);
assert.equal(isBlockVisible(shownLayout, null), false);
assert.equal(isBlockVisible({ type: 'stack', children: [{ id: 'first' }, { id: 'second' }] }, 'second'), false, 'A stack defaults to its first child');
const beforeHiddenDispatch = commands.length;
timers[0].callback(cx);
assert.equal(tasks.length, 1, 'Reopening a due panel resumes refreshing');
panelContainer.hidden = true;
await tasks.shift()(cx);
assert.equal(commands.length, beforeHiddenDispatch, 'Hiding after scheduling must prevent the remote request');
const hidden = new Panel();
hidden.init({}, cx);
await tasks.shift()(cx);
assert.equal(tasks.length, 0, 'A copy initialized while hidden must not fetch');
hidden.close();
panelContainer.hidden = false;
timers[0].callback(cx);
await tasks.shift()(cx);
assert.equal(commands.length, beforeHiddenDispatch + 1, 'A visible due panel refreshes normally');
const find = (item, id) => {
  if (!item || typeof item !== 'object') return null;
  const node = item._node;
  if (node.id === id) return node;
  for (const child of node.children) { const found = find(child, id); if (found) return found; }
  return null;
};
find(panel.render(), 'jira-filter-@mentions').click({}, cx);
assert.ok(find(panel.render(), 'jira-ticket-CORE-2'));
assert.equal(find(panel.render(), 'jira-ticket-OTHER-4'), null);
find(panel.render(), 'jira-ticket-CORE-2').click({}, cx);
await tasks.shift()(cx);
assert.equal(commands.at(-1).command, 'open');
assert.equal(commands.at(-1).options, undefined, 'Browser opens locally, not on the VM');
panel.setFilters({ source: 'All' });
find(panel.render(), 'jira-hide-done').click({}, cx);
assert.equal(preferences.hideDone, true);
find(panel.render(), 'jira-statuses').click({}, cx);
assert.ok(find(panel.render(), 'jira-status-list'));
find(panel.render(), 'jira-status-0').click({}, cx);
assert.deepEqual(preferences.statuses, ['Open']);
const second = new Panel();
second.rows = data.rows;
assert.ok(find(second.render(), 'jira-ticket-CORE-2'), 'A new copy reuses shared persisted filters');
assert.equal(preferences.hideDone, true);
find(panel.render(), 'jira-all-statuses').click({}, cx);
assert.deepEqual(preferences.statuses, []);
const count = commands.length;
panel.openTicket({ url: 'https://example.invalid/steal' }, cx);
assert.equal(commands.length, count);
fail = true;
panel.refresh(cx);
await tasks.shift()(cx);
assert.equal(panel.rows.length, 3, 'Connection errors preserve the visible last good feed');
assert.match(panel.error, /offline/);
assert.ok(find(panel.render(), 'jira-error'));
panel.close();
panel.refresh(cx);
assert.equal(tasks.length, 0, 'Closing the panel stops new requests');
console.log('PASS: exact account mentions, complete comment pagination, assigned/mentioned deduplication, date ordering, 90-day/project limits, resumable incremental scans, failures/retries, private cache/lock, remote execution, filters, visibility-gated automatic refresh, safe local links and stale-result preservation');
