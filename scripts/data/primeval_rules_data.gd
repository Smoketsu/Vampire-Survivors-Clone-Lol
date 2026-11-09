## PrimevalRulesData — the numbers of THE AGE OF TITANS' shared rules
## (temporary Act XIV, final slot XIV; GDD §15.0 "The Age of Titans
## foundation (phase 1)", "Packs", "Herds", "Scavengers" and "The Stampede of
## Ash"; design docs/proposals/LAST_SIX_ACTS.md section XIV and
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 2, plan docs/last_acts/PLAN.md).
## Read by PrimevalRules (Game.primeval) and its parts:
##   PACKS       — predators hunt in packs with an alpha: they circle the ring,
##                 hold, then rush together faster from the flanks; kill the
##                 alpha and the pack charges straight in (PackBrain).
##   HERDS       — neutral giants that graze, stampede when hurt or near a
##                 fight (a 600 px front on a telegraphed line, both armies
##                 trampled, rocks shelter), and rise as Fossil Giants (Herds).
##   SCAVENGERS  — Skyraiders that dive on crystal piles and carry them to the
##                 nests; kill one in the air and its pile drops (Scavengers).
##   ASH         — the Reckoning of the first two stages, the Stampede of Ash
##                 (StampedeOfAsh).
## A stage's STAGE "packs" / "herds" / "scavengers" dictionaries override any
## key here; its RECKONING "stampede_of_ash" overrides ASH. Data only, no
## logic. Every value is TUNING (not in GDD) unless it is marked as the
## owner-approved proposal. Tuned for the act's FINAL slot XIV (above the
## Concord of Stars, Act IX), not its temporary number.
class_name PrimevalRulesData
extends RefCounted

## Faction id of the Age of Titans' kinds (row "faction").
const FACTION: String = "primeval"
## The roster's groups in order (row "group"; the Codex and the report group
## by them): the swarms (fodder), the hunters (the pack predators and the
## spitters), the herds (the neutral giants), the fliers (the Skyraiders), the
## titans (the Tyrants). Phase 2 adds its stage kinds to these groups.
const GROUPS: Array[String] = ["swarm", "hunters", "herds", "fliers", "titans"]

# --- Packs (PackBrain; one steering path) --------------------------------------------------
## The packs (a stage's STAGE "packs" overrides any key). A pack forms from the
## pack kinds (row "pack") that come onto the field together; the first is
## its alpha.
const PACKS := {
	"form_window": 1.0,  # TUNING (not in GDD) s: a pack kind activated this soon after a pack opened joins it (a timeline group spawns in one tick)
	"max_size": 8,  # TUNING (not in GDD) most members of one pack (a bigger group opens a second pack with its own alpha)
	"engage": 360.0,  # TUNING (not in GDD) px from the nearest standing necromancer at which the alpha starts the circle
	"circle_radius": 230.0,  # TUNING (not in GDD) px from the necromancer the pack circles (outside the Bone Ring, 60-150 px)
	"circle_time": 2.5,  # Owner-approved proposal: "circles the ring for a moment"; TUNING (not in GDD) s
	"orbit": 0.7,  # TUNING (not in GDD) rad/s the circle turns
	"spread": 0.42,  # TUNING (not in GDD) rad between two members' posts on the circle (the flanks)
	"hold": 1.5,  # Owner-approved proposal: "holds 1.5 s"
	"rush_mult": 1.4,  # Owner-approved proposal: "rushes together with +40% speed"
	"rush_time": 2.5,  # TUNING (not in GDD) s the rush lasts at most (a member a blocker holds fights at once)
	"post_reach": 6.0,  # TUNING (not in GDD) px: a member this close to its post stands on it
}

