## PantheonRulesData — the numbers of the Olympian Republic's three shared rules
## (Act IV; GDD §15.0 "Act IV foundation (phase 1)", "Wrath of the Gods",
## "Phalanx" and "Glory"), each with ONE code path, inert on Acts I, II and III
## (Game.pantheon stays null there):
##   WRATH — DivineWrath: one scheduler of the gods' telegraphed hazards; the
##       stage's STAGE "wrath" dictionary picks the kind ("kind": waves /
##       lightning / fissures) and overrides any of that kind's keys below
##       ({} or absent keys = these defaults). Every strike hits BOTH armies
##       through CombatResolver: enemies, summons and the necromancer.
##   TWILIGHT — the Twilight of the Gods (the shared Act IV Reckoning hook): at
##       0:00 every wrath kind fires together, faster each minute; the
##       stage's RECKONING "twilight" dictionary overrides these keys
##       (absent = no twilight; the Titans are the RECKONING "kind").
##   PHALANX — Phalanx: "phalanx" kinds standing shoulder to shoulder lock
##       shields; hits from the front by projectiles are cut hard and cause no
##       knockback; the locked wall keeps one pace; a hit from the side or
##       behind breaks the lock for a moment.
##   GLORY — Glory: "hero" kinds gain a stack per summon they kill (damage and
##       size up, a gold aura) and pay a chest and a Soul Ash bounty when slain
##       with enough stacks.
##   SOUNDS — event -> sound id map (one place to switch the Pantheon pack in).
## Counter-passive hooks (NOT built in phase 1; AbilityManager.passive_value()
## returns 0 while no PassiveData row exists, so each hook is exactly 1):
##   GROUNDED_BONES — less lightning and wave damage to the army and the
##       necromancer (DivineWrath.grounded_mult(), the one read).
##   BRONZE_BREAKER — summon hits on a locked shield's front deal more
##       (Phalanx.breaker_mult(), the one read).
## Data only (CLAUDE.md rule 2). Every number is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name PantheonRulesData
extends RefCounted

# --- Wrath of the Gods (DivineWrath) ------------------------------------------------

## Wrath kinds, in the Twilight's order (STAGE "wrath" "kind" values).
const WRATH_KINDS: Array[String] = ["waves", "lightning", "fissures"]

