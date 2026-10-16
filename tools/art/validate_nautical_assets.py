"""Validate delivered XML, palette, stroke weights and physical mast junctions."""

from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "docs/art/archive/svg"
INK = "#1B1612"
PALETTE = {INK, "#F4ECD8", "#D5C4A1", "#8C2D19", "#C59B27", "none"}
FILES = [
    "ship_ironclad", "ship_freighter", "ship_corvette", "ship_standard", "ship_flying_dutchman",
    "monster_shark", "monster_serpent", "monster_jellyfish", "monster_squid", "monster_crustacean", "monster_kraken",
    "icon_unstable_tincture", "icon_blast_pack", "icon_chakram", "icon_cannon", "icon_torpedo_launcher",
    "icon_blade_launcher", "icon_lightning_railgun", "icon_flamethrower",
]
TAGS = {"svg", "g", "path", "line", "rect", "circle", "title", "desc"}


def horizontal_segments(d, outline=False):
    """Read the hull's linear upper rim or the explicitly inked deck spans."""
    tokens = re.findall(r"[A-Za-z]|-?\d+(?:\.\d+)?", d)
    result, i, x, y = [], 0, None, None
    while i < len(tokens):
        cmd = tokens[i]
        i += 1
        if cmd == "M":
            x, y = float(tokens[i]), float(tokens[i+1])
            i += 2
        elif cmd == "H":
            end = float(tokens[i])
            i += 1
            result.append((min(x, end), max(x, end), y))
            x = end
        elif outline and cmd == "V":
            y = float(tokens[i])
            i += 1
        elif outline and cmd == "L":
            next_x, next_y = float(tokens[i]), float(tokens[i+1])
            i += 2
            if next_y == y:
                result.append((min(x, next_x), max(x, next_x), y))
            x, y = next_x, next_y
        elif outline:
            # The linear deck rim precedes the curved keel in these hulls.
            break
        else:
            raise AssertionError(f"Deck uses unexpected command: {cmd}")
    return result


def validate(name):
    file = ART / (name + ".svg")
    source = file.read_text(encoding="utf-8")
    assert not any(s in source.lower() for s in ("data:", "base64", "<!doctype", "<!entity", "url(")), f"{name}: embedded or external source"
    root = ET.fromstring(source)
    size = 64 if name.startswith("icon_") else 200
    assert root.attrib["viewBox"] == f"0 0 {size} {size}", f"{name}: viewBox"
    assert root.attrib["width"] == root.attrib["height"] == str(size)
    ids = {}
    for element in root.iter():
        tag = element.tag.split("}")[-1]
        assert tag in TAGS, f"{name}: unsupported element {tag}"
        for key, value in element.attrib.items():
            assert "href" not in key and not key.startswith("on"), f"{name}: external content or script"
            if key in ("fill", "stroke"):
                assert value in PALETTE, f"{name}: off-palette {value}"
                if key == "stroke":
                    assert value == INK or (name in ("icon_blast_pack", "icon_lightning_railgun") and value == "#8C2D19"), f"{name}: non-ink structure"
            if key == "stroke-width":
                assert 1.5 <= float(value) <= 3, f"{name}: stroke width {value}"
        if "id" in element.attrib:
            ident = element.attrib["id"]
            assert ident not in ids, f"{name}: duplicate id {ident}"
            ids[ident] = element
    assert "title" in ids and "desc" in ids, f"{name}: accessible description"
    if name.startswith("ship_"):
        hull = ids["hull"].attrib["d"]
        assert hull.rstrip().endswith("Z"), f"{name}: hull must be closed"
        assert ids["hull"].attrib["fill"] == "#D5C4A1"
        segments = horizontal_segments(ids["deck-main"].attrib["d"])
        # Every explicitly inked deck span is also present in the actual hull outline.
        rim = horizontal_segments(hull, outline=True)
        for segment in segments:
            assert segment in rim, f"{name}: deck disconnected from hull"
        masts = [node for ident, node in ids.items() if ident.startswith("mast-")]
        expected = {"ship_ironclad": 1, "ship_freighter": 3, "ship_corvette": 2, "ship_standard": 2, "ship_flying_dutchman": 3}
        assert len(masts) == expected[name], f"{name}: mast count"
        for node in masts:
            x, y = float(node.attrib["x1"]), float(node.attrib["y1"])
            assert any(start <= x <= end and y == deck_y for start, end, deck_y in segments), f"{name}: {node.attrib['id']} floats above deck"
            assert float(node.attrib["y2"]) < y, f"{name}: mast does not extend upward"


if __name__ == "__main__":
    for file in FILES:
        validate(file)
    print(f"PASS: {len(FILES)} standalone SVGs; correct viewBoxes, palette, native geometry, stroke weights and all 11 physical mast/deck connections.")
