## EmpyreanStage — STAGE 39 (temporary number; final stage 30), THE EMPYREAN
## (temporary Act XIII, the Celestial Host, final slot X, the end of Part One;
## GDD §15.0 "The Celestial Host foundation (phase 1)" and "The Empyrean (Act
## XIII phase 2)"; design docs/proposals/LAST_SIX_ACTS.md section X, "Stage 30:
## The Empyrean"). The highest heaven: a white rose of light, endless and
## silent.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (the
## Throne's fall on the Wheel of Thrones opens it); it runs the Host's three
## shared rules ("host": true: Judgment, Hallowed Light, Grace) and its own
## systems (EmpyreanDirector, STAGE "empyrean"): THE CHOIR (every Choir Angel
## alive widens the Light), the Herald of the Seventh Trumpet (the miniboss,
## at 12:00) and THE LAST WORD. Its kinds: the whole Host, the Cherub and the
## Ophan among them (the shared guardians, from 6:00), with more Choir Angels
## than the act's other stages. Its boss is the Voice (BossVoice: the Holy, Be
## Not Afraid, the Last Word), the act's finale; when it falls, a short ending
## text only (no epilogue part until the reorder pass). The Last Trumpet is its
## Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Rose's Edge, the Petals, the
## Choir, the Heart of the Rose.
## The Voice arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot X (docs/last_acts/PLAN.md: at or just above
## the Inferno), the hardest of the act's three stages, not its temporary
## number. Every rate, cap and weight is TUNING (not in GDD).
class_name EmpyreanStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "empyrean"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot X sits at or just above the Inferno's 1.75; the act's finale a step
## over the Wheel of Thrones' 1.75).
const ENEMY_HP_MULT: float = 1.8  # TUNING (not in GDD) the stub's
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Inferno's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) as the Wheel of Thrones (the stub's 1.6, a first pass 1.55: the Choir's wider Light is this stage's extra weight)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 3 of the act

## The obstacle layout every zone shares the kinds of (the Host art's sprites
## obstacles/<kind>_m, one size each; HostGlyphs without art). Rect kinds lie
## either way (no "orient": the art has its `_v` turn):
##   host_pillar — a pillar of white stone with a band of light (circle; its
##                 shadow is safe from the Light).
##   host_petal  — a standing petal of light (rect).
## Footprints: host_pillar a circle of 10 px (art 24x46), host_petal a rect
## 44 x 10 px (art 56x24 / 24x56); only the weights change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": an
## EmpyreanGround style over the `rose`, the zone's floor tile
## tiles/empyrean_<style>; "grid": px between two petal seams) and its
## obstacle layout ("arena"):
##   rose_edge — the Rose's Edge: the palest petals.
##   petals    — the Petals: petal seams and rose blushes; more standing petals.
##   choir     — the Choir: silver lines of the hymn.
##   heart     — the Heart of the Rose: the deepest light, starlight sparks.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Rose's Edge", "id": "rose_edge",  # Owner-approved proposal (zones)
		"blurb": "The outermost petals of a white rose of light",
		"ground": {"style": "rose_edge", "grid": 96.0, "base": Color(0.30, 0.29, 0.35), "line": Color(0.38, 0.37, 0.44),
			"accent": Palette.HOST_SILVER, "trim": Palette.HOST_ROSE},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 3939,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.5, "shape": "circle", "sizes": [10.0]}, "host_petal": {"weight": 0.5, "shape": "rect", "sizes": [44.0], "short": 10.0}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Petals", "id": "petals",  # Owner-approved proposal (zones)
		"blurb": "Petal on petal, and the light between them",
		"ground": {"style": "petals", "grid": 112.0, "base": Color(0.27, 0.26, 0.32), "line": Color(0.35, 0.34, 0.41),
			"accent": Palette.HOST_SILVER, "trim": Palette.HOST_ROSE},
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 3949,  # TUNING (not in GDD)
			"kinds": {"host_petal": {"weight": 0.65, "shape": "rect", "sizes": [44.0], "short": 10.0}, "host_pillar": {"weight": 0.35, "shape": "circle", "sizes": [10.0]}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Choir", "id": "choir",  # Owner-approved proposal (zones)
		"blurb": "The hymn of the whole Host, and every voice widens the light",
		"ground": {"style": "choir", "grid": 128.0, "base": Color(0.24, 0.23, 0.29), "line": Color(0.32, 0.31, 0.38),
			"accent": Palette.HOST_STARLIGHT, "trim": Palette.HOST_CERULEAN},
		"arena": {"density": 0.15, "clear_radius": 220.0, "layout_seed": 3959,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.55, "shape": "circle", "sizes": [10.0]}, "host_petal": {"weight": 0.45, "shape": "rect", "sizes": [44.0], "short": 10.0}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Heart of the Rose", "id": "heart",  # Owner-approved proposal (zones)
		"blurb": "The silent heart, where the Voice waits",
		"ground": {"style": "heart", "grid": 144.0, "base": Color(0.20, 0.19, 0.25), "line": Color(0.28, 0.27, 0.34),
			"accent": Palette.HOST_STARLIGHT, "trim": Palette.HOST_ROSE},
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 3969,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.6, "shape": "circle", "sizes": [10.0]}, "host_petal": {"weight": 0.4, "shape": "rect", "sizes": [44.0], "short": 10.0}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE EMPYREAN  -  CIRCLE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.96, 0.82, 0.88),  # Dawn rose (Palette.HOST_ROSE's light): never the player's true gold.
	"fog_color": Color(0.16, 0.15, 0.20),  # The rose's shadowed folds.
	"fog_bank_color": Color(0.96, 0.92, 0.98),  # White petal light.
	"zones": ZONES,
}

