## CodexData — designer data for the CODEX and ACHIEVEMENTS screen (GDD §10.1
## "Collection / Codex" and "Achievements" menu buttons; GDD §15.0 "Codex
## and achievements screen"). Data only, no logic beyond lookups.
##
## The codex is an illustrated compendium that fills in as the player MEETS
## things in runs (CodexLog records them, Meta saves them in [codex]):
##   * "spell"  — a spell learned (the starting spell or a card),
##   * "summon" — a summon class raised (the starting Warriors or a card),
##   * "enemy"  — a Covenant kind slain (soldiers, structures, the Reckoning
##                Inquisitor, the Cathedral Guardian miniboss),
##   * "boss"   — a stage boss faced (it arrived on the field).
## Evolutions are NOT recorded here: they follow the owner's recipe rule
## (hidden until obtained) and read the Meta [recipes] discoveries, so an
## unobtained evolution is a "?" tile with no name, shape or hint.
## Entry ids are the game's own ids (AbilityData, UnitData, the enemy data
## files, StageRegistry.BOSS_ARRIVALS), so new content only needs a line in
## the lists below; names, icons and stats are read from those files, the
## descriptions of the Covenant (whose data has none) live here.
class_name CodexData
extends RefCounted

## Codex category: spells learned.
const SPELL: String = "spell"
## Codex category: summon classes raised.
const SUMMON: String = "summon"
## Codex category: Covenant kinds slain.
const ENEMY: String = "enemy"
## Codex category: stage bosses faced.
const BOSS: String = "boss"
## Every recorded category, in save / summary order.
const CATEGORIES: Array[String] = [SPELL, SUMMON, ENEMY, BOSS]

## Screen tabs, left to right: [tab id, button text]. "feats" is the
## achievements list; the others are codex pages.
const TABS: Array = [["feats", "Achievements"], ["spells", "Spells"], ["summons", "Summons"], ["covenant", "Covenant"], ["eye", "Ancient Eye"]]  # TUNING (not in GDD) Act II adds the Ancient Eye tab

## Summon classes shown on the Summons page (UnitData ids, card order). The
## Profane Bishop is a merge evolution, so it sits with the evolutions.
const SUMMON_ORDER: Array[String] = ["warrior", "archer", "mage", "mender", "warder", "abomination",
		"rogue", "gargoyle", "frost_wraith", "bone_hound", "banshee", "corpse_catapult"]

## Covenant soldiers (enemy kinds), in the order the stages bring them.
const SOLDIERS: Array[String] = ["recruit", "footman", "archer", "chaplain", "purifier", "templar",
		"shieldbearer", "banner_bearer", "halberdier", "battle_sister",
		"sanctified_sentinel", "radiant_inquisitor", "high_confessor", "sun_paladin"]
## Covenant structures (enemy kinds that are buildings or carts).
const STRUCTURES: Array[String] = ["watchtower", "outpost", "ward_generator", "supply_cart", "holy_standard",
		"ward_crystal", "sacred_altar"]
## Champions: the Reckoning's executioner and the Sanctum's miniboss.
const CHAMPIONS: Array[String] = ["inquisitor", "cathedral_guardian"]
## Stage bosses (StageRegistry.BOSS_ARRIVALS ids), campaign order.
const BOSSES: Array[String] = ["alaric", "vael", "seraphine"]

## Act II, the Ancient Eye (GDD §15.0 "Act II: the Ancient Eye"; the Ancient
## Eye tab): its soldiers in the order the stages bring them (the Drowned
## Thrall last: the claimed dead), its minibosses, and its stage bosses
## (StageRegistry.BOSS_ARRIVALS ids). Each Act II stage adds its own as it is built.
const EYE_SOLDIERS: Array[String] = ["eye_initiate", "eye_chanter",
	# --- Act II: Gullhaven Harbour ---
	"deep_kin", "tide_caller", "netcaster", "deep_herald",
	"drowned_thrall"]
## Ancient Eye minibosses (enemy kinds).
const EYE_CHAMPIONS: Array[String] = [
	# --- Act II: Gullhaven Harbour ---
	"harbourmaster",
]
## Ancient Eye stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const EYE_BOSSES: Array[String] = [
	# --- Act II: Gullhaven Harbour ---
	"merrow",
]

