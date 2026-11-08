## HrimgarData — immutable design data for HRIMGAR THE DRAUGR-KING, the boss of
## the Barrow Fields (the Hall of the Slain, temporarily Act XI, Stage 16 in
## the final order; GDD §15.0 "Hrimgar the Draugr-King"; owner-approved
## proposal docs/proposals/LAST_SIX_ACTS.md "Stage 16": "he rises three times.
## Each time he falls he sinks into his barrow and returns stronger 20 s later,
## unless the necromancer breaks the barrow while he is down. Phases: the Grave
## (frost mist and draugr from every mound), the Barrow Lord (a cleaving
## greatsword), the Last Rising (he drags summons into the mound with him)").
## BossHrimgar (scripts/enemies/norse/boss_hrimgar.gd, loaded by name for the
## boss id "hrimgar") reads it. A towering male draugr king in a rime-white
## crown and rotten mail, a greatsword, ice-blue eyes (norse/hrimgar, 88 px,
## walk strip). His three RISINGS share one HP bar, cut in three LIVES:
##   * The Grave (100% to fall1_hp): he walks in with the shared AI (his
##     greatsword in reach). Every mist_every s FROST MIST: mist_count
##     telegraphed circles (mist_radius px, mist_telegraph s) on the ring
##     around the nearest necromancer burst cold: every grounded summon inside
##     takes mist_damage_summon and is chilled (CombatResolver.chill_unit(),
##     mist_chill for mist_chill_time s), the necromancer mist_damage. Every
##     call_every s DRAUGR FROM EVERY MOUND: every standing open barrow lets out
##     call_per_barrow draugr at once, and call_new new open barrows crack open
##     around the ring (BarrowFieldsDirector.open_barrow(), the one barrow path).
##   * The Barrow Lord (fall1_hp to fall2_hp): THE CLEAVE: every cleave_every s
##     he raises the greatsword (cleave_windup s; a sector telegraph
##     cleave_reach px, cleave_half rad wide toward the nearest necromancer)
##     and cleaves: every summon in the sector takes cleave_damage_summon and is
##     knocked cleave_knock px, the necromancer cleave_damage. The mist goes on
##     at mist_every_lord.
##   * The Last Rising (below fall2_hp): THE DRAG: every drag_every s he reaches
##     for the drag_count summons nearest him within drag_reach px: each is HELD
##     (SummonedUnit.held_until, the existing held hook, plus one
##     CombatResolver.stun_unit()) and drawn to him over drag_pull s, then held
##     in the mound drag_hold s taking drag_dps of its max HP a second
##     (damage_unit()); his fall releases them. The cleave goes on at
##     cleave_every_last.
##   * HIS FALLS: when his HP reaches fall1_hp (and later fall2_hp) he does not
##     die: he SINKS (sink_time s, untargetable) and HIS BARROW rises where he
##     fell (BarrowFieldsEnemyData "hrimgar_barrow": draugr climb out of it).
##     If the barrow is broken within down_time s, he never rises again: he
##     dies for good (the boss kill path). Otherwise he RISES from it (rise_time
##     s) as his next phase, each rising stronger (x rise_damage damage and
##     x rise_speed speed per rising, his HP back up to the top of his life:
##     the floor he fell at plus rise_heal of max HP, never above it).
## Killing him (his last life, or a broken barrow) drops a big XP burst and the
## boss chest; slaying him unlocks Barrow Grasp and Grave Frost (UnlockData,
## boss "hrimgar"). A short ending text only (no epilogue until the reorder
## pass, docs/last_acts/PLAN.md). The GDD gives no numbers: everything is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name HrimgarData
extends RefCounted

