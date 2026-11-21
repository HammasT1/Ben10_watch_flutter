#!/usr/bin/env python3
"""Generates the animated SVG artwork used by README.md.

Reads the alien roster from lib/data/aliens.dart so the art stays in sync
with the app. Run from the repo root:

    python3 tool/readme_art.py

Output goes to docs/readme/.
"""

import math
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "readme"

# App palette (lib/screens/omnitrix_screen.dart and friends).
GREEN = "#1FFF8B"
GREEN_HI = "#17FF73"
GREEN_SOFT = "#9BFFAE"
GLOW = "#D8FFE4"
RED = "#FF3B3B"
BG = "#030706"
BG_DEEP = "#010302"
PANEL = "#07140D"
DARK = "#081A10"
EDGE = "#113C25"

SANS = "'Segoe UI', 'Helvetica Neue', Ubuntu, Arial, sans-serif"
MONO = "'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace"


def load_aliens():
    src = (ROOT / "lib" / "data" / "aliens.dart").read_text()
    aliens = []
    for block in re.findall(r"Alien\((.*?)image:", src, re.S):
        def grab(key):
            m = re.search(key + r":\s*'([^']*)'", block)
            return m.group(1) if m else ""

        color = re.search(r"Color\(0xFF([0-9A-Fa-f]{6})\)", block).group(1)
        stats = {
            k: int(re.search(k + r":\s*(\d+)", block).group(1))
            for k in ("strength", "speed", "intelligence", "durability")
        }
        aliens.append(
            dict(
                name=grab("name"),
                species=grab("species"),
                homeworld=grab("homeworld"),
                color="#" + color.upper(),
                stats=stats,
            )
        )
    return aliens


def esc(text):
    return (
        text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )


def defs_common():
    return f"""
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
    <feGaussianBlur stdDeviation="5" result="b"/>
    <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <filter id="softglow" x="-80%" y="-80%" width="260%" height="260%">
    <feGaussianBlur stdDeviation="14"/>
  </filter>
  <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
    <path d="M40 0H0V40" fill="none" stroke="{GREEN}" stroke-opacity="0.06"/>
  </pattern>"""


def hourglass(cx, cy, r, fill, wedge=BG):
    """Omnitrix-style core: a lit disc with two dark side wedges."""
    w = r * 1.08
    return f"""
    <g>
      <circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"/>
      <polygon points="{cx - w},{cy - r * 0.86} {cx - r * 0.14},{cy} {cx - w},{cy + r * 0.86}" fill="{wedge}"/>
      <polygon points="{cx + w},{cy - r * 0.86} {cx + r * 0.14},{cy} {cx + w},{cy + r * 0.86}" fill="{wedge}"/>
    </g>"""


def svg(w, h, body, style=""):
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img">
<style>
  .spin {{ transform-box: view-box; animation: spin 36s linear infinite; }}
  .spin-rev {{ transform-box: view-box; animation: spin 48s linear infinite reverse; }}
  .breathe {{ transform-box: fill-box; transform-origin: center; animation: breathe 2.4s ease-in-out infinite; }}
  .flicker {{ animation: flicker 6s linear infinite; }}
  .blink {{ animation: blink 1s steps(1) infinite; }}
  @keyframes spin {{ to {{ transform: rotate(360deg); }} }}
  @keyframes breathe {{ 0%,100% {{ transform: scale(1); opacity: .9; }} 50% {{ transform: scale(1.05); opacity: 1; }} }}
  @keyframes flicker {{ 0%,18%,22%,62%,64%,100% {{ opacity: 1; }} 20%,63% {{ opacity: .45; }} }}
  @keyframes blink {{ 50% {{ opacity: 0; }} }}
  @keyframes wave {{ 0%,100% {{ opacity: .25; }} 50% {{ opacity: 1; }} }}
{style}
</style>
<defs>{defs_common()}
  <clipPath id="card"><rect width="{w}" height="{h}" rx="24"/></clipPath>
