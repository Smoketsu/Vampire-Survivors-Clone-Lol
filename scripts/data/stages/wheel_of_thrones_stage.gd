## WheelOfThronesStage — STAGE 38 (temporary number; final stage 29), THE WHEEL OF THRONES
## (temporary Act XIII, the Celestial Host, final slot X; GDD §15.0 "The
## Celestial Host foundation (phase 1)" and "The Wheel of Thrones (Act XIII
## phase 2)"; design docs/proposals/LAST_SIX_ACTS.md section X, "Stage 29: The
## Wheel of Thrones"). The turning spheres of heaven: rings of crystal that
## orbit through the arena.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## STATUS: BUILT (phase 2), playable. Unlocked in the campaign chain (Seraiel's
## fall on the Silver Stair opens it); it runs the Host's three shared rules
## ("host": true: Judgment, Hallowed Light, Grace) and its own systems
## (WheelOfThronesDirector, STAGE "wheel_of_thrones"): THE TURNING SPHERES
## (crystal rings that drift slowly across the map as moving walls with gaps,
## more and faster each zone), the Dominion of the Spheres (the miniboss, at
## 12:00) and THE WHEEL BREAKS. Its kinds: the shared Host with the Ophan (a
## guardian, the stage's block in HostEnemyData; from 5:40). Its boss is the
## Throne (BossThrone: the Rolling, the Gaze, the Core). The Last Trumpet is
## its Reckoning.
## Zones (ZONES; clock-driven, MarchDirector): the Sphere of the Moon, the
## Sphere of the Sun, the Sphere of the Stars, the Wheel.
## The Throne arrives with 3:00 left; the Reckoning at 0:00.
## Tuned for the act's FINAL slot X (docs/last_acts/PLAN.md: at or just above
## the Inferno), a little harder than the Silver Stair, not its temporary
## number. Every rate, cap and weight is TUNING (not in GDD).
class_name WheelOfThronesStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "wheel_of_thrones"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot X sits at or just above the Inferno's 1.75; a little lower here,
## because Grace's halos shrug off the first hit of every kind of damage).
const ENEMY_HP_MULT: float = 1.75  # TUNING (not in GDD) phase 2 (the stub's; the Silver Stair 1.7)
## Enemy damage multiplier of this stage on top of the shared time scaling
## (the Inferno's 1.5 and up).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) phase 2, as the Silver Stair (the stub's 1.55: the turning spheres are this stage's extra weight)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to XII (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 2 of the act

## The obstacle layout every zone shares the kinds of (the Host art's sprites
## obstacles/<kind>_m, one size each; HostGlyphs without art). Rect kinds lie
## either way (no "orient": the art has its `_v` turn):
##   host_pillar  — a pillar of white stone with a band of light (circle; its
##                  shadow is safe from the Light).
##   host_crystal — a standing shard of a sphere's crystal (rect).
## Footprints: host_pillar a circle of 10 px (art 24x46), host_crystal a rect
## 36 x 10 px (art 44x26 / 26x44); only the weights change by zone.

