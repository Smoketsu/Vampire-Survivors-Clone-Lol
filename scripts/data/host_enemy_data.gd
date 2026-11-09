## HostEnemyData — immutable design data for the kinds THE CELESTIAL HOST
## fields on every one of its stages (temporary Act XIII, final slot X; GDD
## §15.0 "The Celestial Host foundation (phase 1)"; design
## docs/proposals/LAST_SIX_ACTS.md section X, "Roster"). Heaven itself comes
## down: the old, strange angels, silver and blue, with thin geometric halos;
## never crimson, never warm gold. The shared kinds of phase 1 (every one used
## by a rule):
##   lesser_light — the lesser lights: small winged orbs of light in swarms of
##                  12; fodder; no halo (a halo on a swarm of 12 would be the
##                  strongest wall in the act).
##   virtue       — a soldier (male): a silver spearman with a mirror mask and
##                  four wings; GRACE.
##   power        — a soldier (female, figure style): a blade of white flame;
##                  a telegraphed lunge that cuts the first two bodies in its
##                  line; GRACE.
##   choir_angel  — the choir (female, figure style): her hymn heals angels
##                  within 200 px (the existing enemy-heal path); GRACE.
##   herald       — the choir (male): a trumpet blast that calls a squad and
##                  pushes the ring back; GRACE.
##   dominion     — the high orders (male), an elite: a sceptre of light
##                  rings; angels near him move faster (the existing aura
##                  path) and their halos come back after 10 s (GRACE).
##   judge        — the high orders (male), an elite sent by JUDGMENT at each
##                  third of the scales: he comes for the necromancer himself
##                  with a sword and a set of scales; killing him lightens them.
## Added by the Silver Stair (phase 2, its block at the end):
##   cherub       — the guardians (no sex, a creature), an elite: four faces,
##                  four wings full of eyes and a flaming sword that SWEEPS
##                  ALL AROUND IT (CherubKit, row "sword"); GRACE.
## The Reckoning, the Last Trumpet, has no kind of its own: its heavy is the
## Dominion (RECKONING_KIND) with the shared kinds as companions.
## Each stage's own kinds live in its own file (SilverStairEnemyData,
## WheelOfThronesEnemyData, EmpyreanEnemyData; empty until phase 2: the Cherub
## and the Ophan (group "guardians"), the stage minibosses and the bosses'
## allies); EnemyDirector.enemy_def() looks them up through host_def(), this
## file first, after the Dynasty's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Host keys (absent = off):
##   faction  — "host" (the Codex's Host tab, the reports).
##   kit      — a CovenantKit id; a Host kit lives in
##              scripts/enemies/host/<kit>_kit.gd (CovenantKits loads it by
##              name after the Dynasty's folder, so kit ids must be unique
##              across every kit folder). Every Host kind has one (a HostKit).
##   group    — String, one of HostRulesData.GROUPS (the Codex and the report
##              group by it).
##   halo     — bool: the kind wears a GRACE halo (Grace.absorbs()).
##   regrows  — bool: halos of angels within its aura_radius come back
##              HostRulesData.GRACE regrow s after their last absorbed hit
##              (the Dominion).
##   judge    — bool: it hunts the necromancer, not the ring (JudgeKit), and
##              its death lightens the scales (Judgment.on_judge_died()).
##   lunge    — Dictionary: the Power's lunge: first, every (s), trigger (px
##              to the target), windup (s), recover (s), reach (px), width
##              (px), targets (bodies struck), damage_summon, damage_player
##              (per body, before the time scaling).
##   blast    — Dictionary: the Herald's trumpet: first, every (s), windup
##              (s), radius (px of the push), push (px a summon is moved),
##              calls (most squads a Herald calls), squad (Array of
##              {kind, count}).
##   sword    — Dictionary: the Cherub's flaming sword (CherubKit): first (s
##              after it arrives), every (s between two sweeps; 0 = the
##              sword never stops turning), windup (s of telegraph), turn (s
##              for one full circle), turns (full circles a sweep), reach
##              (px), damage_summon, damage_player (per body a pass, before
##              the time scaling).
##   miniboss — true: the stage miniboss (the HUD bar, the chest); with
##              reward_xp / reward_crystals, its XP burst (CherubKit).
##   fodder   — true: fodder (reports).
##   figure   — true: a figure-style woman (the art pass's bust rig; no rule
##              reads it).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot X (at or just
## above the Inferno), not its temporary number.
class_name HostEnemyData
extends RefCounted

## Faction id of the Host's kinds (row "faction").
const FACTION: String = HostRulesData.FACTION
## Kind id of the lesser light.
const LESSER_LIGHT: String = "lesser_light"
## Kind id of the Virtue.
const VIRTUE: String = "virtue"
## Kind id of the Power.
const POWER: String = "power"
## Kind id of the Choir Angel.
const CHOIR_ANGEL: String = "choir_angel"
## Kind id of the Herald.
const HERALD: String = "herald"
## Kind id of the Dominion.
const DOMINION: String = "dominion"
## Kind id of the Judge (Judgment's elite).
const JUDGE: String = "judge"
# --- Act XIII (temporary number): the Silver Stair ---
## Kind id of the Cherub (the guardians; a shared row, the Silver Stair's block).
const CHERUB: String = "cherub"
## Sprite folder of the Host's kinds (assets/sprites/host/).
const SPRITE_DIR: String = "host/"

