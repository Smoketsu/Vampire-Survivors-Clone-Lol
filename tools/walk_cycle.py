"""walk_cycle.py: procedural walk strips cut from the approved still sprites (art pass).

Usage (from the repo root):
    python3 tools/walk_cycle.py build <key> [<key> ...]     write assets/sprites/<key>_walk.png
    python3 tools/walk_cycle.py build --all                  every key in RIGS
    python3 tools/walk_cycle.py preview <key> [...] --out-dir DIR
        per key: <id>_walk.gif (walking in place, 4x) and <id>_walk_sheet.png
        (the still, then every frame, 6x, on the Graveyard soil)
    python3 tools/walk_cycle.py sheet <key> [...] --out PNG  one review sheet for many keys

Why procedural (ART_BIBLE "Walk cycles", the pilot): the owner approved the
stills pixel by pixel. An AI walk sheet, even with the still attached, redraws
the character (the pilot lost the Warrior's skull face and the Recruit's face,
changed the helmets and came back on a dark glow, not a clean alpha), so its
frames would not be the approved sprite and would flicker against it. This tool
keeps EVERY approved pixel and only moves parts of the still:

  1. The still is cut at the rig's `hip` row. Rows above it are the upper body
     (head, torso, arms, held weapons): moved as one rigid block, only up and
     down (the step dip), so nothing above the hip ever changes shape or x.
  2. Below the hip each pixel goes to a layer by its column: the `back` leg's
     column range, the `front` leg's range, and everything else (a spear butt,
     a staff foot, a shield rim) to the rigid layer, which moves with the body.
     In "robe" mode the whole lower part (the hem) is one layer instead.
  3. Each leg is re-laid row by row from its hip to its foot: shortened by
     whole rows taken out near its middle (the knee bends when the body dips,
     the swinging foot lifts) and sheared sideways, 0 px at the hip growing to
     its full shift at the foot (the legs swing together and apart). Rows are
     moved intact, so every outline, rim and colour pixel is an approved one;
     only their positions change, by whole art px.
  4. Layers are stacked back leg, front leg, rigid parts, upper body.

The cycle is FRAMES (WalkData.FRAMES, 8) frames = two steps of four poses each:
contact (the still itself: frame 0 is pixel-identical to the still), down (the
body 1 px lower, the feet a little closer, the swinging foot starting to lift),
passing (the feet together under the hip, the swinging foot lifted `lift` px)
and up (the feet parting again). The first step swings the back leg, the
second the front one. A robe sways its hem forward and back instead
(`sway` px at the hem, ROBE_SWAY per pose) and dips with the body.

Output layout (the engine contract, SpriteBank.draw()): assets/sprites/
<key>_walk.png is FRAMES frames side by side, no gaps, each exactly the still's
width and height: frame i covers x = i * W .. (i + 1) * W - 1, so a frame drawn
where the still is drawn lines up pixel for pixel (feet on the bottom row, the
body at the same x). Colours are the still's own (no new colour can appear).

Every number that shapes a strip is in RIGS (per key) or the pose tables below,
so a rebuild is exact and deterministic. Requires Pillow and numpy.
"""

import argparse
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent  # Repo root.
SPRITE_DIR = ROOT / "assets" / "sprites"  # In-game sprite folder (SpriteData.ROOT).
WALK_DATA = ROOT / "scripts" / "data" / "walk_data.gd"  # Frame count and suffix live there.


def _walk_const(name: str, default: str) -> str:
    """Reads constant `name` from walk_data.gd (one source of truth for the engine and the tool)."""
    m = re.search(rf"const {name}: \w+ = \"?([\w]+)\"?", WALK_DATA.read_text())
    return m.group(1) if m else default


FRAMES = int(_walk_const("FRAMES", "8"))  # Frames per cycle (two steps).
SUFFIX = _walk_const("SUFFIX", "_walk")  # Strip key suffix.
POSES = 4  # Poses per step: contact, down, passing, up.
if FRAMES != 2 * POSES:
    sys.exit(f"walk_data.gd FRAMES is {FRAMES}; this tool writes two steps of {POSES} poses")

