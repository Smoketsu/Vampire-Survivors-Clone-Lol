## Revelation — the REVELATION spell (AbilityData "revelation"; temporary Act
## XIII, the Empyrean; GDD §15.0 "Revelation, Be Not Afraid, Seventh Seal and
## the Unveiled"; owner-approved proposal: "a flash that stuns every enemy on
## screen for 1 s and weakens them through the one debuff path"). Unlocked by
## slaying the Voice (UnlockData), then offered on every stage; driven by
## NecroSpellBook's one dispatch (EMPYREAN_IDS, stepped only) with its
## EFFECTIVE stats (AbilityManager.spell_stats()).
##   * Every `cooldown` s, a foe on screen, THE FLASH: every foe inside the view
##     round the necromancer (Game.view_size(), RevelationData.EDGE_PAD; at most
##     MAX_TARGETS) takes `damage` (CombatResolver.damage_enemy(); the spell is
##     its own Grace kind), is stunned `stun` s (CombatResolver.stun_enemy(),
##     the one stun path: bosses / minibosses STUN_BOSS of it, elites
##     STUN_ELITE) and weakened `weaken_time` s (CombatResolver.weaken_enemy(),
##     the one debuff path: `weaken_slow` slower, `weaken_cut` less damage;
##     bosses WEAKEN_BOSS of it).
##   * Seventh Seal (its paired passive, PassiveData "seventh_seal", read only
##     here): x 1 + seal_damage on the damage, + seal_stun s on the stun.
##   * The Unveiled's Lifted Veil (CharacterData "revelation_stun_bonus"): + s
##     on the stun (0 for every other character).
## Evolved into BE NOT AFRAID (EvolutionData "be_not_afraid", detected by the
## "echo_share" key): longer stun, deeper weakening, and echo_delay s later a
## SECOND flash strikes every foe on screen for echo_share of the damage (no
## second stun).
## Deterministic: no RNG; foes in the spatial hash's order. Stats:
## revelation_flashes, revelation_hits, revelation_stuns, revelation_weakened,
## revelation_echoes, revelation_stun_bonus_s; damage as dmg_revelation /
## dmg_be_not_afraid.
class_name Revelation
extends NecroSpell

## Seconds until the next flash may start.
var _cd: float = 0.0
## Game time (s) of the evolution's second flash (INF = none pending).
var _echo_at: float = INF
## Damage of the pending second flash.
var _echo_dmg: float = 0.0
## Game time (s) of the last flash (drawing only).
var _shown_at: float = -INF
## Own query buffer (kill hooks may query the grid again).
var _cand: Array = []


func _ready() -> void:
	z_index = 3


## Flashes on the cooldown; the evolution's second flash follows.
func step(delta: float, stats: Dictionary) -> void:
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _flash(stats) else AbilityData.SPELL_RETRY
	if game.elapsed >= _echo_at:
		_echo_at = INF
		game.stat_add("revelation_echoes", 1.0)
		_strike(_echo_dmg, RevelationData.EVOLVED_SOURCE, 0.0, stats)
		_shown_at = game.elapsed
	if game.elapsed - _shown_at <= RevelationData.FLASH_SHOW + 0.05:
		queue_redraw()


## Every open foe inside the view round the necromancer (at most MAX_TARGETS).
func _in_view() -> Array[Enemy]:
	var p := game.player.position  # The necromancer.
	var half := game.view_size() * 0.5 - Vector2.ONE * RevelationData.EDGE_PAD  # The view's half size.
	game.enemy_grid.query(p, half.length() + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var out: Array[Enemy] = []
	for e: Enemy in _cand:
		if out.size() >= RevelationData.MAX_TARGETS:
			break
		if not e.active or e.untargetable or e.civilian:
			continue
		var rel := e.position - p
		if absf(rel.x) <= half.x and absf(rel.y) <= half.y:
			out.append(e)
	return out


## THE FLASH. Returns false when no foe is on screen (the spell then waits).
func _flash(stats: Dictionary) -> bool:
	if _in_view().is_empty():
		return false
	var seal := game.abilities.passive_value(RevelationData.SEVENTH_SEAL, RevelationData.DAMAGE_KEY)
	var dmg := float(stats["damage"]) * (1.0 + seal)
	var bonus := game.character.innate_value(RevelationData.INNATE_KEY)  # The Unveiled's Lifted Veil.
	var stun := float(stats["stun"]) + game.abilities.passive_value(RevelationData.SEVENTH_SEAL, RevelationData.STUN_KEY) + bonus
	var evolved := stats.has("echo_share")
	_strike(dmg, RevelationData.EVOLVED_SOURCE if evolved else RevelationData.SOURCE, stun, stats)
	game.stat_add("revelation_flashes", 1.0)
	if bonus > 0.0:
		game.stat_add("revelation_stun_bonus_s", bonus)
	if evolved:
		_echo_at = game.elapsed + float(stats["echo_delay"])
		_echo_dmg = dmg * float(stats["echo_share"])
	_shown_at = game.elapsed
	game.player.cast_motion(game.player.position + Vector2.UP)  # Engine motion (visual only).
	Sfx.play("bolt_cast", game.player.position, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return true


## Strikes every foe on screen for `dmg` (`source`); `stun` > 0 also stuns
## and weakens them.
func _strike(dmg: float, source: String, stun: float, stats: Dictionary) -> void:
	var p := game.player.position
	for e: Enemy in _in_view():
		if not e.active:
			continue
		if stun > 0.0:
			if game.combat.stun_enemy(e, stun, RevelationData.STUN_BOSS, RevelationData.STUN_ELITE) > 0.0:
				game.stat_add("revelation_stuns", 1.0)
			if game.combat.weaken_enemy(e, float(stats["weaken_slow"]), float(stats["weaken_cut"]), float(stats["weaken_time"]), RevelationData.WEAKEN_BOSS, false):
				game.stat_add("revelation_weakened", 1.0)
		game.combat.damage_enemy(e, dmg, source, -1, p)
		game.stat_add("revelation_hits", 1.0)


## Autotest counters (EmpyreanReport's Revelation line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "flashes=%d hits=%d stuns=%d weakened=%d echoes=%d stun_bonus_s=%.1f" % [int(st.get("revelation_flashes", 0.0)),
		int(st.get("revelation_hits", 0.0)), int(st.get("revelation_stuns", 0.0)), int(st.get("revelation_weakened", 0.0)),
		int(st.get("revelation_echoes", 0.0)), float(st.get("revelation_stun_bonus_s", 0.0))]


## The flash: a fading soul-teal light round the necromancer. Visual only:
## disc textures.
func _draw() -> void:
	var k := 1.0 - clampf((game.elapsed - _shown_at) / RevelationData.FLASH_SHOW, 0.0, 1.0)
	if k <= 0.0:
		return
	var c := caster_pos()
	SpriteBank.draw_disc(self, c, 60.0 + 260.0 * (1.0 - k), Color(RevelationData.LIGHT, 0.18 * k))
	SpriteBank.draw_disc(self, c, 26.0, Color(RevelationData.LIGHT, 0.5 * k))
