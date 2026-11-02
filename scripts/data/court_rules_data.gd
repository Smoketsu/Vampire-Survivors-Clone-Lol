## CourtRulesData — the numbers of the Sanguine Court's three shared rules (Act
## VII; GDD §15.0 "Act VII foundation (phase 1)", "Bloodfeast", "Night Wings"
## and "The Blood Moon"), each with ONE code path, inert on Acts I to VI
## (Game.court stays null there):
##   BLOODFEAST — Bloodfeast: a Court enemy's melee hit (row "feeds" > 0) heals
##       it for feeds x the damage it dealt to a summon or the necromancer,
##       called once from CombatResolver.damage_unit() and once from
##       damage_player(); healing past full banks as a blood shield; Rot and
##       Wither halve it; a red thread from the victim to the feeder.
##   NIGHT_WINGS — NightWings (the row flag "flies", Enemy.flies): fliers pass
##       over the Bone Ring (Enemy.resolve_blocking() skips them), hunt the
##       necromancer and the priests inside, land in a swoop to bite, and in
##       flight take only airborne, ranged and spell hits (CourtKit.taken_mult()).
##   BLOOD_MOON — BloodMoon: every few minutes the moon turns red for a while
##       (warned on the HUD): werebeasts transform, every Court enemy feeds
##       twice as hard, phase 2's witch covens can cast. A stage's STAGE "moon"
##       dictionary overrides any key ({} = these defaults).
##   ENDLESS_FEAST — the shared Act VII Reckoning hook (a stage's RECKONING
##       "endless_feast" dictionary overrides these keys; absent = off): the
##       Blood Moon rises at 0:00 and never sets, feeding grows each minute and
##       coffins open and release nobles.
##   SOUNDS — event -> sound id map (one place to switch the Court pack in).
## Counter-passive hooks (NOT built in phase 1; AbilityManager.passive_value()
## returns 0 while no PassiveData row exists, so each hook is exactly 1):
##   EMBALMED — enemies heal less from hitting summons
##       (Bloodfeast.embalmed_mult(), the one read).
##   SILVER_BONES — summon hits on werebeast / noble kinds deal more
##       (CourtRules.silver_bones_mult(), read by CourtKit.taken_mult()), and
##       mist form lasts less (CourtRules.silver_mist_mult(), read by
##       VampireNobleKit).
## Data only (CLAUDE.md rule 2). Every number is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name CourtRulesData
extends RefCounted

# --- Bloodfeast (Bloodfeast) --------------------------------------------------------------

## Bloodfeast.
##   shield_cap      — most blood shield (share 0..1 of the feeder's max HP)
##                     healing past full can bank (owner-approved proposal: "up
##                     to 25% of max HP").
##   rot_wither_mult — x the feeding of an enemy under Rot or inside the Wither
##                     aura (owner-approved: "Rot and Wither halve it").
##   thread_life     — s a red thread from victim to feeder shows (drawn only).
##   thread_cap      — most threads drawn at once (the oldest is replaced).
##   thread_width    — px of a thread's width (drawn only).
##   bite_sound_gap  — least s between two bite_feed sounds.
##   shield_sound_gap — least s between two blood_shield sounds.
const BLOODFEAST := {
	"shield_cap": 0.25,  # Owner-approved proposal
	"rot_wither_mult": 0.5,  # Owner-approved (Oct 31, 2026): "Rot and Wither halve it"
	"thread_life": 0.4,  # TUNING (not in GDD) s
	"thread_cap": 48,  # TUNING (not in GDD)
	"thread_width": 3.0,  # TUNING (not in GDD) px
	"bite_sound_gap": 0.3,  # TUNING (not in GDD) s
	"shield_sound_gap": 0.8,  # TUNING (not in GDD) s
}

## The future Act VII counter-passive Embalmed (owner-approved proposal:
## "enemies heal half as much from hitting summons"; NOT built in phase 1):
## PassiveData row EMBALMED's level value EMBALMED_KEY is the share of a feed
## on a summon withheld (Bloodfeast.embalmed_mult(): 1 - value; exactly 1 while
## no such passive exists).
const EMBALMED: String = "embalmed"
## Level-row key of Embalmed's feeding cut on summons (fraction 0..1).
const EMBALMED_KEY: String = "feed_reduction"

## The future Act VII counter-passive Silver Bones (owner-approved proposal:
## "summon hits on werewolves and vampire nobles deal more, and mist form lasts
## half as long"; NOT built in phase 1): PassiveData row SILVER_BONES's level
## value SILVER_DAMAGE_KEY is the extra share a summon's hit deals to a
## werebeast / noble kind (CourtRules.silver_bones_mult(): 1 + value) and
## SILVER_MIST_KEY the share of mist form cut (CourtRules.silver_mist_mult():
## 1 - value); both exactly 1 while no such passive exists.
const SILVER_BONES: String = "silver_bones"
## Level-row key of Silver Bones' extra summon damage on werebeasts and nobles (fraction).
const SILVER_DAMAGE_KEY: String = "silver_damage"
## Level-row key of Silver Bones' mist form cut (fraction 0..1).
const SILVER_MIST_KEY: String = "mist_reduction"

# --- Night Wings (NightWings; the row flag "flies") ---------------------------------------