# Per pose (contact, down, passing, up): how far the feet have come together
# (0 = the still's stance, 1 = the rig's full `spread` toward each other).
TOGETHER = (0.0, 0.5, 1.0, 0.5)
# Per pose: share of the rig's `lift` the swinging foot is raised (rounded).
LIFT = (0.0, 0.5, 1.0, 0.5)
# Per pose: art px the body (upper block, rigid parts, hip) dips, times the rig's `dip`.
DIP = (0, 1, 0, 0)
# Per frame (both steps): hem shift at the hem bottom as a share of a robe rig's
# `sway` (+ = forward, the facing side): the hem swings forward on each step.
ROBE_SWAY = (0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5)
# Per frame (both steps): how far the bust's underside moves relative to the body, as a
# share of the rig's `bust` bounce px (+ = down). Secondary motion (owner request, Oct 2026:
# "jiggle"), timed like a damped spring driven by the step: the bust lags the body's dip
# ("down": it stays up, -0.5), overshoots as the body rises ("passing": +1), rebounds
# ("up": -0.5) and settles on the contact (0, so frame 0 stays the still).
BUST_BOUNCE = (0.0, -0.5, 1.0, -0.5, 0.0, -0.5, 1.0, -0.5)
# Rows below the bust box over which the warp fades back to zero, per bounce px (the
# belly takes up the motion instead of tearing at the box edge).
BUST_TAIL_PER_PX = 1

