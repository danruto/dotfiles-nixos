import { View } from "gpui-kit";
import { props } from "herdr";
import MarkdownReader from "./reader.js";
import DiagramInspector from "./inspector.js";

export default class AquaMarkdown extends View {
  /** @param {unknown} input @param {import("gpui-kit").AsyncContext} cx */
  init(input, cx) {
    this.content = props()?.view === "inspector" ? new DiagramInspector() : new MarkdownReader();
    this.content.init(input, cx);
  }

  /** @param {import("gpui-kit").Context} cx */
  render(cx) { return this.content.render(cx); }

  close() { this.content.close(); }
}