## Night Wings.
##   flight_melee_taken — share (0..1) of a GROUNDED MELEE summon's blow a flier
##                     takes in flight (FallenAngelKit.grounded_melee(), the
##                     shared test: every melee class but the gargoyle's swoop;
##                     owner-approved: "in flight only airborne summons, ranged
##                     attacks and spells can hit them").
##   prey_classes    — summon classes a flier may keep as its target (the
##                     priests inside the ring); any other summon it targets is
##                     dropped for the necromancer ("they reach the necromancer
##                     and the priests inside").
##   shadow_lift     — px below a flier its ground shadow lies in flight (drawn only).
##   shadow_alpha_air / shadow_alpha_land — the shadow's alpha in flight /
##                     landed (drawn only).
const NIGHT_WINGS := {
	"flight_melee_taken": 0.0,  # Owner-approved proposal (no grounded melee blow lands in flight)
	"prey_classes": ["mender", "warder", "bishop"],  # Owner-approved proposal: "the priests inside"
	"shadow_lift": 14.0,  # TUNING (not in GDD) px
	"shadow_alpha_air": 0.22,  # TUNING (not in GDD)
	"shadow_alpha_land": 0.5,  # TUNING (not in GDD)
}

# --- The Blood Moon (BloodMoon) --------------------------------------------------------------

## The Blood Moon's defaults (a stage's STAGE "moon" overrides any key).
##   first       — game time (s) of the first Blood Moon (owner-approved
##                 proposal: "every 4:00").
##   every       — s between two Blood Moons' rises.
##   duration    — s the moon stays red (owner-approved proposal: "for 45 s").
##   warn        — s ahead the HUD shows it coming (owner-approved proposal:
##                 "shown 10 s ahead on the HUD").
##   feed_mult   — x every Court enemy's feeding under it (owner-approved
##                 proposal: "every Court enemy feeds twice as hard").
##   tint        — colour the world is multiplied by at the moon's height
##                 (a blend-mode rect; drawn only).
##   fade        — s the tint takes to come and go (drawn only).
##   warn_banner / rise_banner / set_banner — the banners.
const BLOOD_MOON := {
	"first": 240.0,  # Owner-approved proposal: "every 4:00"
	"every": 240.0,  # Owner-approved proposal
	"duration": 45.0,  # Owner-approved proposal
	"warn": 10.0,  # Owner-approved proposal
	"feed_mult": 2.0,  # Owner-approved proposal
	"tint": Color(1.0, 0.62, 0.64),  # TUNING (not in GDD) a red wash (multiplied)
	"fade": 2.0,  # TUNING (not in GDD) s
	"warn_banner": "The moon reddens... the Blood Moon rises in 10 seconds!",  # TUNING (not in GDD)
	"rise_banner": "THE BLOOD MOON RISES: the Court feeds!",  # TUNING (not in GDD)
	"set_banner": "The Blood Moon sets.",  # TUNING (not in GDD)
}
## Colour of the HUD's moon line (Palette.COURT_BLOOD_LIGHT: crimson = danger).
const MOON_HUD_COLOR := Color(0.878, 0.220, 0.306)  # Palette.COURT_BLOOD_LIGHT
## Layer of the moon's HUD line (CanvasLayer.layer; over the world, under the
## pause and level-up screens like the HUD).
const MOON_HUD_LAYER: int = 5  # TUNING (not in GDD)
## px below the HUD's top-centre block the moon line sits.
const MOON_HUD_GAP: float = 6.0  # TUNING (not in GDD)

# --- The Endless Feast (the shared Act VII Reckoning hook) ----------------------------------

## After 0:00, on a stage whose RECKONING has an "endless_feast" dictionary (its
## keys override these): the Blood Moon rises and never sets, feeding grows
## each minute, and coffins open and release nobles.
##   feed_growth   — x the feeding for every minute past 0:00 (compounding,
##                   on top of the moon's feed_mult; owner-approved proposal:
##                   "the Court feeds three times as hard each minute").
##   coffins       — coffins opened around each standing necromancer at 0:00.
##   coffin_dist   — px from the necromancer they open.
##   coffin_every  — s between two later coffins (one around a necromancer).
##   coffin_max    — most coffins standing at once.
const ENDLESS_FEAST := {
	"feed_growth": 3.0,  # Owner-approved proposal
	"coffins": 3,  # TUNING (not in GDD)
	"coffin_dist": 300.0,  # TUNING (not in GDD) px
	"coffin_every": 40.0,  # TUNING (not in GDD) s
	"coffin_max": 8,  # TUNING (not in GDD)
}

# --- Sounds ------------------------------------------------------------------------------------

## Court event -> sound id played for it (Sfx.play(); an id that is not
## rendered is a silent no-op). The ids are the Court pack's
## (SoundData.COURT_SOUNDS), loaded lazily with the "sanguine" music; wired by
## the lead at the foundation merge. An event with no pack sound would keep its
## stand-in (none at present: every event has its own id).
const SOUNDS := {
	"bite_feed": "bite_feed",  # A bite landing and feeding (Court pack).
	"blood_shield": "blood_shield",  # Overheal banking as a blood shield (Court pack).
	"bat_screech": "bat_screech",  # A Vampire Bat's screech (Court pack).
	"moon_rise": "moon_rise",  # The Blood Moon rising (Court pack).
	"moon_set": "moon_set",  # The Blood Moon setting (Court pack).
	"wolf_howl": "wolf_howl",  # A Werewolf's howl (Court pack).
	"coffin_creak": "coffin_creak",  # A Court coffin opening (Court pack).
	"mist_form": "mist_form",  # A Vampire Noble turning to mist (Court pack).
}
