## CityRulesData — the numbers of the Last Line's shared rules (Act VIII; GDD
## §15.0 "Act VIII foundation (phase 1)", "Armour", "Supers", "Civilians" and
## "The escalation"), each with ONE code path, inert on Acts I to VII
## (Game.city stays null there):
##   ESCALATION — Escalation: the plain clock that climbs from the gangs to the
##       police, SWAT and the Guard, the army and the heroes (owner: "the
##       escalation is a plain clock, not the Wanted Level"); the tier badge on
##       the HUD, the banner ahead of each tier, a Super every 90 s from the
##       heroes. A stage's STAGE "escalation" dictionary overrides any key.
##   ARMOUR — Armour: the front of a row with "armour_front" (a hit inside the
##       front arc is cut), called once from CombatResolver.damage_enemy();
##       the Kevlar Bones hook.
##   CONVOY — Convoy: the vehicles (row "vehicle"): they drive the street lanes
##       with headlights 1 s ahead, run over summons and the necromancer, turn
##       at the lane's end, ram wrecks; a dead vehicle leaves a burning wreck
##       that explodes.
##   SUPERS — SuperKit / SuperRoster: guarded until the weakness is read, then
##       exposed; the plate; the met list.
##   CIVILIANS — Civilians: the crowd that flees through the streets from 0:00,
##       the trickle until the army comes, their own alive cap.
##   SHELLS — CityShells: telegraphed landing circles (the tank's cannon, the
##       breacher's flashbang, Martial Law's artillery).
##   MARTIAL_LAW — the shared Act VIII Reckoning hook (a stage's RECKONING
##       "martial_law" dictionary overrides these keys; absent = off).
##   SOUNDS — event -> sound id map (one place to switch the City pack in).
## Counter-passive hook (NOT built in phase 1; AbilityManager.passive_value()
## returns 0 while no PassiveData row exists, so the hook is exactly 1):
##   KEVLAR_BONES — summons take less RANGED damage from City kinds
##       (Armour.kevlar_mult(), read once by CombatResolver.damage_unit()).
## Data only (CLAUDE.md rule 2). Every number is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name CityRulesData
extends RefCounted

# --- The escalation (Escalation) ---------------------------------------------------------

## Tier ids in order (the Fixed names). Each kind's row names its "tier".
const TIERS: Array[String] = ["gangs", "police", "swat", "army", "heroes"]
## The escalation.
##   times        — tier id -> elapsed game seconds it begins (owner: a plain
##                  clock: gangs, police, SWAT and the Guard, army, heroes).
##   last         — the last tier the stage climbs to (phase 2: Skid Row
##                  "swat", Fort Kessler "army", Liberty Heights "heroes").
##   warn         — s before a tier that the banner and tier_alarm warn.
##   super_every  — s between two Supers from the heroes tier on.
##   super_max    — most Supers alive at once from the escalation.
##   warn_banners — tier id -> the banner shown `warn` s ahead.
##   names        — tier id -> the HUD badge text.
##   colors       — tier id -> the HUD badge colour.
const ESCALATION := {
	"times": {"gangs": 0.0, "police": 240.0, "swat": 480.0, "army": 720.0, "heroes": 900.0},  # TUNING (not in GDD) brief: 0:00, 4:00, 8:00, 12:00, 15:00
	"last": "heroes",  # TUNING (not in GDD) the stubs climb the full ladder so every rule shows
	"warn": 10.0,  # TUNING (not in GDD) brief: a banner 10 s ahead
	"super_every": 90.0,  # Owner-approved proposal: "a Super joins the fight every 90 s"
	"super_max": 1,  # TUNING (not in GDD) brief: at most one alive
	"warn_banners": {
		"police": "Sirens in the distance: the police are coming!",  # TUNING (not in GDD)
		"swat": "Armoured trucks: SWAT and the Guard are coming!",  # TUNING (not in GDD)
		"army": "The city calls in the army! Get the civilians out!",  # TUNING (not in GDD)
		"heroes": "The skyline lights up: the heroes are coming!",  # TUNING (not in GDD)
	},
	"names": {"gangs": "Gangs", "police": "Police", "swat": "SWAT", "army": "Army", "heroes": "Heroes"},  # TUNING (not in GDD)
	"colors": {
		"gangs": Palette.CITY_NEON_PINK,  # TUNING (not in GDD)
		"police": Palette.CITY_POLICE_BLUE,  # TUNING (not in GDD)
		"swat": Palette.CITY_CONCRETE_LIGHT,  # TUNING (not in GDD)
		"army": Palette.CITY_OLIVE,  # TUNING (not in GDD)
		"heroes": Palette.CITY_HERO_ORANGE,  # TUNING (not in GDD)
	},
}
## px below the HUD's top-centre block of the escalation badge (under the
## other act lines' slot).
const BADGE_HUD_GAP: float = 4.0  # TUNING (not in GDD)

