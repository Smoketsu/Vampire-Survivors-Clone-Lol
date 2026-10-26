## PassiveData — immutable design data for the global horde passives listed in
## GDD §34 ("Global passives"). The prototype implements the first four:
##   Grave Dominion  — Capacity.
##   Necrotic Vigor  — Max minion health.
##   Dark Command    — Minion attack damage/speed (at Lv 5 it also evolves
##                     Lv 5 Skeleton Warriors into Death Knights, user rule).
##   Soul Recycling  — Faster replacement.
## plus the three spell-evolution passives of GDD §6.1 (their standalone
## effects are not defined by the GDD, open question 28; these are the
## prototype's choice):
##   Soul Conduit    — +% damage of every shadow spell (evolves Shadow Bolt).
##   Warding Ritual  — -% damage taken by the necromancer (evolves Orb Shield).
##   Abyssal Focus   — -% spell cooldowns / orb recharge (evolves Shadow Blast).
## plus two summon-evolution passives of GDD §6.1 (user request; standalone
## effects are the prototype's choice, open question 28):
##   Forbidden Knowledge — +% Undead Mage damage and splash radius (at Lv 5
##                         it evolves Lv 5 Mages into Liches).
##   Dark Benediction    — +% heals, wards and barriers of the priest orders
##                         (at Lv 5 it merges Lv 5 Menders + Warders into
##                         Profane Bishops). Recipes: SummonEvolutionData.
## Every evolution needs its paired passive at Lv 5 (owner rule, GDD §15.0).
## plus the four evolution passives of the newer spells (user request "more
## weapons"; prototype's choice, recorded in GDD §15.0):
##   Shade Stride          — +% necromancer move speed (evolves Bone Spear).
##   Vampiric Rite         — +HP/s regeneration (evolves Soul Siphon).
##   Necrotic Expanse      — +% spell area (evolves Corpse Explosion).
##   Lingering Malediction — +% spell durations (evolves Plague Cloud).
## plus the four later horde passives (GDD §34 names them; the effects are
## the prototype's choice, recorded in GDD §15.0, open question 28). Each
## pairs with a later summon evolution (recipes in SummonEvolutionData; card
## descriptions never spell a recipe out, owner rule "Card text: one
## sentence"):
##   Bone Plating       — minions ignore a flat amount of every hit
##                        (Abominations -> Bone Colossi).
##   Unholy Precision   — minion critical hits (Archers -> Gravebows).
##   Unholy Resilience  — minions take less area and holy damage
##                        (Gargoyles -> Cathedral Horrors).
##   Bound Souls        — minion move speed, leash range and faster returns
##                        (Rogues -> Shadow Reapers).
## Their combat hooks live in CombatResolver (damage) and
## HordeDirector.compute_stats() (move speed, leash, return speed).
## plus the evolution passives of the five later spells (owner-approved, GDD
## §15.0 "Five more spells"; Grave Dominion and Necrotic Vigor above pair
## with Bone Wall and Wither, so no passive pairs with two evolutions):
##   Grim Ledger     — +% damage to elites, minibosses and bosses from every
##                     source (CombatResolver.damage_enemy(); evolves Death
##                     Mark into Doom Brand).
##   Spirit Binding  — every slow, chill, Deep Freeze and stun on enemies
##                     lasts longer (CombatResolver's status calls; evolves
##                     Soul Chains into Chains of the Damned).
##   Restless Dead   — temporary summons (Death Mark Risen, Raise Dead
##                     skeletons, Lich raises, stage reinforcements) last
##                     longer and hit harder (HordeDirector.spawn_temporary();
##                     evolves Raise Dead into Legion of Bones).
## plus the three passives paired with the newest summon classes
## (owner-approved, recorded in GDD §15.0; card lines and the autotest line
## in ClassPassives):
##   Blood Scent  — fast summons (base move speed >= FAST_SUMMON_SPEED) move
##                  and attack faster (HordeDirector.compute_stats(); Bone
##                  Hounds -> Hellhounds).
##   Mournsong    — every weakening effect on enemies lasts longer: slows,
##                  chills, the Dirge's damage cut, curses and Rot
##                  (CombatResolver.debuff_time(); Banshees -> Keening Ladies).
##   Siegecraft   — summons deal more damage to structures, elites and
##                  minibosses (CombatResolver.damage_enemy(); Corpse
##                  Catapults -> Ossuary Engines).
## plus the passive paired with the Fallen Seraph (Act II, GDD §15.0
## "Fallen Seraph"; unlocked with her by slaying Seraphine, UnlockData):
##   Fallen Grace — every summon special (stomp, dash, swoop, Deep Freeze,
##                  Dirge, dive) recharges faster: every special *_cooldown is
##                  divided by (1 + special_haste) in HordeDirector.
##                  _special_stats() (Fallen Seraphs -> Seraphs of Ruin).
## plus Act II's passives (owner-approved "Unlockable spells and passives",
## GDD §15.0; both are unlockable items, UnlockData):
##   Salt of the Deep — more damage to slowed, chilled or frozen enemies
##                      (CombatResolver.damage_enemy(); evolves Undertow into
##                      Maelstrom; unlocked with Undertow by slaying Merrow).
##   Brinewalker      — a counter-passive, offered only on Act II stages
##                      ("act": 2): water and ink slow the necromancer less,
##                      and summons from BRINEWALKER_SUMMON_LEVEL (TerrainSlow,
##                      the one ground-slow path; unlocked by the Low Tide
##                      achievement).
## plus the Hollow Archive's two (Act II, GDD §15.0 "Act II: the Hollow
## Archive"; both locked until earned, UnlockData):
##   Marginalia — every on-death effect hits harder (ink bursts, corpse
##                bursts, the frozen shatter, bone shrapnel...;
##                CombatResolver.damage_enemy(), VerseData.MARGINALIA_SOURCES;
##                evolves Forbidden Verse into The Unwritten Word). Unlocked
##                with the spell by slaying the Archivist.
##   Iron Mind  — an Act II counter-passive ("act": 2, offered only on Act II
##                stages; unlocked by the achievement Nothing Unwritten): Dread
##                rises slower and, at Lv 5, kills calm it twice as fast
##                (DreadMeter reads its two level keys). Evolves nothing.
## plus content wave 2's passive (owner-approved proposal 5, GDD §15.0 "Bone
## Golem (content wave 2)"; locked until Bone Legion, UnlockData):
##   Grave Masonry — the blockers (MASONRY_CLASSES: Warriors, Abominations,
##                   Bone Golems and their evolutions) take less damage
##                   (CombatResolver.damage_unit()) and hold their ground
##                   longer: more block mass and a longer Bulwark
##                   (HordeDirector.compute_stats(); Golems -> Ossuary Titans).
## plus the Scrap Wastes' two (Act III, GDD §15.0 "The Scrap Wastes (Act III
## phase 2)"; both locked until earned, UnlockData):
##   Conductive Marrow — a longer, wider Death Ray beam (beam_length and
##                       beam_width in AbilityManager.apply_spell_mods(), the one
##                       spell modifier path; evolves Death Ray into Event
##                       Horizon). Unlocked with the spell by slaying Kestrel.
##   Lead-Lined Bones  — an Act III counter-passive ("act": 3, offered only on
##                       Act III stages; unlocked by the achievement Static in the
##                       Wastes): RANGED hits on your summons deal less (one
##                       multiplier in CombatResolver.damage_unit() for ranged
##                       sources, CombatResolver.is_ranged_source()). Evolves
##                       nothing.
## plus Mount Olympus's two (Act IV, GDD §15.0 "Stolen Thunder, Titan's Blood and
## the Oathbreaker" and "Twilight of the Gods and Grounded Bones"; both locked
## until earned, UnlockData):
##   Titan's Blood     — Stolen Thunder chains more hops and charges faster
##                       (thunder_chains / thunder_charge in
##                       AbilityManager.apply_spell_mods(); evolves Stolen
##                       Thunder into Gigantomachy). Unlocked with the spell by
##                       slaying Zeus.
##   Grounded Bones    — an Act IV counter-passive ("act": 4, offered only on
##                       Act IV stages; unlocked by the achievement Twilight of
##                       the Gods): less lightning and wave damage (the Wrath of
##                       the Gods) to the army and the necromancer
##                       (DivineWrath.grounded_mult(), the one read, per target
##                       slot). Evolves nothing.
## plus the opt-in difficulty passive (user request, data in PactData):
##   Profane Pact    — stronger, more numerous enemies for more XP, Soul Ash
##                     and power-up drops.
## The GDD defines what each passive does but gives no values, so all numbers
## are TUNING (not in GDD).
##
## Stacking rule (GDD §34 "Add like-category bonus percentages, then multiply
## separate categories"): skill-level bonuses (UnitData.LEVELS) and passive
## bonuses (here) are two separate categories, so e.g.
##   effective_hp = base_hp * (1 + skill_hp_bonus) * (1 + vigor_hp_bonus).
class_name PassiveData
extends RefCounted

