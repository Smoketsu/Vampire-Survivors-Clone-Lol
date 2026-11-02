## DonMarrowData — immutable design data for DON MARROW, THE KINGPIN, the boss
## of Skid Row (Act VIII, Stage 22; GDD §15.0 "Don Marrow, the Kingpin (Act
## VIII)"; owner-approved proposal docs/act8/PROPOSAL.md: "the Bounty (he puts a
## price on the necromancer's head: gang spawns double while his bounty board
## is up; break the board to end it), the Call (he phones the police on you),
## the Last Stand (behind the limo's armour with a gold-plated minigun that
## sweeps the arena)"; the owner's phase 2 answers of Nov 2, 2026, and the
## lead's call for the Call: "the police and SWAT tiers arrive at once for the
## rest of his fight"). BossDonMarrow (scripts/enemies/city/boss_don_marrow.gd,
## loaded by name for the boss id "don_marrow") reads it. A male crime boss in a
## white suit, black shirt, gold rings and a gold cane. Three phases by his HP:
##   * The Bounty (100% to phase2_hp): he raises his BOUNTY BOARD (the
##     bounty_board structure, a priority target) board_dist px from the
##     necromancer on his side; while it stands, Skid Row's gangs come twice
##     as thick (SkidRowDirector.bounty_active()); break it to end the Bounty
##     (it stays up through the later phases until broken). He walks in with
##     his cane and fires his gold REVOLVER: every revolver_every s a fan of
##     revolver_shots bullets (revolver_spread rad) at his target within
##     revolver_range px.
##   * The Call (phase2_hp to phase3_hp): he phones the police on you: from now
##     until he falls a SQUAD of the police and SWAT tiers comes in together on
##     the spawn ring every call_every s (call_squad: riot cops, breachers, a
##     medic; a squad car every call_car_every-th call), under the hard cap.
##     The escalation's tier badge does not change.
##   * The Last Stand (below phase3_hp): his ARMOURED LIMO rolls up and he
##     fights from behind it (an armour front of cover_front facing the ring,
##     the Armour rule's one path through his MarrowCoverKit), slower
##     (last_speed), with a gold-plated MINIGUN: every sweep_every s a street
##     lane through the necromancer (CityBlocks.lane(), the axis whose centre
##     line is nearer him; a straight line through him off the blocks) lights
##     gold for sweep_windup s, then a stream of fire runs along it at
##     sweep_speed px/s for sweep_length px: every summon and necromancer
##     within sweep_half px of the line takes sweep_damage once. Grave Step's
##     i-frames dodge it; so does stepping out of the lane.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks the
## Hearse Run spell and Black Car (UnlockData, boss "don_marrow"). The GDD
## gives no numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name DonMarrowData
extends RefCounted

