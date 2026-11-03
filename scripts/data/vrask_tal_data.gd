## VraskTalData — immutable design data for VRASK'TAL, THE HUNT-LORD, the boss of
## the Proving Moon (Act IX, Stage 26; GDD §15.0 "Vrask'Tal, the Hunt-Lord (Act
## IX)"; owner-approved proposal docs/act9/PROPOSAL.md: "the Stalk (cloaked,
## picking summons off the ring's edge; each kill hangs a skull on his belt),
## the Duel (he drops his cloak and fights the necromancer with a glaive,
## leaping over the ring), the Last Trophy (he arms the bomb on his wrist: a
## 20 s countdown he tries to finish standing next to the necromancer)").
## BossVraskTal (scripts/enemies/concord/boss_vrask_tal.gd, loaded by name for
## the boss id "vrask_tal") reads it. A male reptilian hunter, as the Vrask
## Hunter but larger, with a belt of skulls. Three phases by his HP:
##   * THE STALK (100% to phase2_hp): CLOAKED while he moves (the Vrask
##     hunter's mechanism, VraskHunterKit.cloak_hit_mult(): a shimmer; a
##     summon's or a hazard's hit deals cloak cloaked_taken; a SPELL hit lands
##     in full and reveals him for cloak reveal_time s, as does his
##     caster's shot; he uncloaks while he stands to cut). He hunts the RING'S EDGE: his prey is the summon within
##     stalk_search px of him that stands farthest from its necromancer
##     (re-chosen every stalk_retarget s); he walks at it and cuts it with his
##     glaive (the shared melee), and every lock_every s his shoulder caster
##     locks it ("lock" beam through ConcordBeams.fire(), the one beam path,
##     boss override: lock_* overrides). Every summon his blows kill HANGS A
##     SKULL on his belt (drawn): +skull_step of his damage each (hit_mult(),
##     the one damage read of his blows and beams), at most skull_cap skulls.
##   * THE DUEL (phase2_hp to phase3_hp): he drops his cloak for good and fights
##     the necromancer: he walks at the nearest necromancer (the shared walk
##     and glaive), his caster locks the necromancer every lock_every_duel s,
##     and every leap_every s, when the necromancer is within leap_reach px x
##     the low gravity (ConcordRules.gravity(): twice as far on the moon), he
##     LEAPS OVER THE RING onto him (a landing circle of leap_radius px for
##     leap_windup s, the leap in leap_time s ignoring the body-block, as
##     Vargr's; everyone in the circle takes leap_damage_*; the summons are
##     thrown leap_push px x the low gravity).
##   * THE LAST TROPHY (below phase3_hp): he arms the bomb on his wrist: a
##     trophy_time s COUNTDOWN as HUD TEXT only (ProvingMoonDirector
##     .objective_override(), a banner every trophy_banner_every s; never a
##     screen effect). He walks at the necromancer trophy_speed_mult faster and
##     leaps every leap_every_p3 s, to finish standing next to him. KILL HIM IN
##     TIME and the bomb is off (the run stat HUNTED_STAT: the achievement The
##     Hunter Hunted). FAIL and THE BOMB goes off where he stands
##     (BossVraskTal._detonate(), the ONE documented path): every necromancer
##     within bomb_radius px is left at bomb_hp_left of his max HP
##     (damage_player() with his i-frames cleared first: Grave Step does not
##     dodge it; through his ward; never lethal by itself: nothing when he is
##     already below it), every summon within bomb_radius px takes
##     bomb_summon_share of its max HP through damage_unit() (destroyed), the
##     enemies are spared, and VRASK'TAL DIES in it (own decision, the lead's
##     suggestion): his death counts as the boss kill for the unlock chain and
##     the rewards, but never for the achievement (the run stat BOMB_STAT).
## The army bot steps away from him while the countdown runs and out of a
## leap's circle (BossVraskTal.danger_push()). The GDD gives no numbers:
## everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal.
class_name VraskTalData
extends RefCounted

