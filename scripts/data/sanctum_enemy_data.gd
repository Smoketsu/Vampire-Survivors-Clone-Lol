## SanctumEnemyData — immutable design data for the five Covenant kinds of
## Stage 3, the Sanctum of Judgment (GDD §7.2 roster, §8.3): the Sanctified
## Sentinel, the Radiant Inquisitor, the High Confessor, the Sun Paladin and
## the Cathedral Guardian miniboss. EnemyDirector.enemy_def() looks a kind up
## in EnemyData.ENEMIES, then MarchEnemyData.ENEMIES, then ENEMIES here, so
## any stage can spawn them through the normal spawn path (trickle weights,
## formation events, EnemyDirector.spawn_at()). Their special actions are
## CovenantKit subclasses (CovenantKits, keyed by the row's "kit").
##
## Every row has all the keys of an EnemyData.ENEMIES row (same meaning).
## Optional keys read by Enemy.activate() (absent = off; no Graveyard or
## Crimson March row has them, so those kinds are unchanged):
##   kit            — CovenantKits id of the kind's special actions.
##   always_elite   — true: the kind IS an elite (gold ring, elite loot rolls,
##                    elite Dread Rally points, elite freeze / stun times, Soul
##                    Ash elite bonus) and its numbers below are final: the
##                    EnemyData.ELITE_* multipliers are never applied to it,
##                    whatever `elite` flag the spawner passes.
##   construct      — true for animated stone (Sentinel, Guardian): never
##                    healed (Chaplains, Confessors), shielded or raised by a
##                    Confessor.
##   flat_armor     — damage ignored from EVERY hit, after percentage armour
##                    (CombatResolver.damage_enemy()); a hit always keeps at
##                    least FLAT_ARMOR_MIN_FRACTION of its damage, and the
##                    FLAT_ARMOR_EXEMPT_SOURCES ignore it.
##   miniboss       — true for the Cathedral Guardian: its own HUD health bar
##                    (EnemyDirector.miniboss), boss-like crowd-control
##                    resistance (Deep Freeze / dive stun durations use the
##                    caller's boss multiplier, Stasis holds it only for the
##                    boss share, no knockback), never recycled, and a
##                    guaranteed treasure chest on death (ChestManager).
##   projectile     — "radiant": a "ranged" kind fires Covenant radiant bolts
##                    tagged with its kind instead of arrows.
##   heal_stat      — Game.stats key counted per heal of a "healer" kind
##                    (default "chaplain_heals").
## The GDD gives no numbers: everything is TUNING (not in GDD) unless cited;
## owner-approved decisions are tagged as such (GDD §15.0).
class_name SanctumEnemyData
extends RefCounted

## Display / iteration order of the Sanctum kinds.
const ORDER := ["sanctified_sentinel", "radiant_inquisitor", "high_confessor", "sun_paladin", "cathedral_guardian"]

## A flat-armoured hit always keeps at least this fraction (0..1) of its
## post-armour damage, so weak hits (orbs, Plague ticks, early swings) still
## chip a Sentinel instead of bouncing off.
const FLAT_ARMOR_MIN_FRACTION: float = 0.25  # TUNING (not in GDD)
## Damage sources that ignore flat armour, holy shields and the Sun Paladin's
## ward: the Soul Nova (it undoes armour to land its intended amount).
const FLAT_ARMOR_EXEMPT_SOURCES := ["nova"]
## Seconds a Sun Paladin's ward lingers on a soldier after it leaves the aura
## (the aura refreshes at the 5 Hz think rate).
const WARD_LINGER: float = 0.6  # TUNING (not in GDD)
## Size of the recent-deaths ring buffer High Confessors raise soldiers from
## (CovenantRites; the oldest entry is overwritten).
const DEATH_BUFFER_SIZE: int = 32  # TUNING (not in GDD)

