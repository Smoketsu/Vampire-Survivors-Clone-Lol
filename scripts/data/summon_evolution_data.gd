## SummonEvolutionData — immutable design data for the summon evolutions (user
## request; GDD §4.2 / §6.1 name one evolution per summon class). Runtime
## logic lives in SummonEvolutions (owned by HordeDirector).
##
## Recipes (user rules, recorded in GDD §15.0):
##   Skeleton Warrior Lv 5 + Dark Command Lv 5        = Death Knight
##       (GDD "Dreadguard Legion"; the user named it Death Knight)
##   Undead Mage Lv 5      + Forbidden Knowledge Lv 5 = Lich
##       (GDD "Lich Conclave")
##   Grave Mender Lv 5 + Crypt Warder Lv 5 + Dark Benediction Lv 5
##                                                     = Profane Bishop
##       (GDD §4.2 priest evolution; the split priest classes MERGE into one)
##   Frost Wraith Lv 5     + Soul Recycling Lv 5      = Winter Revenant
##       (owner-approved; wider Deep Freeze, shatter, death nova)
##   Grave Rogue Lv 5      + Bound Souls Lv 5         = Shadow Reaper
##   Crypt Gargoyle Lv 5   + Unholy Resilience Lv 5   = Cathedral Horror
##       (owner-approved; they UPGRADE the class special, RogueBehavior /
##       GargoyleBehavior, through the special_mult / special_set overlays)
##   Skeletal Archer Lv 5  + Unholy Precision Lv 5    = Gravebow
##       (GDD §4.2 / §6.1 "Gravebow Company"; the owner chose the singular)
##   Corpse Abomination Lv 5 + Bone Plating Lv 5      = Bone Colossus
## Owner rule: every evolution, spell or summon, needs its paired passive at
## Lv 5 (EvolutionData.PASSIVE_LEVEL_REQUIRED); `passive_level` below is 5
## for every recipe.
##
## Delivery is the same as the spell evolutions (EvolutionData): once a recipe
## holds and the run has reached EvolutionData.MIN_ELAPSED (8:00), the next
## treasure chest grants it first (AbilityManager.ready_evolutions() /
## chest_rewards() include these ids). Evolutions never appear on level-up
## cards.
##
## Two modes:
##   "transform" — the base class keeps its id, slot, level and capacity; its
##                 stats get the evolution overlay below and every existing
##                 unit transforms in place (full heal + transformation FX).
##                 Its card / HUD / slot identity becomes the evolution's.
##   "merge"     — every base class is removed (level 0, never offered again,
##                 its active slot is freed) and the `result` class takes
##                 over at RESULT_LEVEL. Existing units convert in place up to
##                 the result's capacity; the rest dissolve into it.
## All numbers are TUNING (not in GDD) unless tagged otherwise.
class_name SummonEvolutionData
extends RefCounted

## Display / check order of the summon evolutions.
const ORDER := ["death_knight", "lich", "profane_bishop",
	"winter_revenant", "shadow_reaper", "cathedral_horror", "gravebow", "bone_colossus"]

## Summon skill level every base class needs (user rule: Lv 5).
const BASE_LEVEL_REQUIRED: int = 5  # TUNING (not in GDD) user rule
## Skill level the merged result class is created at (its LEVELS table has
## a single row; this keeps it "maxed" for synergies, cards and the HUD).
const RESULT_LEVEL: int = 5  # TUNING (not in GDD)
## Seconds each unit shows its transformation glow.
const TRANSFORM_FX_TIME: float = 1.2  # TUNING (not in GDD)

