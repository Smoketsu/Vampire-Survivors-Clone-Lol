## SeraphineData — immutable design data for GRAND INQUISITOR SERAPHINE,
## VOICE OF THE DAWN (GDD §7.5), the Stage 3 boss (BossSeraphine). The GDD
## names her three phases and their behaviours; every number below is
## TUNING (not in GDD), the behaviour it expresses is cited. Data only.
##
## BOSS has every key of an EnemyData.ENEMIES row (same meaning) plus the
## shared boss keys of EnemyData.BOSS (reward_xp, reward_crystals,
## slow_resist, attack_gap, first_special, recover_time), cast_time (s she
## holds the brief casts: holy circles, suppression) and her kit:
##   Phases (GDD §7.5 table):
##     avatar_hp_fraction    — below this HP fraction: Avatar of the Dawn.
##     last_light_hp_fraction — below this: The Last Light.
##     phase_specials        — per phase (0 Divine Judgment, 1 Avatar,
##                             2 Last Light): the specials she may choose
##                             (weighted, see NAME_weight). The Judgment
##                             nova is not in these lists: it runs on its
##                             own clock (nova_interval).
##     phase_gap_mult        — attack_gap multiplier per phase.
##     phase_telegraph_mult  — windup multiplier per phase (still readable).
##   Avatar transformation (GDD "relic transformation"):
##     avatar_transform_time — s she channels the relic, INVULNERABLE.
##     avatar_banner / last_light_banner — HUD banners on phase entry.
##     last_light_time       — s she flares at the Last Light (not invulnerable).
##   Attendants (GDD §15.5 q34, resolved in §15.0: her healers):
##     attendant_kind        — enemy kind of her healers (spawned with her).
##     attendant_count       — healers when no altar was destroyed; the
##                             count is attendant_count - altars destroyed
##                             (game.altars_destroyed, Stage 3), min 0.
##     attendant_hp_mult     — extra HP multiplier on each healer.
##     attendant_spawn_radius — px from her where they appear.
##     attend_radius         — px: a living healer this close heals her.
##     attend_regen          — HP/s she regenerates per healer in reach
##                             (through CombatResolver.heal_enemy()).
##     attend_tick           — s between those heal pulses.
##   Each special NAME has NAME_weight (relative choice weight) and
##   NAME_cooldown (s before it may be chosen again), plus:
##   Radiant fan (GDD "radiant projectiles"):
##     fan_telegraph, fan_bolts / fan_bolts_last, fan_spread (rad, whole
##     fan), fan_damage (x enemy damage scaling), fan_speed (px/s),
##     fan_max_range (px to the necromancer to use it), fan_cone (px,
##     length of the drawn warning sector).
##   Delayed holy circles (GDD "delayed holy circles"):
##     circles_delay (s from the mark to
##     the blast), circles_count (+ circles_extra_last in the Last Light),
##     circles_radius, circles_lead (s of necromancer movement the first one
##     leads by), circles_spread_min / max (px of the others from him),
##     circles_damage_player (x scaling), circles_damage_summon,
##     circles_max_range.
##   Templar squads (GDD "templars"): templars_telegraph, templars_groups
##     ({kind, count}), templars_radius_min / max (px from her).
##   Teleport (GDD "teleportation"): teleport_glow (s of glow first),
##     teleport_min_range (px: only used to close in), teleport_dist_min /
##     max (px from the necromancer she lands), teleport_turn (rad: max
##     angle from her current bearing; she lands on his near side, never
##     farther away).
##   Rotating holy beams (GDD Avatar): beams_telegraph, beams_count,
##     beams_length (px), beams_width (px), beams_speed (rad/s; x
##     beams_speed_last in the Last Light), beams_duration (s of sweep),
##     beams_tick (s between damage pulses), beams_damage_player (x
##     scaling), beams_damage_summon, beams_max_range.
##   Barrage (GDD "barrages"): barrage_telegraph, barrage_volleys,
##     barrage_interval (s), barrage_bolts (per ring), barrage_damage,
##     barrage_speed, barrage_max_range.
##   Constructs (GDD "constructs"): construct_kind, constructs_count,
##     constructs_telegraph, constructs_hp_mult, constructs_offset (px from
##     her toward the necromancer), constructs_spread (px between them).
##   Undead suppression (GDD "temporary undead suppression"; §15.5 q36):
##     suppression_telegraph, suppression_radius (px around the necromancer
##     at the cast), suppression_duration (s), suppression_damage_mult
##     (summon damage multiplier inside), suppression_min_summons.
##   Judgment nova (GDD "safe-zone navigation"): nova_interval (s between
##     novas in the Avatar phase; nova_interval_last in the Last Light),
##     nova_first (s after the transformation), nova_telegraph, nova_radius
##     (px around her that burns), nova_safe_zones / nova_safe_zones_last,
##     nova_safe_radius, nova_near_min / max (px from the necromancer of the
##     first safe zone: always reachable in time), nova_near_turn (rad: max
##     angle of that zone from his bearing to her), nova_far_min / max (px
##     from her of the others), nova_damage_player (x scaling),
##     nova_damage_summon.
##   Collapsing arena (GDD "collapsing arena", the Last Light):
##     collapse_start_radius / collapse_end_radius (px around her position at
##     the Last Light), collapse_time (s to shrink), collapse_tick,
##     collapse_damage_player (x scaling, per tick), collapse_damage_summon.
##   Final guard (GDD "final army confrontation"): guard_groups ({kind,
##     count}), guard_telegraph, guard_radius (px from the arena centre).
class_name SeraphineData
extends RefCounted