</defs>
<g clip-path="url(#card)">
{body}
</g>
<rect x="1" y="1" width="{w - 2}" height="{h - 2}" rx="23" fill="none" stroke="{EDGE}" stroke-width="2"/>
</svg>
"""


def ring_pulses(cx, cy, r0, r1, color, n=3, dur=3.0):
    out = []
    for i in range(n):
        begin = f"{i * dur / n:.2f}s"
        out.append(
            f"""
    <circle cx="{cx}" cy="{cy}" r="{r0}" fill="none" stroke="{color}" stroke-width="2">
      <animate attributeName="r" values="{r0};{r1}" dur="{dur}s" begin="{begin}" repeatCount="indefinite"/>
      <animate attributeName="stroke-opacity" values="0.7;0" dur="{dur}s" begin="{begin}" repeatCount="indefinite"/>
    </circle>"""
        )
    return "".join(out)


def sparks(xs, y0, y1, colors):
    out = []
    for i, x in enumerate(xs):
        c = colors[i % len(colors)]
        dur = 4 + (i * 37 % 30) / 10
        begin = (i * 53 % 40) / 10
        out.append(
            f"""
  <circle cx="{x}" cy="{y0}" r="{1.5 + (i % 3) * 0.8}" fill="{c}">
    <animate attributeName="cy" values="{y0};{y1}" dur="{dur}s" begin="-{begin}s" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;1;0" dur="{dur}s" begin="-{begin}s" repeatCount="indefinite"/>
  </circle>"""
        )
    return "".join(out)


def hero(aliens):
    W, H = 1200, 420
    cx, cy = 250, 210
    colors = [a["color"] for a in aliens]

    ticks = []
    for i in range(60):
        a = math.radians(i * 6)
        r_in = 128 if i % 5 == 0 else 135
        x1, y1 = cx + r_in * math.cos(a), cy + r_in * math.sin(a)
        x2, y2 = cx + 143 * math.cos(a), cy + 143 * math.sin(a)
        op = 0.9 if i % 5 == 0 else 0.4
        ticks.append(
            f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{GREEN}" stroke-opacity="{op}" stroke-width="2"/>'
        )

    dots = []
    n = len(aliens)
    for i, c in enumerate(colors):
        a = math.radians(-90 + i * 360 / n)
        x, y = cx + 110 * math.cos(a), cy + 110 * math.sin(a)
        dots.append(
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="7" fill="{c}" filter="url(#glow)" '
            f'style="animation: wave 2.2s ease-in-out {i * 0.2:.1f}s infinite both"/>'
        )

    tx = 470
    bars = "".join(
        f'<rect x="{tx + i * 46}" y="370" width="40" height="5" rx="2.5" fill="{c}" '
        f'style="animation: wave 2.2s ease-in-out {i * 0.2:.1f}s infinite both"/>'
        for i, c in enumerate(colors)
    )

    typed = "&gt; IT'S HERO TIME"
    type_w = 300
    body = f"""
  <defs>
    <radialGradient id="bg" cx="21%" cy="50%" r="85%">
      <stop offset="0" stop-color="#0d2a1a"/>
      <stop offset="0.45" stop-color="#04100a"/>
      <stop offset="1" stop-color="{BG_DEEP}"/>
    </radialGradient>
    <linearGradient id="title" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{GLOW}"/>
      <stop offset="0.55" stop-color="{GREEN}"/>
      <stop offset="1" stop-color="{GREEN_HI}"/>
    </linearGradient>
    <clipPath id="core"><circle cx="{cx}" cy="{cy}" r="70"/></clipPath>
    <clipPath id="typing">
      <rect x="{tx}" y="310" height="44" width="0">
        <animate attributeName="width" values="0;{type_w};{type_w};0" keyTimes="0;0.35;0.9;1" dur="6s" repeatCount="indefinite"/>
      </rect>
    </clipPath>
  </defs>
  <rect width="{W}" height="{H}" fill="url(#bg)"/>
  <rect width="{W}" height="{H}" fill="url(#grid)"/>
  <rect x="0" width="{W}" height="2" fill="{GREEN}" opacity="0.18">
    <animate attributeName="y" values="-2;{H}" dur="5s" repeatCount="indefinite"/>
  </rect>
  {sparks(range(40, W, 61), H + 10, -10, colors)}

  <circle cx="{cx}" cy="{cy}" r="150" fill="{GREEN}" opacity="0.12" filter="url(#softglow)" class="breathe"/>
  {ring_pulses(cx, cy, 150, 205, GREEN)}
  <circle cx="{cx}" cy="{cy}" r="150" fill="{DARK}" stroke="{EDGE}" stroke-width="6"/>
  <g class="spin" style="transform-origin: {cx}px {cy}px">{''.join(ticks)}</g>
  <g class="spin-rev" style="transform-origin: {cx}px {cy}px">{''.join(dots)}</g>
  <circle cx="{cx}" cy="{cy}" r="88" fill="{BG}" stroke="{GREEN}" stroke-width="3" filter="url(#glow)"/>
  <g class="breathe" filter="url(#glow)">
    <g clip-path="url(#core)">{hourglass(cx, cy, 70, GREEN)}</g>
  </g>

  <text x="{tx}" y="118" font-family="{MONO}" font-size="16" letter-spacing="3" fill="{GREEN}" fill-opacity="0.75">
    <tspan class="blink">●</tspan> SYSTEM ONLINE  //  DNA SAMPLES: {n:02d}
  </text>
  <text x="{tx - 4}" y="232" font-family="{SANS}" font-size="108" font-weight="900" letter-spacing="10"
        fill="url(#title)" filter="url(#glow)" class="flicker">OMNITRIX</text>
  <text x="{tx}" y="280" font-family="{MONO}" font-size="20" letter-spacing="6" fill="{GREEN_SOFT}">BEN 10 WATCH  ·  BUILT WITH FLUTTER</text>
  <g clip-path="url(#typing)">
    <text x="{tx}" y="342" font-family="{MONO}" font-size="28" font-weight="700" fill="{GLOW}"
          textLength="{type_w - 20}" lengthAdjust="spacingAndGlyphs">{typed}</text>
  </g>
  <rect y="318" width="14" height="30" fill="{GREEN}" class="blink">
    <animate attributeName="x" values="{tx};{tx + type_w - 14};{tx + type_w - 14};{tx}" keyTimes="0;0.35;0.9;1" dur="6s" repeatCount="indefinite"/>
  </rect>
  {bars}
