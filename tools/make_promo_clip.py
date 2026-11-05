#!/usr/bin/env python3
"""make_promo_clip.py: records and cuts a vertical (9:16) promo clip of Necropathy for TikTok / Shorts.

What it does (all from one JSON spec, default tools/promo_clip_spec.json):
  1. CAPTURE   For every distinct (stage, seed, extra args) in the spec it runs the game ONCE under xvfb with the
               autotest bot (`--autotest --policy=army`), fast-forwarded, and Godot's Movie Maker
               (`--write-movie`, real GL renderer: llvmpipe, not --headless) records only the listed spans at real
               speed (autotest option `--movie-spans=T:N,...`, scripts/core/movie_spans.gd). The recording (lossless PNG frames +
               a WAV of the game's own synthesized music and sound; only the span frames are kept) is cached in <work>/<stage>_<seed>_<hash>/ (f%08d.png frames, f.wav) so a re-cut
               does not re-record; pass --force to record again.
  2. CUT       Each shot's frames and audio are cut out of its AVI, upscaled by an integer factor with
               nearest-neighbour (the pixel art stays crisp), darkened if asked, and given its burned-in text.
               Text is drawn with the game's own fonts (Jacquard 24 / Jersey 10 from assets/fonts) at native size,
               no anti-aliasing, outlined, then enlarged by an integer (so it matches the pixel art), with a soft
               shadow, in the game's colours (UiTheme: gold, soul-teal, violet).
  3. ASSEMBLE  Concatenates the shots (hard cuts; the intermediates are lossless FFV1 RGB), fades the audio at
               every cut and at both ends, measures and normalises loudness (two-pass loudnorm, -14 LUFS
               integrated, -1.5 dBTP) and encodes H.264 high (yuv420p as TikTok requires, -tune animation,
               CRF 14, keyint 60, nearest-neighbour everywhere) + AAC, 30 fps, faststart. Also writes a 6-frame contact sheet (storyboard.png).
Nothing is committed from here (videos are build output).

Usage:
    python3 tools/make_promo_clip.py [--spec tools/promo_clip_spec.json] [--out DIR] [--work DIR] [--force]
                                     [--only-capture] [--jobs 3] [--godot PATH]
Needs: python3 with Pillow, ffmpeg (with libx264, the `loudnorm` filter), xvfb-run, the Godot 4.3 binary.

Spec (JSON). Top level:
  "name"        output basename (<out>/<name>.mp4, <out>/storyboard.png)
  "render"      [w, h] window the game is recorded at (px): the FINAL video size (1080x1920), so no frame is
                ever resampled. (The first cut recorded a 270x480 window: Godot's canvas_items stretch then
                shrank the 1280-wide world to 0.21x, the sprites became ~10 px smudges and were blown up 5x:
                the grainy look the owner reported.)
  "art_scale"   integer N: 1 art px = N window px exactly (`--capture-scale=N`, 2 = the game's own "Close"
                zoom, a 540x960 world view; 3 = a 360x640 view). The tool also passes `--view=(w/N)x(h/N)` so the
                enemy spawn ring fits that view, and `--hide-hud` so no HUD or level-up card is in frame.
  "crop"        optional [w, h] centred crop of the recording (px, no scaling unless it differs from "size";
                then nearest-neighbour by an integer). Per-shot "crop" / "crop_dy" override.
  "size"        [w, h] of the final video (1080 x 1920)
  "fps"         frames per second of the recording and the video (30)
  "lufs"        target integrated loudness (-14)
  "shots"       list of shots, in order (below)
A shot:
  "id"          name (also the work-file name)
  "stage"       stage id for `--stage=` (graveyard, olympus, kurogane, liberty_heights, ark, ...)
  "seed"        `--seed=` (the same seed + stage + extra always records the same run)
  "start"       game second at which the shot starts (the run is fast-forwarded to it)
  "seconds"     length of the shot (s of game time = s of video: the shot plays at x1)
  "extra"       optional list of more autotest args (e.g. ["--boss=alaric", "--character=bone_oracle"])
  "dim"         optional 0..1, darkens the picture (an end card behind text)
  "logo"        optional {"y": px, "scale": int}: the game's logo PNG (assets/ui/logo.png) at that y
  "texts"       (a text that lasts to the end of the shot has no fade-out, so repeating it in the next shot holds
                it across the cut) list of {"text": "LINE1\\nLINE2", "font": "jersey"|"jacquard", "size": native px (28 / 38 / 57 for
                Jersey, 43 for Jacquard), "scale": integer enlargement, "color": "gold"|"teal"|"cream"|"violet"|
                "crimson", "y": top of the text block in the final video (px), "from": s, "to": s (within the shot)}
Safe zone: keep text inside x 80..918 (TikTok's buttons sit on the right ~15%) and y 150..1500 (the caption, bottom
~20%, and the top bar are covered by TikTok's own UI).
"""
import argparse
import concurrent.futures
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# Repository root (this file lives in tools/).
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Default Godot binary (cloud sessions); override with --godot or $GODOT.
GODOT_DEFAULT = "/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64"
# The game's fonts (OFL): Jersey 10 for text, Jacquard 24 for titles.
FONTS = {"jersey": os.path.join(ROOT, "assets/fonts/Jersey10-Regular.ttf"),
         "jacquard": os.path.join(ROOT, "assets/fonts/Jacquard24-Regular.ttf")}