## The Empyrean's stage systems (EmpyreanDirector; StageRegistry "empyrean").
##   zones            — start (s) of each zone (the report's zone count).
##   per_angel        — THE CHOIR: the Light's width rises by this share per
##                      live Choir Angel (x the Light's width_mult, applied
##                      relatively) ...
##   max_angels       — ... counting at most this many angels.
##   herald_objective — HUD objective while the Herald of the Seventh Trumpet stands.
##   last_word_banner — banner when The Last Word is earned.
const EMPYREAN := {
	"zones": [0.0, 300.0, 600.0, 900.0],  # ZONES' starts
	"per_angel": 0.06,  # Owner-approved proposal: "every Choir Angel alive adds to the light's width"; TUNING (not in GDD) +6% each (first passes 12%, 8%)
	"max_angels": 4,  # TUNING (not in GDD) at most x1.24 from the Choir (the Last Trumpet multiplies on top; first pass 5 x 12%: x1.6 most of the run)
	"herald_objective": "Bring down the Herald of the Seventh Trumpet: every blast calls the squads of the earlier zones",  # TUNING (not in GDD)
	"last_word_banner": "THE LAST WORD: the Voice is silent, and heaven, earth and hell answer to you!",  # TUNING (not in GDD)
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the LAST
## TRUMPET, shared by every Host stage: seven trumpets sound one after another
## ("kind": the Dominion, with the shared kinds as companions); each fills the
## scales, widens the light and doubles the Host, and the sky opens
## ("last_trumpet": HostRulesData.TRUMPET keys; {} = those defaults).
const RECKONING := {
	"banner": "THE LAST TRUMPET: THE SKY OPENS",
	"kind": HostEnemyData.RECKONING_KIND,  # The shared Last Trumpet heavy (the Dominion).
	"last_trumpet": {},  # HostRulesData.TRUMPET defaults (the act's shared Reckoning; the brief gives the finale none of its own).
	"companions": HostEnemyData.RECKONING_COMPANIONS,  # Lesser lights, Virtues, Powers, a Choir Angel.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) Dominions
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE LAST TRUMPET: seven trumpets, and the sky opens. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the Wheel
## of Thrones' rates and Choir Angels (each one widens the Light; a first pass
## made them more common: 13-16 alive at once) and the guardians (Cherub, Ophan) rare from 6:00. The Judges come
## from Judgment, never from these weights.
const SEGMENTS := [
	# Zone I, the Rose's Edge.
	{"start": 0.0, "rate": 1.2, "max_alive": 26,  # TUNING (not in GDD) as the Wheel of Thrones (the army bot's first ring is small)
		"weights": {"lesser_light": 0.8, "virtue": 0.2},
		"objective": "The Rose's Edge: the Host comes down. Every halo shrugs off the first blow of each kind"},
	{"start": 60.0, "rate": 1.5, "max_alive": 34,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.66, "virtue": 0.2, "power": 0.14},
		"objective": "The light sweeps the ground: lead your ring into the shadow of a cloud or a pillar"},
	{"start": 180.0, "rate": 1.8, "max_alive": 44,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.52, "virtue": 0.2, "power": 0.16, "choir_angel": 0.05, "herald": 0.05},
		"objective": "A Choir Angel sings: while she lives, the light is wider. Kill the Choir first"},
	# Zone II, the Petals (5:00).
	{"start": 300.0, "rate": 2.0, "max_alive": 52,  # TUNING (not in GDD) a softer step than the Wheel of Thrones' 2.3 / 60 (a first pass killed the seed-3 army bot at 7:20)
		"weights": {"lesser_light": 0.39, "virtue": 0.26, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03},
		"objective": "The Petals: every raise and every summon you replace weighs on the scales"},
	{"start": 360.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.38, "virtue": 0.25, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03, "cherub": 0.005, "ophan": 0.004},
		"objective": "The guardians of the lower heavens come up to the Rose"},
	# Zone III, the Choir (10:00): the Herald of the Seventh Trumpet at 12:00.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.35, "virtue": 0.24, "power": 0.2, "choir_angel": 0.045, "herald": 0.05, "dominion": 0.04, "cherub": 0.006, "ophan": 0.006},
		"objective": "The Choir: the hymn of the whole Host. Every voice widens the light"},
	# Zone IV, the Heart of the Rose (15:00).
	{"start": 900.0, "rate": 2.6, "max_alive": 76,  # TUNING (not in GDD) the Wheel of Thrones 3.0 / 84 (the Voice's Holy follows; a first pass 2.8 / 80 broke the army bot's ring before the Voice)
		"weights": {"lesser_light": 0.34, "virtue": 0.24, "power": 0.2, "choir_angel": 0.045, "herald": 0.06, "dominion": 0.05, "cherub": 0.006, "ophan": 0.006},
		"objective": "The Heart of the Rose: the silence before the Voice"},
	# 17:00, the boss: thinner, so the fight is the Holy, Be Not Afraid and the Last Word.
	{"start": BOSS_TIME, "rate": 1.8, "max_alive": 50,  # TUNING (not in GDD) thinner during the boss fight (the Wheel of Thrones 2.0 / 56: the Voice's Holy and Judges are the fight)
		"weights": {"lesser_light": 0.42, "virtue": 0.27, "power": 0.19, "choir_angel": 0.05, "herald": 0.05},
		"objective": "The Voice has come down. Go to it: it never moves"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS), plus the
