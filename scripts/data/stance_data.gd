## StanceData — the army formation (GDD §15.0 "Bone Ring is the only formation"). The
## owner (Oct 2026) liked the formations but wanted them to hit harder, and chose one
## formation for every run: the **Bone Ring**. The army stands on a closed circle around
## the necromancer (blockers, flankers and ranged units on the ring, priests and siege
## artillery inside) and its volleys (VolleyData) fly outward in every direction. There
## is no switching any more: no stance keys, stick flicks, HUD stance bar, touch stance
## rose or Spearhead unlock (its Soul Ash is refunded, MetaProgress).
## The formation is only a set of OVERRIDES on numbers the horde AI already uses; no unit
## gets new behaviour code:
##   * the formation post shape (StanceFormations, called by
##     HordeDirector._calculate_formation_anchors()),
##   * the engagement / chase distance and the soft recall, both still scaled by Bound
##     Souls in HordeDirector.compute_stats(),
##   * the formation pull (w_formation multiplier).
## The hard recall (UnitData.HARD_RECALL) never changes: it is the safety net.
## The optional flavour bonus exists as data but is OFF (BONUSES_ENABLED false); it
## already flows through the single path (CombatResolver for damage taken).
## No logic here (ArmyStance owns the per-run state, StanceFormations the shape).
class_name StanceData
extends RefCounted

## The one formation id (kept as a list so the per-formation summary code stays generic).
const ORDER := ["bone_ring"]
## Formation the army holds in every run.
const DEFAULT_ID: String = "bone_ring"

## Formation definitions.
##   display_name    — UI name.
##   description     — one-line description.
##   shape           — formation shape ("ring", StanceFormations).
##   engage_radius   — px; chase / engagement leash from the necromancer, times Bound
##                     Souls: the ring fights what reaches it and a little beyond.
##   soft_recall     — px; beyond it a unit drops its target and RETURNs, times Bound Souls.
##   formation_pull  — multiplier on every class's w_formation.
##   jitter          — multiplier on UnitData.FORMATION_JITTER_ANGLE (lower = a crisper ring).
##   bonus           — flavour bonus applied only while BONUSES_ENABLED:
##                     damage_taken_reduction (fraction off army damage taken).
const STANCES := {
	"bone_ring": {"display_name": "Bone Ring",
		"description": "Your army rings you in bone and fires outward in every direction.",
		"shape": "ring",
		"engage_radius": 210.0,  # TUNING (not in GDD) the ring (up to RING_MAX) plus ~60 px of reach
		"soft_recall": UnitData.SOFT_RECALL,  # GDD §24 (unchanged)
		"formation_pull": 1.0,  # TUNING (not in GDD)
		"jitter": 0.15,  # TUNING (not in GDD) evenly spaced posts
		"bonus": {"damage_taken_reduction": 0.10}},  # TUNING (not in GDD) owner proposal -10% army damage taken (off while BONUSES_ENABLED is false)
}

## Master switch of the flavour bonus above (owner decision: no stat bonuses at first;
## a later balance pass may switch it on).
const BONUSES_ENABLED: bool = false  # TUNING (not in GDD) owner decision: off

# --- The ring (StanceFormations; px from the necromancer) --------------------------------

## Smallest ring radius.
const RING_MIN: float = 60.0  # TUNING (not in GDD) owner proposal
## Largest ring radius: past it the ring stands two deep (alternate posts step inward by
## RING_LAYER), so a big army stays a ring instead of a crowd.
const RING_MAX: float = 150.0  # TUNING (not in GDD) first look: 90 px crammed a 45-unit army into a blob
## Arc length (px) each ring post needs: the ring radius is posts x this / TAU (within
## RING_MIN..RING_MAX), so a small army closes a small circle and a big one a wide circle.
const RING_SPACING: float = 24.0  # TUNING (not in GDD) about one body width plus a gap
## The ring radius also keeps this much room per unit inside it (priests, siege), from
## RING_MIN up.
const RING_PER_INNER: float = 3.0  # TUNING (not in GDD)
## Ring posts sit within +/- this many px of the ring radius.
const RING_DEPTH: float = 6.0  # TUNING (not in GDD)
## An overfull ring (more posts than fit at RING_MAX): every second post steps this many
## px inward (a two-deep ring).
const RING_LAYER: float = 22.0  # TUNING (not in GDD)
## Inner units keep at least this far inside the ring.
const RING_INNER_GAP: float = 30.0  # TUNING (not in GDD)
## Inner units never closer to the necromancer than this.
const RING_INNER_MIN: float = 24.0  # TUNING (not in GDD)

# --- Autotest ------------------------------------------------------------------------

## Seconds between two army-spread samples (autotest formation line).
const SPREAD_SAMPLE: float = 0.25  # TUNING (not in GDD)


## Definition of formation `id` (the ring for an unknown id).
static func def(id: String) -> Dictionary:
	return STANCES.get(id, STANCES[DEFAULT_ID])
