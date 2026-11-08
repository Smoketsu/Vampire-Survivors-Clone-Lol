## NorseEnemyData — immutable design data for the kinds THE HALL OF THE SLAIN
## fields on every one of its stages (the Norse act, temporarily Act XI, final
## slot VI; GDD §15.0 "The Hall of the Slain foundation (phase 1)"; the act's
## section "VI. The Hall of the Slain" of docs/proposals/LAST_SIX_ACTS.md). In
## the north the dead are not owned but CHOSEN; since the necromancer took the
## world's dead the hall's benches stand empty, so the raiders, shield-maidens,
## berserkers, barrow-dead and giants come south, and the valkyries fly with
## them. The shared kinds of phase 1 (the whole roster of the proposal):
##   raider          — warriors, fodder (male): axe and round shield, in crowds.
##   shield_maiden   — warriors, soldier (female, figure style): spear and
##                     shield; a SHIELD BASH that throws one summon back.
##   berserker       — warriors, elite (male): bear pelt, two axes, always in
##                     the fury (BERSERKERGANG from its first step).
##   skald           — warriors, support (male): a WAR-SONG; Norse warriors
##                     near him attack faster.
##   valkyrie        — hall, flying elite (female, figure style): a SPEAR DIVE
##                     at the ring (she carries no bodies: the owner dropped
##                     the Choosing on Nov 7, 2026). In flight
##                     only airborne summons, ranged attacks, casters, spells
##                     and volleys hit her (the Act VII Night Wings test).
##   seer            — hall, support (female, figure style): RE-CARVES taken
##                     Rune-Stones and DOUSES the braziers she passes (the
##                     Long Winter); a CURSE that blinds one summon a while
##                     (CombatResolver.blind_unit(), the one summon blind path).
##   draugr          — wilds, soldier (male and female: the art alternates):
##                     barrow-dead in rusted mail, flat armour 3; a COLD TOUCH
##                     that slows the summon it strikes
##                     (CombatResolver.chill_unit()).
##   wolf_of_the_wastes — wilds, fodder pack (a beast): packs of 5 that LUNGE.
##   frost_giant     — wilds, heavy (male): throws a BOULDER onto a telegraphed
##                     landing circle; a STOMP when the ring closes in; DOUSES
##                     the braziers it passes (the Long Winter).
##   fire_giant      — wilds, heavy (male): the fire-giants of the south, the
##                     RAGNARÖK heavy (the RECKONING "kind" of every Norse
##                     stage; Vigrid's miniboss in phase 2 is one of them).
##   rune_stone      — a STRUCTURE row (RULE 3): RuneStones raises and runs
##                     every stone itself (never an Enemy on the field); this
##                     row names it for the Codex and lets --spawn= raise one.
##   brazier         — a STRUCTURE row (RULE 1, the Long Winter): LongWinter
##                     places and runs every brazier itself; this row names it
##                     for the Codex and lets --spawn= place one.
## Every Norse kind is born to the cold: the Long Winter never slows or bites
## one (it reads only the necromancer and the summons).
## The row key "warrior" (bool) marks the warriors BERSERKERGANG drives (raider, shield_maiden, berserker, skald); the
## draugr are already dead, the wolves and giants are not men of the hall.
## Each stage's own kinds live in its own file (BarrowFieldsEnemyData,
## ValgardEnemyData, VigridEnemyData; empty until phase 2), looked up through
## EnemyDirector.norse_def(), this file first, after the Concord's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Norse keys (absent = off):
##   faction       — "norse" (the Codex's Norse tab, the reports).
##   kit           — a CovenantKit id; a Norse kit lives in
##                   scripts/enemies/norse/<kit>_kit.gd (CovenantKits loads it
##                   by name after the Concord's folder, so kit ids must be
##                   unique across the nine folders). Every Norse kind has one
##                   (a NorseKit).
##   group         — String, one of NorseRulesData.GROUPS (Codex and report).
##   warrior       — bool: a warrior of the hall (Berserkergang).
##   douses        — bool: it douses a lit brazier it passes (the Long Winter;
##                   LongWinter reads it, the frost giant and the seer).
##   berserk_always — bool: in the fury from its first step (the berserker).
##   flight_melee_taken — share of a GROUNDED MELEE summon's blow a flier
##                   takes in flight (FallenAngelKit.grounded_melee(); 0 = it
##                   finds only air), the Night Wings test.
##   bash_*        — the shield-maiden's bash (every / range / push / damage /
##                   windup).
##   song_*        — the skald's war-song (radius / attack-speed bonus / every
##                   / time).
##   dive_*        — the valkyrie's spear dive (every / trigger / rise / fall
##                   / radius / damage / push / landed).
##   carve_rate    — x a seer's re-carving speed (1 = RUNE_STONES carve_time).
##   curse_*       — the seer's curse (every / range / time / windup).
##   chill_*       — the draugr's cold touch (slow share, s).
##   lunge_*       — the wolf's lunge (every / range / dist / time / windup /
##                   damage).
##   boulder_*     — the frost giant's throw (every / range_min / range_max /
##                   radius / flight / damage).
##   stomp_*       — a giant's stomp (every / radius / windup / damage / push).
##   fodder / elite_kind / figure — reports and art only (no rule reads them;
##                   an elite_kind is NOT spawned as an elite: its row is
##                   already strong).
## The GDD gives no numbers: everything is TUNING (not in GDD), tuned for the
## act's final slot VI (between the Shogunate's and Olympus's kinds), unless
## marked as the owner-approved proposal.
class_name NorseEnemyData
extends RefCounted