## Empyrean's own (EmpyreanDirector):
##   "seventh_herald" — the Herald of the Seventh Trumpet (kind `kind`) comes
##                      down on the spawn ring with an `escort` (groups of
##                      {kind, count}); the stage miniboss.
const EVENTS := [
	# Zone I: the Rose's Edge.
	{"time": 20.0, "type": "wave", "banner": "A swarm of lesser lights descends!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "The Virtues advance behind their mirror masks!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "virtue", "count": 4, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Choir Angel sings over the Powers: the light widens!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "power", "count": 3, "elite": false}]},
	{"time": 260.0, "type": "wave", "banner": "A Herald raises his trumpet!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "herald", "count": 1, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	# Zone II: the Petals.
	{"time": 340.0, "type": "wave", "banner": "Two Choir Angels: the hymn rises, and the light with it!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 2, "elite": false}, {"kind": "virtue", "count": 4, "elite": false}]},
	{"time": 410.0, "type": "wave", "banner": "A Dominion leads the Powers: their halos come back!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 1, "elite": false}, {"kind": "power", "count": 4, "elite": false}]},
	{"time": 490.0, "type": "wave", "banner": "A Cherub climbs to the Rose, its sword turning!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "cherub", "count": 1, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "An Ophan rolls out of the lower spheres!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "ophan", "count": 1, "elite": false}, {"kind": "power", "count": 3, "elite": false}]},
	# Zone III: the Choir.
	{"time": 640.0, "type": "wave", "banner": "The Choir comes down to sing over its soldiers!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "virtue", "count": 8, "elite": false}]},
	{"time": 720.0, "type": "seventh_herald", "banner": "THE HERALD OF THE SEVENTH TRUMPET! His trumpets call the squads of the whole Rose!",  # Owner-approved proposal (miniboss); 8:00 left
		"kind": "herald_of_the_seventh_trumpet", "elite": false,
		"escort": [{"kind": "virtue", "count": 6}, {"kind": "choir_angel", "count": 1}]},  # TUNING (not in GDD)
	{"time": 800.0, "type": "wave", "banner": "A host of Powers, blades of white flame!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "power", "count": 8, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "dominion", "count": 1, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "The guardians come together: a Cherub and an Ophan!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "cherub", "count": 1, "elite": false}, {"kind": "ophan", "count": 1, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	# Zone IV: the Heart of the Rose.
	{"time": 930.0, "type": "wave", "banner": "The whole Host comes down!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Host gathers before the Voice!", "formation": "arc",  # TUNING (not in GDD) an arc, not the Wheel's ring (it closed on a worn ring just before the boss)
		"groups": [{"kind": "virtue", "count": 8, "elite": false}, {"kind": "power", "count": 4, "elite": false}]},
]

## The Voice's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "voice"). Its script is scripts/enemies/host/boss_voice.gd
## (loaded by its id); its numbers are VoiceData's.
const BOSS := {
	"id": "voice",
	"time": BOSS_TIME,
	"display_name": "The Voice",
	"short_name": "The Voice",
	"arrive_banner": "The Voice comes down in the heart of the rose. Two of its six wings hide its face.",
	"defeat_banner": "The Voice folds its wings and is silent! Hold out until the end...",
	"dead_objective": "The Voice is silent. Survive the Last Trumpet... you cannot.",
}

## Placeholder floor of the foundation stub (HostGround "floor" key), kept for
## the other tools that read it; the stage draws EmpyreanGround ("ground").
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
	"playable": true,  # Phase 2 built (GDD §15.0 "The Empyrean (Act XIII phase 2)").
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
	"arena": ZONES[0]["arena"],
	"ground": "empyrean",  # EmpyreanGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"empyrean": EMPYREAN,  # EmpyreanDirector: the Choir, the Herald of the Seventh Trumpet, The Last Word.
	"host": true,  # Judgment, Hallowed Light, Grace (HostRules).
	"judgment": {"capacity": 52.0},  # TUNING (not in GDD) the scales hold more here (HostRulesData.JUDGMENT 45): the Choir's wider Light kills more summons, and every one replaced is a sin (a first pass: five Verdicts in the seed-7 army run, its ring collapsing at each)
	"light": {},  # This stage's Hallowed Light ({} = HostRulesData.LIGHT).
	"clouds": {},  # This stage's fixed cloud banks ({} = HostRulesData.CLOUDS).
	"grace": {},  # This stage's Grace ({} = HostRulesData.GRACE).
	"zones": ZONES,  # The four zones.
	# Music key: the Host's own score "Hosanna in the Silence" (SoundData.HOSANNA_SCORE).
	"music": "hosanna",
}
