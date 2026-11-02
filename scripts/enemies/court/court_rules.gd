## CourtRules — the Sanguine Court's shared rules (Act VII; GDD §15.0 "Act VII
## foundation (phase 1)", "Bloodfeast", "Night Wings" and "The Blood Moon"),
## run as `Game.court`. Null on Acts I to VI (created in Game._ready() only for
## a stage whose STAGE has "court": true), except that a Court kind forced onto
## any other stage with --spawn= creates it on its first activation through
## Game.court_rules() (CourtKit.reset()), so a kind works anywhere (as the Act
## III to VI kinds do); there the Blood Moon and the Endless Feast stay off
## (they read the STAGE "court" key) and only what the kind itself uses
## (Bloodfeast, Night Wings) runs.
## Owns ONE path per rule:
##   feast    — Bloodfeast: BLOODFEAST. A Court enemy's melee hit heals it for
##              its row's "feeds" share of the damage, banked past full as a
##              blood shield; called once from CombatResolver.damage_unit() and
##              once from damage_player(); the red threads; the Embalmed hook.
##   wings    — NightWings: NIGHT WINGS' counters and numbers. The flag is the
##              row's "flies" (Enemy.flies, read by Enemy.resolve_blocking());
##              the swoop and the in-flight hit rule live in CourtKit (the
##              enemy's own kit: no summon gets an act rule).
##   moon     — BloodMoon: THE BLOOD MOON, the clock (is_up(), force()), the
##              tinted overlay and the HUD line.
##   endless  — EndlessFeast: the shared Act VII Reckoning (RECKONING
##              "endless_feast"): the moon never sets, feeding grows, coffins.
## Stepped by Game after the enemies (and the Inferno's rules) and before the
## obstacle push-out, so a noble a coffin releases this tick is pushed out of
## any obstacle before it is drawn.
## Determinism: game time and the seeded gameplay RNG only (the coffins'
## angles), and only while it exists (Act VII, or a forced Court kind).
class_name CourtRules
extends Node2D

## Owning run.
var game: Game
## True on an Act VII stage (STAGE "court"): the Blood Moon and the Endless
## Feast may run; false when a forced Court kind made the rules elsewhere.
var enabled: bool = false
## Bloodfeast (child node: the red threads).
var feast: Bloodfeast
## Night Wings (its counters).
var wings: NightWings
## The Blood Moon (child node: the overlay and the HUD line).
var moon: BloodMoon
## The Endless Feast (the Reckoning).
var endless: EndlessFeast
## Court kind -> game time (s) of its first activation this run (the
## autotest's "court kinds" line).
var first_seen: Dictionary = {}
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "CourtRules"
	enabled = bool(p_game.stage_def.get("court", false))
	feast = Bloodfeast.new(p_game)
	add_child(feast)
	wings = NightWings.new(p_game)
	moon = BloodMoon.new(p_game, enabled)
	add_child(moon)
	endless = EndlessFeast.new(p_game, enabled)


## Per-tick update (Game, after the enemies, before the obstacle push-out): the
## Endless Feast's clock, the Blood Moon, then the threads' bookkeeping.
func step(delta: float) -> void:
	endless.step(delta)
	moon.step(delta)
	feast.step(delta)


## THE feeding multiplier now (Bloodfeast): the Blood Moon's feed_mult while
## it is up, times the Endless Feast's growth past 0:00. Exactly 1 off Act VII.
func feed_mult() -> float:
	return moon.feed_mult() * endless.feed_mult()


# =====================================================================================
# Hooks (kits, bosses)
# =====================================================================================

## A Court kind's enemy `e` was activated (CourtKit.reset()): its first time is
## recorded.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed


## Plays the sound of Court event `event` (CourtRulesData.SOUNDS) at `pos`, at
## most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(CourtRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## Silver Bones (counter-passive hook, NOT built): x on a summon's hit tagged
## `source` on a werebeast or noble kind `e` (1 + the bound player's PassiveData
## silver_bones / silver_damage); exactly 1 while the passive does not exist,
## for any other source and any other kind. Read once by CourtKit.taken_mult().
static func silver_bones_mult(e: Enemy, source: String) -> float:
	var v := e.game.abilities.passive_value(CourtRulesData.SILVER_BONES, CourtRulesData.SILVER_DAMAGE_KEY)  # 0 when not owned.
	if v <= 0.0 or not e.game.combat.is_minion_source(source):
		return 1.0
	e.game.stat_add("silver_bones_bonus_hits", 1.0)
	return 1.0 + v


## Silver Bones (counter-passive hook, NOT built): x on a noble's mist time
## (1 - the bound player's PassiveData silver_bones / mist_reduction); exactly
## 1 while the passive does not exist. Read once by VampireNobleKit.
static func silver_mist_mult(e: Enemy) -> float:
	return 1.0 - e.game.abilities.passive_value(CourtRulesData.SILVER_BONES, CourtRulesData.SILVER_MIST_KEY)


# =====================================================================================
# Autotest
# =====================================================================================

## The army bot's Blood Moon hint (Autotest._rally_wanted(), cheap): 1 = spend
## Dread Rally now (the moon is up), 0 = hold it (the moon rises within
## `save` s), -1 = no opinion (the rest of the bot's rule decides).
func rally_hint(save: float) -> int:
	if not enabled:
		return -1
	if moon.is_up():
		return 1
	var to_rise := moon.time_to_rise()
	if to_rise >= 0.0 and to_rise <= save:
		return 0
	return -1
