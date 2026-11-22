## MarrecData — ADMIRAL ISABEAU MARREC, THE SEA WOLF, the boss of the Treasure
## Galleon (Act X, the Black Tide; GDD §15.0 "Admiral Isabeau Marrec, the Sea
## Wolf (Act X)"; owner-approved proposal: "the Fleet (her flagship's
## broadsides on a 30 s rhythm, a raider ship boards with a plank), the
## Boarding (she leads her marines across the plank; cut both hooks and the
## plank falls with her crew in the water), Gold Fever (cursed coins that
## become short barriers round her marines; area damage clears them; then a
## duel on the quarterdeck)"). Read by BossMarrec. No logic here. Every number
## is TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name MarrecData
extends RefCounted

## Her special abilities in report order (Boss.special_ids(): the autotest's
## "boss attacks" line reads boss_atk_<id>).
const SPECIALS := ["fleet", "broadside", "pistol", "plank", "plank_fall", "lunge", "gold_fever", "coins"]
## Damage source of her pistol shots (an ordinary hostile bullet).
const PISTOL_SOURCE: String = "marrec_pistol"
## Damage source of her rapier lunge.
const LUNGE_SOURCE: String = "marrec_lunge"
## Damage source of the plank's fall on her (her own HP: CombatResolver's one kill path).
const FALL_SOURCE: String = "plank_fall"
## Her sprite (assets/sprites/corsair/marrec.png, walk and idle strips; figure style).
const SPRITE: String = "corsair/marrec"
## Run stat: set to 1 when she falls (GalleonReport).
const SLAIN_STAT: String = "marrec_slain"

## Her boss row (Enemy row keys plus her numbers).
const BOSS := {
	"display_name": "Admiral Isabeau Marrec, the Sea Wolf",  # Owner-approved proposal
	"max_hp": 22000.0,  # TUNING (not in GDD) first pass 14,000 (the seed-7 army run slew her 46 s after she arrived)
	"move_speed": 58.0,  # TUNING (not in GDD) px/s on the deck
	"damage": 10.0,  # TUNING (not in GDD) her cutlass in reach
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 10.0,  # TUNING (not in GDD) px
	"radius": 18.0,  # TUNING (not in GDD) px (the sprite is drawn larger)
	"armor": 0.15,  # TUNING (not in GDD) an admiral's coat
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 340.0,  # TUNING (not in GDD) px/s, her pistol
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 10.0,  # TUNING (not in GDD)
	"faction": CorsairEnemyData.FACTION,
	"kit": "marrec",  # MarrecKit (a CorsairKit): in the water on her flagship, on the deck once aboard.
	"reward_xp": 600,  # TUNING (not in GDD) as Don Marrow
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.4,  # TUNING (not in GDD) s she stands after a special
	"advance_range": 380.0,  # TUNING (not in GDD) px; farther than this she strides faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# --- The Fleet ---
	"fleet_time": 30.0,  # TUNING (not in GDD) s on her flagship before the Boarding ...
	"fleet_hp": 0.8,  # TUNING (not in GDD) ... or once her HP falls below this share
	"ship_off": 74.0,  # TUNING (not in GDD) px her flagship's deck lies off the rail (in reach of ranged summons and spells)
	"broadside_every": 30.0,  # Owner-approved proposal: her flagship's broadsides on a 30 s rhythm
	"broadside_first": 3.0,  # TUNING (not in GDD) s after she arrives
	"fleet_crew": [{"kind": "deckhand", "count": 12}, {"kind": "musketeer", "count": 4}, {"kind": "swashbuckler", "count": 2}],  # Owner-approved proposal: a raider ship boards (24 crew hold it); counts TUNING (not in GDD)
	"pistol_every": 3.2,  # TUNING (not in GDD) s between two pistol shots (every phase)
	"pistol_range": 320.0,  # TUNING (not in GDD) px
	"pistol_damage": 7.0,  # TUNING (not in GDD) before the time scaling
	# --- The Boarding ---
	"plank_time": 5.0,  # TUNING (not in GDD) s she takes to cross her plank (cut both hooks first!)
	"hook_spread": 34.0,  # TUNING (not in GDD) px each plank hook sits from the plank along the rail
	"fall_share": 0.08,  # TUNING (not in GDD) share of her max HP the fall into the sea costs her
	"fall_time": 3.0,  # TUNING (not in GDD) s she flounders in the water before she climbs back on her flagship
	"replank_time": 6.0,  # TUNING (not in GDD) s before she lays a new plank
	"max_falls": 2,  # TUNING (not in GDD) after this many falls she swings across on a rope (no hooks)
	"marines": [{"kind": "deckhand", "count": 4}, {"kind": "swashbuckler", "count": 2}],  # TUNING (not in GDD) her marines on the plank (they drown with it)
	"plank_banner": "THE BOARDING: Admiral Marrec crosses her plank with her marines! Cut both hooks!",  # TUNING (not in GDD)
	"fall_banner": "The hooks are cut: the plank falls, and the Admiral with it!",  # TUNING (not in GDD)
	"aboard_banner": "Admiral Marrec is aboard! Cutlass and pistol!",  # TUNING (not in GDD)
	# --- The duel (on the deck) ---
	"lunge_every": 5.5,  # TUNING (not in GDD) s between two rapier lunges
	"lunge_range": 180.0,  # TUNING (not in GDD) px she lunges from
	"lunge_windup": 0.6,  # TUNING (not in GDD) s the lane shows
	"lunge_speed": 520.0,  # TUNING (not in GDD) px/s
	"lunge_width": 30.0,  # TUNING (not in GDD) px, the lane
	"lunge_damage": 14.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"lunge_damage_summon": 18.0,  # TUNING (not in GDD) to a summon, before the time scaling
	# --- Gold Fever ---
	"fever_hp": 0.4,  # TUNING (not in GDD) Gold Fever below this share of her HP
	"coins": 6,  # TUNING (not in GDD) cursed coins a scatter
	"coin_every": 10.0,  # TUNING (not in GDD) s between two scatters
	"coin_spread": 150.0,  # TUNING (not in GDD) px round her a coin lands
	"coin_cut": 0.12,  # TUNING (not in GDD) share of her damage taken each standing coin within its aura cuts ...
	"coin_cut_max": 0.5,  # TUNING (not in GDD) ... at most
	"fever_marines": [{"kind": "deckhand", "count": 4}, {"kind": "swashbuckler", "count": 1}],  # TUNING (not in GDD) her last marines, with the first scatter
	"fever_lunge_every": 4.0,  # TUNING (not in GDD) s: the duel quickens
	"quarterdeck_in": 170.0,  # TUNING (not in GDD) px inside the stern she makes her stand
	"retreat_time": 3.5,  # TUNING (not in GDD) s at most she runs to the quarterdeck
	"retreat_speed_mult": 2.0,  # TUNING (not in GDD)
	"fever_banner": "GOLD FEVER: cursed coins shield her marines! Clear them with area blows, then duel her on the quarterdeck!",  # TUNING (not in GDD)
}
