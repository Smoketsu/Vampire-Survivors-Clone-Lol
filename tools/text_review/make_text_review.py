#!/usr/bin/env python3
"""Build the text review page: docs/text_review/strings.json -> docs/text_review/text_review.html.

Usage (from the repo root):  python3 tools/text_review/make_text_review.py

The page is adapted from the art review (docs/act3/tools/art_review_template.html): the same look,
the same db wiring (claude.use("db") / claude.use("user"), one onSnapshot on one collection, a
{verdict, note, at, by} document per entry) and a notice where the runtime cannot save. There are no
images; each entry is a compact row with OK / Change buttons and a note. Rows render lazily when a
category is opened, so thousands of entries stay light. Marks are saved in COLLECTION; a later round
bumps the name (text_review_r2) and matches entries by their stable ids.
"""
from __future__ import annotations

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
STRINGS = os.path.join(ROOT, "docs", "text_review", "strings.json")
TEMPLATE = os.path.join(HERE, "text_review_template.html")
OUT = os.path.join(ROOT, "docs", "text_review", "text_review.html")
COLLECTION = "text_review_r1"  # The db collection this round's marks are saved in.
MAX_BYTES = 3 * 1024 * 1024  # The page must stay under this size.


def main() -> int:
    entries = json.load(open(STRINGS, encoding="utf-8"))
    cats: list[str] = []
    rows = []
    for e in entries:
        if e["category"] not in cats:
            cats.append(e["category"])
        others = None
        if e.get("contexts") and len(e["contexts"]) > 1:
            # The first context is the entry's own; list the rest.
            others = [[c["context"], c["file"], c["line"]] for c in e["contexts"][1:]]
        rows.append([e["id"], cats.index(e["category"]), e["group"], e["context"], e["file"], e["line"],
                     e["text"], e["kind"], others])
    data = {"collection": COLLECTION, "cats": cats, "rows": rows}
    # "</" and the line separators must not end the script block early.
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    blob = blob.replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    html = open(TEMPLATE, encoding="utf-8").read()
    html = html.replace("{{TOTAL}}", str(len(rows))).replace("{{DATA}}", blob)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(html)
    size = os.path.getsize(OUT)
    print(f"{len(rows)} entries, {len(cats)} categories, {size / 1024:.0f} KB -> {os.path.relpath(OUT, ROOT)}")
    if size > MAX_BYTES:
        print("WARNING: the page is over 3 MB", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
