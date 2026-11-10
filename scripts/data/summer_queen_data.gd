## SummerQueenData — immutable design data for THE SUMMER QUEEN OF THE FAE, the
## boss of the Fae Court (temporary Act XV, the Turning Year, final slot XV; GDD
## §15.0 "The Summer Queen (Act XV phase 2)"; owner-approved proposal
## docs/proposals/LAST_SIX_ACTS.md section XV, "Stage 44: The Fae Court": "Boss,
## the Summer Queen (female, figure style): the Masque (glamour: she and her
## court change faces, and only hits reveal which is real), the Bargain (she
## offers the necromancer a bargain on screen, a real choice: a strong boon at a
## price, such as +30% army damage for 60 s while the army no longer heals;
## refuse and she attacks harder), the Court in Bloom (she floods the arena with
## blossoms and thorns until she falls)"). BossSummerQueen
## (scripts/enemies/wild/boss_summer_queen.gd, loaded by name for the boss id
## "summer_queen") reads it. Art `wild/summer_queen` (64x80, glide strip, idle,
## pose 1 the bargain; `wild/summer_queen_mask` the masked face her court wears;
## docs/year/ART_MANIFEST.md). Her fight (she comes with 3:00 left, in her own
## endless summer):
##   * PETALS (all fight): every petal_every s she throws petal_bolts petal bolts
##     in a fan (petal_spread degrees) at the nearest necromancer (the plain
##     hostile shot: petal_damage x the time scaling to whatever it strikes).
##   * THE MASQUE (from masque_first s, every masque_every s): she vanishes in
##     a swirl of petals and masque_faces courtiers (FaeCourtEnemyData
##     "masked_courtier") appear with her on a ring masque_ring px round the
##     necromancer, all wearing her face; she takes one of the places (seeded).
##     The first hit on a courtier unmasks it; the first hit on HER unmasks her
##     and every face still masked (masque_banner / reveal_banner); after
##     masque_time s she drops her mask anyway.
##   * THE BARGAIN (once at each share of bargain_at): she offers one of
##     BARGAINS (in order) on screen, two choices: ACCEPT (the boon and its
##     price, through WildRules.take_bargain(): army damage for `time` s while
##     the army heals no more, and a life cost) or REFUSE (SCORN: her specials
##     strike scorn_damage harder and come scorn_haste sooner, for the rest of
##     the fight, stacking). Solo: the run pauses as for a level-up; online
##     co-op: a lockstep command (CoopLockstep.Cmd.BARGAIN), the first answer
##     counts, none within offer_time s is a refusal; the autotest's bots
##     accept (the naive bot refuses).
##   * THE COURT IN BLOOM (from bloom_first s until she falls): every
##     bloom_every s (down to bloom_min_every as her HP falls) she sows
##     bloom_count blossoms bloom_spread px round the necromancer (one on him);
##     each shows bloom_lead s, then bursts into thorns: every grounded summon
##     within bloom_radius px takes bloom_damage_summon and the necromancer
##     bloom_damage; every bloom_seed_every-th blossom leaves a thorn thicket's
##     seed (Thickets.plant(), the one planting path, growing in bloom_grow s).
## Beaten: a short ending text (no epilogue part until the reorder pass). Slaying
## her unlocks Glamour with Changeling (UnlockData, boss "summer_queen").
## Everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal. Tuned for the final slot XV.
class_name SummerQueenData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["petals", "masque", "bargain", "bloom"]

## Sprite key of her art (assets/sprites/wild/summer_queen.png, glide strip;
## pose 1 `summer_queen_bargain`, a hand held out with the bargain).
const SPRITE: String = "wild/summer_queen"
## Sprite key of the masked face she and her courtiers wear during the Masque.
const MASK_SPRITE: String = "wild/summer_queen_mask"
## Damage tag of her petal bolts (and her masked courtiers' bolts).
const PETAL_SOURCE: String = "summer_queen_petals"
## Damage tag of the Court in Bloom's thorns.
const BLOOM_SOURCE: String = "summer_queen_bloom"
## Damage tag of a bargain's life cost.
const BARGAIN_SOURCE: String = "summer_bargain"
## Seconds the ending line stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when she falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE SUMMER ENDS", "The Summer Queen's last mask falls.", "Her roses brown at once, and for the first time the sky over her court begins to set."]  # TUNING (not in GDD) the words
## The ending text when she falls during Spring Returns.
const LATE_ANNOUNCE := ["THE SUMMER ENDS", "The Summer Queen falls as spring returns.", "Her court wilts, and the year turns on without her."]  # TUNING (not in GDD) the words
## Petal pink of her blossoms and her glamour (visual only; Palette.WILD_BLOSSOM's light).
const PETAL := Color(0.98, 0.70, 0.82)  # TUNING (not in GDD) visual only

## The Summer Queen's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 8000.0  # TUNING (not in GDD) a little over the Stag King's 7,600: her bargains lend the army their damage (first passes 7,800 and 7,000: never slain while the bot walked round the fairy rings, then slain in 53-73 s)

