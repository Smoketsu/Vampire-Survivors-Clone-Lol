## EnemyData — immutable design data for the Crimson Covenant roster used in
## the prototype (GDD §10 roster, §35 interaction rules) and for the
## Graveyard boss Sir Alaric and his five abilities (GDD §11).
##
## The GDD only describes enemies qualitatively ("weak basic infantry",
## "moderate damage resistance", "bonus damage versus undead"...), so every
## number below is TUNING (not in GDD); the behaviour each number expresses
## is cited.
class_name EnemyData
extends RefCounted

## Display / iteration order of regular enemy kinds.
const ORDER := ["recruit", "footman", "archer", "chaplain", "purifier", "templar"]

## Regular enemy definitions. Field reference (same keys in every row):
##   display_name        — UI string.
##   max_hp              — HP before time scaling.
##   move_speed          — px/s.
##   damage              — damage per attack before time scaling.
##   attack_interval     — s between attacks.
##   attack_range        — px edge-to-edge (melee) / max firing range (ranged).
##   radius              — body radius px.
##   armor               — fraction of incoming damage ignored (0..0.9).
##   xp                  — XP crystal value dropped on death.
##   behavior            — AI branch: "melee" | "ranged" | "healer" | "purifier".
##   projectile_speed    — px/s for ranged attacks.
##   undead_damage_mult  — damage multiplier vs undead summons (not player).
##   heal_amount         — HP healed per cast on another enemy.
##   heal_interval       — s between heals.
##   heal_radius         — px search radius for heal targets.
##   target_priority     — 0..1 "role priority" summons use when scoring this
##                         enemy as a target (healers/casters high).
##   mass                — weight vs blocking warriors (UnitData block_mass):
##                         heavier enemies shove warriors more.
## Optional keys of the "templar" behaviour (Templar Knight charge):
##   charge_range_min / charge_range_max — px; charges only at a player this far.
##   charge_telegraph    — s the warning lane is shown before the rush.
##   charge_speed        — px/s during the rush.
##   charge_length       — px; maximum rush distance (cut short by obstacles).
##   charge_width        — px; lane width (hit radius = half of it).
##   charge_cooldown     — s between charges.
##   charge_damage       — damage to the player or a summon hit by the rush.
##   charge_knockback    — px a hit summon is shoved aside ("disruption").
##   charge_block_mass   — warrior block_mass it takes to stop the rush
##                         (undead body-block it, user brief).
const ENEMIES := {
	# GDD §10 "Weak basic infantry, mass waves."
	"recruit": {
		"display_name": "Covenant Recruit",
		"max_hp": 14.0,  # TUNING (not in GDD)
		"move_speed": 58.0,  # TUNING (not in GDD)
		"damage": 3.0,  # TUNING (not in GDD)
		"attack_interval": 1.0,  # TUNING (not in GDD)
		"attack_range": 4.0,  # TUNING (not in GDD)
		"radius": 9.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD)
		"mass": 1.0,  # TUNING (not in GDD) pushback vs blocking warriors
	},
	# GDD §10 "Armored melee, moderate damage resistance."
	"footman": {
		"display_name": "Crimson Footman",
		"max_hp": 36.0,  # TUNING (not in GDD)
		"move_speed": 50.0,  # TUNING (not in GDD)
		"damage": 5.0,  # TUNING (not in GDD)
		"attack_interval": 1.2,  # TUNING (not in GDD)
		"attack_range": 5.0,  # TUNING (not in GDD)
		"radius": 11.0,  # TUNING (not in GDD)
		"armor": 0.3,  # TUNING (not in GDD) — "moderate damage resistance"
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD)
		"mass": 1.6,  # TUNING (not in GDD) pushback vs blocking warriors
	},
	# GDD §10 "Ranged projectiles."
	"archer": {
		"display_name": "Zealous Archer",
		"max_hp": 18.0,  # TUNING (not in GDD)
		"move_speed": 55.0,  # TUNING (not in GDD)
		"damage": 4.0,  # TUNING (not in GDD)
		"attack_interval": 2.6,  # TUNING (not in GDD)
		"attack_range": 200.0,  # TUNING (not in GDD) max firing distance
		"radius": 9.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 230.0,  # TUNING (not in GDD)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # GDD §27 archers prefer enemy archers/casters
		"mass": 1.0,  # TUNING (not in GDD) pushback vs blocking warriors
	},
	# GDD §10 "Heals enemy allies"; §35 "increase ranged-unit target preference".
	"chaplain": {
		"display_name": "Covenant Chaplain",
		"max_hp": 32.0,  # TUNING (not in GDD)
		"move_speed": 48.0,  # TUNING (not in GDD)
		"damage": 2.0,  # TUNING (not in GDD) weak melee if cornered
		"attack_interval": 1.4,  # TUNING (not in GDD)
		"attack_range": 4.0,  # TUNING (not in GDD)
		"radius": 10.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "healer",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 3.0,  # TUNING (not in GDD)
		"heal_interval": 5.0,  # TUNING (not in GDD)
		"heal_radius": 120.0,  # TUNING (not in GDD)
		"target_priority": 1.0,  # GDD §27/§35 healers are top archer priority
		"mass": 1.0,  # TUNING (not in GDD) pushback vs blocking warriors
	},
	# GDD §10 "Bonus damage versus undead summons"; §35 "prioritize undead...
	# relatively vulnerable to ranged focus".
	"purifier": {
		"display_name": "Purifier",
		"max_hp": 26.0,  # TUNING (not in GDD) fragile on purpose (§35)
		"move_speed": 66.0,  # TUNING (not in GDD)
		"damage": 5.0,  # TUNING (not in GDD)
		"attack_interval": 1.0,  # TUNING (not in GDD)
		"attack_range": 5.0,  # TUNING (not in GDD)
		"radius": 10.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "purifier",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.5,  # TUNING (not in GDD) "bonus damage vs undead"
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD)
		"mass": 1.0,  # TUNING (not in GDD) pushback vs blocking warriors
	},
	# GDD §10 "Templar Knight: Heavy charging melee; knockback/disruption";
	# §35 "charges and disrupts melee army, threatening player through gaps".
	"templar": {
		"display_name": "Templar Knight",
		"max_hp": 80.0,  # TUNING (not in GDD)
		"move_speed": 46.0,  # TUNING (not in GDD)
		"damage": 8.0,  # TUNING (not in GDD)
		"attack_interval": 1.3,  # TUNING (not in GDD)
		"attack_range": 6.0,  # TUNING (not in GDD)
		"radius": 13.0,  # TUNING (not in GDD)
		"armor": 0.35,  # TUNING (not in GDD) heavy armour
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "templar",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD)
		"mass": 3.0,  # TUNING (not in GDD) heavy: shoves warriors
		"charge_range_min": 60.0,  # TUNING (not in GDD)
		"charge_range_max": 190.0,  # TUNING (not in GDD)
		"charge_telegraph": 0.75,  # TUNING (not in GDD)
		"charge_speed": 340.0,  # TUNING (not in GDD)
		"charge_length": 170.0,  # TUNING (not in GDD)
		"charge_width": 30.0,  # TUNING (not in GDD)
		"charge_cooldown": 6.0,  # TUNING (not in GDD)
		"charge_damage": 10.0,  # TUNING (not in GDD)
		"charge_knockback": 26.0,  # TUNING (not in GDD)
		"charge_block_mass": 3.0,  # TUNING (not in GDD) one warrior stops it
	},
}

