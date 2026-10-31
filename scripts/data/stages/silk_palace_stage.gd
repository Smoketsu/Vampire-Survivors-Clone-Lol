## SilkPalaceStage — STAGE 17, THE PALACE OF SILK AND ASH (Act VI, the Inferno;
## GDD §15.0 "Act VI foundation (phase 1)" and "The Palace of Silk and Ash (Act
## VI phase 2)"; owner-approved proposal docs/act6/PROPOSAL.md "Stage 17: The
## Palace of Silk and Ash"). The court of desire: velvet halls, mirrors, rose
## gardens of black thorns, a ballroom over a lava lake. Every number and event
## that belongs to this stage; StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are documented
## in StageRegistry). Unlocked by slaying Moloch at the Burning Gate.
##
## THE CLOCK IS AUTHORITATIVE, as on every zoned stage: four zones on fixed
## times (ZONES, run by MarchDirector: a zone banner, a sweep of incense smoke,
## the obstacles and floor re-drawn as the next zone), and the Inferno's three
## shared rules run all the way (the Hell Pits with this stage's fixed pits per
## zone, the demon portals, Temptation):
##   20:00  Zone I,   the Rose Garden:      black-thorned rose bushes, marble
##                                           columns, candelabra; the damned,
##                                           imps, hell knights
##   16:00  the LILIM WITCHES join (pits under the ring, portal rites)
##   15:00  Zone II,  the Hall of Mirrors:  standing mirrors and mirror walls:
##                                           REFLECTIONS of the necromancer
##                                           lure the summons astray
##                                           (SilkPalaceDirector, through
##                                           SummonedUnit.misdirect(): an effect
##                                           of the ground)
##   10:00  Zone III, the Ballroom:         a ballroom over a lava lake: the
##                                           most fixed Hell Pits of the act
##                                           (PITS fixed_chance), candelabra,
##                                           velvet divans
##    8:20  THE TWIN SUCCUBI, the miniboss (two sisters who charm in turns)
##    5:00  Zone IV,  the Queen's Chamber:   velvet, roses and mirrors
##    3:00  LILITH, Queen of the Night, Mother of Demons (BossLilith, LilithData)
##    0:00  THE LAST JUDGMENT (the shared Act VI Reckoning)
## The Burning Gate's kinds (built in parallel; candidate ids) join as guest
## squads once this build knows them (SILK_PALACE "guests"), like the Road to
## the Sun's guests. Every rate, cap and weight is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name SilkPalaceStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "silk_palace"

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act VI starts a step above the Road to the Sun's 1.65; the step goes in HP,
## not damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 1.75  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling (the
## Road to the Sun's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) placeholder, tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) placeholder (Acts III to V: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 2 of Act VI

## The Hell Pits on this stage (InfernoRulesData.PITS keys): the defaults, with
## this stage's chance of a fixed pit per zone (fixed_chance, one per ZONES
## entry): few in the Hall of Mirrors (its reflections are the hazard there),
## the most of the act in the Ballroom over the lava lake.
const PITS := {
	"fixed_chance": [0.3, 0.22, 0.58, 0.45],  # TUNING (not in GDD) the Rose Garden, the Hall of Mirrors, the Ballroom (a lava lake), the Queen's Chamber
}

