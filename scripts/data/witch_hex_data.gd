## WitchHexData — the numbers of the Court witches' shared hexes (Act VII, the
## Witchwood; GDD §15.0 "The Witchwood (Act VII phase 2)"; owner-approved
## proposal docs/act7/PROPOSAL.md "Roster": "Crimson Witch ... Covens of three;
## together they cast a hex circle that heals the Court inside it and drains the
## army ... Break the coven: kill one and the circle fails"; "Bloated Thrall ...
## bursts into a pool that heals Court units walking through it"; "Hex stones:
## standing stones that power the covens' circles; destroy one and its zone's
## covens cannot cast"), run by WitchHexes (scripts/enemies/court/witch_hexes.gd,
## owned by Game.court once a witch, a bloated thrall, a hex stone or Isolde
## needs it). They work on ANY stage the Court's kinds walk (--spawn=), as every
## Court kind does; only the hex stones are the Witchwood's own (its director
## raises them), and covens cast under the Blood Moon on any Act VII stage.
##   COVEN — the covens of three Crimson Witches and their hex circles.
##   STONES — the hex stones' power and dead ground.
##   POOLS — the blood pools (a Bloated Thrall's burst, Isolde's cauldron bombs).
## Every Court heal here goes through CombatResolver.heal_enemy() (the existing
## enemy heal path; the brief: "Every new Court heal goes through this path or
## the existing enemy-heal path"), naming the witch as the healer so a Keening
## Lady's silence stops it. Data only (CLAUDE.md rule 2). Every number is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name WitchHexData
extends RefCounted

## Damage tag of a coven's hex circle draining a summon (summon_dmg_from_<tag>).
const CIRCLE_SOURCE: String = "hex_circle"
## Kind id of the Crimson Witch (CourtEnemyData, Act VII: the Witchwood's block).
const WITCH: String = "crimson_witch"
## Kind id of the Bloated Thrall (CourtEnemyData, the Witchwood's block).
const BLOATED: String = "bloated_thrall"
## Kind id of the hex stone structure (WitchwoodEnemyData).
const STONE: String = "hex_stone"

## The covens and their hex circles (WitchHexes).
##   size          — witches in a coven (owner-approved proposal: "covens of three").
##   form_range    — px: a free witch joins a coven with free witches this close
##                   to her (all within it of the first).
##   keep_range    — px: a coven witch farther than this from the coven's centre
##                   walks back toward it instead of fighting on.
##   cast_every    — s between two circles of one coven (counted from the end
##                   of its last cast).
##   first_cast    — s after a coven forms before its first circle may start.
##   cast_reach    — px: the coven casts only when the necromancer or a summon
##                   is this close to its centre.
##   windup        — s the circle glows on the ground before it bites (the
##                   telegraph; the witches already chant and hold).
##   cast_time     — s the circle bites after the windup (the witches hold,
##                   chanting, the whole time).
##   radius        — px of the circle (around the coven's centre).
##   tick          — s between two pulses of the circle.
##   heal_share    — share (0..1) of a Court enemy's max HP healed per second
##                   inside the circle (heal_enemy(), the witch as healer).
##   boss_heal_mult — x that heal on a boss or miniboss (they are big).
##   drain_dps     — damage per second to each summon inside (before the time
##                   scaling), CIRCLE_SOURCE.
##   drain_player_dps — damage per second to the necromancer inside: 0 (owner-
##                   approved proposal: "drains the army"; the necromancer is
##                   not the army). Kept as a key for a later tuning pass.
##   cast_banner_gap — least s between two coven banners.
const COVEN := {
	"size": 3,  # Owner-approved proposal: "Covens of three"
	"form_range": 150.0,  # TUNING (not in GDD) px
	"keep_range": 70.0,  # TUNING (not in GDD) px
	"cast_every": 9.0,  # TUNING (not in GDD) s
	"first_cast": 2.0,  # TUNING (not in GDD) s
	"cast_reach": 260.0,  # TUNING (not in GDD) px
	"windup": 1.0,  # TUNING (not in GDD) s
	"cast_time": 5.0,  # TUNING (not in GDD) s
	"radius": 95.0,  # TUNING (not in GDD) px (the Bone Ring is 60-150 px: a circle under one side of it)
	"tick": 0.5,  # TUNING (not in GDD) s
	"heal_share": 0.04,  # TUNING (not in GDD) per s: a Blood Knight inside heals ~20% over a cast; first pass 0.06 (the covens healed 24k in the forced-spell run)
	"boss_heal_mult": 0.0,  # TUNING (not in GDD) first pass 0.15: Isolde stood in her own circles and the bot left her at full HP
	"drain_dps": 3.0,  # TUNING (not in GDD) per s per summon, before the time scaling; first pass 5
	"drain_player_dps": 0.0,  # Owner-approved proposal: "drains the army" (summons only)
	"cast_banner_gap": 30.0,  # TUNING (not in GDD) s
}
## Banner shown when a coven first casts (at most every cast_banner_gap s).
const COVEN_BANNER: String = "A COVEN casts its hex circle: kill one witch and the circle fails!"  # TUNING (not in GDD)

## The hex stones (WitchHexes; the Witchwood's director raises them).
##   power_range  — px: a coven whose centre is this close to a standing hex
##                  stone is POWERED: it may cast even while the Blood Moon is
##                  down (owner-approved proposal: "standing stones that power
##                  the covens' circles").
##   dead_range   — px: a broken stone leaves dead ground this wide; a coven
##                  whose centre stands on it cannot cast at all, moon or not
##                  (owner-approved proposal: "destroy one and its zone's covens
##                  cannot cast"; own decision: "its zone" is the stone's own
##                  ground, since the stage's zones change on the clock and cover
##                  the whole map).
##   dead_life    — s the dead ground lasts (the rest of the zone; the
##                  director clears it at the next zone too).
const STONES := {
	"power_range": 340.0,  # TUNING (not in GDD) px
	"dead_range": 220.0,  # TUNING (not in GDD) px; first pass 340 (as wide as its power: 22 casts denied, only 4 circles in the seed-7 run)
	"dead_life": 300.0,  # TUNING (not in GDD) s (a zone)
}

## The blood pools (WitchHexes.open_pool(): the one pool path).
##   radius      — px of a Bloated Thrall's pool.
##   life        — s a pool lasts.
##   tick        — s between two heals of the pools.
##   heal_share  — share (0..1) of a Court enemy's max HP healed per second
##                 while it stands in a pool (owner-approved proposal: "a pool
##                 that heals Court units walking through it").
##   boss_heal_mult — x that heal on a boss or miniboss.
##   max_pools   — most pools at once (the oldest dries first).
##   fade        — s a drying pool takes to vanish (drawn only).
const POOLS := {
	"radius": 46.0,  # TUNING (not in GDD) px
	"life": 7.0,  # TUNING (not in GDD) s; first pass 9
	"tick": 0.5,  # TUNING (not in GDD) s
	"heal_share": 0.03,  # TUNING (not in GDD) per s; first pass 0.05 (pools healed 185k in the seed-7 run)
	"boss_heal_mult": 0.0,  # TUNING (not in GDD) first pass 0.15: "healing pools for her thralls", never for her or the Bog Mother
	"max_pools": 16,  # TUNING (not in GDD)
	"fade": 0.8,  # TUNING (not in GDD) s
}