## Defaults of each wrath kind (a stage's STAGE "wrath" overrides any key of its
## own kind; the Twilight uses the defaults of the other two).
## Shared keys:
##   first        — game time (s) of the first strike (its telegraph starts then).
##   interval     — s between two strikes (telegraph start to telegraph start).
##   telegraph    — s the warning shows before the hazard lands.
##   dmg_player   — damage to the necromancer (x the enemies' damage scaling).
##   dmg_summon   — damage to each summon (x the enemies' damage scaling).
##   dmg_enemy    — damage to each enemy (x the enemies' HP scaling, so it stays
##                  worth luring them in all run long).
## "waves" (Poseidon, Ilion): a wall of water rolls across the arena from one
## edge; it pushes everyone it crosses and drowns fodder.
##   drown_hp_mult — a drowned fodder takes this many times its max HP.
##   start_dist   — px from the necromancer (against the wave's heading) where
##                  the wall starts; it rolls 2 x this.
##   half_len     — px each side of the necromancer's line the wall reaches.
##   speed        — px/s the wall's front rolls.
##   band         — px depth of the water behind the front (bodies inside are carried).
##   push_speed   — px/s a body inside the band is carried; a body is carried
##                  band x push_speed / (speed - push_speed) px in all (~140).
## "lightning" (Zeus, Olympus): bolts on marked circles; a strike chains to
## bronze-clad enemies nearby.
##   count        — bolts per salvo (one always near the necromancer).
##   bronze_aim   — bolts of a salvo aimed at a bronze enemy near the
##                  necromancer when one exists (the lure), after the first.
##   near         — px from the necromancer the first bolt lands within.
##   scatter      — px around the necromancer the other bolts land within.
##   radius       — px of each bolt's circle.
##   chain_count  — most bronze enemies one strike chains to (hop by hop).
##   chain_range  — px of each hop.
##   chain_damage — damage of each chained hit (x the enemies' HP scaling).
## "fissures" (Hades, Underworld): red telegraph lines open into cracks that
## burn whoever stands on them, swallow corpses and spit shades.
##   count        — fissures per salvo (one always across the necromancer).
##   length       — px length of a fissure.
##   width        — px width of an open fissure (a body is on it within width / 2
##                  of its line, plus its own radius).
##   scatter      — px around the necromancer the other fissures open within.
##   open         — s a fissure stays open after its telegraph.
##   tick         — s between two burns of an open fissure.
##   spit_time    — s at the start of the opening during which it spits shades.
##   spit_every   — s between two shades.
##   spit_kind    — the kind it spits (the shared fodder).
##   first_scatter / min_scatter — px: the first crack opens within first_scatter
##                  of the necromancer, the others from min_scatter out to scatter.
##   swallow_body — share (0-1) of a body's radius that must lie on an open
##                  crack for its corpse to be swallowed.
const WRATH := {
	"waves": {
		"first": 60.0,  # TUNING (not in GDD) the first wave at 19:00 left
		"interval": 90.0,  # Owner-approved proposal: "every 90 s"
		"telegraph": 3.0,  # Owner-approved proposal: "shown 3 s ahead as a foam line"
		"start_dist": 520.0,  # TUNING (not in GDD) px, about the view's edge
		"half_len": 900.0,  # TUNING (not in GDD) px, wider than any view
		"speed": 420.0,  # TUNING (not in GDD) px/s
		"band": 80.0,  # TUNING (not in GDD) px
		"push_speed": 267.0,  # TUNING (not in GDD) px/s: 80 x 267 / (420 - 267) = ~140 px, the proposal's "about 140 px"
		"dmg_player": 4.0,  # TUNING (not in GDD) the push is the point, not the damage
		"dmg_summon": 5.0,  # TUNING (not in GDD) first pass 10: a quarter of the army bot's summon deaths on Ilion were waves
		"dmg_enemy": 18.0,  # TUNING (not in GDD)
		"drown_hp_mult": 10.0,  # TUNING (not in GDD) a drowned fodder takes this many times its max HP (killed outright)
	},
	"lightning": {
		"first": 30.0,  # TUNING (not in GDD)
		"interval": 6.0,  # TUNING (not in GDD) s between salvos
		"telegraph": 1.2,  # Owner-approved proposal: "1.2 s warning"
		"count": 3,  # TUNING (not in GDD)
		"bronze_aim": 1,  # TUNING (not in GDD) the storm favours bronze: luring a phalanx under it is the counterplay
		"near": 90.0,  # TUNING (not in GDD) px
		"scatter": 300.0,  # TUNING (not in GDD) px
		"radius": 44.0,  # TUNING (not in GDD) px
		"chain_count": 4,  # TUNING (not in GDD)
		"chain_range": 130.0,  # TUNING (not in GDD) px
		"chain_damage": 30.0,  # TUNING (not in GDD)
		"dmg_player": 9.0,  # TUNING (not in GDD)
		"dmg_summon": 16.0,  # TUNING (not in GDD)
		"dmg_enemy": 45.0,  # TUNING (not in GDD)
	},
	"fissures": {
		"first": 40.0,  # TUNING (not in GDD)
		"interval": 14.0,  # TUNING (not in GDD)
		"telegraph": 1.6,  # TUNING (not in GDD)
		"count": 2,  # TUNING (not in GDD)
		"length": 220.0,  # TUNING (not in GDD) px
		"width": 18.0,  # TUNING (not in GDD) px
		"scatter": 280.0,  # TUNING (not in GDD) px
		"open": 5.0,  # TUNING (not in GDD) s
		"tick": 0.5,  # TUNING (not in GDD) s
		"spit_time": 3.0,  # Owner-approved proposal: "spits pale shades for a few seconds"
		"spit_every": 1.0,  # TUNING (not in GDD) s
		"spit_kind": PantheonEnemyData.SHADE,
		"dmg_player": 3.0,  # TUNING (not in GDD) per burn tick
		"dmg_summon": 3.0,  # TUNING (not in GDD) per burn tick (first pass 5: the undead never step off, fissures were the army bot's top summon killer)
		"dmg_enemy": 10.0,  # TUNING (not in GDD) per burn tick
		"first_scatter": 30.0,  # TUNING (not in GDD) px: the salvo's first crack opens within this of the necromancer (across him)
		"min_scatter": 60.0,  # TUNING (not in GDD) px: the others open at least this far from him (up to "scatter")
		"swallow_body": 0.5,  # TUNING (not in GDD) share (0-1) of a body's radius that must lie on an open crack for its corpse to be swallowed
	},
}

