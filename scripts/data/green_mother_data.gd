## GreenMotherData — immutable design data for THE GREEN MOTHER, the boss of the
## World-Tree and the campaign's last boss (temporary Act XV, the Turning Year,
## final slot XV; GDD §15.0 "The Green Mother (Act XV phase 2)" and "The Last
## Claim"; owner-approved proposal docs/proposals/LAST_SIX_ACTS.md section XV,
## "Stage 45: The World-Tree": "Boss, the Green Mother (female, figure style, a
## colossal goddess grown from the tree): the Turning, the Burial, the Last
## Claim"). BossGreenMother (scripts/enemies/wild/boss_green_mother.gd, loaded
## by name for the boss id "green_mother") and LastClaim
## (scripts/enemies/wild/last_claim.gd) read it. Art `wild/green_mother`
## (128x144, idle, pose 1 `_cast` while she casts a season, pose 2 `_burial`
## while she buries; docs/year/ART_MANIFEST.md). Her fight (she comes with 3:00
## left; she walks slowly at the nearest necromancer, enemies always advance):
##   * THE TURNING (all fight but a Last Claim slot): every turn_every s she
##     casts the NEXT season (spring, summer, autumn, winter, in turn) through
##     SeasonCycle.set_override(season, now + turn_time), so the arena's own
##     rules follow (the roots, the wildfires, the rot, the snow), and that
##     season's attack: turn_count telegraphed circles (turn_radius px, shown
##     turn_lead s) round the necromancer (one on him), each bursting through
##     WildKit.trample() (the one Wild trample) with its season's effect:
##       spring — the roots: every summon struck is held spring_hold s
##                (SummonedUnit.held_until x Deadwood), the necromancer slowed
##                spring_slow for spring_hold s (WildRules.slow_player());
##       summer — the fire: summer_mult x the damage, and the thickets inside
##                burn (Thickets.burn_at());
##       autumn — the rot: autumn_summon_mult x the damage on summons (the dead
##                rot), and a thicket seed is left (Thickets.plant());
##       winter — the frost: every summon struck is chilled winter_slow for
##                winter_time s (CombatResolver.chill_unit()), the necromancer
##                slowed as much.
##   * THE BURIAL (from burial_from of her HP): every burial_every s she pulls
##     one seeded summon within burial_reach px of a necromancer into the earth:
##     a BURIAL THICKET (WorldTreeEnemyData "burial_thicket", BurialThicketKit)
##     grows over it, holding it (SummonedUnit.held_until) until the ring cuts
##     the thicket down or burial_time s (x Deadwood) pass; at most burial_max
##     stand at once.
##   * THE LAST CLAIM (from LAST_CLAIM claim_from of her HP, once): she
##     remembers every power that ever claimed the dead; LastClaim replays
##     `slots` of the fourteen other acts' signature rules (picked with the
##     run's seeded RNG, each at most once, in a seeded order; owner answer),
##     `slot_time` s each, through each act's ONE existing path. During a slot
##     her Turning and Burial rest (her melee stays); she can be hurt
##     throughout.
## Beaten, she does not die: she sinks into the roots and gives the
## necromancer the one claim left (the short ending text; at 0:00 the FIRST
## SPRING, WildRules.first_spring, instead of Spring Returns). Slaying her
## unlocks Root and Rot with Compost Heart, and the Ossuary Oak with Heartwood
## (UnlockData, boss "green_mother"); the achievement The First Spring.
## Everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal or an owner answer. Tuned for the final slot XV (the hardest).
class_name GreenMotherData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["turning", "burial", "last_claim"]

## Sprite key of her art (assets/sprites/wild/green_mother.png; pose 1
## `green_mother_cast`, pose 2 `green_mother_burial`).
const SPRITE: String = "wild/green_mother"
## Damage tag of the Turning's season bursts.
const TURNING_SOURCE: String = "green_mother_turning"
## Kind id of a burial thicket (WorldTreeEnemyData).
const BURIAL_KIND: String = "burial_thicket"
## Run stat set (1) when she is beaten before 0:00 (the First Spring reads it).
const BEATEN_STAT: String = "green_mother_beaten"
## Seconds the ending line stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The ending text when she is beaten (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE LAST CLAIM", "The Green Mother sinks into the roots.", "She takes your dead back into the soil: they are planted now, and in spring they will rise to you."]  # Owner-approved proposal (the ending); TUNING (not in GDD) the words
## The ending text when she is beaten during Spring Returns.
const LATE_ANNOUNCE := ["THE LAST CLAIM", "The Green Mother sinks as spring returns.", "She gives your dead to the soil, and the soil gives them back to you."]  # TUNING (not in GDD) the words
## Her bloom-and-frost colours (visual only): the bloom half, the frost half.
const BLOOM := Color(0.62, 0.86, 0.48)  # TUNING (not in GDD) visual only
## The frost half of her (visual only).
const FROST := Color(0.86, 0.94, 0.98)  # TUNING (not in GDD) visual only
## Each season's burst colour (index as WildRulesData.SEASON_IDS; visual only).
const SEASON_COLORS: Array[Color] = [Color(0.55, 0.85, 0.42), Color(1.0, 0.55, 0.2), Color(0.78, 0.55, 0.25), Color(0.86, 0.94, 0.98)]  # TUNING (not in GDD) visual only

