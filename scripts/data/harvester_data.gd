## HarvesterData — immutable design data of THE HARVESTER, the boss of the Ark
## of the Concord and the finale of Act IX (the Concord of Stars; GDD §15.0
## "The Harvester (Act IX)"; owner-approved proposal docs/act9/PROPOSAL.md
## "Stage 27: The Ark of the Concord (the finale)", with the owner's answers:
## a plain finale, no twist, no epilogue). BossHarvester
## (scripts/enemies/concord/boss_harvester.gd, loaded by name for the boss id
## "harvester") reads BOSS; StageRegistry.BOSS_ARRIVALS and ArkStage.BOSS read
## ARRIVAL. It descends from its throne of rings at 17:00 (3:00 left). The
## oldest of its kind, the one who planted the world: a tall grey, SEX
## UNMARKED as the greys are, floating above a throne of rings (the approved
## concept act9_boss.png). Every beam goes through ConcordBeams.fire() (THE
## beam path, boss override), every lift through Abduction.lift() (THE lift),
## every patch of ground through Terraforming.seed() (THE ground). Three
## phases:
##   THE COUNCIL (100% -> reaping_hp of its health): it floats at the
##        necromancer and fights with the Concord's powers IN TURN, one every
##        council_turn s (the order of COUNCIL_POWERS):
##          THE BROOD'S SWARMS: brood_swarms swarms of brood_count broodlings
##          burst from the ring's edge around the necromancer;
##          THE VRASK'S CLOAK: for cloak_time s it is CLOAKED (the Vrask
##          hunter's rule and numbers, ConcordEnemyData "vrask_hunter"
##          "cloak": drawn as a shimmer, a summon's or a hazard's hit deals
##          cloaked_taken of itself, a spell hit lands in full and reveals it
##          for reveal_time s) and it glides at the necromancer faster
##          (cloak_speed_mult);
##          THE LUMINOUS BEAMS: lumen_beams "sweep" beams fanned at the
##          necromancer (lumen_spread rad apart, the style's numbers with
##          lumen_overrides) and one "eye" beam (eye_overrides).
##   THE REAPING (at reaping_hp): it rises above its throne, immune, and opens
##        a tractor beam over the whole ring: emitters `reap_emitter`
##        structures (ArkEnemyData "reap_emitter", ReapEmitterKit) land
##        emitter_dist px around the necromancer, and each lifts a summon
##        through Abduction.lift() every lift_every s (Abduction.uncapped is set
##        for the phase and cleared after, unless the Final Harvest holds it).
##        A destroyed emitter drops what it holds (the rescue,
##        Abduction.release_all() through ConcordRules.note_gone()); with all
##        of them destroyed (or after reaping_max s) the Reaping ends. Anchored
##        applies as usual (ReapEmitterKit.taken_mult() calls the hook).
##   THE GARDENER (after the Reaping, to the end): it reveals its TRUE FORM, a
##        vast being of light and rings (the sprite TRUE_SPRITE, else a glow
##        of rings over its body), and turns the world below into its weapon:
##        every ring_every s a RING OF LIVE TURF grows around the necromancer
##        (ring_points patches of ring_patch px on a circle ring_radius px out,
##        Terraforming.seed(.., {"live": true, "tag": "gardener"})), and every
##        adds_every s it calls adds (ADDS) that heal on that turf (the shared
##        heal); the necromancer's spells burn it back (the shared burn). It
##        does NOT heal on its own turf (own decision: Terraforming boss_mult
##        stays 0, so the fight always ends). Its luminous beams go on every
##        gardener_beam_every s, and it is faster (gardener_speed_mult).
## Beaten: a short ending text only (ENDING_ANNOUNCE: the stars go dark), no
## epilogue (owner decision Oct 31, 2026 and Nov 3, 2026). THE LAST HARVEST
## (MetaData) records the clear: a boss kill on the Ark (the stage record).
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist) and the abilities' own
## numbers. Damage keys are before the time scaling. The GDD gives no numbers:
## everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal.
class_name HarvesterData
extends RefCounted

