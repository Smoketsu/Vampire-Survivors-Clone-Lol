## ConcordRulesData — the numbers of the Concord of Stars' shared rules (Act IX;
## GDD §15.0 "Act IX foundation (phase 1)", "Beams", "Abduction",
## "Terraforming" and "The Final Harvest"), each with ONE code path, inert on
## Acts I to VIII (Game.concord stays null there):
##   BEAMS / BEAM_STYLES — ConcordBeams: every Concord weapon is a continuous
##       beam: a thin magenta aiming line, then a beam that holds and sweeps,
##       cutting through every summon and necromancer on its line (the Bone
##       Ring does not block it). Orb Shields and Warder / Bishop barriers
##       reflect it back along its line into its firer's side; a Prism splits
##       it into three. At most `cap` beams at once (a boss override more).
##   ABDUCTION — Abduction: saucers lift a summon in a tractor beam and hold it;
##       shoot the saucer down in time and it drops back, else it is gone until
##       the next replenish. At most `cap` summons held at once.
##   TERRAFORMING — Terraforming: landing pods root and grow alien ground; the
##       ground heals Concord units standing on it; the necromancer's spells
##       burn it back.
##   FINAL_HARVEST — the shared Act IX Reckoning hook (a stage's RECKONING
##       "final_harvest" dictionary overrides these keys; absent = off): the
##       mothership's eye opens over the arena and sweeps it with its beam, and
##       the abduction cap is gone.
##   RACES — the four races of the coalition (row key "race"; the Codex and
##       the report group by it).
##   SOUNDS — event -> sound id map (one place to switch the Concord pack in).
## Counter-passive hooks (NOT built in phase 1; AbilityManager.passive_value()
## returns 0 while no PassiveData row exists, so each hook is exactly 1 / false):
##   MIRROR_BONES — reflected beams deal more, summons take less beam damage
##       (ConcordRules.mirror_reflect_mult() / mirror_taken_mult()).
##   ANCHORED — abductions last half as long and break when the saucer takes
##       damage (ConcordRules.anchored_hold_mult() / anchored_breaks()).
## Data only (CLAUDE.md rule 2). Every number is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name ConcordRulesData
extends RefCounted

# --- The races ----------------------------------------------------------------------------

## Race ids in Codex / report order (the Fixed names; row key "race"). The race
## id is plural "harvesters", so it never reads as the boss id "harvester".
const RACES: Array[String] = ["brood", "harvesters", "vrask", "luminous"]
## Race id -> its display name (the report, the Codex headers).
const RACE_NAMES := {
	"brood": "The Brood",  # Owner-approved proposal
	"harvesters": "The Harvesters",  # Owner-approved proposal
	"vrask": "The Vrask",  # Owner-approved proposal
	"luminous": "The Luminous",  # Owner-approved proposal
}

# --- Beams (ConcordBeams) -----------------------------------------------------------------

