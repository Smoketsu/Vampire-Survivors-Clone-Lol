## ArchiveEnemyData — immutable design data for the Ancient Eye kinds that
## join on The Hollow Archive (Stage 5) (GDD §15.0 "Act II: the Ancient Eye",
## "Act II: the Hollow Archive"): the Scribe of the Unwritten, the Ink Wraith,
## the Pilgrim of the Spore, the Gibbering Mass (and the two smaller masses it
## splits into), the Librarian miniboss, the stage's rifts, its Reckoning kind
## and the Archivist's Footnote copies.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T): its kit (scripts/enemies/eye/<kit>_kit.gd) works without
## the Archive's own director, and the world hazards it leaves (ink pools,
## spore clouds) live in ArchiveHazards, which EnemyDirector creates on first
## use on any stage. EnemyDirector.enemy_def() looks these rows up after
## EyeEnemyData. Rows have every key of an EyeEnemyData.ENEMIES row (same
## meaning) plus the kit's own numbers (documented on each kit) and:
##   phases   — true: the body slips through obstacles (Arena.resolve_all()
##              skips it; Enemy.phases_obstacles). The Ink Wraith.
##   floating — true: drawn hovering (no ground contact; visual only).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name ArchiveEnemyData
extends RefCounted

## Kind ids in the order the Archive brings them (Codex, summaries).
const ORDER := ["scribe", "ink_wraith", "spore_pilgrim", "gibbering_mass", "librarian"]
## Every Gibbering Mass size, largest first (the autotest counts them together).
const MASS_KINDS := ["gibbering_mass", "gibbering_lesser", "gibbering_least"]
## Kind id of a rift (RiftDirector places it; a structure the army can break).
const RIFT: String = "archive_rift"
## Kind id of the Archive's Reckoning soldier (ArchiveStage.RECKONING "kind").
const RECKONER: String = "unwritten_one"
## Kind id of one of the Archivist's Footnote copies (BossArchivist; never in a timeline).
const COPY: String = "archivist_copy"

