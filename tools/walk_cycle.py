"""walk_cycle.py: procedural walk strips cut from the approved still sprites (art pass).

Usage (from the repo root):
    python3 tools/walk_cycle.py build <key> [<key> ...]     write assets/sprites/<key>_walk.png
    python3 tools/walk_cycle.py build --all                  every key in RIGS
    python3 tools/walk_cycle.py preview <key> [...] --out-dir DIR
        per key: <id>_walk.gif (walking in place, 4x) and <id>_walk_sheet.png
        (the still, then every frame, 6x, on the Graveyard soil)
    python3 tools/walk_cycle.py sheet <key> [...] --out PNG  one review sheet for many keys
    python3 tools/walk_cycle.py idle <key> [...] | --all     write assets/sprites/<key>_idle.png
        (the idle breathing loop; only rigs with a `bust` box; --all = those)
    python3 tools/walk_cycle.py idle-preview <key> [...] | --all --out-dir DIR
        per key: <id>_idle.gif (the breathing loop at IdleData.FPS, 4x) and
        <id>_idle_sheet.png (the still, then every frame, 6x)

Idle strips (the "Idle" section below): IDLE_FRAMES frames, the walk-strip
contract (each frame the still's size, frame 0 the still, no new colour). The
stills fill their frame up to row 0, so the breath cannot rise above the still:
the still is the full breath and the exhale sinks every row above the hip 1 art
px (the last row above the hip is the one taken out, so the hip and everything
below it never move, the feet stay planted), then rises back. The bust reacts
through the same _bounce() field as the walk, timed like a damped spring
(IDLE_BUST: lag, overshoot, a smaller rebound, settle) on each sink and rise.

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
     In "hover" mode (flyers) nothing is cut at a hip: the whole sprite bobs
     (HOVER_BOB) and only the rig's `parts` move: wings flap (FLAP), rotors
     spin (SPIN); see the RIGS key list.
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
# Owner, Oct 2026 (after the Act IV art review): "every bounce animation... just too fast, make
# them a bit slower": the three reversals a step (lag, overshoot, rebound) became one smooth
# swell a step (down to the passing pose and back), so the bust moves at half the rate.
# Was (0.0, -0.5, 1.0, -0.5, 0.0, -0.5, 1.0, -0.5).
BUST_BOUNCE = (0.0, 0.5, 1.0, 0.5, 0.0, 0.5, 1.0, 0.5)
# Per frame (both steps): the same spring for a bounce box with `bust_axis="x"` (a sideways
# jiggle; owner's Act IV art review, round 2, on the Amazon's hips: "things should be jiggling
# side to side rather than up and down"), as a share of the box's px (+ = toward the facing
# side, right). The weight shifts to the other foot on each step, so the kick changes side
# every step: the first step's lag, overshoot and rebound one way, the second's the other way.
# Slowed with BUST_BOUNCE (owner, Oct 2026): one smooth swing to each side per stride instead of a
# kick and rebound every step. Was (0.0, -0.5, 1.0, -0.5, 0.0, 0.5, -1.0, 0.5).
BUST_SWAY = (0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5)
# Per frame (both steps): a rig's optional `swish` box (a skirt's front drape, owner's Act IV art
# review round 5 on the Amazon: "it should swish in front of her") sways sideways like BUST_SWAY
# one frame later (follow-through: the cloth lags the hips it hangs from), as a share of the
# box's px (+ = right). Frame 0 stays 0 so frame 0 is the still.
# Slowed with BUST_SWAY (owner, Oct 2026): BUST_SWAY one frame later, frame 0 kept at 0.
# Was (0.0, 0.0, -0.5, 1.0, -0.5, 0.0, 0.5, -1.0).
SWISH_SWAY = (0.0, 0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0)
# Rows below the bust box over which the warp fades back to zero, per bounce px (the
# belly takes up the motion instead of tearing at the box edge).
BUST_TAIL_PER_PX = 1
# Swing: the pendulum profile of a `swing` part per frame (1 = its full swing one way, -1 the
# other): one swing forward and back over the two steps, 0 on frame 0 (the still).
SWING = (0.0, 0.7, 1.0, 0.7, 0.0, -0.7, -1.0, -0.7)
# Swing: an outline pixel is one whose R + G + B (0-765) is below this (the palette's inks).
SWING_INK_SUM = 120
# Hover mode (flyers; owner's Act III art review, round 1: "it flies, its walk should just
# be a bob"): per frame, the whole sprite's rise as a share of the rig's `bob` px (+ = up).
# One slow bob per cycle; frame 0 is the still (the lowest point). The still keeps `bob`
# empty rows on top for it (the feet rule keeps its lowest part on the bottom row).
HOVER_BOB = (0.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 0.0)
# Per frame: a "flap" part's tip drop as a share of its `amp` px (+ = down): two wingbeats
# per cycle, from the still's raised wings down and back.
FLAP = (0.0, 0.5, 1.0, 0.5, 0.0, 0.5, 1.0, 0.5)
# Per frame: a "spin" part's width as a share of its full span from the hub (a rotor blade
# seen edge-on foreshortens as it turns: full, shorter, almost gone, shorter): two turns
# per cycle.
SPIN = (1.0, 0.6, 0.3, 0.6, 1.0, 0.6, 0.3, 0.6)
# Stride mode (owner's Act IV art review, round 1, on the Bronze Titan: "his pose isn't going to
# work for this kind of animation; mirror his legs so it looks like he's walking"). Per frame:
# how far the near leg has swung from its forward pose (0, the still's leg) to its backward pose
# (1, the same leg mirrored about its hip): a cosine, back at frame 4, forward again at frame 8.
# The far leg runs half a cycle behind, so the legs really alternate instead of closing and opening.
STRIDE_SWING = tuple((1.0 - float(np.cos(2.0 * np.pi * f / 8))) / 2.0 for f in range(8))
# Per frame: share of the rig's `lift` each leg is raised while it swings forward (the near leg
# on the second step, the far leg on the first).
STRIDE_LIFT_NEAR = (0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 1.0, 0.5)
STRIDE_LIFT_FAR = (0.0, 0.5, 1.0, 0.5, 0.0, 0.0, 0.0, 0.0)
# The far leg is the near leg one shade darker (it is farther from the light and the camera, and
# the mirrored pose's rim light would otherwise sit on the wrong side): palette name -> darker name.
STRIDE_FAR_SHADE = {"bronze_light": "bronze", "bronze": "bronze_dark", "marble_light": "marble", "marble": "marble_dark"}

# Rigs: how each still is cut. Columns and rows are art px in the still (x from
# the left, y from the top; ranges are [start, end) ). Keys:
#   mode    "legs" (two legs), "robe" (one hem layer), "stride" (see `stride`) or "hover" (a flyer: the whole
#           sprite bobs, HOVER_BOB, and only its `parts` move: wings flap, rotors spin).
#   bob     px the sprite rises at the top of the bob ("hover").
#   parts   "hover": list of moving parts, each a dict: `box` (x0, x1, y0, y1) of the still
#           holding it, optional `colors` (palette names: only those pixels of the box are
#           the part, so a rotor can be lifted off the flame behind it), `kind` "flap" (each
#           column drops FLAP * `amp` px times its distance from the `root` column over the
#           box's farthest column: a wing hinged at `root`) or "spin" (the part squeezed
#           toward the `root` column, the hub, to SPIN of its width). Parts are taken out of
#           the body, moved and laid back on top; pixels are only moved, never recoloured.
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
#   stride  mode "stride" (a figure whose still pose cannot be sheared into a walk: the Bronze
#           Titan): the rows from `hip` down are cut off, except the `keep` rectangles
#           (x0, x1, y0, y1; low fists) which ride with the body; the pixels from `hip` down at
#           columns >= `near_x0` (outside `keep`) are the near leg, the forward pose; its mirror
#           image about its own hip (the middle of its top row) is the backward pose. Each frame
#           blends the two by STRIDE_SWING: the nearer pose, sheared about the hip row toward
#           the other (at most half the distance between the two feet, so the shear stays small);
#           the far leg is the same leg darkened (STRIDE_FAR_SHADE), `far_dx` px aside, half a
#           cycle behind and drawn behind it; the leg swinging forward is lifted STRIDE_LIFT_* *
#           `lift` px; `reach` px pushes both poses' feet further apart (a longer stride); the
#           body dips like the legs mode. Frame 0 is the stride, NOT the still (the
#           still is approved as it stands; the strip plays only while the unit walks).
#   swing   optional (x0, x1, y0, y1, pivot_y, px): a hanging part (the Harbourmaster's
#           anchor) in the still's box [x0, x1) x [y0, y1) that swings like a pendulum from
#           row `pivot_y` (where it is held): each frame its rows slide sideways SWING * px at
#           its bottom row, proportionally less toward the pivot (a shear, so rows move intact
#           and every pixel stays an approved one), and it is laid back on top (_swing()).
#   bust    optional (x0, x1, y0, y1, px): the box of the still holding the bust (art px,
#           [start, end) ; y0 = the neckline, y1 - 1 = the underside) and the bounce in
#           px at its strongest point. Each frame warps that box vertically (_bounce): the
#           neckline stays, the underside moves BUST_BOUNCE * px at the box's centre column,
#           less toward its sides, fading out below it. Pixels are only moved, never
#           recoloured, so every pixel stays an approved one. An optional sixth field
#           `lobes` (default 1) = 2 puts one bell under each side instead of one across the
#           box (each side peaks at its own centre, the cleavage stays): for a wide bust whose
#           outer sides barely moved under one bell (owner's art review, round 2).
#   bust_axis  optional "y" (default: the up-and-down bounce above) or "x": the same box and
#           field moves sideways instead (each pixel takes the pixel |d| columns aside in its
#           own row; + = right, the facing side), timed by BUST_SWAY in the walk (the kick
#           changes side every step) and IDLE_BUST in the idle (one way on the exhale, the
#           other on the inhale). For a box on the hips (the Amazon, art review round 2).
#   swish   optional (x0, x1, y0, y1, px): a second sideways box (a skirt's front drape), applied
#           after the bust box through the same _bounce() field on axis "x", timed by SWISH_SWAY
#           in the walk and SWISH_IDLE in the idle (each one frame behind the hips). It may
#           reach below the hip / waist: the idle's waist check skips its columns there.
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
    # Redesigned figures (owner request, Oct 2026): the bust box bounces (BUST_BOUNCE). The
    # Wither Witch's box starts right of her near arm so the arm never shakes.
    "player/soulbinder": dict(mode="legs", hip=54, back=(0, 24), front=(24, 44), rigid=[], spread=1, lift=1, dip=1, bust=(19, 30, 20, 27, 2)),
    "player/wither_witch": dict(mode="legs", hip=40, back=(0, 18), front=(18, 26), rigid=[(26, 36, 0, None)], spread=1, lift=1, dip=1, bust=(16, 24, 15, 21, 2)),
    # Seraphine floats: her "walk" is a glide (robe hem sway, the body bob, the bust bounce).
    # The still's relic staff stays rigid down to row 90, where it meets the robe.
    "bosses/seraphine": dict(mode="robe", hip=70, rigid=[(68, 98, 0, 90)], sway=2, dip=1, bust=(42, 64, 44, 58, 3)),
    "bosses/seraphine_avatar": dict(mode="robe", hip=106, rigid=[], sway=2, dip=1, bust=(74, 97, 61, 78, 3)),
    # The floating Banshee and Keening Lady (figure redesign): a glide like Seraphine's.
    "summons/banshee": dict(mode="robe", hip=24, rigid=[], sway=2, dip=1, bust=(18, 29, 12, 18, 2)),
    "summons/keening_lady": dict(mode="robe", hip=26, rigid=[], sway=2, dip=1, bust=(19, 30, 13, 19, 2)),
    "player/grave_herald": dict(mode="legs", hip=53, back=(0, 24), front=(24, 46), rigid=[], spread=1, lift=1, dip=1),
    # Later units with long screen time: the walking summon evolutions and two March soldiers.
    "summons/death_knight": dict(mode="legs", hip=41, back=(0, 25), front=(25, 54), rigid=[], spread=2, lift=2, dip=1),
    "summons/gravebow": dict(mode="legs", hip=42, back=(0, 22), front=(22, 33), rigid=[(33, 52, 0, None)], spread=2, lift=2, dip=1),
    "summons/shadow_reaper": dict(mode="legs", hip=40, back=(0, 24), front=(24, 43), rigid=[(43, 50, 0, None)], spread=2, lift=2, dip=1),
    "summons/hellhound": dict(mode="legs", hip=25, back=(0, 30), front=(30, 60), rigid=[(47, 60, 0, 27)], spread=2, lift=1, dip=1),
    "enemies/templar": dict(mode="legs", hip=69, back=(0, 18), front=(18, 36), rigid=[(28, 32, 0, 72), (0, 7, 0, 72)], spread=2, lift=2, dip=1),
    "enemies/banner_bearer": dict(mode="legs", hip=75, back=(0, 16), front=(16, 40), rigid=[(27, 31, 0, 79)], spread=2, lift=2, dip=1),
    "enemies/battle_sister": dict(mode="legs", hip=38, back=(0, 15), front=(15, 24), rigid=[(24, 36, 0, None)], spread=1, lift=1, dip=1, bust=(14, 22, 11, 17, 2)),
    # --- Act II: Fallen Seraph --- (figure redesign; she hovers: a glide like the Banshee's).
    # The near wing hangs below the hip, so its columns ride with the body (rigid).
    "summons/fallen_seraph": dict(mode="robe", hip=25, rigid=[(24, 36, 0, 40)], sway=2, dip=1, bust=(13, 23, 15, 22, 2)),
    "summons/ruin_seraph": dict(mode="robe", hip=29, rigid=[(30, 44, 0, 40), (0, 10, 0, 32)], sway=2, dip=1, bust=(18, 28, 18, 25, 2)),
    # --- Act II: the Ancient Eye's shared kinds (harbour placeholder art pass) ---
    # The Initiate shuffles on two bare feet under its ragged hem; the Chanter's robe sways,
    # its tall eye staff rigid.
    "eye/eye_initiate": dict(mode="legs", hip=37, back=(8, 19), front=(19, 30), rigid=[], spread=1, lift=1, dip=1),
    "eye/eye_chanter": dict(mode="robe", hip=47, rigid=[(0, 13, 0, None)], sway=1, dip=1),
    # --- Act II: Gullhaven Harbour ---
    # The Deep Kin's long arms hang below the hip: rigid, so the claws ride with the body.
    "eye/deep_kin": dict(mode="legs", hip=44, back=(4, 18), front=(18, 30), rigid=[(0, 6, 0, None), (30, 38, 0, None)], spread=2, lift=1, dip=1),
    # Harbour placeholder art pass: the Herald's hanging claws and the Harbourmaster's anchor
    # (and his far coat tail) ride with the body; only the legs step.
    "eye/deep_herald": dict(mode="legs", hip=48, back=(8, 26), front=(26, 46), rigid=[(0, 8, 0, None), (46, 54, 0, None)], spread=2, lift=1, dip=1),
    # Owner's review (round 2): the anchor swings back and forth from his fist (row 76).
    "eye/harbourmaster": dict(mode="legs", hip=100, back=(50, 82), front=(82, 120), rigid=[(0, 50, 0, None), (120, 132, 0, None)], spread=2, lift=2, dip=1,
                              swing=(0, 46, 75, 124, 76, 5)),
    "eye/netcaster": dict(mode="legs", hip=43, back=(8, 21), front=(21, 33), rigid=[(33, 44, 0, None)], spread=2, lift=1, dip=1),
    # Figure redesign: the Tide Caller and the Brine Widow glide on their gowns (hem sway),
    # the staff rigid, with the bust bounce and (bust rigs) an idle breathing strip.
    "eye/tide_caller": dict(mode="robe", hip=40, rigid=[(25, 36, 0, None)], sway=1, dip=1, bust=(15, 24, 16, 22, 2)),
    "player/brine_widow": dict(mode="robe", hip=44, rigid=[(37, 52, 0, None)], sway=1, dip=1, bust=(22, 34, 20, 27, 2)),
    # --- Act II: the Hollow Archive ---
    # The robed Scribe and Pilgrim shuffle on their hems (the Pilgrim's staff stays rigid);
    # the Ink Wraith glides (its dripping tail sways); the Heretic Scribe walks like the
    # other robed characters, his quill-staff rigid.
    "eye/scribe": dict(mode="robe", hip=32, rigid=[], sway=1, dip=1),
    "eye/spore_pilgrim": dict(mode="robe", hip=40, rigid=[(29, 36, 0, None)], sway=1, dip=1),
    "eye/ink_wraith": dict(mode="robe", hip=26, rigid=[], sway=2, dip=1),
    "player/heretic_scribe": dict(mode="legs", hip=48, back=(0, 22), front=(22, 33), rigid=[(33, 44, 0, None)], spread=1, lift=1, dip=1),
    # --- Act II: Ul-Thalos ---
    # The Siren floats (a kelp hem, robe); the Tide Widow's gown is a robe with her staff rigid;
    # the Spawns crawl (their tentacle skirts sway like a hem).
    "eye/eye_siren": dict(mode="robe", hip=32, rigid=[], sway=2, dip=1, bust=(23, 32, 11, 19, 2)),  # Bust box raised after the owner's art review (was rows 17-25, too low).
    "eye/eye_hierophant": dict(mode="robe", hip=46, rigid=[(26, 38, 0, None)], sway=2, dip=1),
    "eye/eye_spawn": dict(mode="robe", hip=50, rigid=[], sway=2, dip=1),
    "eye/eye_waking_horror": dict(mode="legs", hip=52, back=(0, 33), front=(33, 62), rigid=[], spread=2, lift=2, dip=1),
    "summons/spawn_of_the_deep": dict(mode="robe", hip=46, rigid=[], sway=2, dip=1),
    "summons/leviathan": dict(mode="robe", hip=58, rigid=[], sway=2, dip=1),
    "summons/drowned_thrall_ally": dict(mode="legs", hip=34, back=(0, 17), front=(17, 36), rigid=[], spread=2, lift=1, dip=1),
    "player/tide_widow": dict(mode="robe", hip=35, rigid=[(30, 44, 0, None)], sway=2, dip=1, bust=(21, 30, 18, 26, 2)),
    # --- Content wave 2: Bone Golem ---
    # Heavy stumping legs (short spread and lift); both huge low fists hang below the hip
    # and ride with the body (rigid), so only the two stumps step.
    # Wave 2 art review (the huge-skull redo): the jaw ends above the hip; each low fist hangs
    # over its leg's top, so the fist is a rigid box down to the foot, then a narrower box beside it.
    "summons/bone_golem": dict(mode="legs", hip=60, back=(0, 43), front=(43, 84), rigid=[(0, 29, 60, 71), (0, 23, 71, None), (61, 84, 60, 70)], spread=2, lift=2, dip=1),
    "summons/ossuary_titan": dict(mode="legs", hip=80, back=(0, 58), front=(58, 108), rigid=[(0, 34, 80, 93), (0, 28, 93, None), (86, 108, 80, None)], spread=2, lift=2, dip=1),
    # --- Act III: the Electronic Empire (the shared kinds) ---
    # The Line Trooper marches (its levelled rifle ends above the hip, so it rides with the
    # body); the Spotter walks under its long coat (the hem ends above the hip, only the
    # chrome legs step); the Scout Drone hovers (owner's art review, round 1: "it flies, its
    # walk should just be a bob": the whole drone bobs 2 px, nothing else moves). The Grave
    # Gunner (round 1 redo: its own drawing, a skull-faced iron trooper) marches like the Trooper.
    "empire/line_trooper": dict(mode="legs", hip=27, back=(0, 23), front=(23, 48), rigid=[], spread=2, lift=2, dip=1),
    "empire/spotter": dict(mode="legs", hip=41, back=(0, 28), front=(28, 62), rigid=[], spread=2, lift=2, dip=1),
    "empire/scout_drone": dict(mode="hover", bob=2, parts=[]),
    "empire/kill_drone": dict(mode="hover", bob=2, parts=[]),  # Act III missing sprites: the Purge Protocol's drone bobs like the Scout Drone
    "summons/grave_gunner": dict(mode="legs", hip=27, back=(0, 24), front=(24, 48), rigid=[], spread=2, lift=2, dip=1),
    # --- Act III: the Assembly Halls ---
    # The Arc Engineer and the Juggernaut march on their legs (the emitter / flamethrower ride
    # with the body); the Beta Build stalks on its long frame legs (its low left hand ends above
    # the hip). The two drone summons hover (owner's art review, round 1): the Grave Drone bobs
    # and beats its two crossed-bone wings (hinged at the skull), the Wraith Drone bobs and
    # spins its three bone rotors (only the bone pixels, lifted off the flame). The Marionette
    # and her three skins glide in their long gowns (figure redesign: bust bounce, idle breathing), the puppet strings
    # above the hip ride with the body.
    "empire/arc_engineer": dict(mode="legs", hip=30, back=(0, 25), front=(25, 52), rigid=[], spread=2, lift=2, dip=1),
    "empire/juggernaut": dict(mode="legs", hip=31, back=(0, 31), front=(31, 66), rigid=[], spread=2, lift=2, dip=1),
    "empire/beta_build": dict(mode="legs", hip=69, back=(0, 55), front=(55, 102), rigid=[], spread=3, lift=3, dip=1),
    "summons/grave_drone": dict(mode="hover", bob=2, parts=[
        dict(kind="flap", box=(0, 13, 0, 20), root=13, amp=4),
        dict(kind="flap", box=(28, 38, 0, 18), root=27, amp=4)]),
    "summons/wraith_drone": dict(mode="hover", bob=2, parts=[
        dict(kind="spin", box=(13, 25, 2, 12), root=18, colors=["ink_warm", "bone_shade", "bone_mid", "bone", "brown", "brown_light", "ink_cold", "grey_light"]),
        dict(kind="spin", box=(3, 18, 12, 23), root=12, colors=["ink_warm", "bone_shade", "bone_mid", "bone", "brown", "brown_light", "ink_cold", "grey_light"]),
        dict(kind="spin", box=(26, 38, 8, 18), root=31, colors=["ink_warm", "bone_shade", "bone_mid", "bone", "brown", "brown_light", "ink_cold", "grey_light"])]),
    "player/marionette": dict(mode="robe", hip=31, rigid=[], sway=2, dip=1, bust=(18, 30, 14, 21, 2, 2)),  # Round 1 redo: redrawn with a larger bust and a plunging neckline; box on it (two lobes).
    "player/marionette_hyper": dict(mode="robe", hip=33, rigid=[], sway=2, dip=1, bust=(12, 26, 17, 24, 2)),
    "player/marionette_untouchable": dict(mode="robe", hip=31, rigid=[], sway=2, dip=1, bust=(14, 24, 14, 20, 2, 2)),  # Round 1 redo: bust repainted larger; box raised onto it (was rows 15-21, "too low").
    "player/marionette_deathlord": dict(mode="robe", hip=35, rigid=[], sway=2, dip=1, bust=(19, 30, 16, 21, 2, 2)),  # Round 1 redo: box raised off the belt (rows 23-26) onto the bust (was rows 17-24).
    # --- Act III: the Scrap Wastes ---
    # The Aegis Bot walks behind its shield (the shield's columns ride with the body); the
    # Mortar Walker and the Trojan Horse step their four legs as two pairs (left and right
    # halves); Kestrel walks on her legs, the rifle and the raised blade above the hip ride with
    # the body (the low blade is rigid), the bust bounces (figure redesign); the
    # Lightning Abbess glides on her habit like the Tide Widow, her crescent staff rigid.
    "empire/aegis_bot": dict(mode="legs", hip=30, back=(0, 16), front=(16, 30), rigid=[(30, 40, 0, None)], spread=2, lift=1, dip=1),
    "empire/mortar_walker": dict(mode="legs", hip=28, back=(0, 32), front=(32, 60), rigid=[], spread=2, lift=1, dip=1),
    # Round 1 redo (three-quarter front view): the hind pair at the left, the front pair at the
    # right; the red chest plate hanging over the near foreleg rides with the body.
    "empire/trojan_horse": dict(mode="legs", hip=64, back=(0, 47), front=(47, 108), rigid=[(62, 84, 64, 71)], spread=2, lift=2, dip=1),
    "empire/trojan_horse_split": dict(mode="legs", hip=64, back=(0, 47), front=(47, 108), rigid=[(62, 84, 64, 71)], spread=2, lift=2, dip=1),
    # Round 1 redo (owner's Act III art review): Kestrel redrawn pear-shaped (wide hips, full rear,
    # the cape ends at the waist); the crotch tab between her legs rides with the body; both bust
    # boxes span the two lobes (two bells), the still's further right and the blades pose's further
    # left than before ("the jiggle needs to extend").
    "bosses/kestrel": dict(mode="legs", hip=88, back=(0, 68), front=(79, 144), rigid=[(68, 79, 88, 94)], spread=2, lift=2, dip=1, bust=(64, 88, 24, 38, 2, 2)),
    "bosses/kestrel_blades": dict(mode="legs", hip=82, back=(0, 61), front=(61, 120), rigid=[(94, 120, 0, 100)], spread=2, lift=2, dip=1, bust=(44, 72, 38, 51, 2, 2)),  # Round 2 redo: legs split at col 61 (was 60): the thicker back thigh reaches col 60.
    "player/lightning_abbess": dict(mode="robe", hip=38, rigid=[(29, 44, 0, None)], sway=2, dip=1, bust=(20, 31, 18, 25, 2)),  # Round 1 redo: box 2 px right (was cols 18-28).
    # --- Act III: the Iron Citadel ---
    # The two Valkyries are in the figure-redesign style (bust bounce + idle breathing); Valkyrie
    # 2.0's blade arm (left) and tower shield (right) hang below the hip and move with the body.
    # The Rust Prophet walks in his robe, the scrap staff rigid; the revenants stomp on two legs.
    "empire/valkyrie_duelist": dict(mode="legs", hip=32, back=(0, 27), front=(27, 52), rigid=[], spread=2, lift=2, dip=1, bust=(22, 34, 13, 21, 2)),
    # Round 2 redo ("her feet split"): the blade (cols 0-10) and shield (cols 49-75) are rigid only down to
    # row 85, where they end; below it the legs own every column, so the toes (cols 6-13 and 52-55, which the
    # old full-height rigid columns 0-14 / 52-76 held still while the rest of the foot moved) stay whole.
    "empire/valkyrie_prime": dict(mode="legs", hip=70, back=(0, 36), front=(36, 76), rigid=[(0, 11, 0, 86), (49, 76, 0, 86)], spread=2, lift=3, dip=1, bust=(28, 44, 27, 39, 3, 2)),  # Round 1 redo: box raised onto the whole breastplate (was rows 30-39, cols 28-45: "extend upward").
    "player/rust_prophet": dict(mode="robe", hip=40, rigid=[(30, 42, 0, None)], sway=1, dip=1),
    "summons/iron_revenant": dict(mode="legs", hip=34, back=(0, 26), front=(26, 58), rigid=[], spread=2, lift=2, dip=1),
    "summons/deus_revenant": dict(mode="legs", hip=44, back=(0, 27), front=(27, 66), rigid=[], spread=2, lift=2, dip=1),  # Round 1 redo (simpler drawing).
    # --- Act IV: the Olympian Republic (the shared kinds) ---
    # The Shade of the Dead hovers (a ghost: the whole sprite bobs 2 px, nothing steps; the
    # still keeps two empty rows on top). The Hoplite marches, his upright spear (cols 2-5)
    # rigid; the Hero strides, the low hem of his blue cloak (left of his back leg) rigid; the
    # Bronze Titan stomps, both huge low fists hanging below the hip ride with the body.
    "pantheon/shade_of_dead": dict(mode="hover", bob=2, parts=[]),
    "pantheon/shade_archer": dict(mode="hover", bob=2, parts=[]),  # a ghost archer: the whole sprite bobs, bow and all
    "pantheon/hoplite": dict(mode="legs", hip=42, back=(0, 17), front=(17, 30), rigid=[(2, 6, 0, None)], spread=2, lift=2, dip=1),
    "pantheon/hero": dict(mode="legs", hip=41, back=(0, 31), front=(31, 58), rigid=[(0, 17, 41, 48)], spread=2, lift=2, dip=1),
    # Owner's Act IV art review, round 2: the round 1 stride (his crossed legs mirrored) did not
    # read ("not even close"). Round 3: a new still of the same titan with his legs apart (crotch
    # at row 64), walked by the normal legs rig; both low fists (rows 64-69) ride with the body.
    "pantheon/bronze_titan": dict(mode="legs", hip=64, back=(0, 40), front=(40, 74), rigid=[(0, 21, 64, 70), (56, 74, 64, 70)], spread=3, lift=4, dip=1),
    # --- Act IV: the Shores of Ilion ---
    # The Legionary marches behind his scutum (it ends above the hip); the Wolf of Rome lopes
    # (hind legs left, forelegs right: the bounding lope of the Bone Hound's rig); the Cyclops and
    # Polyphemus stomp (short spread, a big lift); Achilles strides with his spear rigid (cols 0-13)
    # and his rage form strides wide. The Doomed Prophetess glides in her long peplos (robe: hem
    # sway, the tall bone bow rigid, bust bounce and idle breathing). The siege tower rolls (no strip).
    "pantheon/legionary": dict(mode="legs", hip=41, back=(0, 15), front=(15, 32), rigid=[], spread=2, lift=2, dip=1),
    "pantheon/wolf_of_rome": dict(mode="legs", hip=19, back=(0, 30), front=(30, 68), rigid=[], spread=3, lift=2, dip=1),
    "pantheon/cyclops": dict(mode="legs", hip=53, back=(0, 25), front=(25, 56), rigid=[], spread=2, lift=3, dip=1),
    "pantheon/polyphemus": dict(mode="legs", hip=88, back=(0, 30), front=(30, 60), rigid=[], spread=2, lift=3, dip=1),
    "bosses/achilles": dict(mode="legs", hip=91, back=(14, 33), front=(33, 64), rigid=[(0, 14, 0, None)], spread=2, lift=2, dip=1),
    "bosses/achilles_rage": dict(mode="legs", hip=90, back=(0, 46), front=(46, 92), rigid=[], spread=2, lift=2, dip=1),
    "player/doomed_prophetess": dict(mode="robe", hip=36, rigid=[(27, 36, 0, None)], sway=2, dip=1, bust=(16, 26, 15, 22, 2)),
    # --- Act IV: Mount Olympus ---
    # Ares's spear tip (right of his front leg) rides with the body; Artemis, the Amazon and the
    # Gorgon have the bust bounce (figure redesign); the centaur and the hound step their legs as
    # two pairs (left and right halves); robes and tails sway (Zeus, Poseidon with his trident
    # rigid, the Gorgon, the sea serpent, the Oathbreaker's cloak).
    "pantheon/ares": dict(mode="legs", hip=70, back=(0, 45), front=(45, 70), rigid=[(70, 94, 66, None)], spread=2, lift=2, dip=1),
    # Art review round 1 redo (slim-thick, muscular; the old box sat on her bow): the bust box on
    # her chest (cols 23-37, rows 31-39, two lobes), the bow's lower limb right of her front leg rigid.
    "pantheon/artemis": dict(mode="legs", hip=60, back=(0, 31), front=(31, 62), rigid=[(46, 62, 0, 64)], spread=2, lift=2, dip=1, bust=(23, 38, 31, 40, 2, 2)),
    "pantheon/poseidon": dict(mode="robe", hip=75, rigid=[(52, 68, 0, None)], sway=1, dip=1),
    "pantheon/centaur_archer": dict(mode="legs", hip=41, back=(0, 26), front=(26, 54), rigid=[], spread=2, lift=2, dip=1),
    # Art review round 1 redo ("muscle mommy"; the owner liked her idle jiggling the hips, not the
    # bust): the bounce box sits on her hips and skirt (cols 18-37, rows 27-37, two lobes); the
    # skirt's front flap hanging between her thighs rigid. Round 2 ("jiggling side to side rather
    # than up and down"): the box sways sideways (`bust_axis="x"`, BUST_SWAY / IDLE_BUST) as one
    # mass (one bell: two lobes swaying the same way tore the skirt at the centre column). Round 4
    # (the narrow front flap between bare thighs read as a crotch): the still's skirt covers both
    # thighs down to a flat hem (row 40), the flap is gone; only the hem's ink row (41) rides rigid.
    # Round 5 (owner: the skirt too long; regenerated as a bigger, curvier "muscle mommy", 70 tall,
    # 66 wide). Round 6 ("too boxy... it should swish in front of her, and show off her thighs"): the
    # skirt is two short flared side flaps (hems rows 39-41) and a wide front panel (cols 26-41) hanging
    # to row 46 over the crotch. Hip 42 (the thighs under the flaps walk); the panel below the hip
    # rides with the body (per-column rigid rects down to its ink row, so it always covers where the
    # thighs meet); the shield's foot rigid. The hip box sways on the skirt (rows 35-38, fading to 41)
    # and the `swish` box carries the skirt one frame behind it, growing from the belt to the panel's hem (rows 35-45, fading below), so the pleats bend smoothly.
    # Round 7 (owner: "start again with fresh generation... the original style, a bit stronger and more
    # voluptuous, a bit scandalous"): a new still, 64x70. Hip 46 (just under the skirt's front hem and its
    # ink row, so the whole skirt rides with the body and never tears), legs split at col 33 (the gap
    # between the thighs), the shield's foot rigid; the hip box sways sideways on the skirt over her hips
    # (cols 22-42, rows 36-42, as the owner liked) and the `swish` box carries the hem one frame behind.
    # Round 7 (owner: "at this level, we should get a bounce box on her chest as well"): the `bust` box
    # bounces the bronze top (cols 28-41, rows 23-31, two lobes) and the hips' sideways sway the owner
    # liked moved to the `swish` box over the skirt (cols 22-42, rows 36-45, 2 px).
    "pantheon/amazon": dict(mode="legs", hip=46, back=(0, 33), front=(33, 64), rigid=[(0, 22, 46, 51)],
                            spread=2, lift=2, dip=1, bust=(28, 41, 23, 31, 2, 2), swish=(22, 42, 36, 45, 2)),
    # Art review round 1 redo (slim-thick, a bit chubby; the old box sat too low): on her bust
    # (cols 21-31, rows 17-21, two lobes).
    "pantheon/gorgon": dict(mode="robe", hip=36, rigid=[], sway=2, dip=1, bust=(21, 32, 17, 22, 2, 2)),
    # Art review round 1 redo (regenerated, side view): hind legs left, forelegs right, the chin
    # just below the hip rigid.
    "pantheon/moon_hound": dict(mode="legs", hip=13, back=(0, 28), front=(28, 56), rigid=[(38, 56, 13, 16)], spread=2, lift=2, dip=1),
    "pantheon/sea_serpent": dict(mode="robe", hip=40, rigid=[], sway=2, dip=1),
    "bosses/zeus": dict(mode="robe", hip=93, rigid=[(0, 24, 0, None)], sway=1, dip=1),
    "bosses/zeus_colossus": dict(mode="legs", hip=141, back=(0, 82), front=(82, 164), rigid=[], spread=2, lift=3, dip=1),
    "player/oathbreaker": dict(mode="robe", hip=48, rigid=[], sway=1, dip=1),
    # --- Act IV: the Asphodel Underworld ---
    # Cerberus lopes on four legs (the hind pair left, the forelegs right; the flame tail and
    # the three heads above the hip ride with the body). Hades glides in his long robe, the
    # upright bident rigid. The Ferrywoman (figure redesign: bust bounce, idle breathing) glides
    # in her cloak, the oar and its lantern rigid. The Myrmidons march, the upright spear rigid,
    # the round shield (low on the front side) riding with the body.
    "pantheon/cerberus": dict(mode="legs", hip=66, back=(0, 48), front=(48, 94), rigid=[], spread=2, lift=2, dip=1),
    "bosses/hades": dict(mode="robe", hip=78, rigid=[(56, 70, 0, None)], sway=1, dip=1),  # Act IV art review round 4: back to the round 1 still (the bident on the right, cols 56-70), recoloured.
    "player/ferrywoman": dict(mode="robe", hip=34, rigid=[(32, 39, 0, None)], sway=2, dip=1, bust=(19, 31, 18, 25, 2)),  # Act IV art review round 1 redo: box 2 px right (was cols 19-29); round 2 redo: widened 2 px left (cols 19-31).
    # Act IV art review round 4: regenerated from the original prompt (24 wide): the spear (cols 0-4, to row 37) and the shield rigid.
    "summons/myrmidon_shade": dict(mode="legs", hip=34, back=(0, 10), front=(10, 24), rigid=[(0, 5, 0, 38), (12, 24, 20, 37)], spread=2, lift=2, dip=1),
    # Act IV art review round 4: regenerated (36 wide): the spear (cols 2-5, to the ground) and the shield rigid.
    "summons/legion_of_tartarus": dict(mode="legs", hip=41, back=(0, 15), front=(15, 36), rigid=[(2, 6, 0, None), (23, 36, 23, 46)], spread=2, lift=2, dip=1),
    # --- Act I walk strips (audit "walk strips" findings U01 - U03; GDD §15.0 "Act I walk strips") ---
    # The heavy summon bodies. The Abomination's two huge fists hang over the tops of its short
    # legs (rigid, down to where the feet start); the Colossus carries its club (right, rigid) and
    # steps on two bone legs.
    "summons/abomination": dict(mode="legs", hip=66, back=(0, 45), front=(45, 88), rigid=[(0, 35, 66, 78), (66, 88, 66, 80)], spread=3, lift=2, dip=1),
    "summons/bone_colossus": dict(mode="legs", hip=70, back=(0, 46), front=(46, 76), rigid=[(76, 98, 70, None), (41, 49, 70, 86)], spread=2, lift=2, dip=1),
    # The two siege carts roll: no wheel can turn without being redrawn, so the cart rocks over
    # the ground instead (spread 0: the wheels stay put; the body dips and each side's wheels
    # take turns riding up a bump, lift 1).
    "summons/corpse_catapult": dict(mode="legs", hip=38, back=(0, 24), front=(24, 68), rigid=[], spread=0, lift=1, dip=1),
    "summons/ossuary_engine": dict(mode="legs", hip=48, back=(0, 32), front=(32, 78), rigid=[], spread=0, lift=1, dip=1),
    # The winged stone summons flap (hover mode with no body bob: the stills' wing tips touch the
    # top row, so there is no room to rise; the wing tips drop and rise instead).
    "summons/gargoyle": dict(mode="hover", bob=0, parts=[
        dict(kind="flap", box=(0, 18, 0, 31), root=18, amp=4)]),
    "summons/cathedral_horror": dict(mode="hover", bob=0, parts=[
        dict(kind="flap", box=(0, 30, 0, 36), root=30, amp=5),
        dict(kind="flap", box=(54, 72, 0, 38), root=54, amp=5)]),
    # The two ghosts glide on their ragged hems (like the Banshee).
    "summons/frost_wraith": dict(mode="robe", hip=30, rigid=[], sway=2, dip=1),
    "summons/winter_revenant": dict(mode="robe", hip=34, rigid=[], sway=2, dip=1),
    # The robed priests walk on their hem lobes like the Mender and Warder, staff rigid.
    "summons/bishop": dict(mode="legs", hip=44, back=(0, 24), front=(24, 34), rigid=[(34, 46, 0, None)], spread=1, lift=1, dip=1),
    "summons/lich": dict(mode="legs", hip=36, back=(0, 23), front=(23, 34), rigid=[(34, 42, 0, None)], spread=1, lift=1, dip=1),
    # Sanctum Covenant kinds.
    "enemies/sanctified_sentinel": dict(mode="legs", hip=48, back=(0, 36), front=(36, 78), rigid=[(34, 42, 48, None)], spread=2, lift=2, dip=1),
    "enemies/radiant_inquisitor": dict(mode="legs", hip=48, back=(0, 26), front=(26, 50), rigid=[], spread=1, lift=1, dip=1),
    "enemies/high_confessor": dict(mode="legs", hip=48, back=(0, 24), front=(24, 34), rigid=[(34, 48, 0, None)], spread=1, lift=1, dip=1),
    "enemies/sun_paladin": dict(mode="legs", hip=52, back=(9, 21), front=(21, 34), rigid=[(0, 9, 0, None), (22, 33, 52, 57)], spread=1, lift=1, dip=1),
    "enemies/cathedral_guardian": dict(mode="legs", hip=106, back=(0, 56), front=(56, 112), rigid=[], spread=3, lift=2, dip=1),
    # The Reckoning Inquisitor and the first two stage bosses.
    "enemies/inquisitor": dict(mode="legs", hip=46, back=(0, 24), front=(24, 48), rigid=[], spread=1, lift=1, dip=1),
    "bosses/alaric": dict(mode="legs", hip=78, back=(0, 86), front=(110, 174), rigid=[(0, 54, 78, 102), (86, 110, 78, None)], spread=2, lift=2, dip=1),
    "bosses/vael": dict(mode="legs", hip=70, back=(0, 50), front=(50, 120), rigid=[(46, 94, 70, 106)], spread=2, lift=2, dip=1),
    # --- Act V: the Shogunate of the Rising Sun (the shared kinds) ---
    # The Ashigaru marches with his long yari (cols 3-5, the whole height) rigid; the Samurai strides, hand on his hilt (all
    # above the hip); the Teppo Gunner shuffles under his level arquebus (above the hip); the Ninja creeps low (long diagonal
    # legs); the Onryo glides (the whole ghost bobs 2 px; the still keeps two empty rows on top, no bust: a ghost, not the
    # figure-redesign style); the Oni stomps, his iron kanabo (held low across the front) riding with the body above the hip.
    "shogunate/ashigaru": dict(mode="legs", hip=39, back=(0, 13), front=(13, 22), rigid=[(3, 6, 0, None)], spread=2, lift=2, dip=1),
    "shogunate/samurai": dict(mode="legs", hip=40, back=(0, 23), front=(23, 52), rigid=[], spread=2, lift=2, dip=1),
    "shogunate/teppo_gunner": dict(mode="legs", hip=33, back=(0, 32), front=(32, 62), rigid=[], spread=2, lift=2, dip=1),
    "shogunate/ninja": dict(mode="legs", hip=28, back=(0, 18), front=(18, 36), rigid=[], spread=2, lift=2, dip=1),
    "shogunate/onryo": dict(mode="hover", bob=2, parts=[]),
    "shogunate/oni": dict(mode="legs", hip=61, back=(0, 31), front=(31, 70), rigid=[], spread=3, lift=3, dip=1),
    # --- Act V: the Burning Province ---
    # The Kunoichi strides, a tanto in each hand (the blades riding with the body below the hip), with a bust box and
    # idle breathing (figure-redesign style); the Kappa scuttles, its reaching claw rigid; Shuten-doji stomps, his
    # spiked kanabo (cols 62+) riding with the body; Kage strides wide in her ready stance (bust box, idle breathing;
    # her clones wear the same strips); the Grave Kunoichi strides, her long scarf (cols 0-16) riding with the body.
    "shogunate/kunoichi": dict(mode="legs", hip=34, back=(12, 20), front=(20, 30), rigid=[(0, 12, 0, None), (30, 40, 0, None)], spread=1, lift=1, dip=1, bust=(16, 28, 14, 20, 2)),  # Round 1 redo: box 2 px to the right (was cols 16-26).
    "shogunate/kappa": dict(mode="legs", hip=24, back=(0, 14), front=(14, 24), rigid=[(24, 32, 0, None)], spread=1, lift=2, dip=1),
    "shogunate/shuten_doji": dict(mode="legs", hip=86, back=(0, 36), front=(36, 62), rigid=[(62, 94, 0, None)], spread=2, lift=3, dip=1),
    "bosses/kage": dict(mode="legs", hip=44, back=(0, 32), front=(32, 50), rigid=[(50, 66, 0, None)], spread=2, lift=2, dip=1, bust=(24, 37, 15, 23, 2)),  # Round 1 redo: box up and left onto the chest (was cols 27-40, rows 18-26).
    "player/grave_kunoichi": dict(mode="legs", hip=40, back=(17, 27), front=(27, 44), rigid=[(0, 17, 0, None)], spread=1, lift=1, dip=1, bust=(21, 34, 16, 23, 2)),  # Round 1 redo: box widened to the right (was cols 21-32; the three skins share it).
    # --- Act V: the Road to the Sun ---
    # The Sohei strides, the naginata (above the hip) riding with the body; the Kirin lopes on four legs (the hind
    # pair left, the forelegs right, like Cerberus); the Kitsune (figure redesign: bust bounce, idle breathing)
    # glides in her kimono; Amaterasu floats, her robe and sashes swaying (bust bounce, the mirror above the hip);
    # the Shrine Maiden of Night (figure redesign) glides in her hakama, the gohei above the hip; the Bound Oni and
    # the Oni Lord stomp, the tip of the kanabo (held low across the front) rigid.
    "shogunate/sohei": dict(mode="legs", hip=41, back=(0, 32), front=(32, 64), rigid=[], spread=2, lift=2, dip=1),
    "shogunate/kirin": dict(mode="legs", hip=64, back=(0, 63), front=(63, 104), rigid=[], spread=2, lift=2, dip=1),
    # Round 1 redo (owner: "make her bustier"): redrawn with a larger bust, rows 15-19 above the sash, cols 13-23 (two lobes).
    "shogunate/kitsune": dict(mode="robe", hip=34, rigid=[], sway=2, dip=1, bust=(9, 24, 13, 20, 1, 2)),
    # Round 1 redo (owner: "bounce box needs to go up and to the right"): she was redrawn fuller (more mature figure), her
    # chest now rows 32-42, cols 43-59 (two lobes, a gold collar between); the old box (cols 36-52, rows 34-45) sat low and left.
    "bosses/amaterasu": dict(mode="robe", hip=78, rigid=[], sway=1, dip=1, bust=(42, 60, 30, 43, 2, 2)),
    # Round 1 redo (owner: "extend two pixels to the right and go up two pixels"): the box was cols 17-27, rows 17-25, now cols 17-29, rows 15-23.
    "player/shrine_maiden": dict(mode="robe", hip=36, rigid=[], sway=2, dip=1, bust=(17, 29, 15, 23, 1)),
    "summons/bound_oni": dict(mode="legs", hip=50, back=(0, 26), front=(26, 54), rigid=[], spread=2, lift=2, dip=1),
    "summons/oni_lord": dict(mode="legs", hip=60, back=(0, 31), front=(31, 68), rigid=[], spread=2, lift=2, dip=1),
    # --- Act V: Castle Kurogane ---
    # The Hatamoto marches under his tall white banner (pole cols 22-28, the whole height, rigid); the Kiba-musha and the
    # General of the Left gallop (the horse's hind legs left, forelegs right; a wide spread and a high lift); Shogun
    # Kurogane strides under his crimson cloak (his duel pose bosses/shogun_duel is a still: no strip). The Ronin
    # Revenant walks in his tattered kimono and hakama (robe: the hem sways).
    "shogunate/hatamoto": dict(mode="legs", hip=61, back=(0, 12), front=(12, 22), rigid=[(22, 29, 0, None)], spread=2, lift=2, dip=1),
    "shogunate/kiba_musha": dict(mode="legs", hip=46, back=(0, 37), front=(37, 74), rigid=[], spread=3, lift=2, dip=1),
    "shogunate/general_left": dict(mode="legs", hip=77, back=(0, 60), front=(60, 110), rigid=[], spread=3, lift=3, dip=1),
    "bosses/shogun": dict(mode="legs", hip=94, back=(0, 64), front=(64, 116), rigid=[], spread=2, lift=2, dip=1),
    "player/ronin_revenant": dict(mode="robe", hip=50, rigid=[], sway=1, dip=1),
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
    "player/tide_widow_hyper": "player/tide_widow",  # --- Act II: Ul-Thalos ---
    # --- Wave 2 art review: the Untouchable and Deathlord skins (drawn art, every character) ---
    "player/gravecaller_untouchable": "player/necromancer",
    "player/gravecaller_deathlord": "player/necromancer",
    "player/umbral_warden_untouchable": "player/umbral_warden",
    "player/umbral_warden_deathlord": "player/umbral_warden",
    "player/voidcaller_untouchable": "player/voidcaller",
    "player/voidcaller_deathlord": "player/voidcaller",
    "player/bone_oracle_untouchable": "player/bone_oracle",
    "player/bone_oracle_deathlord": "player/bone_oracle",
    "player/fallen_confessor_untouchable": "player/fallen_confessor",
    "player/fallen_confessor_deathlord": "player/fallen_confessor",
    "player/carrion_lord_untouchable": "player/carrion_lord",
    "player/carrion_lord_deathlord": "player/carrion_lord",
    "player/plague_scholar_untouchable": "player/plague_scholar",
    "player/plague_scholar_deathlord": "player/plague_scholar",
    "player/doomsayer_untouchable": "player/doomsayer",
    "player/doomsayer_deathlord": "player/doomsayer",
    "player/barrow_warden_untouchable": "player/barrow_warden",
    "player/barrow_warden_deathlord": "player/barrow_warden",
    "player/grave_herald_untouchable": "player/grave_herald",
    "player/grave_herald_deathlord": "player/grave_herald",
    "player/soulbinder_untouchable": "player/soulbinder",
    "player/soulbinder_deathlord": "player/soulbinder",
    "player/wither_witch_untouchable": "player/wither_witch",
    "player/wither_witch_deathlord": "player/wither_witch",
    "player/brine_widow_untouchable": "player/brine_widow",
    "player/brine_widow_deathlord": "player/brine_widow",
    "player/heretic_scribe_untouchable": "player/heretic_scribe",
    "player/heretic_scribe_deathlord": "player/heretic_scribe",
    "player/tide_widow_untouchable": "player/tide_widow",
    "player/tide_widow_deathlord": "player/tide_widow",
    # --- Act III: the Scrap Wastes ---
    "player/lightning_abbess_hyper": "player/lightning_abbess",
    "player/lightning_abbess_untouchable": "player/lightning_abbess",
    "player/lightning_abbess_deathlord": "player/lightning_abbess",
    # --- Act III: the Iron Citadel ---
    "player/rust_prophet_hyper": "player/rust_prophet",
    "player/rust_prophet_untouchable": "player/rust_prophet",
    "player/rust_prophet_deathlord": "player/rust_prophet",
    # --- Act IV: the Shores of Ilion ---
    "player/doomed_prophetess_hyper": "player/doomed_prophetess",
    "player/doomed_prophetess_untouchable": "player/doomed_prophetess",
    "player/doomed_prophetess_deathlord": "player/doomed_prophetess",
    # --- Act IV: Mount Olympus ---
    "player/oathbreaker_hyper": "player/oathbreaker",
    "player/oathbreaker_untouchable": "player/oathbreaker",
    "player/oathbreaker_deathlord": "player/oathbreaker",
    # --- Act IV: the Asphodel Underworld ---
    "player/ferrywoman_hyper": "player/ferrywoman",
    "player/ferrywoman_untouchable": "player/ferrywoman",
    "player/ferrywoman_deathlord": "player/ferrywoman",
    # --- Act V: the Burning Province ---
    "player/grave_kunoichi_hyper": "player/grave_kunoichi",
    "player/grave_kunoichi_untouchable": "player/grave_kunoichi",
    "player/grave_kunoichi_deathlord": "player/grave_kunoichi",
    # --- Act V: the Road to the Sun ---
    "player/shrine_maiden_hyper": "player/shrine_maiden",
    "player/shrine_maiden_untouchable": "player/shrine_maiden",
    "player/shrine_maiden_deathlord": "player/shrine_maiden",
    # --- Act V: Castle Kurogane ---
    "player/ronin_revenant_hyper": "player/ronin_revenant",
    "player/ronin_revenant_untouchable": "player/ronin_revenant",
    "player/ronin_revenant_deathlord": "player/ronin_revenant",
}
# Per-skin field overrides of the derived rig (same keys as RIGS), set after review.
SKIN_FIX = {
    # --- Act V: the Burning Province --- (the Grave Kunoichi's skins)
    # Round 2 redo: the Hyper and Deathlord skins have their own box, the shared one (derived: cols 23-36, rows 18-25)
    # with 1 px less at the bottom (owner: "reduced like 1 pixel on the bottom"); the base keeps the approved shared box.
    # The Untouchable skin was redrawn (a ghost-white phantom): its bust sits at cols 19-30, rows 15-21.
    "player/grave_kunoichi_hyper": {"bust": (23, 36, 18, 24, 2)},
    "player/grave_kunoichi_deathlord": {"bust": (23, 36, 18, 24, 2)},
    "player/grave_kunoichi_untouchable": {"bust": (19, 31, 15, 22, 2)},
    # --- Act V: the Road to the Sun --- (the Shrine Maiden's skins: their own bust boxes)
    # Round 1 redo: the Hyper box up 5 px and 2 px wider to the right (was cols 18-28, rows 17-25; owner); the Untouchable skin
    # (a new entry) takes the same box, up 5 / right 2, which lands on its bust (rows 14-19) and stops above the teal bow;
    # the Deathlord skin was redrawn with fewer, bigger shapes, its bust sits under the chin (rows 18-22) right of the face.
    "player/shrine_maiden_hyper": {"bust": (18, 30, 12, 20, 1)},
    "player/shrine_maiden_untouchable": {"bust": (17, 29, 12, 20, 1)},
    "player/shrine_maiden_deathlord": {"bust": (15, 26, 18, 23, 1)},
    # --- Act IV: the Asphodel Underworld --- (the Ferrywoman's skins: their own oar column and bust box)
    "player/ferrywoman_hyper": {"rigid": [(28, 35, 0, None)], "bust": (17, 26, 17, 24, 2)},
    "player/ferrywoman_untouchable": {"rigid": [(28, 34, 0, None)], "bust": (17, 27, 17, 24, 2)},
    "player/ferrywoman_deathlord": {"rigid": [(29, 35, 0, None)], "bust": (16, 29, 19, 26, 2)},  # Round 1 redo: box 2 px right (was cols 18-27); round 2 redo: widened 4 px left (cols 16-29).
    # Act IV art review round 1 redo: the Doomed Prophetess's Hyper and Deathlord skins' boxes extend 2 px
    # further left (derived boxes were cols 14-24 and 17-27, both starting right of the bust's left edge).
    "player/doomed_prophetess_hyper": {"bust": (12, 24, 17, 24, 2)},
    "player/doomed_prophetess_deathlord": {"bust": (15, 27, 17, 24, 2)},
    # The Hyper gown's crown adds 2 rows on top but her bust sits no lower than the base
    # Tide Widow's, so the derived box (rows 20-28) landed on the waist (owner's art review).
    # Round 2: 2 px wider to the right and two lobes, so both sides bounce ("just one is bouncing").
    "player/tide_widow_hyper": {"bust": (19, 32, 17, 25, 2, 2)},
    # Wave 2 skins: the ghost witch's wisps widen her lower body to the left, so the derived box
    # (cols 18-26) sat right of her bust; her bust is cols 13-22, rows 17-23 of the still.
    "player/wither_witch_untouchable": {"bust": (13, 22, 17, 23, 2)},
    # The crowned widow's crown adds 2 rows, but her bust sits no lower than the base Brine
    # Widow's (like the Tide Widow's Hyper skin): the derived box (rows 22-29) was on the bodice.
    "player/brine_widow_deathlord": {"bust": (19, 31, 19, 26, 2)},
    # Owner's review round 2 ("she's jiggling her belt"): the derived box (rows 20-27) ended on
    # the gold belt (rows 25-26); her bust is rows 17-23, cols 19-28 of the still.
    "player/tide_widow_deathlord": {"bust": (19, 29, 17, 24, 2)},
    # Owner's review round 2: the Voidcaller's two skins are redrawn in the figure-redesign style
    # (her base sprite is not, so its rig has no bust box): a bust box each, two lobes so both
    # sides bounce (like the Tide Widow's Hyper skin), and idle strips.
    "player/voidcaller_untouchable": {"bust": (14, 25, 13, 20, 2, 2)},
    "player/voidcaller_deathlord": {"bust": (17, 29, 16, 22, 2, 2)},
    # Act III art review, round 1 redo: the ghost Abbess's derived box stopped short of the right
    # of her bust (cols 20-29, rows 18-24); the crowned Abbess's (cols 12-22, rows 20-26) sat low
    # and left, on the gold belt (row 26): her bust is cols 14-23, rows 17-23, the box ending above the belt ("up and to the right");
    # round 2 moved it 1 px right (cols 15-24: "a little bit more to the right, maybe 1 pixel").
    "player/lightning_abbess_untouchable": {"bust": (19, 31, 18, 25, 2)},
    # The Gilded Stormbride was redrawn simpler (round 1 redo, "too much detail"): her bust is
    # cols 13-22, rows 17-23, the box ending above the gold sash (row 26) and left of the staff.
    "player/lightning_abbess_hyper": {"bust": (13, 23, 17, 24, 2)},
    "player/lightning_abbess_deathlord": {"bust": (15, 27, 17, 24, 2)},  # Round 3 redo: 2 px wider to the right (was cols 15-24; round 2: 14-23).
}


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
        bx0, bx1, by0, by1, bpx = rig["bust"][:5]
        rig["bust"] = (*cols((bx0, bx1)), by0 + dy, by1 + dy, bpx, *rig["bust"][5:])
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


PALETTE_JSON = ROOT / "tools" / "palette.json"  # The locked palette (hover parts name their colours).


def _palette_rgb(names: list) -> list:
    """RGB tuples of palette colours `names` (tools/palette.json)."""
    import json
    hexes = {c["name"]: c["hex"] for c in json.loads(PALETTE_JSON.read_text())["colors"]}
    return [tuple(int(hexes[n][i:i + 2], 16) for i in (1, 3, 5)) for n in names]


def _part_mask(still: np.ndarray, part: dict) -> np.ndarray:
    """Pixels of hover part `part`: opaque pixels in its box (of its `colors` only, if set)."""
    h, w = still.shape[:2]
    x0, x1, y0, y1 = part["box"]
    m = np.zeros((h, w), dtype=bool)
    m[y0:y1, x0:x1] = still[y0:y1, x0:x1, 3] > 0
    if part.get("colors"):
        ok = np.zeros((h, w), dtype=bool)
        for c in _palette_rgb(part["colors"]):
            ok |= (still[:, :, :3] == np.array(c, dtype=np.uint8)).all(-1)
        m &= ok
    return m


def _move_part(layer: np.ndarray, part: dict, f: int) -> np.ndarray:
    """Hover part `layer` (only the part's pixels) posed for frame `f` (FLAP / SPIN), nearest
    inverse mapping so pixels are only moved, never blended or recoloured."""
    h, w = layer.shape[:2]
    out = np.zeros_like(layer)
    x0, x1 = part["box"][0], part["box"][1]
    root = part["root"]
    far = float(max(abs(x0 - root), abs(x1 - 1 - root), 1))  # Farthest column from the root.
    for x in range(w):
        if part["kind"] == "flap":
            d = int(round(FLAP[f] * part["amp"] * abs(x - root) / far))  # Rows this column drops.
            if d == 0:
                out[:, x] = layer[:, x]
            else:
                out[d:, x] = layer[:-d, x]
        else:  # "spin": column x shows the source column at its unsqueezed distance from the hub.
            k = SPIN[f]
            sx = int(np.floor(root + (x - root) / k + 0.5)) if k > 0 else root
            if 0 <= sx < w:
                out[:, x] = layer[:, sx]
    return out


def _shift_v(img: np.ndarray, dy: int, key: str) -> np.ndarray:
    """`img` moved `dy` rows (+ = down); an opaque pixel pushed off the canvas is a rig error."""
    if dy == 0:
        return img.copy()
    out = np.zeros_like(img)
    if dy > 0:
        lost, out[dy:] = img[-dy:], img[:-dy]
    else:
        lost, out[:dy] = img[:-dy], img[-dy:]
    if lost[:, :, 3].any():
        sys.exit(f"{key}: the hover bob pushes pixels off the canvas (the still needs empty rows on top)")
    return out


def _drop_strays(frame: np.ndarray, parts: list) -> np.ndarray:
    """Removes pixels left alone (no opaque 8-neighbour) inside the parts' boxes: outline
    bits of a moved part that were not in its colour mask (ART_BIBLE: no lone specks)."""
    a = frame[:, :, 3] > 0
    p = np.pad(a, 1)
    n = sum(np.roll(np.roll(p, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx)[1:-1, 1:-1]
    inbox = np.zeros_like(a)
    for part in parts:
        x0, x1, y0, y1 = part["box"]
        inbox[max(0, y0 - 1):y1 + 1, max(0, x0 - 1):x1 + 1] = True
    out = frame.copy()
    out[a & (n == 0) & inbox] = 0
    return out


def hover_frames(key: str, still: np.ndarray, rig: dict) -> list:
    """The FRAMES frames of a "hover" rig: the parts taken out, posed (flap / spin) and laid
    back over the body, then the whole frame raised by HOVER_BOB * bob px."""
    masks = [_part_mask(still, p) for p in rig.get("parts", [])]
    body = still.copy()
    for m in masks:
        body[m] = 0
    out = []
    for f in range(FRAMES):
        layers = [body]
        for p, m in zip(rig.get("parts", []), masks):
            lay = np.zeros_like(still)
            lay[m] = still[m]
            layers.append(_move_part(lay, p, f))
        frame = _stack(layers)
        if f:
            frame = _drop_strays(frame, rig.get("parts", []))
        out.append(_shift_v(frame, -int(round(HOVER_BOB[f] * rig.get("bob", 1))), key))
    return out


def _shear_leg(layer: np.ndarray, top: int, shift: float, lift: int) -> np.ndarray:
    """Stride leg `layer` (rows from `top` down) sheared sideways by round(shift * t) per row, t = 0
    at `top` to 1 at its lowest opaque row, then raised `lift` rows."""
    h, w = layer.shape[:2]
    rows = np.nonzero(layer[:, :, 3].any(axis=1))[0]
    out = np.zeros_like(layer)
    if rows.size == 0:
        return out
    bottom = max(int(rows.max()), top + 1)  # Foot row.
    for y in rows:
        t = (y - top) / float(bottom - top)  # 0 at the hip, 1 at the foot.
        dx = int(np.floor(shift * t + 0.5)) if shift >= 0 else -int(np.floor(-shift * t + 0.5))  # Sideways px.
        yy = y - lift  # Destination row.
        if not 0 <= yy < h:
            continue
        if dx > 0:
            out[yy, dx:] = layer[y, :w - dx]
        elif dx < 0:
            out[yy, :w + dx] = layer[y, -dx:]
        else:
            out[yy] = layer[y]
    return out


def stride_frames(key: str, still: np.ndarray, rig: dict) -> list:
    """The FRAMES frames of a "stride" rig (RIGS key list): the body, the near leg swinging between
    its forward pose and its mirror image, and the far leg (darker) half a cycle behind it."""
    h, w = still.shape[:2]
    hip = rig["hip"]
    keep = np.zeros((h, w), dtype=bool)  # Pixels below the hip that ride with the body (fists).
    for x0, x1, y0, y1 in rig.get("keep", []):
        keep[y0:y1, x0:x1] = True
    lower = np.zeros((h, w), dtype=bool)
    lower[hip:] = True
    body = still.copy()
    body[lower & ~keep] = 0
    fwd_m = lower & ~keep & (np.arange(w) >= rig["near_x0"])[None, :] & (still[:, :, 3] > 0)
    fwd_m = _largest_blob(fwd_m)  # Only the leg itself (bits of the other leg's heel left out).
    fwd = np.zeros_like(still)  # Forward pose: the still's near leg.
    fwd[fwd_m] = still[fwd_m]
    top_cols = np.nonzero(fwd[hip, :, 3])[0]
    pivot = int(top_cols.min() + top_cols.max())  # Column sum of the mirror (its axis = the hip's middle).
    back = np.zeros_like(still)  # Backward pose: the leg mirrored about its hip.
    for x in range(w):
        if 0 <= pivot - x < w:
            back[:, pivot - x] = fwd[:, x]
    rows = np.nonzero(fwd[:, :, 3].any(axis=1))[0]
    foot = fwd[rows.max() - 3:rows.max() + 1, :, 3].any(axis=0).nonzero()[0]  # The foot's columns.
    amp = float(foot.min() + foot.max()) - pivot  # Px between the two poses' feet (forward - backward).

    def pose(q: float) -> np.ndarray:
        """The leg swung `q` (0 forward .. 1 backward) of the way: the nearer pose, sheared."""
        r = rig.get("reach", 0)  # Extra px each pose's foot is pushed out (a longer stride).
        span = amp + 2 * r  # Px between the two pushed-out feet.
        return (_shear_leg(fwd, hip, r - q * span, 0) if q <= 0.5
                else _shear_leg(back, hip, -r + (1.0 - q) * span, 0))

    names = dict(zip(STRIDE_FAR_SHADE, _palette_rgb(list(STRIDE_FAR_SHADE))))  # Lighter name -> RGB.
    dark = dict(zip(STRIDE_FAR_SHADE, _palette_rgb(list(STRIDE_FAR_SHADE.values()))))  # Lighter name -> darker RGB.
    out = []
    for f in range(FRAMES):
        q = STRIDE_SWING[f]  # Near leg's swing (0 forward, 1 backward); the far leg's is 1 - q.
        dy = DIP[f % POSES] * rig.get("dip", 1)
        near = _lift(pose(q), int(round(STRIDE_LIFT_NEAR[f] * rig["lift"])), hip)
        far = _lift(pose(1.0 - q), int(round(STRIDE_LIFT_FAR[f] * rig["lift"])), hip)
        far = np.roll(far, rig.get("far_dx", 0), axis=1)
        src = far.copy()
        for n, rgb in names.items():
            m = (src[:, :, :3] == np.array(rgb, dtype=np.uint8)).all(-1) & (src[:, :, 3] > 0)
            far[m, :3] = dark[n]
        out.append(_stack([far, near, _move(body, dy)]))
    return out


def _largest_blob(mask: np.ndarray) -> np.ndarray:
    """The largest 8-connected region of the boolean `mask` (flood fill)."""
    seen = np.zeros_like(mask)
    best = np.zeros_like(mask)
    h, w = mask.shape
    for y0, x0 in zip(*np.nonzero(mask)):
        if seen[y0, x0]:
            continue
        blob = np.zeros_like(mask)
        stack = [(y0, x0)]
        seen[y0, x0] = True
        while stack:
            y, x = stack.pop()
            blob[y, x] = True
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not seen[yy, xx]:
                        seen[yy, xx] = True
                        stack.append((yy, xx))
        if blob.sum() > best.sum():
            best = blob
    return best


def _lift(layer: np.ndarray, n: int, top: int) -> np.ndarray:
    """`layer` raised `n` rows; rows pushed above row `top` (the hip) are dropped, so nothing of
    the leg shows through the gaps between the body's kilt and fists."""
    if n <= 0:
        return layer
    out = np.zeros_like(layer)
    out[:-n] = layer[n:]
    out[:top] = 0
    return out


def frames_of(key: str) -> list:
    """The FRAMES walk frames of `key` (RGBA arrays the still's size); frame 0 is the still
    (except a "stride" rig's, whose frame 0 is the mirrored stance)."""
    still = load(key)
    rig = RIGS[key]
    if rig["mode"] == "stride":
        return stride_frames(key, still, rig)
    if rig["mode"] == "hover":
        out = hover_frames(key, still, rig)
        if not np.array_equal(out[0], still):
            sys.exit(f"{key}: frame 0 differs from the still (rig error)")
        return out
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
        if "swing" in rig:
            frame = _swing(frame, rig["swing"], dy, SWING[f])
        if "bust" in rig:
            axis = rig.get("bust_axis", "y")  # "y" bounces, "x" sways (BUST_SWAY).
            share = (BUST_SWAY if axis == "x" else BUST_BOUNCE)[f]
            frame = _bounce(frame, rig["bust"], dy, share * rig["bust"][4], axis)
        if "swish" in rig:
            frame = _bounce(frame, rig["swish"], dy, SWISH_SWAY[f] * rig["swish"][4], "x")
        out.append(frame)
    if not np.array_equal(out[0], still):
        sys.exit(f"{key}: frame 0 differs from the still (rig error)")
    return out


def _swing(frame: np.ndarray, swing: tuple, dy: int, k: float) -> np.ndarray:
    """Swings the hanging part of `frame` (the still's box `swing` lowered by the body dip
    `dy`): its opaque pixels are lifted out and laid back on top with each row slid
    round(k * px * (row - pivot) / (bottom - pivot)) px sideways (+ = right). k = 0 returns
    the frame unchanged."""
    if k == 0:
        return frame
    x0, x1, y0, y1, pivot, px = swing
    y0, y1, pivot = y0 + dy, y1 + dy, pivot + dy  # This frame's rows.
    h, w = frame.shape[:2]
    out = frame.copy()
    part = np.zeros_like(frame)  # The lifted part.
    rows = slice(max(0, y0), min(h, y1))
    part[rows, x0:x1] = frame[rows, x0:x1]
    out[rows, x0:x1][frame[rows, x0:x1, 3] > 0] = 0  # Taken out of the body.
    span = float(max(1, y1 - 1 - pivot))  # Rows from the pivot to the bottom.
    for y in range(max(0, y0), min(h, y1)):
        d = int(round(k * px * max(0, y - pivot) / span))  # Sideways slide of this row (px).
        src = part[y]
        mask = src[:, 3] > 0
        xs = np.nonzero(mask)[0]
        for x in xs:
            nx = x + d
            if 0 <= nx < w:
                out[y, nx] = src[x]
        # The box's last columns also hold the body's own outline where the part touched it:
        # an outline (ink) pixel left empty there next to the body keeps its still colour (no
        # hole in the coat; the part's lit pixels are never left behind).
        if x1 < w and frame[y, x1, 3] > 0:
            for x in range(max(x0, x1 - 2), x1):
                if out[y, x, 3] == 0 and frame[y, x, 3] > 0 and int(frame[y, x, :3].sum()) < SWING_INK_SUM:
                    out[y, x] = frame[y, x]
    return out


def _bounce(frame: np.ndarray, bust: tuple, dy: int, s: float, axis: str = "y") -> np.ndarray:
    """Warps the bust of `frame` (the still's box `bust` lowered by the body dip `dy`) so its
    underside moves `s` px (+ = down) at the box's centre column. Displacement field: a
    sine bell across the columns (1 at the centre, 0 just outside the box) times a ramp down
    the rows (0 at the neckline, 1 on the underside), then a fade back to 0 over the
    BUST_TAIL_PER_PX * |s| rows below. Each pixel takes the pixel |d| rows above or below it
    in the same column (nearest, inverse mapping: no holes, no new colours). s = 0 returns
    the frame unchanged. axis "x" (a rig's `bust_axis`): the same field moves the pixels
    sideways instead (+ = right): each pixel takes the pixel |d| columns left or right of it
    in the same row."""
    if s == 0:
        return frame
    x0, x1 = bust[0], bust[1]  # Box columns [x0, x1) (art px).
    lobes = bust[5] if len(bust) > 5 else 1  # Bells across the box: 1 (centre) or 2 (one per side).
    y0, y1 = bust[2] + dy, bust[3] + dy  # Box rows in this frame: neckline .. underside + 1.
    tail = int(np.ceil(abs(s) * BUST_TAIL_PER_PX)) + 1  # Fade-out rows below the box.
    h = frame.shape[0]  # Frame height (art px).
    out = frame.copy()
    span = float(x1 - x0)  # Box width (art px).
    for x in range(x0, x1):
        wx = abs(float(np.sin(lobes * np.pi * (x - x0 + 0.5) / span)))  # Column weight: 1 at each bell's centre.
        for y in range(max(0, y0), min(h, y1 + tail)):
            if y < y1:
                wy = (y - y0 + 1) / float(y1 - y0)  # 0 at the neckline, 1 on the underside.
            else:
                wy = 1.0 - (y - y1 + 1) / float(tail + 1)  # Fades out under the bust.
            d = int(round(s * wx * wy))  # Px this pixel's content moves (+ = down, or right on axis "x").
            if d == 0:
                continue
            if axis == "x":
                sx = x - d  # Source column (inverse mapping).
                if 0 <= sx < frame.shape[1]:
                    out[y, x] = frame[y, sx]
            else:
                sy = y - d  # Source row (inverse mapping).
                if 0 <= sy < h:
                    out[y, x] = frame[sy, x]
    return out


def build(key: str) -> Path:
    """Writes assets/sprites/<key>_walk.png and returns its path."""
    frames = frames_of(key)
    strip = np.concatenate(frames, axis=1)
    dest = SPRITE_DIR / (key + SUFFIX + ".png")
    Image.fromarray(strip, "RGBA").save(dest, optimize=True)
    still = load(key)  # The approved still (a stride strip's frame 0 is not it).
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


# ------------------------------------------------------------------ idle (breathing) strips

IDLE_DATA = ROOT / "scripts" / "data" / "idle_data.gd"  # Idle frame count and suffix live there.


def _idle_const(name: str, default: str) -> str:
    """Reads constant `name` from idle_data.gd (one source of truth for the engine and the tool)."""
    if not IDLE_DATA.exists():
        return default
    m = re.search(rf"const {name}: \w+ = \"?([\w.]+)\"?", IDLE_DATA.read_text())
    return m.group(1) if m else default


IDLE_FRAMES = int(_idle_const("FRAMES", "24"))  # Frames per idle loop (IdleData.FRAMES).
IDLE_SUFFIX = _idle_const("SUFFIX", "_idle")  # Idle strip key suffix (IdleData.SUFFIX).
IDLE_FPS = float(_idle_const("FPS", "8.0"))  # Frames per second of the loop (IdleData.FPS; the preview GIF's rate).
# Per frame: art px every row above the hip sinks (0 = the still = the full breath, 1 = exhaled).
# 0.75 s at rest, the exhale, 1.5 s exhaled, the inhale, 0.75 s at rest (at 8 fps).
IDLE_SINK = (0,) * 6 + (1,) * 12 + (0,) * 6
# Per frame: the bust underside's move relative to the body, as a share of the rig's `bust` px
# (+ = down; the same field as BUST_BOUNCE). A damped spring kicked by each sink and rise: it
# lags the body (stays up as the body sinks, down as it rises), overshoots, rebounds less (only
# the box's centre still moves), then settles; at rest it is 0, so frame 0 stays the still.
# A `bust_axis="x"` box reads it sideways (+ = right): its kicks change side between the
# exhale and the inhale on their own.
IDLE_BUST = ((0.0,) * 6
             + (-0.5, 0.75, -0.375) + (0.0,) * 9
             + (0.5, -0.75, 0.375) + (0.0,) * 3)
# Per-key overrides of the idle cut (set after review): "waist" = the row taken out on the
# exhale (default the rig's hip - 1, the last row above the hip).
IDLE_FIX = {}
# Per frame: a `swish` box's sideways share in the idle: IDLE_BUST one frame later (the drape
# follows the hips).
IDLE_SWISH = (0.0,) + IDLE_BUST[:-1]
if len(IDLE_SINK) != IDLE_FRAMES or len(IDLE_BUST) != IDLE_FRAMES:
    sys.exit(f"idle_data.gd FRAMES is {IDLE_FRAMES}; IDLE_SINK / IDLE_BUST hold {len(IDLE_SINK)} / {len(IDLE_BUST)}")


def idle_keys() -> list:
    """Keys whose rig has a bust box (the only ones with idle strips)."""
    return [k for k, r in RIGS.items() if "bust" in r]


def _sink(still: np.ndarray, waist: int, dy: int) -> np.ndarray:
    """The still with rows 0 .. waist - dy moved `dy` rows down (row `waist` and the dy - 1
    rows above it are covered, the top dy rows emptied); rows below `waist` are untouched."""
    if dy == 0:
        return still.copy()
    out = still.copy()
    out[dy:waist + 1] = still[0:waist + 1 - dy]
    out[:dy] = 0
    return out


def idle_frames_of(key: str) -> list:
    """The IDLE_FRAMES idle frames of `key` (RGBA arrays the still's size); frame 0 is the still."""
    rig = RIGS[key]
    if "bust" not in rig:
        sys.exit(f"{key}: no bust box in its rig (idle strips are for bust rigs only)")
    still = load(key)
    waist = int(IDLE_FIX.get(key, {}).get("waist", rig["hip"] - 1))  # Row taken out on the exhale.
    out = []
    for f in range(IDLE_FRAMES):
        dy = IDLE_SINK[f]  # Body sink this frame (art px).
        frame = _sink(still, waist, dy)
        frame = _bounce(frame, rig["bust"], dy, IDLE_BUST[f] * rig["bust"][4], rig.get("bust_axis", "y"))
        if "swish" in rig:
            frame = _bounce(frame, rig["swish"], dy, IDLE_SWISH[f] * rig["swish"][4], "x")
        out.append(frame)
    if not np.array_equal(out[0], still):
        sys.exit(f"{key}: idle frame 0 differs from the still (rig error)")
    keep = np.ones(still.shape[:2], dtype=bool)  # Pixels below the waist that must not move.
    keep[:waist + 1] = False
    if "swish" in rig:  # The drape's box (with its fade rows and the sink) may sway below the waist.
        sx0, sx1, sy0, sy1, spx = rig["swish"]
        keep[sy0:sy1 + int(np.ceil(spx * BUST_TAIL_PER_PX)) + 3, sx0:sx1] = False
    if any(not np.array_equal(f[keep], still[keep]) for f in out):
        sys.exit(f"{key}: an idle frame moved a row below the waist (rig error)")
    return out


def build_idle(key: str) -> Path:
    """Writes assets/sprites/<key>_idle.png and returns its path."""
    frames = idle_frames_of(key)
    strip = np.concatenate(frames, axis=1)
    dest = SPRITE_DIR / (key + IDLE_SUFFIX + ".png")
    still = load(key)  # The approved still (a stride strip's frame 0 is not it).
    new_cols = {tuple(c) for f in frames for c in f[f[:, :, 3] > 0].tolist()} - {tuple(c) for c in still[still[:, :, 3] > 0].tolist()}
    if new_cols:
        sys.exit(f"{key}: idle frames hold colours the still does not ({len(new_cols)})")
    Image.fromarray(strip, "RGBA").save(dest, optimize=True)
    print(f"{key}{IDLE_SUFFIX}: {len(frames)} frames of {still.shape[1]}x{still.shape[0]} -> {dest.relative_to(ROOT)} "
          f"({strip.shape[1]}x{strip.shape[0]})")
    return dest


def preview_idle(key: str, out_dir: Path, gif_scale: int = 4, sheet_scale: int = 6) -> None:
    """A GIF of the breathing loop and a frame sheet for `key` (on the Graveyard soil)."""
    frames = idle_frames_of(key)
    out_dir.mkdir(parents=True, exist_ok=True)
    name = key.replace("/", "_")
    h, w = frames[0].shape[:2]
    pad = 4
    gif = []
    for f in frames:
        c = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), SOIL)
        c.alpha_composite(Image.fromarray(f, "RGBA"), (pad, pad))
        gif.append(c.convert("RGB").resize(((w + 2 * pad) * gif_scale, (h + 2 * pad) * gif_scale), Image.NEAREST))
    # Identical neighbouring frames would be merged by the GIF writer; disposal keeps them apart.
    gif[0].save(out_dir / (name + "_idle.gif"), save_all=True, append_images=gif[1:],
                duration=int(round(1000.0 / IDLE_FPS)), loop=0, optimize=False, disposal=1)
    cells = [frames[0]] + frames
    sheet = Image.new("RGBA", ((w + pad) * len(cells) + pad, h + 2 * pad), SOIL)
    for i, f in enumerate(cells):
        sheet.alpha_composite(Image.fromarray(f, "RGBA"), (pad + i * (w + pad), pad))
    sheet = sheet.resize((sheet.width * sheet_scale, sheet.height * sheet_scale), Image.NEAREST)
    sheet.save(out_dir / (name + "_idle_sheet.png"))
    print(f"{key}: {out_dir / (name + '_idle.gif')}, {out_dir / (name + '_idle_sheet.png')}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["build", "preview", "sheet", "idle", "idle-preview"])
    ap.add_argument("keys", nargs="*")
    ap.add_argument("--all", action="store_true", help="every key in RIGS (idle commands: every bust rig)")
    ap.add_argument("--out-dir", default="", help="preview / idle-preview: output folder")
    ap.add_argument("--out", default="", help="sheet: output PNG")
    args = ap.parse_args()
    keys = list(RIGS) if args.all else args.keys
    if args.cmd in ("idle", "idle-preview"):
        keys = idle_keys() if args.all else args.keys
        unknown = [k for k in keys if k not in RIGS]
        if unknown:
            sys.exit(f"no rig for: {', '.join(unknown)}")
        for k in keys:
            if args.cmd == "idle":
                build_idle(k)
            else:
                preview_idle(k, Path(args.out_dir or "."))
        return
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
