## EmpireRulesData — the numbers of the Electronic Empire's three shared rules
## (Act III; GDD §15.0 "Act III foundation (phase 1)", "Line of Fire", "Lock-On"
## and "Steel has no soul"), each with ONE code path, inert on Acts I and II:
##   LINE_OF_FIRE / SHOT_STYLES — EmpireShots: every Empire shot is a real
##       projectile (pooled packed arrays, a hard cap) that stops on the first
##       summon in its path; Bone Wall segments stop it, Warder barriers absorb
##       it (CombatResolver.damage_unit()), the Orb Shield intercepts it; the
##       necromancer is hit only by shots that find a gap. Arcing shots (style
##       "arc": true, mortars) fly over everything and burst where they land.
##   LOCK_ON — LockOn: a Spotter paints a thin red line on a target for
##       paint_time s, then a heavy shot fires down it; at most max_lines
##       painted at once (a boss may exceed it, boss_max_lines).
##   STEEL — machines leave no corpse (Enemy.leaves_corpse()); a raised cyborg
##       rises as a Grave Gunner (HordeDirector.raise_corpse()).
##   PURGE — the shared Purge Protocol Reckoning hook (EmpireRules): orbital
##       strikes on telegraphed circles, faster each minute; a stage's RECKONING
##       "orbital" dictionary overrides any of these keys.
## Data only (CLAUDE.md rule 2). Every number is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name EmpireRulesData
extends RefCounted

# --- Line of Fire (EmpireShots) ----------------------------------------------------

## Line of Fire limits and checks.
##   cap              — most Empire shots in flight at once (new ones are
##                      dropped beyond it; never touches ProjectileManager's cap).
##   draw_cap_reduced — most shots drawn with Effects: Reduced (phones).
##   summon_slack     — px added to a shot's summon query (the largest summon
##                      body beyond the shot's own radius and travel).
##   life_mult        — a shot flies range x this before it fades (it may still
##                      hit what stands just past its firer's range).
const LINE_OF_FIRE := {
	"cap": 360,  # TUNING (not in GDD) Act III has many shots; volleys hold 320
	"draw_cap_reduced": 140,  # TUNING (not in GDD)
	"summon_slack": 34.0,  # TUNING (not in GDD) px (the Golem / Colossus bodies are the widest)
	"life_mult": 1.2,  # TUNING (not in GDD)
}