## Display / card order of passives.
const ORDER := ["grave_dominion", "necrotic_vigor", "dark_command", "soul_recycling",
	"soul_conduit", "warding_ritual", "abyssal_focus", "forbidden_knowledge", "dark_benediction",
	"shade_stride", "vampiric_rite", "necrotic_expanse", "lingering_malediction",
	"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls",
	"grim_ledger", "spirit_binding", "restless_dead",
	"blood_scent", "mournsong", "siegecraft", PactData.ID,
	# --- Act II: Fallen Seraph ---
	"fallen_grace",
	# --- Act II: Gullhaven Harbour ---
	"salt_of_the_deep", "brinewalker",
	# --- Act II: the Hollow Archive ---
	"marginalia", "iron_mind",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"abyssal_pact", "crushing_depths",
	# --- Content wave 2: Bone Golem ---
	"grave_masonry",
	# --- Act III: the Assembly Halls ---
	"strings_of_the_dead", "overclock", "signal_ghost",
	# --- Act III: the Scrap Wastes ---
	"conductive_marrow", "lead_lined_bones",
	# --- Act III: the Iron Citadel ---
	"machine_soul", "recoil_frame",
	# --- Act IV: the Shores of Ilion ---
	"mortal_heel", "bronze_breaker",
	# --- Act IV: Mount Olympus ---
	"titans_blood", "grounded_bones",
	# --- Act IV: the Asphodel Underworld ---
	"ferrymans_toll", "myrmidon_oath"]

## Passives that only help summons (a "dead" level-up card while no summon
## class is owned, see AbilityManager.build_offers()).
const ARMY_PASSIVES := ["grave_dominion", "necrotic_vigor", "dark_command", "soul_recycling",
	"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls",
	"blood_scent", "siegecraft",
	# --- Act II: Fallen Seraph ---
	"fallen_grace",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"crushing_depths",
	# --- Content wave 2: Bone Golem ---
	"grave_masonry",
	# --- Act III: the Assembly Halls ---
	"overclock",
	# --- Act III: the Scrap Wastes ---
	"lead_lined_bones",
	# --- Act III: the Iron Citadel ---
	"recoil_frame",
	# --- Act IV: the Shores of Ilion ---
	"bronze_breaker",
	# --- Act IV: the Asphodel Underworld ---
	"myrmidon_oath"]

# --- Act III: the Assembly Halls ---
## Overclock (paired with the Grave Drone): a summon class is "ranged" (and
## gets its attack speed) when its UnitData base attack_range is at least this
## (px): Skeletal Archers 170, Undead Mages 145, Banshees 150, Grave Drones 190,
## the priest orders' bolts... Warriors, Abominations, Rogues and the other
## melee classes (edge-to-edge reach under 40 px) are not.
const OVERCLOCK_MIN_RANGE: float = 100.0  # TUNING (not in GDD)

## Blood Scent: a summon class is "fast" (and gets the passive) when its
## UnitData base move_speed is at least this (px/s): Bone Hounds 122, Grave
## Rogues 112, Skeletal Archers and Crypt Gargoyles 95. Warriors (85), the
## priest orders (90), Banshees (92) and the slower classes are not.
const FAST_SUMMON_SPEED: float = 95.0  # TUNING (not in GDD) owner brief: "define fast by base speed threshold in data"
## Siegecraft: minion damage-over-time sources that also count as summon
## damage for its bonus (the strike sources are CombatResolver.
## is_minion_source(); these ticks are left out of crits and suppression
## like the Rogue bleed, but a siege bonus applies to them too).
const MINION_DOT_SOURCES := ["rogue_bleed", "hellhound_burn", "hellhound_trail", "ossuary_shards",
	# --- Content wave 2: Bone Golem --- (the Ossuary Titan's collapse wall spikes)
	"titan_wall"]
## Passives that only help shadow spells (a "dead" card while no spell is owned).
const SPELL_PASSIVES := ["soul_conduit", "abyssal_focus"]

## Unholy Precision: damage multiplier of a minion critical hit (2 = double
## damage).
const CRIT_DAMAGE_MULT: float = 2.0  # TUNING (not in GDD) user brief: "a crit deals double damage"
## Unholy Precision: the damage-source tags (CombatResolver.damage_enemy
## `source`) that count as a minion attack are every summon tag (each class
## id in UnitData.CLASS_ORDER, each summon evolution id in
## SummonEvolutionData.ORDER, and MINION_EXTRA_TAGS) followed by one of
## these suffixes: "" the basic attack (melee hit, arrow, mage orb, priest
## bolt, frost bolt), "_bash" an evolved shield bash, "_cleave" a Death
## Knight cleave, "_aura" a Profane Bishop aura pulse.
const MINION_SOURCE_SUFFIXES := ["", "_bash", "_cleave", "_aura"]
## Unholy Precision: summon tags that are not a class or evolution id (the
## Lich's raised skeletons, Death Mark's Risen and Raise Dead's skeletons).
const MINION_EXTRA_TAGS := ["lich_risen", "death_mark_risen", "raised_dead",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"drowned_thrall_ally", "tide_host_spawn",
	# --- Content wave 2: Ultimates --- (Grave Tide's Risen, UltimateSystem)
	"grave_tide_risen",
	# --- Act III: the Electronic Empire --- (a raised cyborg's Grave Gunner, EmpireRulesData.STEEL)
	"grave_gunner",
	# --- Act III: the Assembly Halls --- (a Hollow Puppet, PuppetData.SOURCE)
	"hollow_puppet"]
## Unholy Precision: the other minion damage sources that can crit: the
## basic warrior shield bash and the later classes' specials (and the Bone
## Colossus's death shrapnel). The Rogue's
## bleed ("rogue_bleed") is left out on purpose: it is a damage-over-time
## tick, not a strike.
const MINION_SPECIAL_SOURCES := ["bash", "abom_stomp", "rogue_dash", "gargoyle_swoop", "colossus_shrapnel",
	# --- Act II: Fallen Seraph --- (SeraphBehavior dive impact, SeraphFeathers ring)
	"seraph_dive", "seraph_feathers",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"deep_grasp", "leviathan_sweep",
	# --- Content wave 2: Bone Golem --- (the slam's splash, GolemBehavior)
	"golem_slam",
	# --- Act III: the Iron Citadel --- (the Deus Revenant's missiles; the Rust Prophet's Risen scrap bolts)
	"deus_revenant_missile", "scrap_bolt",
	# --- Act IV: the Asphodel Underworld --- (the Myrmidon Shades' spear through a second foe)
	"myrmidon_pierce"]
