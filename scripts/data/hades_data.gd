## HadesData — immutable design data for HADES, LORD OF THE DEAD, the boss of
## the Asphodel Underworld and of Act IV (Stage 12; GDD §15.0 "The Asphodel
## Underworld (Act IV phase 2)"; owner-approved proposal docs/act4/PROPOSAL.md:
## "the first rival necromancer, in three phases"). BossHades
## (scripts/enemies/pantheon/boss_hades.gd, loaded by name for the boss id
## "hades") reads BOSS; StageRegistry.BOSS_ARRIVALS and UnderworldStage.BOSS read
## ARRIVAL. Three phases:
##   The Helm of Darkness (100% -> reclaim_hp): "invisible except for his
##                  footprints in the asphodel; his fissures open under the
##                  ring". He CLOAKS for cloak_time s (untargetable: out of the
##                  enemy spatial hash, drawn only as a faint shimmer; his
##                  footprints appear on the ground every footprint_every s) and
##                  opens ring_fissures fissures across the Bone Ring around the
##                  necromancer; then he is REVEALED for reveal_time s, sweeping
##                  his bident (a telegraphed cone) and open to every blow. His
##                  HP never falls below reclaim_hp while this phase runs.
##   The Reclaiming (reclaim_hp -> lord_hp): "he marks your summons and turns
##                  them into his shades for 10 s (the Claims path from Act II),
##                  and raises the gods you killed on Olympus as shades for one
##                  attack each". Every reclaim_interval s he marks the
##                  reclaim_marks summons nearest him (mark_time s of a pale
##                  sigil over each); a summon still marked when it resolves is
##                  TAKEN: it falls and rises at once as his shade (EyeClaims,
##                  the Act II Claims path: a hostile Drowned Thrall wearing the
##                  summon's sprite, tinted pale, for shade_life s; killed, its
##                  soul is Dread Rally charge). Every god_interval s the next
##                  god of GOD_SHADES rises as a shade near the necromancer for
##                  one attack (below). He keeps sweeping his bident.
##   Lord of the Dead (lord_hp -> 0): "he raises his own ring of the dead around
##                  himself, army against army, until his ring breaks". He
##                  raises ring_count Tartarus Wardens (UnderworldEnemyData)
##                  holding posts ring_radius px around him; while at least
##                  ring_hold stand he takes ring_damage_taken. When fewer
##                  stand, the RING BREAKS: he staggers broken_time s taking
##                  broken_damage_taken, then raises a new ring after
##                  reraise_time s more. Fissures open under the necromancer's
##                  ring every lord_fissure_interval s.
## Beaten, he does not die: he KNEELS and gives up his crown (the ending line
## ARRIVAL defeat_banner and ENDING_ANNOUNCE, like Vhal'Neth's and Deus Ex
## Machina's endings; the kneeling figure stays kneel_time s).
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist) and the abilities' own numbers.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name HadesData
extends RefCounted

