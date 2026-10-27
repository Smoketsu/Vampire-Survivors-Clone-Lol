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
##   Bone Hounds Lv 5      + Blood Scent Lv 5         = Hellhounds
##   Banshee Lv 5          + Mournsong Lv 5           = Keening Lady
##   Corpse Catapult Lv 5  + Siegecraft Lv 5          = Ossuary Engine
##       (owner-approved; they upgrade the class kit through special_set,
##       read by BoneHoundBehavior / BansheeBehavior / CatapultBehavior and
##       HordeHazards)
##   Fallen Seraph Lv 5    + Fallen Grace Lv 5        = Seraph of Ruin
##       (Act II, GDD §15.0 "Fallen Seraph"; chained dives and a second,
##       wider feather ring through special_set, read by SeraphBehavior)
##   Bone Golem Lv 5       + Grave Masonry Lv 5       = Ossuary Titan
##       (content wave 2, GDD §15.0 "Bone Golem (content wave 2)"; heals and
##       shields from absorbed bones, falls into a bone wall: GolemKit)
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
	"winter_revenant", "shadow_reaper", "cathedral_horror", "gravebow", "bone_colossus",
	"hellhound", "keening_lady", "ossuary_engine",
	# --- Act II: Fallen Seraph ---
	"ruin_seraph",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"leviathan",
	# --- Content wave 2: Bone Golem ---
	"ossuary_titan",
	# --- Act III: the Assembly Halls ---
	"wraith_drone",
	# --- Act III: the Iron Citadel ---
	"deus_revenant",
	# --- Act IV: the Asphodel Underworld ---
	"legion_of_tartarus",
	# --- Act V: the Road to the Sun ---
	"oni_lord"]

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
## Hellhound keys (special_set; BoneHoundBehavior, HordeHazards):
##   burn_fraction   — a bite sets the foe burning for this fraction of the
##                     bite's damage in total (source "hellhound_burn"),
##   burn_ticks / burn_tick — ticks of a burn / s between them; a new bite
##                     refreshes the burn (one burn per hound per foe),
##   trail_interval  — s between fire patches a running Hellhound drops,
##   trail_spacing   — px it must have run since its last patch,
##   trail_life      — s a patch burns, trail_radius — its radius (px),
##   trail_tick      — s between patch damage ticks,
##   trail_fraction  — damage per tick to every foe in a patch, as a fraction
##                     of the Hellhound's bite damage (source "hellhound_trail"),
##   pack_split      — 2: the pack splits into two halves (by think slot) that
##                     each focus their own target (1 = one pack).
## Keening Lady keys (special_set; BansheeBehavior):
##   waves         — wails per Dirge (the first plus expanding repeats),
##   wave_interval — s between waves, wave_growth — each wave's radius grows
##                   by this fraction of the Dirge radius,
##   silence       — 1: every foe a wave reaches is silenced for the Dirge
##                   duration: its heals fail (Chaplains, High Confessors,
##                   Seraphine's attendant regeneration; CombatResolver).
## Ossuary Engine keys (special_set; CatapultBehavior, HordeHazards):
##   volley        — boulders per volley (one on the target, the others
##                   volley_spread px to its sides),
##   volley_spread — px between the boulders' landing points,
##   shard_life    — s the burning bone shards stay on the ground,
##   shard_radius  — px radius of a shard field,
##   shard_tick    — s between shard damage ticks,
##   shard_fraction — damage per tick to every foe in the field, as a fraction
##                   of the boulder's damage (source "ossuary_shards").
const EVOLUTIONS := {
	"death_knight": {
		"mode": "transform",
		"bases": ["warrior"],
		"passive": "dark_command",
		"passive_level": 5,  # TUNING (not in GDD) user rule: Dark Command at max level
		"display_name": "Death Knight",
		"plural": "Death Knights",
		"icon": "death_knight",
		"description": "Armoured Death Knights cleave, drain life and hold foes like a wall.",
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
		"description": "Liches cast deadlier blasts, and the foes they slay rise as skeletons.",
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
		"description": "Bishops heal and ward more, burn foes with an aura and free a slot.",
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
		"description": "Deep Freeze spreads wider, frozen foes shatter, and fallen Revenants burst in frost.",
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
		"description": "Reapers chain rapid dashes, stack bleeds, and a dash kill readies the next.",
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
		"description": "Wider dives stun their prey, and each landing turns them to untouchable stone.",
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
		"description": "Piercing, splitting arrows curse foes to take more damage from your undead.",
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
		"description": "Colossi draw foes in, stomp wider and burst into bone shrapnel when slain.",
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
	# Hellhounds (owner-approved): Bone Hounds Lv 5 + Blood Scent Lv 5.
	# Burning bites, a short fire trail, and a pack that splits to hunt two
	# targets (BoneHoundBehavior; patches in HordeHazards).
	"hellhound": {
		"mode": "transform",
		"bases": ["bone_hound"],
		"passive": "blood_scent",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Hellhound",  # TUNING (not in GDD) owner-approved name
		"plural": "Hellhounds",
		"icon": "hellhound",
		"description": "Hellhounds bite with fire, leave burning trails and split to hunt two prey.",
		"mult": {
			"max_hp": 1.3,  # TUNING (not in GDD)
			"damage": 1.2,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 9.0,  # TUNING (not in GDD) bone hounds are 8
		},
		"special_set": {
			"burn_fraction": 0.6,  # TUNING (not in GDD) a burn deals 60% of the bite again over its duration
			"burn_ticks": 6,  # TUNING (not in GDD)
			"burn_tick": 0.5,  # TUNING (not in GDD) s (6 ticks = 3 s)
			"trail_interval": 0.3,  # TUNING (not in GDD) s
			"trail_spacing": 26.0,  # TUNING (not in GDD) px (patches barely overlap)
			"trail_life": 1.6,  # TUNING (not in GDD) s (owner brief: a SHORT fire trail)
			"trail_radius": 14.0,  # TUNING (not in GDD) px
			"trail_tick": 0.5,  # TUNING (not in GDD) s
			"trail_fraction": 0.3,  # TUNING (not in GDD) of the bite damage per tick
			"pack_split": 2,  # TUNING (not in GDD) owner brief: the pack hunts two targets
		},
	},
	# Keening Lady (owner-approved): Banshee Lv 5 + Mournsong Lv 5. The Dirge
	# repeats in three expanding waves and silences priests' heals.
	"keening_lady": {
		"mode": "transform",
		"bases": ["banshee"],
		"passive": "mournsong",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Keening Lady",  # TUNING (not in GDD) owner-approved name
		"plural": "Keening Ladies",
		"icon": "keening_lady",
		"description": "Dirges roll out in widening waves and stop priests from healing.",
		"mult": {
			"max_hp": 1.3,  # TUNING (not in GDD)
			"damage": 1.25,  # TUNING (not in GDD) shriek bolt
		},
		"set": {
			"radius": 11.0,  # TUNING (not in GDD) banshees are 10
		},
		"special_set": {
			"waves": 3,  # TUNING (not in GDD) owner brief: three expanding waves
			"wave_interval": 0.35,  # TUNING (not in GDD) s
			"wave_growth": 0.3,  # TUNING (not in GDD) radius x1, x1.3, x1.6
			"silence": 1,  # TUNING (not in GDD) owner brief: silences priests' heals
		},
	},
	# Ossuary Engine (owner-approved): Corpse Catapult Lv 5 + Siegecraft Lv 5.
	# Three boulders per volley, each leaving burning bone shards.
	"ossuary_engine": {
		"mode": "transform",
		"bases": ["corpse_catapult"],
		"passive": "siegecraft",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Ossuary Engine",  # TUNING (not in GDD) owner-approved name
		"plural": "Ossuary Engines",
		"icon": "ossuary_engine",
		"description": "Heavier volleys leave fields of burning bone shards where they land.",
		# First forced tests (seed 1, --policy=summon): at x1.0 damage and 0.15 shards the
		# catapults dealt 38% of all army damage in a mixed run (the Cathedral Horrors 20%)
		# and 58-88% in runs with only the three newest classes; at x0.85 / 0.12 still 66%
		# in a mixed Sanctum run (the Abominations 25%).
		"mult": {
			"max_hp": 1.35,  # TUNING (not in GDD)
			"damage": 0.75,  # TUNING (not in GDD) each boulder; three per volley (was 1.0, then 0.85)
			"attack_interval": 1.2,  # TUNING (not in GDD) heavier volleys come a little slower
		},
		"set": {
			"radius": 15.0,  # TUNING (not in GDD) catapults are 13
		},
		"special_set": {
			"volley": 3,  # TUNING (not in GDD) owner brief: three boulders per volley
			"volley_spread": 52.0,  # TUNING (not in GDD) px between landing points
			"shard_life": 3.0,  # TUNING (not in GDD) s (owner brief: a few seconds)
			"shard_radius": 30.0,  # TUNING (not in GDD) px
			"shard_tick": 0.5,  # TUNING (not in GDD) s
			"shard_fraction": 0.1,  # TUNING (not in GDD) of the boulder damage per tick (was 0.15, then 0.12)
		},
	},
	# --- Act II: Fallen Seraph ---
	# Seraph of Ruin (GDD §15.0 "Fallen Seraph"): Fallen Seraph Lv 5 + Fallen
	# Grace Lv 5. Each dive chains to a second pack and lays two feather rings,
	# the second wider (SeraphBehavior; rings in SeraphFeathers).
	# Seraph of Ruin keys (special_set; SeraphBehavior):
	#   chain_dives — extra dives after the first: when a dive's recovery ends,
	#                 the densest pack within chain_range px of the impact (not
	#                 the one just struck) is dived on at once (no rise),
	#   chain_range — px around the impact searched for the chained dive,
	#   rings       — feather rings laid per impact,
	#   ring_delay  — s between those rings starting,
	#   ring_growth — ring i reaches ring_radius x (1 + i x this).
	"ruin_seraph": {
		"mode": "transform",
		"bases": ["fallen_seraph"],
		"passive": "fallen_grace",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Seraph of Ruin",  # TUNING (not in GDD) Act II workstream name
		"plural": "Seraphs of Ruin",
		"icon": "ruin_seraph",
		"description": "Each dive chains to a second pack and cuts a second, wider ring of feathers.",
		"mult": {
			"max_hp": 1.3,  # TUNING (not in GDD)
			"damage": 1.2,  # TUNING (not in GDD) feather blades
		},
		"set": {
			"radius": 11.0,  # TUNING (not in GDD) fallen seraphs are 10
		},
		"special_set": {
			"chain_dives": 1,  # TUNING (not in GDD) one chained dive per special
			"chain_range": 170.0,  # TUNING (not in GDD) px around the first impact
			"rings": 2,  # TUNING (not in GDD) two feather rings per impact
			"ring_delay": 0.22,  # TUNING (not in GDD) s
			"ring_growth": 0.4,  # TUNING (not in GDD) the second ring reaches 1.4 x ring_radius
		},
	},
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# Leviathan (GDD §15.0 "Ul-Thalos, the Risen Spire"): Spawn of the Deep
	# Lv 5 + Crushing Depths Lv 5 (a NEW passive, owner rule). Its Grasp seizes
	# two foes and its tentacles sweep everything around it, throwing them back
	# (DeepSpawnBehavior reads the special_set keys).
	"leviathan": {
		"mode": "transform",
		"bases": ["spawn_of_the_deep"],
		"passive": "crushing_depths",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Leviathan",  # TUNING (not in GDD)
		"plural": "Leviathans",
		"icon": "leviathan",
		"description": "Leviathans seize two foes at once and sweep the ground around them with their tentacles.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			"damage": 1.25,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 18.0,  # TUNING (not in GDD) spawns are 15
		},
		"special_set": {
			"grasp_targets": 2,  # TUNING (not in GDD)
			"sweep": 1,  # TUNING (not in GDD) 1 = the tentacle sweep with every grasp
			"sweep_radius": 80.0,  # TUNING (not in GDD) px around the Leviathan
			"sweep_fraction": 2.0,  # TUNING (not in GDD) sweep damage = this x one squeeze
			"sweep_knockback": 180.0,  # TUNING (not in GDD) px/s impulse, divided by enemy mass
		},
	},
	# --- Content wave 2: Bone Golem ---
	# Ossuary Titan (owner-approved proposal 5): Bone Golem Lv 5 + Grave
	# Masonry Lv 5 (a NEW passive, owner rule). The Golem's kit stays
	# (GolemBehavior: slam, Bulwark, Ossuary Hunger); GolemKit reads these
	# special_set keys (final, not suffix-scaled):
	#   absorb_heal      — fraction of its max HP an absorbed body heals,
	#   barrier_amount   — barrier HP every other summon within barrier_reach px
	#                      gets on an absorb (the Warder's barrier path:
	#                      SummonAbilities.grant_barrier(), the stronger wins),
	#   barrier_cooldown — s between those barriers from one Titan,
	#   wall_segments    — Bone Wall segments it collapses into when it falls
	#                      (BoneWall.raise_wall(); fewer if obstacles are in the way),
	#   wall_duration    — s that wall stands,
	#   wall_damage      — spike damage per wall tick as a fraction of its damage
	#                      (source "titan_wall").
	# Body and blocking ring grow together (the Bone Colossus's 4 px reach gap);
	# its 19 px body equals UnitData.MAX_BLOCK_RADIUS.
	"ossuary_titan": {
		"mode": "transform",
		"bases": ["bone_golem"],
		"passive": "grave_masonry",
		"passive_level": 5,  # Owner rule: every evolution needs its paired passive maxed
		"display_name": "Ossuary Titan",  # Owner-approved proposal 5
		"plural": "Ossuary Titans",
		"icon": "ossuary_titan",
		"description": "Titans heal on the bones they absorb, shield the army around them and fall as a wall of bone.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			"damage": 1.3,  # TUNING (not in GDD) the slam
		},
		"set": {
			"radius": 19.0,  # TUNING (not in GDD) golems are 18 (= UnitData.MAX_BLOCK_RADIUS)
			"block_radius": 23.0,  # TUNING (not in GDD) golems are 22; same 4 px reach gap
			"block_mass": 12.0,  # TUNING (not in GDD) golems are 10
		},
		"special_mult": {
			"slam_radius": 1.25,  # TUNING (not in GDD) a wider slam
		},
		"special_set": {
			"absorb_heal": 0.08,  # TUNING (not in GDD) 8% of its max HP per absorbed body
			"barrier_amount": 18.0,  # TUNING (not in GDD) barrier HP (a Warder's is 12, a Bishop's 16)
			"barrier_reach": 110.0,  # TUNING (not in GDD) px around the Titan
			"barrier_cooldown": 2.0,  # TUNING (not in GDD) s between barrier waves from one Titan
			"wall_segments": 7,  # TUNING (not in GDD) about 100 px of wall (GraveSpellData.BONE_WALL_SPACING 16)
			"wall_duration": 6.0,  # Owner-approved proposal: a bone wall for 6 s
			"wall_damage": 0.3,  # TUNING (not in GDD) spike damage per tick, x its slam damage
		},
	},
	# --- Act III: the Assembly Halls ---
	# Wraith Drone (owner-approved Act III proposal): Grave Drone Lv 5 +
	# Overclock Lv 5 (a NEW passive, owner rule). The drones turn spectral:
	# sturdier and harder-hitting, each attack a fan of dart_count piercing
	# darts (GraveDroneBehavior reads the special_set keys).
	"wraith_drone": {
		"mode": "transform",
		"bases": ["grave_drone"],
		"passive": "overclock",
		"passive_level": 5,  # TUNING (not in GDD) owner rule: every evolution needs its passive maxed
		"display_name": "Wraith Drone",  # Owner-approved proposal
		"plural": "Wraith Drones",
		"icon": "wraith_drone",
		"description": "Spectral drones that fire fans of piercing bone darts.",
		"mult": {
			"max_hp": 1.35,  # TUNING (not in GDD)
			"damage": 1.2,  # TUNING (not in GDD) per dart (three darts an attack)
		},
		"set": {
			"radius": 8.0,  # TUNING (not in GDD) drones are 7
		},
		"special_set": {
			"dart_count": 3,  # TUNING (not in GDD) a fan of three darts
			"dart_spread": 0.2,  # TUNING (not in GDD) rad between two darts
			"dart_pierce": 1,  # TUNING (not in GDD) each passes through one more foe
		},
	},
	# --- Act III: the Iron Citadel ---
	# Deus Revenant (GDD §15.0 "Iron Revenant, Deus Revenant and Recoil Frame";
	# owner-approved proposal: "twin cannons, a missile salvo"): Iron Revenant
	# Lv 5 + Recoil Frame Lv 5 (a NEW passive, owner rule). RevenantBehavior
	# reads these special_set keys (final, not suffix-scaled):
	#   twin / twin_offset — 1: two cannons, px apart (twice the shells);
	#   salvo_missiles     — missiles per salvo (0 = none: the base class);
	#   salvo_cooldown     — s between salvos;
	#   salvo_range        — px it looks for targets;
	#   salvo_radius       — px splash of each missile;
	#   salvo_fraction     — each missile's damage, x the unit's damage.
	"deus_revenant": {
		"mode": "transform",
		"bases": ["iron_revenant"],
		"passive": "recoil_frame",
		"passive_level": 5,  # Owner rule: every evolution needs its paired passive maxed
		"display_name": "Deus Revenant",  # Owner-approved proposal
		"plural": "Deus Revenants",
		"icon": "deus_revenant",
		"description": "Twin cannons double the suppressive fire, and missile salvos fall on the strongest foes.",
		"mult": {
			"max_hp": 1.35,  # TUNING (not in GDD)
			"damage": 1.2,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 17.0,  # TUNING (not in GDD) revenants are 15
		},
		"special_set": {
			"twin": 1,  # Owner-approved proposal: twin cannons
			"twin_offset": 7.0,  # TUNING (not in GDD) px
			"salvo_missiles": 4,  # Owner-approved proposal: a missile salvo; TUNING (not in GDD) 4
			"salvo_cooldown": 7.0,  # TUNING (not in GDD) s
			"salvo_range": 340.0,  # TUNING (not in GDD) px
			"salvo_radius": 40.0,  # TUNING (not in GDD) px
			"salvo_fraction": 2.5,  # TUNING (not in GDD) x one shell
		},
	},
	# --- Act IV: the Asphodel Underworld ---
	# Legion of Tartarus (owner-approved proposal: "Myrmidon Shades (evolution
	# Legion of Tartarus)"; GDD §15.0 "Myrmidon Shades, Legion of Tartarus and
	# Myrmidon Oath"): Myrmidon Shade Lv 5 + Myrmidon Oath Lv 5 (a NEW passive,
	# own decision, owner rule: maxed). The Myrmidons come back from Tartarus in
	# black bronze: MyrmidonBehavior reads these special_set keys (final, not
	# suffix-scaled):
	#   wall_cut      — share of every hit a Myrmidon in a locked wall no longer takes;
	#   pierce_count  — foes behind the struck one the spear runs through;
	#   grip_slow / grip_time — every foe the spear strikes is slowed this much
	#                   for this long (the grip of Tartarus).
	"legion_of_tartarus": {
		"mode": "transform",
		"bases": ["myrmidon_shade"],
		"passive": "myrmidon_oath",
		"passive_level": 5,  # Owner rule: every evolution needs its paired passive maxed
		"display_name": "Legion of Tartarus",  # Owner-approved proposal
		"plural": "Legionaries of Tartarus",
		"icon": "legion_of_tartarus",
		"description": "The wall returns from Tartarus: harder shields, a spear through two more foes, and a grip that slows.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			"damage": 1.3,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 11.0,  # TUNING (not in GDD) Myrmidons are 10
			"block_mass": 4.5,  # TUNING (not in GDD) a heavier wall (Myrmidons 3.5)
		},
		"special_set": {
			"wall_cut": 0.45,  # TUNING (not in GDD) (base 0.3)
			"pierce_count": 2,  # TUNING (not in GDD) (base 1)
			"grip_slow": 0.3,  # TUNING (not in GDD)
			"grip_time": 1.0,  # TUNING (not in GDD) s
		},
	},
	# --- Act V: the Road to the Sun ---
	# The Oni Lord (owner-approved proposal: "the Oni ... evolution Oni Lord";
	# GDD §15.0 "The Bound Oni, the Oni Lord and Oni's Resolve"): Bound Oni Lv 5 +
	# Oni's Resolve Lv 5 (a NEW passive, own decision, owner rule: maxed). A
	# great horned oni in bone chains broken loose, a kanabō studded with
	# soul-teal iron. OniBehavior reads these special_set keys (final):
	#   quake_radius   — px of the QUAKE the smash sends out around the blow
	#                    (every foe in it struck for quake_fraction of the smash
	#                    and knocked back, not stunned);
	#   quake_fraction — share of the smash the quake deals.
	"oni_lord": {
		"mode": "transform",
		"bases": ["bound_oni"],
		"passive": "onis_resolve",
		"passive_level": 5,  # Owner rule: every evolution needs its paired passive maxed
		"display_name": "Oni Lord",  # Owner-approved proposal
		"plural": "Oni Lords",
		"icon": "oni_lord",
		"description": "The chains break: a lord of the oni whose smash shakes the ground around it.",
		"mult": {
			"max_hp": 1.4,  # TUNING (not in GDD)
			"damage": 1.3,  # TUNING (not in GDD)
		},
		"set": {
			"radius": 17.0,  # TUNING (not in GDD) Bound Oni 15
			"block_mass": 10.0,  # TUNING (not in GDD) Bound Oni 7
		},
		"special_set": {
			"quake_radius": 92.0,  # TUNING (not in GDD) px
			"quake_fraction": 0.5,  # TUNING (not in GDD)
		},
	},
}