## Faction id of the Norse kinds (row "faction").
const FACTION: String = "norse"
## Kind id of the raider (fodder).
const RAIDER: String = "raider"
## Kind id of the shield-maiden.
const SHIELD_MAIDEN: String = "shield_maiden"
## Kind id of the berserker.
const BERSERKER: String = "berserker"
## Kind id of the skald.
const SKALD: String = "skald"
## Kind id of the valkyrie (the spear-diving flier).
const VALKYRIE: String = "valkyrie"
## Kind id of the seer.
const SEER: String = "seer"
## Kind id of the draugr.
const DRAUGR: String = "draugr"
## Kind id of the wolf of the wastes.
const WOLF: String = "wolf_of_the_wastes"
## Kind id of the frost giant.
const FROST_GIANT: String = "frost_giant"
## Kind id of the fire-giant (Ragnarök's heavy).
const FIRE_GIANT: String = "fire_giant"
## Sprite folder of the Norse kinds (assets/sprites/norse/).
const SPRITE_DIR: String = "norse/"

## Ragnarök's heavy (the RECKONING "kind" of every Norse stage).
const RECKONING_KIND: String = FIRE_GIANT
## Ragnarök's companions (the RECKONING "companions" of every Norse stage):
## raiders, berserkers, wolves and a valkyrie each wave.
const RECKONING_COMPANIONS: Array = [
	{"kind": RAIDER, "count": 8, "growth": 2.0},  # TUNING (not in GDD) a war-band
	{"kind": BERSERKER, "count": 1, "growth": 0.5},  # TUNING (not in GDD)
	{"kind": WOLF, "count": 5, "growth": 1.0},  # TUNING (not in GDD) a pack
	{"kind": VALKYRIE, "count": 1, "growth": 0.34},  # TUNING (not in GDD) "every valkyrie dives at the ring"
]

