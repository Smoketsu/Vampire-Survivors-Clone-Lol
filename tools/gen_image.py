"""gen_image.py: generate one art-pass source image with the OpenAI image API and log its cost.

Usage (from the repo root):
    python3 tools/gen_image.py <prompt file> <output png> [--ref IMG ...] [--key LABEL]
        [--model M] [--quality low|medium|high] [--size 1024x1024]
    python3 tools/gen_image.py --ledger          # print the running totals

The art pass (docs/art/ART_BIBLE.md) normally has the owner paste a prompt into ChatGPT.
This tool does the same call through the API so the lead can generate, convert
(tools/prepare_sprite.py), check (tools/art_check.py) and retry without a round trip.
With --ref images (the approved anchors) it calls /v1/images/edits so the references
steer the style; without, /v1/images/generations. The background is requested
transparent and the result saved as PNG.

Authentication: the API key is NOT read here. The cloud environment stores it as a
network secret and its egress proxy adds it to requests to api.openai.com, so the
script never sees or prints it. Outside that environment, set OPENAI_API_KEY and it is
sent as a bearer token.

Cost tracking (owner request: report usage and the bill): every call appends a row to
docs/art/generation_ledger.csv with the exact token counts the API returns (text input,
image input, image output) and a cost ESTIMATE from the per-token rates below. The rates
come from OpenAI's published pricing for the gpt-image-2.5 models as of Oct 2026 (the
official page was not reachable from the cloud environment; the figures were taken from
search results quoting it), so the OpenAI usage dashboard is the source of truth for the
actual bill.
"""

import argparse
import base64
import csv
import datetime as dt
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # Repo root.
# Running cost ledger, one row per API call (committed with the art).
LEDGER = ROOT / "docs" / "art" / "generation_ledger.csv"
# API base URL.
API = "https://api.openai.com/v1/images"
# Default model: gpt-image-2.5-flare (same published rates as -sunburst).
DEFAULT_MODEL = "gpt-image-2.5-flare"
# Default quality (low / medium / high): medium keeps the cost near $0.05 per 1024 image.
DEFAULT_QUALITY = "medium"
# Default output size (px): square, as the art bible asks.
DEFAULT_SIZE = "1024x1024"
# Request timeout (s): image generation can take a minute or two.
TIMEOUT_S = 300
# Estimated USD per 1M tokens, by model prefix: (text input, image input, image output).
RATES = {
    "gpt-image-2.5": (5.0, 8.0, 30.0),
}
# Ledger columns, in order.
FIELDS = ["utc", "key", "model", "quality", "size", "refs", "text_in", "image_in", "image_out", "usd_est", "file"]


def rates_for(model: str) -> tuple:
    """Per-1M-token USD rates (text in, image in, image out) for `model`, or None if unknown."""
    for prefix, r in RATES.items():
        if model.startswith(prefix):
            return r
    return None


def post_json(url: str, body: dict) -> dict:
    """POSTs `body` as JSON and returns the decoded JSON response."""
    req = urllib.request.Request(url, data=json.dumps(body).encode(), method="POST",
                                 headers=headers({"Content-Type": "application/json"}))
    with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
        return json.loads(resp.read())


def post_multipart(url: str, fields: dict, files: list) -> dict:
    """POSTs multipart form data (`fields` as text, `files` as (name, path)) and returns JSON."""
    boundary = uuid.uuid4().hex  # Multipart boundary.
    parts = []  # Encoded body parts.
    for k, v in fields.items():
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
    for name, path in files:
        mime = mimetypes.guess_type(path)[0] or "image/png"  # Reference image type.
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"; filename="{Path(path).name}"\r\n'
                     f"Content-Type: {mime}\r\n\r\n".encode() + Path(path).read_bytes() + b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode())
    req = urllib.request.Request(url, data=b"".join(parts), method="POST",
                                 headers=headers({"Content-Type": f"multipart/form-data; boundary={boundary}"}))
    with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
        return json.loads(resp.read())


