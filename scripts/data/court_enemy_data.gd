## CourtEnemyData — immutable design data for the kinds THE SANGUINE COURT
## fields on every Act VII stage (GDD §15.0 "Act VII foundation (phase 1)";
## owner-approved proposal docs/act7/PROPOSAL.md "Act VII: The Sanguine
## Court"). The dead who never served: vampires, bats, werewolves and witches
## who kept their own will in death, starving since the necromancer emptied
## their table. The shared kinds of phase 1:
##   blood_thrall   — Blood Thrall: fodder, bitten servants, pale and slow; they
##                    feed a little (Bloodfeast).
##   vampire_bat    — Vampire Bat: flying fodder in swarms of 10; NIGHT WINGS
##                    (they fly over the Bone Ring and must land to bite).
##   blood_knight   — Blood Knight: soldier, a halberd (a cleave) and blood-red
##                    plate; a vampire: it feeds hard on every hit.
##   werewolf       — Werewolf: heavy; a human hunter with a silver crossbow
##                    until the Blood Moon or half HP, then a huge beast that
##                    lunges and feeds (WEREBEAST).
##   vampire_noble  — Vampire Noble: elite, the Countess (figure style); a
##                    blood-drain beam at range (a ranged feed); at low HP she
##                    turns to mist (1.5 s untargetable) and reforms nearer the
##                    necromancer (NOBLE).
##   court_coffin   — the Court's coffin: a placeholder STRUCTURE (the Endless
##                    Feast opens them; phase 2's Ravensmoor sleeps them) that
##                    releases a vampire noble when it opens.
## Each stage's own kinds live in its own file (RavensmoorEnemyData,
## WitchwoodEnemyData, CastleSanguisEnemyData; empty until phase 2);
## EnemyDirector.enemy_def() looks them up through court_def(), this file
## first, after the Inferno's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Court keys (absent = off):
##   faction    — "court" (the Codex's Court tab, the reports).
##   kit        — a CovenantKit id; a Court kit lives in
##                scripts/enemies/court/<kit>_kit.gd (CovenantKits loads it by
##                name, after the Eye's, the Empire's, the Pantheon's, the
##                Shogunate's and the Inferno's folders, so kit ids must be
##                unique across the six folders). Every Court kind has one (a
##                CourtKit).
##   feeds      — float 0..1: the BLOODFEAST share (Bloodfeast, the one path):
##                each melee hit heals the attacker for feeds x the damage it
##                dealt (owner-approved: vampires 0.5, every other Court kind
##                0.25). 0 / absent = it never feeds.
##   flies      — bool: NIGHT WINGS (NightWings, the one path; Enemy.flies,
##                read by Enemy.resolve_blocking(), so the Bone Ring never
##                body-blocks it). It also sets "phases" and "floating" (it
##                crosses obstacles, the ground's slows spare it). In flight
##                only airborne summons, ranged attacks and spells hit it
##                (CourtKit.taken_mult()); it lands for a swoop to bite.
##   werebeast  — bool: transforms under the Blood Moon or at beast_at of its
##                HP (WerewolfKit); Silver Bones' damage hook reads it.
##   noble      — bool: mist form at low HP (VampireNobleKit); Silver Bones'
##                damage and mist hooks read it.
##   fodder     — true: fodder (reports; phase 2 may read it).
## Kit numbers (the swoop, the transformation, the beam, the mist, the coffin)
## are row keys documented on each row. The GDD gives no numbers: everything is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name CourtEnemyData
extends RefCounted

