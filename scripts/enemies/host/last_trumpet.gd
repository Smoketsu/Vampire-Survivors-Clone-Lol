## LastTrumpet — THE LAST TRUMPET, the Celestial Host's Reckoning (temporary
## Act XIII; GDD §15.0 "The Last Trumpet"; proposal: "at 0:00 seven trumpets
## sound one after another; each fills the scales, widens the light and
## doubles the Host, and the sky opens"), owned by Game.host as `trumpet`. On
## a stage whose RECKONING has a "last_trumpet" dictionary (its keys override
## HostRulesData.TRUMPET; absent = off), from 0:00, TRUMPET "count" trumpets
## sound, the first "first" s after 0:00, then every "every" s; each one:
##   * FILLS THE SCALES: Judgment.fill() (the Verdict, or a longer one);
##   * WIDENS THE LIGHT: HallowedLight.width_mult x width_mult, and its clock
##     x every_mult;
##   * DOUBLES THE HOST: a squad of host_kind lands around each standing
##     necromancer (host_base, doubled every trumpet, at most host_cap),
##     through EnemyDirector.spawn_at();
## and after the last, THE SKY OPENS: the Light's clock every open_every s,
## open_max_live shafts at once. The RECKONING's "kind" (the Dominion) and its
## companions are spawned by EnemyDirector like every Reckoning. Determinism:
## game time and the seeded gameplay RNG (the squads' ring angle), only on a
## Host stage. Stats: trumpets, trumpet_host_spawned.
class_name LastTrumpet
extends RefCounted

## Owning run.
var game: Game
## The Last Trumpet's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and the trumpets began.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Trumpets sounded so far.
var sounded: int = 0
## True once the sky opened (after the last trumpet).
var sky_open: bool = false
## Game time (s) of the next trumpet.
var _next: float = INF


## Builds the Last Trumpet for `p_game`; `enabled`: a Host stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("last_trumpet"):
		cfg = HostRulesData.TRUMPET.duplicate()
		var over: Dictionary = r["last_trumpet"]
		for key: String in over:
			cfg[key] = over[key]


## True while the Last Trumpet runs (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## Per tick (HostRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty():
		return
	if not started:
		if game.countdown_finished():
			started = true
			started_at = game.elapsed
			_next = game.elapsed + float(cfg["first"])
		return
	if sounded < int(cfg["count"]) and game.elapsed >= _next:
		_next = game.elapsed + float(cfg["every"])
		_sound()


## One trumpet: the scales fill, the light widens, the Host doubles; the last
## one opens the sky.
func _sound() -> void:
	sounded += 1
	var host := game.host
	game.stat_add("trumpets", 1.0)
	host.play_sound("trumpet", game.player.position, 1.0)
	host.judgment.fill()
	host.light.width_mult *= float(cfg["width_mult"])
	host.light.every_mult *= float(cfg["every_mult"])
	var n := mini(int(cfg["host_base"]) * int(pow(2.0, float(sounded - 1))), int(cfg["host_cap"]))  # The squad: doubled each trumpet.
	var a0 := randf() * TAU
	for pl in game.all_players:
		if pl.dead:
			continue
		for i in n:
			var at := pl.position + Vector2.from_angle(a0 + TAU * float(i) / float(n)) * float(cfg["host_ring"])
			if game.enemies.spawn_at(String(cfg["host_kind"]), game.arena.free_point(at, 10.0), false) != null:
				game.stat_add("trumpet_host_spawned", 1.0)
	if sounded >= int(cfg["count"]):
		sky_open = true
		host.light.every_mult = float(cfg["open_every"]) / maxf(float(host.light.cfg["every_min"]), 0.01)
		host.light.max_live = int(cfg["open_max_live"])
		game.enemies.show_banner("The seventh trumpet: the sky opens!")
	else:
		game.enemies.show_banner("The trumpet sounds (%d of %d)!" % [sounded, int(cfg["count"])])
