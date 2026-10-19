## SpriteData: on-screen sizes for the optional sprite art (docs/art/ART_BIBLE.md).
## A sprite key is "<category>/<id>", matching res://assets/sprites/<category>/<id>.png.
## When a PNG exists, SpriteBank draws it instead of the code-drawn glyph, scaled
## so its height (in world px) is the value below. Keys without a file keep
## their glyph, so art can be added one piece at a time. Data only, no logic.
## The main-menu diorama's art (assets/sprites/menu/) needs no entry here: it
## is drawn through EnvironmentArt.texture(), always as grid art at its texel
## size (MenuBackdropData, docs/art/ART_BIBLE.md "Menu diorama").
class_name SpriteData
extends RefCounted

## Root folder of the in-game sprite PNGs (prepared by tools/prepare_sprite.py).
const ROOT: String = "res://assets/sprites/"

## Grid art (the true pixel-art pass): screen px per art px at the 1280x720
## layout, an integer. Owner decision (GDD §15.0 "Art pass grid: 1 art px = 1
## screen px"): 1, so the necromancer is a 56 art px drawing shown at 56 px
## (at 2 the 28 px version lost its skull pauldrons and staff skull). Storage
## contract with tools/prepare_sprite.py: a grid-art PNG for key K is exactly
## HEIGHTS[K] / ART_SCALE texels tall (every HEIGHTS value is even) and
## SpriteBank draws it ART_SCALE times its texel size through the sharp-pixel
## shader (SHARP_SHADER). A PNG taller than HEIGHTS[K] is a legacy placeholder
## (stored at 3x) and is still scaled smoothly to HEIGHTS[K].
const ART_SCALE: int = 1  # TUNING (not in GDD) GDD §15.0 "Art pass grid": 1 art px = 1 screen px (was 2)

## Shader that draws grid art sharp at any screen scale (crisp pixels, edges
## blended over SHARP_EDGE_SOFTNESS screen px; see the shader header).
const SHARP_SHADER: String = "res://scripts/fx/sharp_pixel.gdshader"

## Width (screen px, 0-1) of the blend at each art-pixel edge in the sharp-pixel
## shader: 0 = nearest (uneven pixels at fractional scales such as a 1080p
## window), 1 = soft. Owner pick from 1080p renders: 0.5 ("C2").
const SHARP_EDGE_SOFTNESS: float = 0.5  # TUNING (not in GDD) owner choice, 1080p comparison