# --- Herds (Herds; one path for the neutral giants) -----------------------------------------
## The herds (a stage's STAGE "herds" overrides any key).
const HERDS := {
	"first": 40.0,  # TUNING (not in GDD) s of game time of the first herd
	"every": 45.0,  # TUNING (not in GDD) s between two herds (only while fewer than `cap` beasts graze)
	"cap": 6,  # Owner-approved proposal: "herds 6" alive at most
	"size": 3,  # TUNING (not in GDD) beasts in one herd
	"kinds": ["longneck", "duckbill", "duckbill"],  # TUNING (not in GDD) the herd's kinds, one per beast (cycled)
	"spawn_dist": 560.0,  # TUNING (not in GDD) px from a standing necromancer a herd comes on
	"spawn_spread": 70.0,  # TUNING (not in GDD) px between two beasts of a new herd
	"form_window": 1.0,  # TUNING (not in GDD) s: a herd kind activated this soon after a herd opened joins it
	"graze_radius": 460.0,  # TUNING (not in GDD) px: a grazing beast farther than this from the nearest necromancer drifts back toward him
	"graze_mult": 0.35,  # TUNING (not in GDD) x its move speed while grazing
	"drift_every": 4.0,  # TUNING (not in GDD) s between two changes of a grazing beast's drift
	"lead": 2.0,  # Owner-approved proposal: "dust line 2 s ahead"
	"width": 600.0,  # Owner-approved proposal: "a living front 600 px wide"
	"depth": 56.0,  # TUNING (not in GDD) px, the front's depth (a body this close to its line is trampled)
	"run_speed": 210.0,  # TUNING (not in GDD) px/s the front runs
	"run_length": 1500.0,  # TUNING (not in GDD) px the front runs before the herd settles
	"front_back": 40.0,  # TUNING (not in GDD) px behind the herd's centre the front starts
	"cooldown": 45.0,  # TUNING (not in GDD) s a herd grazes after a run before it can stampede again (first pass 20: 77 stampedes, 99k trample damage on summons in the seed-7 army run)
	"shelter_len": 110.0,  # TUNING (not in GDD) px: an obstacle this close upstream of a body (toward the oncoming front) shelters it
	"trample_summon": 12.0,  # TUNING (not in GDD) per summon, before the time scaling
	"trample_player": 8.0,  # TUNING (not in GDD) before the time scaling (Grave Step's i-frames dodge it)
	"trample_enemy_share": 0.6,  # TUNING (not in GDD) share of an enemy's max HP (bosses, minibosses and structures are never trampled)
	"knock": 70.0,  # TUNING (not in GDD) px a trampled summon is thrown along the run
	"giant": {
		"class": "abomination",  # TUNING (not in GDD) the Fossil Giant's body (a temporary summon of an existing class, HordeDirector.raise_corpse())
		"hp_mult": 4.0,  # Owner-approved proposal: "HP x4"
		"dmg_mult": 1.0,  # TUNING (not in GDD)
		"life": 30.0,  # Owner-approved proposal: "lasts 30 s"
		"cap": 2,  # Owner-approved proposal: "at most 2 alive"
		"reach": 520.0,  # TUNING (not in GDD) px from a standing necromancer a heavy corpse rises for him
		"tag": "fossil_giant",  # Damage-source tag of a Fossil Giant (CombatResolver stats)
		"sprite": "summons/fossil_giant",  # The Fossil Giant's art key (drawn when the art pass adds it; the class's look until then)
	},
}
## Damage source tag of a stampede's trample (summons, the necromancer, enemies).
const TRAMPLE_SOURCE: String = "primeval_trample"

# --- Scavengers (Scavengers; one path over the crystal pool) --------------------------------
## The Skyraiders' thefts (a stage's STAGE "scavengers" overrides any key).
const SCAVENGERS := {
	"first": 30.0,  # TUNING (not in GDD) s of game time of the first dive
	"every": 8.0,  # Owner-approved proposal: "every 8 s a Skyraider dives"
	"safe_radius": 200.0,  # Owner-approved proposal: "anything within 200 px of the necromancer is safe"
	"max_crystals": 10,  # Owner-approved proposal: "the nearest pile worth up to 10 crystals"
	"pile_radius": 70.0,  # TUNING (not in GDD) px around the first crystal that make one pile
	"search": 900.0,  # TUNING (not in GDD) px from the Skyraider it looks for a pile
	"warn": 1.2,  # Owner-approved proposal: "a shadow circle first"; TUNING (not in GDD) s it shows before the snatch
	"shadow_radius": 34.0,  # TUNING (not in GDD) px, drawing only: the shadow circle
	"dive_speed": 240.0,  # TUNING (not in GDD) px/s
	"flee_speed": 170.0,  # TUNING (not in GDD) px/s to its nest
	"nest_dist": 760.0,  # TUNING (not in GDD) px from every standing necromancer at which it reaches its nest (under the 950 px recycle distance)
	"hover_radius": 300.0,  # TUNING (not in GDD) px: an idle Skyraider circles this far from the nearest necromancer (it never bites)
	"hover_orbit": 0.5,  # TUNING (not in GDD) rad/s
}

