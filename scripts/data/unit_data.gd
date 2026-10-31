## UnitData — immutable design data for the undead summon classes and the
## horde AI tuning knobs (GDD Part II §23–§34). The shared SummonedUnit script
## reads one row of UNITS per class. The four GDD classes need no
## class-specific code; the later classes (Abomination, Rogue, Gargoyle, Frost
## Wraith) add ONE special action each through a SummonBehavior
## (scripts/horde/behaviors/, chosen by the row's "behavior" key) whose
## numbers live in the row's "special" dictionary below.
##
## Per GDD §37 note: this file holds IMMUTABLE design data only. Per-run state
## (current level, timers, live instances) lives in HordeDirector.
##
## Numbers taken from the GDD are tagged "GDD §x"; invented ones are tagged
## "TUNING (not in GDD)". Distances are in pixels (GDD: ~32 px per world tile),
## times in seconds, speeds in px/s.
class_name UnitData
extends RefCounted

## Display / iteration order of summon classes (HUD rows, card pool).
## The GDD's single Undead Priest is split into two classes (user request,
## GDD §15.0): the Grave Mender (heals) and the Crypt Warder (wards and
## barriers). "bishop" (the Profane Bishop) is never offered on a card: it
## only appears when the Mender and Warder merge (SummonEvolutionData).
## The four later classes (Abomination, Rogue, Gargoyle, Frost Wraith) follow,
## then the three newest (owner-approved): Bone Hounds, Banshee, Corpse
## Catapult.
const CLASS_ORDER := ["warrior", "archer", "mage", "mender", "warder", "bishop",
		"abomination", "rogue", "gargoyle", "frost_wraith",
		"bone_hound", "banshee", "corpse_catapult",
		# --- Act II: Fallen Seraph ---
		# Unlockable (UnlockData: slaying Grand Inquisitor Seraphine once), so a
		# save that never slew her never offers it (Unlocks.offerable()).
		"fallen_seraph",
		# --- Act II: Ul-Thalos, the Risen Spire ---
		"spawn_of_the_deep",
		# --- Content wave 2: Bone Golem ---
		# Unlockable (UnlockData: the Bone Legion achievement), so a fresh save
		# never offers it (Unlocks.offerable()).
		"bone_golem",
		# --- Act III: the Assembly Halls ---
		# Unlockable (UnlockData: slaying the Motherboard), so a fresh save never
		# offers it (Unlocks.offerable()).
		"grave_drone",
		# --- Act III: the Iron Citadel ---
		# Unlockable (UnlockData: defeating Deus Ex Machina), so a fresh save
		# never offers it.
		"iron_revenant",
		# --- Act IV: the Asphodel Underworld ---
		# Unlockable (UnlockData: defeating Hades), so a fresh save never offers it.
		"myrmidon_shade",
		# --- Act V: the Road to the Sun ---
		# Unlockable (UnlockData: defeating Amaterasu), so a fresh save never offers it.
		"bound_oni",
		# --- Act VI: Pandemonium ---
		# Unlockable (UnlockData: defeating the Morning Star), so a fresh save never offers it.
		"archfiend"]
## The four GDD §4.2 summon ROLES ("all 4 classes": the Dread Sovereign
## achievement), in SynergyManager.classes_met() format: an entry that is an
## Array means "any one of these", so after the priest split either priest
## order (or the Profane Bishop, which `counts_as` both) fills the priest
## role. The later classes are never required.
const CORE_CLASSES := ["warrior", "archer", "mage", ["mender", "warder"]]

