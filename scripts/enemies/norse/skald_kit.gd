## SkaldKit — the kit of the Skald (NorseEnemyData "skald"; the Hall of the
## Slain, temporarily Act XI; GDD §15.0 "The Hall of the Slain foundation (phase
## 1)"; owner-approved proposal: "Skald (male) | Support | War-song: Norse
## warriors near him attack faster | Priority target"). A WARRIOR himself. THE
## WAR-SONG: every song_every s he sings a verse: every other Norse WARRIOR
## within song_radius px is quickened for song_time s (sing(): the one writer
## of NorseKit.song_until / song_bonus; NorseKit.physics() runs a quickened
## warrior's attack cooldown song_bonus faster). No RNG. Stats: skald_verses,
## skald_warriors_sung.
class_name SkaldKit
extends NorseKit

## Seconds until the next verse.
var _cd: float = 0.0
## Scratch for the grid query.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("song_every", 1.0)))


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(d.get("song_every", 1.0))
		sing(e)
	return false


## One verse: every Norse warrior near him is quickened for song_time s.
func sing(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("song_radius", 160.0))
	var until := g.elapsed + float(d.get("song_time", 1.6))
	var bonus := float(d.get("song_bonus", 0.35))
	var n := 0
	g.enemy_grid.query(e.position, r + 30.0, _tmp)
	for o: Enemy in _tmp:
		if o == e or not o.active or not NorseRules.is_warrior(o) or o.position.distance_squared_to(e.position) > r * r:
			continue
		var k := o.kit as NorseKit
		var live := k.song_until > g.elapsed  # Already quickened by a verse.
		if not live:
			o.queue_redraw()
		k.song_bonus = maxf(k.song_bonus if live else 0.0, bonus)
		k.song_until = maxf(k.song_until, until)
		n += 1
	g.stat_add("skald_verses", 1.0)
	g.stat_add("skald_warriors_sung", float(n))
	if n > 0 and g.norse != null:
		g.norse.play_sound("skald_song", e.position, 4.0)
