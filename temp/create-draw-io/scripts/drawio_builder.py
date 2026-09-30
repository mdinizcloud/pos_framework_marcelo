#!/usr/bin/env python3
"""Reusable builder for hand-authored .drawio (mxGraph) files with real icon assets
and a dark theme that actually survives opening in the real app.

Import this module and call the helpers to accumulate `cells`, then call
`render_mxfile()` to get the final XML string. See SKILL.md for the three gotchas
this module exists to work around (icon encoding, PNG icons, dark background).

Usage sketch:

    import drawio_builder as db

    db.rect_bg(0, 0, 1500, 1200, "#0d1117")
    db.group(40, 240, 340, 320, "My group", fill="#161b22", stroke="#30363d")
    db.icon("icons/aks.svg", cx=115, cy=305, size=48, label1="aks", label2="v1.30")
    db.edge(75, 175, 75, 238, "#3fb950", label="deploy")

    xml = db.render_mxfile(title="My Diagram", background="#0d1117")
    open("out.drawio", "w").write(xml)
"""
import base64
import os
import re
import struct
import urllib.parse

cells = []
_cell_id = 0
_icon_cache = {}

MIME = {".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg"}


def _nid():
    global _cell_id
    _cell_id += 1
    return f"c{_cell_id}"


def reset():
    """Call between building multiple independent diagrams in one process."""
    global cells, _cell_id, _icon_cache
    cells, _cell_id, _icon_cache = [], 0, {}


def _png_size(raw):
    return struct.unpack(">II", raw[16:24])


def _svg_aspect(raw_text):
    m = re.search(r'viewBox="[\d.\-]+\s+[\d.\-]+\s+([\d.]+)\s+([\d.]+)"', raw_text[:2000])
    if m:
        w, h = float(m.group(1)), float(m.group(2))
        return w / h if h else 1.0
    return 1.0


def data_uri(path):
    """Build a data: URI safe to drop into an mxGraph `style="...;image=...;"` value.

    Percent-encodes the whole payload (safe="") instead of base64 -- see SKILL.md
    "Gotcha 1". PNG/raster files get wrapped in a tiny SVG <image> first -- see
    "Gotcha 2" -- because mxGraph's image shape refuses non-base64 raster data URIs.
    Returns (uri, aspect_ratio). Cached by path.
    """
    if path in _icon_cache:
        return _icon_cache[path]
    ext = os.path.splitext(path)[1].lower()
    with open(path, "rb") as f:
        raw = f.read()
    if ext == ".svg":
        text = raw.decode("utf-8")
        ar = _svg_aspect(text)
        enc = urllib.parse.quote(raw, safe="")
        uri = f"data:{MIME[ext]},{enc}"
    elif ext in (".png", ".jpg", ".jpeg"):
        if ext == ".png":
            w, h = _png_size(raw)
        else:
            w, h = 1, 1  # aspect unknown for jpg without a decoder; caller can override
        ar = w / h if h else 1.0
        b64 = base64.b64encode(raw).decode()
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}"><image width="{w}" height="{h}" href="data:{MIME[ext]};base64,{b64}"/></svg>'
        enc = urllib.parse.quote(svg, safe="")
        uri = f"data:image/svg+xml,{enc}"
    else:
        raise ValueError(f"unsupported icon type: {path}")
    _icon_cache[path] = (uri, ar)
    return uri, ar


def rect_bg(x, y, w, h, fill, locked=True):
    """Full-canvas (or any) filled rectangle. Use once at (0,0,pageWidth,pageHeight)
    as a belt-and-suspenders dark background alongside mxGraphModel background= --
    cheap insurance if a given renderer ignores the model-level attribute."""
    cid = _nid()
    lock = "movable=0;resizable=0;editable=0;locked=1;" if locked else ""
    cells.append(
        f'<mxCell id="{cid}" style="rounded=0;fillColor={fill};strokeColor=none;{lock}" '
        f'vertex="1" parent="1"><mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>'
    )
    return cid


def group(x, y, w, h, title, fill="#161b22", stroke="#30363d", font_color="#e6edf3"):
    cid = _nid()
    cells.append(
        f'<mxCell id="{cid}" value="{title}" style="rounded=1;arcSize=6;fillColor={fill};'
        f'strokeColor={stroke};strokeWidth=1.3;verticalAlign=top;align=center;fontColor={font_color};'
        f'fontSize=15;fontStyle=1;spacingTop=8;" vertex="1" parent="1">'
        f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>'
    )
    return cid


def icon(path, cx, cy, size, label1=None, label2=None, label_w=120, font_size=11,
         font_color="#e6edf3", sub_color="#8b949e", sub_size=9):
    """Place an icon centered at (cx, cy), aspect-ratio preserved within `size`, with
    an optional one- or two-line label centered below it."""
    uri, ar = data_uri(path)
    if ar >= 1:
        w, h = size, size / ar
    else:
        w, h = size * ar, size
    iid = _nid()
    cells.append(
        f'<mxCell id="{iid}" style="shape=image;image={uri};imageAspect=1;" vertex="1" parent="1">'
        f'<mxGeometry x="{cx - w/2:.1f}" y="{cy - h/2:.1f}" width="{w:.1f}" height="{h:.1f}" as="geometry"/></mxCell>'
    )
    if label1:
        text_val = label1
        if label2:
            text_val = f"{label1}&lt;br&gt;&lt;font color='{sub_color}' style='font-size:{sub_size}px'&gt;{label2}&lt;/font&gt;"
        lid = _nid()
        ly = cy + size / 2 + 4
        cells.append(
            f'<mxCell id="{lid}" value="{text_val}" style="text;html=1;whiteSpace=wrap;align=center;'
            f'verticalAlign=top;fontColor={font_color};fontSize={font_size};fontStyle=1;" vertex="1" parent="1">'
            f'<mxGeometry x="{cx - label_w/2:.1f}" y="{ly:.1f}" width="{label_w}" height="34" as="geometry"/></mxCell>'
        )
    return iid


