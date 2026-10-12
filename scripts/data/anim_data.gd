## AnimData: one-shot effect animations (docs/art/ART_BIBLE.md "Effects").
## Each animation is a horizontal strip of square frames at
## res://assets/sprites/effects/<id>.png (made by tools/prepare_sprite.py
## --anim from a GIF or a ChatGPT / SpriteCook sprite sheet); the frame count
## is the strip width / height. An effect plays its animation once, scaled to
## the effect's gameplay radius, instead of its code-drawn shape; without the
## PNG the drawn shape is used. Purely visual. Data only.
class_name AnimData
extends RefCounted

## Animation id -> {duration: seconds for one play-through,
##                  fill: drawn diameter as a multiple of the effect's
##                        gameplay diameter (art often has empty margins)}.
const ANIMS: Dictionary = {
	"shadow_blast": {"duration": 0.4, "fill": 1.15},  # TUNING (not in GDD) test effect
	"frost_shatter": {"duration": 0.35, "fill": 1.15},  # TUNING (not in GDD) Winter Revenant shatter
	"frost_nova": {"duration": 0.5, "fill": 1.15},  # TUNING (not in GDD) Winter Revenant death nova
	"dread_rally": {"duration": 0.6, "fill": 1.15},  # TUNING (not in GDD) Dread Rally burst (10 frames, ART_BIBLE)
	"grave_step_trail": {"duration": 0.3, "fill": 1.3},  # TUNING (not in GDD) Grave Step departure puff (6 frames)
	"seraphine_nova": {"duration": 0.55, "fill": 1.05},  # TUNING (not in GDD) Seraphine's Judgment nova blast (10 frames)
	"holy_beam": {"duration": 0.4, "fill": 1.2},  # TUNING (not in GDD) Seraphine's beams igniting (6 frames)
	"relic_shatter": {"duration": 0.8, "fill": 1.15},  # TUNING (not in GDD) Seraphine's death, the relic shattering (10 frames)
	"soul_lightning": {"duration": 0.2, "fill": 1.4},  # TUNING (not in GDD) Soul Chains strike flash at each struck foe (6 frames)
	"bone_wall_rise": {"duration": 0.25, "fill": 1.2},  # TUNING (not in GDD) a Bone Wall segment bursting out of the ground (6 frames)
	"bone_wall_burst": {"duration": 0.35, "fill": 1.15},  # TUNING (not in GDD) Charnel Bastion shrapnel burst per segment (8 frames)
	"wither_aura": {"duration": 0.35, "fill": 1.1},  # TUNING (not in GDD) one Wither / Necrotic Blight pulse ring (8 frames)
	"doom_burst": {"duration": 0.4, "fill": 1.15},  # TUNING (not in GDD) Doom Brand detonation of a branded death (8 frames)
	"raise_dead": {"duration": 0.45, "fill": 1.2},  # TUNING (not in GDD) a raised skeleton clawing out of the ground (8 frames)
	"legion_burst": {"duration": 0.35, "fill": 1.15},  # TUNING (not in GDD) a Legion of Bones skeleton bursting into shards (8 frames)
}
## Duration (s) for an animation id missing from ANIMS.
const DEFAULT_DURATION: float = 0.4  # TUNING (not in GDD)
## Fill for an animation id missing from ANIMS.
const DEFAULT_FILL: float = 1.1  # TUNING (not in GDD)
## Stored frame size (px) that prepare_sprite.py --anim produces.
const FRAME_PX: int = 128  # TUNING (not in GDD)
