import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { setImmediate } from "node:timers/promises";
import { pathToFileURL } from "node:url";
import { Worker } from "node:worker_threads";
import { test } from "node:test";

const packageRoot = path.resolve(process.env.HERMES_PACKAGE);
const { DatabaseManager } = await import(pathToFileURL(path.join(packageRoot, "src/store/db.ts")).href);

function fixture(t) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "hermes-integrity-"));
  const manager = new DatabaseManager(directory);
  t.after(async () => {
    const pending = manager.waitForStartupIntegrityScan();
    manager.close();
    await pending;
    fs.rmSync(directory, { recursive: true, force: true });
  });
  return { directory, manager };
}

async function activeWorker(manager) {
  while (!manager.startupIntegrityWorker && manager.pendingOpenIntegrityScan) await setImmediate();
  assert.ok(manager.startupIntegrityWorker instanceof Worker);
  return manager.startupIntegrityWorker;
}

test("checks healthy SQLite in a worker while the parent event loop advances", async (t) => {
  const { manager } = fixture(t);
  manager.getDb().prepare("INSERT INTO extension_metadata (key, value) VALUES (?, ?)").run("retained", "value");
  const original = manager.assertIntegrityOk.bind(manager);
  let synchronousChecks = 0;
  manager.assertIntegrityOk = (...args) => { synchronousChecks++; return original(...args); };
  await activeWorker(manager);
  assert.ok(manager.pendingOpenIntegrityScan);
  await manager.waitForStartupIntegrityScan();
  assert.equal(synchronousChecks, 0);
  assert.equal(manager.startupIntegrityWorker, null);
  assert.equal(manager.getLastRecovery(), null);
  assert.equal(manager.getDb().prepare("SELECT value FROM extension_metadata WHERE key = ?").get("retained").value, "value");
});

test("a worker read failure falls back to the active connection without creating a database", async (t) => {
  const { directory, manager } = fixture(t);
  manager.getDb();
  const missing = path.join(directory, "missing.db");
  Object.defineProperty(manager, "dbPath", { value: missing });
  const original = manager.assertIntegrityOk.bind(manager);
  let synchronousChecks = 0;
  manager.assertIntegrityOk = (...args) => { synchronousChecks++; return original(...args); };
  await manager.waitForStartupIntegrityScan();
  assert.equal(synchronousChecks, 1);
  assert.equal(fs.existsSync(missing), false);
  assert.equal(manager.getLastRecovery(), null);
});

test("a worker that exits without a result still runs the synchronous safety check", async (t) => {
  const { manager } = fixture(t);
  manager.getDb();
  const original = manager.assertIntegrityOk.bind(manager);
  let synchronousChecks = 0;
  manager.assertIntegrityOk = (...args) => { synchronousChecks++; return original(...args); };
  const worker = await activeWorker(manager);
  await worker.terminate();
  await manager.waitForStartupIntegrityScan();
  assert.equal(synchronousChecks, 1);
  assert.equal(manager.startupIntegrityWorker, null);
});

test("close cancels the old worker and reopening owns a fresh scan", async (t) => {
  const { manager } = fixture(t);
  const oldDb = manager.getDb();
  await activeWorker(manager);
  const oldScan = manager.waitForStartupIntegrityScan();
  manager.close();
  const newDb = manager.getDb();
  assert.notEqual(newDb, oldDb);
  await Promise.all([oldScan, manager.waitForStartupIntegrityScan()]);
  assert.equal(manager.startupIntegrityWorker, null);
  assert.equal(manager.getLastRecovery(), null);
  assert.equal(manager.getDb(), newDb);
});

test("a worker failure retains the existing corruption recovery path", async (t) => {
  const { manager } = fixture(t);
  manager.getDb();
  Object.defineProperty(manager, "dbPath", { value: "/nonexistent/hermes-integrity.db" });
  const corrupt = Object.assign(new Error("database disk image is malformed"), { code: "SQLITE_CORRUPT" });
  manager.assertIntegrityOk = () => { throw corrupt; };
  let recovered;
  manager.recoverFromCorruption = (error) => { recovered = error; };
  await manager.waitForStartupIntegrityScan();
  assert.equal(recovered, corrupt);
});

test("the existing opt-out still skips startup checking", async (t) => {
  const { manager } = fixture(t);
  manager.setQuickCheckOnOpen(false);
  manager.getDb();
  await manager.waitForStartupIntegrityScan();
  assert.equal(manager.startupIntegrityWorker, null);
  assert.equal(manager.pendingOpenIntegrityScan, null);
});
