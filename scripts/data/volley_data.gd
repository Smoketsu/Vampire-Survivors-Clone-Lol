## VolleyData: the bullet heaven pass (owner request, Oct 2026; GDD §15.0 "Bullet heaven
## pass"). Every summon class gets a flashy signature volley on top of its normal attack,
## every owned spell releases a themed echo volley, Dread Rally fires the whole army's
## volleys at once (the Rally Barrage) and fodder waves come denser but frailer. The whole
## pass is one switch: Settings.volleys (Settings -> Video -> Volleys, default on), read
## once per run as Game.volleys_on; --volleys=off runs none of the pass (no volleys, the
## usual fodder; the army keeps the Bone Ring, GDD §15.0 "Bone Ring is the only formation").
## VolleyDirector reads this file; no logic here.
##
## Shot patterns (the "pattern" key of a volley):
##   fan    count shots spread evenly over `spread` degrees around the aim direction
##   ring   count shots evenly around a full circle (start angle turns each volley)
##   spiral a ring whose shots also turn at `curve` rad/s as they fly (a swirl)
##   seek   count shots that home on the nearest enemies (turn rate `homing` rad/s)
##   rain   count shots dropping onto points scattered around the target (`scatter` px)
## Volley keys:
##   trigger  "attack" = every `every`-th attack the unit releases; "special" = the class
##            special's own moment (stomp, dash end, swoop impact, Dirge wave, boulder
##            landing, mage explosion), called by that code
##   every    attack releases per volley (attack triggers only)
##   pattern  see above
##   counts   [shots at class Lv 3-4, shots at Lv 5] (an evolution entry: [shots])
##   spread   fan width (degrees)
##   speed    shot speed (px/s)
##   life     shot lifetime (s): range = speed x life
##   share    damage of ONE shot as a fraction of the triggering hit (the unit's attack
##            damage, or the special's own damage); the volley splits damage, it adds
##            only what lands on extra enemies
##   pierce   extra enemies a shot passes through (0 = stops at the first)
##   radius   collision radius of a shot (px)
##   style    look: "shard", "orb", "dagger", "spark", "note", "feather", "wave"
##   color    main colour (the necromancer's violets, greens, bone and frost: never the
##            Covenant's crimson or gold, so enemy attacks always read apart)
##   curve    turn rate while flying (rad/s; spiral only)
##   homing   turn rate toward the target (rad/s; seek only)
##   scatter  radius of the rain's landing points around the target (px; rain only)
class_name VolleyData
extends RefCounted

# --- Global rules ---------------------------------------------------------------------

## Most volley shots in play at once on every platform (the gameplay cap: identical on
## desktop, browser and phone, so a seed plays out the same everywhere). Over it, a new
## volley fires fewer shots, each carrying the dropped shots' damage.
const SHOT_CAP: int = 320  # TUNING (not in GDD)
## Most shots drawn with Effects = Reduced (phones): drawing only, the shots still fly.
const DRAW_CAP_REDUCED: int = 160  # TUNING (not in GDD) mobile
## Class level at which a summon class's volley switches on (owner: Lv 3).
const LEVEL_ON: int = 3  # TUNING (not in GDD) owner decision Oct 2026
## Class level at which the volley grows to its second count.
const LEVEL_GROW: int = 5  # TUNING (not in GDD)
## Most hits one volley may land on bosses and minibosses (boss kill times stay put).
const BOSS_HITS_PER_VOLLEY: int = 2  # TUNING (not in GDD)
## Size of the per-volley boss-hit ring buffer (volleys tracked at once).
const VOLLEY_SLOTS: int = 1024  # TUNING (not in GDD) bookkeeping
## Largest enemy radius considered in shot contact queries (px; the boss is 22).
const MAX_BODY: float = 30.0  # TUNING (not in GDD)
## Rally Barrage: while Dread Rally's buff runs, attack-triggered volleys come this many
## times as often (owner: on top of Rally's own bonuses, no trade).
const BARRAGE_RATE: int = 2  # TUNING (not in GDD) owner decision Oct 2026
## Rally Barrage: the opening burst fires each unit's volley at least at this level's
## count, so a Lv 1-2 class still joins in.
const BARRAGE_MIN_LEVEL: int = 3  # TUNING (not in GDD)
## Denser fodder (owner: yes): enemy trickle spawn rate and caps x this ...
const FODDER_SPAWN_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026
## ... and every non-boss enemy's HP x this (about the same total HP on screen). Kills
## keep their full XP (owner: the build may complete earlier).
const FODDER_HP_MULT: float = 0.8  # TUNING (not in GDD) owner decision Oct 2026
## Every shot's `life` x this (one knob for the volleys' reach: range = speed x life x it).
const LIFE_MULT: float = 1.6  # TUNING (not in GDD) first look: shots died before reaching the enemies at the screen edge
## Drawn size of a shot as a multiple of its collision radius (drawing only).
const DRAW_SCALE: float = 2.3  # TUNING (not in GDD) visual
## A shot's trail length as a multiple of its distance per 1/60 s (drawing only).
const TRAIL: float = 3.5  # TUNING (not in GDD) visual
## Glow halo radius as a multiple of the shot's radius (drawing only).
const GLOW: float = 2.2  # TUNING (not in GDD) visual
## Glow halo opacity (0..1, drawing only; drawn additively, so it brightens what is under it).
const GLOW_ALPHA: float = 0.35  # TUNING (not in GDD) visual
## Core opacity of a volley shot (0..1, drawing only): slightly see-through, so the
## Covenant's solid attacks and telegraphs always read on top.
const CORE_ALPHA: float = 0.9  # TUNING (not in GDD) visual

