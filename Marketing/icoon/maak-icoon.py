#!/usr/bin/env python3
"""Tekent het app-icoon van Memo!, Raak! of Dobbel! als 1024x1024-PNG.

De drie spellen delen één opbouw: crème grond, een koraalrode tegel schuin
achteraan en een witte tegel vooraan met het motief van het spel. Alleen het
motief verschilt, zodat de iconen naast elkaar op een telefoon als één
familie lezen.

Gebruik:  python3 maak-icoon.py memo|raak|dobbel uitvoer.png
Nodig:    pip install cairosvg pillow
"""
import io
import math
import sys

import cairosvg
from PIL import Image

# Vaste kleuren, uit het thema Klassiek van de apps.
CREAM = "#FCF4E3"
INK = "#21211C"
CORAL = "#FF6B4A"
AMBER = "#FFC93D"
SKY = "#4A9EFF"
SKY_TINT = "#D6EDFF"
WHITE = "#FFFFFF"

STROKE = 24   # inktrand van de tegels
DEPTH = 30    # harde slagschaduw onder elke tegel


def tile(cx, cy, size, radius, angle, fill, inner=""):
    """Een speelgoedtegel: blok met inktrand en hetzelfde blok iets lager."""
    half = size / 2
    rect = f'x="{-half}" y="{-half}" width="{size}" height="{size}" rx="{radius}"'
    return f'''
  <g transform="translate({cx} {cy}) rotate({angle})">
    <rect {rect} fill="{INK}" transform="translate(0 {DEPTH})" />
    <rect {rect} fill="{fill}" stroke="{INK}" stroke-width="{STROKE}" />
    {inner}
  </g>'''


def star_points(cx, cy, outer, inner, points=5, rotation=-90):
    pts = []
    for i in range(points * 2):
        r = outer if i % 2 == 0 else inner
        a = math.radians(rotation + i * 180 / points)
        pts.append(f"{cx + r * math.cos(a):.1f},{cy + r * math.sin(a):.1f}")
    return " ".join(pts)


def memo_motif():
    # Een omgedraaid kaartje met een ster, en een fonkeling ernaast.
    star = star_points(0, 12, 150, 66)
    sparkle = star_points(118, -118, 46, 14, points=4, rotation=-90)
    return f'''
    <polygon points="{star}" fill="{AMBER}" stroke="{INK}" stroke-width="18" stroke-linejoin="round" />
    <polygon points="{sparkle}" fill="{SKY}" stroke="{INK}" stroke-width="10" stroke-linejoin="round" />'''


def raak_motif():
    # Een stukje zee van 3x3 vakjes met één voltreffer in het midden.
    cell, gap = 100, 20
    step = cell + gap
    parts = []
    for row in range(3):
        for col in range(3):
            x = (col - 1) * step - cell / 2
            y = (row - 1) * step - cell / 2
            hit = row == 1 and col == 1
            parts.append(
                f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" rx="20" '
                f'fill="{CORAL if hit else SKY_TINT}" stroke="{INK}" stroke-width="10" />'
            )
    # Twee kleine golfjes en de knal op de voltreffer.
    burst = star_points(0, 0, 40, 18, points=8, rotation=-90)
    parts.append(f'<polygon points="{burst}" fill="{AMBER}" stroke="{INK}" stroke-width="7" stroke-linejoin="round" />')
    for (x, y) in [(-step, -step), (step, step)]:
        parts.append(f'<circle cx="{x - 18}" cy="{y - 18}" r="11" fill="{WHITE}" />')
    return "\n    ".join(parts)


def dobbel_motif():
    # Vijf ogen, zoals op een echte dobbelsteen.
    d, r = 118, 38
    pips = [(-d, -d), (d, -d), (0, 0), (-d, d), (d, d)]
    return "\n    ".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}" />' for x, y in pips)


MOTIFS = {"memo": memo_motif, "raak": raak_motif, "dobbel": dobbel_motif}


def svg(game):
    back = tile(398, 410, 400, 76, -9, CORAL)
    front = tile(584, 596, 470, 84, 6, WHITE, MOTIFS[game]())
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" fill="{CREAM}" />{back}{front}
</svg>'''


if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in MOTIFS:
        sys.exit(__doc__)
    png = cairosvg.svg2png(bytestring=svg(sys.argv[1]).encode(),
                           output_width=1024, output_height=1024)
    # De App Store weigert iconen met een alfakanaal.
    Image.open(io.BytesIO(png)).convert("RGB").save(sys.argv[2], optimize=True)