"""
    return svg(W, H, body)


def roster(aliens):
    W = 1200
    cols, cw, ch, gap = 4, 270, 172, 20
    top, step = 104, ch + gap
    rows = math.ceil(len(aliens) / cols)
    H = top + rows * step + 14
    n = len(aliens)
    cycle = n * 0.4

    style = f"""
  .sel {{ opacity: 0; animation: sel {cycle:.2f}s ease-in-out infinite both; }}
  @keyframes sel {{ 0%,20%,100% {{ opacity: 0; }} 4%,12% {{ opacity: 1; }} }}"""

    cards = []
    for i, a in enumerate(aliens):
        r, c = divmod(i, cols)
        in_row = min(cols, n - r * cols)
        x0 = (W - (in_row * cw + (in_row - 1) * gap)) / 2 + c * (cw + gap)
        y0 = top + r * step
        col = a["color"]
        delay = f"{i * 0.4:.1f}s"

        stat_rows = []
        for j, (key, label) in enumerate(
            [("strength", "STR"), ("speed", "SPD"), ("intelligence", "INT"), ("durability", "DUR")]
        ):
            v = a["stats"][key]
            y = 110 + j * 15
            stat_rows.append(
                f"""
      <text x="20" y="{y + 6}" font-family="{MONO}" font-size="10" fill="{GREEN_SOFT}" fill-opacity="0.55">{label}</text>
      <rect x="54" y="{y}" width="170" height="6" rx="3" fill="{EDGE}"/>
      <rect x="54" y="{y}" width="{v * 17}" height="6" rx="3" fill="{col}">
        <animate attributeName="width" values="0;{v * 17}" dur="1.4s" begin="{0.2 + i * 0.08 + j * 0.05:.2f}s"
                 fill="freeze" calcMode="spline" keySplines="0.2 0.8 0.2 1"/>
      </rect>
      <text x="252" y="{y + 6}" text-anchor="end" font-family="{MONO}" font-size="10" fill="{col}">{v}</text>"""
            )

        cards.append(
            f"""
    <g transform="translate({x0:.0f},{y0})">
      <rect width="{cw}" height="{ch}" rx="16" fill="{PANEL}" stroke="{col}" stroke-opacity="0.3" stroke-width="1.5"/>
      <rect width="{cw}" height="{ch}" rx="16" fill="{col}" fill-opacity="0.08" stroke="{col}" stroke-width="2.5"
            filter="url(#glow)" class="sel" style="animation-delay: {delay}"/>
      <circle cx="48" cy="52" r="31" fill="{col}" fill-opacity="0.12" stroke="{col}" stroke-width="2"/>
      <g class="breathe" style="animation-delay: {i * 0.2:.1f}s">{hourglass(48, 52, 17, col, PANEL)}</g>
      <text x="92" y="46" font-family="{SANS}" font-size="22" font-weight="800" fill="{col}">{esc(a['name'])}</text>
      <text x="92" y="67" font-family="{MONO}" font-size="12" fill="{GLOW}" fill-opacity="0.8">{esc(a['species'])}</text>
      <text x="92" y="84" font-family="{MONO}" font-size="11" fill="{GREEN_SOFT}" fill-opacity="0.5">⌂ {esc(a['homeworld'])}</text>
      {''.join(stat_rows)}
    </g>"""
        )

    body = f"""
  <rect width="{W}" height="{H}" fill="{BG}"/>
  <rect width="{W}" height="{H}" fill="url(#grid)"/>
  <text x="{W / 2}" y="54" text-anchor="middle" font-family="{SANS}" font-size="30" font-weight="900"
        letter-spacing="8" fill="{GREEN}" filter="url(#glow)">ALIEN ROSTER</text>
  <text x="{W / 2}" y="80" text-anchor="middle" font-family="{MONO}" font-size="13" letter-spacing="4"
        fill="{GREEN_SOFT}" fill-opacity="0.6">SCANNING DNA  //  {n} SAMPLES LOADED</text>
  {''.join(cards)}
