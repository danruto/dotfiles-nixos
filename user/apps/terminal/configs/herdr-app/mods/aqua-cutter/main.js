// Aqua Cutter: walkthroughs and Markdown, read natively. The page shows the file; a stop's
// Inspect opens a copy of this mod as a dialog holding that section's complete reader, and a
// diagram's Inspect opens another copy as the pan/zoom diagram inspector.

import { View } from "gpui-kit";
import { props } from "herdr";
import AquaCutterPage from "./page.js";
import AquaCutterInspector from "./inspector.js";
import DiagramInspector from "./diagram-inspector.js";

const VIEWS = { inspector: AquaCutterInspector, diagram: DiagramInspector };

export default class AquaCutter extends View {
  init(input, cx) {
    this.content = new (VIEWS[props()?.view] ?? AquaCutterPage)();
    this.content.init(input, cx);
  }

  render(cx) { return this.content.render(cx); }

  close() { this.content.close(); }
}
