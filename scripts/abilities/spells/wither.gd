## Wither — the Wither spell (AbilityData "wither", GDD §15.0 "Five more
## spells"): a decay aura of `radius` px around the necromancer (survivor
## "garlic"). Every `cooldown` s it pulses: each enemy inside first has its
## armour shredded (Enemy.wither_until / wither_shred: CombatResolver cuts
## its percentage armour and flat armour by `shred` until the next pulse
## plus GraveSpellData.WITHER_LINGER s; bosses get
## GraveSpellData.WITHER_BOSS_MULT of it), then takes `damage`. The shred is
## not a damage-taken bonus on unarmoured foes (armour 0 stays 0), so it only
## helps against the Covenant's armoured soldiers.
## Evolved into Necrotic Blight (EvolutionData "necrotic_blight", detected by
## the "heal" key): a wider aura, and every pulse heals the necromancer
## `heal` HP per enemy inside, never more than `heal_cap` HP per second (a
## leaky budget banking at most GraveSpellData.BLIGHT_BUDGET_SECONDS of it,
## like Soul Siphon's lifesteal cap).
## Pulses cost nothing when the aura is empty (no cooldown to waste). The
## aura is drawn under the units; each pulse also plays a ring
## ("wither_aura" animation when its art exists).
class_name Wither
extends NecroSpell

## Seconds until the next pulse.
var _timer: float = 0.5
## Heal HP still allowed by the Necrotic Blight per-second cap.
var _budget: float = 0.0
## Enemies inside at the last pulse (drawing intensity, uptime stat).
var _inside: int = 0
## Aura radius drawn (px; the effective stat of the last step).
var _radius: float = 0.0
## True while the evolved (Necrotic Blight) stats are in use.
var _blight: bool = false
## Seconds of animation time.
var _phase: float = 0.0
## 1 right after a pulse, fading to 0 (drawing).
var _flash: float = 0.0
## Own query buffer for the pulse (kills may query the grid too).
var _hit: Array = []


func _ready() -> void:
	z_index = -3


## Accrues the heal budget, pulses on cooldown and redraws the aura.
func step(delta: float, stats: Dictionary) -> void:
	_phase += delta
	_flash = maxf(0.0, _flash - delta * 2.5)
	_blight = stats.has("heal")
	_radius = float(stats["radius"])
	if _blight:
		var cap := float(stats["heal_cap"])  # HP/s.
		_budget = minf(_budget + cap * delta, cap * GraveSpellData.BLIGHT_BUDGET_SECONDS)
	if _inside > 0:
		game.stat_add("wither_uptime", delta)  # Seconds with foes inside the aura.
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"])
		_pulse(stats)
	queue_redraw()  # The aura follows the necromancer.


## One pulse: shreds, then damages every enemy inside; Blight heals.
func _pulse(stats: Dictionary) -> void:
	var p := game.player.position  # Aura centre.
	var r := float(stats["radius"])  # Aura radius (px).
	game.enemy_grid.query(p, r + ProjectileManager.MAX_BODY_RADIUS, _hit)
	var victims: Array[Enemy] = []  # Own copy: damage may trigger kill hooks.
	for e: Enemy in _hit:
		if e.active and e.position.distance_to(p) <= r + e.radius * 0.5:
			victims.append(e)
	_inside = victims.size()
	if victims.is_empty():
		return
	var until := game.elapsed + float(stats["cooldown"]) + GraveSpellData.WITHER_LINGER  # Shred expiry.
	var shred := float(stats["shred"])  # Armour fraction removed.
	var src := "blight" if _blight else "wither"  # Stats tag.
	# The Wither Witch's Creeping Rot innate (CharacterData wither_rot /
	# wither_rot_linger; 0 for every other character): each pulse also
	# inflicts Rot through the one Rot path, lingering briefly past the aura.
	var rot := game.character.innate_value("wither_rot")  # Rot fraction (0 = none).
	for e in victims:
		if not e.active:
			continue
		e.wither_shred = shred * (GraveSpellData.WITHER_BOSS_MULT if e.is_boss else 1.0)
		e.wither_until = until
		if rot > 0.0:
			game.combat.rot_enemy(e, rot, game.elapsed + game.character.innate_value("wither_rot_linger"))
			game.stat_add("creeping_rot_applied", 1.0)
		game.combat.damage_enemy(e, float(stats["damage"]), src)
	game.stat_add("wither_pulses", 1.0)
	game.stat_add("wither_hits", float(victims.size()))
	_flash = 1.0
	game.effects.ring(p, r, Palette.NECRO_GREEN if _blight else SpellGlyphs.PLAGUE, 0.3, "wither_aura")
	if _blight:
		var want := minf(float(victims.size()) * float(stats["heal"]), _budget)  # Heal allowed this pulse.
		if want > 0.0:
			var healed := game.combat.heal_player(want)  # HP the necromancer took.
			_budget -= healed
			game.stat_add("blight_healed", healed)


## Autotest counters (NecroSpellBook.later_summary_line()).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "pulses=%d hits=%d uptime_s=%d shred_bonus_dmg=%d healed=%d" % [int(st.get("wither_pulses", 0.0)), int(st.get("wither_hits", 0.0)),
		int(st.get("wither_uptime", 0.0)), int(st.get("wither_shred_bonus_dmg", 0.0)), int(st.get("blight_healed", 0.0))]


func _draw() -> void:
	GraveSpellGlyphs.draw_wither(self, game.player.position, _radius, _phase, _flash, _blight, _inside > 0)