## Most pending / open hazards of each kind at once (a strike asked beyond it
## waits for the next turn; keeps the Twilight's late minutes bounded).
const WRATH_CAPS := {
	"waves": 3,  # TUNING (not in GDD)
	"lightning": 40,  # TUNING (not in GDD) bolts
	"fissures": 16,  # TUNING (not in GDD)
}

## px added to a hazard's summon query (the widest summon body beyond the
## hazard's own reach: the Golem / Colossus).
const SUMMON_SLACK: float = 34.0  # TUNING (not in GDD) px

## The autotest bot's push off a telegraphed bolt circle or fissure line:
## px of reach beyond the hazard's own radius / half-width.
const DANGER_REACH: float = 14.0  # TUNING (not in GDD) px

## The future Act IV counter-passive Grounded Bones (owner-approved proposal; NOT
## built in phase 1): PassiveData row GROUNDED_BONES's level value
## GROUNDED_BONES_KEY is the fraction of lightning and wave damage the army and
## the necromancer no longer take (DivineWrath.grounded_mult(): 1 - value).
const GROUNDED_BONES: String = "grounded_bones"
## Level-row key of Grounded Bones's damage cut (fraction 0..1).
const GROUNDED_BONES_KEY: String = "wrath_reduction"

# --- The Twilight of the Gods (the shared Act IV Reckoning hook) ---------------------

## After 0:00, on a stage whose RECKONING has a "twilight" dictionary (its keys
## override these): every wrath kind fires (its own defaults, the stage's own
## kind with the stage's overrides), each on interval x interval_mult x
## speedup ^ (minutes past 0:00), never under interval x interval_min_mult.
##   kinds          — the wrath kinds that fire together.
##   interval_mult  — x each kind's interval at 0:00.
##   speedup        — x the interval for every minute past 0:00 ("faster each minute").
##   interval_min_mult — the fastest, x each kind's interval.
##   first_delay    — s after 0:00 each kind first strikes (in kind order, x its index).
const TWILIGHT := {
	"kinds": ["waves", "lightning", "fissures"],  # Owner-approved proposal: "lightning, waves and fissures fire together"
	"interval_mult": 0.5,  # TUNING (not in GDD)
	"speedup": 0.75,  # TUNING (not in GDD)
	"interval_min_mult": 0.15,  # TUNING (not in GDD)
	"first_delay": 1.5,  # TUNING (not in GDD) s
}

# --- Phalanx (Phalanx) ----------------------------------------------------------------

## Shield walls.
##   lock_count        — phalanx bodies that must stand together to lock
##                       (owner-approved proposal: "3+").
##   lock_range        — px between two bodies' centres to count as shoulder to
##                       shoulder (owner-approved proposal: "within 28 px").
##   facing_half_angle — rad: two bodies face "the same way" when their facings
##                       differ by at most this.
##   turn_rate         — rad/s a Pantheon kind turns its facing toward the
##                       necromancer it advances on (PantheonKit).
##   front_half_angle  — rad each side of the facing that counts as the FRONT
##                       (PantheonRules.hit_from_front(), the one direction test).
##   front_shot_mult   — damage share of a projectile hit on a locked front
##                       ("stopped or heavily reduced").
##   break_time        — s a wall stays unlocked after a hit from the side or
##                       behind (every member of the broken wall).
##   check_every       — s between two lock checks (shield walls form and break
##                       on this rhythm; the pace and the drawing follow it).
const PHALANX := {
	"lock_count": 3,  # Owner-approved proposal: "3+ within 28 px"
	"lock_range": 28.0,  # Owner-approved proposal: px
	"facing_half_angle": 0.6,  # TUNING (not in GDD) rad (~34 degrees)
	"turn_rate": 2.4,  # TUNING (not in GDD) rad/s
	"front_half_angle": 1.05,  # TUNING (not in GDD) rad (~60 degrees each side: a 120-degree front)
	"front_shot_mult": 0.1,  # TUNING (not in GDD) 90% of a frontal shot stopped
	"break_time": 1.6,  # TUNING (not in GDD) s ("break the lock for a moment")
	"check_every": 0.2,  # TUNING (not in GDD) s (5 Hz, the AI's think rate)
}

