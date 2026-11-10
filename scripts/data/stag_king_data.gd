## StagKingData — immutable design data for THE STAG KING, LORD OF THE GREENWOOD,
## the boss of the Greenwood (temporary Act XV, the Turning Year, final slot XV;
## GDD §15.0 "The Stag King (Act XV phase 2)"; owner-approved proposal
## docs/proposals/LAST_SIX_ACTS.md section XV, "Stage 43: The Greenwood": "Boss,
## the Stag King (male, stag-headed, the antlered lord of the forest): the Hunt
## (he leads the Wild Hunt across the arena in sweeping lines), the Rut (charges
## that crack trees into new thickets), the Antler Crown (his antlers grow a
## thicket ring around him that must be burned through before he can be
## hurt)"). BossStagKing (scripts/enemies/wild/boss_stag_king.gd, loaded by name
## for the boss id "stag_king") reads it. Art `wild/stag_king` (72x88, walk strip,
## pose 1 the horn raised; docs/year/ART_MANIFEST.md). His fight (he comes with
## 3:00 left, in the dead of winter):
##   * THE RUT (all fight): every charge_every s, once the necromancer is within
##     charge_trigger px, he lowers his antlers for charge_windup s (a line
##     shows) and CHARGES charge_speed px/s up to charge_len px; every grounded
##     summon and necromancer he crosses is hit once (WildKit.trample(), the one
##     Wild trample): summons take charge_damage_summon (x the time scaling), are
##     stunned charge_stun s and thrown charge_knock px aside; the necromancer
##     takes charge_damage. A charge into an obstacle (a tree) CRACKS it:
##     crack_seeds seeds sprout crack_ring px round the impact and grow in
##     crack_grow s (Thickets.plant(), the one planting path) and he staggers
##     crack_stagger s; a charge that ends in the open plants end_seeds there.
##   * THE HUNT (from hunt_first s, every hunt_every s): he blows his horn and
##     hunt_riders spectral riders appear hunt_back px from the necromancer,
##     abreast hunt_spacing px apart; their path shows hunt_lead s, then they
##     sweep hunt_len px through him at hunt_speed px/s; every body within
##     hunt_radius px of a rider is hit once a sweep (the one Wild trample):
##     summons hunt_damage_summon, the necromancer hunt_damage. Below hunt_split
##     of his HP a second line crosses the first at a right angle.
##   * THE ANTLER CROWN (at each share of crown_at): his antlers grow
##     crown_thorns thorns (GreenwoodEnemyData "antler_thicket") in a ring
##     crown_radius px round him that walk with him; while one stands he takes
##     NO damage (damage_taken_mult()). The army breaks them, or any fire source
##     burns those within its reach (Thickets.burn_at() -> crown_burn()); while
##     crowned he walks at crown_speed x his stride.
## Beaten: a short ending text (no epilogue part until the reorder pass).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks Wild
## Hunt, Horn of the Hunt and so the Horned Herald (UnlockData, boss
## "stag_king"). The GDD gives no numbers: everything is TUNING (not in GDD)
## unless marked as the owner-approved proposal. Tuned for the final slot XV.
class_name StagKingData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["rut", "hunt", "crown"]

## Sprite key of his art (assets/sprites/wild/stag_king.png, 72x88, walk strip;
## pose 1 `stag_king_horn`, the horn raised for the Hunt).
const SPRITE: String = "wild/stag_king"
## Sprite key of a spectral rider of his Hunt (the Rider of the Wild Hunt's art, drawn pale).
const RIDER_SPRITE: String = "wild/wild_rider"
## Damage tag of the Rut (stats, the death line, `wild damage`).
const RUT_SOURCE: String = "stag_king_rut"
## Damage tag of the Hunt's riders (stats, the death line, `wild damage`).
const HUNT_SOURCE: String = "stag_king_hunt"
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when he falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE HUNT IS OVER", "The Stag King falls in the snow.", "His horn rolls from his hand, and the Wild Hunt scatters into the white wood."]  # TUNING (not in GDD) the words
## The ending text when he falls during Spring Returns.
const LATE_ANNOUNCE := ["THE HUNT IS OVER", "The Stag King falls as spring returns.", "The forest grows over him at once, and still it comes for your dead."]  # TUNING (not in GDD) the words
## The spectral riders' pale frost glow (visual only; the Wild Hunt's ramp).
const RIDER_TINT := Color(0.75, 0.88, 1.0, 0.7)  # TUNING (not in GDD) visual only

## The Stag King's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 8500.0  # TUNING (not in GDD) under Old Ironbrow's 10,000: the crown is his extra life (x the stage's HP multiplier; first passes 10,000 and 9,000: not slain by the army bot on seed 11 nor by an evolved Wild Hunt build on seed 7)