# Rigs: how each still is cut. Columns and rows are art px in the still (x from
# the left, y from the top; ranges are [start, end) ). Keys:
#   mode    "legs" (two legs) or "robe" (one hem layer).
#   hip     first row of the lower part (legs / hem); rows above are the upper body.
#   back    column range of the back (left, trailing) leg below the hip ("legs").
#   front   column range of the front (right, leading) leg below the hip ("legs").
#   rigid   rectangles (x0, x1, y0, y1) below the hip that move with the body,
#           never sheared (a staff or spear foot, a sword tip, a shield rim);
#           checked before the legs. y1 None = to the bottom.
#   spread  px each foot moves toward the other at passing ("legs").
#   lift    px the swinging foot rises at passing ("legs").
#   sway    px the hem bottom swings at most ("robe").
#   dip     px the body dips on the "down" pose (0 or 1; 1 for every unit so far).
#   bust    optional (x0, x1, y0, y1, px): the box of the still holding the bust (art px,
#           [start, end) ; y0 = the neckline, y1 - 1 = the underside) and the bounce in
#           px at its strongest point. Each frame warps that box vertically (_bounce): the
#           neckline stays, the underside moves BUST_BOUNCE * px at the box's centre column,
#           less toward its sides, fading out below it. Pixels are only moved, never
#           recoloured, so every pixel stays an approved one.
RIGS = {
    # The pilot (ART_BIBLE "Walk cycles"): the three units with the most screen time.
    "player/necromancer": dict(mode="legs", hip=47, back=(0, 20), front=(20, 33), rigid=[(33, 46, 0, None)], spread=1, lift=1, dip=1),
    "summons/warrior": dict(mode="legs", hip=33, back=(0, 8), front=(16, 28), rigid=[(8, 16, 0, 37)], spread=3, lift=2, dip=1),
    "enemies/recruit": dict(mode="legs", hip=41, back=(0, 13), front=(13, 25), rigid=[(24, 30, 0, 45), (25, 30, 45, None)], spread=2, lift=2, dip=1),
    # Summons, by screen time. Robed priests walk on their hem lobes and feet.
    "summons/archer": dict(mode="legs", hip=32, back=(0, 26), front=(26, 50), rigid=[(35, 50, 0, 34)], spread=3, lift=2, dip=1),
    "summons/mage": dict(mode="legs", hip=38, back=(0, 20), front=(20, 42), rigid=[(31, 36, 0, 40)], spread=2, lift=1, dip=1),
    "summons/mender": dict(mode="legs", hip=44, back=(0, 24), front=(24, 38), rigid=[(38, 48, 0, None)], spread=2, lift=2, dip=1),
    "summons/warder": dict(mode="legs", hip=42, back=(0, 24), front=(24, 44), rigid=[], spread=2, lift=1, dip=1),
    "summons/rogue": dict(mode="legs", hip=34, back=(0, 27), front=(27, 48), rigid=[(0, 11, 0, 36)], spread=3, lift=2, dip=1),
    "summons/risen": dict(mode="legs", hip=27, back=(0, 12), front=(12, 24), rigid=[], spread=2, lift=1, dip=1),
    # The hound: hind legs gather toward the forelegs (a bounding lope); the head rides with the body.
    "summons/bone_hound": dict(mode="legs", hip=19, back=(0, 27), front=(27, 56), rigid=[(44, 56, 0, 24)], spread=2, lift=1, dip=1),
    # Covenant soldiers.
    "enemies/footman": dict(mode="legs", hip=41, back=(0, 14), front=(14, 32), rigid=[], spread=2, lift=2, dip=1),
    "enemies/archer": dict(mode="legs", hip=43, back=(0, 15), front=(19, 36), rigid=[(25, 36, 0, 46)], spread=2, lift=2, dip=1),
    "enemies/chaplain": dict(mode="legs", hip=38, back=(0, 22), front=(22, 40), rigid=[], spread=1, lift=1, dip=1),
    "enemies/purifier": dict(mode="legs", hip=36, back=(0, 20), front=(20, 46), rigid=[], spread=2, lift=2, dip=1),
    "enemies/shieldbearer": dict(mode="legs", hip=45, back=(0, 12), front=(12, 32), rigid=[(14, 30, 0, 52)], spread=2, lift=1, dip=1),
    "enemies/halberdier": dict(mode="legs", hip=50, back=(0, 14), front=(14, 30), rigid=[(21, 30, 0, 55)], spread=2, lift=2, dip=1),
    # The playable characters (robes: the hem lobes and the feet under them).
    "player/umbral_warden": dict(mode="legs", hip=56, back=(0, 21), front=(21, 31), rigid=[(31, 42, 0, None)], spread=1, lift=1, dip=1),
    "player/voidcaller": dict(mode="legs", hip=47, back=(0, 23), front=(23, 42), rigid=[], spread=1, lift=1, dip=1),
    "player/bone_oracle": dict(mode="legs", hip=47, back=(0, 18), front=(18, 28), rigid=[(28, 38, 0, None)], spread=1, lift=1, dip=1),
    "player/fallen_confessor": dict(mode="legs", hip=44, back=(15, 26), front=(26, 44), rigid=[(0, 15, 0, None)], spread=1, lift=1, dip=1),
    "player/carrion_lord": dict(mode="legs", hip=47, back=(0, 30), front=(30, 62), rigid=[], spread=1, lift=1, dip=1),
    "player/plague_scholar": dict(mode="legs", hip=43, back=(0, 26), front=(26, 60), rigid=[], spread=2, lift=1, dip=1),
    "player/doomsayer": dict(mode="legs", hip=47, back=(0, 17), front=(17, 32), rigid=[], spread=1, lift=1, dip=1),
    "player/barrow_warden": dict(mode="legs", hip=52, back=(0, 18), front=(18, 30), rigid=[(30, 44, 0, None)], spread=1, lift=1, dip=1),
    # Redesigned figures (owner request, Oct 2026): the bust box bounces 1 px (BUST_BOUNCE).
    "player/soulbinder": dict(mode="legs", hip=54, back=(0, 24), front=(24, 44), rigid=[], spread=1, lift=1, dip=1, bust=(18, 31, 21, 26, 2)),
    "player/wither_witch": dict(mode="legs", hip=40, back=(0, 18), front=(18, 26), rigid=[(26, 36, 0, None)], spread=1, lift=1, dip=1, bust=(14, 25, 15, 21, 2)),
    # Seraphine floats: her "walk" is a glide (robe hem sway, the body bob, the bust bounce).
    # The still's relic staff stays rigid down to row 90, where it meets the robe.
    "bosses/seraphine": dict(mode="robe", hip=70, rigid=[(68, 98, 0, 90)], sway=2, dip=1, bust=(45, 61, 45, 57, 3)),
    "bosses/seraphine_avatar": dict(mode="robe", hip=104, rigid=[], sway=2, dip=1, bust=(81, 97, 63, 75, 3)),
    "player/grave_herald": dict(mode="legs", hip=53, back=(0, 24), front=(24, 46), rigid=[], spread=1, lift=1, dip=1),
    # Later units with long screen time: the walking summon evolutions and two March soldiers.
    "summons/death_knight": dict(mode="legs", hip=41, back=(0, 25), front=(25, 54), rigid=[], spread=2, lift=2, dip=1),
    "summons/gravebow": dict(mode="legs", hip=42, back=(0, 22), front=(22, 33), rigid=[(33, 52, 0, None)], spread=2, lift=2, dip=1),
    "summons/shadow_reaper": dict(mode="legs", hip=40, back=(0, 24), front=(24, 43), rigid=[(43, 50, 0, None)], spread=2, lift=2, dip=1),
    "summons/hellhound": dict(mode="legs", hip=25, back=(0, 30), front=(30, 60), rigid=[(47, 60, 0, 27)], spread=2, lift=1, dip=1),
    "enemies/templar": dict(mode="legs", hip=69, back=(0, 18), front=(18, 36), rigid=[(28, 32, 0, 72), (0, 7, 0, 72)], spread=2, lift=2, dip=1),
    "enemies/banner_bearer": dict(mode="legs", hip=75, back=(0, 16), front=(16, 40), rigid=[(27, 31, 0, 79)], spread=2, lift=2, dip=1),
}

