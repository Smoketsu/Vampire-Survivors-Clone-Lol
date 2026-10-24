## FrameData: how the Web build paces the simulation against slow frames (GDD §15.0
## "Web physics catch-up cap"). Godot runs the 60 Hz simulation in whole ticks: a frame
## that took longer than one tick runs several ticks to catch up, at most
## max_physics_steps_per_frame (the project default is 8). On a phone that cannot keep
## up (Low Power Mode throttles the CPU and caps the page at 30 fps), every slow frame
## then runs more ticks, which makes the next frame slower still, up to 8 ticks
## (~130 ms of simulation) in one frame: the picture stutters at a few frames a second
## and the no-threads Web audio, mixed on the same thread, crackles. A lower ceiling in
## solo play lets the game run a little slower instead (each tick is still exactly
## 1/60 s of game time, so gameplay and the same-seed results do not change).
## Data only, no logic.
class_name FrameData
extends RefCounted

## Most simulation ticks one rendered frame may run in a solo run of the Web build
## (Game._apply_step_cap(); 2 are needed per frame at a 30 fps cap, so 3 still absorbs
## a 50 ms frame without slowing the game). Co-op keeps the project default: the
## lockstep paces its own ticks against the partner. The autotest sets its own.
const WEB_SOLO_MAX_STEPS: int = 3  # TUNING (not in GDD) mobile
## The project default (physics/common/max_physics_steps_per_frame), restored for co-op
## and when a run ends.
const DEFAULT_MAX_STEPS: int = 8  # Godot 4.3 default (not in GDD)
