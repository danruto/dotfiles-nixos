// C4: an authored C1–C3 level rail with ancestry, explicit node drills and single or
// before/after Mermaid panes carrying authored change markers (lenses/c4.tsx).

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { markDiagram, changeMarks } from "./model.js";
import { mono, button, tag, eyebrow, rich, frame, stepList, diagram } from "./ui.js";
import { ALTITUDES, ancestry, targetLabel } from "./c4.js";

const NOTICE = "Authored architecture and change markers — not an inferred diff or verified source model";
const HINT = "Nodes with a declared drill open their child level from the + buttons under the diagram.";
const PANE_LABELS = { single: "Single", before: "Before", after: "After" };
const STATUS_TONE = { added: "added", removed: "removed", moved: "moved", same: "neutral" };

const levelsOf = (section) => section.levels ?? [];
const paneData = (level, role) => (role === "single" ? level?.diagram : level?.[role]);
const paneSource = (data, colours) => markDiagram(data?.source, changeMarks(data, colours), colours.background);
const label = (altitude) => ALTITUDES[altitude] ?? String(altitude ?? "").toUpperCase();

// The address another reader asked to inspect, drawn as a dashed accent outline over the authored
// markers. It is a request, not a claim of current focus.
const requested = (section, ctx) => (ctx.request && (!ctx.request.architecture || ctx.request.architecture === section.id) ? ctx.request : null);
function requestMark(request, level, role, colours) {
  if (!request || request.level !== level.id || (request.pane ?? role) !== role) return [];
  const target = request.target ?? {};
  if (target.kind === "node") return [{ node: target.node, colour: colours.accent, width: 4, dashed: true }];
  return target.kind === "edge" && target.edge ? [{ edge: target.edge, colour: colours.accent, width: 4, dashed: true }] : [];
}
const markedSource = (data, colours, extra) => markDiagram(data?.source, [...changeMarks(data, colours), ...extra], colours.background);

const ledger = (data) => [
  ...(data.nodeChanges ?? []).map((change) => [targetLabel({ kind: "node", node: change.node }), change.status]),
  ...(data.edgeChanges ?? []).map((change) => [targetLabel({ kind: "edge", edge: change.edge }), change.status]),
];

