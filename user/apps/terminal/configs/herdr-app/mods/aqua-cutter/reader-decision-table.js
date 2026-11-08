// Decision Table: each policy table's ordered rule matrix against one declared case, the case's
// inputs, matches and winner, and the explicit unmatched result.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { mono, eyebrow, frame, tabs, hue } from "./ui.js";

const CELL = { any: "Any (wildcard)", absent: "Absent", null: "Null", unknown: "Unknown" };

function cellValue(t, cell) {
  if (cell?.kind !== "literal") return div().text_size(12).text_color(t.muted).child(CELL[cell?.kind] ?? "Unknown");
  const text = String(cell.text ?? "");
  return v_flex().gap(3)
    .child(div().text_size(10.5).text_color(t.dim).child(text === "" ? "Empty literal (0 UTF-8 bytes)" : text.trim() === "" ? "Whitespace literal" : "Literal"))
    .child(div().px(6).py(3).rounded(4).bg(t.background).font_family(mono()).text_size(11).text_color(t.foreground).child(text || " "));
}

const label = (t, text) => div().text_size(11).font_semibold().text_color(t.muted).child(text);

function effects(t, entries) {
  if (!entries?.length) return div().text_size(12).text_color(t.dim).child("None supplied");
  return v_flex().gap(2).children(entries.map((entry) => h_flex().gap(6).items_start()
    .child(div().flex_none().text_size(12).text_color(t.dim).child("•"))
    .child(div().flex_1().min_w(0).text_size(12).text_color(t.foreground).child(String(entry)))));
}

function result(t, value) {
  return v_flex().gap(6).children([
    ["Outcome", div().text_size(12).font_semibold().text_color(t.foreground).child(String(value?.outcome ?? ""))],
    ["Reason", div().text_size(12).text_color(t.foreground).child(String(value?.reason ?? ""))],
    ["Allowed effects", effects(t, value?.allowed)],
    ["Prohibited effects", effects(t, value?.prohibited)],
  ].map(([name, body]) => v_flex().gap(2).child(label(t, name)).child(body)));
}

const heading = (t, text) => div().text_size(13.5).font_semibold().text_color(t.foreground).child(text);