## Vrask'Tal's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "vrask_tal" through ProvingMoonStage.BOSS, so --boss=vrask_tal
## and the Codex find him).
const ARRIVAL := {
	"id": "vrask_tal",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Vrask'Tal, the Hunt-Lord",  # Owner-approved proposal
	"short_name": "Vrask'Tal",
	"arrive_banner": "A shimmer at the edge of your ring: Vrask'Tal, the Hunt-Lord, has come for you!",  # TUNING (not in GDD)
	"defeat_banner": "Vrask'Tal falls, and the hunt is over! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Vrask'Tal is dead. Survive the Final Harvest... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["stalk", "lock", "duel", "leap", "last_trophy", "bomb"]

## Damage tag of his glaive (the shared melee names the boss "boss"; his
## leap's landing and his caster have their own tags).
const LEAP_SOURCE: String = "vrask_tal_leap"
## Damage tag of his shoulder caster's lock beam (ConcordBeams "source").
const CASTER_SOURCE: String = "vrask_tal_caster"
## Damage tag of the Last Trophy's bomb (never a spell or summon source).
const BOMB_SOURCE: String = "vrask_bomb"
## Sprite key of his art (pose 1: the glaive raised / the crouch).
const SPRITE: String = "bosses/vrask_tal"
## Run stat set to 1 when he fell to anything but his own bomb (the
## achievement The Hunter Hunted; MetaProgress counts the runs).
const HUNTED_STAT: String = "proving_moon_hunter_hunted"
## Run stat set to 1 when the Last Trophy's bomb went off (his own death too).
const BOMB_STAT: String = "vrask_tal_bombed"

## His base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 14500.0  # TUNING (not in GDD) Vargr 14,000, Harrow 15,000

## Vrask'Tal's design row.
const BOSS := {
	"display_name": "Vrask'Tal, the Hunt-Lord",
	"max_hp": MAX_HP,
	"move_speed": 60.0,  # TUNING (not in GDD) px/s (the Vrask hunter 56)
	"damage": 11.0,  # TUNING (not in GDD) a glaive blow, before the time scaling
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 18.0,  # TUNING (not in GDD) px (the glaive's reach)
	"radius": 26.0,  # TUNING (not in GDD) px (a ~84 px sprite)
	"armor": 0.2,  # TUNING (not in GDD) dark armour
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD)
	"faction": ConcordEnemyData.FACTION,
	"race": "vrask",  # The report and the Codex group him with the Vrask.
	"reward_xp": 650,  # TUNING (not in GDD) Harrow 650
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.45,  # TUNING (not in GDD) s he stands after a leap
	"advance_range": 460.0,  # TUNING (not in GDD) px; farther than this he moves faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.65,  # TUNING (not in GDD) the Duel below this
	"phase3_hp": 0.25,  # TUNING (not in GDD) the Last Trophy below this (first pass 0.3: the seed-7 army bot needed ~24 s for that share and the bomb went off)
	"stalk_banner": "THE STALK: Vrask'Tal hunts the edge of your ring, cloaked. Spells reveal him!",  # TUNING (not in GDD)
	"phase2_banner": "THE DUEL: Vrask'Tal drops his cloak and comes for you with his glaive!",  # TUNING (not in GDD)
	"phase3_banner": "THE LAST TROPHY: Vrask'Tal arms the bomb on his wrist! Kill him before it ends!",  # TUNING (not in GDD)
	"countdown_banner": "The Last Trophy: %d s",  # TUNING (not in GDD) every trophy_banner_every s
	"defused_banner": "The Hunter Hunted: the bomb dies with him.",  # TUNING (not in GDD)
	"bomb_banner": "THE LAST TROPHY: the bomb goes off, and takes the Hunt-Lord with it!",  # TUNING (not in GDD)
	# The Stalk: the cloak, the prey, the skulls.
	"cloak": {"alpha": 0.2, "cloaked_taken": 0.5, "reveal_time": 2.0, "min_speed": 8.0},  # TUNING (not in GDD) the Vrask hunter's cloak (owner-approved proposal: "cloaked")
	"stalk_search": 320.0,  # TUNING (not in GDD) px around him he looks for prey
	"stalk_retarget": 1.5,  # TUNING (not in GDD) s between two prey choices
	"skull_step": 0.04,  # TUNING (not in GDD) own decision: +4% damage a skull
	"skull_cap": 8,  # TUNING (not in GDD) own decision: at most 8 skulls (+32%)
	# His shoulder caster (the "lock" beam, ConcordBeams; boss override).
	"lock_every": 5.0,  # TUNING (not in GDD) s, the Stalk (at his prey)
	"lock_every_duel": 4.0,  # TUNING (not in GDD) s, the Duel (at the necromancer)
	"lock_range": 300.0,  # TUNING (not in GDD) px: he locks only this near
	"lock_dps": 40.0,  # TUNING (not in GDD) the pulse's dps before the time scaling (the hunter's lock 50 over 0.15 s)
	"lock_length": 340.0,  # TUNING (not in GDD) px
	"lock_width": 10.0,  # TUNING (not in GDD) px
	# The Duel: the leap over the ring.
	"first_leap": 2.0,  # TUNING (not in GDD) s after the Duel starts
	"leap_every": 7.0,  # TUNING (not in GDD) s
	"leap_every_p3": 4.5,  # TUNING (not in GDD) s, the Last Trophy
	"leap_min": 70.0,  # TUNING (not in GDD) px: nearer than this he cuts instead
	"leap_reach": 200.0,  # TUNING (not in GDD) px, x the low gravity (400 on the moon)
	"leap_windup": 0.9,  # TUNING (not in GDD) s
	"leap_time": 0.55,  # TUNING (not in GDD) s
	"leap_height": 34.0,  # TUNING (not in GDD) px (drawing)
	"leap_radius": 58.0,  # TUNING (not in GDD) px
	"leap_damage_player": 11.0,  # TUNING (not in GDD) before the time scaling
	"leap_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling
	"leap_push": 22.0,  # TUNING (not in GDD) px, x the low gravity
	# The Last Trophy.
	"trophy_time": 20.0,  # Owner-approved proposal: "a 20 s countdown"
	"trophy_banner_every": 5.0,  # TUNING (not in GDD) s between two countdown banners
	"trophy_speed_mult": 1.35,  # TUNING (not in GDD) he hurries to the necromancer
	"bomb_radius": 190.0,  # TUNING (not in GDD) px around him
	"bomb_hp_left": 0.25,  # TUNING (not in GDD) the lead's suggestion (as Broken Arrow): the necromancer left at this share of his max HP (never lethal)
	"bomb_summon_share": 2.0,  # TUNING (not in GDD) of each summon's max HP: destroyed
	"bomb_danger_reach": 260.0,  # TUNING (not in GDD) px the autotest bot keeps from him while the countdown runs
}