def rect(x, y, w, h, fill="none", stroke="#333c48", stroke_width=0.7, dashed=False,
         opacity=1, rounded=True, arc=3):
    """Generic small box (subnet cards, "not created" ghost placeholders, etc) --
    a lighter-weight sibling of group() with no title bar and dashed/opacity support."""
    rid = _nid()
    dash = "dashed=1;dashPattern=4 3;" if dashed else ""
    rnd = f"rounded=1;arcSize={arc};" if rounded else "rounded=0;"
    cells.append(
        f'<mxCell id="{rid}" style="{rnd}fillColor={fill};strokeColor={stroke};'
        f'strokeWidth={stroke_width};opacity={opacity};{dash}" vertex="1" parent="1">'
        f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>'
    )
    return rid


def dot(cx, cy, r, color, label=None, font_color="#e6edf3"):
    """Fallback node shape for anything without an official icon -- a plain colored
    circle, same visual language as the rest of the diagram."""
    did = _nid()
    cells.append(
        f'<mxCell id="{did}" style="ellipse;fillColor={color};strokeColor=none;" vertex="1" parent="1">'
        f'<mxGeometry x="{cx-r}" y="{cy-r}" width="{2*r}" height="{2*r}" as="geometry"/></mxCell>'
    )
    if label:
        lid = _nid()
        cells.append(
            f'<mxCell id="{lid}" value="{label}" style="text;html=1;whiteSpace=wrap;align=center;'
            f'verticalAlign=top;fontColor={font_color};fontSize=11;fontStyle=1;" vertex="1" parent="1">'
            f'<mxGeometry x="{cx-65}" y="{cy+r+4}" width="130" height="30" as="geometry"/></mxCell>'
        )
    return did


def edge(x1, y1, x2, y2, color, label=None, control=None, bg="#0d1117"):
    """control=(cx,cy) draws a curved polyline through that waypoint (approximates a
    single-control-point quadratic bezier). Omit for a straight line."""
    eid = _nid()
    style = (
        f"endArrow=block;html=1;strokeColor={color};strokeWidth=1.8;rounded=1;"
        f"curved={1 if control else 0};fontColor={color};labelBackgroundColor={bg};"
    )
    val = f' value="{label}"' if label else ""
    points = f'<Array as="points"><mxPoint x="{control[0]}" y="{control[1]}"/></Array>' if control else ""
    cells.append(
        f'<mxCell id="{eid}"{val} style="{style}" edge="1" parent="1">'
        f'<mxGeometry relative="1" as="geometry">'
        f'<mxPoint x="{x1}" y="{y1}" as="sourcePoint"/><mxPoint x="{x2}" y="{y2}" as="targetPoint"/>'
        f"{points}</mxGeometry></mxCell>"
    )
    return eid


def text(x, y, s, size=12, color="#e6edf3", bold=False, w=400, h=18, align="left",
         font_family=None, opacity=1, anchor="start", bg=None):
    """anchor mirrors SVG text-anchor ('start'/'middle'/'end') and repositions the
    box left edge so `x` keeps meaning "the SVG anchor point" instead of "box left"."""
    tid = _nid()
    s = s.replace('"', "&quot;")
    if anchor == "middle":
        align = "center"
        x = x - w / 2
    elif anchor == "end":
        align = "right"
        x = x - w
    fs = "fontStyle=1;" if bold else ""
    ff = f"fontFamily={font_family};" if font_family else ""
    op = f"opacity={opacity};" if opacity != 1 else ""
    bgc = f"labelBackgroundColor={bg};" if bg else ""
    cells.append(
        f'<mxCell id="{tid}" value="{s}" style="text;html=1;align={align};verticalAlign=middle;'
        f'fontColor={color};fontSize={size};{fs}{ff}{op}{bgc}" vertex="1" parent="1">'
        f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>'
    )


def render_mxfile(page_width=1500, page_height=1200, background="#0d1117", diagram_name="Diagram"):
    """Assemble everything drawn so far into a full .drawio file string.

    background= + adaptiveColors="none" together are what make a dark theme survive
    the real editor -- see SKILL.md "Gotcha 3". Dropping either one silently reverts
    to a white canvas even though the XML still "looks" right.
    """
    body = "\n".join(cells)
    return f'''<mxfile host="app.diagrams.net" version="24.0.0">
  <diagram name="{diagram_name}" id="diagram-1">
    <mxGraphModel dx="{page_width}" dy="{page_height}" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="{page_width}" pageHeight="{page_height}" background="{background}" adaptiveColors="none" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
{body}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
'''
