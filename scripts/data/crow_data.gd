## CrowData — immutable design data for CAPTAIN EZEKIEL CROW, THE GULL KING,
## the boss of the Smuggler's Cutter (Act X, the Black Tide; GDD §15.0 "Captain
## Crow (Act X)"; owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md
## Part 1: "Broadside: his sloop pulls alongside; three telegraphed cannon lines
## cross the deck every 20 s while his crew boards double. The Duel: he swings
## aboard and fights the necromancer with a cutlass and a pistol; he leaps the
## ring on a landing circle. Fire Ship: he sets his own ship ablaze and rams the
## cutter; burning planks spread as short fire patches (the Hell Pits ground
## path, not a new one) until he falls"). BossCrow
## (scripts/enemies/corsair/boss_crow.gd, loaded by name for the boss id
## "crow") reads it. A lean MALE pirate captain in a heavy cloak, a cutlass and
## a flintlock. Three phases:
##   * BROADSIDE (from his arrival): his sloop (CutterEnemyData "crow_sloop", a
##     boat structure in the water, HP x his HP multiplier) comes alongside the
##     rail farther from the necromancer, x near his; Crow commands from its
##     deck, out of reach (Enemy.untargetable, ethereal: the Hive Mother's
##     path). Every broadside_every s (the first after broadside_first) THREE
##     CANNON LINES cross the deck from his rail to the far one, line_gap px
##     apart round the nearest necromancer's x: each a band 2 x line_half px
##     wide that shows line_telegraph s (lantern amber), then fires: every
##     grounded summon in it takes line_damage_summon, a necromancer
##     line_damage_player (time-scaled), and every deck enemy in it (both
##     armies: never a boss, miniboss or structure) takes line_damage_enemy x
##     the HP scaling and is knocked line_push px toward the far rail (its
##     knockback: at the far rail it drowns). HIS CREW BOARDS DOUBLE: every
##     crew_every s he sends crew_count of crew_kinds (in turn) through THE
##     spawn route (CorsairRules.route_spawn(): by boat), under the hard cap.
##     The Broadside ends when the sloop sinks or after broadside_time s.
##   * THE DUEL: he swings aboard: a LEAP onto a landing circle (leap_radius
##     px) leap_short px short of the nearest necromancer, on his side
##     (telegraph leap_time s; on landing every
##     grounded summon in it takes leap_damage_summon and is knocked leap_push
##     px out, x Sea Legs, a necromancer leap_damage_player). The sloop casts
##     off. He fights with the shared melee AI (the cutlass in reach), fires
##     his PISTOL at the nearest necromancer every pistol_every s when he is
##     farther than pistol_min px (an ordinary hostile projectile), and LEAPS
##     THE RING onto a new landing circle at the necromancer every leap_every s
##     (in the air he flies: no body-block).
##   * THE FIRE SHIP (below fire_hp of his HP): he sets his sloop ablaze and it
##     rams the hull at his rail (CutterDirector.fire_ship(): the hull stagger,
##     then short fire patches through THE Hell Pits ground path until he
##     falls; off the Cutter there is no director and no fire). He keeps
##     duelling, leaping every fire_leap_every s.
## Beaten: a short ending text only (no epilogue part, owner). Killing him drops
## a big XP burst and the boss chest; slaying him unlocks Chain Shot and
## Bosun's Whistle (UnlockData, boss "crow").
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot II.
class_name CrowData
extends RefCounted

## Captain Crow's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "crow" through CutterStage.BOSS, so --boss=crow and the Codex
## find him).
const ARRIVAL := {
	"id": "crow",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Captain Ezekiel Crow, the Gull King",  # Owner-approved proposal
	"short_name": "Captain Crow",
	"arrive_banner": "Captain Crow's sloop pulls alongside! BROADSIDE: get out of the cannon lines!",  # TUNING (not in GDD)
	"defeat_banner": "Crow goes over the rail at last! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Captain Crow is beaten. Survive the Black Tide... you cannot.",  # TUNING (not in GDD)
}

## His abilities in report order (the autotest "boss attacks" line).
const SPECIALS := ["broadside", "crew", "swing_aboard", "leap", "pistol", "fire_ship"]

## Sprite key of his art (assets/sprites/corsair/crow.png, 98 x 88, walk strip).
const SPRITE: String = "corsair/crow"
## Damage tag of a broadside line.
const LINE_SOURCE: String = "crow_broadside"
## Damage tag of his landing.
const LEAP_SOURCE: String = "crow_leap"
## Damage tag of his pistol shot.
const PISTOL_SOURCE: String = "crow_pistol"
## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text when he falls (HUD announce: title, line, text).
## Owner: a short ending text only, no epilogue part until the reorder.
const ENDING_ANNOUNCE := ["THE GULL KING FALLS", "Captain Crow goes over the rail.", "His sloop burns to the waterline behind you. The fog closes over the Cove, and the Brotherhood's boats turn for deeper water."]  # TUNING (not in GDD) the words
## The ending text when he falls during the Black Tide.
const LATE_ANNOUNCE := ["THE GULL KING FALLS", "Captain Crow goes over the rail in the Black Tide.", "His crew fights on without him. The sea does not care who captains it."]  # TUNING (not in GDD) the words

