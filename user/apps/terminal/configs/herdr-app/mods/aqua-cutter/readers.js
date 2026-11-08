// Native readers for section types beyond the four in inspector.js. Each module's default export
// is { sources?(section, ctx), editors?(section), render(ctx, t, section) }, with ctx from
// AquaCutterInspector.context(), or null while that type is still unported.

import lifecycle from "./reader-lifecycle.js";
import contracts from "./reader-contracts.js";
import corpus from "./reader-corpus.js";
import decisionTable from "./reader-decision-table.js";
import c4 from "./reader-c4.js";
import eventModel from "./reader-event-model.js";
import rollout from "./reader-rollout.js";
import recovery from "./reader-recovery.js";
import identity from "./reader-identity.js";
import impact from "./reader-impact.js";
import telemetry from "./reader-telemetry.js";
import tradeoffs from "./reader-tradeoffs.js";
import dataFlow from "./reader-data-flow.js";

export const READERS = Object.fromEntries(Object.entries({
  lifecycle, contracts, corpus, "decision-table": decisionTable, c4,
  "event-model": eventModel, rollout, recovery, identity, impact, telemetry, tradeoffs, "data-flow": dataFlow,
}).filter(([, reader]) => reader));
