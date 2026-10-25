#!/usr/bin/env python3
"""Generate the Icon Composer layer SVGs (1024x1024, 824px body offset by 100).

Usage: scripts/generate-icon-layers.py [output-dir]
Default output: design/icon/src. See icon.md for the layer spec.
"""
import math
import sys
from pathlib import Path

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "design/icon/src")
C = 512  # canvas center
OFF = 100  # body offset in icon.md's 1024 frame
# Icon Composer's canvas is the whole icon shape (Xcode adds the macOS margin),
# so the 824px body is scaled up to fill the 1024 canvas.
K = 1024 / 824


def svg(body, defs=""):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
        'viewBox="0 0 1024 1024">\n'
        + (f"<defs>\n{defs}</defs>\n" if defs else "")
        + f'<g transform="translate({C} {C}) scale({K:.6f}) translate({-C} {-C})">\n'
        + body
        + "</g>\n</svg>\n"
    )


def raw(body):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
        'viewBox="0 0 1024 1024">\n' + body + "</svg>\n"
    )


def write(name, content):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_text(content)


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


# 01 brushed hairlines (the gradient itself is the .icon background fill)
def hairlines(white, black):
    rows = []
    for y in range(0, 1024, 3):
        rows.append(f'<rect x="0" y="{y}" width="1024" height="1" fill="#fff" fill-opacity="{white}"/>')
        rows.append(f'<rect x="0" y="{y + 1.5}" width="1024" height="1" fill="#000" fill-opacity="{black}"/>')
    return "\n".join(rows) + "\n"


# 02 grid
def grid(color, opacity):
    lines = []
    for k in range(0, 9):
        p = OFF + 103 * k
        lines.append(f'<rect x="{p - 0.5}" y="{OFF}" width="1" height="824"/>')
        lines.append(f'<rect x="{OFF}" y="{p - 0.5}" width="824" height="1"/>')
    return f'<g fill="{color}" fill-opacity="{opacity}">\n' + "\n".join(lines) + "\n</g>\n"


# 03 bezel: conic sweep approximated with thin overlapping wedges
def conic(stops, r, start_deg, step=2):
    cols = [hex_rgb(s) for s in stops]
    n = len(cols) - 1
    out = []
    for a in range(0, 360, step):
        t = a / 360 * n
        i = min(int(t), n - 1)
        f = t - i
        rgb = tuple(round(cols[i][j] + (cols[i + 1][j] - cols[i][j]) * f) for j in range(3))
        a0 = math.radians(start_deg + a - 0.4)
        a1 = math.radians(start_deg + a + step + 0.4)
        p = lambda ang: (C + r * math.sin(ang), C - r * math.cos(ang))
        x0, y0 = p(a0)
        x1, y1 = p(a1)
        out.append(
            f'<path fill="#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}" '
            f'd="M{C} {C}L{x0:.2f} {y0:.2f}A{r} {r} 0 0 1 {x1:.2f} {y1:.2f}Z"/>'
        )
    return "\n".join(out) + "\n"


def bezel(stops, rim):
    return svg(
        conic(stops, 286, 20)
        + f'<circle cx="{C}" cy="{C}" r="285.5" fill="none" stroke="#000" stroke-opacity="{rim}"/>\n'
    )


# 04 lens
def lens(grad, rim, rim_color):
    stops = "\n".join(
        f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in grad
    )
    defs = (
        f'<radialGradient id="l" gradientUnits="userSpaceOnUse" cx="{OFF + 0.32 * 824:.1f}" '
        f'cy="{OFF + 0.26 * 824:.1f}" r="560">\n{stops}\n</radialGradient>\n'
    )
    return svg(
        f'<circle cx="{C}" cy="{C}" r="260" fill="url(#l)"/>\n'
        f'<circle cx="{C}" cy="{C}" r="259.25" fill="none" stroke="{rim_color}" '
        f'stroke-opacity="{rim}" stroke-width="1.5"/>\n',
        defs,
    )