## Captain Crow's base max HP (x the boss HP multiplier and the stage's 1.3).
const MAX_HP: float = 15000.0  # TUNING (not in GDD) slot II: below Merrow (26,000 x 1.15) and Kestrel (17,000 x 1.25); out of reach during the Broadside

## Captain Crow's design row.
const BOSS := {
	"display_name": "Captain Ezekiel Crow",
	"max_hp": MAX_HP,
	"move_speed": 66.0,  # TUNING (not in GDD) px/s; a lean duellist
	"damage": 7.0,  # TUNING (not in GDD) his cutlass in reach (first pass 11: 152 to the forced Chain Shot run's necromancer; balance pass 1: 9 -> 7, his Duel killed every spell build at 17:40)
	"attack_interval": 1.2,  # TUNING (not in GDD) s (balance pass 1: 0.9 -> 1.2, below Admiral Marrec's cutlass: the act's first boss)
	"attack_range": 12.0,  # TUNING (not in GDD) px
	"radius": 20.0,  # TUNING (not in GDD) px (the sprite 88 px tall)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 10.0,  # TUNING (not in GDD)
	"faction": CorsairEnemyData.FACTION,
	"reward_xp": 600,  # TUNING (not in GDD) as the Hive Mother
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"fire_hp": 0.4,  # TUNING (not in GDD) the Fire Ship below this share of his HP
	"broadside_banner": "THE DUEL: Captain Crow swings aboard with cutlass and pistol!",  # TUNING (not in GDD)
	"fire_banner": "THE FIRE SHIP: Crow sets his sloop ablaze and rams the cutter! The planks are burning!",  # TUNING (not in GDD)
	# The Broadside.
	"broadside_first": 4.0,  # TUNING (not in GDD) s after he arrives
	"broadside_every": 20.0,  # Owner-approved proposal: "three telegraphed cannon lines ... every 20 s"
	"broadside_time": 44.0,  # TUNING (not in GDD) s the Broadside lasts at most (two or three broadsides); sinking the sloop ends it sooner
	"lines": 3,  # Owner-approved proposal: three cannon lines
	"line_gap": 150.0,  # TUNING (not in GDD) px between two lines
	"line_half": 18.0,  # TUNING (not in GDD) px half width of a line
	"line_telegraph": 1.5,  # TUNING (not in GDD) s (the Galleon's broadsides' 1.5 s)
	"line_stagger": 0.25,  # TUNING (not in GDD) s between the three lines' shots (a rolling broadside)
	"line_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling (first pass 22: the lines cut the forced Chain Shot run's army from 45 to 7 in his first minute; undead do not dodge)
	"line_damage_player": 14.0,  # TUNING (not in GDD) before the time scaling
	"line_damage_enemy": 40.0,  # TUNING (not in GDD) x the HP scaling (his own crew too)
	"line_push": 140.0,  # TUNING (not in GDD) px a deck enemy is knocked toward the far rail
	"crew_every": 6.0,  # TUNING (not in GDD) s; owner-approved proposal: "his crew boards double"
	"crew_count": 4,  # TUNING (not in GDD) crewmen a call
	"crew_kinds": ["deckhand", "deckhand", "swashbuckler", "deckhand", "powder_runner", "grappler"],  # TUNING (not in GDD) taken in turn
	# The Duel.
	"leap_time": 1.0,  # TUNING (not in GDD) s in the air (the landing circle shows as long)
	"leap_height": 60.0,  # TUNING (not in GDD) px of the arc drawn (visual only)
	"leap_radius": 54.0,  # TUNING (not in GDD) px
	"leap_short": 70.0,  # TUNING (not in GDD) px short of the necromancer the circle lands (over the ring, into it: his blade does not land on top of him; first pass 0, the forced Chain Shot runs fell to his Duel at 18:00)
	"leap_damage_summon": 10.0,  # TUNING (not in GDD) before the time scaling (first pass 16: his landings killed 37 summons in the forced seed-7 run)
	"leap_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling (first pass 12)
	"leap_push": 60.0,  # TUNING (not in GDD) px summons are knocked out of the circle (x Sea Legs)
	"leap_every": 9.0,  # TUNING (not in GDD) s between two leaps in the Duel
	"leap_min": 90.0,  # TUNING (not in GDD) px: no leap when he already stands this close to the necromancer
	"pistol_every": 3.2,  # TUNING (not in GDD) s
	"pistol_min": 70.0,  # TUNING (not in GDD) px: closer than this he uses the cutlass
	"pistol_damage": 7.0,  # TUNING (not in GDD) before the time scaling (first pass 9)
	"pistol_speed": 300.0,  # TUNING (not in GDD) px/s
	"recover_time": 0.5,  # TUNING (not in GDD) s he stands after a landing
	# The Fire Ship.
	"fire_leap_every": 8.0,  # TUNING (not in GDD) s between two leaps once his ship burns (first pass 6.5)
}
