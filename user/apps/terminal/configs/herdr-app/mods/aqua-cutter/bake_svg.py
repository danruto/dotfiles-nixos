import json
import math
import re
import sys
import xml.etree.ElementTree as ET

NS = "http://www.w3.org/2000/svg"
TAGS = set("svg g defs marker path polyline polygon line rect circle ellipse text tspan title desc".split())
ATTRS = set("viewBox width height x y x1 y1 x2 y2 cx cy r rx ry d points transform fill stroke stroke-width stroke-dasharray stroke-linecap stroke-linejoin fill-rule opacity fill-opacity stroke-opacity text-anchor dominant-baseline dy dx font-size font-weight font-style font-family id marker-start marker-end markerWidth markerHeight markerUnits refX refY orient preserveAspectRatio color text-decoration".split())
PAINT = set("fill stroke stroke-width stroke-dasharray stroke-linecap stroke-linejoin opacity fill-opacity stroke-opacity font-family font-size font-weight font-style color text-decoration rx ry".split())


def resolve(value, variables, stack=()):
    if len(stack) > 24:
        raise ValueError("Cyclic SVG colour variables")
    while "var(" in value:
        start = value.index("var(")
        end = start + 4
        depth = 1
        comma = None
        while end < len(value) and depth:
            char = value[end]
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
            elif char == "," and depth == 1 and comma is None:
                comma = end
            end += 1
        if depth:
            raise ValueError("Unclosed SVG variable")
        name = value[start + 4:comma if comma is not None else end - 1].strip()
        if name in stack:
            raise ValueError("Cyclic SVG colour variable")
        fallback = value[comma + 1:end - 1].strip() if comma is not None else None
        replacement = variables.get(name, fallback)
        if replacement is None:
            raise ValueError("Unresolved SVG variable: " + name)
        value = value[:start] + resolve(replacement, variables, stack + (name,)) + value[end:]
    return value


def bake(payload):
    raw = payload["svg"]
    if len(raw.encode("utf-8")) > 524288 or "<!" in raw:
        raise ValueError("Unsupported SVG size or declaration")
    width, height = payload["width"], payload["height"]
    if not all(isinstance(n, (int, float)) and math.isfinite(n) and 0 < n <= 12000 for n in [width, height]):
        raise ValueError("Diagram dimensions exceed the native viewer limit")
    theme = payload["theme"]
    for value in theme.values():
        if not re.fullmatch(r"#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?", value):
            raise ValueError("Invalid diagram colour")
    variables = {"--pele-bg": theme["background"], "--pele-fg": theme["foreground"], "--pele-muted": theme["muted"], "--pele-line": theme["muted"], "--pele-surface": theme["surface"], "--pele-surface-alt": theme["raised"], "--pele-border": theme["border"], "--pele-accent": theme["accent"], "--pele-font": "Arial", "--pele-font-mono": "Menlo", "--pele-radius": "4px"}
    node_colours = payload.get("nodeColours", [])
    if not isinstance(node_colours, list) or len(node_colours) > 6 or any(not isinstance(item, dict) or set(item) != {"fill", "stroke"} or any(not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value) for value in item.values()) for item in node_colours):
        raise ValueError("Invalid node colour palette")
    assignments = {}
    root = ET.fromstring(raw)
    if root.tag != "{" + NS + "}svg":
        raise ValueError("Expected an SVG document")

    def visit(element, inherited):
        if not isinstance(element.tag, str) or not element.tag.startswith("{" + NS + "}") or element.tag.split("}")[-1] not in TAGS:
            raise ValueError("Unsupported generated SVG element")
        variables = dict(inherited)
        styles = []
        for declaration in element.attrib.get("style", "").split(";"):
            key, separator, value = declaration.partition(":")
            if not separator:
                continue
            key, value = key.strip(), value.strip()
            if key.startswith("--"):
                variables[key] = value
            elif key in PAINT:
                styles.append((key, value))
        if node_colours and "pele-node" in element.attrib.get("class", "").split():
            identity = element.attrib.get("data-id", str(len(assignments)))
            index = assignments.setdefault(identity, len(assignments) % len(node_colours))
            colour = node_colours[index]
            variables.update({"--_s": colour["fill"], "--_a": colour["fill"], "--_b": colour["stroke"]})
        for key in list(element.attrib):
            value = element.attrib[key]
            if key.lower().startswith("on") or key.split("}")[-1] in ["href", "src"]:
                raise ValueError("External or executable SVG content is disabled")
            if key not in ATTRS:
                del element.attrib[key]
            elif key in PAINT:
                element.set(key, resolve(value, variables))
        for key, value in styles:
            element.set(key, resolve(value, variables))
        for key, value in element.attrib.items():
            if "url(" in value.lower() and not (key in ["marker-start", "marker-end"] and re.fullmatch(r"url\(#[A-Za-z0-9_.:-]+\)", value)):
                raise ValueError("External SVG resources are disabled")
        for child in element:
            visit(child, variables)

    visit(root, variables)
    root.set("font-family", "Arial")
    root.set("font-size", "14")
    root.set("fill", theme["foreground"])
    root.insert(0, ET.Element("{" + NS + "}rect", {"width": str(width), "height": str(height), "fill": theme["background"]}))
    ET.register_namespace("", NS)
    return ET.tostring(root, encoding="unicode")


if __name__ == "__main__":
    try:
        payload = json.load(sys.stdin)
        print(json.dumps({"svg": bake(payload)}))
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