## Unholy Resilience: enemy damage-source tags (CombatResolver.damage_unit
## `source`) that count as AREA or HOLY damage, tag -> category ("area" |
## "holy"; the category only splits the summary stats). Every other source
## (melee swings, arrows, charges) is not reduced. Charges (Templar Knight,
## Sir Alaric) are body hits along a line, not an area, so they are not
## listed.
const AREA_HOLY_SOURCES := {
	"boss_hammer": "area",  # TUNING (not in GDD) Sir Alaric's Hammerfall slam.
	"boss_cleave": "area",  # TUNING (not in GDD) Marshal Vael's cleave sweep.
	"halberdier_cleave": "area",  # TUNING (not in GDD) a Halberdier's sweep onto neighbouring summons.
	"boss_judgment": "holy",  # TUNING (not in GDD) Sir Alaric's Judgment (holy light marks).
	"purifier": "holy",  # TUNING (not in GDD) Purifier holy fire (bonus vs undead).
	"holy_zone": "holy",  # TUNING (not in GDD) holy ground: grave consecration, Holy Ward Generators, boss holy zones.
	"holy_retribution": "holy",  # TUNING (not in GDD) radiant bolts of the Holy Retribution run modifier.
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"vhalneth_slam": "area",  # TUNING (not in GDD) an arm of Vhal'Neth crashing along its lane.
	"vhalneth_roar": "area",  # TUNING (not in GDD) her roar's blast.
	"sentinel_sweep": "area",  # TUNING (not in GDD) a Sanctified Sentinel's frontal sweep.
	"guardian_slam": "area",  # TUNING (not in GDD) the Cathedral Guardian's ground slam.
	"guardian_beam": "holy",  # TUNING (not in GDD) the Cathedral Guardian's sweeping beam.
	"radiant_inquisitor": "holy",  # TUNING (not in GDD) a Radiant Inquisitor's radiant bolts.
	"seraphine_bolt": "holy",  # TUNING (not in GDD) Seraphine's radiant fans and barrages.
	"seraphine_circle": "area",  # TUNING (not in GDD) Seraphine's delayed holy circles.
	"seraphine_beam": "holy",  # TUNING (not in GDD) Seraphine's rotating holy beams.
	"seraphine_nova": "holy",  # TUNING (not in GDD) Seraphine's Judgment nova.
	"seraphine_collapse": "holy",  # TUNING (not in GDD) the holy fire of her collapsing arena.
	# --- Act II: Gullhaven Harbour ---
	"deep_kin_leap": "area",  # TUNING (not in GDD) a Deep Kin's landing.
	"tide_wall": "area",  # TUNING (not in GDD) a Tide Caller's water line.
	"harbourmaster_sweep": "area",  # TUNING (not in GDD) the Harbourmaster's anchor sweep.
	"merrow_wave": "area",  # TUNING (not in GDD) Abbot Merrow's Brine Wave.
	"merrow_whirl": "area",  # TUNING (not in GDD) Abbot Merrow's Whirl.
	# --- Act III: the Assembly Halls ---
	"juggernaut_flame": "area",  # TUNING (not in GDD) a Juggernaut's flame cone.
	"furnace": "area",  # TUNING (not in GDD) a burning furnace channel.
	"beta_swipe": "area",  # TUNING (not in GDD) the Beta Build's weld swipe.
	"motherboard_stamp": "area",  # TUNING (not in GDD) the Motherboard's press-stamps.
	"motherboard_hurl": "area",  # TUNING (not in GDD) a hurled summon landing.
}
## Bone Plating: a plated hit always keeps at least this fraction (0..1) of
## its damage, so the flat reduction never makes a summon immune to the
## early, weak hits (a 3-damage recruit swing still deals 0.75 at Lv 5).
const PLATING_MIN_FRACTION: float = 0.25  # TUNING (not in GDD)
## Bone Plating: damage sources it ignores. Holy ground damages summons in
## small ticks (StageDirector, every WaveData.ZONE_TICK s), which a flat
## per-hit reduction would erase; it is a field, not a hit (Unholy
## Resilience covers it instead).
## Seraphine's beam pulses and collapse fire tick the same way (fields).
const PLATING_EXEMPT_SOURCES := ["holy_zone", "seraphine_beam", "seraphine_collapse",
	# --- Act III: the Assembly Halls --- (fields that tick, like holy ground)
	"furnace", "juggernaut_flame"]
## Grim Ledger: damage sources it does NOT amplify. The Soul Nova power-up
## deals an exact share of max HP (like the Gravebow curse exemption).
const LEDGER_EXEMPT_SOURCES := ["nova"]  # TUNING (not in GDD)
## Salt of the Deep: damage sources it does NOT amplify (the Soul Nova deals an
## exact share of max HP, like Grim Ledger's exemption).
const SALT_EXEMPT_SOURCES := ["nova"]  # TUNING (not in GDD)
## Brinewalker: the passive level from which it also helps the summons
## (owner-approved "and summons from Lv 3").
const BRINEWALKER_SUMMON_LEVEL: int = 3  # owner-approved
# --- Content wave 2: Bone Golem ---
## Grave Masonry: the blocker classes it protects (UnitData ids; their
## evolutions keep the class id: Death Knight, Bone Colossus, Ossuary Titan).
## Read by CombatResolver.damage_unit() (blocker_reduction) and
## HordeDirector.compute_stats() (hold_bonus).
const MASONRY_CLASSES := ["warrior", "abomination", "bone_golem"]  # Owner-approved proposal 5
# --- Act IV: the Asphodel Underworld ---
## Myrmidon Oath: the front-line classes (the blockers on the Bone Ring's
## outer posts) whose max HP and damage it raises (HordeDirector.compute_stats()).
const OATH_CLASSES := ["warrior", "abomination", "bone_golem", "myrmidon_shade"]  # TUNING (not in GDD)
# --- Act III: the Iron Citadel ---
## Recoil Frame: the attack profiles (UnitData "attack_profile", after a summon
## evolution's overlay) that count as RANGED summons: they fire faster and
## farther with it (HordeDirector.compute_stats()). Archers / Gravebows, Mages /
## Liches, Catapults / Ossuary Engines, Fallen Seraphs, Frost Wraiths and Iron
## Revenants.
const RECOIL_PROFILES := ["arrow", "aoe", "boulder", "feather", "frost", "suppress"]  # TUNING (not in GDD)

