// Rollout: authored release snapshots. Rollout tabs, an ordered phase chooser, the optional phase
// map (connection roles per phase), the chosen phase's components, gates with supplied evidence,
// verification and rollback obligations, then the coexistence ledger and release-together groups.
// Ported from the renderer's lenses/rollout.tsx and rollout_map.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme } from "herdr";
import { markDiagram } from "./model.js";
import { mono, tag, frame, tabs, diagram, hue } from "./ui.js";

const NOTICE = "Authored rollout plan — not deployed state, verified evidence or permission to proceed";
const ASSESSMENTS = { met: ["Author says met", "added"], unmet: ["Author says unmet", "removed"], unknown: ["Unknown", "neutral"] };
const COMPATIBILITY = { compatible: ["Authored compatible", "added"], incompatible: ["Authored incompatible", "removed"], unknown: ["Compatibility unknown", "neutral"] };
const ROLLBACK = {
  "switch-back": ["Switch-back described", "info"], "repair-required": ["Repair required", "warn"],
  unavailable: ["Rollback unavailable", "removed"], unknown: ["Rollback unknown", "neutral"],
};
const ROLE_LABELS = { write: "Write", read: "Read", shadow: "Shadow read", off: "Off", unlisted: "Not listed" };

const plain = (text) => String(text ?? "").replace(/\r\n?/g, "\n");
const para = (t, text, colour = t.foreground) => div().w_full().min_w(0).overflow_hidden().text_size(12).text_color(colour).child(plain(text) || " ");
const lab = (t, text) => div().flex_none().font_family(mono()).text_size(10).text_color(t.muted).child(String(text).toUpperCase());
const heading = (t, text, size = 13) => div().w_full().min_w(0).text_size(size).font_semibold().text_color(t.foreground).child(plain(text));
const label = (pair, value) => (pair[value] ?? [String(value ?? "unknown"), "neutral"]);

function field(t, name, value, wide) {
  return (wide ? h_flex().gap(12).items_start() : v_flex().gap(2)).flex_none().w_full().min_w(0)
    .child(lab(t, name).when(wide, (el) => el.w(104).pt(2)))
    .child(div().flex_1().min_w(0).child(typeof value === "string" ? para(t, value) : value));
}

const panel = (t, children, tint) => v_flex().flex_none().w_full().min_w(0).p(12).gap(8).rounded(7).border(1).border_color(t.border)
  .bg(tint ? t.raised : t.background).children(children);

const edgeKey = (edge) => JSON.stringify([edge?.from, edge?.to, edge?.label ?? "", edge?.occurrence ?? 0]);
const edgeText = (edge) => `${edge?.from ?? ""} → ${edge?.to ?? ""}${edge?.label ? ` (${edge.label})` : ""}`;

// Each phase path's role, and whether it differs from the previous phase (the first phase has
// nothing to compare with). A path the previous phase named but this one drops is "Not listed".
function connections(rollout, index) {
  const roles = (phase) => new Map((phase?.paths ?? []).map((path) => [edgeKey(path.edge), path]));
  const current = roles(rollout.phases?.[index]), previous = index > 0 ? roles(rollout.phases[index - 1]) : undefined;
  const listed = [...current.entries()].map(([key, path]) => ({
    edge: path.edge, role: path.role, changed: previous !== undefined && previous.get(key)?.role !== path.role,
  }));
  const dropped = previous ? [...previous.entries()].filter(([key]) => !current.has(key))
    .map(([, path]) => ({ edge: path.edge, role: "unlisted", changed: true })) : [];
  return [...listed, ...dropped];
}

function roleColour(t, role) {
  return { write: hue(t, "09"), read: hue(t, "0C"), shadow: hue(t, "0E") }[role] ?? t.dim;
}

function mapSource(rollout, index) {
  const t = theme();
  const marks = connections(rollout, index).filter((entry) => entry.edge).map((entry) => ({
    edge: entry.edge, colour: roleColour(t, entry.role), dashed: entry.role === "shadow" || entry.role === "off",
    width: entry.changed ? 4.5 : entry.role === "off" ? 1.5 : entry.role === "unlisted" ? 1 : 2.5,
  }));
  return markDiagram(rollout.map?.source, marks, t.background);
}

