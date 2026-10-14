## CodexLog — what ONE run has met, for the Codex (GDD §10.1 "Collection /
## Codex", CodexData; owned by Game as `game.codex`, built first in
## Game._ready so every hook can reach it). The game's hooks call meet():
##   * AbilityManager: the starting spell and every spell card (SPELL),
##   * HordeDirector.set_class_level(): every summon class raised (SUMMON),
##   * CombatResolver._kill_enemy(): every Covenant kind slain (ENEMY),
##   * EnemyDirector.boss_spawned (connected in Game._ready): the boss (BOSS).
## The first sight of an entry in a run is a set insert here and a forward
## to Meta.codex_record() (which saves new entries once per frame, never
## under the autotest); every later sight is one Dictionary lookup. It only
## writes its own Dictionaries and the Meta codex: no RNG, no gameplay state,
## so runs stay deterministic. summary_line() is the autotest's codex line.
class_name CodexLog
extends RefCounted

## The run (for the boss id of the stage's boss slot).
var game: Game = null
## CodexData category -> {entry id -> true when it is a known codex entry,
## false for an id the codex does not list (an alias, a boss body)}.
var _met: Dictionary = {}
## Entries met this run that were new to the save (in-memory Meta under
## the autotest, so there every known entry is new).
var new_entries: int = 0


func _init(p_game: Game) -> void:
	game = p_game
	for cat: String in CodexData.CATEGORIES:
		_met[cat] = {}


## Records that this run met entry `id` of category `cat` (CodexData). Cheap
## after the first sight: one lookup.
func meet(cat: String, id: String) -> void:
	var seen: Dictionary = _met[cat]  # This run's sights in the category.
	if seen.has(id):
		return
	var known := CodexData.is_known(cat, id)  # A codex entry (else ignored).
	seen[id] = known
	if known and Meta.codex_record(cat, id):
		new_entries += 1


## EnemyDirector.boss_spawned: the stage's boss (its slot's id) was faced.
func on_boss_spawned(_boss: Boss) -> void:
	meet(CodexData.BOSS, String(game.enemies.boss_info.get("id", "")))


## Known entries of category `cat` met this run.
func count(cat: String) -> int:
	var n := 0  # Known ids.
	for id: String in (_met[cat] as Dictionary):
		if bool((_met[cat] as Dictionary)[id]):
			n += 1
	return n


## Known entries met this run, all categories.
func total() -> int:
	var n := 0  # Sum over the categories.
	for cat: String in CodexData.CATEGORIES:
		n += count(cat)
	return n


## The autotest's codex line: entries met this run per category, how many
## were new to the save, and the save's totals (Meta, in memory unless
## --meta-save; evolutions from the [recipes] book).
func summary_line() -> String:
	var parts := PackedStringArray()  # "spells 3" per category.
	var saved := PackedStringArray()  # "spells 3/12" per category.
	for cat: String in CodexData.CATEGORIES:
		parts.append("%s %d" % [cat, count(cat)])
		saved.append("%s %d/%d" % [cat, Meta.codex_count(cat), CodexData.total(cat)])
	return "%d entries met this run (%s) | new to the save %d | save: %s, evolutions %d/%d" % [
		total(), ", ".join(parts), new_entries, ", ".join(saved), Meta.discovered_count(), EvolutionRecipes.ids().size()]
