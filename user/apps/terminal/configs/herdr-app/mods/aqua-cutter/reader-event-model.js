// EventModel: role-bearing flow diagrams, a block chooser, and the chosen block's authored
// coverage (scenarios in a numbered rail beside the literal Given/When/Then body, requirements,
// references). Ported from the renderer's lenses/event_model.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { theme } from "herdr";
import { blend } from "./model.js";
import { mono, button, frame, tabs, diagram, rich } from "./ui.js";

const NOTICE = "Authored coverage references — not executed scenarios or passing tests";
const ROLES = { trigger: "Trigger", command: "Command", event: "Event", view: "View" };
// The renderer tells roles apart by line style, so the map still reads without colour.
const DASH = { trigger: "2 3", event: "9 3", view: "8 2 2 2" };
const CLAMP = 280;
const SAFE_ID = /^[A-Za-z_][\w-]*$/;

// A Given/When/Then body as keyword groups, hard-wrapped lines joined back into clauses;
// undefined when it doesn't start with a keyword, so it shows verbatim.
function scenarioSteps(body) {
  const steps = [];
  for (const raw of String(body).split(/\r\n?|\n/)) {
    const line = raw.trim();
    if (!line) continue;
    const keyword = /^(Given|When|Then|And|But)\b:?\s*(.*)$/.exec(line);
    const clause = /^[-*•]\s+(.*)$/.exec(line);
    const current = steps.at(-1);
    if (keyword) steps.push({ keyword: keyword[1], clauses: keyword[2] ? [keyword[2]] : [] });
    else if (!current) return undefined;
    else if (clause) current.clauses.push(clause[1]);
    else if (!current.clauses.length) current.clauses.push(line);
    else current.clauses[current.clauses.length - 1] += ` ${line}`;
  }
  return steps.length ? steps : undefined;
}

function flowSource(flow, node) {
  const t = theme(), text = String(flow.diagram?.source ?? "");
  if (!/^\s*(?:flowchart|graph)\b/.test(text)) return text;
  const lines = (flow.blocks ?? []).filter((block) => SAFE_ID.test(block.node ?? "")).map((block) => {
    const selected = block.node === node, colour = String(selected ? t.accent : t.foreground).slice(0, 7);
    const parts = [`stroke:${colour}`, `stroke-width:${selected ? 4 : 2}px`];
    if (selected) parts.unshift(`fill:${blend(colour, t.background, 0.22)}`);
    if (DASH[block.role]) parts.push(`stroke-dasharray:${DASH[block.role]}`);
    return `style ${block.node} ${parts.join(",")}`;
  });
  return lines.length ? `${text.replace(/\s+$/, "")}\n${lines.join("\n")}` : text;
}

const lab = (t, text) => div().flex_none().font_family(mono()).text_size(10).text_color(t.muted).child(String(text).toUpperCase());
const meta = (t, text) => div().font_family(mono()).text_size(10.5).text_color(t.muted).child(text);
const empty = (t, text) => div().text_size(11.5).text_color(t.dim).child(text);
const chip = (t, text) => div().flex_none().px(6).py(1).rounded(4).border(1).border_color(t.border).bg(t.background)
  .font_family(mono()).text_size(10.5).text_color(t.foreground).child(String(text));

function row(t, label, content, { stacked = false, count = 0 } = {}) {
  const head = h_flex().flex_none().gap(6).items_center().child(lab(t, label))
    .when(count > 0, (el) => el.child(div().font_family(mono()).text_size(10).text_color(t.dim).child(String(count))));
  return (stacked ? v_flex().gap(6) : h_flex().gap(12).items_start())
    .flex_none().w_full().px(2).py(9).border_t(1).border_color(t.border)
    .child(stacked ? head : head.w(110).pt(2))
    .child(div().flex_1().min_w(0).child(content));
}

function references(t, label, ids, none) {
  return row(t, label, ids?.length ? h_flex().gap(5).flex_wrap().children(ids.map((id) => chip(t, id))) : empty(t, none));
}

