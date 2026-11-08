## ValgardEnemyData — immutable design data for the Norse kinds that join on Valgard, the Hall of Heroes
## (Stage 17 in the final order; the Hall of the Slain, temporarily Act XI;
## GDD §15.0 "Valgard, the Hall of Heroes (the Hall of the Slain phase 2)"; the
## act's section of docs/proposals/LAST_SIX_ACTS.md). Phase 2 adds the stage's
## own kinds here:
##   einherjar          — warriors, elite soldier (male): a gold-lit hero of the
##                        hall (the art pass's norse/einherjar). THE FEAST:
##                        they sit at the long tables (drawn by ValgardDirector,
##                        no body) and wake whenever a horn blows
##                        (RuneStones.horn_blown, the Einherjar Champion's horn,
##                        Sigrun's Doors of the Hall), then fight. EinherjarKit
##                        makes every one an Einherjar at once
##                        (NorseKit.make_einherjar(): gold, stronger).
##   einherjar_champion — the stage MINIBOSS (male): a gold-lit hero of a
##                        thousand years in the hall (EinherjarChampionKit: the
##                        Hero's Sweep, the Champion's Horn that wakes the
##                        Feast; the HUD's miniboss bar, the chest, an XP burst).
##   wing_valkyrie      — hall, flying elite (female, figure style): SIGRUN'S
##                        VALKYRIE WING (WingValkyrieKit: the shared valkyrie's
##                        dive and flight, plus the CHARGE lanes Sigrun calls;
##                        drawn with the shared norse/valkyrie art).
## EnemyDirector.norse_def() looks these rows up after NorseEnemyData.
## Rows have every key of a NorseEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/norse/<kit>_kit.gd, unique across the Eye, Empire,
## Pantheon, Shogunate, Inferno, Court, City, Concord, Black Tide and Norse
## folders; "warrior" puts a kind under Berserkergang), plus:
##   sweep_*   — the Champion's Hero's Sweep (every / trigger / radius / windup
##               / damage_player / damage_summon / push).
##   horn_*    — the Champion's Horn (first / every / wake: seated Einherjar
##               it wakes / escort: Einherjar beside him when no Feast runs).
##   charge_*  — the wing's charge lane (it reads Sigrun's numbers, SigrunData;
##               the row only carries the dive's).
##   reward_xp / reward_crystals — the miniboss's XP burst.
## The GDD gives no numbers: everything is TUNING (not in GDD), tuned for the
## act's final slot VI.
class_name ValgardEnemyData
extends RefCounted

## Kind id of the feasting Einherjar.
const EINHERJAR: String = "einherjar"
## Kind id of the Einherjar Champion (the miniboss).
const CHAMPION: String = "einherjar_champion"
## Kind id of Sigrun's valkyrie wing.
const WING: String = "wing_valkyrie"
## Damage tag of the Champion's Hero's Sweep.
const SWEEP_SOURCE: String = "champion_sweep"
## Sprite key the wing valkyries draw (the shared valkyrie's art).
const WING_SPRITE: String = "norse/valkyrie"

