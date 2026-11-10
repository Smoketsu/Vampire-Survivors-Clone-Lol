## LastDayStage — STAGE 42 (temporary and final stage 42), THE LAST DAY
## (temporary Act XIV, the Age of Titans, its finale, final slot XIV; GDD §15.0
## "The Age of Titans foundation (phase 1)" and "The Last Day (Act XIV phase
## 2)"; design docs/proposals/LAST_SIX_ACTS.md section XIV and
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 2). The impact basin: the sky is
## white, the meteor is the size of a moon, ash falls. Every number and event
## that belongs to this stage. StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (Old
## Ironbrow's fall on the Great Plain opens it); it runs the act's three shared
## rules ("primeval": true: Packs, Herds, Scavengers) and its own systems
## (LastDayDirector, STAGE "last_day"): FIRE FROM THE SKY (meteorites on
## telegraphed circles, both armies hit, faster each zone), the growing meteor
## beside the HUD clock, the Stormwing (the shared flier elite), the Tyrant's
## swallow and roar, and THUNDERWING, THE SKY KING (the miniboss, at 11:30).
## Its boss is Old Gravejaw, the Tyrant King (BossGravejaw: the Roar, the
## Hunt, the Last Day). Its Reckoning is THE EXTINCTION (owner-approved Option
## A, PrimevalRules' Extinction): at 0:00 the necromancer's meteor lands, a 5 s
## white-out under a one-time ward, every enemy dies, every corpse rises as a
## Fossil Host (cap 60) for 30 s (owner answer), and the run ends in victory.
## No lit beacons (owner: later); no epilogue part or closing card until the
## reorder pass.
## Zones (ZONES; clock-driven, MarchDirector): the Scorched Plain, the Ash
## Forest, the Lava Fields and the Impact Rim.
## Old Gravejaw arrives with 3:00 left; the Extinction at 0:00.
## Tuned for the act's FINAL slot XIV (docs/last_acts/PLAN.md: above the
## Concord of Stars), not its temporary number; the hardest of the three
## Titans stages. Every rate, cap and weight is TUNING (not in GDD).
class_name LastDayStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "last_day"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot XIV sits above the Concord: the Crash Site's 2.15 and up; the step is
## in HP).
const ENEMY_HP_MULT: float = 2.2  # TUNING (not in GDD) phase 2 (the stub's 2.6, passes 2.3 and 2.25: the naive bot died on seeds 3, 7 and 11): the Great Plain's 2.2; the meteorites, the Stormwings, the Tyrants and Thunderwing are the finale's step up
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Crash Site's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) phase 2 (the stub's 1.8, passes 1.5 and 1.45): the Great Plain's 1.4 (the stage's own hazards are its step up)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XIII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 3 of the act
## Damage-source tag of a meteorite of Fire from the Sky (stats, the death line).
const METEOR_SOURCE: String = "last_day_meteorite"