function scenarioBody(t, id, body) {
  const steps = scenarioSteps(body);
  if (!steps) return v_flex().gap(1).children(String(body).split(/\r\n?|\n/)
    .map((line) => div().font_family(mono()).text_size(11).text_color(t.foreground).child(line || " ")));
  return v_flex().gap(8).children(steps.map((step, index) => v_flex().gap(3)
    .child(div().text_size(11.5).font_semibold().text_color(t.accent).child(step.keyword))
    .children(step.clauses.map((clause, at) => div().pl(10).border_l(1).border_color(t.border)
      .child(rich(`${id}-${index}-${at}`, clause, 12))))));
}

function coverage(ctx, t, section, flow, block, scenarioId) {
  const cover = block.coverage, key = `aqua-em-${flow.id}-${block.node}`;
  const ids = cover?.scenarioIds ?? [], requirements = cover?.requirements ?? [];
  const scenarios = ids.map((id) => (section.scenarios ?? []).find((entry) => entry.id === id) ?? { id, missing: true });
  const refs = (cover?.architecture?.length ?? 0) + (cover?.seams?.length ?? 0) + (cover?.cases?.length ?? 0);
  const rows = [row(t, "Block", v_flex().gap(2)
    .child(div().text_size(12.5).font_semibold().text_color(t.foreground).child(block.title ?? block.node))
    .when(cover?.title !== undefined && cover.title !== block.title, (el) => el.child(meta(t, cover.title)))
    .child(meta(t, `role ${ROLES[block.role] ?? block.role} · node ${block.node}${cover
      ? ` · ${scenarios.length} scenarios · ${requirements.length} requirements · ${refs} references` : ""}`)))];
  if (!cover) return [...rows, row(t, "Coverage", empty(t, "No coverage supplied for this block"))];

  const scenario = scenarios.find((entry) => entry.id === scenarioId);
  const rail = v_flex().gap(1).children(scenarios.map((entry, index) => {
    const pressed = entry.id === scenarioId;
    return h_flex().id(`aqua-em-scn-${index}`).gap(8).px(8).py(5).items_start().cursor_pointer()
      .border_l(2).border_color(pressed ? t.accent : t.surface).bg(pressed ? t.raised : t.surface)
      .hover((el) => el.bg(t.hover))
      .on_click((_event, cx) => ctx.set(`em-scenario:${flow.id}`, entry.id, cx))
      .child(div().w(18).flex_none().pt(1).font_family(mono()).text_size(10).text_color(t.dim).child(String(index + 1).padStart(2, "0")))
      .child(div().flex_1().min_w(0).text_size(11.5).text_color(pressed ? t.foreground : t.muted).child(entry.name ?? entry.id));
  }));
  const detail = scenario ? v_flex().gap(6)
    .child(meta(t, `${scenario.name !== undefined ? `${scenario.name} · ` : ""}${scenario.id}`))
    .child(scenario.missing ? empty(t, "Scenario is not in this section's catalogue")
      : scenario.body === undefined ? empty(t, "No scenario body supplied")
        : scenarioBody(t, `${key}-${scenario.id}`, scenario.body)) : empty(t, "Choose a scenario");
  const wide = ctx.width >= 700;
  rows.push(row(t, "Scenarios", scenarios.length === 0 ? empty(t, "No scenarios supplied")
    : wide ? h_flex().items_start().gap(0).child(rail.w(224).flex_none())
      .child(div().flex_1().min_w(0).pl(14).border_l(1).border_color(t.border).child(detail))
      : v_flex().gap(10).child(rail).child(detail), { stacked: true, count: scenarios.length }));

  rows.push(row(t, "Requirements", requirements.length === 0 ? empty(t, "No requirements supplied")
    : v_flex().children(requirements.map((requirement, index) => {
      const text = requirement.text ?? "No requirement text supplied", long = text.length > CLAMP;
      const openKey = `em-req:${flow.id}:${block.node}:${index}`, open = ctx.get(openKey, false);
      return v_flex().gap(3).py(6).when(index > 0, (el) => el.border_t(1).border_color(t.border))
        .child(div().font_family(mono()).text_size(11.5).text_color(t.foreground).child(String(requirement.id)))
        .child(rich(`${key}-req-${index}-${open}`, long && !open ? `${text.slice(0, CLAMP).trimEnd()}…` : text, 12))
        .when(long, (el) => el.child(div().id(`aqua-em-req-${index}`).text_size(11).text_color(t.accent).cursor_pointer()
          .hover((h) => h.text_color(t.foreground))
          .on_click((_event, cx) => ctx.set(openKey, !open, cx))
          .child(open ? "Show less" : "Show full requirement")));
    })), { stacked: true, count: requirements.length }));
  rows.push(references(t, "Architecture", cover.architecture, "No architecture references supplied"),
    references(t, "Interfaces", cover.seams, "No interface references supplied"),
    references(t, "Cases", cover.cases, "No case references supplied"));
  return rows;
}