## The Archive's kinds, keyed by kind id.
const ENEMIES := {
	# Support: inks a curse on nearby cultists. A cursed cultist is a claimer
	# for curse_duration s (Enemy.claimer_until, reach EyeEnemyData.CLAIM
	# curse_radius): a summon dying near it rises as a Drowned Thrall. High
	# target priority: the counterplay is to kill the Scribe first.
	"scribe": {
		"display_name": "Scribe of the Unwritten",
		"max_hp": 44.0,  # TUNING (not in GDD) a support (Chanter 46)
		"move_speed": 48.0,  # TUNING (not in GDD) px/s; keeps pace with the cultists it inks
		"damage": 4.0,  # TUNING (not in GDD) quill stab
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD) (4 at first: builds completed by ~12:45, a minute early)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; kill it before it curses the crowd
		"mass": 1.1,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "scribe",
		# The curse (ScribeKit).
		"curse_first": 2.0,  # TUNING (not in GDD) s after spawning before the first curse
		"curse_cooldown": 7.0,  # TUNING (not in GDD) s between curses
		"curse_range": 130.0,  # TUNING (not in GDD) px; cultists this close can be cursed
		"curse_count": 3,  # TUNING (not in GDD) cultists cursed per cast (the nearest uncursed ones)
		"curse_duration": 10.0,  # TUNING (not in GDD) s a cultist stays a claimer
		"curse_cast": 0.8,  # TUNING (not in GDD) s it stands still writing (the telegraph)
	},
	# Flanker: slips through shelves and obstacles and rises out of ink pools
	# (the Ink Wells' wells, the Archivist's ink); a fast, frail hunter.
	"ink_wraith": {
		"display_name": "Ink Wraith",
		"max_hp": 32.0,  # TUNING (not in GDD)
		"move_speed": 80.0,  # TUNING (not in GDD) px/s; a flanker (the necromancer runs at 110)
		"damage": 4.0,  # TUNING (not in GDD) claws (5 at first: with the rise beside the necromancer, the top hitter of naive builds)
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD) (3 at first)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1 (0.5 at first): the army hunts the flanker that rose beside its master
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "ink_wraith",
		"phases": true,  # Slips through shelves and every obstacle.
		"floating": true,  # Glides (visual only).
		# Diving through the ink (InkWraithKit).
		"rise_time": 0.6,  # TUNING (not in GDD) s it takes to rise out of a pool (it stands still)
		"sink_time": 0.6,  # TUNING (not in GDD) s it takes to sink into a pool (it stands still)
		"dive_first": 3.0,  # TUNING (not in GDD) s after spawning before the first dive
		"dive_cooldown": 8.0,  # TUNING (not in GDD) s between dives
		"dive_range": 360.0,  # TUNING (not in GDD) px; only pools this close to the necromancer
		"dive_gain": 120.0,  # TUNING (not in GDD) px; a dive must bring it at least this much closer to him
		"spawn_rise_range": 420.0,  # TUNING (not in GDD) px; a new Wraith rises from a pool this close to him instead of the spawn ring
	},
	# Area denial: leaves spore clouds behind it that raise the necromancer's
	# Dread and choke the undead inside; bursts into a big cloud when it dies.
	"spore_pilgrim": {
		"display_name": "Pilgrim of the Spore",
		"max_hp": 60.0,  # TUNING (not in GDD)
		"move_speed": 42.0,  # TUNING (not in GDD) px/s; a slow pilgrim
		"damage": 5.0,  # TUNING (not in GDD) staff
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD) (5 at first)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1; worth killing before it fogs the field
		"mass": 1.4,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "spore_pilgrim",
		# Spore clouds (SporePilgrimKit; their effect is HAZARDS below).
		"cloud_first": 1.5,  # TUNING (not in GDD) s after spawning before the first cloud
		"cloud_interval": 4.5,  # TUNING (not in GDD) s between clouds while it walks
		"cloud_radius": 44.0,  # TUNING (not in GDD) px
		"cloud_life": 6.0,  # TUNING (not in GDD) s
		"death_cloud_radius": 70.0,  # TUNING (not in GDD) px; the burst when it dies
		"death_cloud_life": 7.0,  # TUNING (not in GDD) s
	},
	# Tank: slow and heavy; splits into two smaller masses when it dies, and
	# each of those once more (at most twice, deterministic: no RNG).
	"gibbering_mass": {
		"display_name": "Gibbering Mass",
		"max_hp": 170.0,  # TUNING (not in GDD) a tank (Sentinel 120 with flat armour)
		"move_speed": 36.0,  # TUNING (not in GDD) px/s
		"damage": 10.0,  # TUNING (not in GDD) crushing bulk
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px edge to edge
		"radius": 17.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD) (5 at first; the splits pay their own)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.4,  # TUNING (not in GDD) 0..1
		"mass": 4.0,  # TUNING (not in GDD) shoves warriors
		"slow_resist": 0.2,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "gibbering",
		"split_into": "gibbering_lesser",  # Kind it splits into ("" = none).
		"split_count": 2,  # TUNING (not in GDD) owner-approved proposal "two smaller masses"
		"split_offset": 18.0,  # TUNING (not in GDD) px from the fallen mass, either side of its line to the necromancer
	},
	"gibbering_lesser": {
		"display_name": "Lesser Mass",
		"max_hp": 70.0,  # TUNING (not in GDD)
		"move_speed": 44.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD)
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 12.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD) (2 at first)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD)
		"mass": 2.0,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "gibbering",
		"split_into": "gibbering_least",
		"split_count": 2,  # TUNING (not in GDD)
		"split_offset": 12.0,  # TUNING (not in GDD) px
	},
	"gibbering_least": {
		"display_name": "Least Mass",
		"max_hp": 28.0,  # TUNING (not in GDD)
		"move_speed": 54.0,  # TUNING (not in GDD) px/s
		"damage": 3.5,  # TUNING (not in GDD)
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD)
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "gibbering",
		"split_into": "",  # The last split: nothing left to divide.
		"split_count": 0,
		"split_offset": 0.0,
	},
	# The miniboss at 9:00: a floating eye wrapped in tendrils. A slow,
	# telegraphed beam turns the summons it crosses around for turn_time s
	# (SummonedUnit.misdirect(): they walk away and do not fight), and a
	# tendril lash throws back the undead crowding it. LibrarianKit; HUD
	# miniboss bar (EnemyDirector.set_miniboss()), guaranteed chest
	# (ChestManager miniboss rule).
	"librarian": {
		"display_name": "The Librarian",
		"max_hp": 1700.0,  # TUNING (not in GDD) x enemy HP scaling (x2.3 at 9:00) x the stage HP multiplier
		"move_speed": 34.0,  # TUNING (not in GDD) px/s; floats slowly
		"damage": 14.0,  # TUNING (not in GDD) tendril strike in reach
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px edge to edge
		"radius": 26.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is LibrarianKit's XP burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers focus it like a boss
		"mass": 10.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD) like the bosses
		"faction": EyeEnemyData.FACTION,
		"kit": "librarian",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"floating": true,  # Hovers (visual only).
		"reward_xp": 180,  # TUNING (not in GDD) XP burst on death
		"reward_crystals": 10,  # TUNING (not in GDD)
		"first_special": 3.0,  # TUNING (not in GDD) s after arrival
		"attack_gap": 3.5,  # TUNING (not in GDD) s between the end of one special and the next
		"recover_time": 0.7,  # TUNING (not in GDD) s it hangs still after a special
		"advance_range": 260.0,  # TUNING (not in GDD) px; farther than this it drifts faster
		"advance_speed_mult": 2.0,  # TUNING (not in GDD) 34 -> 68 px/s
		# The Index beam: a lane telegraph toward the necromancer, then the
		# beam fires down it.
		"beam_cooldown": 9.0,  # TUNING (not in GDD) s
		"beam_range": 360.0,  # TUNING (not in GDD) px; used on a necromancer this close
		"beam_length": 400.0,  # TUNING (not in GDD) px
		"beam_width": 44.0,  # TUNING (not in GDD) px
		"beam_telegraph": 1.6,  # TUNING (not in GDD) owner-approved proposal "slow, telegraphed"
		"beam_fire_time": 0.45,  # TUNING (not in GDD) s the beam burns down the lane
		"turn_time": 2.0,  # TUNING (not in GDD) owner-approved proposal "turns your summons around for 2 s"
		"turn_speed": 0.6,  # TUNING (not in GDD) fraction of its speed a turned summon walks away at
		"beam_damage_summon": 4.0,  # TUNING (not in GDD) before time scaling
		"beam_damage_player": 14.0,  # TUNING (not in GDD) before time scaling
		"beam_dread": 10.0,  # TUNING (not in GDD) Dread when the beam's gaze catches the necromancer (Act II only)
		# Tendril lash: a circle around itself, then the tendrils sweep it.
		"lash_cooldown": 8.0,  # TUNING (not in GDD) s
		"lash_radius": 92.0,  # TUNING (not in GDD) px
		"lash_telegraph": 1.0,  # TUNING (not in GDD) s
		"lash_min_summons": 3,  # TUNING (not in GDD) used when this many summons crowd it (or the necromancer is inside)
		"lash_damage_summon": 7.0,  # TUNING (not in GDD) before time scaling
		"lash_damage_player": 12.0,  # TUNING (not in GDD) before time scaling
		"lash_knockback": 36.0,  # TUNING (not in GDD) px summons are thrown out
	},
	# A rift (RiftDirector): a tear in the air that spits the Eye out next to
	# the army. A structure: it stands, the army attacks it, and breaking it
	# closes the rift early.
	"archive_rift": {
		"display_name": "Rift",
		"max_hp": 220.0,  # TUNING (not in GDD) x enemy HP scaling: a few volleys close it
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD) a small reward for closing it
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; the army goes for it
		"mass": 99.0,  # A standing tear: never shoved.
		"is_structure": true,
		"construct": true,  # Never healed or raised by priests.
		"faction": EyeEnemyData.FACTION,
		"kit": "rift",
	},
	# The Archive's Reckoning: the Unwritten, page-wrapped horrors that end
	# the run after 0:00 (same scaling as the Reckoning Inquisitor).
	"unwritten_one": {
		"display_name": "The Unwritten",
		"max_hp": 900.0,  # TUNING (not in GDD) as EnemyData.RECKONING_ENEMY
		"move_speed": 100.0,  # TUNING (not in GDD) slightly slower than the necromancer
		"damage": 45.0,  # TUNING (not in GDD)
		"attack_interval": 0.8,  # TUNING (not in GDD)
		"attack_range": 6.0,  # TUNING (not in GDD)
		"radius": 16.0,  # TUNING (not in GDD)
		"armor": 0.5,  # TUNING (not in GDD)
		"xp": 30,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 3.0,  # TUNING (not in GDD)
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD)
		"mass": 8.0,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"phases": true,  # The Unwritten pass through the stacks.
	},
	# One of the Archivist's Footnote copies (BossArchivist): it walks with
	# her and draws the army's blows, but casts no shadow and takes no damage.
	"archivist_copy": {
		"display_name": "A Footnote",
		"max_hp": 1.0,  # Never takes damage (ArchivistCopy.damage_taken_mult()).
		"move_speed": 46.0,  # TUNING (not in GDD) her pace
		"damage": 0.0,  # Strikes nothing: a copy only misleads.
		"attack_interval": 1.0,
		"attack_range": 6.0,  # px; only its stopping reach (it never strikes)
		"radius": 22.0,  # TUNING (not in GDD) her body
		"armor": 0.0,
		"xp": 0,
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) as tempting as she is
		"mass": 12.0,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
	},
}