## The Sanctum's Covenant kinds (keys: see the header and EnemyData).
const ENEMIES := {
	# GDD §7.2 "Sanctified Sentinel: high-armor construct with sweeps". A slow
	# stone construct: flat armour shrugs off weak hits (counterplay: big
	# single hits, mages, spears), and a telegraphed frontal sweep knocks the
	# undead back.
	"sanctified_sentinel": {
		"display_name": "Sanctified Sentinel",
		"max_hp": 120.0,  # TUNING (not in GDD)
		"move_speed": 34.0,  # TUNING (not in GDD) slow construct
		"damage": 7.0,  # TUNING (not in GDD) stone fist
		"attack_interval": 1.6,  # TUNING (not in GDD)
		"attack_range": 6.0,  # TUNING (not in GDD)
		"radius": 15.0,  # TUNING (not in GDD)
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.4,  # TUNING (not in GDD)
		"mass": 5.0,  # TUNING (not in GDD) heavy stone: shoves warriors
		"slow_resist": 0.3,  # TUNING (not in GDD)
		"kit": "sentinel",
		"construct": true,
		"flat_armor": 6.0,  # Owner-approved: ignores the first 6 damage of every hit
		# Frontal sweep (SentinelKit): a gold cone toward its target, then a
		# stone sweep that hurts and shoves back every undead in it.
		"sweep_first": 2.5,  # TUNING (not in GDD) s after spawning before the first sweep
		"sweep_cooldown": 6.0,  # TUNING (not in GDD) s between sweeps
		"sweep_trigger_range": 60.0,  # TUNING (not in GDD) px edge-to-edge; sweeps only a target this close
		"sweep_radius": 74.0,  # TUNING (not in GDD) px cone reach from its centre
		"sweep_half_angle": 1.05,  # TUNING (not in GDD) rad each side (~120 degrees)
		"sweep_telegraph": 1.0,  # Owner-approved ~1 s telegraph
		"sweep_damage_player": 12.0,  # TUNING (not in GDD) before time scaling
		"sweep_damage_summon": 14.0,  # TUNING (not in GDD) before time scaling
		"sweep_knockback": 46.0,  # TUNING (not in GDD) px a struck summon is shoved away
	},
	# GDD §7.2 "Radiant Inquisitor: elite caster, creates holy damage zones;
	# at later difficulty may briefly suppress replacement locally, with
	# telegraphed visuals". A mid-game elite caster (the Reckoning's
	# Inquisitor of the End scaled far down): advances shooting radiant
	# bolts, lays holy zones and casts the suppression sigil on the undead
	# frontline.
	"radiant_inquisitor": {
		"display_name": "Radiant Inquisitor",
		"max_hp": 150.0,  # TUNING (not in GDD) an elite's HP (an elite Footman has 108)
		"move_speed": 52.0,  # TUNING (not in GDD)
		"damage": 6.0,  # TUNING (not in GDD) radiant bolt
		"attack_interval": 2.4,  # TUNING (not in GDD)
		"attack_range": 230.0,  # TUNING (not in GDD) max firing distance
		"radius": 13.0,  # TUNING (not in GDD)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 25,  # TUNING (not in GDD) an elite Chaplain's XP
		"behavior": "ranged",
		"projectile_speed": 220.0,  # TUNING (not in GDD)
		"undead_damage_mult": 1.2,  # TUNING (not in GDD) holy light burns the dead
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # GDD §27 casters are preferred targets
		"mass": 1.2,  # TUNING (not in GDD)
		"kit": "inquisitor",
		"always_elite": true,  # GDD §7.2 "Elite caster"
		"projectile": "radiant",
		# Holy zones (InquisitorKit): StageDirector holy ground on the
		# necromancer's path (it also blocks summon replacement inside).
		"zone_first": 3.0,  # TUNING (not in GDD) s before the first zone
		"zone_cooldown": 8.0,  # TUNING (not in GDD)
		"zone_range": 260.0,  # TUNING (not in GDD) px; casts only at a necromancer this close
		"zone_lead": 0.4,  # TUNING (not in GDD) s of necromancer movement the zone leads by
		"zone_cast": 0.6,  # TUNING (not in GDD) s it stands still casting
		"zone": {
			"radius": 52.0,  # TUNING (not in GDD)
			"arm_time": 1.2,  # TUNING (not in GDD) GDD §10.5 telegraphed
			"duration": 6.0,  # TUNING (not in GDD)
			"undead_dps": 6.0,  # TUNING (not in GDD)
			"undead_slow": 0.35,  # TUNING (not in GDD)
			"player_damage": 5.0,  # TUNING (not in GDD)
			"player_interval": 1.0,  # TUNING (not in GDD)
		},
		# Suppression (owner-approved, GDD §15.0): a 1 s telegraphed 160 px
		# circle; for 4 s summons that die inside are not replaced and no
		# replacement spawns inside (HordeDirector.add_suppression()).
		"suppress_first": 6.0,  # TUNING (not in GDD) s before the first sigil
		"suppress_cooldown": 14.0,  # TUNING (not in GDD)
		"suppress_range": 260.0,  # TUNING (not in GDD) px to the summon it centres on
		"suppress_radius": 160.0,  # Owner-approved 160 px
		"suppress_duration": 4.0,  # Owner-approved 4 s
		"suppress_telegraph": 1.0,  # Owner-approved 1 s telegraph
		"suppress_min_summons": 3,  # TUNING (not in GDD) summons inside the circle to bother casting
		"suppress_damage_mult": 1.0,  # TUNING (not in GDD) no damage halving (that is Seraphine's)
	},
	# GDD §7.2 "High Confessor: elite priest; healing, shielding and limited
	# revival". Advances like a Chaplain (never kites), heals the most
	# wounded ally, shields up to three allies and raises a fallen soldier
	# every 12 s (owner-approved, GDD §15.0 / open question 35).
	"high_confessor": {
		"display_name": "High Confessor",
		"max_hp": 170.0,  # TUNING (not in GDD)
		"move_speed": 46.0,  # TUNING (not in GDD)
		"damage": 3.0,  # TUNING (not in GDD) weak melee if cornered
		"attack_interval": 1.4,  # TUNING (not in GDD)
		"attack_range": 4.0,  # TUNING (not in GDD)
		"radius": 12.0,  # TUNING (not in GDD)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 30,  # TUNING (not in GDD)
		"behavior": "healer",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 6.0,  # TUNING (not in GDD) per heal at 0:00, grows with enemy HP scaling (ConfessorKit)
		"heal_interval": 3.0,  # TUNING (not in GDD) 10 -> 6 HP / 2.5 -> 3 s after a forced-spawn test: a pack of Confessors outhealed a 3-minute army
		"heal_radius": 120.0,  # Owner brief: heals Covenant allies within 120 px
		"target_priority": 1.0,  # GDD §27/§35 healers are top priority (like Chaplains)
		"mass": 1.4,  # TUNING (not in GDD)
		"kit": "confessor",
		"always_elite": true,  # GDD §7.2 "Elite priest"
		"heal_stat": "high_confessor_heals",
		# Holy shields (ConfessorKit): an absorb barrier on up to
		# shield_targets allies (bosses, minibosses and elites first; never
		# another High Confessor, so a pack of priests cannot shield itself).
		"shield_first": 2.0,  # TUNING (not in GDD) s before the first shields
		"shield_interval": 10.0,  # TUNING (not in GDD)
		"shield_radius": 120.0,  # TUNING (not in GDD) px
		"shield_targets": 3,  # Owner brief: up to 3 allies
		"shield_amount": 15.0,  # TUNING (not in GDD) absorb at 0:00, grows with enemy HP scaling
		"shield_duration": 6.0,  # TUNING (not in GDD) s before an unbroken shield fades
		# Revival (owner-approved, GDD §15.0 / open question 35).
		"revive_first": 6.0,  # TUNING (not in GDD) s before the first revival
		"revive_interval": 12.0,  # Owner-approved: every 12 s
		"revive_radius": 140.0,  # Owner-approved: a soldier that fell within 140 px
		"revive_telegraph": 1.5,  # Owner-approved: a gold pillar for 1.5 s
		"revive_max": 3,  # Owner-approved: at most 3 revives per Confessor
		"revive_max_age": 20.0,  # TUNING (not in GDD) s; older deaths are beyond saving
		"revive_hp_fraction": 0.6,  # TUNING (not in GDD) HP a raised soldier comes back with
	},
	# GDD §8.3 "16:00 Elite paladins" (GDD §15.0 resolves the roster gap): an
	# armoured Templar whose sun aura hardens the soldiers around it.
	# Counterplay: kill it first (the ward drops 0.6 s later), pull soldiers
	# away from it, body-block its charge.
	"sun_paladin": {
		"display_name": "Sun Paladin",
		"max_hp": 260.0,  # TUNING (not in GDD)
		"move_speed": 46.0,  # TUNING (not in GDD)
		"damage": 10.0,  # TUNING (not in GDD)
		"attack_interval": 1.3,  # TUNING (not in GDD)
		"attack_range": 7.0,  # TUNING (not in GDD)
		"radius": 14.0,  # TUNING (not in GDD)
		"armor": 0.35,  # TUNING (not in GDD) gilded plate
		"xp": 30,  # TUNING (not in GDD)
		"behavior": "templar",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.65,  # TUNING (not in GDD) the army should break the aura
		"mass": 4.0,  # TUNING (not in GDD) heavy: shoves warriors
		"kit": "paladin",
		"always_elite": true,  # GDD §8.3 "Elite paladins"
		# Templar charge (same keys and behaviour as EnemyData templar).
		"charge_range_min": 60.0,  # TUNING (not in GDD)
		"charge_range_max": 200.0,  # TUNING (not in GDD)
		"charge_telegraph": 0.75,  # TUNING (not in GDD)
		"charge_speed": 340.0,  # TUNING (not in GDD)
		"charge_length": 180.0,  # TUNING (not in GDD)
		"charge_width": 32.0,  # TUNING (not in GDD)
		"charge_cooldown": 8.0,  # TUNING (not in GDD)
		"charge_damage": 14.0,  # TUNING (not in GDD)
		"charge_knockback": 28.0,  # TUNING (not in GDD)
		"charge_block_mass": 3.0,  # TUNING (not in GDD) one warrior stops it
		# Sun aura (PaladinKit, owner brief): other Covenant soldiers within
		# ward_radius take ward_resist less damage; one ward per soldier
		# (several paladins do not stack).
		"ward_radius": 110.0,  # Owner brief: ~110 px
		"ward_resist": 0.2,  # Owner brief: 20% damage resistance
	},
	# GDD §7.4 / §8.3 "Cathedral Guardians: construct minibosses controlling
	# route access" (owner decision: a plain miniboss, spawned once by the
	# stage). A giant stone construct with its own health bar: telegraphed
	# ground slams and a sweeping beam; it advances slowly and drops a
	# treasure chest when it falls.
	"cathedral_guardian": {
		"display_name": "Cathedral Guardian",
		"max_hp": 2200.0,  # TUNING (not in GDD) x enemy HP scaling (x1.9 at 5:30)
		"move_speed": 30.0,  # TUNING (not in GDD) slow
		"damage": 16.0,  # TUNING (not in GDD) stone fist
		"attack_interval": 1.6,  # TUNING (not in GDD)
		"attack_range": 10.0,  # TUNING (not in GDD)
		"radius": 30.0,  # TUNING (not in GDD)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is GuardianKit's XP burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers focus it like a boss
		"mass": 14.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.5,  # TUNING (not in GDD) like the bosses
		"kit": "guardian",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"construct": true,
		"miniboss": true,
		"reward_xp": 160,  # TUNING (not in GDD) XP burst on death
		"reward_crystals": 10,  # TUNING (not in GDD) crystals it is split into
		# Pacing between specials.
		"first_special": 2.5,  # TUNING (not in GDD) s after arrival
		"attack_gap": 4.0,  # TUNING (not in GDD) s between the end of one special and the next
		"recover_time": 0.8,  # TUNING (not in GDD) s it stands after a special
		# Forced march: it never kites, and catches up when left behind.
		"advance_range": 260.0,  # TUNING (not in GDD) px; farther than this it strides faster
		"advance_speed_mult": 2.0,  # TUNING (not in GDD) 30 -> 60 px/s (the necromancer runs at 110)
		# Ground slam: a gold circle on the necromancer, then the fists land.
		"slam_weight": 1.0,  # TUNING (not in GDD) choice weight
		"slam_cooldown": 10.0,  # TUNING (not in GDD)
		"slam_range": 240.0,  # TUNING (not in GDD) px; used on a necromancer this close
		"slam_radius": 72.0,  # TUNING (not in GDD)
		"slam_telegraph": 1.3,  # TUNING (not in GDD) GDD §10.5 clear telegraphs
		"slam_damage_player": 26.0,  # TUNING (not in GDD) before time scaling
		"slam_damage_summon": 14.0,  # TUNING (not in GDD) before time scaling
		"slam_soak_per_unit": 0.15,  # TUNING (not in GDD) body-blocking (like Hammerfall)
		"slam_soak_max": 0.6,  # TUNING (not in GDD)
		"slam_knockback": 40.0,  # TUNING (not in GDD) px summons are thrown out of the circle
		# Sweeping beam: a gold sector telegraph, then a radiant beam sweeps
		# across it from one edge to the other, hitting everything it crosses
		# once.
		"beam_weight": 1.0,  # TUNING (not in GDD)
		"beam_cooldown": 14.0,  # TUNING (not in GDD)
		"beam_min_range": 50.0,  # TUNING (not in GDD) px; not used on a necromancer hugging it
		"beam_range": 300.0,  # TUNING (not in GDD) px; used on a necromancer this close
		"beam_length": 340.0,  # TUNING (not in GDD) px
		"beam_width": 24.0,  # TUNING (not in GDD) px
		"beam_half_arc": 0.75,  # TUNING (not in GDD) rad each side of the necromancer
		"beam_telegraph": 1.2,  # TUNING (not in GDD)
		"beam_sweep_time": 1.5,  # TUNING (not in GDD) s to cross the arc
		"beam_damage_player": 22.0,  # TUNING (not in GDD) before time scaling
		"beam_damage_summon": 9.0,  # TUNING (not in GDD) before time scaling
	},
}

## The Cathedral Guardian's special ability ids, in report order.
const GUARDIAN_SPECIALS := ["slam", "beam"]
