## KuroganeEnemyData — immutable design data for the Shogunate kinds that
## join on Castle Kurogane (Stage 14) (Act V; GDD §15.0 "Act V foundation (phase 1)"
## and "Castle Kurogane (Act V phase 2)"; owner-approved proposal
## docs/act5/PROPOSAL.md "Roster" and "Stage 14: Castle Kurogane"):
##   hatamoto      — Hatamoto: ELITE banner guard (always elite). A veteran
##                   under a tall white war banner; nearby soldiers fight harder
##                   while he stands, through the one enemy-buff path (the
##                   row's aura_* keys: Enemy._pulse_aura() ->
##                   Enemy.apply_buff()). Kill the banner. In the Shogun's fight
##                   each regiment marches under one (HatamotoKit carries the
##                   regiment's banner colour): killing him BREAKS it.
##   kiba_musha    — Kiba-musha: mounted samurai cavalry, a charging soldier
##                   (KibaKit: a telegraphed lane, then a gallop that strikes
##                   the necromancer once and throws summons aside); the
##                   regiments' cavalry.
##   general_left  — the General of the Left: the stage MINIBOSS (9:00 left), a
##                   mounted samurai general who charges THROUGH the ring on a
##                   telegraphed line (GeneralKit, a bigger KibaKit), and calls
##                   his riders. Registers on the HUD's miniboss bar
##                   (EnemyDirector.set_miniboss(); ChestManager drops the chest).
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.shogunate_def() looks these rows up after
## ShogunateEnemyData. Rows have every key of a ShogunateEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/shogunate/<kit>_kit.gd, unique
## across the Eye, Empire, Pantheon and Shogunate folders), plus each kit's own
## numbers documented on its row. The GDD gives no numbers: everything is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name KuroganeEnemyData
extends RefCounted

## Kind id of the Hatamoto (elite banner guard; each regiment's banner).
const HATAMOTO: String = "hatamoto"
## Kind id of the Kiba-musha (mounted samurai cavalry).
const KIBA_MUSHA: String = "kiba_musha"
## Kind id of the General of the Left (the stage miniboss).
const GENERAL_LEFT: String = "general_left"
## Damage source tag of a Kiba-musha's charge (KibaKit).
const KIBA_CHARGE_SOURCE: String = "kiba_charge"
## Damage source tag of the General of the Left's charge (GeneralKit).
const GENERAL_CHARGE_SOURCE: String = "general_charge"

