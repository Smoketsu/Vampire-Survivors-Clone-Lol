## UndertowData — the fixed rules of the UNDERTOW spell and its evolution
## MAELSTROM (Act II, GDD §15.0 "Gullhaven Harbour (Act II phase 2)";
## owner-approved "Unlockable spells and passives": the necromancer steals the
## Ancient Eye's own tide magic). The per-level numbers are the spell's
## AbilityData.SPELLS "undertow" row and the evolution's EvolutionData
## "maelstrom" row (one modifier path, AbilityManager.spell_stats()); these are
## the numbers that never level. Logic: scripts/abilities/spells/undertow.gd.
## Unlocked by slaying Abbot Merrow (UnlockData, boss "merrow"); its paired
## passive Salt of the Deep (PassiveData) is unlocked with it.
## Every number is TUNING (not in GDD) unless marked owner-approved.
class_name UndertowData
extends RefCounted

## Half the wave's cone (rad): owner-approved "a 120° cone".
const CONE_HALF_ANGLE: float = PI / 3.0  # owner-approved 120 degrees in all
## Every Nth wave leaves shallow water (owner-approved "every third wave");
## the Brine Widow's Riptide innate lowers it (CharacterData
## "undertow_shallows_every").
const SHALLOWS_EVERY: int = 3  # owner-approved
## Radius (px) of the shallow-water patch a wave leaves, as a share of the
## wave's range (centred SHALLOWS_AT of the range out along the aim).
const SHALLOWS_RADIUS_SHARE: float = 0.45  # TUNING (not in GDD)
## Where the patch lies along the aim, as a share of the wave's range.
const SHALLOWS_AT: float = 0.6  # TUNING (not in GDD)
## Seconds a shallow-water patch lies on the ground.
const SHALLOWS_LIFE: float = 4.0  # TUNING (not in GDD)
## Seconds between two slows of the enemies standing in a patch.
const SHALLOWS_TICK: float = 0.4  # TUNING (not in GDD)
## Most shallow-water patches at once (the oldest dries up first).
const SHALLOWS_MAX: int = 6  # TUNING (not in GDD)
## A wave is only cast while an enemy is within its range plus this many px
## (else the spell retries every AbilityData.SPELL_RETRY s).
const TRIGGER_MARGIN: float = 30.0  # TUNING (not in GDD)
## Aim assist (rad around the walking direction): the wave rolls at the
## nearest enemy inside this cone, else at the nearest enemy (like Bone Spear).
const AIM_CONE: float = 0.7  # TUNING (not in GDD)
## Seconds the drawn wave takes to roll out (purely visual: the hit is instant).
const WAVE_TIME: float = 0.35  # TUNING (not in GDD)
## Most drawn waves at once (purely visual).
const WAVE_MAX: int = 6  # TUNING (not in GDD)
## Maelstrom: most whirlpools at once (the oldest collapses first).
const WHIRL_MAX: int = 3  # TUNING (not in GDD)
## Maelstrom: drag radius of a whirlpool, as a multiple of its grind radius.
const WHIRL_DRAG_RADIUS_MULT: float = 2.4  # TUNING (not in GDD)
## Maelstrom: a dragged enemy stops this many px from the whirlpool's centre.
const WHIRL_KNOT: float = 10.0  # TUNING (not in GDD)
## Maelstrom: slow (fraction) on bosses and minibosses in a whirlpool (they are
## slowed, never dragged: owner-approved), refreshed every grind tick.
const WHIRL_BOSS_SLOW: float = 0.4  # TUNING (not in GDD)
## Colours (purely visual): the wave's crest, its foam, the shallows.
const WAVE_COLOR := Color(0.36, 0.62, 0.78)  # TUNING (not in GDD) the necromancer's stolen tide (cool blue, apart from the Eye's teal)
const FOAM_COLOR := Color(0.86, 0.92, 0.96)  # TUNING (not in GDD)
const SHALLOWS_COLOR := Color(0.20, 0.36, 0.52, 0.32)  # TUNING (not in GDD)
const WHIRL_COLOR := Color(0.48, 0.30, 0.78)  # TUNING (not in GDD) violet: the player's colour in the maelstrom's heart
