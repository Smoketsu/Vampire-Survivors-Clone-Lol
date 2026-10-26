## FrontDoorData: every number and short caption of the front door screens
## (GDD §15.0 "Front door screens"): the main menu (MainMenu, MenuLogo,
## SoulMarker), the stage select (StageSelect, StageVignette) and the pre-run
## setup (PreRunSetup, CharacterPicker, PreRunHero, PreRunHyperSkins). Sizes
## are layout px on the 1280x720 layout (x1.5 in a 1080p window). Art keys are
## SpriteData keys (res://assets/sprites/<key>.png). Data only, no logic.
class_name FrontDoorData
extends RefCounted

# ------------------------------------------------------------------ main menu

## Main-menu entries top to bottom: [id, one-word caption]. "codex" and
## "credits" open screens added by another branch (MainMenu loads them at
## runtime and plays `denied` while they are missing); "quit" asks first when
## the confirm dialog exists; "feedback" opens the feedback form in the browser
## and is left out while no form link is set (FeedbackReport.enabled()).
const MENU_ITEMS: Array = [
	["play", "Play"],  # TUNING (not in GDD) owner: one-word buttons
	["coop", "Co-op"],  # TUNING (not in GDD) online co-op (CoopScreen; GDD §15.0 "Online co-op: relay and lobby")
	["codex", "Codex"],  # TUNING (not in GDD)
	["ossuary", "Ossuary"],  # TUNING (not in GDD)
	["settings", "Settings"],  # TUNING (not in GDD)
	["credits", "Credits"],  # TUNING (not in GDD)
	["feedback", "Feedback"],  # TUNING (not in GDD) owner request: opens the feedback form (FeedbackData); shown only while a form link is set
	["quit", "Quit"],  # TUNING (not in GDD)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	["epilogue", "Epilogue"],  # TUNING (not in GDD) the campaign epilogue (EpilogueData); shown once a part is open, above Credits
]
## Co-op button icon: MaskIconData key, drawn COOP_ICON_COUNT times side by
## side (two skulls: two necromancers) at COOP_ICON_SCALE x, COOP_ICON_INSET px
## from the button's left edge.
const COOP_ICON: String = "skull"  # TUNING (not in GDD)
const COOP_ICON_COUNT: int = 2  # TUNING (not in GDD)
const COOP_ICON_SCALE: int = 2  # TUNING (not in GDD)
const COOP_ICON_INSET: float = 10.0  # TUNING (not in GDD)
## MENU_ITEMS ids left out of the title screen on the Web build (a browser
## tab cannot quit; GDD §15.0 "Web build").
const WEB_HIDDEN_ITEMS: Array = ["quit"]  # TUNING (not in GDD)
## Tagline under the logo (BODY tier).
const MENU_TAGLINE: String = "Begin as the hunted. Raise the fallen. Become the army."  # TUNING (not in GDD)
## Distance (px) from the screen top to the logo's top.
const MENU_TOP: float = 30.0  # TUNING (not in GDD)
## Width (px) of the menu button column (narrow: one-word buttons).
const MENU_COLUMN_WIDTH: float = 232.0  # TUNING (not in GDD)
## Height (px) of one menu button (the kit button needs at least 20).
const MENU_BUTTON_HEIGHT: float = 36.0  # TUNING (not in GDD)
## Gap (px) between two menu buttons.
const MENU_BUTTON_GAP: int = 6  # TUNING (not in GDD)
## Gap (px) between the column's blocks (logo, tagline, buttons, plaque).
const MENU_BLOCK_GAP: int = 12  # TUNING (not in GDD)
## Dark band of the diorama behind the column: full width (px) and peak
## alpha (0-1); MenuBackdrop.set_band().
const MENU_BAND_WIDTH: float = 600.0  # TUNING (not in GDD) the 492 px logo plus a soft margin
const MENU_BAND_ALPHA: float = 0.55  # TUNING (not in GDD)
## Soul Ash plaque: icon size (px) and the gap (px) between its parts.
const PLAQUE_ICON_PX: float = 28.0  # TUNING (not in GDD)
const PLAQUE_GAP: int = 8  # TUNING (not in GDD)
## Lifetime stats row: icon scale (layout px per art px), gap (px) between an
## icon and its number, and between two stats.
const STAT_ICON_SCALE: int = 2  # TUNING (not in GDD)
const STAT_INNER_GAP: int = 5  # TUNING (not in GDD)
const STAT_GAP: int = 20  # TUNING (not in GDD)
## Version label inset (px) from the bottom-right corner, and its alpha (0-1).
const VERSION_INSET: Vector2 = Vector2(14.0, 12.0)  # TUNING (not in GDD)
const VERSION_ALPHA: float = 0.55  # TUNING (not in GDD)
## Menu entrance: delay (s) before the buttons' staggered rise.
const MENU_STAGGER_DELAY: float = 0.12  # TUNING (not in GDD)
## A longer column (Feedback, the Epilogue) must still clear the bottom hint
## strip: with more than MENU_ROOMY_ITEMS buttons the column starts higher
## (MENU_COMPACT_TOP px) and its gaps shrink (MENU_COMPACT_BUTTON_GAP px between
## buttons, MENU_COMPACT_BLOCK_GAP px between blocks); with more than
## MENU_ROOMY_ITEMS + 1 the tagline is left out too.
const MENU_ROOMY_ITEMS: int = 6  # TUNING (not in GDD) Play, Codex, Ossuary, Settings, Credits, Quit
const MENU_COMPACT_TOP: float = 16.0  # TUNING (not in GDD)
const MENU_COMPACT_BUTTON_GAP: int = 3  # TUNING (not in GDD)
const MENU_COMPACT_BLOCK_GAP: int = 6  # TUNING (not in GDD)