## Special ability ids in HUD / report order (the nova is timed, not chosen).
const SPECIALS := ["fan", "circles", "templars", "teleport", "beams", "barrage", "constructs", "suppression", "nova"]

## Damage-source tags of her attacks (CombatResolver stats; PassiveData
## lists them for Unholy Resilience).
const SOURCES := ["seraphine_bolt", "seraphine_circle", "seraphine_beam", "seraphine_nova", "seraphine_collapse"]

## Seraphine's arrival in a stage's boss slot (StageRegistry "boss" keys,
## see GraveyardStage.BOSS). The Sanctum of Judgment uses it; the autotest
## option --boss=seraphine puts it in any stage's slot (StageRegistry
## BOSS_ARRIVALS, keeping that stage's time).
const ARRIVAL := {
	"id": "seraphine",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Grand Inquisitor Seraphine, Voice of the Dawn",  # GDD §7.5
	"short_name": "Seraphine",
	"arrive_banner": "Grand Inquisitor Seraphine descends: the Voice of the Dawn passes judgment!",  # TUNING (not in GDD)
	"defeat_banner": "The Sanctum falls. Across the realm, other holy orders begin to mobilize.",  # GDD §7.5 ending (owner wording)
	"dead_objective": "The radiant relic is shattered. Survive until the countdown ends.",  # GDD §7.5 "shatter the radiant relic"
}

## Seconds the ending text (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 9.0  # TUNING (not in GDD)
## HUD announcement on her death (title, line, description).
const ENDING_ANNOUNCE := ["THE SANCTUM FALLS", "The radiant relic shatters", "Across the realm, other holy orders begin to mobilize."]  # GDD §7.5 ending
## Radius (px) of the relic-shatter burst on her death.
const SHATTER_RADIUS: float = 170.0  # TUNING (not in GDD)
## Gold / ivory shards flung out by the shatter (cosmetic particles).
const SHATTER_SHARDS: int = 36  # TUNING (not in GDD)

