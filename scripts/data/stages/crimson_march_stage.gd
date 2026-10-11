## CrimsonMarchStage — STAGE 2, THE CRIMSON MARCH (GDD §8.2): the
## necromancer's army marches on the Covenant headquarters ("counteroffensive
## and siege"). Every number and event that belongs to this stage. StageRegistry
## exposes it to the run as `Game.stage_def` (the STAGE dictionary at the
## bottom; its keys are documented in StageRegistry). Unlocked by slaying Sir
## Alaric once (GDD §9.3).
##
## Open question 3 (zone progression vs the fixed timeline), resolved in GDD
## §15.0: THE CLOCK IS AUTHORITATIVE. The march passes through four battle
## zones on fixed times (ZONES). At each zone change MarchDirector shows a
## zone banner, a fog of war sweeps over the field and the terrain around the
## necromancer is re-drawn as the next zone (new ground look and new obstacle
## layout; a clear circle around him so nobody is trapped). Outposts, ward
## generators and supply carts are timeline events placed near him, so a run
## never soft-locks on geography and Marshal Vael always arrives at 17:00.
##
## Timeline (GDD §8.2 time -> prototype elapsed; the 24:00 boss moves to 17:00
## like Sir Alaric, so the two late beats move just before him):
##   GDD time   Event                          Prototype
##   00:00      Patrols                        0:00  Zone I, the Burned Road
##   04:00      Fortified checkpoint           4:00  Zone II (watchtower + shield line)
##   06:00      Templar ambush                 6:00
##   09:00      Siege outpost                  9:00  Zone III, the Siege Camp (2 outposts)
##   12:00      Heavy infantry                 12:00 (halberdiers + shieldbearers)
##   15:00      Ward generator                 15:00 Zone IV, the Fortress Approach
##   18:00      Cathedral defenders mobilize   16:00 (moved before the boss)
##   20:00      Fortress assault               16:30 (moved before the boss)
##   24:00      Marshal Vael boss              17:00 (3:00 left, same run structure)
## Supply carts (GDD §8.2 "optional rewards") roll past at 2:30, 6:40, 10:30
## and 13:20; the battlefield dead (this stage's empowered graves) rise on the
## Graveyard's schedule. Gap-filling waves, all rates, caps and weights are
## TUNING (not in GDD). The stage is harder than the Graveyard (GDD campaign
## intent): tougher enemy kinds earlier, slightly denser segments and the
## stage multipliers ENEMY_HP_MULT / ENEMY_DAMAGE_MULT.
class_name CrimsonMarchStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "crimson_march"

## Game time (s) at which Marshal Vael appears (3:00 left on the countdown).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) GDD §8.2 places him at 24:00; same 17:00 as Sir Alaric (user decision)

## Enemy max-HP multiplier of this stage on top of the shared time scaling.
const ENEMY_HP_MULT: float = 1.1  # TUNING (not in GDD) GDD §9.3 campaign: each chapter steps up
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.05  # TUNING (not in GDD)
## Soul Ash multiplier of a run on this stage (shown as its own end-screen line).
const ASH_MULT: float = 1.25  # TUNING (not in GDD) user brief "e.g. x1.25"