## World hazards the Archive's kinds and boss leave (ArchiveHazards; on any
## stage). Dread is raised only through DreadMeter.add() and only where the
## stage has Dread (Act II).
##   ink_slow           — fraction of the necromancer's speed lost in ink
##                        (Necromancer.apply_ground_slow()).
##   ink_dread          — Dread per second while he stands in ink ("ink").
##   ink_linger         — s the ink slow lingers after he steps out.
##   spore_dread        — Dread per second while he stands in spores ("spores").
##   spore_summon_dps   — damage per second to each summon inside a cloud
##                        (source "spores", before the enemy time scaling).
##   spore_tick         — s between spore damage ticks.
##   max_pools / max_clouds — most ink pools / spore clouds at once (the
##                        oldest is replaced).
##   pool_fade / cloud_fade — s a pool / cloud takes to fade in and out (look).
const HAZARDS := {
	"ink_slow": 0.3,  # TUNING (not in GDD) owner-approved proposal: ink pools slow
	"ink_dread": 14.0,  # TUNING (not in GDD) Dread per second; it must outpace the kills' calming (1 per kill) to bite
	"ink_linger": 0.3,  # TUNING (not in GDD) s
	"spore_dread": 10.0,  # TUNING (not in GDD) Dread per second
	"spore_summon_dps": 0.8,  # TUNING (not in GDD) light: the clouds deny ground, they do not shred the army (1.6, per overlapping cloud, was half of all summon damage)
	"spore_tick": 0.5,  # TUNING (not in GDD) s
	"max_pools": 24,  # TUNING (not in GDD)
	"max_clouds": 18,  # TUNING (not in GDD)
	"pool_fade": 0.6,  # TUNING (not in GDD) visual
	"cloud_fade": 0.8,  # TUNING (not in GDD) visual
}

## Look of the hazards (ArchiveHazards / ArchiveGlyphs; drawing only).
const INK_COLOR: Color = Color(0.04, 0.04, 0.09)  # TUNING (not in GDD) black ink with a blue sheen
const INK_SHEEN: Color = Color(0.27, 0.31, 0.62)  # TUNING (not in GDD)
const SPORE_COLOR: Color = Color(0.56, 0.66, 0.36)  # TUNING (not in GDD) sickly spore green (never the UI's soul-teal)
const CURSE_COLOR: Color = Color(0.20, 0.18, 0.42)  # TUNING (not in GDD) the Scribe's ink sigil over a cursed cultist
