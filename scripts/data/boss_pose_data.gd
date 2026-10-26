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
	# --- Act III: the Assembly Halls ---
	"bosses/motherboard": {1: "windup", 3: "strike"},  # TUNING (not in GDD) crane arms raised for a special / claws slammed down (BossMotherboard)
	# --- Act III: the Scrap Wastes ---
	"bosses/kestrel": {1: "aim"},  # TUNING (not in GDD) kneeling with the rifle raised on her perch (BossKestrel; the leap keeps the still; her blades are their own still, bosses/kestrel_blades)
	# --- Act III: the Iron Citadel ---
	"bosses/deus_ex_machina": {1: "fire"},  # TUNING (not in GDD) the Walker firing: chaingun spun up, missile pods open (BossDeusExMachina)
	# --- Act IV: the Shores of Ilion ---
	"bosses/achilles": {3: "strike"},  # TUNING (not in GDD) the low spear lunge (BossAchilles: the lunge's windup, run and recovery; his rage form is its own still, bosses/achilles_rage)
	# --- Act IV: Mount Olympus ---
	"bosses/zeus": {1: "cast"},  # TUNING (not in GDD) the thunderbolt raised to call a storm or the beam (BossZeus; his true form is its own still, bosses/zeus_colossus)
	# --- Act IV: the Asphodel Underworld ---
	"bosses/hades": {1: "bident"},  # TUNING (not in GDD) the bident swept forward (BossHades: the sweep's windup and the phase changes)
	# --- Act V: Castle Kurogane ---
	"bosses/shogun": {3: "duel"},  # TUNING (not in GDD) the low iai stance with the blade drawn (BossShogun: the leap down and every cut he stands to draw in the duel)
}
