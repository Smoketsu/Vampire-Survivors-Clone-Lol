## TwoTruthsStage — STAGE 36 (temporary number; final stage 21), THE HALL OF TWO
## TRUTHS, the finale of the Necropolis Dynasty (temporary Act XII, final slot
## VII; GDD §15.0 "The Necropolis Dynasty foundation (phase 1)" and "The Hall of
## Two Truths (Necropolis Dynasty phase 2)"; owner-approved proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 3 "Stage C: The Hall of Two Truths
## (the finale)"). The judgment hall of the dead: the gate of reeds, the river
## of fire, the great scales. Every number and event that belongs to this
## stage. StageRegistry exposes it to the run as `Game.stage_def` (the STAGE
## dictionary at the bottom; its keys are documented in StageRegistry).
##
## The stage runs the Dynasty's three shared rules ("dynasty": true: Rebirth,
## the Black Land, Heka), four clock-driven zones (ZONES, run by MarchDirector:
## a zone banner, the zone's floor and obstacles) and its own mechanics in
## TwoTruthsDirector (STAGE key "two_truths", TWO_TRUTHS):
##   THE SCALES (from 0:00): the Balance bar on the HUD; each Rebirth tips it
##       toward the Dynasty, each raise toward the necromancer (TruthScales);
##   I   THE GATE OF REEDS (0:00): reed mud; the wrapped dead come first;
##   II  THE RIVER OF FIRE (5:00): basalt and braziers; the Crocodile Wardens
##       climb out of the sand;
##   III THE HALL OF THE SCALES (10:00): blue-black marble, the great Scales
##       among the colonnades; THE DEVOURER'S WHELP (the miniboss) at 12:30;
##   IV  THE THRONE OF OSIRIS (15:00): the whole Dynasty before the throne.
## Osiris and Ammit (OsirisData, boss_osiris.gd: the Judge, the Weighing, the
## Devourer) arrive with 3:00 left; the Reckoning, the Devourer's Hour, at 0:00.
## Still hidden from the stage select ("playable": false) until the lead's
## integration. Tuned for the act's FINAL slot VII (docs/last_acts/PLAN.md:
## the Shogunate / Olympus level), not its temporary number. Every rate, cap
## and weight is TUNING (not in GDD).
## The other stages' Dynasty kinds (the Nile Archer, the Jackal Warrior, the
## Bastet Hunter, the Ushabti Statue) are built on their own branches; the
## lead adds them to this timeline at the merge (GDD §15.0 row).
class_name TwoTruthsStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "two_truths"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (slot VII's finale: the Road to the Sun 1.65, the Underworld 1.5; Rebirth
## gives an uncountered body up to 1 + 0.7 + 0.7 of its HP again).
const ENEMY_HP_MULT: float = 1.55  # TUNING (not in GDD) phase 2 (the foundation's 1.5)
## Enemy damage multiplier of this stage on top of the shared time scaling
## (a returned body hits x1.2 per return on top; the Scales add or take 15%).
const ENEMY_DAMAGE_MULT: float = 1.45  # TUNING (not in GDD) phase 2 (the foundation's 1.4)
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) as Acts III to IX (7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026 (GDD §15.0 "Ossuary expansion: owner decisions"): every act restarts, stage 3 of the act

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is a TwoTruthsGround look: style "reeds", "fire", "scales" or
## "throne" (tiles/two_truths_<style>), base / line colours of the code floor
## and the accent of its decorations. Obstacles from their obstacles/<kind>
## PNGs (the art pass's dyn_* kinds; the single-sprite ones through
## TwoTruthsGlyphs).
const ZONES := [
	{"id": "gate_of_reeds", "start": 0.0, "numeral": "I", "name": "The Gate of Reeds",  # Owner-approved proposal zone I
		"blurb": "Reed mud and broken stone at the edge of the judgment hall, where the dead wait their turn",
		"ground": {"style": "reeds", "base": Color(0.14, 0.16, 0.12), "line": Color(0.10, 0.12, 0.09), "accent": Palette.DYN_PAPYRUS},
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 3621,  # TUNING (not in GDD)
			"kinds": {
				"dyn_obelisk": {"weight": 0.35, "shape": "circle", "sizes": [8.0, 10.0]},  # TUNING (not in GDD) obelisks (two sprites, s / l)
				"dyn_sphinx_head": {"weight": 0.3, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD) a half-buried sphinx head
				"dyn_sandstone_blocks": {"weight": 0.35, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD) broken blocks
			}},
	},
	{"id": "river_of_fire", "start": 300.0, "numeral": "II", "name": "The River of Fire",  # Owner-approved proposal zone II
		"blurb": "Basalt split by the river of fire, braziers lighting the way of the dead",
		"ground": {"style": "fire", "base": Color(0.12, 0.08, 0.08), "line": Color(0.07, 0.05, 0.05), "accent": Palette.DYN_CARNELIAN_LIGHT},
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 3622,  # TUNING (not in GDD)
			"kinds": {
				"dyn_brazier": {"weight": 0.45, "shape": "circle", "sizes": [9.0]},  # TUNING (not in GDD) stone braziers
				"dyn_sandstone_blocks": {"weight": 0.3, "shape": "circle", "sizes": [15.0]},  # TUNING (not in GDD)
				"dyn_obelisk": {"weight": 0.25, "shape": "circle", "sizes": [8.0, 10.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "hall_of_scales", "start": 600.0, "numeral": "III", "name": "The Hall of the Scales",  # Owner-approved proposal zone III
		"blurb": "Blue-black marble under the colonnades, and the great Scales where every heart is weighed",
		"ground": {"style": "scales", "base": Color(0.08, 0.09, 0.15), "line": Color(0.05, 0.06, 0.10), "accent": Palette.DYN_LAPIS_LIGHT},
		"arena": {"density": 0.16, "clear_radius": 230.0, "layout_seed": 3623,  # TUNING (not in GDD)
			"kinds": {
				"dyn_colonnade": {"weight": 0.45, "shape": "rect", "sizes": [44.0, 72.0], "short": 14.0},  # TUNING (not in GDD) colonnades (s / l, both orientations)
				"dyn_brazier": {"weight": 0.35, "shape": "circle", "sizes": [9.0]},  # TUNING (not in GDD)
				"dyn_great_scales": {"weight": 0.2, "shape": "circle", "sizes": [24.0]},  # TUNING (not in GDD) the great Scales (the set piece)
			}},
	},
	{"id": "throne", "start": 900.0, "numeral": "IV", "name": "The Throne of Osiris",  # Owner-approved proposal zone IV
		"blurb": "Night-blue slabs inlaid with bronze before the throne of the Lord of the Dead",
		"ground": {"style": "throne", "base": Color(0.10, 0.11, 0.20), "line": Color(0.06, 0.07, 0.13), "accent": Palette.DYN_BRONZE},
		"arena": {"density": 0.14, "clear_radius": 240.0, "layout_seed": 3624,  # TUNING (not in GDD) open for the finale
			"kinds": {
				"dyn_colonnade": {"weight": 0.4, "shape": "rect", "sizes": [44.0, 72.0], "short": 14.0},  # TUNING (not in GDD)
				"dyn_obelisk": {"weight": 0.3, "shape": "circle", "sizes": [8.0, 10.0]},  # TUNING (not in GDD)
				"dyn_brazier": {"weight": 0.3, "shape": "circle", "sizes": [9.0]},  # TUNING (not in GDD)
			}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "DEEPER INTO THE HALL  -  ZONE %s",
	"zone_color": Palette.DYN_BRONZE_LIGHT,  # The dull bronze-gold (true gold stays the player's).
	"fog_color": Color(0.04, 0.04, 0.09),  # The desert night.
	"fog_bank_color": Color(0.22, 0.20, 0.16),  # Incense haze.
	"zones": ZONES,
}

## TwoTruthsDirector's config (STAGE key "two_truths"; the director's and
## TruthScales' headers document the rules):
##   scales — the Balance: limit (each side), threshold (favour), the tips
##            (return_tip toward the Dynasty; raise_tip, steal_tip, smash_tip
##            toward the necromancer), settle (per s toward level outside the
##            Weighing), dynasty_mult / maat_mult (x a Dynasty enemy's hits),
##            rebirth_bonus (s on every cartouche in the Dynasty's favour),
##            the two banners;
##   crocs  — the "crocodile_rise" event: ring_min / ring_max (px from the
##            necromancer).
const TWO_TRUTHS := {
	"scales": {
		"limit": 100.0,  # TUNING (not in GDD) each side
		"threshold": 40.0,  # TUNING (not in GDD) past it the favour turns
		"return_tip": 5.0,  # TUNING (not in GDD) toward the Dynasty per body that returned (proposal: "Each Rebirth tips the scale toward the Dynasty")
		"raise_tip": 4.0,  # TUNING (not in GDD) toward the necromancer per raise (proposal: "each raise tips it toward the necromancer")
		"steal_tip": 4.0,  # TUNING (not in GDD) more per raise that stole a Name ("Raising the dead is the way to win the scale")
		"smash_tip": 0.25,  # TUNING (not in GDD) own decision: a smashed Name is a lighter weight than a stolen one
		"settle": 1.0,  # TUNING (not in GDD) per s back toward level (not during the Weighing)
		"dynasty_mult": 1.15,  # Owner-approved proposal: "toward the Dynasty, they gain +15%"
		"maat_mult": 0.85,  # Owner-approved proposal: "toward the necromancer, Dynasty enemies deal -15% damage (Ma'at's favour)"
		"rebirth_bonus": -2.0,  # Owner-approved proposal: "Rebirth timers are 2 s shorter"
		"dynasty_banner": "The Scales tip to the Dynasty: its dead strike harder and return sooner!",  # TUNING (not in GDD)
		"maat_banner": "The Scales tip your way: Ma'at's favour weakens the Dynasty's blows!",  # TUNING (not in GDD)
	},
	"crocs": {
		"ring_min": 180.0,  # TUNING (not in GDD) px
		"ring_max": 300.0,  # TUNING (not in GDD) px
	},
}

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the
## DEVOURER'S HOUR, shared by every Dynasty stage: every sarcophagus opens
## ("kind": the khopesh guard, with the shared kinds as companions), Rebirth
## has no limit, the Sandstorm becomes permanent and the Devourer sweeps its
## lanes ("devourers_hour": DynastyRulesData.DEVOURER keys; {} = those
## defaults). In the hall the Crocodile Wardens come with them.
const RECKONING_COMPANIONS: Array = [
	{"kind": DynastyEnemyData.MUMMY, "count": 8, "growth": 2.0},  # As DynastyEnemyData.RECKONING_COMPANIONS
	{"kind": DynastyEnemyData.MUMMY_FEMALE, "count": 6, "growth": 1.5},  # As DynastyEnemyData.RECKONING_COMPANIONS
	{"kind": DynastyEnemyData.SCARAB_SWARM, "count": 3, "growth": 1.0},  # As DynastyEnemyData.RECKONING_COMPANIONS
	{"kind": DynastyEnemyData.HEKA_PRIEST, "count": 1, "growth": 0.34},  # As DynastyEnemyData.RECKONING_COMPANIONS
	{"kind": DynastyEnemyData.CROCODILE_WARDEN, "count": 1, "growth": 0.34},  # TUNING (not in GDD) the river's wardens
]
## The Reckoning (see above).
const RECKONING := {
	"banner": "THE DEVOURER'S HOUR: EVERY SARCOPHAGUS OPENS",
	"kind": DynastyEnemyData.RECKONING_KIND,  # The shared Devourer's Hour heavy (the khopesh guard).
	"devourers_hour": {},  # DynastyRulesData.DEVOURER defaults.
	"companions": RECKONING_COMPANIONS,  # The shared companions and a Crocodile Warden.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) guards
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE DEVOURER'S HOUR: the dead rise without end, and the Devourer eats its lanes. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the wrapped
## dead first, then the guard and the priesthood, the Crocodile Wardens from
## the River of Fire. The priests and the wardens stay rare.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.6, "max_alive": 34,  # TUNING (not in GDD)
		"weights": {"mummy": 0.6, "mummy_female": 0.4},
		"objective": "The Gate of Reeds: a fallen mummy's Name waits over it. Raise it to tip the Scales your way"},
	{"start": 60.0, "rate": 1.95, "max_alive": 46,  # TUNING (not in GDD)
		"weights": {"mummy": 0.45, "mummy_female": 0.3, "scarab_swarm": 0.25},
		"objective": "Every body that stands again tips the Scales to the Dynasty. Smash the Names or raise them"},
	{"start": 180.0, "rate": 2.3, "max_alive": 58,  # TUNING (not in GDD)
		"weights": {"mummy": 0.4, "mummy_female": 0.27, "scarab_swarm": 0.17, "khopesh_guard": 0.11, "heka_priest": 0.05},
		"objective": "Heka priests curse your dead. A Mender's heal or a Warder's barrier clears the glyph"},
	{"start": 300.0, "rate": 2.6, "max_alive": 68,  # TUNING (not in GDD)
		"weights": {"mummy": 0.34, "mummy_female": 0.24, "scarab_swarm": 0.16, "khopesh_guard": 0.13, "heka_priest": 0.05, "embalmer": 0.05, "crocodile_warden": 0.03},
		"objective": "The River of Fire: Crocodile Wardens climb out of the sand and drag your dead under. Keep out of the quicksand"},
	{"start": 600.0, "rate": 3.0, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"mummy": 0.32, "mummy_female": 0.23, "scarab_swarm": 0.15, "khopesh_guard": 0.15, "heka_priest": 0.06, "embalmer": 0.05, "crocodile_warden": 0.04},
		"objective": "The Hall of the Scales: when the sand blows, every bow and spell reaches half as far"},
	{"start": 900.0, "rate": 3.4, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"mummy": 0.3, "mummy_female": 0.22, "scarab_swarm": 0.15, "khopesh_guard": 0.17, "heka_priest": 0.06, "embalmer": 0.05, "crocodile_warden": 0.05},
		"objective": "The Throne of Osiris: the Dynasty comes for its dead, and for yours"},
	{"start": BOSS_TIME, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"mummy": 0.36, "mummy_female": 0.25, "scarab_swarm": 0.16, "khopesh_guard": 0.12, "heka_priest": 0.04, "embalmer": 0.04, "crocodile_warden": 0.03},
		"objective": "Osiris sits in judgment over you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). The
## "crocodile_rise" and "devourers_whelp" events are TwoTruthsDirector's.
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The wrapped dead rise from the reeds!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 8, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A swarm of scarabs pours through the gate!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 170.0, "type": "wave", "banner": "A Heka priest raises his hands: a glyph for your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 1, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 250.0, "type": "wave", "banner": "An Embalmer walks with the dead: their Names return faster!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "embalmer", "count": 1, "elite": false}, {"kind": "mummy", "count": 8, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}]},
	{"time": 330.0, "type": "crocodile_rise", "count": 2,  # TUNING (not in GDD) the river's wardens
		"banner": "Crocodile Wardens climb out of the sand! Keep your dead out of their jaws"},
	{"time": 420.0, "type": "wave", "banner": "The guard of the river advances!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 5, "elite": false}, {"kind": "heka_priest", "count": 1, "elite": false}]},
	{"time": 500.0, "type": "wave", "banner": "Two swarms at once!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "scarab_swarm", "count": 5, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 570.0, "type": "crocodile_rise", "count": 3,  # TUNING (not in GDD)
		"banner": "The river boils: more wardens rise from the sand!"},
	{"time": 660.0, "type": "wave", "banner": "The priesthood comes to wrap its dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "embalmer", "count": 2, "elite": false}, {"kind": "mummy", "count": 10, "elite": false}]},
	{"time": 750.0, "type": "devourers_whelp", "kind": TwoTruthsEnemyData.WHELP,  # TUNING (not in GDD) the miniboss, in the Hall of the Scales
		"banner": "The DEVOURER'S WHELP smells the dead! It eats their Names: raise them before it does",
		"escort": [{"kind": "khopesh_guard", "count": 3, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "A procession of the dead!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 12, "elite": false}, {"kind": "mummy_female", "count": 10, "elite": false}, {"kind": "khopesh_guard", "count": 3, "elite": false}]},
	{"time": 930.0, "type": "crocodile_rise", "count": 3,  # TUNING (not in GDD)
		"banner": "The wardens of the throne rise from the sand!"},
	{"time": 970.0, "type": "wave", "banner": "The whole Dynasty comes before the throne!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "khopesh_guard", "count": 4, "elite": false}, {"kind": "heka_priest", "count": 2, "elite": false}, {"kind": "embalmer", "count": 1, "elite": false}, {"kind": "scarab_swarm", "count": 5, "elite": false}]},
	{"time": 1000.0, "type": "wave", "banner": "The dead gather before their master!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "mummy", "count": 12, "elite": false}, {"kind": "mummy_female", "count": 10, "elite": false}, {"kind": "embalmer", "count": 1, "elite": false}]},
]

## Obstacle layout of the first zone (keys as GraveyardStage.ARENA; every zone
## has its own in ZONES).
const ARENA: Dictionary = ZONES[0]["arena"]

## Osiris and Ammit's arrival (keys as GraveyardStage.BOSS): OsirisData.ARRIVAL
## (boss id "osiris"), whose `time` equals BOSS_TIME (17:00). Its script is
## scripts/enemies/dynasty/boss_osiris.gd (found by the boss id).
const BOSS: Dictionary = OsirisData.ARRIVAL

## Floor look of the placeholder "dynasty" ground (DynastyGround; the stage now
## uses TwoTruthsGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "hall",  # dark basalt flagstones with bronze and lapis inlay.
	"base": Color(0.13, 0.14, 0.22),  # TUNING (not in GDD)
	"line": Color(0.19, 0.20, 0.30),  # TUNING (not in GDD)
	"accent": Palette.DYN_BRONZE_DARK,  # TUNING (not in GDD)
	"trim": Palette.DYN_LAPIS,  # TUNING (not in GDD)
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Hall of Two Truths",
	"short_name": "Two Truths",
	"chapter": "Chapter XXXVI",  # Temporary (the reorder pass renumbers; final stage 21).
	"act": 12,  # Temporary Act XII, the Necropolis Dynasty (final slot VII; docs/last_acts/PLAN.md).
	"playable": false,  # Phase 2 built; the lead switches it on at the integration.
	"description": "The judgment hall of the dead: past the gate of reeds and the river of fire the great scales wait, and Osiris on his throne.",
	"unlock": {"stage": "lioness_temple", "boss_kills": 1},  # Brief: each stage opens the next
	"unlock_text": "Defeat Sekhmet at the Temple of the Lioness to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Dynasty stages.
	"consecration": {},  # A Covenant event: none here.
	"crypt_defender": {},  # None here.
	"arena": ARENA,
	"ground": "two_truths",  # TwoTruthsGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"two_truths": TWO_TRUTHS,  # TwoTruthsDirector (the Scales, the Whelp, the wardens' rise).
	"dynasty": true,  # Rebirth, the Black Land, Heka (DynastyRules).
	"rebirth": {},  # This stage's Rebirth overrides ({} = DynastyRulesData.REBIRTH).
	"jars": {"every": 150.0},  # TUNING (not in GDD) the stub jars, rarer in the hall (its own counter is the Scales)
	"quicksand": {"chance": 0.18},  # TUNING (not in GDD) fewer fixed patches (the wardens open their own)
	"sandstorm": {},  # This stage's Sandstorm ({} = DynastyRulesData.SANDSTORM).
	"heka": {},  # This stage's Heka ({} = DynastyRulesData.HEKA).
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march").
	"music": "weighing",  # Wave 1 integration: the act's own score (SoundData.SCORES; its pack renders with it)
}
