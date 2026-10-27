## BannerOfTheDead — the Banner of the Dead spell (AbilityData
## "banner_of_the_dead"; Act V, Castle Kurogane; GDD §15.0 "Banner of the Dead,
## Warlord's Seal and the Ronin Revenant"; owner-approved proposal: "a war
## banner planted where you stand; summons near it attack faster"; unlocked by
## slaying Shogun Kurogane, then offered on every stage at the later-item card
## weight). Every `cooldown` s it PLANTS a black war banner with a violet skull
## where the necromancer stands: the planting strikes every foe within
## `pulse_radius` px for `damage` (the friendly damage path,
## CombatResolver.damage_enemy()); the banner stands `duration` s, at most
## `banners` at once (the oldest uprooted). Every summon of his army within
## `radius` px of a standing banner attacks `haste` faster: the spell writes its
## banners to its own army each tick (HordeDirector.set_banners()), and
## HordeDirector.attack_haste() is the ONE read (SummonedUnit's attack timer),
## the same on every stage. The Ronin Revenant's innate (Unbowed Banner, key
## BannerData.INNATE_KEY) raises the haste by its share.
## Evolved into HUNDRED BANNERS (EvolutionData "hundred_banners", detected by
## the "pulse_interval" key): each planting raises `banners` banners at once on
## a ring BannerData.RING px round him (each with its blast), and every banner
## beats a WAR DRUM every `pulse_interval` s: `pulse_damage` to every foe within
## `pulse_radius` px of it.
## Determinism: no RNG. Stats: banner_planted, banner_drums, dmg_banner_of_the_dead
## / dmg_hundred_banners.
class_name BannerOfTheDead
extends NecroSpell

## Standing banners: {pos (world), until (game s), drum (game s of the next
## war-drum beat; INF when not evolved)}.
var banners: Array[Dictionary] = []
## Seconds until the next planting.
var _cd: float = BannerData.FIRST_PLANT
## Blast rings to draw: [pos, until (game s), radius] each (drawing only).
var _blasts: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false
## Banner count at the last redraw (redraw only on a change; drawing only).
var _drawn_count: int = -1
## Aura radius (px) of the standing banners at the last step (drawing only).
var _radius: float = 0.0


## Plants on its cooldown, beats the war drums, uproots the old banners and
## hands the standing ones to its army.
func step(delta: float, stats: Dictionary) -> void:
	var now := game.elapsed
	var i := banners.size() - 1
	while i >= 0:
		if now >= float(banners[i]["until"]):
			banners.remove_at(i)
		i -= 1
	_cd -= delta
	if _cd <= 0.0:
		_plant(stats)
		_cd = float(stats["cooldown"])
	if stats.has("pulse_interval"):
		_drums(stats)
	var zones := PackedVector3Array()  # (x, y, radius px) of each standing banner.
	var r := float(stats["radius"])
	if r != _radius:
		_radius = r
		_drawn_count = -1  # Redraw the auras at their new size.
	for b in banners:
		var p: Vector2 = b["pos"]
		zones.append(Vector3(p.x, p.y, r))
	var haste := float(stats["haste"]) * (1.0 + game.character.innate_value(BannerData.INNATE_KEY))  # The Ronin Revenant's Unbowed Banner (0 for everyone else).
	game.horde.set_banners(zones, haste)
	var k := _blasts.size() - 1
	while k >= 0:
		if now >= float(_blasts[k][1]):
			_blasts.remove_at(k)
		k -= 1
	var busy := not _blasts.is_empty()
	if busy or _drawn or banners.size() != _drawn_count:
		queue_redraw()
	_drawn = busy
	_drawn_count = banners.size()


## Plants one banner where the necromancer stands (Hundred Banners: `banners`
## on a ring round him), each with its blast.
func _plant(stats: Dictionary) -> void:
	var p := game.player.position
	var evolved := stats.has("pulse_interval")
	var src := BannerData.EVOLVED_SOURCE if evolved else BannerData.SOURCE
	var n := int(stats["banners"]) if evolved else 1
	var spots: Array[Vector2] = []
	if n <= 1:
		spots.append(p)
	else:
		var a0 := game.player.velocity.angle() if game.player.velocity.length() > 1.0 else 0.0  # The first toward where he walks.
		for j in n:
			spots.append(game.arena.free_point(p + Vector2.from_angle(a0 + TAU * float(j) / float(n)) * BannerData.RING, 6.0))
	var keep := mini(int(stats["banners"]), BannerData.MAX_STANDING)  # Most standing at once.
	for at in spots:
		while banners.size() >= keep:
			banners.remove_at(0)  # The oldest is uprooted.
		banners.append({"pos": at, "until": game.elapsed + float(stats["duration"]),
			"drum": game.elapsed + float(stats.get("pulse_interval", 0.0)) if evolved else INF})
		damage_area(at, float(stats["pulse_radius"]), float(stats["damage"]), src)
		_blasts.append([at, game.elapsed + BannerData.BLAST_TIME, float(stats["pulse_radius"])])
		game.stat_add("banner_planted", 1.0)
	Sfx.play("abom_stomp", p, BannerData.PLANT_PITCH)  # A startup-bank sound: the spell plays on every stage.


## Hundred Banners: each banner's war drum on its beat.
func _drums(stats: Dictionary) -> void:
	var now := game.elapsed
	for b in banners:
		if now < float(b["drum"]):
			continue
		b["drum"] = now + float(stats["pulse_interval"])
		var at: Vector2 = b["pos"]
		damage_area(at, float(stats["pulse_radius"]), float(stats["pulse_damage"]), BannerData.EVOLVED_SOURCE)
		_blasts.append([at, now + BannerData.BLAST_TIME, float(stats["pulse_radius"]) * 0.8])
		game.stat_add("banner_drums", 1.0)


## Spell counters for the autotest summary.
func summary_extra() -> String:
	return "planted=%d drums=%d standing=%d" % [int(game.stats.get("banner_planted", 0.0)), int(game.stats.get("banner_drums", 0.0)), banners.size()]


## Draws each standing banner (a faint violet aura disc on the ground, a bone
## pole, a black cloth with a violet emblem) and the fresh blast rings. On game
## time. Visual only: rects and texture discs (no polygon redrawn every frame).
func _draw() -> void:
	for b in banners:
		var p: Vector2 = b["pos"]
		SpriteBank.draw_disc(self, p, _radius, Color(BannerData.EMBLEM, BannerData.AURA_ALPHA))
		draw_rect(Rect2(p + Vector2(-1.0, -34.0), Vector2(2.0, 36.0)), BannerData.POLE)
		draw_rect(Rect2(p + Vector2(1.0, -33.0), Vector2(11.0, 16.0)), BannerData.CLOTH)
		SpriteBank.draw_disc(self, p + Vector2(6.5, -25.0), 3.0, BannerData.EMBLEM)
	var now := game.elapsed
	for bl: Array in _blasts:
		var left := clampf((float(bl[1]) - now) / BannerData.BLAST_TIME, 0.0, 1.0)
		draw_arc(bl[0], float(bl[2]) * (1.1 - 0.3 * left), 0.0, TAU, 28, Color(BannerData.EMBLEM, 0.7 * left), 2.0)