# Skins (SkinData, cosmetic): skin sprite key -> its character's sprite key. A skin keeps
# its character's body height and pose (ART_BIBLE "Player skins"), so its rig is derived
# from the character's (skin_rig()); SKIN_FIX overrides single fields after review.
SKINS = {
    "player/gravecaller_dread_sovereign": "player/necromancer",
    "player/gravecaller_hyper": "player/necromancer",
    "player/umbral_warden_hyper": "player/umbral_warden",
    "player/voidcaller_hyper": "player/voidcaller",
    "player/bone_oracle_ivory_seer": "player/bone_oracle",
    "player/bone_oracle_hyper": "player/bone_oracle",
    "player/fallen_confessor_heretic_saint": "player/fallen_confessor",
    "player/fallen_confessor_hyper": "player/fallen_confessor",
    "player/carrion_lord_hyper": "player/carrion_lord",
    "player/plague_scholar_plague_doctor": "player/plague_scholar",
    "player/plague_scholar_hyper": "player/plague_scholar",
    "player/doomsayer_hyper": "player/doomsayer",
    "player/barrow_warden_hyper": "player/barrow_warden",
    "player/soulbinder_hyper": "player/soulbinder",
    "player/wither_witch_hyper": "player/wither_witch",
    "player/grave_herald_hyper": "player/grave_herald",
}
# Per-skin field overrides of the derived rig (same keys as RIGS), set after review.
SKIN_FIX = {}


def load(key: str) -> np.ndarray:
    """The approved still of `key` as an RGBA uint8 array (rows, cols, 4)."""
    return np.array(Image.open(SPRITE_DIR / (key + ".png")).convert("RGBA"))


def _lower_centre(img: np.ndarray, hip: int) -> float:
    """Centre column of the opaque pixels at and below row `hip`."""
    cols = np.nonzero(img[hip:, :, 3].any(axis=0))[0]
    return (cols.min() + cols.max()) / 2.0 if cols.size else img.shape[1] / 2.0