## Kind id -> design row.
const ENEMIES := {
	# Elite banner guard: a stocky veteran in black lacquer laced red, a tall
	# white sashimono banner on his back, a short yari. His banner AURA buffs
	# every soldier near him (the shared Banner Bearer path); he advances
	# behind his men (slow) and never kites.
	#   banner_color — colour (multiplied over his sprite: the white banner
	#                  takes it, the dark lacquer barely changes) when he
	#                  marches outside the Shogun's regiments (HatamotoKit).
	"hatamoto": {
		"display_name": "Hatamoto",
		"max_hp": 170.0,  # TUNING (not in GDD) an elite banner guard (x the elite multiplier: always elite)
		"move_speed": 44.0,  # TUNING (not in GDD) px/s; he marches behind his men
		"damage": 7.0,  # TUNING (not in GDD) a yari thrust, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD) lacquered plates
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # Owner-approved proposal "kill the banner": summons go for him (GDD §7.2 Banner Bearer's elevated priority)
		"mass": 2.4,  # TUNING (not in GDD)
		"faction": ShogunateEnemyData.FACTION,
		"kit": "hatamoto",
		"always_elite": true,  # Owner-approved proposal: "Elite"
		"aura_radius": 130.0,  # TUNING (not in GDD) px (the Banner Bearer 110)
		"aura_damage_mult": 1.2,  # TUNING (not in GDD) "nearby soldiers fight harder"
		"aura_speed_mult": 1.12,  # TUNING (not in GDD)
		"aura_taken_mult": 0.9,  # TUNING (not in GDD)
		"banner_color": Color(1.0, 1.0, 1.0),  # TUNING (not in GDD) plain white outside a regiment
	},
	# Mounted samurai cavalry: a rider in black-and-red lacquer with a crescent
	# kabuto on a brown war horse, a levelled yari. Its CHARGE: every
	# charge_every s, when the necromancer is charge_min..charge_max px away,
	# it reins in for charge_telegraph s (a lane charge_width px wide on the
	# ground), then gallops up to charge_length px at charge_speed: the
	# necromancer in the lane is struck once (charge_damage_player), every
	# summon in it struck once (charge_damage_summon) and thrown charge_push px
	# aside. It stands charge_recover s, then walks on.
	"kiba_musha": {
		"display_name": "Kiba-musha",
		"max_hp": 70.0,  # TUNING (not in GDD) a mounted soldier
		"move_speed": 66.0,  # TUNING (not in GDD) px/s; a horse
		"damage": 6.0,  # TUNING (not in GDD) a spear thrust, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 15.0,  # TUNING (not in GDD) px; horse and rider
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD) a horse shoves warriors
		"faction": ShogunateEnemyData.FACTION,
		"kit": "kiba",
		"charge_every": 6.0,  # TUNING (not in GDD) s between two charges
		"charge_min": 70.0,  # TUNING (not in GDD) px
		"charge_max": 260.0,  # TUNING (not in GDD) px
		"charge_length": 240.0,  # TUNING (not in GDD) px (cut short by obstacles)
		"charge_width": 26.0,  # TUNING (not in GDD) px
		"charge_telegraph": 0.7,  # TUNING (not in GDD) s
		"charge_speed": 420.0,  # TUNING (not in GDD) px/s
		"charge_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
		"charge_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling
		"charge_push": 26.0,  # TUNING (not in GDD) px
		"charge_recover": 0.5,  # TUNING (not in GDD) s
	},
	# The miniboss: the General of the Left, a samurai general in gold-trimmed
	# black lacquer with antler crests and a red war cloak on a huge black war
	# horse, a naginata levelled. His CHARGE goes THROUGH the ring (the Kiba
	# charge, longer and wider; the necromancer is the aim). Every
	# riders_every s, while fewer than riders_max_alive of his riders ride, he
	# calls riders_count Kiba-musha (the left wing) at his side. Below rage_hp
	# of his HP he charges rage_charges times in a row. Beyond advance_range
	# px he rides advance_speed_mult faster (never left behind).
	"general_left": {
		"display_name": "The General of the Left",
		"max_hp": 2600.0,  # TUNING (not in GDD) before the time / stage scaling (Polyphemus 2500)
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 15.0,  # TUNING (not in GDD) a naginata cut in reach
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 26.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise it like a boss
		"mass": 14.0,  # TUNING (not in GDD) rides warriors down
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": ShogunateEnemyData.FACTION,
		"kit": "general",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 180,  # TUNING (not in GDD) XP burst on death (Polyphemus 180)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"advance_range": 520.0,  # TUNING (not in GDD) px beyond which he rides faster
		"advance_speed_mult": 1.8,  # TUNING (not in GDD)
		"charge_every": 5.0,  # TUNING (not in GDD) s
		"charge_min": 60.0,  # TUNING (not in GDD) px
		"charge_max": 380.0,  # TUNING (not in GDD) px
		"charge_length": 420.0,  # Owner-approved proposal "charges through the ring": well past the necromancer (TUNING the length)
		"charge_width": 44.0,  # TUNING (not in GDD) px
		"charge_telegraph": 0.9,  # TUNING (not in GDD) s
		"charge_speed": 560.0,  # TUNING (not in GDD) px/s
		"charge_damage_player": 16.0,  # TUNING (not in GDD) before the time scaling
		"charge_damage_summon": 20.0,  # TUNING (not in GDD) before the time scaling
		"charge_push": 40.0,  # TUNING (not in GDD) px
		"charge_recover": 0.7,  # TUNING (not in GDD) s
		"riders_every": 18.0,  # TUNING (not in GDD) s between two calls of his riders
		"riders_count": 3,  # TUNING (not in GDD) Kiba-musha per call
		"riders_max_alive": 6,  # TUNING (not in GDD) no call while this many of his riders ride
		"rage_hp": 0.4,  # TUNING (not in GDD) HP share below which he charges twice in a row
		"rage_charges": 2,  # TUNING (not in GDD)
	},
}