# ------------------------------------------------------------------ logo

## Colours (8-bit RGB) of the logo's soul flames in assets/ui/logo.png: these
## pixels sway (MenuLogo); the dark one is the flames' own outline.
const LOGO_FLAME_COLORS: Array = [
	Color8(28, 107, 88), Color8(61, 204, 148), Color8(168, 255, 210), Color8(8, 24, 20),
]  # TUNING (not in GDD) measured from logo.png
## Flame animation: frames in the loop, frames per second, and the sway's
## largest sideways shift (art px) at a flame's tip.
const LOGO_FLAME_FRAMES: int = 8  # TUNING (not in GDD)
const LOGO_FLAME_FPS: float = 7.0  # TUNING (not in GDD)
const LOGO_FLAME_SWAY: float = 1.6  # TUNING (not in GDD) whole art px after rounding: 0-2
## Phase step (rad) per art px of height above a flame's base: the wave that
## climbs each flame.
const LOGO_FLAME_WAVE: float = 0.55  # TUNING (not in GDD)
## Soul glow behind each flame: menu glow art scale, alpha, pulse share (0-1)
## and period (s).
const LOGO_GLOW_SCALE: float = 0.5  # TUNING (not in GDD)
const LOGO_GLOW_ALPHA: float = 0.22  # TUNING (not in GDD)
const LOGO_GLOW_PULSE: float = 0.3  # TUNING (not in GDD)
const LOGO_GLOW_PERIOD: float = 3.2  # TUNING (not in GDD)
## Embers rising from the flame tips: seconds between two (random in range),
## rise speed (art px/s), sideways drift (art px/s), life (s), most at once.
const LOGO_EMBER_INTERVAL: Vector2 = Vector2(0.35, 0.9)  # TUNING (not in GDD)
const LOGO_EMBER_RISE: Vector2 = Vector2(6.0, 11.0)  # TUNING (not in GDD)
const LOGO_EMBER_DRIFT: float = 2.5  # TUNING (not in GDD)
const LOGO_EMBER_LIFE: Vector2 = Vector2(1.4, 2.4)  # TUNING (not in GDD)
const LOGO_EMBER_MAX: int = 8  # TUNING (not in GDD)
## Ember colours, bright first.
const LOGO_EMBER_COLORS: Array = [Color8(168, 255, 210), Color8(61, 204, 148)]  # TUNING (not in GDD)

# ------------------------------------------------------------------ focus wisp