## The Reckoning (same escalation as the Graveyard; only the flavour differs).
## Keys as GraveyardStage.RECKONING.
const RECKONING := {
	"banner": "THE RECKONING: THE FORTRESS GATES OPEN",
	"interval": 10.0,  # TUNING (not in GDD) user brief "every ~10s"
	"base_count": 3,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE RECKONING: the whole garrison marches out. Endure."

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS). New kinds: shieldbearer from 4:00, banner bearer
## from 9:00, halberdier from 12:00 (MarchEnemyData).
const SEGMENTS := [
	# Zone I, the Burned Road: GDD §8.2 "00:00 Patrols".
	{"start": 0.0, "rate": 1.5, "max_alive": 32,  # TUNING (not in GDD)
		"weights": {"recruit": 1.0},
		"objective": "The Burned Road: Covenant patrols bar the way"},
	{"start": 60.0, "rate": 1.8, "max_alive": 42,  # TUNING (not in GDD) recruits only (was 10% footmen; see the 0:12 patrol)
		"weights": {"recruit": 1.0},
		"objective": "March on: the patrols grow bolder"},
	{"start": 120.0, "rate": 2.0, "max_alive": 52,  # TUNING (not in GDD)
		"weights": {"recruit": 0.8, "footman": 0.12, "archer": 0.08},
		"objective": "The Burned Road: carts and patrols ahead"},
	{"start": 180.0, "rate": 2.2, "max_alive": 58,  # TUNING (not in GDD)
		"weights": {"recruit": 0.66, "footman": 0.2, "archer": 0.1, "chaplain": 0.04},
		"objective": "The checkpoint is near: break the patrols"},
	# Zone II, the Fortified Checkpoint: GDD §8.2 "04:00 Fortified checkpoint".
	{"start": 240.0, "rate": 2.4, "max_alive": 64,  # TUNING (not in GDD)
		"weights": {"recruit": 0.56, "footman": 0.2, "archer": 0.1, "shieldbearer": 0.1, "chaplain": 0.04},
		"objective": "The Fortified Checkpoint: tower shields stop spells and arrows"},
	{"start": 300.0, "rate": 2.7, "max_alive": 75,  # TUNING (not in GDD)
		"weights": {"recruit": 0.52, "footman": 0.2, "archer": 0.1, "shieldbearer": 0.13, "chaplain": 0.05},
		"objective": "Break through the checkpoint"},
	# GDD §8.2 "06:00 Templar ambush".
	{"start": 360.0, "rate": 2.9, "max_alive": 85,  # TUNING (not in GDD)
		"weights": {"recruit": 0.5, "footman": 0.2, "archer": 0.1, "shieldbearer": 0.1, "chaplain": 0.05, "templar": 0.05},
		"objective": "Templar ambush: hold your lines"},
	{"start": 420.0, "rate": 2.6, "max_alive": 80,  # TUNING (not in GDD) lull
		"weights": {"recruit": 0.5, "footman": 0.2, "archer": 0.1, "shieldbearer": 0.1, "chaplain": 0.05, "templar": 0.05},
		"objective": "The road to the siege camp opens"},
	{"start": 450.0, "rate": 3.0, "max_alive": 90,  # TUNING (not in GDD)
		"weights": {"recruit": 0.46, "footman": 0.2, "archer": 0.1, "shieldbearer": 0.1, "chaplain": 0.05, "purifier": 0.06, "templar": 0.03},
		"objective": "Purifiers hunt your undead along the road"},
	# Zone III, the Siege Camp: GDD §8.2 "09:00 Siege outpost".
	{"start": 540.0, "rate": 3.4, "max_alive": 105,  # TUNING (not in GDD)
		"weights": {"recruit": 0.42, "footman": 0.18, "archer": 0.12, "shieldbearer": 0.1, "chaplain": 0.05, "purifier": 0.08, "templar": 0.03, "banner_bearer": 0.02},
		"objective": "The Siege Camp: Banner Bearers rally the Covenant"},
	{"start": 600.0, "rate": 3.8, "max_alive": 115,  # TUNING (not in GDD)
		"weights": {"recruit": 0.42, "footman": 0.18, "archer": 0.12, "shieldbearer": 0.1, "chaplain": 0.05, "purifier": 0.08, "templar": 0.03, "banner_bearer": 0.02},
		"objective": "Burn the siege camp"},
	{"start": 660.0, "rate": 3.4, "max_alive": 110,  # TUNING (not in GDD) lull before the heavy infantry
		"weights": {"recruit": 0.42, "footman": 0.18, "archer": 0.12, "shieldbearer": 0.1, "chaplain": 0.05, "purifier": 0.08, "templar": 0.03, "banner_bearer": 0.02},
		"objective": "Steel yourself: the heavy infantry forms up"},
	# GDD §8.2 "12:00 Heavy infantry".
	{"start": 720.0, "rate": 4.4, "max_alive": 135,  # TUNING (not in GDD)
		"weights": {"recruit": 0.36, "footman": 0.16, "archer": 0.12, "shieldbearer": 0.12, "halberdier": 0.08, "chaplain": 0.05, "purifier": 0.07, "templar": 0.03, "banner_bearer": 0.02},
		"objective": "Heavy infantry: halberds cleave your packed ranks"},
	{"start": 780.0, "rate": 4.8, "max_alive": 145,  # TUNING (not in GDD)
		"weights": {"recruit": 0.36, "footman": 0.16, "archer": 0.12, "shieldbearer": 0.12, "halberdier": 0.08, "chaplain": 0.05, "purifier": 0.07, "templar": 0.03, "banner_bearer": 0.02},
		"objective": "Grind through the heavy infantry"},
	{"start": 840.0, "rate": 4.4, "max_alive": 140,  # TUNING (not in GDD) lull before the fortress
		"weights": {"recruit": 0.36, "footman": 0.16, "archer": 0.12, "shieldbearer": 0.12, "halberdier": 0.08, "chaplain": 0.05, "purifier": 0.07, "templar": 0.03, "banner_bearer": 0.02},
		"objective": "The fortress towers rise ahead"},
	# Zone IV, the Fortress Approach: GDD §8.2 "15:00 Ward generator".
	{"start": 900.0, "rate": 6.0, "max_alive": 165,  # TUNING (not in GDD) the density peak of the run
		"weights": {"recruit": 0.36, "footman": 0.16, "archer": 0.12, "shieldbearer": 0.12, "halberdier": 0.08, "chaplain": 0.05, "purifier": 0.08, "templar": 0.03, "banner_bearer": 0.02},
		"objective": "The Fortress Approach: holy wards protect the walls"},
	# GDD §8.2 "18:00 Cathedral defenders mobilize" (moved to 16:00, before the boss).
	{"start": 960.0, "rate": 5.0, "max_alive": 160,  # TUNING (not in GDD)
		"weights": {"recruit": 0.32, "footman": 0.16, "archer": 0.12, "shieldbearer": 0.12, "halberdier": 0.1, "chaplain": 0.06, "purifier": 0.08, "templar": 0.04, "banner_bearer": 0.02},
		"objective": "The cathedral defenders mobilize: Marshal Vael approaches"},
	# 17:00, Marshal Vael: a thinner trickle so the duel stays readable.
	{"start": BOSS_TIME, "rate": 3.2, "max_alive": 100,  # TUNING (not in GDD)
		"weights": {"recruit": 0.5, "footman": 0.2, "archer": 0.15, "shieldbearer": 0.1, "purifier": 0.05},
		"objective": "Marshal Vael, the Crimson Bulwark, holds the gates"},
	{"start": 1110.0, "rate": 4.0, "max_alive": 120,  # TUNING (not in GDD)
		"weights": {"recruit": 0.45, "footman": 0.2, "archer": 0.15, "shieldbearer": 0.1, "purifier": 0.1},
		"objective": "Marshal Vael, the Crimson Bulwark, holds the gates"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave" entries: formation + groups), plus the Crimson March types run by
## MarchDirector:
##   "outposts"   — `count` structures of MarchEnemyData kind `kind` placed
##                  `distance_min`..`distance_max` px from the necromancer;
##                  each spawns `groups` (list of {kind, count, elite}) every
##                  `interval` s while he is within MARCH.active_radius,
##                  until destroyed (GDD §8.2 "outposts spawn reinforcements
##                  until destroyed"). `reward_xp` / `reward_crystals`: XP
##                  burst when one falls; `reward_chest` (optional): it also
##                  drops a treasure chest. `escort`: an optional formation
##                  wave {formation, groups} that arrives with them.
##   "generators" — `count` Holy Ward Generators (kind `kind`), each the
##                  centre of a holy zone (`zone`, keys as a holy zone) that
##                  lasts until the generator is destroyed (GDD §8.2 "Holy
##                  Ward Generators damage/weaken summons in areas"). Same
##                  distance / reward / escort keys as "outposts".
##   "cart"       — a supply cart (kind `kind`) rolls PAST the necromancer:
##                  it appears `pass_distance` px from him on one side,
##                  `pass_offset` px off his line, and drives to the mirrored
##                  point on the other side, escorted by `escort` groups; it
##                  escapes after `lifetime` s. Destroying it pays `reward_xp`
##                  in `reward_crystals` crystals plus the next power-up of
##                  MARCH.cart_rewards (GDD §8.2 "destroy enemy supply carts
##                  for optional rewards").
const EVENTS := [
	# Zone I: patrols (GDD §8.2 00:00).
	# Combined balance pass: the first two patrols are recruits only (were 6 + 2 footmen
	# and 10 + 2 footmen). Every build opens with Shadow Bolt and 2 warriors, and armoured
	# footmen in the first minute let the patrols kill both warriors whenever the first
	# cards held no damage: 6 of 8 army runs fell behind at 1:00 (about 30 foes alive
	# instead of 15) and 4 of them never recovered. The stage step-up now starts with
	# the 1:50 sergeant and the 2:00 footmen.
	{"time": 12.0, "type": "wave", "banner": "A Covenant patrol blocks the road!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 8, "elite": false}]},
	{"time": 45.0, "type": "wave", "banner": "A patrol column marches down the road!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 12, "elite": false}]},
	{"time": 80.0, "type": "wave", "banner": "Patrols close in from the burned fields!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 12, "elite": false}]},
	{"time": 110.0, "type": "wave", "banner": "A patrol sergeant leads the charge!", "formation": "arc",  # TUNING (not in GDD) first elite
		"groups": [{"kind": "footman", "count": 1, "elite": true}, {"kind": "recruit", "count": 10, "elite": false}]},
	{"time": 150.0, "type": "cart", "banner": "A Covenant supply cart rumbles past: destroy it for spoils!",  # GDD §8.2 supply carts
		"kind": "supply_cart", "pass_distance": 240.0, "pass_offset": 90.0, "lifetime": 30.0,  # TUNING (not in GDD)
		"reward_xp": 20, "reward_crystals": 4,  # TUNING (not in GDD)
		"escort": [{"kind": "recruit", "count": 4, "elite": false}]},  # TUNING (not in GDD)
	{"time": 180.0, "type": "wave", "banner": "Archers on the ridge!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "archer", "count": 4, "elite": false}, {"kind": "footman", "count": 4, "elite": false}, {"kind": "recruit", "count": 6, "elite": false}]},
	{"time": 210.0, "type": "wave", "banner": "The patrols surround you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 16, "elite": false}, {"kind": "footman", "count": 4, "elite": false}]},
	# Zone II: the fortified checkpoint (GDD §8.2 04:00).
	{"time": 240.0, "type": "outposts", "banner": "A fortified checkpoint bars the road: tear down its watchtower!",  # GDD §8.2 04:00
		"kind": "watchtower", "count": 1, "distance_min": 230.0, "distance_max": 290.0,  # TUNING (not in GDD)
		"interval": 14.0,  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 3, "elite": false}, {"kind": "archer", "count": 1, "elite": false}],  # TUNING (not in GDD)
		"reward_xp": 25, "reward_crystals": 5,  # TUNING (not in GDD)
		"escort": {"formation": "line", "groups": [{"kind": "shieldbearer", "count": 6, "elite": false}, {"kind": "footman", "count": 4, "elite": false}]}},  # TUNING (not in GDD)
	{"time": 285.0, "type": "wave", "banner": "Shieldbearers advance behind their tower shields!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "shieldbearer", "count": 4, "elite": false}, {"kind": "archer", "count": 4, "elite": false}, {"kind": "chaplain", "count": 1, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "The checkpoint garrison sallies out!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 16, "elite": false}, {"kind": "footman", "count": 4, "elite": false}, {"kind": "shieldbearer", "count": 1, "elite": true}]},
	# GDD §8.2 06:00 Templar ambush.
	{"time": 360.0, "type": "wave", "banner": "AMBUSH! Templar Knights charge from the treeline!", "formation": "ring",  # GDD §8.2 06:00
		"groups": [{"kind": "templar", "count": 4, "elite": false}, {"kind": "templar", "count": 1, "elite": true}, {"kind": "footman", "count": 6, "elite": false}]},
	{"time": 400.0, "type": "cart", "banner": "Another supply cart tries to slip past!",  # GDD §8.2 supply carts
		"kind": "supply_cart", "pass_distance": 240.0, "pass_offset": 90.0, "lifetime": 30.0,  # TUNING (not in GDD)
		"reward_xp": 25, "reward_crystals": 5,  # TUNING (not in GDD)
		"escort": [{"kind": "footman", "count": 3, "elite": false}, {"kind": "recruit", "count": 3, "elite": false}]},  # TUNING (not in GDD)
	{"time": 435.0, "type": "wave", "banner": "Purifiers and archers flank the road!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "purifier", "count": 6, "elite": false}, {"kind": "archer", "count": 4, "elite": false}]},
	{"time": 480.0, "type": "wave", "banner": "A shield wall marches on you!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "shieldbearer", "count": 8, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}, {"kind": "archer", "count": 3, "elite": false}]},
	{"time": 515.0, "type": "wave", "banner": "The Covenant surges down the road!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 22, "elite": false}, {"kind": "footman", "count": 6, "elite": false}, {"kind": "purifier", "count": 4, "elite": false}]},
	# Zone III: the siege camp (GDD §8.2 09:00 Siege outpost).
	{"time": 540.0, "type": "outposts", "banner": "Siege outposts pour out reinforcements: destroy them!",  # GDD §8.2 09:00
		"kind": "outpost", "count": 2, "distance_min": 250.0, "distance_max": 330.0,  # TUNING (not in GDD)
		"interval": 12.0,  # TUNING (not in GDD)
		"groups": [{"kind": "footman", "count": 2, "elite": false}, {"kind": "recruit", "count": 2, "elite": false}, {"kind": "archer", "count": 1, "elite": false}],  # TUNING (not in GDD)
		"reward_xp": 30, "reward_crystals": 6,  # TUNING (not in GDD)
		"escort": {"formation": "arc", "groups": [{"kind": "footman", "count": 6, "elite": false}, {"kind": "archer", "count": 4, "elite": false}]}},  # TUNING (not in GDD)
	{"time": 580.0, "type": "wave", "banner": "A Banner Bearer rallies the line!", "formation": "arc",  # TUNING (not in GDD) GDD §7.2 Banner Bearer
		"groups": [{"kind": "banner_bearer", "count": 2, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "archer", "count": 4, "elite": false}]},
	{"time": 630.0, "type": "cart", "banner": "A heavy supply wagon leaves the camp: stop it!",  # GDD §8.2 supply carts
		"kind": "supply_cart", "pass_distance": 240.0, "pass_offset": 90.0, "lifetime": 30.0,  # TUNING (not in GDD)
		"reward_xp": 40, "reward_crystals": 8,  # TUNING (not in GDD)
		"escort": [{"kind": "footman", "count": 4, "elite": false}, {"kind": "shieldbearer", "count": 2, "elite": false}]},  # TUNING (not in GDD)
	{"time": 660.0, "type": "wave", "banner": "The camp turns out against you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 24, "elite": false}, {"kind": "purifier", "count": 6, "elite": false}, {"kind": "templar", "count": 2, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}]},
	{"time": 700.0, "type": "wave", "banner": "Templars ride under a holy banner!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "templar", "count": 3, "elite": false}, {"kind": "banner_bearer", "count": 1, "elite": false}, {"kind": "footman", "count": 6, "elite": false}]},
	# GDD §8.2 12:00 Heavy infantry.
	{"time": 720.0, "type": "wave", "banner": "Heavy infantry advances: halberds and tower shields!", "formation": "line",  # GDD §8.2 12:00
		"groups": [{"kind": "halberdier", "count": 6, "elite": false}, {"kind": "shieldbearer", "count": 6, "elite": false}, {"kind": "halberdier", "count": 1, "elite": true}]},
	{"time": 765.0, "type": "wave", "banner": "Halberdiers and archers under a banner!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "halberdier", "count": 4, "elite": false}, {"kind": "archer", "count": 6, "elite": false}, {"kind": "banner_bearer", "count": 1, "elite": false}]},
	{"time": 800.0, "type": "cart", "banner": "The war chest is on the move: seize it!",  # GDD §8.2 supply carts
		"kind": "supply_cart", "pass_distance": 240.0, "pass_offset": 90.0, "lifetime": 30.0,  # TUNING (not in GDD)
		"reward_xp": 50, "reward_crystals": 8,  # TUNING (not in GDD)
		"escort": [{"kind": "halberdier", "count": 2, "elite": false}, {"kind": "shieldbearer", "count": 3, "elite": false}]},  # TUNING (not in GDD)
	{"time": 820.0, "type": "wave", "banner": "The heavy infantry closes the ring!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 26, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "purifier", "count": 6, "elite": false}, {"kind": "shieldbearer", "count": 1, "elite": true}]},
	{"time": 860.0, "type": "wave", "banner": "Templars and halberdiers strike together!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "templar", "count": 4, "elite": false}, {"kind": "halberdier", "count": 3, "elite": false}, {"kind": "chaplain", "count": 2, "elite": false}]},
	# Zone IV: the fortress approach (GDD §8.2 15:00 Ward generator).
	{"time": 900.0, "type": "generators", "banner": "Holy Ward Generators burn your dead: destroy them!",  # GDD §8.2 15:00
		"kind": "ward_generator", "count": 2, "distance_min": 160.0, "distance_max": 210.0,  # TUNING (not in GDD)
		"reward_xp": 40, "reward_crystals": 8, "reward_chest": true,  # TUNING (not in GDD)
		"zone": {
			"radius": 105.0,  # TUNING (not in GDD)
			"arm_time": 2.0,  # TUNING (not in GDD)
			"duration": 900.0,  # TUNING (not in GDD) lasts until the generator falls
			"undead_dps": 6.0,  # TUNING (not in GDD)
			"undead_slow": 0.35,  # TUNING (not in GDD) "weaken summons"
			"player_damage": 5.0,  # TUNING (not in GDD)
			"player_interval": 1.0,  # TUNING (not in GDD)
		},
		"escort": {"formation": "ring", "groups": [{"kind": "shieldbearer", "count": 6, "elite": false}, {"kind": "halberdier", "count": 4, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}]}},  # TUNING (not in GDD)
	{"time": 930.0, "type": "wave", "banner": "Purifiers sally from the walls!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "purifier", "count": 8, "elite": false}, {"kind": "archer", "count": 6, "elite": false}, {"kind": "banner_bearer", "count": 1, "elite": false}]},
	# GDD §8.2 18:00 Cathedral defenders mobilize (moved to 16:00).
	{"time": 960.0, "type": "wave", "banner": "The cathedral defenders mobilize!", "formation": "ring",  # GDD §8.2 18:00, moved to 16:00
		"groups": [{"kind": "chaplain", "count": 2, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}, {"kind": "banner_bearer", "count": 1, "elite": false},
			{"kind": "templar", "count": 2, "elite": false}, {"kind": "shieldbearer", "count": 6, "elite": false}, {"kind": "halberdier", "count": 2, "elite": false}]},
	# GDD §8.2 20:00 Fortress assault (moved to 16:30).
	{"time": 990.0, "type": "wave", "banner": "FORTRESS ASSAULT: the gates are in sight!", "formation": "ring",  # GDD §8.2 20:00, moved to 16:30
		"groups": [{"kind": "recruit", "count": 24, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "halberdier", "count": 2, "elite": false},
			{"kind": "templar", "count": 2, "elite": false}, {"kind": "templar", "count": 1, "elite": true}]},
	# 17:00 Marshal Vael (BOSS_TIME): his own Crusader's Command, plus two garrison sallies.
	{"time": 1080.0, "type": "wave", "banner": "The garrison sallies from the gates!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "footman", "count": 10, "elite": false}, {"kind": "shieldbearer", "count": 6, "elite": false}, {"kind": "archer", "count": 6, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}]},
	{"time": 1140.0, "type": "wave", "banner": "The last defenders surround you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 20, "elite": false}, {"kind": "halberdier", "count": 3, "elite": false}, {"kind": "templar", "count": 2, "elite": false}, {"kind": "templar", "count": 1, "elite": true}]},
]

## The battlefield dead: this stage's empowered graves (GDD §8.1 mechanic
## carried into the march as a reinforcement source; same keys and schedule
## as GraveyardStage.EMPOWERED_GRAVES, plus the text / look overrides below).
##   style          — "corpse" draws a heap of fallen soldiers instead of a grave.
##   rise_banner    — HUD banner when one appears.
##   reinforce_banner / replenish_banner — HUD banners when claimed.
##   objective      — HUD objective while one is unclaimed.
const EMPOWERED_GRAVES := {
	"first": 45.0,  # TUNING (not in GDD)
	"interval": 75.0,  # TUNING (not in GDD)
	"until": 1150.0,  # TUNING (not in GDD)
	"lifetime": 25.0,  # TUNING (not in GDD)
	"distance_min": 130.0,  # TUNING (not in GDD)
	"distance_max": 210.0,  # TUNING (not in GDD)
	"claim_radius": 30.0,  # TUNING (not in GDD)
	"rewards": ["reinforce", "replenish"],  # GDD §8.1 the two empowered-grave effects
	"reinforce_class": "warrior",  # TUNING (not in GDD)
	"reinforce_count": 3,  # TUNING (not in GDD)
	"reinforce_growth": 0.2,  # TUNING (not in GDD)
	"reinforce_duration": 25.0,  # TUNING (not in GDD)
	"reinforce_hp_mult": 1.0,  # TUNING (not in GDD)
	"reinforce_damage_mult": 1.0,  # TUNING (not in GDD)
	"style": "corpse",
	"rise_banner": "The battlefield dead stir nearby!",
	"reinforce_banner": "The fallen rise to march with you!",
	"replenish_banner": "The battlefield feeds your army: your fallen return!",
	"objective": "Fallen soldiers stir nearby: walk onto them to raise them",
}

## Battle zones (open question 3: the clock is authoritative). Keys:
##   start    — s of game time the zone begins.
##   numeral  — zone number shown on the banner.
##   name     — zone name (banner and HUD).
##   blurb    — banner subtitle.
##   ground   — MarchGround look: style id ("burned", "checkpoint", "camp",
##              "fortress") and colours base / line / road / road_edge.
##   arena    — obstacle layout (keys as GraveyardStage.ARENA, plus
##              road_half_width from MARCH); obstacle kinds are drawn by
##              MarchGlyphs.
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Burned Road",  # GDD §8.2 art "roads, devastated settlements"
		"blurb": "Ash and ruin where the Covenant has passed",
		"ground": {"style": "burned", "base": Color(0.11, 0.095, 0.085), "line": Color(0.15, 0.13, 0.11),
			"road": Color(0.20, 0.16, 0.12), "road_edge": Color(0.13, 0.10, 0.08)},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 9101,  # TUNING (not in GDD)
			"kinds": {
				"burned_house": {"weight": 0.35, "shape": "rect", "long_min": 64.0, "long_max": 92.0, "short": 44.0},  # TUNING (not in GDD)
				"charred_tree": {"weight": 0.40, "shape": "circle", "radius_min": 12.0, "radius_max": 17.0},  # TUNING (not in GDD)
				"cart_wreck": {"weight": 0.25, "shape": "rect", "long_min": 40.0, "long_max": 56.0, "short": 22.0},  # TUNING (not in GDD)
			}}},
	{"start": 240.0, "numeral": "II", "name": "The Fortified Checkpoint",  # GDD §8.2 04:00 / art "barricades, forests"
		"blurb": "Barricades and stakes across the forest road",
		"ground": {"style": "checkpoint", "base": Color(0.075, 0.105, 0.075), "line": Color(0.10, 0.14, 0.10),
			"road": Color(0.19, 0.16, 0.11), "road_edge": Color(0.12, 0.10, 0.07)},
		"arena": {"density": 0.26, "clear_radius": 220.0, "layout_seed": 9202,  # TUNING (not in GDD)
			"kinds": {
				"barricade": {"weight": 0.40, "shape": "rect", "long_min": 64.0, "long_max": 96.0, "short": 16.0},  # TUNING (not in GDD)
				"pine": {"weight": 0.40, "shape": "circle", "radius_min": 14.0, "radius_max": 19.0},  # TUNING (not in GDD)
				"stakes": {"weight": 0.20, "shape": "circle", "radius_min": 12.0, "radius_max": 15.0},  # TUNING (not in GDD)
			}}},
	{"start": 540.0, "numeral": "III", "name": "The Siege Camp",  # GDD §8.2 09:00 / art "camps"
		"blurb": "Tents, supply wagons and siege engines",
		"ground": {"style": "camp", "base": Color(0.115, 0.10, 0.075), "line": Color(0.15, 0.13, 0.10),
			"road": Color(0.21, 0.17, 0.12), "road_edge": Color(0.14, 0.11, 0.08)},
		"arena": {"density": 0.26, "clear_radius": 220.0, "layout_seed": 9303,  # TUNING (not in GDD)
			"kinds": {
				"tent": {"weight": 0.45, "shape": "circle", "radius_min": 22.0, "radius_max": 30.0},  # TUNING (not in GDD)
				"crates": {"weight": 0.30, "shape": "rect", "long_min": 36.0, "long_max": 52.0, "short": 26.0},  # TUNING (not in GDD)
				"siege_engine": {"weight": 0.25, "shape": "rect", "long_min": 70.0, "long_max": 90.0, "short": 34.0},  # TUNING (not in GDD)
			}}},
	{"start": 900.0, "numeral": "IV", "name": "The Fortress Approach",  # GDD §8.2 art "distant fortress towers"
		"blurb": "The Covenant fortress and its holy wards",
		"ground": {"style": "fortress", "base": Color(0.09, 0.09, 0.10), "line": Color(0.13, 0.13, 0.15),
			"road": Color(0.24, 0.23, 0.22), "road_edge": Color(0.15, 0.14, 0.14)},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 9404,  # TUNING (not in GDD)
			"kinds": {
				"fort_wall": {"weight": 0.35, "shape": "rect", "long_min": 80.0, "long_max": 96.0, "short": 24.0},  # TUNING (not in GDD)
				"tower_base": {"weight": 0.25, "shape": "circle", "radius_min": 26.0, "radius_max": 34.0},  # TUNING (not in GDD)
				"rubble": {"weight": 0.40, "shape": "circle", "radius_min": 12.0, "radius_max": 18.0},  # TUNING (not in GDD)
			}}},
]

## Crimson March mechanics run by MarchDirector (zones, structures, carts).
##   active_radius      — px; an outpost only sends reinforcements while the
##                        necromancer is this close (no armies from far away).
##   transition_time    — s the fog of war sweeps the field at a zone change.
##   transition_clear   — px; no obstacle within this distance of the
##                        necromancer in the new zone's layout.
##   road_half_width    — px; the old road along y = 0 stays free of obstacles.
##   cart_rewards       — power-ups a destroyed cart drops, in order (cycled;
##                        deterministic, no RNG).
##   structure_spacing  — px; minimum distance between two structures of one
##                        event.
const MARCH := {
	"active_radius": 760.0,  # TUNING (not in GDD)
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"road_half_width": 70.0,  # TUNING (not in GDD) GDD §8.2 art "roads"
	"cart_rewards": ["feast", "magnet", "hyper", "frenzy"],  # TUNING (not in GDD)
	"structure_spacing": 160.0,  # TUNING (not in GDD)
	"zones": ZONES,
}

## Marshal Vael's arrival in this stage (the boss data itself is
## MarchEnemyData.VAEL). Keys as GraveyardStage.BOSS.
const BOSS := {
	"id": "vael",
	"time": BOSS_TIME,
	"display_name": "Marshal Vael, the Crimson Bulwark",  # GDD §7.5
	"short_name": "Marshal Vael",
	"arrive_banner": "Marshal Vael, the Crimson Bulwark, rides out to meet you!",
	"defeat_banner": "Marshal Vael has fallen! The gates are breached: hold out...",  # GDD §7.5 "breach the fortress gates"
	"dead_objective": "Marshal Vael is dead. Survive until the countdown ends.",
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Crimson March",  # GDD §8.2
	"short_name": "Crimson March",
	"chapter": "Chapter II",
	"description": "Counteroffensive and siege. Lead your army down the burned road, through the checkpoint and the siege camp to the Covenant fortress. Destroy outposts, ward generators and supply carts, then break Marshal Vael, the Crimson Bulwark.",  # GDD §8.2 theme / story
	"unlock": {"stage": "graveyard", "boss_kills": 1},  # GDD §9.3: defeat the previous stage's boss
	"unlock_text": "Slay Sir Alaric in the Desecrated Graveyard to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": EMPOWERED_GRAVES,
	"consecration": {},  # No desecration events on the march.
	"crypt_defender": {},  # No Crypt Defender on the march.
	"arena": ZONES[0]["arena"],
	"ground": "march",
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"ash_mult": ASH_MULT,
	"march": MARCH,
}
