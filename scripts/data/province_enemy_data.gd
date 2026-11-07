## ProvinceEnemyData — immutable design data for the Shogunate kinds that
## join on the Burning Province (Stage 13) (Act V; GDD §15.0 "Act V foundation
## (phase 1)" and "The Burning Province (Act V phase 2)"; owner-approved
## proposal docs/act5/PROPOSAL.md "Roster" and "Stage 13: The Burning
## Province"):
##   kunoichi    — Kunoichi: ELITE (female, figure-redesign style), an
##                 AMBUSHER (From the Shadows). Smoke bombs that BLIND summons
##                 2 s (CombatResolver.blind_unit(), the one summon blind path)
##                 and a telegraphed lunge at the necromancer (KunoichiKit).
##   kappa       — Kappa: NIGHT yokai fodder of the paddies. Water-strong (row
##                 "swimmer": the paddy water never slows it, ProvinceDirector)
##                 and it GRAPPLES a summon briefly (held through the one
##                 compel path, SummonedUnit.compel() with no speed; KappaKit).
##   shuten_doji — Shuten-dōji, the Oni King: the stage MINIBOSS, NIGHT only
##                 (the "shuten_doji" timeline event waits for the night).
##                 Drunk and enormous: a swaying gait, the oni's kanabō smash,
##                 and SAKE BARRELS thrown onto landing circles that burst into
##                 fire (ProvinceHazards fire patches; ShutenKit).
##   kage_clone  — a shadow clone of Kage (her boss fight, BossKage): her look,
##                 a short life, weak blows; light reveals it as false (it
##                 dissolves; KageCloneKit). Never in a timeline.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.shogunate_def() looks these rows up after
## ShogunateEnemyData. Rows have every key of a ShogunateEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/shogunate/<kit>_kit.gd, unique
## across the Eye, Empire, Pantheon and Shogunate folders; "night", "draws",
## "ambusher", "ethereal" switch the shared rules on for the kind) plus the
## Province key "swimmer" (true: the paddy water does not slow it) and each
## kit's own numbers (documented on each row).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name ProvinceEnemyData
extends RefCounted

## Kind id of the Kunoichi.
const KUNOICHI: String = "kunoichi"
## Kind id of the Kappa.
const KAPPA: String = "kappa"
## Kind id of Shuten-dōji, the Oni King (the stage miniboss).
const SHUTEN_DOJI: String = "shuten_doji"
## Kind id of Kage's shadow clones (BossKage spawns them).
const KAGE_CLONE: String = "kage_clone"
## Damage source tag of a Kunoichi's lunge (KunoichiKit).
const LUNGE_SOURCE: String = "kunoichi_lunge"
## Damage source tag of a Kappa's grapple squeeze (KappaKit).
const GRAPPLE_SOURCE: String = "kappa_grapple"
## Damage source tag of a sake barrel bursting (ShutenKit).
const BARREL_SOURCE: String = "sake_barrel"
## Damage source tag of a sake fire patch (ProvinceHazards).
const SAKE_FIRE_SOURCE: String = "sake_fire"