## The soul wisp marking the focused menu button (SoulMarker, menu/wisp art):
## gap (px) between the button's edge and the wisp, frames per second, the
## slide time (s) to a newly focused button, bob (px) and bob period (s).
const MARKER_GAP: float = 8.0  # TUNING (not in GDD)
const MARKER_FPS: float = 8.0  # TUNING (not in GDD)
const MARKER_SLIDE_TIME: float = 0.12  # TUNING (not in GDD)
const MARKER_BOB: float = 1.0  # TUNING (not in GDD)
const MARKER_BOB_PERIOD: float = 1.6  # TUNING (not in GDD)
## Glow under the wisp: menu glow art scale and alpha.
const MARKER_GLOW_SCALE: float = 0.55  # TUNING (not in GDD)
const MARKER_GLOW_ALPHA: float = 0.35  # TUNING (not in GDD)

# ------------------------------------------------------------------ stage select

## One stage card (px).
const CARD_SIZE: Vector2 = Vector2(300.0, 424.0)  # TUNING (not in GDD)
## Gap (px) between two stage cards.
const CARD_GAP: int = 20  # TUNING (not in GDD)
## Inset (px) of a card's content from its edge.
const CARD_INSET: float = 12.0  # TUNING (not in GDD)
## The vignette scene of a card (px; the card's width minus its insets).
const VIGNETTE_SIZE: Vector2 = Vector2(276.0, 232.0)  # TUNING (not in GDD)
## Back button of the stage select (px).
const STAGE_BACK_SIZE: Vector2 = Vector2(180.0, 36.0)  # TUNING (not in GDD)
## Vignette brightness while its card is not focused (1 = full).
const VIGNETTE_IDLE_BRIGHT: float = 0.72  # TUNING (not in GDD)
## Seconds for a vignette to brighten / dim with focus.
const VIGNETTE_FOCUS_TIME: float = 0.2  # TUNING (not in GDD)
## Edge shading of a vignette: alpha (0-1) of the dark inner frame bands and
## their width (px) in steps (stepped, pixel-art style).
const VIGNETTE_EDGE_ALPHA: float = 0.5  # TUNING (not in GDD)
const VIGNETTE_EDGE_STEPS: Array = [6.0, 12.0, 20.0]  # TUNING (not in GDD)
## Locked vignette: the silhouette tint of every sprite and the floor's tint.
const LOCK_SILHOUETTE: Color = Color(0.05, 0.035, 0.07)  # TUNING (not in GDD)
const LOCK_FLOOR: Color = Color(0.66, 0.6, 0.76)  # TUNING (not in GDD)
## Padlock scale (layout px per art px) on a locked vignette.
const LOCK_ICON_SCALE: int = 3  # TUNING (not in GDD)
## Unit drop shadow: width share of the sprite, vertical squash, alpha.
const VIGNETTE_SHADOW: Vector3 = Vector3(0.62, 0.32, 0.38)  # TUNING (not in GDD)
## Denied shake of a locked card: amplitude (px) and duration (s).
const DENIED_SHAKE_PX: float = 5.0  # TUNING (not in GDD)
const DENIED_SHAKE_TIME: float = 0.28  # TUNING (not in GDD)

## One line per stage (owner: no wall of text; the long GDD description is
## the card's tooltip).
const STAGE_LINES: Dictionary = {
	"graveyard": "Hold your burial grounds for twenty minutes.",  # TUNING (not in GDD)
	"crimson_march": "Burn the road to the Covenant's fortress.",  # TUNING (not in GDD)
	"sanctum": "Storm the cathedral. End the Covenant.",  # TUNING (not in GDD)
	"harbour": "Follow your stolen dead to the drowning town.",  # TUNING (not in GDD) Act II
	"archive": "Learn where the god sleeps.",  # TUNING (not in GDD) Act II
	"spire": "The god is dead. Raise her.",  # TUNING (not in GDD) Act II
	"wastes": "Your beacons drew the Empire. Meet it.",  # TUNING (not in GDD) Act III
	"assembly": "Break the line that rebuilds the dead.",  # TUNING (not in GDD) Act III
	"citadel": "Death was conquered with steel. Take it back.",  # TUNING (not in GDD) Act III
	# --- Act IV: the Olympian Republic ---
	"ilion": "The gods want the dead back. Meet them on the beach.",  # TUNING (not in GDD) Act IV
	"olympus": "Climb the mountain. Face the Pantheon.",  # TUNING (not in GDD) Act IV
	"underworld": "Go down to the god who started it.",  # TUNING (not in GDD) Act IV
}

