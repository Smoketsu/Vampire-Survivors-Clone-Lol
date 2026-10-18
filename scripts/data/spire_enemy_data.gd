## SpireEnemyData — immutable design data for the Ancient Eye kinds that
## join on Ul-Thalos, the Risen Spire (Stage 6) (GDD §15.0 "Act II: the
## Ancient Eye" and "Ul-Thalos, the Risen Spire"):
##   eye_siren        — Siren of the Eye: an elite caster (female, figure-
##                      redesign style). Her telegraphed song lures every
##                      summon near her out of formation for a moment
##                      (SirenKit).
##   eye_spawn        — Spawn of the Deep: a tentacled, armoured heavy that
##                      grabs and holds the nearest summon (SpawnKit).
##   eye_hierophant   — Hierophant of the Eye: an elite leader (a buff aura,
##                      a claim reach like a Chanter) that starts an ASCENSION
##                      ritual: if it survives the channel it turns into a
##                      Spawn of the Deep (HierophantKit). Interruptible, like
##                      the High Confessor's revival.
## and the stage's objects:
##   dream_pillar     — a dream pillar (structure): three rise in the Dream
##                      Gate; each one still standing when Vhal'Neth wakes
##                      gives her opening phase one more arm (SpireDirector,
##                      BossVhalneth).
##   vhalneth_arm     — one of Vhal'Neth's arms (structure, ArmKit): it rises
##                      out of the sea at the shore and slams telegraphed lanes
##                      across the island. Its HP is set by the boss.
##   eye_waking_horror — Dreamspawn of the Waking: the stage's Reckoning kind
##                      (SpireStage.RECKONING "kind"), the god's last surge.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.enemy_def() looks these rows up after
## EyeEnemyData. Rows have every key of an EyeEnemyData.ENEMIES row (same
## meaning) plus their kit's numbers (documented on each kit).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name SpireEnemyData
extends RefCounted

## Kind id of the Spawn of the Deep (a Hierophant's Ascension turns into it).
const SPAWN: String = "eye_spawn"
## Kind id of a dream pillar (SpireDirector places them).
const PILLAR: String = "dream_pillar"
## Kind id of one of Vhal'Neth's arms (BossVhalneth raises them).
const ARM: String = "vhalneth_arm"

