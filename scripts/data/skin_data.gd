## SkinData — designer data for CHARACTER SKINS (owner-approved; GDD §3.4 /
## §11.4 "cosmetic, no default mechanical bonuses"; GDD §15.0 resolves open
## question 42: skins are PURELY COSMETIC, they never touch a stat). No logic
## beyond lookups; Meta decides what is unlocked, SkinGlyphs draws them and the
## pre-run setup screen (PreRunHyperSkins) offers them.
##
## Every playable character has:
##   * its DEFAULT look ("<character>_default", the character's own sprite),
##   * a HYPER skin ("<character>_hyper"), unlocked by clearing the Sanctum
##     of Judgment on Hyper (HyperData) with that character,
## and four characters have an ACHIEVEMENT skin (ACHIEVEMENT_SKINS).
##
## Rendering: a skin's sprite key is "player/<character>_<skin>" (the default
## skin uses the character's own key). While that PNG does not exist yet the
## character's sprite (or, without art, its code-drawn glyph) is drawn with
## the skin's PALETTE: `tint` multiplies the sprite / robe colours (above 1
## brightens), `accent` colours an emblem drawn over it and a faint aura ring,
## `glow` colours the eyes and the staff orb of the glyph, and `emblem` picks
## the emblem shape ("none", "crown", "halo", "broken_halo", "corona",
## "mask"). So every skin is visible before its art exists.
##
## Characters: the twelve playable characters (agent C's CharacterData, which
## owns their stats and default looks; RunConfig.character_id). The list is
## mirrored here so skins work before / without the character system; the
## run uses DEFAULT_CHARACTER when RunConfig has no character id.
class_name SkinData
extends RefCounted

## Character used when no character system / id exists (today's necromancer).
const DEFAULT_CHARACTER: String = "gravecaller"
## Character ids in UI order (CharacterData order).
const CHARACTER_ORDER := ["gravecaller", "umbral_warden", "voidcaller", "bone_oracle", "carrion_lord",
	"fallen_confessor", "plague_scholar", "doomsayer", "barrow_warden", "soulbinder", "wither_witch", "grave_herald"]
## Character id -> UI name.
const CHARACTER_NAMES := {
	"gravecaller": "The Gravecaller",  # GDD §11.4
	"umbral_warden": "The Umbral Warden",  # TUNING (not in GDD) character list
	"voidcaller": "The Voidcaller",  # TUNING (not in GDD) character list
	"bone_oracle": "The Bone Oracle",  # GDD §11.4
	"carrion_lord": "The Carrion Lord",  # TUNING (not in GDD) character list
	"fallen_confessor": "The Fallen Confessor",  # GDD §11.4
	"plague_scholar": "The Plague Scholar",  # GDD §11.4
	"doomsayer": "The Doomsayer",  # TUNING (not in GDD) character list
	"barrow_warden": "The Barrow Warden",  # TUNING (not in GDD) character list
	"soulbinder": "The Soulbinder",  # TUNING (not in GDD) character list
	"wither_witch": "The Wither Witch",  # TUNING (not in GDD) character list
	"grave_herald": "The Grave Herald",  # TUNING (not in GDD) character list
}
## Character id -> its own sprite key (the default skin draws this; the
## Gravecaller is the existing necromancer art).
const BASE_SPRITES := {
	"gravecaller": "player/necromancer",  # ART_BIBLE (existing art)
	"umbral_warden": "player/umbral_warden",  # ART_BIBLE character row
	"voidcaller": "player/voidcaller",  # ART_BIBLE character row
	"bone_oracle": "player/bone_oracle",  # ART_BIBLE character row
	"carrion_lord": "player/carrion_lord",  # ART_BIBLE character row
	"fallen_confessor": "player/fallen_confessor",  # ART_BIBLE character row
	"plague_scholar": "player/plague_scholar",  # ART_BIBLE character row
	"doomsayer": "player/doomsayer",  # ART_BIBLE character row
	"barrow_warden": "player/barrow_warden",  # ART_BIBLE character row
	"soulbinder": "player/soulbinder",  # ART_BIBLE character row
	"wither_witch": "player/wither_witch",  # ART_BIBLE character row
	"grave_herald": "player/grave_herald",  # ART_BIBLE character row
}