## Shot looks and rules, keyed by EmpireEnemyData "shot_style" id:
##   radius  — hit radius (px) against summons, walls and the necromancer.
##   length  — drawn tracer length (px, along the flight).
##   width   — drawn tracer width (px).
##   color   — tracer colour (signal ramp); the core is drawn whiter.
##   arc     — true: an arcing shot (mortar) that ignores Line of Fire and
##             bursts at its landing point (EmpireShots.fire_arc()).
##   splash  — arcing shots only: burst radius (px) where it lands.
##   heavy   — true: a heavy shot (the Lock-On rail): drawn thick, counted on
##             its own in the stats.
##   art     — optional SpriteBank flat sprite key drawn instead of the tracer
##             (Act III missing sprites): facing +x, its head on the shot's
##             position; for an arcing shot the sprite is the lobbed shell.
const SHOT_STYLES := {
	"zap": {"radius": 3.0, "length": 7.0, "width": 2.0, "color": Color(1.0, 0.682, 0.102), "arc": false, "splash": 0.0, "heavy": false},  # TUNING (not in GDD) signal_amber spark
	"round": {"radius": 2.5, "length": 11.0, "width": 2.0, "color": Color(1.0, 0.682, 0.102), "arc": false, "splash": 0.0, "heavy": false},  # TUNING (not in GDD) amber tracer
	"rail": {"radius": 4.0, "length": 46.0, "width": 4.0, "color": Color(0.878, 0.224, 0.118), "arc": false, "splash": 0.0, "heavy": true, "art": "projectiles/empire_rail"},  # TUNING (not in GDD) warning-red rail slug
	"bolt": {"radius": 4.0, "length": 14.0, "width": 3.0, "color": Color(0.878, 0.224, 0.118), "arc": false, "splash": 0.0, "heavy": false},  # TUNING (not in GDD) phase 2 (turret / arc bolts)
	"mortar": {"radius": 6.0, "length": 8.0, "width": 6.0, "color": Color(1.0, 0.682, 0.102), "arc": true, "splash": 48.0, "heavy": false, "art": "projectiles/mortar_shell"},  # TUNING (not in GDD) phase 2 (Mortar Walker)
	# --- Act III: the Assembly Halls ---
	"arc_bolt": {"radius": 3.5, "length": 12.0, "width": 2.0, "color": Color(1.0, 0.922, 0.659), "arc": false, "splash": 0.0, "heavy": false},  # TUNING (not in GDD) the Arc Engineer's crackling bolt (signal_glow)
	"rivet": {"radius": 3.5, "length": 9.0, "width": 3.0, "color": Color(1.0, 0.682, 0.102), "arc": false, "splash": 0.0, "heavy": false},  # TUNING (not in GDD) the Beta Build's rivet spray (signal_amber)
	"turret_bolt": {"radius": 3.5, "length": 14.0, "width": 3.0, "color": Color(0.878, 0.224, 0.118), "arc": false, "splash": 0.0, "heavy": false},  # TUNING (not in GDD) the Motherboard Turret's bolt (signal_red)
	# --- Act III: the Iron Citadel ---
	# Deus Ex Machina's missile (its four-line Lock-On salvo, LockOn.paint(...,
	# style)): a heavy, slower warhead with a long amber exhaust trail.
	"missile": {"radius": 6.0, "length": 26.0, "width": 5.0, "color": Color(1.0, 0.682, 0.102), "arc": false, "splash": 0.0, "heavy": true, "art": "projectiles/empire_missile"},  # TUNING (not in GDD)
	# Deus Ex Machina's chaingun rounds (its sweeps and the Founder's ring of fire):
	# short warning-red tracers, lighter than a rifle round.
	"chaingun": {"radius": 2.5, "length": 9.0, "width": 2.0, "color": Color(0.878, 0.224, 0.118), "arc": false, "splash": 0.0, "heavy": false},  # TUNING (not in GDD)
}
## Arcing shots: peak height (px) of the drawn lob at mid-flight, per px of range.
const ARC_HEIGHT_PER_PX: float = 0.18  # TUNING (not in GDD)
## Arcing shots: seconds the landing circle is shown before impact (its telegraph).
const ARC_TELEGRAPH: float = 0.6  # TUNING (not in GDD)

# --- Lock-On (LockOn, SpotterKit) ----------------------------------------------------