## The four zones (owner-approved proposal names), each from `start` game
## seconds (clock-driven, MarchDirector): its floor look ("ground": a
## WheelOfThronesGround style over the `wheel`, the zone's floor tile
## tiles/wheel_<style>; "grid": px between two lines of the celestial grid)
## and its obstacle layout ("arena"):
##   sphere_moon  — the Sphere of the Moon: pale silver dust on night blue.
##   sphere_sun   — the Sphere of the Sun: a lighter sky, motes of light.
##   sphere_stars — the Sphere of the Stars: deep star-blue; more crystal.
##   wheel        — the Wheel: the Throne's rim, silver lines in dark blue.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Sphere of the Moon", "id": "sphere_moon",  # Owner-approved proposal (zones)
		"blurb": "Pale silver dust where the lowest sphere turns",
		"ground": {"style": "moon", "grid": 96.0, "base": Color(0.12, 0.14, 0.22), "line": Color(0.19, 0.22, 0.33),
			"accent": Palette.HOST_SILVER, "trim": Palette.HOST_CERULEAN},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 3838,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.55, "shape": "circle", "sizes": [10.0]}, "host_crystal": {"weight": 0.45, "shape": "rect", "sizes": [36.0], "short": 10.0}}}},  # TUNING (not in GDD)
	{"start": 300.0, "numeral": "II", "name": "The Sphere of the Sun", "id": "sphere_sun",  # Owner-approved proposal (zones)
		"blurb": "A brighter sky, and the spheres turn faster",
		"ground": {"style": "sun", "grid": 112.0, "base": Color(0.17, 0.19, 0.29), "line": Color(0.25, 0.28, 0.40),
			"accent": Palette.HOST_STARLIGHT, "trim": Palette.HOST_CERULEAN},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 3848,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.5, "shape": "circle", "sizes": [10.0]}, "host_crystal": {"weight": 0.5, "shape": "rect", "sizes": [36.0], "short": 10.0}}}},  # TUNING (not in GDD)
	{"start": 600.0, "numeral": "III", "name": "The Sphere of the Stars", "id": "sphere_stars",  # Owner-approved proposal (zones)
		"blurb": "Deep star-blue, crossed by two spheres at once",
		"ground": {"style": "stars", "grid": 128.0, "base": Color(0.07, 0.09, 0.18), "line": Color(0.13, 0.16, 0.28),
			"accent": Palette.HOST_SILVER, "trim": Palette.HOST_CERULEAN},
		"arena": {"density": 0.15, "clear_radius": 220.0, "layout_seed": 3858,  # TUNING (not in GDD)
			"kinds": {"host_crystal": {"weight": 0.6, "shape": "rect", "sizes": [36.0], "short": 10.0}, "host_pillar": {"weight": 0.4, "shape": "circle", "sizes": [10.0]}}}},  # TUNING (not in GDD)
	{"start": 900.0, "numeral": "IV", "name": "The Wheel", "id": "wheel",  # Owner-approved proposal (zones)
		"blurb": "The Throne's own rim, where every sphere turns about it",
		"ground": {"style": "core", "grid": 144.0, "base": Color(0.10, 0.12, 0.22), "line": Color(0.18, 0.22, 0.36),
			"accent": Palette.HOST_SILVER, "trim": Palette.HOST_ROSE},
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 3868,  # TUNING (not in GDD)
			"kinds": {"host_pillar": {"weight": 0.6, "shape": "circle", "sizes": [10.0]}, "host_crystal": {"weight": 0.4, "shape": "rect", "sizes": [36.0], "short": 10.0}}}},  # TUNING (not in GDD)
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 220.0,  # TUNING (not in GDD)
	"zone_title": "THE WHEEL OF THRONES  -  SPHERE %s",  # TUNING (not in GDD)
	"zone_color": Color(0.62, 0.78, 0.94),  # Pale cerulean (Palette.HOST_CERULEAN's light): never the player's true gold.
	"fog_color": Color(0.06, 0.08, 0.16),  # The night between the spheres.
	"fog_bank_color": Color(0.62, 0.78, 0.94),  # Crystal light.
	"zones": ZONES,
}