# --- Art (GDD §15.0 "Volley art"; drawing only, never read by gameplay) ---------------
# The art is grey TINT MASKS (tools/volley_art.py): white = hot core, greys = glow. The
# director multiplies each by the shot's colour and draws it additively; a missing file
# keeps the code-drawn shape.

## Sprite key prefix of the shot masks: assets/sprites/volleys/<style>.png.
const ART_DIR: String = "volleys/"  # TUNING (not in GDD)
## Style -> drawn length of its mask (longest side, px) as a multiple of the shot's drawn
## radius (radius x DRAW_SCALE). The masks include their own trails.
const ART_LEN := {
	"shard": 5.2,  # TUNING (not in GDD) visual
	"orb": 4.6,  # TUNING (not in GDD) visual
	"dagger": 5.0,  # TUNING (not in GDD) visual
	"spark": 4.8,  # TUNING (not in GDD) visual
	"note": 3.6,  # TUNING (not in GDD) visual
	"feather": 5.2,  # TUNING (not in GDD) visual
	"wave": 3.4,  # TUNING (not in GDD) visual (radius 12: about 94 px across)
}
## How far the mask's centre sits behind the shot's position, as a fraction of its drawn
## length (the head of the art leads, the trail follows).
const ART_LEAD: float = 0.28  # TUNING (not in GDD) visual
## Fraction the mask's tint is lightened toward white (keeps a hot white-ish core).
const ART_WHITEN: float = 0.3  # TUNING (not in GDD) visual
## Opacity of the mask (0..1).
const ART_ALPHA: float = 0.95  # TUNING (not in GDD) visual
## Glow halo drawn under a mask: radius as a multiple of the drawn radius ...
const ART_GLOW: float = 1.5  # TUNING (not in GDD) visual
## ... at most this many px (a big sword wave keeps a small halo, not a disc) ...
const ART_GLOW_MAX: float = 12.0  # TUNING (not in GDD) visual
## ... and this opacity (0..1).
const ART_GLOW_ALPHA: float = 0.22  # TUNING (not in GDD) visual

