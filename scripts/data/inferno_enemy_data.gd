## InfernoEnemyData — immutable design data for the kinds THE INFERNO fields on
## every Act VI stage (GDD §15.0 "Act VI foundation (phase 1)"; owner-approved
## proposal docs/act6/PROPOSAL.md "Act VI: The Inferno"). Hell comes to
## collect: every soul the necromancer raised was owed to the Pit, and its
## demons fight for them. The shared kinds of phase 1:
##   damned       — The Damned: fodder, chained wailing souls; DAMNED (they burn
##                  in the Hell Pits, fast: luring them through is the counterplay).
##   imp          — Imp: fodder FLIER with a pitchfork; flies over the pits and
##                  obstacles; DEMON.
##   hell_knight  — Hell Knight: soldier, a burning greatsword (a telegraphed
##                  sweep in front of it), ember armour (flat armour); DEMON.
##   succubus     — Succubus: elite (figure style), CHARMER (Temptation:
##                  HordeDirector.charm()), FLIER; DEMON.
##   demon_brute  — Demon Brute: heavy, four arms, a telegraphed ground slam,
##                  flat armour; DEMON. Also the Last Judgment's heavy.
##   demon_portal — the demon portal: a STRUCTURE (DemonPortals) that pours out
##                  a squad every few seconds; destroyed by damage or sealed.
##   charmed      — the hostile body of a charmed summon (Temptation; never
##                  spawned by a timeline, not in the Codex): it wears the
##                  summon's look and fights through the shared melee AI.
## Each stage's own kinds live in its own file (BurningGateEnemyData,
## SilkPalaceEnemyData, PandemoniumEnemyData; empty until phase 2);
## EnemyDirector.enemy_def() looks them up through inferno_def(), this file
## first, after the Shogunate's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Inferno keys (absent = off):
##   faction   — "inferno" (the Codex's Inferno tab, the reports).
##   kit       — a CovenantKit id; an Inferno kit lives in
##               scripts/enemies/inferno/<kit>_kit.gd (CovenantKits loads it by
##               name, after the Eye's, the Empire's, the Pantheon's and the
##               Shogunate's folders, so kit ids must be unique across the five
##               folders). Every Inferno kind has one (an InfernoKit).
##   demon     — true: immune to the Hell Pits (HellPits.burns_enemy(), the one
##               test; bosses, minibosses and structures never burn either).
##   flier     — true: crosses the pits and obstacles (it also sets "phases"
##               and "floating": Arena.resolve_all() skips it, drawn hovering);
##               a flier never burns.
##   charmer   — true: uses Temptation (its kit calls HordeDirector.charm(); its
##               death breaks its charms through InfernoKit.on_killed()).
##   damned    — true: burns in the pits at damned_mult x (HellPits); phase 2's
##               Gatekeeper drags them.
##   fodder    — true: fodder (reports; phase 2 may read it).
##   codex     — false: never listed in the Codex (the charmed body).
## Kit numbers (the greatsword sweep, the slam, the kiss) are row keys
## documented on each row. The GDD gives no numbers: everything is TUNING (not
## in GDD).
class_name InfernoEnemyData
extends RefCounted

## Faction id of the Inferno's kinds (row "faction").
const FACTION: String = "inferno"
## Kind id of the shared fodder that burns in the pits.
const DAMNED: String = "damned"
## Kind id of the shared flying fodder.
const IMP: String = "imp"
## Kind id of the shared soldier.
const HELL_KNIGHT: String = "hell_knight"
## Kind id of the shared charmer elite.
const SUCCUBUS: String = "succubus"
## Kind id of the shared heavy and the Last Judgment's Reckoning kind.
const DEMON_BRUTE: String = "demon_brute"
## Kind id of the demon portal structure (DemonPortals).
const PORTAL: String = "demon_portal"
## Kind id of a charmed summon's hostile body (Temptation).
const CHARMED: String = "charmed"