## Evolution definitions.
##   mode          — "transform" | "merge" (see header).
##   bases         — base class ids (UnitData.CLASS_ORDER) that must all be at
##                   BASE_LEVEL_REQUIRED.
##   passive       — paired passive id (PassiveData.PASSIVES key).
##   passive_level — passive level required (5 = max, 1 = owned).
##   result        — "merge" only: the class id that replaces the bases.
##   display_name  — UI name (singular), plural — UI name (plural).
##   icon          — IconGlyph kind of the evolved class (SummonGlyphs).
##   description   — card / banner text.
##   mult          — "transform" only: effective-stat key -> multiplier
##                   (its own stacking category, GDD §6.4).
##   set           — "transform" only: effective-stat key -> absolute value.
##   special_mult  — "transform" only: class-special key (UnitData "special",
##                   already scaled by HordeDirector._special_stats()) ->
##                   multiplier.
##   special_set   — "transform" only: class-special key -> absolute value
##                   (applied after every scaling: these numbers are final).
## Death Knight keys (SummonAbilities.after_melee):
##   cleave_radius   — px around the struck enemy; other enemies inside take
##                     cleave_fraction of the hit (source "death_knight_cleave").
##   lifesteal       — fraction of all melee damage dealt healed back.
##   engaged_speed_mult — enemies touching a Death Knight move this slowly
##                     (the "dread" of its presence; a slow, not a fear, so
##                     enemies still always advance, GDD §15.0).
## Lich keys:
##   raise — the raise-the-dead effect (SummonEvolutions.on_enemy_killed):
##     chance     — expected raises per Lich kill (deterministic accumulator,
##                  no RNG: every 1/chance kills one foe rises),
##     class      — summon class of the risen skeleton (base stats, no evolution),
##     duration   — s a risen skeleton lasts before it crumbles,
##     hp_mult / damage_mult — multipliers on that class's current stats,
##     max_alive  — at most this many risen skeletons at once.
## Shadow Reaper special keys (RogueBehavior; 0 / absent on the base Rogue):
##   chain_dashes    — extra dashes after the first: when a dash ends, the
##                     nearest enemy not struck by this chain, dash_min..
##                     dash_length px away, with a clear lane whose end stays
##                     inside the soft leash, is dashed at at once.
##   chain_telegraph — s the lane of a chained dash is shown (the first dash
##                     keeps dash_telegraph).
##   bleed_stacks    — bleeds one Reaper keeps on one enemy at once; each
##                     dash hit adds a stack (each ticks on its own) and at
##                     the cap refreshes the stack with the fewest ticks left.
##   dash_kill_reset — 1 = a kill by a dash hit resets the dash cooldown, at
##                     most once per dash chain (applied when the chain ends).
##   dash_reset_floor — s the cooldown is set to by that reset (never 0, so
##                     kills cannot loop dashes).
## Cathedral Horror special keys (GargoyleBehavior; 0 / absent on the base):
##   stun_duration   — s every enemy hit by the dive is stunned
##                     (CombatResolver.stun_enemy(): the Deep Freeze hold).
##   stun_boss_mult / stun_elite_mult — share of the stun for the boss /
##                     elites; Reckoning enemies and structures are immune.
##   stone_duration  — s it stands as stone after landing: it does not move
##                     or attack, takes no damage and still body-blocks.
## Gravebow curse: damage sources it does NOT amplify. A cursed enemy takes
## more damage from every undead source (all summons AND the necromancer's
## spells: every hit on a Covenant soldier is undead); only the Soul Nova
## power-up is left out, because it deals an exact share of max HP (it also
## ignores the enemy-side modifiers, Enemy.damage_taken_mult()).
const CURSE_EXEMPT_SOURCES := ["nova"]  # TUNING (not in GDD)

