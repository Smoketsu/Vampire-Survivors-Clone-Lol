## WildEnemyData — immutable design data for the kinds THE TURNING YEAR fields
## on every one of its stages (temporary Act XV, final slot XV, the campaign
## finale; GDD §15.0 "The Turning Year foundation (phase 1)"; design
## docs/proposals/LAST_SIX_ACTS.md section XV, "Roster"). The world itself
## rises to take its dead back: moss, bark, blossom pink, gold leaves and frost
## white; the beasts are few and fae-touched (the Titans own the herds), and
## winter is the fae's Winter Court (the Norse act owns the giants and wolves).
## The shared kinds (phase 1; their specials built in phase 2 by the Greenwood,
## GDD §15.0 "The Turning Year's shared kinds: their specials (the Greenwood)"):
##   thornling    — growth: twig creatures in swarms of 12; fodder.
##   dryad        — growth (female, figure style): plants thicket SEEDS
##                  (OVERGROWTH, DryadKit) and heals the Wild ("healer").
##   treant       — growth: the slow heavy; the Reckoning's heavy (Spring
##                  Returns); its strike roots the summon it hits (TreantKit).
##   corpse_bloom — growth: a structure that eats corpses near it and buds
##                  Thornlings (CorpseBloomKit).
##   fae_knight   — fae (male): leaf armour and a thorn sword; short blinks
##                  through the ring (FaeKnightKit).
##   winter_fae   — fae (female, figure style): frost bolts from range that
##                  chill summons; WINTER ONLY (row "season").
##   great_stag   — hunt (male): an elite with a telegraphed antler charge
##                  that scatters the ring (GreatStagKit, WildChargeKit).
##   wild_rider   — hunt (male): a spectral horseman with two hounds and a
##                  long sweep; after leave_after sweeps it rides on
##                  (WildRiderKit, WildChargeKit).
##   will_o_wisp  — spirits: a lure that draws summons away from the ring
##                  through SummonedUnit.misdirect() (WillOWispKit).
##   spore_mother — spirits (female, figure style): spores that rot summons,
##                  mould that kills blight (SporeMotherKit).
##   hunt_hound   — hunt (phase 2): the Rider's hounds (HuntHoundKit).
## The charge keys (charge_*) of the hunters: WildChargeKit's header.
## Each stage's own kinds live in its own file (GreenwoodEnemyData,
## FaeCourtEnemyData, WorldTreeEnemyData: the stage minibosses and the
## bosses' allies); EnemyDirector.enemy_def() looks them up
## through wild_def(), this file first, after the Age of Titans' tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Turning Year keys (absent = off):
##   faction    — "wild" (the Codex's Wild tab, the reports; every Wild kind
##                heals on living ground, BloomField).
##   kit        — a CovenantKit id; a Turning Year kit lives in
##                scripts/enemies/wild/<kit>_kit.gd (CovenantKits loads it by
##                name after the Titans' folder, so kit ids must be unique
##                across every kit folder). Every kind has one (a WildKit).
##   group      — String, one of WildRulesData.GROUPS.
##   season     — String, one of WildRulesData.SEASON_IDS: the kind comes in
##                the trickle and the waves only in that season
##                (SeasonCycle.timeline_weights() / filter_groups()).
##   no_bloom   — true: never heals on living ground (bosses set it until
##                phase 2 decides).
##   plant_*    — a planter's seeds (DryadKit -> Thickets.plant()).
##   fodder     — true: fodder (reports).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot XV (the hardest
## act), not its temporary number.
class_name WildEnemyData
extends RefCounted

## Faction id of the Turning Year's kinds (row "faction").
const FACTION: String = WildRulesData.FACTION
## Kind id of the Thornling (the swarm).
const THORNLING: String = "thornling"
## Kind id of the Dryad (the planter).
const DRYAD: String = "dryad"
## Kind id of the Treant (the heavy; the Reckoning's).
const TREANT: String = "treant"
## Kind id of the Fae Knight.
const FAE_KNIGHT: String = "fae_knight"
## Kind id of the Will-o'-Wisp.
const WISP: String = "will_o_wisp"
## Kind id of the Great Stag.
const GREAT_STAG: String = "great_stag"
## Kind id of the Rider of the Wild Hunt.
const WILD_RIDER: String = "wild_rider"
## Kind id of the Spore Mother.
const SPORE_MOTHER: String = "spore_mother"
## Kind id of the Winter Fae (winter only).
const WINTER_FAE: String = "winter_fae"
## Kind id of the Corpse-Bloom (a structure).
const CORPSE_BLOOM: String = "corpse_bloom"
## Kind id of a Hound of the Wild Hunt (a Rider brings two; phase 2, the Greenwood).
const HUNT_HOUND: String = "hunt_hound"
## Sprite folder of the Turning Year's kinds (assets/sprites/wild/).
const SPRITE_DIR: String = "wild/"