## Size (px) of an act tab button on the stage select (Act I / Act II / Act III).
const ACT_TAB_SIZE: Vector2 = Vector2(300.0, 40.0)  # TUNING (not in GDD)
# --- Act IV: the Olympian Republic ---
## Most act tabs shown at full size ("Act I · The Crimson Covenant"); with more
## acts than this, only the shown act's tab keeps its full text and size and the
## others shrink to ACT_TAB_COMPACT_SIZE showing the act name only, so the row
## fits six acts at 1280 x 600 layout px (GDD §15.0 "Act IV foundation (phase 1)").
const ACT_TABS_FULL_MAX: int = 3  # TUNING (not in GDD)
## Size (px) of a compact act tab ("Act IV").
const ACT_TAB_COMPACT_SIZE: Vector2 = Vector2(104.0, 40.0)  # TUNING (not in GDD)
## Lock line of a registered stage that is not yet playable (StageRegistry "playable").
const COMING_SOON: String = "Coming soon"  # TUNING (not in GDD)

## Vignette scene per stage: "tile" (floor tile, repeated), "items" (drawn in
## order: [sprite key, x, y, flip]; x is the centre, y the feet (bottom) in
## px from the vignette's top-left; decals are centred on y), "fx" (ambient
## motes: "wisps" rising soul flames, "embers" drifting sparks, "motes" holy
## light), "fx_color". Built from art the game already has; the boss stands in
## an attack pose (bosses/<id>_windup / _cast) facing the undead.
const VIGNETTES: Dictionary = {
	"graveyard": {
		"tile": "tiles/graveyard",
		"items": [
			["decals/graveyard_grave", 70, 150, false], ["decals/graveyard_grass", 210, 40, false],
			["obstacles/dead_tree_m", 36, 96, false], ["obstacles/gravestone_l", 118, 78, false],
			["obstacles/gravestone_s", 150, 60, true], ["obstacles/cypress_s", 248, 92, false],
			["obstacles/gravestone_s", 22, 150, false],
			["summons/archer", 30, 188, false], ["summons/warrior", 52, 214, false], ["summons/mage", 92, 226, false],
			["bosses/alaric_windup", 190, 222, true],
		],
		"fx": "wisps", "fx_color": Color8(61, 204, 148),
	},  # TUNING (not in GDD)
	"crimson_march": {
		"tile": "tiles/march_burned",
		"items": [
			["decals/march_burned_embers", 150, 160, false], ["decals/march_arrow", 60, 130, false],
			["obstacles/burned_house_m", 60, 64, false], ["obstacles/barricade_s", 130, 104, false],
			["structures/watchtower", 200, 100, false], ["obstacles/charred_tree_m", 250, 84, false],
			["enemies/shieldbearer", 238, 172, true],
			["summons/archer", 26, 186, false], ["summons/warrior", 46, 214, false], ["summons/rogue", 90, 224, false],
			["bosses/vael_windup", 176, 222, true],
		],
		"fx": "embers", "fx_color": Color8(255, 140, 38),
	},  # TUNING (not in GDD)
	"sanctum": {
		"tile": "tiles/sanctum_halls",
		"items": [
			["decals/sanctum_halls_carpet", 138, 150, false],
			["obstacles/marble_column_m", 26, 94, false], ["obstacles/marble_column_m", 250, 94, false],
			["structures/sacred_altar", 140, 82, false],
			["enemies/high_confessor", 226, 162, true],
			["summons/warrior", 46, 214, false], ["summons/mage", 90, 224, false],
			["bosses/seraphine_cast", 178, 222, true],
		],
		"fx": "motes", "fx_color": Color8(255, 226, 140),
	},  # TUNING (not in GDD)
	# --- Act II: Gullhaven Harbour ---
	"harbour": {
		"tile": "tiles/harbour_mudflats",
		"items": [
			["obstacles/wreck_ribs_s", 60, 70, false], ["obstacles/mooring_post_l", 250, 86, false],
			["structures/bell_buoy", 150, 96, false], ["obstacles/net_pile_s", 24, 150, false],
			["eye/deep_kin", 236, 170, true], ["eye/tide_caller", 206, 150, true],
			["summons/warrior", 46, 214, false], ["summons/archer", 88, 224, false],
			["bosses/merrow_sermon", 172, 226, true],
		],
		"fx": "wisps", "fx_color": Color8(127, 181, 172),
	},  # TUNING (not in GDD) drowned teal wisps
	# --- Act II: the Hollow Archive ---
	"archive": {
		"tile": "tiles/archive_halls",
		"items": [
			["decals/ink_pool", 196, 168, false],
			["obstacles/bookshelf_l", 54, 70, false], ["obstacles/blank_shelf_m", 226, 62, false],
			["structures/forbidden_lectern", 138, 104, false],
			["eye/scribe", 236, 150, true], ["eye/ink_wraith", 206, 188, true],
			["summons/archer", 26, 186, false], ["summons/warrior", 48, 214, false], ["summons/mage", 92, 226, false],
			["bosses/archivist_cast", 176, 226, true],
		],
		"fx": "wisps", "fx_color": Color8(240, 156, 242),
	},  # TUNING (not in GDD)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"spire": {
		"tile": "tiles/spire_breakwater",
		"items": [
			["decals/spire_breakwater_barnacles", 150, 150, false],
			["obstacles/barnacle_pillar_m", 28, 96, false], ["obstacles/cyclopean_block_s", 248, 104, false],
			["eye/dream_pillar", 140, 98, false],
			["eye/eye_siren", 248, 196, true],
			["summons/warrior", 46, 214, false], ["summons/spawn_of_the_deep", 92, 226, false],
			["eye/vhalneth_arm", 178, 226, true],
		],
		"fx": "motes", "fx_color": Color8(176, 76, 192),
	},  # TUNING (not in GDD) the Eye's biolume motes
	# --- Act III: the Electronic Empire (the Scrap Wastes: its own slag floor, wreckage, a signal pylon,
	# its Aegis Bot, Scout Drones and Kestrel in her aim pose; Act III missing sprites) ---
	"wastes": {
		"tile": "tiles/wastes_slag",
		"items": [
			["obstacles/titan_hull_s", 70, 96, false], ["obstacles/wreck_plate_s", 204, 92, false],
			["obstacles/slag_mound_m", 150, 64, false], ["obstacles/tank_trap_s", 24, 150, false],
			["empire/signal_pylon", 252, 128, false],
			["empire/scout_drone", 122, 44, true],
			["empire/aegis_bot", 100, 164, true],
			["summons/warrior", 46, 214, false], ["summons/archer", 88, 224, false],
			["bosses/kestrel_aim", 196, 226, true],
		],
		"fx": "embers", "fx_color": Color8(255, 174, 26),
	},  # TUNING (not in GDD) signal-amber sparks
	# --- Act III: the Assembly Halls (its own floor, props, kinds and boss) ---
	"assembly": {
		"tile": "tiles/assembly_fabricator",
		"items": [
			["obstacles/press_machine_s", 40, 84, false], ["obstacles/fuel_drum_l", 252, 90, false],
			["empire/fabricator", 146, 100, false],
			["empire/arc_engineer", 240, 170, true], ["empire/juggernaut", 206, 156, true],
			["summons/warrior", 46, 214, false], ["summons/grave_drone", 92, 200, false],
			["bosses/motherboard", 178, 236, true],
		],
		"fx": "embers", "fx_color": Color8(255, 174, 26),
	},  # TUNING (not in GDD) signal-amber sparks over the fabricator floor
	# --- Act III: the Iron Citadel (its own floor, props, turret, Valkyrie and engine) ---
	"citadel": {
		"tile": "tiles/citadel_gates",
		"items": [
			["obstacles/emitter_pylon_m", 30, 100, false], ["obstacles/iron_barricade_s", 244, 108, false],
			["empire/sentry_turret", 140, 96, true],
			["empire/valkyrie_duelist", 236, 184, true],
			["summons/warrior", 46, 214, false], ["summons/archer", 92, 226, false],
			["bosses/deus_ex_machina_fire", 178, 226, true],
		],
		"fx": "embers", "fx_color": Color8(224, 57, 30),
	},  # TUNING (not in GDD) warning-red sparks
	# --- Act IV: the Olympian Republic (placeholder scenes from the shared kinds' art
	# until each stage brings its own floor, props and boss; a missing sprite is skipped) ---
	"ilion": {
		"tile": "tiles/harbour_mudflats",
		"items": [
			["pantheon/shade_of_dead", 210, 80, true], ["pantheon/hoplite", 200, 176, true],
			["pantheon/hoplite", 236, 196, true], ["pantheon/hero", 172, 224, true],
			["summons/warrior", 46, 214, false], ["summons/archer", 88, 224, false],
		],
		"fx": "motes", "fx_color": Color8(111, 182, 232),
	},  # TUNING (not in GDD) aegean_light spray
	"olympus": {
		"tile": "tiles/sanctum_halls",
		"items": [
			["obstacles/marble_column_m", 26, 94, false], ["obstacles/marble_column_m", 250, 94, false],
			["pantheon/hoplite", 214, 180, true], ["pantheon/hero", 176, 224, true],
			["summons/warrior", 46, 214, false], ["summons/mage", 90, 224, false],
		],
		"fx": "embers", "fx_color": Color8(224, 169, 85),
	},  # TUNING (not in GDD) bronze_light sparks of the storm
	"underworld": {
		"tile": "tiles/graveyard",
		"items": [
			["pantheon/shade_of_dead", 200, 90, true], ["pantheon/shade_of_dead", 240, 130, true],
			["pantheon/bronze_titan", 186, 226, true],
			["summons/warrior", 46, 214, false], ["summons/archer", 88, 224, false],
		],
		"fx": "wisps", "fx_color": Color8(207, 203, 196),
	},  # TUNING (not in GDD) pale marble wisps of the dead
}
## Ambient motes of a vignette: most at once, seconds between two (random in
## range), life (s), rise speed (px/s), sideways sway (px).
const VIGNETTE_FX_MAX: int = 7  # TUNING (not in GDD)
const VIGNETTE_FX_INTERVAL: Vector2 = Vector2(0.25, 0.7)  # TUNING (not in GDD)
const VIGNETTE_FX_LIFE: Vector2 = Vector2(1.6, 3.0)  # TUNING (not in GDD)
const VIGNETTE_FX_RISE: Vector2 = Vector2(8.0, 18.0)  # TUNING (not in GDD)
const VIGNETTE_FX_SWAY: float = 3.0  # TUNING (not in GDD)

