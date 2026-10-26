## ShogunData — immutable design data for SHOGUN KUROGANE, the boss of Castle
## Kurogane (Act V, Stage 14; GDD §15.0 "Castle Kurogane (Act V phase 2)" and
## "Shogun Kurogane: his army is his health bar"; owner-approved proposal
## docs/act5/PROPOSAL.md "Stage 14": "his army is his health bar ... He never
## enters the fight at first: he stands on a command platform, signalling with
## a war fan. His bar is the number of soldiers he has left (for example 600 in
## six regiments, each with its own banner colour), and every Shogunate kill
## takes a point off it. Each regiment arrives with a different order ...
## Killing a regiment's Hatamoto breaks it: the rest flee and count as lost.
## Under 10% he draws his own blade and comes down with his honour guard for a
## short final duel, fought with iai slashes (owner: 'give him Iai style
## slashes'): every draw-cut is a white line flashed across the arena, they come
## faster as his guard falls, and his last move is a triple cut of three lines
## at once"). BossShogun (scripts/enemies/shogunate/boss_shogun.gd, loaded by
## name for the boss id "shogun") reads it; his regiments run in
## ShogunRegiments. Two parts of one fight:
##   * THE COMMAND PLATFORM (the bar = his soldiers): he stands on his platform
##     (platform_distance px from the necromancer when he arrives), UNTARGETABLE
##     (Enemy.untargetable: out of the enemy grid, so nothing aims at him, and
##     damage_taken_mult() 0), signalling with his war fan. His six REGIMENTS
##     (REGIMENTS) march in one after another; his HUD bar (the one boss bar:
##     Enemy.hp / max_hp) is the soldiers he has left, the sum of their sizes.
##     Every Shogunate kill takes a point off it; killing a regiment's Hatamoto
##     BREAKS it: its soldiers on the field flee (taken off the field) and its
##     reserve is lost.
##   * THE DUEL (at descend_share of the bar): he draws his blade and comes
##     down with his honour guard (guard_count samurai elites); the regiments
##     stop marching. The rest of the bar is now his own life (his max_hp after
##     the boss HP scaling, mapped onto the points left, at least
##     duel_min_share of the bar). He walks at the necromancer and fights with
##     IAI CUTS through DrawCuts.draw() with the boss override: a white line
##     from him through the necromancer, cut_length px past him, flashing
##     cut_flash_slow s while his guard stands and down to cut_flash_fast s as
##     it falls; after the cut he dashes along it. Below triple_hp of his own
##     life his last move is the TRIPLE CUT: three lines at once crossing on the
##     necromancer (a six-pointed star, triple_length px each), every
##     triple_every s.
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, advance_range,
## advance_speed_mult) and the numbers below. The GDD gives no numbers:
## everything is TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name ShogunData
extends RefCounted

