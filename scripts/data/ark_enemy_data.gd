## ArkEnemyData — immutable design data for the Concord kinds that join on
## the Ark of the Concord (Stage 27) (Act IX, the Concord of Stars; GDD §15.0
## "The Ark of the Concord (Act IX phase 2)"; owner-approved proposal
## docs/act9/PROPOSAL.md "Stage 27: The Ark of the Concord (the finale)").
## EnemyDirector.concord_def() looks these rows up after ConcordEnemyData. The
## stage's own kinds (the shared Grey Overseer is a ConcordEnemyData row):
##   luminous_archon — THE MINIBOSS: a being of pure light (male, as the Lumen
##                     Sentinel but larger, in white-gold crystal) whose every
##                     attack is a beam to reflect (ConcordBeams.fire() with
##                     the boss override: a fan of lances and a halo of
##                     beams); a lumen_shield of its health. ArkDirector sends
##                     it (the "luminous_archon" event).
##   specimen_tank   — a STRUCTURE of the Specimen Vaults: a sealed tank with a
##                     captured beast inside. ArkDirector raises them near the
##                     necromancer in the Vaults; broken, it frees `beasts`
##                     vault beasts (SpecimenTankKit).
##   vault_beast     — a FREED BEAST (a creature): an enemy that attacks
##                     everyone: the army and the necromancer as every enemy
##                     does, and the Concord's kinds near it through
##                     CombatResolver.damage_enemy() with its own source
##                     (VaultBeastKit.prey(): THE ONE CHECK of whom it attacks,
##                     the nearest of summons, the necromancer and Concord
##                     enemies). It never heals on turf.
##   reactor_vent    — a STRUCTURE of the Reactor: a vent that seeds live turf
##                     (Terraforming.seed(), tag "vents") every vent_every s
##                     while it stands; broken, it stops (ReactorVentKit).
##   reap_emitter    — a STRUCTURE of the Harvester's Reaping: a beam emitter
##                     that lifts a summon through Abduction.lift() on a steady
##                     rhythm (ReapEmitterKit; BossHarvester places four).
## Rows have every key of a ConcordEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/concord/<kit>_kit.gd, unique across the Eye,
## Empire, Pantheon, Shogunate, Inferno, Court, City and Concord folders;
## "race", "beam", "abducts", "cloak" and "heals_on_turf" switch the shared
## rules on for the kind). Own keys are documented on each row. The GDD gives
## no numbers: everything is TUNING (not in GDD).
class_name ArkEnemyData
extends RefCounted

## Kind id of the miniboss.
const ARCHON: String = "luminous_archon"
## Kind id of a specimen tank (structure).
const TANK: String = "specimen_tank"
## Kind id of a freed beast.
const BEAST: String = "vault_beast"
## Kind id of a reactor vent (structure).
const VENT: String = "reactor_vent"
## Kind id of a Reaping emitter (structure).
const EMITTER: String = "reap_emitter"
## Damage-source tag of a freed beast's bite on a Concord enemy
## (CombatResolver.damage_enemy(); never a summon or spell source).
const BEAST_SOURCE: String = "vault_beast_bite"

