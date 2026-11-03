## ProvingMoonStage — STAGE 26, THE PROVING MOON (Act IX, the Concord of
## Stars; GDD §15.0 "The Proving Moon (Act IX phase 2)" and the rows after it;
## owner-approved proposal docs/act9/PROPOSAL.md "Stage 26: The Proving Moon",
## with the owner's phase 2 answers of Nov 3, 2026). The Vrask take the
## necromancer to their hunting ground on the moon, to see what he is worth.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## The stage runs the Concord's three shared rules ("concord": true: Beams,
## Abduction and Terraforming, ConcordRules) and the Final Harvest Reckoning.
## One coalition (owner): THE VRASK LEAD here (their hunters heavier in the
## timeline, hunting parties in the events, the Warbeast and Vrask'Tal), their
## Brood beasts as the fodder, the Harvesters' drones and saucers, and the
## Luminous mixed in. LOW GRAVITY: the STAGE key "gravity" (2.0), read only
## through ConcordRules.gravity(): every enemy knockback travels twice as far
## (Enemy's one knockback decay is divided by it), the enemies' shoves on the
## summons are doubled (the shared rush, the Warbeast's and Vrask'Tal's
## throws), and the leaps of this stage's kits reach twice as far (the
## Warbeast's pounce, Vrask'Tal's leap); Grave Step stays a shadow step.
## Four clock-driven zones (ZONES, MarchDirector; ProvingMoonGround draws their
## floors): THE LANDING (grey regolith, boulders), THE CRATERS (crater rims),
## THE TROPHY HALL (dark stone, trophy pillars, hanging skulls; the Warbeast,
## the miniboss, ProvingMoonDirector) and THE DUELLING RING (the marked
## circles). Vrask'Tal, the Hunt-Lord (BossVraskTal, VraskTalData) arrives
## with 3:00 left: the Stalk, the Duel, the Last Trophy; the Reckoning at 0:00.
## Hidden from the stage select ("playable": false) until the lead's
## integration pass.
## Every rate, cap and weight is TUNING (not in GDD).
class_name ProvingMoonStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "proving_moon"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IX starts a step above Liberty Heights's 2.0; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 2.15  # TUNING (not in GDD) brief: a step above Liberty Heights (placeholder, tuned in the balance pass)
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Liberty Heights's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to VIII: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of Act IX

# =====================================================================================
# Zones and their look
# =====================================================================================

## Obstacle kinds of the stage (ProvingMoonGlyphs without art;
## obstacles/<kind>_<size>[_v]); each keeps the same sizes in every zone, so its
## art keys stay the same:
##   moon_boulder  — a grey moon boulder (circle).
##   crater_rim    — a raised ring of regolith around a dark bowl (circle).
##   trophy_pillar — a dark stone pillar hung with the Vrask's skulls (rect).
## The moon boulder's layout entry (shared by every zone).
const BOULDER := {"shape": "circle", "sizes": [12.0, 18.0, 24.0]}  # TUNING (not in GDD)
## The crater rim's layout entry (shared by every zone).
const CRATER_RIM := {"shape": "circle", "sizes": [22.0, 30.0, 38.0]}  # TUNING (not in GDD)
## The trophy pillar's layout entry (shared by every zone).
const TROPHY_PILLAR := {"shape": "rect", "sizes": [40.0, 56.0], "short": 14.0}  # TUNING (not in GDD)