## Don Marrow's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "don_marrow" through SkidRowStage.BOSS, so --boss=don_marrow
## and the Codex find him).
const ARRIVAL := {
	"id": "don_marrow",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Don Marrow, the Kingpin",  # Owner-approved proposal
	"short_name": "Don Marrow",
	"arrive_banner": "Don Marrow rolls up in his armoured limo!",  # TUNING (not in GDD)
	"defeat_banner": "The Kingpin falls! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Skid Row is yours. Survive Martial Law... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["bounty", "revolver", "call", "last_stand", "minigun"]

## Damage tag of his gold revolver (a ranged City source: Kevlar Bones).
const REVOLVER_SOURCE: String = "marrow_revolver"
## Damage tag of his gold minigun's sweep (a ranged City source: Kevlar Bones).
const MINIGUN_SOURCE: String = "marrow_minigun"
## Kind id of his bounty board (SkidRowEnemyData).
const BOARD: String = "bounty_board"
## Sprite key of his art (assets/sprites/bosses/don_marrow.png).
const SPRITE: String = "bosses/don_marrow"
## Sprite key of the limo he fights behind in the Last Stand (the miniboss's
## art, drawn in front of him).
const COVER_SPRITE: String = "city/armoured_limo"

## Don Marrow's base max HP (x the boss HP multiplier and the stage's HP
## multiplier 2.0: 30,000 on Skid Row; Vargr 14,000 x 1.85).
const MAX_HP: float = 15000.0  # TUNING (not in GDD) first pass 13000 (the seed-7 army run slew him 83 s after he arrived)

## Don Marrow's design row.
const BOSS := {
	"display_name": "Don Marrow, the Kingpin",
	"max_hp": MAX_HP,
	"move_speed": 48.0,  # TUNING (not in GDD) px/s; an unhurried walk
	"damage": 11.0,  # TUNING (not in GDD) his gold cane in reach
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 10.0,  # TUNING (not in GDD) px
	"radius": 18.0,  # TUNING (not in GDD) px; within CityBlockData.MAX_BODY_RADIUS (36), drawn larger
	"armor": 0.15,  # TUNING (not in GDD) a vest under the suit
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 360.0,  # TUNING (not in GDD) px/s, his revolver
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 10.0,  # TUNING (not in GDD)
	"faction": CityEnemyData.FACTION,
	"kit": "marrow_cover",  # His cover (MarrowCoverKit, a CityKit): the Armour front of the Last Stand.
	"tier": "gangs",  # The Kingpin of the gangs (the report groups him there).
	"reward_xp": 600,  # TUNING (not in GDD) as Vargr
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.4,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.66,  # TUNING (not in GDD) the Call below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the Last Stand below this
	"bounty_banner": "THE BOUNTY: a price on your head! The gangs come twice as thick until you break his board!",  # TUNING (not in GDD)
	"board_down_banner": "The bounty board is broken: the gangs lose interest!",  # TUNING (not in GDD)
	"phase2_banner": "THE CALL: Don Marrow phones the police on you! Riot squads and SWAT, together, until he falls!",  # TUNING (not in GDD)
	"phase3_banner": "THE LAST STAND: behind his limo with a gold minigun! Step out of the gold lanes!",  # TUNING (not in GDD)
	# The Bounty: the board.
	"board_dist": 230.0,  # TUNING (not in GDD) px from the necromancer, on his side
	"board_delay": 1.0,  # TUNING (not in GDD) s after his arrival it goes up
	# The revolver (every phase until the Last Stand).
	"revolver_every": 2.4,  # TUNING (not in GDD) s
	"revolver_range": 280.0,  # TUNING (not in GDD) px
	"revolver_shots": 3,  # TUNING (not in GDD) bullets a fan
	"revolver_spread": 0.18,  # TUNING (not in GDD) rad between two bullets
	"revolver_damage": 4.0,  # TUNING (not in GDD) per bullet, before the time scaling
	# The Call: police and SWAT squads together.
	"call_first": 2.0,  # TUNING (not in GDD) s after the phase begins
	"call_every": 10.0,  # TUNING (not in GDD) s between two squads
	"call_squad": [{"kind": "riot_cop", "count": 3}, {"kind": "swat_breacher", "count": 1}, {"kind": "field_medic", "count": 1}],  # Lead's call (GDD §15.0): police and SWAT together; counts TUNING (not in GDD)
	"call_car_every": 2,  # TUNING (not in GDD) a squad car with every n-th squad
	"call_spread": 22.0,  # TUNING (not in GDD) px between two squad members on the ring
	# The Last Stand: the limo's cover and the gold minigun.
	"cover_front": 0.6,  # TUNING (not in GDD) share cut from a hit on the limo's side of him (+-60 degrees toward the ring)
	"last_speed": 26.0,  # TUNING (not in GDD) px/s; he pushes the limo forward
	"first_sweep": 2.5,  # TUNING (not in GDD) s after the phase begins
	"sweep_every": 6.0,  # TUNING (not in GDD) s between two sweeps
	"sweep_windup": 1.3,  # TUNING (not in GDD) s the gold lane shows before the fire runs
	"sweep_speed": 760.0,  # TUNING (not in GDD) px/s the stream of fire runs along the lane
	"sweep_length": 1100.0,  # TUNING (not in GDD) px of lane swept (centred on the necromancer)
	"sweep_half": 34.0,  # TUNING (not in GDD) px each side of the lane's line that are hit
	"sweep_damage": 12.0,  # TUNING (not in GDD) before the time scaling, once a body a sweep
	"sweep_damage_summon": 16.0,  # TUNING (not in GDD) to a summon, before the time scaling
}