export default {
  sources(section, ctx) {
    const request = requested(section, ctx);
    return levelsOf(section).flatMap((level) => ["single", "before", "after"]
      .filter((role) => paneData(level, role)?.source)
      .flatMap((role) => {
        const data = paneData(level, role), extra = requestMark(request, level, role, ctx.colours);
        return extra.length ? [paneSource(data, ctx.colours), markedSource(data, ctx.colours, extra)] : [paneSource(data, ctx.colours)];
      }));
  },

  render(ctx, t, section) {
    const levels = levelsOf(section), request = requested(section, ctx);
    const initial = levels.some((level) => level.id === request?.level) ? request.level : section.initialLevel;
    const fallback = levels.some((level) => level.id === initial) ? initial : levels[0]?.id;
    const selected = levels.find((level) => level.id === ctx.get("c4-level", fallback)) ?? levels[0];
    if (!selected) return frame(t, { body: [div().text_size(12).text_color(t.dim).child("No C4 levels supplied")], notice: NOTICE });
    const diff = section.mode === "diff", showBefore = diff && ctx.get("c4-before", request?.pane === "before");
    const role = diff ? (showBefore ? "before" : "after") : "single";
    const data = paneData(selected, role);
    const choose = (id, cx) => ctx.set("c4-level", id, cx);
    const shared = new Set(levels.map((level) => level.altitude).filter((altitude, index, all) => all.indexOf(altitude) !== index));

    const rail = h_flex().gap(4).items_center().flex_wrap().children(levels.map((level, index) =>
      button(t, `aqua-c4-level-${index}`, h_flex().gap(5).items_center().font_family(mono())
        .child(String(level.altitude ?? "").toUpperCase())
        .when(shared.has(level.altitude), (el) => el.child(div().max_w(160).truncate().child(level.title ?? level.id))),
      (cx) => choose(level.id, cx), { pressed: level.id === selected.id })));
    const crumbs = ancestry(section, selected.id);
    const heading = h_flex().flex_wrap().items_center().font_family(mono()).text_size(11).text_color(t.foreground)
      .child(div().text_color(t.muted).child(`${label(selected.altitude)}: `))
      .children(crumbs.flatMap((level, index) => [
        ...(index > 0 ? [div().px(4).text_color(t.dim).child("›")] : []),
        div().when(level.id === selected.id, (el) => el.font_semibold()).text_color(level.id === selected.id ? t.foreground : t.muted).child(level.title ?? level.id),
      ]))
      .when(diff, (el) => el.child(div().text_color(t.muted).child(` · ${PANE_LABELS[role]}`)));
    const legend = h_flex().gap(10).items_center().flex_wrap().children(["added", "removed", "moved", "same"].map((status) =>
      h_flex().gap(5).items_center().font_family(mono()).text_size(10.5).text_color(t.muted)
        .child(div().size(8).flex_none().bg(status === "same" ? t.dim : { added: t.done, removed: t.blocked, moved: t.working }[status]))
        .child(status.charAt(0).toUpperCase() + status.slice(1))));

    const toolbar = h_flex().gap(8).items_center()
      .child(eyebrow(t, data ? `${PANE_LABELS[role]} · ${data.kind === "sequence" ? "Sequence" : "Topology"}` : PANE_LABELS[role]))
      .child(div().flex_1())
      .when(diff, (el) => el.child(button(t, "aqua-c4-before", "Before", (cx) => ctx.set("c4-before", !showBefore, cx), { pressed: showBefore })));
    const body = [toolbar];
    if (request) body.unshift(div().p(8).rounded(6).bg(t.raised).border_l(3).border_color(t.accent).text_size(11).text_color(t.muted)
      .child(`Requested address: ${request.level ?? "?"} · ${PANE_LABELS[request.pane] ?? request.pane ?? "?"} · ${targetLabel(request.target)} — a dashed outline marks it; explore freely.`));
    if (!data) {
      body.push(div().p(12).rounded(7).bg(t.background).text_size(12).text_color(t.muted)
        .child(role === "before" ? "No prior diagram supplied" : "No resulting diagram supplied"));
    } else {
      const extra = requestMark(request, selected, role, ctx.colours);
      body.push(diagram(t, ctx.diagram(extra.length ? markedSource(data, ctx.colours, extra) : paneSource(data, ctx.colours)), ctx.width - 80, { height: 280 }));
      if (data.description) body.push(rich(`aqua-c4-narration-${selected.id}-${role}`, data.description, 12.5));
      const drills = (selected.drills ?? []).filter((drill) => drill.pane === role);
      const markers = ledger(data);
      const detailsOpen = ctx.get("c4-details", false);
      const details = v_flex().gap(8).pt(8).border_t(1).border_color(t.border)
        .child(h_flex().id("aqua-c4-details").gap(5).items_center().cursor_pointer().font_family(mono()).text_size(10.5).text_color(t.muted)
          .hover((el) => el.text_color(t.foreground))
          .on_click((_event, cx) => ctx.set("c4-details", !detailsOpen, cx))
          .child(detailsOpen ? "▾" : "▸").child("STEPS, MARKERS AND DRILLS"));
      if (detailsOpen) {
        details.child(stepList(t, `aqua-c4-steps-${selected.id}-${role}`, data.steps ?? []))
          .child(eyebrow(t, "Authored markers and pin"))
          .child(v_flex().gap(4).font_family(mono()).text_size(10.5).text_color(t.muted)
            .children(markers.length ? markers.map(([target, status]) => h_flex().gap(8).items_center()
              .child(tag(t, String(status ?? ""), STATUS_TONE[status] ?? "neutral"))
              .child(div().flex_1().min_w(0).child(target))) : [div().child("No change markers supplied")])
            .when(Boolean(data.initialFocus), (el) => el.child(div().child(`Initial pin: ${targetLabel(data.initialFocus)}`))))
          .child(eyebrow(t, `${PANE_LABELS[role]} drills`))
          .child(drills.length
            ? h_flex().gap(6).flex_wrap().children(drills.map((drill, index) => {
              const child = levels.find((level) => level.id === drill.level);
              return button(t, `aqua-c4-drill-${index}`, `+ ${PANE_LABELS[role]}: ${drill.node} — open ${child?.title ?? drill.level}`,
                (cx) => choose(drill.level, cx), { disabled: !child });
            }))
            : div().text_size(11).text_color(t.dim).child("No drills declared"));
      } else if (drills.length) {
        details.child(h_flex().gap(6).flex_wrap().children(drills.map((drill, index) => {
          const child = levels.find((level) => level.id === drill.level);
          return button(t, `aqua-c4-drill-${index}`, `+ ${drill.node} — ${child?.title ?? drill.level}`,
            (cx) => choose(drill.level, cx), { disabled: !child });
        })));
      }
      body.push(details);
    }

    return frame(t, {
      tabs: v_flex().flex_1().min_w(0).gap(6)
        .child(h_flex().gap(10).items_center().flex_wrap().child(rail).child(div().flex_1()).when(diff, (el) => el.child(legend)))
        .child(heading),
      body,
      footer: [div().child(HINT), ...(data?.source ? [ctx.sourceToggle(t, [["", "", data.source]])] : [])],
      notice: NOTICE,
    });
  },
};
