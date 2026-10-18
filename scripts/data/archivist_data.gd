## ArchivistData — THE ARCHIVIST, KEEPER OF THE UNWRITTEN, the boss of the
## Hollow Archive (Stage 5; GDD §15.0 "Act II: the Hollow Archive",
## owner-approved proposal "Boss: The Archivist"): a robed figure whose face is
## an open book. BossArchivist reads this file; no logic here.
## Her three abilities:
##   Recitation — pages fly up around her, hover for page_rise_time s (the
##                telegraph), then home on the necromancer; a page that hits
##                him or a summon on the way bursts into a short-lived ink
##                pool (ArchiveHazards: slow and Dread).
##   Footnotes  — from the second phase she splits into three: two copies
##                (ArchiveEnemyData "archivist_copy", ArchivistCopy) walk with
##                her for footnote_time s. Only the one casting a shadow (the
##                real Archivist) takes damage; blows on a copy are wasted.
##   Erasure    — erasure_start s after she arrives, the edges of the field
##                erase: a circle of erasure_radius px around the necromancer,
##                whose wall steps erasure_step px inward every
##                erasure_interval s (each step telegraphed for
##                erasure_telegraph s) down to erasure_min, until she falls.
##                The necromancer and the army are pushed back inside (never
##                into an obstacle); the Eye walks in from the void freely.
## Phases (fight_phase): 0 the Reading (Recitation), 1 the Footnotes (from
## footnote_hp_fraction: Recitation and Footnotes), 2 the Last Page (from
## last_page_hp_fraction: more pages, shorter gaps, Footnotes more often).
## Row keys: every EnemyData row key, the shared boss keys (reward_xp,
## reward_crystals, slow_resist, attack_gap, first_special, recover_time),
## and the ability keys below. The GDD gives no numbers: everything is TUNING
## (not in GDD).
class_name ArchivistData
extends RefCounted

## Her special ability ids, in report order (the autotest "boss attacks"
## line reads the boss_atk_<id> stats; Erasure is a rule, not a special).
const SPECIALS := ["recitation", "footnotes"]

