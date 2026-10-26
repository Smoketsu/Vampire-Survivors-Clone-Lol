## SunRoadEnemyData — immutable design data for the Shogunate kinds that
## join on the Road to the Sun (Stage 15, the Act V finale; GDD §15.0 "Act V
## foundation (phase 1)" and "The Road to the Sun (Act V phase 2)";
## owner-approved proposal docs/act5/PROPOSAL.md "Stage 15: The Road to the
## Sun" and its roster):
##   kitsune  — Kitsune: NIGHT support (female, figure-redesign style). Her
##              FOX-FIRE ILLUSIONS (KitsuneKit): she conjures fox_fire decoys,
##              copies of herself your summons waste attacks on.
##   fox_fire — a Kitsune's fox-fire illusion (FoxFireKit): looks like her,
##              harmless, ranks high on every summon's target list and shrugs
##              off their single blows (wasted); revealed in light (the Sun's
##              Course, SunCourse.light_at()) or by area damage (a spell, a
##              splash, a hazard: anything that is not a summon's own blow), it
##              vanishes. Never killed: no XP, no kill, no drop.
##   sohei    — Sōhei: soldier, a warrior monk with a naginata (SoheiKit): a
##              telegraphed SWEEPING CUT in a wide arc in front of him.
##   kirin    — the Kirin, a holy beast of light: the stage MINIBOSS (KirinKit;
##              SunRoadDirector sends it): its golden gallop down a telegraphed
##              lane, the Horn of Heaven's rays and a halo that burns the undead
##              near it.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.shogunate_def() looks these rows up after
## ShogunateEnemyData. Rows have every key of a ShogunateEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/shogunate/<kit>_kit.gd, unique
## across the Eye, Empire, Pantheon and Shogunate folders; "night", "draws",
## "ambusher", "ethereal" switch the shared rules on for the kind) plus their
## kit's numbers, documented on each row.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name SunRoadEnemyData
extends RefCounted

## Kind id of the Kitsune (night support).
const KITSUNE: String = "kitsune"
## Kind id of a Kitsune's fox-fire illusion (KitsuneKit conjures them).
const FOX_FIRE: String = "fox_fire"
## Kind id of the Sōhei (warrior monk soldier).
const SOHEI: String = "sohei"
## Kind id of the Kirin (the stage miniboss).
const KIRIN: String = "kirin"
## Damage source tag of the Sōhei's sweeping cut.
const SOHEI_SWEEP_SOURCE: String = "sohei_sweep"
## Damage source tag of the Kirin's gallop.
const KIRIN_GALLOP_SOURCE: String = "kirin_gallop"
## Damage source tag of the Kirin's Horn of Heaven rays.
const KIRIN_HORN_SOURCE: String = "kirin_horn"
## Damage source tag of the Kirin's halo (holy burn on the undead near it).
const KIRIN_HALO_SOURCE: String = "kirin_halo"

