## SanctumStage — STAGE 3, THE SANCTUM OF JUDGMENT (GDD §8.3): the final
## assault on the Covenant's fortress interior. Every number and event that
## belongs to this stage. StageRegistry exposes it to the run as
## `Game.stage_def` (the STAGE dictionary at the bottom; its keys are
## documented in StageRegistry). Unlocked by slaying Marshal Vael once (GDD
## §9.3).
##
## Like the Crimson March, THE CLOCK IS AUTHORITATIVE: the assault passes
## through four battle zones on fixed times (ZONES, run by MarchDirector: a
## zone banner, a sweep of holy light, the ground and obstacles around the
## necromancer re-drawn as the next zone). The stage's own objectives
## (sanctified chambers, the Cathedral Guardian, the sacred altars, the
## corruption of the floor) are run by SanctumDirector from SANCTUM and the
## "chamber" / "guardian" / "altars" timeline events.
##
## Timeline (GDD §8.3 time -> prototype elapsed; the GDD's 22:00 boss moves
## to 17:00 like the other stage bosses, so every beat is compressed into the
## 20:00 countdown; owner-approved proposal):
##   GDD time   Event                          Prototype
##   00:00      Outer defenders                0:00  Zone I, the Outer Courtyards
##   04:00      Sanctified chamber             3:00  chamber 1 (two ward crystals)
##                                             4:00  Zone II, the Sanctified Halls; Sentinels
##   07:00      Guardian miniboss              5:30  Cathedral Guardian + chamber 2
##                                             6:00  Radiant Inquisitors join
##   10:00      High Confessor ambush          8:30  Zone III, the Cloisters
##   13:00      Altar destruction              10:30 three sacred altars (optional)
##   16:00      Elite paladins                 13:00 Zone IV, the Final Sanctuary; Sun Paladins
##   19:00      Final sanctuary opens          15:30 final sanctuary wave
##   22:00      Final boss                     17:00 Grand Inquisitor Seraphine (3:00 left)
## The Reckoning is restyled as "Dawn's Wrath" (same escalation; Sun Paladins
## march with the Inquisitors). Gap-filling waves, all rates, caps and weights
## are TUNING (not in GDD). The stage is the hardest of the three (GDD campaign
## intent): tougher kinds earlier and the stage multipliers ENEMY_HP_MULT /
## ENEMY_DAMAGE_MULT, above the Crimson March's.
class_name SanctumStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "sanctum"

# =====================================================================================
# Stage 3 kinds
# =====================================================================================

## Stage-local enemy kind aliases. Every timeline entry of this stage (trickle
## weights, waves, escorts, altar guards, the Guardian, the Dawn's Wrath
## companions) names its Stage 3 kinds by these short keys;
## EnemyDirector.resolve_kind() maps them to the real SanctumEnemyData kind
## when one is looked up or spawned (StageRegistry "kind_aliases"):
##   sentinel  -> Sanctified Sentinel   (GDD §7.2 high-armour construct with sweeps)
##   confessor -> High Confessor        (GDD §7.2 elite priest)
##   paladin   -> Sun Paladin           (GDD §8.3 "elite paladins")
##   radiant   -> Radiant Inquisitor    (GDD §7.2 elite caster, holy zones)
##   guardian  -> Cathedral Guardian    (GDD §7.4 construct miniboss)
const KINDS := {
	"sentinel": "sanctified_sentinel",  # GDD §7.2
	"confessor": "high_confessor",  # GDD §7.2
	"paladin": "sun_paladin",  # GDD §8.3
	"radiant": "radiant_inquisitor",  # GDD §7.2
	"guardian": "cathedral_guardian",  # GDD §7.4
}

# =====================================================================================
# Run structure
# =====================================================================================

## Game time (s) at which Grand Inquisitor Seraphine appears (3:00 left).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) GDD §8.3 places her at 22:00; same 17:00 as the other bosses (owner-approved)

## Enemy max-HP multiplier of this stage on top of the shared time scaling.
const ENEMY_HP_MULT: float = 1.2  # TUNING (not in GDD) GDD §9.3 campaign: each chapter steps up (March 1.1)
## Enemy damage multiplier of this stage on top of the shared time scaling.
const ENEMY_DAMAGE_MULT: float = 1.1  # TUNING (not in GDD) (March 1.05)
## Elapsed game seconds from which ENEMY_HP_MULT / ENEMY_DAMAGE_MULT apply to
## regular enemies: Zone II, the Sanctified Halls (the boss always gets them).
## Same reason as the March: from 0:00 they would lift a recruit past the
## starting Shadow Bolt's one-shot and starve the early army.
const ENEMY_MULT_FROM: float = 240.0  # TUNING (not in GDD)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner-approved x1.5 (March x1.25)

