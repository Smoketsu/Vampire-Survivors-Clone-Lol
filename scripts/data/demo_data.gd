## DemoData — what the free demo build holds (owner request "let's do a demo
## mode switch", Nov 2026; GDD §15.0 "Demo mode (owner request, Nov 2026)";
## the funnel in docs/marketing/MARKETING_PLAN.md §2.3). Demo mode is ON only
## in a build exported with the custom feature tag FEATURE_TAG (the "Web Demo"
## export preset) or with the test flag --demo; everywhere else nothing here is
## read and the game is the full game, bit for bit. Every rule reads these
## lists through DemoMode (scripts/core/demo_mode.gd), the one path. Data only,
## no logic.
class_name DemoData
extends RefCounted

# ------------------------------------------------------------------ switch

## Custom export feature tag that turns demo mode on (OS.has_feature()). The
## "Web Demo" preset in export_presets.cfg sets it; no other preset does.
const FEATURE_TAG: String = "demo"  # TUNING (not in GDD)

# ------------------------------------------------------------------ content

## Acts (StageRegistry.ACTS keys) whose stages the demo lets the player play.
## Every other act's tab and stage cards stay visible, locked with LOCK_LINE.
## Act I = the Desecrated Graveyard, the Crimson March and the Sanctum of
## Judgment (the marketing plan's free tier). Add an act number to widen it.
const ACTS: Array[int] = [1]  # TUNING (not in GDD) owner request: an Act I demo

## Lockable items (UnlockData ids) the demo may still unlock and offer: the
## rewards Act I content can earn (achievement rewards and the Bone Golem from
## Bone Legion). Every other UnlockData row (the spells, passives, summon
## classes, titles of Acts II-IX, and the Act II Fallen Seraph that Seraphine's
## fall would open) is "full game": never offered, never unlocked by a demo run,
## shown locked with LOCK_LINE. Items that are not lockable at all (every Act I
## spell, passive and summon class) are always open. A character whose starting
## spell is full game is locked the same way (DemoMode.allows_character()).
const OPEN_ITEMS: Array[String] = [
	"bone_golem", "grave_masonry",  # TUNING (not in GDD) Bone Legion (Skeleton Warriors' kills): earnable in Act I
	"sovereigns_decree", "eclipse", "grave_tide",  # TUNING (not in GDD) ultimates earned by Act I achievements
	"heretics_bane", "archnecromancer", "executioner",  # TUNING (not in GDD) titles earned in any stage
	"untouchable", "deathlord",  # TUNING (not in GDD) universal skins earned in any stage
]

# ------------------------------------------------------------------ words

## Lock line of a full-game stage card, character, Codex entry or reward in the
## demo (the stage select's crimson lock style; few words, owner UI rule).
const LOCK_LINE: String = "Full game"  # TUNING (not in GDD)
## The small badge on the title screen (soul-teal: something new to try).
const BADGE_TEXT: String = "Demo"  # TUNING (not in GDD)
## The stage select's call-to-action line under the cards ("%d" = the number
## of acts left out of the demo).
const CTA_TEXT: String = "%d more acts in the full game"  # TUNING (not in GDD)
## Caption of the call-to-action button (one word, owner rule). It is shown
## only while STORE_URL is set.
const CTA_BUTTON: String = "Wishlist"  # TUNING (not in GDD)
## Tooltip of the call-to-action button (desktop hover): where it goes.
const CTA_TOOLTIP: String = "Opens the game's store page in your browser."  # TUNING (not in GDD)
## The store page the Wishlist button opens (e.g. the Steam page). "" = no
## button: only the line shows and nothing ever opens. The owner sets it.
const STORE_URL: String = ""  # TUNING (not in GDD) owner: set the Steam URL when the page is live

# ------------------------------------------------------------------ layout

## Title screen: the badge's inset (px) from the logo's bottom-right corner
## (it hangs off the logo, so the column's layout is unchanged).
const BADGE_INSET: Vector2 = Vector2(6.0, -4.0)  # TUNING (not in GDD)
## Stage select: the Wishlist button (px) beside Back.
const CTA_BUTTON_SIZE: Vector2 = Vector2(160.0, 44.0)  # TUNING (not in GDD)

# ------------------------------------------------------------------ saves and co-op

## Suffix put before the extension of the progress save's file name in the
## demo (user://save.cfg -> user://save_demo.cfg), so a demo and the full game
## in the same browser (the same origin and project name share one IndexedDB
## folder) never read or overwrite each other's progress. Settings
## (user://settings.cfg) stay shared: they hold no progress.
const SAVE_SUFFIX: String = "_demo"  # TUNING (not in GDD)
## Appended to the co-op game version (CoopNet.game_version()) in the demo,
## so the relay refuses a demo and a full-game player in one lobby (its
## "version" error): a full-game host could otherwise start a later act.
const COOP_VERSION_SUFFIX: String = "-demo"  # TUNING (not in GDD)
