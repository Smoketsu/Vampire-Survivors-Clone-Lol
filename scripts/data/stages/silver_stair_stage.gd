## SilverStairStage — STAGE 37 (temporary number; final stage 28), THE SILVER STAIR
## (temporary Act XIII, the Celestial Host, final slot X; GDD §15.0 "The
## Celestial Host foundation (phase 1)" and "The Silver Stair (Act XIII phase
## 2)"; design docs/proposals/LAST_SIX_ACTS.md section X, "Stage 28: The Silver
## Stair"). A stair of light rising from hell's ashes into the clouds.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (Osiris's
## fall in the Hall of Two Truths opens it); it runs the Host's three shared
## rules ("host": true: Judgment, Hallowed Light, Grace) and its own systems
## (SilverStairDirector, STAGE "silver_stair"): THE STAIR (each zone a wider
## step: the Light widens, and low cloud banks settle round the necromancer as
## the shadows that hide from it), WITHOUT SIN, and the Cherub of the Gate
## (the miniboss, at 12:00). Its kinds: the shared Host with the Cherub (a
## guardian, the stage's block in HostEnemyData; from 6:00). Its boss is
## Seraiel, Warden of the Gate (BossSeraiel: the Sword, the Gate, the Trial).
## The Last Trumpet is its Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Ashen Foot, the Stair, the
## Cloud Shelf, the Gate of Pearl.
## Seraiel arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot X (docs/last_acts/PLAN.md: at or just above
## the Inferno), not its temporary number. Every rate, cap and weight is
## TUNING (not in GDD).
class_name SilverStairStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "silver_stair"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot X sits at or just above the Inferno's 1.75; a little lower here,
## because Grace's halos shrug off the first hit of every kind of damage).
const ENEMY_HP_MULT: float = 1.7  # TUNING (not in GDD) phase 2 (the stub's)
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Inferno's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) phase 2 (the stub's)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.0  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 1 of the act

## The obstacle layout every zone shares the kinds of (the Host art's sprites
## obstacles/<kind>_m, one size each; HostGlyphs without art). Rect kinds lie
## either way (no "orient": the art has its `_v` turn):
##   host_pillar     — a pillar of white stone with a band of light (circle;
##                     its shadow is safe from the Light).
##   host_cloudstone — a cloud-wrapped block of the stair (rect).
## Footprints: host_pillar a circle of 10 px (art 24x46), host_cloudstone a
## rect 40 x 12 px (art 46x30 / 30x46); only the weights change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## SilverStairGround style over the stair, the zone's floor tile
## tiles/silver_stair_<style>; "step": px between two step edges, wider each
## zone) and its obstacle layout ("arena"):
##   ashen_foot  — the Ashen Foot: hell's ash on the first step of light.
##   stair       — the Stair: wide pale steps, pillars along them.
##   cloud_shelf — the Cloud Shelf: steps among cloud; more cloudstones.
##   pearl_gate  — the Gate of Pearl: pearl flagstones and white pillars.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Ashen Foot", "id": "ashen_foot",  # Owner-approved proposal (zones)
		"blurb": "Hell's ash under the first step of light",
		"ground": {"style": "ashen_foot", "step": 72.0, "base": Color(0.17, 0.17, 0.21), "line": Color(0.27, 0.28, 0.35),
			"accent": Palette.HOST_SILVER, "trim": Palette.HOST_CERULEAN},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 3737,  # TUNING (not in GDD)
			"kinds": {"host_cloudstone": {"weight": 0.6, "shape": "rect", "sizes": [40.0], "short": 12.0}, "host_pillar": {"weight": 0.4, "shape": "circle", "sizes": [10.0]}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Stair", "id": "stair",  # Owner-approved proposal (zones)
		"blurb": "Wide pale steps climbing toward the clouds",
		"ground": {"style": "stair", "step": 96.0, "base": Color(0.21, 0.23, 0.31), "line": Color(0.31, 0.34, 0.44),
			"accent": Palette.HOST_SILVER, "trim": Palette.HOST_CERULEAN},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 3747,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.55, "shape": "circle", "sizes": [10.0]}, "host_cloudstone": {"weight": 0.45, "shape": "rect", "sizes": [40.0], "short": 12.0}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Cloud Shelf", "id": "cloud_shelf",  # Owner-approved proposal (zones)
		"blurb": "Steps among the clouds, where the low banks hide you from the light",
		"ground": {"style": "cloud_shelf", "step": 120.0, "base": Color(0.22, 0.25, 0.34), "line": Color(0.33, 0.37, 0.48),
			"accent": Palette.HOST_CLOUD, "trim": Palette.HOST_CERULEAN},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 3757,  # TUNING (not in GDD)
			"kinds": {"host_cloudstone": {"weight": 0.7, "shape": "rect", "sizes": [40.0], "short": 12.0}, "host_pillar": {"weight": 0.3, "shape": "circle", "sizes": [10.0]}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Gate of Pearl", "id": "pearl_gate",  # Owner-approved proposal (zones)
		"blurb": "Pearl flagstones before the gate Seraiel keeps",
		"ground": {"style": "pearl_gate", "step": 144.0, "base": Color(0.24, 0.26, 0.34), "line": Color(0.36, 0.38, 0.48),
			"accent": Palette.HOST_STARLIGHT, "trim": Palette.HOST_ROSE},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 3767,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.65, "shape": "circle", "sizes": [10.0]}, "host_cloudstone": {"weight": 0.35, "shape": "rect", "sizes": [40.0], "short": 12.0}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE SILVER STAIR  -  STEP %s",  # TUNING (not in GDD)
	"zone_color": Color(0.80, 0.86, 0.96),  # Pale silver (Palette.HOST_SILVER's light): never the player's true gold.
	"fog_color": Color(0.12, 0.13, 0.18),  # Ash under the stair.
	"fog_bank_color": Color(0.80, 0.84, 0.92),  # Cloud.
	"zones": ZONES,
}