## Evolution definitions.
##   mode          — "transform" | "merge" (see header).
##   bases         — base class ids (UnitData.CLASS_ORDER) that must all be at
##                   BASE_LEVEL_REQUIRED.
##   passive       — paired passive id (PassiveData.PASSIVES key).
##   passive_level — passive level required (5 = max, 1 = owned).
##   result        — "merge" only: the class id that replaces the bases.
##   display_name  — UI name (singular), plural — UI name (plural).
##   icon          — IconGlyph kind of the evolved class (SummonGlyphs).
##   description   — card / banner text.
##   mult          — "transform" only: effective-stat key -> multiplier
##                   (its own stacking category, GDD §6.4).
##   set           — "transform" only: effective-stat key -> absolute value.
## Death Knight keys (SummonAbilities.after_melee):
##   cleave_radius   — px around the struck enemy; other enemies inside take
##                     cleave_fraction of the hit (source "death_knight_cleave").
##   lifesteal       — fraction of all melee damage dealt healed back.
##   engaged_speed_mult — enemies touching a Death Knight move this slowly
##                     (the "dread" of its presence; a slow, not a fear, so
##                     enemies still always advance, GDD §15.0).
## Lich keys:
##   raise — the raise-the-dead effect (SummonEvolutions.on_enemy_killed):
##     chance     — expected raises per Lich kill (deterministic accumulator,
##                  no RNG: every 1/chance kills one foe rises),
##     class      — summon class of the risen skeleton (base stats, no evolution),
##     duration   — s a risen skeleton lasts before it crumbles,
##     hp_mult / damage_mult — multipliers on that class's current stats,
##     max_alive  — at most this many risen skeletons at once.
## Special overlays ("transform" only; SummonEvolutions.modify_stats() applies
## them to the class's effective "special" numbers, after HordeDirector's
## suffix scaling, so an evolution UPGRADES the class special):
##   special_mult  — special key -> multiplier on the scaled value.
##   special_set   — special key -> value added as is (not suffix-scaled).
## Gravebow keys (special_set; GravebowKit, CombatResolver.curse_enemy):
##   split_every    — every Nth volley of a Gravebow splits (1..).
##   split_count    — arrows in a split volley (the aimed one included).
##   split_fan      — radians; total spread of the split fan.
##   curse_amp      — 0..1; extra damage a cursed enemy takes from every
##                    undead source (CURSE_EXEMPT_SOURCES aside).
##   curse_duration — s an arrow's curse lasts (refreshed by every hit).
## Bone Colossus keys (special_set; ColossusKit):
##   taunt_radius          — px; enemies (not bosses, Reckoning enemies or
##                           structures) whose centre is this close pick the
##                           Colossus as their target first.
##   shrapnel_radius       — px; reach of the bone burst when it dies.
##   shrapnel_damage_mult  — burst damage per enemy as a multiple of its
##                           (fully scaled) stomp_damage.
##   shrapnel_knockback    — px/s impulse of the burst, divided by enemy mass.
##   shrapnel_shake        — screen-shake request (px, Juice) of the burst.
const EVOLUTIONS := {
	"death_knight": {
		"mode": "transform",
		"bases": ["warrior"],
		"passive": "dark_command",
		"passive_level": 5,  # TUNING (not in GDD) user rule: Dark Command at max level
		"display_name": "Death Knight",
		"plural": "Death Knights",
		"icon": "death_knight",
		"description": "Your warriors rise as armoured Death Knights: cleaving blows, life drain and a dread wall foes cannot pass.",
		"mult": {
			"max_hp": 1.5,  # TUNING (not in GDD)
			"damage": 1.35,  # TUNING (not in GDD)
			"bash_damage": 2.0,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 12.0,  # TUNING (not in GDD) bigger silhouette
			"block_radius": 15.0,  # TUNING (not in GDD) <= UnitData.MAX_BLOCK_RADIUS
			"block_mass": 5.0,  # TUNING (not in GDD) warriors are 3
			"engaged_speed_mult": 0.45,  # TUNING (not in GDD) warriors are 0.6
			"bash_cooldown": 1.5,  # TUNING (not in GDD) warriors are 2.0
			"bash_knockback": 220.0,  # TUNING (not in GDD) warriors are 160
			"cleave_radius": 32.0,  # TUNING (not in GDD)
			"cleave_fraction": 0.5,  # TUNING (not in GDD)
			"lifesteal": 0.12,  # TUNING (not in GDD)
		},
	},
	"lich": {
		"mode": "transform",
		"bases": ["mage"],
		"passive": "forbidden_knowledge",
		"passive_level": 5,  # TUNING (not in GDD) user rule: Forbidden Knowledge maxed
		"display_name": "Lich",
		"plural": "Liches",
		"icon": "lich",
		"description": "Your mages ascend as Liches: deadlier blasts, sturdier bodies, and the foes they slay rise as skeletons.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			# Combined balance pass: 1.35 (on top of Forbidden Knowledge's +40% damage and +25%
			# splash) left Liches at 29% of all damage in the summon build, up to 45% in one
			# run (plus 12% from the mages before they evolved).
			"damage": 1.2,  # TUNING (not in GDD) was 1.35; 1.5 made Liches 36% of all damage in the summon build
			# Combined balance pass: 1.25 -> 1.0. With Grave Dominion a summon build fields up
			# to 8 Liches, and splash width decides who lands the kills (Forbidden Knowledge
			# still adds up to +25%).
			"splash_radius": 1.0,  # TUNING (not in GDD) was 1.25
			# Combined balance pass: 0.85 (casts 15% faster) -> 1.0. Strong summon builds kill
			# everything that spawns, so the damage cut alone barely moved the Lich's share
			# (its splash lands most kills first: 37% of all damage, up to 43%); fewer casts
			# land fewer of them.
			"attack_interval": 1.0,  # TUNING (not in GDD) was 0.85
		},
		"set": {
			"radius": 11.0,  # TUNING (not in GDD)
		},
		"raise": {
			"chance": 0.2,  # TUNING (not in GDD)
			"class": "warrior",  # TUNING (not in GDD)
			"duration": 12.0,  # TUNING (not in GDD)
			"hp_mult": 0.6,  # TUNING (not in GDD)
			"damage_mult": 0.8,  # TUNING (not in GDD)
			"max_alive": 6,  # TUNING (not in GDD)
		},
	},
	"profane_bishop": {
		"mode": "merge",
		"bases": ["mender", "warder"],
		"passive": "dark_benediction",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: Dark Benediction at max level (was 1, owned)
		"result": "bishop",
		"display_name": "Profane Bishop",  # GDD §4.2
		"plural": "Bishops",
		"icon": "profane_bishop",
		"description": "Menders and Warders merge into Profane Bishops: stronger heals, wards and barriers, a healing aura that burns foes, and one free active slot.",
	},
	# Winter Revenant (owner-approved): Frost Wraith Lv 5 + Soul Recycling Lv 5.
	# Upgrades the Frost Wraith kit (FrostWraithBehavior); the shatter and the
	# death nova run in WinterRevenant (owned by SummonEvolutions).
	# Extra keys:
	#   special_mult — "transform" only: UnitData "special" key -> multiplier,
	#                  applied after HordeDirector._special_stats() scaling.
	#   shatter      — an enemy killed while Deep-Frozen (Enemy.freeze_timer > 0;
	#                  not the Stasis power-up, not a boss or a structure)
	#                  splashes frost on the enemies around it:
	#     radius          — px around the shattered enemy (body edges count half),
	#     damage_fraction — fraction of the SHATTERED enemy's max HP dealt to each
	#                       (source "winter_revenant_shatter"; scales with the
	#                       enemy HP growth of the run),
	#     chill_slow / chill_duration — chill applied to each survivor (fraction
	#                       of speed removed / s),
	#     max_per_frame   — at most this many shatters resolve per physics tick
	#                       (the rest are skipped and counted; a perf cap).
	#                       Shatters never chain: see WinterRevenant.
	#   nova         — when a Winter Revenant dies (not dissolved, not a temporary):
	#     radius          — px around the fallen Revenant,
	#     damage_mult     — damage to each enemy as a multiple of the Revenant's
	#                       frost-bolt damage (source "winter_revenant_nova"),
	#     freeze_duration — s of Deep Freeze applied to each survivor through
	#                       CombatResolver.freeze_enemy() (the class's boss / elite
	#                       multipliers apply, Reckoning enemies are immune).
	"winter_revenant": {
		"mode": "transform",
		"bases": ["frost_wraith"],
		"passive": "soul_recycling",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: Soul Recycling at max level
		"display_name": "Winter Revenant",  # TUNING (not in GDD) owner-approved name
		"plural": "Winter Revenants",
		"icon": "winter_revenant",
		"description": "Your Frost Wraiths rise as Winter Revenants: a wider Deep Freeze, frozen foes shatter into frost, and each Revenant that falls bursts in a freezing nova.",
		"mult": {
			"max_hp": 1.25,  # TUNING (not in GDD)
			"damage": 1.25,  # TUNING (not in GDD) frost bolt
		},
		"set": {
			"radius": 12.0,  # TUNING (not in GDD) bigger silhouette (Frost Wraiths are 10)
		},
		"special_mult": {
			"freeze_radius": 1.35,  # TUNING (not in GDD) owner brief: Deep Freeze radius +35%
		},
		"shatter": {
			"radius": 56.0,  # TUNING (not in GDD) px
			# First test (seed 1, --classes=frost_wraith --passives=soul_recycling --policy=summon):
			# 0.3 made shatters 16% of ALL damage on the Crimson March (the class 29%, like the
			# Lich before the combined balance pass nerfed it), 6% in the Graveyard.
			"damage_fraction": 0.22,  # TUNING (not in GDD) of the shattered enemy's max HP; was 0.3
			"chill_slow": 0.4,  # TUNING (not in GDD) Frost Wraith bolts chill 0.35
			"chill_duration": 2.0,  # TUNING (not in GDD) s
			"max_per_frame": 12,  # TUNING (not in GDD) perf cap per physics tick
		},
		"nova": {
			"radius": 84.0,  # TUNING (not in GDD) px
			# First test: 4.0 gave 50k (8% of all damage) on the Crimson March, where the
			# Revenants die far more often (92 deaths vs 23 in the Graveyard).
			"damage_mult": 3.0,  # TUNING (not in GDD) x the Revenant's frost-bolt damage; was 4.0
			"freeze_duration": 1.2,  # TUNING (not in GDD) s (Deep Freeze is 1.6)
		},
	},
	"shadow_reaper": {
		"mode": "transform",
		"bases": ["rogue"],
		"passive": "bound_souls",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: Bound Souls at max level
		"display_name": "Shadow Reaper",  # TUNING (not in GDD) owner-approved name
		"plural": "Shadow Reapers",
		"icon": "shadow_reaper",
		"description": "Your rogues become Shadow Reapers: dashes twice as often, each one chains to a second foe, bleeds stack, and a kill mid-dash readies the next.",
		"mult": {
			"max_hp": 1.35,  # TUNING (not in GDD)
			"damage": 1.25,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 10.0,  # TUNING (not in GDD) rogues are 9
		},
		"special_mult": {
			"dash_cooldown": 0.5,  # TUNING (not in GDD) owner brief: cooldown halved
		},
		"special_set": {
			"chain_dashes": 1,  # TUNING (not in GDD) owner brief: chains to a second target
			"chain_telegraph": 0.1,  # TUNING (not in GDD) s; a short flash of the lane keeps the chain readable
			"bleed_stacks": 3,  # TUNING (not in GDD) owner brief: bleeds stack up to 3 times
			"dash_kill_reset": 1,  # TUNING (not in GDD) owner brief: a kill during a dash resets the cooldown
			"dash_reset_floor": 0.9,  # TUNING (not in GDD) s; at most one reset per chain, never below this (0.6 let 35% of chains come back almost at once: Reapers dealt 38% of all damage in a forced summon run)
		},
	},
	"cathedral_horror": {
		"mode": "transform",
		"bases": ["gargoyle"],
		"passive": "unholy_resilience",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: Unholy Resilience at max level
		"display_name": "Cathedral Horror",  # TUNING (not in GDD) owner-approved name
		"plural": "Cathedral Horrors",
		"icon": "cathedral_horror",
		"description": "Your gargoyles tear free as Cathedral Horrors: wider dives that stun what they hit, and after each landing they turn to stone, untouchable.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			"damage": 1.25,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 13.0,  # TUNING (not in GDD) gargoyles are 11
		},
		"special_mult": {
			"swoop_radius": 1.3,  # TUNING (not in GDD) owner brief: swoop radius +30%
		},
		"special_set": {
			"stun_duration": 0.6,  # TUNING (not in GDD) owner brief: dive stuns for 0.6 s
			"stun_boss_mult": 0.25,  # TUNING (not in GDD) the stage boss: 25% of the stun (like the Deep Freeze's reduced boss share)
			"stun_elite_mult": 0.6,  # TUNING (not in GDD) elites: 60% (the Deep Freeze's elite share)
			"stone_duration": 2.0,  # TUNING (not in GDD) owner brief: stone for 2 s after landing
		},
	},
	# Gravebow (GDD §4.2 / §6.1 "Gravebow Company": splitting / piercing arrows
	# and curses). Archers still hold their ground (owner decision): only the
	# arrows change (GravebowKit).
	"gravebow": {
		"mode": "transform",
		"bases": ["archer"],
		"passive": "unholy_precision",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Gravebow",  # GDD §6.1 (owner: singular "Gravebow")
		"plural": "Gravebows",
		"icon": "gravebow",
		"description": "Your archers rise as Gravebows: piercing arrows, a splitting volley every 4th shot, and a curse that makes foes take more damage from all your undead.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			"damage": 1.25,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 10.0,  # TUNING (not in GDD) archers are 9
			"pierce": 2,  # TUNING (not in GDD) each arrow passes through 2 enemies (Lv 5 archers: 1)
		},
		"special_set": {
			"split_every": 4,  # TUNING (not in GDD) every 4th volley splits
			"split_count": 3,  # TUNING (not in GDD) arrows in a split volley
			"split_fan": 0.5,  # TUNING (not in GDD) radians, total fan spread (~29 degrees)
			"curse_amp": 0.15,  # TUNING (not in GDD) +15% damage taken from the undead
			"curse_duration": 4.0,  # TUNING (not in GDD) s
		},
	},
	# Bone Colossus: a towering, bone-armoured Abomination. A bigger stomp,
	# a wider and heavier blocker, a taunt and a death burst (ColossusKit).
	# Body and blocking ring grow together: an enemy held at the ring is
	# block_radius - radius px from the body's edge and must reach that far
	# to strike, so the gap stays the Abomination's 4 px (a wider ring alone
	# would put it out of reach of every melee soldier). The 19 px body is
	# the largest summon body: UnitData.MAX_BLOCK_RADIUS (the padding of
	# every enemy / boss query for summon bodies) was raised to match, and
	# HordeDirector.block_query_radius follows the widest block_radius (also
	# raised on the transformation itself).
	"bone_colossus": {
		"mode": "transform",
		"bases": ["abomination"],
		"passive": "bone_plating",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Bone Colossus",  # TUNING (not in GDD) owner-approved name
		"plural": "Bone Colossi",
		"icon": "bone_colossus",
		"description": "Your abominations rise as Bone Colossi: far tougher, wider bodies, bigger stomps, foes nearby are drawn to them, and they burst into bone shrapnel when they fall.",
		"mult": {
			"max_hp": 1.6,  # TUNING (not in GDD) +60% HP
		},
		"set": {
			"radius": 19.0,  # TUNING (not in GDD) abominations are 16 (= UnitData.MAX_BLOCK_RADIUS)
			"block_radius": 23.0,  # TUNING (not in GDD) abominations are 20; same 4 px reach gap
			"block_mass": 11.0,  # TUNING (not in GDD) abominations are 8; the boss (12) still shoves it
		},
		"special_mult": {
			"stomp_radius": 1.4,  # TUNING (not in GDD) +40% stomp radius
		},
		"special_set": {
			"taunt_radius": 110.0,  # TUNING (not in GDD) px
			"shrapnel_radius": 90.0,  # TUNING (not in GDD) px
			"shrapnel_damage_mult": 2.0,  # TUNING (not in GDD) x its stomp damage
			"shrapnel_knockback": 220.0,  # TUNING (not in GDD) px/s
			"shrapnel_shake": 4.0,  # TUNING (not in GDD) px
		},
	},
}
