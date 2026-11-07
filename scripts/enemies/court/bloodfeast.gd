## Bloodfeast — BLOODFEAST, the first Sanguine Court rule (Act VII; GDD §15.0
## "Bloodfeast"; owner-approved proposal: "Court enemies heal on melee hits:
## each bite, claw or blade heals the attacker for a share of the damage it
## deals to a summon or the necromancer (about 50% for vampires, 25% for
## everything else), shown as a red thread from the victim to the attacker.
## Healing past full HP banks as a blood shield of up to 25% of max HP ... Rot
## and Wither halve feeding on the enemies they touch"), owned by Game.court.
## THE one path:
##   * on_hit(by, dealt, at, on_summon) is called ONCE from
##     CombatResolver.damage_unit() (the HP a summon lost) and ONCE from
##     CombatResolver.damage_player() (the HP the necromancer lost), only when
##     the hit names its attacker (`by`: Enemy._melee_hit() and its cleave, the
##     kits' own feeding blows such as the noble's drain beam and the beast's
##     lunge) and Game.court exists. A barrier's or a ward's absorbed share is
##     not fed on; shots that name no attacker never feed.
##   * the share: share_of(by), the row's "feeds" through the kit (CourtKit
##     .feed_share()), or a boss's boss_def "feeds" (phase 2's bosses); 0 =
##     no feeding (every non-Court foe).
##   * the multiplier: CourtRules.feed_mult() (the Blood Moon x2, the Endless
##     Feast's growth), x BLOODFEAST rot_wither_mult when the feeder is under
##     Rot (Enemy.rot_until) or inside the Wither aura (Enemy.wither_until),
##     x embalmed_mult() on a summon (the Embalmed hook, exactly 1 while the
##     passive does not exist).
##   * the heal goes through CombatResolver.heal_enemy() (the existing enemy
##     heal path); what is left past full banks in Enemy.blood_shield, up to
##     shield_cap x its max HP, and absorb() spends it before HP in
##     CombatResolver.damage_enemy() (Enemy.blood_shield stays 0 on every other
##     act, so nothing changes there).
## Drawn: a red thread from the victim to the feeder (a texture stretched along
## the line, CourtGlyphs.draw_thread(); never headless, never a polygon), and
## the shield ring on the feeder (CourtKit.draw_over()).
## Determinism: no RNG; threads are drawing only. Stats: feast_bites,
## feast_bites_you, feast_bites_summons, feast_heal, feast_heal_<kind>,
## feast_shield_banked, feast_shield_absorbed, feast_shields_broken,
## feast_halved, feast_halved_withheld, feast_moon_bites, feast_moon_heal,
## feast_embalmed_withheld.
class_name Bloodfeast
extends Node2D

## One red thread.
class FeedThread:
	extends RefCounted
	## Where the victim stood when it was bitten (world px).
	var from: Vector2 = Vector2.ZERO
	## The feeder (its current position is the thread's other end).
	var enemy: Enemy = null
	## The feeder's pool generation when it fed (stale guard).
	var gen: int = 0
	## The feeder's last known position (world px).
	var to: Vector2 = Vector2.ZERO
	## Game time (s) the thread fades out.
	var until: float = 0.0

## Owning run.
var game: Game
## Bloodfeast numbers (CourtRulesData.BLOODFEAST).
var cfg: Dictionary = {}
## Feeds this run (bites that healed or banked).
var bites: int = 0
## HP healed by feeding this run.
var healed: float = 0.0
## Blood shield banked this run.
var banked: float = 0.0
## Blood shield spent on hits this run.
var absorbed: float = 0.0
## Feeds halved by Rot / Wither this run.
var halved: int = 0
## Live threads (drawn only; empty headless).
var threads: Array[FeedThread] = []
## True when this build draws (never headless).
var _draws: bool = false
## True if the last frame drew a thread.
var _drawn: bool = false


## Builds Bloodfeast for `p_game` (CourtRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "Bloodfeast"
	z_index = 17  # Over the bodies and the effects, under the moon's tint.
	z_as_relative = false
	cfg = CourtRulesData.BLOODFEAST.duplicate()
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# The one path
# =====================================================================================