# Text colours = UiTheme constants (scripts/ui/ui_theme.gd), 0-255 RGB.
COLORS = {"gold": (255, 214, 102),    # TEXT_GOLD: evolution / victory / selection
          "teal": (140, 255, 166),    # TEXT_GOOD: soul-teal, affordable / focused / new
          "cream": (235, 230, 214),   # TEXT: normal text
          "violet": (170, 130, 235),  # a light tint of the violet BORDER (0.45, 0.3, 0.7)
          "crimson": (255, 96, 96)}   # danger
# Outline colour of burned-in text: UiTheme.BG (0.08, 0.05, 0.12), the game's near-black violet.
OUTLINE = (20, 13, 31)
# Seconds of audio fade at every cut (s), so hard cuts between different scores do not click.
CUT_FADE = 0.06
# Seconds the audio fades in at the start and out at the end of the clip (s).
FADE_IN, FADE_OUT = 0.25, 0.9
# Seconds the video fades to black at the very end (s).
VIDEO_FADE_OUT = 0.5
# Seconds a text takes to fade in / out (s).
TEXT_FADE = 0.12
# x264 quality (lower = better; 14 keeps hard pixel edges clean on the dithered floors) and AAC bitrate.
CRF, AAC_BITRATE = "14", "192k"
# Peak video bitrate allowed (VBV, Mbit/s): keeps a 30 s clip well under 150 MB.
MAXRATE_MBIT = 60
# Keyframe interval (frames) and x264 tune for flat-coloured pixel art.
KEYINT, X264_TUNE = 60, "animation"
# RGB -> YUV: nearest-neighbour scaling flags, accurate rounding and full chroma, BT.709 matrix.
SWS = "flags=neighbor+accurate_rnd+full_chroma_int"


def run(cmd, **kw):
    """Runs a command, raising with its output on failure."""
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, **kw)
    if r.returncode != 0:
        sys.exit("command failed (%d): %s\n%s" % (r.returncode, " ".join(cmd), r.stdout[-3000:]))
    return r.stdout


