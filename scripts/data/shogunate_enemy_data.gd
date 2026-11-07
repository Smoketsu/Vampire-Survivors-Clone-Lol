## ShogunateEnemyData — immutable design data for the kinds the SHOGUNATE OF THE
## RISING SUN fields on every Act V stage (GDD §15.0 "Act V foundation (phase
## 1)"; owner-approved proposal docs/act5/PROPOSAL.md "Act V: The Shogunate of
## the Rising Sun"). A warrior nation ruled in the sun goddess's name:
## disciplined samurai and ashigaru by day, ninja in the shadows at dusk, the
## oni and yokai of the old stories at night. The shared kinds of phase 1:
##   ashigaru     — Ashigaru: day fodder, spear levies in wide ranks.
##   samurai      — Samurai: soldier, a katana duelist; its ELITE uses the Draw
##                  (DRAWS: DrawCuts, the iaijutsu line).
##   teppo_gunner — Teppo Gunner: ranged; arquebus volleys every 6 s on a shared
##                  beat, then a long reload while still advancing (its balls
##                  fly through ProjectileManager: Line of Fire is Act III only).
##   ninja        — Ninja: soldier; AMBUSHER (From the Shadows: it appears out
##                  of an obstacle's shadow after a smoke puff); shuriken, then
##                  the dagger.
##   onryo        — Onryō: night fodder, a vengeful ghost; NIGHT (spawns only at
##                  night) and ETHEREAL (drifts through obstacles and the ring).
##   oni          — Oni: the night heavy; NIGHT; an iron kanabō smash that stuns
##                  summons (CombatResolver.stun_unit(), the one summon stun
##                  path); flat armour. Also the Endless Night Reckoning's kind.
## Each stage's own kinds live in its own file (ProvinceEnemyData,
## KuroganeEnemyData, SunRoadEnemyData; empty until phase 2);
## EnemyDirector.enemy_def() looks them up through shogunate_def(), this file
## first, after the Olympian Republic's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Shogunate keys (absent = off):
##   faction   — "shogunate" (the Codex's Shogunate tab, the reports).
##   kit       — a CovenantKit id; a Shogunate kit lives in
##               scripts/enemies/shogunate/<kit>_kit.gd (CovenantKits loads it
##               by name, after the Eye's, the Empire's and the Pantheon's
##               folders, so kit ids must be unique across the four folders).
##               Every Shogunate kind has one (a ShogunateKit).
##   night     — true: spawns only at night (the Sun's Course): the timeline
##               helper SunCourse.timeline_weights() / filter_groups() drops it
##               from the trickle and the waves by day and at dusk.
##   draws     — true: can use the Draw (DrawCuts). The samurai's row draws on
##               its ELITE only (ShogunateKit.can_draw()); "draws_always" lets
##               a phase 2 kind draw without being elite.
##   ambusher  — true: enters From the Shadows (ShadowAmbush; the stages hand
##               such squads to it through the "ambush" event and the
##               segments' "ambush" trickle instead of the spawn ring).
##   ethereal  — true: passes through obstacles and the Bone Ring (Enemy
##               .ethereal, the one path: Arena.resolve_all() and
##               Enemy.resolve_blocking() skip it).
##   fodder    — true: fodder (reports; phase 2 may read it).
##   floating  — true: drawn hovering, never carried by the ground (TerrainSlow).
## Kit numbers (the Draw's rhythm, the shuriken, the kanabō smash) are row keys
## documented on each row. The GDD gives no numbers: everything is TUNING (not
## in GDD).
class_name ShogunateEnemyData
extends RefCounted

## Faction id of the Shogunate's kinds (row "faction").
const FACTION: String = "shogunate"
## Kind id of the shared day fodder.
const ASHIGARU: String = "ashigaru"
## Kind id of the shared katana soldier (its elite draws).
const SAMURAI: String = "samurai"
## Kind id of the shared arquebus gunner.
const TEPPO_GUNNER: String = "teppo_gunner"
## Kind id of the shared ambusher.
const NINJA: String = "ninja"
## Kind id of the shared night fodder (ethereal).
const ONRYO: String = "onryo"
## Kind id of the shared night heavy and the Endless Night's Reckoning kind.
const ONI: String = "oni"