# --- Armour (Armour, Convoy) ----------------------------------------------------------------

## Armour.
##   front_half_angle — rad each side of the facing that counts as the front
##                      (brief: +-60 degrees).
const ARMOUR := {
	"front_half_angle": 1.0471976,  # TUNING (not in GDD) brief: +-60 degrees (PI / 3 rad)
}

## Kevlar Bones (counter-passive hook, NOT built): its PassiveData id ...
const KEVLAR_BONES: String = "kevlar_bones"
## ... and the passive_value() key of its ranged-damage cut (0..1).
const KEVLAR_KEY: String = "ranged_reduction"

## The vehicles (Convoy; every number a vehicle row does not set itself).
##   headlight_time — s of road ahead the headlights show (owner-approved
##                    proposal: "headlights show the lane 1 s ahead").
##   overrun        — px a vehicle drives past the necromancer's projection on
##                    its lane before it turns.
##   turn_time      — s it stands to turn at the lane's end (or at a crossing).
##   hit_every      — s before the same body can be run over again.
##   shove          — px a summon it runs over is shoved sideways out of the
##                    lane (to a free point).
##   ram_stop       — s a vehicle that rammed a wreck stands before it turns.
##   ram_damage     — share (0..1) of its max HP a vehicle loses ramming a wreck.
##   lane_jitter    — px a vehicle keeps off the lane's exact centre (by think
##                    slot, so two cars in one street do not stack).
const CONVOY := {
	"headlight_time": 1.0,  # Owner-approved proposal: 1 s ahead
	"overrun": 520.0,  # TUNING (not in GDD) px
	"turn_time": 0.7,  # TUNING (not in GDD) s
	"hit_every": 1.2,  # TUNING (not in GDD) s (first pass 0.8)
	"shove": 30.0,  # TUNING (not in GDD) px
	"ram_stop": 1.2,  # TUNING (not in GDD) s
	"ram_damage": 0.15,  # TUNING (not in GDD) share of max HP
	"lane_jitter": 26.0,  # TUNING (not in GDD) px
}

## The burning wreck a dead vehicle leaves (Convoy; owner-approved proposal: "a
## destroyed vehicle becomes a burning wreck, a new obstacle for the rest of the
## run (and it explodes a few seconds later, hurting both sides)").
##   explode_after — s from the death to the explosion (brief: 3 s).
##   radius        — px of the explosion (brief: 64 px).
##   damage        — explosion damage before the time scaling, to summons,
##                   the necromancer and enemies (never civilians).
##   burn_time     — s the wreck shows burning (then the _burnt look).
##   half_along    — px the wreck's half length along its street when the
##                   vehicle row sets none (clamped to WRECK_HALF_MAX).
const WRECK := {
	"explode_after": 3.0,  # TUNING (not in GDD) brief: 3 s later
	"radius": 64.0,  # TUNING (not in GDD) brief: within 64 px
	"damage": 10.0,  # TUNING (not in GDD) before the time scaling (first pass 14)
	"burn_time": 20.0,  # TUNING (not in GDD) s
	"half_along": 26.0,  # TUNING (not in GDD) px
}

## Police lights: the light bar's pulse (Hz). Owner rule (photosensitivity):
## at most 1 Hz, a soft fade, never a full-screen flash.
const SIREN_PULSE_HZ: float = 0.8  # TUNING (not in GDD) owner rule: at most 1.0

