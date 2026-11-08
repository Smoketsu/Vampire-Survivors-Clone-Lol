## OsirisData — immutable design data of OSIRIS, LORD OF THE DEAD, AND AMMIT THE
## DEVOURER, the boss of the Hall of Two Truths and the finale of the Necropolis
## Dynasty (temporary Act XII, final slot VII; GDD §15.0 "Osiris and Ammit (the
## Hall of Two Truths)"; owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md
## Part 3, "Stage C: The Hall of Two Truths": "The Judge: Osiris on the throne;
## Heka glyphs and Rebirth at speed; his court fills the hall. The Weighing: the
## necromancer's heart (a glowing orb) is placed on the scales for 60 s. If the
## Balance ends toward the Dynasty, Ammit eats 30% of the summons. If it ends
## toward the necromancer, Osiris's shield breaks by 25%. Every raise matters.
## The Devourer: Osiris gives the throne to Ammit. She eats every corpse on the
## map, charging in lanes, and leaves no Rebirth. Slay her and the throne is
## empty. When Osiris falls, no old master has a claim on the dead"). BossOsiris
## (scripts/enemies/dynasty/boss_osiris.gd, loaded by name for the boss id
## "osiris") reads BOSS; TwoTruthsStage.BOSS reads ARRIVAL. Osiris is MALE, a
## green-skinned god in linen with the crook and flail, seated on his throne
## (still art, no strip); Ammit is a MONSTER (crocodile jaws, lion front, hippo
## rump). ONE body and ONE health bar for the pair: the last share of it is
## Ammit's. Three phases:
##   THE JUDGE (100% -> weighing_hp): Osiris glides at the necromancer on his
##        throne. Every glyph_every s he writes glyph_count Heka glyphs at
##        once (Heka.write(), THE one call; the glyphs jump heka_jump_speed x
##        as fast while he judges); while he lives every cartouche runs
##        rebirth_bonus s shorter (Rebirth.set_duration_bonus(), the one
##        duration path: "Rebirth at speed"); every court_every s his COURT
##        comes (COURT, in turn, around him); every judgment_every s a
##        JUDGMENT circle (judgment_radius px) is telegraphed under the
##        necromancer for judgment_warn s, then strikes every summon in it
##        (judgment_summon_damage) and the necromancer (judgment_damage).
##   THE WEIGHING (at weighing_hp, weighing_time s): the necromancer's heart is
##        laid on the great Scales (TruthScales.begin_weighing(): the Scales
##        stop settling, so every raise and every Rebirth counts). Osiris sits
##        immune on his throne; his court, his glyphs and his Judgments go on.
##        When the time is up the Scales decide (TruthScales.end_weighing()):
##          toward the DYNASTY: AMMIT EATS devour_share of the summons (the
##          strongest first, each through HordeDirector.on_unit_died(u): a real
##          death, so each class queue replaces its own);
##          toward the NECROMANCER: OSIRIS'S SHIELD BREAKS: he loses
##          shield_break of his max HP at once (no lower than 1 HP); the
##          achievement A Light Heart (MetaData "a_light_heart");
##          dead level: nothing happens.
##   THE DEVOURER (after the Weighing, to the end): Osiris gives the throne to
##        Ammit (the body is drawn as her, ammit_* numbers); he watches from
##        the empty throne (TwoTruthsDirector draws him faded where he sat).
##        Every feast_every s she EATS EVERY CORPSE ON THE MAP (Rebirth.eat()
##        on every cartouche: "leaves no Rebirth"); every charge_every s she
##        CHARGES IN A LANE through the necromancer (the Devourer's lane look,
##        EffectManager.telegraph_line(), charge_warn s, then she runs
##        charge_length px at charge_speed px/s: every summon she passes takes
##        charge_summon_damage and the necromancer charge_damage once; every
##        cartouche she passes is eaten). Slay her and the throne is empty.
## Beaten: a short ending text only (ENDING_ANNOUNCE: no old master has a claim
## on the dead), no epilogue part and no closing card (docs/last_acts/PLAN.md).
## Damage keys are before the time scaling (and Enemy.hit_mult(): the Scales'
## favour). The GDD gives no numbers: everything is TUNING (not in GDD) unless
## marked as the owner-approved proposal. Tuned for the act's final slot VII
## (Amaterasu 14,000 x1.65, Hades 16,000 x1.5).
class_name OsirisData
extends RefCounted