## Spring Returns' heavy (the RECKONING "kind" of every Wild stage; "everything grows back").
const RECKONING_KIND: String = TREANT
## Spring Returns' companions (the RECKONING "companions": all of them).
const RECKONING_COMPANIONS: Array = [
	{"kind": THORNLING, "count": 12, "growth": 2.0},  # TUNING (not in GDD) a swarm of 12, as the roster says
	{"kind": DRYAD, "count": 2, "growth": 1.0},  # TUNING (not in GDD) more seeds
	{"kind": FAE_KNIGHT, "count": 3, "growth": 1.0},  # TUNING (not in GDD)
]

## The Turning Year's shared kinds, keyed by kind id.
const ENEMIES := {
	# Growth: the swarm (owner-approved proposal: "Thornling | Fodder swarm |
	# Twig creatures in swarms of 12 | Anything").
	"thornling": {
		"display_name": "Thornling",
		"max_hp": 11.0,  # TUNING (not in GDD) fodder (a Scuttler 10; slot XV is the hardest)
		"move_speed": 80.0,  # TUNING (not in GDD) px/s
		"damage": 2.5,  # TUNING (not in GDD) a scratch, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 6.0,  # TUNING (not in GDD) px (~22 px sprite)
		"armor": 0.0,
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "thornling",
		"group": "growth",
		"fodder": true,
	},  # The Thornling.
	# Growth: the planter (owner-approved proposal: "Dryad (female, figure
	# style) | Support | Plants thicket seeds; heals the Wild on living ground |
	# Priority target"). OVERGROWTH's seeds; the heal is the plain healer's.
	"dryad": {
		"display_name": "Dryad",
		"max_hp": 40.0,  # TUNING (not in GDD) a support
		"move_speed": 48.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) a weak lash
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~52 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "healer",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 8.0,  # TUNING (not in GDD) HP a heal
		"heal_interval": 3.0,  # TUNING (not in GDD) s
		"heal_radius": 150.0,  # TUNING (not in GDD) px
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; "priority target"
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "dryad",
		"group": "growth",
		"plant_first": 5.0,  # TUNING (not in GDD) s after it comes on
		"plant_every": 14.0,  # TUNING (not in GDD) s between two seeds
		"plant_reach": 260.0,  # TUNING (not in GDD) px from the nearest necromancer at which it plants
		"plant_ahead": 120.0,  # TUNING (not in GDD) px toward him from itself the seed lands
	},  # The Dryad.
	# Growth: the heavy (owner-approved proposal: "Treant | Heavy | Slow; roots
	# the summon it strikes | Fire, Wither, Siegecraft"). The root on its strike
	# is TreantKit's (the Greenwood).
	"treant": {
		"display_name": "Treant",
		"max_hp": 340.0,  # TUNING (not in GDD) a heavy (first pass 420: the spell-only builds could not clear them and 17-33 piled up by 8:00-10:00, their top killer; balance pass 1)
		"move_speed": 34.0,  # TUNING (not in GDD) px/s; slow
		"damage": 8.5,  # TUNING (not in GDD) a branch, before the time scaling (the stub's 14, first passes 12 and 11: with its root it hit the bots hardest, seeds 7 and 11; balance pass 1: up to 345 on the thin-ring bots, the top killer)
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (~80 px sprite)
		"armor": 0.3,  # TUNING (not in GDD) bark
		"xp": 16,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 5.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "treant",
		"group": "growth",
		# --- Act XV (temporary number): the Greenwood --- the root on its strike (TreantKit).
		"root_hold": 1.2,  # Owner-approved proposal: "roots the summon it strikes"; TUNING (not in GDD) s x Deadwood
	},  # The Treant.
	# Growth: the structure (owner-approved proposal: "Corpse-Bloom | Structure
	# | Eats corpses on the field and spawns thornlings | Break it"). The eating
	# is CorpseBloomKit's (the Greenwood); not in the stubs' timelines (--spawn= fields it).
	"corpse_bloom": {
		"display_name": "Corpse-Bloom",
		"max_hp": 380.0,  # TUNING (not in GDD) a structure (x the time and stage scaling)
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD) px (~48 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",  # It never moves.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; break it
		"mass": 60.0,  # Immovable.
		"is_structure": true,  # No corpse, no knockback.
		"faction": FACTION,
		"kit": "corpse_bloom",
		"group": "growth",
		# --- Act XV (temporary number): the Greenwood --- the meals and the buds (CorpseBloomKit).
		"eat_every": 2.0,  # TUNING (not in GDD) s between two meals
		"eat_radius": 160.0,  # Owner-approved proposal: "eats corpses on the field"; TUNING (not in GDD) px
		"eat_max": 3,  # TUNING (not in GDD) corpses of Corpse Explosion's store a meal at most
		"bud_meals": 3,  # TUNING (not in GDD) meals a bud costs
		"bud_count": 4,  # Owner-approved proposal: "spawns thornlings"; TUNING (not in GDD) Thornlings a bud
		"bud_kind": THORNLING,  # Owner-approved proposal
	},  # The Corpse-Bloom.
	# The fae: the soldier (owner-approved proposal: "Fae Knight (male) |
	# Soldier | Leaf armour and a thorn sword; short blinks through the ring |
	# Blockers inside the ring"). The blinks: FaeKnightKit (the Greenwood).
	"fae_knight": {
		"display_name": "Fae Knight",
		"max_hp": 70.0,  # TUNING (not in GDD) a soldier
		"move_speed": 64.0,  # TUNING (not in GDD) px/s
		"damage": 6.5,  # TUNING (not in GDD) a thorn sword, before the time scaling (first pass 8: it blinks inside the ring, the highest damage per second of the shared kinds; balance pass 1)
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~52 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) leaf armour
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.65,  # TUNING (not in GDD) 0..1
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "fae_knight",
		"group": "fae",
		# --- Act XV (temporary number): the Greenwood --- the blinks through the ring (FaeKnightKit).
		"blink_first": 3.0,  # TUNING (not in GDD) s after it comes on
		"blink_every": 12.0,  # TUNING (not in GDD) s between two blinks (first passes 7, 9: 461 and 700 blinks a run, seed 7)
		"blink_min": 170.0,  # TUNING (not in GDD) px: nearer than this it walks (first pass 120)
		"blink_lane": 30.0,  # TUNING (not in GDD) px half width of the line a summon must stand in for it to blink
		"blink_dist": 110.0,  # Owner-approved proposal: "short blinks through the ring"; TUNING (not in GDD) px
		"blink_keep": 90.0,  # TUNING (not in GDD) px it lands at least from the necromancer's edge: in the ring (60-150 px), not on him (first passes 40, 70)
		"blink_warn": 0.35,  # TUNING (not in GDD) s it gathers itself (leaves swirl)
	},  # The Fae Knight.
	# The fae: the Winter Court (owner-approved proposal: "Winter Fae (female,
	# figure style) | Ranged | Frost bolts that chill summons; winter only |
	# Fire; Mages"). The chill: WinterFaeKit (the Greenwood).
	"winter_fae": {
		"display_name": "Winter Fae",
		"max_hp": 34.0,  # TUNING (not in GDD) ranged
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 4.5,  # TUNING (not in GDD) a frost bolt, before the time scaling
		"attack_interval": 2.8,  # TUNING (not in GDD) s
		"attack_range": 260.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px (~52 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 280.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.65,  # TUNING (not in GDD) 0..1
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "winter_fae",
		"group": "fae",
		"season": "winter",  # Owner-approved proposal: "winter only"
		# --- Act XV (temporary number): the Greenwood --- the frost bolt's chill (WinterFaeKit).
		"chill_slow": 0.35,  # Owner-approved proposal: "frost bolts that chill summons"; TUNING (not in GDD) 0..1
		"chill_time": 2.0,  # TUNING (not in GDD) s
	},  # The Winter Fae.
	# The Wild Hunt: the elite beast (owner-approved proposal: "Great Stag
	# (male) | Elite | A telegraphed antler charge that scatters the ring |
	# Grave Step; Bone Wall"). The charge: GreatStagKit (the Greenwood).
	"great_stag": {
		"display_name": "Great Stag",
		"max_hp": 300.0,  # TUNING (not in GDD) an elite
		"move_speed": 70.0,  # TUNING (not in GDD) px/s
		"damage": 10.0,  # TUNING (not in GDD) antlers, before the time scaling (the stub's 12: with its charge it hit the naive bot hard)
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 16.0,  # TUNING (not in GDD) px (~72 px sprite)
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 14,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "great_stag",
		"group": "hunt",
		# --- Act XV (temporary number): the Greenwood --- the antler charge (GreatStagKit, WildChargeKit).
		"charge_first": 3.0,  # TUNING (not in GDD) s after it comes on
		"charge_every": 11.0,  # TUNING (not in GDD) s between two charges (first pass 8)
		"charge_trigger": 240.0,  # TUNING (not in GDD) px to the necromancer for a charge to start
		"charge_windup": 1.0,  # Owner-approved proposal: "a telegraphed antler charge"; TUNING (not in GDD) s
		"charge_speed": 320.0,  # TUNING (not in GDD) px/s
		"charge_len": 260.0,  # TUNING (not in GDD) px at most (through the ring)
		"charge_damage": 8.0,  # TUNING (not in GDD) to each summon it crosses, before the time scaling
		"charge_player": 4.0,  # TUNING (not in GDD) to the necromancer, before the time scaling (first passes 8, 6: the naive bot's killer, seed 11)
		"charge_stun": 0.6,  # TUNING (not in GDD) s each summon it crosses is stunned
		"charge_knock": 34.0,  # Owner-approved proposal: "scatters the ring"; TUNING (not in GDD) px a summon is thrown aside
	},  # The Great Stag.
	# The Wild Hunt: the rider (owner-approved proposal: "Rider of the Wild Hunt
	# (male) | Elite | A spectral horseman and two hounds; sweeps across the
	# arena in a line | Step out of the line; Archers"). The hounds and the
	# sweep: WildRiderKit (the Greenwood).
	"wild_rider": {
		"display_name": "Rider of the Wild Hunt",
		"max_hp": 200.0,  # TUNING (not in GDD) an elite (the stub's 240: with its sweep and hounds it outlived the naive bot's army)
		"move_speed": 82.0,  # TUNING (not in GDD) px/s
		"damage": 8.0,  # TUNING (not in GDD) a spear, before the time scaling (the stub's 11: its sweep is its threat now)
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 15.0,  # TUNING (not in GDD) px (~72 px sprite)
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 12,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "wild_rider",
		"group": "hunt",
		# --- Act XV (temporary number): the Greenwood --- the sweep and the hounds (WildRiderKit, WildChargeKit).
		"charge_first": 4.0,  # TUNING (not in GDD) s after it comes on
		"charge_every": 16.0,  # TUNING (not in GDD) s between two sweeps (first passes 11, 14)
		"charge_trigger": 360.0,  # TUNING (not in GDD) px to the necromancer for a sweep to start
		"charge_windup": 1.2,  # TUNING (not in GDD) s the line shows
		"charge_speed": 380.0,  # TUNING (not in GDD) px/s
		"charge_len": 520.0,  # Owner-approved proposal: "sweeps across the arena in a line"; TUNING (not in GDD) px
		"charge_damage": 7.0,  # TUNING (not in GDD) to each summon it crosses, before the time scaling
		"charge_player": 3.0,  # TUNING (not in GDD) to the necromancer, before the time scaling (first passes 8, 4: the riders were the bots' killer, seed 3 and 11)
		"charge_stun": 0.4,  # TUNING (not in GDD) s
		"charge_knock": 24.0,  # TUNING (not in GDD) px
		"hounds": 2,  # Owner-approved proposal: "a spectral horseman and two hounds"
		"hound_kind": "hunt_hound",  # Its hounds' row (below)
		"hound_side": 34.0,  # TUNING (not in GDD) px a hound sweeps to either side of it
		"leave_after": 3,  # Owner-approved proposal: "sweeps across the arena"; TUNING (not in GDD) sweeps of its own before it rides on with its hounds (the Hunt passes; first pass: they stayed and overran the naive bot)
	},  # The Rider of the Wild Hunt.
	# The spirits: the lure (owner-approved proposal: "Will-o'-Wisp | Lure |
	# Draws summons away from the ring (the existing misdirect() hook) | Kill
	# it; area damage"). The lure: WillOWispKit (the Greenwood).
	"will_o_wisp": {
		"display_name": "Will-o'-Wisp",
		"max_hp": 18.0,  # TUNING (not in GDD) fragile
		"move_speed": 72.0,  # TUNING (not in GDD) px/s
		"damage": 2.0,  # TUNING (not in GDD) a cold touch
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 7.0,  # TUNING (not in GDD) px (~28 px sprite)
		"armor": 0.0,
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1; "kill it"
		"mass": 0.3,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "will_o_wisp",
		"group": "spirits",
		# --- Act XV (temporary number): the Greenwood --- the lure (WillOWispKit).
		"lure_first": 1.5,  # TUNING (not in GDD) s after it comes on
		"lure_every": 5.0,  # TUNING (not in GDD) s between two lures (first pass 3: 450 summons lured in the army bot's run, seed 11)
		"lure_radius": 110.0,  # TUNING (not in GDD) px
		"lure_cap": 2,  # TUNING (not in GDD) summons a lure takes at most (first pass 3)
		"lure_time": 1.6,  # Owner-approved proposal: "draws summons away from the ring"; TUNING (not in GDD) s
		"lure_speed": 0.8,  # TUNING (not in GDD) x the summon's speed
	},  # The Will-o'-Wisp.
	# The spirits: the rot (owner-approved proposal: "Spore Mother (female,
	# figure style) | Support | Spores that rot summons and spread
	# blight-killing mould | Kill early"). The spores: SporeMotherKit (the Greenwood).
	"spore_mother": {
		"display_name": "Spore Mother",
		"max_hp": 60.0,  # TUNING (not in GDD) a support
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) a spore puff, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 11.0,  # TUNING (not in GDD) px (~52 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; "kill early"
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "spore_mother",
		"group": "spirits",
		# --- Act XV (temporary number): the Greenwood --- the spores and the mould (SporeMotherKit).
		"spore_first": 2.5,  # TUNING (not in GDD) s after she comes on
		"spore_every": 6.0,  # TUNING (not in GDD) s between two puffs (first pass 5)
		"spore_radius": 70.0,  # TUNING (not in GDD) px
		"spore_damage": 3.0,  # TUNING (not in GDD) to each summon, before the time scaling
		"spore_curse": 0.85,  # Owner-approved proposal: "spores that rot summons"; TUNING (not in GDD) x the summon's damage and speed (first pass 0.8)
		"spore_time": 4.0,  # TUNING (not in GDD) s the rot lasts
		"mould_radius": 90.0,  # Owner-approved proposal: "spread blight-killing mould"; TUNING (not in GDD) px
		"mould_cut": 0.5,  # TUNING (not in GDD) blight a puff takes off each cell in reach
	},  # The Spore Mother.
	# --- Act XV (temporary number): the Greenwood (phase 2's shared kinds) ---
	# The Wild Hunt: the Rider's hounds (owner-approved proposal: "Rider of the
	# Wild Hunt (male) | Elite | A spectral horseman and two hounds"). Fast,
	# light biters that sweep beside their Rider (HuntHoundKit: charge_every 0,
	# they never charge on their own).
	"hunt_hound": {
		"display_name": "Hound of the Wild Hunt",
		"max_hp": 48.0,  # TUNING (not in GDD) a light beast
		"move_speed": 96.0,  # TUNING (not in GDD) px/s; fast
		"damage": 4.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 0.8,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px (~28 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "hunt_hound",
		"group": "hunt",
		"charge_every": 0.0,  # Never on its own: it sweeps only when its Rider leads it
		"charge_speed": 380.0,  # TUNING (not in GDD) px/s, as its Rider
		"charge_len": 520.0,  # TUNING (not in GDD) px, as its Rider
		"charge_damage": 4.0,  # TUNING (not in GDD) to each summon it crosses, before the time scaling
		"charge_player": 3.0,  # TUNING (not in GDD) to the necromancer, before the time scaling (first pass 5)
		"charge_stun": 0.0,  # A bite in passing: no stun
		"charge_knock": 10.0,  # TUNING (not in GDD) px
	},  # The Hound of the Wild Hunt.
}