## Base stats per summon class at skill level 1, before any bonus.
## Field reference (same keys in every row):
##   display_name / plural   — UI strings.
##   description             — level-up card text: one short sentence, no
##                             numbers and no evolution recipe (owner rule,
##                             GDD §15.0 "Card text: one sentence").
##   max_hp                 — hit points.
##   damage                  — damage per attack (Mender / Warder / Bishop: offensive bolt only).
##   attack_interval         — seconds between attacks / heal casts.
##   attack_range            — preferred attack range in px. For melee it is
##                             measured edge-to-edge, for ranged centre-to-edge.
##   move_speed              — px/s.
##   radius                  — body radius in px.
##   acquisition_range       — px; how far the unit looks for targets.
##   replenish_interval      — s; per-ability sequential replacement timer.
##   band_min / band_max     — px; soft formation band around the necromancer.
##   w_pursuit / w_formation / w_separation / w_threat — steering weights.
##   attack_profile          — which attack branch the shared AI runs:
##                             "melee" | "arrow" | "aoe" | "heal" | "ward"
##                             ("ward": minor offense bolts; the Warder's
##                             wards and barriers are instant side casts).
##   target_profile          — which TARGET_WEIGHTS row scores enemies.
##   windup                  — s; cast / swing time before the hit lands.
##   projectile_speed        — px/s (0 for melee).
##   splash_radius           — px; mage explosion radius (0 = none).
##   heal_amount             — HP restored per heal cast (Mender, Bishop) (0 = no heals).
##   kite_distance           — px; archers retreat from threats this close.
##   heal_role_priority      — 0..1 "tactical role priority" a healer assigns
##                             to healing this class (GDD §31).
## Optional keys (read with a default of 0 when absent):
##   block_radius            — px; >0 makes the unit a physical blocker that
##                             enemies cannot overlap (warriors only).
##   block_mass              — blocker "mass" vs Enemy mass: share of an
##                             overlap correction is mass-weighted, so heavy
##                             warriors barely move and the boss shoves them.
##   engaged_speed_mult      — speed multiplier for enemies touching this
##                             blocker (they are "engaged").
##   bash_damage             — shield-bash damage on contact.
##   bash_cooldown           — s between shield bashes.
##   bash_knockback          — px/s impulse of the bash (divided by enemy mass).
##   shield_amount           — HP absorbed by a ward cast on the player
##                             (Warder / Profane Bishop).
##   shield_duration         — s the ward lasts.
##   shield_cooldown         — s between wards from the same unit.
##   ally_shield_amount      — HP of the barrier cast on a threatened ally
##                             (Warder / Profane Bishop; not stacked, the
##                             stronger barrier wins).
##   ally_shield_cooldown    — s between ally barriers from the same unit.
##   aura_interval           — s between aura pulses (Profane Bishop; 0 = none).
##   aura_radius             — px radius of the aura pulse.
##   aura_heal               — HP every ally (and the player) in the aura regains
##                             per pulse.
##   aura_damage             — damage every enemy in the aura takes per pulse.
##   evolved_only            — true: never offered on a level-up card, only
##                             created by a summon evolution (SummonEvolutionData).
##   counts_as               — class ids this class stands in for when synergies
##                             and achievements check requirements.
##   formation               — "front" joins the warriors' threat-facing arc,
##                             "mid" (the default) the midline ring, "back"
##                             an arc of its own BEHIND the necromancer
##                             (opposite the threat; the Corpse Catapult). The
##                             support classes (Mender, Warder, Bishop) always
##                             take the support ring (HordeDirector
##                             _calculate_formation_anchors()).
##   flies                   — Act III (the Grave Drone): true for a class that
##                             always hovers (SummonedUnit.flies): it passes over
##                             obstacles and rides no conveyor belt, but enemies
##                             still target and hit it; false when absent.
##   rejoin_speed_mult       — content wave 2 (the Bone Golem): multiplier on its
##                             catch-up (FOLLOWING far from its post) and
##                             RETURNING speeds; 1 when absent.
##   capacity_bonus_mult     — share (0..1) of GLOBAL capacity bonuses (Grave
##                             Dominion, Legion of Bone) this class receives,
##                             rounded down; 1 when absent. Low-population
##                             elite classes would otherwise double in size.
##   shared_card_pool        — true (every class after the GDD roles): a later
##                             item, its NEW card weighs
##                             LevelUpData.WEIGHT_NEW_LATER; absent (the GDD
##                             summon roles): LevelUpData.WEIGHT_NEW_CORE_SUMMON.
##   new_card_weight_mult    — multiplier on that NEW-card weight (1 when
##                             absent). The Mender and Warder are the GDD's one
##                             Priest role split in two, so each has 0.5: the
##                             two orders together come up as often as one role.
##   behavior                — SummonBehavior id ("stomp" | "dash" | "swoop" |
##                             "frost" | "pack" | "dirge" | "barrage" |
##                             "dive" (Act II: the Fallen Seraph) |
##                             "bulwark" (content wave 2: the Bone Golem));
##                             absent = no special action.
##   special                 — the behaviour's numbers. HordeDirector scales
##                             them by suffix (see _special_stats()):
##                               *_damage   x minion damage bonuses x (1 +
##                                          the level row's special_bonus),
##                               *_radius, *_length  x (1 + special_area),
##                               *_cooldown / (1 + special_haste),
##                               *_duration x (1 + special_duration);
##                             every other key is copied unchanged.
const UNITS := {
	"warrior": {
		"display_name": "Skeleton Warrior",  # GDD §7
		"plural": "Warriors",
		"description": "Skeleton warriors that hold the line and shield you.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 60.0,  # GDD §23
		"damage": 10.0,  # GDD §23
		"attack_interval": 1.2,  # GDD §23
		"attack_range": 22.0,  # GDD §23 / §28
		"move_speed": 85.0,  # GDD §23
		"radius": 10.0,  # GDD §23
		"acquisition_range": 150.0,  # TUNING (not in GDD)
		"replenish_interval": 5.0,  # GDD §24
		"band_min": 35.0,  # GDD §26 inner defense band
		"band_max": 85.0,  # GDD §26
		"w_pursuit": 1.0,  # GDD §26
		"w_formation": 0.35,  # GDD §26
		"w_separation": 0.8,  # GDD §26
		"w_threat": 0.1,  # GDD §26
		"attack_profile": "melee",
		"target_profile": "guard",
		"windup": 0.2,  # TUNING (not in GDD)
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 1.0,  # GDD §31 "Warriors may get a small role bonus"
		"block_radius": 12.0,  # TUNING (not in GDD) user brief: warriors physically block
		"block_mass": 3.0,  # TUNING (not in GDD)
		"engaged_speed_mult": 0.6,  # TUNING (not in GDD) user brief: ~60% speed
		"bash_damage": 5.0,  # TUNING (not in GDD)
		"bash_cooldown": 2.0,  # TUNING (not in GDD)
		"bash_knockback": 160.0,  # TUNING (not in GDD)
	},
	"archer": {
		"display_name": "Skeletal Archer",  # GDD §7
		"plural": "Archers",
		"description": "Skeletal archers that hold their ground and loose arrows from afar.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 30.0,  # GDD §23
		"damage": 8.0,  # GDD §23
		"attack_interval": 1.6,  # GDD §23
		"attack_range": 170.0,  # GDD §23 / §29
		"move_speed": 95.0,  # GDD §23
		"radius": 9.0,  # GDD §23
		"acquisition_range": 260.0,  # TUNING (not in GDD)
		"replenish_interval": 8.0,  # GDD §24
		"band_min": 85.0,  # GDD §26 midline band
		"band_max": 155.0,  # GDD §26
		"w_pursuit": 0.6,  # TUNING (not in GDD)
		"w_formation": 0.5,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.1,  # TUNING (not in GDD) user decision: archers hold their ground (was 0.6); same as warriors
		"attack_profile": "arrow",
		"target_profile": "ranged",
		"windup": 0.15,  # TUNING (not in GDD)
		"projectile_speed": 420.0,  # TUNING (not in GDD)
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,  # User decision (GDD §15.0): archers hold their ground and fire (GDD §29 had a 45 px step-back)
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
	},
	"mage": {
		"display_name": "Undead Mage",  # GDD §7
		"plural": "Mages",
		"description": "Undead mages hurl dark orbs that burst over packed foes.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 35.0,  # GDD §23
		"damage": 14.0,  # GDD §23
		"attack_interval": 2.5,  # GDD §23
		"attack_range": 145.0,  # GDD §23
		"move_speed": 82.0,  # GDD §23
		"radius": 10.0,  # GDD §23
		"acquisition_range": 240.0,  # TUNING (not in GDD)
		"replenish_interval": 12.0,  # GDD §24
		"band_min": 85.0,  # GDD §26 midline band
		"band_max": 155.0,  # GDD §26
		"w_pursuit": 0.5,  # TUNING (not in GDD)
		"w_formation": 0.6,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.7,  # TUNING (not in GDD)
		"attack_profile": "aoe",
		"target_profile": "cluster",
		"windup": 0.35,  # TUNING (not in GDD)
		"projectile_speed": 260.0,  # TUNING (not in GDD)
		"splash_radius": 40.0,  # TUNING (not in GDD)
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
	},
	# Grave Mender: the healing half of the GDD's Undead Priest (user request:
	# priest split). Keeps the priest's §23 numbers and §31 heal formula; it
	# no longer wards (the Crypt Warder does).
	"mender": {
		"display_name": "Grave Mender",  # TUNING (not in GDD) user request: priest split
		"plural": "Menders",
		"description": "Grave menders that mend your undead and you.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 40.0,  # GDD §23 (priest)
		"damage": 3.0,  # GDD §23 (minor offense when nothing needs healing)
		"attack_interval": 2.0,  # GDD §23
		"attack_range": 150.0,  # GDD §23
		"move_speed": 90.0,  # GDD §23
		"radius": 10.0,  # GDD §23
		"acquisition_range": 200.0,  # TUNING (not in GDD)
		"replenish_interval": 15.0,  # GDD §24 (priest)
		"band_min": 60.0,  # GDD §26 support band
		"band_max": 125.0,  # GDD §26
		"w_pursuit": 0.0,  # GDD §26 (0 while healing)
		"w_formation": 0.7,  # GDD §26
		"w_separation": 0.8,  # GDD §26
		"w_threat": 1.0,  # GDD §26
		"attack_profile": "heal",
		"target_profile": "support",
		"windup": 0.3,  # TUNING (not in GDD)
		"projectile_speed": 300.0,  # TUNING (not in GDD)
		"splash_radius": 0.0,
		"heal_amount": 8.0,  # GDD §23 (8 HP per cast at 2.0 s)
		"kite_distance": 0.0,
		"new_card_weight_mult": 0.5,  # TUNING (not in GDD) combined balance pass: one Priest role split in two (naive builds took both no-damage orders in 15 of 16 runs)
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
	},
	# Crypt Warder: the shielding half of the Undead Priest. Instant ward on
	# the threatened necromancer (the old priest ward, same numbers) plus an
	# instant barrier on a threatened ally; slow bolts when idle.
	"warder": {
		"display_name": "Crypt Warder",  # TUNING (not in GDD) user request: priest split
		"plural": "Warders",
		"description": "Crypt warders that ward you and shield threatened allies.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 45.0,  # TUNING (not in GDD) a little sturdier than the Mender
		"damage": 3.0,  # GDD §23 (priest minor offense)
		"attack_interval": 2.0,  # GDD §23 (priest)
		"attack_range": 150.0,  # GDD §23 (priest)
		"move_speed": 90.0,  # GDD §23 (priest)
		"radius": 10.0,  # GDD §23 (priest)
		"acquisition_range": 200.0,  # TUNING (not in GDD) also the ward / barrier reach
		"replenish_interval": 15.0,  # GDD §24 (priest)
		"band_min": 60.0,  # GDD §26 support band
		"band_max": 125.0,  # GDD §26
		"w_pursuit": 0.0,  # GDD §26 (priest)
		"w_formation": 0.7,  # GDD §26 (priest)
		"w_separation": 0.8,  # GDD §26
		"w_threat": 1.0,  # GDD §26 (priest)
		"attack_profile": "ward",
		"target_profile": "support",
		"windup": 0.3,  # TUNING (not in GDD)
		"projectile_speed": 300.0,  # TUNING (not in GDD)
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"new_card_weight_mult": 0.5,  # TUNING (not in GDD) combined balance pass: one Priest role split in two (naive builds took both no-damage orders in 15 of 16 runs)
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
		"shield_amount": 15.0,  # TUNING (not in GDD) the old priest ward on the player
		"shield_duration": 4.0,  # TUNING (not in GDD)
		"shield_cooldown": 6.0,  # TUNING (not in GDD)
		"ally_shield_amount": 12.0,  # TUNING (not in GDD) barrier HP on a threatened ally
		"ally_shield_cooldown": 3.0,  # TUNING (not in GDD)
	},
	# Profane Bishop (GDD §4.2 priest evolution): created only when the Mender
	# and Warder merge (SummonEvolutionData "profane_bishop"). Heals like a
	# Mender, wards and shields like a Warder, and pulses an aura that heals
	# allies and burns enemies (GDD §4.10 "group heal aura ... damage pulse").
	"bishop": {
		"display_name": "Profane Bishop",  # GDD §4.2
		"plural": "Bishops",
		"description": "Profane bishops that heal, ward and burn foes with an unholy aura.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 70.0,  # TUNING (not in GDD)
		"damage": 6.0,  # TUNING (not in GDD) minor offense when nothing needs healing
		"attack_interval": 2.0,  # TUNING (not in GDD)
		"attack_range": 150.0,  # TUNING (not in GDD)
		"move_speed": 90.0,  # TUNING (not in GDD)
		"radius": 12.0,  # TUNING (not in GDD) bigger silhouette
		"acquisition_range": 220.0,  # TUNING (not in GDD)
		"replenish_interval": 12.0,  # TUNING (not in GDD)
		"band_min": 60.0,  # GDD §26 support band
		"band_max": 125.0,  # GDD §26
		"w_pursuit": 0.0,  # GDD §26 (priest)
		"w_formation": 0.7,  # GDD §26 (priest)
		"w_separation": 0.8,  # GDD §26
		"w_threat": 1.0,  # GDD §26 (priest)
		"attack_profile": "heal",
		"target_profile": "support",
		"windup": 0.25,  # TUNING (not in GDD)
		"projectile_speed": 300.0,  # TUNING (not in GDD)
		"splash_radius": 0.0,
		"heal_amount": 12.0,  # TUNING (not in GDD)
		"kite_distance": 0.0,
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
		"shield_amount": 20.0,  # TUNING (not in GDD)
		"shield_duration": 4.0,  # TUNING (not in GDD)
		"shield_cooldown": 5.0,  # TUNING (not in GDD)
		"ally_shield_amount": 16.0,  # TUNING (not in GDD)
		"ally_shield_cooldown": 2.5,  # TUNING (not in GDD)
		"aura_interval": 3.0,  # TUNING (not in GDD)
		"aura_radius": 90.0,  # TUNING (not in GDD)
		"aura_heal": 4.0,  # TUNING (not in GDD)
		"aura_damage": 12.0,  # TUNING (not in GDD)
		"evolved_only": true,
		"counts_as": ["mender", "warder"],
	},
	# --- Later classes (user request; GDD §4.2 lists the Corpse Abomination as
	# a "possible future summon"). Every number below is TUNING (not in GDD).
	# Corpse Abomination: a slow, huge blocker that stomps the crowd around it
	# (AbominationBehavior).
	"abomination": {
		"display_name": "Corpse Abomination",  # GDD §4.2 possible future summon
		"plural": "Abominations",
		"description": "Hulking abominations that block foes and stomp the ground around them.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 260.0,  # TUNING (not in GDD) ~4 warriors of HP in one body
		"damage": 16.0,  # TUNING (not in GDD) fist slam (melee)
		"attack_interval": 1.6,  # TUNING (not in GDD)
		"attack_range": 16.0,  # TUNING (not in GDD) edge-to-edge melee reach (px)
		"move_speed": 62.0,  # TUNING (not in GDD) slowest summon (px/s)
		"radius": 16.0,  # TUNING (not in GDD) body radius (px), the largest summon
		"acquisition_range": 140.0,  # TUNING (not in GDD)
		"replenish_interval": 20.0,  # TUNING (not in GDD) slow to rebuild (s)
		"band_min": 45.0,  # TUNING (not in GDD) just outside the warriors' band (px)
		"band_max": 95.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.4,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.0,  # TUNING (not in GDD) a tank never shies away
		"attack_profile": "melee",
		"target_profile": "guard",  # same preferences as warriors (GDD §27): threats to the player first
		"windup": 0.3,  # TUNING (not in GDD)
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.9,  # TUNING (not in GDD) healers (Mender, Bishop) value the tank
		"block_radius": 20.0,  # TUNING (not in GDD) blocks like a warrior, wider (px)
		"block_mass": 8.0,  # TUNING (not in GDD) warrior 3; the boss (12) still shoves it
		"engaged_speed_mult": 0.45,  # TUNING (not in GDD) touching enemies move at 45%
		"formation": "front",  # TUNING (not in GDD) frontline arc with the warriors
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2, not +5
		"behavior": "stomp",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"stomp_damage": 22.0,  # TUNING (not in GDD) AoE damage to every enemy in the ring
			"stomp_radius": 64.0,  # TUNING (not in GDD) px around the abomination
			"stomp_cooldown": 6.0,  # TUNING (not in GDD) s between stomps
			"stomp_windup": 0.6,  # TUNING (not in GDD) s the ring is telegraphed before it lands
			"stomp_recover": 0.25,  # TUNING (not in GDD) s it stands still after the impact
			"stomp_knockback": 260.0,  # TUNING (not in GDD) px/s impulse, divided by enemy mass
			"stomp_min_enemies": 2,  # TUNING (not in GDD) enemies inside 85% of the ring to stomp (an elite / boss alone also counts)
			"stomp_shake": 3.0,  # TUNING (not in GDD) screen-shake request (px, Juice)
		},
	},
	# Grave Rogue: a fast, fragile assassin that telegraphs a short lane and
	# dashes through it onto backline targets, leaving them bleeding
	# (RogueBehavior), then runs back to its formation slot.
	"rogue": {
		"display_name": "Grave Rogue",  # TUNING (not in GDD) user request
		"plural": "Rogues",
		"description": "Grave rogues that dash through foes and leave them bleeding.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 38.0,  # TUNING (not in GDD) fragile
		"damage": 9.0,  # TUNING (not in GDD) dagger stab (melee)
		"attack_interval": 0.9,  # TUNING (not in GDD)
		"attack_range": 18.0,  # TUNING (not in GDD) edge-to-edge (px)
		"move_speed": 112.0,  # TUNING (not in GDD) fastest summon (px/s)
		"radius": 9.0,  # TUNING (not in GDD)
		"acquisition_range": 240.0,  # TUNING (not in GDD) looks far for backline targets
		"replenish_interval": 9.0,  # TUNING (not in GDD)
		"band_min": 70.0,  # TUNING (not in GDD) between the frontline and the midline (px)
		"band_max": 130.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.4,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.3,  # TUNING (not in GDD)
		"attack_profile": "melee",
		"target_profile": "assassin",
		"windup": 0.12,  # TUNING (not in GDD)
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.4,  # TUNING (not in GDD)
		"formation": "mid",
		"capacity_bonus_mult": 0.6,  # TUNING (not in GDD) Grave Dominion V: +3
		"behavior": "dash",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"dash_damage": 24.0,  # TUNING (not in GDD) to every enemy in the lane
			"dash_length": 130.0,  # TUNING (not in GDD) max lane length (px)
			"dash_min": 45.0,  # TUNING (not in GDD) the target must be at least this far (px) to dash
			"dash_overshoot": 30.0,  # TUNING (not in GDD) px the lane runs past the target
			"dash_width": 24.0,  # TUNING (not in GDD) lane width (px)
			"dash_telegraph": 0.3,  # TUNING (not in GDD) s the lane is shown before the dash
			"dash_speed": 560.0,  # TUNING (not in GDD) px/s while dashing
			"dash_cooldown": 4.5,  # TUNING (not in GDD) s between dashes
			"bleed_damage": 3.0,  # TUNING (not in GDD) damage per bleed tick
			"bleed_duration": 3.0,  # TUNING (not in GDD) s a dash's bleed lasts
			"bleed_tick": 0.5,  # TUNING (not in GDD) s between bleed ticks
			"backline_bonus": 0.6,  # TUNING (not in GDD) target-score bonus for archers / chaplains / consecrators
			"far_bonus": 0.3,  # TUNING (not in GDD) score bonus x (enemy distance to player / the unit's engagement leash, ENGAGE_RADIUS x Bound Souls): the back of the crowd
		},
	},
	# Crypt Gargoyle: melee claws, and a periodic swoop: it takes off (airborne:
	# ignores obstacles and body-blocking, cannot be hit), dives onto a cluster
	# for AoE damage, then lands (GargoyleBehavior).
	"gargoyle": {
		"display_name": "Crypt Gargoyle",  # TUNING (not in GDD) user request
		"plural": "Gargoyles",
		"description": "Crypt gargoyles that fly over the fray and dive onto packed foes.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 70.0,  # TUNING (not in GDD) stone skin
		"damage": 11.0,  # TUNING (not in GDD) claw rake (melee)
		"attack_interval": 1.0,  # TUNING (not in GDD)
		"attack_range": 18.0,  # TUNING (not in GDD) edge-to-edge (px)
		"move_speed": 95.0,  # TUNING (not in GDD)
		"radius": 11.0,  # TUNING (not in GDD)
		"acquisition_range": 200.0,  # TUNING (not in GDD)
		"replenish_interval": 12.0,  # TUNING (not in GDD)
		"band_min": 50.0,  # TUNING (not in GDD) frontline arc, a little behind the abominations (px)
		"band_max": 110.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.4,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.1,  # TUNING (not in GDD)
		"attack_profile": "melee",
		"target_profile": "skirmisher",
		"windup": 0.15,  # TUNING (not in GDD)
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.6,  # TUNING (not in GDD)
		"formation": "front",
		"capacity_bonus_mult": 0.6,  # TUNING (not in GDD) Grave Dominion V: +3
		"behavior": "swoop",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"swoop_damage": 30.0,  # TUNING (not in GDD) AoE damage where it lands
			"swoop_radius": 50.0,  # TUNING (not in GDD) impact radius (px)
			"swoop_cooldown": 7.0,  # TUNING (not in GDD) s between swoops
			"swoop_takeoff": 0.25,  # TUNING (not in GDD) s rising in place (already airborne)
			"swoop_land": 0.25,  # TUNING (not in GDD) s settling after the dive (still airborne)
			"swoop_speed": 330.0,  # TUNING (not in GDD) flight speed (px/s)
			"swoop_range_min": 50.0,  # TUNING (not in GDD) closer clusters are clawed instead (px)
			"swoop_range_max": 230.0,  # TUNING (not in GDD) farthest dive (px)
			"swoop_max_flight": 1.4,  # TUNING (not in GDD) s; the dive lands wherever it is by then
			"swoop_min_enemies": 3,  # TUNING (not in GDD) enemies around the target to swoop (an elite / boss alone also counts)
			"swoop_knockback": 160.0,  # TUNING (not in GDD) px/s impulse, divided by enemy mass
			"swoop_lift": 18.0,  # TUNING (not in GDD) px the body is drawn above its shadow at full height
			"swoop_shake": 1.5,  # TUNING (not in GDD) screen-shake request (px, Juice)
			"cluster_bonus": 0.6,  # TUNING (not in GDD) target-score bonus x cluster fullness while the swoop is ready
		},
	},
	# Frost Wraith: an ice mage. Frost bolts chill (slow) what they hit; a
	# periodic Deep Freeze freezes every enemy around its target (the Stasis
	# freeze path; bosses briefly, Reckoning enemies never; FrostWraithBehavior).
	"frost_wraith": {
		"display_name": "Frost Wraith",  # TUNING (not in GDD) user request
		"plural": "Frost Wraiths",
		"description": "Frost wraiths that chill foes and lock packs in Deep Freeze.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 34.0,  # TUNING (not in GDD)
		# Combined balance pass: 8 -> 12. At 8 it dealt about 18k per run at Lv 5 (the other
		# later classes 73-120k, warriors / Death Knights 120-140k) and about 4k in naive
		# runs, so a Wraith slot was nearly dead weight outside its Deep Freeze.
		"damage": 18.0,  # TUNING (not in GDD) frost bolt; owner balance pass (Oct 2026) 12 -> 18: forced into an army it dealt 55% of a core unit's damage per unit
		"attack_interval": 1.5,  # TUNING (not in GDD)
		"attack_range": 160.0,  # TUNING (not in GDD) centre-to-edge (px)
		"move_speed": 88.0,  # TUNING (not in GDD)
		"radius": 10.0,  # TUNING (not in GDD)
		"acquisition_range": 250.0,  # TUNING (not in GDD)
		"replenish_interval": 14.0,  # TUNING (not in GDD)
		"band_min": 95.0,  # TUNING (not in GDD) outer midline (px)
		"band_max": 160.0,  # TUNING (not in GDD)
		"w_pursuit": 0.5,  # TUNING (not in GDD)
		"w_formation": 0.6,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.8,  # TUNING (not in GDD) keeps out of the crowd
		"attack_profile": "frost",
		"target_profile": "frost",
		"windup": 0.25,  # TUNING (not in GDD)
		"projectile_speed": 340.0,  # TUNING (not in GDD)
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
		"formation": "mid",
		"capacity_bonus_mult": 0.5,  # TUNING (not in GDD) Grave Dominion V: +2
		"behavior": "frost",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"chill_slow": 0.35,  # TUNING (not in GDD) fraction of speed a frost bolt removes
			"chill_duration": 1.8,  # TUNING (not in GDD) s the chill lasts
			"freeze_radius": 52.0,  # TUNING (not in GDD) px around the target
			"freeze_duration": 1.6,  # TUNING (not in GDD) s enemies stay frozen
			"freeze_cooldown": 9.0,  # TUNING (not in GDD) s between Deep Freezes
			"freeze_windup": 0.45,  # TUNING (not in GDD) s the frost circle is telegraphed
			"freeze_boss_mult": 0.2,  # TUNING (not in GDD) Sir Alaric: 20% of the duration (Stasis gives him 50%)
			"freeze_elite_mult": 0.6,  # TUNING (not in GDD) elites: 60% of the duration
			"freeze_min_enemies": 3,  # TUNING (not in GDD) enemies around the target (an elite / boss, or a target next to an endangered player, alone also counts)
			"unchilled_bonus": 0.4,  # TUNING (not in GDD) target-score bonus for an enemy not chilled yet (spreads the slow)
		},
	},
	# --- The three newest classes (owner-approved). Every number is TUNING
	# (not in GDD). Bone Hounds: cheap, fast pack beasts that share a target
	# and bite harder together (BoneHoundBehavior, Pack Hunt). Melee; like
	# every summon they never kite.
	"bone_hound": {
		"display_name": "Bone Hound",  # TUNING (not in GDD) owner-approved class
		"plural": "Bone Hounds",
		"description": "Bone hounds that hunt one prey as a pack, biting harder together.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		# First forced tests (seed 1): at 26 HP and 5.5 damage every 0.8 s the pack died 238
		# times in a run and dealt 7% of the army's damage, and in the Sanctum the Sentinels'
		# flat armour 6 ate most of each bite. Heavier, slower bites (same damage per second).
		"max_hp": 40.0,  # TUNING (not in GDD) cheap and fragile; was 26
		"damage": 12.0,  # TUNING (not in GDD) bite (melee); owner balance pass (Oct 2026) 7.5 -> 12: a hound dealt 43% of a core unit's damage, the whole pack about half a core class (was 5.5 before 7.5)
		"attack_interval": 1.0,  # TUNING (not in GDD) s; was 0.8
		"attack_range": 14.0,  # TUNING (not in GDD) edge-to-edge (px)
		"move_speed": 122.0,  # TUNING (not in GDD) the fastest summon (px/s; rogues 112)
		"radius": 8.0,  # TUNING (not in GDD) small body (px)
		"acquisition_range": 230.0,  # TUNING (not in GDD) looks far for prey at the edge of the crowd (px)
		"replenish_interval": 6.0,  # TUNING (not in GDD) s; cheap to replace
		"band_min": 55.0,  # TUNING (not in GDD) between the frontline and the midline (px)
		"band_max": 115.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.35,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.0,  # TUNING (not in GDD) a hunting pack never shies away
		"attack_profile": "melee",
		"target_profile": "pack",
		"windup": 0.1,  # TUNING (not in GDD) s
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.3,  # TUNING (not in GDD) healers value the cheap hounds least
		"formation": "mid",
		"capacity_bonus_mult": 0.6,  # TUNING (not in GDD) Grave Dominion V: +3 (the pack is already the biggest class)
		"behavior": "pack",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"pack_bonus": 0.15,  # TUNING (not in GDD) +15% bite damage per other hound biting the same foe
			"pack_cap": 3,  # TUNING (not in GDD) at most 3 packmates count (+45%)
			"pack_radius": 30.0,  # TUNING (not in GDD) px beyond the foe's edge a packmate counts as biting it
			# Backline / edge pulls were 0.5 / 0.3 at first: the pack ran through the whole crowd
			# to reach an archer and was swarmed (200+ deaths a run in the forced tests).
			"backline_bonus": 0.35,  # TUNING (not in GDD) target-score bonus for archers / casters / priests / banner bearers
			"edge_bonus": 0.1,  # TUNING (not in GDD) score bonus x (foe distance to the player / the engagement leash): the edge of the crowd
			"focus_bonus": 0.45,  # TUNING (not in GDD) score bonus x (packmates already on this foe / pack_cap): the pack shares a target
		},
	},
	# Banshee: a spectral support caster. It floats (drawn above a shadow; it
	# passes through enemies like every summon) but, unlike a swooping Gargoyle,
	# it is NOT airborne: enemies can target and hit it, so it keeps its
	# distance (w_threat). Its Dirge (BansheeBehavior) is a telegraphed wail
	# around its target that slows foes and cuts their damage
	# (CombatResolver.weaken_enemy(), the one debuff path).
	"banshee": {
		"display_name": "Banshee",  # TUNING (not in GDD) owner-approved class
		"plural": "Banshees",
		"description": "A floating banshee whose wailing Dirge slows foes and weakens their blows.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 40.0,  # TUNING (not in GDD) was 36 (63-70 deaths a run in the first forced tests)
		"damage": 14.0,  # TUNING (not in GDD) spectral shriek bolt; owner balance pass (Oct 2026) 7 -> 14: it dealt 23% of a core unit's damage (the Dirge debuff aside)
		"attack_interval": 1.8,  # TUNING (not in GDD) s
		"attack_range": 150.0,  # TUNING (not in GDD) centre-to-edge (px); also the Dirge's reach
		"move_speed": 92.0,  # TUNING (not in GDD) px/s
		"radius": 10.0,  # TUNING (not in GDD)
		"acquisition_range": 240.0,  # TUNING (not in GDD)
		"replenish_interval": 14.0,  # TUNING (not in GDD) s
		"band_min": 90.0,  # TUNING (not in GDD) midline (px)
		"band_max": 150.0,  # TUNING (not in GDD)
		"w_pursuit": 0.5,  # TUNING (not in GDD)
		"w_formation": 0.6,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.9,  # TUNING (not in GDD) a frail caster keeps out of the crowd
		"attack_profile": "dirge",
		"target_profile": "dirge",
		"windup": 0.25,  # TUNING (not in GDD) s
		"projectile_speed": 300.0,  # TUNING (not in GDD) px/s
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.6,  # TUNING (not in GDD)
		"formation": "mid",
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2
		"behavior": "dirge",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"dirge_radius": 72.0,  # TUNING (not in GDD) px around the target
			"dirge_cooldown": 6.0,  # TUNING (not in GDD) s between Dirges (owner brief: every ~6 s)
			"dirge_windup": 0.6,  # TUNING (not in GDD) s the wail is telegraphed
			"dirge_duration": 4.0,  # TUNING (not in GDD) s the slow and the damage cut last (owner brief)
			"dirge_slow": 0.3,  # TUNING (not in GDD) fraction of speed removed (a slow, never a fear)
			"dirge_cut": 0.25,  # TUNING (not in GDD) fraction of damage removed from the foe's hits
			"dirge_boss_mult": 0.5,  # TUNING (not in GDD) share of the slow and cut on bosses / minibosses
			"dirge_min_enemies": 3,  # TUNING (not in GDD) foes around the target to wail (an elite / boss, or a foe on an endangered player, alone also counts)
			"unweakened_bonus": 0.4,  # TUNING (not in GDD) target-score bonus for a foe not weakened yet (spreads the Dirge)
		},
	},
	# Corpse Catapult: slow siege artillery that stays behind the army
	# (formation "back") and holds its ground while firing like the Archers.
	# Its attack is Bone Barrage (CatapultBehavior): an arcing bone boulder
	# with a landing telegraph that splashes splash_radius px; it targets
	# structures, elites, minibosses and the densest packs first.
	"corpse_catapult": {
		"display_name": "Corpse Catapult",  # TUNING (not in GDD) owner-approved class
		"plural": "Catapults",
		"description": "Corpse catapults that hang back and lob boulders at packs and structures.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 90.0,  # TUNING (not in GDD) a sturdy frame of bone and sinew
		"damage": 22.0,  # TUNING (not in GDD) per enemy in the boulder's splash
		"attack_interval": 3.6,  # TUNING (not in GDD) s between boulders
		"attack_range": 235.0,  # TUNING (not in GDD) centre-to-edge (px), the longest reach
		"move_speed": 60.0,  # TUNING (not in GDD) the slowest summon (px/s)
		"radius": 13.0,  # TUNING (not in GDD)
		# 300 at first: from its post ~170 px behind the necromancer it then saw structures only
		# when he stood next to them (Crimson March test: 551 structure damage in a run).
		"acquisition_range": 380.0,  # TUNING (not in GDD) px; was 300
		"replenish_interval": 18.0,  # TUNING (not in GDD) s; slow to rebuild
		"band_min": 110.0,  # TUNING (not in GDD) behind the necromancer (px)
		"band_max": 150.0,  # TUNING (not in GDD)
		"w_pursuit": 0.3,  # TUNING (not in GDD)
		"w_formation": 0.7,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.1,  # TUNING (not in GDD) holds its ground like the Archers
		"attack_profile": "boulder",
		"target_profile": "siege",
		"windup": 0.5,  # TUNING (not in GDD) s winding the arm
		"projectile_speed": 0.0,
		"splash_radius": 50.0,  # TUNING (not in GDD) boulder splash radius (px)
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.7,  # TUNING (not in GDD)
		"formation": "back",
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2
		"behavior": "barrage",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"boulder_speed": 300.0,  # TUNING (not in GDD) px/s along the ground: flight time = distance / this
			"boulder_flight_min": 0.55,  # TUNING (not in GDD) s, shortest flight (the telegraph is always readable)
			"boulder_flight_max": 1.1,  # TUNING (not in GDD) s, longest flight
			"boulder_lead": 0.7,  # TUNING (not in GDD) share of the target's velocity x flight time the aim leads by
			"boulder_arc": 48.0,  # TUNING (not in GDD) px peak height of the drawn arc
			"boulder_knockback": 120.0,  # TUNING (not in GDD) px/s impulse, divided by enemy mass
			"boulder_shake": 1.0,  # TUNING (not in GDD) screen-shake request (px, Juice)
			"structure_bonus": 1.5,  # TUNING (not in GDD) target-score bonus for a structure (outposts, generators, crystals, altars, carts)
			"elite_bonus": 0.7,  # TUNING (not in GDD) target-score bonus for an elite, a miniboss or the boss
		},
	},
	# --- Act II: Fallen Seraph ---
	# Fallen Seraph (owner-approved, GDD §15.0 "Fallen Seraph"): a corrupted
	# angel raised from the Covenant's fallen, granted by slaying Grand
	# Inquisitor Seraphine (UnlockData). She HOVERS like the Banshee (drawn
	# above a shadow, but not airborne: enemies can target and hit her, so she
	# keeps a little distance, w_threat) and throws black feather blades
	# (attack_profile "feather", released by SeraphBehavior). Her special
	# (SeraphBehavior, "dive"): she dives onto the densest pack in reach and
	# leaves a ring of black feathers that cuts outward (SeraphFeathers).
	# Every number is TUNING (not in GDD).
	"fallen_seraph": {
		"display_name": "Fallen Seraph",  # TUNING (not in GDD) owner-approved class
		"plural": "Fallen Seraphs",
		"description": "A fallen seraph who dives onto packed foes and leaves a ring of cutting feathers.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 55.0,  # TUNING (not in GDD) between the Banshee (40) and the Gargoyle (70): she dives into the crowd
		"damage": 12.0,  # TUNING (not in GDD) one feather blade (ranged)
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 140.0,  # TUNING (not in GDD) centre-to-edge (px)
		"move_speed": 90.0,  # TUNING (not in GDD) px/s; below PassiveData.FAST_SUMMON_SPEED (not a Blood Scent class)
		"radius": 10.0,  # TUNING (not in GDD) body radius (px)
		"acquisition_range": 250.0,  # TUNING (not in GDD) px
		"replenish_interval": 15.0,  # TUNING (not in GDD) s
		"band_min": 80.0,  # TUNING (not in GDD) midline (px)
		"band_max": 140.0,  # TUNING (not in GDD)
		"w_pursuit": 0.5,  # TUNING (not in GDD)
		"w_formation": 0.6,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.7,  # TUNING (not in GDD) keeps a little distance between dives
		"attack_profile": "feather",
		"target_profile": "seraph",
		"windup": 0.2,  # TUNING (not in GDD) s
		"projectile_speed": 380.0,  # TUNING (not in GDD) px/s
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.6,  # TUNING (not in GDD)
		"formation": "mid",
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2
		"behavior": "dive",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"dive_damage": 18.0,  # TUNING (not in GDD) to every enemy within dive_radius where she lands
			"dive_radius": 40.0,  # TUNING (not in GDD) impact radius (px)
			"dive_cooldown": 7.0,  # TUNING (not in GDD) s between dives
			"dive_rise": 0.25,  # TUNING (not in GDD) s she rises in place before the dive
			"dive_speed": 380.0,  # TUNING (not in GDD) px/s while diving
			"dive_max_flight": 0.9,  # TUNING (not in GDD) s; the dive lands wherever she is by then
			"dive_recover": 0.3,  # TUNING (not in GDD) s she hovers over the impact before rejoining the army
			"dive_range_min": 40.0,  # TUNING (not in GDD) px; a closer pack is not dived on (she throws feathers)
			"dive_range_max": 220.0,  # TUNING (not in GDD) px; the farthest pack she dives on
			"dive_min_enemies": 4,  # TUNING (not in GDD) enemies within dive_radius of the pack centre (an elite / boss alone also counts)
			"dive_candidates": 10,  # TUNING (not in GDD) enemies compared per pack search (performance cap)
			"dive_retry": 0.6,  # TUNING (not in GDD) s before searching again when no pack was worth it
			"dive_knockback": 110.0,  # TUNING (not in GDD) px/s impulse, divided by enemy mass
			"dive_lift": 16.0,  # TUNING (not in GDD) px she is drawn above her shadow at the top of the rise
			"dive_shake": 1.0,  # TUNING (not in GDD) screen-shake request (px, Juice)
			"feather_damage": 10.0,  # TUNING (not in GDD) to every enemy the feather ring cuts (once each)
			"ring_radius": 85.0,  # TUNING (not in GDD) px the feather ring reaches
			"ring_start": 0.3,  # TUNING (not in GDD) the ring starts at this fraction of ring_radius
			"ring_time": 0.4,  # TUNING (not in GDD) s the ring takes to reach ring_radius
			"ring_feathers": 14,  # TUNING (not in GDD) feathers drawn on the ring (drawing only)
		},
	},
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# Spawn of the Deep (GDD §15.0 "Ul-Thalos, the Risen Spire": the finale's
	# reward, unlocked by slaying Vhal'Neth, UnlockData): a tentacled,
	# barnacled heavy of the deep, bound to the necromancer. A frontline
	# blocker (like the Abomination, a little lighter) whose special, Grasp
	# (DeepSpawnBehavior), seizes the strongest foe in reach and holds it fast
	# (the Cathedral Horror's stun hold, CombatResolver.stun_enemy()),
	# dragging it in and squeezing it. Its evolution, the Leviathan, holds two
	# and sweeps everything around it (SummonEvolutionData).
	"spawn_of_the_deep": {
		"display_name": "Spawn of the Deep",  # Owner-approved class (proposal decision 5)
		"plural": "Spawns of the Deep",
		"description": "Tentacled spawn of the deep that seize foes and hold them fast.",  # Card text: one short sentence (owner rule).
		"max_hp": 210.0,  # TUNING (not in GDD) a heavy (Abomination 260)
		"damage": 14.0,  # TUNING (not in GDD) tentacle lash (melee)
		"attack_interval": 1.4,  # TUNING (not in GDD)
		"attack_range": 14.0,  # TUNING (not in GDD) edge-to-edge melee reach (px)
		"move_speed": 66.0,  # TUNING (not in GDD) px/s, slow
		"radius": 15.0,  # TUNING (not in GDD) body radius (px)
		"acquisition_range": 150.0,  # TUNING (not in GDD)
		"replenish_interval": 18.0,  # TUNING (not in GDD) slow to rebuild (s)
		"band_min": 45.0,  # TUNING (not in GDD) with the frontline (px)
		"band_max": 95.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.4,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.0,  # TUNING (not in GDD) a heavy never shies away
		"attack_profile": "melee",
		"target_profile": "guard",  # Threats to the necromancer first (GDD §27).
		"windup": 0.3,  # TUNING (not in GDD)
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.85,  # TUNING (not in GDD) healers value the heavy
		"block_radius": 18.0,  # TUNING (not in GDD) blocks like a warrior, wider (px)
		"block_mass": 6.0,  # TUNING (not in GDD) warrior 3, Abomination 8
		"engaged_speed_mult": 0.55,  # TUNING (not in GDD) touching enemies move at 55%
		"formation": "front",  # TUNING (not in GDD) the frontline arc
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2, not +5
		"behavior": "grasp",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"grasp_damage": 7.0,  # TUNING (not in GDD) per squeeze tick
			"grasp_tick": 0.5,  # TUNING (not in GDD) s between squeezes
			"grasp_duration": 2.4,  # TUNING (not in GDD) s a foe is held (the stun hold)
			"grasp_cooldown": 7.0,  # TUNING (not in GDD) s between grasps
			"grasp_range": 90.0,  # TUNING (not in GDD) px edge to edge
			"grasp_windup": 0.35,  # TUNING (not in GDD) s the tentacle reaches
			"grasp_recover": 0.25,  # TUNING (not in GDD) s it stands after the grasp
			"grasp_pull": 120.0,  # TUNING (not in GDD) px/s a held foe is dragged in (not bosses, minibosses, structures)
			"grasp_boss_mult": 0.25,  # TUNING (not in GDD) share of the hold on the boss / a miniboss
			"grasp_elite_mult": 0.6,  # TUNING (not in GDD) share of the hold on an elite
			"grasp_targets": 1,  # Foes seized per grasp (the Leviathan: 2).
			"elite_bonus": 0.6,  # TUNING (not in GDD) target-score bonus for an elite, a miniboss or the boss
		},
	},
	# --- Content wave 2: Bone Golem ---
	# Bone Golem (owner-approved proposal 5, GDD §15.0 "Bone Golem (content
	# wave 2)"; locked until the Bone Legion achievement, UnlockData): a slow,
	# living fortress built from the necromancer's fallen. Not a second
	# Abomination: an ANCHOR that holds its post on the Bone Ring (formation
	# "front", a blocker like the Warriors), grows during a run and protects
	# the dead. Its attack is a heavy two-handed slam: an ordinary "melee"
	# strike on its target plus a splash of slam_fraction of it on every other
	# foe within slam_radius of the struck one (GolemBehavior.on_melee_hit(),
	# source "golem_slam"). Its specials (GolemBehavior, "bulwark"):
	#   Ossuary Hunger: a summon of yours that dies within hunger_reach px of a
	#     Golem is absorbed by the nearest one (GolemKit): +hunger_hp max HP
	#     each, up to hunger_cap, and the body is drawn up to hunger_size
	#     bigger (a sprite scale, UnitMotion.size_k). Same on every stage
	#     (owner rule: no act-specific summon mechanics).
	#   Bulwark: every bulwark_cooldown s, with bulwark_min_enemies foes within
	#     bulwark_trigger px (or an elite / the boss), it plants itself for
	#     bulwark_duration s: it cannot walk (it still slams), its block mass
	#     becomes bulwark_mass (nothing walks through it: Enemy.
	#     resolve_blocking()'s push-out) and every foe within bulwark_reach px
	#     targets it (ColossusKit's taunt; bosses, Reckoning foes and structures
	#     ignore it).
	# Every number is TUNING (not in GDD).
	"bone_golem": {
		"display_name": "Bone Golem",  # Owner-approved proposal 5
		"plural": "Bone Golems",
		"description": "A slow fortress of bone that holds its ground, slams foes and grows from your fallen.",  # Card text: one short sentence (owner rule).
		"max_hp": 420.0,  # TUNING (not in GDD) the biggest body in the army (Abomination 260)
		# Balance screen (4 seeds x Graveyard / Sanctum, --mortal --policy=army, the Golem vs the
		# Abomination beside Warriors, Archers, Mages): at 26 damage, 130 px reach and a 60%
		# splash the Golem was as safe (min HP 109 / 83 vs 100 / 92) but dealt 42-57% of the
		# Abomination's damage; it now hits harder and looks a little farther.
		"damage": 32.0,  # TUNING (not in GDD) the two-handed slam on its target (melee); was 26
		"attack_interval": 2.2,  # TUNING (not in GDD) s; a slow, heavy slam
		"attack_range": 28.0,  # TUNING (not in GDD) edge-to-edge melee reach (px): long arms (Abomination 16); 18 at first, it chased foes it could not catch
		"move_speed": 48.0,  # TUNING (not in GDD) px/s; about half a Warrior's 85 (proposal: very slow)
		# First forced tests: at its fighting speed it trailed the moving army (60% of its
		# time without a target, 106 slams a run); it now lumbers faster only to rejoin its
		# post (catch-up 46 x 1.35 x this, return 46 x 1.5 x this px/s).
		"rejoin_speed_mult": 1.7,  # TUNING (not in GDD) optional key (1 when absent): catch-up and return speed factor
		"radius": 18.0,  # TUNING (not in GDD) body radius (px); <= UnitData.MAX_BLOCK_RADIUS (the Bone Colossus is 19)
		"acquisition_range": 160.0,  # TUNING (not in GDD) px; an anchor does not chase far (was 130)
		"replenish_interval": 24.0,  # TUNING (not in GDD) s; the slowest to rebuild
		"band_min": 45.0,  # TUNING (not in GDD) with the frontline (px)
		"band_max": 95.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.35,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.0,  # TUNING (not in GDD) a fortress never shies away
		"attack_profile": "melee",
		"target_profile": "fortress",  # The nearest foes first, never filtered by the necromancer's danger (an anchor fights what reaches it).
		"windup": 0.35,  # TUNING (not in GDD) s; both fists raised before the slam (0.45 at first: half the slams missed a foe that had moved or died)
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.9,  # TUNING (not in GDD) healers value the fortress
		"block_radius": 22.0,  # TUNING (not in GDD) blocks like a warrior, wider (px); same 4 px reach gap as the Abomination
		"block_mass": 10.0,  # TUNING (not in GDD) Abomination 8, Colossus 11; the boss (12) still shoves it unless it plants
		"engaged_speed_mult": 0.45,  # TUNING (not in GDD) touching enemies move at 45%
		"formation": "front",  # TUNING (not in GDD) holds a post on the Bone Ring like a blocker
		"capacity_bonus_mult": 0.2,  # TUNING (not in GDD) Grave Dominion V: +1, not +5 (a 1-2 body class)
		"behavior": "bulwark",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"slam_radius": 40.0,  # TUNING (not in GDD) px around the struck foe the slam splashes
			"slam_fraction": 0.7,  # TUNING (not in GDD) splash damage = this x the slam's damage, to every other foe in slam_radius (was 0.6)
			"slam_shake": 1.5,  # TUNING (not in GDD) screen-shake request (px, Juice)
			"hunger_reach": 140.0,  # Owner-approved proposal: a summon dying within 140 px is absorbed (not area-scaled: no _radius suffix)
			"hunger_hp": 0.04,  # Owner-approved proposal: +4% max HP per absorbed body
			"hunger_cap": 0.60,  # Owner-approved proposal: at most +60% max HP
			"hunger_size": 0.25,  # TUNING (not in GDD) the body is drawn up to 25% bigger at the cap (visual only)
			"bulwark_cooldown": 12.0,  # Owner-approved proposal: plants every 12 s
			"bulwark_duration": 3.0,  # Owner-approved proposal: for 3 s (Grave Masonry and special_duration lengthen it)
			"bulwark_reach": 120.0,  # Owner-approved proposal: draws foes within 120 px (taunt; not area-scaled)
			"bulwark_trigger": 80.0,  # TUNING (not in GDD) px; foes this close make it plant
			"bulwark_min_enemies": 3,  # TUNING (not in GDD) foes within bulwark_trigger to plant (an elite / the boss alone also counts)
			"bulwark_mass": 400.0,  # TUNING (not in GDD) block mass while planted: the boss (12) moves it by 3% of an overlap
			"planted_reach_bonus": 2.0,  # TUNING (not in GDD) target-score bonus while planted for a foe within slam reach (the shared score is ~1-3)
			"planted_far_penalty": 1.0,  # TUNING (not in GDD) target-score penalty while planted for a foe out of reach (it cannot walk)
		},
	},
	# --- Act III: the Assembly Halls ---
	# Grave Drone (owner-approved Act III proposal: "a flying swarm of skull
	# drones, three to a card, that hover over the army and fire bone darts. A
	# ranged class that cannot be body-blocked"; unlocked by slaying the
	# Motherboard). A cheap ranged swarm that HOVERS (flies: no obstacle
	# collision, no conveyor) inside the Bone Ring with the support classes
	# (formation "back"), firing bone darts (GraveDroneBehavior "hover"
	# releases its "dart" profile). Enemies can target and hit it; its body is
	# drawn floating over a shadow. Works the same on every stage.
	"grave_drone": {
		"display_name": "Grave Drone",  # Owner-approved proposal
		"plural": "Grave Drones",
		"description": "A swarm of skull drones that hovers over your army and fires bone darts.",  # Card text: one short sentence (owner rule; numbers stay on the stat lines).
		"max_hp": 30.0,  # TUNING (not in GDD) frail like an archer (first pass 22: 253 deaths in a forced run, Empire rounds stop on it)
		"damage": 6.0,  # TUNING (not in GDD) per dart (an archer's arrow is 8; first pass 5)
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 190.0,  # TUNING (not in GDD) centre-to-edge (px); a little past the archers
		"move_speed": 100.0,  # TUNING (not in GDD) px/s; quick hover (Blood Scent counts it as fast)
		"radius": 7.0,  # TUNING (not in GDD) small body (px)
		"acquisition_range": 270.0,  # TUNING (not in GDD)
		"replenish_interval": 7.0,  # TUNING (not in GDD) s; cheap to rebuild
		"band_min": 26.0,  # TUNING (not in GDD) over the army, inside the ring (px)
		"band_max": 64.0,  # TUNING (not in GDD)
		"w_pursuit": 0.35,  # TUNING (not in GDD) it fires from where it hovers
		"w_formation": 0.9,  # TUNING (not in GDD) keeps over the army
		"w_separation": 0.9,  # TUNING (not in GDD)
		"w_threat": 0.0,  # TUNING (not in GDD) hovers; never shies away
		"attack_profile": "dart",  # Released by GraveDroneBehavior (one or more darts).
		"target_profile": "ranged",
		"windup": 0.12,  # TUNING (not in GDD) s
		"projectile_speed": 460.0,  # TUNING (not in GDD) px/s
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.3,  # TUNING (not in GDD) healers value the cheap drones little
		"formation": "back",  # Over the army: inside the Bone Ring with the support classes.
		"capacity_bonus_mult": 0.6,  # TUNING (not in GDD) a swarm (like the Bone Hounds)
		"flies": true,  # Owner-approved proposal: "cannot be body-blocked" (SummonedUnit.flies)
		"behavior": "hover",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"dart_count": 1,  # Darts per attack (the Wraith Drone fires 3).
			"dart_spread": 0.0,  # Rad between two darts of one attack.
			"dart_pierce": 0,  # Extra foes a dart passes through (beyond the level rows' pierce).
			"hover_lift": 15.0,  # TUNING (not in GDD) px the body hovers above its shadow (drawing only)
		},
	},
	# --- Act III: the Iron Citadel ---
	# Iron Revenant (owner-approved proposal "the finale's reward, from Deus Ex
	# Machina"; GDD §15.0 "Iron Revenant, Deus Revenant and Recoil Frame"): one of
	# the Empire's war walkers, reanimated, its plating bound with bone and soul
	# fire. The army's heavy gunner: it holds a back post inside the Bone Ring
	# (formation "back", like the Corpse Catapult) and lays down suppressive fire
	# that slows what it hits (attack_profile "suppress", released by
	# RevenantBehavior). Unlockable (UnlockData), then offered on every stage.
	"iron_revenant": {
		"display_name": "Iron Revenant",  # Owner-approved proposal
		"plural": "Iron Revenants",
		"description": "A reanimated war walker that holds the ring's heart and lays down slowing suppressive fire.",  # Card text: one short sentence (owner rule).
		"max_hp": 170.0,  # TUNING (not in GDD) a war walker's frame (Catapult 90, Abomination 260)
		"damage": 6.0,  # TUNING (not in GDD) per shell (3 shells a burst)
		"attack_interval": 1.7,  # TUNING (not in GDD) s between bursts
		"attack_range": 270.0,  # TUNING (not in GDD) centre-to-edge (px): reaches past the ring
		"move_speed": 56.0,  # TUNING (not in GDD) px/s; a heavy walker
		"radius": 15.0,  # TUNING (not in GDD)
		"acquisition_range": 330.0,  # TUNING (not in GDD) px
		"replenish_interval": 20.0,  # TUNING (not in GDD) s; slow to rebuild
		"band_min": 90.0,  # TUNING (not in GDD) px
		"band_max": 130.0,  # TUNING (not in GDD)
		"w_pursuit": 0.3,  # TUNING (not in GDD)
		"w_formation": 0.7,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.1,  # TUNING (not in GDD) holds its ground like the Archers
		"attack_profile": "suppress",
		"target_profile": "ranged",
		"windup": 0.3,  # TUNING (not in GDD) s the cannon swings round
		"projectile_speed": 560.0,  # TUNING (not in GDD) px/s shells
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.7,  # TUNING (not in GDD)
		"formation": "back",  # Owner-approved proposal: "It holds a back post on the Bone Ring"
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2
		"behavior": "suppress",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"shells": 3,  # TUNING (not in GDD) shells per burst
			"shell_spread": 0.07,  # TUNING (not in GDD) rad between two shells
			"slow": 0.3,  # Owner-approved proposal "suppressive fire that slows what it hits"; TUNING (not in GDD) 30%
			"slow_duration": 1.2,  # TUNING (not in GDD) s (special_duration lengthens it)
		},
	},
	# --- Act IV: the Asphodel Underworld ---
	# Myrmidon Shade (owner-approved proposal: "the finale's reward: undead
	# hoplites that fight as a three-shield phalanx on the ring"; GDD §15.0
	# "Myrmidon Shades, Legion of Tartarus and Myrmidon Oath"): Achilles' own
	# Myrmidons, dead and bound to the necromancer, in bone-grey bronze with
	# soul-teal eyes. Three to a card, they hold the Bone Ring's outer posts like
	# Warriors (formation "front", they block) and LOCK SHIELDS: a Myrmidon with
	# two more in one chain (each within wall_range px of the next) is in the wall and takes wall_cut less from
	# every hit (MyrmidonBehavior, "shieldwall"); their spear reaches far and
	# runs through a second foe behind the first. No act rule (owner rule:
	# summons work the same everywhere). Unlockable (UnlockData), then offered
	# on every stage.
	"myrmidon_shade": {
		"display_name": "Myrmidon Shade",  # Owner-approved proposal ("the Myrmidon Shades")
		"plural": "Myrmidon Shades",
		"description": "Undead hoplites that hold the ring three shields wide and spear through the foes behind.",  # Card text: one short sentence (owner rule).
		"max_hp": 70.0,  # TUNING (not in GDD) a little sturdier than a Warrior (60): bronze and a big shield
		"damage": 9.0,  # TUNING (not in GDD) per spear thrust (Warrior 10)
		"attack_interval": 1.25,  # TUNING (not in GDD) s
		"attack_range": 30.0,  # TUNING (not in GDD) edge-to-edge reach (px): the spear outreaches a sword (Warrior 22)
		"move_speed": 80.0,  # TUNING (not in GDD) px/s; a steady march (Warrior 85)
		"radius": 10.0,  # TUNING (not in GDD)
		"acquisition_range": 150.0,  # TUNING (not in GDD) px
		"replenish_interval": 7.0,  # TUNING (not in GDD) s (Warrior 5): three come back one by one
		"band_min": 35.0,  # TUNING (not in GDD) px, with the frontline
		"band_max": 85.0,  # TUNING (not in GDD)
		"w_pursuit": 0.8,  # TUNING (not in GDD) a wall pursues less than a Warrior
		"w_formation": 0.5,  # TUNING (not in GDD) and keeps its place more
		"w_separation": 0.6,  # TUNING (not in GDD) shoulder to shoulder
		"w_threat": 0.1,  # TUNING (not in GDD)
		"attack_profile": "melee",
		"target_profile": "guard",
		"windup": 0.22,  # TUNING (not in GDD) s; the spear drawn back
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.9,  # TUNING (not in GDD) healers value the wall
		"block_radius": 12.0,  # TUNING (not in GDD) blocks like a Warrior (px)
		"block_mass": 3.5,  # TUNING (not in GDD) a braced shield (Warrior 3)
		"engaged_speed_mult": 0.6,  # TUNING (not in GDD) touching enemies move at 60%, like a Warrior
		"formation": "front",  # Owner-approved proposal: "a phalanx on the ring"
		"capacity_bonus_mult": 1.0,  # TUNING (not in GDD) Grave Dominion V: +5, like the Warriors
		"behavior": "shieldwall",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"wall_range": 56.0,  # TUNING (not in GDD) px between two Myrmidons' centres to stand in one chain (about two Bone Ring posts; not area-scaled: no _radius suffix)
			"wall_size": 3,  # Owner-approved proposal "a three-shield phalanx": Myrmidons that make a wall
			"wall_cut": 0.3,  # TUNING (not in GDD) share of every hit a Myrmidon in the wall no longer takes
			"pierce_reach": 26.0,  # TUNING (not in GDD) px behind the struck foe the spear runs on (not area-scaled)
			"pierce_fraction": 0.6,  # TUNING (not in GDD) the second foe takes this x the thrust
		},
	},
	# --- Act V: the Road to the Sun ---
	# Bound Oni (owner-approved proposal: "Finale summon class: the Oni, bound
	# oni brutes with kanabō (a heavy blocker with a stun smash)"; GDD §15.0 "The
	# Bound Oni, the Oni Lord and Oni's Resolve"; id "bound_oni", so its stats and
	# art never meet the enemy kind "oni"): an oni of the old stories, chained in
	# bone and bound to the necromancer, soul-teal eyes. A heavy blocker on the
	# Bone Ring's front posts (formation "front", it blocks like the
	# Abomination) whose KANABŌ SMASH (OniBehavior, "kanabo") brings the iron
	# club down in front of it: every foe in the circle is struck and STUNNED
	# (CombatResolver.stun_enemy(): bosses and minibosses a quarter, elites
	# half). No act rule (owner rule: summons work the same everywhere).
	# Unlockable (UnlockData), then offered on every stage.
	"bound_oni": {
		"display_name": "Bound Oni",  # Owner-approved proposal ("the Oni, bound oni brutes")
		"plural": "Bound Oni",
		"description": "Chained oni brutes that hold the front and stun whatever their iron club lands on.",  # Card text: one short sentence (owner rule).
		"max_hp": 240.0,  # TUNING (not in GDD) a heavy (Abomination 260)
		"damage": 18.0,  # TUNING (not in GDD) a kanabō blow (Abomination 16)
		"attack_interval": 1.7,  # TUNING (not in GDD) s
		"attack_range": 18.0,  # TUNING (not in GDD) edge-to-edge reach (px): the long club
		"move_speed": 64.0,  # TUNING (not in GDD) px/s, a heavy's pace (Abomination 62)
		"radius": 15.0,  # TUNING (not in GDD) px
		"acquisition_range": 140.0,  # TUNING (not in GDD) px
		"replenish_interval": 18.0,  # TUNING (not in GDD) s, slow to rebuild (Abomination 20)
		"band_min": 45.0,  # TUNING (not in GDD) px, with the front
		"band_max": 95.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.4,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.0,  # TUNING (not in GDD) a brute never shies away
		"attack_profile": "melee",
		"target_profile": "guard",
		"windup": 0.32,  # TUNING (not in GDD) s
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.9,  # TUNING (not in GDD) healers value the brute
		"block_radius": 19.0,  # TUNING (not in GDD) px, blocks like the Abomination
		"block_mass": 7.0,  # TUNING (not in GDD) (Abomination 8)
		"engaged_speed_mult": 0.45,  # TUNING (not in GDD) touching enemies move at 45%
		"formation": "front",  # Owner-approved proposal: "a heavy blocker"
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2, like the Abominations
		"behavior": "kanabo",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"smash_damage": 24.0,  # TUNING (not in GDD) to every foe in the circle
			"smash_radius": 40.0,  # TUNING (not in GDD) px of the circle in front of it
			"smash_cooldown": 5.5,  # TUNING (not in GDD) s
			"smash_windup": 0.5,  # TUNING (not in GDD) s the club is raised (the circle telegraphed)
			"smash_recover": 0.3,  # TUNING (not in GDD) s it stands after the blow
			"smash_stun_duration": 1.0,  # Owner-approved proposal "a stun smash"; TUNING (not in GDD) s (special_duration lengthens it)
			"smash_trigger": 26.0,  # TUNING (not in GDD) px edge to edge: it smashes when a foe is this close
		},
	},
	# --- Act VI: Pandemonium ---
	# Archfiend (owner-approved proposal: "the finale's Archfiend (a winged heavy
	# demon; evolution Prince of Hell)"; GDD §15.0 "The Archfiend, the Prince of
	# Hell and Crown of Horns"): a horned demon with bat wings, bound to the
	# necromancer in undeath (ashen grey-violet skin, soul-teal eyes, a bone
	# collar), a huge black cleaver. A heavy blocker on the Bone Ring's front
	# posts (formation "front", it blocks like the Abomination) whose HELLFIRE
	# CLEAVE (ArchfiendBehavior, "hellfire") sweeps a wide arc in front of it,
	# knocking every foe in it back. Winged, but it fights on the ground (it is
	# no flier: summons never get act-only rules, and the Gargoyle keeps the
	# air). Unlockable (UnlockData), then offered on every stage.
	"archfiend": {
		"display_name": "Archfiend",  # Owner-approved proposal
		"plural": "Archfiends",
		"description": "Winged demons bound in undeath that hold the front and cleave whole ranks aside.",  # Card text: one short sentence (owner rule).
		"max_hp": 250.0,  # TUNING (not in GDD) a heavy (Bound Oni 240, Abomination 260)
		"damage": 19.0,  # TUNING (not in GDD) a cleaver blow (Bound Oni 18)
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 18.0,  # TUNING (not in GDD) edge-to-edge reach (px): the long cleaver
		"move_speed": 70.0,  # TUNING (not in GDD) px/s, a heavy that half-flies (Bound Oni 64)
		"radius": 15.0,  # TUNING (not in GDD) px
		"acquisition_range": 150.0,  # TUNING (not in GDD) px
		"replenish_interval": 18.0,  # TUNING (not in GDD) s, slow to rebuild (Bound Oni 18)
		"band_min": 45.0,  # TUNING (not in GDD) px, with the front
		"band_max": 95.0,  # TUNING (not in GDD)
		"w_pursuit": 1.0,  # TUNING (not in GDD)
		"w_formation": 0.4,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.0,  # TUNING (not in GDD) a demon never shies away
		"attack_profile": "melee",
		"target_profile": "guard",
		"windup": 0.3,  # TUNING (not in GDD) s
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.9,  # TUNING (not in GDD) healers value the heavy
		"block_radius": 19.0,  # TUNING (not in GDD) px, blocks like the Abomination
		"block_mass": 7.0,  # TUNING (not in GDD) (Bound Oni 7)
		"engaged_speed_mult": 0.45,  # TUNING (not in GDD) touching enemies move at 45%
		"formation": "front",  # Owner-approved proposal: "a winged heavy demon"
		"capacity_bonus_mult": 0.4,  # TUNING (not in GDD) Grave Dominion V: +2, like the Abominations
		"behavior": "hellfire",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"special": {
			"cleave_damage": 22.0,  # TUNING (not in GDD) to every foe in the arc
			"cleave_radius": 46.0,  # TUNING (not in GDD) px of the arc from its centre
			"cleave_arc": 70.0,  # TUNING (not in GDD) degrees each side (the Prince of Hell: 180, a full circle)
			"cleave_cooldown": 5.0,  # TUNING (not in GDD) s
			"cleave_windup": 0.4,  # TUNING (not in GDD) s the cleaver is raised (the arc telegraphed)
			"cleave_recover": 0.3,  # TUNING (not in GDD) s it stands after the sweep
			"cleave_knockback": 160.0,  # TUNING (not in GDD) px/s impulse, divided by the foe's mass
			"cleave_trigger": 28.0,  # TUNING (not in GDD) px edge to edge: it cleaves when a foe is this close
		},
	},
}

