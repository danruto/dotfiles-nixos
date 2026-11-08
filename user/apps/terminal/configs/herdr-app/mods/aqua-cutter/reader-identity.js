// Identity: one tab per identity scheme, its definition and scheme evolution, a chooser of
// authored sample pairs with each ingredient's raw and normalized values side by side, and the
// lifetime ledger. Ported from the renderer's lenses/identity.tsx.

import { div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { mono, tag, frame, tabs } from "./ui.js";

const NOTICE = "Authored identity relationships — no keys generated or uniqueness verified";
const RELATIONS = { same: ["Declared same identity", "added"], different: ["Declared different identities", "info"], unknown: ["Identity relation unknown", "warn"] };
const ACTIONS = { reuse: "added", replace: "warn", retire: "removed", unknown: "neutral" };

const plain = (text) => String(text ?? "").replace(/\r\n?/g, "\n");
const para = (t, text, colour = t.foreground) => div().w_full().min_w(0).overflow_hidden().text_size(12).text_color(colour).child(plain(text) || " ");
const lab = (t, text) => div().flex_none().font_family(mono()).text_size(10).text_color(t.muted).child(String(text).toUpperCase());
const heading = (t, text, size = 13) => div().w_full().min_w(0).text_size(size).font_semibold().text_color(t.foreground).child(plain(text));

function field(t, name, value, wide) {
  return (wide ? h_flex().gap(12).items_start() : v_flex().gap(2)).flex_none().w_full().min_w(0)
    .child(lab(t, name).when(wide, (el) => el.w(118).pt(2)))
    .child(div().flex_1().min_w(0).child(typeof value === "string" ? para(t, value) : value));
}

// Literal text exactly as supplied. Whitespace is invisible in a box, so its escaped spelling
// is shown beside it.
function literal(t, text) {
  return v_flex().w_full().min_w(0).gap(2)
    .child(v_flex().w_full().min_w(0).min_h(22).px(6).py(3).rounded(4).border(1).border_color(t.border).bg(t.background).overflow_hidden()
      .children(String(text).split("\n").map((line) => div().font_family(mono()).text_size(11).text_color(t.foreground).child(line || " "))))
    .when(text !== "" && text.trim() !== text, (el) => el.child(div().font_family(mono()).text_size(10).text_color(t.dim).child(`escaped ${JSON.stringify(text)}`)));
}

function value(t, entry) {
  if (!entry) return para(t, "No value supplied", t.dim);
  if (entry.kind !== "literal") return h_flex().child(tag(t, entry.kind === "missing" ? "Missing" : entry.kind === "null" ? "Null" : String(entry.kind), "neutral"));
  const text = String(entry.text ?? "");
  const kind = text === "" ? "Empty literal (0 UTF-8 bytes)" : text.trim() === "" ? "Whitespace literal" : "Literal";
  return v_flex().w_full().min_w(0).gap(3).child(div().text_size(10.5).text_color(t.dim).child(kind)).when(text !== "", (el) => el.child(literal(t, text)));
}

function supplied(t, text, name) {
  if (text === undefined) return para(t, `No ${name} supplied`, t.dim);
  return text === "" ? para(t, `Empty ${name} (0 UTF-8 bytes)`, t.dim) : literal(t, text);
}

// Both samples share the identity's ingredients, so each ingredient is one row with the left and
// right values side by side.
function samples(t, identity, pair, wide) {
  const sides = [["Left", pair.left ?? {}], ["Right", pair.right ?? {}]];
  const split = (render) => (wide ? h_flex().gap(16).items_start() : v_flex().gap(8)).w_full().min_w(0)
    .children(sides.map(([side, sample]) => v_flex().flex_1().min_w(0).gap(4).children(render(side, sample))));
  const block = (children) => v_flex().w_full().min_w(0).gap(6).py(9).border_t(1).border_color(t.border).children(children);
  return v_flex().w_full().min_w(0)
    .child(split((side, sample) => [heading(t, `${side} sample — ${sample.label ?? ""}`, 12.5),
      field(t, "Scheme label", sample.scheme ?? "No scheme label supplied", false)]).pb(8))
    .children((identity.ingredients ?? []).map((ingredient, index) => block([
      h_flex().gap(8).items_baseline().flex_wrap()
        .child(div().font_family(mono()).text_size(11.5).font_semibold().text_color(t.foreground).child(`${ingredient.id} — ${plain(ingredient.label)}`)),
      para(t, ingredient.meaning ?? "", t.muted),
      split((side, sample) => {
        const entry = sample.values?.[index];
        return [lab(t, `${side} raw`), value(t, entry?.raw), lab(t, `${side} normalized`),
          entry?.normalized === undefined ? para(t, "No normalized value supplied", t.dim) : value(t, entry.normalized)];
      }),
    ])))
    .child(block([lab(t, "Encoded form"), split((side, sample) => [div().text_size(10.5).text_color(t.dim).child(side), supplied(t, sample.encoded, "encoded form")])]))
    .child(block([lab(t, "Key"), split((side, sample) => [div().text_size(10.5).text_color(t.dim).child(side), supplied(t, sample.key, "key")])]));
}

function lifetime(t, entries, wide) {
  return v_flex().w_full().min_w(0).children((entries ?? []).map((entry, index) =>
    (wide ? h_flex().gap(12).items_start() : v_flex().gap(4)).w_full().min_w(0).py(8)
      .when(index > 0, (el) => el.border_t(1).border_color(t.border))
      .child(h_flex().gap(8).items_start().when(wide, (el) => el.w(220).flex_none())
        .child(div().w(18).flex_none().pt(1).font_family(mono()).text_size(10).text_color(t.dim).child(String(index + 1).padStart(2, "0")))
        .child(div().flex_1().min_w(0).text_size(12).font_semibold().text_color(t.foreground).child(plain(entry.event))))
      .child(h_flex().flex_none().when(wide, (el) => el.w(84)).child(tag(t, String(entry.action ?? "unknown"), ACTIONS[entry.action] ?? "neutral")))
      .child(div().flex_1().min_w(0).child(para(t, entry.reason ?? "", t.muted)))));
}

export default {
  render(ctx, t, section) {
    const identities = section.identities ?? [], wide = ctx.width >= 760;
    const identity = identities.find((entry) => entry.id === ctx.get("id-identity", section.initialIdentity)) ?? identities[0];
    if (!identity) return frame(t, { body: [para(t, "No identities supplied", t.dim)], notice: NOTICE });
    const pairs = identity.pairs ?? [];
    const pair = pairs.find((entry) => entry.id === ctx.get(`id-pair:${identity.id}`, identity.initialPair)) ?? pairs[0];
    const evolution = identity.evolution;
    const [relation, relationTone] = RELATIONS[pair?.relation] ?? [String(pair?.relation ?? "unknown"), "neutral"];
    return frame(t, {
      tabs: tabs(t, "aqua-id-identities", identities.map((entry) => ({ label: `${entry.id} — ${entry.title ?? ""}`, value: entry.id })),
        identity.id, (id, cx) => ctx.set("id-identity", id, cx), { monospace: true }),
      caption: [div().child(`Current identity: ${identity.id} — ${identity.title ?? ""}`)],
      body: [
        v_flex().w_full().min_w(0).gap(8).p(12).rounded(7).border(1).border_color(t.border).bg(t.raised)
          .child(field(t, "Role", identity.role ?? "", wide))
          .child(field(t, "Scope", identity.scope ?? "", wide))
          .child(field(t, "Namespace", identity.namespace ?? "No namespace supplied", wide))
          .child(field(t, "Encoding", identity.encoding ?? "", wide))
          .child(field(t, "Normalization", identity.normalization ?? "", wide))
          .child(div().pt(4).child(lab(t, "Scheme evolution")))
          .children(evolution ? [field(t, "Before", evolution.before ?? "", wide), field(t, "After", evolution.after ?? "", wide),
            field(t, "Existing records", evolution.existingRecords ?? "", wide)] : [para(t, "No scheme change supplied", t.dim)]),
        ...(pair ? [
          tabs(t, "aqua-id-pairs", pairs.map((entry) => ({ label: `${entry.id} — ${entry.title ?? ""}`, value: entry.id })),
            pair.id, (id, cx) => ctx.set(`id-pair:${identity.id}`, id, cx), { monospace: true }),
          v_flex().w_full().min_w(0).gap(8).p(12).rounded(7).border(1).border_color(t.border)
            .child(heading(t, `${pair.id} — ${pair.title ?? ""}`))
            .child(field(t, "Relation", h_flex().child(tag(t, relation, relationTone)), wide))
            .child(field(t, "Reason", pair.reason ?? "", wide))
            .child(samples(t, identity, pair, wide)),
        ] : [para(t, "No sample pairs supplied", t.dim)]),
        v_flex().w_full().min_w(0).gap(4).child(heading(t, "Lifetime ledger", 12.5)).child(lifetime(t, identity.lifetime, wide)),
      ],
      notice: NOTICE,
    });
  },
};