## Dawn's Wrath: the Sanctum's Reckoning (same escalation as the Graveyard;
## keys as GraveyardStage.RECKONING) plus:
##   companions — extra kinds that march with every wave's Inquisitors, scaled
##                like them: {kind, count, growth} = `count` + floor(wave x
##                `growth`) of `kind` (a KINDS alias) per wave.
##   light      — colour of the gold dawn light SanctumDirector washes over the
##                field once it begins.
const RECKONING := {
	"banner": "DAWN'S WRATH: THE SANCTUM BLAZES WITH JUDGMENT",
	"interval": 10.0,  # TUNING (not in GDD) user brief "every ~10s"
	"base_count": 3,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
	"companions": [{"kind": "paladin", "count": 1, "growth": 0.5}],  # TUNING (not in GDD) Sun Paladins march with the Inquisitors
	"light": Color(1.0, 0.86, 0.45),  # TUNING (not in GDD) dawn gold
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "DAWN'S WRATH: the Sanctum's light falls on you. Endure."

# =====================================================================================
# Timeline
# =====================================================================================

## Continuous spawning segments, sorted by start time (keys as
## GraveyardStage.SEGMENTS; kind keys may be KINDS aliases). New kinds:
## Sentinels from 4:00, Radiant Inquisitors from 6:00, High Confessors from
## 8:30, Sun Paladins from 13:00.
const SEGMENTS := [
	# Zone I, the Outer Courtyards: GDD §8.3 "00:00 Outer defenders".
	{"start": 0.0, "rate": 1.5, "max_alive": 32,  # TUNING (not in GDD)
		"weights": {"recruit": 1.0},
		"objective": "The Outer Courtyards: break the outer defenders"},
	{"start": 60.0, "rate": 1.8, "max_alive": 42,  # TUNING (not in GDD)
		"weights": {"recruit": 1.0},
		"objective": "Push through the courtyards"},
	{"start": 120.0, "rate": 2.1, "max_alive": 52,  # TUNING (not in GDD)
		"weights": {"recruit": 0.78, "footman": 0.14, "archer": 0.08},
		"objective": "Archers line the cathedral walls"},
	{"start": 180.0, "rate": 2.3, "max_alive": 58,  # TUNING (not in GDD)
		"weights": {"recruit": 0.64, "footman": 0.2, "archer": 0.1, "chaplain": 0.06},
		"objective": "Holy ground ahead: shatter the ward crystals"},
	# Zone II, the Sanctified Halls: Sentinels from 4:00.
	{"start": 240.0, "rate": 2.5, "max_alive": 66,  # TUNING (not in GDD)
		"weights": {"recruit": 0.54, "footman": 0.2, "archer": 0.1, "sentinel": 0.06, "shieldbearer": 0.05, "chaplain": 0.05},
		"objective": "The Sanctified Halls: Sentinels guard the colonnades"},
	{"start": 300.0, "rate": 2.8, "max_alive": 76,  # TUNING (not in GDD)
		"weights": {"recruit": 0.5, "footman": 0.2, "archer": 0.1, "sentinel": 0.08, "shieldbearer": 0.07, "chaplain": 0.05},
		"objective": "Fight through the halls"},
	# GDD §8.3 "07:00 Guardian miniboss" (5:30); Radiant Inquisitors from 6:00.
	{"start": 360.0, "rate": 3.0, "max_alive": 86,  # TUNING (not in GDD)
		"weights": {"recruit": 0.46, "footman": 0.2, "archer": 0.1, "sentinel": 0.08, "shieldbearer": 0.06, "chaplain": 0.05, "radiant": 0.05},
		"objective": "Radiant Inquisitors sanctify the halls"},
	{"start": 420.0, "rate": 2.7, "max_alive": 82,  # TUNING (not in GDD) lull
		"weights": {"recruit": 0.46, "footman": 0.2, "archer": 0.1, "sentinel": 0.08, "shieldbearer": 0.06, "chaplain": 0.05, "radiant": 0.05},
		"objective": "The cloisters lie beyond the halls"},
	{"start": 465.0, "rate": 3.1, "max_alive": 92,  # TUNING (not in GDD)
		"weights": {"recruit": 0.42, "footman": 0.2, "archer": 0.1, "sentinel": 0.08, "shieldbearer": 0.06, "chaplain": 0.05, "radiant": 0.05, "purifier": 0.04},
		"objective": "Purifiers hunt your dead between the pillars"},
	# Zone III, the Cloisters: GDD §8.3 "10:00 High Confessor ambush" (8:30).
	{"start": 510.0, "rate": 3.5, "max_alive": 106,  # TUNING (not in GDD)
		"weights": {"recruit": 0.38, "footman": 0.18, "archer": 0.12, "sentinel": 0.09, "shieldbearer": 0.06, "chaplain": 0.04, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05},
		"objective": "The Cloisters: High Confessors shield the faithful"},
	{"start": 570.0, "rate": 3.9, "max_alive": 116,  # TUNING (not in GDD)
		"weights": {"recruit": 0.38, "footman": 0.18, "archer": 0.12, "sentinel": 0.09, "shieldbearer": 0.06, "chaplain": 0.04, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05},
		"objective": "Purge the cloisters"},
	# GDD §8.3 "13:00 Altar destruction" (10:30).
	{"start": 630.0, "rate": 3.6, "max_alive": 112,  # TUNING (not in GDD) room for the altar hunt
		"weights": {"recruit": 0.38, "footman": 0.18, "archer": 0.12, "sentinel": 0.09, "shieldbearer": 0.06, "chaplain": 0.04, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05},
		"objective": "Sacred altars bless the Covenant: destroy them to weaken it"},
	{"start": 720.0, "rate": 4.4, "max_alive": 136,  # TUNING (not in GDD)
		"weights": {"recruit": 0.34, "footman": 0.16, "archer": 0.12, "sentinel": 0.1, "halberdier": 0.05, "shieldbearer": 0.06, "chaplain": 0.04, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05},
		"objective": "The sanctuary doors tremble"},
	# Zone IV, the Final Sanctuary: GDD §8.3 "16:00 Elite paladins" (13:00).
	{"start": 780.0, "rate": 4.9, "max_alive": 146,  # TUNING (not in GDD)
		"weights": {"recruit": 0.32, "footman": 0.16, "archer": 0.12, "sentinel": 0.1, "halberdier": 0.05, "shieldbearer": 0.06, "chaplain": 0.04, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05, "paladin": 0.02},
		"objective": "The Final Sanctuary: Sun Paladins defend the inner sanctum"},
	{"start": 840.0, "rate": 4.5, "max_alive": 140,  # TUNING (not in GDD) lull
		"weights": {"recruit": 0.32, "footman": 0.16, "archer": 0.12, "sentinel": 0.1, "halberdier": 0.05, "shieldbearer": 0.06, "chaplain": 0.04, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05, "paladin": 0.02},
		"objective": "Stained light falls on the last defenders"},
	{"start": 900.0, "rate": 5.6, "max_alive": 160,  # TUNING (not in GDD) the density peak of the run
		"weights": {"recruit": 0.32, "footman": 0.16, "archer": 0.12, "sentinel": 0.1, "halberdier": 0.05, "shieldbearer": 0.06, "chaplain": 0.04, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05, "paladin": 0.02},
		"objective": "The final sanctuary opens"},
	{"start": 960.0, "rate": 5.0, "max_alive": 158,  # TUNING (not in GDD)
		"weights": {"recruit": 0.3, "footman": 0.16, "archer": 0.12, "sentinel": 0.1, "halberdier": 0.05, "shieldbearer": 0.06, "chaplain": 0.05, "confessor": 0.02, "radiant": 0.06, "purifier": 0.05, "paladin": 0.03},
		"objective": "The Voice of the Dawn approaches"},
	# 17:00, the boss: a thinner trickle so the duel stays readable.
	{"start": BOSS_TIME, "rate": 3.2, "max_alive": 100,  # TUNING (not in GDD)
		"weights": {"recruit": 0.5, "footman": 0.2, "archer": 0.15, "sentinel": 0.1, "purifier": 0.05},
		"objective": "Grand Inquisitor Seraphine passes judgment"},
	{"start": 1110.0, "rate": 4.0, "max_alive": 120,  # TUNING (not in GDD)
		"weights": {"recruit": 0.45, "footman": 0.2, "archer": 0.15, "sentinel": 0.1, "purifier": 0.1},
		"objective": "Grand Inquisitor Seraphine passes judgment"},
]

## One-shot scripted events, sorted by time. Keys as GraveyardStage.EVENTS
## ("wave" entries: formation + groups; kind keys may be KINDS aliases), plus
## the Sanctum types run by SanctumDirector:
##   "chamber"  — a sanctified chamber (GDD §7.4 "ward crystals"): a holy
##                circle of SANCTUM.chamber_radius px centred
##                `distance_min`..`distance_max` px from the necromancer,
##                with SANCTUM.crystals_per_chamber ward crystals (kind
##                `kind`) `crystal_offset` px from its centre. Undead inside
##                burn and hit weaker until every crystal is destroyed; then
##                the chamber is cleansed. `reward_xp` / `reward_crystals`:
##                XP burst per crystal. `escort`: an optional formation wave
##                {formation, groups} that arrives with it.
##   "guardian" — the Cathedral Guardian miniboss (GDD §7.4 / §7.5): one
##                `kind` (elite if `elite`; the Guardian is always_elite, so
##                the flag changes nothing) from the spawn ring. Its own kit
##                (GuardianKit) registers it on the HUD's miniboss bar and
##                pays its XP burst; ChestManager drops its guaranteed
##                treasure chest. A plain miniboss (owner decision: it
##                shields nothing).
##   "altars"   — `count` sacred altars (kind `kind`) rise
##                `distance_min`..`distance_max` px from the necromancer
##                (spread evenly), each with `guards` (list of {kind, count,
##                elite}) spawned beside it. Optional: each one destroyed
##                lowers later soldiers' HP (SANCTUM.altar_hp_cut) and pays
##                an XP burst; skipping them costs only the bonus.
const EVENTS := [
	# Zone I: the outer defenders (GDD §8.3 00:00). The first two waves are
	# recruits only (the Crimson March's combined-balance lesson: armoured
	# footmen in the first minute starve the starting army).
	{"time": 12.0, "type": "wave", "banner": "The outer defenders hold the courtyard!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 8, "elite": false}]},
	{"time": 45.0, "type": "wave", "banner": "A column marches out of the gatehouse!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 12, "elite": false}]},
	{"time": 80.0, "type": "wave", "banner": "Defenders pour from every archway!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 12, "elite": false}]},
	{"time": 110.0, "type": "wave", "banner": "A courtyard sergeant leads the charge!", "formation": "arc",  # TUNING (not in GDD) first elite
		"groups": [{"kind": "footman", "count": 1, "elite": true}, {"kind": "recruit", "count": 10, "elite": false}]},
	{"time": 145.0, "type": "wave", "banner": "Archers on the cathedral walls!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "archer", "count": 4, "elite": false}, {"kind": "footman", "count": 4, "elite": false}, {"kind": "recruit", "count": 6, "elite": false}]},
	# GDD §8.3 04:00 "Sanctified chamber" (moved to 3:00).
	{"time": 180.0, "type": "chamber", "banner": "A sanctified chamber burns your dead: shatter its ward crystals!",  # GDD §8.3 / §7.4
		"kind": "ward_crystal", "distance_min": 250.0, "distance_max": 310.0, "crystal_offset": 110.0,  # TUNING (not in GDD)
		"reward_xp": 16, "reward_crystals": 4,  # TUNING (not in GDD)
		"escort": {"formation": "arc", "groups": [{"kind": "footman", "count": 4, "elite": false}, {"kind": "chaplain", "count": 1, "elite": false}]}},  # TUNING (not in GDD)
	{"time": 210.0, "type": "wave", "banner": "The courtyard garrison surrounds you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 16, "elite": false}, {"kind": "footman", "count": 4, "elite": false}]},
	# Zone II: the Sanctified Halls; Sentinels from 4:00.
	{"time": 250.0, "type": "wave", "banner": "Sanctified Sentinels awaken in the halls!", "formation": "line",  # TUNING (not in GDD) GDD §7.2 Sanctified Sentinel
		"groups": [{"kind": "sentinel", "count": 3, "elite": false}, {"kind": "footman", "count": 6, "elite": false}]},
	{"time": 290.0, "type": "wave", "banner": "Shieldbearers advance between the pillars!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "shieldbearer", "count": 4, "elite": false}, {"kind": "archer", "count": 4, "elite": false}, {"kind": "chaplain", "count": 1, "elite": false}]},
	# GDD §8.3 07:00 "Guardian miniboss" (moved to 5:30) and a second chamber.
	{"time": 330.0, "type": "guardian", "banner": "A Cathedral Guardian lumbers out of its alcove!",  # GDD §7.4 / §7.5 minibosses
		"kind": "guardian", "elite": false},  # its HP, XP burst and chest: SanctumEnemyData / GuardianKit / ChestManager
	{"time": 332.0, "type": "chamber", "banner": "Another sanctified chamber flares: break its crystals!",  # GDD §8.3 / §7.4
		"kind": "ward_crystal", "distance_min": 260.0, "distance_max": 320.0, "crystal_offset": 115.0,  # TUNING (not in GDD)
		"reward_xp": 22, "reward_crystals": 5,  # TUNING (not in GDD)
		"escort": {}},
	# Radiant Inquisitors from 6:00.
	{"time": 360.0, "type": "wave", "banner": "Radiant Inquisitors sanctify the ground!", "formation": "arc",  # TUNING (not in GDD) GDD §7.2 Radiant Inquisitor
		"groups": [{"kind": "radiant", "count": 3, "elite": false}, {"kind": "footman", "count": 6, "elite": false}]},
	{"time": 400.0, "type": "wave", "banner": "The hall garrison sallies out!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 18, "elite": false}, {"kind": "footman", "count": 6, "elite": false}, {"kind": "sentinel", "count": 1, "elite": true}]},
	{"time": 450.0, "type": "wave", "banner": "A Banner Bearer rallies the halls!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "banner_bearer", "count": 1, "elite": false}, {"kind": "sentinel", "count": 2, "elite": false}, {"kind": "archer", "count": 4, "elite": false}, {"kind": "footman", "count": 4, "elite": false}]},
	{"time": 485.0, "type": "wave", "banner": "Purifiers and Inquisitors close in!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 20, "elite": false}, {"kind": "purifier", "count": 4, "elite": false}, {"kind": "radiant", "count": 2, "elite": false}]},
	# Zone III: the Cloisters. GDD §8.3 10:00 "High Confessor ambush" (moved to 8:30).
	{"time": 510.0, "type": "wave", "banner": "AMBUSH! High Confessors lead the faithful from the cloisters!", "formation": "ring",  # GDD §8.3 10:00
		"groups": [{"kind": "confessor", "count": 2, "elite": false}, {"kind": "confessor", "count": 1, "elite": true}, {"kind": "templar", "count": 2, "elite": false},
			{"kind": "footman", "count": 8, "elite": false}]},
	{"time": 560.0, "type": "wave", "banner": "Archers fire from the cloister arches!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "archer", "count": 6, "elite": false}, {"kind": "purifier", "count": 4, "elite": false}, {"kind": "sentinel", "count": 2, "elite": false}]},
	{"time": 600.0, "type": "wave", "banner": "The cloister garrison closes the ring!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 24, "elite": false}, {"kind": "footman", "count": 6, "elite": false}, {"kind": "radiant", "count": 2, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}]},
	# GDD §8.3 13:00 "Altar destruction" (moved to 10:30): optional altars.
	{"time": 630.0, "type": "altars", "banner": "Three sacred altars bless the Covenant: destroy them to weaken its soldiers!",  # GDD §8.3 / §7.4
		"kind": "sacred_altar", "count": 3, "distance_min": 300.0, "distance_max": 400.0,  # owner-approved 300-400 px
		"reward_xp": 30, "reward_crystals": 6,  # TUNING (not in GDD)
		"guards": [{"kind": "confessor", "count": 1, "elite": false}, {"kind": "footman", "count": 2, "elite": false}]},  # owner-approved "each guarded by a High Confessor"
	{"time": 680.0, "type": "wave", "banner": "Templars charge across the cloister garden!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "templar", "count": 3, "elite": false}, {"kind": "sentinel", "count": 2, "elite": false}, {"kind": "footman", "count": 6, "elite": false}]},
	{"time": 730.0, "type": "wave", "banner": "Heavy infantry bars the sanctuary doors!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "halberdier", "count": 4, "elite": false}, {"kind": "shieldbearer", "count": 6, "elite": false}, {"kind": "sentinel", "count": 1, "elite": true}]},
	# Zone IV: the Final Sanctuary. GDD §8.3 16:00 "Elite paladins" (moved to 13:00).
	{"time": 780.0, "type": "wave", "banner": "SUN PALADINS descend from the sanctuary!", "formation": "arc",  # GDD §8.3 16:00
		"groups": [{"kind": "paladin", "count": 2, "elite": false}, {"kind": "paladin", "count": 1, "elite": true}, {"kind": "footman", "count": 8, "elite": false}]},
	{"time": 830.0, "type": "wave", "banner": "Confessors and Inquisitors bless the line!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 24, "elite": false}, {"kind": "confessor", "count": 1, "elite": false}, {"kind": "radiant", "count": 3, "elite": false}, {"kind": "sentinel", "count": 2, "elite": false}]},
	{"time": 870.0, "type": "wave", "banner": "Paladins and halberdiers strike together!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "paladin", "count": 2, "elite": false}, {"kind": "halberdier", "count": 3, "elite": false}, {"kind": "chaplain", "count": 2, "elite": false}]},
	# GDD §8.3 19:00 "Final sanctuary opens" (moved to 15:30).
	{"time": 930.0, "type": "wave", "banner": "THE FINAL SANCTUARY OPENS: its last defenders surround you!", "formation": "ring",  # GDD §8.3 19:00, moved to 15:30
		"groups": [{"kind": "recruit", "count": 22, "elite": false}, {"kind": "footman", "count": 8, "elite": false}, {"kind": "sentinel", "count": 2, "elite": false},
			{"kind": "paladin", "count": 2, "elite": false}, {"kind": "confessor", "count": 1, "elite": true}]},
	{"time": 980.0, "type": "wave", "banner": "The Inquisition gathers before its Grand Inquisitor!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "radiant", "count": 3, "elite": false}, {"kind": "purifier", "count": 4, "elite": false}, {"kind": "archer", "count": 4, "elite": false}, {"kind": "paladin", "count": 1, "elite": true}]},
	# 17:00 Grand Inquisitor Seraphine (BOSS_TIME), plus two sallies.
	{"time": 1080.0, "type": "wave", "banner": "The faithful rush to their Grand Inquisitor!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "footman", "count": 10, "elite": false}, {"kind": "shieldbearer", "count": 6, "elite": false}, {"kind": "archer", "count": 6, "elite": false}, {"kind": "chaplain", "count": 1, "elite": true}]},
	{"time": 1140.0, "type": "wave", "banner": "The last Sun Paladins surround you!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "recruit", "count": 20, "elite": false}, {"kind": "sentinel", "count": 3, "elite": false}, {"kind": "paladin", "count": 2, "elite": false}, {"kind": "paladin", "count": 1, "elite": true}]},
]

## The Sanctum's dead (the crypts under the cathedral): this stage's
## empowered graves, same keys and schedule as CrimsonMarchStage.EMPOWERED_GRAVES
## (style "grave": an open grave like the Graveyard's).
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
	"style": "grave",
	"rise_banner": "A crypt beneath the flagstones cracks open!",
	"reinforce_banner": "The cathedral's buried dead rise to serve you!",
	"replenish_banner": "The crypt feeds your army: your fallen return!",
	"objective": "A crypt has opened nearby: walk onto it to raise its dead",
}

# =====================================================================================
# Battle zones and their look
# =====================================================================================

## Battle zones (the clock is authoritative, as on the Crimson March). Keys
## as CrimsonMarchStage.ZONES; `ground` is a SanctumGround look:
##   style  — "courtyard" (pale flagstones), "halls" (gold mosaic floor),
##            "cloisters" (stone walks and garden turf) or "sanctuary"
##            (marble with stained-glass light).
##   base / line / accent / trim — colours of the floor, its joints, the
##            zone's decoration and the gold inlay.
## Obstacle kinds are drawn by SanctumTerrainGlyphs. `arena` may carry
## `aligned` (true: each obstacle sits at its cell's centre, so the
## Sanctified Halls' pillars stand in rows; Arena._generate()).
const ZONES := [
	{"start": 0.0, "numeral": "I", "name": "The Outer Courtyards",  # GDD §8.3 art "sacred courtyards"
		"blurb": "Pale flagstones, fountains and the statues of the saints",
		"ground": {"style": "courtyard", "base": Color(0.27, 0.26, 0.24), "line": Color(0.20, 0.19, 0.18),
			"accent": Color(0.36, 0.35, 0.32), "trim": Color(0.62, 0.52, 0.28)},
		"arena": {"density": 0.24, "clear_radius": 220.0, "layout_seed": 9511,  # TUNING (not in GDD)
			"kinds": {
				"saint_statue": {"weight": 0.45, "shape": "circle", "radius_min": 13.0, "radius_max": 17.0},  # TUNING (not in GDD)
				"fountain": {"weight": 0.30, "shape": "circle", "radius_min": 28.0, "radius_max": 36.0},  # TUNING (not in GDD)
				"stone_bench": {"weight": 0.25, "shape": "rect", "long_min": 44.0, "long_max": 60.0, "short": 16.0},  # TUNING (not in GDD)
			}}},
	{"start": 240.0, "numeral": "II", "name": "The Sanctified Halls",  # GDD §8.3 art "cathedral halls, golden mosaics"
		"blurb": "Golden mosaics under endless colonnades",
		"ground": {"style": "halls", "base": Color(0.25, 0.21, 0.14), "line": Color(0.19, 0.16, 0.10),
			"accent": Color(0.42, 0.34, 0.16), "trim": Color(0.78, 0.62, 0.24)},
		"arena": {"density": 0.7, "clear_radius": 220.0, "layout_seed": 9622, "aligned": true,  # TUNING (not in GDD) rows of pillars
			"kinds": {
				"pillar": {"weight": 0.80, "shape": "circle", "radius_min": 13.0, "radius_max": 15.0},  # TUNING (not in GDD)
				"pew": {"weight": 0.20, "shape": "rect", "long_min": 60.0, "long_max": 76.0, "short": 14.0},  # TUNING (not in GDD)
			}}},
	{"start": 510.0, "numeral": "III", "name": "The Cloisters",  # GDD §8.3 art "cloisters"
		"blurb": "Arcaded walks around the Inquisition's gardens",
		"ground": {"style": "cloisters", "base": Color(0.22, 0.23, 0.20), "line": Color(0.17, 0.18, 0.15),
			"accent": Color(0.20, 0.30, 0.18), "trim": Color(0.58, 0.50, 0.30)},
		"arena": {"density": 0.26, "clear_radius": 220.0, "layout_seed": 9733,  # TUNING (not in GDD)
			"kinds": {
				"cloister_arch": {"weight": 0.45, "shape": "rect", "long_min": 72.0, "long_max": 92.0, "short": 18.0},  # TUNING (not in GDD)
				"garden_bed": {"weight": 0.35, "shape": "rect", "long_min": 44.0, "long_max": 60.0, "short": 30.0},  # TUNING (not in GDD)
				"cypress": {"weight": 0.20, "shape": "circle", "radius_min": 11.0, "radius_max": 14.0},  # TUNING (not in GDD)
			}}},
	{"start": 780.0, "numeral": "IV", "name": "The Final Sanctuary",  # GDD §8.3 art "stained glass, giant statues"
		"blurb": "Marble and stained-glass light before the high altar",
		"ground": {"style": "sanctuary", "base": Color(0.29, 0.28, 0.30), "line": Color(0.22, 0.21, 0.23),
			"accent": Color(0.38, 0.37, 0.40), "trim": Color(0.82, 0.66, 0.30)},
		"arena": {"density": 0.22, "clear_radius": 220.0, "layout_seed": 9844,  # TUNING (not in GDD)
			"kinds": {
				"giant_statue": {"weight": 0.40, "shape": "circle", "radius_min": 28.0, "radius_max": 36.0},  # TUNING (not in GDD)
				"marble_column": {"weight": 0.40, "shape": "circle", "radius_min": 15.0, "radius_max": 19.0},  # TUNING (not in GDD)
				"reliquary": {"weight": 0.20, "shape": "rect", "long_min": 40.0, "long_max": 52.0, "short": 26.0},  # TUNING (not in GDD)
			}}},
]

## Zone mechanics for MarchDirector (keys as CrimsonMarchStage.MARCH; the
## Sanctum has no road, outposts or carts), plus its restyled zone change:
##   zone_title  — banner title format ("%s" = the zone numeral).
##   zone_color  — banner / sweep ring / HUD zone label colour.
##   fog_color / fog_bank_color — the sweep's veil and drifting banks.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "THE SANCTUM OPENS  -  ZONE %s",
	"zone_color": Color(1.0, 0.86, 0.5),  # Gold (GDD §7.1 "radiant gold/white").
	"fog_color": Color(0.32, 0.28, 0.18),  # Dusty gold light.
	"fog_bank_color": Color(0.55, 0.48, 0.30),
	"zones": ZONES,
}

## Sanctum objectives run by SanctumDirector (chambers, altars, corruption).
##   chamber_radius        — px; the holy circle of a sanctified chamber.
##   crystals_per_chamber  — ward crystals per chamber (all must fall).
##   chamber_undead_dps    — holy damage per second to each summon inside
##                           (source "holy_zone": Unholy Resilience applies).
##   chamber_tick          — s between those damage ticks.
##   chamber_minion_damage — multiplier on undead minion damage dealt to a
##                           foe standing in an uncleansed chamber (summons
##                           fighting on holy ground; CombatResolver).
##   altar_hp_cut          — fraction of max HP each destroyed altar takes
##                           off every Covenant soldier spawned afterwards
##                           (additive: 3 altars = -18%).
##   corruption_per_chamber / corruption_per_altar — added to the run's
##                           corruption (0..1) when one is cleansed / falls.
##   corruption_ease       — corruption points per second the floor tint
##                           moves toward the target.
##   corrupt_color         — floor colour at corruption 1 (blended).
##   corrupt_tint          — strength (0..1) of that blend at corruption 1.
##   ash_per_chamber / ash_per_altar — Soul Ash per cleansed chamber /
##                           destroyed altar (the "objective_ash" stat, a
##                           Soul Ash part).
##   placement_tries       — attempts to find spaced, obstacle-free spots.
##   structure_spacing     — px; minimum distance between two altars.
const SANCTUM := {
	"chamber_radius": 220.0,  # owner-approved 220 px circle
	"crystals_per_chamber": 2,  # owner-approved
	"chamber_undead_dps": 3.0,  # TUNING (not in GDD) "light holy damage"
	"chamber_tick": 1.0,  # owner-approved "each second"
	"chamber_minion_damage": 0.75,  # owner-approved "25% less damage"
	"altar_hp_cut": 0.06,  # owner-approved -6% per altar, stacking to -18%
	"corruption_per_chamber": 0.25,  # TUNING (not in GDD) 2 chambers = 0.5
	"corruption_per_altar": 0.5 / 3.0,  # TUNING (not in GDD) 3 altars = 0.5
	"corruption_ease": 0.5,  # TUNING (not in GDD)
	"corrupt_color": Color(0.17, 0.07, 0.21),  # GDD §8.3 "progressively corrupted"; necromantic purple
	"corrupt_tint": 0.65,  # TUNING (not in GDD)
	"ash_per_chamber": 10,  # TUNING (not in GDD) "small"
	"ash_per_altar": 8,  # TUNING (not in GDD) "small"
	"placement_tries": 8,  # TUNING (not in GDD)
	"structure_spacing": 170.0,  # TUNING (not in GDD)
}

## Grand Inquisitor Seraphine's arrival (keys as GraveyardStage.BOSS): her
## own SeraphineData.ARRIVAL (boss id "seraphine", the ending text as the
## defeat banner), whose `time` equals BOSS_TIME (17:00).
const BOSS: Dictionary = SeraphineData.ARRIVAL

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Sanctum of Judgment",  # GDD §8.3
	"short_name": "Sanctum",
	"chapter": "Chapter III",
	"description": "The final assault. Storm the Covenant's cathedral through its courtyards, golden halls and cloisters to the final sanctuary. Shatter the ward crystals, topple the sacred altars and corrupt the holy ground, then silence Grand Inquisitor Seraphine.",  # GDD §8.3 theme / story
	"unlock": {"stage": "crimson_march", "boss_kills": 1},  # GDD §9.3: defeat the previous stage's boss
	"unlock_text": "Slay Marshal Vael on the Crimson March to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": EMPOWERED_GRAVES,
	"consecration": {},  # No desecration events in the Sanctum.
	"crypt_defender": {},  # No Crypt Defender in the Sanctum.
	"arena": ZONES[0]["arena"],
	"ground": "sanctum",
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,
	"sanctum": SANCTUM,
	"kind_aliases": KINDS,
}
