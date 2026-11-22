## GalleonData — the numbers of the Treasure Galleon's own systems (Act X, the
## Black Tide; GDD §15.0 "The Treasure Galleon (Act X phase 2)"; owner-approved
## proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 1 "Stage 2: the Treasure
## Galleon"), read by GalleonDirector (the broadsides, the deck cannons, Old
## Hollow-Eye's event, the floor dressing) and GalleonReport. No logic here.
## The zones' rhythm (broadside_every) and the timeline are GalleonStage's.
class_name GalleonData
extends RefCounted

## Damage source tag of a broadside's cannonball (both armies: CombatResolver
## stats summon_dmg_from_broadside / player_dmg_from_broadside, and the enemy
## damage counted by the director).
const BROADSIDE_SOURCE: String = "broadside"
## Damage source tag of a deck cannon's shot (a world rule, not a class: no
## synergy or summon bonus reads it).
const CANNON_SOURCE: String = "deck_cannon"
## Obstacle kind of the deck cannons (GalleonStage.ARENA): the director finds
## them in the fixed layout.
const CANNON_KIND: String = "deck_cannon"
## Sprite drawn as the enemy galleon alongside during a broadside (the raider
## ship's plan view, drawn at BROADSIDE "ship_scale").
const SHIP_SPRITE: String = "corsair/raider_ship"

## BROADSIDES (owner-approved proposal: "Every 70 s an enemy galleon pulls
## alongside and fires a 6-line broadside across the deck: 1.5 s telegraph,
## hits both armies, knockback on enemies"). The rhythm is each zone's
## "broadside_every" (GalleonStage.ZONES); the first comes `first` s into
## the run. The galleon shows alongside a seeded rail for `ship_time` s; its
## `lines` lanes run straight across the deck from that rail, `spacing` px
## apart (+- `jitter`, seeded) around the nearest necromancer's x, each
## `width` px wide; after `telegraph` s every lane is hit at once: summons and
## necromancers dmg_summon / dmg_player x the enemies' damage scaling, deck
## enemies dmg_enemy x their HP scaling and knocked `knock` px/s toward the
## far rail (so the far rail drowns them, DeckBounds); bosses, minibosses and
## structures stand.
const BROADSIDE := {
	"first": 70.0,  # Owner-approved proposal: every 70 s (the first at 1:10)
	"lines": 6,  # Owner-approved proposal: a 6-line broadside
	"telegraph": 1.5,  # Owner-approved proposal: 1.5 s
	"width": 34.0,  # TUNING (not in GDD) px, a lane
	"spacing": 96.0,  # TUNING (not in GDD) px between two lanes (gaps to stand in)
	"jitter": 16.0,  # TUNING (not in GDD) +- px of seeded jitter per lane
	"dmg_summon": 12.0,  # TUNING (not in GDD) per lane, x the damage scaling
	"dmg_player": 10.0,  # TUNING (not in GDD) per lane, x the damage scaling
	"dmg_enemy": 26.0,  # TUNING (not in GDD) per lane, x the enemies' HP scaling
	"knock": 300.0,  # TUNING (not in GDD) px/s toward the far rail (overboard near it)
	"ship_time": 4.0,  # TUNING (not in GDD) s the enemy galleon is drawn alongside (from the telegraph)
	"ship_off": 70.0,  # TUNING (not in GDD) px its hull's centre lies off the rail
	"ship_scale": 2.2,  # TUNING (not in GDD) x the raider ship sprite (the galleon is bigger)
	"danger_margin": 20.0,  # TUNING (not in GDD) autotest hint only: px the bot keeps from a lane's edge
}

## THE DECK CANNONS (owner-approved proposal: "the deck's own cannons are
## usable: a cannon a summon or the necromancer stands next to for 3 s fires
## once at the nearest boat"). A world rule, never a class rule: any summon
## or necromancer within `reach` px of a cannon's footprint MANS it; while
## manned its charge fills (it drains at `drain` x the rate when nobody is
## there); full (`charge` s) it fires at the nearest boat, gunboat or surfaced
## swimmer within `range` px (ties by a seeded pick), dealing `damage` x the
## enemies' HP scaling to it and `splash_dmg` x the HP scaling to the deck
## enemies within `splash` px of the impact (knocked outward `splash_knock`
## px/s); then it cools `cooldown` s. A cannon with nothing in range keeps its
## charge and fires as soon as a boat comes.
const CANNONS := {
	"reach": 34.0,  # TUNING (not in GDD) px past the cannon's footprint a body mans it
	"charge": 3.0,  # Owner-approved proposal: 3 s
	"drain": 1.0,  # TUNING (not in GDD) x the fill rate the charge drains while unmanned
	"cooldown": 4.0,  # TUNING (not in GDD) s after a shot before it charges again
	"range": 900.0,  # TUNING (not in GDD) px a cannon reaches
	"damage": 140.0,  # TUNING (not in GDD) to the boat, x the enemies' HP scaling (a skiff in ~1-2 shots)
	"splash": 44.0,  # TUNING (not in GDD) px round the impact
	"splash_dmg": 18.0,  # TUNING (not in GDD) x the enemies' HP scaling
	"splash_knock": 220.0,  # TUNING (not in GDD) px/s outward
	"shot_time": 0.35,  # TUNING (not in GDD) s the drawn ball takes to fly (visual only; the hit lands at once)
}

## Old Hollow-Eye's event (the "hollow_eye" timeline event): its HP x the
## enemies' HP scaling at the time; `arms` kraken arms come up with it.
const HOLLOW_EYE := {
	"banner_dead": "Old Hollow-Eye sinks into the deep! Its arms still reach for your dead...",  # TUNING (not in GDD)
}

## Floor dressing of GalleonGround (no collision; the cells hold the
## colliding furniture): [sprite key, position (px)] of the hatches and the
## lashed barrels along the rails.
const DRESSING := [
	["obstacles/deck_hatch_l", Vector2(-250.0, 0.0)],  # TUNING (not in GDD) the main hatch
	["obstacles/deck_hatch_l", Vector2(250.0, 0.0)],  # TUNING (not in GDD) the fore hatch
	["obstacles/deck_hatch_l_v", Vector2(520.0, 10.0)],  # TUNING (not in GDD) the forecastle hatch
	["obstacles/deck_barrels_s", Vector2(-520.0, -236.0)],  # TUNING (not in GDD) barrels against the rails
	["obstacles/deck_barrels_s", Vector2(0.0, 236.0)],  # TUNING (not in GDD)
	["obstacles/deck_barrels_l", Vector2(-700.0, 0.0)],  # TUNING (not in GDD) the stern's lashed powder
	["obstacles/deck_barrels_s", Vector2(260.0, -236.0)],  # TUNING (not in GDD)
]
## x (px from the deck's centre) of the quarterdeck's edge (a raised deck
## behind it, drawn lighter) and of the forecastle's.
const QUARTERDECK_X: float = -470.0  # TUNING (not in GDD)
## x (px from the deck's centre) of the forecastle's edge (a raised deck before it).
const FORECASTLE_X: float = 500.0  # TUNING (not in GDD)

## WALKED THE PLANK (the stage's achievement; brief: "push 200 enemies
## overboard in one run: the overboard_total stat"): enemies drowned overboard
## in one run (any Act X deck) that earn it.
const WALKED_GOAL: int = 200  # Brief: 200