## Kind id -> design row.
const ENEMIES := {
	# The feasting Einherjar (see the header). The kit makes each one an
	# Einherjar (x NorseRulesData.EINHERJAR hp 1.35 / damage 1.25 / speed 1.1 on
	# top of these numbers).
	"einherjar": {
		"display_name": "Einherjar",
		"max_hp": 64.0,  # TUNING (not in GDD) x1.35 = 86: an elite soldier (shield-maiden 44)
		"move_speed": 54.0,  # TUNING (not in GDD) px/s (x1.1 = 59)
		"damage": 4.5,  # TUNING (not in GDD) a sword blow, before the time scaling (x1.25 = 5.6)
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~46 px sprite)
		"armor": 0.15,  # TUNING (not in GDD) a round shield and gilded mail
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 1.6,  # TUNING (not in GDD)
		"faction": NorseEnemyData.FACTION,
		"kit": "einherjar",
		"group": "warriors",
		"warrior": true,  # Berserkergang: a hero of the hall.
	},  # The feasting Einherjar (Valgard).
	# The Einherjar Champion (see the header): the miniboss of Valgard.
	"einherjar_champion": {
		"display_name": "Einherjar Champion",
		"max_hp": 2200.0,  # TUNING (not in GDD) a miniboss (Warbeast 2,100, Mammoth 2,200)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 9.0,  # TUNING (not in GDD) a war-axe blow, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 20.0,  # TUNING (not in GDD) px (x 1.35 as an elite = 27; a ~60 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) gilded mail
		"flat_armor": 3.0,  # TUNING (not in GDD) own decision: a thousand years of armour (Wither shreds it)
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 30.0,  # TUNING (not in GDD) heavy
		"slow_resist": 0.6,  # TUNING (not in GDD) like a miniboss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": NorseEnemyData.FACTION,
		"kit": "einherjar_champion",
		"group": "warriors",
		"warrior": true,  # Own decision: a hero of the hall, he goes berserk below 40% (his second wind).
		"sweep_every": 5.5,  # TUNING (not in GDD) s
		"sweep_trigger": 70.0,  # TUNING (not in GDD) px from his edge to his target's
		"sweep_radius": 64.0,  # TUNING (not in GDD) px
		"sweep_windup": 0.75,  # TUNING (not in GDD) s (the telegraph circle)
		"sweep_damage_player": 8.0,  # TUNING (not in GDD) before the time scaling
		"sweep_damage_summon": 11.0,  # TUNING (not in GDD) before the time scaling
		"sweep_push": 24.0,  # TUNING (not in GDD) px
		"horn_first": 6.0,  # TUNING (not in GDD) s after he arrives
		"horn_every": 24.0,  # TUNING (not in GDD) s
		"horn_wake": 3,  # TUNING (not in GDD) seated Einherjar his horn wakes (the Feast)
		"horn_escort": 2,  # TUNING (not in GDD) Einherjar that rise beside him instead when no Feast runs (another stage)
		"reward_xp": 260,  # TUNING (not in GDD) a miniboss (Warbeast 260)
		"reward_crystals": 12,  # TUNING (not in GDD)
	},  # The Einherjar Champion (Valgard).
	# Sigrun's valkyrie wing (see the header): the shared valkyrie's numbers and
	# dive, a little tougher; the Charge's lanes read SigrunData.
	"wing_valkyrie": {
		"display_name": "Valkyrie of the Wing",
		"max_hp": 110.0,  # TUNING (not in GDD) a flying elite (the valkyrie 90)
		"move_speed": 70.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) a spear thrust from above, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 11.0,  # TUNING (not in GDD) px (~52 px sprite with wings)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": NorseEnemyData.FACTION,
		"kit": "wing_valkyrie",
		"group": "hall",
		"flies": true,  # The Night Wings test (as the shared valkyrie).
		"phases": true,  # She flies over the obstacles.
		"flight_melee_taken": 0.0,  # As the shared valkyrie: no grounded blow reaches her aloft
		"figure": true,
		"elite_kind": true,
		"dive_every": 8.0,  # TUNING (not in GDD) s (her own dives between Sigrun's charges)
		"dive_trigger": 240.0,  # TUNING (not in GDD) px
		"dive_rise": 0.8,  # TUNING (not in GDD) s
		"dive_fall": 0.25,  # TUNING (not in GDD) s
		"dive_radius": 36.0,  # TUNING (not in GDD) px
		"dive_damage": 6.0,  # TUNING (not in GDD) before the time scaling
		"dive_push": 24.0,  # TUNING (not in GDD) px
		"landed_time": 1.3,  # TUNING (not in GDD) s on the ground after a dive or a charge (every blow lands)
	},  # Sigrun's valkyrie wing (Valgard).
}