## The four zones (owner-approved proposal names; the clock is authoritative).
## Keys as CrimsonMarchStage.ZONES (MarchDirector). `ground` is a
## ProvingMoonGround look:
##   style  — "landing" (grey regolith, small craters, teal trail markers),
##            "craters" (pitted regolith, crater bowls), "trophy_hall" (dark
##            cut stone, hanging skulls) or "duelling_ring" (packed dust marked
##            with the duellists' circles).
##   base / line / accent / trim — colours of the code floor, its seams, its
##            craters and its teal marks.
## `arena` is the zone's obstacle layout (keys as GraveyardStage.ARENA; each
## kind's entry is one of the constants above plus its weight).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Landing",  # Owner-approved proposal (zones)
		"blurb": "Grey dust where the Vrask set their quarry down",
		"ground": {"style": "landing", "base": Color(0.20, 0.21, 0.24), "line": Color(0.25, 0.26, 0.29),
			"accent": Color(0.13, 0.14, 0.17), "trim": Palette.CONCORD_VRASK},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 2626,  # TUNING (not in GDD)
			"kinds": {
				"moon_boulder": {"weight": 0.75, "shape": BOULDER["shape"], "sizes": BOULDER["sizes"]},  # TUNING (not in GDD)
				"crater_rim": {"weight": 0.25, "shape": CRATER_RIM["shape"], "sizes": CRATER_RIM["sizes"]},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Craters",  # Owner-approved proposal (zones)
		"blurb": "Old impacts, and the hunters waiting in their shadows",
		"ground": {"style": "craters", "base": Color(0.18, 0.19, 0.22), "line": Color(0.27, 0.28, 0.31),
			"accent": Color(0.10, 0.11, 0.13), "trim": Palette.CONCORD_VRASK},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 2636,  # TUNING (not in GDD)
			"kinds": {
				"crater_rim": {"weight": 0.6, "shape": CRATER_RIM["shape"], "sizes": CRATER_RIM["sizes"]},  # TUNING (not in GDD)
				"moon_boulder": {"weight": 0.4, "shape": BOULDER["shape"], "sizes": BOULDER["sizes"]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Trophy Hall",  # Owner-approved proposal (zones)
		"blurb": "The skulls of every world they hunted, and their hound",
		"ground": {"style": "trophy_hall", "base": Color(0.12, 0.13, 0.15), "line": Color(0.07, 0.08, 0.09),
			"accent": Palette.CONCORD_GUNMETAL_DARK, "trim": Palette.CONCORD_VRASK},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 2646,  # TUNING (not in GDD)
			"kinds": {
				"trophy_pillar": {"weight": 0.5, "shape": TROPHY_PILLAR["shape"], "sizes": TROPHY_PILLAR["sizes"], "short": TROPHY_PILLAR["short"]},  # TUNING (not in GDD)
				"moon_boulder": {"weight": 0.5, "shape": BOULDER["shape"], "sizes": BOULDER["sizes"]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Duelling Ring",  # Owner-approved proposal (zones)
		"blurb": "The marked circle where the Hunt-Lord meets his prey",
		"ground": {"style": "duelling_ring", "base": Color(0.22, 0.22, 0.24), "line": Color(0.30, 0.30, 0.33),
			"accent": Color(0.15, 0.15, 0.17), "trim": Palette.CONCORD_VRASK},
		"arena": {"density": 0.13, "clear_radius": 240.0, "layout_seed": 2656,  # TUNING (not in GDD) the open ring
			"kinds": {
				"moon_boulder": {"weight": 0.7, "shape": BOULDER["shape"], "sizes": BOULDER["sizes"]},  # TUNING (not in GDD)
				"trophy_pillar": {"weight": 0.3, "shape": TROPHY_PILLAR["shape"], "sizes": TROPHY_PILLAR["sizes"], "short": TROPHY_PILLAR["short"]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE PROVING MOON  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.86, 0.89, 0.93),  # Moonlight white (the hull's light), never the UI's soul-teal.
	"fog_color": Color(0.05, 0.06, 0.09),  # The black sky.
	"fog_bank_color": Color(0.42, 0.44, 0.48),  # Grey moon dust.
	"zones": ZONES,
}

## Terraforming on this stage: {} = the defaults of
## ConcordRulesData.TERRAFORMING (any of its keys overrides them here).
const TERRAFORMING := {}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the FINAL
## HARVEST, shared by every Act IX stage: the mothership's eye opens over the
## arena and sweeps it with its beam, saucers fill the sky ("kind": the
## saucer, with the shared kinds as companions), and the abduction cap is gone
## ("final_harvest": ConcordRulesData.FINAL_HARVEST keys; {} = those
## defaults). The pods keep falling.
const RECKONING := {
	"banner": "THE FINAL HARVEST: THE MOTHERSHIP OPENS ITS EYE",
	"kind": ConcordEnemyData.RECKONING_KIND,  # The shared Final Harvest heavy (the saucer).
	"final_harvest": {},  # ConcordRulesData.FINAL_HARVEST defaults.
	"companions": ConcordEnemyData.RECKONING_COMPANIONS,  # Broodlings, grey drones, a Vrask hunter, a Lumen Sentinel.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) saucers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE FINAL HARVEST: the eye sweeps the world, and the saucers take your dead. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the Vrask
## lead (their hunters a heavier share of the trickle than on the other Act IX
## stages), their Brood beasts the fodder, the Harvesters' drones and saucers
## and the Luminous mixed in.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"broodling": 0.8, "grey_drone": 0.15, "vrask_hunter": 0.05},
		"objective": "The Landing: the Vrask's quarry is you. Their beasts come first"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"broodling": 0.64, "grey_drone": 0.28, "vrask_hunter": 0.08},
		"objective": "A shimmer that moves is a hunter. Your spells reveal it"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"broodling": 0.58, "grey_drone": 0.24, "vrask_hunter": 0.09, "lumen_sentinel": 0.06, "prism": 0.03},
		"objective": "Three red dots are a hunter's lock: step aside before it fires"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"broodling": 0.58, "grey_drone": 0.2, "vrask_hunter": 0.1, "lumen_sentinel": 0.06, "prism": 0.03, "saucer": 0.03},
		"objective": "The Craters: low gravity throws everything twice as far"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"broodling": 0.565, "grey_drone": 0.2, "vrask_hunter": 0.11, "lumen_sentinel": 0.065, "prism": 0.03, "saucer": 0.03},
		"objective": "The Trophy Hall: the alien ground heals the Concord. Burn it back with your spells"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"broodling": 0.55, "grey_drone": 0.2, "vrask_hunter": 0.12, "lumen_sentinel": 0.065, "prism": 0.03, "saucer": 0.035},
		"objective": "The Duelling Ring: the hunters gather for their Hunt-Lord"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"broodling": 0.62, "grey_drone": 0.22, "vrask_hunter": 0.07, "lumen_sentinel": 0.05, "prism": 0.02, "saucer": 0.02},
		"objective": "Vrask'Tal has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus "warbeast":
## ProvingMoonDirector's miniboss, with an "escort" list of {kind, count}).
## Broodlings come in swarms of 12 (owner-approved proposal), grey drones in
## squads, the Vrask in hunting parties.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The Vrask loose their Brood on the moon!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 95.0, "type": "wave", "banner": "A hunting party: two Vrask hunters stalk your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 2, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 160.0, "type": "wave", "banner": "A saucer drifts over your ring! Shoot it down before it takes your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 1, "elite": false}, {"kind": "grey_drone", "count": 4, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "The Luminous! A Star-Seer splits their beams!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 1, "elite": false}, {"kind": "prism", "count": 1, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "The hunt moves into the Craters: three hunters!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 3, "elite": false}, {"kind": "grey_drone", "count": 4, "elite": false}]},
	{"time": 450.0, "type": "wave", "banner": "Two swarms at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "vrask_hunter", "count": 1, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Saucers over the Craters!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 2, "elite": false}, {"kind": "grey_drone", "count": 5, "elite": false}]},
	{"time": 690.0, "type": "warbeast", "banner": "THE WARBEAST is loosed in the Trophy Hall! Mind its pounce!", "kind": "warbeast",  # TUNING (not in GDD) the miniboss
		"escort": [{"kind": "vrask_hunter", "count": 2}]},
	{"time": 780.0, "type": "wave", "banner": "The Luminous line their beams up!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 2, "elite": false}, {"kind": "prism", "count": 1, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 870.0, "type": "wave", "banner": "A great hunting party!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 3, "elite": false}, {"kind": "saucer", "count": 1, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 960.0, "type": "wave", "banner": "The hunters gather in the Duelling Ring for their Hunt-Lord!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 2, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "lumen_sentinel", "count": 1, "elite": false}]},
]

## Vrask'Tal's arrival (keys as GraveyardStage.BOSS): his own
## VraskTalData.ARRIVAL (boss id "vrask_tal"), whose `time` equals BOSS_TIME
## (17:00). His script is scripts/enemies/concord/boss_vrask_tal.gd (loaded by
## his id).
const BOSS: Dictionary = VraskTalData.ARRIVAL

## The Proving Moon's stage systems (ProvingMoonDirector; StageRegistry
## "proving_moon").
##   warbeast_objective — the HUD objective while the Warbeast stands.
##   trophy_objective   — the HUD countdown text while the Last Trophy counts
##                        down (%d: seconds left).
const PROVING_MOON := {
	"warbeast_objective": "The Warbeast hunts you: step out of its pounce, and break its plates",  # TUNING (not in GDD)
	"trophy_objective": "THE LAST TROPHY in %d s: kill Vrask'Tal before his bomb goes off, and keep away from him!",  # TUNING (not in GDD)
}

## The foundation stub's floor (ConcordGround "floor" key), kept for the other
## tools that read it; the stage draws ProvingMoonGround ("ground").
const FLOOR := {
	"style": "moon",  # Grey regolith, small craters, the Vrask's teal trail markers.
	"base": Color(0.20, 0.21, 0.24),  # TUNING (not in GDD) grey regolith
	"line": Color(0.25, 0.26, 0.29),  # TUNING (not in GDD)
	"accent": Color(0.13, 0.14, 0.17),  # TUNING (not in GDD) crater shadows
	"trim": Palette.CONCORD_VRASK,  # TUNING (not in GDD) the hunters' trail markers
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Proving Moon",
	"short_name": "Proving Moon",
	"chapter": "Chapter XXVI",
	"act": 9,  # Act IX, the Concord of Stars.
	"playable": false,  # Phase 2 built; the lead's integration pass opens it.
	"description": "The Vrask take the necromancer to their hunting ground on the moon, to see what he is worth.",
	"unlock": {"stage": "crash_site", "boss_kills": 1},  # Brief: each Act IX stage opens the next
	"unlock_text": "Defeat the Hive Mother at the Crash Site to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IX stages.
	"gravity": 2.0,  # Owner-approved proposal: low gravity, "knockback goes twice as far for everyone ... and leaps are longer" (ConcordRules.gravity(), the one read)
	"consecration": {},  # A Covenant event: none in Act IX.
	"crypt_defender": {},  # None in Act IX.
	"arena": ZONES[0]["arena"],
	"ground": "proving_moon",  # ProvingMoonGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"concord": true,  # Act IX: Beams, Abduction, Terraforming (ConcordRules).
	"terraforming": TERRAFORMING,  # Act IX: this stage's Terraforming overrides ({} = the defaults).
	"zones": ZONES,  # Act IX: the four zones.
	"proving_moon": PROVING_MOON,  # ProvingMoonDirector: the Warbeast, the Last Trophy's countdown.
	# Music: "The Reaping Stars" (SoundData.STARSONG_SCORE).
	"music": "starsong",
}
