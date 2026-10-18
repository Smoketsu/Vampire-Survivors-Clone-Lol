## ArchiveStage — STAGE 5, THE HOLLOW ARCHIVE (Act II, the Ancient Eye; GDD
## §15.0 "Act II: the Ancient Eye" and "Act II: the Hollow Archive",
## owner-approved proposal "Stage 5: The Hollow Archive", faction renamed the
## Ancient Eye by the owner): the buried library and observatory under the
## cliffs where the Eye keeps its god's scripture. Every number and event that
## belongs to this stage. StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry). Unlocked by slaying Abbot Merrow in
## Gullhaven Harbour once.
##
## THE CLOCK IS AUTHORITATIVE, as on the Crimson March and in the Sanctum:
## four zones on fixed times (ZONES, run by MarchDirector: a zone banner, a
## sweep of ink, the ground and obstacles around the necromancer re-drawn as
## the next zone). The stage's own mechanics are ArchiveDirector's (ARCHIVE
## below: the Ink Wells' pools, the Orrery's moving arms, the forbidden tomes,
## the Reckoning's look) and RiftDirector's (rifts):
##   countdown  elapsed  zone / event
##   20:00      0:00     Zone I, the Reading Halls: long shelves in rows split
##                       the field into aisles
##   17:30      2:30     the first forbidden tome (optional)
##   15:00      5:00     Zone II, the Ink Wells: pools of black ink slow the
##                       necromancer and raise his Dread; Ink Wraiths rise
##                       out of them
##   13:00      7:00     two more tomes
##   10:00      10:00    Zone III, the Orrery: a huge brass orrery turns in
##                       steps, its arms moving walls with a clear telegraph
##   9:00       11:00    the Librarian (miniboss)
##   8:00       12:00    the last two tomes
##   5:00       15:00    Zone IV, the Unwritten Stacks: a rift every 45 s
##   3:00       17:00    the Archivist, Keeper of the Unwritten
##   0:00       20:00    the Reckoning restyled: the Unwritten
## Single rifts also open in Zones I-III as a preview ("rift" events).
## Every rate, cap and weight is TUNING (not in GDD). The step up over the
## Sanctum (and Gullhaven before it) comes from the Archive's kinds (Scribes
## turning the crowd into claimers, Ink Wraiths through the shelves, Spore
## clouds, splitting masses), the rifts that open behind the army and the stage
## multipliers ENEMY_HP_MULT / ENEMY_DAMAGE_MULT from ENEMY_MULT_FROM.
class_name ArchiveStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "archive"

## Game time (s) at which the Archivist appears (3:00 left).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling.
const ENEMY_HP_MULT: float = 1.2  # TUNING (not in GDD) Act II climbs: Sanctum 1.1, the Archive a step above Gullhaven (Act II integration: 1.25; the naive bot died in 7 of 8 runs)
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.2  # TUNING (not in GDD)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies: Zone II (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) (Act II integration: 300.0; the naive bot died in 7 of 8 runs)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 2.0  # TUNING (not in GDD) owner-approved proposal placeholder (Act I: x1.25, x1.5)