## On-screen height in world px per sprite key (ART_BIBLE.md manifest sizes).
## Every value is even, so grid art is HEIGHTS / ART_SCALE whole art px tall
## (with ART_SCALE 1, the art px height equals this value).
const HEIGHTS: Dictionary = {
	"player/necromancer": 56.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"player/umbral_warden": 63.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer, staff and orbs above
	"player/voidcaller": 53.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer, the void ring above
	"player/bone_oracle": 54.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer, the spear above
	"player/fallen_confessor": 48.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer (no overhang)
	"player/carrion_lord": 52.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer (no overhang)
	"player/plague_scholar": 48.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer (no overhang)
	"player/doomsayer": 53.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer, the branding iron above
	"player/barrow_warden": 59.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer, the shovel staff above
	"player/soulbinder": 61.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer, the lightning hand above
	"player/wither_witch": 48.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer (no overhang)
	"player/grave_herald": 62.0,  # TUNING (not in GDD) art pass: 56 before; body ~48 like the necromancer, the skull banner above
	# Skins (SkinData, cosmetic only): each keeps its character's body height
	# (head to feet, art px); the sprite height adds what rises above the head.
	"player/gravecaller_dread_sovereign": 56.0,  # TUNING (not in GDD) skin art: body 49 like the necromancer, the flame staff above (the crown sits on the hood)
	"player/bone_oracle_ivory_seer": 60.0,  # TUNING (not in GDD) skin art: body 48 like the Bone Oracle, the spear and the halo above
	"player/plague_scholar_plague_doctor": 48.0,  # TUNING (not in GDD) skin art: body 48 like the Plague Scholar (the hat is the top, no overhang)
	"player/fallen_confessor_heretic_saint": 56.0,  # TUNING (not in GDD) skin art: body 48 like the Fallen Confessor, the cracked halo above
	"player/gravecaller_hyper": 58.0,  # TUNING (not in GDD) skin art: body 49 like the necromancer, the gold-ringed flame staff and the corona above
	"player/umbral_warden_hyper": 69.0,  # TUNING (not in GDD) skin art: body 49 like the Umbral Warden, the taller gold-ringed black-sun staff above
	"player/voidcaller_hyper": 55.0,  # TUNING (not in GDD) skin art: body 48 like the Voidcaller, the gold-framed void ring and the corona above
	"player/bone_oracle_hyper": 59.0,  # TUNING (not in GDD) skin art: body 48 like the Bone Oracle, the gold spear and the corona above
	"player/carrion_lord_hyper": 60.0,  # TUNING (not in GDD) skin art: body 52 like the Carrion Lord, the crown and the corona above
	"player/fallen_confessor_hyper": 54.0,  # TUNING (not in GDD) skin art: body 48 like the Fallen Confessor, the corona above
	"player/plague_scholar_hyper": 53.0,  # TUNING (not in GDD) skin art: body 48 like the Plague Scholar, the corona above
	"player/doomsayer_hyper": 54.0,  # TUNING (not in GDD) skin art: body 45 like the Doomsayer, the gold branding iron and the corona above
	"player/barrow_warden_hyper": 63.0,  # TUNING (not in GDD) skin art: body 49 like the Barrow Warden, the gold shovel staff and the corona above
	"player/soulbinder_hyper": 63.0,  # TUNING (not in GDD) skin art: body 49 like the Soulbinder, the gold lightning hand and the corona above
	"player/wither_witch_hyper": 50.0,  # TUNING (not in GDD) skin art: body 48 like the Wither Witch, the gold thorn tips above the hat
	"player/grave_herald_hyper": 63.0,  # TUNING (not in GDD) skin art: body 48 like the Grave Herald, the skull banner and the corona above
	"summons/warrior": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/archer": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/mage": 46.0,  # TUNING (not in GDD) art pass: 44 before; the orb staff rises above the hood (body ~44)
	"summons/mender": 52.0,  # TUNING (not in GDD) art pass: 44 before; the halo floats above the hood (body ~44)
	"summons/warder": 48.0,  # TUNING (not in GDD) art pass: 44 before; the ward sigil is raised above the hood (body ~44)
	"summons/bishop": 64.0,  # TUNING (not in GDD) art pass: 52 before; the halo floats above the mitre (body ~52)
	"summons/death_knight": 52.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/lich": 52.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/abomination": 88.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/rogue": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/gargoyle": 56.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/frost_wraith": 48.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/risen": 36.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/winter_revenant": 56.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/shadow_reaper": 48.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/cathedral_horror": 64.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/gravebow": 54.0,  # TUNING (not in GDD) art pass: 52 before; the huge longbow rises above the hood (body ~48)
	"summons/bone_colossus": 100.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/bone_hound": 32.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/hellhound": 40.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/banshee": 48.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/keening_lady": 56.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/corpse_catapult": 56.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"summons/ossuary_engine": 72.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/recruit": 50.0,  # TUNING (not in GDD) art pass: 40 before; his spear rises above the helmet, so 50 gives a ~40 px body (fodder tier)
	"enemies/footman": 48.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/archer": 50.0,  # TUNING (not in GDD) art pass: 40 before; the longbow rises above the hood (body ~40)
	"enemies/chaplain": 42.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/purifier": 44.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/templar": 78.0,  # TUNING (not in GDD) art pass: 52 before; the upright lance rises well above the helm (body ~52)
	"enemies/inquisitor": 64.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/shieldbearer": 56.0,  # TUNING (not in GDD) art pass: 50 before; the spear tip rises above the helm (body ~50)
	"enemies/banner_bearer": 84.0,  # TUNING (not in GDD) art pass: 50 before; the war banner rises far above the head (body ~44)
	"enemies/halberdier": 60.0,  # TUNING (not in GDD) art pass: 50 before; the halberd blade rises above the helm (body ~46)
	"enemies/sanctified_sentinel": 72.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/radiant_inquisitor": 68.0,  # TUNING (not in GDD) art pass: 60 before; the halo rays rise above the hood (body ~56)
	"enemies/high_confessor": 64.0,  # TUNING (not in GDD) art pass: 56 before; the mitre and crook rise above the head (body ~52)
	"enemies/sun_paladin": 70.0,  # TUNING (not in GDD) art pass: 56 before; the lance rises above the plumed helm (body ~56)
	"enemies/cathedral_guardian": 140.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"enemies/battle_sister": 52.0,  # TUNING (not in GDD) Sister of the Scourge: soldier tier (body 52 head to feet, the veil the top; the scourge hangs at her side, no overhang)
	"bosses/alaric": 120.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"bosses/vael": 120.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"bosses/seraphine": 130.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"bosses/seraphine_avatar": 156.0,  # TUNING (not in GDD) ART_BIBLE manifest size (optional Avatar form)
	"bosses/alaric_windup": 177.0,  # TUNING (not in GDD) boss attack pose (hammer raised overhead; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"bosses/alaric_charge": 117.0,  # TUNING (not in GDD) boss attack pose (shoulder charge; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"bosses/alaric_strike": 108.0,  # TUNING (not in GDD) boss attack pose (hammer slammed down, crouched; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"bosses/vael_windup": 133.0,  # TUNING (not in GDD) boss attack pose (flaming sword raised; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"bosses/vael_guard": 104.0,  # TUNING (not in GDD) boss attack pose (Shieldwall crouch; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"bosses/vael_strike": 118.0,  # TUNING (not in GDD) boss attack pose (cleave follow-through; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"bosses/seraphine_cast": 156.0,  # TUNING (not in GDD) boss attack pose (relic staff raised; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"bosses/seraphine_avatar_cast": 176.0,  # TUNING (not in GDD) boss attack pose (the Avatar casting, wings spread; BossPoseData): body as tall as the still; the pose (raised weapon or crouch) sets the height
	"structures/outpost": 96.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/ward_generator": 80.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/supply_cart": 60.0,  # TUNING (not in GDD) art pass: 72 before; the wide side-on cart keeps its old ~84 px width
	"structures/holy_standard": 72.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/watchtower": 96.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/ward_crystal": 64.0,  # TUNING (not in GDD) art pass: a tall thin crystal, ~26 px wide for its 15 px radius
	"structures/sacred_altar": 72.0,  # TUNING (not in GDD) ART_BIBLE manifest size
	"structures/empowered_grave": 40.0,  # TUNING (not in GDD) the Graveyard's empowered grave (StageDirector shrine), ~44 px wide for its 30 px claim radius
	"structures/battlefield_dead": 36.0,  # TUNING (not in GDD) the Crimson March's empowered grave: a heap of fallen soldiers
	"structures/sanctum_crypt": 36.0,  # TUNING (not in GDD) the Sanctum's empowered grave: marble flagstones cracking over a crypt
	"structures/crypt_door": 56.0,  # TUNING (not in GDD) the Crypt Defender event's crypt (StageDirector shrine "crypt")
	"structures/consecration_grave": 30.0,  # TUNING (not in GDD) a grave a Chaplain tries to consecrate (desecration event)
	# Placeholder art batch (MarkerArtData): spell walls and the stone form.
	"structures/bone_wall_segment": 26.0,  # TUNING (not in GDD) one Bone Wall segment (9 px radius, 16 px apart): three bone spikes on a mound, ~20 px wide
	"structures/bone_wall_bastion": 30.0,  # TUNING (not in GDD) one Charnel Bastion segment: four spikes and a skull, ~24 px wide
	"summons/cathedral_horror_stone": 64.0,  # TUNING (not in GDD) the Cathedral Horror's stone form: its still turned to grey stone, same size
	# --- Act II: Fallen Seraph ---
	"summons/fallen_seraph": 52.0,  # TUNING (not in GDD) ART_BIBLE manifest size (body ~46, the halo above)
	"summons/ruin_seraph": 60.0,  # TUNING (not in GDD) ART_BIBLE manifest size (body ~52, the thorn halo above)
	# --- Act II: Gullhaven Harbour ---
	"eye/deep_kin": 56.0,  # TUNING (not in GDD) Deep Kin: a bruiser, between soldier and heavy (the fin ridge rises above the hunched head)
	"eye/tide_caller": 54.0,  # TUNING (not in GDD) Tide Caller: soldier tier (body ~48, the conch staff above)
	"eye/netcaster": 50.0,  # TUNING (not in GDD) Netcaster: soldier tier
	"eye/deep_herald": 64.0,  # TUNING (not in GDD) Herald of the Deep: the Reckoning's heavy
	"eye/harbourmaster": 124.0,  # TUNING (not in GDD) the Harbourmaster: miniboss tier (the Cathedral Guardian is 140)
	"bosses/merrow": 130.0,  # TUNING (not in GDD) Abbot Merrow, robed (the mitre the top)
	"bosses/merrow_sermon": 150.0,  # TUNING (not in GDD) boss attack pose (preaching, arms raised; BossPoseData): body as tall as the still, the raised arms above
	"bosses/merrow_changed": 136.0,  # TUNING (not in GDD) Abbot Merrow after The Change (the frill crown the top, limbs spread wide)
	"bosses/merrow_changed_strike": 120.0,  # TUNING (not in GDD) boss attack pose (lunging lash; BossPoseData)
	"structures/bell_buoy": 64.0,  # TUNING (not in GDD) a bell buoy: the float and its bell cage
	"structures/smuggler_cache": 40.0,  # TUNING (not in GDD) a smugglers' cache: an iron-bound crate, ~34 px wide for its 15 px radius
	"player/brine_widow": 58.0,  # TUNING (not in GDD) the Brine Widow: body ~48 like the necromancer, the hooked staff above
	# --- Act II: the Hollow Archive ---
	"eye/scribe": 48.0,  # TUNING (not in GDD) soldier tier: body 44, the raised quill above
	"eye/ink_wraith": 44.0,  # TUNING (not in GDD) a floating flanker (soldier tier)
	"eye/spore_pilgrim": 50.0,  # TUNING (not in GDD) soldier tier: body 44, the mushroom staff above
	"eye/gibbering_mass": 60.0,  # TUNING (not in GDD) heavy tier: a wide lumpy mound
	"eye/gibbering_lesser": 44.0,  # TUNING (not in GDD) the first split (same art, smaller)
	"eye/gibbering_least": 32.0,  # TUNING (not in GDD) the last split (same art, smallest)
	"eye/librarian": 110.0,  # TUNING (not in GDD) miniboss tier: the floating eye and its hanging tentacles
	"eye/unwritten_one": 60.0,  # TUNING (not in GDD) the Reckoning's soldier (the Inquisitor is 64)
	"bosses/archivist": 130.0,  # TUNING (not in GDD) boss tier: the open-book head and the quill staff
	"bosses/archivist_cast": 152.0,  # TUNING (not in GDD) boss attack pose (Recitation: tome and quill raised, pages flying up; BossPoseData)
	"bosses/archivist_split": 134.0,  # TUNING (not in GDD) boss attack pose (Footnotes: arms flung wide, the pages fanned; BossPoseData)
	"bosses/archivist_strike": 124.0,  # TUNING (not in GDD) boss attack pose (the chained tome slammed forward; BossPoseData)
	"player/heretic_scribe": 60.0,  # TUNING (not in GDD) body ~48 like the necromancer, the quill-staff above
	"structures/archive_rift": 64.0,  # TUNING (not in GDD) a rift's tear (18 px body radius)
	"structures/forbidden_lectern": 52.0,  # TUNING (not in GDD) a lectern with its open tome
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"eye/eye_siren": 56.0,  # TUNING (not in GDD) elite caster: body ~52 (figure redesign), the hair crest above
	"eye/eye_spawn": 66.0,  # TUNING (not in GDD) heavy tier (60-72)
	"eye/eye_hierophant": 64.0,  # TUNING (not in GDD) elite leader: body ~52, the tall mitre and the staff's sigil above
	"eye/eye_waking_horror": 70.0,  # TUNING (not in GDD) the Waking's Dreamspawn (the Inquisitor of the End is 64)
	"eye/dream_pillar": 88.0,  # TUNING (not in GDD) structure tier: a cyclopean obelisk (~36 px wide for its 18 px radius)
	"eye/vhalneth_arm": 124.0,  # TUNING (not in GDD) boss part: an arm rearing out of the surf
	"bosses/vhalneth": 150.0,  # TUNING (not in GDD) boss tier: her face, eyes open (Stirring)
	"bosses/vhalneth_dreaming": 150.0,  # TUNING (not in GDD) her face under the sea, eyes shut (Dreaming)
	"bosses/vhalneth_waking": 156.0,  # TUNING (not in GDD) her face risen, roaring (Waking)
	"summons/spawn_of_the_deep": 60.0,  # TUNING (not in GDD) a heavy summon (Abomination 88, Corpse Catapult 56)
	"summons/leviathan": 76.0,  # TUNING (not in GDD) its evolution, bigger
	"summons/drowned_thrall_ally": 44.0,  # TUNING (not in GDD) Call of the Drowned's Thrall (soldier tier)
	"player/tide_widow": 56.0,  # TUNING (not in GDD) character tier: body ~48 like the necromancer, the coral crown above
	"player/tide_widow_hyper": 58.0,  # TUNING (not in GDD) skin art: the Tide Widow's body, the taller gold coral crown above
	# --- Content wave 2: Bone Golem ---
	"summons/bone_golem": 80.0,  # TUNING (not in GDD) lead brief 72-80; one huge skull for a torso on stumpy legs (84 wide, wave 2 art review), drawn up to x1.25 by Ossuary Hunger
	"summons/ossuary_titan": 104.0,  # TUNING (not in GDD) its evolution, the tallest summon (Bone Colossus 100); the crowned huge-skull torso (108 wide)
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
## projectiles (art pointing right), orbs and the pickups (drawn centred,
## unrotated). Keys "projectiles/<id>" and "pickups/<id>", plus the flat
## markers, overlays and corpses of the placeholder art batch ("markers/",
## "overlays/", "decals/corpse*", "ui/rotate_phone"). Grid art is stored
## at exactly this longest side (or less) and drawn 1:1.
const FLAT_SIZES: Dictionary = {
	"pickups/xp_crystal_s": 12.0,  # TUNING (not in GDD) XP crystal worth 1-2 (the code glyph was ~10-12 px tall)
	"pickups/xp_crystal_m": 16.0,  # TUNING (not in GDD) XP crystal worth 3-7
	"pickups/xp_crystal_l": 20.0,  # TUNING (not in GDD) XP crystal worth 8+
	"pickups/chest": 32.0,  # TUNING (not in GDD) world treasure chest (code chest 22 px wide); art pass: 30 before; the grid art with its outline is 32 px long
	"pickups/pu_magnet": 24.0,  # TUNING (not in GDD) power-up medallion (token radius 10 + rim)
	"pickups/pu_feast": 24.0,  # TUNING (not in GDD) power-up medallion
	"pickups/pu_hyper": 26.0,  # TUNING (not in GDD) power-up medallion; art pass: 24 before; the grid art with its outline is 26 px long
	"pickups/pu_stasis": 24.0,  # TUNING (not in GDD) power-up medallion
	"pickups/pu_frenzy": 24.0,  # TUNING (not in GDD) power-up medallion
	"pickups/pu_nova": 24.0,  # TUNING (not in GDD) power-up medallion
	"projectiles/shadow_bolt": 22.0,  # TUNING (not in GDD)
	"projectiles/void_bolt": 32.0,  # TUNING (not in GDD) art pass: 30 before; the grid art with its outline is 32 px long
	"projectiles/void_shard": 16.0,  # TUNING (not in GDD) art pass: 14 before; the grid art with its outline is 16 px long
	"projectiles/arrow": 22.0,  # TUNING (not in GDD) art pass: 20 before; the grid art with its outline is 22 px long
	"projectiles/enemy_arrow": 20.0,  # TUNING (not in GDD)
	"projectiles/mage_orb": 22.0,  # TUNING (not in GDD) art pass: 20 before; the grid art with its outline is 22 px long
	"projectiles/priest_bolt": 14.0,  # TUNING (not in GDD)
	"projectiles/frost_bolt": 22.0,  # TUNING (not in GDD) art pass: 20 before; the grid art with its outline is 22 px long
	"projectiles/radiant_bolt": 20.0,  # TUNING (not in GDD)
	"projectiles/bone_spear": 26.0,  # TUNING (not in GDD)
	"projectiles/ossuary_lance": 46.0,  # TUNING (not in GDD) art pass: 44 before; the grid art with its outline is 46 px long
	"projectiles/orb": 18.0,  # TUNING (not in GDD) Shadow Orb Shield orb
	# Placeholder art batch (MarkerArtData): markers, overlays and spell props,
	# drawn flat (no shadow) at 1 art px = 1 px. The longest side of each PNG.
	"projectiles/eclipse_orb": 20.0,  # TUNING (not in GDD) Eclipse Ward orb (the code orb was ~18 px across)
	"projectiles/oracle_shard": 20.0,  # TUNING (not in GDD) Bone Oracle orbiting shard (code shard 14 px long)
	"projectiles/corpse_boulder": 16.0,  # TUNING (not in GDD) catapult skull boulder, 16 x 14 (code boulder 12-18 px across)
	"projectiles/corpse_boulder_burning": 23.0,  # TUNING (not in GDD) Ossuary Engine burning skull, 14 x 23 with its flames
	"markers/rally_pennant": 30.0,  # TUNING (not in GDD) Call to Arms pennant, 28 x 30 (code pole 28 px tall)
	"markers/buff_chevron": 10.0,  # TUNING (not in GDD) aura buff chevron, 10 x 7 (code chevron 8 x 4)
	"markers/sun_ward": 10.0,  # TUNING (not in GDD) Sun Paladin ward badge, 8 x 10 (code pip 7 x 8)
	"markers/sanctuary_cross": 28.0,  # TUNING (not in GDD) Seraphine nova safe-spot cross, 20 x 28 (code cross 20 x 28)
	"markers/mage_mark": 10.0,  # TUNING (not in GDD) Volley of the Fallen mark, 8 x 10 (code diamond 6 x 8)
	"markers/death_brand": 14.0,  # TUNING (not in GDD) Death Mark skull, 12 x 14 with its flame
	"markers/death_brand_doom": 16.0,  # TUNING (not in GDD) Doom Brand skull, 12 x 16 with its flame
	"markers/stun_stars": 16.0,  # TUNING (not in GDD) stun stars, 16 x 11
	"overlays/frozen_shell": 40.0,  # TUNING (not in GDD) ice shell ring, 36 x 40, scaled up by body radius (MarkerArtData)
	"decals/corpse": 12.0,  # TUNING (not in GDD) Corpse Explosion corpse, crossed bones and a skull, 12 x 12
	"decals/corpse_2": 16.0,  # TUNING (not in GDD) corpse variant: a skull and a ribcage, 16 x 10
	"decals/corpse_3": 16.0,  # TUNING (not in GDD) corpse variant: scattered bones on a torn cloth, 16 x 10
	"ui/rotate_phone": 60.0,  # TUNING (not in GDD) the rotate overlay's phone, 35 x 60 (drawn x2: 70 x 120 layout px)
	# --- Act II: Fallen Seraph ---
	"projectiles/seraph_feather": 14.0,  # TUNING (not in GDD) one black feather blade of the Fallen Seraph's feather ring (SeraphGlyphs.draw_ring())
	# --- Act II: the Hollow Archive ---
	"structures/orrery_hub": 75.0,  # TUNING (not in GDD) the orrery's brass hub seen from above, 72 x 75 (36 px radius)
	"obstacles/orrery_arm": 62.0,  # TUNING (not in GDD) one tile of an orrery arm, 62 x 17, repeated along the arm (ArchiveGlyphs.ARM_TILE)
	"obstacles/orrery_planet": 24.0,  # TUNING (not in GDD) the planet on an arm's tip, 24 x 19
	"decals/ink_pool": 64.0,  # TUNING (not in GDD) an ink pool, 64 x 49, scaled to the pool's radius
	"decals/ink_well": 64.0,  # TUNING (not in GDD) an Ink Wells well (the pool's art), scaled to its radius
	"projectiles/archive_page": 12.0,  # TUNING (not in GDD) a Recitation page, 12 x 9
	"projectiles/verse_page": 13.0,  # TUNING (not in GDD) a Forbidden Verse page, 12 x 13
	"projectiles/unwritten_page": 14.0,  # TUNING (not in GDD) a The Unwritten Word page, 14 x 14 (gilded)
}
## Longest side (px) for a flat sprite key missing from FLAT_SIZES.
const DEFAULT_FLAT_SIZE: float = 20.0  # TUNING (not in GDD)
## Fraction of an icon box that icon art (assets/sprites/icons/) fills.
const ICON_ART_FILL: float = 0.92  # TUNING (not in GDD)

## Icon art (assets/sprites/icons/) no taller than this (px) is grid pixel art
## (the art pass's 32x32 badge icons, which carry their own badge and border):
## SpriteBank draws it filling the whole icon box through the sharp-pixel shader,
## and Glyphs.draw_icon() skips its code-drawn backdrop. Taller icon art is a
## legacy placeholder, drawn smooth at ICON_ART_FILL inside the code backdrop.
const ICON_GRID_MAX_PX: int = 64  # TUNING (not in GDD) art pass: icons are 32x32 art px

## Drop-shadow ellipse under a sprite: width as a fraction of the sprite height.
const SHADOW_WIDTH: float = 0.55  # TUNING (not in GDD)
## Drop-shadow ellipse height as a fraction of its width.
const SHADOW_SQUASH: float = 0.35  # TUNING (not in GDD)
## Drop-shadow opacity (0-1).
const SHADOW_ALPHA: float = 0.35  # TUNING (not in GDD)