## The demon portals on this stage: any InfernoRulesData.PORTALS key ({} = the
## defaults); "table" is the squads its portals pour (Lilim Witches heal the
## demons around a standing portal: seal it first).
const PORTALS := {"table": [{"kind": "imp", "count": 3, "weight": 1.0}, {"kind": "damned", "count": 3, "weight": 0.8},
	{"kind": "hell_knight", "count": 1, "weight": 0.3}, {"kind": "succubus", "count": 1, "weight": 0.2}]}  # TUNING (not in GDD) this stage's squads

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the Last
## Judgment, shared by every Act VI stage: every portal opens at once, the pits
## open faster each minute and the Adversary's hand reaches up through the
## floor ("last_judgment": InfernoRulesData.LAST_JUDGMENT keys; {} = those
## defaults); demon brutes ("kind") step out with imps, the damned and the
## palace's Lilim Witches.
const RECKONING := {
	"banner": "THE LAST JUDGMENT: THE PIT OPENS",
	"kind": InfernoEnemyData.DEMON_BRUTE,  # The shared Last Judgment heavy.
	"last_judgment": {},  # InfernoRulesData.LAST_JUDGMENT defaults.
	"companions": [{"kind": InfernoEnemyData.IMP, "count": 6, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": InfernoEnemyData.DAMNED, "count": 4, "growth": 1.0},  # TUNING (not in GDD)
		{"kind": SilkPalaceEnemyData.LILIM_WITCH, "count": 1, "growth": 0.5}],  # TUNING (not in GDD) the palace's own support
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) brutes are heavy
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE LAST JUDGMENT: the Pit has come for every soul. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS). The damned
## and imps throughout, hell knights from 3:00, the Lilim Witches from 4:00,
## succubi from the Hall of Mirrors, demon brutes from the Ballroom. Succubi
## stay rare (Temptation holds at most 3 summons at once anyway).
const SEGMENTS := [
	# Zone I, the Rose Garden.
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"damned": 1.0},
		"objective": "The Rose Garden: the damned shuffle through the thorns. Lead them through the pits"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"damned": 0.7, "imp": 0.3},
		"objective": "Imps fly over the pits: they never burn"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"damned": 0.55, "imp": 0.25, "hell_knight": 0.2},
		"objective": "Hell knights in ember armour: step out of the burning blade"},
	{"start": 240.0, "rate": 2.1, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"damned": 0.52, "imp": 0.24, "hell_knight": 0.2, "lilim_witch": 0.04},
		"objective": "Lilim Witches open pits under your ring: kill them first"},
	# Zone II, the Hall of Mirrors.
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"damned": 0.45, "imp": 0.24, "hell_knight": 0.24, "lilim_witch": 0.05, "succubus": 0.02},
		"objective": "The Hall of Mirrors: your reflections lure your dead astray"},
	# Zone III, the Ballroom.
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"damned": 0.4, "imp": 0.25, "hell_knight": 0.27, "lilim_witch": 0.05, "succubus": 0.02, "demon_brute": 0.01},
		"objective": "The Ballroom over the lava lake: mind the burning floor"},
	# Zone IV, the Queen's Chamber.
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"damned": 0.36, "imp": 0.25, "hell_knight": 0.3, "lilim_witch": 0.055, "succubus": 0.025, "demon_brute": 0.015},
		"objective": "The Queen's Chamber: the court of desire awaits its queen"},
	# 17:00, the boss: a thinner trickle so the fight stays readable.
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"damned": 0.42, "imp": 0.3, "hell_knight": 0.22, "lilim_witch": 0.04, "succubus": 0.01, "demon_brute": 0.01},
		"objective": "Lilith has come for your dead: keep them your own"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the Act VI
