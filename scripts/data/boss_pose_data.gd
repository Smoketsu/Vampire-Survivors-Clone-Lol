## BossPoseData: which attack-pose sprite each stage boss shows in each attack
## pose (art pass: boss attack poses, GDD §15.0 "Boss attack poses"). The boss
## scripts already report a pose number from their attack phase (Alaric,
## Vael and Seraphine all use the same four): 0 walking, 1 winding up or
## casting, 2 the special stance (Alaric's charge, Vael's Shieldwall,
## Seraphine's teleport / transformation glow), 3 the strike just landed
## (recover). SpriteBank.draw_pose() draws "<still key>_<suffix>.png" for a
## pose listed here when that file exists, its feet on the still's feet, and
## the still otherwise, so every pose falls back on its own. Purely visual:
## poses never change timings, hitboxes or anything a run computes. Data only.
class_name BossPoseData
extends RefCounted

## Still sprite key -> {pose number -> file suffix}. A pose missing here (or
## whose PNG is missing) shows the still.
const POSES: Dictionary = {
	"bosses/alaric": {1: "windup", 2: "charge", 3: "strike"},  # TUNING (not in GDD) hammer raised / shoulder charge / hammer slammed down
	"bosses/vael": {1: "windup", 2: "guard", 3: "strike"},  # TUNING (not in GDD) flaming sword raised / Shieldwall / cleave follow-through
	"bosses/seraphine": {1: "cast"},  # TUNING (not in GDD) relic staff raised in a cast (teleport and recover keep the still)
	"bosses/seraphine_avatar": {1: "cast"},  # TUNING (not in GDD) the Avatar's cast
	# --- Act II: Gullhaven Harbour ---
	"bosses/merrow": {1: "sermon"},  # TUNING (not in GDD) preaching / casting with both arms raised
	"bosses/merrow_changed": {3: "strike"},  # TUNING (not in GDD) the limbs lashing forward
	# --- Act II: the Hollow Archive ---
	"bosses/archivist": {1: "cast", 2: "split", 3: "strike"},  # TUNING (not in GDD) Recitation / Footnotes / the tome slammed down (BossArchivist)
}