## "Reckoning" enemy that spawns once the countdown reaches 0:00 (user brief:
## absurdly strong holy executioners that normally end the run). Spawned only
## by EnemyDirector's Reckoning logic (WaveData.RECKONING), never by the
## regular trickle. Same keys as ENEMIES rows.
const RECKONING_ENEMY := {
	"display_name": "Inquisitor of the End",
	"max_hp": 900.0,  # TUNING (not in GDD)
	"move_speed": 100.0,  # TUNING (not in GDD) slightly slower than the player
	"damage": 45.0,  # TUNING (not in GDD)
	"attack_interval": 0.8,  # TUNING (not in GDD)
	"attack_range": 6.0,  # TUNING (not in GDD)
	"radius": 16.0,  # TUNING (not in GDD)
	"armor": 0.5,  # TUNING (not in GDD)
	"xp": 30,  # TUNING (not in GDD)
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 3.0,  # TUNING (not in GDD)
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # TUNING (not in GDD)
	"mass": 8.0,  # TUNING (not in GDD)
}

## Elite modifiers (GDD §11 timeline "05:00 Chaplain elite").
## Multiplier on max HP for elites.
const ELITE_HP_MULT: float = 3.0  # TUNING (not in GDD)
## Multiplier on body radius for elites.
const ELITE_RADIUS_MULT: float = 1.35  # TUNING (not in GDD)
## Multiplier on XP value for elites.
const ELITE_XP_MULT: int = 5  # TUNING (not in GDD)
## Multiplier on heal amount for elite healers.
const ELITE_HEAL_MULT: float = 1.5  # TUNING (not in GDD)