## Beams (the shared numbers; each style's own in BEAM_STYLES).
##   cap            — most beams at once (owner-approved proposal: "At most 6
##                    beams at once"); a beam asked beyond it is refused and
##                    counted (the kit retries after `retry` s).
##   boss_cap       — most beams at once with a boss override (the Final
##                    Harvest's eye, phase 2's bosses), as LockOn's boss lines.
##   retry          — s a kit waits before it asks again after a refusal.
##   lock_time      — s at the end of the aim during which the line stops
##                    turning (brief: "it tracks its target, then stops
##                    turning for the last 0.3 s").
##   track_rate     — rad/s the aiming line turns toward its target.
##   muzzle         — px from the firer's centre the beam leaves.
##   prism_angle    — degrees each side a prism's outer split beams leave at
##                    (brief: +-25 degrees).
##   prism_radius   — px of a prism's body the line must pass within to split
##                    (on top of the beam's half width).
##   reflect_dps    — damage per second a reflected beam deals to each enemy on
##                    its line, x the enemies' HP scaling (EnemyDirector
##                    .hp_mult, so it keeps pace with the enemies it hits) and
##                    x Mirror Bones.
##   orb_slack      — px added to an orb's reach when the line is tested
##                    against it.
##   summon_slack   — px added to a grid query around a beam's segment.
##   danger_reach   — px from an aiming line within which the autotest bot
##                    steps sideways out of it.
##   aim_alpha      — opacity of an aiming line (drawing only).
const BEAMS := {
	"cap": 6,  # Owner-approved proposal: "At most 6 beams at once"
	"boss_cap": 12,  # TUNING (not in GDD) as LockOn's boss_max_lines
	"retry": 0.6,  # TUNING (not in GDD) s
	"lock_time": 0.3,  # TUNING (not in GDD) brief: stops turning for the last 0.3 s
	"track_rate": 2.2,  # TUNING (not in GDD) rad/s
	"muzzle": 10.0,  # TUNING (not in GDD) px
	"prism_angle": 25.0,  # TUNING (not in GDD) brief: +-25 degrees
	"prism_radius": 10.0,  # TUNING (not in GDD) px
	"reflect_dps": 12.0,  # TUNING (not in GDD) x EnemyDirector.hp_mult (first pass 30: 105k reflected damage in the seed-7 Crash Site army run)
	"orb_slack": 2.0,  # TUNING (not in GDD) px
	"summon_slack": 24.0,  # TUNING (not in GDD) px
	"danger_reach": 26.0,  # TUNING (not in GDD) px
	"aim_alpha": 0.6,  # TUNING (not in GDD)
}
## Beam styles (ConcordBeams.fire()'s `style`; a call's `overrides` may replace
## any key):
##   aim     — s of the thin aiming line (owner-approved proposal: "a thin
##             aiming line for 1 s").
##   hold    — s the beam holds (owner-approved proposal: "about 1.5 s").
##   sweep   — degrees the beam turns while it holds (its side from the
##             firer's think slot, no RNG).
##   length  — px of the beam from its muzzle.
##   width   — px of the beam (its hit band; drawn at this width).
##   dps     — damage per second to each body on the line, before the time
##             scaling (x the firer's damage scaling; x its undead mult on a
##             summon).
##   tick    — s between two damage ticks (each body at most once a tick).
##   dots    — true: the Vrask lock's three red dots on the target during the
##             aim instead of the line (drawing; the aim still tracks).
const BEAM_STYLES := {
	# The grey drones' probe: short, thin, little sweep.
	"probe": {"aim": 1.0, "hold": 0.8, "sweep": 10.0, "length": 150.0, "width": 6.0, "dps": 3.5, "tick": 0.2, "dots": false},  # TUNING (not in GDD) aim: owner-approved proposal (1 s)
	# The Vrask hunter's lock: three red dots on the target for the aim, then a 0.15 s pulse.
	"lock": {"aim": 1.0, "hold": 0.15, "sweep": 0.0, "length": 300.0, "width": 8.0, "dps": 50.0, "tick": 0.15, "dots": true},  # TUNING (not in GDD) brief: a 0.15 s pulse
	# The Lumen Sentinel's sweep: the proposal's beam.
	"sweep": {"aim": 1.0, "hold": 1.5, "sweep": 45.0, "length": 260.0, "width": 10.0, "dps": 3.5, "tick": 0.25, "dots": false},  # TUNING (not in GDD) aim / hold: owner-approved proposal (1 s, about 1.5 s); first pass dps 6 (sentinels wiped the seed-7 army at 9:00)
	# The Final Harvest's eye: long enough to cross the view, sweeping across the necromancer.
	"eye": {"aim": 1.5, "hold": 2.4, "sweep": 60.0, "length": 1700.0, "width": 26.0, "dps": 10.0, "tick": 0.25, "dots": false},  # TUNING (not in GDD)
}
## Damage tag of a reflected beam (CombatResolver.damage_enemy() source).
const REFLECT_SOURCE: String = "beam_reflect"
## Damage tag of the Final Harvest's eye beam.
const EYE_SOURCE: String = "mothership_eye"

# --- Abduction (Abduction) ----------------------------------------------------------------

