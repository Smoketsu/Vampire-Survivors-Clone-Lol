## VoiceData — immutable design data for THE VOICE, the boss of the Empyrean and
## the Celestial Host's finale (temporary Act XIII, final slot X, the end of
## Part One; GDD §15.0 "The Voice (Act XIII phase 2)"; owner-approved proposal
## docs/proposals/LAST_SIX_ACTS.md section X: "Boss, the Voice (a six-winged
## seraph of light; two wings hide its face, two its feet, two are spread): the
## Holy (the light at its strongest; the Voice never moves), Be Not Afraid (it
## lowers the wings from its face: the screen whitens and every summon in the
## open stops for 2 s; summons behind a barrier or in shadow are spared), the
## Last Word (the scales read the run's sins back: every raise of the run
## returns as a Judge, in waves, until the Voice falls)"). BossVoice
## (scripts/enemies/host/boss_voice.gd, loaded by name for the boss id "voice")
## reads it. A sexless seraph of starlight in a white rose (art `host/voice`,
## `host/voice_unveiled`; no crimson, no warm gold).
##   * IT NEVER MOVES: it comes down arrive_distance px from the nearest
##     necromancer and stays there (the army goes to it).
##   * THE HOLY (all fight): while it stands the Light's max_live is raised by
##     holy_live; every holy_every s (holy_every_p2 below last_word_hp) it opens
##     holy_shafts shafts of Hallowed Light round the necromancer, evenly
##     turned, holy_width px wide, each starting the Light's start_offset px off
##     him and sweeping across him (HallowedLight.add_shaft(), the Light's one
##     path: shade and barriers stop them).
##   * BE NOT AFRAID: every unveil_every s it lowers the wings from its face for
##     unveil_windup s (the telegraph: hide in shade or behind a barrier), then
##     the screen whitens (a flat additive rect: ParagonSky, no screen read)
##     and every summon in the open (not shaded by HallowedLight.shaded(), no
##     barrier) stops unveil_stun s (CombatResolver.stun_unit(), the one summon
##     stun path; Oni's Resolve shortens it like every stun).
##   * THE LAST WORD (once, below last_word_hp of its HP): the scales read the
##     run's sins back: every corpse raised and every summon replaced this run
##     (Judgment.raised + replaced) x judges_per_sin returns as a Judge, at
##     least last_word_min, at most last_word_cap, in waves of wave_size
##     (per necromancer) every wave_every s (Judgment.send_wave()), until the
##     owed Judges are sent or the Voice falls.
## Beaten: a short ending text (ENDING_ANNOUNCE: "heaven, earth and hell
## answer to the necromancer"; no epilogue part until the reorder pass).
## Killing it drops a big XP burst and the boss chest; slaying it unlocks
## Revelation, Seventh Seal, the Bound Ophan and Turning Bones (UnlockData,
## boss "voice"); THE LAST WORD (the achievement) is recorded by
## EmpyreanDirector when it falls on the Empyrean.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name VoiceData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["holy", "unveil", "last_word"]

## Sprite key of its art (assets/sprites/host/voice.png, 104 px, glide strip).
const SPRITE: String = "host/voice"
## Sprite key of its unveiled art (wings lowered from the face; Be Not Afraid).
const UNVEILED_SPRITE: String = "host/voice_unveiled"
## Damage tag of Be Not Afraid's stop (CombatResolver.stun_unit()'s source).
const UNVEIL_SOURCE: String = "voice_unveil"
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 12.0  # TUNING (not in GDD)
## The short ending text shown when it falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE VOICE IS SILENT", "The Voice folds its six wings and says nothing more.", "Heaven, earth and hell answer to the necromancer."]  # Owner-approved proposal: "The ending: the Voice folds its wings and is silent. Part One ends: heaven, earth and hell answer to the necromancer"
## The ending text when it falls during the Last Trumpet.
const LATE_ANNOUNCE := ["THE VOICE IS SILENT", "The Voice folds its wings as the trumpets sound.", "Heaven, earth and hell answer to the necromancer, though the Host still comes down."]  # TUNING (not in GDD) the words
## The whitening of Be Not Afraid (ParagonSky): s it takes to turn white (it
## then fades out over ParagonSky.FADE_OUT s). Visual only.
const WHITE_FADE: float = 0.12  # TUNING (not in GDD) visual only
## Strength (0..1) of the white at its peak. Visual only.
const WHITE_ALPHA: float = 0.42  # TUNING (not in GDD) visual only
## Px the autotest bot walks to within of it before it stops closing in (hint only).
const APPROACH: float = 140.0  # TUNING (not in GDD) autotest hint only