## Rooftop antenna lamps (CityLamps; the art pass draws them unlit): the slow
## red pulse rate (Hz; same owner rule as the police lights: at most 1 Hz, a
## soft fade, never a flash), the soft glow's radius (px) and its peak alpha (0..1).
const ANTENNA_PULSE_HZ: float = 0.35  # TUNING (not in GDD) a slow aircraft-warning blink
const ANTENNA_GLOW_RADIUS: float = 6.0  # TUNING (not in GDD) px
const ANTENNA_GLOW_ALPHA: float = 0.55  # TUNING (not in GDD) 0..1

# --- Supers (SuperKit, SuperRoster) ---------------------------------------------------------

## The Supers.
##   guarded_mult — x damage taken until the weakness is triggered (brief: 0.6).
##   exposed_mult — x damage taken while exposed (brief: 1.5).
##   stun         — s a Super is stunned when exposed (brief: 1 s).
##   exposed_time — s the exposed window lasts after the stun (brief: 4 s).
##   roster       — the Super ids the escalation sends in turn (a stage's
##                  STAGE "supers" list overrides it; phase 2 adds Atlas,
##                  Aurora and Nightjar).
const SUPERS := {
	"guarded_mult": 0.6,  # TUNING (not in GDD) brief
	"exposed_mult": 1.5,  # TUNING (not in GDD) brief
	"stun": 1.0,  # TUNING (not in GDD) brief
	"exposed_time": 4.0,  # TUNING (not in GDD) brief
	"roster": ["blitz"],  # TUNING (not in GDD) the reference Super
}
## px above a Super's head of its plate's baseline.
const PLATE_LIFT: float = 14.0  # TUNING (not in GDD)
## Colour of a guarded Super's plate edge.
const PLATE_GUARDED := Palette.CITY_NEON_CYAN  # TUNING (not in GDD)
## Colour of an exposed Super's plate edge and crack mark.
const PLATE_EXPOSED := Palette.CITY_HAZARD  # TUNING (not in GDD)

# --- Civilians (Civilians) ---------------------------------------------------------------

## The civilians (owner: "Civilians appearing at the beginning is awesome, but
## we're not sparing them. Let them drop XP to reward killing them").
##   crowd        — civilians in the streets at 0:00 (brief: 36).
##   crowd_min / crowd_max — px from the necromancer the crowd stands.
##   trickle_min / trickle_max — px from a necromancer a later civilian
##                  comes out (on screen or just off it: a doorway, a corner).
##   trickle_every — s between two later civilians (brief: one every 2 s).
##   max_alive    — their own alive cap (brief: 24; never the enemy cap).
##   evacuate     — the tier at which the city is evacuated (no more come).
##   recycle      — px from every necromancer past which a civilian has fled
##                  (taken off the field with no XP).
##   summon_fear  — px within which a summon frightens a civilian too.
##   panic        — px from the nearest necromancer within which a civilian
##                  runs flat out; farther off it only walks away (stroll x
##                  its speed), so the army can catch the crowd.
##   stroll       — share (0..1) of its speed a civilian walks at outside the
##                  panic radius (no summon near).
##   female_every — every n-th civilian has the woman's look (by its slot).
const CIVILIANS := {
	"crowd": 36,  # TUNING (not in GDD) brief: 36
	"crowd_min": 180.0,  # TUNING (not in GDD) px, beyond the clear radius
	"crowd_max": 560.0,  # TUNING (not in GDD) px
	"trickle_min": 300.0,  # TUNING (not in GDD) px
	"trickle_max": 620.0,  # TUNING (not in GDD) px
	"trickle_every": 2.0,  # TUNING (not in GDD) brief: one every 2 s
	"max_alive": 24,  # TUNING (not in GDD) brief: at most 24 alive
	"evacuate": "army",  # TUNING (not in GDD) brief: until the army tier
	"recycle": 900.0,  # TUNING (not in GDD) brief: 900 px
	"summon_fear": 140.0,  # TUNING (not in GDD) px
	"panic": 340.0,  # TUNING (not in GDD) px
	"stroll": 0.35,  # TUNING (not in GDD)
	"female_every": 2,  # TUNING (not in GDD) every second civilian a woman
}