## Impact burst played where a shot hits (effect strip assets/sprites/effects/<id>.png,
## tinted with the shot's colour). No burst without the art.
const HIT_ANIM: String = "volley_hit"  # TUNING (not in GDD)
## Impact burst duration (s, game time).
const HIT_TIME: float = 0.22  # TUNING (not in GDD) visual
## Impact burst diameter as a multiple of the shot's drawn radius (radius x DRAW_SCALE).
const HIT_SIZE: float = 3.6  # TUNING (not in GDD) visual
## Impact burst opacity (0..1).
const HIT_ALPHA: float = 0.9  # TUNING (not in GDD) visual
## Impact burst diameter range (px).
const HIT_MIN: float = 18.0  # TUNING (not in GDD) visual
const HIT_MAX: float = 56.0  # TUNING (not in GDD) visual
## Launch flash played where a volley is fired (strip id, tinted with the volley colour).
const FLASH_ANIM: String = "volley_flash"  # TUNING (not in GDD)
## Launch flash opacity (0..1): kept low, as a full ring of summons firing at once stacks
## its flashes additively over the army.
const FLASH_ALPHA: float = 0.45  # TUNING (not in GDD) visual first look: 1.0 washed the ring out to white
## Launch flash duration (s, game time).
const FLASH_TIME: float = 0.28  # TUNING (not in GDD) visual
## Launch flash diameter (px): base + per shot in the volley, at most FLASH_MAX.
const FLASH_BASE: float = 22.0  # TUNING (not in GDD) visual
const FLASH_PER_SHOT: float = 2.5  # TUNING (not in GDD) visual
const FLASH_MAX: float = 64.0  # TUNING (not in GDD) visual
## Bursts (impacts + flashes) remembered at once: a ring buffer, the oldest replaced.
const FX_CAP: int = 96  # TUNING (not in GDD) visual
## Most bursts drawn with Effects = Reduced (phones).
const FX_DRAW_REDUCED: int = 24  # TUNING (not in GDD) mobile

# --- Summon classes (switch on at LEVEL_ON, grow at LEVEL_GROW) -----------------------