## The Green Mother's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 8500.0  # TUNING (not in GDD) the campaign's last boss, over the Summer Queen's 8,000: the Last Claim's slots need her alive a while (first pass 11,000: the army bot left her on 1,450 HP at 0:00, seed 7)

## Her row (keys as an EnemyData row, plus her fight's; see the header).
const BOSS := {
	"display_name": "The Green Mother",
	"max_hp": MAX_HP,
	"move_speed": 30.0,  # TUNING (not in GDD) px/s (a colossus grown from the tree: slow)
	"damage": 14.0,  # TUNING (not in GDD) a root-hand in reach, before the time scaling
	"attack_interval": 1.5,  # TUNING (not in GDD) s
	"attack_range": 18.0,  # TUNING (not in GDD) px
	"radius": 34.0,  # TUNING (not in GDD) px (the sprite 128x144)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 30.0,  # TUNING (not in GDD) a colossus
	"faction": WildEnemyData.FACTION,
	"group": "growth",  # The tree's own (the reports).
	"no_bloom": true,  # A boss never heals on living ground.
	"reward_xp": 800,  # TUNING (not in GDD) the campaign's last boss
	"reward_crystals": 30,  # TUNING (not in GDD)
	"slow_resist": 0.6,  # TUNING (not in GDD) like every boss
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this she walks faster
	"advance_speed_mult": 2.2,  # TUNING (not in GDD)
	"arrive_banner": "THE GREEN MOTHER wakes in the World-Tree! The whole year turns in her hands.",  # TUNING (not in GDD)
	"turn_first": 4.0,  # TUNING (not in GDD) s after she arrives
	"turn_every": 13.0,  # TUNING (not in GDD) s between two seasons cast
	"turn_time": 11.0,  # TUNING (not in GDD) s each cast season holds (SeasonCycle.set_override())
	"turn_count": 4,  # TUNING (not in GDD) circles a cast
	"turn_spread": 220.0,  # TUNING (not in GDD) px round the necromancer
	"turn_lead": 1.3,  # TUNING (not in GDD) s a circle shows before it bursts
	"turn_radius": 48.0,  # TUNING (not in GDD) px
	"turn_damage": 6.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"turn_damage_summon": 6.0,  # TUNING (not in GDD) to each summon, before the time scaling
	"spring_hold": 1.4,  # Owner-approved proposal ("spring roots"); TUNING (not in GDD) s x Deadwood
	"spring_slow": 0.6,  # TUNING (not in GDD) 0..1 on the necromancer (Grave Step breaks free)
	"summer_mult": 1.5,  # Owner-approved proposal ("summer fire"); TUNING (not in GDD) x the burst's damage
	"autumn_summon_mult": 1.6,  # Owner-approved proposal ("autumn rot"); TUNING (not in GDD) x the burst's damage on summons
	"autumn_grow": 2.5,  # TUNING (not in GDD) s an autumn burst's thicket seed takes to grow
	"winter_slow": 0.4,  # Owner-approved proposal ("winter frost"); TUNING (not in GDD) 0..1 chill on summons and slow on the necromancer
	"winter_time": 2.5,  # TUNING (not in GDD) s
	"turn_banners": ["She casts SPRING: roots burst from the earth!", "She casts SUMMER: the World-Tree burns!",
		"She casts AUTUMN: the dead rot where they stand!", "She casts WINTER: frost bites your bones!"],  # TUNING (not in GDD) one per season (index as WildRulesData.SEASON_IDS)
	"burial_from": 0.66,  # TUNING (not in GDD) share of her HP from which she buries
	"burial_every": 9.0,  # TUNING (not in GDD) s between two burials
	"burial_reach": 260.0,  # TUNING (not in GDD) px from a necromancer
	"burial_time": 12.0,  # TUNING (not in GDD) s at most a summon stays buried (x Deadwood)
	"burial_max": 3,  # TUNING (not in GDD) burial thickets standing at once
	"burial_banner": "THE BURIAL: the Green Mother pulls your dead into the earth! Cut them free.",  # TUNING (not in GDD)
}