# --- Shells (CityShells) ----------------------------------------------------------------------

## Most shells pending at once (the oldest lands early when full; drawing cap).
const SHELL_CAP: int = 64  # TUNING (not in GDD)

# --- Martial Law (the Reckoning, MartialLaw) ---------------------------------------------------

## Martial Law (the shared Act VIII Reckoning; brief: "every tier's kinds spawn
## at once; artillery walks across the arena in telegraphed lines of shell
## circles along the streets, hurting both sides; every Super in the met list
## returns, one every 20 s"). The tier kinds come as the RECKONING's "kind"
## (the tank) and "companions"; this is the rest.
##   artillery_first — s after 0:00 of the first artillery line.
##   artillery_every — s between two lines.
##   shells          — shell circles in one line.
##   spacing         — px between two circles along the street lane.
##   walk            — s between two circles landing (the line walks).
##   warn            — s each circle shows before it lands.
##   radius          — px of a circle.
##   damage          — damage before the Reckoning scaling (both sides; never
##                     civilians).
##   offset          — px from the necromancer the line starts (it walks
##                     through his street).
##   super_every     — s between two returning Supers.
const MARTIAL_LAW := {
	"artillery_first": 4.0,  # TUNING (not in GDD)
	"artillery_every": 8.0,  # TUNING (not in GDD)
	"shells": 8,  # TUNING (not in GDD)
	"spacing": 70.0,  # TUNING (not in GDD) px
	"walk": 0.22,  # TUNING (not in GDD) s
	"warn": 1.2,  # TUNING (not in GDD) s
	"radius": 46.0,  # TUNING (not in GDD) px
	"damage": 22.0,  # TUNING (not in GDD)
	"offset": 300.0,  # TUNING (not in GDD) px
	"super_every": 20.0,  # TUNING (not in GDD) brief: one every 20 s
}

# --- Sounds -----------------------------------------------------------------------------

## City event -> sound id: the City pack (SoundData.CITY_SOUNDS), rendered lazily
## with the "siren" music the first time an Act VIII run asks for it. Kept as a
## map (not hard-coded ids) so one place can repoint an event.
const SOUNDS := {
	"siren_wail": "siren_wail",  # A slow, distant siren rise and fall (police cars).
	"gun_burst": "gun_burst",  # A short dry burst of shots (gunners, riflemen).
	"engine_rev": "engine_rev",  # An engine revving up (vehicles).
	"vehicle_wreck": "vehicle_wreck",  # A crunch of metal and a fire whoomp (wrecks).
	"crowd_panic": "crowd_panic",  # A short alarmed crowd shout (civilians).
	"super_arrive": "super_arrive",  # A rising whoosh and a bright chord (Supers).
	"weakness_crack": "weakness_crack",  # A glassy crack (a Super exposed).
	"tier_alarm": "tier_alarm",  # A radio squelch and a low klaxon (the escalation).
	# --- Act VIII: Fort Kessler --- (the City pack's own sounds, no new synthesis)
	"mine_blast": "vehicle_wreck",  # A minefield mine going off (Minefields).
	"mg_sweep": "gun_burst",  # A machine gunner's lane opening up (MachineGunnerKit).
	"rotor_pass": "engine_rev",  # An attack helicopter starting a strafing run (AttackHelicopterKit).
	"carpet_call": "siren_wail",  # General Harrow calling a carpet-bombing line (BossHarrow).
	"broken_arrow": "tier_alarm",  # Broken Arrow ordered, and each 10 s of its countdown (BossHarrow).
}

# --- Act VIII: Fort Kessler ---
## Armour-Piercing Bones (Act VIII's counter-passive, earned by the Fort Kessler
## achievement Broken Arrow; owner answer of Nov 2, 2026: "summon hits ignore
## part of the Armour rule's shield-front reduction"): its PassiveData id ...
const ARMOUR_PIERCING: String = "armour_piercing_bones"
## ... and the passive_value() key of the share (0..1) of a front's cut a
## summon-class hit ignores (Armour.front_mult(): front x (1 - v)).
const PIERCE_KEY: String = "front_pierce"