## Kind id -> design row.
const ENEMIES := {
	# THE LUMINOUS ARCHON (the miniboss; owner-approved proposal: "a being of
	# pure light whose every attack is a beam to reflect"; male, as the Lumen
	# Sentinel but larger, in white-gold crystal). It never strikes in melee:
	# every attack is a Concord beam through ConcordBeams.fire() with the boss
	# override (LuminousArchonKit): a FAN of `lance_beams` sweep beams at the
	# necromancer every lance_every s and a HALO of `halo_beams` short beams
	# all round it every halo_every s. Its shield is the existing holy shield
	# (row "lumen_shield"). Orb Shields and barriers send its beams back into
	# it (the shared reflection).
	"luminous_archon": {
		"display_name": "Luminous Archon",  # Owner-approved proposal
		"max_hp": 1800.0,  # TUNING (not in GDD) a miniboss (the Chiropteran King 1,600)
		"move_speed": 38.0,  # TUNING (not in GDD) px/s, it glides
		"damage": 0.0,  # Every attack is a beam.
		"attack_interval": 2.0,  # Unused: its kit fires its beams on its own clocks.
		"attack_range": 230.0,  # TUNING (not in GDD) px it keeps from the necromancer
		"radius": 16.0,  # TUNING (not in GDD) px (~64 px sprite)
		"armor": 0.15,  # TUNING (not in GDD) crystal
		"xp": 60,  # TUNING (not in GDD)
		"behavior": "ranged",  # It hangs back; its kit fires.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1
		"mass": 12.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) a miniboss
		"miniboss": true,  # Its chest (ChestManager) and the HUD bar (LuminousArchonKit registers it).
		"floating": true,  # A being of light: the ground's hazards spare it.
		"faction": "concord",
		"kit": "luminous_archon",
		"race": "luminous",  # Owner: the Luminous are mixed into every stage
		"lumen_shield": 0.25,  # TUNING (not in GDD) brief: "a row in ArkEnemyData with a lumen_shield"
		"first_attack": 2.0,  # TUNING (not in GDD) s before its first lance
		"lance_every": 5.0,  # TUNING (not in GDD) s between two fans of lances (from the fan's start)
		"lance_beams": 3,  # TUNING (not in GDD) sweep beams a fan
		"lance_spread": 0.3,  # TUNING (not in GDD) rad between two lances
		"lance_overrides": {"length": 320.0, "width": 12.0, "dps": 4.0, "sweep": 25.0},  # TUNING (not in GDD) over BEAM_STYLES "sweep"
		"halo_first": 7.0,  # TUNING (not in GDD) s before its first halo
		"halo_every": 13.0,  # TUNING (not in GDD) s between two halos
		"halo_beams": 6,  # TUNING (not in GDD) beams round it
		"halo_overrides": {"length": 210.0, "width": 9.0, "dps": 3.5, "hold": 1.4, "sweep": 40.0},  # TUNING (not in GDD) over BEAM_STYLES "probe"
	},  # The Luminous Archon.
	# A SPECIMEN TANK (a structure of the Specimen Vaults; owner-approved
	# proposal: "break the tanks to free captured beasts that attack
	# everyone"): a sealed tank of green fluid with a beast curled inside.
	# Broken, it frees `beasts` vault beasts where it stood (SpecimenTankKit).
	"specimen_tank": {
		"display_name": "Specimen Tank",
		"max_hp": 120.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 14.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD) glass and steel
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # TUNING (not in GDD) 0..1: the army breaks them on the way
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": "concord",
		"kit": "specimen_tank",
		"race": "harvesters",  # The Harvesters' harvest vault (the report lists it with them).
		"heals_on_turf": false,  # Brief: false for structures
		"beasts": 2,  # TUNING (not in GDD) beasts a broken tank frees
	},  # The specimen tank.
	# A FREED BEAST (a creature, a captured alien grazer-predator: six legs, a
	# rust-red hide, an ochre crest, a pale glowing spine; never violet and
	# bone): an enemy that attacks EVERYONE (VaultBeastKit.prey(), the one
	# check: the nearest of summons, the necromancer and Concord enemies). It
	# fights the army as every enemy does (the shared melee AI); when a
	# Concord enemy is the nearest, it runs at it and bites it through
	# CombatResolver.damage_enemy() (source BEAST_SOURCE, bite_damage x the
	# enemies' HP scaling). It never heals on turf.
	"vault_beast": {
		"display_name": "Freed Beast",
		"max_hp": 46.0,  # TUNING (not in GDD)
		"move_speed": 72.0,  # TUNING (not in GDD) px/s; quick
		"damage": 4.0,  # TUNING (not in GDD) a bite on a summon / the necromancer, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~36 px sprite)
		"armor": 0.0,
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.4,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD)
		"faction": "concord",
		"kit": "vault_beast",
		"race": "",  # Not of the coalition: the Harvesters' captive (the report lists it apart).
		"heals_on_turf": false,  # Brief: freed beasts don't heal on turf
		"prey_reach": 220.0,  # TUNING (not in GDD) px it looks for its nearest prey
		"bite_damage": 9.0,  # TUNING (not in GDD) a bite on a Concord enemy, x EnemyDirector.hp_mult (it must hurt the Concord's scaled health)
	},  # The freed beast.
	# A REACTOR VENT (a structure of the Reactor; brief: "vents that seed turf
	# on a timer. They are structures; breaking one stops it"): every
	# vent_every s it seeds live alien ground vent_radius px round it through
	# Terraforming.seed() (tag "vents"), the Concord's healing ground.
	"reactor_vent": {
		"display_name": "Reactor Vent",
		"max_hp": 160.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 15.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) a grated hull
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1: break the vents
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": "concord",
		"kit": "reactor_vent",
		"race": "harvesters",  # The Harvesters' reactor (the report lists it with them).
		"heals_on_turf": false,  # Brief: false for structures
		"vent_first": 2.0,  # TUNING (not in GDD) s before its first breath
		"vent_every": 9.0,  # TUNING (not in GDD) s between two breaths
		"vent_radius": 110.0,  # TUNING (not in GDD) px of live turf a breath seeds
	},  # The reactor vent.
	# A REAPING EMITTER (a structure of the Harvester's Reaping; owner-approved
	# proposal: "Four beam emitters around the arena must be destroyed before
	# the army is gone"): a gunmetal pylon with a plasma lens. Every
	# HarvesterData lift_every s it picks the nearest liftable summon within
	# lift_range px (Abduction.pick()) and lifts it through Abduction.lift()
	# (THE lift; the summon rises to the emitter). Destroyed, it drops what it
	# holds (the rescue). ReapEmitterKit.
	"reap_emitter": {
		"display_name": "Reaping Emitter",
		"max_hp": 260.0,  # TUNING (not in GDD) x the run's enemy HP scaling at the call
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 15.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1: the army must break them
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": "concord",
		"kit": "reap_emitter",
		"race": "harvesters",  # The Harvester's own machine.
		"heals_on_turf": false,  # Brief: false for structures
	},  # The Reaping emitter.
}