## The Wheel of Thrones' stage systems (WheelOfThronesDirector; StageRegistry
## "wheel_of_thrones").
##   zones — THE TURNING SPHERES, one row per zone (by `start` s): from
##           `first` s into the zone, every `every` s a crystal ring comes in
##           (at most `max_live` at once): `radius` px round a centre that
##           starts `from` px off a standing necromancer at a seeded angle
##           and drifts straight across, passing up to `miss` px
##           beside him, at `speed` px/s for twice that distance, turning
##           `spin` rad/s (a seeded way round); `segments` crystal arcs, each
##           filling `fill` of its share of the circle, `thickness` px thick.
##   dominion_objective   — HUD objective while the Dominion of the Spheres stands.
##   wheel_breaks_banner  — banner when The Wheel Breaks is earned.
const SPHERES := {
	"zones": [
		{"start": 0.0, "first": 150.0, "every": 40.0, "max_live": 1, "from": 700.0, "miss": 160.0, "speed": 22.0, "spin": 0.12,  # TUNING (not in GDD) the Sphere of the Moon: one slow ring, from 2:30 (first pass 0:30: the army bot's first ring is small)
			"radius": 240.0, "segments": 4, "fill": 0.5, "thickness": 14.0},  # TUNING (not in GDD) gaps ~190 px (the Bone Ring flows through)
		{"start": 300.0, "first": 6.0, "every": 34.0, "max_live": 1, "from": 720.0, "miss": 160.0, "speed": 26.0, "spin": 0.16,  # TUNING (not in GDD) the Sphere of the Sun: a little faster
			"radius": 280.0, "segments": 5, "fill": 0.55, "thickness": 14.0},  # TUNING (not in GDD)
		{"start": 600.0, "first": 6.0, "every": 26.0, "max_live": 2, "from": 740.0, "miss": 180.0, "speed": 28.0, "spin": 0.18,  # TUNING (not in GDD) the Sphere of the Stars: two rings at once
			"radius": 300.0, "segments": 6, "fill": 0.58, "thickness": 14.0},  # TUNING (not in GDD)
		{"start": 900.0, "first": 6.0, "every": 26.0, "max_live": 2, "from": 760.0, "miss": 180.0, "speed": 32.0, "spin": 0.22,  # TUNING (not in GDD) the Wheel: the fastest
			"radius": 320.0, "segments": 6, "fill": 0.6, "thickness": 16.0},  # TUNING (not in GDD)
	],
	"dominion_objective": "Bring down the Dominion of the Spheres: while he stands, every halo in the zone comes back",  # TUNING (not in GDD)
	"wheel_breaks_banner": "THE WHEEL BREAKS: the Throne fell by its burning eye!",  # TUNING (not in GDD)
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
## lights and the soldiers of light lead; the Ophan (a guardian) joins from
## 6:00, rare; the supports stay rare. The Judges come from Judgment, never
## from these weights. The Silver Stair's rates (slot X: the turning spheres
## and the Ophans make it a little harder than the act's first stage).
const SEGMENTS := [
	# Zone I, the Sphere of the Moon.
	{"start": 0.0, "rate": 1.2, "max_alive": 26,  # TUNING (not in GDD) as the Silver Stair (the army bot's first ring is small)
		"weights": {"lesser_light": 0.8, "virtue": 0.2},
		"objective": "The Sphere of the Moon: the Host comes down. Every halo shrugs off the first blow of each kind"},
	{"start": 60.0, "rate": 1.5, "max_alive": 34,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.66, "virtue": 0.2, "power": 0.14},
		"objective": "A ring of crystal turns across the sphere: lead your ring through its gaps"},
	{"start": 180.0, "rate": 1.8, "max_alive": 44,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.54, "virtue": 0.2, "power": 0.16, "choir_angel": 0.05, "herald": 0.05},
		"objective": "Every raise and every summon you replace weighs on the scales. At each third a Judge comes for you"},
	# Zone II, the Sphere of the Sun (5:00): the spheres turn faster.
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD) as the Silver Stair (first pass 2.4 / 62: the turning spheres are weight enough)
		"weights": {"lesser_light": 0.4, "virtue": 0.27, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03},
		"objective": "The Sphere of the Sun: the light sweeps the ground. Lead your ring into the shadow of a cloud or a pillar"},
	{"start": 360.0, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.39, "virtue": 0.26, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03, "ophan": 0.006},
		"objective": "An Ophan rolls straight through your ring: step out of its line, or wall it off"},
	# Zone III, the Sphere of the Stars (10:00): the Dominion of the Spheres at 12:00.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.37, "virtue": 0.25, "power": 0.2, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.04, "ophan": 0.009},
		"objective": "The Sphere of the Stars: two rings turn at once. When the scales are full, the Verdict falls on you for 20 s"},
	# Zone IV, the Wheel (15:00).
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"lesser_light": 0.35, "virtue": 0.25, "power": 0.2, "choir_angel": 0.06, "herald": 0.06, "dominion": 0.05, "ophan": 0.009},
		"objective": "The Wheel: every sphere turns about the Throne"},
	# 17:00, the boss: thinner, so the fight is the Rolling, the Gaze and the Core.
	{"start": BOSS_TIME, "rate": 2.0, "max_alive": 56,  # TUNING (not in GDD) thinner during the boss fight (as the Silver Stair)
		"weights": {"lesser_light": 0.4, "virtue": 0.27, "power": 0.19, "choir_angel": 0.06, "herald": 0.05, "dominion": 0.03},
		"objective": "The Throne has come for you. Strike its burning eye when the wheels open"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS), plus the Wheel