## Kind id -> design row.
const ENEMIES := {
	# Elite (female, figure-redesign style): an indigo-black kunoichi, a lacquer
	# red sash and scarf, a short tanto; she comes out of the shadows.
	#   smoke_every    — s between two smoke bombs (her first after half).
	#   smoke_range    — px: she throws when a summon stands this close to her.
	#   smoke_radius   — px of the smoke cloud.
	#   smoke_flight   — s the bomb flies before it bursts (a landing circle).
	#   smoke_life     — s the cloud hangs (drawing; the blind is applied once).
	#   smoke_blind    — s every summon in the burst is BLINDED (owner-approved
	#                    "blind summons for 2 s"; CombatResolver.blind_unit()).
	#   lunge_every    — s between two lunges.
	#   lunge_min / lunge_max — px: she lunges at a necromancer this far.
	#   lunge_telegraph — s the lane shows before she goes.
	#   lunge_length   — px of the lunge (cut short by obstacles).
	#   lunge_width    — px of the lane.
	#   lunge_speed    — px/s.
	#   lunge_damage   — damage to the necromancer in her lane (once; before the
	#                    time scaling). She leaps over the ring: summons are not hit.
	"kunoichi": {
		"display_name": "Kunoichi",
		"max_hp": 64.0,  # TUNING (not in GDD) an elite of the ninja (Ninja 30)
		"move_speed": 80.0,  # TUNING (not in GDD) px/s; quick
		"damage": 6.0,  # TUNING (not in GDD) a tanto cut, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD) an elite's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1: kill her on appear
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": ShogunateEnemyData.FACTION,
		"kit": "kunoichi",
		"always_elite": true,  # Owner-approved proposal: "Kunoichi | Elite"
		"ambusher": true,  # From the Shadows, like the ninja (owner-approved roster: a ninja elite)
		"smoke_every": 7.0,  # TUNING (not in GDD) s
		"smoke_range": 160.0,  # TUNING (not in GDD) px
		"smoke_radius": 50.0,  # TUNING (not in GDD) px
		"smoke_flight": 0.5,  # TUNING (not in GDD) s
		"smoke_life": 2.0,  # TUNING (not in GDD) s (drawing)
		"smoke_blind": 2.0,  # Owner-approved proposal: "smoke bombs that blind summons 2 s"
		"lunge_every": 6.0,  # TUNING (not in GDD) s
		"lunge_min": 50.0,  # TUNING (not in GDD) px
		"lunge_max": 200.0,  # TUNING (not in GDD) px
		"lunge_telegraph": 0.55,  # TUNING (not in GDD) s
		"lunge_length": 210.0,  # TUNING (not in GDD) px
		"lunge_width": 22.0,  # TUNING (not in GDD) px
		"lunge_speed": 560.0,  # TUNING (not in GDD) px/s
		"lunge_damage": 8.0,  # TUNING (not in GDD) before the time scaling (a Draw cut 13)
	},
	# Night fodder: a green river imp with a turtle shell, a beak and a water
	# dish on its head; lurks in the paddies.
	#   grapple_every — s between two grapples (its first after half).
	#   grapple_reach — px (edge to edge): it grapples a summon this close.
	#   grapple_hold  — s it holds the summon fast (it holds still too).
	#   grapple_tick  — s between two squeezes while it holds.
	#   grapple_damage — damage of a squeeze (before the time scaling).
	"kappa": {
		"display_name": "Kappa",
		"max_hp": 22.0,  # TUNING (not in GDD) fodder with a shell (Onryō 15)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) a clawed grab, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD) its shell
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": ShogunateEnemyData.FACTION,
		"kit": "kappa",
		"night": true,  # Owner-approved brief: "night yokai fodder of the paddies"
		"fodder": true,
		"swimmer": true,  # Owner-approved brief: "water-strong (no slow in water)" (ProvinceDirector)
		"grapple_every": 7.0,  # TUNING (not in GDD) s
		"grapple_reach": 8.0,  # TUNING (not in GDD) px
		"grapple_hold": 1.2,  # Owner-approved brief: "grapples a summon briefly"; TUNING the length
		"grapple_tick": 0.4,  # TUNING (not in GDD) s
		"grapple_damage": 2.0,  # TUNING (not in GDD) before the time scaling
	},
	# The miniboss: Shuten-dōji, the Oni King, drunk and enormous: a crimson
	# giant, a wild white mane, horns, a sake gourd on his belt, a great kanabō,
	# a sake barrel on his shoulder. NIGHT only (the "shuten_doji" event waits
	# for night). Keys of the Oni row (his smash) plus:
	#   throw_cooldown / first_throw — s between two barrel volleys / before the first.
	#   throw_range   — px: he throws at a necromancer this far.
	#   throw_windup  — s the barrel is raised over his head.
	#   barrel_flight — s from his hand to the ground (the landing circle).
	#   barrel_lead   — share of the flight a moving target is led by.
	#   barrels       — barrels per volley (rage_barrels in his rage).
	#   barrel_spread — px between the landing points of one volley.
	#   barrel_radius — px of the burst (the landing circle).
	#   barrel_damage_player / barrel_damage_summon — damage of the burst.
	#   fire_radius   — px of the sake fire left where a barrel burst.
	#   fire_life     — s the fire burns.
	#   fire_tick     — s between two burns of the fire.
	#   fire_damage_player / fire_damage_summon — damage of one burn.
	#   sway / sway_rate — px/s and rad/s of his drunken sway (a sine).
	#   advance_range / advance_speed_mult — farther than this he strides faster.
	#   rage_hp       — share of max HP below which he drains his gourd (once).
	#   rage_cd_mult  — x the throw cooldown in his rage.
	#   recover_time  — s he stands after a throw.
	"shuten_doji": {
		"display_name": "Shuten-dōji, the Oni King",
		"max_hp": 2600.0,  # TUNING (not in GDD) before the time / stage scaling (Polyphemus 2500)
		"move_speed": 34.0,  # TUNING (not in GDD) px/s
		"damage": 15.0,  # TUNING (not in GDD) a fist in reach, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px edge to edge
		"radius": 28.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"flat_armor": 4.0,  # TUNING (not in GDD) the oni's flat armour (owner-approved roster)
		"xp": 0,  # His reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise him like a boss
		"mass": 16.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": ShogunateEnemyData.FACTION,
		"kit": "shuten_doji",
		"night": true,  # Owner-approved proposal: "(night only)"
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 190,  # TUNING (not in GDD) XP burst on death (Polyphemus 180)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"advance_range": 520.0,  # TUNING (not in GDD) px
		"advance_speed_mult": 1.8,  # TUNING (not in GDD)
		# The kanabō smash (OniKit; keys as the Oni row).
		"smash_every": 6.5,  # TUNING (not in GDD) s
		"smash_trigger": 40.0,  # TUNING (not in GDD) px
		"smash_windup": 0.9,  # TUNING (not in GDD) s
		"smash_radius": 66.0,  # TUNING (not in GDD) px
		"smash_damage": 12.0,  # TUNING (not in GDD) before the time scaling
		"smash_stun": 0.9,  # TUNING (not in GDD) s
		# Sake barrels (owner-approved proposal: "throws sake barrels that burst into fire").
		"throw_cooldown": 7.5,  # TUNING (not in GDD) s
		"first_throw": 3.0,  # TUNING (not in GDD) s after he arrives
		"throw_range": 480.0,  # TUNING (not in GDD) px
		"throw_windup": 0.8,  # TUNING (not in GDD) s
		"barrel_flight": 1.2,  # TUNING (not in GDD) s
		"barrel_lead": 0.5,  # TUNING (not in GDD)
		"barrels": 2,  # TUNING (not in GDD)
		"rage_barrels": 4,  # TUNING (not in GDD)
		"barrel_spread": 90.0,  # TUNING (not in GDD) px
		"barrel_radius": 44.0,  # TUNING (not in GDD) px
		"barrel_damage_player": 8.0,  # TUNING (not in GDD) before the time scaling (a Polyphemus boulder 11)
		"barrel_damage_summon": 5.0,  # TUNING (not in GDD) before the time scaling (a Polyphemus boulder 6)
		"fire_radius": 38.0,  # TUNING (not in GDD) px
		"fire_life": 4.5,  # TUNING (not in GDD) s
		"fire_tick": 0.5,  # TUNING (not in GDD) s
		"fire_damage_player": 2.0,  # TUNING (not in GDD) per burn, before the time scaling
		"fire_damage_summon": 2.0,  # TUNING (not in GDD) per burn, before the time scaling
		"sway": 22.0,  # TUNING (not in GDD) px/s; he is drunk
		"sway_rate": 1.1,  # TUNING (not in GDD) rad/s
		"rage_hp": 0.5,  # TUNING (not in GDD)
		"rage_cd_mult": 0.65,  # TUNING (not in GDD)
		"recover_time": 0.6,  # TUNING (not in GDD) s
	},
	# Kage's shadow clone (BossKage): her shape in smoke-dark indigo. Weak
	# blows, a short life; a clone that stands in light (SunCourse.light_at() at
	# least KageData.BOSS reveal_light for reveal_time s) is revealed as false
	# and dissolves. No XP, no corpse, no drops.
	"kage_clone": {
		"display_name": "Shadow of Kage",
		"max_hp": 130.0,  # TUNING (not in GDD) before the time / stage scaling: a few blows
		"move_speed": 64.0,  # TUNING (not in GDD) px/s (Kage 66)
		"damage": 5.0,  # TUNING (not in GDD) a shadow blade (Kage 13), before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 14.0,  # TUNING (not in GDD) px (as Kage: the clones must look like her)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 0,  # A shadow: nothing to collect.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) as Kage: the army wastes its blows on her shadows (owner-approved "only one is real")
		"mass": 3.0,  # TUNING (not in GDD)
		"faction": ShogunateEnemyData.FACTION,
		"kit": "kage_clone",
	},
}
