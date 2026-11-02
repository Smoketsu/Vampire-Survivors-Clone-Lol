## RavensmoorEnemyData — immutable design data for the Court kinds that join on
## Ravensmoor (Stage 19) (Act VII; GDD §15.0 "Act VII foundation (phase 1)" and
## "Ravensmoor (Act VII phase 2)"; owner-approved proposal docs/act7/PROPOSAL.md,
## "Roster" and "Stage 19: Ravensmoor"):
##   old_greymane    — OLD GREYMANE, the stage's miniboss (owner-approved: "the
##                     pack's alpha, who howls the rest of the wolves into beast
##                     form early"): a huge grey wolf-man, always the beast; his
##                     HOWL turns every werewolf near him into the beast at once
##                     and spurs them (OldGreymaneKit); a feeding lunge.
##   sleeping_coffin — a SLEEPING COFFIN (owner-approved: "sealed coffins in
##                     each zone. Break one before the next Blood Moon for a Soul
##                     Ash bounty; leave it and a Vampire Noble climbs out when
##                     the moon turns"): the Court's coffin with one noble inside
##                     (SleepingCoffinKit, a CourtCoffinKit), placed and opened
##                     by RavensmoorDirector.
## The stage's fodder pack, the GHOUL, is a shared kind (CourtEnemyData
## "ghoul", built here). Each kind stays in play on the stages after it, and
## any stage can spawn it (--spawn=kind@T). EnemyDirector.court_def() looks
## these rows up after CourtEnemyData. Rows have every key of a
## CourtEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/court/<kit>_kit.gd, unique across the Eye, Empire, Pantheon,
## Shogunate, Inferno and Court folders; "feeds", "flies", "werebeast",
## "noble" switch the shared rules on for the kind). Kit numbers are row keys
## documented on each row.
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name RavensmoorEnemyData
extends RefCounted

## Kind id of Old Greymane (the stage's miniboss).
const GREYMANE: String = "old_greymane"
## Kind id of a sleeping coffin.
const SLEEPING_COFFIN: String = "sleeping_coffin"
## Damage tag of Old Greymane's lunge.
const GREYMANE_LUNGE_SOURCE: String = "greymane_lunge"

## Kind id -> design row.
const ENEMIES := {
	# Miniboss: Old Greymane, the pack's alpha (OldGreymaneKit). Always the
	# beast. Not a vampire: feeds 0.25 (his heavy bites feed him hard).
	#   howl_first       — s after he arrives of his first howl.
	#   howl_every       — s between two howls.
	#   howl_time        — s he stands howling.
	#   howl_radius      — px: every werewolf within turns and is spurred.
	#   howl_buff_damage — extra share of damage of a spurred werewolf.
	#   howl_buff_speed  — extra share of speed of a spurred werewolf.
	#   howl_buff_time   — s the spur lasts.
	#   lunge_every / lunge_trigger / lunge_min / lunge_windup / lunge_time /
	#   lunge_damage     — his lunge (as the werewolf beast's keys).
	#   advance_range / advance_speed_mult — the forced march.
	#   reward_xp / reward_crystals — his XP burst.
	"old_greymane": {
		"display_name": "Old Greymane",
		"max_hp": 2200.0,  # TUNING (not in GDD) a miniboss (the Gatekeeper 2,300)
		"move_speed": 62.0,  # TUNING (not in GDD) px/s; the alpha runs ahead of his pack
		"damage": 13.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px; bigger than a beast (20)
		"armor": 0.15,  # TUNING (not in GDD) a hide of old scars
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the alpha first
		"mass": 9.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss (the Gatekeeper's)
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": CourtEnemyData.FACTION,
		"kit": "old_greymane",
		"feeds": 0.25,  # Owner-approved (Oct 31, 2026): not a vampire: 25%
		"werebeast": true,  # A werewolf: Silver Bones' damage hook reads it (he is always the beast).
		"howl_first": 3.0,  # TUNING (not in GDD) s
		"howl_every": 14.0,  # TUNING (not in GDD) s
		"howl_time": 0.9,  # TUNING (not in GDD) s
		"howl_radius": 380.0,  # TUNING (not in GDD) px
		"howl_buff_damage": 0.2,  # TUNING (not in GDD)
		"howl_buff_speed": 0.15,  # TUNING (not in GDD)
		"howl_buff_time": 6.0,  # TUNING (not in GDD) s
		"lunge_every": 7.0,  # TUNING (not in GDD) s
		"lunge_trigger": 130.0,  # TUNING (not in GDD) px
		"lunge_min": 30.0,  # TUNING (not in GDD) px
		"lunge_windup": 0.55,  # TUNING (not in GDD) s
		"lunge_time": 0.3,  # TUNING (not in GDD) s
		"lunge_damage": 18.0,  # TUNING (not in GDD) before the time scaling
		"advance_range": 420.0,  # TUNING (not in GDD) px
		"advance_speed_mult": 1.6,  # TUNING (not in GDD)
		"reward_xp": 220,  # TUNING (not in GDD) as the Gatekeeper
		"reward_crystals": 10,  # TUNING (not in GDD)
	},  # Old Greymane (Ravensmoor).
	# Structure: a sleeping coffin (SleepingCoffinKit, a CourtCoffinKit with
	# ONE noble inside: "a Vampire Noble climbs out"). The coffin keys as the
	# court_coffin row's. Its HP before the time / stage scaling.
	"sleeping_coffin": {
		"display_name": "Sleeping Coffin",
		"max_hp": 140.0,  # TUNING (not in GDD) breakable in a few seconds by a ring (the Endless Feast's coffin 260)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 14.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) worth breaking before the moon
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": CourtEnemyData.FACTION,
		"kit": "sleeping_coffin",
		"release_kind": "vampire_noble",  # Owner-approved proposal: "a Vampire Noble climbs out"
		"release_first": 1.2,  # TUNING (not in GDD) s after it opens
		"release_every": 24.0,  # TUNING (not in GDD) s (unused: one noble)
		"release_reach": 1400.0,  # TUNING (not in GDD) px: she climbs out wherever the necromancer is on the map
		"release_max": 1,  # Owner-approved proposal: one noble
	},  # A sleeping coffin (Ravensmoor).
}