def skin_rig(skin: str, base: str) -> dict:
    """The rig of skin `skin` derived from its character `base`: the hip the same number of
    rows above the feet (the bodies match head to feet; a crown or halo only adds rows on
    top) and every column range moved by the offset between the two lower bodies' centres."""
    rig = dict(RIGS[base])
    b, s = load(base), load(skin)
    dy = s.shape[0] - b.shape[0]  # Extra rows on top of the skin.
    rig["hip"] = RIGS[base]["hip"] + dy
    dx = int(round(_lower_centre(s, rig["hip"]) - _lower_centre(b, RIGS[base]["hip"])))  # Column shift.
    w = s.shape[1]

    def cols(r: tuple) -> tuple:
        return (min(w, max(0, r[0] + dx)), min(w, max(0, r[1] + dx)))

    if "back" in rig:
        rig["back"], rig["front"] = cols(rig["back"]), cols(rig["front"])
    rig["rigid"] = [(*cols((x0, x1)), y0 if y0 == 0 else y0 + dy, None if y1 is None else y1 + dy)
                    for x0, x1, y0, y1 in rig.get("rigid", [])]
    if "bust" in rig:
        bx0, bx1, by0, by1, bpx = rig["bust"]
        rig["bust"] = (*cols((bx0, bx1)), by0 + dy, by1 + dy, bpx)
    rig.update(SKIN_FIX.get(skin, {}))
    return rig


for _skin, _base in SKINS.items():
    RIGS[_skin] = skin_rig(_skin, _base)


def _shift_rows(layer: np.ndarray, top: int, dy: int, lift: int, shift: float) -> np.ndarray:
    """Re-lays the opaque rows of `layer` from row `top` down to its last opaque
    row: the block starts `dy` rows lower, ends `lift` rows higher (whole rows
    taken out evenly between, first and last kept) and each row is moved
    sideways by round(shift * t), t = 0 at the top row to 1 at the last."""
    h, w = layer.shape[:2]
    out = np.zeros_like(layer)
    rows = np.nonzero(layer[:, :, 3].any(axis=1))[0]
    rows = rows[rows >= top]
    if rows.size == 0:
        return out
    bottom = int(rows.max())
    n = bottom - top + 1  # Source rows (hip to foot).
    n2 = max(1, n - dy - lift)  # Rows after the dip and the lift.
    for i in range(n2):
        src = top + (0 if n2 == 1 else int(round(i * (n - 1) / (n2 - 1))))  # Source row (even take-out).
        t = 0.0 if n2 == 1 else i / (n2 - 1)  # 0 at the hip, 1 at the foot.
        dx = int(np.floor(shift * t + 0.5)) if shift >= 0 else -int(np.floor(-shift * t + 0.5))  # Sideways px.
        y = top + dy + i  # Destination row.
        if not 0 <= y < h:
            continue
        row = layer[src]
        if dx > 0:
            out[y, dx:] = row[:w - dx]
        elif dx < 0:
            out[y, :w + dx] = row[-dx:]
        else:
            out[y] = row
    return out


def _move(layer: np.ndarray, dy: int) -> np.ndarray:
    """`layer` moved `dy` rows down (rows pushed past the bottom are dropped)."""
    if dy == 0:
        return layer.copy()
    out = np.zeros_like(layer)
    out[dy:] = layer[:-dy]
    return out


def _stack(layers: list) -> np.ndarray:
    """Layers composited in order (later ones on top; alpha is 0 or 255)."""
    out = np.zeros_like(layers[0])
    for lay in layers:
        m = lay[:, :, 3] > 0
        out[m] = lay[m]
    return out


def split(still: np.ndarray, rig: dict) -> dict:
    """Cuts the still into its layers by the rig (module doc, steps 1-2)."""
    h, w = still.shape[:2]
    cols = np.arange(w)
    lower = np.zeros((h, w), dtype=bool)
    lower[rig["hip"]:] = True
    rigid = np.zeros((h, w), dtype=bool)  # Pixels that ride with the body below the hip.
    for x0, x1, y0, y1 in rig.get("rigid", []):
        rigid[y0:h if y1 is None else y1, x0:x1] = True
    rigid &= lower
    parts = {}

    def take(mask: np.ndarray) -> np.ndarray:
        lay = np.zeros_like(still)
        lay[mask] = still[mask]
        return lay

    parts["upper"] = take(~lower)
    if rig["mode"] == "legs":
        back = lower & ~rigid & ((cols >= rig["back"][0]) & (cols < rig["back"][1]))[None, :]
        front = lower & ~rigid & ~back & ((cols >= rig["front"][0]) & (cols < rig["front"][1]))[None, :]
        parts["back"] = take(back)
        parts["front"] = take(front)
        rigid |= lower & ~back & ~front  # Unclaimed lower pixels ride with the body.
    else:
        parts["hem"] = take(lower & ~rigid)
    parts["rigid"] = take(rigid)
    return parts