## The Inferno's shared kinds, keyed by kind id.
const ENEMIES := {
	# Fodder: a wailing grey soul in chains, dragged to the Pit. Burns in the
	# pits like any living thing, faster.
	"damned": {
		"display_name": "The Damned",
		"max_hp": 14.0,  # TUNING (not in GDD) fodder (Ashigaru 13)
		"move_speed": 52.0,  # TUNING (not in GDD) px/s; shuffling in chains
		"damage": 2.5,  # TUNING (not in GDD) a clawing grasp, before the time scaling
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
		"kit": "damned",
		"damned": true,  # Owner-approved proposal: "they burn in the pits too"
		"fodder": true,
	},
	# Flying fodder: a small winged red imp with a pitchfork. Fast; flies over
	# the pits and the obstacles.
	"imp": {
		"display_name": "Imp",
		"max_hp": 11.0,  # TUNING (not in GDD) fodder, frail
		"move_speed": 84.0,  # TUNING (not in GDD) px/s; "fast fliers"
		"damage": 2.5,  # TUNING (not in GDD) a pitchfork jab, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px; the pitchfork's reach
		"radius": 7.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.25,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "imp",
		"demon": true,
		"flier": true,  # Owner-approved proposal: "fly over pits"
		"phases": true,  # A flier crosses obstacles (Arena.resolve_all() skips it).
		"floating": true,  # Drawn hovering.
		"fodder": true,
	},
	# Soldier: obsidian armour with ember cracks, a burning greatsword. Its
	# SWEEP: when a body comes into reach it raises the blade for sweep_windup s
	# (a fiery arc on the ground) and cuts everything in front of it.
	#   sweep_every   — s between two sweeps.
	#   sweep_reach   — px of the sweep from its body's edge.
	#   sweep_arc     — degrees of the half-angle of the sweep.
	#   sweep_windup  — s of the telegraph.
	#   sweep_damage  — damage to each body in the arc (before the time scaling).
	"hell_knight": {
		"display_name": "Hell Knight",
		"max_hp": 42.0,  # TUNING (not in GDD) a soldier (Samurai 42); first pass 48
		"move_speed": 48.0,  # TUNING (not in GDD) px/s
		"damage": 5.5,  # TUNING (not in GDD) per blow, before the time scaling; first pass 6.5
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px; a greatsword
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"flat_armor": 1.0,  # Owner-approved proposal: "ember armour" (TUNING the amount; first pass 2 absorbed more than the archers dealt)
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
		"kit": "hell_knight",
		"demon": true,
		"sweep_every": 7.0,  # TUNING (not in GDD) s; first pass 5.5 (the knights were the stub's top summon killer)
		"sweep_reach": 28.0,  # TUNING (not in GDD) px
		"sweep_arc": 60.0,  # TUNING (not in GDD) degrees
		"sweep_windup": 0.6,  # TUNING (not in GDD) s
		"sweep_damage": 6.0,  # TUNING (not in GDD) first pass 8
	},
	# Elite (figure style, female): bat wings, horns, a tail. CHARMER: she
	# blows a kiss at a summon in reach (a pink telegraph for kiss_windup s),
	# and it fights for hell (Temptation). Flies.
	#   kiss_every    — s between two kisses (after her first: half).
	#   kiss_range    — px: she kisses a summon this close.
	#   kiss_windup   — s of the blown kiss before it lands.
	#   kiss_duration — s the charm lasts (x Faithless; owner-approved: 6 s).
	"succubus": {
		"display_name": "Succubus",
		"max_hp": 72.0,  # TUNING (not in GDD) an elite-tier body; kill first
		"move_speed": 60.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) a raking claw, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; "kill first"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "succubus",
		"demon": true,
		"flier": true,  # Owner-approved proposal: "flies"
		"phases": true,
		"floating": true,
		"charmer": true,  # Owner-approved proposal: Temptation
		"kiss_every": 10.0,  # TUNING (not in GDD) s; first pass 9
		"kiss_range": 170.0,  # TUNING (not in GDD) px
		"kiss_windup": 0.7,  # TUNING (not in GDD) s
		"kiss_duration": 6.0,  # Owner-approved proposal: "fights for hell for 6 s"
	},
	# Heavy: four arms, demon skin, horns. Its SLAM: a telegraphed ground slam
	# (all four fists) that hits every summon and the necromancer in its circle
	# and throws the summons back. Flat armour.
	#   slam_every   — s between two slams.
	#   slam_trigger — px: it winds up when a body is this close (edge to edge).
	#   slam_windup  — s of the telegraph circle.
	#   slam_radius  — px of the slam.
	#   slam_damage  — damage of the slam (before the time scaling).
	#   slam_push    — px each summon in the slam is thrown back.
	"demon_brute": {
		"display_name": "Demon Brute",
		"max_hp": 330.0,  # TUNING (not in GDD) a heavy (Oni 320)
		"move_speed": 36.0,  # TUNING (not in GDD) px/s
		"damage": 11.0,  # TUNING (not in GDD) per blow, before the time scaling
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 19.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"flat_armor": 4.0,  # Owner-approved proposal: "flat armour" (TUNING the amount)
		"xp": 12,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1
		"mass": 5.0,  # TUNING (not in GDD) blockers barely slow it
		"faction": FACTION,
		"kit": "demon_brute",
		"demon": true,
		"slam_every": 6.0,  # TUNING (not in GDD) s
		"slam_trigger": 34.0,  # TUNING (not in GDD) px
		"slam_windup": 0.9,  # TUNING (not in GDD) s
		"slam_radius": 46.0,  # TUNING (not in GDD) px
		"slam_damage": 10.0,  # TUNING (not in GDD) (the Oni's smash 10)
		"slam_push": 26.0,  # TUNING (not in GDD) px
	},
	# Structure: a ring of obsidian and lava with a charm-pink swirl. While it
	# stands it pours out a squad every few seconds (DemonPortals). Destroyed
	# by damage (its XP), or SEALED by the necromancer (a Soul Ash bounty).
	"demon_portal": {
		"display_name": "Demon Portal",
		"max_hp": 360.0,  # TUNING (not in GDD) before the time / stage scaling (a Signal Pylon 300)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 20.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 8,  # TUNING (not in GDD) destroyed by damage: its XP (sealed: Soul Ash instead)
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
		"kit": "demon_portal",
		"demon": true,
	},
	# A charmed summon's hostile body (Temptation): it wears the summon's art,
	# tinted pink, with hearts over it. Its HP is the summon's (carried back
	# when the charm ends); its hit damage is this row's (time-scaled like every
	# foe's: a late Death Knight does not come back hitting like one, as with
	# Act II's Thralls).
	"charmed": {
		"display_name": "Charmed",
		"max_hp": 20.0,  # Replaced by the summon's own max HP.
		"move_speed": 56.0,  # TUNING (not in GDD) px/s floor; TEMPTATION speed_mult x the summon's
		"damage": 4.0,  # TUNING (not in GDD) before the enemy time scaling, like every foe's
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px edge to edge (every charmed body fights in melee)
		"radius": 10.0,  # Replaced by the summon's own body radius.
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 0,  # Your own dead give no XP (no farming).
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1; first pass 0.65 (the army broke almost every charm within a second)
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "charmed",
		"codex": false,
	},
}
