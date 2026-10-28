import assert from "node:assert/strict";
import { test } from "node:test";
import usageStatus from "../user/apps/ai/configs/pi-usage-status.ts";

test("publishes structured totals and quota without changing Pi's text status", () => {
  const handlers = new Map();
  const listeners = new Map();
  const publications = [];
  const statuses = [];
  usageStatus({
    events: {
      on: (name, handler) => listeners.set(name, handler),
      emit: (name, data) => publications.push({ name, data }),
    },
    on: (name, handler) => handlers.set(name, handler),
  });
  const entries = [
    { type: "message", message: { role: "user" } },
    { type: "message", message: { role: "assistant", usage: { input: 100_000, output: 2_000, cost: { total: 0.216 } } } },
    { type: "message", message: { role: "assistant", usage: { input: 1_000, output: 100, cost: { total: 0.004 } } } },
  ];
  const context = {
    ui: { setStatus: (id, text) => statuses.push({ id, text }) },
    sessionManager: { getEntries: () => entries, getBranch: () => assert.fail("unexpected branch fallback") },
    getContextUsage: () => ({ percent: 10 }),
  };
  handlers.get("session_start")({}, context);
  assert.deepEqual(publications.at(-1), {
    name: "pig-status:usage",
    data: { input: 101_000, output: 2_100, cost: 0.22, windows: [] },
  });
  const windows = [{ label: "5h", usedPercent: 39 }, { label: "Week", usedPercent: 13 }];
  listeners.get("usage-core:ready")({ state: { provider: "openai", usage: { windows } } });
  assert.deepEqual(publications.at(-1).data.windows, windows);
  assert.equal(statuses.at(-1).id, "subscription-usage");
  assert.match(statuses.at(-1).text, /5h 61% left · Week 87% left/);
  assert.match(statuses.at(-1).text, /↑101k ↓2.1k · ctx 10% · \$0.220/);

  listeners.get("usage-core:update-current")({ state: { provider: "openai", usage: { windows: [{ label: "5h", usedPercent: 50 }] } } });
  assert.deepEqual(publications.at(-1).data.windows, [{ label: "5h", usedPercent: 50 }]);
  listeners.get("usage-core:update-current")({ state: {} });
  assert.deepEqual(publications.at(-1).data.windows, []);
  assert.doesNotMatch(statuses.at(-1).text, /left/);

  entries.splice(0);
  handlers.get("session_start")({}, context);
  assert.equal(publications.at(-1).data.input, 0);
  assert.equal(publications.at(-1).data.output, 0);
  assert.equal(publications.at(-1).data.cost, 0);
});
