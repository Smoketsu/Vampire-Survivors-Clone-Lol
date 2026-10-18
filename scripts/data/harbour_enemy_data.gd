## HarbourEnemyData — immutable design data for the Ancient Eye kinds that
## join on Gullhaven Harbour (Stage 4) (GDD §15.0 "Act II: the Ancient Eye" and
## "Gullhaven Harbour (Act II phase 2)"; owner-approved proposal roster):
##   deep_kin       — Deep Kin: the bruiser. A telegraphed leap onto the front
##                    rank (DeepKinKit); swims at full speed in the tide.
##   tide_caller    — Tide Caller: the caster. Raises a line of water that knocks
##                    summons back (TideCallerKit). Figure-redesign style.
##   netcaster      — Netcaster: the disabler. Throws a net that pins one summon
##                    in place for 3 s (NetcasterKit).
##   harbourmaster  — the Harbourmaster: the stage miniboss (9:00 left), a
##                    hulking Deep Kin with a chained anchor: an arc sweep that
##                    drags what it hits toward him, and an anchor hurl that
##                    reels in the first body it strikes (HarbourmasterKit).
##   deep_herald    — Herald of the Deep: the Harbour's Reckoning kind (the
##                    stage's RECKONING "kind"), a swimmer.
##   bell_buoy      — a bell buoy out on the flats (a structure): it tolls up
##                    reinforcements; sinking it thins the Eye's later waves
##                    (HarbourDirector).
##   smuggler_cache — a locked smugglers' crate at the end of a pier (a
##                    structure): broken, it drops a treasure chest.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T; the tide only exists on the Harbour, so a Deep Kin
## elsewhere simply walks). EnemyDirector.enemy_def() looks these rows up after
## EyeEnemyData. Rows have every key of an EyeEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/eye/<kit>_kit.gd) plus each kit's
## own numbers, documented on the kit. Every kind keeps advancing on the
## necromancer (the shared melee AI) and has one telegraphed trick.
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name HarbourEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
	# The bruiser: a hunched, scaled fisherman halfway into the sea. Tough for a
	# soldier, slow on land; its leap is the danger.
	"deep_kin": {
		"display_name": "Deep Kin",
		"max_hp": 84.0,  # TUNING (not in GDD) a bruiser (Footman 36, Shieldbearer 52, Sister 44)
		"move_speed": 56.0,  # TUNING (not in GDD) px/s; lumbering on land, never slowed in water (HarbourStage.TIDE swimmers)
		"damage": 7.0,  # TUNING (not in GDD) claws in contact
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px edge to edge
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD) scaled hide
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 2.6,  # TUNING (not in GDD) heavier than a soldier
		"faction": EyeEnemyData.FACTION,
		"kit": "deep_kin",
		# Leap onto the front rank (DeepKinKit).
		"leap_first": 3.5,  # TUNING (not in GDD) s after it spawns (plus the think-slot stagger)
		"leap_cooldown": 9.0,  # TUNING (not in GDD) s
		"leap_range_min": 70.0,  # TUNING (not in GDD) px; closer than this it just claws
		"leap_range_max": 230.0,  # TUNING (not in GDD) px
		"leap_telegraph": 0.85,  # TUNING (not in GDD) s; the landing circle shows this long
		"leap_air_time": 0.45,  # TUNING (not in GDD) s in the air
		"leap_radius": 44.0,  # TUNING (not in GDD) px landing circle
		"leap_damage_summon": 10.0,  # TUNING (not in GDD) before time scaling
		"leap_damage_player": 12.0,  # TUNING (not in GDD) before time scaling
		"leap_knockback": 28.0,  # TUNING (not in GDD) px summons are thrown out of the circle
		"leap_recover": 0.6,  # TUNING (not in GDD) s it crouches after landing
	},
	# The caster: a fishwife of the Eye (figure-redesign style: an hourglass
	# figure in a fully closed, salt-stained oilskin gown and a kelp shawl).
	"tide_caller": {
		"display_name": "Tide Caller",
		"max_hp": 50.0,  # TUNING (not in GDD)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) her conch staff in contact (the water line is her real attack)
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1; a caster the archers should drop
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "tide_caller",
		# Water line (TideCallerKit): a line of water rises across the army's path.
		"wall_first": 2.5,  # TUNING (not in GDD) s
		"wall_cooldown": 8.0,  # TUNING (not in GDD) s
		"wall_trigger": 150.0,  # TUNING (not in GDD) px; a summon this close (or the necromancer) starts it
		"wall_distance": 36.0,  # TUNING (not in GDD) px from her to the line's centre, toward the necromancer (it covers the summons fighting her)
		"wall_length": 150.0,  # TUNING (not in GDD) px
		"wall_width": 46.0,  # TUNING (not in GDD) px
		"wall_telegraph": 1.0,  # TUNING (not in GDD) s
		"wall_push": 80.0,  # TUNING (not in GDD) px summons in the line are thrown back (away from her)
		"wall_damage_summon": 5.0,  # TUNING (not in GDD) before time scaling
		"wall_damage_player": 6.0,  # TUNING (not in GDD) before time scaling
		"wall_recover": 0.6,  # TUNING (not in GDD) s
	},
	# The disabler: a net-mender of the Eye with a weighted net over one arm.
	"netcaster": {
		"display_name": "Netcaster",
		"max_hp": 56.0,  # TUNING (not in GDD)
		"move_speed": 54.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) gaff hook in contact
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1
		"mass": 1.1,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "netcaster",
		# Net (NetcasterKit): pins one summon in place.
		"net_first": 3.0,  # TUNING (not in GDD) s
		"net_cooldown": 9.0,  # TUNING (not in GDD) s
		"net_range": 170.0,  # TUNING (not in GDD) px
		"net_telegraph": 0.6,  # TUNING (not in GDD) s; the aim line shows this long
		"net_flight": 0.25,  # TUNING (not in GDD) s the net flies
		"net_pin": 3.0,  # owner-approved proposal "pins one summon in place for 3 s"
		"net_damage": 3.0,  # TUNING (not in GDD) before time scaling, when it lands
		"net_immunity": 4.0,  # TUNING (not in GDD) s a freed summon cannot be netted again
		"net_recover": 0.5,  # TUNING (not in GDD) s
	},
	# The miniboss: a hulking Deep Kin dragging a chained ship's anchor.
	"harbourmaster": {
		"display_name": "The Harbourmaster",
		"max_hp": 1700.0,  # TUNING (not in GDD) x the time / stage HP scaling (~x2.2 at 11:00); the Cathedral Guardian has 1,400
		"move_speed": 34.0,  # TUNING (not in GDD) px/s; heavy, but a swimmer
		"damage": 18.0,  # TUNING (not in GDD) fist and chain
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 30.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is HarbourmasterKit's XP burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers focus it like a boss
		"mass": 14.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.5,  # TUNING (not in GDD) like the bosses
		"faction": EyeEnemyData.FACTION,
		"kit": "harbourmaster",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 170,  # TUNING (not in GDD) XP burst on death
		"reward_crystals": 10,  # TUNING (not in GDD)
		"first_special": 2.5,  # TUNING (not in GDD) s after arrival
		"attack_gap": 3.6,  # TUNING (not in GDD) s between the end of one special and the next
		"recover_time": 0.8,  # TUNING (not in GDD) s it stands after a special
		"advance_range": 260.0,  # TUNING (not in GDD) px; farther than this it strides faster
		"advance_speed_mult": 2.0,  # TUNING (not in GDD) 34 -> 68 px/s (the necromancer runs at 110)
		# Anchor sweep: a sector toward the necromancer, then the anchor swings
		# through it and drags what it hits toward him.
		"sweep_weight": 1.0,  # TUNING (not in GDD)
		"sweep_cooldown": 9.0,  # TUNING (not in GDD) s
		"sweep_range": 200.0,  # TUNING (not in GDD) px; used on a necromancer this close
		"sweep_radius": 170.0,  # TUNING (not in GDD) px
		"sweep_half_angle": 0.95,  # TUNING (not in GDD) rad (~110 degrees in all)
		"sweep_telegraph": 1.2,  # TUNING (not in GDD) s
		"sweep_damage_summon": 9.0,  # TUNING (not in GDD) before time scaling
		"sweep_damage_player": 16.0,  # TUNING (not in GDD) before time scaling
		"sweep_drag": 0.6,  # TUNING (not in GDD) share of the distance a hit body is dragged toward him
		"sweep_drag_gap": 22.0,  # TUNING (not in GDD) px; a dragged body stops this far from his body
		"sweep_player_drag_max": 70.0,  # TUNING (not in GDD) px; the necromancer is dragged at most this far
		# Anchor hurl: a lane toward the necromancer, then the anchor flies down
		# it; the first body it strikes is reeled in beside him.
		"hurl_weight": 1.0,  # TUNING (not in GDD)
		"hurl_cooldown": 12.0,  # TUNING (not in GDD) s
		"hurl_min_range": 110.0,  # TUNING (not in GDD) px
		"hurl_range": 360.0,  # TUNING (not in GDD) px
		"hurl_length": 380.0,  # TUNING (not in GDD) px
		"hurl_width": 30.0,  # TUNING (not in GDD) px
		"hurl_telegraph": 1.0,  # TUNING (not in GDD) s
		"hurl_flight": 0.35,  # TUNING (not in GDD) s the anchor flies out
		"hurl_damage_summon": 12.0,  # TUNING (not in GDD) before time scaling
		"hurl_damage_player": 18.0,  # TUNING (not in GDD) before time scaling
		"hurl_player_drag_max": 90.0,  # TUNING (not in GDD) px; a reeled necromancer moves at most this far
	},
	# The Reckoning: what the deep sends once the countdown ends.
	"deep_herald": {
		"display_name": "Herald of the Deep",
		"max_hp": 950.0,  # TUNING (not in GDD) the Reckoning Inquisitor has 900
		"move_speed": 102.0,  # TUNING (not in GDD) px/s; a swimmer, slightly slower than the player
		"damage": 46.0,  # TUNING (not in GDD)
		"attack_interval": 0.8,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 17.0,  # TUNING (not in GDD) px
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
	},
	# Structures (HarbourDirector places and tracks them).
	"bell_buoy": {
		"display_name": "Bell Buoy",
		"max_hp": 380.0,  # TUNING (not in GDD) ~550 HP at 2:30 after time scaling
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is HarbourDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD)
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": EyeEnemyData.FACTION,
	},
	"smuggler_cache": {
		"display_name": "Smugglers' Cache",
		"max_hp": 300.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 15.0,  # TUNING (not in GDD)
		"armor": 0.3,  # TUNING (not in GDD) iron-bound
		"xp": 0,  # Its reward is HarbourDirector's chest and XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD)
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": EyeEnemyData.FACTION,
	},
}
