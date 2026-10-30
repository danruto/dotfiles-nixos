#!/usr/bin/env node
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { readFile, writeFile, mkdir, rename, rm, stat, realpath } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { identity, validateConfig, updateFeed, snapshot } from './feed.mjs';

const execute = promisify(execFile);

export async function refresh() {
  const configFile = join(process.env.XDG_CONFIG_HOME || join(homedir(), '.config'), 'herdr-jira/config.json');
  let config;
  try { config = validateConfig(JSON.parse(await readFile(configFile, 'utf8'))); }
  catch (error) { throw new Error(`Check the private VM config ${configFile}: ${error.message}`); }
  const deadline = Date.now() + 22000;
  const run = async args => {
    const timeout = Math.min(20000, deadline - Date.now());
    if (timeout < 100) throw Object.assign(new Error('Refresh time budget reached; retry to continue'), { code: 'REFRESH_BUDGET' });
    try {
      const response = await execute(process.env.HERDR_JIRA_ACLI || 'acli', ['jira', ...args], { encoding: 'utf8', timeout, killSignal: 'SIGKILL', maxBuffer: 8 * 1024 * 1024, env: { ...process.env, NO_COLOR: '1' } });
      return response.stdout;
    } catch (error) {
      if (error.killed && timeout < 20000) error.code = 'REFRESH_BUDGET';
      throw error;
    }
  };
  const account = identity(await run(['auth', 'status']));
  const directory = join(process.env.XDG_CACHE_HOME || join(homedir(), '.cache'), 'herdr-jira');
  await mkdir(directory, { recursive: true, mode: 0o700 });
  const lock = join(directory, 'refresh.lock');
  try { if (Date.now() - (await stat(lock)).mtimeMs > 120000) await rm(lock, { recursive: true, force: true }); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  try { await mkdir(lock, { mode: 0o700 }); }
  catch (error) { if (error.code === 'EEXIST') throw new Error('Another Jira refresh is running; the next refresh will retry'); throw error; }
  try {
    const file = join(directory, 'feed.json');
    let state = null;
    try { state = JSON.parse(await readFile(file, 'utf8')); }
    catch (error) { if (error.code !== 'ENOENT' && !(error instanceof SyntaxError)) throw error; }
    const save = async value => {
      const temporary = `${file}.${process.pid}.tmp`;
      try {
        await writeFile(temporary, JSON.stringify(value), { mode: 0o600 });
        await rename(temporary, file);
      } finally { await rm(temporary, { force: true }); }
    };
    state = await updateFeed({ config, state, account, deadline, cli: async args => JSON.parse(await run(args)), save });
    return snapshot(state, config);
  } finally { await rm(lock, { recursive: true, force: true }); }
}

if (process.argv[1] && await realpath(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (process.argv[2] && process.argv[2] !== 'refresh') throw new Error('Usage: herdr-jira [refresh]');
    console.log(JSON.stringify(await refresh()));
  } catch (error) {
    console.log(JSON.stringify({ ok: false, error: String(error.message || error).slice(0, 400) }));
    process.exitCode = 1;
  }
}