def headers(extra: dict) -> dict:
    """Request headers; adds the bearer token only when OPENAI_API_KEY is set (outside the cloud proxy)."""
    h = dict(extra)
    key = os.environ.get("OPENAI_API_KEY", "")  # Never printed or logged.
    if key:
        h["Authorization"] = f"Bearer {key}"
    return h


def log_usage(row: dict) -> None:
    """Appends one row to the ledger (creating it with a header first)."""
    new = not LEDGER.exists()
    LEDGER.parent.mkdir(parents=True, exist_ok=True)
    with LEDGER.open("a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        if new:
            w.writeheader()
        w.writerow(row)


def ledger_totals() -> tuple:
    """(calls, total estimated USD) over the whole ledger."""
    if not LEDGER.exists():
        return 0, 0.0
    with LEDGER.open() as f:
        rows = list(csv.DictReader(f))
    return len(rows), sum(float(r["usd_est"] or 0) for r in rows)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("prompt", nargs="?", help="text file holding the prompt")
    ap.add_argument("out", nargs="?", help="output PNG path")
    ap.add_argument("--ref", action="append", default=[], help="reference image (repeatable): the approved anchors")
    ap.add_argument("--key", default="", help="label for the ledger (the sprite key)")
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--quality", default=DEFAULT_QUALITY)
    ap.add_argument("--size", default=DEFAULT_SIZE)
    ap.add_argument("--ledger", action="store_true", help="print the ledger totals and exit")
    args = ap.parse_args()
    if args.ledger:
        n, usd = ledger_totals()
        print(f"{n} image(s), estimated ${usd:.2f}")
        return
    if not args.prompt or not args.out:
        sys.exit("need a prompt file and an output path")
    prompt = Path(args.prompt).read_text().strip()  # Prompt text.
    common = {"model": args.model, "prompt": prompt, "quality": args.quality, "size": args.size,
              "background": "transparent", "output_format": "png", "n": 1}
    try:
        if args.ref:
            data = post_multipart(f"{API}/edits", {k: str(v) for k, v in common.items()},
                                  [("image[]", r) for r in args.ref])
        else:
            data = post_json(f"{API}/generations", common)
    except urllib.error.HTTPError as e:
        # The API explains the failure (no credits, rate limit, bad parameter); nothing is billed or logged.
        try:
            err = json.loads(e.read()).get("error", {})  # API error object.
        except ValueError:
            err = {}
        sys.exit(f"API error {e.code}: {err.get('code') or err.get('type') or ''} {err.get('message', e.reason)}")
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_bytes(base64.b64decode(data["data"][0]["b64_json"]))
    usage = data.get("usage", {})  # Token counts reported by the API.
    det = usage.get("input_tokens_details", {})  # Input split into text and image tokens.
    text_in = int(det.get("text_tokens", usage.get("input_tokens", 0)))  # Prompt tokens.
    image_in = int(det.get("image_tokens", 0))  # Reference-image tokens.
    image_out = int(usage.get("output_tokens", 0))  # Generated-image tokens.
    r = rates_for(args.model)  # Per-1M rates, or None.
    usd = (text_in * r[0] + image_in * r[1] + image_out * r[2]) / 1e6 if r else 0.0  # Estimated cost.
    log_usage({"utc": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M"), "key": args.key,
               "model": args.model, "quality": args.quality, "size": args.size, "refs": len(args.ref),
               "text_in": text_in, "image_in": image_in, "image_out": image_out,
               "usd_est": f"{usd:.4f}", "file": Path(args.out).name})
    n, total = ledger_totals()
    print(f"{args.out}: {text_in} text + {image_in} image in, {image_out} out -> ~${usd:.3f}"
          f"{'' if r else ' (no rate for this model)'}; ledger {n} image(s), ~${total:.2f}")


if __name__ == "__main__":
    main()