## The Silver Stair's stage systems (SilverStairDirector; StageRegistry
## "silver_stair").
##   steps — THE STAIR, one step per zone (by `start` s): the Light's
##           width_mult becomes `width` (relative to the last step); from
##           bank_first s into the step, every bank_every s `banks` low cloud
##           banks of bank_radius px settle bank_min..bank_max px from a
##           standing necromancer (seeded angles) for bank_life s
##           (CloudShade.add_shade()).
##   cherub_objective   — HUD objective while the Cherub of the Gate stands.
##   without_sin_banner — banner when Without Sin is earned.
const STAIR := {
	"steps": [
		{"start": 0.0, "width": 1.0, "bank_first": 40.0, "bank_every": 40.0, "banks": 2, "bank_radius": 70.0,  # TUNING (not in GDD) the Ashen Foot
			"bank_min": 150.0, "bank_max": 320.0, "bank_life": 30.0},  # TUNING (not in GDD)
		{"start": 300.0, "width": 1.08, "bank_first": 4.0, "bank_every": 36.0, "banks": 2, "bank_radius": 74.0,  # TUNING (not in GDD) the Stair: a wider step
			"bank_min": 150.0, "bank_max": 320.0, "bank_life": 30.0},  # TUNING (not in GDD)
		{"start": 600.0, "width": 1.16, "bank_first": 4.0, "bank_every": 30.0, "banks": 3, "bank_radius": 84.0,  # TUNING (not in GDD) the Cloud Shelf: wider, and more cloud
			"bank_min": 140.0, "bank_max": 300.0, "bank_life": 28.0},  # TUNING (not in GDD)
		{"start": 900.0, "width": 1.24, "bank_first": 4.0, "bank_every": 34.0, "banks": 2, "bank_radius": 72.0,  # TUNING (not in GDD) the Gate of Pearl: the widest step
			"bank_min": 150.0, "bank_max": 320.0, "bank_life": 28.0},  # TUNING (not in GDD)
	],
	"cherub_objective": "Bring down the Cherub of the Gate: its sword never stops turning. Stay out of its reach",  # TUNING (not in GDD)
	"without_sin_banner": "WITHOUT SIN: the scales never passed their first third!",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the LAST
## TRUMPET, shared by every Host stage: seven trumpets sound one after another
## ("kind": the Dominion, with the shared kinds as companions); each fills the
## scales, widens the light and doubles the Host, and the sky opens
## ("last_trumpet": HostRulesData.TRUMPET keys; {} = those defaults).
const RECKONING := {
	"banner": "THE LAST TRUMPET: THE SKY OPENS",
	"kind": HostEnemyData.RECKONING_KIND,  # The shared Last Trumpet heavy (the Dominion).
	"last_trumpet": {},  # HostRulesData.TRUMPET defaults (phase 2 may tune them here).
	"companions": HostEnemyData.RECKONING_COMPANIONS,  # Lesser lights, Virtues, Powers, a Choir Angel.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) Dominions
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE LAST TRUMPET: seven trumpets, and the sky opens. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the lesser
## lights and the soldiers of light lead; the Cherub (a guardian) joins from
## 6:00, rare; the supports stay rare. The Judges come from Judgment, never
## from these weights.
const SEGMENTS := [
	# Zone I, the Ashen Foot.
	{"start": 0.0, "rate": 1.2, "max_alive": 26,  # TUNING (not in GDD) softer than the stub's 1.4 / 30 (seeds 3 and 11: the army bot's first ring never grew)
		"weights": {"lesser_light": 0.8, "virtue": 0.2},
		"objective": "The Ashen Foot: the Host comes down. Every halo shrugs off the first blow of each kind"},
	{"start": 60.0, "rate": 1.5, "max_alive": 34,  # TUNING (not in GDD) stub 1.7 / 40
		"weights": {"lesser_light": 0.66, "virtue": 0.2, "power": 0.14},
		"objective": "The light sweeps the ground: lead your ring into the shadow of a cloud or a pillar"},
	{"start": 180.0, "rate": 1.8, "max_alive": 44,  # TUNING (not in GDD) stub 2.0 / 50
		"weights": {"lesser_light": 0.54, "virtue": 0.2, "power": 0.16, "choir_angel": 0.05, "herald": 0.05},
		"objective": "Every raise and every summon you replace weighs on the scales. At each third a Judge comes for you"},
	# Zone II, the Stair (5:00): each step is wider, and the light with it.
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.4, "virtue": 0.27, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03},
		"objective": "The Stair: every step is wider, and the light with it. Low clouds settle: lead your ring into their shadow"},
	{"start": 360.0, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.39, "virtue": 0.26, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03, "cherub": 0.005},
		"objective": "A Cherub's flaming sword sweeps all around it: stay out of its reach"},
	# Zone III, the Cloud Shelf (10:00): the Cherub of the Gate at 12:00.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.37, "virtue": 0.25, "power": 0.2, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.04, "cherub": 0.008},
		"objective": "The Cloud Shelf: when the scales are full, the Verdict falls on you for 20 s"},
	# Zone IV, the Gate of Pearl (15:00).
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.35, "virtue": 0.25, "power": 0.2, "choir_angel": 0.06, "herald": 0.06, "dominion": 0.05, "cherub": 0.008},
		"objective": "The Gate of Pearl: the whole Host stands against you"},
	# 17:00, the boss: thinner, so the fight is the Gate and the Sword.
	{"start": BOSS_TIME, "rate": 2.0, "max_alive": 56,  # TUNING (not in GDD) thinner during the boss fight (the stub 2.4 / 64)
		"weights": {"lesser_light": 0.4, "virtue": 0.27, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03},
		"objective": "Seraiel has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS), plus the Silver
## Stair's own (SilverStairDirector):
##   "cherub_gate" — the Cherub of the Gate (kind `kind`) comes down on the
##                   spawn ring with an `escort` (groups of {kind, count}); the
##                   stage miniboss.
const EVENTS := [
	# Zone I: the Ashen Foot.
	{"time": 20.0, "type": "wave", "banner": "A swarm of lesser lights descends!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "The Virtues advance behind their mirror masks!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "virtue", "count": 4, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Herald raises his trumpet!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "herald", "count": 1, "elite": false}, {"kind": "power", "count": 3, "elite": false}]},
	{"time": 260.0, "type": "wave", "banner": "A Choir Angel sings: the angels near her heal!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	# Zone II: the Stair.
	{"time": 340.0, "type": "wave", "banner": "A Cherub guards the stair: four faces, and a sword that sweeps all around it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "cherub", "count": 1, "elite": false}, {"kind": "virtue", "count": 4, "elite": false}]},
	{"time": 410.0, "type": "wave", "banner": "A Dominion leads the Powers: their halos come back!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 1, "elite": false}, {"kind": "power", "count": 4, "elite": false}]},
	{"time": 490.0, "type": "wave", "banner": "Two swarms of light at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lesser_light", "count": 12, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}, {"kind": "virtue", "count": 4, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Two Cherubs bar the next step!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "cherub", "count": 2, "elite": false}, {"kind": "power", "count": 3, "elite": false}]},
	# Zone III: the Cloud Shelf.
	{"time": 650.0, "type": "wave", "banner": "The Choir comes down to sing over its soldiers!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "virtue", "count": 8, "elite": false}]},
	{"time": 720.0, "type": "cherub_gate", "banner": "THE CHERUB OF THE GATE! Its flaming sword turns a full circle: stay out of its reach!",  # Owner-approved proposal (miniboss); 8:00 left
		"kind": "cherub_of_the_gate", "elite": false,
		"escort": [{"kind": "virtue", "count": 6}, {"kind": "power", "count": 2}]},  # TUNING (not in GDD)
	{"time": 800.0, "type": "wave", "banner": "A host of Powers, blades of white flame!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "power", "count": 8, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "dominion", "count": 1, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Cherubs in the clouds!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "cherub", "count": 2, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	# Zone IV: the Gate of Pearl.
	{"time": 930.0, "type": "wave", "banner": "The whole Host comes down!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "cherub", "count": 1, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Host gathers before Seraiel!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "virtue", "count": 10, "elite": false}, {"kind": "power", "count": 6, "elite": false}, {"kind": "choir_angel", "count": 1, "elite": false}]},
]

## Seraiel's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "seraiel"). His script is scripts/enemies/host/boss_seraiel.gd (loaded by
## his id); his numbers are SeraielData's.
const BOSS := {
	"id": "seraiel",
	"time": BOSS_TIME,
	"display_name": "Seraiel, Warden of the Gate",
	"short_name": "Seraiel",
	"arrive_banner": "Seraiel, Warden of the Gate, raises his flaming sword before the Gate of Pearl!",
	"defeat_banner": "Seraiel falls, and the Gate of Pearl stands open! Hold out until the end...",
	"dead_objective": "Seraiel is dead. Survive the Last Trumpet... you cannot.",
}

## Placeholder floor of the foundation stub (HostGround "floor" key), kept for
## the other tools that read it; the stage draws SilverStairGround ("ground").
const FLOOR := {
	"style": "stair",  # pale ash steps under cloud.
	"base": Color(0.20, 0.22, 0.30),  # TUNING (not in GDD)
	"line": Color(0.30, 0.33, 0.43),  # TUNING (not in GDD)
	"accent": Palette.HOST_SILVER,  # TUNING (not in GDD)
	"trim": Palette.HOST_CERULEAN,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Silver Stair",
	"short_name": "Silver Stair",
	"chapter": "Chapter XXXVII",  # Temporary (the reorder pass renumbers; final stage 28).
	"act": 13,  # Temporary Act XIII, the Celestial Host (final slot X; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The Silver Stair (Act XIII phase 2)").
	"description": "A stair of light rising from hell's ashes into the clouds: step by step to the Gate of Pearl, where Seraiel keeps the way.",
	"unlock": {"stage": "two_truths", "boss_kills": 1},  # Plan: each stage opens the next
	"unlock_text": "Defeat Osiris in the Hall of Two Truths to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Host stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "silver_stair",  # SilverStairGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"silver_stair": STAIR,  # SilverStairDirector: the Stair's steps and low clouds, Without Sin, the Cherub of the Gate.
	"host": true,  # Judgment, Hallowed Light, Grace (HostRules).
	"judgment": {},  # This stage's Judgment overrides ({} = HostRulesData.JUDGMENT).
	"light": {},  # This stage's Hallowed Light ({} = HostRulesData.LIGHT).
	"clouds": {},  # This stage's fixed cloud banks ({} = HostRulesData.CLOUDS; the Stair adds its low banks).
	"grace": {},  # This stage's Grace ({} = HostRulesData.GRACE).
	"zones": ZONES,  # The four zones.
	# Music key: the Host's own score "Hosanna in the Silence" (SoundData.HOSANNA_SCORE).
	"music": "hosanna",
}