## Search radius (px) in which melee enemies will divert onto a summon that is
## closer than the player ("enemies can still hit allied summons", GDD §26).
const MELEE_DIVERT_RADIUS: float = 22.0  # TUNING (not in GDD)
## Search radius (px) in which Zealous Archers shoot a summon instead of the
## player (if that summon is closer than the player).
const RANGED_DIVERT_RADIUS: float = 70.0  # TUNING (not in GDD)
## Search radius (px) in which Purifiers hunt summons first (GDD §35).
const PURIFIER_HUNT_RADIUS: float = 180.0  # TUNING (not in GDD)
## Enemies within this distance (px) of the player with the player as target
## count as "attacking the player" for warrior threat scoring (GDD §27).
const ATTACKING_PLAYER_RADIUS: float = 120.0  # TUNING (not in GDD)
## Minimum missing-HP fraction before a chaplain will heal an ally.
const HEAL_MIN_MISSING_FRACTION: float = 0.1  # TUNING (not in GDD)
## Survivor convention (user brief): every enemy advances on the player.
## Ranged / healer units stop walking only when within this many px (edge to
## edge) of him, so they don't overlap his body.
const ADVANCE_STOP_GAP: float = 4.0  # TUNING (not in GDD)
## Speed multiplier for a ranged unit right after it fires (reads as
## "stopping to shoot" without ever backing away).
const SHOOT_SLOW_MULT: float = 0.5  # TUNING (not in GDD)
## Seconds the post-shot slowdown lasts.
const SHOOT_SLOW_TIME: float = 0.35  # TUNING (not in GDD)
## Seconds an enemy stays "engaged" after its last contact with a blocker.
const ENGAGED_TIME: float = 0.3  # TUNING (not in GDD)
## Knockback velocity decay in px/s^2.
const KNOCKBACK_DECAY: float = 700.0  # TUNING (not in GDD)
## Strength of enemy-enemy separation steering (fraction of move speed).
const SEPARATION_STRENGTH: float = 0.9  # TUNING (not in GDD)