## Shogun Kurogane's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "shogun" through KuroganeStage.BOSS, so --boss=shogun and the
## Codex find him).
const ARRIVAL := {
	"id": "shogun",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Shogun Kurogane",  # Owner-approved name
	"short_name": "The Shogun",
	"arrive_banner": "Shogun Kurogane raises his war fan: his regiments march! Break their banners!",  # TUNING (not in GDD)
	"defeat_banner": "Shogun Kurogane falls! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "The Shogun is dead. Survive until the night ends... it will not.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["regiment", "fan", "iai", "triple"]

## The Shogun's design row.
const BOSS := {
	"display_name": "Shogun Kurogane",
	"max_hp": 5500.0,  # TUNING (not in GDD) his own life in the duel, x the stage HP multiplier (8,800 on Kurogane); the regiments are the rest of the fight (first pass 6500 came down too late to finish; 4500 fell in 16 s)
	"move_speed": 56.0,  # TUNING (not in GDD) px/s in the duel
	"damage": 9.0,  # TUNING (not in GDD) a blade cut in reach (first pass 16: his melee after a cut killed the army bot; his iai cuts are his damage)
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 18.0,  # TUNING (not in GDD) px
	"armor": 0.25,  # TUNING (not in GDD) black lacquer and gold
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 9.0,  # TUNING (not in GDD)
	"faction": ShogunateEnemyData.FACTION,
	"reward_xp": 600,  # TUNING (not in GDD) a step above Achilles' 560
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"advance_range": 380.0,  # TUNING (not in GDD) px; farther than this he strides faster in the duel
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	# The command platform.
	"platform_distance": 260.0,  # TUNING (not in GDD) px from the necromancer at arrival (on screen)
	"fan_every": 9.0,  # TUNING (not in GDD) s between two war-fan signals (a flourish and a taiko beat; drawing and sound)
	# The bar.
	"descend_share": 0.1,  # Owner-approved proposal: "Under 10% he draws his own blade"
	"duel_min_share": 0.05,  # TUNING (not in GDD) the least share of the bar his own life fills in the duel
	# The duel.
	"descend_time": 1.4,  # TUNING (not in GDD) s he leaps down from the platform (invulnerable)
	"guard_kind": ShogunateEnemyData.SAMURAI,  # Own decision: his honour guard are samurai (their elites Draw too)
	"guard_count": 6,  # TUNING (not in GDD)
	"guard_elites": 6,  # TUNING (not in GDD) every one of them an elite (they draw)
	"guard_ring": 46.0,  # TUNING (not in GDD) px around him the guard lands
	"cut_every": 3.0,  # TUNING (not in GDD) s between two iai cuts (start to start)
	"cut_range": 460.0,  # TUNING (not in GDD) px: he cuts at a necromancer this close
	"cut_length": 160.0,  # TUNING (not in GDD) px the line runs past the necromancer ("across the arena")
	"cut_width": 20.0,  # TUNING (not in GDD) px
	"cut_flash_slow": 0.8,  # Owner-approved proposal (the Draw's 0.8 s) while his whole guard stands
	"cut_flash_fast": 0.45,  # TUNING (not in GDD) s once his guard has fallen ("faster as his guard falls")
	"cut_dmg_player": 18.0,  # TUNING (not in GDD) before the time scaling (the Draw 13)
	"cut_dmg_summon": 22.0,  # TUNING (not in GDD) before the time scaling (the Draw 24; first pass 30: his cuts took ~36 summons in a 60 s duel)
	"cut_dash": 1.0,  # TUNING (not in GDD) share of the line he dashes along: the whole line, he ends cut_length px past the necromancer (first pass 0.7 left him in reach)
	"triple_hp": 0.35,  # TUNING (not in GDD) share of his own life below which the triple cut comes ("his last move")
	"triple_every": 4.2,  # TUNING (not in GDD) s
	"triple_length": 380.0,  # TUNING (not in GDD) px of each of the three lines (centred on the necromancer)
	"triple_flash": 0.75,  # TUNING (not in GDD) s; a little slower than a single cut: three lines to read
	"triple_dmg_summon": 16.0,  # TUNING (not in GDD) before the time scaling: each of the three lines on a summon (they cross the ring)
}

## The six regiments, in marching order (owner-approved proposal: "600 in six
## regiments, each with its own banner colour ... a different order (an
## arquebus line, a spear wall, a cavalry charge, a ninja ambush, a samurai
## duel squad)"; own decision: the sixth is the night host, the yokai bound to
## his banner, as the fight comes at night). Keys:
##   name        — banner shown when it marches ("the White Regiment ...").
##   order       — how it fights: "spear_wall" (a wide line of levies),
##                 "arquebus" (a line of gunners firing on the shared beat),
##                 "cavalry" (charging riders), "ambush" (ninja squads out of
##                 the shadows through ShadowAmbush; off Act V they enter from
##                 the spawn ring), "duel" (samurai, `elites` of each batch
##                 elite: they Draw), "night_host" (oni and onryo).
##   color       — the banner colour (the Hatamoto's sprite tint; the HUD
##                 objective names it).
##   size        — soldiers in it (points of the bar), the Hatamoto included.
##   kinds       — {kind: weight} of its soldiers (seeded pick per soldier).
##   batch       — soldiers it sends at once.
##   every       — s between two batches.
##   field       — most of its soldiers on the field at once.
##   elites      — elites in each batch (the duel squad's drawing samurai).
const REGIMENTS := [
	{"name": "The White Regiment: a spear wall advances!", "order": "spear_wall", "color": Color(1.0, 1.0, 1.0),  # TUNING (not in GDD)
		"size": 130, "kinds": {"ashigaru": 1.0}, "batch": 12, "every": 1.6, "field": 34, "elites": 0},
	{"name": "The Indigo Regiment: an arquebus line! Rush the reload!", "order": "arquebus", "color": Color(0.55, 0.65, 1.0),  # TUNING (not in GDD)
		"size": 100, "kinds": {"teppo_gunner": 0.7, "ashigaru": 0.3}, "batch": 8, "every": 1.7, "field": 24, "elites": 0},
	{"name": "The Crimson Regiment: the cavalry charges!", "order": "cavalry", "color": Color(1.0, 0.45, 0.42),  # TUNING (not in GDD)
		"size": 90, "kinds": {"kiba_musha": 1.0}, "batch": 5, "every": 1.8, "field": 16, "elites": 0},
	{"name": "The Black Regiment: ninja in the shadows!", "order": "ambush", "color": Color(0.5, 0.5, 0.58),  # TUNING (not in GDD)
		"size": 90, "kinds": {"ninja": 1.0}, "batch": 4, "every": 1.7, "field": 16, "elites": 0},
	{"name": "The Gold Regiment: a samurai duel squad draws!", "order": "duel", "color": Color(1.0, 0.85, 0.4),  # TUNING (not in GDD)
		"size": 90, "kinds": {"samurai": 1.0}, "batch": 5, "every": 1.8, "field": 16, "elites": 1},
	{"name": "The Sakura Regiment: the night host rises to his banner!", "order": "night_host", "color": Color(1.0, 0.68, 0.8),  # TUNING (not in GDD)
		"size": 100, "kinds": {"onryo": 0.82, "oni": 0.18}, "batch": 8, "every": 1.7, "field": 24, "elites": 0},
]
## Seconds after his arrival the first regiment marches.
const FIRST_MARCH: float = 3.0  # TUNING (not in GDD)
## Seconds between two regiments' march (a later one waits at most this long).
const MARCH_EVERY: float = 15.0  # TUNING (not in GDD) six regiments in about 80 s (first pass 22 with MAX_ACTIVE 2: he came down at 1:51 left, too late for the duel)
## Most regiments on the field at once (the next waits for one to break or be spent).
const MAX_ACTIVE: int = 3  # TUNING (not in GDD) first pass 2
## px from the necromancer a regiment's line forms (on the spawn ring when larger).
const MARCH_DISTANCE: float = 0.0  # TUNING (not in GDD) 0 = the spawn ring
## px between two soldiers of a regiment's line.
const LINE_SPACING: float = 22.0  # TUNING (not in GDD)
## Angle (rad) between the directions two successive regiments march from.
const MARCH_TURN: float = 2.2  # TUNING (not in GDD) about 126 degrees: each from another side
## px below the Shogun's feet the bottom edge of his command platform's sprite
## sits while he stands on its deck (shogunate/command_platform, 124 art px
## tall, its deck's centre about 56 px above its bottom edge). Visual only.
const PLATFORM_DECK_RISE: float = 56.0  # TUNING (not in GDD) art fit