## The Shogunate's shared kinds, keyed by kind id.
const ENEMIES := {
	# Day fodder: a spear levy in a jingasa hat and a lacquer-red do, a long
	# yari; comes in wide ranks.
	"ashigaru": {
		"display_name": "Ashigaru",
		"max_hp": 13.0,  # TUNING (not in GDD) fodder (Recruit 14, Shade of the Dead 9)
		"move_speed": 56.0,  # TUNING (not in GDD) px/s (Recruit 58)
		"damage": 2.5,  # TUNING (not in GDD) a spear jab, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px; the yari outreaches a sword
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.25,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "ashigaru",
		"fodder": true,
	},
	# Soldier: black and red lacquered armour, a crested kabuto, the katana at
	# the hip. Its elite stops, hand on the hilt, and DRAWS (DrawCuts).
	#   draw_every — s between two Draws of one samurai (after its first: half).
	#   draw_range — px: it draws when the necromancer is this close (the cut
	#                reaches ShogunateRulesData.DRAW length).
	"samurai": {
		"display_name": "Samurai",
		"max_hp": 42.0,  # TUNING (not in GDD) a soldier (Hoplite 34, Footman 36)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) a katana cut, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) lacquered plates
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "samurai",
		"draws": true,  # Owner-approved proposal: "Samurai elites ... the Draw" (elites only)
		"draw_every": 7.0,  # TUNING (not in GDD) s
		"draw_range": 200.0,  # TUNING (not in GDD) px (inside the 250 px line)
	},
	# Ranged: indigo and lacquer, an arquebus held level, a smouldering match
	# cord. Fires on the shared volley beat (ShogunateRulesData.VOLLEY_BEAT).
	"teppo_gunner": {
		"display_name": "Teppo Gunner",
		"max_hp": 26.0,  # TUNING (not in GDD) ranged (Line Trooper 24)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s; it reloads while advancing
		"damage": 9.0,  # TUNING (not in GDD) one heavy ball, before the time scaling
		"attack_interval": 6.0,  # Owner-approved proposal: "volleys ... every 6 s" (the long reload)
		"attack_range": 300.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 430.0,  # TUNING (not in GDD) px/s, a fast ball
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1; rush the reload
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "teppo",
	},
	# Soldier: indigo-black, masked, a shuriken in hand. AMBUSHER: appears out
	# of an obstacle's shadow (ShadowAmbush). Shuriken while it closes, then the
	# dagger (the shared melee blow).
	#   shuriken_count  — shuriken it throws before it closes with the dagger.
	#   shuriken_every  — s between two throws.
	#   shuriken_damage — damage of one shuriken (before the time scaling).
	#   shuriken_speed  — px/s.
	#   shuriken_min / shuriken_max — px: it throws only at targets this far.
	"ninja": {
		"display_name": "Ninja",
		"max_hp": 30.0,  # TUNING (not in GDD) a soldier, lightly armoured
		"move_speed": 74.0,  # TUNING (not in GDD) px/s; fast
		"damage": 5.0,  # TUNING (not in GDD) a dagger thrust, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 7.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "ninja",
		"ambusher": true,  # Owner-approved proposal: From the Shadows
		"shuriken_count": 3,  # TUNING (not in GDD)
		"shuriken_every": 1.1,  # TUNING (not in GDD) s
		"shuriken_damage": 3.5,  # TUNING (not in GDD)
		"shuriken_speed": 320.0,  # TUNING (not in GDD) px/s
		"shuriken_min": 40.0,  # TUNING (not in GDD) px
		"shuriken_max": 200.0,  # TUNING (not in GDD) px
	},
	# Night fodder: a pale vengeful ghost, long black hair over the face, a
	# white burial kimono; hovers, no feet. ETHEREAL: drifts through obstacles
	# and the Bone Ring.
	#   drift      — px/s of its sideways sway (a deterministic sine).
	#   drift_rate — rad/s of the sway.
	"onryo": {
		"display_name": "Onryō",
		"max_hp": 15.0,  # TUNING (not in GDD) fodder
		"move_speed": 46.0,  # TUNING (not in GDD) px/s; drifts
		"damage": 3.0,  # TUNING (not in GDD) a cold grasp, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1
		"mass": 0.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "onryo",
		"night": true,  # Owner-approved proposal: a yokai of the night
		"ethereal": true,  # Owner-approved proposal: "drift through walls and the ring"
		"fodder": true,
		"floating": true,  # Hovers, drawn hovering.
		"drift": 18.0,  # TUNING (not in GDD) px/s
		"drift_rate": 1.7,  # TUNING (not in GDD) rad/s
	},
	# Night heavy: a huge red-skinned ogre, horns, a tiger-skin loincloth, an
	# iron kanabō. Its SMASH: a telegraphed slam that hits and stuns summons
	# (CombatResolver.stun_unit()) and hits the necromancer. Flat armour.
	#   smash_every   — s between two smashes.
	#   smash_trigger — px: it winds up when a summon or the necromancer is this
	#                   close (edge to edge).
	#   smash_windup  — s of the raised-club telegraph (the ring on the ground).
	#   smash_radius  — px of the slam.
	#   smash_damage  — damage of the slam (before the time scaling).
	#   smash_stun    — s each summon in the slam is stunned.
	"oni": {
		"display_name": "Oni",
		"max_hp": 320.0,  # TUNING (not in GDD) a heavy (Cyclops tier); first pass 380
		"move_speed": 38.0,  # TUNING (not in GDD) px/s
		"damage": 11.0,  # TUNING (not in GDD) per blow, before the time scaling; first pass 14
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"flat_armor": 4.0,  # Owner-approved proposal: "flat armour" (TUNING the amount)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1
		"mass": 5.0,  # TUNING (not in GDD) blockers barely slow it
		"faction": FACTION,
		"kit": "oni",
		"night": true,  # Owner-approved proposal: "Heavy (night)"
		"smash_every": 6.0,  # TUNING (not in GDD) s; first pass 5
		"smash_trigger": 34.0,  # TUNING (not in GDD) px
		"smash_windup": 0.8,  # TUNING (not in GDD) s
		"smash_radius": 44.0,  # TUNING (not in GDD) px; first pass 52
		"smash_damage": 10.0,  # TUNING (not in GDD) first pass 16: the oni were the army bot's top summon killer on the stubs (Kurogane)
		"smash_stun": 0.9,  # TUNING (not in GDD) s; first pass 1.2
	},
}
