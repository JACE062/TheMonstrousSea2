"""Author historical SVG engravings in the archive, outside the game bundle.

Run from any directory with Python 3. Ships face port (left). Coordinates are
deliberately authored in the final viewBox, including every deck/mast junction.
Repeated marks are expanded to ordinary XML geometry in the delivered SVGs.
"""

from pathlib import Path
from math import cos, sin, pi
from html import escape
import re

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "docs/art/archive/svg"
INK, VELLUM, SHADE, RED, GOLD = "#1B1612", "#F4ECD8", "#D5C4A1", "#8C2D19", "#C59B27"
CATALOG = []


def path(d, fill="none", width=None, ident=None, extra=""):
    attrs = f' fill="{fill}"'
    if width is not None:
        attrs += f' stroke-width="{width}"'
    if ident:
        attrs += f' id="{ident}"'
    return f'<path d="{d}"{attrs}{extra}/>'


def line(x1, y1, x2, y2, width=1.5, ident=None):
    tag = f' id="{ident}"' if ident else ""
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke-width="{width}"{tag}/>'


def circle(x, y, r, fill=VELLUM, width=1.5):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke-width="{width}"/>'


def rect(x, y, w, h, fill=SHADE, width=1.5):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke-width="{width}"/>'


def group(name, *parts):
    return f'<g id="{name}">\n' + "\n".join(parts) + "\n</g>"


def marks(d):
    return path(d, width=1.5)


def waves(y=175):
    return group("sea-engraving", marks(
        f"M9 {y} Q17 {y-4} 25 {y} T41 {y} M49 {y} Q57 {y-4} 65 {y} T81 {y} "
        f"M113 {y} Q121 {y-4} 129 {y} T145 {y} M153 {y} Q161 {y-4} 169 {y} T185 {y} "
        f"M22 {y+7} H46 M58 {y+7} H93 M108 {y+7} H138 M151 {y+7} H177"
    ))


def mast(x, deck, top, name):
    # The bottom is a literal point on the inked deck, never a sail edge.
    return line(x, deck, x, top, 3, f"mast-{name}")


def ratlines(top_x, top_y, foot_x, foot_y, count=6):
    parts = [line(top_x, top_y, foot_x, foot_y)]
    # Shroud ladder: both ends of every rung lie on its two structural ropes.
    for i in range(1, count + 1):
        t = i / (count + 1)
        y = round(top_y + (foot_y - top_y) * t, 2)
        x = round(top_x + (foot_x - top_x) * t, 2)
        parts.append(line(top_x, y, x, y))
    return "\n".join(parts)


def square_sail(x, y, w, h, torn=False):
    left, right, bottom = x-w/2, x+w/2, y+h
    if torn:
        d = (f"M{left} {y} Q{x} {y+3} {right} {y} L{right-3} {bottom-5} "
             f"L{x+9} {bottom-2} L{x+6} {bottom-10} L{x+2} {bottom} "
             f"L{x-3} {bottom-8} L{x-8} {bottom+1} L{left+3} {bottom-3} Z")
    else:
        d = (f"M{left} {y} Q{x} {y+3} {right} {y} "
             f"Q{right-5} {y+h/2} {right-2} {bottom} "
             f"Q{x} {bottom+4} {left+2} {bottom} Q{left+6} {y+h/2} {left} {y} Z")
    details = [path(d, VELLUM), line(left-3, y, right+3, y, 2.5)]
    for dx in (-w/4, 0, w/4):
        details.append(marks(f"M{x+dx} {y+5} Q{x+dx-2} {y+h/2} {x+dx} {bottom-3}"))
    details.append(marks(f"M{left+4} {bottom-8} l5 5 M{left+5} {bottom-13} l9 8 "
                         f"M{right-9} {y+5} l5 5 M{right-14} {y+5} l8 8"))
    if torn:
        details.append(path(f"M{x-8} {y+10} l6 -2 l-1 9 l-6 -2 Z", SHADE, 1.5))
        details.append(marks(f"M{right-2} {bottom-5} l4 7 M{x-8} {bottom+1} l-3 5"))
    return "\n".join(details)


def write(name, title, desc, parts, size=200, category=""):
    source = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
              f'viewBox="0 0 {size} {size}" role="img" aria-labelledby="title desc">\n'
              f'  <title id="title">{escape(title)}</title>\n'
              f'  <desc id="desc">{escape(desc)}</desc>\n'
              f'  <g fill="none" stroke="{INK}" stroke-width="2" '
              'stroke-linecap="round" stroke-linejoin="round">\n'
              + "\n".join(parts) + "\n  </g>\n</svg>\n")
    (ART / name).write_text(source, encoding="utf-8")
    CATALOG.append((name, title, category, size))


