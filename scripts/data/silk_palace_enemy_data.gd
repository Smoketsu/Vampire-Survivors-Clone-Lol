## SilkPalaceEnemyData — immutable design data for the Inferno kinds that
## join on the Palace of Silk and Ash (Stage 17) (Act VI; GDD §15.0 "Act VI
## foundation (phase 1)" and "The Palace of Silk and Ash (Act VI phase 2)";
## owner-approved proposal docs/act6/PROPOSAL.md "Roster" and "Stage 17"):
##   lilim_witch  — the Lilim Witch: SUPPORT, female, in the approved Act VI
##                  figure style (a white-haired demon sorceress with a burning
##                  eye-staff). She opens small Hell Pits under the Bone Ring
##                  (HellPits.open_pit(), the one pit path) and heals the demons
##                  around a standing portal (CombatResolver.heal_enemy()).
##                  DEMON (the pits spare her). LilimWitchKit.
##   twin_naamah  — Naamah, the elder of the TWIN SUCCUBI, the stage MINIBOSS;
##   twin_agrat   — Agrat, the younger: two sisters (female, the approved Act VI
##                  figure style) who charm in turns (Temptation, the one charm
##                  path: HordeDirector.charm()) and break the necromancer's
##                  heart with a telegraphed kiss of pain; kill one and the other
##                  RAGES. Fliers, demons, charmers. TwinSuccubusKit (one kit; the
##                  row's "twin" key names the sister); SilkPalaceDirector sends
##                  them together (the "twins" timeline event).
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T; a twin forced alone fights alone and pays the reward).
## EnemyDirector.inferno_def() looks these rows up after InfernoEnemyData. Rows
## have every key of an InfernoEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/inferno/<kit>_kit.gd, unique across the Eye, Empire,
## Pantheon, Shogunate and Inferno folders; "demon", "flier", "charmer",
## "damned" switch the shared rules on for the kind) plus the kit keys
## documented on each row. The GDD gives no numbers: everything is TUNING (not
## in GDD) unless marked as the owner-approved proposal.
class_name SilkPalaceEnemyData
extends RefCounted

## Kind id of the Lilim Witch (support).
const LILIM_WITCH: String = "lilim_witch"
## Kind id of Naamah, the elder twin (miniboss).
const TWIN_NAAMAH: String = "twin_naamah"
## Kind id of Agrat, the younger twin (miniboss).
const TWIN_AGRAT: String = "twin_agrat"
## Damage source tag of a twin's kiss of pain (the telegraphed circle).
const HEARTBREAK_SOURCE: String = "twin_heartbreak"
## HellPits stats tag of a Lilim Witch's pits (the burn itself is the shared
## pit's "hell_pit").
const LILIM_PIT_TAG: String = "lilim"