"""
    return svg(W, H, body, style)


def lifecycle(aliens):
    W, H = 1200, 300
    bw, bh, by = 220, 84, 88
    xs = [40, 340, 640, 940]
    centers = [x + bw / 2 for x in xs]
    mid = by + bh / 2
    low = 250
    cycle = 10.0
    alien_colors = ";".join(a["color"] for a in aliens) + ";" + aliens[0]["color"]

    nodes = [
        ("IDLE", "turn the dial", GREEN, (0, 6), (88, 100)),
        ("TRANSFORMING", "charge · flash", GLOW, (9, 21), None),
        ("TRANSFORMED", "15 s countdown", None, (24, 36), None),
        ("RECHARGING", "8 s · input locked", RED, (39, 85), None),
    ]

    style_parts = []
    node_svg = []
    for i, (title, sub, col, win, win2) in enumerate(nodes):
        a, b = win
        frames = f"0%,100% {{ opacity: 0; }} {a}%,{b}% {{ opacity: 1; }} {max(a - 2, 0)}% {{ opacity: 0; }} {b + 2}% {{ opacity: 0; }}"
        if win2:
            frames = f"0%,{win[1]}%,{win2[0]}%,100% {{ opacity: 1; }} {win[1] + 2}%,{win2[0] - 2}% {{ opacity: 0; }}"
        style_parts.append(f"  @keyframes lit{i} {{ {frames} }}")
        x = xs[i]
        stroke = col or aliens[0]["color"]
        anim = (
            f'<animate attributeName="stroke" values="{alien_colors}" dur="11s" repeatCount="indefinite"/>'
            f'<animate attributeName="fill" values="{alien_colors}" dur="11s" repeatCount="indefinite"/>'
            if col is None
            else ""
        )
        tcol = col or aliens[0]["color"]
        tanim = (
            f'<animate attributeName="fill" values="{alien_colors}" dur="11s" repeatCount="indefinite"/>'
            if col is None
            else ""
        )
        node_svg.append(
            f"""
  <g>
    <rect x="{x}" y="{by}" width="{bw}" height="{bh}" rx="14" fill="{PANEL}" stroke="{EDGE}" stroke-width="2"/>
    <rect x="{x}" y="{by}" width="{bw}" height="{bh}" rx="14" fill="{stroke}" fill-opacity="0.12" stroke="{stroke}"
          stroke-width="3" filter="url(#glow)" style="animation: lit{i} {cycle}s linear infinite">{anim}</rect>
    <text x="{x + bw / 2}" y="{by + 38}" text-anchor="middle" font-family="{MONO}" font-size="19" font-weight="700"
          letter-spacing="2" fill="{tcol}">{title}{tanim}</text>
    <text x="{x + bw / 2}" y="{by + 62}" text-anchor="middle" font-family="{MONO}" font-size="12"
          fill="{GREEN_SOFT}" fill-opacity="0.65">{sub}</text>
  </g>"""
        )

    labels = ["tap core", "1.4 s", "timeout"]
    links = []
    for i in range(3):
        x1, x2 = xs[i] + bw, xs[i + 1]
        links.append(
            f"""
  <line x1="{x1}" y1="{mid}" x2="{x2 - 8}" y2="{mid}" stroke="{EDGE}" stroke-width="3"/>
  <polygon points="{x2 - 10},{mid - 6} {x2},{mid} {x2 - 10},{mid + 6}" fill="{GREEN}" fill-opacity="0.6"/>
  <text x="{(x1 + x2) / 2}" y="{mid - 12}" text-anchor="middle" font-family="{MONO}" font-size="12"
        fill="{GREEN}" fill-opacity="0.8">{labels[i]}</text>"""
        )

    ret = (
        f"M{centers[3]},{by + bh} V{low - 14} Q{centers[3]},{low} {centers[3] - 14},{low} "
        f"H{centers[0] + 14} Q{centers[0]},{low} {centers[0]},{low - 14} V{by + bh + 8}"
    )
    revert = f"M{centers[2]},{by + bh} V{low}"
    track = f"M{centers[0]},{mid} H{centers[3]} V{low} H{centers[0]} Z"

    body = f"""
  <rect width="{W}" height="{H}" fill="{BG}"/>
  <rect width="{W}" height="{H}" fill="url(#grid)"/>
  <text x="40" y="50" font-family="{SANS}" font-size="22" font-weight="900" letter-spacing="6" fill="{GREEN}"
        filter="url(#glow)">WATCH LIFECYCLE</text>
  <text x="{W - 40}" y="50" text-anchor="end" font-family="{MONO}" font-size="12" letter-spacing="3"
        fill="{GREEN_SOFT}" fill-opacity="0.55">lib/models/watch_phase.dart</text>
  <path d="{ret}" fill="none" stroke="{EDGE}" stroke-width="3"/>
  <path d="{revert}" fill="none" stroke="{EDGE}" stroke-width="3" stroke-dasharray="6 6"/>
  <polygon points="{centers[0] - 6},{by + bh + 12} {centers[0]},{by + bh + 2} {centers[0] + 6},{by + bh + 12}" fill="{RED}" fill-opacity="0.7"/>
  <text x="{(centers[0] + centers[2]) / 2}" y="{low + 22}" text-anchor="middle" font-family="{MONO}" font-size="12"
        fill="{GREEN_SOFT}" fill-opacity="0.7">manual revert ↺</text>
  <text x="{(centers[2] + centers[3]) / 2}" y="{low + 22}" text-anchor="middle" font-family="{MONO}" font-size="12"
        fill="{RED}" fill-opacity="0.85">recharged · ready</text>
  {''.join(links)}
  <circle r="7" fill="{GLOW}" filter="url(#glow)">
    <animateMotion dur="{cycle}s" repeatCount="indefinite" path="{track}"/>
  </circle>
  {''.join(node_svg)}