## Section headers of each page: page id -> [[section id, header text], ...].
const SECTIONS: Dictionary = {
	"spells": [["spells", "Spells"], ["spell_evolutions", "Evolutions"]],  # TUNING (not in GDD)
	"summons": [["summons", "Summons"], ["summon_evolutions", "Evolutions"]],  # TUNING (not in GDD)
	"covenant": [["soldiers", "Soldiers"], ["structures", "Structures"], ["champions", "Champions"], ["bosses", "Bosses"]],  # TUNING (not in GDD)
	"eye": [["eye_soldiers", "Soldiers"], ["eye_champions", "Champions"], ["eye_bosses", "Bosses"]],  # TUNING (not in GDD) Act II
}

## One-sentence descriptions of the Covenant (the enemy data has none),
## from the GDD rows each kind cites (GDD §7.2, §7.4, §8, §10, §11).
const DESCRIPTIONS: Dictionary = {
	"recruit": "Weak basic infantry that come in massed waves.",  # GDD §10
	"footman": "Armoured melee soldiers that shrug off part of every blow.",  # GDD §10
	"archer": "Zealous archers that loose arrows from range.",  # GDD §10
	"chaplain": "Covenant priests that heal their wounded allies.",  # GDD §10
	"purifier": "Holy fire-bearers that deal bonus damage to the undead.",  # GDD §10
	"templar": "Heavy knights that charge through the army's lines.",  # GDD §10
	"shieldbearer": "Tower-shield infantry that block projectiles from the front.",  # GDD §7.2
	"banner_bearer": "Standard-bearers whose banner strengthens nearby soldiers.",  # GDD §7.2
	"halberdier": "Slow, armoured soldiers whose sweeps cleave packed summons.",  # GDD §8.2
	"battle_sister": "Battle-nuns whose scourges lash past the front line, zealous when a comrade falls.",  # GDD §15.0 "Sister of the Scourge" (owner request)
	"sanctified_sentinel": "Stone constructs with flat armour and a sweeping strike.",  # GDD §7.2
	"radiant_inquisitor": "Inquisitors who lay holy ground and suppress the undead.",  # GDD §7.2
	"high_confessor": "Confessors who heal, shield allies and raise the fallen.",  # GDD §7.2
	"sun_paladin": "Paladins whose sun aura hardens the soldiers around them.",  # GDD §7.2
	"watchtower": "A checkpoint tower that sends soldiers until it falls.",  # GDD §8.2
	"outpost": "A siege camp that spawns reinforcements until it is razed.",  # GDD §7.4
	"ward_generator": "A holy engine whose zone weakens the undead nearby.",  # GDD §7.4
	"supply_cart": "A Covenant cart that pays a reward if it is stopped.",  # GDD §7.4
	"holy_standard": "Marshal Vael's war banner, a zone that buffs the Covenant.",  # GDD §7.5
	"ward_crystal": "Crystals that keep a sanctified chamber's holy ground alive.",  # GDD §7.4
	"sacred_altar": "Altars whose fall weakens every soldier sent afterwards.",  # GDD §7.4
	"inquisitor": "The Reckoning's executioners, sent once the countdown ends.",  # GDD §15.0 run structure
	"cathedral_guardian": "A giant stone guardian that slams the ground and sweeps a beam.",  # GDD §7.4
	"alaric": "The Gravebreaker, master of the Desecrated Graveyard.",  # GDD §11
	"vael": "The Crimson Bulwark, who holds the March behind her shieldwall.",  # GDD §7.5
	"seraphine": "The Voice of the Dawn, judge of the Sanctum.",  # GDD §7.5
	"eye_initiate": "Robed, slow cultists of the Ancient Eye who come in great crowds.",  # GDD §15.0 Act II
	"eye_chanter": "Leads a squad of Initiates; a summon that falls near it is claimed.",  # GDD §15.0 Act II Claims
	"drowned_thrall": "One of your own dead, claimed by the Eye. Free its soul.",  # GDD §15.0 Act II Claims
	# --- Act II: Gullhaven Harbour ---
	"deep_kin": "Scaled fisherfolk of the deep who leap onto your front rank and swim at full speed.",  # owner-approved roster
	"tide_caller": "Fishwives of the Eye who raise a line of water that throws your dead back.",  # owner-approved roster
	"netcaster": "Net-menders who pin one of your dead in place until the net is cut.",  # owner-approved roster
	"deep_herald": "What the deep sends once the countdown ends.",  # GDD §15.0 run structure (the Harbour's Reckoning)
	"harbourmaster": "A hulking Deep Kin who drags your dead in on a chained anchor.",  # owner-approved proposal
	"merrow": "The Voice of the Deep, Gullhaven's priest, halfway through his Change.",  # owner-approved proposal
}