## Kind id -> design row.
const ENEMIES := {
	# Night support (female, figure-redesign style): a fox spirit in a white and
	# sakura kimono, pale fox tails, fox-fire in her hands. She advances with
	# the night host and keeps conjuring copies of herself.
	#   decoy_every   — s between two conjurings (after her first: half).
	#   decoy_count   — illusions per conjuring.
	#   decoy_max     — her illusions on the field at most (older ones fade first).
	#   decoy_spread  — px around her the illusions appear.
	#   decoy_trigger — px: she conjures only when the necromancer is this close.
	#   decoy_windup  — s she stands with raised hands before they appear.
	"kitsune": {
		"display_name": "Kitsune",
		"max_hp": 64.0,  # TUNING (not in GDD) a support who must live long enough to conjure (Samurai 42)
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) a fox-fire touch, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD) a support's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1 (her illusions rank higher: the lure)
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": ShogunateEnemyData.FACTION,
		"kit": "kitsune",
		"night": true,  # Owner-approved proposal: "Kitsune | Support (night, figure style)"
		"decoy_every": 7.0,  # TUNING (not in GDD) s
		"decoy_count": 3,  # TUNING (not in GDD)
		"decoy_max": 4,  # TUNING (not in GDD)
		"decoy_spread": 34.0,  # TUNING (not in GDD) px
		"decoy_trigger": 360.0,  # TUNING (not in GDD) px
		"decoy_windup": 0.6,  # TUNING (not in GDD) s
	},
	# A Kitsune's fox-fire illusion: her own image with a faint flicker of blue
	# fox-fire. Harmless; your summons waste their blows on it.
	#   decoy_life    — s before it fades by itself.
	#   reveal_light  — light (0..1, SunCourse.light_at()) at which it is revealed.
	"fox_fire": {
		"display_name": "Kitsune",  # It wears her name: the summons cannot tell (the reports call it fox_fire).
		"max_hp": 1.0,  # Never struck for real (FoxFireKit.taken_mult()).
		"move_speed": 54.0,  # TUNING (not in GDD) px/s, a step quicker than her (it leads)
		"damage": 0.0,  # Harmless: an illusion.
		"attack_interval": 1.2,  # TUNING (not in GDD) s (its touch does nothing)
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # As the Kitsune.
		"armor": 0.0,
		"xp": 0,  # No reward: it is not real.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # Owner-approved proposal: "decoy enemies your summons waste attacks on" (TUNING the value: the top of their list)
		"mass": 0.2,  # TUNING (not in GDD) a wisp of fire: it barely pushes
		"faction": ShogunateEnemyData.FACTION,
		"kit": "fox_fire",
		"decoy_life": 9.0,  # TUNING (not in GDD) s
		"reveal_light": 0.75,  # TUNING (not in GDD) light 0..1 (about 115 px into the necromancer's own pool at night)
	},
	# Soldier: a warrior monk, white hood and dark robes over armour, a
	# naginata. His SWEEPING CUT: a telegraphed wide arc in front of him.
	#   sweep_first         — s before his first cut (plus the think-slot stagger).
	#   sweep_cooldown      — s between two cuts.
	#   sweep_trigger_range — px edge to edge: he cuts when his target is this close.
	#   sweep_radius        — px the naginata reaches.
	#   sweep_half_angle    — rad each side of his aim.
	#   sweep_telegraph     — s the arc shows before the cut.
	#   sweep_damage_summon / sweep_damage_player — before the time scaling.
	#   sweep_knockback     — px summons in the arc are thrown back.
	"sohei": {
		"display_name": "Sōhei",
		"max_hp": 48.0,  # TUNING (not in GDD) a soldier (Samurai 42)
		"move_speed": 48.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) a naginata thrust, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px; the naginata outreaches a sword
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 1.5,  # TUNING (not in GDD)
		"faction": ShogunateEnemyData.FACTION,
		"kit": "sohei",
		"sweep_first": 2.5,  # TUNING (not in GDD) s
		"sweep_cooldown": 5.5,  # TUNING (not in GDD) s
		"sweep_trigger_range": 26.0,  # TUNING (not in GDD) px
		"sweep_radius": 54.0,  # TUNING (not in GDD) px
		"sweep_half_angle": 1.1,  # Owner-approved proposal "a sweeping cut" (TUNING the arc: about 125 degrees)
		"sweep_telegraph": 0.55,  # TUNING (not in GDD) s
		"sweep_damage_summon": 9.0,  # TUNING (not in GDD)
		"sweep_damage_player": 8.0,  # TUNING (not in GDD)
		"sweep_knockback": 22.0,  # TUNING (not in GDD) px
	},
	# The MINIBOSS: a holy beast of light, a golden-scaled deer-dragon with a
	# single horn, a flowing white mane and clouds of light at its hooves.
	#   gallop_*  — the golden gallop: a lane (gallop_length px from it through
	#               the necromancer, gallop_width wide) telegraphed for
	#               gallop_telegraph s, then it gallops down the lane in
	#               gallop_time s; every body in the lane is struck once and
	#               summons are thrown gallop_push px aside.
	#   horn_*    — the Horn of Heaven: horn_rays rays of light (horn_length px,
	#               horn_width wide) around it, telegraphed for horn_telegraph s,
	#               then they flash once.
	#   halo_*    — the halo: every halo_tick s each summon within halo_radius px
	#               of it takes halo_damage (holy).
	"kirin": {
		"display_name": "The Kirin",
		"max_hp": 2300.0,  # TUNING (not in GDD) before the time / stage scaling (Polyphemus 2500, Cerberus's heads 1,560)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s; a stately walk between gallops
		"damage": 12.0,  # TUNING (not in GDD) a hoof strike in reach, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 26.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) golden scales
		"xp": 0,  # Its reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise it like a boss
		"mass": 14.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": ShogunateEnemyData.FACTION,
		"kit": "kirin",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 200,  # TUNING (not in GDD) XP burst on death (Cerberus 200)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"reward_ash": 14,  # TUNING (not in GDD) Soul Ash bounty (objective_ash; Cerberus 14)
		"advance_range": 420.0,  # TUNING (not in GDD) px beyond which it strides faster
		"advance_speed_mult": 1.9,  # TUNING (not in GDD)
		"first_attack": 2.5,  # TUNING (not in GDD) s after it arrives
		"attack_gap": 2.2,  # TUNING (not in GDD) s between the end of one attack and the next
		"recover_time": 0.5,  # TUNING (not in GDD) s it stands after an attack
		"gallop_length": 400.0,  # TUNING (not in GDD) px
		"gallop_width": 34.0,  # TUNING (not in GDD) px
		"gallop_telegraph": 0.9,  # TUNING (not in GDD) s
		"gallop_time": 0.5,  # TUNING (not in GDD) s
		"gallop_push": 34.0,  # TUNING (not in GDD) px
		"gallop_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
		"gallop_damage_summon": 10.0,  # TUNING (not in GDD) before the time scaling
		"gallop_min": 90.0,  # TUNING (not in GDD) px: it gallops only at a necromancer at least this far
		"horn_rays": 6,  # TUNING (not in GDD)
		"horn_length": 240.0,  # TUNING (not in GDD) px
		"horn_width": 16.0,  # TUNING (not in GDD) px
		"horn_telegraph": 1.0,  # TUNING (not in GDD) s
		"horn_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
		"horn_damage_summon": 9.0,  # TUNING (not in GDD) before the time scaling
		"halo_radius": 64.0,  # TUNING (not in GDD) px around it
		"halo_tick": 0.5,  # TUNING (not in GDD) s
		"halo_damage": 1.5,  # TUNING (not in GDD) per tick, before the time scaling
	},
}