# --- The Stampede of Ash (the Reckoning of the first two stages) ----------------------------
## The Stampede of Ash (a stage's RECKONING "stampede_of_ash" overrides any key):
## from 0:00 the sky burns: herds come stampeding from every side, volcanic
## bombs fall on telegraphed circles, packs double (the RECKONING companions)
## and Tyrants roam (the RECKONING kind).
const ASH := {
	"first": 4.0,  # TUNING (not in GDD) s after 0:00
	"stampede_every": 14.0,  # Owner-approved proposal: "every herd stampedes at once from every side"; TUNING (not in GDD) s between two
	"stampede_size": 4,  # TUNING (not in GDD) beasts a stampede of ash brings (over the herd cap: the Reckoning lifts it)
	"stampede_kinds": ["longneck", "duckbill"],  # TUNING (not in GDD) cycled
	"stampede_ring": 620.0,  # TUNING (not in GDD) px from the necromancer a stampede of ash comes on
	"bomb_every": 2.5,  # Owner-approved proposal: "volcanic bombs fall on telegraphed circles"; TUNING (not in GDD) s
	"bombs": 2,  # TUNING (not in GDD) bombs per standing necromancer each time
	"bomb_spread": 280.0,  # TUNING (not in GDD) px around the necromancer a bomb lands
	"bomb_warn": 1.4,  # TUNING (not in GDD) s the circle shows before it lands
	"bomb_radius": 70.0,  # TUNING (not in GDD) px
	"bomb_player": 14.0,  # TUNING (not in GDD) before the time scaling (Grave Step's i-frames dodge it)
	"bomb_summon": 30.0,  # TUNING (not in GDD) per summon, before the time scaling
	"bomb_enemy_share": 0.3,  # TUNING (not in GDD) share of an enemy's max HP (bosses and structures spared)
	"bomb_show": 0.3,  # TUNING (not in GDD) drawing only: s the burst stays drawn
}
## Damage source tag of a volcanic bomb.
const BOMB_SOURCE: String = "primeval_bomb"

## Sound of each Age of Titans event: each is an id of the lazy "titans" pack (SoundData.TITANS_SOUNDS, rendered with the score
## "primordial"; the comment names what it sounds like).
const SOUNDS := {
	"pack_circle": "pack_rustle",  # Titans pack id "pack_rustle" (ferns rustling on both flanks, a low chatter).
	"pack_hold": "pack_hiss",  # Titans pack id "pack_hiss" (a held, rising hiss: the pack is about to rush).
	"pack_rush": "pack_rush",  # Titans pack id "pack_rush" (claws on earth, a shriek).
	"alpha_slain": "alpha_slain",  # Titans pack id "alpha_slain" (a broken screech, the pack's yelps).
	"stampede_warn": "stampede_warn",  # Titans pack id "stampede_warn" (a deep rolling rumble, a bellow).
	"stampede_run": "stampede_run",  # Titans pack id "stampede_run" (heavy footfalls in rhythm).
	"trample": "trample",  # Titans pack id "trample" (a heavy thud and bones cracking).
	"fossil_rise": "fossil_rise",  # Titans pack id "fossil_rise" (stone cracking, a hollow bone groan).
	"skyraider_dive": "skyraider_dive",  # Titans pack id "skyraider_dive" (a falling whistle and a screech).
	"snatch": "snatch",  # Titans pack id "snatch" (a beak clack and crystals chiming away).
	"pile_drop": "pile_drop",  # Titans pack id "pile_drop" (crystals scattering on stone).
	"bomb_warn": "bomb_warn",  # Titans pack id "bomb_warn" (a falling roar of fire).
	"bomb_land": "bomb_land",  # Titans pack id "bomb_land" (a molten crack and a splash of embers).
	"ash_stampede": "ash_horn",  # Titans pack id "ash_horn" (the sky burns: a long low roar of herds).
}

# --- The counter-passives (phase 2 builds them; PrimevalRules' hooks read them) -------------
## Passive id of Hoarder's Bones (proposal: "crystals and drops within 300 px cannot be snatched; a snatched pile drops sooner"; this act only).
const HOARDERS_BONES: String = "hoarders_bones"
## Hoarder's Bones' value key: px the safe radius grows to (0 = not owned; the proposal's 300).
const HOARDERS_BONES_KEY: String = "safe_radius"
## Passive id of Thick Marrow (proposal: "summons take less damage from trampling, charges and stomps"; this act only).
const THICK_MARROW: String = "thick_marrow"
## Thick Marrow's value key: the share of a trample / charge / stomp on a summon it takes off (0..1).
const THICK_MARROW_KEY: String = "trample_cut"