"""
    return svg(W, H, body, "\n".join(style_parts))


def divider(aliens):
    W, H = 1200, 16
    stops = len(aliens) - 1
    grad = "".join(
        f'<stop offset="{i / stops:.3f}" stop-color="{a["color"]}"/>'
        for i, a in enumerate(aliens)
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<defs>
  <linearGradient id="spectrum" x1="0" x2="1">{grad}</linearGradient>
  <linearGradient id="beam" x1="0" x2="1">
    <stop offset="0" stop-color="{GLOW}" stop-opacity="0"/>
    <stop offset="0.5" stop-color="{GLOW}"/>
    <stop offset="1" stop-color="{GLOW}" stop-opacity="0"/>
  </linearGradient>
  <filter id="g" x="-10%" y="-200%" width="120%" height="500%"><feGaussianBlur stdDeviation="2.5"/></filter>
</defs>
<rect x="0" y="7" width="{W}" height="2" rx="1" fill="url(#spectrum)" opacity="0.45"/>
<rect x="-240" y="6" width="240" height="4" rx="2" fill="url(#beam)" filter="url(#g)">
  <animate attributeName="x" values="-240;{W}" dur="3.2s" repeatCount="indefinite"/>
</rect>
<rect x="-160" y="7" width="160" height="2" rx="1" fill="url(#beam)">
  <animate attributeName="x" values="-160;{W}" dur="3.2s" repeatCount="indefinite"/>
</rect>
</svg>
"""


