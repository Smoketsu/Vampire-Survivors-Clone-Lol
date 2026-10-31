## LilithData — immutable design data for LILITH, QUEEN OF THE NIGHT, MOTHER OF
## DEMONS, the boss of the Palace of Silk and Ash (Act VI, Stage 17; GDD §15.0
## "Lilith, Queen of the Night (Act VI)"; owner-approved proposal
## docs/act6/PROPOSAL.md "Stage 17": "charm waves that turn a whole arc of the
## ring for a few seconds, a kiss that marks the necromancer (while marked, every
## heal on him is turned into damage for 5 s), demon children born from her
## wings, and a final phase where she takes her true demon form"; female, the
## approved Act VI figure style at its height, chest and hips covered). BossLilith
## (scripts/enemies/inferno/boss_lilith.gd, loaded by name for the boss id
## "lilith") and LilithHazards read it. Her kit, every part telegraphed:
##   * CHARM WAVE — every wave_cooldown s she raises her hand for wave_cast s:
##     an ARC of the Bone Ring is marked in hearts (the sector of the ring
##     facing her: wave_inner .. wave_outer px from the necromancer,
##     wave_half_angle[phase] degrees each side); then every summon standing in
##     it (at most wave_max[phase], the nearest the arc's middle first) is
##     CHARMED for wave_charm s through the one charm path
##     (HordeDirector.charm() with opts ignore_cap: her waves are not held to
##     Temptation's cap of 3; Faithless shortens them there).
##   * THE KISS — every kiss_cooldown s she blows a kiss at the necromancer (the
##     nearest standing one): a heart flies kiss_speed px/s for kiss_range px.
##     A summon in its way catches it (the ring body-blocks it: the heart
##     breaks harmlessly); if it reaches the necromancer he is MARKED for
##     mark_time s (owner-approved 5 s): while marked, every heal on him is
##     turned into damage (CombatResolver.heal_player(), the one heal path;
##     source KISS_SOURCE).
##   * DEMON CHILDREN — every children_cooldown s she spreads her wings for
##     children_cast s and children_count[phase] of child_kind (the Inferno's
##     imps: her children) are born from her wings, at her sides.
##   * PHASES — below phase2_hp her waves widen and come faster; below phase3_hp
##     she takes her TRUE DEMON FORM (owner-approved): invulnerable for
##     form_time s while she changes, then her demon sprite (DEMON_SPRITE), a
##     bigger body (demon_radius), faster (demon_speed_mult), every cooldown x
##     demon_cd_mult, and THE WING STORM: every storm_cooldown s a circle of
##     storm_radius px around her is telegraphed storm_cast s, then her four
##     wings beat: storm_damage_player / _summon to everything inside, summons
##     thrown storm_push px out.
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, recover_time, advance_range,
## advance_speed_mult) and the abilities' own numbers below. The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal. Data only.
class_name LilithData
extends RefCounted

