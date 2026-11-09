## EmpyreanStage — STAGE 39 (temporary number; final stage 30), THE EMPYREAN
## (temporary Act XIII, the Celestial Host, final slot X; GDD §15.0 "The
## Celestial Host foundation (phase 1)"; design docs/proposals/LAST_SIX_ACTS.md
## section X). The highest heaven: a white rose of light, endless and silent.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: FOUNDATION STUB (phase 1). The stage is registered, unlocked in the
## campaign chain, runs the Host's three shared rules ("host": true:
## Judgment, Hallowed Light, Grace) and plays a simple timeline of ALL the
## shared kinds (so every rule shows) against a PLACEHOLDER boss script (the
## "vael" boss script under The Voice's name), with the Last Trumpet
## Reckoning (seven trumpets: the scales fill, the light widens, the Host
## doubles, the sky opens). It is hidden from the stage select ("playable":
## false) until phase 2 builds it: the Choir (every Choir Angel alive widens the light), the Herald of the Seventh Trumpet (the miniboss) and the Voice (the Holy, Be Not Afraid, the Last Word) with the act's ending.
## Planned zones (ZONES; clock-driven like every stage): The Rose's Edge, The Petals, The Choir and The Heart of the Rose.
## The Voice arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot X (docs/last_acts/PLAN.md: at or just above
## the Inferno), not its temporary number. Every rate, cap and weight is
## TUNING (not in GDD).
class_name EmpyreanStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "empyrean"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot X sits at or just above the Inferno's 1.75; a little lower here,
## because Grace's halos shrug off the first hit of every kind of damage).
const ENEMY_HP_MULT: float = 1.8  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Inferno's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.6  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 3 of the act

