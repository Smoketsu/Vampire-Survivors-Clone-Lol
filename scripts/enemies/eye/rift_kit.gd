## RiftKit — an open rift (ArchiveEnemyData "archive_rift"; Act II, GDD §15.0
## "Act II: the Hollow Archive"): a structure the army can attack. RiftDirector
## places it when a telegraphed rift opens, spits the Eye out of it and takes
## it off the field when its life runs out (EnemyDirector.despawn(): no kill,
## no XP); breaking it closes the rift early (RiftDirector notices the kill).
## The kit only draws the tear (its sprite is structures/archive_rift when that
## art exists; the code look otherwise): a swirling bioluminescent slit.
class_name RiftKit
extends CovenantKit


## The tear's glow on the ground under it.
func draw_under(e: Enemy) -> void:
	ArchiveGlyphs.draw_rift_glow(e, e.radius, e.game.elapsed)
