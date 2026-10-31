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
	# --- Act II: the Ancient Eye's shared kinds (harbour placeholder art pass) ---
	"eye/eye_initiate": 46.0,  # TUNING (not in GDD) Initiate of the Eye: fodder, a hunched cultist a little smaller than the Recruit (50)
	"eye/eye_chanter": 64.0,  # TUNING (not in GDD) Chanter of the Eye: squad leader, body ~44, the tall eye staff above (the Hierophant is 64)
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
	"structures/merrow_pulpit": 40.0,  # TUNING (not in GDD) Abbot Merrow's driftwood pulpit before him while he preaches, 42 x 40 (harbour placeholder art pass)
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
	# --- Act III: the Electronic Empire (the shared kinds; assets/sprites/empire/) ---
	"empire/scout_drone": 32.0,  # TUNING (not in GDD) fodder: a small flying drone, about 40 px wide with its rotors; art review round 1: 30 + two empty rows on top for the hover bob (walk_cycle.py "hover")
	"empire/kill_drone": 32.0,  # TUNING (not in GDD) the Purge Protocol's armoured drone, 70 px wide with its rotors; like the Scout Drone: 30 + two empty rows on top for the hover bob (Act III missing sprites)
	"empire/line_trooper": 50.0,  # TUNING (not in GDD) soldier tier: body ~46, the helmet dome on top
	"empire/spotter": 56.0,  # TUNING (not in GDD) elite tier: a tall coated marksman, the antenna above
	"summons/grave_gunner": 50.0,  # TUNING (not in GDD) a raised Line Trooper (Steel has no soul), drawn from its sprite
	"player/tide_widow": 56.0,  # TUNING (not in GDD) character tier: body ~48 like the necromancer, the coral crown above
	"player/tide_widow_hyper": 58.0,  # TUNING (not in GDD) skin art: the Tide Widow's body, the taller gold coral crown above
	# --- Content wave 2: Bone Golem ---
	"summons/bone_golem": 80.0,  # TUNING (not in GDD) lead brief 72-80; one huge skull for a torso on stumpy legs (84 wide, wave 2 art review), drawn up to x1.25 by Ossuary Hunger
	"summons/ossuary_titan": 104.0,  # TUNING (not in GDD) its evolution, the tallest summon (Bone Colossus 100); the crowned huge-skull torso (108 wide)
	# --- Wave 2 art review: Untouchable and Deathlord skins (drawn art for every character) ---
	# Each keeps its character's body height (head to feet); a crown, horns or drifting
	# ghost hair above the head adds rows on top.
	"player/gravecaller_untouchable": 56.0,  # TUNING (not in GDD) skin art: body 49 like the necromancer, the soul-teal flame staff above
	"player/gravecaller_deathlord": 60.0,  # TUNING (not in GDD) skin art: body 49 like the necromancer, the horned crown and the flame staff above
	"player/umbral_warden_untouchable": 63.0,  # TUNING (not in GDD) skin art: body 48 like the Umbral Warden, the ghost-sun staff above
	"player/umbral_warden_deathlord": 63.0,  # TUNING (not in GDD) skin art: body 48 like the Umbral Warden, the crowned hood and the black-sun staff above
	"player/voidcaller_untouchable": 53.0,  # TUNING (not in GDD) skin art (figure redesign, owner's review round 2): body 48 like the Voidcaller, the ghost hair and the soul ring above
	"player/voidcaller_deathlord": 56.0,  # TUNING (not in GDD) skin art (figure redesign, owner's review round 2): body 48 like the Voidcaller, the spiked crown above
	"player/bone_oracle_untouchable": 57.0,  # TUNING (not in GDD) skin art: body 48 like the Bone Oracle, the teal-tipped spear above
	"player/bone_oracle_deathlord": 56.0,  # TUNING (not in GDD) skin art: body 48 like the Bone Oracle, the horned crown and the gold spear above
	"player/fallen_confessor_untouchable": 48.0,  # TUNING (not in GDD) skin art: body 48 like the Fallen Confessor (no overhang)
	"player/fallen_confessor_deathlord": 53.0,  # TUNING (not in GDD) skin art: body 48 like the Fallen Confessor, the spiked crown above
	"player/carrion_lord_untouchable": 52.0,  # TUNING (not in GDD) skin art: body 52 like the Carrion Lord (the ghost cleaver no higher than the hood)
	"player/carrion_lord_deathlord": 56.0,  # TUNING (not in GDD) skin art: body 52 like the Carrion Lord, the horned crown above
	"player/plague_scholar_untouchable": 49.0,  # TUNING (not in GDD) skin art: body 48 like the Plague Scholar, the hood tip above
	"player/plague_scholar_deathlord": 52.0,  # TUNING (not in GDD) skin art: body 48 like the Plague Scholar, the crown above
	"player/doomsayer_untouchable": 53.0,  # TUNING (not in GDD) skin art: body 45 like the Doomsayer, the soul-fire branding iron above
	"player/doomsayer_deathlord": 55.0,  # TUNING (not in GDD) skin art: body 45 like the Doomsayer, the crown and the gold branding iron above
	"player/barrow_warden_untouchable": 59.0,  # TUNING (not in GDD) skin art: body 49 like the Barrow Warden, the ghost shovel staff above
	"player/barrow_warden_deathlord": 61.0,  # TUNING (not in GDD) skin art: body 49 like the Barrow Warden, the crown and the shovel staff above
	"player/grave_herald_untouchable": 62.0,  # TUNING (not in GDD) skin art: body 48 like the Grave Herald, the spectral skull banner above
	"player/grave_herald_deathlord": 63.0,  # TUNING (not in GDD) skin art: body 48 like the Grave Herald, the crowned skull banner above
	"player/soulbinder_untouchable": 61.0,  # TUNING (not in GDD) skin art: body 49 like the Soulbinder, the soul-teal lightning hand above
	"player/soulbinder_deathlord": 63.0,  # TUNING (not in GDD) skin art: body 49 like the Soulbinder, the spiked crown and the violet lightning hand above
	"player/wither_witch_untouchable": 49.0,  # TUNING (not in GDD) skin art: body 48 like the Wither Witch, the ghost hat tip above
	"player/wither_witch_deathlord": 50.0,  # TUNING (not in GDD) skin art: body 48 like the Wither Witch, the crown band's spikes above the hat
	"player/brine_widow_untouchable": 58.0,  # TUNING (not in GDD) skin art: body 48 like the Brine Widow, the bleached hooked staff above
	"player/brine_widow_deathlord": 60.0,  # TUNING (not in GDD) skin art: body 48 like the Brine Widow, the spiked crown above
	"player/heretic_scribe_untouchable": 60.0,  # TUNING (not in GDD) skin art: body 48 like the Heretic Scribe, the soul-teal quill-staff above
	"player/heretic_scribe_deathlord": 61.0,  # TUNING (not in GDD) skin art: body 48 like the Heretic Scribe, the crimson quill-staff above
	"player/tide_widow_untouchable": 56.0,  # TUNING (not in GDD) skin art: body 48 like the Tide Widow, the pearl crown and the soul conch above
	"player/tide_widow_deathlord": 58.0,  # TUNING (not in GDD) skin art: body 48 like the Tide Widow, the taller spiked crown above
	# --- Act III: the Assembly Halls ---
	"empire/arc_engineer": 50.0,  # TUNING (not in GDD) support tier, like the Line Trooper (the toolkit drum adds width)
	"empire/juggernaut": 62.0,  # TUNING (not in GDD) heavy elite: a squat armoured walker
	"empire/fabricator": 54.0,  # TUNING (not in GDD) a structure: the build bay with its robot arm above
	"empire/motherboard_turret": 32.0,  # TUNING (not in GDD) the boss's small tripod turret
	"empire/beta_build": 104.0,  # TUNING (not in GDD) miniboss tier (the Harbourmaster 124, the Cathedral Guardian 140): a tall, thin, unfinished mech
	"bosses/motherboard": 150.0,  # TUNING (not in GDD) boss tier: the titan on its treads, both crane arms raised
	"bosses/motherboard_windup": 150.0,  # TUNING (not in GDD) attack pose: both crane arms raised high (BossPoseData 1)
	"bosses/motherboard_strike": 150.0,  # TUNING (not in GDD) attack pose: both claws slammed down in front (BossPoseData 3)
	"summons/grave_drone": 28.0,  # TUNING (not in GDD) a small flying skull drone (drawn hovering); art review round 1: 26 + two empty rows on top for the hover bob and wingbeat
	"summons/wraith_drone": 32.0,  # TUNING (not in GDD) its evolution, wreathed in ghost flame; art review round 1: 30 + two empty rows on top for the hover bob
	"player/marionette": 56.0,  # TUNING (not in GDD) character tier: body ~50, the jester bun above
	"player/marionette_hyper": 58.0,  # TUNING (not in GDD) skin art: the Marionette's body, the tall gold jester crown above
	"player/marionette_untouchable": 56.0,  # TUNING (not in GDD) skin art: body like the Marionette's
	"player/marionette_deathlord": 60.0,  # TUNING (not in GDD) skin art: body like the Marionette's, the spiked crown above
	# --- Act III: the Scrap Wastes (assets/sprites/empire/, bosses/, player/) ---
	"empire/aegis_bot": 48.0,  # TUNING (not in GDD) soldier tier: a squat walker behind its shield (40 wide)
	"empire/mortar_walker": 48.0,  # TUNING (not in GDD) heavy: a low four-legged walker, wider than tall (the tube on top)
	"empire/signal_pylon": 96.0,  # TUNING (not in GDD) structure tier: a tall mast on a tripod, the red beacon on top
	"empire/trojan_horse": 104.0,  # TUNING (not in GDD) miniboss: a horse-shaped drone tank (about 120 wide)
	"empire/trojan_horse_split": 104.0,  # TUNING (not in GDD) its split hull (the same body, hull halves bent out)
	"bosses/kestrel": 124.0,  # TUNING (not in GDD) boss tier: a tall pear-shaped markswoman (round 1 redo), the long rifle across her
	"bosses/kestrel_aim": 108.0,  # TUNING (not in GDD) attack pose: kneeling, rifle raised (her body is lower)
	"bosses/kestrel_blades": 124.0,  # TUNING (not in GDD) her last phase: the arm blade raised high above her head
	"player/lightning_abbess": 56.0,  # TUNING (not in GDD) character tier: body ~48, the crescent staff above
	"player/lightning_abbess_hyper": 58.0,  # TUNING (not in GDD) skin art: her body, the gold storm crown above
	"player/lightning_abbess_untouchable": 56.0,  # TUNING (not in GDD) skin art: her body, the soul-teal staff above
	"player/lightning_abbess_deathlord": 58.0,  # TUNING (not in GDD) skin art: her body, the spiked crown above
	# --- Act III: the Iron Citadel ---
	"empire/valkyrie_duelist": 52.0,  # TUNING (not in GDD) elite tier, female (figure redesign): body ~46, the winged helmet above
	"empire/valkyrie_prime": 104.0,  # TUNING (not in GDD) Valkyrie 2.0, the miniboss (the Cathedral Guardian is 140): her crest and jet pack above
	"empire/sentry_turret": 44.0,  # TUNING (not in GDD) structure: a squat domed emplacement (its barrel is drawn by SentryKit)
	"empire/shield_generator": 64.0,  # TUNING (not in GDD) structure: a chrome pylon with its amber core
	"empire/deus_leg_plate": 32.0,  # TUNING (not in GDD) one of Deus Ex Machina's knee plates (drawn over its leg)
	"empire/deus_shield_drone": 24.0,  # TUNING (not in GDD) a Siege Core shield drone
	"bosses/deus_ex_machina": 156.0,  # TUNING (not in GDD) boss tier, "a walking fortress the height of the screen" (proposal): the Walker
	"bosses/deus_ex_machina_fire": 156.0,  # TUNING (not in GDD) boss attack pose (cannons blazing; BossPoseData)
	"bosses/deus_ex_machina_siege": 140.0,  # TUNING (not in GDD) the Siege Core: knelt and planted, lower
	"bosses/deus_ex_machina_founder": 156.0,  # TUNING (not in GDD) the Founder: the cracked core, Varn's face in the light
	"player/rust_prophet": 58.0,  # TUNING (not in GDD) character tier: body ~48 like the necromancer, the gear-topped staff above
	"player/rust_prophet_hyper": 58.0,  # TUNING (not in GDD) skin art: his body, the gilded staff above
	"player/rust_prophet_untouchable": 58.0,  # TUNING (not in GDD) skin art: his body, the ghost staff above
	"player/rust_prophet_deathlord": 60.0,  # TUNING (not in GDD) skin art: his body, the crowned hood and staff above
	"summons/iron_revenant": 58.0,  # TUNING (not in GDD) a heavy summon (Corpse Catapult 56, Spawn of the Deep 60)
	"summons/deus_revenant": 70.0,  # TUNING (not in GDD) its evolution, bigger
	# --- Act IV: the Olympian Republic (the shared kinds; assets/sprites/pantheon/) ---
	"pantheon/shade_of_dead": 36.0,  # TUNING (not in GDD) fodder: a hooded ghost with a long wisp tail (34) + two empty rows on top for the hover bob (walk_cycle.py "hover")
	"pantheon/shade_archer": 40.0,  # TUNING (not in GDD) ranged soldier: a hooded-crested ghost drawing a recurve bow, a wisp tail (38) + two empty rows on top for the hover bob (walk_cycle.py "hover"); a little taller than the Shade of the Dead
	"pantheon/hoplite": 56.0,  # TUNING (not in GDD) soldier tier: body ~50 (crest to sandals), the upright spear head above
	"pantheon/hero": 58.0,  # TUNING (not in GDD) elite tier: a demigod, the tall plume on top (elites are also drawn larger by the game)
	"pantheon/bronze_titan": 96.0,  # TUNING (not in GDD) the Reckoning's heavy, bigger than the heavy tier (60-72) and below the minibosses (104+)
	# --- Act IV: the Shores of Ilion (assets/sprites/pantheon/, bosses/, player/) ---
	"pantheon/legionary": 56.0,  # TUNING (not in GDD) soldier tier like the Hoplite: body ~50, the crest above
	"pantheon/wolf_of_rome": 36.0,  # TUNING (not in GDD) fodder pack: a low bronze wolf, about 1.6 x as long as tall
	"pantheon/cyclops": 70.0,  # TUNING (not in GDD) heavy tier (60-72): a hulking giant, the boulder beside his head
	"pantheon/polyphemus": 112.0,  # TUNING (not in GDD) miniboss tier (104+): the giant with a boulder over his head
	"pantheon/siege_tower": 104.0,  # TUNING (not in GDD) a structure: a tall tower on wheels (the Signal Pylon 96)
	"bosses/achilles": 120.0,  # TUNING (not in GDD) boss tier: the hero with his crest and long spear (Kestrel 124)
	"bosses/achilles_strike": 80.0,  # TUNING (not in GDD) attack pose: the low lunge, the spear thrust far ahead (BossPoseData 3)
	"bosses/achilles_rage": 120.0,  # TUNING (not in GDD) his rage: helmet and shield gone, the spear raised high
	"player/doomed_prophetess": 56.0,  # TUNING (not in GDD) character tier: body ~50, the bone circlet and bow tip above
	"player/doomed_prophetess_hyper": 58.0,  # TUNING (not in GDD) skin art: her body, the gold laurel crown above
	"player/doomed_prophetess_untouchable": 56.0,  # TUNING (not in GDD) skin art: her body
	"player/doomed_prophetess_deathlord": 58.0,  # TUNING (not in GDD) skin art: her body, the spiked crown above
	# --- Act IV: Mount Olympus (assets/sprites/pantheon/, bosses/, player/) ---
	"pantheon/centaur_archer": 60.0,  # TUNING (not in GDD) ranged, a horse body (wider than tall), the helmet crest on top
	"pantheon/amazon": 70.0,  # TUNING (not in GDD) elite tier, female (figure redesign, a towering muscular build since the art review round 1; round 5: 70, was 58, bigger than the elites for the detail, below the gods / bosses at 92+): the crest on top
	"pantheon/gorgon": 54.0,  # TUNING (not in GDD) elite tier, female (figure redesign): reared on her tail, the snake hair on top
	"pantheon/moon_hound": 30.0,  # TUNING (not in GDD) fodder: a lean hound (Bone Hound tier), wider than tall
	"pantheon/sea_serpent": 64.0,  # TUNING (not in GDD) heavy tier: the reared S-neck over its coil
	"pantheon/ares": 96.0,  # TUNING (not in GDD) a god of the trial (miniboss tier, below Zeus): the crest and the spear head above
	"pantheon/artemis": 92.0,  # TUNING (not in GDD) a goddess of the trial (miniboss tier), the bow above her head
	"pantheon/poseidon": 100.0,  # TUNING (not in GDD) a god of the trial (miniboss tier), the trident's prongs above
	"bosses/zeus": 124.0,  # TUNING (not in GDD) boss tier: the King of the Gods
	"bosses/zeus_cast": 128.0,  # TUNING (not in GDD) attack pose: the thunderbolt raised above his head
	"bosses/zeus_colossus": 176.0,  # TUNING (not in GDD) phase 3, his true colossal form (x1.55 body, bigger than any boss)
	"player/oathbreaker": 58.0,  # TUNING (not in GDD) character tier: body ~48, the thunderbolt staff above
	"player/oathbreaker_hyper": 58.0,  # TUNING (not in GDD) skin art: his body, the gilded staff above
	"player/oathbreaker_untouchable": 58.0,  # TUNING (not in GDD) skin art: his body, the ghost staff above
	"player/oathbreaker_deathlord": 60.0,  # TUNING (not in GDD) skin art: his body, the spiked crown above
	# --- Act IV: the Asphodel Underworld ---
	"pantheon/cerberus": 92.0,  # TUNING (not in GDD) miniboss tier: a huge three-headed hound, wide rather than tall (the flame tips on top)
	"bosses/hades": 116.0,  # TUNING (not in GDD) boss tier: a tall god, the blue flames of his crown and the bident above
	"bosses/hades_bident": 108.0,  # TUNING (not in GDD) attack pose (BossPoseData 1): leaning into the sweep, lower
	"bosses/hades_kneel": 84.0,  # TUNING (not in GDD) the ending: kneeling, offering his crown (HadesHazards' finale)
	"player/ferrywoman": 56.0,  # TUNING (not in GDD) character tier: body ~48, the hood and the oar's lantern above
	"player/ferrywoman_hyper": 56.0,  # TUNING (not in GDD) skin art: her body, the gilded oar
	"player/ferrywoman_untouchable": 56.0,  # TUNING (not in GDD) skin art: her body, the white phantom
	"player/ferrywoman_deathlord": 58.0,  # TUNING (not in GDD) skin art: her body, the spiked crown above
	"summons/myrmidon_shade": 46.0,  # TUNING (not in GDD) a summon like the Warrior (44), the spear head above
	"summons/legion_of_tartarus": 54.0,  # TUNING (not in GDD) its evolution, bigger
	# --- Act V: the Shogunate of the Rising Sun (the shared kinds; assets/sprites/shogunate/) ---
	"shogunate/ashigaru": 46.0,  # TUNING (not in GDD) fodder: body ~32 (hat to sandals), the long yari rising far above the hat
	"shogunate/samurai": 56.0,  # TUNING (not in GDD) soldier tier: body ~50, the crescent crest above
	"shogunate/teppo_gunner": 46.0,  # TUNING (not in GDD) ranged soldier: body ~44, the arquebus held level
	"shogunate/ninja": 40.0,  # TUNING (not in GDD) soldier tier, a crouching figure
	"shogunate/onryo": 36.0,  # TUNING (not in GDD) night fodder: a floating ghost (34) + two empty rows on top for the hover bob (walk_cycle.py "hover")
	"shogunate/oni": 80.0,  # TUNING (not in GDD) night heavy tier (60-72 and up): a huge red ogre, the horns and the club
	"obstacles/stone_lantern": 40.0,  # TUNING (not in GDD) a toro, unlit (an obstacle; the glow pool is drawn by code)
	"obstacles/stone_lantern_lit": 40.0,  # TUNING (not in GDD) the same toro with a warm lit window
	# --- Act V: the Burning Province (assets/sprites/shogunate/, bosses/, player/) ---
	"shogunate/kunoichi": 52.0,  # TUNING (not in GDD) elite tier (elites are also drawn larger): body ~46, the hair knot and scarf above
	"shogunate/kappa": 34.0,  # TUNING (not in GDD) fodder: a squat river imp, the water dish on top
	"shogunate/shuten_doji": 112.0,  # TUNING (not in GDD) miniboss tier (104+, Polyphemus 112): the Oni King, the barrel on his shoulder
	"bosses/kage": 64.0,  # TUNING (not in GDD) boss tier for a slender figure (a ninja grandmaster, not a giant): body ~58, the hair and scarf above; her clones wear it
	"player/grave_kunoichi": 56.0,  # TUNING (not in GDD) character tier: body ~50, the hair knot above
	"player/grave_kunoichi_hyper": 58.0,  # TUNING (not in GDD) skin art: her body, the gold crest above
	"player/grave_kunoichi_untouchable": 56.0,  # TUNING (not in GDD) skin art: her body
	"player/grave_kunoichi_deathlord": 58.0,  # TUNING (not in GDD) skin art: her body, the spiked crown above
	# --- Act V: the Road to the Sun ---
	"shogunate/kitsune": 52.0,  # TUNING (not in GDD) support tier: body ~44, her ears and tails above (the figure redesign)
	"shogunate/sohei": 56.0,  # TUNING (not in GDD) soldier tier: body ~46, the naginata's blade above
	"shogunate/kirin": 96.0,  # TUNING (not in GDD) miniboss tier: a tall beast, the horn and mane on top
	"bosses/amaterasu": 116.0,  # TUNING (not in GDD) boss tier: a goddess, her sun crown and mirror above
	"bosses/amaterasu_mirror": 112.0,  # TUNING (not in GDD) attack pose (BossPoseData 1): the mirror raised high
	"player/shrine_maiden": 56.0,  # TUNING (not in GDD) character tier: body ~48, the hair ornament and the gohei above
	"player/shrine_maiden_hyper": 56.0,  # TUNING (not in GDD) skin art: her body, gold and white
	"player/shrine_maiden_untouchable": 56.0,  # TUNING (not in GDD) skin art: her body, the white phantom
	"player/shrine_maiden_deathlord": 58.0,  # TUNING (not in GDD) skin art: her body, the spiked crown above
	"summons/bound_oni": 60.0,  # TUNING (not in GDD) a heavy summon (Abomination ~56), the horns and kanabō above
	"summons/oni_lord": 70.0,  # TUNING (not in GDD) its evolution, bigger
	# --- Act V: Castle Kurogane (assets/sprites/shogunate/, bosses/, player/) ---
	"shogunate/hatamoto": 72.0,  # TUNING (not in GDD) elite tier: body ~46, the tall white sashimono banner rising far above the helmet
	"shogunate/kiba_musha": 60.0,  # TUNING (not in GDD) a horse and rider, about 1.2 x as long as tall
	"shogunate/general_left": 100.0,  # TUNING (not in GDD) miniboss tier: the huge black war horse and the antler crest
	"shogunate/command_platform": 124.0,  # TUNING (not in GDD) the Shogun's platform with its four nobori (BossShogun draws it at its art size)
	"bosses/shogun": 116.0,  # TUNING (not in GDD) boss tier: the crescent crest and the raised war fan (Achilles 120)
	"bosses/shogun_duel": 100.0,  # TUNING (not in GDD) duel pose: low iai stance, the blade drawn level (BossPoseData 3)
	"player/ronin_revenant": 58.0,  # TUNING (not in GDD) character tier: body ~50, the straw hat and the small banner above
	"player/ronin_revenant_hyper": 58.0,  # TUNING (not in GDD) skin art: his body, the gilded hat
	"player/ronin_revenant_untouchable": 58.0,  # TUNING (not in GDD) skin art: his body, the white phantom
	"player/ronin_revenant_deathlord": 58.0,  # TUNING (not in GDD) skin art: his body, the black iron crest
	# --- Act VI: the Inferno (the shared kinds; assets/sprites/inferno/) ---
	"inferno/damned": 30.0,  # TUNING (not in GDD) fodder: a hunched wailing soul in chains, body ~30
	"inferno/imp": 32.0,  # TUNING (not in GDD) fodder flier: body ~26 + two empty rows on top for the hover bob, the pitchfork and horns above
	"inferno/hell_knight": 54.0,  # TUNING (not in GDD) soldier tier: body ~50, the horned helm above, the burning greatsword held forward
	"inferno/succubus": 56.0,  # TUNING (not in GDD) elite tier, female (figure redesign, the approved act6_units concept; 56, not 48: at 48 the face and the hourglass were lost, as with the Kunoichi at 52): body ~52, the curled horns above; she flies, the bust and hip box sway in the glide strip
	"inferno/demon_brute": 84.0,  # TUNING (not in GDD) heavy tier (60-72 and up): a huge four-armed demon, the horns and the raised fists
	"structures/demon_portal": 64.0,  # TUNING (not in GDD) the Inferno's portal structure: an obsidian-and-lava ring with a charm-pink swirl (the looping glow is drawn by code)
	# --- Act VI: the Burning Gate (assets/sprites/inferno/, bosses/, player/) ---
	"inferno/lava_hound": 30.0,  # TUNING (not in GDD) pack tier: a long low hound, ~1.5 x as long as tall
	"inferno/pit_cultist": 46.0,  # TUNING (not in GDD) support tier: a robed man, the horned mask above
	"inferno/gatekeeper": 108.0,  # TUNING (not in GDD) miniboss tier (104+, the General 100): a chained giant
	"bosses/moloch": 124.0,  # TUNING (not in GDD) boss tier, colossal: the bull horns and the furnace belly (the Shogun 116)
	"player/furnace_priest": 56.0,  # TUNING (not in GDD) character tier: body ~50, the horned mitre above
	"player/furnace_priest_hyper": 56.0,  # TUNING (not in GDD) skin art: his body, gilded
	"player/furnace_priest_untouchable": 56.0,  # TUNING (not in GDD) skin art: his body, the white phantom
	"player/furnace_priest_deathlord": 58.0,  # TUNING (not in GDD) skin art: his body, the spiked crown above
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
	# --- Chest beacon (ChestBeaconData) ---
	"markers/chest_beacon": 19.0,  # TUNING (not in GDD) gold down-chevron over a chest, 19 x 15
	"markers/chest_badge": 21.0,  # TUNING (not in GDD) off-screen chest badge, 21 x 21 (edge arrows)
	# --- Gullhaven Harbour (harbour placeholder art pass; MarkerArtData "Gullhaven Harbour") ---
	"structures/harbour_pier": 152.0,  # TUNING (not in GDD) a smugglers' dry pier, 152 x 40, along +x (pier_length 150 x pier_width 40)
	# --- Act III missing sprites (hand-built on the grid, tools/act3_projectiles.py) ---
	"projectiles/soul_round": 12.0,  # TUNING (not in GDD) a Grave Gunner's rifle round, 12 x 5, soul-teal fire
	"projectiles/scrap_bolt": 14.0,  # TUNING (not in GDD) a scrap drone's bolt, 14 x 6, a bone shard wrapped in violet
	"projectiles/iron_shell": 20.0,  # TUNING (not in GDD) an Iron Revenant's cannon shell, 20 x 8, with a soul-teal trail
	"projectiles/trojan_rocket": 24.0,  # TUNING (not in GDD) the Trojan Horse's Swarm Rocket, 24 x 12 (its hit circle is 6 px)
	"projectiles/trojan_rocket_flame": 36.0,  # TUNING (not in GDD) its exhaust, a 3-frame strip of 12 x 8 (drawn by SpriteBank.draw_flat_frame)
	"projectiles/empire_rail": 46.0,  # TUNING (not in GDD) the Lock-On rail slug, 46 x 7 (EmpireRulesData rail "art")
	"projectiles/empire_missile": 26.0,  # TUNING (not in GDD) Deus Ex Machina's missile, 26 x 10 with its exhaust (missile "art")
	"projectiles/mortar_shell": 12.0,  # TUNING (not in GDD) the Mortar Walker's lobbed shell, 12 x 12 (mortar "art")
	"projectiles/deus_missile": 26.0,  # TUNING (not in GDD) the Deus Revenant's missile, 26 x 10 (HordeHazards draws it along its arc)
	"projectiles/scrap_drone": 44.0,  # TUNING (not in GDD) a Scrap Swarm drone, a 2-frame rotor strip of 22 x 14
	"projectiles/scrap_drone_bright": 44.0,  # TUNING (not in GDD) a Deathless Swarm kill drone (violet rotors), the same strip
	"projectiles/harbour_anchor": 28.0,  # TUNING (not in GDD) the Harbourmaster's anchor raised or hurled, 24 x 28
	"projectiles/anchor_chain_link": 7.0,  # TUNING (not in GDD) one link of the anchor chain, 7 x 5, along +x
	"overlays/harbour_net": 33.0,  # TUNING (not in GDD) the Netcaster's net, 33 x 33, scaled to the pinned body
	"overlays/tide_wall": 152.0,  # TUNING (not in GDD) the Tide Caller's rising water line, 152 x 28, along +x (wall_length 150)
	"overlays/undertow_crest": 14.0,  # TUNING (not in GDD) one foam crest of the Undertow wave, 10 x 14, facing +x
	"overlays/maelstrom_whirl": 96.0,  # TUNING (not in GDD) a Maelstrom whirlpool from above, 92 x 96
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
## Size (texels) of the shared white disc texture (SpriteBank.disc()) that drop
## shadows and volley glows are drawn with: one textured rect each, which the 2D
## renderer batches, where a draw_circle is a 64-point polygon whose GPU buffers
## Godot rebuilds on every redraw (GDD §15.0 "Disc texture for shadows and glows").
const DISC_PX: int = 64  # TUNING (not in GDD) mobile