## THE call (CombatResolver.damage_unit() / damage_player()): enemy `by` dealt
## `dealt` HP to a summon (`on_summon`) or the necromancer standing at `at`.
## Feeds `by` when it is a feeder (see the header). No-op otherwise.
func on_hit(by: Enemy, dealt: float, at: Vector2, on_summon: bool) -> void:
	if by == null or not by.active or dealt <= 0.0:
		return
	var share := share_of(by)  # 0 = not a feeder.
	if share <= 0.0:
		return
	var mult := game.court.feed_mult()  # The moon, the Endless Feast.
	var moon := game.court.moon.is_up()
	if by.rot_until > game.elapsed or by.wither_until > game.elapsed:
		var cut := float(cfg["rot_wither_mult"])  # Rot and Wither halve it.
		halved += 1
		game.stat_add("feast_halved", 1.0)
		game.stat_add("feast_halved_withheld", dealt * share * mult * (1.0 - cut))
		mult *= cut
	if on_summon:
		var emb := embalmed_mult()  # Embalmed (1 while not owned).
		if emb < 1.0:
			game.stat_add("feast_embalmed_withheld", dealt * share * mult * (1.0 - emb))
			mult *= emb
	var amount := dealt * share * mult  # HP the bite is worth.
	if amount <= 0.0:
		return
	var heal := game.combat.heal_enemy(by, amount)  # The existing enemy heal path.
	var over := amount - heal  # Past full: the blood shield.
	var bank := 0.0
	if over > 0.0:
		var cap := by.max_hp * float(cfg["shield_cap"])
		bank = minf(over, maxf(0.0, cap - by.blood_shield))
		if bank > 0.0:
			by.blood_shield += bank
			banked += bank
			game.stat_add("feast_shield_banked", bank)
			game.court.play_sound("blood_shield", by.position, float(cfg["shield_sound_gap"]))
	if heal <= 0.0 and bank <= 0.0:
		return  # Full and shielded to the cap: nothing taken.
	bites += 1
	healed += heal
	game.stat_add("feast_bites", 1.0)
	game.stat_add("feast_bites_summons" if on_summon else "feast_bites_you", 1.0)
	game.stat_add("feast_heal", heal)
	game.stat_add("feast_heal_" + by.kind, heal)
	if moon:
		game.stat_add("feast_moon_bites", 1.0)
		game.stat_add("feast_moon_heal", heal + bank)
	by.queue_redraw()
	game.court.play_sound("bite_feed", at, float(cfg["bite_sound_gap"]))
	if _draws:
		_add_thread(at, by)


## Feeding share (0..1) of enemy `e`: its kit's (CourtKit.feed_share(): the
## row's "feeds"), else a boss's boss_def "feeds" (phase 2's Court bosses),
## else 0 (every non-Court foe).
static func share_of(e: Enemy) -> float:
	if e.kit is CourtKit:
		return (e.kit as CourtKit).feed_share(e)
	if e is Boss:
		return float((e as Boss).boss_def.get("feeds", 0.0))
	return 0.0


## Spends enemy `e`'s blood shield on `raw` post-armour damage (CombatResolver
## .damage_enemy(), only while e.blood_shield > 0); returns what is left for HP.
func absorb(e: Enemy, raw: float) -> float:
	var used := minf(e.blood_shield, raw)  # Taken by the shield.
	e.blood_shield -= used
	absorbed += used
	game.stat_add("feast_shield_absorbed", used)
	if e.blood_shield <= 0.0:
		e.blood_shield = 0.0
		game.stat_add("feast_shields_broken", 1.0)
	e.queue_redraw()
	return raw - used


## Embalmed (counter-passive hook, NOT built): x on a feed from a SUMMON
## (1 - the bound player's PassiveData embalmed / feed_reduction); exactly 1
## while the passive does not exist.
func embalmed_mult() -> float:
	return 1.0 - game.abilities.passive_value(CourtRulesData.EMBALMED, CourtRulesData.EMBALMED_KEY)


# =====================================================================================
# The threads (visual only)
# =====================================================================================

## A new thread from `at` to feeder `by` (the oldest replaced at the cap).
func _add_thread(at: Vector2, by: Enemy) -> void:
	var t := FeedThread.new()
	t.from = at
	t.enemy = by
	t.gen = by.generation
	t.to = by.position
	t.until = game.elapsed + float(cfg["thread_life"])
	if threads.size() >= int(cfg["thread_cap"]):
		threads.remove_at(0)
	threads.append(t)


## Per-tick update (CourtRules.step()): faded threads leave, live ones follow
## their feeder.
func step(_delta: float) -> void:
	if not _draws:
		return
	var now := game.elapsed
	var i := threads.size() - 1
	while i >= 0:
		var t := threads[i]
		if now >= t.until:
			threads.remove_at(i)
		elif t.enemy.active and t.enemy.generation == t.gen:
			t.to = t.enemy.position
		i -= 1
	var busy := not threads.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Each thread: a red line from the victim to the feeder, fading. Visual only.
func _draw() -> void:
	var now := game.elapsed
	var life := maxf(float(cfg["thread_life"]), 0.01)
	for t in threads:
		var k := clampf((t.until - now) / life, 0.0, 1.0)  # 1 fresh .. 0 gone.
		CourtGlyphs.draw_thread(self, t.from, t.to, float(cfg["thread_width"]), Color(Palette.COURT_BLOOD_LIGHT, 0.9 * k))