## of Thrones' own (WheelOfThronesDirector):
##   "spheres_dominion" — the Dominion of the Spheres (kind `kind`) comes down
##                        on the spawn ring with an `escort` (groups of {kind,
##                        count}); the stage miniboss.
const EVENTS := [
	# Zone I: the Sphere of the Moon.
	{"time": 20.0, "type": "wave", "banner": "A swarm of lesser lights descends!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "The Virtues advance behind their mirror masks!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "virtue", "count": 4, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Herald raises his trumpet!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "herald", "count": 1, "elite": false}, {"kind": "power", "count": 3, "elite": false}]},
	{"time": 260.0, "type": "wave", "banner": "A Choir Angel sings: the angels near her heal!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	# Zone II: the Sphere of the Sun.
	{"time": 340.0, "type": "wave", "banner": "An Ophan, a burning wheel within a wheel: it rolls straight through your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "ophan", "count": 1, "elite": false}, {"kind": "virtue", "count": 4, "elite": false}]},
	{"time": 410.0, "type": "wave", "banner": "A Dominion leads the Powers: their halos come back!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 1, "elite": false}, {"kind": "power", "count": 4, "elite": false}]},
	{"time": 490.0, "type": "wave", "banner": "Two swarms of light at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lesser_light", "count": 12, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}, {"kind": "virtue", "count": 4, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Two Ophans turn toward you!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "ophan", "count": 2, "elite": false}, {"kind": "power", "count": 3, "elite": false}]},
	# Zone III: the Sphere of the Stars.
	{"time": 650.0, "type": "wave", "banner": "The Choir comes down to sing over its soldiers!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "choir_angel", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "virtue", "count": 8, "elite": false}]},
	{"time": 720.0, "type": "spheres_dominion", "banner": "THE DOMINION OF THE SPHERES! While he stands, every halo in the zone comes back!",  # Owner-approved proposal (miniboss); 8:00 left
		"kind": "dominion_of_the_spheres", "elite": false,
		"escort": [{"kind": "virtue", "count": 6}, {"kind": "power", "count": 3}]},  # TUNING (not in GDD)
	{"time": 800.0, "type": "wave", "banner": "A host of Powers, blades of white flame!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "power", "count": 8, "elite": false}, {"kind": "virtue", "count": 6, "elite": false}, {"kind": "dominion", "count": 1, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "Ophans roll out of the stars!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ophan", "count": 2, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	# Zone IV: the Wheel.
	{"time": 930.0, "type": "wave", "banner": "The whole Host comes down!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "dominion", "count": 2, "elite": false}, {"kind": "herald", "count": 1, "elite": false}, {"kind": "choir_angel", "count": 1, "elite": false}, {"kind": "ophan", "count": 1, "elite": false}, {"kind": "lesser_light", "count": 12, "elite": false}]},
	{"time": 990.0, "type": "wave", "banner": "The Host gathers before the Throne!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "virtue", "count": 10, "elite": false}, {"kind": "power", "count": 6, "elite": false}, {"kind": "choir_angel", "count": 1, "elite": false}]},
]

## The Throne's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "throne"). Its script is scripts/enemies/host/boss_throne.gd
## (loaded by its id); its numbers are ThroneData's.
const BOSS := {
	"id": "throne",
	"time": BOSS_TIME,
	"display_name": "The Throne",
	"short_name": "The Throne",
	"arrive_banner": "The Throne turns toward you, and every eye on its rims opens!",
	"defeat_banner": "The Throne breaks on its own rims! Hold out until the end...",
	"dead_objective": "The Throne is broken. Survive the Last Trumpet... you cannot.",
}

## Placeholder floor of the foundation stub (HostGround "floor" key), kept for
## the other tools that read it; the stage draws WheelOfThronesGround ("ground").
const FLOOR := {
	"style": "wheel",  # deep cerulean sky with crystal rings.
	"base": Color(0.10, 0.14, 0.26),  # TUNING (not in GDD)
	"line": Color(0.18, 0.24, 0.40),  # TUNING (not in GDD)
	"accent": Palette.HOST_SILVER,  # TUNING (not in GDD)
	"trim": Palette.HOST_CERULEAN,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Wheel of Thrones",
	"short_name": "Wheel of Thrones",
	"chapter": "Chapter XXXVIII",  # Temporary (the reorder pass renumbers; final stage 29).
	"act": 13,  # Temporary Act XIII, the Celestial Host (final slot X; docs/last_acts/PLAN.md).
	"playable": true,  # Phase 2 built (GDD §15.0 "The Wheel of Thrones (Act XIII phase 2)").
	"description": "The turning spheres of heaven: rings of crystal orbit through the arena, and at their centre the Throne turns, its rims covered in eyes.",
	"unlock": {"stage": "silver_stair", "boss_kills": 1},  # Plan: each stage opens the next
	"unlock_text": "Defeat Seraiel on the Silver Stair to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Host stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "wheel_of_thrones",  # WheelOfThronesGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"wheel_of_thrones": SPHERES,  # WheelOfThronesDirector: the turning spheres, the Dominion of the Spheres, The Wheel Breaks.
	"host": true,  # Judgment, Hallowed Light, Grace (HostRules).
	"judgment": {},  # This stage's Judgment overrides ({} = HostRulesData.JUDGMENT).
	"light": {},  # This stage's Hallowed Light ({} = HostRulesData.LIGHT).
	"clouds": {},  # This stage's fixed cloud banks ({} = HostRulesData.CLOUDS).
	"grace": {},  # This stage's Grace ({} = HostRulesData.GRACE).
	"zones": ZONES,  # The four zones.
	# Music key: the Host's own score "Hosanna in the Silence" (SoundData.HOSANNA_SCORE).
	"music": "hosanna",
}
