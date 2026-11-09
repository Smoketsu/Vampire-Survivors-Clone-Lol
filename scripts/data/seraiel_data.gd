## SeraielData — immutable design data for SERAIEL, WARDEN OF THE GATE, the boss
## of the Silver Stair (temporary Act XIII, the Celestial Host, final slot X;
## GDD §15.0 "Seraiel, Warden of the Gate (Act XIII phase 2)"; owner-approved
## proposal docs/proposals/LAST_SIX_ACTS.md section X: "Boss, Seraiel, Warden
## of the Gate (male, a four-winged archangel): the Gate (walls of light split
## the arena into lanes that close one by one), the Sword (sweeps of a flaming
## sword across the ring), the Trial (he fills the scales by a third with each
## phase he survives)"). BossSeraiel (scripts/enemies/host/boss_seraiel.gd,
## loaded by name for the boss id "seraiel") reads it. A towering male archangel
## in silver armour with four wings and a flaming white sword (art
## `host/seraiel`, 96 px; no crimson, no warm gold). Three phases by his HP:
##   * THE SWORD (100% to phase2_hp): he walks at the nearest necromancer and,
##     every sword_every s once that necromancer is within sword_trigger px,
##     raises the sword for sword_windup s (an arc of marks shows its path)
##     and SWEEPS it sword_arc degrees across the ring in sword_time s, centred
##     on the necromancer: every summon and necromancer within sword_reach px
##     that the blade passes takes sword_damage_summon / sword_damage (x the
##     time scaling; CherubKit.sweep(), the one blade test).
##   * THE GATE (phase2_hp to phase3_hp; the Sword goes on): every gate_every
##     s he stands gate_cast s and the Gate rises round the necromancer:
##     gate_lanes parallel lanes gate_lane px wide, across a seeded axis, split
##     by walls of light (drawn). One lane, chosen by the seeded gameplay RNG,
##     is the GATE and never closes; the others CLOSE ONE BY ONE in a seeded
##     order, one every gate_close_every s: a wall of Hallowed Light sweeps
##     across the lane (HallowedLight.add_shaft(), the Light's one path: its
##     burn, its shade, its barriers and its lead line), gate_wall px wide.
##   * THE GATE AND THE SWORD (below phase3_hp): both, faster
##     (sword_every_p3, gate_every_p3).
##   * THE TRIAL (all fight): each phase has trial_time s; if the phase still
##     runs when they are up, he has SURVIVED it and fills the scales by a third
##     (Judgment.add(capacity / 3), THE one write), once a phase. Own reading of
##     "each phase he survives": a phase broken inside its trial adds nothing,
##     so a fast kill keeps the scales light (Without Sin).
## Beaten: a short ending text (ENDING_ANNOUNCE; no epilogue part until the
## reorder pass). Killing him drops a big XP burst and the boss chest; slaying
## him unlocks Flaming Sword, Fallen Light and so the Fallen Herald (UnlockData,
## boss "seraiel"); WITHOUT SIN is judged by SilverStairDirector when he falls.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name SeraielData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["sword", "gate", "lane_closed", "trial"]

## Sprite key of his art (assets/sprites/host/seraiel.png, 96 px, walk strip).
const SPRITE: String = "host/seraiel"
## Damage tag of his sword (stats, the death line).
const SWORD_SOURCE: String = "seraiel_sword"
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when he falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE GATE STANDS OPEN", "Seraiel, Warden of the Gate, lays down his sword.", "The stair of light runs on into the clouds, and the spheres above begin to turn."]  # TUNING (not in GDD) the words
## The ending text when he falls during the Last Trumpet.
const LATE_ANNOUNCE := ["THE GATE STANDS OPEN", "Seraiel falls as the trumpets sound.", "The Warden is gone, but the whole Host is coming down the stair."]  # TUNING (not in GDD) the words