## The future Act IV counter-passive Bronze Breaker (owner-approved proposal; NOT
## built in phase 1): PassiveData row BRONZE_BREAKER's level value
## BRONZE_BREAKER_KEY is the extra share summon hits on a locked shield's front
## deal (Phalanx.breaker_mult(): 1 + value).
const BRONZE_BREAKER: String = "bronze_breaker"
## Level-row key of Bronze Breaker's bonus (fraction).
const BRONZE_BREAKER_KEY: String = "front_damage"

# --- Glory (Glory) ----------------------------------------------------------------------

## Heroes' Glory.
##   max_stacks       — most stacks (owner-approved proposal: "up to 10").
##   damage_per_stack — extra share of damage per stack (Enemy.hit_mult();
##                      owner-approved proposal: "+10% damage").
##   size_per_stack   — extra share of body radius and drawn size per stack
##                      (owner-approved proposal: "+10% size").
##   chest_stacks     — stacks at which a slain hero drops a chest (owner-
##                      approved proposal: "at 5+ stacks, a chest").
##   ash_per_stack    — Soul Ash bounty per stack of a slain hero (the run's
##                      "objective_ash", the existing Soul Ash path).
##   banner_stacks    — stacks at which the HUD banner names the hero.
const GLORY := {
	"max_stacks": 10,  # Owner-approved proposal
	"damage_per_stack": 0.1,  # Owner-approved proposal
	"size_per_stack": 0.1,  # Owner-approved proposal
	"chest_stacks": 5,  # Owner-approved proposal
	"ash_per_stack": 2,  # TUNING (not in GDD) Soul Ash (a Sentry Turret pays 5, Valkyrie 2.0 12)
	"banner_stacks": 5,  # TUNING (not in GDD)
}

# --- Sounds ---------------------------------------------------------------------------

## Pantheon event -> sound id played for it (Sfx.play(); an id that is not
## rendered is a silent no-op). They are the Pantheon pack (SoundData.PANTHEON_SOUNDS), rendered lazily when
## the "bronze" music starts; Sfx.play() skips a pack sound that is not ready.
const SOUNDS := {
	"wave": "wrath_wave",  # SoundData.PANTHEON_SOUNDS (lazy pack, loaded with the "bronze" music)
	"thunder": "wrath_thunder",  # SoundData.PANTHEON_SOUNDS (lazy pack, loaded with the "bronze" music)
	"fissure": "wrath_fissure",  # SoundData.PANTHEON_SOUNDS (lazy pack, loaded with the "bronze" music)
	"shield_lock": "shield_lock",  # SoundData.PANTHEON_SOUNDS (lazy pack, loaded with the "bronze" music)
	"shield_break": "shield_break",  # SoundData.PANTHEON_SOUNDS (lazy pack, loaded with the "bronze" music)
	"glory": "glory_gain",  # SoundData.PANTHEON_SOUNDS (lazy pack, loaded with the "bronze" music)
	"hoplite_step": "hoplite_step",  # SoundData.PANTHEON_SOUNDS; reserved: nothing plays it yet (phase 2: a throttled march step for a locked wall)
	"titan_rise": "titan_rise",  # SoundData.PANTHEON_SOUNDS (lazy pack, loaded with the "bronze" music)
}