def frames_of(key: str) -> list:
    """The FRAMES walk frames of `key` (RGBA arrays the still's size); frame 0 is the still."""
    still = load(key)
    rig = RIGS[key]
    parts = split(still, rig)
    hip = rig["hip"]
    out = []
    for f in range(FRAMES):
        step, pose = divmod(f, POSES)  # Step 0 swings the back leg, step 1 the front one.
        dy = DIP[pose] * rig.get("dip", 1)
        body = [_move(parts["rigid"], dy), _move(parts["upper"], dy)]
        if rig["mode"] == "legs":
            g = TOGETHER[pose] * rig["spread"]  # Px each foot moves toward the other.
            up = int(round(LIFT[pose] * rig["lift"]))  # Px the swinging foot rises.
            back = _shift_rows(parts["back"], hip, dy, up if step == 0 else 0, g)
            front = _shift_rows(parts["front"], hip, dy, up if step == 1 else 0, -g)
            frame = _stack([back, front] + body)
        else:
            hem = _shift_rows(parts["hem"], hip, dy, 0, ROBE_SWAY[f] * rig["sway"])
            frame = _stack([hem] + body)
        if "bust" in rig:
            frame = _bounce(frame, rig["bust"], dy, BUST_BOUNCE[f] * rig["bust"][4])
        out.append(frame)
    if not np.array_equal(out[0], still):
        sys.exit(f"{key}: frame 0 differs from the still (rig error)")
    return out


def _bounce(frame: np.ndarray, bust: tuple, dy: int, s: float) -> np.ndarray:
    """Warps the bust of `frame` (the still's box `bust` lowered by the body dip `dy`) so its
    underside moves `s` px (+ = down) at the box's centre column. Displacement field: a
    sine bell across the columns (1 at the centre, 0 just outside the box) times a ramp down
    the rows (0 at the neckline, 1 on the underside), then a fade back to 0 over the
    BUST_TAIL_PER_PX * |s| rows below. Each pixel takes the pixel |d| rows above or below it
    in the same column (nearest, inverse mapping: no holes, no new colours). s = 0 returns
    the frame unchanged."""
    if s == 0:
        return frame
    x0, x1 = bust[0], bust[1]  # Box columns [x0, x1) (art px).
    y0, y1 = bust[2] + dy, bust[3] + dy  # Box rows in this frame: neckline .. underside + 1.
    tail = int(np.ceil(abs(s) * BUST_TAIL_PER_PX)) + 1  # Fade-out rows below the box.
    h = frame.shape[0]  # Frame height (art px).
    out = frame.copy()
    span = float(x1 - x0)  # Box width (art px).
    for x in range(x0, x1):
        wx = float(np.sin(np.pi * (x - x0 + 0.5) / span))  # Column weight: 1 at the centre.
        for y in range(max(0, y0), min(h, y1 + tail)):
            if y < y1:
                wy = (y - y0 + 1) / float(y1 - y0)  # 0 at the neckline, 1 on the underside.
            else:
                wy = 1.0 - (y - y1 + 1) / float(tail + 1)  # Fades out under the bust.
            d = int(round(s * wx * wy))  # Rows this pixel's content moves (+ = down).
            sy = y - d  # Source row (inverse mapping).
            if d != 0 and 0 <= sy < h:
                out[y, x] = frame[sy, x]
    return out