function selection(ctx, flow) {
  const blocks = flow.blocks ?? [];
  const node = ctx.get(`em-node:${flow.id}`, blocks[0]?.node);
  const block = blocks.find((entry) => entry.node === node) ?? blocks[0];
  return { block, scenario: ctx.get(`em-scenario:${flow.id}`, block?.coverage?.scenarioIds?.[0] ?? null) };
}

export default {
  sources(section) {
    return (section.flows ?? []).flatMap((flow) => (flow.blocks ?? []).map((block) => flowSource(flow, block.node)));
  },

  render(ctx, t, section) {
    const flows = section.flows ?? [];
    const flow = flows.find((entry) => entry.id === ctx.get("em-flow", section.initialFlow)) ?? flows[0];
    if (!flow) return frame(t, { body: [empty(t, "No flows supplied")], notice: NOTICE });
    const { block, scenario } = selection(ctx, flow);
    const chooser = h_flex().gap(5).flex_wrap().children((flow.blocks ?? []).map((entry, index) => {
      const pressed = entry.node === block?.node;
      return button(t, `aqua-em-block-${index}`, h_flex().gap(6).items_center()
        .child(div().font_family(mono()).text_size(9.5).text_color(pressed ? t.accent : t.dim).child((ROLES[entry.role] ?? entry.role ?? "").toUpperCase()))
        .child(entry.title ?? entry.node), (cx) => {
        ctx.set(`em-scenario:${flow.id}`, entry.coverage?.scenarioIds?.[0] ?? null, cx);
        ctx.set(`em-node:${flow.id}`, entry.node, cx);
      }, { pressed });
    }));
    return frame(t, {
      tabs: flows.length > 1
        ? tabs(t, "aqua-em-flows", flows.map((entry) => ({ label: entry.title ?? entry.id, value: entry.id })), flow.id, (id, cx) => ctx.set("em-flow", id, cx))
        : div().text_size(12).font_semibold().text_color(t.foreground).child("Flow blocks"),
      caption: [div().child("choose a block to reveal coverage")],
      body: [
        ...(flow.diagram?.source ? [diagram(t, ctx.diagram(flowSource(flow, block?.node)), ctx.width - 80, { height: 260 })] : []),
        ...(flow.diagram?.description ? [div().text_size(11).text_color(t.dim).child(flow.diagram.description)] : []),
        v_flex().gap(6).child(lab(t, "Choose block")).child(chooser),
        ...(block ? [v_flex().w_full().children(coverage(ctx, t, section, flow, block, scenario))] : [empty(t, "No blocks supplied")]),
      ],
      footer: [
        div().child("Role key: Trigger dotted · Command solid · Event dashed · View dash-dot; the chosen block is outlined in the accent colour. Undeclared nodes have no supplied role."),
        ...(flow.diagram?.source ? [ctx.sourceToggle(t, [["", flow.diagram.description, flow.diagram.source]])] : []),
      ],
      notice: NOTICE,
    });
  },
};
