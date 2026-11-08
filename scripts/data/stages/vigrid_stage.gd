## VigridStage — STAGE 18 (final order), VIGRID, THE LAST FIELD, the finale of
## the Hall of the Slain (the Norse act, temporarily Act XI, final slot VI;
## GDD §15.0 "The Hall of the Slain foundation (phase 1)" and "Vigrid, the
## Last Field (phase 2)"; the act's section "Stage 18: Vigrid, the Last Field"
## of docs/proposals/LAST_SIX_ACTS.md, with the owner's answers of Nov 7, 2026:
## the Long Winter replaces the Choosing). The plain where the last battle is
## fought, under a sky going out: the giants march, the wolf strains at his
## chain, and the one-eyed god rides out for the army he was promised.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## The stage runs the act's shared rules ("norse": true: the Long Winter,
## Berserkergang, the Rune-Stones, Ragnarok), four clock-driven zones (ZONES,
## run by MarchDirector: a zone banner, the zone's floor and obstacles) and its
## own mechanics in VigridDirector (STAGE key "vigrid", VIGRID):
##   I   THE FROZEN SEA (0:00): fjord ice and frozen boulders; wolves run the
##       ice and the first frost giant crosses it;
##   II  THE ASH PLAIN (5:00): ash and burial mounds; the dark takes the
##       farthest brazier (THE FADING LIGHT, zone by zone);
##   III THE GIANTS' MARCH (10:00): the giants and the wolves lead; the
##       FIRE-GIANT OF THE SOUTH (the miniboss, burning tracks) comes at 12:00;
##   IV  THE FIELD OF VIGRID (15:00): shields planted in the ash for the last
##       battle; the Reckoning's dark arrives early (the red darkness and a
##       vanguard of fire-giants out of the south).
## The braziers stand by the map (LONG_WINTER "points": two contested fires by
## the start, a ring of four farther out), the dark takes one at each zone
## change, and frost giants and seers douse them: warmth is fought over.
## Odin and Fenrir (OdinData, boss_odin.gd: the Wolf, the All-Father,
## Ragnarok) arrive with 3:00 left; the Reckoning, Ragnarok, at 0:00. Every
## rate, cap and weight is TUNING (not in GDD), tuned for the act's final slot
## VI (between the Shogunate and Olympus). "playable" stays for the lead.
class_name VigridStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "vigrid"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (final slot VI: a hair above the Shogunate's 1.55 / 1.6 / 1.65; the step
## between the stages goes in HP, the Act IV lesson).
const ENEMY_HP_MULT: float = 1.65  # foundation pass: 1.7 -> 1.65 (the seed-7 army bot broke at 10:00); TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Enemy damage multiplier of this stage on top of the shared time scaling
## (between Olympus's 1.3 and the Shogunate's 1.5).
const ENEMY_DAMAGE_MULT: float = 1.45  # foundation pass: 1.5 -> 1.45; TUNING (not in GDD) placeholder, tuned in the act's bot passes
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) 7:00, as Acts III to IX
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of the act

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is a VigridGround look: style "ice" (the art pass's fjord ice,
## tiles/norse_ice) or "ash" (Vigrid's ash, tiles/norse_ash; "embers": the
## share of cells with an ember, more as the field burns); base / line /
## accent colours of the code floor. Obstacle kinds: "mound" (burial mounds,
## obstacles/mound_<s|l>[_v]) and "standing_shield" (shields planted in the
## ash, obstacles/standing_shield_<s|l>[_v]) from the art pass, "norse_boulder"
## (frozen boulders) and "norse_ash_rock" drawn by NorseGlyphs.
const ZONES := [
	{"id": "frozen_sea", "start": 0.0, "numeral": "I", "name": "The Frozen Sea",  # Owner-approved proposal zone I
		"blurb": "The sea at the world's edge has frozen solid, and the last war-host crosses it",
		"ground": {"style": "ice", "base": Color(0.55, 0.62, 0.70), "line": Palette.NORSE_FROST_SHADE, "accent": Palette.NORSE_FROST},
		"arena": {"density": 0.16, "clear_radius": 220.0, "layout_seed": 1811,  # TUNING (not in GDD) open ice
			"kinds": {
				"norse_boulder": {"weight": 0.65, "shape": "circle", "sizes": [10.0, 14.0]},  # TUNING (not in GDD) frozen boulders (NorseGlyphs)
				"mound": {"weight": 0.35, "shape": "rect", "sizes": [36.0, 56.0], "short": 16.0},  # TUNING (not in GDD) rimed mounds on the shore (art pass)
			}},
	},
	{"id": "ash_plain", "start": 300.0, "numeral": "II", "name": "The Ash Plain",  # Owner-approved proposal zone II
		"blurb": "A plain of ash and frozen earth, where the burial mounds of every war before stand open",
		"ground": {"style": "ash", "base": Color(0.20, 0.20, 0.22), "line": Color(0.34, 0.32, 0.32), "accent": Palette.NORSE_FIRE, "embers": 0.04},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 1812,  # TUNING (not in GDD)
			"kinds": {
				"mound": {"weight": 0.5, "shape": "rect", "sizes": [36.0, 56.0], "short": 16.0},  # TUNING (not in GDD) burial mounds (art pass)
				"norse_ash_rock": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD) ash rocks (NorseGlyphs)
			}},
	},
	{"id": "giants_march", "start": 600.0, "numeral": "III", "name": "The Giants' March",  # Owner-approved proposal zone III
		"blurb": "The road of the giants: the ground shakes, and wolves run before them",
		"ground": {"style": "ash", "base": Color(0.19, 0.17, 0.17), "line": Color(0.32, 0.27, 0.25), "accent": Palette.NORSE_FIRE, "embers": 0.07},
		"arena": {"density": 0.17, "clear_radius": 230.0, "layout_seed": 1813,  # TUNING (not in GDD) open for the giants
			"kinds": {
				"norse_ash_rock": {"weight": 0.6, "shape": "circle", "sizes": [12.0, 16.0, 22.0]},  # TUNING (not in GDD)
				"mound": {"weight": 0.4, "shape": "rect", "sizes": [36.0, 56.0], "short": 16.0},  # TUNING (not in GDD)
			}},
	},
	{"id": "field_of_vigrid", "start": 900.0, "numeral": "IV", "name": "The Field of Vigrid",  # Owner-approved proposal zone IV
		"blurb": "The last field: shields planted in the ash for a hundred miles, and the sky going out",
		"ground": {"style": "ash", "base": Color(0.18, 0.14, 0.13), "line": Color(0.36, 0.24, 0.20), "accent": Palette.NORSE_FIRE, "embers": 0.12},
		"arena": {"density": 0.15, "clear_radius": 240.0, "layout_seed": 1814,  # TUNING (not in GDD) open for the finale
			"kinds": {
				"standing_shield": {"weight": 0.6, "shape": "rect", "sizes": [24.0, 36.0], "short": 10.0},  # TUNING (not in GDD) shields planted in the ash (art pass)
				"norse_ash_rock": {"weight": 0.4, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
			}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "ONTO THE LAST FIELD  -  ZONE %s",
	"zone_color": Palette.NORSE_FIRE,  # The south's fire under a dying sky.
	"fog_color": Color(0.05, 0.05, 0.07),  # The sky going out.
	"fog_bank_color": Color(0.30, 0.30, 0.33),  # Ash haze.
	"zones": ZONES,
}

## The Long Winter on this stage (keys of NorseRulesData.LONG_WINTER): the
## braziers stand BY THE MAP ("points": offsets from the start, px): two
## contested fires close to the start (the last war-camp), and four along the
## field farther out, so the bot and the player must hold or walk to warmth
## (the foundation's seeded ring left the army in the cold most of the run).
## The cold steps keep the act's clock (every 5:00, as the zones).
const LONG_WINTER := {
	"points": [Vector2(-230.0, 110.0), Vector2(230.0, 110.0), Vector2(0.0, -460.0), Vector2(-700.0, -240.0), Vector2(700.0, -240.0), Vector2(0.0, 640.0)],  # TUNING (not in GDD) by the map
}
## The Rune-Stones on this stage: {} = the defaults of NorseRulesData.RUNE_STONES.
const RUNE_STONES := {}

## VigridDirector's config (STAGE key "vigrid"; the director's header documents
## the rules):
##   light    — the Fading Light's look (VigridLight): dark_by_zone (darkness
##              share per zone, 0..1), fade (s to blend), cell (px per texel),
##              necro_light (px of the necromancer's pool), brazier_light (x
##              the warm_radius: a lit brazier's pool), color (the night),
##              early_color (the early dark: Ragnarok's red).
##   keep_lit — the dark never takes the last this-many lit braziers.
##   vanguard — the early dark's fire-giants: from / until (game s), every (s),
##              giants (a march), kind, banner.
const VIGRID := {
	"light": {
		"dark_by_zone": [0.0, 0.2, 0.36, 0.5],  # TUNING (not in GDD) visual only: the light fades zone by zone
		"fade": 25.0,  # TUNING (not in GDD) s, visual only
		"cell": 16.0,  # TUNING (not in GDD) px, visual only
		"necro_light": 150.0,  # TUNING (not in GDD) px, visual only
		"brazier_light": 1.0,  # TUNING (not in GDD) x warm_radius, visual only (the light is the warmth)
		"color": Color(0.02, 0.03, 0.07),  # TUNING (not in GDD) visual only
		"early_color": Color(0.17, 0.02, 0.02),  # TUNING (not in GDD) visual only, Ragnarok's red
	},
	"keep_lit": 2,  # TUNING (not in GDD) the dark leaves at least two fires burning
	"vanguard": {
		"from": 915.0,  # TUNING (not in GDD) 15:15, the last zone
		"until": 1015.0,  # TUNING (not in GDD) before the boss
		"every": 75.0,  # TUNING (not in GDD) s
		"giants": 1,  # TUNING (not in GDD)
		"kind": NorseEnemyData.FIRE_GIANT,  # Owner-approved proposal: the fire-giants of the south
		"banner": "The Reckoning's dark comes early: a fire-giant of the south steps out of the dark!",
	},
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): RAGNAROK,
## shared by every stage of the act: the wolf swallows the sun (a dark red
## sky), the Einherjar of the hall march at once, fire-giants step out of the
## south edge, every valkyrie dives at the ring ("ragnarok":
## NorseRulesData.RAGNAROK keys; {} = those defaults). Its waves' heavy is the
## fire-giant, with raiders, berserkers, wolves and a valkyrie.
const RECKONING := {
	"banner": "RAGNAROK: THE WOLF SWALLOWS THE SUN",
	"kind": NorseEnemyData.RECKONING_KIND,  # The shared Ragnarok heavy (the fire-giant).
	"ragnarok": {},  # NorseRulesData.RAGNAROK defaults (phase 2 may tune them here).
	"companions": NorseEnemyData.RECKONING_COMPANIONS,  # Raiders, berserkers, wolves, a valkyrie.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) fire-giants
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "RAGNAROK: the sun is gone, the hall's heroes march and the giants burn the field. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the giants
## and the wolves lead (wolves weighted up across the stage, frost giants kept
## rare: four or more heavies at once broke the seed-7 army bot's ring in the
## foundation pass), the warriors of the hall march with them. Berserkers,
## valkyries and giants stay rare (elites and heavies).
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"raider": 0.75, "wolf_of_the_wastes": 0.25},
		"objective": "The Frozen Sea: the last battle begins in the cold. Keep near the braziers"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"raider": 0.62, "wolf_of_the_wastes": 0.2, "shield_maiden": 0.17, "frost_giant": 0.007},
		"objective": "Wolves run the ice. Your blockers hold their lunges"},
	{"start": 150.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"raider": 0.5, "wolf_of_the_wastes": 0.18, "shield_maiden": 0.17, "draugr": 0.12, "frost_giant": 0.007},
		"objective": "Draugr from the old barrows: armoured, and their touch is cold"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"raider": 0.42, "wolf_of_the_wastes": 0.17, "shield_maiden": 0.16, "draugr": 0.13, "skald": 0.04, "seer": 0.04, "frost_giant": 0.007},
		"objective": "The Ash Plain: the light fades, and the dark takes the farthest fire. Seers douse the rest"},
	{"start": 480.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"raider": 0.4, "wolf_of_the_wastes": 0.17, "shield_maiden": 0.16, "draugr": 0.13, "skald": 0.04, "seer": 0.04, "berserker": 0.025, "valkyrie": 0.015, "frost_giant": 0.008},
		"objective": "Wounded warriors go berserk: finish them in one blow"},
	{"start": 600.0, "rate": 2.8, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"raider": 0.36, "wolf_of_the_wastes": 0.2, "shield_maiden": 0.15, "draugr": 0.13, "skald": 0.04, "seer": 0.04, "berserker": 0.028, "valkyrie": 0.018, "frost_giant": 0.011},
		"objective": "The Giants' March: frost giants douse the braziers they pass. Stand by one to relight it"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"raider": 0.36, "wolf_of_the_wastes": 0.19, "shield_maiden": 0.16, "draugr": 0.13, "skald": 0.04, "seer": 0.05, "berserker": 0.032, "valkyrie": 0.02, "frost_giant": 0.011},
		"objective": "The Field of Vigrid: the sky goes out, and the whole north comes south"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"raider": 0.45, "wolf_of_the_wastes": 0.2, "shield_maiden": 0.15, "draugr": 0.12, "skald": 0.03, "seer": 0.03, "berserker": 0.02, "frost_giant": 0.005},
		"objective": "Odin and Fenrir have come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the type