## Class id -> volley (keys in the header).
const CLASSES := {
	"warrior": {"trigger": "attack", "every": 2, "pattern": "fan", "counts": [3, 5], "spread": 50.0, "speed": 300.0,
		"life": 0.45, "share": 0.25, "pierce": 0, "radius": 4.0, "style": "shard", "color": Color(0.87, 0.85, 0.76)},  # TUNING (not in GDD) bone shards from the line
	"archer": {"trigger": "attack", "every": 1, "pattern": "fan", "counts": [3, 5], "spread": 34.0, "speed": 420.0,
		"life": 0.5, "share": 0.3, "pierce": 0, "radius": 3.0, "style": "shard", "color": Color(0.70, 0.95, 0.75)},  # TUNING (not in GDD) multishot
	"mage": {"trigger": "special", "pattern": "ring", "counts": [3, 5], "speed": 230.0,
		"life": 0.42, "share": 0.3, "pierce": 0, "radius": 4.0, "style": "spark", "color": Color(0.64, 0.36, 0.98)},  # TUNING (not in GDD) forking sparks where the orb bursts
	"mender": {"trigger": "attack", "every": 1, "pattern": "seek", "counts": [2, 3], "speed": 260.0,
		"life": 0.9, "share": 0.6, "pierce": 0, "radius": 3.5, "style": "spark", "color": Color(0.42, 0.95, 0.55), "homing": 7.0},  # TUNING (not in GDD) soul sparks
	"warder": {"trigger": "attack", "every": 1, "pattern": "ring", "counts": [6, 8], "speed": 200.0,
		"life": 0.5, "share": 0.45, "pierce": 0, "radius": 3.5, "style": "shard", "color": Color(0.55, 0.70, 0.98)},  # TUNING (not in GDD) barrier shards
	"bishop": {"trigger": "attack", "every": 1, "pattern": "spiral", "counts": [8, 8], "speed": 170.0,
		"life": 0.8, "share": 0.4, "pierce": 1, "radius": 4.0, "style": "orb", "color": Color(0.55, 0.25, 0.85), "curve": 2.4},  # TUNING (not in GDD) turning ring of dark orbs
	"abomination": {"trigger": "special", "pattern": "ring", "counts": [8, 12], "speed": 240.0,
		"life": 0.5, "share": 0.3, "pierce": 0, "radius": 4.5, "style": "orb", "color": Color(0.55, 0.66, 0.48)},  # TUNING (not in GDD) flesh chunks from the stomp
	"rogue": {"trigger": "special", "pattern": "fan", "counts": [3, 5], "spread": 40.0, "speed": 380.0,
		"life": 0.4, "share": 0.35, "pierce": 0, "radius": 3.0, "style": "dagger", "color": Color(0.74, 0.55, 0.98)},  # TUNING (not in GDD) thrown daggers at the dash end
	"gargoyle": {"trigger": "special", "pattern": "ring", "counts": [6, 8], "speed": 260.0,
		"life": 0.4, "share": 0.3, "pierce": 0, "radius": 4.0, "style": "feather", "color": Color(0.62, 0.66, 0.74)},  # TUNING (not in GDD) stone feather darts from the dive
	"frost_wraith": {"trigger": "attack", "every": 1, "pattern": "fan", "counts": [3, 5], "spread": 30.0, "speed": 340.0,
		"life": 0.5, "share": 0.3, "pierce": 0, "radius": 3.5, "style": "shard", "color": Color(0.62, 0.84, 1.0)},  # TUNING (not in GDD) ice shard cone
	"bone_hound": {"trigger": "attack", "every": 3, "pattern": "fan", "counts": [3, 4], "spread": 46.0, "speed": 320.0,
		"life": 0.5, "share": 0.3, "pierce": 1, "radius": 5.0, "style": "orb", "color": Color(0.70, 0.92, 0.86)},  # TUNING (not in GDD) ghost wolves of the howl
	"banshee": {"trigger": "special", "pattern": "ring", "counts": [10, 14], "speed": 210.0,
		"life": 0.55, "share": 0.5, "pierce": 1, "radius": 4.0, "style": "note", "color": Color(0.80, 0.70, 1.0)},  # TUNING (not in GDD) the Dirge's visible rings (share of the shriek bolt)
	"corpse_catapult": {"trigger": "special", "pattern": "ring", "counts": [6, 10], "speed": 250.0,
		"life": 0.38, "share": 0.25, "pierce": 0, "radius": 4.0, "style": "shard", "color": Color(0.87, 0.85, 0.76)},  # TUNING (not in GDD) bone fragments where the boulder lands
	# --- Act II: Fallen Seraph ---
	"fallen_seraph": {"trigger": "attack", "every": 2, "pattern": "fan", "counts": [3, 5], "spread": 44.0, "speed": 360.0,
		"life": 0.5, "share": 0.3, "pierce": 0, "radius": 3.5, "style": "feather", "color": Color(0.72, 0.74, 0.80)},  # TUNING (not in GDD) fans of black feather blades (an ash-pale tint: shots are drawn additively, black would not show)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"spawn_of_the_deep": {"trigger": "special", "pattern": "ring", "counts": [6, 9], "speed": 230.0,
		"life": 0.45, "share": 0.5, "pierce": 0, "radius": 4.5, "style": "orb", "color": Color(0.45, 0.80, 0.74)},  # TUNING (not in GDD) brine spray from the grasp (share of a squeeze)
	# --- Content wave 2: Bone Golem ---
	"bone_golem": {"trigger": "attack", "every": 1, "pattern": "ring", "counts": [8, 12], "speed": 230.0,
		"life": 0.5, "share": 0.25, "pierce": 0, "radius": 4.5, "style": "shard", "color": Color(0.87, 0.85, 0.76)},  # TUNING (not in GDD) owner-approved: every slam throws a ring of bone shards outward
	# --- Act III: the Assembly Halls ---
	"grave_drone": {"trigger": "attack", "every": 4, "pattern": "seek", "counts": [2, 3], "speed": 360.0,
		"life": 0.6, "share": 0.4, "pierce": 0, "radius": 3.0, "style": "shard", "color": Color(0.87, 0.85, 0.76), "homing": 9.0},  # TUNING (not in GDD) seeking bone splinters
}

