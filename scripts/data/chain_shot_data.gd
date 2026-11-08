## ChainShotData — the fixed rules of the Chain Shot spell (AbilityData
## "chain_shot"; Act X, the Smuggler's Cutter; GDD §15.0 "Chain Shot,
## Keelhauler, Bosun's Whistle and the Marooned Quartermaster (Act X)";
## owner-approved proposal: "a spectral chain-shot spins through a line of
## enemies and returns"). The per-level numbers live in the AbilityData row and
## the Keelhauler EvolutionData row; these are the rules that never level. No
## logic here.
class_name ChainShotData
extends RefCounted

## Spell id (AbilityData.SPELLS key).
const ID: String = "chain_shot"
## Damage source tag of a Chain Shot hit (stats dmg_chain_shot).
const SOURCE: String = "chain_shot"
## Damage source tag of a Keelhauler hit (stats dmg_keelhauler).
const EVOLVED_SOURCE: String = "keelhauler"
## PassiveData id of its paired passive, Bosun's Whistle.
const WHISTLE: String = "bosuns_whistle"
## Bosun's Whistle's value key: the share cut off Chain Shot's cooldown (0..1;
## 0 while not owned).
const WHISTLE_KEY: String = "cooldown_cut"
## CharacterData innate value key of the Marooned Quartermaster's Spare Shot
## (extra chain-shots a cast).
const EXTRA_KEY: String = "chain_extra"
## Most chain-shots in flight at once (a cap on the pooled array).
const MAX_SHOTS: int = 12  # TUNING (not in GDD)
## Foes looked at when a cast picks its lines (the nearest first).
const TARGET_SAMPLES: int = 24  # TUNING (not in GDD)
## px between two shots' targets in one cast (spread over different foes).
const LINE_APART: float = 60.0  # TUNING (not in GDD)
## Seconds the shot hangs at the far end of its throw before it spins home.
const TURN_TIME: float = 0.08  # TUNING (not in GDD)
## px from the necromancer at which a returning shot is caught (it ends).
const CATCH_RADIUS: float = 16.0  # TUNING (not in GDD)
## Radians a chain-shot spins per second (drawing only).
const SPIN: float = 18.0  # TUNING (not in GDD) visual
## px between the two balls of a chain-shot (drawing only).
const BALL_SPREAD: float = 7.0  # TUNING (not in GDD) visual
