## MarrowCoverKit — DON MARROW'S COVER, the kit of the Skid Row boss (his
## boss row's "kit"; Act VIII, GDD §15.0 "Don Marrow, the Kingpin (Act
## VIII)"; owner-approved proposal: "the Last Stand (behind the limo's armour
## with a gold-plated minigun that sweeps the arena)"). It exists only so his
## LAST STAND's cover goes through the Armour rule's ONE path: Armour
## .front_mult() reads a CityKit's armour_front() and its `facing`
## (Armour.hit_from_front(), the act's one facing test). Until the Last Stand
## his front is 0 (no cover); BossDonMarrow calls take_cover() as the phase
## begins, and from then on the limo's armour cuts DonMarrowData cover_front
## of every hit from inside +-60 degrees of his facing, which the boss keeps
## pointed at the nearest necromancer (the ring around him). Arcing hits
## (FROM_ABOVE) and undirected hits ignore it, as on every armoured row. The
## boss owns every tick (Boss.physics_step()), so nothing here moves him.
## No RNG.
class_name MarrowCoverKit
extends CityKit

## The share (0..1) of a front hit the limo's armour cuts (0 until the Last
## Stand).
var cover: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cover = 0.0


## The Last Stand: the limo's armour covers his front from now on.
func take_cover(share: float) -> void:
	cover = clampf(share, 0.0, 1.0)


## Armour's front share: the limo's cover in the Last Stand, else none.
func armour_front() -> float:
	return cover


## Points his front at `toward` (the necromancer: the ring is around him).
func face_toward(e: Enemy, toward: Vector2) -> void:
	var to := toward - e.position
	if to.length_squared() > 1.0:
		facing = to.normalized()