## Sprite key of an entry whose art is not "<category folder>/<id>":
## entry id -> SpriteBank key ("" = draw its icon instead).
const SPRITE_KEYS: Dictionary = {
	"profane_bishop": "summons/bishop",
	"inquisitor": "enemies/inquisitor",
	# --- Act II: Gullhaven Harbour (the Ancient Eye's art is in eye/) ---
	"deep_kin": "eye/deep_kin",
	"tide_caller": "eye/tide_caller",
	"netcaster": "eye/netcaster",
	"deep_herald": "eye/deep_herald",
	"harbourmaster": "eye/harbourmaster",
}

## Stat labels and record lines of the detail panel (format strings use
## %s / %d).
const TEXT: Dictionary = {
	"hp": "Base HP",  # TUNING (not in GDD)
	"damage": "Damage",  # TUNING (not in GDD)
	"speed": "Speed",  # TUNING (not in GDD)
	"armour": "Armour",  # TUNING (not in GDD)
	"recipe": "Recipe",  # TUNING (not in GDD)
	"stage": "Stage",  # TUNING (not in GDD)
	"arrives": "Arrives",  # TUNING (not in GDD)
	"arrives_at": "with %d:%02d left",  # TUNING (not in GDD) minutes, seconds of the countdown
	"slain": "Slain: %s",  # TUNING (not in GDD)
	"destroyed": "Destroyed: %s",  # TUNING (not in GDD)
	"best_level": "Best level reached: %d",  # TUNING (not in GDD)
	"skin_reward": "%s skin (%s)",  # TUNING (not in GDD) skin name, character name
}
## Lines on the detail panel of a locked entry, per page.
const LOCKED_HINT: Dictionary = {
	"spells": "Learn it in a run to record it.",  # TUNING (not in GDD)
	"summons": "Raise it in a run to record it.",  # TUNING (not in GDD)
	"soldiers": "Slay one to record it.",  # TUNING (not in GDD)
	"structures": "Destroy one to record it.",  # TUNING (not in GDD)
	"champions": "Slay one to record it.",  # TUNING (not in GDD)
	"bosses": "Face it to record it.",  # TUNING (not in GDD)
	"eye_soldiers": "Slay one to record it.",  # TUNING (not in GDD)
	"eye_champions": "Slay one to record it.",  # TUNING (not in GDD)
	"eye_bosses": "Face it to record it.",  # TUNING (not in GDD)
	"evolution": "Undiscovered.",  # TUNING (not in GDD) owner rule: no hint
}
## Name shown for a locked entry.
const LOCKED_NAME: String = "Unknown"  # TUNING (not in GDD)
## Name shown for an undiscovered evolution.
const LOCKED_EVOLUTION: String = "???"  # TUNING (not in GDD)
## Tag line (LABEL tier) of each section's entries on the detail panel.
const TAGS: Dictionary = {
	"spells": "Spell",  # TUNING (not in GDD)
	"spell_evolutions": "Spell evolution",  # TUNING (not in GDD)
	"summons": "Summon class",  # TUNING (not in GDD)
	"summon_evolutions": "Summon evolution",  # TUNING (not in GDD)
	"soldiers": "Covenant soldier",  # TUNING (not in GDD)
	"structures": "Covenant structure",  # TUNING (not in GDD)
	"champions": "Champion",  # TUNING (not in GDD)
	"bosses": "Stage boss",  # TUNING (not in GDD)
	"eye_soldiers": "Ancient Eye",  # TUNING (not in GDD)
	"eye_champions": "Champion of the Eye",  # TUNING (not in GDD)
	"eye_bosses": "Stage boss",  # TUNING (not in GDD)
}

# --- Layout (layout px at 1280x720; TUNING, not in GDD) -----------------------------