def capture(spec, shots, work, godot, force, jobs):
    """Records every distinct run once; returns {shot id: (recording dir path prefix, start frame, end frame)}."""
    groups = {}
    for s in shots:
        key = (s["stage"], int(s["seed"]), tuple(s.get("extra", [])))
        groups.setdefault(key, []).append(s)
    found = {}
    rw, rh = spec["render"]
    fps = spec["fps"]
    art = int(spec.get("art_scale", 0))
    view = ["--capture-scale=%d" % art, "--view=%dx%d" % (rw // art, rh // art), "--hide-hud"] if art else []
    todo = []  # (shot group, recording dir, spans text, command) per run that still has to be recorded
    plans = []
    for (stage, seed, extra), group in groups.items():
        group.sort(key=lambda s: s["start"])
        spans = ",".join("%g:%g" % (s["start"], s["seconds"]) for s in group)
        tag = hashlib.sha1(("%s|%s|%s|%dx%d|%d|%d" % (stage, spans, extra, rw, rh, fps, art)).encode()).hexdigest()[:8]
        d = os.path.join(work, "%s_%d_%s" % (stage, seed, tag))
        rec, log = os.path.join(d, "f.png"), os.path.join(d, "log.txt")  # Movie Maker: f00000000.png ... + f.wav
        plans.append((group, d, rec, log))
        if force or not (os.path.exists(os.path.join(d, "f.wav")) and os.path.exists(log)):
            cmd = ["xvfb-run", "-a", "-s", "-screen 0 %dx%dx24" % (max(rw, 1280), max(rh, 1280)),
                   godot, "--path", ROOT, "--resolution", "%dx%d" % (rw, rh), "--fixed-fps", str(fps),
                   "--write-movie", rec, "--", "--autotest", "--policy=army", "--seed=%d" % seed,
                   "--stage=%s" % stage, "--speed=32", "--movie-spans=%s" % spans] + view + list(extra)
            todo.append((group, d, rec, log, cmd, stage, seed, spans))

    def record(job):
        group, d, rec, log, cmd, stage, seed, spans = job
        os.makedirs(d, exist_ok=True)
        print("[capture] %s seed %d spans %s ..." % (stage, seed, spans), flush=True)
        out = run(cmd)
        open(log, "w").write(out)
        keep = set()  # frames of the spans; the other (fast-forward) frames are deleted
        for m in re.finditer(r"\[movie\] span (\d+) start frame=(\d+)", out):
            keep.update(range(int(m.group(2)), int(m.group(2)) + int(round(float(group[int(m.group(1))]["seconds"]) * fps)) + 2))
        for f in os.listdir(d):
            m = re.match(r"f(\d{8})\.png$", f)
            if m and int(m.group(1)) not in keep:
                os.remove(os.path.join(d, f))

    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, jobs)) as ex:
        list(ex.map(record, todo))  # raises the first failure
    for group, d, rec, log in plans:
        text = open(log).read()
        marks = {}
        for m in re.finditer(r"\[movie\] span (\d+) (start|end) frame=(\d+)", text):
            marks[(int(m.group(1)), m.group(2))] = int(m.group(3))
        for i, s in enumerate(group):
            if (i, "start") not in marks or (i, "end") not in marks:
                sys.exit("no [movie] span marks for shot %s in %s (the run ended early?)" % (s["id"], log))
            found[s["id"]] = (rec, marks[(i, "start")], marks[(i, "end")])
    return found