## Summon-ability progression, one entry per skill level (index 0 = level 1).
## Values are CUMULATIVE totals for that level, not per-level increments.
##   count           — population cap granted by this ability level.
##   hp_bonus        — +% max HP from skill levels (0.15 = +15%).
##   damage_bonus    — +% damage from skill levels.
##   speed_bonus     — +% attack speed from skill levels.
##   splash_bonus    — +% splash radius (mage).
##   heal_bonus      — +% heal per cast (Mender, Bishop aura heal too).
##   pierce          — extra enemies an arrow passes through (archer).
##   shield_bonus    — +% ward and ally-barrier strength (Warder, Bishop).
##   special_bonus   — +% damage of the class special (stomp, dash + bleed,
##                     swoop).
##   special_area    — +% radius / length of the class special.
##   special_haste   — special cooldown divided by (1 + this).
##   special_duration — +% duration of the special's status (bleed, chill,
##                     freeze).
## A class may have fewer than 5 rows: the Profane Bishop has ONE row (it is
## created at its final strength); HordeDirector.level_row() clamps.
const LEVELS := {
	# GDD §34 example Skeleton Warrior L1–L5 (2, +1 +10% dmg, +2 +15% HP,
	# +1 +20% attack speed, +2 +20% HP = 8 total).
	"warrior": [
		{"count": 2, "hp_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0},
		{"count": 3, "hp_bonus": 0.0, "damage_bonus": 0.10, "speed_bonus": 0.0},
		{"count": 5, "hp_bonus": 0.15, "damage_bonus": 0.10, "speed_bonus": 0.0},
		{"count": 6, "hp_bonus": 0.15, "damage_bonus": 0.10, "speed_bonus": 0.20},
		{"count": 8, "hp_bonus": 0.35, "damage_bonus": 0.10, "speed_bonus": 0.20},
	],
	# L1 count 1 is GDD §23; the rest is TUNING (not in GDD), aimed at the
	# §42 sandbox composition of 5 archers.
	"archer": [
		{"count": 1, "damage_bonus": 0.0, "speed_bonus": 0.0, "pierce": 0},
		{"count": 2, "damage_bonus": 0.0, "speed_bonus": 0.0, "pierce": 0},
		{"count": 3, "damage_bonus": 0.15, "speed_bonus": 0.0, "pierce": 0},
		{"count": 4, "damage_bonus": 0.15, "speed_bonus": 0.0, "pierce": 1},
		{"count": 5, "damage_bonus": 0.15, "speed_bonus": 0.20, "pierce": 1},
	],
	# L1 count 1 is GDD §23; the rest is TUNING (not in GDD), aimed at the
	# §42 sandbox composition of 3 mages.
	"mage": [
		{"count": 1, "damage_bonus": 0.0, "splash_bonus": 0.0},
		{"count": 2, "damage_bonus": 0.0, "splash_bonus": 0.0},
		{"count": 2, "damage_bonus": 0.0, "splash_bonus": 0.30},
		{"count": 3, "damage_bonus": 0.0, "splash_bonus": 0.30},
		{"count": 3, "damage_bonus": 0.30, "splash_bonus": 0.50},
	],
	# Grave Mender: the old priest table's count / heal / HP rows (L1 count 1
	# is GDD §23; the rest is TUNING (not in GDD), §42 sandbox of 2 priests).
	# The priest's L5 ward bonus moved to the Warder; L5 casts faster instead.
	"mender": [
		{"count": 1, "heal_bonus": 0.0, "hp_bonus": 0.0},
		{"count": 1, "heal_bonus": 0.25, "hp_bonus": 0.0},
		{"count": 2, "heal_bonus": 0.25, "hp_bonus": 0.0},
		{"count": 2, "heal_bonus": 0.50, "hp_bonus": 0.20},
		{"count": 2, "heal_bonus": 0.50, "hp_bonus": 0.20, "speed_bonus": 0.25},  # TUNING (not in GDD)
	],
	# Crypt Warder: same count / HP rhythm as the Mender; the ward and ally
	# barrier grow instead of the heal. TUNING (not in GDD).
	"warder": [
		{"count": 1, "shield_bonus": 0.0, "hp_bonus": 0.0},
		{"count": 1, "shield_bonus": 0.25, "hp_bonus": 0.0},
		{"count": 2, "shield_bonus": 0.25, "hp_bonus": 0.0},
		{"count": 2, "shield_bonus": 0.50, "hp_bonus": 0.20},
		{"count": 2, "shield_bonus": 0.80, "hp_bonus": 0.20},
	],
	# Profane Bishop: one row, the strength it is created at. Count 3 replaces
	# the 2 + 2 Menders and Warders it merges (decision recorded in GDD §15.0);
	# global capacity bonuses then apply once instead of twice. TUNING (not in GDD).
	"bishop": [
		{"count": 3, "heal_bonus": 0.50, "hp_bonus": 0.20, "shield_bonus": 0.80, "speed_bonus": 0.20},
	],
	# TUNING (not in GDD): low population, 1 -> 3 (user request), each level
	# adds bulk or a bigger stomp.
	"abomination": [
		{"count": 1},
		{"count": 1, "hp_bonus": 0.20, "special_bonus": 0.25},
		{"count": 2, "hp_bonus": 0.20, "special_bonus": 0.25},
		{"count": 2, "hp_bonus": 0.40, "special_bonus": 0.25, "special_area": 0.20},
		{"count": 3, "hp_bonus": 0.40, "damage_bonus": 0.20, "special_bonus": 0.50, "special_area": 0.20},
	],
	# TUNING (not in GDD): 1 -> 4 rogues; harder dashes, then faster ones.
	"rogue": [
		{"count": 1},
		{"count": 2},
		{"count": 2, "special_bonus": 0.30, "special_duration": 0.30},
		{"count": 3, "damage_bonus": 0.20, "special_bonus": 0.30, "special_duration": 0.30},
		{"count": 4, "damage_bonus": 0.20, "special_bonus": 0.30, "special_duration": 0.30, "special_haste": 0.25},
	],
	# TUNING (not in GDD): 1 -> 3 gargoyles; bigger, harder, more frequent swoops.
	"gargoyle": [
		{"count": 1},
		{"count": 2},
		{"count": 2, "hp_bonus": 0.25, "special_bonus": 0.25},
		{"count": 3, "hp_bonus": 0.25, "special_bonus": 0.25, "special_area": 0.20},
		{"count": 3, "hp_bonus": 0.25, "damage_bonus": 0.25, "special_bonus": 0.50, "special_area": 0.20, "special_haste": 0.20},
	],
	# TUNING (not in GDD): 1 -> 3 wraiths; wider, longer, then more frequent freezes.
	"frost_wraith": [
		{"count": 1},
		{"count": 1, "damage_bonus": 0.25, "special_area": 0.15},
		{"count": 2, "damage_bonus": 0.25, "special_area": 0.15},
		{"count": 2, "damage_bonus": 0.25, "special_area": 0.15, "special_duration": 0.25},
		{"count": 3, "damage_bonus": 0.25, "special_area": 0.15, "special_duration": 0.25, "special_haste": 0.25},
	],
	# TUNING (not in GDD): 3 -> 9 hounds (owner brief: more capacity per level
	# than any other class); harder, then faster bites.
	"bone_hound": [
		{"count": 3},
		{"count": 4},
		{"count": 5, "damage_bonus": 0.15},
		{"count": 7, "damage_bonus": 0.15, "hp_bonus": 0.15},
		{"count": 9, "damage_bonus": 0.25, "hp_bonus": 0.15, "speed_bonus": 0.15},
	],
	# TUNING (not in GDD): 1 -> 3 banshees; a wider, longer, then more frequent Dirge.
	"banshee": [
		{"count": 1},
		{"count": 1, "special_area": 0.15},
		{"count": 2, "special_area": 0.15},
		{"count": 2, "special_area": 0.15, "special_duration": 0.25},
		{"count": 3, "damage_bonus": 0.2, "special_area": 0.25, "special_duration": 0.25, "special_haste": 0.2},
	],
	# TUNING (not in GDD): 1 -> 3 catapults; heavier, then wider boulders.
	"corpse_catapult": [
		{"count": 1},
		{"count": 1, "damage_bonus": 0.2},
		{"count": 2, "damage_bonus": 0.2, "splash_bonus": 0.15},
		{"count": 2, "damage_bonus": 0.35, "splash_bonus": 0.15, "hp_bonus": 0.2},
		{"count": 3, "damage_bonus": 0.35, "splash_bonus": 0.3, "hp_bonus": 0.2, "speed_bonus": 0.15},
	],
	# --- Act II: Fallen Seraph ---
	# TUNING (not in GDD): 1 -> 3 seraphs; harder dives, a wider ring, then more frequent dives.
	"fallen_seraph": [
		{"count": 1},
		{"count": 1, "special_bonus": 0.2},
		{"count": 2, "special_bonus": 0.2},
		{"count": 2, "special_bonus": 0.2, "special_area": 0.15},
		{"count": 3, "damage_bonus": 0.2, "special_bonus": 0.4, "special_area": 0.15, "special_haste": 0.2},
	],
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# TUNING (not in GDD): 1 -> 3 spawns; harder squeezes, then longer and
	# more frequent grasps.
	"spawn_of_the_deep": [
		{"count": 1},
		{"count": 1, "special_bonus": 0.2},
		{"count": 2, "special_bonus": 0.2, "hp_bonus": 0.2},
		{"count": 2, "damage_bonus": 0.2, "special_bonus": 0.2, "hp_bonus": 0.2, "special_duration": 0.25},
		{"count": 3, "damage_bonus": 0.2, "special_bonus": 0.4, "hp_bonus": 0.2, "special_duration": 0.25, "special_haste": 0.2},
	],
	# --- Content wave 2: Bone Golem ---
	# TUNING (not in GDD): 1 -> 2 golems (owner-approved proposal: 2 at Lv 5);
	# more bulk and a wider slam, then longer and more frequent Bulwarks.
	"bone_golem": [
		{"count": 1},
		{"count": 1, "hp_bonus": 0.15, "damage_bonus": 0.10},
		{"count": 1, "hp_bonus": 0.15, "damage_bonus": 0.20, "special_area": 0.15},
		{"count": 1, "hp_bonus": 0.30, "damage_bonus": 0.20, "special_area": 0.15, "special_duration": 0.15},
		{"count": 2, "hp_bonus": 0.30, "damage_bonus": 0.30, "special_area": 0.25, "special_duration": 0.15, "special_haste": 0.2},
	],
	# --- Act III: the Assembly Halls ---
	# TUNING (not in GDD): three to a card (owner-approved proposal), 3 -> 6
	# drones, harder darts, then faster and piercing at Lv 5.
	"grave_drone": [
		{"count": 3},
		{"count": 4, "damage_bonus": 0.10},
		{"count": 4, "damage_bonus": 0.20, "hp_bonus": 0.15},
		{"count": 5, "damage_bonus": 0.25, "hp_bonus": 0.15, "speed_bonus": 0.10},
		{"count": 6, "damage_bonus": 0.35, "hp_bonus": 0.25, "speed_bonus": 0.15, "pierce": 1},
	],
	# --- Act III: the Iron Citadel ---
	# TUNING (not in GDD): 1 -> 3 revenants; harder shells, then longer slows
	# and faster bursts.
	"iron_revenant": [
		{"count": 1},
		{"count": 1, "damage_bonus": 0.2},
		{"count": 2, "damage_bonus": 0.2, "hp_bonus": 0.2},
		{"count": 2, "damage_bonus": 0.35, "hp_bonus": 0.2, "special_duration": 0.3},
		{"count": 3, "damage_bonus": 0.35, "hp_bonus": 0.2, "special_duration": 0.3, "speed_bonus": 0.15},
	],
	# --- Act IV: the Asphodel Underworld ---
	# TUNING (not in GDD): three to a card (owner-approved "a three-shield
	# phalanx"), 3 -> 6 Myrmidons; then sturdier walls and harder spears.
	"myrmidon_shade": [
		{"count": 3},
		{"count": 3, "damage_bonus": 0.15, "hp_bonus": 0.1},
		{"count": 4, "damage_bonus": 0.2, "hp_bonus": 0.2},
		{"count": 5, "damage_bonus": 0.3, "hp_bonus": 0.25},
		{"count": 6, "damage_bonus": 0.4, "hp_bonus": 0.3, "speed_bonus": 0.1},
	],
	# --- Act V: the Road to the Sun ---
	# TUNING (not in GDD): one brute to a card (a heavy), 1 -> 3 Bound Oni; then
	# harder, wider smashes and longer stuns.
	"bound_oni": [
		{"count": 1},
		{"count": 1, "hp_bonus": 0.2, "special_bonus": 0.25},
		{"count": 2, "hp_bonus": 0.2, "special_bonus": 0.25, "special_duration": 0.2},
		{"count": 2, "hp_bonus": 0.4, "special_bonus": 0.35, "special_area": 0.2, "special_duration": 0.2},
		{"count": 3, "hp_bonus": 0.4, "damage_bonus": 0.2, "special_bonus": 0.5, "special_area": 0.2, "special_duration": 0.3},
	],
	# --- Act VI: Pandemonium ---
	# TUNING (not in GDD): one demon to a card (a heavy), 1 -> 3 Archfiends;
	# then harder, wider and quicker cleaves.
	"archfiend": [
		{"count": 1},
		{"count": 1, "hp_bonus": 0.2, "special_bonus": 0.25},
		{"count": 2, "hp_bonus": 0.2, "special_bonus": 0.25, "special_haste": 0.1},
		{"count": 2, "hp_bonus": 0.4, "special_bonus": 0.35, "special_area": 0.2, "special_haste": 0.1},
		{"count": 3, "hp_bonus": 0.4, "damage_bonus": 0.2, "special_bonus": 0.5, "special_area": 0.2, "special_haste": 0.2},
	],
}

## Ally-barrier targeting (Warder / Profane Bishop, SummonAbilities):
## an ally counts as "threatened" if it was hit within this many seconds ...
const ALLY_WARD_HIT_WINDOW: float = 2.0  # TUNING (not in GDD)
## ... or it is a blocker (warrior) fighting in melee right now. An ally
## whose barrier is still above this fraction of the new barrier is skipped.
const ALLY_WARD_REFRESH_FRACTION: float = 0.5  # TUNING (not in GDD)
## Ally-barrier score weights: missing barrier, missing HP, role priority.
const ALLY_WARD_W_BARRIER: float = 0.5  # TUNING (not in GDD)
## Weight of the ally's missing HP fraction in the barrier score.
const ALLY_WARD_W_HURT: float = 0.3  # TUNING (not in GDD)
## Weight of the ally's heal_role_priority in the barrier score.
const ALLY_WARD_W_ROLE: float = 0.2  # TUNING (not in GDD)

## Target-scoring weights per target_profile (GDD §27):
## score = distance*Wd + threat_to_player*Wt + role_priority*Wr
##       + tactical*Wv (+ cluster*Wc for mages) - overkill*Wo
## All constituent measures are normalised to 0..1 before weighting.
const TARGET_WEIGHTS := {
	# Warriors: enemies attacking the player / close intruders first.
	"guard": {"distance": 1.0, "threat": 1.4, "role": 0.3, "tactical": 0.4, "cluster": 0.0, "overkill": 0.5},  # TUNING (not in GDD)
	# Archers: exposed healers / casters, finishable enemies.
	"ranged": {"distance": 0.4, "threat": 0.6, "role": 1.2, "tactical": 0.6, "cluster": 0.0, "overkill": 2.0},  # TUNING (not in GDD)
	# Mages: biggest valuable cluster near the player.
	"cluster": {"distance": 0.3, "threat": 0.6, "role": 0.6, "tactical": 0.0, "cluster": 1.5, "overkill": 1.0},  # TUNING (not in GDD)
	# Support classes (Mender, Warder, Bishop) offensive fallback: nearest threat.
	"support": {"distance": 1.0, "threat": 0.8, "role": 0.2, "tactical": 0.0, "cluster": 0.0, "overkill": 2.0},  # TUNING (not in GDD)
	# Rogues: backline healers / archers first, wherever they are (the
	# RogueBehavior adds a backline and far-from-player bonus).
	"assassin": {"distance": 0.4, "threat": 0.2, "role": 1.6, "tactical": 0.0, "cluster": 0.0, "overkill": 1.0},  # TUNING (not in GDD)
	# Gargoyles: threats near the player, clusters while a swoop is ready
	# (GargoyleBehavior cluster bonus).
	"skirmisher": {"distance": 0.8, "threat": 1.0, "role": 0.4, "tactical": 0.0, "cluster": 0.0, "overkill": 0.6},  # TUNING (not in GDD)
	# Frost Wraiths: enemies closing on the player, unchilled ones first
	# (FrostWraithBehavior bonus), never wasted on doomed targets.
	"frost": {"distance": 0.5, "threat": 1.2, "role": 0.5, "tactical": 0.0, "cluster": 0.0, "overkill": 2.0},  # TUNING (not in GDD)
	# Bone Hounds: backline prey at the edge of the crowd and the pack's
	# shared target (BoneHoundBehavior backline / edge / focus bonuses).
	"pack": {"distance": 0.6, "threat": 0.7, "role": 0.6, "tactical": 0.0, "cluster": 0.0, "overkill": 0.8},  # TUNING (not in GDD) role was 1.0, threat 0.4 (the pack ran too deep)
	# Banshees: crowds closing on the player, unweakened ones first
	# (BansheeBehavior bonus).
	"dirge": {"distance": 0.5, "threat": 1.2, "role": 0.4, "tactical": 0.0, "cluster": 0.0, "overkill": 2.0},  # TUNING (not in GDD)
	# Corpse Catapults: the densest pack (cluster value inside the boulder's
	# splash), structures / elites / minibosses first (CatapultBehavior bonus).
	"siege": {"distance": 0.2, "threat": 0.4, "role": 0.4, "tactical": 0.0, "cluster": 1.4, "overkill": 1.5},  # TUNING (not in GDD)
	# --- Act II: Fallen Seraph ---
	# Fallen Seraphs: feather blades at foes closing on the necromancer, never
	# wasted on doomed targets; the dive picks its own pack (SeraphBehavior).
	"seraph": {"distance": 0.6, "threat": 1.1, "role": 0.4, "tactical": 0.0, "cluster": 0.0, "overkill": 2.0},  # TUNING (not in GDD)
	# --- Content wave 2: Bone Golem ---
	# Bone Golems: the nearest foes first (it is too slow to chase), threats to
	# the necromancer second. Not "guard": the guard profile only looks near a
	# necromancer in danger, which left the slow anchor idle at its post (first
	# forced test: 106 slams in a run, 60% of its time without a target).
	"fortress": {"distance": 1.6, "threat": 0.8, "role": 0.2, "tactical": 0.0, "cluster": 0.0, "overkill": 0.5},  # TUNING (not in GDD)
}

# --- Leash / lifecycle (GDD §24) ---------------------------------------------

## Engagement zone radius around the player (px).
const ENGAGE_RADIUS: float = 220.0  # GDD §24
## Beyond this distance from the player a unit drops its target and RETURNs.
const SOFT_RECALL: float = 320.0  # GDD §24
## Beyond this distance a unit is spectrally teleported back (should be rare).
const HARD_RECALL: float = 650.0  # GDD §24
## Stall recall: a unit that is RETURNING (or FOLLOWING more than
## STALL_MIN_GAP px from its formation spot) but moves less than
## STALL_DISTANCE px in STALL_TIME s is wedged (e.g. between an obstacle and a
## Covenant structure, where the push-out and the structure's push cancel) and
## gets the hard recall's teleport back to its spot. Moving units cover
## ~100 px/s, so it never fires on a unit that is merely slow.
const STALL_TIME: float = 3.0  # TUNING (not in GDD) s, playtest fix (Oct 2026)
## Movement (px) that restarts the stall window.
const STALL_DISTANCE: float = 12.0  # TUNING (not in GDD)
## A FOLLOWING unit closer than this (px) to its formation spot is not trying to move.
const STALL_MIN_GAP: float = 48.0  # TUNING (not in GDD)
## Minimum spawn distance from the player (px).
const SPAWN_MIN: float = 35.0  # GDD §24
## Maximum spawn distance from the player (px).
const SPAWN_MAX: float = 80.0  # GDD §24
## Spawn-point attempts per frame before giving up (timer is NOT consumed).
const SPAWN_RETRIES: int = 6  # TUNING (not in GDD)
## Duration of the "rise from the grave" emergence animation (s).
const SPAWN_DURATION: float = 0.5  # TUNING (not in GDD)
## RETURNING -> FOLLOWING once within band_max + this margin of the player.
const RETURN_ARRIVE_MARGIN: float = 30.0  # TUNING (not in GDD)

# --- Update rates (GDD §25) -----------------------------------------------------

## AI decisions run every Nth physics tick: 60 Hz / 12 = 5 Hz, and units are
## spread round-robin over the 12 slots so work never spikes on one frame.
const AI_TICK_DIVISOR: int = 12  # GDD §25 (5 Hz)
## Formation anchors recomputed every Nth physics tick: 60 / 15 = 4 Hz.
const FORMATION_TICK_DIVISOR: int = 15  # GDD §25 (4 Hz)
## Player threat evaluation every Nth physics tick: 60 / 12 = 5 Hz.
const THREAT_TICK_DIVISOR: int = 12  # GDD §25 (5 Hz)

# --- Targeting (GDD §27–§31) -------------------------------------------------

## Minimum time (s) a unit keeps a valid target before reconsidering.
const TARGET_COMMIT_TIME: float = 1.0  # GDD §27
## Score margin a new target must beat the current one by to cause an early
## switch ("significantly greater threat").
const SWITCH_MARGIN: float = 0.35  # TUNING (not in GDD)
## Distance (px) used to normalise "threat to player" (0 at this distance).
const THREAT_NORM_DISTANCE: float = 200.0  # TUNING (not in GDD)
## Warriors intercept enemies within this distance of the player when the
## player is in danger, ignoring farther targets.
const WARRIOR_INTERCEPT_RADIUS: float = 80.0  # GDD §28
## Mages evaluate at most this many candidate impact points per decision.
const MAGE_MAX_CANDIDATES: int = 16  # TUNING (not in GDD)
## Enemy count inside a splash that counts as a "full" cluster (score 1.0).
const MAGE_CLUSTER_NORM: float = 6.0  # TUNING (not in GDD)
## Extra edge tolerance (px) for a melee swing to still connect after windup.
const MELEE_TOLERANCE: float = 10.0  # TUNING (not in GDD)
## How long (s) an archer kites before firing again.
const KITE_DURATION: float = 0.5  # TUNING (not in GDD)
## Cooldown (s) between kites so archers "otherwise keep firing" (GDD §29).
const KITE_COOLDOWN: float = 1.2  # TUNING (not in GDD)

## Heal score weights (Mender, Bishop) (GDD §31):
## 0.6*missing_fraction + 0.2*normalised_missing_raw + 0.2*role_priority.
const HEAL_W_MISSING_FRACTION: float = 0.6  # GDD §31
## Weight of normalised raw missing HP.
const HEAL_W_MISSING_RAW: float = 0.2  # GDD §31
## Weight of tactical role priority.
const HEAL_W_ROLE: float = 0.2  # GDD §31
## Raw missing HP that normalises to 1.0.
const HEAL_MISSING_RAW_NORM: float = 60.0  # TUNING (not in GDD)
## Allies under this HP fraction are "critical" (GDD §27: below 35% HP).
const HEAL_CRITICAL_FRACTION: float = 0.35  # GDD §27
## Extra score for critical allies so they always win over chip damage.
const HEAL_CRITICAL_BONUS: float = 0.5  # TUNING (not in GDD)
## Tactical role priority of the necromancer as a heal target (healers may
## always heal the player, per the user brief overriding GDD §27's "if skill
## allows").
const PLAYER_HEAL_ROLE: float = 1.0  # TUNING (not in GDD)
## Extra score when the necromancer is critical (< HEAL_CRITICAL_FRACTION) so
## a critical necromancer has top priority (GDD §31).
const PLAYER_CRITICAL_BONUS: float = 1.0  # TUNING (not in GDD)
## Warders and Bishops consider a ward when the player was hit within this many seconds
## (or is flagged "in danger").
const SHIELD_TRIGGER_WINDOW: float = 1.5  # TUNING (not in GDD)
## The necromancer also counts as "under threat" (ward-worthy) while any enemy
## is within this many px of him.
const WARD_THREAT_RADIUS: float = 90.0  # TUNING (not in GDD)
## Max radius (px) of any summon body (and of the warriors' blocker), used to
## size enemy-vs-summon queries. A wider blocker (the Corpse Abomination's
## 20 px block radius) raises HordeDirector.block_query_radius instead, only
## once one has been spawned, so runs without it pay nothing extra.
## 19 = the Bone Colossus body (SummonEvolutionData; it was 16, the Abomination
## body). Every query using it filters by exact distance afterwards, so a
## larger pad only stops bigger bodies being missed; results are otherwise
## unchanged.
const MAX_BLOCK_RADIUS: float = 19.0  # TUNING (not in GDD) was 16; the Bone Colossus body

# --- Coordination / steering ----------------------------------------------------

## Radius (px) around the player scanned for threats.
const THREAT_RADIUS: float = 160.0  # TUNING (not in GDD)
## Radius (px) in which enemies count as "immediate melee" danger.
const DANGER_RADIUS: float = 80.0  # TUNING (not in GDD)
## Enemies inside DANGER_RADIUS that flag the player as "in danger".
const DANGER_COUNT: int = 4  # TUNING (not in GDD)
## Player HP fraction under which the player is always "in danger".
const DANGER_HP_FRACTION: float = 0.35  # TUNING (not in GDD)
## Max random angular offset (radians) per unit slot (non-rigid formation).
const FORMATION_JITTER_ANGLE: float = 0.35  # TUNING (not in GDD)
## Speed multiplier while FOLLOWING but far (> CATCHUP_DISTANCE) from anchor.
const CATCHUP_SPEED_MULT: float = 1.35  # TUNING (not in GDD)
## Distance (px) from anchor at which catch-up speed kicks in.
const CATCHUP_DISTANCE: float = 60.0  # TUNING (not in GDD)
## Speed multiplier while RETURNING to the army.
const RETURN_SPEED_MULT: float = 1.5  # TUNING (not in GDD)
## Steering acceleration as a multiple of move speed per second.
const STEER_ACCEL: float = 8.0  # TUNING (not in GDD)
## Extra spacing (px) kept between allies on top of their radii.
const SEPARATION_PADDING: float = 4.0  # TUNING (not in GDD)
## Multiplier on every class's formation band (band_min / band_max) so the
## army spreads out enough for its 44-88 px sprites to stay readable
## (the GDD §26 bands were sized for small placeholder shapes).
const FORMATION_SPREAD: float = 1.3  # TUNING (not in GDD) user decision: wider spacing for sprite art
## Multiplier on the ally separation distance (sum of the two radii) for the
## same reason; the padding below the radii is unchanged.
const SEPARATION_SPREAD: float = 1.3  # TUNING (not in GDD) user decision: wider spacing for sprite art
## Radius (px) scanned for threats to avoid (support classes / archers / mages).
const THREAT_AVOID_RADIUS: float = 55.0  # TUNING (not in GDD)