function components(t, entries, wide) {
  const list = entries ?? [];
  if (!list.length) return para(t, "No components supplied", t.dim);
  if (!wide) return v_flex().w_full().gap(8).children(list.map((entry) => v_flex().gap(3).p(8).rounded(6).bg(t.background)
    .child(field(t, "Component", entry.component, false)).child(field(t, "Version", entry.version, false)).child(field(t, "Settings", entry.settings, false))));
  const cells = (a, b, c, head) => h_flex().w_full().min_w(0).gap(12).px(8).py(head ? 5 : 7).items_start()
    .when(!head, (el) => el.border_t(1).border_color(t.border))
    .child(div().w(170).flex_none().min_w(0).child(a)).child(div().w(150).flex_none().min_w(0).child(b)).child(div().flex_1().min_w(0).child(c));
  return v_flex().w_full().min_w(0).rounded(6).bg(t.background).overflow_hidden()
    .child(cells(lab(t, "Component"), lab(t, "Version"), lab(t, "Settings"), true))
    .children(list.map((entry) => cells(para(t, entry.component), div().font_family(mono()).text_size(11).text_color(t.foreground).child(plain(entry.version)),
      para(t, entry.settings, t.muted), false)));
}

function evidence(t, supplied, wide) {
  if (!supplied) return para(t, "No evidence supplied", t.dim);
  return v_flex().w_full().min_w(0).gap(4).pl(10).border_l(2).border_color(t.accent)
    .child(field(t, "Evidence", supplied.description, wide))
    .child(field(t, "Source", div().font_family(mono()).text_size(11).text_color(t.muted).overflow_hidden().child(plain(supplied.source)), wide));
}

const items = (t, list, render) => v_flex().w_full().min_w(0).children(list.map((entry, index) =>
  v_flex().w_full().min_w(0).gap(5).py(7).when(index > 0, (el) => el.border_t(1).border_color(t.border)).children(render(entry, index))));

function snapshot(t, phase, wide) {
  const gates = v_flex().gap(6).child(lab(t, "Gates")).child(phase.gates?.length
    ? items(t, phase.gates, (gate) => [
      h_flex().gap(8).items_start().child(div().flex_1().min_w(0).child(para(t, gate.condition)))
        .child(tag(t, label(ASSESSMENTS, gate.assessment)[0], label(ASSESSMENTS, gate.assessment)[1])),
      evidence(t, gate.evidence, wide)])
    : para(t, "No gates supplied", t.dim));
  const work = v_flex().gap(6).child(field(t, "Existing work", phase.existingWork, true)).child(field(t, "New work", phase.newWork, true));
  const verification = v_flex().gap(6).child(lab(t, "Planned verification")).child(phase.verification?.length
    ? items(t, phase.verification, (entry) => [para(t, entry.check), evidence(t, entry.evidence, wide)])
    : para(t, "No verification checks supplied", t.dim));
  const rollback = phase.rollback ?? {}, mode = label(ROLLBACK, rollback.mode);
  const back = v_flex().gap(6).child(lab(t, "Rollback"))
    .child(h_flex().child(tag(t, mode[0], mode[1])))
    .child(field(t, "Action", rollback.action ?? "", true))
    .child(field(t, "Existing work", rollback.existingWork ?? "", true))
    .child(field(t, "New work", rollback.newWork ?? "", true))
    .child(field(t, "Boundary", rollback.boundary ?? "", true));
  const left = v_flex().gap(14).child(gates).child(work).child(verification);
  return [
    heading(t, `${phase.id} — ${phase.title ?? ""}`),
    field(t, "Intent", phase.intent ?? "", wide),
    ...(phase.invariant !== undefined ? [div().pl(10).py(4).border_l(3).border_color(hue(t, "0D")).text_size(12).text_color(t.foreground)
      .child(`Invariant. ${plain(phase.invariant)}`)] : []),
    v_flex().gap(6).child(lab(t, "Components")).child(components(t, phase.components, wide)),
    wide ? h_flex().w_full().gap(20).items_start().child(left.flex_1().min_w(0)).child(back.flex_1().min_w(0).pl(16).border_l(1).border_color(t.border))
      : v_flex().gap(14).child(left).child(back),
  ];
}