## Abduction.
##   hold             — s a lifted summon is held before it is taken
##                      (owner-approved proposal: "held for 8 s").
##   cap              — most summons held at once across both armies
##                      (owner-approved proposal: "capped at 3 summons held at
##                      once"); the Final Harvest lifts it.
##   windup           — s of the tractor cone on the ground before the lift
##                      (brief: 1.0).
##   lift_max_radius  — px: a summon with a larger body is too heavy to lift
##                      (the Abomination 16, the Golem 18 and the Colossus are;
##                      brief: TUNING).
##   lift_px          — px the lifted summon hangs below the saucer's centre.
##   rise_time        — s the summon takes to rise from the ground to the saucer.
##   renew            — s each carry() renews the hold (it lapses on its own if
##                      the saucer stops renewing it).
##   drop_daze        — s a dropped summon stays held after a rescue (as the
##                      Chiropteran King's drop).
##   cone_width       — px half width of the tractor cone's foot (drawing).
const ABDUCTION := {
	"hold": 8.0,  # Owner-approved proposal: "held for 8 s"
	"cap": 3,  # Owner-approved proposal: "capped at 3 summons held at once"
	"windup": 1.0,  # TUNING (not in GDD) brief: 1.0 s tractor cone
	"lift_max_radius": 14.0,  # TUNING (not in GDD) px (Abomination 16, Golem 18 too heavy)
	"lift_px": 18.0,  # TUNING (not in GDD) px
	"rise_time": 0.8,  # TUNING (not in GDD) s
	"renew": 0.2,  # TUNING (not in GDD) s
	"drop_daze": 0.6,  # TUNING (not in GDD) s
	"cone_width": 16.0,  # TUNING (not in GDD) px
}
## Damage / stun tag of an abduction (CombatResolver.stun_unit() source).
const ABDUCTION_SOURCE: String = "abduction"

# --- Terraforming (Terraforming) ----------------------------------------------------------

## Terraforming.
##   cell           — px side of a ground cell (brief: 64).
##   active_radius  — px around a standing necromancer within which cells are
##                    drawn and simulated (pods grow, units heal).
##   max_cells      — most live cells at once (the oldest go first).
##   grow_time      — s a newly grown cell takes to go live (it shows growing).
##   start_at       — game s of the first pod.
##   pod_every      — s between two pods at 0:00 of elapsed time ...
##   pod_every_step — ... minus this many s each minute ...
##   pod_every_min  — ... down to this.
##   pod_min / pod_max — px from a standing necromancer a pod lands (seeded).
##   max_pods       — most pods alive at once.
##   pod_warn       — s of the pod's telegraphed streak before it lands (brief: 1.5).
##   pod_radius     — px a pod's patch grows to.
##   spread_every   — s between two rings of a live pod's patch.
##   tick           — s between two heal ticks.
##   heal_frac      — share of its max HP a Concord unit standing on live turf
##                    heals per second.
##   boss_mult      — x the heal of a boss or miniboss (0 by default; a stage
##                    may raise it).
##   burn_radius    — px around the enemy a spell hit that burns the ground.
##   burn_cap       — most burns a tick (a big area spell stays cheap).
##   regrow_delay   — s a burnt cell stays scorched; nothing grows into it.
##   scorch_fade    — s a scorched cell takes to fade once its delay is over
##                    (drawing only).
##   shimmer_rise   — px the green heal shimmer rises over a healed unit
##                    (drawing only).
##   shimmer_time   — s the heal shimmer shows after a heal (drawing only).
const TERRAFORMING := {
	"cell": 64.0,  # TUNING (not in GDD) brief: 64 px cells
	"active_radius": 900.0,  # TUNING (not in GDD) px
	"max_cells": 260,  # TUNING (not in GDD)
	"grow_time": 1.2,  # TUNING (not in GDD) s
	"start_at": 40.0,  # TUNING (not in GDD) s
	"pod_every": 55.0,  # TUNING (not in GDD) s
	"pod_every_step": 1.5,  # TUNING (not in GDD) s less each minute
	"pod_every_min": 30.0,  # TUNING (not in GDD) s
	"pod_min": 220.0,  # TUNING (not in GDD) px
	"pod_max": 420.0,  # TUNING (not in GDD) px
	"max_pods": 3,  # TUNING (not in GDD)
	"pod_warn": 1.5,  # TUNING (not in GDD) brief: a telegraphed streak (1.5 s)
	"pod_radius": 224.0,  # TUNING (not in GDD) px (3.5 cells)
	"spread_every": 4.0,  # TUNING (not in GDD) s per ring
	"tick": 0.5,  # TUNING (not in GDD) s
	"heal_frac": 0.03,  # TUNING (not in GDD) 3% of max HP a second
	"boss_mult": 0.0,  # TUNING (not in GDD) brief: 0 by default
	"burn_radius": 56.0,  # TUNING (not in GDD) px
	"burn_cap": 12,  # TUNING (not in GDD) burns a tick
	"regrow_delay": 20.0,  # TUNING (not in GDD) s
	"scorch_fade": 2.0,  # TUNING (not in GDD) s
	"shimmer_rise": 10.0,  # TUNING (not in GDD) px (drawing)
	"shimmer_time": 0.6,  # TUNING (not in GDD) s (drawing)
}
## Kind id of the landing pod that roots and grows alien ground (a structure row).
const TERRAFORMER: String = "concord_terraformer"

