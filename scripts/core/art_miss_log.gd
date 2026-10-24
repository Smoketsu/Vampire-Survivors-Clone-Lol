## ArtMissLog: the art audit's record of missing sprite art (debug flag
## --art-misses, autotest only; GDD §15.0 "Harbour placeholder art pass").
## While `on`, SpriteBank.texture() and EnvironmentArt.texture() report every
## key they are asked for: a found PNG once (hit()), every lookup that finds
## none (miss(), counted per call, so the count says how often a fallback was
## drawn or probed). SpriteBank.draw() also reports a grid-art unit body drawn
## without a walk strip (strip_miss()). print_report() prints the misses at the
## end of the run, sorted by count, as "[art-miss]" lines (never "[autotest]",
## so no summary line changes), after dropping the probes that another key
## answered: Glyphs asks "enemies/", "structures/", "eye/" and "empire/" in
## turn for one kind, and the floors / decals ask for optional "_2" / "_3"
## variants. Only meaningful in a window: headless runs skip _draw(). Purely
## a debug read-out: it never touches gameplay state or RNG.
class_name ArtMissLog
extends RefCounted

## True while lookups are recorded (set once by Game from GameState.autotest_art_misses).
static var on: bool = false
## Missed key -> number of lookups that found no PNG for it.
static var _misses: Dictionary = {}
## Keys whose PNG was found (key -> true), to drop probes answered elsewhere.
static var _hits: Dictionary = {}
## Grid-art still key drawn on a unit body layer without a walk strip -> draws.
static var _no_walk: Dictionary = {}

## Folders Glyphs.draw_enemy() probes in turn for one enemy kind: a miss in one
## of them is only a probe when the same id was found in another.
const PROBE_FOLDERS: Array[String] = ["enemies/", "structures/", "eye/", "empire/"]
## Optional variant suffixes the floors and decals probe for (EnvironmentArtData /
## DecalData): a miss is only a probe when the base key was found.
const VARIANT_SUFFIXES: Array[String] = ["_2", "_3"]
## Lines printed per section at most (the rest are summed in one line).
const MAX_LINES: int = 200


## Records a lookup of `key` that found no PNG.
static func miss(key: String) -> void:
	_misses[key] = int(_misses.get(key, 0)) + 1


## Records that `key`'s PNG was found (called once per key: the caches hold it).
static func hit(key: String) -> void:
	_hits[key] = true


## Records a body-layer draw of grid-art still `key` with no walk strip.
static func strip_miss(key: String) -> void:
	_no_walk[key] = int(_no_walk.get(key, 0)) + 1


## True when missed `key` is only a probe that another key answered.
static func _answered(key: String) -> bool:
	for f: String in PROBE_FOLDERS:
		if key.begins_with(f):
			var id := key.substr(f.length())  # The kind id without its folder.
			for g: String in PROBE_FOLDERS:
				if g != f and _hits.has(g + id):
					return true
	for suffix: String in VARIANT_SUFFIXES:
		if key.ends_with(suffix) and _hits.has(key.substr(0, key.length() - suffix.length())):
			return true
	return false


## Prints the recorded misses ("[art-miss]" lines): the unanswered keys sorted
## by count, then the bodies drawn without a walk strip, then a total line.
static func print_report() -> void:
	var rows: Array = []  # [count, key] of the unanswered misses.
	var probes := 0  # Misses answered by another key (not listed).
	for key: String in _misses:
		if _answered(key):
			probes += 1
		else:
			rows.append([int(_misses[key]), key])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] or (a[0] == b[0] and String(a[1]) < String(b[1])))
	print("[art-miss] missing sprite keys: %d (probes answered elsewhere: %d; keys found: %d)" % [rows.size(), probes, _hits.size()])
	for i in mini(rows.size(), MAX_LINES):
		print("[art-miss]   %7d  %s" % [rows[i][0], rows[i][1]])
	var walk: Array = []  # [count, key] of the bodies without a walk strip.
	for key: String in _no_walk:
		walk.append([int(_no_walk[key]), key])
	walk.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] or (a[0] == b[0] and String(a[1]) < String(b[1])))
	print("[art-miss] unit bodies drawn without a walk strip: %d" % walk.size())
	for i in mini(walk.size(), MAX_LINES):
		print("[art-miss]   %7d  %s_walk" % [walk[i][0], walk[i][1]])
