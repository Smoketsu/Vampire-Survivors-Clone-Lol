## TitleData — designer data for the necromancer's TITLES (content wave 2,
## owner-approved Proposal 2, GDD §15.0 "Achievement rewards (content wave
## 2)"): a purely cosmetic epithet earned by an achievement and worn under the
## character's name on the pre-run setup screen (PreRunHero) and on the
## victory card. A title never touches a stat. No logic beyond lookups.
##
## Unlocking goes through the ONE reward path: each title id is an UnlockData
## row of type "title" whose `achievement` earns it, read with
## Unlocks.is_open(id) (MetaProgress keeps it in [unlocks]). The title worn is
## the player's choice on the setup screen (PreRunTitleRow), saved in the Meta
## [prerun] section as `title` (Meta.selected_title(); "" = none).
##
## Keys of a title row:
##   display_name — the title as shown ("Heretic's Bane").
##   achievement  — MetaData achievement id that earns it (for the texts; the
##                  unlock itself is the UnlockData row).
##   frame        — portrait frame worn with the title ("" = none,
##                  "chaplain_skull" = the gold Chaplain-skull frame drawn by
##                  TitleFrame around the setup screen's hero).
class_name TitleData
extends RefCounted

## Title ids in display order (the setup screen's cycle order after "None").
const ORDER := ["heretics_bane", "master_of_the_drowned", "archnecromancer", "executioner"]  # owner-approved Proposal 2

## Title id -> row (keys above).
const TITLES := {
	"heretics_bane": {"display_name": "Heretic's Bane", "achievement": "heretics_bane", "frame": "chaplain_skull"},  # owner-approved Proposal 2 (title + gold Chaplain-skull frame)
	"master_of_the_drowned": {"display_name": "Master of the Drowned", "achievement": "the_dead_god_serves", "frame": ""},  # owner-approved Proposal 2
	"archnecromancer": {"display_name": "Archnecromancer", "achievement": "full_ossuary", "frame": ""},  # owner-approved Proposal 2
	"executioner": {"display_name": "Executioner", "achievement": "swift_judgment", "frame": ""},  # owner-approved Proposal 2
}

## Text of the "no title" choice on the setup screen's cycle row.
const NONE_TEXT: String = "None"  # TUNING (not in GDD)
## Label of the setup screen's title row.
const ROW_LABEL: String = "Title"  # TUNING (not in GDD)
## The row's detail line: "<earned>/<all> earned" and, while some are locked,
## the next locked title with the achievement that earns it.
const COUNT_TEXT: String = "%d/%d earned"  # TUNING (not in GDD)
## Detail suffix naming the next locked title and its achievement.
const NEXT_TEXT: String = " · next: %s (%s)"  # TUNING (not in GDD)
## Size of the row's cycle tile (layout px, 1280 x 720 design).
const ROW_TILE: Vector2 = Vector2(196.0, 36.0)  # TUNING (not in GDD)

## The Heretic's Bane frame (TitleFrame): band width (px), chamfer of the cut
## corners (px), pixel scale of the corner skulls and of the mitred Chaplain
## skull at the top centre (screen px per bitmap px).
const FRAME_BAND: float = 4.0  # TUNING (not in GDD)
## Chamfer of the frame's cut corners (px).
const FRAME_CHAMFER: float = 10.0  # TUNING (not in GDD)
## Pixel scale of the four corner skulls.
const FRAME_CORNER_SCALE: int = 2  # TUNING (not in GDD)
## Pixel scale of the mitred Chaplain skull at the top centre.
const FRAME_CREST_SCALE: int = 3  # TUNING (not in GDD)


## True when `id` names a title.
static func has(id: String) -> bool:
	return TITLES.has(id)


## The title as shown ("" for "" or an unknown id): the static accessor the
## victory card uses with Meta.selected_title().
static func display_text(id: String) -> String:
	if not TITLES.has(id):
		return ""
	return String(TITLES[id]["display_name"])


## Portrait frame worn with title `id` ("" = none).
static func frame_of(id: String) -> String:
	if not TITLES.has(id):
		return ""
	return String(TITLES[id]["frame"])


## Achievement id that earns title `id` ("" if unknown).
static func achievement_of(id: String) -> String:
	if not TITLES.has(id):
		return ""
	return String(TITLES[id]["achievement"])