## Where a palette-fallback emblem sits on character SPRITE art: the top of
## the head relative to the sprite centre, in fractions of the drawn height
## (x, y). Tuned on the Gravecaller art (hood slightly left of centre).
const SPRITE_HEAD_TOP := Vector2(-0.08, -0.44)  # TUNING (not in GDD)
## Emblem size unit on sprite art, as a fraction of the drawn height.
const SPRITE_HEAD_UNIT: float = 0.16  # TUNING (not in GDD)
## Top of the head on the code-drawn glyph, in body radii from its origin.
const GLYPH_HEAD_TOP := Vector2(0.0, -1.12)  # TUNING (not in GDD)
## Emblem size unit on the glyph, in body radii.
const GLYPH_HEAD_UNIT: float = 0.6  # TUNING (not in GDD)
## Aura ring under a skinned necromancer: radius (px), vertical squash 0..1,
## y offset (px, the feet), line width (px) and alpha 0..1 of the accent.
const AURA_RADIUS: float = 26.0  # TUNING (not in GDD)
## Vertical squash of the aura ellipse (0..1).
const AURA_SQUASH: float = 0.45  # TUNING (not in GDD)
## Aura ring y offset (px below the origin; ViewData.PLAYER_RING_OFFSET).
const AURA_OFFSET: float = 20.0  # TUNING (not in GDD)
## Aura ring line width (px, before the squash).
const AURA_WIDTH: float = 2.0  # TUNING (not in GDD)
## Aura ring opacity 0..1.
const AURA_ALPHA: float = 0.7  # TUNING (not in GDD)

## Palette of every DEFAULT skin: the art / glyph unchanged.
const DEFAULT_LOOK := {"tint": Color(1, 1, 1), "accent": Color(0, 0, 0, 0), "glow": Color(0.42, 0.95, 0.55), "emblem": "none"}  # TUNING (not in GDD)

## Character id -> name of its Hyper skin (owner-named for four; the rest
## follow the same "<epithet> <title>" pattern, gilded or eclipsed).
const HYPER_NAMES := {
	"gravecaller": "Eclipsed Gravecaller",  # owner-named
	"umbral_warden": "Sunless Warden",  # TUNING (not in GDD)
	"voidcaller": "Starless Voidcaller",  # TUNING (not in GDD)
	"bone_oracle": "Gilded Oracle",  # owner-named
	"carrion_lord": "Crowned Carrion Lord",  # TUNING (not in GDD)
	"fallen_confessor": "Fallen Seraph",  # owner-named
	"plague_scholar": "Blighted Scholar",  # owner-named
	"doomsayer": "Final-Hour Doomsayer",  # TUNING (not in GDD)
	"barrow_warden": "Gilded Barrow King",  # TUNING (not in GDD)
	"soulbinder": "Radiant Soulbinder",  # TUNING (not in GDD)
	"wither_witch": "Thorn-Crowned Witch",  # TUNING (not in GDD)
	"grave_herald": "Golden Herald",  # TUNING (not in GDD)
}
## Sprite-multiply tint of each Hyper skin (gilded; the Eclipsed Gravecaller
## and the Sunless / Starless pair are darkened with a gold corona instead).
const HYPER_TINTS := {
	"gravecaller": Color(0.42, 0.36, 0.5),  # TUNING (not in GDD) eclipsed: dark violet, gold corona
	"umbral_warden": Color(0.45, 0.42, 0.5),  # TUNING (not in GDD)
	"voidcaller": Color(0.4, 0.38, 0.55),  # TUNING (not in GDD)
	"bone_oracle": Color(1.25, 1.05, 0.6),  # TUNING (not in GDD) gilded
	"carrion_lord": Color(1.15, 0.95, 0.55),  # TUNING (not in GDD) gilded
	"fallen_confessor": Color(1.3, 1.15, 0.75),  # TUNING (not in GDD) gilded, radiant
	"plague_scholar": Color(0.95, 1.05, 0.5),  # TUNING (not in GDD) blighted gold-green
	"doomsayer": Color(1.1, 0.9, 0.55),  # TUNING (not in GDD) gilded
	"barrow_warden": Color(1.2, 1.0, 0.55),  # TUNING (not in GDD) gilded
	"soulbinder": Color(1.25, 1.1, 0.7),  # TUNING (not in GDD) gilded, radiant
	"wither_witch": Color(1.0, 0.85, 0.5),  # TUNING (not in GDD) gilded
	"grave_herald": Color(1.3, 1.1, 0.55),  # TUNING (not in GDD) gilded
}
## Emblem and accent shared by every Hyper skin: a gold sun corona.
const HYPER_ACCENT := Color(1.0, 0.82, 0.3)  # TUNING (not in GDD) Palette.GOLD
## Eye / orb glow of every Hyper skin.
const HYPER_GLOW := Color(1.0, 0.9, 0.45)  # TUNING (not in GDD)
## Emblem of every Hyper skin.
const HYPER_EMBLEM: String = "corona"  # TUNING (not in GDD)