function phaseMap(ctx, t, rollout, index) {
  const phase = rollout.phases[index];
  const legend = h_flex().gap(14).flex_wrap().items_center().children([...Object.keys(ROLE_LABELS).map((role) =>
    h_flex().gap(6).items_center()
      .child(div().w(22).h(role === "unlisted" ? 1 : 3).flex_none().bg(roleColour(t, role)))
      .child(div().text_size(11).text_color(t.muted).child(`${ROLE_LABELS[role]}${role === "shadow" ? " (dashed)" : role === "off" ? " (dashed, thin)" : ""}`))),
  h_flex().gap(6).items_center().child(div().w(22).h(6).flex_none().bg(t.muted))
    .child(div().text_size(11).text_color(t.muted).child("Changed since the previous phase"))]);
  const list = connections(rollout, index);
  return [
    lab(t, "Phase map"),
    diagram(t, ctx.diagram(mapSource(rollout, index)), ctx.width - 80, { height: 320 }),
    legend,
    v_flex().gap(3).child(div().text_size(11).text_color(t.dim).child("Connections named in this phase"))
      .children(list.length ? list.map((entry) => h_flex().gap(8).items_center()
        .child(div().w(10).h(3).flex_none().bg(roleColour(t, entry.role)))
        .child(div().flex_1().min_w(0).font_family(mono()).text_size(11).text_color(t.foreground)
          .child(`${edgeText(entry.edge)}: ${ROLE_LABELS[entry.role] ?? entry.role}${entry.changed ? " — changed" : ""}`)))
        : [div().text_size(11).text_color(t.dim).child(phase?.paths ? "No connections named" : "This phase names no connection roles")])
      .child(div().text_size(10.5).text_color(t.dim).child("Connections the phase doesn't name keep the diagram's default style.")),
  ];
}

function ledger(t, rollout, wide) {
  const combos = rollout.combinations ?? [], groups = rollout.releaseTogether ?? [];
  return [
    heading(t, "Coexistence ledger"),
    para(t, "Finite authored combinations, not an exhaustive compatibility matrix.", t.dim),
    combos.length ? items(t, combos, (combo) => {
      const [text, name] = label(COMPATIBILITY, combo.compatibility);
      return [h_flex().gap(8).items_start().child(div().flex_1().min_w(0).child(heading(t, `${combo.id} — ${combo.title ?? ""}`, 12.5))).child(tag(t, text, name)),
        field(t, "Reason", combo.reason ?? "", wide), components(t, combo.components, wide)];
    }) : para(t, "No combinations supplied", t.dim),
    heading(t, "Release-together groups"),
    para(t, "Authored release constraints, not development order or phase dependencies.", t.dim),
    groups.length ? items(t, groups, (group) => [
      field(t, "Members", h_flex().gap(5).flex_wrap().children((group.members ?? []).map((member) =>
        div().flex_none().px(6).py(1).rounded(4).border(1).border_color(t.border).text_size(11).text_color(t.foreground).child(plain(member)))), wide),
      field(t, "Reason", group.reason ?? "", wide)]) : para(t, "No release-together groups supplied", t.dim),
  ];
}

function selection(ctx, section) {
  const rollouts = section.rollouts ?? [];
  const rollout = rollouts.find((entry) => entry.id === ctx.get("ro-rollout", section.initialRollout)) ?? rollouts[0];
  const phases = rollout?.phases ?? [];
  const id = ctx.get(`ro-phase:${rollout?.id}`, rollout?.initialPhase);
  return { rollout, index: Math.max(0, phases.findIndex((entry) => entry.id === id)) };
}

export default {
  sources(section) {
    return (section.rollouts ?? []).filter((rollout) => rollout.map?.source)
      .flatMap((rollout) => (rollout.phases ?? []).map((_phase, index) => mapSource(rollout, index)));
  },

  render(ctx, t, section) {
    const { rollout, index } = selection(ctx, section), wide = ctx.width >= 760;
    const phase = rollout?.phases?.[index];
    if (!rollout || !phase) return frame(t, { body: [para(t, "No rollout phases supplied", t.dim)], notice: NOTICE });
    return frame(t, {
      tabs: tabs(t, "aqua-ro-rollouts", (section.rollouts ?? []).map((entry) => ({ label: `${entry.id} — ${entry.title ?? ""}`, value: entry.id })),
        rollout.id, (id, cx) => ctx.set("ro-rollout", id, cx), { monospace: true }),
      caption: [div().child("authored snapshots · not deployed state")],
      body: [
        panel(t, [heading(t, "Authored phase order", 12.5),
          para(t, "Ordinals show supplied reading order, not progress. Every phase is selectable.", t.dim),
          tabs(t, "aqua-ro-phases", rollout.phases.map((entry, at) => ({ label: `${at + 1}. ${entry.id} — ${entry.title ?? ""}`, value: entry.id })),
            phase.id, (id, cx) => ctx.set(`ro-phase:${rollout.id}`, id, cx), { monospace: true })], true),
        ...(rollout.map?.source ? [panel(t, phaseMap(ctx, t, rollout, index))] : []),
        panel(t, snapshot(t, phase, wide)),
        panel(t, ledger(t, rollout, wide)),
      ],
      footer: rollout.map?.source ? [ctx.sourceToggle(t, [["Phase map · source", "", rollout.map.source]])] : [],
      notice: NOTICE,
    });
  },
};