## Seraiel's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 16000.0  # TUNING (not in GDD) first pass 24000, then 20000: the army bot's ring melted in a fight of 2+ minutes under the Light, the Gate and the Trial's Verdict (x the stage's 1.7)

## Seraiel's design row.
const BOSS := {
	"display_name": "Seraiel, Warden of the Gate",
	"max_hp": MAX_HP,
	"move_speed": 42.0,  # TUNING (not in GDD) px/s; a Warden's stride
	"damage": 13.0,  # TUNING (not in GDD) a blow in reach, before the time scaling
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px (the sprite 96 px tall)
	"armor": 0.2,  # TUNING (not in GDD) silver armour
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD)
	"faction": HostEnemyData.FACTION,
	"group": "guardians",  # The Warden of the Gate leads its guardians (the reports).
	"reward_xp": 600,  # TUNING (not in GDD) as Anubis
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.4,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.66,  # TUNING (not in GDD) the Gate below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the Gate and the Sword below this
	"phase1_banner": "THE SWORD: Seraiel's flaming sword sweeps across your ring!",  # TUNING (not in GDD)
	"phase2_banner": "THE GATE: walls of light split the stair into lanes, and they close one by one! Find the lane that stays open!",  # TUNING (not in GDD)
	"phase3_banner": "THE GATE AND THE SWORD: the Warden holds the Gate with everything he has!",  # TUNING (not in GDD)
	# The Sword.
	"sword_first": 3.0,  # TUNING (not in GDD) s after he arrives
	"sword_every": 6.0,  # TUNING (not in GDD) s between two sweeps
	"sword_every_p3": 4.5,  # TUNING (not in GDD) s, the last phase
	"sword_trigger": 220.0,  # TUNING (not in GDD) px to the necromancer for a sweep to start
	"sword_windup": 1.0,  # TUNING (not in GDD) s of telegraph (the arc of marks)
	"sword_time": 0.45,  # TUNING (not in GDD) s the blade takes to cross its arc
	"sword_arc": 120.0,  # TUNING (not in GDD) degrees, centred on the necromancer (first pass 150)
	"sword_reach": 160.0,  # TUNING (not in GDD) px: across the ring (first pass 190)
	"sword_damage": 8.0,  # TUNING (not in GDD) to the necromancer, before the time scaling (first pass 14: 345 of the seed-3 army bot's HP, down to 1)
	"sword_damage_summon": 5.0,  # TUNING (not in GDD) to each summon passed, before the time scaling (first pass 18: 15,900 to summons in the seed-7 army run, the ring wiped)
	# The Gate.
	"gate_first": 2.0,  # TUNING (not in GDD) s after the phase begins
	"gate_every": 20.0,  # TUNING (not in GDD) s between two Gates
	"gate_every_p3": 15.0,  # TUNING (not in GDD) s, the last phase
	"gate_cast": 1.0,  # TUNING (not in GDD) s he stands raising it
	"gate_lanes": 3,  # TUNING (not in GDD) lanes (one stays open; first pass 5: with the act's own shafts the Light burnt 4,000 a minute off the army bot's ring)
	"gate_lane": 120.0,  # TUNING (not in GDD) px a lane's width
	"gate_close_every": 2.2,  # TUNING (not in GDD) s between two lanes closing (a wall crosses a lane in gate_lane / the Light's speed s)
	"gate_wall": 44.0,  # TUNING (not in GDD) px, the closing wall's width (a shaft of Hallowed Light)
	"gate_show_after": 1.5,  # TUNING (not in GDD) drawing only: s the walls stay drawn after the last lane closed
	# The Trial.
	"trial_time": 40.0,  # TUNING (not in GDD) s a phase may run before he has survived it (first pass 30: two Trials and a Verdict in every army bot fight)
	"trial_share": 0.3334,  # Owner-approved proposal: "fills the scales by a third" (share of capacity; a hair over a third, so it always passes the next third)
	"trial_banner": "THE TRIAL: Seraiel endures, and the scales tip by a third!",  # TUNING (not in GDD)
}