def build(key: str) -> Path:
    """Writes assets/sprites/<key>_walk.png and returns its path."""
    frames = frames_of(key)
    strip = np.concatenate(frames, axis=1)
    dest = SPRITE_DIR / (key + SUFFIX + ".png")
    Image.fromarray(strip, "RGBA").save(dest, optimize=True)
    still = frames[0]
    new_cols = {tuple(c) for f in frames for c in f[f[:, :, 3] > 0].tolist()} - {tuple(c) for c in still[still[:, :, 3] > 0].tolist()}
    if new_cols:
        sys.exit(f"{key}: frames hold colours the still does not ({len(new_cols)})")
    print(f"{key}{SUFFIX}: {len(frames)} frames of {still.shape[1]}x{still.shape[0]} -> {dest.relative_to(ROOT)} "
          f"({strip.shape[1]}x{strip.shape[0]})")
    return dest


SOIL = (0x16, 0x1A, 0x1C, 255)  # Graveyard floor colour (palette floor_soil) behind the previews.


def preview(key: str, out_dir: Path, gif_scale: int = 4, sheet_scale: int = 6) -> None:
    """A GIF walking in place and a frame sheet for `key` (on the Graveyard soil)."""
    frames = frames_of(key)
    out_dir.mkdir(parents=True, exist_ok=True)
    name = key.replace("/", "_")
    h, w = frames[0].shape[:2]
    pad = 4
    gif = []
    for f in frames:
        c = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), SOIL)
        c.alpha_composite(Image.fromarray(f, "RGBA"), (pad, pad))
        gif.append(c.convert("RGB").resize(((w + 2 * pad) * gif_scale, (h + 2 * pad) * gif_scale), Image.NEAREST))
    gif[0].save(out_dir / (name + "_walk.gif"), save_all=True, append_images=gif[1:], duration=110, loop=0)
    cells = [frames[0]] + frames
    sheet = Image.new("RGBA", ((w + pad) * len(cells) + pad, h + 2 * pad), SOIL)
    for i, f in enumerate(cells):
        sheet.alpha_composite(Image.fromarray(f, "RGBA"), (pad + i * (w + pad), pad))
    sheet = sheet.resize((sheet.width * sheet_scale, sheet.height * sheet_scale), Image.NEAREST)
    sheet.save(out_dir / (name + "_walk_sheet.png"))
    print(f"{key}: {out_dir / (name + '_walk.gif')}, {out_dir / (name + '_walk_sheet.png')}")


def review_sheet(keys: list, out: Path, scale: int = 4) -> None:
    """One sheet: a row per key with the still and its FRAMES frames."""
    rows = [frames_of(k) for k in keys]
    pad = 4
    W = max((f[0].shape[1] + pad) * (FRAMES + 1) + pad for f in rows)
    H = sum(f[0].shape[0] + pad for f in rows) + pad
    sheet = Image.new("RGBA", (W, H), SOIL)
    y = pad
    for fr in rows:
        h, w = fr[0].shape[:2]
        for i, f in enumerate([fr[0]] + fr):
            sheet.alpha_composite(Image.fromarray(f, "RGBA"), (pad + i * (w + pad), y))
        y += h + pad
    sheet = sheet.resize((W * scale, H * scale), Image.NEAREST)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"review sheet: {out} ({len(keys)} units)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["build", "preview", "sheet"])
    ap.add_argument("keys", nargs="*")
    ap.add_argument("--all", action="store_true", help="every key in RIGS")
    ap.add_argument("--out-dir", default="", help="preview: output folder")
    ap.add_argument("--out", default="", help="sheet: output PNG")
    args = ap.parse_args()
    keys = list(RIGS) if args.all else args.keys
    unknown = [k for k in keys if k not in RIGS]
    if unknown:
        sys.exit(f"no rig for: {', '.join(unknown)}")
    if args.cmd == "build":
        for k in keys:
            build(k)
    elif args.cmd == "preview":
        for k in keys:
            preview(k, Path(args.out_dir or "."))
    else:
        review_sheet(keys, Path(args.out or "walk_sheet.png"))


if __name__ == "__main__":
    main()