## Its arrival (keys as GraveyardStage.BOSS; TwoTruthsStage.BOSS). Its script
## is found by the id (boss_osiris.gd).
const ARRIVAL := {
	"id": "osiris",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Osiris and Ammit the Devourer",  # Owner-approved proposal: "Osiris, Lord of the Dead, and Ammit the Devourer" (one bar for the pair)
	"short_name": "Osiris",
	"arrive_banner": "Osiris, Lord of the Dead, takes his throne to judge you!",  # TUNING (not in GDD)
	"defeat_banner": "The throne is empty: no old master has a claim on the dead!",  # Owner-approved proposal: "Slay her and the throne is empty ... no old master has a claim on the dead"
	"dead_objective": "The throne is empty. Survive the Devourer's Hour... you cannot.",  # TUNING (not in GDD)
}
## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["judge_glyphs", "judge_court", "judgment", "weighing", "ammit_feast", "ammit_charge"]
## Osiris's court, called in turn (owner-approved proposal: "his court fills
## the hall"): groups as GraveyardStage.EVENTS "groups".
const COURT := [
	[{"kind": "khopesh_guard", "count": 3, "elite": false}, {"kind": "mummy", "count": 6, "elite": false}],  # TUNING (not in GDD) the guard
	[{"kind": "heka_priest", "count": 1, "elite": false}, {"kind": "mummy_female", "count": 6, "elite": false}],  # TUNING (not in GDD) the priesthood
	[{"kind": "embalmer", "count": 1, "elite": false}, {"kind": "crocodile_warden", "count": 1, "elite": false}, {"kind": "mummy", "count": 4, "elite": false}],  # TUNING (not in GDD) the wardens
]
## Damage-source tag of the Judgment (stats, the death line).
const SRC_JUDGMENT: String = "osiris_judgment"
## Damage-source tag of Ammit's charge.
const SRC_CHARGE: String = "ammit_charge"
## Sprite key of Osiris on his throne (still art, no strip).
const SPRITE: String = "dynasty/osiris"
## Sprite key of Ammit (walk strip).
const AMMIT_SPRITE: String = "dynasty/ammit"
## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on its fall (title, line, description): the proposal's
## ending, kept short (no epilogue part: docs/last_acts/PLAN.md).
const ENDING_ANNOUNCE := ["THE THRONE IS EMPTY", "Ammit falls, and Osiris with her.", "No old master has a claim on the dead."]  # Owner-approved proposal ending (TUNING the words)
## Shorter announcement when it falls after 0:00 (the Devourer's Hour goes on).
const LATE_ANNOUNCE := ["THE THRONE IS EMPTY", "Ammit falls, and Osiris with her.", "Even as the sarcophagi open, the dead answer to no old master."]  # TUNING (not in GDD)
## Stat of its kill time (s from its arrival; the report).
const KILL_TIME_STAT: String = "osiris_kill_time"
## Stat counting Weighings won toward the necromancer (A Light Heart, MetaData).
const LIGHT_HEART_STAT: String = "light_heart_wins"
## Its design row.
const BOSS := {
	"display_name": "Osiris and Ammit the Devourer",
	"max_hp": 13000.0,  # TUNING (not in GDD) before the stage / co-op scaling; one pool for the pair (the Weighing holds him immune 60 s)
	"move_speed": 30.0,  # TUNING (not in GDD) px/s, his throne glides
	"damage": 10.0,  # TUNING (not in GDD) his flail in melee, before the time scaling
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 20.0,  # TUNING (not in GDD) px (the throne is drawn larger)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 1.0,
	"mass": 40.0,  # TUNING (not in GDD)
	"slow_resist": 0.7,  # TUNING (not in GDD) like every boss
	"reward_xp": 1000,  # TUNING (not in GDD) the act's finale (Paragon 1,000)
	"reward_crystals": 32,  # TUNING (not in GDD)
	"arrive_time": 2.0,  # TUNING (not in GDD) s he rises (invulnerable)
	"advance_range": 360.0,  # TUNING (not in GDD) px beyond which he glides faster
	"advance_speed_mult": 2.2,  # TUNING (not in GDD)
	# The Judge.
	"glyph_first": 3.0,  # TUNING (not in GDD) s before his first glyphs
	"glyph_every": 7.0,  # TUNING (not in GDD) s between two writings
	"glyph_count": 3,  # TUNING (not in GDD) glyphs a writing ("Heka glyphs at speed")
	"glyph_range": 280.0,  # TUNING (not in GDD) px from him a summon may take one
	"heka_jump_speed": 1.5,  # TUNING (not in GDD) x the glyphs' jump rate while he judges
	"rebirth_bonus": -1.5,  # TUNING (not in GDD) s added to every cartouche's time while he lives ("Rebirth at speed")
	"court_first": 6.0,  # TUNING (not in GDD) s before his first court
	"court_every": 15.0,  # TUNING (not in GDD) s between two courts
	"judgment_first": 5.0,  # TUNING (not in GDD) s before his first Judgment
	"judgment_every": 6.0,  # TUNING (not in GDD) s between two
	"judgment_radius": 60.0,  # TUNING (not in GDD) px
	"judgment_warn": 1.2,  # TUNING (not in GDD) s of telegraph
	"judgment_damage": 14.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"judgment_summon_damage": 12.0,  # TUNING (not in GDD) first pass 26 (seed 7: 81 summons lost in his first minute); to each summon, before the time scaling
	# The Weighing.
	"weighing_hp": 0.66,  # TUNING (not in GDD) share of the pool where the Weighing begins
	"weighing_time": 60.0,  # Owner-approved proposal: "placed on the scales for 60 s"
	"weighing_court_every": 12.0,  # TUNING (not in GDD) s between two courts while the heart is weighed
	"devour_share": 0.3,  # Owner-approved proposal: "Ammit eats 30% of the summons"
	"shield_break": 0.25,  # Owner-approved proposal: "Osiris's shield breaks by 25%" (of his max HP)
	# The Devourer (Ammit).
	"ammit_speed": 64.0,  # TUNING (not in GDD) px/s between charges
	"ammit_radius": 20.0,  # TUNING (not in GDD) px (~76 x 44 sprite)
	"ammit_damage": 14.0,  # TUNING (not in GDD) her bite in melee, before the time scaling
	"feast_every": 3.0,  # TUNING (not in GDD) s between two feasts (every cartouche on the map eaten)
	"charge_first": 2.5,  # TUNING (not in GDD) s after she takes the throne
	"charge_every": 5.5,  # TUNING (not in GDD) s between two charges (from the end of the last)
	"charge_warn": 1.1,  # TUNING (not in GDD) s of the lane's telegraph
	"charge_speed": 560.0,  # TUNING (not in GDD) px/s
	"charge_length": 640.0,  # TUNING (not in GDD) px she runs
	"charge_width": 64.0,  # TUNING (not in GDD) px, the lane
	"charge_damage": 22.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"charge_summon_damage": 40.0,  # TUNING (not in GDD) to each summon, before the time scaling
}
