## CarmillaData — immutable design data of QUEEN CARMILLA AND THE ELDER, the
## boss of Castle Sanguis and the finale of Act VII (the Sanguine Court; GDD
## §15.0 "Queen Carmilla and the Elder (Act VII phase 2)"; owner-approved
## proposal docs/act7/PROPOSAL.md "Stage 21: Castle Sanguis"). BossCarmilla
## (scripts/enemies/court/boss_carmilla.gd, loaded by name for the boss id
## "carmilla") reads BOSS; StageRegistry.BOSS_ARRIVALS and CastleSanguisStage
## .BOSS read ARRIVAL. She descends from the Throne of Blood at 17:00 (3:00
## left). One boss body, three phases (the HUD's one boss bar shows hers, then
## the Elder's):
##   THE COURT (her health, 100% -> waking_hp): the Queen (female, the figure
##        style at its limit, chest and hips covered) walks at the necromancer
##        (enemies always advance) with her claws, and takes turns between:
##          THE MIST DANCE: she turns to mist (untargetable, immune) and
##          dances THROUGH the ring along a telegraphed line (mist_telegraph
##          s) past the necromancer (mist_overshoot px beyond him) in
##          mist_time s; every body on the line (mist_width px) is drained
##          once (mist_damage_*, a feeding hit: Bloodfeast);
##          THE DRAIN BEAM: a blood beam beam_length px long sweeps beam_arc
##          degrees across the army in beam_time s after a beam_telegraph s
##          warning; every beam_tick s every body on it is drained
##          (beam_damage_*, feeding hits);
##        and her nobles feed around her: noble_count Vampire Nobles step out
##        beside her on arrival and every noble_every s (at most noble_max
##        alive).
##   THE WAKING (at waking_hp of her health): she flies (mist) to the ELDER'S
##        COFFIN, which rises coffin_dist px from the necromancer on her side,
##        and kneels there for up to waking_time s, immune. The boss bar
##        becomes the Elder's: it starts at elder_floor of his health and
##        FILLS with every heal she lands on him (CombatResolver.heal_enemy(),
##        the existing enemy heal path, she the healer, so a Keening Lady's
##        silence stops it too): feed_rate of his health per second while she
##        feeds, and bearer_heal for every BLOOD BEARER that reaches her
##        (bearer_count of them every bearer_every s from the edge of the
##        fight; CastleSanguisEnemyData "blood_bearer"). INTERRUPT her
##        (owner-approved proposal: "stuns, Soul Chains, killing the thralls
##        that bring her blood"): a stun or a Deep Freeze on her, or a Soul
##        Chains / Chains of the Damned hit, stops her feeding for
##        interrupt_time s; a dead bearer pours nothing. The Waking ends when
##        the time is up or the Elder is full.
##   THE ELDER (rise_time s invulnerable as he climbs out, then his health is
##        what she gave him: owner-approved proposal "with as much HP as she
##        gave him"): the first vampire, a bat-winged horror (male), radius
##        elder_radius, slow (elder_speed_mult). He COMMANDS EVERY BAT ON THE
##        MAP (on rising and every command_every s every flier alive is set on
##        the necromancer with a command_time s frenzy: x command_damage blow,
##        x command_speed pace; command_bats more Vampire Bats burst from his
##        wings), FEEDS ON EVERYTHING HE TOUCHES (every touch_tick s each body
##        touching him is drained touch_damage_*, a feeding hit; his blows and
##        his buffet feed too: "feeds" 0.5) and beats his WINGS (a telegraphed
##        circle of buffet_radius px around him, buffet_telegraph s, every
##        body in it struck buffet_damage_* and the summons thrown buffet_push
##        px back).
## Beaten, the Elder turns to ash and the Court's veil tears: a short ending
## text only (ENDING_ANNOUNCE), no epilogue (owner decision Oct 31, 2026).
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, feeds) and the abilities' own
## numbers. Damage keys are before the time scaling. The GDD gives no numbers:
## everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal.
class_name CarmillaData
extends RefCounted