## Opacity (0..1) of the backdrop over the main menu (hides its hint strip).
const BACKDROP_ALPHA: float = 0.96  # TUNING (not in GDD)
## Outer size of the screen's ornate panel (px).
const PANEL_SIZE := Vector2(1196.0, 634.0)  # TUNING (not in GDD)
## Height (px) of the tab buttons and Back.
const TAB_HEIGHT: float = 42.0  # TUNING (not in GDD)
## Width (px) of the Back button.
const BACK_WIDTH: float = 100.0  # TUNING (not in GDD)
## Gap (px) between the last tab chip and Back.
const BACK_GAP: float = 10.0  # TUNING (not in GDD)
## Inset (px; x left / right, y top / bottom) of an achievement row's content.
const ROW_PAD := Vector2(16.0, 10.0)  # TUNING (not in GDD)
## Size of one codex tile button (px).
const TILE_SIZE := Vector2(80.0, 80.0)  # TUNING (not in GDD)
## Size of one boss tile button (px; two tiles and a gap wide).
const BOSS_TILE_SIZE := Vector2(168.0, 168.0)  # TUNING (not in GDD)
## Gap between tiles (px).
const TILE_GAP: int = 8  # TUNING (not in GDD)
## Tiles per grid row.
const COLUMNS: int = 8  # TUNING (not in GDD)
## Big boss tiles per grid row (each spans COLUMNS / BOSS_COLUMNS small tiles).
const BOSS_COLUMNS: int = 4  # TUNING (not in GDD)
## Width of the detail panel on the right of a codex page (px).
const DETAIL_WIDTH: float = 388.0  # TUNING (not in GDD)
## Size of the big portrait box on the detail panel (px).
const PORTRAIT_SIZE := Vector2(360.0, 244.0)  # TUNING (not in GDD)
## Largest integer scale of a portrait sprite (px per art px).
const PORTRAIT_MAX_SCALE: int = 5  # TUNING (not in GDD)
## Largest integer scale of an icon badge in a portrait (32 px badge -> 192 px).
const PORTRAIT_ICON_SCALE: int = 6  # TUNING (not in GDD)
## Items of a page that run the staggered entrance when its tab opens (the
## rest appear at once).
const STAGGER_COUNT: int = 24  # TUNING (not in GDD)
## Seconds between two items' entrances (quicker than UiMotionData's: tiles are many).
const STAGGER_INTERVAL: float = 0.018  # TUNING (not in GDD)
## Gap (px) kept between the achievement cards and the scroll bar.
const SCROLL_GUTTER: int = 16  # TUNING (not in GDD)
## Inset (px) of the stat lines from the detail card's sides.
const STATS_INSET: int = 14  # TUNING (not in GDD)
## Longest stat value (characters) kept on the label's line; a longer one
## (a recipe) is centred under its label.
const STAT_INLINE_CHARS: int = 24  # TUNING (not in GDD)
## Inset (px) of a tile's art from the tile's edge.
const TILE_INSET: float = 8.0  # TUNING (not in GDD)
## Flat fill of an entry's silhouette while it is not met yet (drawn with
## SILHOUETTE_SHADER: one solid colour).
const SILHOUETTE := Color(0.02, 0.01, 0.04, 1.0)  # TUNING (not in GDD)
## Flat colour of the 1 px rim around a silhouette.
const SILHOUETTE_RIM := Color(0.36, 0.22, 0.54, 0.9)  # TUNING (not in GDD)
## Multiply tint of an icon badge whose entry is not met yet (a dim ghost).
const GHOST_TINT := Color(0.38, 0.32, 0.46, 0.75)  # TUNING (not in GDD)
## Shader of the flat silhouettes.
const SILHOUETTE_SHADER: String = "res://scripts/fx/flat_silhouette.gdshader"
## Opacity (0..1) of a locked tile's frame and "?" glyph.
const LOCKED_ALPHA: float = 0.55  # TUNING (not in GDD)

# --- Achievements page ---------------------------------------------------------------