## "rune_stone": `count` stones rise around the necromancer,
## RuneStones.start_event(); and "muspel_giant": VigridDirector's miniboss with
## its escort). Wolves come in packs of 5 (owner-approved proposal).
const EVENTS := [
	{"time": 25.0, "type": "wave", "banner": "A raiding party crosses the ice!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "raider", "count": 8, "elite": false}]},
	{"time": 45.0, "type": "rune_stone", "count": 1, "banner": "A rune-stone rises! Stand by it with your army to take it"},  # TUNING (not in GDD) rule 3
	{"time": 95.0, "type": "wave", "banner": "Wolves of the wastes run the frozen sea!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A frost giant strides across the ice, his wolves before him!", "formation": "arc",  # TUNING (not in GDD) the giants and the wolves lead
		"groups": [{"kind": "frost_giant", "count": 1, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 220.0, "type": "wave", "banner": "A shield line, and a skald to sing it on!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 6, "elite": false}]},
	{"time": 270.0, "type": "rune_stone", "count": 1, "banner": "Another rune-stone is carved! Its horn will call the hall"},  # TUNING (not in GDD) rule 3
	{"time": 330.0, "type": "wave", "banner": "A berserker! Wound him and he is already in the fury", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 390.0, "type": "wave", "banner": "Three packs of wolves come out of the ash!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 440.0, "type": "wave", "banner": "A valkyrie! Bring her down with arrows and spells", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 1, "elite": false}, {"kind": "draugr", "count": 5, "elite": false}]},
	{"time": 520.0, "type": "rune_stone", "count": 1, "banner": "A seer carves a new stone!"},  # TUNING (not in GDD) rule 3
	{"time": 545.0, "type": "wave", "banner": "Seers walk to your fires and your stones!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "seer", "count": 2, "elite": false}, {"kind": "shield_maiden", "count": 3, "elite": false}]},
	{"time": 615.0, "type": "wave", "banner": "The Giants' March: a frost giant and his barrow-dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "frost_giant", "count": 1, "elite": false}, {"kind": "draugr", "count": 6, "elite": false}]},
	{"time": 680.0, "type": "wave", "banner": "Wolves run before the giants!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "raider", "count": 6, "elite": false}]},
	{"time": 720.0, "type": "muspel_giant", "kind": "muspel_giant",  # TUNING (not in GDD) the miniboss, in the Giants' March
		"banner": "A FIRE-GIANT OF THE SOUTH strides out of Muspell! Keep your ring out of his burning tracks",
		"escort": [{"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "raider", "count": 4, "elite": false}]},
	{"time": 780.0, "type": "rune_stone", "count": 1, "banner": "The last rune-stone rises!"},  # TUNING (not in GDD) rule 3
	{"time": 840.0, "type": "wave", "banner": "Berserkers, and a skald to drive them!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "berserker", "count": 2, "elite": false}, {"kind": "skald", "count": 1, "elite": false}, {"kind": "raider", "count": 8, "elite": false}]},
	{"time": 870.0, "type": "wave", "banner": "Two valkyries circle the ring!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "valkyrie", "count": 2, "elite": false}, {"kind": "raider", "count": 6, "elite": false}]},
	{"time": 950.0, "type": "wave", "banner": "Giants and wolves together!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "frost_giant", "count": 1, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}, {"kind": "wolf_of_the_wastes", "count": 5, "elite": false}]},
	{"time": 995.0, "type": "wave", "banner": "The war-host gathers before its god!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "raider", "count": 10, "elite": false}, {"kind": "shield_maiden", "count": 4, "elite": false}, {"kind": "valkyrie", "count": 1, "elite": false}, {"kind": "berserker", "count": 1, "elite": false}]},
]

## Obstacle layout of the first zone (keys as GraveyardStage.ARENA; every zone
## has its own in ZONES).
const ARENA: Dictionary = ZONES[0]["arena"]

## The boss's arrival (keys as GraveyardStage.BOSS): OdinData.ARRIVAL (boss id
## "odin"), whose `time` equals BOSS_TIME (17:00). Its script is
## scripts/enemies/norse/boss_odin.gd (found by the boss id).
const BOSS: Dictionary = OdinData.ARRIVAL

## Floor look of the placeholder "norse" ground (NorseGround; the stage now
## uses VigridGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "ash",  # A plain of ash and frozen earth, cracks and embers.
	"base": Color(0.20, 0.20, 0.22),  # TUNING (not in GDD)
	"line": Color(0.32, 0.30, 0.30),  # TUNING (not in GDD)
	"accent": Palette.NORSE_IRON_DARK,  # TUNING (not in GDD)
	"trim": Palette.NORSE_FIRE,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "Vigrid, the Last Field",
	"short_name": "Vigrid",
	"chapter": "Chapter XVIII",
	"act": 11,  # The Hall of the Slain: TEMPORARY act number 11 (final slot VI; the reorder pass renumbers it).
	"playable": false,  # The lead switches it on after the act's integration and reviews.
	"description": "The plain where the last battle is fought, under a sky going out. The giants march, the wolf strains at his chain, and the one-eyed god rides out for the army he was promised.",
	"unlock": {"stage": "valgard", "boss_kills": 1},
	"unlock_text": "Defeat Sigrun, the Shield-Queen, in Valgard to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on the act's stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "vigrid",  # VigridGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"vigrid": VIGRID,  # VigridDirector (the Fading Light, the early dark's vanguard, the Fire-Giant of the south).
	"norse": true,  # The Hall of the Slain: the Long Winter, Berserkergang, the Rune-Stones (NorseRules).
	"long_winter": LONG_WINTER,  # This stage's Long Winter overrides (the braziers by the map).
	"rune_stones": RUNE_STONES,  # This stage's Rune-Stone overrides ({} = the defaults).
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march").
	"music": "valhall",  # "Horns at the Last Feast" (SoundData; its pack renders with it).
}