## Her arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "carmilla" through CastleSanguisStage.BOSS, so --boss=carmilla and the Codex
## find her). Her script is found by the id (boss_carmilla.gd).
const ARRIVAL := {
	"id": "carmilla",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Queen Carmilla and the Elder",  # Owner-approved proposal
	"short_name": "Carmilla",
	"arrive_banner": "Queen Carmilla descends from the Throne of Blood!",  # TUNING (not in GDD)
	"defeat_banner": "The Elder turns to ash. The Court's veil over the world tears.",  # Owner-approved proposal ending
	"dead_objective": "The Court is broken. Survive the Endless Feast... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["mist_dance", "drain_beam", "nobles", "waking", "interrupted", "bearers_poured", "elder_rises", "bat_command", "wing_buffet"]

## Damage source tag of her mist dance (a feeding drain).
const SRC_MIST: String = "carmilla_mist"
## Damage source tag of her drain beam (a feeding drain).
const SRC_BEAM: String = "carmilla_beam"
## Damage source tag of the Elder's touch (a feeding drain).
const SRC_TOUCH: String = "elder_touch"
## Damage source tag of the Elder's wing buffet (AREA).
const SRC_BUFFET: String = "elder_buffet"
## Damage sources that interrupt her Waking when they strike her (Soul Chains
## and its evolution, NecroSpellBook.SOURCES "soul_chains"; owner-approved
## proposal: "Interrupt her (stuns, Soul Chains ...)").
const INTERRUPT_SOURCES := ["soul_chains", "chains_damned"]

## Sprite key of the Queen (BossPoseData pose 1: the beam raised, if posed).
const SPRITE_QUEEN: String = "bosses/carmilla"
## Sprite key of the Elder.
const SPRITE_ELDER: String = "bosses/elder"
## Sprite key of the Elder's coffin, closed and open.
const SPRITE_COFFIN: String = "structures/elder_coffin"
## Sprite key of the open coffin (the Elder has risen).
const SPRITE_COFFIN_OPEN: String = "structures/elder_coffin_open"

## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on the Elder's fall (title, line, description): the
## proposal's ending ("Beaten, the Elder turns to ash, and the Court's veil over
## the world tears"), kept short (no epilogue, owner decision Oct 31, 2026).
const ENDING_ANNOUNCE := ["THE VEIL TEARS", "The Elder turns to ash.", "The first vampire crumbles in his coffin, and the veil the Court drew over the world for a thousand years tears like old silk. The feast is over."]  # Owner-approved proposal ending (TUNING the words)
## Shorter announcement when he falls after 0:00 (the Endless Feast rages on).
const LATE_ANNOUNCE := ["THE VEIL TEARS", "The Elder turns to ash.", "Even under the endless moon, the first vampire is dust."]  # TUNING (not in GDD)

## Her design row (the Elder shares it: one boss body).
const BOSS := {
	"display_name": "Queen Carmilla",
	"max_hp": 6400.0,  # TUNING (not in GDD) her bar, before the stage / co-op scaling (the Morning Star's two phases 14,000 in all; the Elder's below); first pass 7600 + 8400: the Elder outlived 0:00 in the seed-7 army run
	"move_speed": 52.0,  # TUNING (not in GDD) px/s
	"damage": 12.0,  # TUNING (not in GDD) a raking claw (the Elder's blow too), before the time scaling
	"attack_interval": 1.2,  # TUNING (not in GDD) s
	"attack_range": 12.0,  # TUNING (not in GDD) px
	"radius": 18.0,  # TUNING (not in GDD) px (the Elder: elder_radius)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 1.0,
	"mass": 30.0,  # TUNING (not in GDD)
	"slow_resist": 0.7,  # TUNING (not in GDD) like every boss
	"feeds": 0.5,  # Owner-approved (Oct 31, 2026): vampires feed 50% (Bloodfeast.share_of(): a boss's boss_def "feeds")
	"reward_xp": 900,  # TUNING (not in GDD) as the Morning Star
	"reward_crystals": 30,  # TUNING (not in GDD)
	"arrive_time": 2.0,  # TUNING (not in GDD) s she descends (invulnerable)
	"advance_range": 380.0,  # TUNING (not in GDD) px beyond which she strides faster
	"advance_speed_mult": 2.0,  # TUNING (not in GDD)
	# The Court.
	"special_first": 3.0,  # TUNING (not in GDD) s after the Court begins
	"special_gap": 4.5,  # TUNING (not in GDD) s between two specials (the mist dance and the beam take turns)
	"mist_telegraph": 0.8,  # TUNING (not in GDD) s the line is shown before she dances
	"mist_time": 0.8,  # TUNING (not in GDD) s of the dance itself
	"mist_overshoot": 130.0,  # TUNING (not in GDD) px past the necromancer she ends
	"mist_width": 30.0,  # TUNING (not in GDD) px
	"mist_damage_player": 8.0,  # TUNING (not in GDD)
	"mist_damage_summon": 10.0,  # TUNING (not in GDD)
	"beam_telegraph": 0.8,  # TUNING (not in GDD) s
	"beam_time": 1.6,  # TUNING (not in GDD) s of the sweep
	"beam_arc": 100.0,  # TUNING (not in GDD) degrees swept (centred on the necromancer)
	"beam_length": 260.0,  # TUNING (not in GDD) px
	"beam_width": 18.0,  # TUNING (not in GDD) px
	"beam_tick": 0.2,  # TUNING (not in GDD) s
	"beam_damage_player": 2.2,  # TUNING (not in GDD) per tick
	"beam_damage_summon": 2.6,  # TUNING (not in GDD) per tick
	"noble_count": 2,  # Owner-approved proposal: "her nobles feed around her"; TUNING the number
	"noble_every": 24.0,  # TUNING (not in GDD) s
	"noble_max": 4,  # TUNING (not in GDD) nobles alive at once
	"noble_dist": 60.0,  # TUNING (not in GDD) px beside her they step out
	# The Waking.
	"waking_hp": 0.05,  # TUNING (not in GDD) share of her health at which she goes to the coffin (above 0, so no blow kills her first)
	"coffin_dist": 170.0,  # TUNING (not in GDD) px from the necromancer the coffin rises
	"kneel_travel": 1.6,  # TUNING (not in GDD) s at most of her flight to the coffin (mist)
	"waking_time": 22.0,  # TUNING (not in GDD) s at most she kneels
	"elder_hp": 6400.0,  # TUNING (not in GDD) the Elder's full health, before the stage / co-op scaling
	"elder_floor": 0.2,  # TUNING (not in GDD) share of his health he has before she feeds
	"feed_rate": 0.018,  # TUNING (not in GDD) share of his health per second while she feeds
	"feed_tick": 0.25,  # TUNING (not in GDD) s between two feeding heals
	"interrupt_time": 2.5,  # TUNING (not in GDD) s a stun, a freeze or a Soul Chains hit stops her feeding
	"bearer_every": 2.5,  # TUNING (not in GDD) s
	"bearer_count": 2,  # TUNING (not in GDD) bearers each time
	"bearer_heal": 0.035,  # TUNING (not in GDD) share of his health one bearer's chalice is worth
	# The Elder.
	"rise_time": 2.5,  # TUNING (not in GDD) s he climbs out (invulnerable)
	"elder_radius": 30.0,  # TUNING (not in GDD) px (drawn huge)
	"elder_speed_mult": 0.75,  # TUNING (not in GDD) x her walk
	"command_every": 14.0,  # TUNING (not in GDD) s
	"command_time": 6.0,  # TUNING (not in GDD) s of the bats' frenzy
	"command_damage": 1.3,  # TUNING (not in GDD) x a commanded flier's blows
	"command_speed": 1.35,  # TUNING (not in GDD) x its pace
	"command_bats": 6,  # TUNING (not in GDD) Vampire Bats from his wings each time
	"touch_tick": 0.5,  # TUNING (not in GDD) s
	"touch_reach": 6.0,  # TUNING (not in GDD) px edge to edge counts as touching
	"touch_damage_player": 2.5,  # TUNING (not in GDD)
	"touch_damage_summon": 3.0,  # TUNING (not in GDD)
	"buffet_first": 3.0,  # TUNING (not in GDD) s after he rises
	"buffet_cooldown": 6.0,  # TUNING (not in GDD) s
	"buffet_trigger": 110.0,  # TUNING (not in GDD) px: he beats his wings when a body is this close
	"buffet_radius": 100.0,  # TUNING (not in GDD) px
	"buffet_telegraph": 1.0,  # TUNING (not in GDD) s
	"buffet_damage_player": 12.0,  # TUNING (not in GDD)
	"buffet_damage_summon": 13.0,  # TUNING (not in GDD)
	"buffet_push": 40.0,  # TUNING (not in GDD) px
}