## The Unwritten: the Archive's Reckoning (keys as GraveyardStage.RECKONING
## plus SanctumStage.RECKONING's companions; "kind" the main wave's kind):
## page-wrapped horrors that pass through the stacks, with Ink Wraiths.
##   ink — colour of the ink darkness ArchiveDirector pools around the
##         necromancer once it begins (cosmetic).
const RECKONING := {
	"banner": "THE STACKS UNWRITE THEMSELVES: THE EYE OPENS UPON YOU",
	"kind": ArchiveEnemyData.RECKONER,
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 3,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
	"companions": [{"kind": "ink_wraith", "count": 2, "growth": 0.5}],  # TUNING (not in GDD)
	"ink": Color(0.03, 0.03, 0.08),  # TUNING (not in GDD) ink darkness
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE UNWRITTEN: the last pages close over you. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS).
const SEGMENTS := [
	# Zone I, the Reading Halls.
	{"start": 0.0, "rate": 1.6, "max_alive": 34,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 1.0},
		"objective": "The Reading Halls: the Eye's faithful walk the aisles"},
	{"start": 60.0, "rate": 2.0, "max_alive": 44,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.94, "eye_chanter": 0.06},
		"objective": "Chanters lead the readers: kill them before they claim your dead"},
	{"start": 120.0, "rate": 2.3, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.86, "eye_chanter": 0.07, "scribe": 0.07},
		"objective": "Scribes ink curses on the faithful: a cursed cultist claims your dead"},
	{"start": 180.0, "rate": 2.6, "max_alive": 62,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.80, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.07},
		"objective": "Ink Wraiths slip through the shelves"},
	{"start": 240.0, "rate": 2.9, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.76, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.08, "gibbering_mass": 0.03},
		"objective": "Something gibbers between the stacks"},
	# Zone II, the Ink Wells.
	{"start": 300.0, "rate": 3.1, "max_alive": 82,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.66, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.10, "gibbering_mass": 0.04, "spore_pilgrim": 0.07},
		"objective": "The Ink Wells: stay out of the ink, it fills the mind with dread"},
	{"start": 390.0, "rate": 3.5, "max_alive": 96,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.64, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.10, "gibbering_mass": 0.05, "spore_pilgrim": 0.08},
		"objective": "Pilgrims of the Spore fog the wells"},
	{"start": 480.0, "rate": 3.8, "max_alive": 108,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.62, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.10, "gibbering_mass": 0.06, "spore_pilgrim": 0.09},
		"objective": "The wells overflow"},
	# Zone III, the Orrery.
	{"start": 600.0, "rate": 4.1, "max_alive": 118,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.60, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.09, "gibbering_mass": 0.07, "spore_pilgrim": 0.09},
		"objective": "The Orrery: its brass arms turn; mind where they sweep"},
	{"start": 660.0, "rate": 3.7, "max_alive": 110,  # TUNING (not in GDD) lull for the Librarian
		"weights": {"eye_initiate": 0.62, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.08, "gibbering_mass": 0.07, "spore_pilgrim": 0.08},
		"objective": "The Librarian watches the Orrery"},
	{"start": 750.0, "rate": 4.6, "max_alive": 134,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.58, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.09, "gibbering_mass": 0.08, "spore_pilgrim": 0.10},
		"objective": "The stars turn against you"},
	{"start": 840.0, "rate": 5.0, "max_alive": 146,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.58, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.09, "gibbering_mass": 0.08, "spore_pilgrim": 0.10},
		"objective": "The Unwritten Stacks lie beyond the Orrery"},
	# Zone IV, the Unwritten Stacks.
	{"start": 900.0, "rate": 5.4, "max_alive": 156,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.56, "eye_chanter": 0.06, "scribe": 0.08, "ink_wraith": 0.10, "gibbering_mass": 0.08, "spore_pilgrim": 0.10},
		"objective": "The Unwritten Stacks: rifts tear open behind you"},
	{"start": 960.0, "rate": 5.8, "max_alive": 164,  # TUNING (not in GDD) the density peak of the run
		"weights": {"eye_initiate": 0.56, "eye_chanter": 0.06, "scribe": 0.08, "ink_wraith": 0.10, "gibbering_mass": 0.08, "spore_pilgrim": 0.10},
		"objective": "The Keeper of the Unwritten approaches"},
	# 17:00, the boss: a thinner trickle so the duel stays readable.
	{"start": BOSS_TIME, "rate": 3.4, "max_alive": 104,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.62, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.09, "gibbering_mass": 0.06, "spore_pilgrim": 0.10},
		"objective": "Slay the Archivist"},
	{"start": 1110.0, "rate": 4.2, "max_alive": 124,  # TUNING (not in GDD)
		"weights": {"eye_initiate": 0.60, "eye_chanter": 0.06, "scribe": 0.07, "ink_wraith": 0.10, "gibbering_mass": 0.07, "spore_pilgrim": 0.10},
		"objective": "Slay the Archivist"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave" entries: formation + groups), plus the Archive types:
##   "tomes"     — ArchiveDirector: `count` forbidden lecterns rise
##                 `distance_min`..`distance_max` px from the necromancer
##                 (spread evenly, out of obstacles), each guarded by
##                 ARCHIVE.tome_guards. Standing on one for ARCHIVE.burn_time s
##                 burns its tome: a free level-up card and ARCHIVE.tome_dread
##                 Dread. It crumbles unburned after ARCHIVE.tome_life s.
##   "librarian" — ArchiveDirector: the Librarian miniboss (`kind`) from the
##                 spawn ring; its kit (LibrarianKit) registers it on the HUD's
##                 miniboss bar and pays its XP burst, ChestManager its chest.
##   "rift"      — RiftDirector: one rift (RIFTS keys) whose squad is `groups`.
const EVENTS := [
	# Zone I, the Reading Halls.
	{"time": 15.0, "type": "wave", "banner": "Readers of the Eye shuffle out of the aisles!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 8, "elite": false}]},
	{"time": 50.0, "type": "wave", "banner": "A Chanter leads its readers: it claims the dead!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_chanter", "count": 1, "elite": false}, {"kind": "eye_initiate", "count": 10, "elite": false}]},
	{"time": 95.0, "type": "wave", "banner": "Readers pour from every aisle!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 14, "elite": false}]},
	{"time": 130.0, "type": "wave", "banner": "Scribes of the Unwritten ink the faithful!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scribe", "count": 2, "elite": false}, {"kind": "eye_initiate", "count": 10, "elite": false}]},
	{"time": 150.0, "type": "tomes", "banner": "A forbidden tome lies open on a lectern: burn it for power, if you dare the dread!",  # TUNING (not in GDD)
		"count": 1, "distance_min": 240.0, "distance_max": 320.0},  # TUNING (not in GDD)
	{"time": 200.0, "type": "wave", "banner": "Ink Wraiths slide out between the shelves!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ink_wraith", "count": 6, "elite": false}, {"kind": "eye_initiate", "count": 10, "elite": false}]},
	{"time": 240.0, "type": "rift", "banner": "A RIFT tears open behind your army!",  # TUNING (not in GDD) the first preview
		"groups": [{"kind": "eye_initiate", "count": 8, "elite": false}, {"kind": "scribe", "count": 1, "elite": false}]},
	{"time": 270.0, "type": "wave", "banner": "A Gibbering Mass heaves out of the stacks!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "gibbering_mass", "count": 2, "elite": false}, {"kind": "eye_chanter", "count": 1, "elite": true}, {"kind": "eye_initiate", "count": 10, "elite": false}]},
	# Zone II, the Ink Wells.
	{"time": 320.0, "type": "wave", "banner": "Pilgrims of the Spore wander through the wells!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "spore_pilgrim", "count": 3, "elite": false}, {"kind": "spore_pilgrim", "count": 1, "elite": true}, {"kind": "eye_initiate", "count": 12, "elite": false}]},
	{"time": 370.0, "type": "wave", "banner": "Wraiths rise from the ink!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "ink_wraith", "count": 8, "elite": false}, {"kind": "scribe", "count": 2, "elite": false}, {"kind": "eye_initiate", "count": 12, "elite": false}]},
	{"time": 420.0, "type": "tomes", "banner": "Two more forbidden tomes lie open: each a gift, each a dread!",  # TUNING (not in GDD)
		"count": 2, "distance_min": 260.0, "distance_max": 360.0},  # TUNING (not in GDD)
	{"time": 470.0, "type": "rift", "banner": "A rift spits the Eye out beside you!",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 10, "elite": false}, {"kind": "ink_wraith", "count": 2, "elite": false}]},
	{"time": 510.0, "type": "wave", "banner": "The congregation of the wells surrounds you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 22, "elite": false}, {"kind": "eye_chanter", "count": 2, "elite": false}, {"kind": "gibbering_mass", "count": 2, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "A Scribe-Master leads the pilgrims!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scribe", "count": 1, "elite": true}, {"kind": "spore_pilgrim", "count": 5, "elite": false}, {"kind": "eye_initiate", "count": 10, "elite": false}]},
	# Zone III, the Orrery.
	{"time": 620.0, "type": "wave", "banner": "The faithful march between the orrery's arms!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 20, "elite": false}, {"kind": "gibbering_mass", "count": 2, "elite": false}, {"kind": "gibbering_mass", "count": 1, "elite": true}]},
	{"time": 660.0, "type": "librarian", "banner": "THE LIBRARIAN opens its eye: its gaze turns your dead around!",  # Owner-approved proposal: the Librarian at 9:00
		"kind": "librarian", "elite": false},
	{"time": 720.0, "type": "tomes", "banner": "The last forbidden tomes lie open: burn them all to leave nothing unwritten!",  # TUNING (not in GDD)
		"count": 2, "distance_min": 260.0, "distance_max": 360.0},  # TUNING (not in GDD)
	{"time": 760.0, "type": "rift", "banner": "A rift opens behind the army!",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 10, "elite": false}, {"kind": "spore_pilgrim", "count": 2, "elite": false}, {"kind": "scribe", "count": 1, "elite": false}]},
	{"time": 800.0, "type": "wave", "banner": "Masses and wraiths close the ring!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 22, "elite": false}, {"kind": "ink_wraith", "count": 6, "elite": false}, {"kind": "gibbering_mass", "count": 2, "elite": true}]},
	{"time": 860.0, "type": "wave", "banner": "The Scribes ink the whole crowd!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scribe", "count": 4, "elite": false}, {"kind": "eye_chanter", "count": 2, "elite": false}, {"kind": "eye_initiate", "count": 14, "elite": false}]},
	# Zone IV, the Unwritten Stacks (its rifts are ARCHIVE "rifts" periodic).
	{"time": 930.0, "type": "wave", "banner": "The Unwritten Stacks empty their aisles!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 24, "elite": false}, {"kind": "spore_pilgrim", "count": 3, "elite": false}, {"kind": "spore_pilgrim", "count": 1, "elite": true}, {"kind": "gibbering_mass", "count": 2, "elite": false}]},
	{"time": 985.0, "type": "wave", "banner": "The Keeper's chosen gather before her!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scribe", "count": 2, "elite": true}, {"kind": "ink_wraith", "count": 6, "elite": false}, {"kind": "eye_chanter", "count": 2, "elite": false}, {"kind": "eye_initiate", "count": 12, "elite": false}]},
	# 17:00 the Archivist (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "The readers rush to their Keeper!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 16, "elite": false}, {"kind": "gibbering_mass", "count": 2, "elite": false}, {"kind": "scribe", "count": 1, "elite": true}]},
	{"time": 1140.0, "type": "wave", "banner": "The last of the faithful surround you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "eye_initiate", "count": 20, "elite": false}, {"kind": "ink_wraith", "count": 6, "elite": false}, {"kind": "spore_pilgrim", "count": 3, "elite": false}]},
]

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES
## plus the optional `clear` (px clear circle around the necromancer at this
## zone change; absent = MARCH.transition_clear). `ground` is an ArchiveGround
## look:
##   style  — "halls" (dark parquet and carpet runners), "wells" (black marble
##            stained with ink), "orrery" (a brass-inlaid star chart) or
##            "stacks" (pale, blank paper over stone, fading at the edges).
##   base / line / accent / trim — colours of the code floor, its joints, the
##            zone's decoration and its inlay.
## Obstacle kinds are drawn by ArchiveGlyphs. `arena` may carry `orient` ("h":
## every rect lies along x, so the Reading Halls' shelves stand in rows;
## Arena._generate()) and `aligned` (each obstacle at its cell's centre).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Reading Halls",  # Owner-approved proposal
		"blurb": "Long shelves split the halls into aisles",
		"ground": {"style": "halls", "base": Color(0.13, 0.10, 0.09), "line": Color(0.09, 0.07, 0.06),
			"accent": Color(0.24, 0.10, 0.12), "trim": Color(0.48, 0.38, 0.22)},
		"arena": {"density": 0.86, "clear_radius": 220.0, "layout_seed": 7101, "aligned": true, "orient": "h",  # TUNING (not in GDD) rows of shelves
			"kinds": {
				"bookshelf": {"weight": 0.85, "shape": "rect", "sizes": [80.0, 88.0, 96.0], "short": 20.0},  # TUNING (not in GDD)
				"reading_desk": {"weight": 0.15, "shape": "rect", "sizes": [40.0, 48.0], "short": 24.0},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Ink Wells",  # Owner-approved proposal
		"blurb": "Pools of black ink fill the mind with dread",
		"ground": {"style": "wells", "base": Color(0.10, 0.10, 0.12), "line": Color(0.07, 0.07, 0.09),
			"accent": Color(0.05, 0.05, 0.09), "trim": Color(0.30, 0.32, 0.46)},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 7202, "orient": "h",  # TUNING (not in GDD) every rect lies along x (one sprite per size)
			"kinds": {
				"book_pile": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 15.0, 18.0]},  # TUNING (not in GDD)
				"toppled_shelf": {"weight": 0.5, "shape": "rect", "sizes": [56.0, 68.0, 80.0], "short": 18.0},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Orrery",  # Owner-approved proposal
		"blurb": "A huge brass orrery turns, its arms sweeping the floor",
		"clear": 400.0,  # TUNING (not in GDD) room for the orrery's arms (ARCHIVE orrery arm_length + margin)
		"ground": {"style": "orrery", "base": Color(0.11, 0.10, 0.11), "line": Color(0.08, 0.07, 0.08),
			"accent": Color(0.20, 0.17, 0.10), "trim": Color(0.55, 0.44, 0.22)},
		"arena": {"density": 0.14, "clear_radius": 220.0, "layout_seed": 7303, "orient": "h",  # TUNING (not in GDD) open floor around the orrery
			"kinds": {
				"brass_globe": {"weight": 0.6, "shape": "circle", "sizes": [14.0, 18.0, 22.0]},  # TUNING (not in GDD)
				"chart_table": {"weight": 0.4, "shape": "rect", "sizes": [44.0, 52.0], "short": 26.0},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Unwritten Stacks",  # Owner-approved proposal
		"blurb": "Blank pages drift where the rifts fold the stacks",
		"ground": {"style": "stacks", "base": Color(0.15, 0.14, 0.13), "line": Color(0.11, 0.10, 0.10),
			"accent": Color(0.30, 0.28, 0.25), "trim": Color(0.36, 0.34, 0.46)},
		"arena": {"density": 0.28, "clear_radius": 220.0, "layout_seed": 7404, "orient": "h",  # TUNING (not in GDD)
			"kinds": {
				"blank_shelf": {"weight": 0.5, "shape": "rect", "sizes": [72.0, 84.0, 96.0], "short": 20.0},  # TUNING (not in GDD)
				"page_heap": {"weight": 0.5, "shape": "circle", "sizes": [13.0, 16.0]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH): the zone
## change restyled as a sweep of ink.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE ARCHIVE SHIFTS  -  ZONE %s",
	"zone_color": Color(0.90, 0.86, 0.72),  # Parchment (the Archive's pages; not the UI's gold).
	"fog_color": Color(0.03, 0.03, 0.07),  # Black ink.
	"fog_bank_color": Color(0.14, 0.13, 0.24),
	"zones": ZONES,
}

## The Archive's own mechanics (ArchiveDirector; RiftDirector reads "rifts").
##   wells_zone      — index of the zone (ZONES) whose floor holds the ink
##                     wells (the Ink Wells).
##   well_cell       — px; the field is cut in cells this big, and a cell holds
##                     a well with chance well_chance (stable hash: the same
##                     wells every run; ArchiveHazards treats a well as ink).
##   well_radius_min / well_radius_max — px well size.
##   well_fade       — s the wells take to fill and drain at the zone changes.
##   orrery_zone     — index of the Orrery zone.
##   orrery          — the orrery's arms (moving walls): arms (count),
##                     arm_length (px from the hub's centre), arm_width (px),
##                     hub_radius (px, solid), hold_time (s it rests between
##                     turns), telegraph (s the next sweep is shown), turn_time
##                     (s a turn takes), turn_step (rad per turn; the direction
##                     alternates every turn), reassemble_range (px: when the
##                     necromancer is farther than this from the hub at the end
##                     of a turn, the orrery folds and rises around him again),
##                     fold_time (s it takes to fold away and to rise),
##                     slide_speed (px/s a body held against a resting arm
##                     slides toward its tip, so nobody presses on it for ever).
##   tome_guards     — the guard squad spawned beside each lectern.
##   burn_radius     — px; the necromancer burns a tome standing this close.
##   burn_time       — s of standing to burn it (the channel).
##   tome_life       — s a lectern stays before its tome is resealed (gone).
##   tome_dread      — Dread added when a tome burns (owner-approved "20 Dread").
##   tome_ash / rift_ash — Soul Ash per tome burned / rift closed early (the
##                     "objective_ash" stat, a Soul Ash part).
##   tome_total      — tomes the run places (the sum of the "tomes" events):
##                     burning all of them earns Nothing Unwritten.
##   placement_tries / structure_spacing — spaced, obstacle-free spots.
##   rifts           — RiftDirector (keys there).
const ARCHIVE := {
	"wells_zone": 1,
	"well_cell": 300.0,  # TUNING (not in GDD)
	"well_chance": 0.4,  # TUNING (not in GDD)
	"well_radius_min": 38.0,  # TUNING (not in GDD)
	"well_radius_max": 64.0,  # TUNING (not in GDD)
	"well_fade": 2.0,  # TUNING (not in GDD) visual
	"orrery_zone": 2,
	"orrery": {
		"arms": 4,  # TUNING (not in GDD)
		"arm_length": 320.0,  # TUNING (not in GDD) px
		"arm_width": 14.0,  # TUNING (not in GDD) px
		"hub_radius": 36.0,  # TUNING (not in GDD) px
		"hold_time": 6.0,  # TUNING (not in GDD) s
		"telegraph": 2.0,  # TUNING (not in GDD) owner-approved proposal "a clear telegraph"
		"turn_time": 2.5,  # TUNING (not in GDD) s
		"turn_step": PI / 4.0,  # TUNING (not in GDD) 45 degrees a turn
		"reassemble_range": 720.0,  # TUNING (not in GDD) px
		"fold_time": 1.2,  # TUNING (not in GDD) s
		"slide_speed": 70.0,  # TUNING (not in GDD) px/s a body held against a resting arm slides toward its tip
	},
	"tome_guards": [{"kind": "scribe", "count": 1, "elite": false}, {"kind": "eye_initiate", "count": 3, "elite": false}],  # Owner-approved "each guarded by a Scribe"
	"burn_radius": 30.0,  # TUNING (not in GDD) px
	"burn_time": 1.5,  # TUNING (not in GDD) s
	"tome_life": 90.0,  # TUNING (not in GDD) s
	"tome_dread": 20.0,  # Owner-approved proposal "adds 20 Dread"
	"tome_ash": 6,  # TUNING (not in GDD) small
	"rift_ash": 2,  # TUNING (not in GDD) small
	"tome_total": 5,  # The "tomes" events above: 1 + 2 + 2.
	"placement_tries": 8,  # TUNING (not in GDD)
	"structure_spacing": 170.0,  # TUNING (not in GDD) px
	# Rifts (RiftDirector).
	"rifts": {
		"telegraph": 3.0,  # Owner-approved proposal "telegraphed for 3 s"
		"life": 10.0,  # Owner-approved proposal "closes by itself after 10 s"
		"behind_min": 150.0,  # TUNING (not in GDD) px from the necromancer, behind the army
		"behind_max": 230.0,  # TUNING (not in GDD) px
		"spit_interval": 2.5,  # TUNING (not in GDD) s between the extra cultists an open rift spits
		"spit_groups": [{"kind": "eye_initiate", "count": 2, "elite": false}],  # TUNING (not in GDD)
		"spit_radius": 30.0,  # TUNING (not in GDD) px around the rift the squad lands in
		"periodic_from": 905.0,  # TUNING (not in GDD) Zone IV (owner-approved "rifts open every 45 s")
		"periodic_interval": 45.0,  # Owner-approved proposal
		"periodic_until": 1190.0,  # TUNING (not in GDD) the last one before 0:00
		"periodic_groups": [{"kind": "eye_initiate", "count": 10, "elite": false}, {"kind": "ink_wraith", "count": 2, "elite": false},
			{"kind": "scribe", "count": 1, "elite": false}, {"kind": "gibbering_mass", "count": 1, "elite": false}],  # TUNING (not in GDD)
		"color": Color(0.62, 0.40, 0.80),  # TUNING (not in GDD) the Eye's bioluminescent tear (drawing)
	},
}

## The Archivist's arrival (keys as GraveyardStage.BOSS): ArchivistData.ARRIVAL,
## whose `time` equals BOSS_TIME (17:00).
const BOSS: Dictionary = ArchivistData.ARRIVAL

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Hollow Archive",
	"short_name": "Archive",
	"chapter": "Chapter V",
	"act": 2,  # Act II, the Ancient Eye.
	"playable": true,  # Act II integration (balance-checked, 8-seed batches); the owner playtests it from here.
	"description": "A buried library and observatory under the cliffs where the Eye keeps its god's scripture. Rifts fold the stacks and open doors behind you; the Archivist, Keeper of the Unwritten, guards the last page.",
	"unlock": {"stage": "harbour", "boss_kills": 1},  # owner-approved: each boss unlocks the next stage
	"unlock_text": "Slay Abbot Merrow in Gullhaven Harbour to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act II stages.
	"consecration": {},  # A Covenant event: none in Act II.
	"crypt_defender": {},  # None in Act II.
	"arena": ZONES[0]["arena"],
	"ground": "archive",
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,
	"archive": ARCHIVE,
	"dread": true,  # Act II: Dread on the necromancer (DreadMeter).
	"claims": true,  # Act II: the Ancient Eye claims the fallen (EyeClaims).
	"music": "tide",  # Act II run loop "Below the Tide" (RunLoopSynth).
}
