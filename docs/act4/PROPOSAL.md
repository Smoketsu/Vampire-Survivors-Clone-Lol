# Necropathy: Acts IV–VI Proposal (Act IV: The Olympian Republic)

Owner-answered (Oct 20, 2026). This is a copy of the Claude Docs proposal "Necropathy: Acts IV–VI Proposal"
(https://claude.ai/artifact/R4bwVB2JHPiDELgtfCTGBg) kept in the repo so any session can build from it. Act IV is
copied in full; Acts V and VI are summarized (the doc has their full text). The owner's answers are at the end.
Concept art: `art_source/concepts/act4_*.png` (prompts beside them).

## The campaign after Act III

Three more acts, nine more stages (10–18), one cultural empire per act. Each act keeps the Act II / III pattern: three
stages, three shared rules built as one code path each, a boss per stage, and a finale that opens an epilogue part.
**Build and ship one act at a time, Act IV first**, and confirm each next act only after the previous one is played.

| Act | Faction | Stages | Its three shared rules | Bosses |
| --- | --- | --- | --- | --- |
| IV | **The Olympian Republic** (Greek gods, Roman legions) | 10 The Shores of Ilion · 11 Mount Olympus · 12 The Asphodel Underworld | Wrath of the Gods · Phalanx · Glory | Achilles, the Unkillable · the Pantheon Trial (Ares, Artemis, Poseidon, then Zeus) · Hades, Lord of the Dead |
| V | The Shogunate of the Rising Sun | 13 The Burning Province · 14 Castle Kurogane · 15 The Road to the Sun | The Sun's Course · The Draw · From the Shadows | Kage · Shogun Kurogane · Amaterasu |
| VI | The Inferno | 16 The Burning Gate · 17 The Palace of Silk and Ash · 18 Pandemonium | Hell Pits · Portals · Temptation | Moloch · Lilith · The Morning Star |

**Story.** The through-line from Act III on: every power that claims the dead comes for the necromancer. Act IV, the
gods of the dead: the necromancer's endless army has emptied the Underworld; Hades complains to Olympus that his
kingdom is a desert, and the gods descend to take the dead back. When Olympus falls, the necromancer goes down to the
Underworld to face the god who started it.

**Closing cards (owner decision):** a closing card after each act's epilogue part names the next enemy without
showing it, the way "The Beacons Burn" set up Act III.

| After | Card | Its line | Sets up |
| --- | --- | --- | --- |
| Act III | The River Runs Dry | Far below the world, the river of the dead has run dry, and its ferryman has no one left to carry. On a mountain of marble, the gods have noticed. | Act IV |
| Act IV | The Sun Still Rises | Olympus is silent and Hades kneels. Only one light still burns against the dead: across the eastern sea, a goddess opens her eyes. | Act V |
| Act V | The Pit Keeps Count | The sun is out, and the night has no end. Far below, the souls owed to the Pit have stopped arriving, and something down there has started counting. | Act VI |
| Act VI | The World Remembers | Heaven, earth and hell answer to the necromancer. Only the world itself is left, and the world remembers how to bury things. | Act VII (concept) |

Epilogue parts: The Gods Are Silent (Act IV), The Sun Goes Out (Act V), The Throne Below (Act VI). In code,
`EpilogueData.CLOSING` becomes one card per act, each with its `after` key.

**Rules every act keeps** (CLAUDE.md, GDD §15.0): the 20:00 clock with the stage boss at 3:00 left and a Reckoning
at 0:00; enemies always advance; undead never dodge; the Bone Ring is the only formation; **summons never get act-only
rules**; each boss unlocks a spell that comes with its playable character; each act has counter-passives offered only
in that act; the finale grants a summon class and opens an epilogue part; every female character uses the
figure-redesign style. **One code path per act, switched by a stage key**, like Act II's `eye` and Act III's
`empire`: `pantheon` (Act IV), read through one `game.pantheon` object that stays null on every other act. Acts I–III
keep their same-seed autotest summaries, the gate every phase must pass.

## Act IV: The Olympian Republic

Greek gods command Roman discipline: bronze hoplites and legions in the field, demigods leading them, monsters loosed
from the myths, and the gods themselves striking the battlefield from above. The look is **bronze, marble, Aegean
blue and gold** against the undead's bone and soul-teal. What changes for the player: the arena itself is the enemy;
you lure the hosts into the gods' hazards and break shield walls from the flanks.

### Shared rules

1. **Wrath of the Gods** (the owner's idea, the headline). Each stage has a patron god whose hazard strikes the arena
   on a telegraphed rhythm, and **it hits both armies**. One scheduler, `DivineWrath`, one hazard kind per stage:
   - **Poseidon's waves** (Ilion): a wall of water rolls across the arena from one edge every 90 s, shown 3 s ahead
     as a foam line. It pushes everyone it crosses about 140 px and drowns fodder. The ring re-forms afterwards.
   - **Zeus's lightning** (Olympus): bolts on marked circles, 1.2 s warning. Bronze armour draws them: a strike chains
     to bronze-clad enemies nearby, so luring a phalanx under the storm is the counterplay.
   - **Hades' fissures** (Underworld): cracks open along telegraphed red lines, burn whoever stands on them, and
     swallow corpses (no raising there). An open fissure spits pale shades for a few seconds.
2. **Phalanx.** Hoplites and legionaries that stand shoulder to shoulder (3+ within 28 px, facing the same way) lock
   shields: their front stops projectiles and knockback, and the wall advances as one. Attacks from the side or behind
   break it. Rogues, Gargoyles, Bone Hounds, stomps and arcing shots finally have a front-line enemy built for them,
   with no act-only summon rule.
3. **Glory.** Named demigod elites (Heroes) gain a Glory stack for every summon they kill: +10% damage and size per
   stack, up to 10, with a growing gold aura. A Hero killed at high Glory drops a bigger Soul Ash bounty and, at 5+
   stacks, a chest. It rewards killing heroes early, and lets a greedy player farm them late.

### Roster

| Kind | Tier | What it does | How you beat it |
| --- | --- | --- | --- |
| Shade of the Dead | Fodder | Pale ghosts fleeing the Underworld; weak, fast, in swarms | Anything |
| Hoplite | Soldier | Spear and round shield; forms the Phalanx | Flank it; area damage |
| Legionary | Soldier | Scutum and gladius; locks the testudo against arrows and volleys from above | Melee and stomps |
| Wolf of Rome | Fodder pack | Bronze wolves in packs of 5, fast lunges | Blockers in the ring |
| Centaur Archer | Ranged | Fires while galloping toward you (no kiting) | Kill it on approach; Line of Fire is Act III only |
| Amazon | Elite | Axe and crescent shield; leaps over the first row of the ring | Warriors, the Golem |
| Gorgon | Elite | A petrifying gaze cone: summons in it turn to stone for 3 s (one stun path) | Kill it first, or Grave Step out of the cone |
| Cyclops | Heavy | Throws boulders with a landing circle; flat armour | Wither, Siegecraft |
| Hero (demigod) | Elite | Carries Glory; named variants (Ajax, Hector, Atalanta) | Kill early |

**Reckoning, the Twilight of the Gods:** at 0:00 the sky splits; lightning, waves and fissures fire together and
faster each minute, while bronze Titans step out of the ground.

### Stage 10: The Shores of Ilion

The beach below a besieged city: beached warships, a siege camp, and the great walls of Troy.
- Zones: the Beachhead, the Siege Camp, the Scaean Gate, the Walls.
- Siege towers roll toward the walls; destroying one spills its soldiers and pays a bounty (Ilion's set piece instead
  of a Trojan Horse, a name Act III's miniboss already uses).
- Miniboss, Polyphemus the Cyclops.
- Boss, **Achilles, the Unkillable.** Hits to his front deal 10%; hits from behind (or to his heel: a gold mark under
  him) deal full damage and stagger him. The Bone Ring surrounding him is the answer, and Rogue dashes and Gargoyle
  dives shine. Phases: the duel, the Myrmidon charge (he summons his guard), the rage after Patroclus (a fast, wild
  last phase).

### Stage 11: Mount Olympus, the Pantheon Trial (the owner's boss rush)

The stage climbs the mountain under Zeus's storm, and each zone has its god.

| Clock left | God | Short kit |
| --- | --- | --- |
| 14:00 | Ares | War-cry buffs every enemy on screen; charges with a spear; dies to blockers |
| 9:30 | Artemis (figure-redesign style) | Volleys of moonlit arrows and her hunting hounds; teleports between groves |
| 6:00 | Poseidon | Floods half the arena, trident throws, a sea serpent |
| 3:00 | Zeus (stage boss) | Lightning storms, the thunderbolt beam, and in phase 3 he takes his true colossal form |

Each of the first three gods has about a third of a normal stage boss's HP and leaves a chest; Zeus arrives on the
usual schedule. (Owner decision: the trial is stage 11 and Hades is the act's final boss.)

### Stage 12: The Asphodel Underworld (the finale)

With Olympus silent, the necromancer goes down to the god who started it all: grey fields of asphodel, the River
Styx, Charon's ferry and the gates of Tartarus.
- Zones: the Asphodel Fields, the Styx Crossing, the Judges' Hall, the Throne of Hades.
- The Styx: a river band that slows the living and makes summons forget (a summon wading it is suppressed for 2 s,
  through the existing `add_suppression()` path).
- Miniboss, Cerberus: three heads, three attacks, and each head must be killed on its own.
- Boss, **Hades, Lord of the Dead**, the first rival necromancer, in three phases: the Helm of Darkness (invisible
  except for his footprints in the asphodel; his fissures open under the ring); the Reclaiming (he marks your summons
  and turns them into his shades for 10 s, the Claims path from Act II, and raises the gods you killed on Olympus as
  shades for one attack each); Lord of the Dead (he raises his own ring of the dead around himself, army against army,
  until his ring breaks). Beaten, he does not die: he kneels and gives up his crown.

### Rewards

| Boss | Spell (paired passive) | Its character |
| --- | --- | --- |
| Achilles | Paris's Arrow: a spectral arrow that always strikes its target from behind (full damage through phalanx fronts) → Arrow of Fate (+ Mortal Heel) | The Doomed Prophetess, a dead seer of Troy (figure style) |
| Hades | River Styx: a black river line that drains and slows whatever crosses it → Lethe's Flood (+ Ferryman's Toll) | The Ferrywoman, Charon's daughter (figure style) |
| Zeus | Stolen Thunder: a charged bolt on the strongest enemy that chains to armoured foes → Gigantomachy (+ Titan's Blood) | The Oathbreaker, a fallen demigod |

- Finale summon class: the **Myrmidon Shades**, undead hoplites that fight as a three-shield phalanx on the ring
  (evolution Legion of Tartarus).
- Counter-passives (Act IV only): **Grounded Bones** (less lightning and wave damage to the army), **Bronze Breaker**
  (summon hits on shielded fronts deal more).
- Achievements: Heel Found (kill Achilles from behind only), Empty Throne (beat Hades; opens the Act IV epilogue),
  Twilight of the Gods (clear the Pantheon Trial).

### Engineering to plan for

Three new palette ramps (bronze, marble and Aegean); a stage select with more act tabs (it fits at 1280 × 600 if each
tab is shorter); no shader may read the screen on the web build.

## The owner's answers (Oct 20, 2026)

1. **Order and pace:** "We're only in the planning stage, this will take a few weeks of rollout." Act IV is built
   first; V and VI are confirmed after it is played.
2. **Act IV finale:** "I want pantheon trial as stage 11 and hades as the final boss for the arc."
3. **Act V mechanic:** "I really like sun's course, maybe we can do seasons next?" (seasons became the Act VII concept).
4. **The Shogun:** "Yeah that's perfect, give him Iai style slashes and stuff."
5. **Act VI limit:** "Go up to the limit of how suggestive you can make it" (no nudity, nothing explicit).
6. **Soldiers' sex:** "Can I see V1 again? I need to see which ones look better." **Resolved (art review round 1, Oct 25): the mixed lineup** ("No the above approach is better"):
   Act IV art uses the mixed roster of the second lineup (`act4_lineup.png`): male hoplites and legionaries, the
   female kinds (Amazon, Gorgon, Atalanta, Artemis) in the figure-redesign style.
7. **Names:** "Let's do The Olympian Republic" (was the Olympian Imperium); the other names are kept.
8. **Story hooks:** "Yes that sounds great. Let's tie everything together nicely." (the closing cards above).
9. Later, on starting the build: "Implement act 4 ... build out the foundational code necessary before phase 2."