# 05 marks (CoreSVG ignores stroke-opacity inherited from a group, so set it per element)
def marks(color, minor, major, cross, merid):
    def line(x1, y1, x2, y2, w, op):
        return (f'<line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" '
                f'stroke="{color}" stroke-opacity="{op}" stroke-width="{w}"/>')

    def ellipse(rx, ry):
        return (f'<ellipse cx="{C}" cy="{C}" rx="{rx}" ry="{ry}" fill="none" '
                f'stroke="{color}" stroke-opacity="{merid}" stroke-width="1.5"/>')

    out = []
    for i in range(60):
        a = math.radians(i * 6)
        r0, r1, w, op = (246, 222, 3, major) if i % 5 == 0 else (246, 234, 1.5, minor)
        out.append(line(C + r0 * math.sin(a), C - r0 * math.cos(a),
                        C + r1 * math.sin(a), C - r1 * math.cos(a), w, op))
    out.append(line(C - 252, C, C + 252, C, 1.5, cross))
    out.append(line(C, C - 252, C, C + 252, 1.5, cross))
    out += [ellipse(200, 70), ellipse(70, 200)]
    return svg("\n".join(out) + "\n")


# 06 command glyph: icon.md's stroked geometry (26 wide, loop r 48), scaled 0.84
# One continuous closed path (bars and loops join tangentially), so there are
# no seams at the bar/loop junctions.
CMD_PATH = (
    "M -55,103 V -103 A 48 48 0 1 0 -103,-55 H 103 A 48 48 0 1 0 55,-103 "
    "V 103 A 48 48 0 1 0 103,55 H -103 A 48 48 0 1 0 -55,103 Z"
)


def command(color):
    return svg(
        f'<g transform="translate({C} {C}) scale(0.84)">\n'
        f'<path fill="none" stroke="{color}" stroke-width="26" stroke-linecap="butt" '
        f'stroke-linejoin="round" d="{CMD_PATH}"/>\n</g>\n'
    )


# 07 lamp
def lamp(ring, glow_opacity, glow_r):
    cx, cy = OFF + 505, OFF + 119
    defs = (
        f'<radialGradient id="g" gradientUnits="userSpaceOnUse" cx="{cx - 4}" cy="{cy - 5}" r="22">\n'
        '<stop offset="0" stop-color="#FF6B5E"/>\n<stop offset="0.55" stop-color="#E3241B"/>\n'
        '<stop offset="1" stop-color="#A9140C"/>\n</radialGradient>\n'
    )
    glow = "".join(
        f'<circle cx="{cx}" cy="{cy}" r="{17 + glow_r * (i + 1) / 8:.2f}" fill="#E3241B" '
        f'fill-opacity="{glow_opacity / 8 * 0.55:.3f}"/>\n'
        for i in range(8)
    )
    return svg(
        glow
        + f'<circle cx="{cx}" cy="{cy}" r="17" fill="url(#g)"/>\n'
        + f'<circle cx="{cx}" cy="{cy}" r="15.5" fill="none" stroke="#000" stroke-opacity="{ring}" stroke-width="3"/>\n',
        defs,
    )


write("01-background-light.svg", raw(hairlines(0.07, 0.025)))
write("01-background-dark.svg", raw(hairlines(0.03, 0.06)))
write("02-grid-light.svg", svg(grid("#000", 0.07)))
write("02-grid-dark.svg", svg(grid("#fff", 0.06)))
write("03-bezel-light.svg", bezel(["#F7F8F9", "#9AA0A8", "#EEF0F2", "#858B93", "#F4F5F6", "#A2A8AF", "#F7F8F9"], 0.18))
write("03-bezel-dark.svg", bezel(["#B7BCC3", "#4A4F57", "#A3A8B0", "#3A3E45", "#B1B6BD", "#50555D", "#B7BCC3"], 0.40))
write("04-lens-light.svg", lens([(0, "#fff", 0.70), (0.38, "#fff", 0.22), (0.70, "#E1E6EC", 0.35), (1, "#fff", 0.50)], 0.25, "#000"))
write("04-lens-dark.svg", lens([(0, "#fff", 0.22), (0.40, "#3C424C", 0.40), (1, "#101216", 0.75)], 0.25, "#fff"))
write("05-marks-light.svg", marks("#111111", 0.45, 0.80, 0.30, 0.18))
write("05-marks-dark.svg", marks("#F2F3F5", 0.40, 0.80, 0.25, 0.15))
write("06-command-light.svg", command("#111111"))
write("06-command-dark.svg", command("#F2F3F5"))
write("07-lamp-light.svg", lamp(0.35, 0.60, 14))
write("07-lamp-dark.svg", lamp(0.55, 0.75, 18))
print(f"wrote layers to {OUT}")