# --- The Final Harvest (FinalHarvest) ----------------------------------------------------

## The Final Harvest (a stage's RECKONING "final_harvest" dictionary overrides
## any key; absent = off).
##   eye_first      — s after 0:00 of the first eye beam.
##   eye_every      — s between two eye beams at the start ...
##   eye_every_step — ... minus this many s each minute past 0:00 ...
##   eye_every_min  — ... down to this.
##   eye_offset     — px from the necromancer the eye beam's origin hangs (off
##                    screen; a seeded angle each beam).
##   fade_in        — s the sky overlay takes to open (drawing only).
##   overlay_alpha  — opacity of the open sky overlay (drawing only).
##   overlay_px     — px wide the sky overlay is drawn at zoom 1 (drawing only).
const FINAL_HARVEST := {
	"eye_first": 3.0,  # TUNING (not in GDD) s
	"eye_every": 9.0,  # TUNING (not in GDD) s
	"eye_every_step": 1.5,  # TUNING (not in GDD) s less each minute
	"eye_every_min": 4.0,  # TUNING (not in GDD) s
	"eye_offset": 760.0,  # TUNING (not in GDD) px
	"fade_in": 2.5,  # TUNING (not in GDD) s
	"overlay_alpha": 0.55,  # TUNING (not in GDD)
	"overlay_px": 520.0,  # TUNING (not in GDD) px
}

# --- Sounds -------------------------------------------------------------------------------

## Concord event -> sound id. FOR NOW each event points at an EXISTING sound
## (the startup bank, or the City pack the stubs' "siren" music loads); the
## intended Concord pack id (SoundData.CONCORD_SOUNDS, the audio pass) is in
## the comment: the lead repoints each event to it at the merge. An id that is
## not rendered is skipped silently by Sfx.play().
const SOUNDS := {
	"beam_charge": "boss_telegraph",  # Intended: "beam_charge" (a thin rising whine: the aiming line).
	"beam_fire": "bolt_cast",  # Intended: "beam_fire" (a held, buzzing laser tone).
	"beam_reflect": "orb_block",  # Intended: "beam_reflect" (a bright glassy ping with a reversed tail).
	"tractor_beam": "banshee_wail",  # Intended: "tractor_beam" (a low, wobbling hum).
	"abduction": "gargoyle_takeoff",  # Intended: "abduction" (a rising whoosh that thins out).
	"saucer_down": "vehicle_wreck",  # Intended: "saucer_down" (a sputtering electric crash).
	"ground_burn": "plague_tick",  # Intended: "ground_burn" (a soft sizzle and hiss).
	"brood_chitter": "enemy_hit",  # Intended: "brood_chitter" (a short insect clicking).
	"harvest_eye": "reckoning",  # Intended: "harvest_eye" (a deep opening groan and a low horn).
}

# --- Counter-passive hooks (not built) -----------------------------------------------------

## PassiveData id of Mirror Bones (the future Act IX counter-passive: reflected
## beams deal more and summons take less beam damage). Not built in phase 1.
const MIRROR_BONES: String = "mirror_bones"
## Its value key: the share reflected beams deal MORE (0 while not owned).
const MIRROR_REFLECT_KEY: String = "reflect_damage"
## Its value key: the share of beam damage summons do NOT take (0 while not owned).
const MIRROR_TAKEN_KEY: String = "beam_reduction"
## PassiveData id of Anchored (the future Act IX counter-passive: abductions
## last half as long and break when the saucer takes damage). Not built.
const ANCHORED: String = "anchored"
## Its value key: the share of the hold removed (0 while not owned; 0.5 when built).
const ANCHORED_KEY: String = "hold_cut"