## Faction id of the Court's kinds (row "faction").
const FACTION: String = "court"
## Kind id of the shared fodder.
const BLOOD_THRALL: String = "blood_thrall"
## Kind id of the shared flying fodder.
const VAMPIRE_BAT: String = "vampire_bat"
## Kind id of the shared soldier.
const BLOOD_KNIGHT: String = "blood_knight"
## Kind id of the shared heavy (the werebeast) and the Endless Feast's Reckoning kind.
const WEREWOLF: String = "werewolf"
## Kind id of the shared elite (the Countess).
const VAMPIRE_NOBLE: String = "vampire_noble"
## Kind id of the coffin structure (the Endless Feast; phase 2's sleeping coffins).
const COFFIN: String = "court_coffin"
## Sprite key of the werewolf's transformed beast (assets/sprites/court/).
const BEAST_SPRITE: String = "court/werewolf_beast"
## Sprite key of an opened coffin (assets/sprites/structures/).
const COFFIN_OPEN_SPRITE: String = "structures/court_coffin_open"
## Damage tag of the noble's blood-drain beam (a ranged feed).
const DRAIN_SOURCE: String = "noble_drain"
## Damage tag of the beast's lunge.
const LUNGE_SOURCE: String = "werewolf_lunge"
## Damage tag of the hunter's silver crossbow bolt.
const BOLT_SOURCE: String = "werewolf"