## Passive definitions.
##   display_name — UI name.
##   icon         — IconGlyph kind.
##   description  — card text (GDD §34 definition): one short sentence, no
##                  numbers and no evolution recipe (GDD §15.0 "Card text:
##                  one sentence").
##   labels       — stat key -> [UI label, format] where format is "int",
##                  "pct" (0.1 -> +10%), "neg_pct" (0.1 -> -10%) or "num"
##                  (0.4 -> +0.4).
##   levels       — 5 rows of ABSOLUTE values at that passive level.
##
## Keys:
##   capacity_per_class — extra population for every summon class you own.
##   minion_hp          — +% minion max HP.
##   minion_damage      — +% minion damage.
##   minion_speed       — +% minion attack speed.
##   replace_reduction  — -% replacement interval.
##   spell_damage       — +% damage of every shadow spell (and its evolution).
##   damage_reduction   — -% damage taken by the necromancer (after wards).
##   cooldown_reduction — -% spell cooldowns, Orb Shield recharge and Eclipse
##                        Ward pulse interval.
##   mage_damage        — +% damage of the `classes` (Undead Mage / Lich).
##   mage_splash        — +% splash radius of the `classes`.
##   support_power      — +% heal, ward, ally barrier and aura heal of the
##                        `classes` (Mender, Warder, Profane Bishop).
##   classes            — (optional) summon classes the passive affects; it
##                        is a "dead" card while none of them is owned.
##   shared_card_pool   — (optional) true for the later passives: a later item,
##                        its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
##                        (like the later summon classes and spells).
##   flat_reduction     — damage every hit on a minion loses (after the other
##                        reductions, before barriers; it keeps at least
##                        PLATING_MIN_FRACTION of the hit).
##   crit_chance        — 0..1 chance a minion attack crits (x CRIT_DAMAGE_MULT).
##   area_holy_reduction — -% damage minions take from AREA_HOLY_SOURCES.
##   minion_move_speed  — +% minion move speed (own category).
##   leash_range        — +% minion engagement leash and soft-recall distance
##                        (UnitData.ENGAGE_RADIUS / SOFT_RECALL; the hard
##                        recall distance is unchanged).
##   return_reduction   — -% time a leashed minion needs to come back to you
##                        (its RETURNING speed is divided by 1 - this).
##   move_speed         — +% necromancer move speed (its own category, on top
##                        of the meta Fleet Shade bonus).
##   hp_regen           — +HP per second added to the necromancer's natural
##                        regeneration (PlayerData.HP_REGEN).
##   spell_area         — +% spell area: the radius stats of every spell
##                        (own category, on top of the meta Widening Dark).
##   spell_duration     — +% spell durations (AbilityData.DURATION_KEYS: Plague
##                        Cloud duration, Grave Eruption spike fields, Shadow
##                        Blast slow).
##   elite_damage       — +% damage elites, minibosses and bosses take from
##                        every source (Grim Ledger).
##   cc_duration        — +% duration of every slow, chill, Deep Freeze and
##                        stun applied to enemies (Spirit Binding).
##   temp_duration      — +% lifetime of temporary summons (Restless Dead).
##   temp_damage        — +% damage of temporary summons (Restless Dead).
##   fast_move_speed    — +% move speed of the fast summon classes
##                        (FAST_SUMMON_SPEED; own category).
##   fast_attack_speed  — +% attack speed of the fast summon classes.
##   debuff_duration    — +% duration of every weakening effect on enemies
##                        (slows, chills, the Dirge, curses, Rot).
##   siege_damage       — +% summon damage to structures, elites and
##                        minibosses (not the stage boss).
##   special_haste      — summon special cooldowns divided by (1 + this)
##                        (Fallen Grace; its own category).
##   slowed_damage      — +% damage enemies take while slowed, chilled or
##                        frozen (Salt of the Deep).
##   water_slow_cut     — share (0..1) of a water / ink slow on the
##                        necromancer removed (Brinewalker; 1 = none), and on
##                        summons from BRINEWALKER_SUMMON_LEVEL.
##   blocker_reduction  — -% damage the MASONRY_CLASSES take (Grave Masonry;
##                        its own category in CombatResolver.damage_unit()).
##   hold_bonus         — +% block mass of the MASONRY_CLASSES and +% Bulwark
##                        plant time of the Bone Golem (Grave Masonry; after
##                        the evolution overlay in compute_stats()).
##   act                — (optional) the only campaign act whose stages offer
##                        the card (Unlocks.act_allows()).
const PASSIVES := {
	# Profane Pact (difficulty / reward passive): defined in PactData.
	PactData.ID: PactData.PASSIVE,
	"grave_dominion": {
		"display_name": "Grave Dominion",
		"icon": "grave_dominion",
		"description": "Raises the capacity of every summon class you command.",
		"labels": {"capacity_per_class": ["Capacity per class", "int"]},
		"levels": [
			{"capacity_per_class": 1},  # TUNING (not in GDD) every level adds +1
			{"capacity_per_class": 2},  # TUNING (not in GDD)
			{"capacity_per_class": 3},  # TUNING (not in GDD)
			{"capacity_per_class": 4},  # TUNING (not in GDD)
			{"capacity_per_class": 5},  # TUNING (not in GDD)
		],
	},
	"necrotic_vigor": {
		"display_name": "Necrotic Vigor",
		"icon": "necrotic_vigor",
		"description": "Increases maximum health of all minions.",
		"labels": {"minion_hp": ["Minion max HP", "pct"]},
		"levels": [
			{"minion_hp": 0.15},  # TUNING (not in GDD)
			{"minion_hp": 0.30},  # TUNING (not in GDD)
			{"minion_hp": 0.45},  # TUNING (not in GDD)
			{"minion_hp": 0.60},  # TUNING (not in GDD)
			{"minion_hp": 0.75},  # TUNING (not in GDD)
		],
	},
	"dark_command": {
		"display_name": "Dark Command",
		"icon": "dark_command",
		"description": "Increases minion attack damage and attack speed.",
		"labels": {"minion_damage": ["Minion damage", "pct"], "minion_speed": ["Minion attack speed", "pct"]},
		"levels": [
			{"minion_damage": 0.10, "minion_speed": 0.05},  # TUNING (not in GDD)
			{"minion_damage": 0.20, "minion_speed": 0.10},  # TUNING (not in GDD)
			{"minion_damage": 0.30, "minion_speed": 0.15},  # TUNING (not in GDD)
			{"minion_damage": 0.40, "minion_speed": 0.20},  # TUNING (not in GDD)
			{"minion_damage": 0.50, "minion_speed": 0.25},  # TUNING (not in GDD)
		],
	},
	"soul_recycling": {
		"display_name": "Soul Recycling",
		"icon": "soul_recycling",
		"description": "Fallen summons are replaced faster.",
		"labels": {"replace_reduction": ["Replacement time", "neg_pct"]},
		"levels": [
			{"replace_reduction": 0.10},  # TUNING (not in GDD)
			{"replace_reduction": 0.20},  # TUNING (not in GDD)
			{"replace_reduction": 0.30},  # TUNING (not in GDD)
			{"replace_reduction": 0.40},  # TUNING (not in GDD)
			{"replace_reduction": 0.50},  # TUNING (not in GDD)
		],
	},
	"soul_conduit": {
		"display_name": "Soul Conduit",
		"icon": "soul_conduit",
		"description": "Harvested souls add damage to your spells.",
		"labels": {"spell_damage": ["Spell damage", "pct"]},
		"levels": [
			{"spell_damage": 0.10},  # TUNING (not in GDD)
			{"spell_damage": 0.20},  # TUNING (not in GDD)
			{"spell_damage": 0.30},  # TUNING (not in GDD)
			{"spell_damage": 0.40},  # TUNING (not in GDD)
			{"spell_damage": 0.50},  # TUNING (not in GDD)
		],
	},
	"warding_ritual": {
		"display_name": "Warding Ritual",
		"icon": "warding_ritual",
		"description": "Protective sigils dull every blow you take.",
		"labels": {"damage_reduction": ["Damage taken", "neg_pct"]},
		"levels": [
			{"damage_reduction": 0.05},  # TUNING (not in GDD)
			{"damage_reduction": 0.10},  # TUNING (not in GDD)
			{"damage_reduction": 0.15},  # TUNING (not in GDD)
			{"damage_reduction": 0.20},  # TUNING (not in GDD)
			{"damage_reduction": 0.25},  # TUNING (not in GDD)
		],
	},
	"abyssal_focus": {
		"display_name": "Abyssal Focus",
		"icon": "abyssal_focus",
		"description": "Your spells return faster from the abyss.",
		"labels": {"cooldown_reduction": ["Spell cooldowns", "neg_pct"]},
		"levels": [
			{"cooldown_reduction": 0.05},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.10},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.15},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.20},  # TUNING (not in GDD)
			{"cooldown_reduction": 0.25},  # TUNING (not in GDD)
		],
	},
	"forbidden_knowledge": {
		"display_name": "Forbidden Knowledge",
		"icon": "forbidden_knowledge",
		"description": "Forbidden rites empower your Undead Mages.",
		"labels": {"mage_damage": ["Mage damage", "pct"], "mage_splash": ["Mage splash radius", "pct"]},
		"classes": ["mage"],
		"levels": [
			{"mage_damage": 0.08, "mage_splash": 0.05},  # TUNING (not in GDD)
			{"mage_damage": 0.16, "mage_splash": 0.10},  # TUNING (not in GDD)
			{"mage_damage": 0.24, "mage_splash": 0.15},  # TUNING (not in GDD)
			{"mage_damage": 0.32, "mage_splash": 0.20},  # TUNING (not in GDD)
			{"mage_damage": 0.40, "mage_splash": 0.25},  # TUNING (not in GDD)
		],
	},
	"dark_benediction": {
		"display_name": "Dark Benediction",
		"icon": "dark_benediction",
		"description": "Unholy blessings strengthen your heals, wards and barriers.",
		"labels": {"support_power": ["Heals, wards and barriers", "pct"]},
		"classes": ["mender", "warder", "bishop"],
		"levels": [
			{"support_power": 0.08},  # TUNING (not in GDD)
			{"support_power": 0.16},  # TUNING (not in GDD)
			{"support_power": 0.24},  # TUNING (not in GDD)
			{"support_power": 0.32},  # TUNING (not in GDD)
			{"support_power": 0.40},  # TUNING (not in GDD)
		],
	},
	"shade_stride": {
		"display_name": "Shade Stride",
		"icon": "shade_stride",
		"description": "You move faster, gliding like a shade across the graves.",
		"labels": {"move_speed": ["Move speed", "pct"]},
		"levels": [
			{"move_speed": 0.03},  # TUNING (not in GDD)
			{"move_speed": 0.06},  # TUNING (not in GDD)
			{"move_speed": 0.09},  # TUNING (not in GDD)
			{"move_speed": 0.12},  # TUNING (not in GDD)
			{"move_speed": 0.15},  # TUNING (not in GDD)
		],
	},
	"vampiric_rite": {
		"display_name": "Vampiric Rite",
		"icon": "vampiric_rite",
		"description": "Stolen life slowly seeps back into you.",
		"labels": {"hp_regen": ["Regeneration (HP/s)", "num"]},
		"levels": [
			{"hp_regen": 0.2},  # TUNING (not in GDD)
			{"hp_regen": 0.4},  # TUNING (not in GDD)
			{"hp_regen": 0.6},  # TUNING (not in GDD)
			{"hp_regen": 0.8},  # TUNING (not in GDD)
			{"hp_regen": 1.0},  # TUNING (not in GDD)
		],
	},
	"necrotic_expanse": {
		"display_name": "Necrotic Expanse",
		"icon": "necrotic_expanse",
		"description": "Your blasts, clouds and bursts spread wider.",
		"labels": {"spell_area": ["Spell area (radius)", "pct"]},
		"levels": [
			{"spell_area": 0.05},  # TUNING (not in GDD)
			{"spell_area": 0.10},  # TUNING (not in GDD)
			{"spell_area": 0.15},  # TUNING (not in GDD)
			{"spell_area": 0.20},  # TUNING (not in GDD)
			{"spell_area": 0.25},  # TUNING (not in GDD)
		],
	},
	"lingering_malediction": {
		"display_name": "Lingering Malediction",
		"icon": "lingering_malediction",
		"description": "Your clouds, spike fields and slows linger longer.",
		"labels": {"spell_duration": ["Spell duration", "pct"]},
		"levels": [
			{"spell_duration": 0.10},  # TUNING (not in GDD)
			{"spell_duration": 0.20},  # TUNING (not in GDD)
			{"spell_duration": 0.30},  # TUNING (not in GDD)
			{"spell_duration": 0.40},  # TUNING (not in GDD)
			{"spell_duration": 0.50},  # TUNING (not in GDD)
		],
	},
	"bone_plating": {
		"display_name": "Bone Plating",
		"icon": "bone_plating",
		"description": "Bone plates turn the edge of every blow your minions take.",
		"labels": {"flat_reduction": ["Damage ignored per hit", "int"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"flat_reduction": 2},  # TUNING (not in GDD) user brief: 2 -> 6
			{"flat_reduction": 3},  # TUNING (not in GDD)
			{"flat_reduction": 4},  # TUNING (not in GDD)
			{"flat_reduction": 5},  # TUNING (not in GDD)
			{"flat_reduction": 6},  # TUNING (not in GDD)
		],
	},
	"unholy_precision": {
		"display_name": "Unholy Precision",
		"icon": "unholy_precision",
		"description": "Your minions' attacks can strike critically for double damage.",
		"labels": {"crit_chance": ["Minion critical chance", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"crit_chance": 0.05},  # TUNING (not in GDD) user brief: 5% -> 25%
			{"crit_chance": 0.10},  # TUNING (not in GDD)
			{"crit_chance": 0.15},  # TUNING (not in GDD)
			{"crit_chance": 0.20},  # TUNING (not in GDD)
			{"crit_chance": 0.25},  # TUNING (not in GDD)
		],
	},
	"unholy_resilience": {
		"display_name": "Unholy Resilience",
		"icon": "unholy_resilience",
		"description": "Your minions shrug off slams, sweeps, holy fire and consecrated ground.",
		"labels": {"area_holy_reduction": ["Area and holy damage taken", "neg_pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"area_holy_reduction": 0.08},  # TUNING (not in GDD) user brief: 8% -> 35%
			{"area_holy_reduction": 0.15},  # TUNING (not in GDD)
			{"area_holy_reduction": 0.21},  # TUNING (not in GDD)
			{"area_holy_reduction": 0.28},  # TUNING (not in GDD)
			{"area_holy_reduction": 0.35},  # TUNING (not in GDD)
		],
	},
	"bound_souls": {
		"display_name": "Bound Souls",
		"icon": "bound_souls",
		"description": "Your minions move faster, roam farther and return to you sooner.",
		"labels": {"minion_move_speed": ["Minion move speed", "pct"], "leash_range": ["Leash range", "pct"], "return_reduction": ["Return time", "neg_pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"minion_move_speed": 0.06, "leash_range": 0.10, "return_reduction": 0.10},  # TUNING (not in GDD) user brief: +6% / +10% / -10% at Lv 1
			{"minion_move_speed": 0.12, "leash_range": 0.20, "return_reduction": 0.20},  # TUNING (not in GDD)
			{"minion_move_speed": 0.18, "leash_range": 0.30, "return_reduction": 0.30},  # TUNING (not in GDD)
			{"minion_move_speed": 0.24, "leash_range": 0.40, "return_reduction": 0.40},  # TUNING (not in GDD)
			{"minion_move_speed": 0.30, "leash_range": 0.50, "return_reduction": 0.50},  # TUNING (not in GDD) user brief: +30% / +50% / half the return time
		],
	},
	"grim_ledger": {
		"display_name": "Grim Ledger",
		"icon": "grim_ledger",
		"description": "Elites, minibosses and bosses take more damage from everything.",
		"labels": {"elite_damage": ["Damage to elites and bosses", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"elite_damage": 0.05},  # TUNING (not in GDD)
			{"elite_damage": 0.10},  # TUNING (not in GDD)
			{"elite_damage": 0.15},  # TUNING (not in GDD)
			{"elite_damage": 0.20},  # TUNING (not in GDD)
			{"elite_damage": 0.25},  # TUNING (not in GDD)
		],
	},
	"spirit_binding": {
		"display_name": "Spirit Binding",
		"icon": "spirit_binding",
		"description": "Every slow, chill, freeze and stun you inflict lasts longer.",
		"labels": {"cc_duration": ["Slow, freeze and stun duration", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"cc_duration": 0.08},  # TUNING (not in GDD)
			{"cc_duration": 0.16},  # TUNING (not in GDD)
			{"cc_duration": 0.24},  # TUNING (not in GDD)
			{"cc_duration": 0.32},  # TUNING (not in GDD)
			{"cc_duration": 0.40},  # TUNING (not in GDD)
		],
	},
	"restless_dead": {
		"display_name": "Restless Dead",
		"icon": "restless_dead",
		"description": "Temporary summons last longer and strike harder.",
		"labels": {"temp_duration": ["Temporary summon lifetime", "pct"], "temp_damage": ["Temporary summon damage", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"temp_duration": 0.10, "temp_damage": 0.08},  # TUNING (not in GDD)
			{"temp_duration": 0.20, "temp_damage": 0.16},  # TUNING (not in GDD)
			{"temp_duration": 0.30, "temp_damage": 0.24},  # TUNING (not in GDD)
			{"temp_duration": 0.40, "temp_damage": 0.32},  # TUNING (not in GDD)
			{"temp_duration": 0.50, "temp_damage": 0.40},  # TUNING (not in GDD)
		],
	},
	"blood_scent": {
		"display_name": "Blood Scent",
		"icon": "blood_scent",
		"description": "Your swiftest dead move and attack faster.",
		"labels": {"fast_move_speed": ["Fast summon move speed", "pct"], "fast_attack_speed": ["Fast summon attack speed", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"fast_move_speed": 0.05, "fast_attack_speed": 0.06},  # TUNING (not in GDD)
			{"fast_move_speed": 0.10, "fast_attack_speed": 0.12},  # TUNING (not in GDD)
			{"fast_move_speed": 0.15, "fast_attack_speed": 0.18},  # TUNING (not in GDD)
			{"fast_move_speed": 0.20, "fast_attack_speed": 0.24},  # TUNING (not in GDD)
			{"fast_move_speed": 0.25, "fast_attack_speed": 0.30},  # TUNING (not in GDD)
		],
	},
	"mournsong": {
		"display_name": "Mournsong",
		"icon": "mournsong",
		"description": "Slows, chills, curses, Rot and Dirges you inflict all last longer.",
		"labels": {"debuff_duration": ["Weakening effect duration", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"debuff_duration": 0.10},  # TUNING (not in GDD)
			{"debuff_duration": 0.20},  # TUNING (not in GDD)
			{"debuff_duration": 0.30},  # TUNING (not in GDD)
			{"debuff_duration": 0.40},  # TUNING (not in GDD)
			{"debuff_duration": 0.50},  # TUNING (not in GDD)
		],
	},
	"siegecraft": {
		"display_name": "Siegecraft",
		"icon": "siegecraft",
		"description": "Summons deal more damage to structures, elites and minibosses.",
		"labels": {"siege_damage": ["Summon damage to structures, elites, minibosses", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"siege_damage": 0.10},  # TUNING (not in GDD)
			{"siege_damage": 0.20},  # TUNING (not in GDD)
			{"siege_damage": 0.30},  # TUNING (not in GDD)
			{"siege_damage": 0.40},  # TUNING (not in GDD)
			{"siege_damage": 0.50},  # TUNING (not in GDD)
		],
	},
	# --- Act II: Fallen Seraph ---
	"fallen_grace": {
		"display_name": "Fallen Grace",  # TUNING (not in GDD) Act II workstream name
		"icon": "fallen_grace",
		"description": "Your summons' special attacks recharge faster.",
		"labels": {"special_haste": ["Summon special recharge speed", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"special_haste": 0.05},  # TUNING (not in GDD)
			{"special_haste": 0.10},  # TUNING (not in GDD)
			{"special_haste": 0.15},  # TUNING (not in GDD)
			{"special_haste": 0.20},  # TUNING (not in GDD)
			{"special_haste": 0.25},  # TUNING (not in GDD)
		],
	},
	# --- Act II: Gullhaven Harbour ---
	"salt_of_the_deep": {
		"display_name": "Salt of the Deep",
		"icon": "salt_of_the_deep",
		"description": "Slowed, chilled and frozen foes take more damage from everything.",
		"labels": {"slowed_damage": ["Damage to slowed foes", "pct"]},
		"shared_card_pool": true,  # owner-approved: unlocked Act II items weigh the later items' 0.5
		"levels": [
			{"slowed_damage": 0.06},  # owner-approved "+6% a level"
			{"slowed_damage": 0.12},  # owner-approved
			{"slowed_damage": 0.18},  # owner-approved
			{"slowed_damage": 0.24},  # owner-approved
			{"slowed_damage": 0.30},  # owner-approved "+30% at Lv 5"
		],
	},
	"brinewalker": {
		"display_name": "Brinewalker",
		"icon": "brinewalker",
		"description": "Water and ink slow you less, and your summons too once it grows.",
		"labels": {"water_slow_cut": ["Water and ink slow removed", "pct"]},
		"shared_card_pool": true,  # owner-approved: Act II items weigh the later items' 0.5
		"act": 2,  # owner-approved: counter-passives are offered only on Act II stages
		"levels": [
			{"water_slow_cut": 0.20},  # owner-approved "-20% a level"
			{"water_slow_cut": 0.40},  # owner-approved
			{"water_slow_cut": 0.60},  # owner-approved (summons too from Lv 3)
			{"water_slow_cut": 0.80},  # owner-approved
			{"water_slow_cut": 1.00},  # owner-approved "no slow at Lv 5"
		],
	},
	# --- Act II: the Hollow Archive ---
	"marginalia": {
		"display_name": "Marginalia",
		"icon": "marginalia",
		"description": "Every blast a death sets off hits harder.",
		"labels": {"on_death_damage": ["On-death effect damage", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"on_death_damage": 0.08},  # Owner-approved proposal "+8% a level"
			{"on_death_damage": 0.16},  # Owner-approved proposal
			{"on_death_damage": 0.24},  # Owner-approved proposal
			{"on_death_damage": 0.32},  # Owner-approved proposal
			{"on_death_damage": 0.40},  # Owner-approved proposal
		],
	},
	"iron_mind": {
		"display_name": "Iron Mind",
		"icon": "iron_mind",
		"description": "Dread takes hold of you more slowly, and kills calm it faster.",
		"labels": {"dread_rise_reduction": ["Dread rise", "neg_pct"], "dread_fall_mult": ["Dread calmed per kill (x)", "num"]},
		"act": 2,  # Act II only (Unlocks.act_allows()): never a dead card.
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"dread_rise_reduction": 0.10, "dread_fall_mult": 1.0},  # Owner-approved proposal "10% slower a level"
			{"dread_rise_reduction": 0.20, "dread_fall_mult": 1.0},  # Owner-approved proposal
			{"dread_rise_reduction": 0.30, "dread_fall_mult": 1.0},  # Owner-approved proposal
			{"dread_rise_reduction": 0.40, "dread_fall_mult": 1.0},  # Owner-approved proposal
			{"dread_rise_reduction": 0.50, "dread_fall_mult": 2.0},  # Owner-approved proposal "falls twice as fast per kill at Lv 5"
		],
	},
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# Abyssal Pact (GDD §15.0 "Ul-Thalos, the Risen Spire"; unlocked by slaying
	# Vhal'Neth, UnlockData): every temporary summon (a Drowned Thrall, a
	# Death Mark Risen, a Raise Dead / Legion skeleton, a Lich's raised dead,
	# a stage reinforcement) releases a soul burst when it crumbles or falls,
	# healing every summon within burst_radius px by burst_heal HP
	# (AbyssalPact, called from HordeDirector.on_unit_died()). Pairs with
	# Call of the Drowned -> Tidecaller's Host.
	"abyssal_pact": {
		"display_name": "Abyssal Pact",
		"icon": "abyssal_pact",
		"description": "Temporary summons release a healing soul burst when they crumble.",
		"labels": {"burst_heal": ["Soul burst heal", "int"], "burst_radius": ["Soul burst radius", "int"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"burst_heal": 6.0, "burst_radius": 70.0},  # TUNING (not in GDD)
			{"burst_heal": 9.0, "burst_radius": 80.0},  # TUNING (not in GDD)
			{"burst_heal": 12.0, "burst_radius": 90.0},  # TUNING (not in GDD)
			{"burst_heal": 16.0, "burst_radius": 100.0},  # TUNING (not in GDD)
			{"burst_heal": 20.0, "burst_radius": 110.0},  # TUNING (not in GDD)
		],
	},
	# Crushing Depths (GDD §15.0; unlocked by slaying Vhal'Neth): summons deal
	# more damage to foes that are held, stunned or frozen (CombatResolver.
	# damage_enemy(): an enemy with a stun or a Deep Freeze running). Pairs
	# with the Spawn of the Deep -> Leviathan.
	"crushing_depths": {
		"display_name": "Crushing Depths",
		"icon": "crushing_depths",
		"description": "Summons strike harder at foes that are held, stunned or frozen.",
		"labels": {"held_damage": ["Summon damage to held foes", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"held_damage": 0.08},  # TUNING (not in GDD)
			{"held_damage": 0.16},  # TUNING (not in GDD)
			{"held_damage": 0.24},  # TUNING (not in GDD)
			{"held_damage": 0.32},  # TUNING (not in GDD)
			{"held_damage": 0.40},  # TUNING (not in GDD)
		],
	},
	# --- Content wave 2: Bone Golem ---
	# Grave Masonry (owner-approved proposal 5; locked with the Golem until the
	# Bone Legion achievement, UnlockData): the blockers (MASONRY_CLASSES) take
	# less damage and hold their ground longer. Pairs with the Bone Golem ->
	# Ossuary Titan.
	"grave_masonry": {
		"display_name": "Grave Masonry",  # Owner-approved proposal 5
		"icon": "grave_masonry",
		"description": "Your Warriors, Abominations and Golems take less damage and hold their ground longer.",
		"labels": {"blocker_reduction": ["Blocker damage taken", "neg_pct"], "hold_bonus": ["Blocker hold (mass, Bulwark time)", "pct"]},
		"classes": MASONRY_CLASSES,  # A dead card while none of them is owned.
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"blocker_reduction": 0.05, "hold_bonus": 0.10},  # TUNING (not in GDD)
			{"blocker_reduction": 0.08, "hold_bonus": 0.15},  # TUNING (not in GDD)
			{"blocker_reduction": 0.11, "hold_bonus": 0.20},  # TUNING (not in GDD)
			{"blocker_reduction": 0.14, "hold_bonus": 0.25},  # TUNING (not in GDD)
			{"blocker_reduction": 0.18, "hold_bonus": 0.30},  # TUNING (not in GDD)
		],
	},
	# --- Act III: the Assembly Halls ---
	# Strings of the Dead (GDD §15.0 "The Assembly Halls (Act III phase 2)";
	# unlocked with Hollow Puppet by slaying the Motherboard, UnlockData): every
	# temporary summon you raise (a puppet, a Risen, a Thrall, a Grave Gunner, a
	# Raise Dead skeleton...) pulls the foes within taunt_reach px onto itself
	# (the taunt path the Bone Colossus uses, ColossusKit; bosses, Reckoning
	# foes and structures ignore it) and rises with temp_hp more HP; both in
	# HordeDirector.spawn_temporary(), the one path of every temporary summon.
	# Pairs with Hollow Puppet -> Puppet King.
	"strings_of_the_dead": {
		"display_name": "Strings of the Dead",  # Owner-approved proposal
		"icon": "strings_of_the_dead",
		"description": "Your temporary dead draw the foes around them and rise sturdier.",
		"labels": {"taunt_reach": ["Temporary summons draw foes within (px)", "int"], "temp_hp": ["Temporary summon HP", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"taunt_reach": 60.0, "temp_hp": 0.08},  # TUNING (not in GDD)
			{"taunt_reach": 75.0, "temp_hp": 0.16},  # TUNING (not in GDD)
			{"taunt_reach": 90.0, "temp_hp": 0.24},  # TUNING (not in GDD)
			{"taunt_reach": 105.0, "temp_hp": 0.32},  # TUNING (not in GDD)
			{"taunt_reach": 120.0, "temp_hp": 0.40},  # TUNING (not in GDD)
		],
	},
	# Overclock (GDD §15.0; unlocked with the Grave Drone by slaying the
	# Motherboard): every RANGED summon class (OVERCLOCK_MIN_RANGE) attacks
	# faster: attack_interval / (1 + ranged_attack_speed), its own category in
	# HordeDirector.compute_stats(). Pairs with the Grave Drone -> Wraith Drone.
	"overclock": {
		"display_name": "Overclock",  # Owner-approved proposal
		"icon": "overclock",
		"description": "Your ranged summons attack faster.",
		"labels": {"ranged_attack_speed": ["Ranged summon attack speed", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"ranged_attack_speed": 0.05},  # TUNING (not in GDD)
			{"ranged_attack_speed": 0.10},  # TUNING (not in GDD)
			{"ranged_attack_speed": 0.15},  # TUNING (not in GDD)
			{"ranged_attack_speed": 0.20},  # TUNING (not in GDD)
			{"ranged_attack_speed": 0.25},  # TUNING (not in GDD)
		],
	},
	# Signal Ghost (owner-approved proposal: an Act III counter-passive, "Lock-On
	# lines take longer to paint on the necromancer"; unlocked by the
	# achievement Cold Assembly, UnlockData; offered only on Act III stages,
	# "act": 3). LockOn.paint_time() reads paint_time (EmpireRulesData
	# SIGNAL_GHOST / SIGNAL_GHOST_KEY): a line on the necromancer paints
	# (1 + paint_time) x as long. Evolves nothing.
	"signal_ghost": {
		"display_name": "Signal Ghost",  # Owner-approved proposal
		"icon": "signal_ghost",
		"description": "The Empire's Lock-On lines take longer to paint on you.",
		"labels": {"paint_time": ["Lock-On paint time on you", "pct"]},
		"shared_card_pool": true,  # owner-approved: Act III items weigh the later items' 0.5, as Act II's counter-passives
		"act": 3,  # Owner-approved proposal: counter-passives are offered only in their act
		"levels": [
			{"paint_time": 0.15},  # TUNING (not in GDD) 1.5 s -> 1.73 s
			{"paint_time": 0.30},  # TUNING (not in GDD)
			{"paint_time": 0.45},  # TUNING (not in GDD)
			{"paint_time": 0.60},  # TUNING (not in GDD)
			{"paint_time": 0.80},  # TUNING (not in GDD) 1.5 s -> 2.7 s
		],
	},
	# --- Act III: the Scrap Wastes ---
	# Death Ray's paired passive (owner-approved Act III proposal: "Conductive
	# Marrow (a longer, wider beam)"); unlocked with the spell by Kestrel.
	"conductive_marrow": {
		"display_name": "Conductive Marrow",
		"icon": "conductive_marrow",
		"description": "Your Death Ray reaches farther and cuts a wider line.",
		"labels": {"beam_length": ["Death Ray length", "pct"], "beam_width": ["Death Ray width", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"beam_length": 0.05, "beam_width": 0.12},  # TUNING (not in GDD)
			{"beam_length": 0.10, "beam_width": 0.24},  # TUNING (not in GDD)
			{"beam_length": 0.15, "beam_width": 0.36},  # TUNING (not in GDD)
			{"beam_length": 0.20, "beam_width": 0.48},  # TUNING (not in GDD)
			{"beam_length": 0.25, "beam_width": 0.60},  # TUNING (not in GDD)
		],
	},
	# Act III's first counter-passive (owner-approved Act III proposal:
	# "Lead-Lined Bones: ranged hits on your summons deal less damage"; offered
	# only in Act III, unlocked by Static in the Wastes).
	"lead_lined_bones": {
		"display_name": "Lead-Lined Bones",
		"icon": "lead_lined_bones",
		"description": "Bullets and shells hurt your summons less.",
		"labels": {"ranged_reduction": ["Ranged damage to summons", "neg_pct"]},
		"act": 3,  # Owner-approved: the act's counter-passives are offered only in Act III (Unlocks.act_allows())
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"ranged_reduction": 0.06},  # TUNING (not in GDD)
			{"ranged_reduction": 0.12},  # TUNING (not in GDD)
			{"ranged_reduction": 0.18},  # TUNING (not in GDD)
			{"ranged_reduction": 0.24},  # TUNING (not in GDD)
			{"ranged_reduction": 0.30},  # TUNING (not in GDD)
		],
	},
	# --- Act III: the Iron Citadel ---
	# Machine Soul (GDD §15.0 "Scrap Swarm, Machine Soul and the Rust Prophet";
	# unlocked by defeating Deus Ex Machina, UnlockData): the soul the Empire
	# forgot to delete, now the necromancer's: every hit of his (spells and
	# summons alike) pierces armour_pierce of the foe's armour, percentage and
	# flat (CombatResolver.damage_enemy(): the stronger of it and the Wither
	# shred applies). Useful on every stage (Footmen, Templars, Sentinels and the
	# Empire's chrome alike). Pairs with Scrap Swarm -> Deathless Swarm.
	"machine_soul": {
		"display_name": "Machine Soul",
		"icon": "machine_soul",
		"description": "Every hit you and your dead land pierces part of the foe's armour.",
		"labels": {"armor_pierce": ["Armour pierced", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"armor_pierce": 0.1},  # TUNING (not in GDD)
			{"armor_pierce": 0.2},  # TUNING (not in GDD)
			{"armor_pierce": 0.3},  # TUNING (not in GDD)
			{"armor_pierce": 0.4},  # TUNING (not in GDD)
			{"armor_pierce": 0.5},  # TUNING (not in GDD) first pass 0.6
		],
	},
	# Recoil Frame (GDD §15.0 "Iron Revenant, Deus Revenant and Recoil Frame";
	# unlocked by defeating Deus Ex Machina): the ranged summons
	# (RECOIL_PROFILES) fire faster and reach farther (HordeDirector.
	# compute_stats(), after the evolution overlay). Pairs with the Iron
	# Revenant -> Deus Revenant.
	"recoil_frame": {
		"display_name": "Recoil Frame",
		"icon": "recoil_frame",
		"description": "Your ranged summons fire faster and reach farther.",
		"labels": {"ranged_haste": ["Ranged summon attack speed", "pct"], "ranged_reach": ["Ranged summon range", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"ranged_haste": 0.06, "ranged_reach": 0.04},  # TUNING (not in GDD)
			{"ranged_haste": 0.12, "ranged_reach": 0.08},  # TUNING (not in GDD)
			{"ranged_haste": 0.18, "ranged_reach": 0.12},  # TUNING (not in GDD)
			{"ranged_haste": 0.24, "ranged_reach": 0.16},  # TUNING (not in GDD)
			{"ranged_haste": 0.30, "ranged_reach": 0.20},  # TUNING (not in GDD)
		],
	},
	# --- Act IV: the Shores of Ilion ---
	# Paris's Arrow's paired passive (owner-approved Act IV proposal: "Arrow of
	# Fate (+ Mortal Heel)"); unlocked with the spell by Achilles and offered on
	# every stage. Own decision on its effect: every DIRECTED hit (a shot or a
	# blow with an origin) that strikes a foe from BEHIND deals back_damage more
	# (CombatResolver.damage_enemy(), PantheonRules.hit_from_behind(): the one
	# direction test, any enemy's facing), Paris's Arrow's hits included; it
	# rewards the ring that surrounds, the Rogue's dash and the Gargoyle's dive.
	"mortal_heel": {
		"display_name": "Mortal Heel",
		"icon": "mortal_heel",
		"description": "Every hit that strikes a foe from behind deals more.",
		"labels": {"back_damage": ["Damage from behind", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"back_damage": 0.08},  # TUNING (not in GDD)
			{"back_damage": 0.16},  # TUNING (not in GDD)
			{"back_damage": 0.24},  # TUNING (not in GDD)
			{"back_damage": 0.32},  # TUNING (not in GDD)
			{"back_damage": 0.40},  # TUNING (not in GDD)
		],
	},
	# Act IV's counter-passive Bronze Breaker (owner-approved Act IV proposal:
	# "summon hits on shielded fronts deal more"; unlocked by the achievement
	# Heel Found and offered only in Act IV through its card row's "act").
	# Phalanx.breaker_mult() (the foundation's one read,
	# PantheonRulesData.BRONZE_BREAKER / BRONZE_BREAKER_KEY): a summon hit on a
	# locked shield's front (or a Legionary's testudo) deals 1 + front_damage
	# times its share.
	"bronze_breaker": {
		"display_name": "Bronze Breaker",  # Owner-approved proposal
		"icon": "bronze_breaker",
		"description": "Your summons' blows on a locked shield wall's front hit harder.",
		"labels": {"front_damage": ["Summon damage to shield fronts", "pct"]},
		"act": 4,  # Owner-approved: the act's counter-passives are offered only in Act IV (Unlocks.act_allows())
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"front_damage": 0.2},  # TUNING (not in GDD) a front shot 10% -> 12%, a front blow x1.2
			{"front_damage": 0.4},  # TUNING (not in GDD)
			{"front_damage": 0.6},  # TUNING (not in GDD)
			{"front_damage": 0.8},  # TUNING (not in GDD)
			{"front_damage": 1.0},  # TUNING (not in GDD) a front shot 10% -> 20%, a front blow x2
		],
	},
	# --- Act IV: Mount Olympus ---
	# Titan's Blood (owner-approved Act IV proposal: Stolen Thunder's paired
	# passive; unlocked with the spell by slaying Zeus): the blood of the giants
	# the gods buried: Stolen Thunder chains `chain_bonus` more hops and its
	# charge is `charge_cut` shorter (AbilityManager.apply_spell_mods()). Pairs
	# with Stolen Thunder -> Gigantomachy.
	"titans_blood": {
		"display_name": "Titan's Blood",
		"icon": "titans_blood",
		"description": "Your Stolen Thunder charges faster and leaps to more armoured foes.",
		"labels": {"chain_bonus": ["Extra chain hops", "int"], "charge_cut": ["Charge time", "neg_pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"chain_bonus": 0.0, "charge_cut": 0.08},  # TUNING (not in GDD)
			{"chain_bonus": 1.0, "charge_cut": 0.14},  # TUNING (not in GDD)
			{"chain_bonus": 1.0, "charge_cut": 0.2},  # TUNING (not in GDD)
			{"chain_bonus": 2.0, "charge_cut": 0.26},  # TUNING (not in GDD)
			{"chain_bonus": 2.0, "charge_cut": 0.32},  # TUNING (not in GDD)
		],
	},
	# Grounded Bones (owner-approved Act IV proposal: "less lightning and wave
	# damage to the army"; Act IV's counter-passive, offered only in Act IV,
	# unlocked by the achievement Twilight of the Gods): the share of the
	# Wrath of the Gods' lightning and wave damage the necromancer and his army
	# no longer take (DivineWrath.grounded_mult(), the one read, per target
	# slot; PantheonRulesData.GROUNDED_BONES_KEY). The fissures are not cut.
	"grounded_bones": {
		"display_name": "Grounded Bones",
		"icon": "grounded_bones",
		"description": "The gods' lightning and waves hurt you and your dead less.",
		"labels": {"wrath_reduction": ["Lightning and wave damage", "neg_pct"]},
		"act": 4,  # Owner-approved: the act's counter-passives are offered only in Act IV (Unlocks.act_allows())
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"wrath_reduction": 0.1},  # TUNING (not in GDD)
			{"wrath_reduction": 0.2},  # TUNING (not in GDD)
			{"wrath_reduction": 0.3},  # TUNING (not in GDD)
			{"wrath_reduction": 0.4},  # TUNING (not in GDD)
			{"wrath_reduction": 0.5},  # TUNING (not in GDD)
		],
	},
	# --- Act IV: the Asphodel Underworld ---
	# Ferryman's Toll (GDD §15.0 "River Styx, Lethe's Flood, Ferryman's Toll and
	# the Ferrywoman"; unlocked by defeating Hades, UnlockData): every foe slain
	# while SLOWED (any slow: the Styx, Frost Wraiths, Soul Chains, Death Mark...)
	# pays the ferryman: the necromancer heals toll_heal HP (at most
	# RiverStyxData.TOLL_HEAL_CAP_PER_S a second) and the Dread Rally gains
	# toll_rally soul points (CombatResolver._kill_enemy(), the one kill path).
	# Pairs with River Styx -> Lethe's Flood.
	"ferrymans_toll": {
		"display_name": "Ferryman's Toll",
		"icon": "ferrymans_toll",
		"description": "Every slowed foe that dies pays the ferryman: you heal and your Dread Rally fills.",
		"labels": {"toll_heal": ["Heal per slowed kill", "num"], "toll_rally": ["Rally charge per slowed kill", "num"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"toll_heal": 0.2, "toll_rally": 0.2},  # TUNING (not in GDD)
			{"toll_heal": 0.3, "toll_rally": 0.3},  # TUNING (not in GDD)
			{"toll_heal": 0.4, "toll_rally": 0.4},  # TUNING (not in GDD)
			{"toll_heal": 0.5, "toll_rally": 0.5},  # TUNING (not in GDD)
			{"toll_heal": 0.6, "toll_rally": 0.6},  # TUNING (not in GDD)
		],
	},
	# Myrmidon Oath (own decision: the Legion of Tartarus's paired passive, its
	# name and rule; GDD §15.0 "Myrmidon Shades, Legion of Tartarus and Myrmidon
	# Oath"; unlocked by defeating Hades): the front line swears to hold: the
	# blockers on the Bone Ring's outer posts (OATH_CLASSES: Warriors,
	# Abominations, the Bone Golem, the Myrmidon Shades and their evolutions)
	# gain max HP and damage (HordeDirector.compute_stats()). Pairs with the
	# Myrmidon Shades -> Legion of Tartarus.
	"myrmidon_oath": {
		"display_name": "Myrmidon Oath",
		"icon": "myrmidon_oath",
		"description": "Your front-line dead swear to hold: they are hardier and strike harder.",
		"labels": {"front_hp": ["Front-line max HP", "pct"], "front_damage": ["Front-line damage", "pct"]},
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"levels": [
			{"front_hp": 0.06, "front_damage": 0.04},  # TUNING (not in GDD)
			{"front_hp": 0.12, "front_damage": 0.08},  # TUNING (not in GDD)
			{"front_hp": 0.18, "front_damage": 0.12},  # TUNING (not in GDD)
			{"front_hp": 0.24, "front_damage": 0.16},  # TUNING (not in GDD)
			{"front_hp": 0.30, "front_damage": 0.20},  # TUNING (not in GDD)
		],
	},
}