## The boss row (keys in the header).
const BOSS := {
	"display_name": "Grand Inquisitor Seraphine, Voice of the Dawn",  # GDD §7.5
	"max_hp": 30000.0,  # TUNING (not in GDD) x the stage HP multiplier (33,000 in the Sanctum); 40,000 was tuned on the Graveyard, but in her own crowded stage (x1.1-1.2) it often outlasted the countdown
	"move_speed": 48.0,  # TUNING (not in GDD)
	"damage": 11.0,  # TUNING (not in GDD) staff strike in reach
	"attack_interval": 1.1,  # TUNING (not in GDD)
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
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD) shoves warriors aside
	"reward_xp": 500,  # TUNING (not in GDD) final boss: a little more than Vael's 450
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD)
	"attack_gap": 2.3,  # TUNING (not in GDD)
	"first_special": 2.0,  # TUNING (not in GDD)
	"recover_time": 0.7,  # TUNING (not in GDD)
	"cast_time": 0.5,  # TUNING (not in GDD) brief cast pose of the holy circles and the suppression
	# Phases.
	"avatar_hp_fraction": 0.6,  # GDD §7.5 "60% HP"
	"last_light_hp_fraction": 0.2,  # GDD §7.5 "20% HP"
	"phase_specials": [
		["fan", "circles", "templars", "teleport"],  # GDD §7.5 Divine Judgment
		["beams", "barrage", "circles", "constructs", "suppression", "teleport"],  # GDD §7.5 Avatar of the Dawn
		["beams", "barrage", "fan", "circles", "constructs", "suppression", "teleport"],  # GDD §7.5 The Last Light "more hazards"
	],
	"phase_gap_mult": [1.0, 0.9, 0.6],  # TUNING (not in GDD) GDD Last Light "faster attacks"
	"phase_telegraph_mult": [1.0, 1.0, 0.85],  # TUNING (not in GDD) still readable
	"avatar_transform_time": 1.0,  # TUNING (not in GDD) owner brief ~1 s invulnerable
	"avatar_banner": "Seraphine raises the relic: the Avatar of the Dawn!",  # TUNING (not in GDD)
	"last_light_time": 0.8,  # TUNING (not in GDD)
	"last_light_banner": "The Last Light! The Sanctum burns around her!",  # TUNING (not in GDD)
	# Attendants (her healers).
	"attendant_kind": "high_confessor",  # GDD §7.2 / §7.5: her healers are High Confessors (SanctumEnemyData)
	"attendant_count": 3,  # TUNING (not in GDD) owner brief: up to three
	"attendant_hp_mult": 1.0,  # TUNING (not in GDD) the High Confessor row carries its own HP (170, always elite; was a x6 Chaplain before the merge, 192)
	"attendant_spawn_radius": 46.0,  # TUNING (not in GDD)
	"attend_radius": 170.0,  # TUNING (not in GDD)
	"attend_regen": 30.0,  # TUNING (not in GDD) HP/s per healer in reach
	"attend_tick": 0.5,  # TUNING (not in GDD)
	# Radiant fan.
	"fan_weight": 1.0,  # TUNING (not in GDD)
	"fan_cooldown": 5.0,  # TUNING (not in GDD)
	"fan_telegraph": 0.6,  # TUNING (not in GDD)
	"fan_bolts": 7,  # TUNING (not in GDD)
	"fan_bolts_last": 9,  # TUNING (not in GDD)
	"fan_spread": 1.1,  # TUNING (not in GDD) ~63 degrees
	"fan_damage": 6.0,  # TUNING (not in GDD)
	"fan_speed": 240.0,  # TUNING (not in GDD)
	"fan_max_range": 380.0,  # TUNING (not in GDD)
	"fan_cone": 220.0,  # TUNING (not in GDD)
	# Delayed holy circles.
	"circles_weight": 1.2,  # TUNING (not in GDD)
	"circles_cooldown": 7.0,  # TUNING (not in GDD)
	"circles_delay": 1.2,  # TUNING (not in GDD) owner brief: detonate after 1.2 s
	"circles_count": 3,  # TUNING (not in GDD)
	"circles_extra_last": 2,  # TUNING (not in GDD)
	"circles_radius": 56.0,  # TUNING (not in GDD)
	"circles_lead": 0.4,  # TUNING (not in GDD)
	"circles_spread_min": 90.0,  # TUNING (not in GDD)
	"circles_spread_max": 170.0,  # TUNING (not in GDD)
	"circles_damage_player": 16.0,  # TUNING (not in GDD) 20 at first (Stage 3 integration balance)
	"circles_damage_summon": 18.0,  # TUNING (not in GDD)
	"circles_max_range": 420.0,  # TUNING (not in GDD)
	# Templar squads.
	"templars_weight": 0.8,  # TUNING (not in GDD)
	"templars_cooldown": 24.0,  # TUNING (not in GDD)
	"templars_telegraph": 1.3,  # TUNING (not in GDD)
	"templars_groups": [{"kind": "templar", "count": 3}, {"kind": "footman", "count": 2}],  # TUNING (not in GDD)
	"templars_radius_min": 70.0,  # TUNING (not in GDD)
	"templars_radius_max": 130.0,  # TUNING (not in GDD)
	# Teleport.
	"teleport_weight": 1.5,  # TUNING (not in GDD)
	"teleport_cooldown": 8.0,  # TUNING (not in GDD)
	"teleport_glow": 1.0,  # TUNING (not in GDD) owner brief: a 1 s glow
	"teleport_min_range": 170.0,  # TUNING (not in GDD)
	"teleport_dist_min": 110.0,  # TUNING (not in GDD)
	"teleport_dist_max": 160.0,  # TUNING (not in GDD)
	"teleport_turn": 1.1,  # TUNING (not in GDD) ~63 degrees either side
	# Rotating holy beams.
	"beams_weight": 1.2,  # TUNING (not in GDD)
	"beams_cooldown": 14.0,  # TUNING (not in GDD)
	"beams_telegraph": 1.2,  # TUNING (not in GDD)
	"beams_count": 2,  # TUNING (not in GDD) owner brief: two beams
	"beams_length": 320.0,  # TUNING (not in GDD)
	"beams_width": 26.0,  # TUNING (not in GDD)
	"beams_speed": 0.85,  # TUNING (not in GDD) rad/s
	"beams_speed_last": 1.15,  # TUNING (not in GDD)
	"beams_duration": 4.2,  # TUNING (not in GDD) each beam sweeps ~205 degrees
	"beams_tick": 0.25,  # TUNING (not in GDD)
	"beams_damage_player": 8.0,  # TUNING (not in GDD) per pulse (i-frames cap it)
	"beams_damage_summon": 5.0,  # TUNING (not in GDD) per pulse
	"beams_max_range": 280.0,  # TUNING (not in GDD)
	# Barrage.
	"barrage_weight": 1.0,  # TUNING (not in GDD)
	"barrage_cooldown": 8.0,  # TUNING (not in GDD)
	"barrage_telegraph": 0.7,  # TUNING (not in GDD)
	"barrage_volleys": 3,  # TUNING (not in GDD)
	"barrage_interval": 0.35,  # TUNING (not in GDD)
	"barrage_bolts": 12,  # TUNING (not in GDD)
	"barrage_damage": 5.0,  # TUNING (not in GDD)
	"barrage_speed": 200.0,  # TUNING (not in GDD)
	"barrage_max_range": 360.0,  # TUNING (not in GDD)
	# Constructs.
	"constructs_weight": 0.8,  # TUNING (not in GDD)
	"constructs_cooldown": 22.0,  # TUNING (not in GDD)
	"construct_kind": "sanctified_sentinel",  # GDD §7.2 / §7.5 "constructs": Sanctified Sentinels (SanctumEnemyData)
	"constructs_count": 2,  # TUNING (not in GDD)
	"constructs_telegraph": 1.5,  # TUNING (not in GDD)
	"constructs_hp_mult": 1.0,  # TUNING (not in GDD) the Sentinel row carries its own HP and flat armour (120; was a x3 footman before the merge, 108)
	"constructs_offset": 90.0,  # TUNING (not in GDD)
	"constructs_spread": 60.0,  # TUNING (not in GDD)
	# Undead suppression.
	"suppression_weight": 0.9,  # TUNING (not in GDD)
	"suppression_cooldown": 18.0,  # TUNING (not in GDD)
	"suppression_telegraph": 1.5,  # TUNING (not in GDD) owner brief
	"suppression_radius": 220.0,  # TUNING (not in GDD) owner brief
	"suppression_duration": 5.0,  # TUNING (not in GDD) owner brief
	"suppression_damage_mult": 0.5,  # TUNING (not in GDD) owner brief: half damage
	"suppression_min_summons": 4,  # TUNING (not in GDD)
	# Judgment nova.
	"nova_interval": 25.0,  # TUNING (not in GDD) owner brief: every 25 s
	"nova_interval_last": 20.0,  # TUNING (not in GDD) GDD Last Light "more hazards"
	"nova_first": 6.0,  # TUNING (not in GDD)
	"nova_telegraph": 2.5,  # TUNING (not in GDD) owner brief ~2.5 s
	"nova_radius": 640.0,  # TUNING (not in GDD) past the screen edge at Normal zoom
	"nova_safe_zones": 3,  # TUNING (not in GDD) owner brief 2-3
	"nova_safe_zones_last": 2,  # TUNING (not in GDD)
	"nova_safe_radius": 62.0,  # TUNING (not in GDD)
	"nova_near_min": 80.0,  # TUNING (not in GDD) <= 1.4 s walk for the necromancer (110 px/s)
	"nova_near_max": 140.0,  # TUNING (not in GDD)
	"nova_near_turn": 1.0,  # TUNING (not in GDD) rad either side of the bearing to her: shelter lies her way, keeping the army on her
	"nova_far_min": 150.0,  # TUNING (not in GDD)
	"nova_far_max": 300.0,  # TUNING (not in GDD)
	"nova_damage_player": 22.0,  # TUNING (not in GDD) heavy (x enemy damage scaling, ~x3 at 17:00); 28 at first
	"nova_damage_summon": 22.0,  # TUNING (not in GDD)
	# Collapsing arena.
	"collapse_start_radius": 600.0,  # TUNING (not in GDD) owner brief
	"collapse_end_radius": 300.0,  # TUNING (not in GDD) owner brief
	"collapse_time": 40.0,  # TUNING (not in GDD) owner brief
	"collapse_tick": 0.5,  # TUNING (not in GDD)
	"collapse_damage_player": 5.0,  # TUNING (not in GDD) per tick (x scaling)
	"collapse_damage_summon": 6.0,  # TUNING (not in GDD) per tick
	# Final guard.
	"guard_groups": [{"kind": "templar", "count": 5}, {"kind": "sun_paladin", "count": 3}],  # TUNING (not in GDD) GDD "final army confrontation": Templars and Sun Paladins (always elite, so 3 where the footmen before the merge were 5)
	"guard_telegraph": 1.5,  # TUNING (not in GDD)
	"guard_radius": 520.0,  # TUNING (not in GDD) inside the 600 px collapse ring
}