def footer(aliens):
    W, H = 1200, 220
    cx, cy = W / 2, 86
    colors = [a["color"] for a in aliens]
    left = "".join(
        f'<rect x="{cx - 120 - (i + 1) * 34}" y="{cy - 2}" width="26" height="4" rx="2" fill="{c}" '
        f'style="animation: wave 2.2s ease-in-out {i * 0.15:.2f}s infinite both"/>'
        for i, c in enumerate(colors)
    )
    right = "".join(
        f'<rect x="{cx + 94 + i * 34}" y="{cy - 2}" width="26" height="4" rx="2" fill="{c}" '
        f'style="animation: wave 2.2s ease-in-out {i * 0.15:.2f}s infinite both"/>'
        for i, c in enumerate(colors)
    )
    body = f"""
  <defs>
    <radialGradient id="fbg" cx="50%" cy="40%" r="70%">
      <stop offset="0" stop-color="#0b2416"/><stop offset="1" stop-color="{BG_DEEP}"/>
    </radialGradient>
    <clipPath id="fcore"><circle cx="{cx}" cy="{cy}" r="40"/></clipPath>
  </defs>
  <rect width="{W}" height="{H}" fill="url(#fbg)"/>
  <rect width="{W}" height="{H}" fill="url(#grid)"/>
  {left}{right}
  {ring_pulses(cx, cy, 52, 120, GREEN, n=3, dur=2.4)}
  <circle cx="{cx}" cy="{cy}" r="52" fill="{BG}" stroke="{GREEN}" stroke-width="3" filter="url(#glow)"/>
  <g class="breathe" filter="url(#glow)"><g clip-path="url(#fcore)">{hourglass(cx, cy, 40, GREEN)}</g></g>
  <text x="{cx}" y="186" text-anchor="middle" font-family="{SANS}" font-size="34" font-weight="900"
        letter-spacing="10" fill="{GREEN}" filter="url(#glow)" class="flicker">IT'S HERO TIME</text>
"""
    return svg(W, H, body)


def main():
    aliens = load_aliens()
    if not aliens:
        raise SystemExit("No aliens found in lib/data/aliens.dart")
    OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in [
        ("hero.svg", hero),
        ("roster.svg", roster),
        ("lifecycle.svg", lifecycle),
        ("divider.svg", divider),
        ("footer.svg", footer),
    ]:
        (OUT / name).write_text(fn(aliens))
        print(f"wrote docs/readme/{name}")


if __name__ == "__main__":
    main()