## Kind id -> design row.
const ENEMIES := {
	# Siren of the Eye: an elite caster who never kites (the shared "banner"
	# walk: she advances on the necromancer, strikes weakly in contact) and
	# sings. The song is the counterplay check: kill her during the 1.2 s
	# telegraph, or the army near her breaks formation and walks to her.
	"eye_siren": {
		"display_name": "Siren of the Eye",
		"max_hp": 120.0,  # TUNING (not in GDD) an elite caster's HP (Radiant Inquisitor 150; balance pass 8: 150 -> 120, a weak army must still bring her down)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s; a slow glide
		"damage": 5.0,  # TUNING (not in GDD) weak touch in contact
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 12.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 24,  # TUNING (not in GDD) an elite caster's XP
		"behavior": "banner",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) casters are preferred targets (GDD §27)
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "siren",
		"always_elite": true,  # Proposal: "elite caster"
		# The song (SirenKit): a telegraph of rising notes, then every summon
		# within song_radius px of her is LURED for song_lure s: it drops its
		# target and walks to her (SummonedUnit.compel()), out of formation.
		"song_first": 4.0,  # TUNING (not in GDD) s after spawning before the first song
		"song_cooldown": 15.0,  # TUNING (not in GDD) s between songs (balance pass 8: 10 -> 15)
		"song_range": 240.0,  # TUNING (not in GDD) px; sings only with summons this close
		"song_min_summons": 3,  # TUNING (not in GDD) summons inside song_radius to bother singing (balance pass 8: 2 -> 3, a tiny army is not lured apart)
		"song_radius": 190.0,  # TUNING (not in GDD) px reach of the lure
		"song_telegraph": 1.2,  # TUNING (not in GDD) s of rising notes (GDD §10.5 telegraphed)
		"song_lure": 2.0,  # Proposal: "lures summons out of formation for 2 s"
		"song_lure_speed": 0.8,  # TUNING (not in GDD) x the summon's move speed while lured
		"song_max_lured": 6,  # TUNING (not in GDD) summons one song can lure (balance pass 8: 10 -> 6)
	},
	# Spawn of the Deep: a tentacled heavy in a barnacle shell. Slow, armoured,
	# it advances like any melee kind; when a summon comes into reach it seizes
	# the nearest one and holds it fast, squeezing, until the hold ends or the
	# Spawn dies.
	"eye_spawn": {
		"display_name": "Spawn of the Deep",
		"max_hp": 300.0,  # TUNING (not in GDD) a heavy (Sanctified Sentinel 120 + flat armour)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 7.0,  # TUNING (not in GDD) tentacle lash in contact (balance pass 3: 10 -> 7)
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px edge to edge
		"radius": 17.0,  # TUNING (not in GDD) px
		"armor": 0.3,  # TUNING (not in GDD) proposal "armoured": a barnacle shell
		"xp": 14,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD)
		"mass": 6.0,  # TUNING (not in GDD) heavy: shoves warriors
		"slow_resist": 0.3,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "spawn",
		# The grab (SpawnKit): a tentacle reaches for the nearest summon within
		# grab_range px, then holds it for grab_hold s (it cannot move:
		# SummonedUnit.compel() with no speed), dragging it to the Spawn's side
		# and squeezing grab_damage every grab_tick s (time-scaled). The Spawn
		# keeps fighting while it holds.
		"grab_first": 3.0,  # TUNING (not in GDD) s after spawning
		"grab_cooldown": 9.0,  # TUNING (not in GDD) s from one grab's end to the next (balance pass 1: 7 -> 9)
		"grab_range": 80.0,  # TUNING (not in GDD) px edge to edge
		"grab_windup": 0.6,  # TUNING (not in GDD) s the tentacle reaches (telegraph)
		"grab_hold": 3.0,  # TUNING (not in GDD) s the summon is held
		"grab_tick": 0.5,  # TUNING (not in GDD) s between squeezes
		"grab_damage": 2.5,  # TUNING (not in GDD) per squeeze, before time scaling (balance pass 1: 4 -> 2.5)
		"grab_pull": 90.0,  # TUNING (not in GDD) px/s the held summon is dragged in
	},
	# Hierophant of the Eye: the elite leader that guards the Dream Gate. Its
	# presence hardens the cultists around it (a buff aura like the Banner
	# Bearer's) and claims the dead like a Chanter. Then it starts the
	# ASCENSION: it stands still in a biolume pillar for ascend_channel s; if
	# it survives, it tears itself open into a Spawn of the Deep. Killing it,
	# or dealing ascend_break of its max HP during the channel, interrupts it
	# (a build without burst gets punished, but never instantly).
	"eye_hierophant": {
		"display_name": "Hierophant of the Eye",
		"max_hp": 230.0,  # TUNING (not in GDD)
		"move_speed": 44.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) weak staff strike in contact
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 30,  # TUNING (not in GDD)
		"behavior": "banner",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # TUNING (not in GDD) the army must break the ritual
		"mass": 1.6,  # TUNING (not in GDD)
		"faction": EyeEnemyData.FACTION,
		"kit": "hierophant",
		"always_elite": true,  # Proposal: "elite leader"
		"claim_radius": 100.0,  # TUNING (not in GDD) px; it claims the dead like a Chanter (EyeClaims)
		# Leader aura (the shared Enemy aura, MarchEnemyData keys).
		"aura_radius": 120.0,  # TUNING (not in GDD) px
		"aura_damage_mult": 1.15,  # TUNING (not in GDD)
		"aura_speed_mult": 1.1,  # TUNING (not in GDD)
		"aura_taken_mult": 1.0,  # TUNING (not in GDD) no damage resistance
		# Ascension (HierophantKit).
		"ascend_first": 10.0,  # TUNING (not in GDD) s after spawning before the ritual starts (balance pass 2: 4 -> 10, it climbs out of the sea at the shore and channelled out of the army's reach)
		"ascend_channel": 12.0,  # Proposal: "survives 12 s of its ritual"
		"ascend_break": 0.25,  # TUNING (not in GDD) fraction of max HP lost during the channel that breaks it (balance pass 1: 0.4 -> 0.25, 11 of 16 rites finished)
		"ascend_retry": 9.0,  # TUNING (not in GDD) s after a broken channel before it starts again
		"ascend_elite": true,  # TUNING (not in GDD) the risen Spawn is elite (more HP, bigger, elite XP)
	},
	# A dream pillar: a cyclopean obelisk humming with the god's dream. It
	# does nothing but stand (and lift the Dread of a necromancer close to
	# it, SpireStage.SPIRE.pillar_dread); every one still standing when
	# Vhal'Neth wakes gives her opening phase one more arm.
	"dream_pillar": {
		"display_name": "Dream Pillar",
		"max_hp": 520.0,  # TUNING (not in GDD) about 1,700 HP at 10:30 after time / stage scaling (a Sanctum altar 450)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is SpireDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD)
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": EyeEnemyData.FACTION,
	},
	# One of Vhal'Neth's arms, rising out of the sea at the shoreline. A
	# stationary structure (never recycled, no target picking): its kit slams
	# telegraphed lanes across the island. BossVhalneth sets its HP (a share of
	# hers) and its pace; severing it wounds her.
	"vhalneth_arm": {
		"display_name": "Arm of Vhal'Neth",
		"max_hp": 1000.0,  # Placeholder: BossVhalneth sets every arm's HP (VhalnethData)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 20.0,  # TUNING (not in GDD) px (its root in the surf)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is the wound it deals Vhal'Neth.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) the army fights her arms
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": EyeEnemyData.FACTION,
		"kit": "arm",
		# The slam (ArmKit): a lane from the arm toward the necromancer (or the
		# densest summons), slam_length px long (cut at the far shore) and
		# slam_width px wide, telegraphed for slam_telegraph s; then the arm
		# crashes down along it.
		"slam_first": 2.5,  # TUNING (not in GDD) s after rising
		"slam_interval": 6.0,  # TUNING (not in GDD) s between slams (BossVhalneth's phase pace divides it)
		"slam_length": 900.0,  # TUNING (not in GDD) px (the far shore cuts it)
		"slam_width": 60.0,  # TUNING (not in GDD) px
		"slam_telegraph": 1.5,  # TUNING (not in GDD) s (GDD §10.5 clear telegraphs)
		"slam_damage_player": 12.0,  # TUNING (not in GDD) before time scaling (balance pass 3: 18 -> 12, two slams took a third of the bot's HP each)
		"slam_damage_summon": 9.0,  # TUNING (not in GDD) before time scaling (the lane crosses the army; balance pass 1: 14 -> 9)
		"slam_knockback": 50.0,  # TUNING (not in GDD) px a struck summon is thrown out of the lane
		"slam_recover": 0.6,  # TUNING (not in GDD) s the arm lies along the lane after the impact (drawing)
	},
	# Dreamspawn of the Waking: the Reckoning of Ul-Thalos (the Waking). Like
	# the Inquisitor of the End: near-unbeatable, it ends the run.
	"eye_waking_horror": {
		"display_name": "Dreamspawn of the Waking",
		"max_hp": 950.0,  # TUNING (not in GDD) the Inquisitor of the End has 900
		"move_speed": 100.0,  # TUNING (not in GDD) slightly slower than the player
		"damage": 46.0,  # TUNING (not in GDD)
		"attack_interval": 0.8,  # TUNING (not in GDD)
		"attack_range": 6.0,  # TUNING (not in GDD)
		"radius": 17.0,  # TUNING (not in GDD)
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
}