## The bargains she offers, in order (one at each share of bargain_at). Each:
##   title       — the dialog's title (TITLE tier).
##   text        — the offer, boon and price (one BODY line).
##   damage      — + army damage share while it lasts (WildRules.take_bargain()).
##   time        — s the boon and the no-heal price last.
##   no_heal     — true: the army heals no more while it lasts.
##   life_cost   — share (0..1) of each necromancer's current HP paid at once
##                 (CombatResolver.pay_life(): no ward or i-frame stops a price).
const BARGAINS: Array[Dictionary] = [
	{"title": "The Rose Oath", "text": "+30% army damage for 60 s, but your army cannot heal while it lasts.",
		"damage": 0.3, "time": 60.0, "no_heal": true, "life_cost": 0.0},  # Owner-approved proposal: "+30% army damage for 60 s while the army no longer heals"
	{"title": "The Thorn Tithe", "text": "+40% army damage for 45 s, but your army cannot heal and you pay a fifth of your life.",
		"damage": 0.4, "time": 45.0, "no_heal": true, "life_cost": 0.2},  # TUNING (not in GDD) the second, dearer bargain
]
## Word on the dialog's accept button.
const ACCEPT_WORD: String = "Accept"  # TUNING (not in GDD)
## Word on the dialog's refuse button (focused first: an accidental press refuses).
const REFUSE_WORD: String = "Refuse"  # TUNING (not in GDD)

## The Summer Queen's design row.
const BOSS := {
	"display_name": "The Summer Queen of the Fae",
	"max_hp": MAX_HP,
	"move_speed": 46.0,  # TUNING (not in GDD) px/s (she glides)
	"damage": 10.0,  # TUNING (not in GDD) a thorned sceptre in reach, before the time scaling
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px (the sprite 64x80)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 14.0,  # TUNING (not in GDD)
	"faction": WildEnemyData.FACTION,
	"group": "fae",  # The queen of the fae (the reports).
	"no_bloom": true,  # A boss never heals on living ground.
	"reward_xp": 600,  # TUNING (not in GDD) as the Stag King
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"advance_range": 460.0,  # TUNING (not in GDD) px; farther than this she glides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	"arrive_banner": "THE SUMMER QUEEN holds court! Every face may be hers, and she has a bargain for you.",  # TUNING (not in GDD)
	# Petals.
	"petal_first": 2.0,  # TUNING (not in GDD) s after she arrives
	"petal_every": 3.4,  # TUNING (not in GDD) s between two fans
	"petal_range": 420.0,  # TUNING (not in GDD) px to the necromancer for a fan
	"petal_bolts": 5,  # TUNING (not in GDD) bolts in a fan
	"petal_spread": 44.0,  # TUNING (not in GDD) degrees
	"petal_speed": 280.0,  # TUNING (not in GDD) px/s
	"petal_damage": 5.0,  # TUNING (not in GDD) per bolt, before the time scaling
	# The Masque.
	"masque_first": 14.0,  # TUNING (not in GDD) s after she arrives
	"masque_every": 36.0,  # TUNING (not in GDD) s between two Masques (start to start; first pass 32)
	"masque_faces": 4,  # Owner-approved proposal: "she and her court change faces"; TUNING (not in GDD) courtiers beside her
	"masque_ring": 170.0,  # TUNING (not in GDD) px from the necromancer (first pass 250: she spent the Masques walking back to the ring)
	"masque_time": 18.0,  # TUNING (not in GDD) s at most she stays masked
	"masque_banner": "THE MASQUE: the Summer Queen hides among her court! Only a hit shows which face is hers.",  # TUNING (not in GDD)
	"reveal_banner": "Found! The Summer Queen's mask breaks, and her court's with it.",  # TUNING (not in GDD)
	# The Bargain.
	"bargain_at": [0.66, 0.33],  # TUNING (not in GDD) HP shares at which she offers (once each; BARGAINS in order)
	"offer_time": 12.0,  # TUNING (not in GDD) s an online co-op offer waits for an answer (then it is refused)
	"scorn_damage": 0.25,  # Owner-approved proposal: "refuse and she attacks harder"; TUNING (not in GDD) + her specials' damage per refusal
	"scorn_haste": 0.2,  # TUNING (not in GDD) share off her specials' waits per refusal (at most 0.5 in all)
	"bargain_banner": "The Summer Queen offers you a bargain...",  # TUNING (not in GDD)
	"accept_banner": "The bargain is struck: your army burns bright, and heals no more.",  # TUNING (not in GDD)
	"refuse_banner": "You refuse her! The Summer Queen's smile turns to thorns: she strikes harder.",  # TUNING (not in GDD)
	# The Court in Bloom.
	"bloom_first": 8.0,  # TUNING (not in GDD) s after she arrives
	"bloom_every": 10.0,  # TUNING (not in GDD) s between two sowings at full HP (first pass 9)
	"bloom_min_every": 5.5,  # Owner-approved proposal: "she floods the arena ... until she falls"; TUNING (not in GDD) s at no HP (it grows faster as she falls)
	"bloom_count": 4,  # TUNING (not in GDD) blossoms a sowing (first pass 5: with her court and the Treants they broke the army bot's ring, seed 3)
	"bloom_spread": 230.0,  # TUNING (not in GDD) px round the necromancer
	"bloom_lead": 1.4,  # TUNING (not in GDD) s a blossom shows before it bursts
	"bloom_radius": 46.0,  # TUNING (not in GDD) px
	"bloom_damage": 6.0,  # TUNING (not in GDD) to the necromancer, before the time scaling (first pass 7)
	"bloom_damage_summon": 5.0,  # TUNING (not in GDD) to each summon, before the time scaling (first pass 6)
	"bloom_seed_every": 4,  # TUNING (not in GDD) every n-th blossom leaves a thicket seed (first pass 3)
	"bloom_grow": 2.0,  # TUNING (not in GDD) s those seeds take to grow
}