def ships():
    write("ship_ironclad.svg", "Ironclad Ram", "Low armored ram ship. A bolted mast meets the deck at (112, 124); riveted plates, a reinforced pilot house and a submerged prow are engraved in iron-gall ink.", [
        group("standing-rigging", path("M29 124 L112 51 L166 124 M112 72 L74 124", width=1.5)),
        group("armored-mast", mast(112, 124, 35, "main"),
              path("M109 44 H115 V124 H109 Z", SHADE),
              line(97, 59, 127, 59, 3), line(104, 76, 120, 76, 2.5),
              path("M114 36 L135 39 L130 44 L114 45 Z", RED),
              marks("M109 89 H115 M109 105 H115")),
        group("pilot-house", path("M133 124 V88 H155 L164 124 Z", SHADE),
              path("M130 88 L135 82 H156 L160 88 Z", VELLUM),
              rect(137, 94, 8, 9, INK), rect(150, 94, 6, 9, INK),
              marks("M136 111 L144 119 M143 110 L151 119 M150 110 L158 119 M136 119 L144 111")),
        group("deck-fittings", path("M45 124 V114 H88 L96 124 Z", SHADE),
              rect(59, 108, 20, 6, VELLUM), path("M45 120 H27 V114 H51", SHADE),
              rect(106, 119, 13, 5, GOLD),
              circle(109, 122, 1.5, INK), circle(116, 122, 1.5, INK)),
        group("hull-engraving", path("M27 124 H179 L173 149 L157 160 H51 L33 149 L10 164 L15 155 L33 146 Z", SHADE, 3, "hull"),
              path("M27 124 H179", width=3, ident="deck-main"),
              path("M33 133 H176 M38 145 H173 M51 156 H157", width=2),
              marks("M50 125 V155 M75 125 V157 M100 125 V157 M125 125 V157 M150 125 V157 "
                    "M38 136 l8 6 M55 136 l7 6 M81 136 l7 6 M106 136 l7 6 M131 136 l7 6 M156 136 l7 6 "
                    "M56 150 l5 -4 M82 150 l5 -4 M107 150 l5 -4 M132 150 l5 -4"),
              *[circle(x, y, 1.5, INK) for x in (57, 83, 109, 135, 161) for y in (129, 141, 151)],
              path("M15 155 L32 151", width=2.5)),
        group("ram-waterline", marks("M5 151 Q13 147 21 151 T37 151")),
        waves(169),
    ], category="Ships")

    write("ship_freighter.svg", "Heavy Freighter", "Three square-rigged masts meet the two-deck cargo hull at (53,124), (101,124), and (147,108). A high sterncastle, deep draft and cargo hatches identify the freighter.", [
        group("standing-rigging", marks("M14 107 L53 30 L101 22 L147 35 L183 108 M53 30 L29 124 M101 22 L67 124 M147 35 L118 124"),
              ratlines(53, 67, 34, 124), ratlines(101, 65, 82, 124), ratlines(147, 68, 168, 108)),
        group("masts", mast(53, 124, 29, "fore"), mast(101, 124, 22, "main"), mast(147, 108, 35, "mizzen"),
              path("M101 22 L118 25 L112 31 L101 30 Z", RED)),
        group("canvas", square_sail(53, 43, 31, 23), square_sail(53, 76, 40, 30),
              square_sail(101, 36, 33, 26), square_sail(101, 73, 43, 35),
              square_sail(147, 47, 28, 21), square_sail(147, 78, 32, 24),
              marks("M36 107 L29 124 M71 107 L78 124 M81 109 L72 124 M120 109 L126 124 M133 103 L124 124 M161 103 L170 108")),
        group("deck-cargo", rect(61, 114, 18, 10), rect(108, 113, 19, 11),
              marks("M61 114 l18 10 M61 124 l18 -10 M108 113 l19 11 M108 124 l19 -11"),
              line(34, 124, 10, 105, 3), line(10, 105, 53, 76)),
        group("hull-engraving", path("M27 124 H135 V108 H177 L184 135 Q179 160 157 168 H60 Q40 163 27 124 Z", SHADE, 3, "hull"),
              path("M27 124 H135 M135 108 H177", width=3, ident="deck-main"),
              path("M35 135 H181 M41 147 H177 M49 157 H169 M64 164 H153", width=2),
              path("M136 122 H178 M137 109 V134 M175 110 L180 134", width=1.5),
              *[rect(x, 113, 6, 6, INK) for x in (143, 155, 167)],
              *[rect(x, 137, 7, 6, VELLUM) for x in (51, 69, 87, 105, 123, 141, 159)],
              marks("M52 149 l12 11 M64 149 l12 13 M76 149 l12 13 M88 149 l12 13 M100 149 l12 13 M112 149 l12 13 M124 149 l12 13 M136 149 l12 12 M148 149 l12 9 "
                    "M58 159 l10 -10 M77 162 l12 -13 M98 162 l12 -13 M120 162 l12 -13 M141 160 l11 -11"),
              circle(170, 128, 3, GOLD)),
        waves(179),
    ], category="Ships")

    write("ship_corvette.svg", "Swift Corvette", "Fine raked clipper bow and two lateen rigs with booms and sheets. Masts are rooted on the deck at (74,128) and (132,128); the bowsprit joins the bow at (32,128).", [
        group("standing-rigging", marks("M10 101 L69 32 L130 41 L173 128 M69 32 L42 128 M130 41 L102 128")),
        group("masts", line(74, 128, 69, 32, 3, "mast-fore"), line(132, 128, 130, 41, 3, "mast-main"),
              path("M69 32 L87 34 L80 40 L69 40 Z", RED)),
        group("lateen-canvas", path("M41 51 L98 100 L58 107 Q57 79 41 51 Z", VELLUM),
              line(38, 48, 101, 103, 3), line(58, 108, 99, 103, 2.5),
              path("M99 55 L158 104 L116 115 Q116 84 99 55 Z", VELLUM),
              line(96, 52, 162, 107, 3), line(116, 115, 158, 108, 2.5),
              path("M15 104 L62 57 L48 117 Z", VELLUM),
              marks("M28 105 L53 76 M47 67 Q66 82 76 104 M55 68 L89 100 M108 70 Q126 88 132 112 M116 71 L148 104 "
                    "M57 103 l8 -1 M55 97 l10 3 M116 109 l9 2 M116 102 l11 5 "
                    "M58 107 L46 128 M98 104 L110 128 M116 115 L109 128 M158 108 L171 128 M48 117 L34 128")),
        group("bow-and-deck", line(32, 128, 8, 99, 3), rect(91, 119, 16, 9),
              path("M148 128 V121 H168 L174 128 Z", SHADE)),
        group("hull-engraving", path("M22 120 L42 128 H177 L167 145 Q133 160 65 154 Q39 149 22 120 Z", SHADE, 3, "hull"),
              path("M42 128 H177", width=3, ident="deck-main"),
              path("M34 133 Q93 148 170 135 M45 144 Q99 157 157 145", width=2),
              *[circle(x, 137, 2, INK) for x in (64, 81, 98, 115, 132, 149)],
              marks("M56 145 l6 6 M68 148 l5 5 M81 150 l4 4 M94 151 l3 3 M108 151 l3 3 M122 150 l4 3 M136 148 l4 3 "
                    "M58 151 l5 -5 M73 152 l4 -4 M88 153 l3 -3 M123 153 l4 -4"),
              circle(163, 132, 2.5, GOLD)),
        waves(168),
    ], category="Ships")

    write("ship_standard.svg", "Standard Sloop", "Balanced two-masted merchant schooner with gaff sails, a square topsail and a jib. Both masts terminate on the deck at (70,128) and (125,128).", [
        group("standing-rigging", marks("M10 108 L70 34 L125 29 L174 128 M70 34 L40 128 M125 29 L101 128"),
              ratlines(70, 84, 51, 128, 5), ratlines(125, 84, 146, 128, 5)),
        group("masts", mast(70, 128, 34, "fore"), mast(125, 128, 29, "main"),
              path("M125 29 L145 32 L139 39 L125 38 Z", RED)),
        group("schooner-canvas", square_sail(70, 45, 30, 24),
              path("M74 77 L99 65 L102 112 L74 116 Z", VELLUM),
              line(70, 80, 99, 64, 2.5), line(70, 116, 105, 114, 2.5),
              path("M129 53 L161 42 L168 111 L129 118 Z", VELLUM),
              line(125, 56, 162, 41, 2.5), line(125, 119, 171, 113, 2.5),
              path("M13 111 L66 49 L48 114 Z", VELLUM),
              marks("M25 109 L57 67 M79 79 L83 111 M88 75 L92 111 M136 56 Q139 84 137 114 M147 53 Q154 83 152 111 "
                    "M76 105 l7 7 M76 100 l12 11 M158 99 l6 6 M154 103 l11 7 "
                    "M48 114 L37 128 M102 113 L112 128 M168 112 L177 128")),
        group("deck-fittings", line(32, 128, 8, 105, 3), rect(88, 119, 18, 9),
              path("M149 128 V119 H171 V128 Z", SHADE), rect(157, 121, 7, 4, INK)),
        group("hull-engraving", path("M29 128 H180 L169 150 Q136 166 65 158 Q44 151 29 128 Z", SHADE, 3, "hull"),
              path("M29 128 H180", width=3, ident="deck-main"),
              path("M37 138 H174 M48 149 Q103 164 164 149", width=2),
              *[rect(x, 140, 6, 5, INK) for x in (59, 78, 97, 116, 135, 154)],
              marks("M59 149 l7 7 M71 151 l6 6 M84 153 l5 5 M97 154 l4 5 M110 154 l4 5 M123 153 l5 4 M137 151 l5 4 M149 149 l5 3 "
                    "M65 156 l5 -6 M85 158 l5 -5 M110 159 l5 -5 M139 155 l5 -5"),
              circle(172, 134, 2.5, GOLD)),
        waves(173),
    ], category="Ships")

    write("ship_flying_dutchman.svg", "Flying Dutchman", "Haunted galleon with three rooted masts at (53,126), (104,126), and (151,112). Torn canvas, exposed barnacle ribs, broken stern galleries and thin spectral wakes evoke an antique sea legend.", [
        group("spectral-wake", marks("M18 160 Q5 137 13 118 M10 143 Q3 127 8 118 M181 119 Q194 137 183 160 "
                    "M5 173 Q23 155 44 171 M151 171 Q176 156 195 172 M21 184 Q41 174 57 180 M146 181 Q167 174 184 181")),
        group("standing-rigging", marks("M12 104 L53 29 L104 20 L151 36 L182 112 M53 29 L28 126 M104 20 L77 126 M151 36 L126 126"),
              ratlines(53, 74, 34, 126), ratlines(104, 75, 84, 126),
              marks("M151 67 L173 112 M153 77 l5 2 M155 86 l8 2 M158 95 l10 2")),
        group("masts", mast(53, 126, 29, "fore"), mast(104, 126, 20, "main"), mast(151, 112, 36, "mizzen"),
              path("M104 20 L127 23 L117 27 L123 32 L104 31 Z", SHADE),
              marks("M110 24 l7 1")),
        group("tattered-canvas", square_sail(53, 44, 29, 26, True), square_sail(53, 80, 38, 31, True),
              square_sail(104, 35, 34, 28, True), square_sail(104, 76, 43, 34, True),
              square_sail(151, 50, 27, 23, True), square_sail(151, 82, 31, 23, True),
              marks("M36 111 L28 126 M69 111 L76 126 M85 111 L76 126 M123 111 L130 126 M165 105 L174 112"),
              path("M97 90 Q104 83 111 90 L109 99 H99 Z", SHADE),
              circle(101, 91, 1.5, INK), circle(107, 91, 1.5, INK),
              marks("M102 98 V102 M106 98 V102 M97 105 L112 101 M98 101 L112 105")),
        group("broken-deck", line(31, 126, 10, 102, 3),
              path("M135 126 V112 L141 112 L145 105 L149 112 H178 L182 125 L177 132 Z", SHADE),
              path("M146 113 L145 122 H153 L152 113 Z M163 114 L165 124 H173 L170 114 Z", INK)),
        group("hull-engraving", path("M25 126 H135 V112 H178 L186 139 L176 146 L173 158 L158 166 L150 163 L142 169 H67 L49 159 L41 147 L33 145 Z", SHADE, 3, "hull"),
              path("M25 126 H135 M135 112 H178", width=3, ident="deck-main"),
              path("M34 137 H179 M44 149 Q107 166 169 151", width=2),
              *[path(f"M{x} 139 q-4 12 6 22 l5 -2 q-9 -9 -6 -20 Z", VELLUM, 1.5) for x in (56, 76, 96, 116, 136, 156)],
              marks("M46 140 l8 -2 M68 145 l8 -2 M88 146 l8 -2 M108 146 l8 -2 M128 146 l8 -2 M148 144 l8 -2 "
                    "M61 152 l6 5 M81 153 l6 5 M101 154 l6 5 M121 154 l6 5 M141 152 l6 5"),
              *[circle(x, y, r, VELLUM) for x, y, r in ((44,148,2),(50,153,2.5),(64,162,2),(87,162,2.5),(110,165,2),(132,163,2),(156,161,2.5),(169,152,2))]),
        waves(176),
    ], category="Ships")