## THE LAST CLAIM (LastClaim; owner answers Nov 2026, GDD §15.0 "Wave 3 owner
## answers": "a random 7 of the 14 acts ... 8 s each, from a third of the Green
## Mother's HP"; the Norse slot is Berserkergang):
##   claim_from  — share of her HP at which it begins (once).
##   slots       — slots replayed (each act at most once, seeded order).
##   slot_time   — s each slot lasts.
##   gap         — s between two slots (her breath).
##   banner      — banner when it begins.
## SLOTS: one row per act, in campaign order (the final slots), each: id (the
## report's and the stats' key, last_claim_<id>), act (its name), banner, and
## its call's numbers ("pulses": slot seconds at which its call fires; the rest
## per slot, documented on the row). Each call goes through that act's ONE
## existing path (LastClaim's header names it).
const LAST_CLAIM := {
	"claim_from": 0.33,  # Owner answer: "from a third of the Green Mother's HP"
	"slots": 7,  # Owner answer: "a random 7 of the 14 acts"
	"slot_time": 8.0,  # Owner answer: "8 s each"
	"gap": 1.0,  # TUNING (not in GDD) s
	"banner": "THE LAST CLAIM: the Green Mother remembers every power that ever claimed the dead!",  # TUNING (not in GDD)
}

