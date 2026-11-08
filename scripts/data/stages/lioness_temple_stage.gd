## LionessTempleStage — STAGE 35 (temporary number; final stage 20), THE TEMPLE OF THE LIONESS
## (temporary Act XII, the Necropolis Dynasty, final slot VII; GDD §15.0 "The
## Temple of the Lioness (Dynasty phase 2)" and the rows after it; proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 3 "Stage B"). A sun-baked temple of
## colonnades and statue-lined courts, sacred to the goddess of war and plague:
## here the stone itself walks.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## The stage runs the Dynasty's three shared rules ("dynasty": true: Rebirth,
## the Black Land, Heka; DynastyRules) and the Devourer's Hour Reckoning. Its
## own systems (LionessTempleDirector, config LIONESS_TEMPLE):
##   * THE AWAKENING STATUES: the temple's statue rows (the obstacle kind
##     dyn_statue_row) are ordinary obstacles until a zone change, a timeline
##     event or the Lion Warden's roar wakes some: their eyes glow 2 s, then the
##     row leaves the layout (a gap, through Arena.remove_obstacle()) and its
##     stone walks as Ushabti Statues, or as one Woken Colossus.
##   * THE LION WARDEN (the miniboss, 11:00 in the Hypostyle Hall): the hall
##     seals around the necromancer and the Warden stands in its one doorway;
##     kill him to pass.
## Four clock-driven zones (ZONES, MarchDirector; LionessTempleGround draws
## their floors): THE AVENUE OF STATUES (rows of statues on their cells), THE
## COURTYARD, THE HYPOSTYLE HALL (a forest of colonnades) and THE SANCTUARY.
## Its kinds: the shared Dynasty kinds, the Bastet Hunter and the Ushabti
## Statue (shared rows, DynastyEnemyData), the Woken Colossus, the Lion Warden
## and Sekhmet's wine jars (LionessTempleEnemyData). Sekhmet, the Lioness of
## Retribution (BossSekhmet, SekhmetData) arrives with 3:00 left: the Hunt, the
## Red Wind, the Feast; the Reckoning at 0:00.
## Tuned for the act's FINAL slot VII (docs/last_acts/PLAN.md: the Shogunate /
## Olympus level), not its temporary number. Playable since the act went
## live (the lead's integration). Every rate, cap and weight
## is TUNING (not in GDD).
class_name LionessTempleStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "lioness_temple"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot VII sits between the Shogunate's 1.55-1.65 and Olympus's 1.45; Rebirth
## gives an uncountered body up to 1 + 0.7 + 0.7 of its HP again).
const ENEMY_HP_MULT: float = 1.55  # TUNING (not in GDD) foundation stub 1.45 (the stubs were easy); tuned in the balance pass
## Enemy damage multiplier of this stage on top of the shared time scaling
## (a returned body hits x1.2 per return on top).
const ENEMY_DAMAGE_MULT: float = 1.4  # TUNING (not in GDD) foundation stub 1.35; tuned in the balance pass
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to IX (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 2 of the act

# =====================================================================================
# Zones and their look
# =====================================================================================

## Obstacle kinds of the stage (the Dynasty art, obstacles/<kind>_<size>[_v];
## the one-size kinds drawn by LionessTempleGlyphs from obstacles/<kind>);
## each keeps the same sizes in every zone, so its art keys stay the same:
##   dyn_statue_row        — a row of 3 (short) or 5 (long) dormant ushabti
##                           statues (rect): THE ROWS THAT WAKE.
##   dyn_colonnade         — a short or long colonnade (rect): Sekhmet's pillars.
##   dyn_obelisk           — a small or tall obelisk (circle).
##   dyn_brazier           — a stone brazier with fire (circle, one size).
##   dyn_sphinx_head       — a half-buried sphinx head (circle, one size).
##   dyn_sandstone_blocks  — broken blocks and a snapped column (circle, one size).
## The statue row's layout entry (shared by every zone).
const STATUE_ROW := {"shape": "rect", "sizes": [36.0, 56.0], "short": 16.0}  # TUNING (not in GDD) the art's 36 / 56 px rows
## The colonnade's layout entry (shared by every zone).
const COLONNADE := {"shape": "rect", "sizes": [44.0, 72.0], "short": 18.0}  # TUNING (not in GDD) the art's 44 / 72 px colonnades
## The obelisk's layout entry (shared by every zone).
const OBELISK := {"shape": "circle", "sizes": [7.0, 9.0]}  # TUNING (not in GDD) the art's 16 / 20 px obelisks
## The brazier's layout entry (shared by every zone).
const BRAZIER := {"shape": "circle", "sizes": [9.0]}  # TUNING (not in GDD) the art's 20 px brazier
## The sphinx head's layout entry (shared by every zone).
const SPHINX_HEAD := {"shape": "circle", "sizes": [15.0]}  # TUNING (not in GDD) the art's 36 px head
## The broken blocks' layout entry (shared by every zone).
const SANDSTONE_BLOCKS := {"shape": "circle", "sizes": [15.0]}  # TUNING (not in GDD) the art's 36 px blocks

## The four zones (owner-approved proposal names; the clock is authoritative).
## Keys as CrimsonMarchStage.ZONES (MarchDirector). `ground` is a
## LionessTempleGround look:
##   style  — "avenue" (processional slabs, bronze inlay), "courtyard" (a
##            checker court), "hypostyle" (dark slabs, glyph dashes) or
##            "sanctuary" (red-tinted slabs, a faint sun ring): the art tile
##            tiles/lioness_temple_<style>.
##   base / line / accent / trim — colours of the code floor, its cracks, its
##            stones and its inlay.
## `arena` is the zone's obstacle layout (keys as GraveyardStage.ARENA; each
## kind's entry is one of the constants above plus its weight; "aligned" puts
## each obstacle at its cell's centre: rows of statues, a forest of columns).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Avenue of Statues",  # Owner-approved proposal (zones)
		"blurb": "The processional way, lined with the goddess's sleeping servants",
		"ground": {"style": "avenue", "base": Color(0.50, 0.40, 0.27), "line": Color(0.40, 0.31, 0.20),
			"accent": Palette.DYN_SAND_LIGHT, "trim": Palette.DYN_BRONZE},
		"arena": {"density": 0.26, "clear_radius": 220.0, "layout_seed": 3535,  # TUNING (not in GDD) statue-lined (first pass 0.42 aligned: the seed-7 army bot's ring broke up among the rows from the first minute)
			"kinds": {
				"dyn_statue_row": {"weight": 0.55, "shape": STATUE_ROW["shape"], "sizes": STATUE_ROW["sizes"], "short": STATUE_ROW["short"]},  # TUNING (not in GDD)
				"dyn_obelisk": {"weight": 0.2, "shape": OBELISK["shape"], "sizes": OBELISK["sizes"]},  # TUNING (not in GDD)
				"dyn_sphinx_head": {"weight": 0.15, "shape": SPHINX_HEAD["shape"], "sizes": SPHINX_HEAD["sizes"]},  # TUNING (not in GDD)
				"dyn_brazier": {"weight": 0.1, "shape": BRAZIER["shape"], "sizes": BRAZIER["sizes"]},  # TUNING (not in GDD)
			}}},
	{"start": 300.0, "numeral": "II", "name": "The Courtyard",  # Owner-approved proposal (zones)
		"blurb": "A sun-bleached court, its statues watching from the walls",
		"ground": {"style": "courtyard", "base": Color(0.55, 0.45, 0.30), "line": Color(0.44, 0.35, 0.22),
			"accent": Palette.DYN_SAND_LIGHT, "trim": Palette.DYN_CARNELIAN},
		"arena": {"density": 0.3, "clear_radius": 220.0, "layout_seed": 3545,  # TUNING (not in GDD)
			"kinds": {
				"dyn_statue_row": {"weight": 0.38, "shape": STATUE_ROW["shape"], "sizes": STATUE_ROW["sizes"], "short": STATUE_ROW["short"]},  # TUNING (not in GDD)
				"dyn_colonnade": {"weight": 0.22, "shape": COLONNADE["shape"], "sizes": COLONNADE["sizes"], "short": COLONNADE["short"]},  # TUNING (not in GDD)
				"dyn_brazier": {"weight": 0.2, "shape": BRAZIER["shape"], "sizes": BRAZIER["sizes"]},  # TUNING (not in GDD)
				"dyn_sandstone_blocks": {"weight": 0.2, "shape": SANDSTONE_BLOCKS["shape"], "sizes": SANDSTONE_BLOCKS["sizes"]},  # TUNING (not in GDD)
			}}},
	{"start": 600.0, "numeral": "III", "name": "The Hypostyle Hall",  # Owner-approved proposal (zones)
		"blurb": "A forest of painted columns, and the Warden at its door",
		"ground": {"style": "hypostyle", "base": Color(0.30, 0.25, 0.20), "line": Color(0.22, 0.18, 0.14),
			"accent": Palette.DYN_SAND_DARK, "trim": Palette.DYN_LAPIS},
		"arena": {"density": 0.3, "clear_radius": 220.0, "layout_seed": 3555,  # TUNING (not in GDD) a forest of columns, kept passable (first pass 0.46 aligned)
			"kinds": {
				"dyn_colonnade": {"weight": 0.55, "shape": COLONNADE["shape"], "sizes": COLONNADE["sizes"], "short": COLONNADE["short"]},  # TUNING (not in GDD)
				"dyn_statue_row": {"weight": 0.3, "shape": STATUE_ROW["shape"], "sizes": STATUE_ROW["sizes"], "short": STATUE_ROW["short"]},  # TUNING (not in GDD)
				"dyn_obelisk": {"weight": 0.15, "shape": OBELISK["shape"], "sizes": OBELISK["sizes"]},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Sanctuary",  # Owner-approved proposal (zones)
		"blurb": "The goddess's own court, where the lioness waits on her pillars",
		"ground": {"style": "sanctuary", "base": Color(0.48, 0.30, 0.22), "line": Color(0.36, 0.20, 0.15),
			"accent": Palette.DYN_SAND, "trim": Palette.DYN_CARNELIAN},
		"arena": {"density": 0.26, "clear_radius": 240.0, "layout_seed": 3565,  # TUNING (not in GDD) open enough for her leaps
			"kinds": {
				"dyn_colonnade": {"weight": 0.38, "shape": COLONNADE["shape"], "sizes": COLONNADE["sizes"], "short": COLONNADE["short"]},  # TUNING (not in GDD) her pillars
				"dyn_statue_row": {"weight": 0.22, "shape": STATUE_ROW["shape"], "sizes": STATUE_ROW["sizes"], "short": STATUE_ROW["short"]},  # TUNING (not in GDD)
				"dyn_obelisk": {"weight": 0.22, "shape": OBELISK["shape"], "sizes": OBELISK["sizes"]},  # TUNING (not in GDD)
				"dyn_brazier": {"weight": 0.18, "shape": BRAZIER["shape"], "sizes": BRAZIER["sizes"]},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE TEMPLE OF THE LIONESS  -  ZONE %s",  # TUNING (not in GDD)
	"zone_color": Palette.DYN_SAND_LIGHT,  # Sun-bleached sandstone (never the UI's soul-teal).
	"fog_color": Color(0.20, 0.12, 0.06),  # A dusty dusk.
	"fog_bank_color": Palette.DYN_SAND,  # Blowing sand.
	"zones": ZONES,
}

## The Temple's systems (LionessTempleDirector; StageRegistry "lioness_temple"):
##   zone_wakes          — statue rows woken at each zone's start (index =
##                         zone; 0 = none), zone_wake_delay s after it (the
##                         new layout stands by then).
##   zone_wake_banner    — the banner of a zone's wake.
##   wake_min / wake_max — px from the necromancer a waking row stands (the
##                         nearest first).
##   glow_time           — s the eyes glow before the stone walks.
##   small_row / long_row — Ushabti Statues out of a short / long row.
##   colossus_every      — every this-many-th long row wakes as one Woken
##                         Colossus instead.
##   seal_radius         — px of the Lion Warden's sealed hall.
##   seal_time           — s before the seal falls by itself (he steps out).
##   door_gap            — rad of the doorway left open in the drawn ring.
##   seal_objective      — HUD objective while sealed (%d: s left).
##   seal_timeout_banner / warden_down_banner — the seal's two endings.
const LIONESS_TEMPLE := {
	"zone_wakes": [0, 3, 3, 4],  # TUNING (not in GDD) rows woken at each zone's start
	"zone_wake_delay": 3.0,  # TUNING (not in GDD) s
	"zone_wake_banner": "The statues of the temple open their eyes!",  # TUNING (not in GDD)
	"wake_min": 140.0,  # TUNING (not in GDD) px
	"wake_max": 620.0,  # TUNING (not in GDD) px (the edge of the view)
	"glow_time": 2.0,  # Owner-approved proposal: "eyes glow for 2 s"
	"small_row": 2,  # TUNING (not in GDD) Ushabti out of a short row (3 statues drawn: 2 walk, 1 crumbles)
	"long_row": 3,  # TUNING (not in GDD) Ushabti out of a long row (5 drawn)
	"colossus_every": 2,  # TUNING (not in GDD) every 2nd long row wakes as one Woken Colossus
	"seal_radius": 220.0,  # TUNING (not in GDD) px: the Warden in his doorway stands within the Bone Ring's reach (first passes 400 and 280: the ring never reached him before the seal fell)
	"seal_time": 100.0,  # TUNING (not in GDD) s
	"door_gap": 0.5,  # TUNING (not in GDD) rad (drawing)
	"seal_objective": "THE LION WARDEN holds the only door: kill him to leave the hall (%d s)",  # TUNING (not in GDD)
	"seal_timeout_banner": "The seal crumbles: the Lion Warden steps out of his door!",  # TUNING (not in GDD)
	"warden_down_banner": "The Lion Warden falls! The way through the hall is open.",  # TUNING (not in GDD)
}

# =====================================================================================
# The Reckoning and the timeline
# =====================================================================================

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the
## DEVOURER'S HOUR, shared by every Dynasty stage: every sarcophagus opens
## ("kind": the khopesh guard, with the shared kinds as companions), Rebirth
## has no limit, the Sandstorm becomes permanent and the Devourer sweeps its
## lanes ("devourers_hour": DynastyRulesData.DEVOURER keys; {} = those
## defaults).
const RECKONING := {
	"banner": "THE DEVOURER'S HOUR: EVERY SARCOPHAGUS OPENS",
	"kind": DynastyEnemyData.RECKONING_KIND,  # The shared Devourer's Hour heavy (the khopesh guard).
	"devourers_hour": {},  # DynastyRulesData.DEVOURER defaults.
	"companions": DynastyEnemyData.RECKONING_COMPANIONS,  # Mummies, scarabs, a Heka priest.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) guards
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE DEVOURER'S HOUR: the dead rise without end, and the Devourer eats its lanes. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS). The
## Ushabti never come from the edge: the statues wake (LIONESS_TEMPLE). The
## Bastet Hunters join from 4:00; the priests stay rare.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"mummy": 0.6, "mummy_female": 0.4},
		"objective": "The Avenue of Statues: the wrapped dead walk. A fallen mummy's Name waits over it: smash it or raise it"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"mummy": 0.45, "mummy_female": 0.3, "scarab_swarm": 0.25},
		"objective": "Watch the statues: when their eyes glow, the stone walks"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"mummy": 0.4, "mummy_female": 0.27, "scarab_swarm": 0.18, "khopesh_guard": 0.1, "heka_priest": 0.05},
		"objective": "Heka priests curse your dead. A Mender's heal or a Warder's barrier clears the glyph"},
	{"start": 240.0, "rate": 2.1, "max_alive": 54,  # TUNING (not in GDD)
		"weights": {"mummy": 0.38, "mummy_female": 0.26, "scarab_swarm": 0.16, "khopesh_guard": 0.1, "heka_priest": 0.05, "bastet_hunter": 0.03},
		"objective": "Bastet's hunters swim in the sand toward your archers and mages. A spell throws them out"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"mummy": 0.35, "mummy_female": 0.24, "scarab_swarm": 0.16, "khopesh_guard": 0.12, "heka_priest": 0.05, "embalmer": 0.04, "bastet_hunter": 0.03},
		"objective": "The Courtyard: Embalmers hasten the Names, and the Canopic Jars hold them. Break the jars"},
	{"start": 600.0, "rate": 2.7, "max_alive": 72,  # TUNING (not in GDD)
		"weights": {"mummy": 0.33, "mummy_female": 0.23, "scarab_swarm": 0.15, "khopesh_guard": 0.14, "heka_priest": 0.06, "embalmer": 0.04, "bastet_hunter": 0.03},
		"objective": "The Hypostyle Hall: when the sand blows, every bow and spell reaches half as far"},
	{"start": 900.0, "rate": 3.0, "max_alive": 84,  # TUNING (not in GDD)
		"weights": {"mummy": 0.31, "mummy_female": 0.22, "scarab_swarm": 0.15, "khopesh_guard": 0.16, "heka_priest": 0.06, "embalmer": 0.04, "bastet_hunter": 0.04},
		"objective": "The Sanctuary: the goddess's own court. She is watching from her pillars"},
	{"start": BOSS_TIME, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"mummy": 0.36, "mummy_female": 0.25, "scarab_swarm": 0.15, "khopesh_guard": 0.12, "heka_priest": 0.04, "embalmer": 0.04, "bastet_hunter": 0.03},
		"objective": "Sekhmet has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS, plus the Temple's
## "statues_wake" (rows: statue rows woken near the necromancer) and
## "lion_warden" (the miniboss and his sealed hall), LionessTempleDirector).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The wrapped dead rise from the sand!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 8, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 75.0, "type": "statues_wake", "rows": 2, "banner": "The statues of the avenue open their eyes!"},  # TUNING (not in GDD) the first wake teaches the rule
	{"time": 90.0, "type": "wave", "banner": "A swarm of scarabs pours out of a shrine!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Heka priest raises his hands: a glyph for your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 1, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 210.0, "type": "statues_wake", "rows": 3, "banner": "More of the avenue's statues stir!"},  # TUNING (not in GDD)
	{"time": 245.0, "type": "wave", "banner": "The cat-masked hunters of Bastet slip into the sand!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "bastet_hunter", "count": 2, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 380.0, "type": "wave", "banner": "The temple guard advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 5, "elite": false}, {"kind": "heka_priest", "count": 1, "elite": false}]},
	{"time": 450.0, "type": "statues_wake", "rows": 3, "banner": "The courtyard's statues step down from the walls!"},  # TUNING (not in GDD)
	{"time": 520.0, "type": "wave", "banner": "A hunting party of Bastet!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "bastet_hunter", "count": 3, "elite": false}, {"kind": "scarab_swarm", "count": 4, "elite": false}]},
	{"time": 640.0, "type": "wave", "banner": "The priesthood comes to wrap its dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "embalmer", "count": 2, "elite": false}, {"kind": "mummy", "count": 10, "elite": false}]},
	{"time": 660.0, "type": "lion_warden", "kind": LionessTempleEnemyData.LION_WARDEN,  # TUNING (not in GDD) the miniboss, in the Hypostyle Hall
		"banner": "THE LION WARDEN: the hall is sealed, and he stands in its only door!"},
	{"time": 820.0, "type": "wave", "banner": "A procession of the dead!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 12, "elite": false}, {"kind": "mummy_female", "count": 10, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 860.0, "type": "statues_wake", "rows": 4, "banner": "The whole hall's statues wake at once!"},  # TUNING (not in GDD)
	{"time": 950.0, "type": "wave", "banner": "The goddess's court comes for you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 4, "elite": false}, {"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "bastet_hunter", "count": 3, "elite": false}, {"kind": "scarab_swarm", "count": 4, "elite": false}]},
	{"time": 995.0, "type": "wave", "banner": "The dead gather before the goddess!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 12, "elite": false}, {"kind": "mummy_female", "count": 10, "elite": false}, {"kind": "embalmer", "count": 1, "elite": false}]},
]

## The stage boss's arrival (keys as GraveyardStage.BOSS): Sekhmet
## (scripts/enemies/dynasty/boss_sekhmet.gd, loaded by name for her id).
const BOSS := {
	"id": "sekhmet",
	"time": BOSS_TIME,
	"display_name": "Sekhmet, the Lioness of Retribution",  # Owner-approved proposal
	"short_name": "Sekhmet",
	"arrive_banner": "Sekhmet, the Lioness of Retribution, leaps down from her pillar!",  # TUNING (not in GDD)
	"defeat_banner": "Sekhmet falls, and the temple is still! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Sekhmet is dead. Survive the Devourer's Hour... you cannot.",  # TUNING (not in GDD)
}

## The foundation stub's floor (DynastyGround "floor" key), kept for the other
## tools that read it; the stage draws LionessTempleGround ("ground").
const FLOOR := {
	"style": "temple",  # sun-baked sandstone flagstones, carnelian inlay.
	"base": Color(0.50, 0.40, 0.27),  # TUNING (not in GDD)
	"line": Color(0.40, 0.31, 0.20),  # TUNING (not in GDD)
	"accent": Palette.DYN_SAND_LIGHT,  # TUNING (not in GDD)
	"trim": Palette.DYN_CARNELIAN,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Temple of the Lioness",
	"short_name": "Lioness Temple",
	"chapter": "Chapter XXXV",  # Temporary (the reorder pass renumbers; final stage 20).
	"act": 12,  # Temporary Act XII, the Necropolis Dynasty (final slot VII; docs/last_acts/PLAN.md).
	"playable": true,  # The Necropolis Dynasty goes live (integration, GDD §15.0 "The Necropolis Dynasty goes live (integration)").
	"description": "A sun-baked temple of colonnades and statue-lined courts, sacred to the goddess of war and plague: here the stone itself walks.",
	"unlock": {"stage": "necropolis", "boss_kills": 1},  # Brief: each stage opens the next
	"unlock_text": "Defeat Anubis at the Necropolis of Sand to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Dynasty stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ZONES[0]["arena"],
	"ground": "lioness_temple",  # LionessTempleGround: the four zone floors.
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"dynasty": true,  # Rebirth, the Black Land, Heka (DynastyRules).
	"rebirth": {},  # This stage's Rebirth overrides ({} = DynastyRulesData.REBIRTH).
	"jars": {},  # This stage's jar clock ({} = DynastyRulesData.JARS: the shared clock's jars).
	"quicksand": {"chance": 0.1},  # TUNING (not in GDD) a paved temple: sand drifts only here and there
	"sandstorm": {},  # This stage's Sandstorm ({} = DynastyRulesData.SANDSTORM).
	"heka": {},  # This stage's Heka ({} = DynastyRulesData.HEKA).
	"zones": ZONES,  # The four zones.
	"lioness_temple": LIONESS_TEMPLE,  # LionessTempleDirector: the Awakening Statues, the Lion Warden's seal.
	"music": "weighing",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
