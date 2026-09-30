#!/usr/bin/env python3
"""Screenshot a .drawio file using the REAL mxGraph rendering engine, headlessly,
with zero network access -- no drawio CLI, no app.diagrams.net, no guessing whether
a fix actually works before asking the user to test it by hand.

How: the VS Code extension `hediet.vscode-drawio` ships a full offline copy of the
draw.io webapp (including `viewer.min.js`, the same core renderer used by the real
editor) under its extension folder. This script finds that bundle, feeds it your
.drawio file via the documented `data-mxgraph` embed attribute
(https://www.drawio.com/doc/faq/embed-mode), and drives headless Chromium to
screenshot it.

Requires: the VS Code extension installed locally (or point --viewer-js at any copy
of viewer.min.js / viewer-static.min.js you have), and a `chromium`/`google-chrome`
binary on PATH.

Note: if chromium is a snap package, its filesystem sandbox generally has NO
visibility into system /tmp at all (not just other apps' subdirectories under
it) -- confirmed empirically: `file:///tmp/tmpXXXX/render.html` silently resolves
to Chromium's own ERR_FILE_NOT_FOUND page (which screenshots as a boring, plausible
-looking dark rectangle -- always check the *content* of a first screenshot, not
just that a file got written with a nonzero size). This script already works
around it by staging the temp HTML/JS under a directory inside $HOME instead of
system /tmp. If your chromium is NOT a snap package, this workaround is harmless
either way.

Usage:
    python3 render_check.py path/to/diagram.drawio -o preview.png
    python3 render_check.py path/to/diagram.drawio -o preview.png --width 1600 --height 1300
"""
import argparse
import glob
import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile


def find_viewer_js():
    candidates = glob.glob(
        os.path.expanduser("~/.vscode*/extensions/hediet.vscode-drawio-*/drawio/src/main/webapp/js/viewer.min.js")
    )
    return candidates[0] if candidates else None


def find_chromium():
    for name in ("chromium", "chromium-browser", "google-chrome", "google-chrome-stable"):
        path = shutil.which(name)
        if path:
            return path
    return None


def extract_mxgraph_model(drawio_text):
    m = re.search(r"(<mxGraphModel.*?</mxGraphModel>)", drawio_text, re.S)
    if not m:
        raise ValueError("no <mxGraphModel>...</mxGraphModel> found in file")
    return m.group(1)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("drawio_file")
    ap.add_argument("-o", "--output", default="preview.png")
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--height", type=int, default=1300)
    ap.add_argument("--viewer-js", help="path to viewer.min.js if not auto-detected")
    ap.add_argument("--bg", default="#333", help="page background behind the diagram canvas")
    args = ap.parse_args()

    viewer_js = args.viewer_js or find_viewer_js()
    if not viewer_js or not os.path.isfile(viewer_js):
        print(
            "ERROR: couldn't find viewer.min.js. Install the 'hediet.vscode-drawio' VS Code "
            "extension, or pass --viewer-js /path/to/viewer.min.js (or viewer-static.min.js).",
            file=sys.stderr,
        )
        sys.exit(1)

    chromium = find_chromium()
    if not chromium:
        print("ERROR: no chromium/google-chrome binary found on PATH.", file=sys.stderr)
        sys.exit(1)

    drawio_text = open(args.drawio_file, encoding="utf-8").read()
    xml = extract_mxgraph_model(drawio_text)

    # Snap-packaged chromium has no visibility into system /tmp at all (confirmed
    # empirically -- python's default tempfile dir there silently fails to load,
    # rendering Chromium's own ERR_FILE_NOT_FOUND page instead of erroring loudly).
    # Stage the temp HTML/JS under $HOME instead, which snap chromium can read.
    # A visible, non-dotfile directory -- some snap chromium builds only portal-allow
    # plain $HOME subpaths, not hidden dirs like ~/.cache (confirmed: ~/.cache gave
    # "Access to the file was denied" even though the path itself resolved fine).
    home_tmp_root = os.path.join(os.path.expanduser("~"), "render_check_tmp")
    os.makedirs(home_tmp_root, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=home_tmp_root) as tmp:
        shutil.copy(viewer_js, os.path.join(tmp, "viewer.min.js"))
        config = {"xml": xml, "toolbar": "zoom", "resize": True}
        attr = html.escape(json.dumps(config), quote=True)
        page = f'''<!DOCTYPE html><html><head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:{args.bg};">
<div class="mxgraph" style="max-width:100%;" data-mxgraph="{attr}"></div>
<script src="viewer.min.js"></script>
</body></html>'''
        html_path = os.path.join(tmp, "render.html")
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(page)

        out_path = os.path.abspath(args.output)
        cmd = [
            chromium, "--headless=new", "--disable-gpu", "--no-sandbox",
            "--virtual-time-budget=4000",
            f"--window-size={args.width},{args.height}",
            f"--screenshot={out_path}",
            f"file://{html_path}",
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if not os.path.isfile(out_path):
            print("ERROR: screenshot was not produced.", file=sys.stderr)
            print(result.stderr[-2000:], file=sys.stderr)
            sys.exit(1)
        print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