## Height (px) of one achievement row.
const ROW_HEIGHT: float = 96.0  # TUNING (not in GDD)
## Size (px) of the badge on an achievement row (a 32 px badge at x2).
const BADGE_SIZE := Vector2(64.0, 64.0)  # TUNING (not in GDD)
## Width (px) of an achievement row's progress bar.
const BAR_WIDTH: float = 400.0  # TUNING (not in GDD)
## Height (px) of an achievement row's progress bar.
const BAR_HEIGHT: float = 14.0  # TUNING (not in GDD)
## Width (px) of the reward column on an achievement row.
const REWARD_WIDTH: float = 330.0  # TUNING (not in GDD)
## Size (px) of the reward preview (a skin, a badge) on an achievement row.
const REWARD_PREVIEW := Vector2(64.0, 64.0)  # TUNING (not in GDD)
## Badge icon (assets/sprites/icons/<id>.png) of each achievement; one
## without art draws the achievement's fallback IconGlyph kind.
const ACHIEVEMENT_ICONS: Dictionary = {
	"bone_legion": "ach_bone_legion",  # TUNING (not in GDD)
	"heretics_bane": "ach_heretics_bane",  # TUNING (not in GDD)
	"dread_sovereign": "ach_dread_sovereign",  # TUNING (not in GDD)
	"dawn_extinguished": "ach_dawn_extinguished",  # TUNING (not in GDD)
	# --- Act II: Gullhaven Harbour ---
	"low_tide": "ach_low_tide",  # TUNING (not in GDD)
}
## IconGlyph kind drawn when an achievement badge PNG is missing.
const ACHIEVEMENT_FALLBACK_ICONS: Dictionary = {
	"bone_legion": "warrior",
	"heretics_bane": "dark_benediction",
	"dread_sovereign": "dark_command",
	"dawn_extinguished": "hyper_badge",
	# --- Act II: Gullhaven Harbour ---
	"low_tide": "brinewalker",
}
## Screen title (TITLE tier).
const TITLE: String = "Codex"  # TUNING (not in GDD)
## Label over an achievement row's reward.
const REWARD_LABEL: String = "Reward"  # TUNING (not in GDD)
## Header of the achievements section, and of the feats (the skin and Hyper
## unlocks that are not achievements) under it.
const ACHIEVEMENTS_HEADER: String = "Achievements"  # TUNING (not in GDD)
## Header of the feats section.
const FEATS_HEADER: String = "Feats"  # TUNING (not in GDD)
## Name, goal and reward text of the Hyper mode unlock feat.
const HYPER_FEAT := {"name": "Beyond the Dawn", "goal": "Slay Grand Inquisitor Seraphine", "reward": "Hyper mode"}  # TUNING (not in GDD) (HyperData unlock)
## Name, goal and reward text of the Hyper skins feat (one per character).
const HYPER_SKINS_FEAT := {"name": "Gilded Legion", "goal": "Clear the Sanctum on Hyper with each character", "reward": "A Hyper skin per character"}  # TUNING (not in GDD) (SkinData Hyper skins)
## Reward line of an achievement's Soul Ash bounty ("+%d Soul Ash").
const BOUNTY_TEXT: String = "+%d Soul Ash"  # TUNING (not in GDD)
## Stamp on an earned row.
const EARNED_TEXT: String = "Earned"  # TUNING (not in GDD)
## Count under the title: earned, total.
const EARNED_COUNT: String = "%d / %d earned"  # TUNING (not in GDD)
## Count under the title on a codex page: recorded, total.
const RECORDED_COUNT: String = "%d / %d recorded"  # TUNING (not in GDD)


## True when `id` is an entry of codex category `cat` (unknown ids are
## never recorded or saved).
static func is_known(cat: String, id: String) -> bool:
	match cat:
		SPELL:
			return AbilityData.SPELLS.has(id)
		SUMMON:
			return SUMMON_ORDER.has(id)
		ENEMY:
			return SOLDIERS.has(id) or STRUCTURES.has(id) or CHAMPIONS.has(id) \
					or EYE_SOLDIERS.has(id) or EYE_CHAMPIONS.has(id)
		BOSS:
			return BOSSES.has(id) or EYE_BOSSES.has(id)
	return false


## Number of entries in category `cat` (the evolutions are not a category).
static func total(cat: String) -> int:
	match cat:
		SPELL:
			return AbilityData.SPELL_ORDER.size()
		SUMMON:
			return SUMMON_ORDER.size()
		ENEMY:
			return SOLDIERS.size() + STRUCTURES.size() + CHAMPIONS.size() + EYE_SOLDIERS.size() + EYE_CHAMPIONS.size()
		BOSS:
			return BOSSES.size() + EYE_BOSSES.size()
	return 0


## The data row of Covenant kind or boss `id` (max_hp, damage, move_speed,
## display_name...; {} when unknown).
static func enemy_row(id: String) -> Dictionary:
	if id == "inquisitor":
		return EnemyData.RECKONING_ENEMY
	for table: Dictionary in [EnemyData.ENEMIES, MarchEnemyData.ENEMIES, BattleSisterData.ENEMIES, SanctumEnemyData.ENEMIES, SanctumObjectiveData.STRUCTURES]:
		if table.has(id):
			return table[id]
	var eye := EnemyDirector.eye_def(id)  # Act II kinds ({} when none).
	if not eye.is_empty():
		return eye
	match id:
		"alaric":
			return EnemyData.BOSS
		"vael":
			return MarchEnemyData.VAEL
		"seraphine":
			return SeraphineData.BOSS
		"merrow":
			return MerrowData.BOSS  # Act II: Gullhaven Harbour.
	return {}