## Lilith's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "lilith" through SilkPalaceStage.BOSS, so --boss=lilith and the Codex find her).
const ARRIVAL := {
	"id": "lilith",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Lilith, Queen of the Night",  # Owner-approved proposal
	"short_name": "Lilith",
	"arrive_banner": "Lilith, Queen of the Night, Mother of Demons, descends! Keep your dead your own!",  # TUNING (not in GDD)
	"defeat_banner": "Lilith falls, and her court with her! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Lilith is dead. Survive the Last Judgment... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["charm_wave", "kiss", "children", "wing_storm"]
## Sprite key of her art (assets/sprites/bosses/lilith.png).
const SPRITE: String = "bosses/lilith"
## Sprite key of her true demon form (the last phase).
const DEMON_SPRITE: String = "bosses/lilith_demon"
## Damage source tag of a heal turned into damage by her kiss (CombatResolver.heal_player()).
const KISS_SOURCE: String = "lilith_kiss"
## Damage source tag of her wing storm.
const STORM_SOURCE: String = "lilith_wings"
## Temptation "source" of her charm waves (stats charm_by_<source>).
const WAVE_SOURCE: String = "lilith_wave"
## Display name of a summon her wave charmed.
const WAVE_NAME: String = "Lilith's Thrall"  # TUNING (not in GDD)
## Tint of a summon her wave charmed (a deeper pink than a succubus's charm).
const WAVE_TINT := Color(1.0, 0.45, 0.72)  # TUNING (not in GDD) visual
## Share (0..1) of a heal turned into damage while the necromancer is marked
## (owner-approved: "every heal on him is turned into damage").
const HEAL_TO_DAMAGE: float = 1.0  # Owner-approved proposal
## Hearts drawn along each edge of a charm wave's arc (visual only).
const ARC_HEARTS: int = 9  # TUNING (not in GDD) visual
## Seconds the ending banner stays up after her fall.
const ENDING_BANNER_TIME: float = 6.0  # TUNING (not in GDD)

## Lilith's design row.
const BOSS := {
	"display_name": "Lilith, Queen of the Night",
	"max_hp": 10500.0,  # TUNING (not in GDD) x the stage HP multiplier (18,375 on the Palace; Amaterasu 14,000 x 1.65); first pass 12,500 (the army bot died under her true form)
	"move_speed": 52.0,  # TUNING (not in GDD) px/s; a queen's glide
	"damage": 11.0,  # TUNING (not in GDD) a raking claw in reach; first pass 14
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 8.0,  # TUNING (not in GDD)
	"faction": InfernoEnemyData.FACTION,
	"reward_xp": 600,  # TUNING (not in GDD) a step above Kage's 580
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.5,  # TUNING (not in GDD) s she stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this she flies faster
	"advance_speed_mult": 1.6,  # TUNING (not in GDD)
	# Charm wave (owner-approved "charm waves that turn a whole arc of the ring for a few seconds").
	"first_wave": 6.0,  # TUNING (not in GDD) s after she arrives
	"wave_cooldown": 14.0,  # TUNING (not in GDD) s (phase 2 and 3: x wave_cd_mult)
	"wave_cd_mult": 0.8,  # TUNING (not in GDD) from phase 2
	"wave_cast": 1.3,  # TUNING (not in GDD) s the arc is marked
	"wave_inner": 24.0,  # TUNING (not in GDD) px from the necromancer
	"wave_outer": 175.0,  # TUNING (not in GDD) px: past the ring's outer posts (150)
	"wave_half_angle": [45.0, 60.0, 80.0],  # TUNING (not in GDD) degrees each side, phases 1 / 2 / 3
	"wave_max": [5, 6, 8],  # TUNING (not in GDD) summons per wave, phases 1 / 2 / 3
	"wave_charm": 4.0,  # Owner-approved "for a few seconds"; TUNING (not in GDD) the 4 s
	# The kiss (owner-approved "a kiss that marks the necromancer ... for 5 s").
	"first_kiss": 3.0,  # TUNING (not in GDD) s after she arrives
	"kiss_cooldown": 9.0,  # TUNING (not in GDD) s
	"kiss_cast": 0.5,  # TUNING (not in GDD) s she blows it
	"kiss_speed": 230.0,  # TUNING (not in GDD) px/s
	"kiss_range": 460.0,  # TUNING (not in GDD) px it flies
	"kiss_hit": 12.0,  # TUNING (not in GDD) px: it lands on a body this close (+ its radius)
	"mark_time": 5.0,  # Owner-approved proposal: "for 5 s"
	# Demon children (owner-approved "demon children born from her wings").
	"first_children": 9.0,  # TUNING (not in GDD) s after she arrives
	"children_cooldown": 12.0,  # TUNING (not in GDD) s
	"children_cast": 1.0,  # TUNING (not in GDD) s her wings spread
	"children_count": [3, 4, 5],  # TUNING (not in GDD) per birth, phases 1 / 2 / 3
	"child_kind": "imp",  # TUNING (not in GDD) her children are the Inferno's imps (own decision: no new kind)
	"child_spread": 34.0,  # TUNING (not in GDD) px from her wings
	# Phases.
	"phase2_hp": 0.66,  # TUNING (not in GDD) HP share
	"phase3_hp": 0.33,  # TUNING (not in GDD) HP share: her true demon form (owner-approved "a final phase")
	"form_time": 2.5,  # TUNING (not in GDD) s invulnerable while she changes
	"demon_radius": 28.0,  # TUNING (not in GDD) px
	"demon_speed_mult": 1.15,  # TUNING (not in GDD) first pass 1.3
	"demon_cd_mult": 0.75,  # TUNING (not in GDD)
	"demon_damage_mult": 1.15,  # TUNING (not in GDD) her claws in true form; first pass 1.3
	# The wing storm (true form only).
	"storm_cooldown": 8.0,  # TUNING (not in GDD) s
	"storm_cast": 1.0,  # TUNING (not in GDD) s
	"storm_radius": 120.0,  # TUNING (not in GDD) px around her
	"storm_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
	"storm_damage_summon": 14.0,  # TUNING (not in GDD) before the time scaling
	"storm_push": 40.0,  # TUNING (not in GDD) px
	"phase2_banner": "The Queen of the Night smiles: her charm widens!",  # TUNING (not in GDD)
	"phase3_banner": "Lilith casts off her glamour: the Mother of Demons in her TRUE FORM!",  # Owner-approved proposal
}

## The announcement when she falls (title, line, sub-line).
const ENDING_ANNOUNCE := ["THE QUEEN OF THE NIGHT FALLS", "Her court is silent; her children scatter.", "Your dead are your own again."]  # TUNING (not in GDD)