def icons():
    write("icon_unstable_tincture.svg", "Unstable Tincture", "Corked apothecary bottle containing bubbling venom, with a droplet seal and engraved glass reflections.", [
        path("M24 16 V25 Q14 29 14 39 V51 Q14 57 21 58 H43 Q50 57 50 51 V39 Q50 29 40 25 V16 Z", VELLUM, 2.5),
        path("M17 39 Q25 35 32 39 T47 39 V51 Q47 55 42 55 H22 Q17 55 17 51 Z", SHADE),
        rect(25, 6, 14, 10), rect(22, 16, 20, 6, GOLD),
        marks("M28 8 l5 6 M34 8 l3 3 M26 19 H38 M19 32 Q22 28 26 28 M19 35 V46 "
              "M42 46 l5 5 M40 49 l5 5 M38 52 l3 3"),
        circle(25, 42, 2), circle(39, 33, 2), circle(33, 28, 1.5),
        path("M33 40 Q25 49 29 51 Q33 54 36 51 Q40 48 33 40 Z", RED),
    ], 64, "Consumables")

    write("icon_blast_pack.svg", "Blast Pack", "Wooden gunpowder keg bound with iron hoops and crossed cord. A burning fuse sparks above the bung.", [
        path("M19 18 Q32 12 45 18 Q52 35 45 54 Q32 61 19 54 Q12 35 19 18 Z", SHADE, 2.5),
        path("M19 18 Q32 23 45 18 M17 51 Q32 57 47 51", width=1.5),
        marks("M24 21 Q20 37 24 55 M31 22 V56 M38 21 Q42 38 38 56 "
              "M19 34 l5 5 M18 39 l6 5 M20 46 l4 4 M37 35 l6 6 M37 41 l6 6"),
        path("M17 25 Q32 30 47 25 L48 30 Q32 35 16 30 Z", VELLUM),
        path("M16 44 Q32 49 48 44 L47 50 Q32 55 17 50 Z", VELLUM),
        marks("M21 27 V30 M42 27 V30 M21 47 V50 M42 47 V50"),
        path("M19 20 L45 54 M45 20 L19 54", width=2),
        rect(28, 13, 8, 5, GOLD), path("M32 13 C31 5 43 15 45 6", width=2.5),
        path("M45 6 l-2 -4 M48 7 l5 -3 M48 10 l6 2", width=1.5, extra=f' stroke="{RED}"'),
    ], 64, "Consumables")

    # Alternating tooth roots and raked tooth tips form a single native ring path.
    points = []
    for i in range(16):
        for fraction, radius in ((0, 25), (0.20, 29), (0.65, 25)):
            a = (i + fraction) * 2*pi/16 - pi/2
            points.append((round(32 + radius*cos(a), 2), round(32 + radius*sin(a), 2)))
    outer = "M" + " L".join(f"{x} {y}" for x, y in points) + " Z"
    inner = "M48 32 A16 16 0 1 0 16 32 A16 16 0 1 0 48 32 Z"
    hatches = []
    for i in range(32):
        a = i*2*pi/32
        hatches.append(line(round(32+19*cos(a),2), round(32+19*sin(a),2),
                            round(32+24*cos(a+0.08),2), round(32+24*sin(a+0.08),2)))
    write("icon_chakram.svg", "Chakram", "Sixteen serrated teeth surround an open throwing ring. Radial engraving and crossed edge hatching define its sharpened bevel.", [
        path(outer + " " + inner, VELLUM, 2, extra=' fill-rule="evenodd"'),
        path("M54 32 A22 22 0 1 0 10 32 A22 22 0 1 0 54 32 Z", width=1.5),
        *hatches,
        marks("M29 9 l5 6 M31 9 l-3 6 M49 19 l-1 7 M52 21 l-6 2 "
              "M49 43 l-7 1 M47 47 l-2 -6 M29 49 l5 6 M31 55 l3 -6 "
              "M13 40 l7 2 M15 45 l3 -6 M14 20 l6 1 M17 17 l1 7"),
    ], 64, "Consumables")

    write("icon_cannon.svg", "Broadside Cannon", "Cast broadside gun on a wheeled oak carriage, with reinforced barrel rings, breech knob, trunnion and touch hole.", [
        path("M13 37 L49 32 L55 44 H12 Z", SHADE, 2.5),
        marks("M17 40 H49 M20 39 l4 4 M28 38 l6 5 M36 37 l6 6"),
        path("M15 27 Q13 23 18 22 L49 15 L53 25 L22 33 Q18 34 15 30 Z", VELLUM, 2.5),
        path("M47 15 L51 14 L55 25 L51 27 Z", SHADE),
        path("M24 21 L27 31 M34 18 L37 28", width=2.5),
        circle(14, 28, 3, GOLD), circle(31, 29, 3, GOLD),
        circle(21, 46, 7, SHADE, 2), circle(46, 46, 7, SHADE, 2),
        circle(21, 46, 2, GOLD), circle(46, 46, 2, GOLD),
        marks("M21 39 V43 M21 49 V53 M14 46 H18 M24 46 H28 M46 39 V43 M46 49 V53 M39 46 H43 M49 46 H53 M18 25 L22 24 M39 20 l6 -1 M41 23 l6 -1 M9 56 H57"),
    ], 64, "Ship weapons")

    write("icon_torpedo_launcher.svg", "Torpedo Launcher", "Riveted twin launch tubes in an oak deck cradle, with a pointed brass torpedo, tail fins and handwheel.", [
        path("M11 39 H49 L55 49 H7 Z", SHADE),
        path("M12 29 L43 18 L51 25 L20 37 Z", SHADE, 2.5),
        path("M15 37 L46 26 L54 33 L23 45 Z", VELLUM, 2.5),
        path("M43 18 L51 25 L54 20 L52 14 Z", GOLD),
        path("M46 26 L54 33 L57 28 L56 21 Z", SHADE),
        path("M7 20 L33 11 L43 13 L37 20 L12 28 Z", GOLD),
        path("M7 20 L6 14 L16 19 M12 28 L7 32 L9 23", VELLUM),
        marks("M29 13 l3 9 M24 22 l7 -2 M22 28 l2 7 M32 25 l2 7 M25 37 l3 6 M38 32 l3 6 M14 47 l6 -2 M29 47 l6 -2"),
        circle(11, 40, 5, VELLUM), circle(11, 40, 1.5, GOLD),
        marks("M11 35 V38 M11 42 V45 M6 40 H9 M13 40 H16"),
        rect(12, 50, 9, 5), rect(42, 50, 9, 5),
    ], 64, "Ship weapons")

    write("icon_blade_launcher.svg", "Blade Launcher", "Deck-mounted rotary blade launcher. An open circular saw sits in a braced wooden track driven by a brass crank.", [
        path("M8 42 L46 33 L55 45 L17 54 Z", SHADE, 2.5),
        path("M11 40 L47 30 L51 35 L15 46 Z", VELLUM),
        path("M13 47 L48 38 M21 44 L24 51 M39 39 L43 47", width=2),
        path("M20 43 L25 30 L31 30 L37 39", SHADE),
        path("M39 7 L43 11 L50 10 L49 17 L55 21 L50 26 L52 33 L45 33 L41 39 L36 34 L29 36 L29 29 L23 25 L28 20 L26 13 L33 13 Z "
             "M45 23 A7 7 0 1 0 31 23 A7 7 0 1 0 45 23 Z", VELLUM, 2, extra=' fill-rule="evenodd"'),
        marks("M36 12 l3 3 M46 15 l-3 3 M49 24 l-4 1 M44 31 l-3 -3 M34 32 l1 -4 M28 23 l4 1 M31 15 l3 3"),
        circle(21, 38, 5, GOLD), circle(21, 38, 1.5, INK),
        path("M21 38 L13 34 L11 28", width=2.5), circle(11, 27, 2, SHADE),
        marks("M20 49 l7 -2 M29 46 l7 -2 M8 57 H54"),
    ], 64, "Ship weapons")

    write("icon_lightning_railgun.svg", "Lightning Railgun", "Nautical brass and iron railgun with paired rails, induction coils, Leyden jar and a crimson lightning discharge.", [
        path("M8 43 L46 35 L53 48 H12 Z", SHADE, 2.5),
        path("M16 35 L47 20 L51 25 L20 40 Z", VELLUM),
        path("M13 26 L44 11 L48 16 L17 31 Z", VELLUM),
        path("M13 26 L17 31 L20 40 L16 35 Z", SHADE),
        path("M44 11 L48 16 M47 20 L51 25", width=3),
        *[path(f"M{x} {y} l4 3 l2 8 l-4 2 l-3 -10 Z", GOLD, 1.5) for x,y in ((21,22),(29,18),(37,14))],
        path("M8 27 V16 H15 V27 Q12 31 8 27 Z", VELLUM), rect(7, 13, 9, 4, GOLD),
        path("M12 13 V8 M12 29 Q6 39 17 43", width=2), circle(12, 7, 2, GOLD),
        path("M52 9 L58 5 L55 14 L61 12 L54 23", width=2, extra=f' stroke="{RED}"'),
        marks("M21 44 l4 3 M29 42 l5 5 M37 40 l7 7 M20 49 V55 M44 49 V55 M16 55 H25 M40 55 H49"),
    ], 64, "Ship weapons")

    write("icon_flamethrower.svg", "Flamethrower", "A copper pressure reservoir feeds an iron fire projector through a curved hose. A wick flame and brass valve distinguish the deck weapon.", [
        path("M8 34 Q8 29 14 29 H22 Q28 29 28 34 V48 Q28 53 22 53 H14 Q8 53 8 48 Z", SHADE, 2.5),
        rect(7, 35, 22, 5, VELLUM), rect(13, 24, 10, 5, GOLD),
        path("M18 24 V20 M14 21 H22", width=2),
        path("M25 46 C40 55 42 35 32 33", width=3),
        path("M29 30 L44 20 L48 27 L34 37 Z", VELLUM, 2.5),
        path("M42 20 L47 17 L52 26 L47 29 Z", GOLD),
        path("M37 35 L43 44 H51 L54 51 H33 L29 44 Z", SHADE),
        path("M51 22 Q50 14 55 12 Q53 16 58 16 Q61 13 59 8 Q65 19 58 24 Z", RED),
        marks("M54 21 Q54 18 57 17 M12 43 l5 7 M18 42 l6 7 M12 49 l6 -6 M34 30 l7 -4 M38 33 l6 -4 M39 45 l4 4 M47 45 l4 4 M7 57 H54"),
        circle(33, 32, 2.5, GOLD),
    ], 64, "Ship weapons")