## The obstacle kinds of the stage (one size each: the Titans art's sprites
## obstacles/<kind>_m, PrimevalGlyphs without art; every obstacle is SHELTER
## from a stampede, Herds):
##   primeval_rock      — a scorched boulder (circle of 15 px; art 36x36).
##   primeval_fossil    — a fossil rib arch (rect 46 x 12 px; art 52x30).
##   primeval_lava_rock — a cooling lava boulder (circle of 16 px; art 40x40,
##                        phase 2's art; PrimevalGlyphs until then).
## Only the weights and the density change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## LastDayGround style, the zone's floor tile tiles/last_day_<style>) and its
## obstacle layout ("arena"):
##   scorched_plain — the Scorched Plain: scorched earth and ash drifts.
##   ash_forest     — the Ash Forest: grey ash and burnt stumps.
##   lava_fields    — the Lava Fields: black crust, glowing cracks, lava rocks.
##   impact_rim     — the Impact Rim: pale shattered rock under the white sky.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Scorched Plain", "id": "scorched_plain",  # Owner-approved proposal (zones)
		"blurb": "The earth is already burning, and the beasts run from it",
		"ground": {"style": "scorched_plain", "base": Color(0.17, 0.14, 0.12), "line": Color(0.26, 0.22, 0.19),
			"accent": Palette.PRIMEVAL_LAVA, "trim": Palette.PRIMEVAL_INK},  # TUNING (not in GDD)
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 4240,  # TUNING (not in GDD)
			"kinds": {"primeval_rock": {"weight": 0.6, "shape": "circle", "sizes": [15.0]},
				"primeval_fossil": {"weight": 0.4, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Ash Forest", "id": "ash_forest",  # Owner-approved proposal (zones)
		"blurb": "Grey ash where the ferns stood yesterday",
		"ground": {"style": "ash_forest", "base": Color(0.22, 0.21, 0.20), "line": Color(0.31, 0.30, 0.28),
			"accent": Palette.PRIMEVAL_LAVA, "trim": Palette.PRIMEVAL_TAR},  # TUNING (not in GDD)
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 4250,  # TUNING (not in GDD)
			"kinds": {"primeval_rock": {"weight": 0.5, "shape": "circle", "sizes": [15.0]},
				"primeval_fossil": {"weight": 0.5, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Lava Fields", "id": "lava_fields",  # Owner-approved proposal (zones)
		"blurb": "Black crust over the fire beneath",
		"ground": {"style": "lava_fields", "base": Color(0.12, 0.10, 0.09), "line": Color(0.20, 0.16, 0.14),
			"accent": Palette.PRIMEVAL_LAVA, "trim": Palette.PRIMEVAL_INK},  # TUNING (not in GDD)
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 4260,  # TUNING (not in GDD)
			"kinds": {"primeval_lava_rock": {"weight": 0.6, "shape": "circle", "sizes": [16.0]},
				"primeval_rock": {"weight": 0.4, "shape": "circle", "sizes": [15.0]}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Impact Rim", "id": "impact_rim",  # Owner-approved proposal (zones)
		"blurb": "The last day of the world, under a white sky",
		"ground": {"style": "impact_rim", "base": Color(0.30, 0.28, 0.26), "line": Color(0.38, 0.36, 0.33),
			"accent": Palette.PRIMEVAL_BONE, "trim": Palette.PRIMEVAL_TAR},  # TUNING (not in GDD) the white sky in value only
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 4270,  # TUNING (not in GDD)
			"kinds": {"primeval_lava_rock": {"weight": 0.5, "shape": "circle", "sizes": [16.0]},
				"primeval_fossil": {"weight": 0.5, "shape": "rect", "sizes": [46.0], "short": 12.0}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE LAST DAY  -  %s",  # TUNING (not in GDD)
	"zone_color": Color(1.0, 0.70, 0.45),  # The lava ramp's light: never the player's true gold.
	"fog_color": Color(0.14, 0.12, 0.11),  # Ash haze.
	"fog_bank_color": Color(0.62, 0.58, 0.54),  # A cloud of ash.
	"zones": ZONES,
}

## The Last Day's stage systems (LastDayDirector; StageRegistry "last_day"):
##   meteor_first       — s of the first meteorites (Fire from the Sky).
##   meteor_every       — s between two strikes, one per zone (I..IV): the
##                        interval shrinks each zone.
##   meteor_count       — circles per standing necromancer each strike, by zone.
##   meteor_spread      — px round the necromancer a circle lands.
##   meteor_warn        — s a circle shows before the meteorite strikes.
##   meteor_radius      — px of a strike.
##   meteor_player      — damage to the necromancer, before the time scaling.
##   meteor_summon      — damage to each summon, before the time scaling.
##   meteor_enemy_share — share of an enemy's max HP (bosses, minibosses and
##                        structures spared).
##   meteor_show        — drawing only: s the burst stays drawn.
##   thunder_objective  — HUD objective while Thunderwing flies.
const LAST_DAY := {
	"meteor_first": 30.0,  # TUNING (not in GDD) s
	"meteor_every": [12.0, 10.0, 8.0, 6.5],  # Owner-approved proposal: "every 12 s ... the interval shrinking each zone"; TUNING (not in GDD) the later steps
	"meteor_count": [1, 1, 2, 2],  # TUNING (not in GDD) circles per necromancer, by zone (first pass 1, 2, 2, 3)
	"meteor_spread": 300.0,  # TUNING (not in GDD) px
	"meteor_warn": 1.6,  # Owner-approved proposal: "telegraphed circles"; TUNING (not in GDD) s
	"meteor_radius": 56.0,  # TUNING (not in GDD) px
	"meteor_player": 10.0,  # TUNING (not in GDD) before the time scaling (Grave Step's i-frames dodge it)
	"meteor_summon": 11.0,  # Owner-approved proposal: "hurting both armies"; TUNING (not in GDD) per summon, before the time scaling (first pass 14: 14.5k on the army bot's summons, its largest source, seed 7)
	"meteor_enemy_share": 0.35,  # TUNING (not in GDD) share of an enemy's max HP
	"meteor_show": 0.3,  # TUNING (not in GDD) drawing only
	"thunder_objective": "Thunderwing, the Sky King, blows your ring apart: strike him when he lands",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): THE
## EXTINCTION (owner-approved Option A; "extinction": PrimevalRulesData
## .EXTINCTION keys, {} = those defaults; PrimevalRules' Extinction runs it).
## The meteor IS the Reckoning: no swarm is spawned (base_count 0, no
## companions), the waves only show the banner; the run ends in victory 30 s
## after the impact (owner answer).
const RECKONING := {
	"banner": "THE EXTINCTION: THE SKY FALLS. Your meteor is coming!",
	"kind": PrimevalEnemyData.RECKONING_KIND,  # Never spawned here (base_count 0): the row is read only.
	"extinction": {},  # PrimevalRulesData.EXTINCTION defaults.
	"companions": [],  # None: the meteor kills everything.
	"interval": 10.0,  # TUNING (not in GDD) as every stage (the waves spawn nothing)
	"base_count": 0,  # Owner-approved Option A: the Extinction replaces the swarm Reckoning
	"count_growth": 0,  # Owner-approved Option A
	"hp_growth": 1.0,  # Unused (nothing spawns).
	"damage_growth": 1.0,  # Unused (nothing spawns).
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE EXTINCTION: the dead rise for you. The world ends in victory."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a ramp of
## the shared kinds with the Stormwing from 3:30 and the plain's heavies; the
## packs come in the EVENTS (a pack is a group that arrives together), the
## herds from Herds, never from these weights. A thin trickle after 0:00 for
## the Fossil Host to clean up. (First pass: Frill-Spitters 0.05 and
## Stormwings 0.005-0.007: the naive bot died before 12:10 on all three seeds.)
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.955, "frill_spitter": 0.045},
		"objective": "The Scorched Plain: the beasts are hungry, and your army smells of meat"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.925, "frill_spitter": 0.045, "skyraider": 0.03},
		"objective": "Meteorites fall on the circles: they burn both armies. Step out"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.922, "frill_spitter": 0.045, "skyraider": 0.03, "stormwing": 0.003},
		"objective": "The herds stampede when a fight comes close: shelter behind a rock"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.905, "frill_spitter": 0.045, "skyraider": 0.04, "stormwing": 0.004, "horncharger": 0.003, "clubtail": 0.003},
		"objective": "The Ash Forest: Stormwings blow your ring open. Strike them when they land"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.901, "frill_spitter": 0.045, "skyraider": 0.04, "stormwing": 0.004, "horncharger": 0.005, "clubtail": 0.005},
		"objective": "The Lava Fields: a Tyrant swallows your summons whole. Burst it and they cut their way out"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"scuttler": 0.896, "frill_spitter": 0.045, "skyraider": 0.045, "stormwing": 0.004, "horncharger": 0.005, "clubtail": 0.005},
		"objective": "The Impact Rim: the last day of the world"},
	{"start": BOSS_TIME, "rate": 2.0, "max_alive": 56,  # TUNING (not in GDD) thinner during the boss fight (as the other Titans stages)
		"weights": {"scuttler": 0.915, "frill_spitter": 0.045, "skyraider": 0.04},
		"objective": "Old Gravejaw hunts you: slay him before the meteor falls, or his spell is lost"},
	{"start": WaveData.RUN_DURATION, "rate": 1.0, "max_alive": 30,  # TUNING (not in GDD) the last beasts for the Fossil Host
		"weights": {"scuttler": 0.9, "razorclaw": 0.1},
		"objective": "The Fossil Host hunts the last beasts of the world"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Each group of
## Razorclaws is a pack (its first is the alpha). Plus the Last Day's own
## (LastDayDirector):
##   "sky_king" — Thunderwing (kind `kind`) swoops in thunder_dist px ahead of
##                the necromancer with an `escort` (groups of {kind, count});
##                the stage miniboss.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of Scuttlers pours out of the ash!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 75.0, "type": "wave", "banner": "A pack of Razorclaws is hunting you: kill the alpha!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 4, "elite": false}]},
	{"time": 150.0, "type": "wave", "banner": "Skyraiders circle over your crystals!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "skyraider", "count": 3, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 210.0, "type": "wave", "banner": "A Stormwing beats her wings and blows your ring open: strike her when she lands!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "stormwing", "count": 1, "elite": false}, {"kind": "scuttler", "count": 10, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "A bigger pack, and Frill-Spitters behind it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 5, "elite": false}, {"kind": "frill_spitter", "count": 3, "elite": false}]},
	{"time": 360.0, "type": "wave", "banner": "Heavies lumber out of the ash!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "horncharger", "count": 1, "elite": false}, {"kind": "clubtail", "count": 1, "elite": false}, {"kind": "razorclaw", "count": 4, "elite": false}]},
	{"time": 460.0, "type": "wave", "banner": "The Razorclaws come back with Skyraiders above them!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 6, "elite": false}, {"kind": "skyraider", "count": 3, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "A Tyrant walks out of the smoke: it swallows your summons whole!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "tyrant", "count": 1, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
	{"time": 690.0, "type": "sky_king", "banner": "THUNDERWING, THE SKY KING! His wings clear your ring: strike him when he lands!",  # Owner-approved proposal (miniboss); 8:30 left
		"kind": LastDayEnemyData.THUNDERWING, "thunder_dist": 320.0, "elite": false,  # TUNING (not in GDD) px he comes in ahead of the necromancer
		"escort": [{"kind": "scuttler", "count": 8}]},  # TUNING (not in GDD)
	{"time": 780.0, "type": "wave", "banner": "The last great pack!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "frill_spitter", "count": 4, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Every flier under the white sky dives at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "stormwing", "count": 2, "elite": false}, {"kind": "skyraider", "count": 4, "elite": false}]},
	{"time": 980.0, "type": "wave", "banner": "The hunters gather before Old Gravejaw!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "razorclaw", "count": 8, "elite": false}, {"kind": "tyrant", "count": 1, "elite": false}, {"kind": "scuttler", "count": 12, "elite": false}]},
]

## Old Gravejaw's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "gravejaw"). His script is
## scripts/enemies/primeval/boss_gravejaw.gd (loaded by his id); his numbers
## are GravejawData's.
const BOSS := {
	"id": "gravejaw",
	"time": BOSS_TIME,
	"display_name": "Old Gravejaw, the Tyrant King",
	"short_name": "Old Gravejaw",
	"arrive_banner": "Old Gravejaw, the Tyrant King, roars under the white sky!",
	"defeat_banner": "Old Gravejaw falls, and the beasts of the world fall silent! Hold out until the meteor...",
	"dead_objective": "Old Gravejaw is dead. The sky is falling: wait for your meteor.",
}

## Placeholder floor of the foundation stub (PrimevalGround "floor" key), kept
## for the other tools that read it; the stage draws LastDayGround ("ground").
const FLOOR := {
	"style": "ash",  # scorched earth under falling ash.
	"base": Color(0.15, 0.13, 0.12),  # TUNING (not in GDD)
	"line": Color(0.22, 0.19, 0.17),  # TUNING (not in GDD)
	"accent": Palette.PRIMEVAL_LAVA,  # TUNING (not in GDD)
	"trim": Palette.PRIMEVAL_TAR,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Last Day",
	"short_name": "Last Day",
	"chapter": "Chapter XLII",  # Temporary and final stage 42 (the reorder pass renumbers if it moves).
	"act": 14,  # Temporary Act XIV, the Age of Titans (final slot XIV; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The Last Day (Act XIV phase 2)").
	"description": "The impact basin under a white sky: the meteor fills the heavens, and the necromancer has taken its Call for himself.",
	"unlock": {"stage": "great_plain", "boss_kills": 1},  # Plan: each stage opens the next
	"unlock_text": "Defeat Old Ironbrow on the Great Plain to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Titans stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "last_day",  # LastDayGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"last_day": LAST_DAY,  # LastDayDirector: Fire from the Sky, the growing meteor, Thunderwing.
	"primeval": true,  # Packs, Herds, Scavengers (PrimevalRules).
	"packs": {},  # This stage's Packs overrides ({} = PrimevalRulesData.PACKS).
	"herds": {},  # This stage's Herds ({} = PrimevalRulesData.HERDS).
	"scavengers": {},  # This stage's Scavengers ({} = PrimevalRulesData.SCAVENGERS).
	"zones": ZONES,  # The four zones.
	# Music key: "primordial" (the Titans' "Before the Fall", SoundData.PRIMORDIAL_SCORE; its sound pack "titans").
	"music": "primordial",
}