# ------------------------------------------------------------------ pre-run setup

## Alpha (0-1) of the pre-run screen's own scrim: low, so the diorama shows
## around its panels (the stage select under it keeps its own scrim).
const PRERUN_SCRIM: float = 0.3  # TUNING (not in GDD)
## Gap (px) between the hero column and the setup column.
const PRERUN_COLUMN_GAP: int = 14  # TUNING (not in GDD)
## Width (px) of the hero panel (the left column).
const HERO_WIDTH: float = 410.0  # TUNING (not in GDD)
## The hero's stage box inside the panel (px).
const HERO_STAGE_SIZE: Vector2 = Vector2(362.0, 226.0)  # TUNING (not in GDD)
## The hero's scale (layout px per art px): 3x, the selected character big.
const HERO_SCALE: int = 3  # TUNING (not in GDD) owner brief: the character is the hero
## Walk-cycle frames per second of the hero (walking in place).
const HERO_WALK_FPS: float = 8.0  # TUNING (not in GDD)
## Height (px) from the stage box's bottom to the hero's feet.
const HERO_FEET_UP: float = 16.0  # TUNING (not in GDD)
## The hero's pedestal glow (the character's school colour): menu glow art
## scale and alpha (0-1), and the floor tile's brightness under it (0-1).
const HERO_GLOW_SCALE: float = 2.6  # TUNING (not in GDD)
const HERO_GLOW_ALPHA: float = 0.32  # TUNING (not in GDD)
## How far the glow's school colour is lightened toward white (0-1).
const HERO_GLOW_LIGHTEN: float = 0.35  # TUNING (not in GDD)
const HERO_FLOOR_BRIGHT: float = 0.8  # TUNING (not in GDD)
## Width (px) of the hero panel's text (innate wraps inside it).
const HERO_TEXT_WIDTH: float = 362.0  # TUNING (not in GDD)
## Width (px) of the setup column (character grid, difficulty, modifiers, plaque).
const SETUP_WIDTH: float = 806.0  # TUNING (not in GDD)
## Character tile (px) and tiles per row (12 = one row).
const CHAR_TILE: Vector2 = Vector2(60.0, 60.0)  # TUNING (not in GDD)
const CHAR_COLUMNS: int = 12  # TUNING (not in GDD)
const CHAR_GAP: int = 5  # TUNING (not in GDD)
## Skin portrait tile (px) and the Hyper tile (px).
const SKIN_TILE: Vector2 = Vector2(56.0, 64.0)  # TUNING (not in GDD)
const HYPER_TILE: Vector2 = Vector2(150.0, 64.0)  # TUNING (not in GDD)
## Difficulty card (px; four in a row), its icon scale.
const LEVEL_CARD: Vector2 = Vector2(194.0, 90.0)  # TUNING (not in GDD)
const LEVEL_ICON_SCALE: int = 2  # TUNING (not in GDD)
## Run-modifier tile (px) and tiles per row.
const MOD_TILE: Vector2 = Vector2(194.0, 38.0)  # TUNING (not in GDD)
const MOD_COLUMNS: int = 4  # TUNING (not in GDD)
## Seconds the gold total plaque rolls to a new value.
const PLAQUE_COUNT_TIME: float = 0.35  # TUNING (not in GDD)
## Bottom buttons (px): Back and Standard, and the primary Begin.
const PRERUN_BUTTON: Vector2 = Vector2(150.0, 40.0)  # TUNING (not in GDD)
const BEGIN_BUTTON: Vector2 = Vector2(260.0, 40.0)  # TUNING (not in GDD)

