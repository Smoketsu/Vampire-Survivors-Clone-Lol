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
## Each duration equals the code duration of the call that plays it (named in
## the comment), so an effect lives exactly as long with or without its art
## and the autotest's effect counts do not change (Shadow Blast's 0.4 s
## predates that rule). Fills put the art's outer edge (95% of its alpha) at
## about the gameplay radius, like Shadow Blast (measured per strip).
const ANIMS: Dictionary = {
	"shadow_blast": {"duration": 0.4, "fill": 1.15},  # TUNING (not in GDD) Shadow Blast ring (8 frames of 128 px, the first strip)
	"frost_shatter": {"duration": 0.3, "fill": 1.2},  # TUNING (not in GDD) Winter Revenant shatter (6 frames of 128 px; winter_revenant.gd 0.3 s)
	"frost_nova": {"duration": 0.45, "fill": 1.2},  # TUNING (not in GDD) Winter Revenant death nova (8 frames of 128 px; 0.45 s; the frost tips reach the nova radius)
	"dread_rally": {"duration": 0.6, "fill": 1.15},  # TUNING (not in GDD) Dread Rally burst (10 frames of 256 px; RALLY_RING_TIME; the shockwave tips reach the knockback radius)
	"grave_step_trail": {"duration": 0.3, "fill": 1.3},  # TUNING (not in GDD) Grave Step departure puff (6 frames of 128 px; 0.3 s)
	"seraphine_nova": {"duration": 0.55, "fill": 1.45},  # TUNING (not in GDD) Seraphine's Judgment nova (9 frames of 512 px built from one high-res ring, centre empty for the impact flash; 0.55 s; the ring peaks at 0.69 of the frame half, so 1.45 puts it on nova_radius)
	"holy_beam": {"duration": 0.4, "fill": 1.2},  # TUNING (not in GDD) Seraphine's beams igniting (6 frames of 192 px; 0.4 s)
	"relic_shatter": {"duration": 0.8, "fill": 1.2},  # TUNING (not in GDD) Seraphine's death, the relic shattering (10 frames of 256 px; 0.8 s)
	"soul_lightning": {"duration": 0.18, "fill": 1.4},  # TUNING (not in GDD) Soul Chains strike flash at each struck foe (6 frames of 128 px; 0.18 s)
	"bone_wall_rise": {"duration": 0.25, "fill": 1.2},  # TUNING (not in GDD) a Bone Wall segment bursting out of the ground (6 frames of 128 px; 0.25 s)
	"bone_wall_burst": {"duration": 0.3, "fill": 1.15},  # TUNING (not in GDD) Charnel Bastion shrapnel burst per segment (8 frames of 128 px; 0.3 s)
	"wither_aura": {"duration": 0.3, "fill": 1.2},  # TUNING (not in GDD) one Wither / Necrotic Blight pulse ring (8 frames of 256 px; 0.3 s; the mist tips reach the aura radius)
	"doom_burst": {"duration": 0.35, "fill": 1.15},  # TUNING (not in GDD) Doom Brand detonation of a branded death (8 frames of 128 px; 0.35 s)
	"raise_dead": {"duration": 0.45, "fill": 1.2},  # TUNING (not in GDD) a raised skeleton clawing out of the ground (8 frames of 128 px; 0.45 s; the dirt mound sits at its feet)
	"legion_burst": {"duration": 0.3, "fill": 1.15},  # TUNING (not in GDD) a Legion of Bones skeleton bursting into shards (8 frames of 128 px; 0.3 s)
	"corpse_explosion": {"duration": 0.3, "fill": 1.05},  # TUNING (not in GDD) Corpse Explosion burst (8 frames of 192 px; corpse_explosion.gd ring 0.3 s)
	"grave_eruption": {"duration": 0.3, "fill": 1.15},  # TUNING (not in GDD) Grave Eruption bone-spike ring (8 frames of 192 px; 0.3 s)
	"abyssal_detonation": {"duration": 0.4, "fill": 1.1},  # TUNING (not in GDD) Abyssal Detonation first hit, the vortex spinning inward (8 frames of 256 px built from the largest drawn vortex; EffectManager.abyss() 0.4 s)
	"abyssal_burst": {"duration": 0.3, "fill": 1.1},  # TUNING (not in GDD) Abyssal Detonation second hit, the burst (7 frames of 256 px from the same sheet; ring 0.3 s)
	"enemy_death": {"duration": 0.35, "fill": 1.4},  # TUNING (not in GDD) a Covenant soldier's death pop (6 frames of 128 px; EffectManager.pop() 0.35 s)
	"undead_death": {"duration": 0.35, "fill": 1.4},  # TUNING (not in GDD) a summon's death pop (6 frames of 128 px; pop() 0.35 s)
	"summon_rise": {"duration": 0.5, "fill": 1.7},  # TUNING (not in GDD) a summon rising (8 frames of 128 px; spawn_ring() 0.5 s; the dirt circle sits at its feet)
	"holy_impact": {"duration": 0.4, "fill": 1.1},  # TUNING (not in GDD) Covenant hammer / boss slam (8 frames of 192 px; EffectManager.impact() 0.4 s)
	"soul_nova": {"duration": 0.6, "fill": 1.33},  # TUNING (not in GDD) the Soul Nova power-up's screen ring (10 frames of 512 px built from one high-res ring; powerup_manager.gd 0.6 s; the ring peaks at 0.75 of the frame half)
	"chest_open": {"duration": 0.6, "fill": 1.15},  # TUNING (not in GDD) a treasure chest bursting open (8 frames of 192 px; Game.open_chest() 0.6 s, seen once the reveal closes)
	# Art-only bursts (AnimBursts, outside the Effect pool: their durations are free).
	"bolt_impact": {"duration": 0.25, "fill": 1.1},  # TUNING (not in GDD) a Shadow Bolt / Void Bolt / Void Shard hit splash (6 frames of 128 px)
	"level_up": {"duration": 0.8, "fill": 1.0},  # TUNING (not in GDD) the level-up column on the necromancer (8 frames of 192 px; tall art, base on the frame's bottom row)
	"evolution": {"duration": 0.9, "fill": 1.3},  # TUNING (not in GDD) an evolution from a chest: vortex collapsing into a violet-gold flash (10 frames of 192 px)
	# --- Act II: Fallen Seraph --- (art-only bursts, EffectManager.burst())
	"seraph_dive": {"duration": 0.35, "fill": 1.3},  # TUNING (not in GDD) the Fallen Seraph's dive impact: black feathers and ash bursting outward (SeraphBehavior)
	# --- Act II: Gullhaven Harbour ---
	"tide_splash": {"duration": 0.4, "fill": 1.2},  # TUNING (not in GDD) a splash of sea water: Deep Kin landing, the Harbourmaster's anchor, Abbot Merrow's blows, a bell buoy sinking (6 frames of 128 px; EffectManager.impact() 0.4 s)
	# --- Act II: the Hollow Archive ---
	"ink_burst": {"duration": 0.35, "fill": 1.1},  # TUNING (not in GDD) Forbidden Verse ink burst of an inscribed death (6 frames of 128 px; 0.35 s, as its code ring)
	# --- Act II: Ul-Thalos ---
	"vhalneth_slam": {"duration": 0.4, "fill": 1.3},  # TUNING (not in GDD) one of Vhal'Neth's arms crashing down: a ring of sea spray and foam (8 frames of 192 px; ArmKit EffectManager.impact() 0.4 s)
	"drowned_tendrils": {"duration": 0.35, "fill": 1.3},  # TUNING (not in GDD) Call of the Drowned eruption: tendrils lashing up out of a whirlpool (8 frames of 128 px; CallOfTheDrowned ring() 0.35 s)
	"vhalneth_gaze": {"duration": 1.4, "fill": 1.15},  # TUNING (not in GDD) Vhal'Neth's gaze opening on the ground (8 frames of 256 px; VhalnethHazards ring() = VhalnethData gaze_telegraph 1.4 s)
	# --- Content wave 2: Bone Golem ---
	"golem_slam": {"duration": 0.3, "fill": 1.3},  # TUNING (not in GDD) a Bone Golem slam: a ring of cracked grave dirt and bone shards (8 frames of 128 px; GolemBehavior ring() 0.3 s)
}
## Most art-only bursts alive at once (AnimBursts ring buffer; the oldest is
## overwritten when full).
const BURST_CAPACITY: int = 48  # TUNING (not in GDD)
## Gameplay radius (px) of a spell-bolt hit splash ("bolt_impact"): small and subtle.
const BOLT_IMPACT_RADIUS: float = 10.0  # TUNING (not in GDD)
## Half-height (px) of the level-up column ("level_up", drawn 2x this tall).
const LEVEL_UP_RADIUS: float = 53.0  # TUNING (not in GDD)
## Column centre relative to the necromancer's position (px): puts its base at
## his feet (the 56 px sprite's feet sit about 21 px below his position).
const LEVEL_UP_OFFSET := Vector2(0.0, -29.0)  # TUNING (not in GDD)
## Gameplay radius (px) of the evolution flash ("evolution") on the necromancer.
const EVOLUTION_RADIUS: float = 70.0  # TUNING (not in GDD)
## Duration (s) for an animation id missing from ANIMS.
const DEFAULT_DURATION: float = 0.4  # TUNING (not in GDD)
## Fill for an animation id missing from ANIMS.
const DEFAULT_FILL: float = 1.1  # TUNING (not in GDD)
## Default stored frame size (px) that prepare_sprite.py --anim produces;
## effects drawn far larger are stored with --frame-px (192 / 256 / 512 px frames).
## SpriteBank.draw_anim() reads the real frame size from the strip height.
const FRAME_PX: int = 128  # TUNING (not in GDD)