## Kind id -> design row.
const ENEMIES := {
	# --- Act VI: the Palace of Silk and Ash ---
	# Support (female, the approved Act VI figure style): a demon sorceress with
	# a burning eye-staff. Her PIT CURSE: when it is ready and the necromancer is
	# within pit_trigger px, she raises the staff for pit_windup s, then opens
	# pit_count small Hell Pits UNDER THE RING (on the summons nearest the
	# necromancer, else around him): each pit_radius px, glowing pit_telegraph s
	# (the shared rim), burning pit_life s. Her PORTAL RITE: every rite_every s,
	# while a standing demon portal is within portal_reach px of her, every
	# demon within rite_radius px of that portal heals rite_amount HP (x the
	# enemies' HP scaling; CombatResolver.heal_enemy(), so the Keening Lady's
	# silence stops it). A demon: the pits spare her.
	#   pit_every / pit_trigger / pit_windup / pit_count / pit_radius /
	#   pit_telegraph / pit_life / pit_spread — the pit curse (s / px).
	#   rite_every / portal_reach / rite_radius / rite_amount — the portal rite.
	"lilim_witch": {
		"display_name": "Lilim Witch",  # Owner-approved proposal
		"max_hp": 66.0,  # TUNING (not in GDD) a support who must live to curse (Kitsune 64)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) a staff strike, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD) a support's XP (the succubus 8)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; owner-approved "kill first"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": InfernoEnemyData.FACTION,
		"kit": "lilim_witch",
		"demon": true,
		"pit_every": 10.0,  # TUNING (not in GDD) s; first pass 9 (370 pits in one run)
		"pit_trigger": 380.0,  # TUNING (not in GDD) px to the necromancer
		"pit_windup": 0.8,  # TUNING (not in GDD) s the staff is raised
		"pit_count": 1,  # TUNING (not in GDD) pits per curse; first pass 2
		"pit_radius": 28.0,  # TUNING (not in GDD) px ("small pits")
		"pit_telegraph": 1.5,  # Owner-approved proposal: "a glowing rim for 1.5 s"
		"pit_life": 6.0,  # TUNING (not in GDD) s
		"pit_spread": 70.0,  # TUNING (not in GDD) px between two pits of one curse
		"rite_every": 3.0,  # TUNING (not in GDD) s
		"portal_reach": 260.0,  # TUNING (not in GDD) px from her to the portal
		"rite_radius": 150.0,  # TUNING (not in GDD) px around the portal
		"rite_amount": 4.0,  # TUNING (not in GDD) first pass 6 (8,600 HP healed in one run); HP per demon, x the enemies' HP scaling
	},  # (lilim_witch)
	# The Twin Succubi: the stage MINIBOSS, two sisters of one kit. Each charms
	# in turn (the elder from first_charm, the younger charm_every / 2 later,
	# then each every charm_every s): she hovers and blows kiss_targets kisses
	# at the summons nearest her within kiss_range px (a pink line of hearts for
	# kiss_windup s), each charmed for kiss_duration s through Temptation (its
	# cap of 3 holds). Every pain_every s, her KISS OF PAIN: a pink circle of
	# pain_radius px on the necromancer (within pain_reach px), pain_windup s,
	# then pain_damage_player to him and pain_damage_summon to each summon
	# inside (x the time scaling). Kill one and the other RAGES: rage_heal of her
	# max HP back, move speed x rage_speed, blows x rage_damage, cooldowns x
	# rage_cd, one more kiss per turn. The miniboss bar shows one sister at a
	# time (TwinSuccubusKit); the chest and the reward drop at the second death.
	#   twin          — which sister ("naamah" / "agrat").
	#   first_charm   — s after she arrives before her first kiss (the younger:
	#                   her sister's + charm_every / 2: they charm in turns).
	"twin_naamah": {
		"display_name": "Naamah, the Elder Twin",  # Owner-approved "the Twin Succubi"; the names TUNING (not in GDD) own decision
		"max_hp": 1100.0,  # TUNING (not in GDD) before the time / stage scaling; two bodies (the Kirin 2300 alone); first pass 1500 (alive 3:30 after they came)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 9.0,  # TUNING (not in GDD) a raking claw in reach, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 0,  # The pair's reward is the XP burst below (paid at the second death).
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise them like a boss
		"mass": 6.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": InfernoEnemyData.FACTION,
		"kit": "twin_succubus",
		"demon": true,
		"flier": true,  # Winged, like every succubus
		"phases": true,
		"floating": true,
		"charmer": true,  # Owner-approved proposal: "two sisters who charm in turns"
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"twin": "naamah",
		"reward_xp": 220,  # TUNING (not in GDD) XP burst at the pair's end (the Kirin 200)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"reward_ash": 16,  # TUNING (not in GDD) Soul Ash bounty (objective_ash; the Kirin 14)
		"first_charm": 3.0,  # TUNING (not in GDD) s
		"charm_every": 8.0,  # TUNING (not in GDD) s per sister (a kiss every 4 s from the pair)
		"kiss_targets": 1,  # TUNING (not in GDD) summons per kiss (+1 in rage)
		"kiss_range": 190.0,  # TUNING (not in GDD) px
		"kiss_windup": 0.8,  # TUNING (not in GDD) s
		"kiss_duration": 5.0,  # TUNING (not in GDD) s (the shared succubus 6)
		"pain_every": 6.0,  # TUNING (not in GDD) s
		"pain_radius": 46.0,  # TUNING (not in GDD) px
		"pain_windup": 1.0,  # TUNING (not in GDD) s
		"pain_damage_player": 7.0,  # TUNING (not in GDD) before the time scaling; first pass 9
		"pain_damage_summon": 6.0,  # TUNING (not in GDD) before the time scaling; first pass 8
		"pain_reach": 420.0,  # TUNING (not in GDD) px
		"advance_range": 380.0,  # TUNING (not in GDD) px beyond which she flies faster
		"advance_speed_mult": 1.7,  # TUNING (not in GDD)
		"rage_heal": 0.25,  # TUNING (not in GDD) share of her max HP
		"rage_speed": 1.35,  # TUNING (not in GDD)
		"rage_damage": 1.4,  # TUNING (not in GDD)
		"rage_cd": 0.6,  # TUNING (not in GDD)
	},  # (twin_naamah)
	"twin_agrat": {
		"display_name": "Agrat, the Younger Twin",  # TUNING (not in GDD) names own decision
		"max_hp": 1100.0,  # TUNING (not in GDD) as her sister
		"move_speed": 62.0,  # TUNING (not in GDD) px/s; the younger is quicker
		"damage": 8.0,  # TUNING (not in GDD)
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 0,  # The pair's reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD)
		"mass": 6.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD)
		"faction": InfernoEnemyData.FACTION,
		"kit": "twin_succubus",
		"demon": true,
		"flier": true,
		"phases": true,
		"floating": true,
		"charmer": true,
		"always_elite": true,
		"miniboss": true,
		"twin": "agrat",
		"reward_xp": 220,  # TUNING (not in GDD) one burst for the pair: whichever falls last pays it
		"reward_crystals": 12,  # TUNING (not in GDD)
		"reward_ash": 16,  # TUNING (not in GDD)
		"first_charm": 7.0,  # TUNING (not in GDD) s: her sister's first + charm_every / 2 (in turns)
		"charm_every": 8.0,  # TUNING (not in GDD) s
		"kiss_targets": 1,  # TUNING (not in GDD)
		"kiss_range": 190.0,  # TUNING (not in GDD) px
		"kiss_windup": 0.8,  # TUNING (not in GDD) s
		"kiss_duration": 5.0,  # TUNING (not in GDD) s
		"pain_every": 6.0,  # TUNING (not in GDD) s
		"pain_radius": 46.0,  # TUNING (not in GDD) px
		"pain_windup": 1.0,  # TUNING (not in GDD) s
		"pain_damage_player": 7.0,  # TUNING (not in GDD)
		"pain_damage_summon": 6.0,  # TUNING (not in GDD)
		"pain_reach": 420.0,  # TUNING (not in GDD) px
		"advance_range": 380.0,  # TUNING (not in GDD) px
		"advance_speed_mult": 1.7,  # TUNING (not in GDD)
		"rage_heal": 0.25,  # TUNING (not in GDD)
		"rage_speed": 1.35,  # TUNING (not in GDD)
		"rage_damage": 1.4,  # TUNING (not in GDD)
		"rage_cd": 0.6,  # TUNING (not in GDD)
	},  # (twin_agrat)
}