## The Norse shared kinds, keyed by kind id.
const ENEMIES := {
	# Warriors, fodder: axe and round shield, in crowds (owner-approved
	# proposal: "Anything").
	"raider": {
		"display_name": "Raider",
		"max_hp": 15.0,  # TUNING (not in GDD) fodder (Ashigaru 13, Recruit 14)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 2.5,  # TUNING (not in GDD) an axe blow, before the time scaling (balance pass 1: 3 -> 2.5, the Ashigaru's; the top damage to both armies, half of them in the fury)
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px (~36 px sprite)
		"armor": 0.05,  # TUNING (not in GDD) a round shield
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.25,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "raider",
		"group": "warriors",
		"warrior": true,  # Berserkergang.
		"fodder": true,
	},  # The raider.
	# Warriors, soldier (female, figure style): spear and shield; a shield bash
	# that throws one summon back (owner-approved proposal: "Flank her; Rogues").
	"shield_maiden": {
		"display_name": "Shield-Maiden",
		"max_hp": 44.0,  # TUNING (not in GDD) a soldier (Samurai 42)
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 3.5,  # TUNING (not in GDD) a spear thrust, before the time scaling (balance pass 1: 4 -> 3.5; foundation pass: 5 -> 4; a wounded maiden goes berserk)
		"attack_interval": 1.15,  # TUNING (not in GDD) s
		"attack_range": 13.0,  # TUNING (not in GDD) px; the spear outreaches an axe
		"radius": 9.0,  # TUNING (not in GDD) px (~42 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) the shield
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD) braced behind her shield
		"faction": FACTION,
		"kit": "shield_maiden",
		"group": "warriors",
		"warrior": true,
		"figure": true,
		"bash_every": 6.0,  # TUNING (not in GDD) s
		"bash_range": 22.0,  # TUNING (not in GDD) px from her edge to the summon's
		"bash_windup": 0.45,  # TUNING (not in GDD) s (she draws her shield back)
		"bash_push": 46.0,  # TUNING (not in GDD) px the summon is thrown back
		"bash_damage": 3.0,  # TUNING (not in GDD) before the time scaling (foundation pass: 4 -> 3)
	},  # The shield-maiden.
	# Warriors, elite: bear pelt, two axes, always in the fury (owner-approved
	# proposal: "Burst; Bone Wall").
	"berserker": {
		"display_name": "Berserker",
		"max_hp": 150.0,  # TUNING (not in GDD) an elite (Ninja 30 x elite; Vrask hunter 150)
		"move_speed": 60.0,  # TUNING (not in GDD) px/s before the fury's +30%
		"damage": 4.0,  # TUNING (not in GDD) per axe, before the fury and the time scaling (balance pass 2: 5 -> 4, the Barrow Fields' bursts; foundation pass: 8 -> 5, the fury and a skald's song stack on it; the seed-7 Vigrid bot died to berserkers)
		"attack_interval": 0.9,  # TUNING (not in GDD) s: two axes (foundation pass: 0.8 -> 0.9)
		"attack_range": 9.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px (~48 px sprite)
		"armor": 0.1,  # TUNING (not in GDD) a bear pelt
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 2.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "berserker",
		"group": "warriors",
		"warrior": true,
		"berserk_always": true,  # Owner-approved proposal: "Berserkers start in it"
		"elite_kind": true,
	},  # The berserker.
	# Warriors, support: a war-song; Norse warriors near him attack faster
	# (owner-approved proposal: "Priority target").
	"skald": {
		"display_name": "Skald",
		"max_hp": 34.0,  # TUNING (not in GDD) a support
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 2.5,  # TUNING (not in GDD) a knife, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 7.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.65,  # TUNING (not in GDD) 0..1: a priority target
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "skald",
		"group": "warriors",
		"warrior": true,
		"song_radius": 160.0,  # TUNING (not in GDD) px
		"song_bonus": 0.35,  # TUNING (not in GDD) + share of attack speed for the warriors near him
		"song_every": 1.0,  # TUNING (not in GDD) s between two verses (each renews the song)
		"song_time": 1.6,  # TUNING (not in GDD) s a verse lasts on a warrior
	},  # The skald.
	# Hall, flying elite (female, figure style): a spear dive at the ring
	# (no body-carrying, owner Nov 7, 2026; owner-approved proposal: "Archers,
	# Gargoyles, spells").
	"valkyrie": {
		"display_name": "Valkyrie",
		"max_hp": 90.0,  # TUNING (not in GDD) a flying elite: an Archer volley or a few spells bring her down
		"move_speed": 66.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) a spear thrust from above, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 11.0,  # TUNING (not in GDD) px (~48 px sprite with wings)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "norse_valkyrie",  # Kit id "valkyrie" is the Empire's Valkyrie 2.0.
		"group": "hall",
		"flies": true,  # The Night Wings test (Enemy.flies; over obstacles).
		"phases": true,  # She flies over the obstacles.
		"flight_melee_taken": 0.0,  # Owner-approved proposal: "Archers, Gargoyles, spells" (no grounded blow reaches her aloft)
		"figure": true,
		"elite_kind": true,
		"dive_every": 7.0,  # TUNING (not in GDD) s
		"dive_trigger": 240.0,  # TUNING (not in GDD) px from her target
		"dive_rise": 0.8,  # TUNING (not in GDD) s (the telegraph circle)
		"dive_fall": 0.25,  # TUNING (not in GDD) s
		"dive_radius": 36.0,  # TUNING (not in GDD) px
		"dive_damage": 5.0,  # TUNING (not in GDD) before the time scaling (balance pass 2: 7 -> 5, Valgard's bursts on the necromancer; foundation pass: 9 -> 7)
		"dive_push": 24.0,  # TUNING (not in GDD) px
		"landed_time": 1.3,  # TUNING (not in GDD) s on the ground after a dive (every blow lands)
	},  # The valkyrie.
	# Hall, support (female, figure style): re-carves Rune-Stones; a curse that
	# weakens one summon (owner-approved proposal: "Kill on the way to a stone").
	"seer": {
		"display_name": "Seer",
		"max_hp": 36.0,  # TUNING (not in GDD) a support
		"move_speed": 54.0,  # TUNING (not in GDD) px/s
		"damage": 2.0,  # TUNING (not in GDD) a staff, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "seer",
		"group": "hall",
		"figure": true,
		"douses": true,  # Owner decision Nov 7, 2026: "Frost giants and seers douse a brazier they pass"
		"carve_rate": 1.0,  # TUNING (not in GDD) x the stones' carve_time
		"curse_every": 8.0,  # TUNING (not in GDD) s
		"curse_range": 190.0,  # TUNING (not in GDD) px
		"curse_windup": 0.6,  # TUNING (not in GDD) s (a pale rune over the summon)
		"curse_time": 2.5,  # TUNING (not in GDD) s the summon is blinded (cannot find a foe)
	},  # The seer.
	# Wilds, soldier (male and female): barrow-dead in rusted mail; armour 3; a
	# cold touch that slows a summon (owner-approved proposal: "Wither, Rot").
	"draugr": {
		"display_name": "Draugr",
		"max_hp": 40.0,  # TUNING (not in GDD) a soldier
		"move_speed": 42.0,  # TUNING (not in GDD) px/s; slow, relentless
		"damage": 4.5,  # TUNING (not in GDD) a rusted blade, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"flat_armor": 3.0,  # Owner-approved proposal: "armour 3" (the Sanctum's flat armour path)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # TUNING (not in GDD) 0..1
		"mass": 1.3,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "draugr",
		"group": "wilds",
		"chill_slow": 0.35,  # TUNING (not in GDD) share of the struck summon's speed lost
		"chill_time": 2.0,  # TUNING (not in GDD) s
	},  # The draugr.
	# Wilds, fodder pack (a beast): packs of 5 that lunge (owner-approved
	# proposal: "Blockers").
	"wolf_of_the_wastes": {
		"display_name": "Wolf of the Wastes",
		"max_hp": 12.0,  # TUNING (not in GDD) fodder
		"move_speed": 80.0,  # TUNING (not in GDD) px/s; fast
		"damage": 2.5,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "wolf_of_the_wastes",
		"group": "wilds",
		"fodder": true,
		"lunge_every": 4.0,  # TUNING (not in GDD) s
		"lunge_range": 90.0,  # TUNING (not in GDD) px from its target's edge
		"lunge_windup": 0.35,  # TUNING (not in GDD) s (it crouches)
		"lunge_time": 0.22,  # TUNING (not in GDD) s in the air
		"lunge_damage": 3.0,  # TUNING (not in GDD) before the time scaling (balance pass 1: 4 -> 3; packs of 5 leap the ring, a top-3 source in the flanker builds' deaths)
	},  # The wolf of the wastes.
	# Wilds, heavy (male): throws boulders on a landing circle; a stomp
	# (owner-approved proposal: "Siegecraft, Wither").
	"frost_giant": {
		"display_name": "Frost Giant",
		"max_hp": 340.0,  # TUNING (not in GDD) a heavy (Oni 320)
		"move_speed": 36.0,  # TUNING (not in GDD) px/s
		"damage": 11.0,  # TUNING (not in GDD) per blow, before the time scaling
		"attack_interval": 1.7,  # TUNING (not in GDD) s
		"attack_range": 15.0,  # TUNING (not in GDD) px
		"radius": 19.0,  # TUNING (not in GDD) px (~76 px sprite)
		"armor": 0.15,  # TUNING (not in GDD)
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
		"kit": "frost_giant",
		"group": "wilds",
		"elite_kind": true,
		"douses": true,  # Owner decision Nov 7, 2026: "Frost giants and seers douse a brazier they pass"
		"boulder_every": 8.0,  # TUNING (not in GDD) s (foundation pass: 6.5 -> 8, the seed-7 Vigrid ring broke under four giants at 11:00)
		"boulder_range_min": 90.0,  # TUNING (not in GDD) px (closer, it stomps)
		"boulder_range_max": 340.0,  # TUNING (not in GDD) px
		"boulder_radius": 34.0,  # TUNING (not in GDD) px of the landing circle (foundation pass: 40 -> 34)
		"boulder_flight": 1.2,  # TUNING (not in GDD) s from the throw to the landing (the telegraph)
		"boulder_damage": 5.0,  # TUNING (not in GDD) before the time scaling (foundation pass: 12 -> 5: it lands on a packed ring)
		"stomp_every": 6.0,  # TUNING (not in GDD) s (foundation pass: 5 -> 6)
		"stomp_radius": 52.0,  # TUNING (not in GDD) px (foundation pass: 60 -> 52)
		"stomp_windup": 0.7,  # TUNING (not in GDD) s
		"stomp_damage": 3.75,  # TUNING (not in GDD) before the time scaling (balance pass 2: 5 -> 3.75, Vigrid's bursts; foundation pass: 9 -> 5)
		"stomp_push": 30.0,  # TUNING (not in GDD) px
	},  # The frost giant.
	# Wilds, heavy (male): the fire-giants of the south, Ragnarök's heavy
	# (owner-approved proposal: "fire-giants step out of the south edge").
	"fire_giant": {
		"display_name": "Fire-Giant",
		"max_hp": 420.0,  # TUNING (not in GDD) a Reckoning heavy (before its growth)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 14.0,  # TUNING (not in GDD) per blow, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 20.0,  # TUNING (not in GDD) px (~80 px sprite)
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 12,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1
		"mass": 6.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "fire_giant",
		"group": "wilds",
		"elite_kind": true,
		"stomp_every": 4.5,  # TUNING (not in GDD) s
		"stomp_radius": 70.0,  # TUNING (not in GDD) px
		"stomp_windup": 0.7,  # TUNING (not in GDD) s
		"stomp_damage": 12.0,  # TUNING (not in GDD) before the time scaling
		"stomp_push": 34.0,  # TUNING (not in GDD) px
	},  # The fire-giant.
	# A Rune-Stone (rule 3; RuneStones runs it). A structure row for the Codex
	# and --spawn= (the kit hands the spot to RuneStones and leaves).
	"rune_stone": {
		"display_name": "Rune-Stone",
		"max_hp": 1.0,  # Never hurt: RuneStones runs the stone; a spawned body leaves at once.
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 16.0,  # NorseRulesData.RUNE_STONES body_radius
		"armor": 0.0,
		"xp": 0,
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.0,
		"mass": 100.0,
		"is_structure": true,
		"faction": FACTION,
		"kit": "rune_stone",
		"group": "hall",
	},  # The Rune-Stone.
	# A brazier (rule 1, the Long Winter; LongWinter runs it). A structure row
	# for the Codex and --spawn= (the kit hands the spot to LongWinter and leaves).
	"brazier": {
		"display_name": "Brazier",
		"max_hp": 1.0,  # Never hurt: LongWinter runs the brazier; a spawned body leaves at once.
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 12.0,  # NorseRulesData.LONG_WINTER brazier_radius
		"armor": 0.0,
		"xp": 0,
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.0,
		"mass": 100.0,
		"is_structure": true,
		"faction": FACTION,
		"kit": "brazier",
		"group": "hall",
	},  # The brazier.
}