## The Court's shared kinds, keyed by kind id.
const ENEMIES := {
	# Fodder: a bitten servant, pale and slow, in mobs. It feeds a little.
	"blood_thrall": {
		"display_name": "Blood Thrall",
		"max_hp": 15.0,  # TUNING (not in GDD) fodder (the Damned 14)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s; "pale and slow"
		"damage": 2.5,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "blood_thrall",
		"feeds": 0.25,  # Owner-approved (Oct 31, 2026): the Court's kinds that are not vampires feed 25%
		"fodder": true,
	},
	# Flying fodder: swarms of 10. NIGHT WINGS: it flies over the Bone Ring at
	# the necromancer and the priests inside, and must LAND to bite:
	#   swoop_time   — s of the swoop down (its ground shadow grows; the owner-
	#                  approved 0.5 s); it bites at the end of it.
	#   landed_time  — s it stays on the ground after the bite (open to every
	#                  blow) before it takes off again.
	#   swoop_reach  — px beyond attack_range from which it starts the swoop.
	#   swoop_follow — x its move speed it dives after its target during the
	#                  swoop (so a necromancer walking on is still bitten).
	"vampire_bat": {
		"display_name": "Vampire Bat",
		"max_hp": 9.0,  # TUNING (not in GDD) fodder, frail (the Imp 11)
		"move_speed": 92.0,  # TUNING (not in GDD) px/s; fast fliers
		"damage": 2.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s (a swoop, a bite, a take-off)
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 6.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.25,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "vampire_bat",
		"feeds": 0.25,  # Owner-approved: not a vampire (a bat): 25%
		"flies": true,  # Owner-approved proposal: Night Wings
		"phases": true,  # A flier crosses obstacles (Arena.resolve_all() skips it).
		"floating": true,  # Over the ground (the terrain slows and fires spare it).
		"fodder": true,
		"swoop_time": 0.5,  # Owner-approved proposal: "a 0.5 s swoop shown by a shadow on the ground"
		"landed_time": 0.5,  # TUNING (not in GDD) s
		"swoop_reach": 6.0,  # TUNING (not in GDD) px
		"swoop_follow": 1.5,  # TUNING (not in GDD) x move speed
	},
	# Soldier: a halberd and blood-red plate. A VAMPIRE: it feeds hard on every
	# hit, its halberd's sweep (the shared cleave) included.
	"blood_knight": {
		"display_name": "Blood Knight",
		"max_hp": 44.0,  # TUNING (not in GDD) a soldier (the Hell Knight 42)
		"move_speed": 48.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) per blow, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px; a halberd
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) blood-red plate
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 1.6,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "blood_knight",
		"feeds": 0.5,  # Owner-approved (Oct 31, 2026): vampires feed 50% ("feeds on every hit")
		"cleave_radius": 26.0,  # TUNING (not in GDD) px; the halberd's sweep (Enemy._cleave(), the shared path)
		"cleave_targets": 1,  # TUNING (not in GDD)
		"cleave_mult": 0.5,  # TUNING (not in GDD)
	},
	# Heavy: a human hunter with a silver crossbow (a ranged bolt; no feeding)
	# until the Blood Moon rises or it falls to beast_at of its HP, then a huge
	# BEAST: faster, bigger, a melee bite that feeds, and a LUNGE.
	#   beast_at          — share (0..1) of its max HP at which it turns.
	#   beast_speed       — px/s of the beast.
	#   beast_damage      — the beast's blow (before the time scaling).
	#   beast_interval    — s between two beast blows.
	#   beast_range       — px of the beast's reach (edge to edge).
	#   beast_radius      — px of the beast's body.
	#   beast_mass        — the beast's weight against blockers.
	#   lunge_every       — s between two lunges.
	#   lunge_trigger     — px (edge to edge): it lunges at a target this close ...
	#   lunge_min         — ... and at least this far (else it just bites).
	#   lunge_windup      — s of the crouch (a red line on the ground).
	#   lunge_time        — s of the leap.
	#   lunge_damage      — damage of the landing bite (before the time scaling).
	"werewolf": {
		"display_name": "Werewolf",
		"max_hp": 300.0,  # TUNING (not in GDD) a heavy (the Demon Brute 330)
		"move_speed": 42.0,  # TUNING (not in GDD) px/s; the hunter
		"damage": 6.0,  # TUNING (not in GDD) a silver bolt, before the time scaling
		"attack_interval": 2.4,  # TUNING (not in GDD) s; a crossbow reloads
		"attack_range": 210.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px; the hunter
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 12,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 360.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1; "burst it before it turns"
		"mass": 2.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "werewolf",
		"feeds": 0.25,  # Owner-approved: not a vampire: 25% (the beast's blows are heavy, so it feeds hard)
		"werebeast": true,  # Owner-approved proposal: turns under the Blood Moon or at half HP
		"beast_at": 0.5,  # Owner-approved proposal: "until the Blood Moon or half HP"
		"beast_speed": 66.0,  # TUNING (not in GDD) px/s
		"beast_damage": 12.0,  # TUNING (not in GDD)
		"beast_interval": 1.2,  # TUNING (not in GDD) s
		"beast_range": 14.0,  # TUNING (not in GDD) px
		"beast_radius": 20.0,  # TUNING (not in GDD) px; "a huge beast"
		"beast_mass": 5.0,  # TUNING (not in GDD)
		"lunge_every": 6.0,  # TUNING (not in GDD) s
		"lunge_trigger": 110.0,  # TUNING (not in GDD) px
		"lunge_min": 30.0,  # TUNING (not in GDD) px
		"lunge_windup": 0.5,  # TUNING (not in GDD) s
		"lunge_time": 0.25,  # TUNING (not in GDD) s
		"lunge_damage": 12.0,  # TUNING (not in GDD)
	},
	# Elite (figure style, female): the Countess. A VAMPIRE (feeds 50%). Her
	# BLOOD-DRAIN BEAM: when a summon or the necromancer is within beam_range
	# she stands and drains it for beam_time s, every beam_tick s a hit that
	# feeds her (a ranged feed: Bloodfeast through the hit). Her MIST: the first
	# time she falls below mist_at of her HP she turns to mist for mist_time s
	# (untargetable: Enemy.untargetable; x Silver Bones) and reforms up to
	# mist_jump px nearer the necromancer (never closer than mist_keep px).
	#   beam_every / beam_range / beam_time / beam_tick / beam_damage
	"vampire_noble": {
		"display_name": "Vampire Noble",
		"max_hp": 90.0,  # TUNING (not in GDD) an elite (the Succubus 72); burst her
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) a raking claw, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 9,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; "burst damage, Death Mark"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "vampire_noble",
		"feeds": 0.5,  # Owner-approved (Oct 31, 2026): vampires feed 50%
		"noble": true,  # Owner-approved proposal: mist form
		"beam_every": 8.0,  # TUNING (not in GDD) s
		"beam_range": 150.0,  # TUNING (not in GDD) px
		"beam_time": 1.4,  # TUNING (not in GDD) s
		"beam_tick": 0.25,  # TUNING (not in GDD) s
		"beam_damage": 1.6,  # TUNING (not in GDD) per tick, before the time scaling (~9 over the beam)
		"mist_at": 0.35,  # TUNING (not in GDD) share of max HP ("at low HP")
		"mist_time": 1.5,  # Owner-approved proposal: "1.5 s untargetable"
		"mist_jump": 120.0,  # TUNING (not in GDD) px
		"mist_keep": 40.0,  # TUNING (not in GDD) px
	},
	# Structure: the Court's coffin (placeholder until the art pass's
	# structures/court_coffin). It stands closed; once it OPENS it releases a
	# vampire noble release_first s later, then one every release_every s
	# while a necromancer is within release_reach px (at most release_max).
	# The Endless Feast places them open; phase 2 (Ravensmoor's sleeping
	# coffins) can place them closed and open them on its own clock
	# (CourtCoffinKit.open_coffin()).
	"court_coffin": {
		"display_name": "Coffin",
		"max_hp": 260.0,  # TUNING (not in GDD) before the time / stage scaling (a demon portal 360)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 14.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) worth breaking
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": FACTION,
		"kit": "court_coffin",
		"release_kind": "vampire_noble",  # Owner-approved proposal: "coffins open and release nobles"
		"release_first": 1.5,  # TUNING (not in GDD) s after it opens
		"release_every": 24.0,  # TUNING (not in GDD) s
		"release_reach": 900.0,  # TUNING (not in GDD) px
		"release_max": 3,  # TUNING (not in GDD) nobles one coffin releases
	},
	# --- Act VII: the Witchwood ---
	# Support (figure style, female): the CRIMSON WITCH. Owner-approved proposal:
	# "Covens of three; together they cast a hex circle that heals the Court
	# inside it and drains the army ... Break the coven: kill one and the circle
	# fails". On her own she keeps her distance and throws hex bolts (the shared
	# "ranged" shot: it names no attacker, so it never feeds). Free witches band
	# into covens of three and cast together while the Blood Moon is up or a
	# hex stone powers them (WitchHexes, numbers in WitchHexData.COVEN); a coven
	# witch who strays walks back to her sisters. Any stage can field her.
	"crimson_witch": {
		"display_name": "Crimson Witch",
		"max_hp": 56.0,  # TUNING (not in GDD) support (the Lilim Witch 52); kill one to break the circle
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) a hex bolt, before the time scaling
		"attack_interval": 2.0,  # TUNING (not in GDD) s
		"attack_range": 170.0,  # TUNING (not in GDD) px; she keeps her distance
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 240.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; "break the coven"
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "crimson_witch",
		"feeds": 0.25,  # Owner-approved: not a vampire: 25% (her bolts never feed; a blow in reach would)
		"witch": true,  # Act VII, the Witchwood: she bands into covens (WitchHexes)
	},
	# Heavy: the BLOATED THRALL. Owner-approved proposal: "Swollen with blood;
	# bursts into a pool that heals Court units walking through it ... Kill it
	# away from the knights". A slow, heavy feeder; when it dies it BURSTS: a
	# splash and a blood pool of pool_radius px for pool_life s (WitchHexes
	# .open_pool(), the one pool path; WitchHexData.POOLS heals in it).
	#   pool_radius / pool_life — its pool (px, s).
	"bloated_thrall": {
		"display_name": "Bloated Thrall",
		"max_hp": 190.0,  # TUNING (not in GDD) a heavy (the Werewolf 300, the Demon Brute 330): slow and soft
		"move_speed": 34.0,  # TUNING (not in GDD) px/s; swollen and slow
		"damage": 8.0,  # TUNING (not in GDD) a heavy slam, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 16.0,  # TUNING (not in GDD) px; the belly
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 3.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "bloated_thrall",
		"feeds": 0.25,  # Owner-approved: not a vampire (a thrall): 25%
		"pool_radius": 46.0,  # TUNING (not in GDD) px; first pass 52
		"pool_life": 7.0,  # TUNING (not in GDD) s; first pass 10 (the pools healed 185k in the first seed-7 run)
	},  # The Bloated Thrall (Act VII: the Witchwood).
}