## The Stag King's design row.
const BOSS := {
	"display_name": "The Stag King, Lord of the Greenwood",
	"max_hp": MAX_HP,
	"move_speed": 50.0,  # TUNING (not in GDD) px/s
	"damage": 12.0,  # TUNING (not in GDD) antlers in reach, before the time scaling
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 24.0,  # TUNING (not in GDD) px (the sprite 72x88)
	"armor": 0.25,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 16.0,  # TUNING (not in GDD)
	"faction": WildEnemyData.FACTION,
	"group": "hunt",  # The lord of the Wild Hunt (the reports).
	"no_bloom": true,  # A boss never heals on living ground (BloomField skips bosses anyway).
	"reward_xp": 600,  # TUNING (not in GDD) as Old Ironbrow
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 1.2,  # TUNING (not in GDD) s he stands after a charge (the army's window)
	"advance_range": 460.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	"arrive_banner": "THE HUNT: the Stag King leads the Wild Hunt through the snow! Step out of the riders' lines!",  # TUNING (not in GDD)
	# The Rut.
	"charge_first": 5.0,  # TUNING (not in GDD) s after he arrives
	"charge_every": 8.5,  # TUNING (not in GDD) s between two charges
	"charge_trigger": 480.0,  # TUNING (not in GDD) px to the necromancer for a charge to start
	"charge_windup": 1.0,  # TUNING (not in GDD) s he lowers his antlers (the line shows)
	"charge_speed": 360.0,  # TUNING (not in GDD) px/s
	"charge_len": 380.0,  # TUNING (not in GDD) px at most (through the ring)
	"charge_damage": 11.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"charge_damage_summon": 8.0,  # TUNING (not in GDD) to each summon he crosses, before the time scaling
	"charge_stun": 0.7,  # TUNING (not in GDD) s each summon he crosses is stunned
	"charge_knock": 36.0,  # TUNING (not in GDD) px a summon he crosses is thrown aside
	"crack_seeds": 3,  # Owner-approved proposal: "charges that crack trees into new thickets"; TUNING (not in GDD) seeds round a cracked tree
	"crack_ring": 64.0,  # TUNING (not in GDD) px from the impact
	"crack_grow": 1.5,  # TUNING (not in GDD) s those seeds take to grow
	"crack_stagger": 1.0,  # TUNING (not in GDD) s he staggers after cracking a tree
	"end_seeds": 1,  # TUNING (not in GDD) seeds where a charge ends in the open
	# The Hunt.
	"hunt_first": 12.0,  # TUNING (not in GDD) s after he arrives
	"hunt_every": 15.0,  # TUNING (not in GDD) s between two Hunts
	"hunt_riders": 4,  # Owner-approved proposal: "he leads the Wild Hunt across the arena in sweeping lines"; TUNING (not in GDD) riders abreast
	"hunt_spacing": 52.0,  # TUNING (not in GDD) px between two riders
	"hunt_back": 380.0,  # TUNING (not in GDD) px from the necromancer the line starts
	"hunt_lead": 1.6,  # TUNING (not in GDD) s the path shows before they ride
	"hunt_speed": 440.0,  # TUNING (not in GDD) px/s
	"hunt_len": 760.0,  # TUNING (not in GDD) px (through him and beyond)
	"hunt_radius": 16.0,  # TUNING (not in GDD) px round a rider
	"hunt_damage": 9.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"hunt_damage_summon": 5.0,  # TUNING (not in GDD) to each summon, before the time scaling (first pass 7: 10-16k on the army bot's summons)
	"hunt_stun": 0.3,  # TUNING (not in GDD) s
	"hunt_knock": 20.0,  # TUNING (not in GDD) px
	"hunt_split": 0.5,  # TUNING (not in GDD) HP share below which two lines cross
	"hunt_banner": "The Stag King sounds his horn: the Wild Hunt rides!",  # TUNING (not in GDD)
	# The Antler Crown.
	"crown_at": [0.7, 0.35],  # TUNING (not in GDD) HP shares at which the crown grows (once each)
	"crown_thorns": 8,  # TUNING (not in GDD) thorns in the ring
	"crown_radius": 50.0,  # TUNING (not in GDD) px from his centre
	"crown_speed": 0.6,  # TUNING (not in GDD) x his stride while crowned
	"crown_banner": "THE ANTLER CROWN: thorns ring the Stag King! Break them, or burn them, before he can be hurt!",  # TUNING (not in GDD)
	"crown_broken_banner": "The Antler Crown breaks: strike the Stag King now!",  # TUNING (not in GDD)
}