def monsters():
    write("monster_shark.svg", "Cartographer's Shark", "A muscular predatory shark in profile, engraved with gill cuts, a serrated jaw, hatched flanks and curling sea foam.", [
        group("fins", path("M85 83 L107 39 Q107 68 127 81 Z", SHADE, 2.5),
              path("M114 124 L150 160 L138 121 Z", SHADE),
              path("M148 91 L179 58 L173 96 L188 130 L151 113 Z", SHADE, 2.5),
              marks("M104 57 l-8 22 M109 71 l-6 9 M172 75 L156 98 M178 119 L160 108 M131 133 l9 15")),
        group("body", path("M13 107 Q34 74 84 79 Q119 77 159 96 L164 105 L154 117 Q103 144 55 129 L27 120 Z", VELLUM, 3),
              path("M28 113 Q75 122 119 113 Q141 111 154 106", width=2),
              path("M65 112 Q94 115 115 99 L102 144 Q77 145 65 112 Z", SHADE),
              marks("M83 119 l17 -8 M82 125 l15 -8 M86 131 l8 -6 "
                    "M50 91 Q55 101 51 109 M59 88 Q65 102 60 114 M69 87 Q76 103 71 114 "
                    "M91 85 l11 9 M102 85 l12 9 M113 86 l11 10 M125 89 l11 10 M137 92 l10 9 "
                    "M102 96 l10 -9 M120 99 l10 -9 M139 102 l7 -7 "
                    "M123 122 l6 4 M135 118 l6 3"),
              path("M16 110 L34 108 L46 115 L26 120 Z", RED),
              path("M21 110 l3 5 l3 -5 l3 5 l3 -5 l4 5 l3 -3 M30 119 l2 -4 l3 5 l3 -3", VELLUM, 1.5),
              circle(38, 100, 4, GOLD), circle(37, 100, 1.5, INK),
              marks("M32 93 L43 95 M14 107 L23 105")),
        waves(171),
    ], category="Monsters")

    write("monster_serpent.svg", "Leviathan Serpent", "A horned sea serpent rises in connected coils. Overlapping engraved scales, dorsal spines and a toothed crimson mouth recall sea-chart marginalia.", [
        group("dorsal-spines", path("M59 72 L71 52 L73 76 L88 69 L87 91 L107 98 L119 67 L128 88 L141 69 L146 98 L163 92 L172 119", SHADE),
              marks("M70 62 L69 74 M121 78 L123 87 M142 80 L143 94")),
        group("coiled-body", path("M43 81 C61 72 69 98 67 121 C66 143 89 151 104 127 C117 106 109 93 129 87 C149 80 162 102 164 124 C166 145 176 143 187 131 C185 156 158 163 149 141 C137 114 142 102 130 105 C122 107 135 128 118 148 C95 179 51 164 48 135 C45 112 53 99 43 95 Z", SHADE, 3),
              path("M51 92 C62 111 52 133 65 148 C78 164 102 153 112 133 C123 114 117 100 132 96 C150 92 151 118 157 138 C163 155 180 148 187 131", width=2),
              marks("M55 113 l10 -2 M55 121 l11 1 M55 130 l12 3 M59 140 l11 4 M67 148 l10 4 M79 154 l10 -1 M92 151 l9 -6 M103 143 l8 -7 "
                    "M119 114 l10 2 M123 123 l10 2 M120 133 l10 2 M114 142 l8 5 "
                    "M144 106 l10 -2 M147 116 l12 -2 M151 127 l12 -1 M156 138 l10 -2 M165 146 l7 -4"),
              *[marks(f"M{x} {y} q4 -5 8 0 q4 5 8 0 M{x+4} {y+6} q4 -5 8 0") for x,y in ((71,139),(86,137),(120,94),(136,98),(156,129))]),
        group("head", path("M53 88 Q61 66 48 59 L48 43 L37 58 L26 52 L20 65 Q10 67 9 78 L24 86 L39 85 L43 96 Z", VELLUM, 2.5),
              path("M10 77 L28 76 L36 84 L23 87 Z", RED),
              path("M15 77 l3 6 l4 -6 l4 7 l3 -5 M22 87 l3 -4 l3 3", VELLUM, 1.5),
              circle(29, 68, 3, GOLD), line(29, 66, 29, 70, 1.5),
              marks("M37 65 l10 4 M39 71 l9 4 M41 77 l8 3 M39 59 l5 -8 M14 69 l5 1 M37 83 l5 6")),
        waves(180),
    ], category="Monsters")

    write("monster_jellyfish.svg", "Stinging Medusa", "An engraved domed bell with scalloped margins and connected venomous tendrils. Stippled cells and sinuous oral arms preserve a transparent vellum silhouette.", [
        group("tendrils", path("M49 94 C28 117 66 134 43 163 Q34 177 47 185 M60 100 C44 124 81 134 59 158 Q48 172 65 182 "
                    "M81 102 C63 130 101 141 79 170 M119 102 C137 132 99 140 121 170 "
                    "M141 98 C158 120 123 139 145 159 Q158 172 139 183 M151 93 C177 118 139 135 163 163 Q175 179 159 187", width=2.5),
              path("M94 95 C68 118 107 136 91 152 C79 166 96 180 100 181 C96 163 118 151 106 135 C95 122 117 110 108 96 Z", SHADE),
              marks("M95 111 l8 5 M90 121 l9 5 M96 134 l9 2 M95 147 l7 4 M91 161 l5 4 "
                    "M41 121 l6 3 M52 141 l6 -2 M143 137 l6 2 M157 115 l6 -2")),
        group("bell", path("M33 90 C34 18 164 18 167 90 Q158 102 149 94 Q140 108 130 99 Q118 111 107 101 Q95 113 84 101 Q71 110 62 98 Q46 105 43 94 Q37 99 33 90 Z", VELLUM, 3),
              path("M35 86 Q101 61 165 86 L167 90 Q158 102 149 94 Q140 108 130 99 Q118 111 107 101 Q95 113 84 101 Q71 110 62 98 Q46 105 43 94 Q37 99 33 90 Z", SHADE),
              marks("M49 77 Q51 46 80 40 M64 76 Q65 48 86 38 M82 74 Q84 45 95 36 M100 73 V36 M118 74 Q118 45 105 36 M136 77 Q135 47 114 39 M153 79 Q150 48 124 43 "
                    "M42 79 l8 3 M47 70 l7 3 M52 61 l7 3 M58 53 l7 3 M147 64 l7 -2 M151 72 l7 -2 M154 81 l6 -2 "
                    "M51 89 l7 5 M67 86 l8 7 M87 84 l8 9 M108 84 l8 9 M129 86 l8 7 M147 89 l8 5"),
              circle(84, 55, 2, SHADE), circle(116, 57, 2, SHADE), circle(98, 64, 2, GOLD)),
    ], category="Monsters")

    write("monster_squid.svg", "Abyssal Squid", "A tapered squid mantle with paired fins and eight attached curling arms. Engraved suckers, mantle hatching and watchful eyes suggest an abyssal chart specimen.", [
        group("fins", path("M84 48 Q56 42 45 73 Q60 67 78 81 Z M116 48 Q145 42 155 73 Q138 67 122 81 Z", SHADE),
              marks("M54 66 L77 56 M61 67 L78 63 M123 55 L146 66 M122 62 L139 68")),
        group("arms", path("M76 111 C51 110 55 137 31 133 C9 129 6 156 26 158 C12 148 25 143 33 148 C63 164 66 128 88 122 Z", SHADE),
              path("M124 111 C149 110 145 137 169 133 C191 129 194 156 174 158 C188 148 175 143 167 148 C137 164 134 128 112 122 Z", SHADE),
              path("M82 118 C67 134 81 155 57 159 C36 162 44 185 59 178 C47 177 49 170 60 171 C94 171 82 144 96 125 Z", VELLUM),
              path("M118 118 C133 134 119 155 143 159 C164 162 156 185 141 178 C153 177 151 170 140 171 C106 171 118 144 104 125 Z", VELLUM),
              path("M87 119 C83 143 96 161 78 182 Q88 179 94 170 C100 151 93 138 100 124 Z", SHADE),
              path("M113 119 C117 143 104 161 122 182 Q112 179 106 170 C100 151 107 138 100 124 Z", SHADE),
              path("M74 108 C43 98 30 113 21 103 Q23 121 46 117 L78 117 Z M126 108 C157 98 170 113 179 103 Q177 121 154 117 L122 117 Z", VELLUM),
              marks("M76 125 Q63 130 58 144 M124 125 Q137 130 142 144 M82 145 Q82 161 60 166 M118 145 Q118 161 140 166 "
                    "M88 139 l4 7 M108 139 l4 7 M36 110 L47 110 M153 110 H164"),
              *[circle(x,y,2,VELLUM) for x,y in ((65,128),(58,137),(45,145),(32,144),(135,128),(142,137),(155,145),(168,144),(76,151),(69,160),(124,151),(131,160))]),
        group("mantle", path("M100 21 C81 42 73 78 74 101 Q69 118 85 126 Q100 131 115 126 Q131 118 126 101 C127 78 119 42 100 21 Z", VELLUM, 3),
              path("M100 30 Q88 65 88 94 M106 38 Q117 70 116 94", width=1.5),
              marks("M84 61 l5 5 M81 70 l6 6 M79 79 l7 7 M78 88 l8 7 M111 58 l5 5 M114 69 l6 6 M116 80 l6 6 "
                    "M80 84 l7 -8 M111 77 l8 -7 M93 122 Q100 125 107 122"),
              circle(85, 107, 6, SHADE, 2), circle(115, 107, 6, SHADE, 2),
              circle(85, 107, 2, INK), circle(115, 107, 2, INK),
              path("M96 114 L100 120 L104 114 Z", RED)),
    ], category="Monsters")

    write("monster_crustacean.svg", "Armored Crustacean", "A carapaced sea crab with articulated limbs, two enormous toothed pincers, stalked eyes and a cross-hatched segmented shell.", [
        group("walking-legs", *[path(d, SHADE, 2) for d in (
            "M69 104 L43 98 L24 125 L40 114 L69 117 Z", "M68 121 L41 125 L27 151 L46 137 L74 132 Z",
            "M78 138 L55 150 L52 177 L63 158 L88 147 Z", "M131 104 L157 98 L176 125 L160 114 L131 117 Z",
            "M132 121 L159 125 L173 151 L154 137 L126 132 Z", "M122 138 L145 150 L148 177 L137 158 L112 147 Z")],
              marks("M43 98 L40 114 M41 125 L46 137 M55 150 L63 158 M157 98 L160 114 M159 125 L154 137 M145 150 L137 158")),
        group("pincer-arms", path("M72 105 L51 87 L44 73 L34 77 L39 95 L64 121 Z", SHADE, 2.5),
              path("M128 105 L149 87 L156 73 L166 77 L161 95 L136 121 Z", SHADE, 2.5),
              circle(48, 89, 5, VELLUM), circle(152, 89, 5, VELLUM)),
        group("pincers", path("M43 83 C15 81 9 47 24 29 Q22 50 38 55 L37 21 C62 35 64 69 43 83 Z", VELLUM, 3),
              path("M157 83 C185 81 191 47 176 29 Q178 50 162 55 L163 21 C138 35 136 69 157 83 Z", VELLUM, 3),
              path("M38 31 L46 37 L39 43 L47 49 L39 55 M162 31 L154 37 L161 43 L153 49 L161 55", SHADE, 1.5),
              marks("M22 56 Q28 70 40 72 M49 44 Q57 61 45 74 M178 56 Q172 70 160 72 M151 44 Q143 61 155 74 "
                    "M25 63 l8 -3 M29 69 l8 -3 M175 63 l-8 -3 M171 69 l-8 -3")),
        group("carapace", path("M58 109 L64 94 L72 91 L80 83 Q100 77 120 83 L128 91 L136 94 L142 109 L137 129 L122 145 Q100 153 78 145 L63 129 Z", SHADE, 3),
              path("M73 96 Q100 84 127 96 L132 115 L120 133 Q100 141 80 133 L68 115 Z", VELLUM),
              marks("M74 106 Q100 94 126 106 M71 116 Q100 106 129 116 M78 127 Q100 118 122 127 "
                    "M76 100 l8 5 M88 96 l8 5 M101 96 l8 5 M115 100 l8 5 M76 113 l7 4 M89 109 l8 4 M103 109 l8 4 M116 113 l8 4 "
                    "M86 132 l7 5 M104 133 l6 4 M72 111 l10 -10 M90 107 l10 -10 M109 108 l10 -8 "
                    "M65 105 l-3 8 M66 124 l7 8 M134 105 l3 8 M134 124 l-7 8"),
              path("M85 84 L80 71 M115 84 L120 71", width=3),
              circle(79, 68, 5, GOLD), circle(121, 68, 5, GOLD),
              circle(79, 68, 2, INK), circle(121, 68, 2, INK),
              path("M91 140 L100 145 L109 140", width=2)),
        waves(181),
    ], category="Monsters")

    write("monster_kraken.svg", "Colossal Kraken", "A crowned abyssal kraken with eight connected curling tentacles, double rows of engraved suckers and a crimson beak. Its massive domed mantle towers over the chart's sea lines.", [
        group("eight-tentacles", *[path(d, SHADE if i%2 == 0 else VELLUM, 2.5) for i,d in enumerate((
            "M75 97 C51 93 55 65 34 58 C12 51 7 70 20 78 C15 65 25 65 32 70 C44 80 40 113 68 119 Z",
            "M125 97 C149 93 145 65 166 58 C188 51 193 70 180 78 C185 65 175 65 168 70 C156 80 160 113 132 119 Z",
            "M69 110 C44 104 41 127 24 113 C5 97 3 133 23 140 C49 151 45 125 77 126 Z",
            "M131 110 C156 104 159 127 176 113 C195 97 197 133 177 140 C151 151 155 125 123 126 Z",
            "M78 120 C45 128 64 160 33 155 C10 151 18 178 35 178 C24 169 30 166 38 168 C76 176 61 146 88 132 Z",
            "M122 120 C155 128 136 160 167 155 C190 151 182 178 165 178 C176 169 170 166 162 168 C124 176 139 146 112 132 Z",
            "M88 128 C67 149 99 166 73 181 C57 191 43 178 47 168 C42 183 61 199 81 189 C114 171 87 150 102 132 Z",
            "M112 128 C133 149 101 166 127 181 C143 191 157 178 153 168 C158 183 139 199 119 189 C86 171 113 150 98 132 Z",
        ))],
              marks("M67 108 Q52 105 46 87 M133 108 Q148 105 154 87 M69 119 Q48 118 40 131 M131 119 Q152 118 160 131 "
                    "M77 131 Q63 138 63 151 M123 131 Q137 138 137 151 M87 142 Q82 154 89 165 M113 142 Q118 154 111 165"),
              *[circle(x,y,2.5,VELLUM) for x,y in ((48,87),(43,76),(35,65),(152,87),(157,76),(165,65),(52,123),(44,132),(32,135),(148,123),(156,132),(168,135),(64,143),(59,154),(49,162),(136,143),(141,154),(151,162),(88,151),(92,163),(86,177),(112,151),(108,163),(114,177))],
              marks("M39 87 l6 2 M37 95 l6 2 M155 89 l6 -2 M157 97 l6 -2 M23 121 l3 6 M174 121 l3 6 M38 159 l6 3 M156 162 l6 -3")),
        group("mantle", path("M62 96 C58 64 68 35 87 30 L94 18 L100 28 L107 17 L114 31 C135 37 142 65 138 96 Q140 121 119 135 Q100 144 81 135 Q60 121 62 96 Z", VELLUM, 3),
              path("M75 77 Q72 48 91 36 M88 73 Q85 49 99 36 M112 73 Q115 49 104 36 M125 78 Q129 51 112 37", width=1.5),
              marks("M67 62 l7 6 M65 73 l8 7 M64 84 l9 7 M65 94 l8 7 M125 58 l7 7 M128 70 l8 7 M128 83 l8 7 M127 94 l7 6 "
                    "M65 85 l9 -9 M67 99 l7 -8 M126 87 l9 -9 M126 100 l8 -7 M77 122 l8 7 M123 122 l-8 7"),
              path("M72 95 Q83 85 94 96 Q84 108 72 95 Z M106 96 Q117 85 128 95 Q116 108 106 96 Z", SHADE, 2),
              circle(84, 96, 3, GOLD), circle(116, 96, 3, GOLD),
              line(84, 94, 84, 98, 1.5), line(116, 94, 116, 98, 1.5),
              path("M92 119 L100 111 L108 119 L100 132 Z", RED),
              marks("M95 121 L100 118 L105 121 M73 86 L91 90 M109 90 L127 86")),
    ], category="Monsters")