## The fourteen slots (see LAST_CLAIM). `kinds` rows are groups for
## EnemyDirector.spawn_formation(); `formation` its shape.
const SLOTS: Array[Dictionary] = [
	# I The Covenant: the march (Act I has no rules object: its kinds' formation is its path).
	{"id": "covenant", "act": "The Covenant", "banner": "THE COVENANT marches again: a shield line advances!", "pulses": [0.0],
		"formation": "line", "groups": [{"kind": "shieldbearer", "count": 4, "elite": false}, {"kind": "halberdier", "count": 3, "elite": false},
			{"kind": "banner_bearer", "count": 1, "elite": false}]},  # Owner-approved proposal ("the Covenant's march"); TUNING (not in GDD) the squad
	# II The Black Tide: a boarding (BoardingParty.launch_boat() needs a deck: off the Black Tide the boarders come through the formation, their CorsairKit bringing the rules).
	{"id": "black_tide", "act": "The Black Tide", "banner": "THE BLACK TIDE boards! Grapplers swarm over the roots!", "pulses": [0.0],
		"formation": "arc", "groups": [{"kind": "grappler", "count": 4, "elite": false}, {"kind": "boatswain", "count": 1, "elite": false}]},  # Owner-approved proposal ("a boarding"); TUNING (not in GDD) the crew
	# III The Sanguine Court: the Blood Moon (BloodMoon.force()), and the werewolves it turns.
	{"id": "sanguine_court", "act": "The Sanguine Court", "banner": "THE SANGUINE COURT: the Blood Moon rises over the tree!", "pulses": [0.0],
		"moon": 8.0, "formation": "ring", "groups": [{"kind": "werewolf", "count": 3, "elite": false}]},  # Owner-approved proposal ("the Blood Moon"); TUNING (not in GDD) s and the pack
	# IV The Last Line: the Wanted stars' top tier as a squad (Escalation has no force call: its kinds' formation).
	{"id": "last_line", "act": "The Last Line", "banner": "THE LAST LINE: five Wanted stars! SWAT and riflemen close in!", "pulses": [0.0],
		"formation": "arc", "groups": [{"kind": "swat_breacher", "count": 3, "elite": false}, {"kind": "rifleman", "count": 4, "elite": false}]},  # Owner-approved proposal ("the Wanted stars"); TUNING (not in GDD) the squad
	# V The Shogunate: the Draw (DrawCuts.draw(), free-standing lines across each necromancer, the boss override).
	{"id": "shogunate", "act": "The Shogunate", "banner": "THE SHOGUNATE: iai lines flash across the roots! Step off them!", "pulses": [0.0, 3.0, 6.0],
		"lines": 2, "flash": 0.9, "length": 420.0},  # Owner-approved proposal ("the Draw"); TUNING (not in GDD) lines a pulse, s, px
	# VI The Hall of the Slain: Berserkergang (NorseRules.enter_fury() on every Wild enemy in reach; owner answer).
	{"id": "hall_of_the_slain", "act": "The Hall of the Slain", "banner": "THE HALL OF THE SLAIN: berserkergang! The Wild goes mad with fury!", "pulses": [0.0, 4.0],
		"reach": 520.0, "most": 24},  # Owner answer: Berserkergang; TUNING (not in GDD) px and enemies a pulse
	# VII The Necropolis Dynasty: Rebirth (Rebirth.on_death() through DynastyRules: only a Dynasty kind carries a Name, so the Dynasty's own dead walk in and rise again).
	{"id": "necropolis_dynasty", "act": "The Necropolis Dynasty", "banner": "THE NECROPOLIS DYNASTY: the wrapped dead walk, and rise again!", "pulses": [0.0],
		"formation": "ring", "groups": [{"kind": "mummy", "count": 5, "elite": false}, {"kind": "mummy_female", "count": 3, "elite": false}]},  # Owner-approved proposal ("Rebirth"); TUNING (not in GDD) the dead
	# VIII The Olympian Republic: the Wrath of the Gods (DivineWrath.strike()).
	{"id": "olympian_republic", "act": "The Olympian Republic", "banner": "THE OLYMPIAN REPUBLIC: the gods' lightning falls on you!", "pulses": [0.0, 4.0],
		"wrath": "lightning"},  # Owner-approved proposal ("the Wrath of the Gods"); TUNING (not in GDD) the kind
	# IX The Inferno: the hell pits (HellPits.open_pit()).
	{"id": "inferno", "act": "The Inferno", "banner": "THE INFERNO: hell pits open round you!", "pulses": [0.0, 4.0],
		"pits": 3, "pit_ring": 110.0, "pit_radius": 44.0, "pit_life": 5.0},  # Owner-approved proposal ("the hell pits"); TUNING (not in GDD) pits a pulse, px, px, s
	# X The Celestial Host: the Judgment (Judgment.send_wave(): the scales stay empty off the Host).
	{"id": "celestial_host", "act": "The Celestial Host", "banner": "THE CELESTIAL HOST: your sins are weighed! A Judge descends!", "pulses": [0.0],
		"judges": 2},  # Owner-approved proposal ("the Judgment"); TUNING (not in GDD) Judges a necromancer
	# XI The Ancient Eye: the Claims (Game.claims_rules(), EyeClaims.mark()).
	{"id": "ancient_eye", "act": "The Ancient Eye", "banner": "THE ANCIENT EYE: she claims your dead! A summon that falls now rises against you!", "pulses": [0.0, 4.0],
		"marks": 5, "thrall_life": 15.0, "tint": Color(0.55, 0.85, 0.5), "name": "Claimed by the Green Mother"},  # Owner-approved proposal ("the Claims"); TUNING (not in GDD) summons a necromancer a pulse, s, the tint
	# XII The Electronic Empire: the Lock-On lines (LockOn.paint(), three at once, the boss override).
	{"id": "electronic_empire", "act": "The Electronic Empire", "banner": "THE ELECTRONIC EMPIRE: three Lock-On lines paint you and yours!", "pulses": [0.0, 4.0],
		"lines": 3, "damage": 12.0, "speed": 620.0, "reach": 900.0, "tag": "lock_on"},  # Owner-approved proposal ("the Lock-On lines"); TUNING (not in GDD) dmg, px/s, px
	# XIII The Concord of Stars: the beams (ConcordBeams.fire(), ownerless beams aimed through each necromancer).
	{"id": "concord", "act": "The Concord of Stars", "banner": "THE CONCORD OF STARS: beams cut the tree! Only Bone Walls stop them!", "pulses": [0.0, 4.0],
		"beams": 2, "style": "sweep", "beam_ring": 240.0, "length": 480.0},  # Owner-approved proposal ("the beams"); TUNING (not in GDD) beams a pulse, px, px
	# XIV The Age of Titans: a stampede (Herds.spawn_herd(), launched at once at the necromancer).
	{"id": "age_of_titans", "act": "The Age of Titans", "banner": "THE AGE OF TITANS: a stampede thunders through the roots!", "pulses": [0.0],
		"herd": 4, "herd_kinds": ["longneck", "duckbill"], "herd_dist": 440.0},  # Owner-approved proposal ("a stampede"); TUNING (not in GDD) beasts, px
]