def text_png(t, size, path):
    """Draws one text block (native pixel size, no anti-aliasing, outlined) enlarged by an integer with
    nearest-neighbour, plus a soft dark shadow, onto a transparent canvas the width of the video.
    Returns the PNG's height (px). The text is centred horizontally; its top is at t['y'] in the video."""
    font = ImageFont.truetype(FONTS[t.get("font", "jersey")], int(t["size"]))
    scale = int(t.get("scale", 3))
    color = COLORS[t.get("color", "cream")]
    lines = t["text"].split("\n")
    pad = 3
    bbs = [font.getbbox(l) for l in lines]
    lh = int(t["size"] * 1.0)
    w = max(b[2] for b in bbs) + 2 * pad
    h = lh * len(lines) + 2 * pad + 4
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.fontmode = "1"  # no anti-aliasing: hard pixels like the game
    for i, l in enumerate(lines):
        lw = font.getbbox(l)[2]
        x = (w - lw) // 2
        y = pad + i * lh
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1, 2):
                if dx or dy:
                    d.text((x + dx, y + dy), l, font=font, fill=OUTLINE + (255,))
        d.text((x, y), l, font=font, fill=color + (255,))
    big = img.resize((w * scale, h * scale), Image.NEAREST)
    # soft shadow under everything, so the text reads on any background
    sh = Image.new("RGBA", big.size, (0, 0, 0, 0))
    alpha = big.split()[3].point(lambda a: 150 if a else 0)
    sh.putalpha(alpha)
    sh = sh.filter(ImageFilter.GaussianBlur(10 * max(1, scale // 3)))
    canvas = Image.new("RGBA", (size[0], big.size[1] + 40), (0, 0, 0, 0))
    ox = (size[0] - big.size[0]) // 2
    canvas.alpha_composite(sh, (ox, 20))
    canvas.alpha_composite(big, (ox, 20))
    canvas.save(path)
    return canvas.size[1]


def logo_png(logo, size, path):
    """The game's logo PNG, enlarged by an integer scale with nearest-neighbour, centred on a video-wide canvas."""
    img = Image.open(os.path.join(ROOT, "assets/ui/logo.png")).convert("RGBA")
    scale = int(logo.get("scale", 3))
    big = img.resize((img.size[0] * scale, img.size[1] * scale), Image.NEAREST)
    canvas = Image.new("RGBA", (size[0], big.size[1]), (0, 0, 0, 0))
    canvas.alpha_composite(big, ((size[0] - big.size[0]) // 2, 0))
    canvas.save(path)


def cut(spec, shot, src, work):
    """Cuts one shot out of its recording into <work>/cut_<id>.mkv (video 1080x1920 with text, audio pcm)."""
    rec, f0, f1 = src
    d = os.path.dirname(rec)
    fps = spec["fps"]
    size = spec["size"]
    n = int(round(shot["seconds"] * fps))
    f1 = f0 + n  # frames f0 .. f1-1 (the recording runs 0.3 s past the span, so they exist)
    out = os.path.join(work, "cut_%s.mkv" % shot["id"])
    dur = (f1 - f0) / fps
    inputs = ["-framerate", str(fps), "-start_number", str(f0), "-i", os.path.join(d, "f%08d.png"),
              "-ss", "%.5f" % (f0 / fps), "-t", "%.5f" % dur, "-i", os.path.join(d, "f.wav")]
    cw, ch = shot.get("crop", spec.get("crop", spec["render"]))  # centred crop of the recorded frame (px)
    cdy = int(shot.get("crop_dy", spec.get("crop_dy", 0)))  # shifts the crop down (+) / up (-) in recorded px
    filt = ["[0:v]setpts=PTS-STARTPTS,crop=%d:%d:(iw-%d)/2:(ih-%d)/2+%d,scale=%d:%d:flags=neighbor,format=rgba%s[v0]" % (
        cw, ch, cw, ch, cdy, size[0], size[1], (",colorchannelmixer=rr=%g:gg=%g:bb=%g" % ((1 - shot["dim"],) * 3)) if shot.get("dim") else "")]
    last, k = "v0", 1
    layers = []
    for i, t in enumerate(shot.get("texts", [])):
        p = os.path.join(work, "txt_%s_%d.png" % (shot["id"], i))
        text_png(t, size, p)
        layers.append((p, int(t["y"]), t.get("from", 0.0), t.get("to", dur)))
    if shot.get("logo"):
        p = os.path.join(work, "logo_%s.png" % shot["id"])
        logo_png(shot["logo"], size, p)
        layers.append((p, int(shot["logo"]["y"]), shot["logo"].get("from", 0.0), shot["logo"].get("to", dur)))
    for p, y, a, b in layers:
        inputs += ["-loop", "1", "-framerate", str(fps), "-t", "%.3f" % dur, "-i", p]
        k_in = k + 1  # input 0 = frames, 1 = wav, then the overlay PNGs
        fx = ["format=rgba"]
        if a > 0:  # a text at 0 s is there from frame 1
            fx.append("fade=t=in:st=%.3f:d=%.3f:alpha=1" % (a, TEXT_FADE))
        if b < dur - 0.01:  # a text that runs to the shot's end is "held" across the cut (the next shot repeats it): no fade-out
            fx.append("fade=t=out:st=%.3f:d=%.3f:alpha=1" % (max(a, b - TEXT_FADE), TEXT_FADE))
        filt.append("[%d:v]%s[t%d]" % (k_in, ",".join(fx), k))
        filt.append("[%s][t%d]overlay=x=0:y=%d:format=auto[o%d]" % (last, k, y, k))
        last = "o%d" % k
        k += 1
    filt.append("[%s]format=rgb24[vout]" % last)  # stays RGB: the one RGB -> YUV step is the final encode
    filt.append("[1:a]asetpts=PTS-STARTPTS,afade=t=in:st=0:d=%g,afade=t=out:st=%.5f:d=%g[aout]" % (
        CUT_FADE, dur - CUT_FADE, CUT_FADE))
    run(["ffmpeg", "-v", "error", "-y"] + inputs + ["-filter_complex", ";".join(filt), "-map", "[vout]", "-map", "[aout]",
        "-r", str(fps), "-c:v", "ffv1", "-pix_fmt", "bgr0", "-c:a", "pcm_s16le",
        "-ar", "48000", "-ac", "2", "-t", "%.3f" % dur, out])
    return out, dur


def assemble(spec, cuts, out_mp4, work):
    """Concatenates the cuts, fades, normalises loudness (two passes) and encodes the final MP4."""
    fps = spec["fps"]
    inputs = []
    for c, _ in cuts:
        inputs += ["-i", c]
    n = len(cuts)
    total = sum(d for _, d in cuts)
    cat = "".join("[%d:v][%d:a]" % (i, i) for i in range(n)) + "concat=n=%d:v=1:a=1[v][a]" % n
    target = spec.get("lufs", -14)
    afade = "afade=t=in:st=0:d=%g,afade=t=out:st=%.3f:d=%g" % (FADE_IN, total - FADE_OUT, FADE_OUT)
    vfade = "fade=t=out:st=%.3f:d=%g" % (total - VIDEO_FADE_OUT, VIDEO_FADE_OUT)
    # pass 1: measure the loudness of the whole mix (audio only)
    acat = "".join("[%d:a]" % i for i in range(n)) + "concat=n=%d:v=0:a=1[a]" % n
    meas = run(["ffmpeg", "-hide_banner", "-y"] + inputs + ["-filter_complex", acat + ";[a]%s,loudnorm=I=%g:TP=-1.5:LRA=11:print_format=json[ao]" % (afade, target),
               "-map", "[ao]", "-f", "null", "-"])
    j = json.loads(meas[meas.rindex("{"):meas.rindex("}") + 1])
    ln = "loudnorm=I=%g:TP=-1.5:LRA=11:measured_I=%s:measured_TP=%s:measured_LRA=%s:measured_thresh=%s:offset=%s:linear=true" % (
        target, j["input_i"], j["input_tp"], j["input_lra"], j["input_thresh"], j["target_offset"])
    run(["ffmpeg", "-v", "error", "-y"] + inputs + ["-filter_complex", cat + ";[v]%s,scale=out_color_matrix=bt709:%s,format=yuv420p[vo];[a]%s,%s[ao]" % (vfade, SWS, afade, ln),
        "-map", "[vo]", "-map", "[ao]", "-r", str(fps), "-sws_flags", SWS,
        "-c:v", "libx264", "-crf", CRF, "-preset", "slow", "-tune", X264_TUNE, "-profile:v", "high", "-level", "4.2",
        "-maxrate", "%dM" % MAXRATE_MBIT, "-bufsize", "%dM" % (2 * MAXRATE_MBIT),
        "-x264-params", "keyint=%d:min-keyint=%d:scenecut=0" % (KEYINT, KEYINT), "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-c:a", "aac", "-b:a", AAC_BITRATE, "-ar", "48000", "-movflags", "+faststart", out_mp4])
    return total


def storyboard(mp4, total, path, work):
    """Six evenly spaced frames in a 3 x 2 contact sheet."""
    times = [total * f for f in (0.05, 0.2, 0.38, 0.58, 0.78, 0.93)]
    files = []
    for i, t in enumerate(times):
        f = os.path.join(work, "sb_%d.png" % i)
        run(["ffmpeg", "-v", "error", "-y", "-ss", "%.2f" % t, "-i", mp4, "-frames:v", "1", "-vf", "scale=360:640:flags=neighbor", f])
        files.append(f)
    sheet = Image.new("RGB", (360 * 3 + 40, 640 * 2 + 30), (20, 13, 31))
    for i, f in enumerate(files):
        sheet.paste(Image.open(f).convert("RGB"), (10 + (i % 3) * 370, 10 + (i // 3) * 650))
    sheet.save(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("--spec", default=os.path.join(ROOT, "tools/promo_clip_spec.json"))
    ap.add_argument("--out", default=os.path.join(ROOT, "build/promo"))
    ap.add_argument("--work", default=None, help="cache / intermediate dir (default <out>/work)")
    ap.add_argument("--godot", default=os.environ.get("GODOT", GODOT_DEFAULT))
    ap.add_argument("--jobs", type=int, default=3, help="Godot runs at once (the machine has ~4 cores; keep <= 3)")
    ap.add_argument("--force", action="store_true", help="record every run again")
    ap.add_argument("--only-capture", action="store_true")
    a = ap.parse_args()
    spec = json.load(open(a.spec))
    out = os.path.abspath(a.out)
    work = os.path.abspath(a.work or os.path.join(out, "work"))
    os.makedirs(work, exist_ok=True)
    shots = spec["shots"]
    found = capture(spec, shots, work, a.godot, a.force, a.jobs)
    if a.only_capture:
        return
    os.makedirs(out, exist_ok=True)
    cwork = os.path.join(work, "cut_" + spec.get("name", "promo"))  # per-clip intermediates: clips can render in parallel sharing the recordings
    os.makedirs(cwork, exist_ok=True)
    cuts = []
    for s in shots:
        print("[cut] %s" % s["id"], flush=True)
        cuts.append(cut(spec, s, found[s["id"]], cwork))
    mp4 = os.path.join(out, spec.get("name", "promo") + ".mp4")
    total = assemble(spec, cuts, mp4, cwork)
    storyboard(mp4, total, os.path.join(out, "storyboard.png"), cwork)
    print("[done] %s  %.1f s  %.1f MB" % (mp4, total, os.path.getsize(mp4) / 1e6))


if __name__ == "__main__":
    main()