## The Last Trumpet's heavy (the RECKONING "kind" of every Host stage).
const RECKONING_KIND: String = DOMINION
## The Last Trumpet's companions (the RECKONING "companions" of every Host stage).
const RECKONING_COMPANIONS: Array = [
	{"kind": LESSER_LIGHT, "count": 12, "growth": 2.0},  # TUNING (not in GDD) a swarm of 12, as the roster says
	{"kind": VIRTUE, "count": 4, "growth": 1.5},  # TUNING (not in GDD)
	{"kind": POWER, "count": 2, "growth": 1.0},  # TUNING (not in GDD)
	{"kind": CHOIR_ANGEL, "count": 1, "growth": 0.34},  # TUNING (not in GDD) the hymn never stops
]

## The Host's shared kinds, keyed by kind id.
const ENEMIES := {
	# The lesser lights: small winged orbs in swarms of 12 (owner-approved
	# proposal: "Fodder swarm | Small winged orbs of light in swarms of 12 |
	# Anything"). No halo.
	"lesser_light": {
		"display_name": "Lesser Light",
		"max_hp": 9.0,  # TUNING (not in GDD) fodder, light as a broodling
		"move_speed": 78.0,  # TUNING (not in GDD) px/s; quick
		"damage": 2.5,  # TUNING (not in GDD) a searing touch, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 7.0,  # TUNING (not in GDD) px (~24 px sprite)
		"armor": 0.0,
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "lesser_light",
		"group": "lights",
		"halo": false,  # TUNING (not in GDD): fodder wears no halo
		"fodder": true,
	},  # The lesser light.
	# A soldier (male): a silver spearman with a mirror mask and four wings
	# (owner-approved proposal: "Soldier | Silver spearman with a mirror mask
	# and four wings | Blockers").
	"virtue": {
		"display_name": "Virtue",
		"max_hp": 40.0,  # TUNING (not in GDD) a soldier (khopesh guard 44: no Rebirth here, but a halo)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) a spear thrust, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px (a spear)
		"radius": 10.0,  # TUNING (not in GDD) px (~48 px sprite)
		"armor": 0.15,  # TUNING (not in GDD) silver mail
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 1.3,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "virtue",
		"group": "soldiers",
		"halo": true,  # Owner-approved proposal: Grace
	},  # The Virtue.
	# A soldier (female, figure style): a blade of white flame; a lunge that
	# cuts two summons in a line (owner-approved proposal: "Soldier | A blade
	# of white flame; a lunge that cuts two summons in a line | Rogues,
	# Gargoyles").
	"power": {
		"display_name": "Power",
		"max_hp": 36.0,  # TUNING (not in GDD) a soldier
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) a blade cut, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~48 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "power",
		"group": "soldiers",
		"halo": true,  # Owner-approved proposal: Grace
		"figure": true,
		"lunge": {
			"first": 2.0,  # TUNING (not in GDD) s after she arrives
			"every": 5.5,  # TUNING (not in GDD) s between two lunges
			"trigger": 70.0,  # TUNING (not in GDD) px to her target
			"windup": 0.6,  # TUNING (not in GDD) s of telegraph (the white line)
			"recover": 0.4,  # TUNING (not in GDD) s
			"reach": 84.0,  # TUNING (not in GDD) px
			"width": 18.0,  # TUNING (not in GDD) px
			"targets": 2,  # Owner-approved proposal: "cuts two summons in a line"
			"damage_summon": 14.0,  # TUNING (not in GDD) per body, before the time scaling
			"damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
		},
	},  # The Power.
	# The choir (female, figure style): her hymn heals angels within 200 px
	# (owner-approved proposal: "Support | Her hymn heals angels within 200 px
	# | Priority target"), through the existing enemy-heal path.
	"choir_angel": {
		"display_name": "Choir Angel",
		"max_hp": 34.0,  # TUNING (not in GDD) a support
		"move_speed": 44.0,  # TUNING (not in GDD) px/s
		"damage": 2.0,  # TUNING (not in GDD) a weak touch
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~48 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "healer",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 9.0,  # TUNING (not in GDD) HP a heal
		"heal_interval": 2.4,  # TUNING (not in GDD) s
		"heal_radius": 200.0,  # Owner-approved proposal: "heals angels within 200 px"
		"heal_stat": "choir_heals",  # The stat her heals count in (Enemy.heal_stat).
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; "priority target"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "choir_angel",
		"group": "choir",
		"halo": true,  # Owner-approved proposal: Grace
		"figure": true,
	},  # The Choir Angel.
	# The choir (male): a trumpet blast that calls a squad and pushes the ring
	# back (owner-approved proposal: "Support | A trumpet blast that calls a
	# squad and pushes the ring back | Kill on arrival").
	"herald": {
		"display_name": "Herald",
		"max_hp": 46.0,  # TUNING (not in GDD) a support worth killing on arrival
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD)
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~48 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "healer",  # The support walk; he heals nothing (heal_amount 0).
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; "kill on arrival"
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "herald",
		"group": "choir",
		"halo": true,  # Owner-approved proposal: Grace
		"blast": {
			"first": 3.0,  # TUNING (not in GDD) s after he arrives ("kill on arrival")
			"every": 12.0,  # TUNING (not in GDD) s between two blasts
			"windup": 0.9,  # TUNING (not in GDD) s he raises the trumpet
			"radius": 150.0,  # TUNING (not in GDD) px of the push
			"push": 46.0,  # TUNING (not in GDD) px a summon is pushed back
			"calls": 1,  # TUNING (not in GDD) most squads one Herald calls (2 called ~2,300 bodies in a run)
			"squad": [{"kind": "virtue", "count": 2}, {"kind": "lesser_light", "count": 4}],  # TUNING (not in GDD)
		},
	},  # The Herald.
	# The high orders (male), an elite: a sceptre of light rings; angels near
	# him move faster and their halos come back after 10 s (owner-approved
	# proposal: "Elite | ... | Kill first"). The speed is the existing aura
	# path (Enemy._pulse_aura()); the halos are Grace's (row "regrows").
	"dominion": {
		"display_name": "Dominion",
		"max_hp": 150.0,  # TUNING (not in GDD) an elite
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 8.0,  # TUNING (not in GDD) a sceptre blow, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px (~54 px sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1; "kill first"
		"mass": 1.8,  # TUNING (not in GDD)
		"aura_radius": 180.0,  # TUNING (not in GDD) px: angels near him move faster, their halos come back
		"aura_damage_mult": 1.0,  # No damage buff.
		"aura_speed_mult": 1.2,  # Owner-approved proposal: "angels near him move faster"; TUNING (not in GDD) x
		"aura_taken_mult": 1.0,  # No damage-taken buff.
		"faction": FACTION,
		"kit": "dominion",
		"group": "orders",
		"halo": true,  # Owner-approved proposal: Grace
		"regrows": true,  # Owner-approved proposal: "their halos come back after 10 s"
	},  # The Dominion.
	# The high orders (male), Judgment's elite: comes for the necromancer with
	# a sword and a set of scales (owner-approved proposal: "Elite (Judgment) |
	# Comes for the necromancer with a sword and a set of scales | Kill it to
	# lighten the scales"). Sent by Judgment; its spawns are not an elite
	# (no chest): its own row is tough.
	"judge": {
		"display_name": "Judge",
		"max_hp": 240.0,  # TUNING (not in GDD) an elite that must be killed to lighten the scales
		"move_speed": 64.0,  # TUNING (not in GDD) px/s; he comes straight for you
		"damage": 12.0,  # TUNING (not in GDD) a sword cut, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px (~56 px sprite)
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 14,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # TUNING (not in GDD) 0..1; the army hunts him
		"mass": 2.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "judge",
		"group": "orders",
		"halo": true,  # Owner-approved proposal: Grace (every angel)
		"judge": true,  # Owner-approved proposal: hunts the necromancer; lightens the scales
	},  # The Judge.
	# --- Act XIII (temporary number): the Silver Stair ---
	# The guardians (a creature, no sex), an elite: four faces (lion, ox,
	# eagle, man), four wings covered in eyes and a flaming sword that sweeps
	# all around it (owner-approved proposal: "Elite (guardian) | Four faces,
	# four wings full of eyes and a flaming sword that sweeps all around it |
	# Siegecraft; stay out of reach"). CherubKit: every sword.every s, once a
	# body stands within reach, it plants itself for sword.windup s (a ring
	# telegraph) and its sword turns one full circle in sword.turn s, cutting
	# every summon and necromancer it passes (their body radius counts).
	# Siegecraft's extra damage to elites already applies to it.
	"cherub": {
		"display_name": "Cherub",
		"max_hp": 200.0,  # TUNING (not in GDD) an elite guardian (Dominion 150; Grace's halo on top)
		"move_speed": 38.0,  # TUNING (not in GDD) px/s; a slow guardian
		"damage": 9.0,  # TUNING (not in GDD) a blow in reach, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 14.0,  # TUNING (not in GDD) px (~56 px sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 12,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "cherub",
		"group": "guardians",
		"halo": true,  # Owner-approved proposal: Grace (every angel)
		"sword": {
			"first": 2.0,  # TUNING (not in GDD) s after it arrives
			"every": 7.5,  # TUNING (not in GDD) s between two sweeps
			"windup": 0.8,  # TUNING (not in GDD) s of telegraph (a ring round it)
			"turn": 1.0,  # TUNING (not in GDD) s for one full circle
			"turns": 1,  # TUNING (not in GDD) full circles a sweep
			"reach": 54.0,  # TUNING (not in GDD) px; "stay out of reach"
			"damage_summon": 12.0,  # TUNING (not in GDD) per summon passed (once a turn), before the time scaling
			"damage_player": 8.0,  # TUNING (not in GDD) before the time scaling
		},
	},  # The Cherub.
}
