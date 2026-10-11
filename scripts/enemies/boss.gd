## Boss — the shared base of every stage boss (Sir Alaric in the Graveyard,
## Marshal Vael on the Crimson March). It extends Enemy, so summons, spells,
## the spatial hash and the combat resolver treat a boss like any other
## enemy; `EnemyDirector.boss` is typed as Boss so the HUD, the autotest,
## power-ups and stage hazards work with whichever boss the stage sends
## (StageRegistry `boss.id`). Each subclass owns its attack state machine and
## overrides the hooks below.
class_name Boss
extends Enemy

## Boss design data (EnemyData.BOSS for Sir Alaric, MarchEnemyData.VAEL for
## Marshal Vael): Enemy row keys plus the boss's ability numbers, including
## reward_xp / reward_crystals (the XP burst EnemyDirector drops on death).
var boss_def: Dictionary = {}


## Sets up the boss at `_pos` with HP scaled by `_hp_mult` (think slot
## `_slot`). Every subclass overrides it and calls Enemy.activate().
func setup_boss(_game: Game, _pos: Vector2, _hp_mult: float, _slot: int) -> void:
	pass


## Ids of this boss's special abilities in report order (the autotest
## "boss attacks" line reads the boss_atk_<id> stats).
func special_ids() -> Array:
	return []


## True while the boss is walking at the necromancer (not winding up,
## striking or recovering): the autotest stuck-unit check.
func is_walking() -> bool:
	return true


## Danger hint for the autotest autopilot: a push away from the active
## telegraph at `_p` (zero when nothing is telegraphed).
func danger_push(_p: Vector2) -> Vector2:
	return Vector2.ZERO