def gallery():
    groups = []
    for category in ("Ships", "Monsters", "Consumables", "Ship weapons"):
        cards = []
        for name, title, cat, size in CATALOG:
            if cat != category:
                continue
            src = "archive/svg/" + name
            cards.append(f'<article><div class="plate"><img src="{src}" alt="{title}" width="{size}" height="{size}"></div>'
                         f'<h3>{title}</h3><code>{name}</code>'
                         f'<div class="scales"><img src="{src}" alt="" width="32" height="32">'
                         f'<img src="{src}" alt="" width="48" height="48">'
                         f'<span>32 / 48 px</span></div></article>')
        groups.append(f'<section><h2>{category}</h2><div class="grid">' + "".join(cards) + "</div></section>")
    html = '''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>The Monstrous Sea — Engraving Proofs</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#F4ECD8;color:#1B1612;font-family:Georgia,serif;padding:42px;max-width:1500px;margin:auto}
header{border-bottom:3px double #1B1612;padding-bottom:24px}h1{font-weight:normal;font-size:42px;margin:8px 0 16px}p{max-width:800px;line-height:1.6}
.eyebrow,h2{font-size:13px;letter-spacing:3px;text-transform:uppercase}h2{border-bottom:1px solid #1B1612;padding-bottom:12px;margin-top:40px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:18px}article{border:1px solid #D5C4A1;padding:16px}
.plate{height:220px;display:flex;align-items:center;justify-content:center}.plate img{width:200px;height:200px}h3{font-size:18px;font-weight:normal;margin:12px 0 8px}
code{font-size:10px}.scales{margin-top:14px;display:flex;gap:12px;align-items:center;height:52px}.scales span{font-size:10px;letter-spacing:1px}
.swatches{display:flex;gap:16px;flex-wrap:wrap;font:12px monospace}.swatches i{display:inline-block;width:16px;height:16px;vertical-align:middle;border:1px solid #1B1612;margin-right:6px}
footer{margin-top:40px;border-top:3px double #1B1612;padding-top:18px;font-size:13px}
</style><header><div class="eyebrow">An atlas of vessels, beasts &amp; ordnance</div><h1>The Monstrous Sea</h1>
<p>Native vector engravings for the captain’s chart. Transparent SVG plates, rooted ship rigs and a restrained five-color palette. Inspect the large proofs and the small interface silhouettes below.</p>
<div class="swatches">'''
    for color in (INK, VELLUM, SHADE, RED, GOLD):
        html += f'<span><i style="background:{color}"></i>{color}</span>'
    html += '</div></header>' + "".join(groups) + '<footer>Ships &amp; beasts: 200 × 200 · Equipment: 64 × 64 · Engraving strokes: 1.5–3 units · Original authored paths</footer></html>'
    (ROOT / "docs/art/asset_gallery.html").write_text(html, encoding="utf-8")

    # A native, self-contained proof sheet: actual nested SVG geometry, not images.
    proof = [f'<svg xmlns="http://www.w3.org/2000/svg" width="1140" height="800" viewBox="0 0 1140 800" role="img" aria-labelledby="proof-title">',
             '<title id="proof-title">The Monstrous Sea: nineteen original vector engravings</title>',
             f'<rect width="1140" height="800" fill="{VELLUM}"/>',
             f'<g fill="{INK}" font-family="Georgia, serif">',
             '<text x="24" y="44" font-size="30">The Monstrous Sea · Engraving Proofs</text>',
             '<text x="24" y="78" font-size="12" letter-spacing="3">VESSELS</text>',
             '<text x="24" y="340" font-size="12" letter-spacing="3">BEASTS OF THE DEEP</text>',
             '<text x="24" y="594" font-size="12" letter-spacing="3">CONSUMABLES &amp; SHIP ORDNANCE</text>',
             '<text x="24" y="782" font-size="12">Native SVG paths · 200 × 200 vessels &amp; beasts · 64 × 64 equipment · Iron-gall ink on vellum</text>',
             '</g>']
    counters = {"Ships": 0, "Monsters": 0, "Equipment": 0}
    for name, title, category, _ in CATALOG:
        key = category if category in ("Ships", "Monsters") else "Equipment"
        i = counters[key]
        counters[key] += 1
        if key == "Ships":
            x, y, size, caption_y, font = 20+i*220, 88, 200, 307, 16
        elif key == "Monsters":
            x, y, size, caption_y, font = 30+i*180, 358, 170, 552, 14
        else:
            x, y, size, caption_y, font = 34+i*140, 616, 96, 735, 12
        source = (ART / name).read_text(encoding="utf-8")
        prefix = name.removesuffix(".svg")
        source = re.sub(r'id="([^"]+)"', lambda m: f'id="{prefix}-{m[1]}"', source)
        source = source.replace('aria-labelledby="title desc"', f'aria-labelledby="{prefix}-title {prefix}-desc"')
        source = re.sub(r'width="\d+" height="\d+"', f'x="{x}" y="{y}" width="{size}" height="{size}"', source, count=1)
        proof.append(source)
        proof.append(f'<text x="{x+size/2}" y="{caption_y}" text-anchor="middle" font-family="Georgia, serif" font-size="{font}" fill="{INK}">{escape(title)}</text>')
    proof.append('</svg>\n')
    (ROOT / "docs/art/asset_proof.svg").write_text("\n".join(proof), encoding="utf-8")


if __name__ == "__main__":
    ART.mkdir(parents=True, exist_ok=True)
    (ROOT / "docs/art").mkdir(parents=True, exist_ok=True)
    ships()
    monsters()
    icons()
    gallery()
    print(f"Authored {len(CATALOG)} standalone SVGs, HTML gallery and native SVG proof sheet.")
