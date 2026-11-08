// Contracts: the exact supplied interface source for each contract, one at a time.

import { div } from "gpui-kit";
import { h_flex, v_flex, TextView } from "gpui-base";
import { richMarkdown, detectLanguage } from "./model.js";
import { mono, eyebrow, rich, frame, tabs, codeBox } from "./ui.js";

const NOTICE = "Supplied interface source — not fetched, executed or verified against a repository";
const KINDS = { openapi: "yaml", yaml: "yaml", json: "json", js: "js", javascript: "js", typescript: "js", go: "go", bash: "bash", shell: "bash", python: "python", html: "html", css: "css" };

const language = (contract) => KINDS[String(contract.kind ?? "").toLowerCase()] ?? detectLanguage(contract.spec);

const selectedOf = (ctx, section) => {
  const contracts = section.contracts ?? [], id = ctx.get("ct:contract", section.initialContract);
  return contracts.find((contract) => contract.id === id) ?? contracts[0];
};

export default {
  editors(section) {
    return (section.contracts ?? []).map((contract) => {
      const lang = language(contract);
      return { key: `contract:${contract.id}`, value: contract.spec ?? "", ...(lang ? { language: lang } : {}) };
    });
  },

  render(ctx, t, section) {
    const contracts = section.contracts ?? [], selected = selectedOf(ctx, section);
    if (!selected) return frame(t, { body: [div().text_size(12).text_color(t.dim).child("No contracts supplied")] });
    const index = contracts.indexOf(selected), provenance = selected.provenance ?? [];
    const panels = [section.surface && "Public surface", section.validity && "Validity envelope"].filter(Boolean);
    const label = (contract) => h_flex().gap(6).items_center()
      .child(div().max_w(280).truncate().child(contract.title ?? contract.id))
      .child(div().max_w(180).truncate().font_family(mono()).text_size(10).text_color(t.dim).child(String(contract.id)));
    return frame(t, {
      tabs: contracts.length > 1
        ? tabs(t, "aqua-ct-contracts", contracts.map((contract, row) => ({ label: label(contract), value: row })), index,
          (row, cx) => ctx.set("ct:contract", contracts[row].id, cx))
        : null,
      caption: [div().child("exact supplied source")],
      body: [
        v_flex().flex_none().gap(4)
          .child(h_flex().gap(10).items_center().flex_wrap()
            .when(selected.kind !== undefined, (el) => el.child(eyebrow(t, selected.kind)))
            .child(div().flex_1().min_w(200).child(TextView.markdown(`aqua-ct-title-${index}`, `**${richMarkdown(selected.title ?? selected.id)}**`)
              .w_full().text_size(13).scrollable(false).selectable(true))))
          .child(div().text_color(t.muted).child(rich(`aqua-ct-summary-${index}`, selected.summary ?? "No interface summary supplied", 12))),
        codeBox(t, `aqua-ct-source-${index}`, ctx.editor(`contract:${selected.id}`), selected.spec),
      ],
      footer: [div().child(`${selected.id} · ${provenance.length ? `provenance: ${provenance.join(" · ")}` : "No provenance supplied"}`),
        ...panels.map((panel) => div().child(`${panel} panel supplied · shown only in the browser renderer`))],
      notice: NOTICE,
    });
  },
};
