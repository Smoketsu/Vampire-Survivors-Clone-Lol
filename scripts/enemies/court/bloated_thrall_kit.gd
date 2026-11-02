## BloatedThrallKit — the kit of the Bloated Thrall (CourtEnemyData
## "bloated_thrall", the Witchwood's block; Act VII, GDD §15.0 "The Witchwood
## (Act VII phase 2)"; owner-approved proposal: "Swollen with blood; bursts into
## a pool that heals Court units walking through it ... Kill it away from the
## knights"). Male. A slow heavy: its slam is the shared melee blow (it feeds
## through it, Bloodfeast). When it DIES it BURSTS: a red splash and a blood
## pool of its row's pool_radius px for pool_life s through WitchHexes
## .open_pool() (the one pool path; the Court heals in it). A thrall that is
## merely despawned (off-screen recycling, the Reckoning's sweep) does not
## burst. No RNG. Stats: bloated_bursts (and WitchHexes' pool stats, tag
## "bloated").
class_name BloatedThrallKit
extends CourtKit

## WitchHexes stats tag of its pool.
const POOL_TAG: String = "bloated"


## The burst (killed only): a splash and the pool where it stood.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	rules(e).witch_hexes().open_pool(e.position, float(d.get("pool_radius", 52.0)), float(d.get("pool_life", 10.0)), POOL_TAG)
	g.stat_add("bloated_bursts", 1.0)
	g.effects.impact(e.position, e.radius * 2.0, Palette.COURT_BLOOD)
	rules(e).play_sound("blood_burst", e.position, 0.2)