## The four zones phase 2 builds (names from the proposal), each from `start`
## game seconds. The stub has one placeholder floor.
const ZONES := [
	{"id": "rose_edge", "name": "The Rose's Edge", "start": 0.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "petals", "name": "The Petals", "start": 300.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "choir", "name": "The Choir", "start": 600.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
	{"id": "heart", "name": "The Heart of the Rose", "start": 900.0},  # Owner-approved proposal (names); TUNING (not in GDD) times
]

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

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): a plain ramp
## of the shared kinds (placeholder); the supports stay rare. The Judges come
## from Judgment, never from these weights.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.7, "virtue": 0.3},
		"objective": "The Rose's Edge: the Host comes down. Every halo shrugs off the first blow of each kind"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.55, "virtue": 0.3, "power": 0.15},
		"objective": "The light sweeps the ground: lead your ring into the shadow of a cloud or a pillar"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.45, "virtue": 0.27, "power": 0.18, "choir_angel": 0.05, "herald": 0.05},
		"objective": "Every raise and every summon you replace weighs on the scales. At each third a Judge comes for you"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.4, "virtue": 0.27, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03},
		"objective": "The Petals: a Dominion's halos come back. Kill him first"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.38, "virtue": 0.26, "power": 0.2, "choir_angel": 0.06, "herald": 0.06, "dominion": 0.04},
		"objective": "The Choir: when the scales are full, the Verdict falls on you for 20 s"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.36, "virtue": 0.26, "power": 0.2, "choir_angel": 0.07, "herald": 0.06, "dominion": 0.05},
		"objective": "The Heart of the Rose: the whole Host stands against you"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"lesser_light": 0.4, "virtue": 0.27, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03},
		"objective": "The Voice has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "A swarm of lesser lights descends!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "The Virtues advance behind their mirror masks!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "virtue", "count": 6, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Herald raises his trumpet!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "herald", "count": 1, "elite": false}, {"kind": "power", "count": 3, "elite": false}]},
	{"time": 260.0, "type": "wave", "banner": "A Choir Angel sings: the angels near her heal!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 380.0, "type": "wave", "banner": "A Dominion leads the Powers: their halos come back!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 1, "elite": false}, {"kind": "power", "count": 4, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "Two swarms of light at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lesser_light", "count": 12, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}, {"kind": "virtue", "count": 4, "elite": false}]},
	{"time": 640.0, "type": "wave", "banner": "The Choir comes down to sing over its soldiers!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "virtue", "count": 8, "elite": false}]},
	{"time": 780.0, "type": "wave", "banner": "A host of Powers, blades of white flame!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "power", "count": 8, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "dominion", "count": 1, "elite": false}]},
	{"time": 930.0, "type": "wave", "banner": "The whole Host comes down!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Host gathers before The Voice!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "virtue", "count": 10, "elite": false}, {"kind": "power", "count": 6, "elite": false}, {"kind": "choir_angel", "count": 1, "elite": false}]},
]

## Obstacle layout (keys as GraveyardStage.ARENA): the normal scattered-obstacle
## arena (each obstacle casts a pillar's shadow, safe from the Hallowed Light).
## Placeholder kinds drawn by HostGlyphs until phase 2 brings the stage's art.
const ARENA := {
	"density": 0.2,  # TUNING (not in GDD)
	"clear_radius": 220.0,  # TUNING (not in GDD)
	"layout_seed": 3939,  # TUNING (not in GDD) (also salts the cloud banks)
	"kinds": {
		"host_pillar": {"weight": 0.40, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD) placeholder art (a pillar of white stone)
		"host_petal": {"weight": 0.60, "shape": "rect", "sizes": [20.0, 28.0], "short": 9.0},  # TUNING (not in GDD) placeholder art (a standing petal of light)
	},
}

## The stage boss's arrival (keys as GraveyardStage.BOSS, plus "script": the
## boss script when it differs from the id). PLACEHOLDER: the "vael" boss script
## under The Voice's name until phase 2 adds
## scripts/enemies/host/boss_voice.gd (then remove the "script" key).
const BOSS := {
	"id": "voice",
	"script": "vael",  # PLACEHOLDER boss script until phase 2 adds boss_voice.gd (then remove this key).
	"time": BOSS_TIME,
	"display_name": "The Voice",
	"short_name": "The Voice",
	"arrive_banner": "The Voice spreads two of its six wings. Its face is still hidden.",
	"defeat_banner": "The Voice folds its wings and is silent! Hold out until the end...",
	"dead_objective": "The Voice is silent. Survive the Last Trumpet... you cannot.",
}

## Placeholder floor (HostGround, code-drawn) until phase 2 brings the stage's
## zone floors: base colour, joint lines, accent, trim, style.
const FLOOR := {
	"style": "rose",  # white rose petals of light.
	"base": Color(0.78, 0.80, 0.86),  # TUNING (not in GDD)
	"line": Color(0.70, 0.72, 0.80),  # TUNING (not in GDD)
	"accent": Palette.HOST_SILVER,  # TUNING (not in GDD)
	"trim": Palette.HOST_CERULEAN,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Empyrean",
	"short_name": "Empyrean",
	"chapter": "Chapter XXXIX",  # Temporary (the reorder pass renumbers; final stage 30).
	"act": 13,  # Temporary Act XIII, the Celestial Host (final slot X; docs/last_acts/PLAN.md).
	"playable": false,  # Foundation stub: hidden from the stage select until phase 2.
	"description": "The highest heaven: a white rose of light, endless and silent. At its heart the Voice waits, its face hidden behind its wings.",
	"unlock": {"stage": "wheel_of_thrones", "boss_kills": 1},  # Plan: each stage opens the next
	"unlock_text": "Break the Throne on the Wheel of Thrones to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Host stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "host",  # Placeholder HostGround until phase 2.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": {},  # Phase 2 adds the clock-driven zones (MarchDirector) if it wants them.
	"host": true,  # Judgment, Hallowed Light, Grace (HostRules).
	"judgment": {},  # This stage's Judgment overrides ({} = HostRulesData.JUDGMENT).
	"light": {},  # This stage's Hallowed Light ({} = HostRulesData.LIGHT).
	"clouds": {},  # This stage's cloud banks ({} = HostRulesData.CLOUDS).
	"grace": {},  # This stage's Grace ({} = HostRulesData.GRACE).
	"zones": ZONES,  # The planned zones (phase 2 builds them).
	# Music key: the Host's own score "Hosanna in the Silence" (SoundData.HOSANNA_SCORE).
	"music": "hosanna",
}
