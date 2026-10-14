## IdleData: numbers of the unit idle "breathing" loops (GDD §15.0 "Idle
## breathing bounce"; ART_BIBLE "Walk cycles" -> "Idle strips"). A unit whose
## still sprite `assets/sprites/<key>.png` has an idle strip
## `assets/sprites/<key>_idle.png` plays it while it stands (not walking, see
## WalkData START_SPEED / STOP_SPEED). The strip holds FRAMES frames side by
## side, each exactly the still's size (the walk-strip contract), so the frame
## count is the strip width divided by the still width (SpriteBank reads it
## from the files; a strip whose size does not fit is ignored). Frame 0 is the
## still itself, so starting or stopping the loop never pops.
##
## tools/walk_cycle.py writes idle strips only for rigs with a bust box (the
## figure redesign): a slow breath (the upper body sinks 1 art px and comes
## back; nothing below the hip moves) with the bust reacting like a damped
## spring (lag, overshoot, a small rebound, settle).
##
## Clock: game time (Game.elapsed), from the moment the unit started standing
## (its loop starts on frame 0 then, so units are out of step with no RNG and
## no per-unit id). Purely visual: no gameplay state, no RNG, so a run is
## unchanged. Data only, no logic.
class_name IdleData
extends RefCounted

## Suffix of an idle strip's sprite key ("player/soulbinder" -> "player/soulbinder_idle").
const SUFFIX: String = "_idle"

## Frames per idle loop in the strips tools/walk_cycle.py writes (the tool reads
## this constant; the engine reads the real count from each strip). Many frames
## at a fixed rate let the holds be long and the spring frames short.
const FRAMES: int = 24  # TUNING (not in GDD) 24 frames: holds of 6-12 frames, 3-frame spring wobbles

## Idle frames shown per game second (1 .. 30). FRAMES / FPS is the loop length:
## 24 / 8 = 3.0 s per breath (about 20 breaths a minute), 0.125 s per spring frame.
const FPS: float = 8.0  # TUNING (not in GDD)