## Summon evolution id -> its showpiece volley (replaces the class volley once evolved;
## keys as above, `counts` = [shots]).
const EVOLVED := {
	"death_knight": {"trigger": "attack", "every": 2, "pattern": "fan", "counts": [1], "spread": 0.0, "speed": 240.0,
		"life": 0.85, "share": 0.65, "pierce": 99, "radius": 12.0, "style": "wave", "color": Color(0.55, 0.62, 0.95)},  # TUNING (not in GDD) spectral sword wave, ~200 px, piercing
	"gravebow": {"trigger": "attack", "every": 5, "pattern": "rain", "counts": [12], "speed": 420.0,
		"life": 0.22, "share": 0.35, "pierce": 0, "radius": 5.0, "style": "shard", "color": Color(0.70, 0.95, 0.75), "scatter": 46.0},  # TUNING (not in GDD) arrow rain on the densest pack
	"lich": {"trigger": "special", "pattern": "spiral", "counts": [12], "speed": 190.0,
		"life": 0.8, "share": 0.25, "pierce": 1, "radius": 4.5, "style": "spark", "color": Color(0.64, 0.36, 0.98), "curve": 2.6},  # TUNING (not in GDD) spiral of bolts
	"profane_bishop": {"trigger": "attack", "every": 1, "pattern": "spiral", "counts": [8], "speed": 170.0,
		"life": 0.9, "share": 0.4, "pierce": 1, "radius": 4.5, "style": "orb", "color": Color(0.55, 0.25, 0.85), "curve": 2.4},  # TUNING (not in GDD) ring of 8 dark orbs
	"bone_colossus": {"trigger": "special", "pattern": "ring", "counts": [20], "speed": 250.0,
		"life": 0.55, "share": 0.25, "pierce": 0, "radius": 5.0, "style": "orb", "color": Color(0.55, 0.66, 0.48)},  # TUNING (not in GDD) two rings' worth of chunks
	"shadow_reaper": {"trigger": "special", "pattern": "ring", "counts": [8], "speed": 360.0,
		"life": 0.38, "share": 0.3, "pierce": 1, "radius": 3.0, "style": "dagger", "color": Color(0.74, 0.55, 0.98)},  # TUNING (not in GDD) dagger storm at each dash end
	"cathedral_horror": {"trigger": "special", "pattern": "ring", "counts": [12], "speed": 270.0,
		"life": 0.45, "share": 0.3, "pierce": 1, "radius": 4.0, "style": "feather", "color": Color(0.62, 0.66, 0.74)},  # TUNING (not in GDD) stone feather darts in every direction
	"winter_revenant": {"trigger": "attack", "every": 1, "pattern": "spiral", "counts": [8], "speed": 220.0,
		"life": 0.6, "share": 0.3, "pierce": 1, "radius": 3.5, "style": "shard", "color": Color(0.62, 0.84, 1.0), "curve": 3.0},  # TUNING (not in GDD) blizzard swirl
	"hellhound": {"trigger": "attack", "every": 3, "pattern": "fan", "counts": [4], "spread": 50.0, "speed": 340.0,
		"life": 0.5, "share": 0.3, "pierce": 1, "radius": 5.0, "style": "orb", "color": Color(1.0, 0.55, 0.15)},  # TUNING (not in GDD) burning ghost wolves
	"keening_lady": {"trigger": "special", "pattern": "ring", "counts": [16], "speed": 220.0,
		"life": 0.6, "share": 0.45, "pierce": 1, "radius": 4.0, "style": "note", "color": Color(0.80, 0.70, 1.0)},  # TUNING (not in GDD) each of the three waves
	"ossuary_engine": {"trigger": "special", "pattern": "ring", "counts": [8], "speed": 240.0,
		"life": 0.42, "share": 0.25, "pierce": 0, "radius": 4.0, "style": "shard", "color": Color(1.0, 0.62, 0.30)},  # TUNING (not in GDD) burning bone fragments
	# --- Act II: Fallen Seraph ---
	"ruin_seraph": {"trigger": "special", "pattern": "spiral", "counts": [12], "speed": 230.0,
		"life": 0.6, "share": 0.3, "pierce": 1, "radius": 3.5, "style": "feather", "color": Color(0.72, 0.74, 0.80), "curve": 2.4},  # TUNING (not in GDD) a whirl of black feathers at every dive impact
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"leviathan": {"trigger": "special", "pattern": "spiral", "counts": [14], "speed": 210.0,
		"life": 0.6, "share": 0.4, "pierce": 1, "radius": 5.0, "style": "wave", "color": Color(0.45, 0.80, 0.74), "curve": 2.0},  # TUNING (not in GDD) a whirl of brine with every sweep
	# --- Content wave 2: Bone Golem ---
	"ossuary_titan": {"trigger": "attack", "every": 1, "pattern": "spiral", "counts": [16], "speed": 220.0,
		"life": 0.6, "share": 0.22, "pierce": 1, "radius": 5.0, "style": "shard", "color": Color(0.80, 0.92, 0.84), "curve": 2.2},  # TUNING (not in GDD) a whirl of bone and soul-lit shards with every slam
	# --- Act III: the Assembly Halls ---
	"wraith_drone": {"trigger": "attack", "every": 3, "pattern": "seek", "counts": [5], "speed": 380.0,
		"life": 0.7, "share": 0.35, "pierce": 1, "radius": 3.5, "style": "spark", "color": Color(0.66, 1.0, 0.82), "homing": 10.0},  # TUNING (not in GDD) a flight of soul-lit wraith darts
}

