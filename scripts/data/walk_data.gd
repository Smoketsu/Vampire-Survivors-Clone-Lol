## WalkData: numbers of the unit walk cycles (GDD §15.0 "Walk cycles"; ART_BIBLE
## "Walk cycles"). A unit whose still sprite `assets/sprites/<key>.png` has a
## walk strip `assets/sprites/<key>_walk.png` shows a walk frame instead of the
## still while it moves. The strip holds FRAMES frames side by side, each
## exactly the still's size (same width, same height, feet on the same bottom
## row, the body at the same x), so the frame count is the strip width divided
## by the still width (SpriteBank reads it from the files; a strip whose size
## does not fit is ignored and the still is drawn). Frame 0 is the still itself.
##
## The frame is picked from the unit's engine-motion step phase (UnitMotion:
## the phase advances by PI per step, at the unit's measured speed over its
## stride), so the legs keep time with the step bob and the speed; standing
## units show the still. Purely visual: game time and positions only, no RNG,
## so a run is unchanged. Data only, no logic.
class_name WalkData
extends RefCounted

## Suffix of a walk strip's sprite key ("summons/warrior" -> "summons/warrior_walk").
const SUFFIX: String = "_walk"

## Frames per full walk cycle (two steps) in the strips tools/walk_cycle.py
## writes: per step contact, down, passing, up. The engine reads the real count
## from each strip; this is the layout the tool writes and documents.
const FRAMES: int = 8  # TUNING (not in GDD) 8 frames: ~9 fps at a Recruit's 58 px/s (4 would be ~4.5 fps)

## Step phase (rad) at which frame 0 (the contact pose = the still) is centred.
## UnitMotion's phase is 0 and PI at the bob's low point (feet apart, contact)
## and PI/2, 3PI/2 at its high point (passing), so frame 0 is centred on 0 and
## the passing frames (2 and 6 of 8) land on the bob's top.
const PHASE_AT_FRAME_0: float = 0.0  # TUNING (not in GDD)

## Measured speed (px/s) above which a standing unit starts walking (frames on).
const START_SPEED: float = 14.0  # TUNING (not in GDD) just above MotionData.BOB_MIN_SPEED (12)
## Measured speed (px/s) below which a walking unit stops and shows its still
## (below START_SPEED: the gap keeps units shoved around in a crowd from
## flickering between the still and a walk frame).
const STOP_SPEED: float = 8.0  # TUNING (not in GDD)

## Share of MotionData.BOB_STRETCH kept while a unit with a walk strip walks:
## the strip carries its own 1 art px body dip, so the procedural stretch is
## cut down to a light accent (0 = none, 1 = the full tier-0 bob).
const BOB_SCALE: float = 0.35  # TUNING (not in GDD)