## The four achievement skins (owner-approved). Keys:
##   character     owning character id.
##   display_name  UI name.
##   look          ART_BIBLE look line (also the setup-screen tooltip).
##   unlock        {"type": "achievement", "id": MetaData achievement id}
##                 or {"type": "lifetime", "stat": Meta.lifetime key,
##                 "goal": count} (checked by Meta.is_skin_unlocked()).
##   unlock_text   UI condition shown while locked (card tooltip, end screen).
##   unlock_short  short form of it on the setup-screen card.
##   tint / accent / glow / emblem   palette fallback (see the header).
const ACHIEVEMENT_SKINS := {
	"dread_sovereign": {
		"character": "gravecaller",
		"display_name": "The Dread Sovereign",  # GDD §11.4
		"look": "Black armour, royal cloak, a gold crown",  # GDD §11.4
		# Owner rule: Seraphine slain while commanding the four GDD roles
		# (the Dread Sovereign achievement's role check, Game._on_boss_defeated).
		"unlock": {"type": "lifetime", "stat": "seraphine_kills_full_army", "goal": 1},  # owner-approved
		"unlock_text": "Slay Grand Inquisitor Seraphine while commanding Warriors, Archers, Mages and a priest order",
		"unlock_short": "Slay Seraphine with all four roles",
		"tint": Color(0.3, 0.28, 0.34),  # TUNING (not in GDD) near-black
		"accent": Color(1.0, 0.8, 0.28),  # TUNING (not in GDD) gold trim
		"glow": Color(1.0, 0.78, 0.3),  # TUNING (not in GDD)
		"emblem": "crown",
	},
	"ivory_seer": {
		"character": "bone_oracle",
		"display_name": "The Ivory Seer",  # owner-named
		"look": "Polished ivory bone mask and mantle, spectral blue eyes",  # TUNING (not in GDD)
		"unlock": {"type": "achievement", "id": "bone_legion"},  # owner-approved (1,000 Warrior killing blows)
		"unlock_text": "Earn Bone Legion: Skeleton Warriors slay 1,000 foes",
		"unlock_short": "Earn Bone Legion",
		"tint": Color(1.35, 1.3, 1.15),  # TUNING (not in GDD) bleached ivory
		"accent": Color(0.95, 0.93, 0.82),  # TUNING (not in GDD)
		"glow": Color(0.6, 0.88, 1.0),  # TUNING (not in GDD) spectral blue
		"emblem": "halo",
	},
	"plague_doctor": {
		"character": "plague_scholar",
		"display_name": "The Plague Doctor",  # owner-named
		"look": "Beaked leather mask, wide-brimmed hat, waxed coat, green censer",  # TUNING (not in GDD)
		"unlock": {"type": "lifetime", "stat": "rot_kills", "goal": 5000},  # owner-approved
		"unlock_text": "Slay 5,000 enemies while they Rot (Plague Cloud)",
		"unlock_short": "Slay 5,000 Rotting foes",
		"tint": Color(0.6, 0.55, 0.42),  # TUNING (not in GDD) leather brown
		"accent": Color(0.55, 0.88, 0.3),  # TUNING (not in GDD) sickly green
		"glow": Color(0.62, 0.95, 0.3),  # TUNING (not in GDD)
		"emblem": "mask",
	},
	"heretic_saint": {
		"character": "fallen_confessor",
		"display_name": "The Heretic Saint",  # owner-named
		"look": "Defiled white Covenant vestments, a cracked crimson halo",  # TUNING (not in GDD)
		"unlock": {"type": "lifetime", "stat": "high_confessor_kills", "goal": 50},  # owner-approved
		"unlock_text": "Slay 50 High Confessors",
		"unlock_short": "Slay 50 High Confessors",
		"tint": Color(1.2, 1.1, 1.0),  # TUNING (not in GDD) pale vestments
		"accent": Color(0.88, 0.16, 0.22),  # TUNING (not in GDD) crimson
		"glow": Color(0.95, 0.25, 0.3),  # TUNING (not in GDD)
		"emblem": "broken_halo",
	},
}