## Sir Alaric, the Gravebreaker (GDD §11): "Heavy holy paladin with
## two-handed hammer" and five abilities. Every special is telegraphed
## (GDD §16 "Clear AoE telegraphs", §32 "Bosses can suppress or kill squads
## with clear telegraphs"). Attacks aimed at the necromancer can be
## body-blocked by undead (user brief: undead don't dodge, they absorb).
##   max_hp ... target_priority — as for ENEMIES.
##   reward_xp / reward_crystals — XP burst dropped on death and the number
##                        of crystals it is split into (killing him no longer
##                        wins the run; user brief).
##   slow_resist        — fraction of slow effects ignored.
##   attack_gap         — s between the end of one special and the next.
##   first_special      — s after arrival before the first special.
## Phase threshold (GDD gives none for Alaric; see GDD §15.0):
##   phase2_hp_fraction — below this HP fraction he enters "Wrath".
##   phase2_gap_mult    — attack_gap multiplier in Wrath.
##   phase2_extra_zones — extra Consecrated Ground zones per cast in Wrath.
##   phase2_extra_marks — extra Judgment of the Dead marks in Wrath.
##   phase2_banner      — HUD banner when Wrath starts (he also casts Call
##                        to Arms as his next special).
## Each special NAME in SPECIALS has NAME_weight (relative choice weight among
## the specials that are ready) and NAME_cooldown (s before NAME can be
## chosen again):
##   Hammerfall (GDD §11 "telegraphed overhead smash"):
##     hammer_radius / hammer_telegraph / hammer_max_range — AoE radius (px),
##                        warning time (s), max distance to the player (px).
##     hammer_damage_player / hammer_damage_summon — damage on impact.
##     hammer_soak_per_unit — fraction of the player's damage each summon
##                        inside the circle absorbs (body-blocking).
##     hammer_soak_max    — cap on that absorbed fraction.
##   Divine Charge (GDD §11 "fast linear rush"):
##     charge_min_range   — px; only used on a player at least this far.
##     charge_telegraph / charge_speed / charge_length / charge_width —
##                        warning time (s), px/s, max lane length (px, cut
##                        short by obstacles), lane width (px).
##     charge_damage_player / charge_damage_summon — damage on contact.
##     charge_absorb_summon / charge_absorb_warrior — px of remaining rush
##                        each undead body hit soaks up; at 0 the charge stops
##                        (body-blocking).
##   Consecrated Ground (GDD §11 "persistent radiant zones"):
##     consecrate_telegraph — s Alaric raises his hammer before the zones
##                        appear (the zones then have their own arm_time).
##     consecrate_count   — zones per cast (one on the necromancer's path).
##     consecrate_lead    — s of player movement the first zone leads by.
##     consecrate_spread_min / consecrate_spread_max — px from the player of
##                        the other zones.
##     consecrate_zone    — the holy zone (keys as WaveData.CONSECRATION.zone).
##   Call to Arms (GDD §11 "reinforcement infantry"):
##     call_telegraph     — s the rally markers are shown before soldiers
##                        arrive.
##     call_groups        — list of {kind, count} soldiers summoned.
##     call_radius_min / call_radius_max — px from Alaric they arrive at.
##   Judgment of the Dead (GDD §11 "marked AoE damages allied summons"):
##     judgment_telegraph — s the marks are shown before the light falls.
##     judgment_marks     — number of marks (centred on summon clusters).
##     judgment_radius    — px radius of each mark.
##     judgment_damage    — damage to each summon inside a mark (the
##                        necromancer is unharmed).
##     judgment_min_summons — only cast while at least this many summons live.
##   recover_time       — s he stands still after any special.
const BOSS := {
	"display_name": "Sir Alaric, the Gravebreaker",  # GDD §11
	"max_hp": 2500.0,  # TUNING (not in GDD)
	"move_speed": 52.0,  # TUNING (not in GDD)
	"damage": 12.0,  # TUNING (not in GDD) basic hammer swing
	"attack_interval": 1.0,  # TUNING (not in GDD)
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
	"target_priority": 0.9,  # GDD §32 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD) shoves warriors aside
	"reward_xp": 150,  # TUNING (not in GDD) user brief: big reward burst on kill
	"reward_crystals": 20,  # TUNING (not in GDD) crystals the reward is split into
	"slow_resist": 0.5,  # TUNING (not in GDD)
	"attack_gap": 2.6,  # TUNING (not in GDD)
	"first_special": 2.0,  # TUNING (not in GDD)
	"recover_time": 0.9,  # TUNING (not in GDD)
	"phase2_hp_fraction": 0.5,  # TUNING (not in GDD) no Alaric phases in the GDD
	"phase2_gap_mult": 0.7,  # TUNING (not in GDD)
	"phase2_extra_zones": 1,  # TUNING (not in GDD)
	"phase2_extra_marks": 2,  # TUNING (not in GDD)
	"phase2_banner": "Sir Alaric's wrath ignites!",  # TUNING (not in GDD)
	# Hammerfall.
	"hammer_weight": 1.0,  # TUNING (not in GDD)
	"hammer_cooldown": 0.0,  # TUNING (not in GDD)
	"hammer_radius": 80.0,  # TUNING (not in GDD)
	"hammer_telegraph": 1.2,  # TUNING (not in GDD)
	"hammer_damage_player": 30.0,  # TUNING (not in GDD)
	"hammer_damage_summon": 25.0,  # TUNING (not in GDD)
	"hammer_max_range": 230.0,  # TUNING (not in GDD)
	"hammer_soak_per_unit": 0.2,  # TUNING (not in GDD) body-blocking
	"hammer_soak_max": 0.8,  # TUNING (not in GDD)
	# Divine Charge.
	"charge_weight": 1.0,  # TUNING (not in GDD)
	"charge_cooldown": 0.0,  # TUNING (not in GDD)
	"charge_min_range": 100.0,  # TUNING (not in GDD)
	"charge_telegraph": 0.9,  # TUNING (not in GDD)
	"charge_speed": 620.0,  # TUNING (not in GDD)
	"charge_length": 420.0,  # TUNING (not in GDD)
	"charge_width": 56.0,  # TUNING (not in GDD)
	"charge_damage_player": 28.0,  # TUNING (not in GDD)
	"charge_damage_summon": 25.0,  # TUNING (not in GDD)
	"charge_absorb_summon": 50.0,  # TUNING (not in GDD) body-blocking
	"charge_absorb_warrior": 120.0,  # TUNING (not in GDD) body-blocking
	# Consecrated Ground.
	"consecrate_weight": 1.0,  # TUNING (not in GDD)
	"consecrate_cooldown": 9.0,  # TUNING (not in GDD)
	"consecrate_telegraph": 0.8,  # TUNING (not in GDD)
	"consecrate_count": 2,  # TUNING (not in GDD)
	"consecrate_lead": 0.4,  # TUNING (not in GDD)
	"consecrate_spread_min": 80.0,  # TUNING (not in GDD)
	"consecrate_spread_max": 160.0,  # TUNING (not in GDD)
	"consecrate_zone": {
		"radius": 62.0,  # TUNING (not in GDD)
		"arm_time": 1.4,  # TUNING (not in GDD)
		"duration": 10.0,  # TUNING (not in GDD) "persistent", but bounded
		"undead_dps": 8.0,  # TUNING (not in GDD)
		"undead_slow": 0.4,  # TUNING (not in GDD)
		"player_damage": 6.0,  # TUNING (not in GDD)
		"player_interval": 1.0,  # TUNING (not in GDD)
	},
	# Call to Arms.
	"call_weight": 1.0,  # TUNING (not in GDD)
	"call_cooldown": 18.0,  # TUNING (not in GDD)
	"call_telegraph": 1.3,  # TUNING (not in GDD)
	"call_groups": [{"kind": "recruit", "count": 6}, {"kind": "footman", "count": 2}],  # TUNING (not in GDD)
	"call_radius_min": 70.0,  # TUNING (not in GDD)
	"call_radius_max": 130.0,  # TUNING (not in GDD)
	# Judgment of the Dead.
	"judgment_weight": 1.0,  # TUNING (not in GDD)
	"judgment_cooldown": 11.0,  # TUNING (not in GDD)
	"judgment_telegraph": 1.8,  # TUNING (not in GDD)
	"judgment_marks": 3,  # TUNING (not in GDD)
	"judgment_radius": 46.0,  # TUNING (not in GDD)
	"judgment_damage": 26.0,  # TUNING (not in GDD)
	"judgment_min_summons": 3,  # TUNING (not in GDD)
}

## Sir Alaric's special ability ids (GDD §11), in HUD / report order.
const SPECIALS := ["hammer", "charge", "consecrate", "call", "judgment"]
