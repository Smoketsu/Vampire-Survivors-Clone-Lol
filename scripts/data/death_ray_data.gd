## DeathRayData — the fixed rules of the Death Ray spell and its evolution
## Event Horizon (Act III, the Scrap Wastes; owner-approved Act III proposal
## "Rewards"; GDD §15.0 "Death Ray, Conductive Marrow and the Lightning
## Abbess"). The levelled numbers live in AbilityData.SPELLS "death_ray" and
## EvolutionData.EVOLUTIONS "event_horizon"; these are the rules that do not
## level. Logic: DeathRay. Data only (CLAUDE.md rule 2).
class_name DeathRayData
extends RefCounted

## Seconds before the first sweep once the spell is learned.
const FIRST_SWEEP: float = 0.6  # TUNING (not in GDD)
## Least seconds between the end of one sweep and the start of the next.
const MIN_GAP: float = 0.25  # TUNING (not in GDD)
## The beam waits for a foe this many px past its length before it sweeps
## (else it retries every AbilityData.SPELL_RETRY s).
const TRIGGER_SLACK: float = 0.0  # TUNING (not in GDD)
## Least distance (px) used for the beam's angular hit test (a foe touching the
## necromancer is struck when the beam passes over it).
const MIN_HIT_DIST: float = 8.0  # TUNING (not in GDD)
## Most lightning arcs drawn at once (older ones are dropped; drawing only).
const ARC_MAX: int = 28  # TUNING (not in GDD)
## Seconds a drawn lightning arc stays visible (drawing only).
const ARC_TIME: float = 0.2  # TUNING (not in GDD)
## Most beam kills per tick that spark lightning (a big swarm cut at once
## sparks at most this many; the rest just die).
const SPARKS_PER_TICK: int = 8  # TUNING (not in GDD)
## Angle (rad) of the fading afterglow drawn behind each beam (drawing only).
const TRAIL_ANGLE: float = 0.45  # TUNING (not in GDD)
## Beam colours (the player's violet soul laser; drawing only).
const GLOW := Color(0.64, 0.36, 0.98)  # TUNING (not in GDD) Palette.VIOLET
## The beam's white-hot core (drawing only).
const CORE := Color(0.87, 0.74, 1.0)  # TUNING (not in GDD) violet_flare
## Sound pitch of the sweep's hum (Sfx "bolt_cast"; audio only).
const SWEEP_PITCH: float = 0.55  # TUNING (not in GDD)
## Sound pitch of a spark (Sfx "bolt_cast"; audio only).
const SPARK_PITCH: float = 1.5  # TUNING (not in GDD)
