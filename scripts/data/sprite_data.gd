## SpriteData: on-screen sizes for the optional sprite art (docs/art/ART_BIBLE.md).
## A sprite key is "<category>/<id>", matching res://assets/sprites/<category>/<id>.png.
## When a PNG exists, SpriteBank draws it instead of the code-drawn glyph, scaled
## so its height (in world px) is the value below. Keys without a file keep
## their glyph, so art can be added one piece at a time. Data only, no logic.
class_name SpriteData
extends RefCounted

## Root folder of the in-game sprite PNGs (prepared by tools/prepare_sprite.py).
const ROOT: String = "res://assets/sprites/"

## On-screen height in world px per sprite key (ART_BIBLE.md manifest sizes).
const HEIGHTS: Dictionary = {
	"player/necromancer": 56.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/warrior": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/archer": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/mage": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/mender": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/warder": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/bishop": 52.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/death_knight": 52.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/lich": 52.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/abomination": 88.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/rogue": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/gargoyle": 56.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/frost_wraith": 48.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/risen": 36.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/shadow_reaper": 48.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/cathedral_horror": 64.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/recruit": 40.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/footman": 48.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/archer": 40.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/chaplain": 42.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/purifier": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/templar": 52.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/inquisitor": 64.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/shieldbearer": 50.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/banner_bearer": 50.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/halberdier": 50.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"bosses/alaric": 120.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"bosses/vael": 120.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/outpost": 96.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/ward_generator": 80.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/supply_cart": 72.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/holy_standard": 72.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/watchtower": 96.0,  # TUNING (not in GDD) ART_BIBLE manifest size
}

## Height (world px) used for a key missing from HEIGHTS.
const DEFAULT_HEIGHT: float = 44.0  # TUNING (not in GDD)

## Vertical offset of the sprite's centre, as a fraction of its height: the
## glyph origin is roughly the unit's body centre, so the sprite sits a little
## higher than its feet (negative = up).
const CENTER_OFFSET: float = -0.12  # TUNING (not in GDD)

## Multiplier applied to the sprite's colour during a hit flash (values above 1
## brighten it towards white; dark outlines stay dark).
const FLASH_MODULATE: Color = Color(2.6, 2.6, 2.6, 1.0)  # TUNING (not in GDD)

## Fraction of an icon box's size that a sprite fills when drawn as a HUD /
## card icon (SpriteBank.icon_cap).
const ICON_FILL: float = 0.9  # TUNING (not in GDD)

## Longest side (world px) of flat sprites drawn by SpriteBank.draw_flat():
## projectiles (art pointing right) and orbs. Keys "projectiles/<id>".
const FLAT_SIZES: Dictionary = {
	"projectiles/shadow_bolt": 22.0,  # TUNING (not in GDD)
	"projectiles/void_bolt": 30.0,  # TUNING (not in GDD)
	"projectiles/void_shard": 14.0,  # TUNING (not in GDD)
	"projectiles/arrow": 20.0,  # TUNING (not in GDD)
	"projectiles/enemy_arrow": 20.0,  # TUNING (not in GDD)
	"projectiles/mage_orb": 20.0,  # TUNING (not in GDD)
	"projectiles/priest_bolt": 14.0,  # TUNING (not in GDD)
	"projectiles/frost_bolt": 20.0,  # TUNING (not in GDD)
	"projectiles/radiant_bolt": 20.0,  # TUNING (not in GDD)
	"projectiles/bone_spear": 26.0,  # TUNING (not in GDD)
	"projectiles/ossuary_lance": 44.0,  # TUNING (not in GDD)
	"projectiles/orb": 18.0,  # TUNING (not in GDD) Shadow Orb Shield orb
}
## Longest side (px) for a flat sprite key missing from FLAT_SIZES.
const DEFAULT_FLAT_SIZE: float = 20.0  # TUNING (not in GDD)
## Fraction of an icon box that icon art (assets/sprites/icons/) fills.
const ICON_ART_FILL: float = 0.92  # TUNING (not in GDD)

## Drop-shadow ellipse under a sprite: width as a fraction of the sprite height.
const SHADOW_WIDTH: float = 0.55  # TUNING (not in GDD)
## Drop-shadow ellipse height as a fraction of its width.
const SHADOW_SQUASH: float = 0.35  # TUNING (not in GDD)
## Drop-shadow opacity (0-1).
const SHADOW_ALPHA: float = 0.35  # TUNING (not in GDD)