## Character id of a RunConfig-style value (unknown / empty -> DEFAULT_CHARACTER).
static func character_or_default(id: String) -> String:
	return id if BASE_SPRITES.has(id) else DEFAULT_CHARACTER


## UI name of character `id`.
static func character_name(id: String) -> String:
	return String(CHARACTER_NAMES.get(id, CHARACTER_NAMES[DEFAULT_CHARACTER]))


## Id of the default skin of character `character`.
static func default_skin(character: String) -> String:
	return character_or_default(character) + "_default"


## Skin ids of character `character` in UI order: default, Hyper, then its
## achievement skin (if any).
static func skins_for(character: String) -> PackedStringArray:
	var ch := character_or_default(character)  # Known character id.
	var out := PackedStringArray([ch + "_default", ch + "_hyper"])  # Ids.
	for id: String in ACHIEVEMENT_SKINS:
		if String(ACHIEVEMENT_SKINS[id]["character"]) == ch:
			out.append(id)
	return out


## Every skin id (all characters), in character order.
static func all_ids() -> PackedStringArray:
	var out := PackedStringArray()  # Ids.
	for ch: String in CHARACTER_ORDER:
		out.append_array(skins_for(ch))
	return out


## True when `id` names a skin.
static func has(id: String) -> bool:
	return ACHIEVEMENT_SKINS.has(id) or _generated_character(id) != ""


## The skin row of `id` ({} for an unknown id) with the keys of
## ACHIEVEMENT_SKINS plus "kind" ("default", "hyper" or "achievement") and
## "sprite" (its sprite key). Default and Hyper rows are built from the
## per-character tables above.
static func skin(id: String) -> Dictionary:
	if ACHIEVEMENT_SKINS.has(id):
		var row: Dictionary = (ACHIEVEMENT_SKINS[id] as Dictionary).duplicate()
		row["kind"] = "achievement"
		row["sprite"] = "player/%s_%s" % [row["character"], id]
		return row
	var ch := _generated_character(id)  # Owning character ("" = unknown id).
	if ch == "":
		return {}
	if id.ends_with("_default"):
		var d: Dictionary = DEFAULT_LOOK.duplicate()
		d["character"] = ch
		d["display_name"] = character_name(ch)
		d["look"] = "The character's own look"
		d["unlock"] = {"type": "default"}
		d["unlock_text"] = ""
		d["unlock_short"] = ""
		d["kind"] = "default"
		d["sprite"] = String(BASE_SPRITES[ch])
		return d
	return {
		"character": ch,
		"display_name": String(HYPER_NAMES[ch]),
		"look": "Gilded / eclipsed regalia under a gold sun corona",
		"unlock": {"type": "hyper_clear", "stage": HyperData.SKIN_STAGE_ID},
		"unlock_text": "Clear the Sanctum of Judgment on Hyper as %s" % character_name(ch),
		"unlock_short": "Clear the Sanctum on Hyper",
		"tint": HYPER_TINTS[ch],
		"accent": HYPER_ACCENT,
		"glow": HYPER_GLOW,
		"emblem": HYPER_EMBLEM,
		"kind": "hyper",
		"sprite": "player/%s_hyper" % ch,
	}


## Character of a generated "<character>_default" / "<character>_hyper" id
## ("" when `id` is not one).
static func _generated_character(id: String) -> String:
	for suffix: String in ["_default", "_hyper"]:
		if id.ends_with(suffix):
			var ch := id.substr(0, id.length() - suffix.length())  # Candidate character id.
			if BASE_SPRITES.has(ch):
				return ch
	return ""