## The Voice's base max HP (x the boss HP multiplier and the stage's HP
## multiplier).
const MAX_HP: float = 9500.0  # TUNING (not in GDD) under Seraiel's 16,000: the Holy and the Last Word wear the ring down while it stands (first passes 15,000 and 11,000: army bot fights ran past 0:00)

## The Voice's design row.
const BOSS := {
	"display_name": "The Voice",
	"max_hp": MAX_HP,
	"move_speed": 0.0,  # Owner-approved proposal: "the Voice never moves"
	"damage": 0.0,  # It never strikes in melee: the Holy, Be Not Afraid and the Judges are its blows.
	"attack_interval": 2.0,  # TUNING (not in GDD) s (unused: no melee)
	"attack_range": 0.0,  # No melee.
	"radius": 34.0,  # TUNING (not in GDD) px (the sprite 104 px tall)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 1000.0,  # TUNING (not in GDD) it never moves: nothing shoves it
	"faction": HostEnemyData.FACTION,
	"group": "guardians",  # The Voice leads the guardians (the reports).
	"reward_xp": 700,  # TUNING (not in GDD) the act's finale (Seraiel 600)
	"reward_crystals": 30,  # TUNING (not in GDD)
	"slow_resist": 1.0,  # It never moves.
	"arrive_distance": 260.0,  # TUNING (not in GDD) px from the nearest necromancer it comes down (in sight)
	"phase1_banner": "THE HOLY: the light is at its strongest! Find shade!",  # TUNING (not in GDD)
	"unveil_banner": "BE NOT AFRAID: the Voice lowers the wings from its face! Hide your dead in shade or behind a barrier!",  # TUNING (not in GDD)
	"last_word_banner": "THE LAST WORD: the scales read your sins back!",  # TUNING (not in GDD)
	# The Holy.
	"holy_live": 1,  # TUNING (not in GDD) shafts at once added to the Light's max_live while it stands
	"holy_first": 4.0,  # TUNING (not in GDD) s after it arrives
	"holy_every": 10.0,  # TUNING (not in GDD) s between two Holy casts
	"holy_every_p2": 8.0,  # TUNING (not in GDD) s below last_word_hp
	"holy_shafts": 2,  # TUNING (not in GDD) shafts a cast
	"holy_width": 60.0,  # TUNING (not in GDD) px (the Light's own 52: "the light at its strongest")
	# Be Not Afraid.
	"unveil_first": 12.0,  # TUNING (not in GDD) s after it arrives
	"unveil_every": 20.0,  # TUNING (not in GDD) s between two unveilings
	"unveil_windup": 2.2,  # TUNING (not in GDD) s the wings lower before the light
	"unveil_stun": 2.0,  # Owner-approved proposal: "every summon in the open stops for 2 s"
	# The Last Word.
	"last_word_hp": 0.5,  # TUNING (not in GDD) share of its HP below which the Last Word begins
	"judges_per_sin": 1.0,  # Owner-approved proposal: "every raise of the run returns as a Judge" (the summons replaced too: the scales' sins)
	"last_word_min": 3,  # TUNING (not in GDD) Judges at least (a run with almost no sins)
	"last_word_cap": 12,  # TUNING (not in GDD) Judges at most per necromancer (the brief: "cap the waves")
	"wave_size": 3,  # TUNING (not in GDD) Judges a wave per necromancer
	"wave_every": 8.0,  # TUNING (not in GDD) s between two waves
}