## Its arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "harvester" through ArkStage.BOSS, so --boss=harvester and the Codex find
## it). Its script is found by the id (boss_harvester.gd).
const ARRIVAL := {
	"id": "harvester",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "The Harvester",  # Owner-approved proposal
	"short_name": "Harvester",
	"arrive_banner": "The Harvester descends from its throne of rings!",  # TUNING (not in GDD)
	"defeat_banner": "The Harvester falls, and the stars go dark!",  # Owner-approved proposal: "When it falls, the stars go dark too"
	"dead_objective": "The stars are dark. Survive the Final Harvest... you cannot.",  # TUNING (not in GDD)
}
## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["brood_swarm", "vrask_cloak", "luminous_beams", "reaping", "gardener_ring", "gardener_adds"]
## The Council's powers, in the order it takes them (owner-approved proposal:
## "the Brood's swarms, the Vrask's cloak, the Luminous beams").
const COUNCIL_POWERS := ["brood", "vrask", "luminous"]
## Kind id of a Reaping emitter (ArkEnemyData "reap_emitter").
const EMITTER: String = "reap_emitter"
## The Gardener's adds, in turn (shared Concord kinds: they heal on its turf).
const ADDS := ["grey_drone", "broodling", "lumen_sentinel"]
## Damage-source tag of its beams (ConcordBeams; its kind is "boss").
const SRC_BEAM: String = "harvester_beam"
## Sprite key of its art (BossPoseData pose 1: a beam / the tractor).
const SPRITE: String = "bosses/harvester"
## Sprite key of its true form (the Gardener); the base sprite with a glow of
## rings when missing.
const TRUE_SPRITE: String = "bosses/harvester_true"
## Sprite key of a ring of its throne (a grey tint mask, tinted hull white;
## code-drawn discs when missing).
const RING_SPRITE: String = "effects/ark_ring"
## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on its fall (title, line, description): the proposal's
## ending ("When it falls, the stars go dark too"), kept short (no epilogue,
## owner decision Oct 31, 2026; brief Nov 3, 2026: a short ending text only).
const ENDING_ANNOUNCE := ["THE STARS GO DARK", "The Harvester falls.", "The one who planted the world lies among its rings, and one by one the Concord's stars go out over the dead world below."]  # Owner-approved proposal ending (TUNING the words)
## Shorter announcement when it falls after 0:00 (the Final Harvest goes on).
const LATE_ANNOUNCE := ["THE STARS GO DARK", "The Harvester falls.", "Even as the eye sweeps the world, the one who planted it is gone."]  # TUNING (not in GDD)
## The Last Harvest's stat (MetaData "last_harvest": a boss kill on the Ark,
## the stage record; this one counts the kill time for the report).
const KILL_TIME_STAT: String = "harvester_kill_time"
## Its design row.
const BOSS := {
	"display_name": "The Harvester",
	"max_hp": 8500.0,  # TUNING (not in GDD) before the stage / co-op scaling (Paragon 9,000; the Reaping holds it immune for a while)
	"move_speed": 44.0,  # TUNING (not in GDD) px/s, floating on its throne
	"damage": 9.0,  # TUNING (not in GDD) its touch in melee, before the time scaling
	"attack_interval": 1.2,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px (the throne is drawn larger)
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
	"floating": true,  # It floats on its throne of rings: the ground's hazards spare it (the ring still blocks it).
	"reward_xp": 1100,  # TUNING (not in GDD) the act's finale (Paragon 1,000)
	"reward_crystals": 34,  # TUNING (not in GDD)
	"arrive_time": 2.5,  # TUNING (not in GDD) s it descends (invulnerable)
	"advance_range": 380.0,  # TUNING (not in GDD) px beyond which it glides faster
	"advance_speed_mult": 2.0,  # TUNING (not in GDD)
	# The Council.
	"council_first": 3.0,  # TUNING (not in GDD) s before its first power
	"council_turn": 8.0,  # TUNING (not in GDD) s between two powers
	"brood_swarms": 2,  # TUNING (not in GDD) swarms a call
	"brood_count": 10,  # TUNING (not in GDD) broodlings a swarm (the proposal's swarms are 12)
	"cloak_time": 6.0,  # TUNING (not in GDD) s cloaked
	"cloak_speed_mult": 1.6,  # TUNING (not in GDD) faster while cloaked
	"lumen_beams": 3,  # TUNING (not in GDD) sweep beams a call
	"lumen_spread": 0.32,  # TUNING (not in GDD) rad between two sweep beams
	"lumen_overrides": {"length": 340.0, "width": 12.0, "dps": 4.0, "sweep": 30.0},  # TUNING (not in GDD) over BEAM_STYLES "sweep"
	"eye_overrides": {"length": 520.0, "width": 18.0, "dps": 5.0, "hold": 1.8, "sweep": 40.0},  # TUNING (not in GDD) over BEAM_STYLES "eye"
	# The Reaping.
	"reaping_hp": 0.66,  # TUNING (not in GDD) share of its health where the Reaping begins
	"reaping_max": 55.0,  # TUNING (not in GDD) s at most (then the emitters fall silent)
	"emitters": 4,  # Owner-approved proposal: "Four beam emitters around the arena"
	"emitter_dist": 250.0,  # TUNING (not in GDD) px from the necromancer (past the ring)
	"lift_every": 3.0,  # TUNING (not in GDD) s between two lifts of one emitter (a steady rhythm)
	"lift_range": 320.0,  # TUNING (not in GDD) px from an emitter a summon can be picked
	"rise_time": 1.2,  # TUNING (not in GDD) s it rises above its throne (immune throughout)
	# The Gardener.
	"gardener_speed_mult": 1.25,  # TUNING (not in GDD) faster in its true form
	"ring_first": 2.0,  # TUNING (not in GDD) s after the Gardener begins
	"ring_every": 7.0,  # TUNING (not in GDD) s between two rings of turf
	"ring_radius": 190.0,  # TUNING (not in GDD) px from the necromancer
	"ring_points": 8,  # TUNING (not in GDD) patches on the ring
	"ring_patch": 64.0,  # TUNING (not in GDD) px of each patch
	"adds_first": 4.0,  # TUNING (not in GDD) s after the Gardener begins
	"adds_every": 10.0,  # TUNING (not in GDD) s between two calls
	"adds_count": 5,  # TUNING (not in GDD) adds a call
	"gardener_beam_every": 6.0,  # TUNING (not in GDD) s between two luminous beam calls
}
