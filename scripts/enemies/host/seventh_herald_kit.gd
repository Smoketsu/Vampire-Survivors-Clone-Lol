## SeventhHeraldKit — the kit of THE HERALD OF THE SEVENTH TRUMPET, the
## Empyrean's miniboss (EmpyreanEnemyData "herald_of_the_seventh_trumpet";
## temporary Act XIII, the Celestial Host; GDD §15.0 "The Empyrean (Act XIII
## phase 2)"; owner-approved proposal: "the Herald of the Seventh Trumpet,
## whose trumpets call the squads of all the earlier zones"). A Herald
## (HeraldKit: the windup ring, the blast that pushes the ring back, the squad
## landing round him through EnemyDirector.spawn_at()) whose every call is the
## NEXT of his row's blast "zone_squads" (one squad per earlier zone, in order,
## then round again), at most blast "calls" (seven) in his life; plus the
## miniboss's parts: the HUD's miniboss bar (EnemyDirector.set_miniboss()), his
## XP burst (reward_xp in reward_crystals) and the stats of his fall;
## ChestManager drops the miniboss chest. Determinism: no RNG (HeraldKit's
## fixed angles). Stats: seventh_herald_calls, seventh_herald_kills,
## seventh_herald_ttk (and HeraldKit's herald_blasts / herald_pushed /
## herald_called).
class_name SeventhHeraldKit
extends HeraldKit

## Game time (s) he arrived (his time to kill).
var spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)


## The blast with this call's squad: the next earlier zone's (HeraldKit's
## push and landing, the one blast path).
func _blast(e: Enemy, bl: Dictionary) -> void:
	var squads: Array = bl["zone_squads"]
	var now_bl := bl.duplicate()  # This blast's numbers with this call's squad.
	now_bl["squad"] = squads[calls % squads.size()] if not squads.is_empty() else []
	if calls < int(bl["calls"]):
		e.game.stat_add("seventh_herald_calls", 1.0)
		e.game.host_rules().play_sound("seventh_trumpet", e.position, 0.5)
		e.game.shake(3.0)
	super._blast(e, now_bl)


## His XP burst and the stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.HOST_STARLIGHT)
	g.shake(8.0)
	g.stat_add("seventh_herald_kills", 1.0)
	g.stat_add("seventh_herald_ttk", g.elapsed - spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