## Her arrival in a stage's boss slot (StageRegistry "boss" keys, see
## GraveyardStage.BOSS). The Hollow Archive uses it; --boss=archivist puts it
## in any stage's slot (StageRegistry.BOSS_ARRIVALS, keeping that stage's time).
const ARRIVAL := {
	"id": "archivist",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "The Archivist, Keeper of the Unwritten",  # Owner-approved proposal
	"short_name": "The Archivist",
	"arrive_banner": "The Archivist opens her book: the Keeper of the Unwritten reads your ending!",  # TUNING (not in GDD)
	"defeat_banner": "The last page burns. You know now where the god sleeps.",  # TUNING (not in GDD) owner-approved story: "The Archive: you learn where the god sleeps"
	"dead_objective": "The Archivist's book is ash. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## The boss row (keys in the header).
const BOSS := {
	"display_name": "The Archivist, Keeper of the Unwritten",
	"max_hp": 20000.0,  # TUNING (not in GDD) x the stage HP multiplier; Footnotes waste part of the army's damage on copies
	"move_speed": 46.0,  # TUNING (not in GDD)
	"damage": 12.0,  # TUNING (not in GDD) a blow of her book in reach
	"attack_interval": 1.2,  # TUNING (not in GDD)
	"attack_range": 8.0,  # TUNING (not in GDD)
	"radius": 22.0,  # TUNING (not in GDD)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD) shoves warriors aside
	"reward_xp": 520,  # TUNING (not in GDD) a little more than Seraphine's 500
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD)
	"attack_gap": 2.2,  # TUNING (not in GDD) s between the end of one special and the next
	"first_special": 2.0,  # TUNING (not in GDD)
	"recover_time": 0.6,  # TUNING (not in GDD)
	# Phases.
	"footnote_hp_fraction": 0.6,  # TUNING (not in GDD) the Footnotes from 60% HP
	"last_page_hp_fraction": 0.25,  # TUNING (not in GDD) the Last Page from 25% HP
	"phase_gap_mult": [1.0, 0.9, 0.65],  # TUNING (not in GDD) per phase
	"phase_banners": ["", "The Archivist writes herself into the margins: only one of her casts a shadow!", "The Last Page! The Archivist reads faster!"],  # TUNING (not in GDD)
	# Forced march: she never kites and catches up when left behind.
	"advance_range": 240.0,  # TUNING (not in GDD) px
	"advance_speed_mult": 1.8,  # TUNING (not in GDD) 46 -> 83 px/s (the necromancer runs at 110)
	# Recitation.
	"recitation_cooldown": 4.5,  # TUNING (not in GDD) s
	"recitation_cast": 0.8,  # TUNING (not in GDD) s she stands reading (the cast pose)
	"pages": [8, 10, 13],  # TUNING (not in GDD) pages per Recitation, per phase
	"page_rise_time": 0.5,  # TUNING (not in GDD) s the pages hover before they hunt (the telegraph)
	"page_rise_radius": 46.0,  # TUNING (not in GDD) px around her the pages rise to
	"page_speed": 150.0,  # TUNING (not in GDD) px/s (the necromancer runs at 110: he outpaces none, so he dodges by turning)
	"page_turn": 2.4,  # TUNING (not in GDD) rad/s homing turn rate (a sharp sidestep beats it)
	"page_life": 4.5,  # TUNING (not in GDD) s a page hunts before it crumbles
	"page_radius": 8.0,  # TUNING (not in GDD) px contact radius
	"page_damage_player": 6.0,  # TUNING (not in GDD) before time scaling (8 at first: the pages were the top hitter of the builds that died to her)
	"page_damage_summon": 5.0,  # TUNING (not in GDD) before time scaling
	"page_pool_radius": 34.0,  # TUNING (not in GDD) px ink pool where a page hits
	"page_pool_life": 4.0,  # TUNING (not in GDD) owner-approved proposal "a short-lived ink pool"
	# Footnotes.
	"footnote_cooldown": [0.0, 16.0, 12.0],  # TUNING (not in GDD) s per phase (0 = not in that phase)
	"footnote_cast": 1.0,  # TUNING (not in GDD) s of the splitting glow (the telegraph)
	"footnote_time": 9.0,  # TUNING (not in GDD) s the copies walk with her
	"footnote_spread": 1.75,  # TUNING (not in GDD) rad; the three stand this far apart around the necromancer
	# Erasure.
	"erasure_start": 6.0,  # TUNING (not in GDD) s after her arrival (she has walked in by then)
	"erasure_interval": 20.0,  # Owner-approved proposal "the walls step inward every 20 s"
	"erasure_telegraph": 3.0,  # TUNING (not in GDD) s the next edge glows before the wall steps
	"erasure_radius": 620.0,  # TUNING (not in GDD) px first radius around the necromancer
	"erasure_step": 60.0,  # TUNING (not in GDD) px per step
	"erasure_min": 260.0,  # TUNING (not in GDD) px; it never closes tighter
}

## Look of the fight (BossArchivist / ArchiveGlyphs; drawing only).
const PAGE_COLOR: Color = Color(0.93, 0.89, 0.76)  # TUNING (not in GDD) parchment (bone ivory)
const ERASE_COLOR: Color = Color(0.86, 0.84, 0.78)  # TUNING (not in GDD) the blank, erased page beyond the edge
const ERASE_EDGE: Color = Color(0.20, 0.18, 0.42)  # TUNING (not in GDD) ink line of the edge
const COPY_TINT: Color = Color(0.72, 0.74, 0.92, 0.82)  # TUNING (not in GDD) a Footnote copy: pale, faintly see-through, no shadow
## Seconds the defeat banner stays on the HUD.
const ENDING_BANNER_TIME: float = 8.0  # TUNING (not in GDD)