## type "portal" (`count` demon portals around the necromancer,
## DemonPortals.start_event(), keys count / banner / distance_min /
## distance_max / table / pour_every) and the SilkPalaceDirector's "twins"
## (the two sisters `kinds` fly in from the spawn ring, `apart` px apart, with
## their `escort` groups)).
const EVENTS := [
	# Zone I: the Rose Garden.
	{"time": 20.0, "type": "wave", "banner": "The damned are dragged through the roses in chains!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "damned", "count": 16, "elite": false}]},
	{"time": 90.0, "type": "portal", "count": 1, "banner": "A demon portal tears open among the roses! Stand in its ring to seal it!"},  # TUNING (not in GDD)
	{"time": 150.0, "type": "wave", "banner": "A swarm of imps!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "imp", "count": 12, "elite": false}]},
	{"time": 245.0, "type": "wave", "banner": "Lilim Witches! They open pits under your ring!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "lilim_witch", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 3, "elite": false}, {"kind": "damned", "count": 8, "elite": false}]},
	# Zone II (5:00): the Hall of Mirrors.
	{"time": 330.0, "type": "wave", "banner": "A succubus! Kill her before she turns your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 1, "elite": false}, {"kind": "imp", "count": 8, "elite": false}]},
	{"time": 420.0, "type": "portal", "count": 2, "banner": "Two portals open in the hall of mirrors!"},  # TUNING (not in GDD)
	{"time": 470.0, "type": "wave", "banner": "Witches gather at the portals: seal them before they heal the host!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "lilim_witch", "count": 3, "elite": false}, {"kind": "hell_knight", "count": 4, "elite": false}, {"kind": "imp", "count": 8, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "The succubi descend!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 3, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	# Zone III (10:00): the Ballroom.
	{"time": 640.0, "type": "wave", "banner": "A demon brute shoulders across the ballroom!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 1, "elite": false}, {"kind": "imp", "count": 10, "elite": false}]},
	{"time": 700.0, "type": "twins", "banner": "THE TWIN SUCCUBI glide in hand in hand: they charm in turns. Kill one and the other rages!",  # Owner-approved proposal: the miniboss
		"kinds": [SilkPalaceEnemyData.TWIN_NAAMAH, SilkPalaceEnemyData.TWIN_AGRAT], "apart": 90.0,  # TUNING (not in GDD)
		"escort": [{"kind": "imp", "count": 6, "elite": false}]},  # TUNING (not in GDD)
	{"time": 780.0, "type": "portal", "count": 2, "banner": "The portals multiply over the lava!"},  # TUNING (not in GDD)
	{"time": 840.0, "type": "wave", "banner": "Brutes, knights and witches!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "demon_brute", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 4, "elite": false}, {"kind": "lilim_witch", "count": 2, "elite": false}]},
	# Zone IV (15:00): the Queen's Chamber.
	{"time": 930.0, "type": "portal", "count": 3, "banner": "Hell gapes open in the queen's chamber!"},  # TUNING (not in GDD)
	{"time": 990.0, "type": "wave", "banner": "The court of desire gathers for its queen!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "succubus", "count": 2, "elite": false}, {"kind": "hell_knight", "count": 5, "elite": false}, {"kind": "lilim_witch", "count": 2, "elite": false}, {"kind": "damned", "count": 12, "elite": false}]},
	# 17:00 Lilith (BOSS_TIME), plus two sallies.
	{"time": 1100.0, "type": "wave", "banner": "The queen's knights rally to her!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "hell_knight", "count": 5, "elite": false}, {"kind": "damned", "count": 10, "elite": false}]},
	{"time": 1170.0, "type": "wave", "banner": "Witches of the court!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "lilim_witch", "count": 2, "elite": false}, {"kind": "imp", "count": 10, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES,
## plus "id" (SilkPalaceDirector's zone test) and "start" (the Hell Pits draw a
## new table of fixed pits for each zone). `ground` is a SilkPalaceGround look:
## style "roses" (dark soil, black petals and thorns), "mirrors" (black-violet
## marble flags, glints), "ballroom" (rose marble over the lava lake's glow) or
## "chamber" (velvet runners on dark marble); base / line / accent colours of
## the code floor (the tiles/silk_palace_<style> PNG replaces them when it
## exists). Obstacle kinds are drawn by SilkPalaceGlyphs and InfernoGlyphs
## (their obstacles/<kind> PNGs when they exist).
const ZONES := [
	{"id": "rose_garden", "start": 0.0, "numeral": "I", "name": "The Rose Garden",  # Owner-approved proposal zone I
		"blurb": "Rose gardens of black thorns, where the damned are led to the palace",
		"ground": {"style": "roses", "base": Color(0.09, 0.07, 0.08), "line": Color(0.07, 0.05, 0.06),
			"accent": Color(0.36, 0.10, 0.23)},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 1717,  # TUNING (not in GDD) also salts the fixed Hell Pits (HellPits)
			"kinds": {
				"black_rosebush": {"weight": 0.55, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"rose_column": {"weight": 0.25, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
				"candelabra": {"weight": 0.2, "shape": "circle", "sizes": [9.0, 11.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "hall_of_mirrors", "start": 300.0, "numeral": "II", "name": "The Hall of Mirrors",  # Owner-approved proposal zone II
		"blurb": "A hall of a thousand mirrors: every one of them shows you, and your dead follow",
		"ground": {"style": "mirrors", "base": Color(0.08, 0.07, 0.10), "line": Color(0.13, 0.11, 0.17),
			"accent": Color(0.66, 0.60, 0.78)},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 1718,  # TUNING (not in GDD)
			"kinds": {
				"palace_mirror": {"weight": 0.42, "shape": "circle", "sizes": [11.0, 13.0]},  # TUNING (not in GDD) the reflections stand at these
				"mirror_wall": {"weight": 0.3, "shape": "rect", "sizes": [44.0, 60.0], "short": 14.0},  # TUNING (not in GDD) and at these
				"rose_column": {"weight": 0.28, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "ballroom", "start": 600.0, "numeral": "III", "name": "The Ballroom",  # Owner-approved proposal zone III
		"blurb": "A ballroom floor of rose marble laid over a lake of lava",
		"ground": {"style": "ballroom", "base": Color(0.11, 0.08, 0.09), "line": Color(0.16, 0.10, 0.12),
			"accent": Palette.INFERNO_LAVA},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 1719,  # TUNING (not in GDD) an open floor: the lava is the hazard
			"kinds": {
				"candelabra": {"weight": 0.35, "shape": "circle", "sizes": [9.0, 11.0]},  # TUNING (not in GDD)
				"velvet_divan": {"weight": 0.35, "shape": "rect", "sizes": [40.0, 52.0], "short": 20.0},  # TUNING (not in GDD)
				"rose_column": {"weight": 0.3, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "queens_chamber", "start": 900.0, "numeral": "IV", "name": "The Queen's Chamber",  # Owner-approved proposal zone IV
		"blurb": "Velvet, black roses and mirrors: the bedchamber of the Queen of the Night",
		"ground": {"style": "chamber", "base": Color(0.10, 0.06, 0.08), "line": Color(0.15, 0.08, 0.11),
			"accent": Palette.INFERNO_DEMON_DARK},
		"arena": {"density": 0.22, "clear_radius": 240.0, "layout_seed": 1720,  # TUNING (not in GDD)
			"kinds": {
				"velvet_divan": {"weight": 0.3, "shape": "rect", "sizes": [40.0, 52.0], "short": 20.0},  # TUNING (not in GDD)
				"black_rosebush": {"weight": 0.3, "shape": "circle", "sizes": [12.0, 15.0]},  # TUNING (not in GDD)
				"candelabra": {"weight": 0.25, "shape": "circle", "sizes": [9.0, 11.0]},  # TUNING (not in GDD)
				"palace_mirror": {"weight": 0.15, "shape": "circle", "sizes": [11.0, 13.0]},  # TUNING (not in GDD)
			}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "DEEPER INTO THE PALACE OF SILK AND ASH  -  ZONE %s",
	"zone_color": Palette.INFERNO_CHARM,  # The act's charm pink.
	"fog_color": Color(0.10, 0.05, 0.08),  # Incense smoke.
	"fog_bank_color": Color(0.36, 0.18, 0.28),  # Rose-tinted smoke banks.
	"zones": ZONES,
}

## The Palace's systems (SilkPalaceDirector; StageRegistry "silk_palace").
##   mirror_zone      — ZONES "id" of the Hall of Mirrors (the reflections run
##                      only while it is the current zone).
##   mirror_kinds     — obstacle kinds a reflection stands at.
##   mirror_first     — s into the zone before the first reflection.
##   mirror_every     — s between two reflections.
##   mirror_reach     — px from the necromancer a mirror must stand within.
##   mirror_near      — px: a mirror closer than this to him is skipped (the
##                      reflection must be out on the ring's edge).
##   mirror_shimmer   — s the mirror shimmers before the reflection steps out
##                      (the telegraph).
##   mirror_life      — s the reflection stands.
##   mirror_lure      — px around the reflection within which summons are lured.
##   mirror_turned    — most summons one reflection lures (the nearest it first).
##   mirror_turn      — s a lured summon walks toward the reflection
##                      (SummonedUnit.misdirect(), the one turn-around path).
##   mirror_speed     — share (0..1) of its speed a lured summon walks at.
##   guest_* / guests — the Burning Gate's kinds in small squads (candidate ids:
##                      the first this build knows; none = skipped).
const SILK_PALACE := {
	"mirror_zone": "hall_of_mirrors",  # Owner-approved proposal: "the Hall of Mirrors (reflections of the necromancer confuse summon targeting)"
	"mirror_kinds": ["palace_mirror", "mirror_wall"],
	"mirror_first": 6.0,  # TUNING (not in GDD) s
	"mirror_every": 6.0,  # TUNING (not in GDD) s
	"mirror_reach": 420.0,  # TUNING (not in GDD) px
	"mirror_near": 90.0,  # TUNING (not in GDD) px
	"mirror_shimmer": 0.8,  # TUNING (not in GDD) s
	"mirror_life": 2.4,  # TUNING (not in GDD) s
	"mirror_lure": 200.0,  # TUNING (not in GDD) px
	"mirror_turned": 4,  # TUNING (not in GDD)
	"mirror_turn": 1.6,  # TUNING (not in GDD) s
	"mirror_speed": 0.8,  # TUNING (not in GDD)
	"guest_first": 300.0,  # TUNING (not in GDD) no guests before 5:00
	"guest_interval": 90.0,  # TUNING (not in GDD)
	"guest_until": 1000.0,  # TUNING (not in GDD) the boss fight keeps its own roster
	"guest_count": 3,  # TUNING (not in GDD)
	"guest_growth": 0.4,  # TUNING (not in GDD)
	"guest_max": 6,  # TUNING (not in GDD)
	"guests": [
		{"ids": ["hellhound", "lava_hound", "hell_hound"], "weight": 0.7},  # The Burning Gate (Act VI phase 2): the lava hounds
		{"ids": ["pit_cultist", "cultist"], "weight": 0.4},  # The Burning Gate: the Pit Cultists
	],
}

## Lilith's arrival (keys as GraveyardStage.BOSS): LilithData.ARRIVAL (boss id
## "lilith"), whose `time` equals BOSS_TIME (17:00). Her script is
## scripts/enemies/inferno/boss_lilith.gd (no "script" key: the id names it).
const BOSS: Dictionary = LilithData.ARRIVAL

## Floor look of the placeholder "inferno" ground (InfernoGround; the stage now
## uses SilkPalaceGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "velvet",  # Rose-veined marble, velvet runners, black-rose petals.
	"base": Color(0.22, 0.17, 0.20),  # TUNING (not in GDD) rose-veined marble
	"line": Color(0.28, 0.22, 0.26),  # TUNING (not in GDD)
	"accent": Palette.INFERNO_DEMON_DARK,  # TUNING (not in GDD) velvet runners
	"trim": Color(0.10, 0.05, 0.08),  # TUNING (not in GDD) black-rose petals
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Palace of Silk and Ash",
	"short_name": "The Palace",
	"chapter": "Chapter XVII",
	"act": 6,  # Act VI, the Inferno.
	"playable": false,  # Phase 2 built (GDD §15.0 "The Palace of Silk and Ash (Act VI phase 2)"); hidden until the lead's merge and the owner's go.
	"description": "The court of desire: velvet halls, mirrors, rose gardens of black thorns and a ballroom over a lava lake, where every smile is a snare for your dead.",
	"unlock": {"stage": "burning_gate", "boss_kills": 1},  # Owner-approved: each Act VI stage opens the next
	"unlock_text": "Slay Moloch at the Burning Gate to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act VI stages.
	"consecration": {},  # A Covenant event: none in Act VI.
	"crypt_defender": {},  # None in Act VI.
	"arena": ZONES[0]["arena"],
	"ground": "silk_palace",  # SilkPalaceGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"silk_palace": SILK_PALACE,  # SilkPalaceDirector (the Hall of Mirrors' reflections, the Twin Succubi, guests).
	"inferno": true,  # Act VI: the Hell Pits, the portals, Temptation (InfernoRules).
	"pits": PITS,  # Act VI: this stage's Hell Pits overrides.
	"portals": PORTALS,  # Act VI: this stage's portal overrides.
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march"; the fixed pits change with each).
	# Music key "brimstone": the Act VI loop "Hymn of the Pit" (SoundData.BRIMSTONE_SCORE).
	"music": "brimstone",
}