## One line per difficulty card (the full GDD line and its numbers are the
## card's tooltip).
const LEVEL_LINES: Dictionary = {
	"initiate": "Gentler scaling.",  # TUNING (not in GDD)
	"necromancer": "The standard ritual.",  # TUNING (not in GDD)
	"lich": "Tougher, faster foes.",  # TUNING (not in GDD)
	"deathlord": "Elites join the march.",  # TUNING (not in GDD)
}
## MaskIconData icon per difficulty card.
const LEVEL_ICONS: Dictionary = {
	"initiate": "candle", "necromancer": "skull", "lich": "lich", "deathlord": "deathlord",
}  # TUNING (not in GDD)
## Hint line under the modifiers while none is focused.
const MOD_HINT: String = "Modifiers stack and add Soul Ash."  # TUNING (not in GDD)
## That line for a co-op guest (the host picks the difficulty, modifiers and Hyper).
const COOP_GUEST_HINT: String = "The host picks the difficulty, modifiers and Hyper."  # TUNING (not in GDD)

# --- Content wave 2: B. Achievement rewards ---
## The skin row of the setup screen (PreRunHyperSkins) with more skin tiles
## than this (every character now has the two universal skins, SkinData
## UNIVERSAL_SKINS) uses the compact sizes below, so up to five skins and the
## Hyper tile stay inside the hero panel's 362 px.
const SKIN_TILES_FULL: int = 3  # TUNING (not in GDD)
## Compact skin portrait tile (px).
const SKIN_TILE_COMPACT: Vector2 = Vector2(44.0, 64.0)  # TUNING (not in GDD)
## Size (layout px) of the skin recolour cycle button at the end of the skin
## detail line (chip and name; Ossuary expansion step 6b, RecolourData).
const RECOLOUR_BUTTON: Vector2 = Vector2(104.0, 30.0)  # TUNING (not in GDD)
## Size (layout px) of the recolour Buy button (Soul Ash icon and price).
const RECOLOUR_BUY_BUTTON: Vector2 = Vector2(80.0, 30.0)  # TUNING (not in GDD)
## Compact Hyper tile (px).
const HYPER_TILE_COMPACT: Vector2 = Vector2(112.0, 64.0)  # TUNING (not in GDD)
## Gap between compact skin tiles (px; the full row uses 6).
const SKIN_GAP_COMPACT: int = 4  # TUNING (not in GDD)