## Hrimgar's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "hrimgar" through BarrowFieldsStage.BOSS, so --boss=hrimgar and the Codex
## find him).
const ARRIVAL := {
	"id": "hrimgar",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Hrimgar the Draugr-King",  # Owner-approved proposal
	"short_name": "Hrimgar",
	"arrive_banner": "Hrimgar the Draugr-King rises from his barrow!",  # TUNING (not in GDD)
	"defeat_banner": "Hrimgar sinks into his barrow for good! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Hrimgar is dead. Survive Ragnarok... you cannot.",  # TUNING (not in GDD)
}
## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["frost_mist", "mound_call", "cleave", "drag", "fall", "rising"]
## Sprite key of his art (assets/sprites/norse/hrimgar.png; 88 px still, walk strip).
const SPRITE: String = "norse/hrimgar"
## Sprite key of his barrow, intact / broken (BarrowFieldsEnemyData "hrimgar_barrow").
const BARROW_SPRITE: String = "norse/boss_barrow"
## Sprite key of his barrow broken (drawn a moment where it fell).
const BARROW_BROKEN_SPRITE: String = "norse/boss_barrow_broken"
## Damage tag of his frost mist.
const MIST_SOURCE: String = "hrimgar_mist"
## Damage tag of his cleave.
const CLEAVE_SOURCE: String = "hrimgar_cleave"
## Damage tag of the drag's crush in the mound.
const DRAG_SOURCE: String = "hrimgar_drag"
## Damage tag of the forced death when his barrow is broken (his kill path).
const BROKEN_SOURCE: String = "barrow_broken"
## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text (HUD announce: title, line, text). No epilogue (PLAN).
const ENDING_ANNOUNCE := ["THE BARROW IS SEALED", "Hrimgar the Draugr-King falls.", "The barrow-dead lie down in the snow. Far to the north a horn answers, and the hall's empty benches wait for heroes."]  # TUNING (not in GDD) the words
## The ending text when he falls during Ragnarok.
const LATE_ANNOUNCE := ["THE BARROW IS SEALED", "Hrimgar falls as the sun goes out.", "His barrow closes over him, and the giants of the south walk on through the dark."]  # TUNING (not in GDD) the words
## The ending text when his barrow was broken while he was down.
const BROKEN_ANNOUNCE := ["THE BARROW IS BROKEN", "Hrimgar does not rise again.", "You broke the king's mound while he lay in it. The barrow-dead lie down in the snow."]  # TUNING (not in GDD) the words
## Hrimgar's base max HP (x the boss HP multiplier and the stage's 1.6), all
## three lives together (Achilles 12,000 on Ilion x1.4, Kage 11,000 x1.55).
const MAX_HP: float = 10200.0  # TUNING (not in GDD) balance pass 2: 12,000 -> 10,200 (he outlived 2 of 3 army bots by a hair); three lives on one bar, and 40 s down between them
## Hrimgar's design row.
const BOSS := {
	"display_name": "Hrimgar the Draugr-King",
	"max_hp": MAX_HP,
	"move_speed": 44.0,  # TUNING (not in GDD) px/s; a slow, heavy king
	"damage": 12.0,  # TUNING (not in GDD) his greatsword in reach, before the time scaling
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px (the sprite 88 px tall)
	"armor": 0.15,  # TUNING (not in GDD) rotten mail
	"flat_armor": 4.0,  # TUNING (not in GDD) a draugr's armour 3, a king's
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 14.0,  # TUNING (not in GDD)
	"faction": NorseEnemyData.FACTION,
	"group": "wilds",  # The barrow-dead's king (the reports group him there).
	"reward_xp": 600,  # TUNING (not in GDD) as the Hive Mother
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.5,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 2.4,  # TUNING (not in GDD) first pass 1.8: risen at his barrow far behind, he spent 88 s walking after the seed-7 necromancer
	# His falls and risings.
	"fall1_hp": 0.67,  # TUNING (not in GDD) the Grave ends here (his first fall)
	"fall2_hp": 0.34,  # TUNING (not in GDD) the Barrow Lord ends here (his second fall)
	"sink_time": 1.2,  # TUNING (not in GDD) s he sinks into the ground
	"down_time": 20.0,  # Owner-approved proposal: "returns stronger 20 s later"
	"rise_time": 1.4,  # TUNING (not in GDD) s he climbs out of the barrow
	"rise_heal": 0.03,  # TUNING (not in GDD) share of max HP he rises with above the floor he fell at
	"rise_damage": 1.15,  # TUNING (not in GDD) x damage per rising ("returns stronger")
	"rise_speed": 1.08,  # TUNING (not in GDD) x speed per rising
	"barrow_offset": 0.0,  # TUNING (not in GDD) px his barrow rises from where he fell (0 = on the spot)
	"fall1_banner": "HRIMGAR FALLS... and sinks into his barrow! Break it before he rises again!",  # TUNING (not in GDD)
	"rise2_banner": "THE BARROW LORD: Hrimgar rises again, his greatsword drawn! Out of the cleave!",  # TUNING (not in GDD)
	"fall2_banner": "Hrimgar sinks into his barrow once more! Break it, or he rises a last time!",  # TUNING (not in GDD)
	"rise3_banner": "THE LAST RISING: Hrimgar drags your dead into the mound with him!",  # TUNING (not in GDD)
	# The Grave: frost mist and draugr from every mound.
	"mist_first": 4.0,  # TUNING (not in GDD) s after he arrives
	"mist_every": 7.0,  # TUNING (not in GDD) s between two mists (the Grave)
	"mist_every_lord": 10.0,  # TUNING (not in GDD) s between two mists (the Barrow Lord)
	"mist_count": 3,  # TUNING (not in GDD) mist circles a time
	"mist_radius": 52.0,  # TUNING (not in GDD) px
	"mist_min": 50.0,  # TUNING (not in GDD) px from the necromancer
	"mist_max": 140.0,  # TUNING (not in GDD) px (the ring is 60-150 px)
	"mist_telegraph": 1.3,  # TUNING (not in GDD) s the circle shows before it bursts
	"mist_damage": 6.0,  # TUNING (not in GDD) first pass 9 (seed-7 army: min HP 27% in his fight); to a necromancer, before the time scaling, once
	"mist_damage_summon": 8.0,  # TUNING (not in GDD) first pass 12 (his Grave cost the seed-7 army 74 summons); to a summon, before the time scaling, once
	"mist_chill": 0.4,  # TUNING (not in GDD) share of a summon's speed lost
	"mist_chill_time": 3.0,  # TUNING (not in GDD) s
	"call_first": 6.0,  # TUNING (not in GDD) s after he arrives
	"call_every": 16.0,  # TUNING (not in GDD) s between two calls (the Grave only)
	"call_per_barrow": 2,  # TUNING (not in GDD) draugr each standing open barrow lets out
	"call_new": 2,  # TUNING (not in GDD) new open barrows cracking around the ring
	"call_dist": 230.0,  # TUNING (not in GDD) px from the necromancer the new barrows crack
	# The Barrow Lord: the cleave.
	"cleave_first": 2.5,  # TUNING (not in GDD) s after he rises
	"cleave_every": 5.5,  # TUNING (not in GDD) s between two cleaves (the Barrow Lord)
	"cleave_every_last": 7.5,  # TUNING (not in GDD) s (the Last Rising)
	"cleave_windup": 1.0,  # TUNING (not in GDD) s he raises the greatsword (the sector shows)
	"cleave_reach": 120.0,  # TUNING (not in GDD) px
	"cleave_half": 0.9,  # TUNING (not in GDD) rad half-angle of the sector (~100 degrees wide)
	"cleave_damage": 14.0,  # TUNING (not in GDD) first pass 16; to a necromancer, before the time scaling, once
	"cleave_damage_summon": 18.0,  # TUNING (not in GDD) first pass 26; to a summon, before the time scaling, once
	"cleave_knock": 40.0,  # TUNING (not in GDD) px a struck summon is thrown
	# The Last Rising: the drag.
	"drag_first": 3.0,  # TUNING (not in GDD) s after he rises
	"drag_every": 9.0,  # TUNING (not in GDD) s between two drags
	"drag_count": 3,  # TUNING (not in GDD) summons a drag
	"drag_reach": 220.0,  # TUNING (not in GDD) px from him
	"drag_pull": 0.8,  # TUNING (not in GDD) s a summon is drawn to him
	"drag_hold": 3.5,  # TUNING (not in GDD) s it is held in the mound
	"drag_dps": 0.06,  # TUNING (not in GDD) share of its max HP lost a second in the mound
}