## Lock-On lines.
##   paint_time     — s a line is painted before the heavy shot (owner-approved
##                    proposal: 1.5 s).
##   lock_time      — the last s of the paint: the line stops tracking and
##                    blinks (the moment to step out of it).
##   track_rate     — rad/s the line turns toward its target while tracking.
##   max_lines      — most lines painted at once (owner-approved proposal: 3);
##                    a paint asked beyond it is refused (the Spotter retries).
##   boss_max_lines — hard cap with a boss override (LockOn.paint(..., true):
##                    e.g. a missile salvo of four lines at once).
##   retry          — s before a Spotter whose paint was refused asks again.
##   length_mult    — drawn line length = the firer's range x this.
##   width / locked_width — drawn line width (px) while tracking / locked.
##   muzzle         — px from the firer's centre where the line and shot start.
##   danger_reach   — px from a painted line inside which the autotest bot
##                    feels its danger push (it steps out or Grave Steps).
const LOCK_ON := {
	"paint_time": 1.5,  # Owner-approved proposal: "paint a target with a thin red laser for 1.5 s"
	"lock_time": 0.45,  # TUNING (not in GDD)
	"track_rate": 1.1,  # TUNING (not in GDD) rad/s
	"max_lines": 3,  # Owner-approved proposal: "At most 3 painted lines at once"
	"boss_max_lines": 8,  # TUNING (not in GDD) the boss override's hard cap
	"retry": 0.6,  # TUNING (not in GDD) s
	"length_mult": 1.15,  # TUNING (not in GDD)
	"width": 1.0,  # TUNING (not in GDD) px "a thin red laser"
	"locked_width": 2.0,  # TUNING (not in GDD) px
	"muzzle": 10.0,  # TUNING (not in GDD) px
	"danger_reach": 26.0,  # TUNING (not in GDD) px
}
## The future Act III counter-passive Signal Ghost (owner-approved proposal; NOT
## built in phase 1): Lock-On lines take longer to paint on the necromancer.
## LockOn.paint_time() reads PassiveData row SIGNAL_GHOST's level value
## SIGNAL_GHOST_KEY (a fraction: paint_time x (1 + value) on the necromancer
## only); AbilityManager.passive_value() returns 0 while no such passive
## exists, so the hook is inert until a phase adds the row.
const SIGNAL_GHOST: String = "signal_ghost"
## Level-row key of Signal Ghost's extra paint time (fraction, see SIGNAL_GHOST).
const SIGNAL_GHOST_KEY: String = "paint_time"

# --- Steel has no soul (Enemy.leaves_corpse(), HordeDirector.raise_corpse()) ----

## Grave Gunners: a cyborg raised as a temporary Risen keeps its weapon.
##   class      — the temporary summon class it rises as (a ranged class, so
##                it fires for you; its stats are that class's effective stats
##                times the raising effect's own HP / damage multipliers).
##   tag        — its damage source (SummonedUnit.dmg_source, the autotest's
##                "steel" line and PassiveData.MINION_EXTRA_TAGS).
##   glyph      — its look (SummonedUnit.glyph_kind: summons/grave_gunner).
##   range_mult — x the class's attack range (it keeps the rifle's reach).
const STEEL := {
	"class": "archer",  # TUNING (not in GDD) the ranged base class (Skeletal Archer profile)
	"tag": "grave_gunner",
	"glyph": "grave_gunner",
	"range_mult": 1.3,  # TUNING (not in GDD) a rifle outranges a bow
}

# --- Purge Protocol (the shared Act III Reckoning hook, EmpireRules) ----------------

## Orbital strikes after 0:00 on a stage whose RECKONING has an "orbital"
## dictionary (its keys override these; absent = no strikes).
##   interval     — s between two strike salvos at 0:00.
##   interval_min — s between salvos at the fastest.
##   speedup      — interval x this for every minute past 0:00 ("faster each minute").
##   count        — strikes per salvo at 0:00 (one always on the necromancer).
##   count_growth — extra strikes per salvo for every minute past 0:00.
##   scatter      — px around the necromancer the other strikes land within.
##   radius       — px of each strike's circle.
##   telegraph    — s the circle is shown before the strike lands.
##   damage       — damage to the necromancer inside (time-scaled like every hit).
##   summon_damage — damage to each summon inside.
const PURGE := {
	"interval": 4.0,  # TUNING (not in GDD)
	"interval_min": 1.2,  # TUNING (not in GDD)
	"speedup": 0.75,  # TUNING (not in GDD)
	"count": 2,  # TUNING (not in GDD)
	"count_growth": 2,  # TUNING (not in GDD)
	"scatter": 260.0,  # TUNING (not in GDD) px
	"radius": 54.0,  # TUNING (not in GDD) px
	"telegraph": 1.2,  # TUNING (not in GDD) s
	"damage": 14.0,  # TUNING (not in GDD)
	"summon_damage": 30.0,  # TUNING (not in GDD)
}