export default {
  render(ctx, t, section) {
    const tables = section.tables ?? [], tableId = ctx.get("dt:table", section.initialTable);
    const table = tables.find((entry) => entry.id === tableId) ?? tables[0];
    if (!table) return frame(t, { body: [div().text_size(12).text_color(t.dim).child("No decision tables supplied")] });
    const cases = table.cases ?? [], rules = table.rules ?? [], conditions = table.conditions ?? [];
    const caseId = ctx.get(`dt:case:${table.id}`, table.initialCase);
    const selected = cases.find((entry) => entry.id === caseId) ?? cases[0];
    const matches = selected?.matches ?? [];
    const winner = rules.find((rule) => rule.id === selected?.selectedRule);
    const tableIndex = tables.indexOf(table), shade = hue(t, "0C");

    // Fixed columns; the matrix scrolls sideways when the conditions don't fit.
    const widths = [180, ...conditions.map(() => 170), 140, 0];
    const col = (index, el) => (widths[index] ? el.w(widths[index]).flex_none() : el.flex_1().min_w(260)).p(9).border_r(1).border_color(t.border);
    const head = h_flex().flex_none().items_start().bg(t.chrome).border_b(1).border_color(t.border)
      .children(["Rule", ...conditions.map((condition) => `${condition.id} — ${condition.label}`), "Declared status", "Result and effects"]
        .map((text, index) => col(index, div()).text_size(11).font_semibold().text_color(t.muted).child(text)));
    const rows = rules.map((rule) => {
      const won = rule.id === selected?.selectedRule, matched = matches.includes(rule.id);
      return h_flex().flex_none().items_start().border_b(1).border_color(t.border)
        .when(won || matched, (el) => el.bg(shade + (won ? "1f" : "0d")))
        .child(col(0, div()).text_size(12).font_semibold().text_color(t.foreground).child(`${rule.id} — ${rule.title ?? ""}`))
        .children(conditions.map((_condition, index) => col(index + 1, div()).child(cellValue(t, (rule.cells ?? [])[index]))))
        .child(col(conditions.length + 1, v_flex().gap(4))
          .child(div().text_size(12).text_color(matched ? t.foreground : t.muted).child(matched ? "Declared match" : "Not declared matched"))
          .when(won, (el) => el.child(div().text_size(12).font_semibold().text_color(shade).child("Declared winner"))))
        .child(col(conditions.length + 2, div()).child(result(t, rule.result)));
    });
    const minWidth = widths.reduce((total, width) => total + (width || 260), 0);

    const caseBody = selected ? v_flex().flex_none().gap(10).pt(4)
      .child(heading(t, `Selected case: ${selected.id} — ${selected.title ?? ""}`))
      .child(v_flex().gap(4).child(label(t, "Inputs")).children(conditions.map((condition, index) => h_flex().gap(12).items_start()
        .child(div().w(220).flex_none().text_size(12).text_color(t.muted).child(`${condition.id} — ${condition.label}`))
        .child(div().flex_1().min_w(0).when((selected.cells ?? [])[index] !== undefined, (el) => el.child(cellValue(t, selected.cells[index])))))))
      .child(v_flex().gap(2).child(label(t, "Explanation")).child(div().text_size(12).text_color(t.foreground).child(String(selected.explanation ?? ""))))
      .child(v_flex().gap(2).child(label(t, "Declared matches")).child(matches.length
        ? v_flex().gap(2).children(matches.map((id, index) => div().text_size(12).text_color(t.foreground)
          .child(`${index + 1}. ${id} — ${rules.find((rule) => rule.id === id)?.title ?? ""}`)))
        : div().text_size(12).text_color(t.dim).child("None supplied")))
      .child(v_flex().gap(2).child(label(t, "Declared winner"))
        .child(div().text_size(12).text_color(t.foreground).child(winner ? `${winner.id} — ${winner.title ?? ""}` : "Unmatched")))
      .child(v_flex().gap(4).child(label(t, "Selected result")).child(result(t, winner?.result ?? table.unmatched)))
      .child(v_flex().gap(2).child(label(t, "References")).child((selected.references ?? []).length
        ? effects(t, selected.references)
        : div().text_size(12).text_color(t.dim).child("No references supplied"))) : null;

    return frame(t, {
      tabs: tabs(t, "aqua-dt-tables", tables.map((entry, index) => ({ label: `${entry.id} — ${entry.title ?? ""}`, value: index })), tableIndex,
        (index, cx) => ctx.set("dt:table", tables[index].id, cx), { monospace: true }),
      caption: [div().max_w(Math.max(220, ctx.width / 2)).truncate().child(`Current table: ${table.id} — ${table.title ?? ""}`)],
      body: [
        v_flex().flex_none().gap(3)
          .child(div().text_size(12.5).text_color(t.foreground).child(`Policy: ${table.policy === "first-match" ? "first-match — first declared match wins" : "unique — at most one declared match"}`))
          .child(div().font_family(mono()).text_size(10.5).text_color(t.dim).child("Authored matches and outcomes — not evaluated or exhaustive")),
        tabs(t, `aqua-dt-cases-${tableIndex}`, cases.map((entry, index) => ({ label: `${entry.id} — ${entry.title ?? ""}`, value: index })), cases.indexOf(selected),
          (index, cx) => ctx.set(`dt:case:${table.id}`, cases[index].id, cx), { monospace: true }),
        v_flex().flex_none().gap(6)
          .child(div().text_size(11.5).text_color(t.muted).child(`${table.id} — ${table.title ?? ""} · ordered rules${selected ? ` for ${selected.id} — ${selected.title ?? ""}` : ""}`))
          .child(div().id(`aqua-dt-matrix-${tableIndex}`).flex_none().w_full().rounded(6).border(1).border_color(t.border).overflow_x_scrollbar()
            .child(v_flex().w_full().min_w(minWidth).child(head).children(rows))),
        ...(caseBody ? [caseBody] : []),
        v_flex().flex_none().gap(8).pt(10).border_t(1).border_color(t.border)
          .child(heading(t, "Explicit unmatched result"))
          .child(result(t, table.unmatched)),
      ],
    });
  },
};