# --- Spell echoes (every owned spell from LEVEL_ON) --------------------------------------

## Spell echo: each owned spell at LEVEL_ON+ releases its echo volley every `every`
## of its own cooldowns (the cooldown key named by `clock`), aimed from the necromancer
## at the target the spell would pick (`aim`: "nearest", "densest" or "strongest").
## Damage per shot = share x the spell's effective damage. Keys as the summon volleys,
## plus `clock`, `aim` and the optional `flat` (base damage for a spell without a
## damage stat); `counts` = [Lv 3-4, Lv 5, evolved].
const SPELLS := {
	"shadow_bolt": {"every": 1, "clock": "cooldown", "aim": "nearest", "pattern": "fan", "counts": [2, 4, 8], "spread": 40.0,
		"speed": 420.0, "life": 0.7, "share": 0.25, "pierce": 0, "radius": 4.0, "style": "orb", "color": Color(0.64, 0.36, 0.98)},  # TUNING (not in GDD)
	"orb_shield": {"every": 1, "clock": "recharge", "aim": "nearest", "pattern": "spiral", "counts": [5, 8, 12], "speed": 200.0,
		"life": 0.8, "share": 0.35, "pierce": 1, "radius": 4.0, "style": "orb", "color": Color(0.55, 0.30, 0.90), "curve": 2.2},  # TUNING (not in GDD)
	"shadow_blast": {"every": 1, "clock": "cooldown", "aim": "densest", "pattern": "ring", "counts": [8, 12, 16], "speed": 260.0,
		"life": 0.45, "share": 0.2, "pierce": 0, "radius": 4.0, "style": "spark", "color": Color(0.64, 0.36, 0.98)},  # TUNING (not in GDD)
	"bone_spear": {"every": 1, "clock": "cooldown", "aim": "nearest", "pattern": "fan", "counts": [2, 4, 6], "spread": 24.0,
		"speed": 520.0, "life": 0.6, "share": 0.3, "pierce": 1, "radius": 3.5, "style": "shard", "color": Color(0.87, 0.85, 0.76)},  # TUNING (not in GDD)
	"soul_siphon": {"every": 2, "clock": "cooldown", "aim": "nearest", "pattern": "seek", "counts": [3, 5, 8], "speed": 260.0,
		"life": 1.0, "share": 0.8, "pierce": 0, "radius": 3.5, "style": "spark", "color": Color(0.42, 0.95, 0.55), "homing": 7.0},  # TUNING (not in GDD)
	"corpse_explosion": {"every": 1, "clock": "cooldown", "aim": "densest", "pattern": "ring", "counts": [8, 12, 16], "speed": 240.0,
		"life": 0.45, "share": 0.18, "pierce": 0, "radius": 4.0, "style": "orb", "color": Color(0.55, 0.66, 0.48)},  # TUNING (not in GDD)
	"plague_cloud": {"every": 1, "clock": "cooldown", "aim": "densest", "pattern": "spiral", "counts": [6, 8, 12], "speed": 120.0,
		"life": 1.1, "share": 1.2, "pierce": 2, "radius": 5.0, "style": "orb", "color": Color(0.55, 0.80, 0.35), "curve": 1.4},  # TUNING (not in GDD) drifting spores (share of a tick)
	"death_mark": {"every": 1, "clock": "cooldown", "aim": "strongest", "pattern": "seek", "counts": [2, 3, 5], "speed": 300.0,
		"life": 1.0, "share": 1.5, "pierce": 0, "radius": 4.0, "style": "spark", "color": Color(0.70, 0.40, 0.95), "homing": 8.0},  # TUNING (not in GDD) seeking skulls (share of a tick)
	"bone_wall": {"every": 1, "clock": "cooldown", "aim": "nearest", "pattern": "fan", "counts": [5, 7, 11], "spread": 70.0,
		"speed": 300.0, "life": 0.5, "share": 1.2, "pierce": 1, "radius": 3.5, "style": "shard", "color": Color(0.87, 0.85, 0.76)},  # TUNING (not in GDD) (share of a spike tick)
	"soul_chains": {"every": 1, "clock": "cooldown", "aim": "nearest", "pattern": "seek", "counts": [3, 5, 7], "speed": 420.0,
		"life": 0.6, "share": 0.25, "pierce": 0, "radius": 3.0, "style": "spark", "color": Color(0.55, 0.90, 1.0), "homing": 10.0},  # TUNING (not in GDD)
	"wither": {"every": 2, "clock": "cooldown", "aim": "nearest", "pattern": "ring", "counts": [8, 10, 14], "speed": 150.0,
		"life": 0.7, "share": 0.6, "pierce": 1, "radius": 4.0, "style": "orb", "color": Color(0.40, 0.30, 0.55)},  # TUNING (not in GDD) (share of a pulse)
	"raise_dead": {"every": 1, "clock": "cooldown", "aim": "densest", "pattern": "rain", "counts": [6, 9, 14], "speed": 420.0,
		"life": 0.22, "share": 1.0, "pierce": 0, "radius": 5.0, "style": "shard", "color": Color(0.87, 0.85, 0.76), "scatter": 50.0, "flat": 14.0},  # TUNING (not in GDD) bone rain; the spell has no damage key: `flat` = the base damage
	# --- Act II: Gullhaven Harbour ---
	"undertow": {"every": 1, "clock": "cooldown", "aim": "densest", "pattern": "fan", "counts": [4, 6, 9], "spread": 60.0,
		"speed": 300.0, "life": 0.55, "share": 0.25, "pierce": 1, "radius": 4.0, "style": "wave", "color": Color(0.36, 0.62, 0.78)},  # TUNING (not in GDD) spray of brine
	# --- Act II: the Hollow Archive ---
	"forbidden_verse": {"every": 1, "clock": "cooldown", "aim": "nearest", "pattern": "spiral", "counts": [6, 9, 14], "speed": 210.0,
		"life": 0.75, "share": 0.5, "pierce": 1, "radius": 4.0, "style": "feather", "color": Color(0.90, 0.86, 0.74), "curve": 2.0},  # TUNING (not in GDD) a swirl of loose pages at each sweep (share of a cut)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"call_of_the_drowned": {"every": 1, "clock": "cooldown", "aim": "strongest", "pattern": "seek", "counts": [3, 5, 8], "speed": 240.0,
		"life": 1.0, "share": 0.3, "pierce": 0, "radius": 4.0, "style": "spark", "color": Color(0.45, 0.80, 0.74), "homing": 7.0},  # TUNING (not in GDD) drowned souls that seek the strongest foe
	# --- Act III: the Assembly Halls ---
	"hollow_puppet": {"every": 1, "clock": "cooldown", "aim": "strongest", "pattern": "seek", "counts": [3, 4, 6], "speed": 260.0,
		"life": 1.0, "share": 0.4, "pierce": 0, "radius": 4.0, "style": "spark", "color": Color(0.64, 0.36, 0.98), "homing": 8.0},  # TUNING (not in GDD) loose soul strings lashing out (share of a puppet hit)
	# --- Act III: the Scrap Wastes ---
	"death_ray": {"every": 1, "clock": "cooldown", "aim": "nearest", "pattern": "ring", "counts": [8, 12, 16], "speed": 320.0,
		"life": 0.5, "share": 0.2, "pierce": 1, "radius": 3.5, "style": "spark", "color": Color(0.80, 0.62, 1.0)},  # TUNING (not in GDD) a ring of violet sparks with each sweep
}
## Range (px) within which a spell echo looks for its target (no target, no echo).
const SPELL_RANGE: float = 340.0  # TUNING (not in GDD)
## "densest" aim: how many of the nearest enemies are compared ...
const DENSE_CANDIDATES: int = 8  # TUNING (not in GDD)
## ... by how many enemies stand within this radius (px) of each.
const DENSE_RADIUS: float = 60.0  # TUNING (not in GDD)