## Hades' arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "hades" through UnderworldStage.BOSS, so --boss=hades and the Codex find him).
## The defeat banner is the ending line.
const ARRIVAL := {
	"id": "hades",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Hades, Lord of the Dead",  # Owner-approved proposal
	"short_name": "Hades",
	"arrive_banner": "Hades, Lord of the Dead, rises from his throne: the dead are his!",  # TUNING (not in GDD)
	"defeat_banner": "Hades kneels and gives up his crown. The dead have one master.",  # Owner-approved proposal ("he kneels and gives up his crown")
	"dead_objective": "The Lord of the Dead kneels. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["cloak", "bident", "reclaim", "god_shade", "ring", "fissures"]

## The Olympus gods Hades raises as shades in the Reclaiming, one attack each,
## in this order (owner-approved proposal: "raises the gods you killed on
## Olympus as shades"). Keyed on the boss / miniboss ids the Mount Olympus agent
## builds in parallel (`ares`, `artemis`, `poseidon`, `zeus`); THE ONE LIST the
## lead wires at the merge. Own decision: every god of the trial rises in turn
## (the Underworld is opened by toppling Zeus, and the Meta save is never read
## in a run, so co-op stays deterministic). Each row:
##   id        the god's id on Olympus (its Codex / boss id).
##   name      shown on the banner.
##   sprites   art keys tried in order (the first that exists is drawn as a pale
##             shade); none = the generic shade glyph, scaled up (degrades
##             gracefully when a god's art is absent).
##   attack    the shade's one attack: "charge" (a telegraphed lane through
##             the necromancer, Ares' spear), "volley" (a telegraphed cone of
##             moonlit arrows from the shade, Artemis), "wave" (a Wrath of the
##             Gods wave, Poseidon) or "lightning" (a Wrath of the Gods bolt
##             salvo, Zeus). The last two go through DivineWrath (the one wrath path).
const GOD_SHADES := [
	{"id": "ares", "name": "Ares", "sprites": ["bosses/ares", "pantheon/ares"], "attack": "charge"},  # Owner-approved proposal: the trial's gods
	{"id": "artemis", "name": "Artemis", "sprites": ["bosses/artemis", "pantheon/artemis"], "attack": "volley"},
	{"id": "poseidon", "name": "Poseidon", "sprites": ["bosses/poseidon", "pantheon/poseidon"], "attack": "wave"},
	{"id": "zeus", "name": "Zeus", "sprites": ["bosses/zeus", "pantheon/zeus"], "attack": "lightning"},
]

## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on his defeat (title, line, description): the proposal's
## ending ("Beaten, he does not die: he kneels and gives up his crown").
const ENDING_ANNOUNCE := ["THE THRONE IS EMPTY", "Hades kneels.", "The Lord of the Dead sets his crown at your feet. Olympus is silent, the Underworld is yours, and every soul it held answers to you now."]  # Owner-approved proposal ending
## Shorter announcement when he falls after 0:00 (the Twilight rages on).
const LATE_ANNOUNCE := ["THE LORD OF THE DEAD KNEELS", "Hades kneels.", "Even as the sky splits, his crown is yours."]  # TUNING (not in GDD)
## Pale shade tint (multiply, RGBA 0..1) of the summons he takes and of the gods'
## shades (marble and Aegean, a ghost's colours; never the undead's teal).
const SHADE_TINT := Color(0.62, 0.72, 0.90, 0.85)  # TUNING (not in GDD)
## Display name of a summon he took.
const SHADE_NAME: String = "Shade of Hades"  # TUNING (not in GDD)

## Hades' design row.
const BOSS := {
	"display_name": "Hades, Lord of the Dead",
	"max_hp": 16000.0,  # TUNING (not in GDD) x the stage HP multiplier (24,000 on the Underworld; Deus Ex Machina 21,600): he hides in the Helm and hides behind his ring, so he carries the Citadel's finale HP
	"move_speed": 50.0,  # TUNING (not in GDD) px/s
	"damage": 13.0,  # TUNING (not in GDD) a bident thrust in melee reach
	"attack_interval": 1.2,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px; a tall god (drawn bigger)
	"armor": 0.2,  # TUNING (not in GDD) dark bronze
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 30.0,  # TUNING (not in GDD) a god shoves the dead aside
	"faction": PantheonEnemyData.FACTION,
	"reward_xp": 760,  # TUNING (not in GDD) Act IV's last boss: more than Deus Ex Machina's 700
	"reward_crystals": 32,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"arrive_time": 2.0,  # TUNING (not in GDD) s he rises from the ground (invulnerable)
	"change_time": 1.6,  # TUNING (not in GDD) s between two phases (invulnerable)
	"advance_range": 380.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phase thresholds (share of max HP).
	"reclaim_hp": 0.66,  # TUNING (not in GDD) the Reclaiming begins
	"lord_hp": 0.33,  # TUNING (not in GDD) Lord of the Dead begins
	# The bident sweep (every phase): a telegraphed cone in front of him.
	"bident_cooldown": 4.5,  # TUNING (not in GDD) s
	"bident_range": 96.0,  # TUNING (not in GDD) px cone length
	"bident_half_arc": 0.7,  # TUNING (not in GDD) rad each side
	"bident_telegraph": 0.6,  # TUNING (not in GDD) s
	"bident_trigger": 120.0,  # TUNING (not in GDD) px; he sweeps when the necromancer or 3+ summons are this close
	"bident_damage_player": 14.0,  # TUNING (not in GDD) before the time scaling
	"bident_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling
	"bident_knockback": 50.0,  # TUNING (not in GDD) px summons are thrown back
	# The Helm of Darkness (phase 1).
	"cloak_time": 4.0,  # TUNING (not in GDD) s cloaked (untargetable)
	"reveal_time": 5.0,  # TUNING (not in GDD) s revealed (open to every blow)
	"cloak_speed_mult": 1.35,  # TUNING (not in GDD) he walks faster unseen
	"footprint_every": 0.35,  # TUNING (not in GDD) s between two footprints while cloaked
	"footprint_life": 2.4,  # TUNING (not in GDD) s a footprint stays on the ground (visual only)
	"ring_fissures": 3,  # Owner-approved proposal "his fissures open under the ring"; TUNING (not in GDD) count
	"ring_fissure_length": 150.0,  # TUNING (not in GDD) px, across the ring (the wrath's own width, burn and spit)
	"ring_fissure_offset": 20.0,  # TUNING (not in GDD) px added to the Bone Ring's radius for the cracks' centres
	# The Reclaiming (phase 2).
	"reclaim_interval": 9.0,  # TUNING (not in GDD) s between two marks
	"reclaim_first": 2.0,  # TUNING (not in GDD) s into the phase
	"reclaim_marks": 3,  # TUNING (not in GDD) summons marked each time (the nearest to him)
	"reclaim_reach": 320.0,  # TUNING (not in GDD) px he looks for summons to mark
	"mark_time": 2.0,  # TUNING (not in GDD) s the sigil shows before the summon is taken
	"shade_life": 10.0,  # Owner-approved proposal: "turns them into his shades for 10 s"
	"god_interval": 11.0,  # TUNING (not in GDD) s between two god shades
	"god_first": 5.0,  # TUNING (not in GDD) s into the phase
	"god_telegraph": 1.4,  # TUNING (not in GDD) s the shade gathers before its attack
	"god_fade": 1.2,  # TUNING (not in GDD) s it lingers after its attack (visual only)
	"god_distance": 220.0,  # TUNING (not in GDD) px from the necromancer the shade rises
	"charge_length": 480.0,  # TUNING (not in GDD) px, Ares' lane (through the necromancer)
	"charge_width": 40.0,  # TUNING (not in GDD) px
	"charge_damage_player": 16.0,  # TUNING (not in GDD) before the time scaling
	"charge_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling
	"volley_range": 360.0,  # TUNING (not in GDD) px, Artemis's cone
	"volley_half_arc": 0.32,  # TUNING (not in GDD) rad each side
	"volley_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
	"volley_damage_summon": 8.0,  # TUNING (not in GDD) before the time scaling
	# Lord of the Dead (phase 3).
	"ring_count": 10,  # TUNING (not in GDD) Tartarus Wardens in his ring
	"ring_radius": 64.0,  # TUNING (not in GDD) px around him
	"ring_hold": 4,  # TUNING (not in GDD) the ring holds while this many stand
	"ring_damage_taken": 0.25,  # TUNING (not in GDD) damage share he takes behind a standing ring
	"broken_time": 8.0,  # TUNING (not in GDD) s he staggers once the ring breaks
	"broken_damage_taken": 1.3,  # TUNING (not in GDD) damage share while staggered
	"reraise_time": 6.0,  # TUNING (not in GDD) s after the stagger before the next ring
	"ring_warden_hp": 1.0,  # TUNING (not in GDD) x the Warden row's HP (x the time scaling)
	"warden_slack": 16.0,  # TUNING (not in GDD) px a Warden may stray from its post before it walks back (TartarusWardenKit)
	"warden_return_mult": 1.5,  # TUNING (not in GDD) x its pace while it returns to its post
	"lord_fissure_interval": 10.0,  # TUNING (not in GDD) s
	"lord_speed_mult": 0.7,  # TUNING (not in GDD) he advances slowly with his ring
	# The ending.
	"kneel_time": 14.0,  # TUNING (not in GDD) s the kneeling figure stays (visual only)
}
