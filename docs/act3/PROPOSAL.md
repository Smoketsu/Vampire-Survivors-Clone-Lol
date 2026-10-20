# Necropathy: Act III Proposal (The Electronic Empire)

Owner-approved (Oct 19, 2026). This is a copy of the Claude Docs proposal
(https://claude.ai/code/artifact/d3e3ce9a-acfe-4c48-ac85-d2733254af19) after the owner's answers, kept in the repo
so any session can build from it. The owner's answers are at the end.

## Summary

Act III sends the necromancer against **the Electronic Empire**, a machine power that conquered death with steel and
sees an undead army as a rival it must delete. It is the first act where most enemies shoot from far away, so the
army's job changes: your undead become **living cover**, standing in the line of fire so the necromancer can push
into the fortress. It ends in the fortress core against **Deus Ex Machina**, a walking war mech.

| # | Stage | Setting | Its twist | Boss |
| --- | --- | --- | --- | --- |
| 7 | **The Scrap Wastes** | A dead industrial frontier of slag hills and wrecked machines | Signal Pylons extend every enemy's range until you destroy them | Kestrel, the Dead Pixel, a sniper cyborg |
| 8 | **The Assembly Halls** | The Empire's factory, conveyor belts and fabricators | Fabricators build new enemies until you smash them | The Motherboard, a crane-armed construction titan |
| 9 | **The Iron Citadel** | The cyber fortress itself: shield walls, laser grids, the core | The fortress fires on you: orbital strikes and sweeping beams, and shield gates that only open when their generators fall | Deus Ex Machina, the war mech |

**What makes it play differently from Acts I and II**

- **About 60% of enemies attack from range** (Act I is under 20%). Each shot is weaker, but there are far more,
  coming from beyond the screen edge.
- **Line of Fire:** enemy shots stop on the first undead in their path. The Bone Ring, Bone Wall, Warriors,
  Abominations and the Bone Golem become your shield.
- **Lock-On:** elite spotters paint targets with a visible laser before the big shots land, so you can step out of
  the line with Grave Step or put a body in the way.
- **Steel has no soul:** pure machines leave no corpse to raise. Half-flesh cyborgs do, and they rise with their
  weapons still attached.

The rules that every act keeps still hold: enemies always advance (the riflemen fire while marching, nobody kites),
your undead never dodge, and each new spell comes with its playable character. Every female character uses the
figure-redesign style.

## Story and faction

The Electronic Empire fights the necromancer because both have beaten death, and only one kind of immortality can
rule. Far beyond the mountains, its engineers learned to move a mind into a machine. Its citizens never die; they
are rebuilt. To them, an army that rises from graves is a disease in the dataset.

**How it follows Act II:** the Act II epilogue ends with "the holy orders the Covenant once led lighting their
beacons". Act III reveals who else saw them. Nobody called the Electronic Empire: it had watched the realm in
silence from beyond the mountains for centuries, and when the beacons burned across every hilltop it read them as a
realm in collapse, ripe to be taken. Its first act is to wall the realm off and send its legions at the coast where
the dead army gathers.

**The three stages as a march:** the necromancer leads the dead inland across the Scrap Wastes (the Empire's
battlefield graveyard), breaks into the Assembly Halls (where its soldiers are built), and storms the Iron Citadel,
where the Empire's founder lives on inside Deus Ex Machina.

**Tone:** dark fantasy meets cold machinery. The machines are clean, symmetrical and lit in hard amber and red; the
undead are bone, rot and soul-teal. The look comes from that contrast: a horde of skeletons swarming chrome walls.

**The name:** the Electronic Empire (owner's pick), "the Empire" for short.

## The act's shared rules

Three rules carry the long-range gimmick, each built as one code path like Act II's Dread and Claims, and each
switched off on Acts I and II (those stages keep their same-seed results).

**1. Line of Fire: your dead are cover.** Every Empire shot travels as a real projectile and stops on the first
summon in its path. Your necromancer is hit only by shots that find a gap.
- The Bone Ring already circles you, so a full army is a moving shield wall; a thin army leaks.
- Bone Wall segments stop these shots too, and Warder barriers soak them.
- Blockers matter more: Warriors, Abominations and the Bone Golem (whose Bone Bastion keeps the shield wall
  standing) gain a clear job without any act-only summon rule.

**2. Lock-On: the big shots are telegraphed.** Spotter elites paint a target (you or a summon) with a thin red laser
for 1.5 s, then a heavy shot fires down that line.
- Counters: Grave Step out of the line, put a summon in it, or kill the spotter first (spotters glow red and are high
  on every summon's target list).
- Painted lines are drawn clearly and capped (at most 3 at once), so the screen never turns into laser noise.

**3. Steel has no soul: machines leave no corpse.** Pure machines (drones, turrets, mechs) leave nothing to raise.
Cyborgs, which are half flesh, do.
- Effects that raise the dead (Raise Dead, Death Mark's Risen, Grave Tide) work on cyborgs only, about half the
  enemies here.
- The twist: a cyborg raised as your temporary Risen **keeps its weapon** and fires it for you (a "Grave Gunner"),
  the act's one piece of good news.
- Dread Rally's soul meter still charges from every kill, so your ultimate is never starved.

**Numbers the act is built around** (all in data, tuned in the balance pass):

| Measure | Act I | Act III target |
| --- | --- | --- |
| Enemies that attack from range | under 20% | about 60% |
| Typical rifle shot damage | mostly melee | 4-6 per shot |
| Engagement range of the riflemen | mostly melee range | 380-520 px (from just off screen) |
| Painted Lock-On lines at once | none | at most 3 |

**What already counters it:** Grave Step's i-frames, Orb Shield, Bone Wall, Warders, Sovereign's Decree (the
necromancer becomes untargetable) and Eclipse (frozen shooters cannot fire). Act III gives these tools their best
stage, without changing how they work elsewhere.

## Enemy roster

Nine new kinds, built so the long-range pressure always has an answer: shooters stay in the back, shields and
duelists push in front, and every kind still walks toward the necromancer.

| Kind | Tier | Body | Range | What it does | How you beat it |
| --- | --- | --- | --- | --- | --- |
| **Scout Drone** | Fodder | Machine | Short | Fast flying swarms with small zaps; fly over obstacles | Anything: arrows, volleys, Soul Chains |
| **Line Trooper** | Soldier | Cyborg | Long (400 px) | Three-round bursts while marching forward ("marching fire") | Stand behind your army (Line of Fire); rises as a Grave Gunner |
| **Aegis Bot** | Soldier | Machine | Melee | Carries a frontal energy shield that stops your projectiles; walks in front of the troopers | Hit it from the side or above (Rogues, Gargoyles), area spells, stomps |
| **Spotter** | Elite | Cyborg | Very long | Paints a Lock-On line, then fires the heavy rail shot down it | Kill it first, Grave Step out, or block the line |
| **Mortar Walker** | Heavy | Machine | Long, arcing | Lobs shells with a landing circle; arcing shots ignore Line of Fire | Keep moving; Catapults and Gargoyles reach it |
| **Arc Engineer** | Support | Cyborg | Medium | Repairs machines and briefly jams nearby summons (2 s, the existing suppression rule) | Priority target, like the High Confessor |
| **Valkyrie Duelist** | Elite | Cyborg (female, figure-redesign style) | Melee dash | Jet-assisted lunges through your ring toward the necromancer with an arm blade | Blockers stop the lunge (Warriors, Golem); Sovereign's Decree |
| **Sentry Turret** | Structure | Machine | Long | Fixed emplacements behind shield walls; they never move (structures are the one exception to "always advance") | Siege them with Catapults and spells; each drops a Soul Ash bounty |
| **Juggernaut** | Heavy elite | Machine | Short | Armoured flamethrower walker with flat armour, like the Sanctified Sentinel | Armour shred (Wither), Grim Ledger, Siegecraft |

**Each stage also has a miniboss** (one bar on the HUD, a chest when it falls), listed with its stage below.

**The Reckoning of Act III, Purge Protocol:** at 0:00 the sky opens. Orbital strikes rain on telegraphed circles,
faster each minute, while kill-drones pour in from every edge, until the run ends.

## The three stages

Each stage keeps the standard run: 20:00 on the clock, four zones that change with the clock, the boss at 3:00 left,
the Reckoning at 0:00. Act III opens when Vhal'Neth falls; each stage opens the next.

### Stage 7: The Scrap Wastes

The Empire's old battlefield: slag hills, rusting war machines the size of buildings, and red signal masts on the
ridges.
- **Zones:** the Slag Fields (open ground), the Wreck Gullies (narrow paths between fallen titans, good for
  blockers), Pylon Ridge, and the Outer Wall.
- **Signal Pylons:** while a pylon stands, enemies near it fire from 30% farther away. Destroying one (a structure
  with a Soul Ash bounty) shrinks their range in that area for the rest of the run.
- **Scrap storms:** every few minutes a dust storm rolls through and cuts everyone's sight range in half for 20 s, a
  window to close the distance on the shooters.
- **Miniboss, the Trojan Horse:** a four-legged drone tank with missile pods that fire volleys of slow homing rockets
  your summons can intercept. Badly damaged, its hull splits open and a swarm of Scout Drones pours out.
- **Boss, Kestrel, the Dead Pixel:** the Empire's sniper commander, a cyborg markswoman (figure-redesign style) who
  never misses by a single pixel. She jumps between sniper perches, fires triple Lock-On lines, releases decoy
  drones, and in her last phase drops the rifle for twin blades and charges.

### Stage 8: The Assembly Halls

The factory where the Empire builds its soldiers: conveyor floors, robotic arms, sparks and molten metal.
- **Zones:** the Loading Docks, the Conveyor Floor, the Fabricator Hall and the Furnace.
- **Conveyors:** belt lanes carry everyone along at a steady push (one ground rule, like the tide and the ink slows
  of Act II), which drags enemies and your army out of position.
- **Fabricators:** factory structures that build a new enemy every few seconds until you smash them; each one
  destroyed thins the waves for the rest of the run.
- **Furnace channels:** glowing floor strips that burn anything standing in them, enemies included.
- **Miniboss, the Beta Build:** an unfinished mech that keeps patching itself from any fabricator still standing, so
  smashing the fabricators first is the way to kill it.
- **Boss, the Motherboard:** the factory's construction titan, mother of every soldier on the line, with two crane
  arms. It grabs your summons and hurls them, drops press-stamps on telegraphed squares, magnet-pulls the army out of
  the ring, and builds turrets mid-fight.

### Stage 9: The Iron Citadel

The cyber fortress: chrome walls, shield gates and the core at its heart. The arena opens up as you break through.
- **Zones:** the Shield Gates, the Laser Courts, the Spire Lifts and the Core.
- **Shield gates:** energy walls that block the way into each new zone until you destroy their two generators;
  enemies pour out of the gate while it holds.
- **Laser grids:** sweeping beams cross the courts on a fixed rhythm, telegraphed a second before they fire; they
  hurt enemies too.
- **Citadel guns:** the fortress itself fires orbital strikes on telegraphed circles, more often the deeper you go.
- **Miniboss, Valkyrie 2.0:** the upgraded leader of the Valkyrie Duelists, with a jet dash, a shield bash and a
  blade storm.
- **Boss: Deus Ex Machina** (next section).

## The final boss: Deus Ex Machina

Deus Ex Machina is a walking fortress the height of the screen, with the Empire's founder, **Varn, the Root User**,
wired into its core. Like the other bosses it arrives with 3:00 left, and a strong army should bring it down in
about 1-2 minutes.

1. **The Walker (100% to 66% HP).** It strides across the Core on four legs. Each leg carries an armour plate you can
   break separately, like Vhal'Neth's arms.
   - **Chaingun sweep:** a long arc of fire across the arena. Line of Fire applies, so an army standing between you
     and the gun shields you.
   - **Missile salvo:** four Lock-On lines at once, then the rockets.
   - **Stomp:** a shockwave ring under each foot as it lands.
   - Breaking all four plates brings it down to its knees and starts phase 2.
2. **The Siege Core (66% to 33%).** It plants itself and becomes a fortress.
   - **Shield drones** orbit it and make the core immune until they are shot down.
   - **Judgment Lance:** a huge beam that sweeps the arena. Summons standing in the beam take the hit for you, and
     the necromancer is safe behind them.
   - **Hangar doors** open and release Line Troopers and Valkyrie Duelists.
3. **The Founder (33% to 0%).** The core cracks open and Varn's mind takes control of the whole frame for a last
   stand.
   - The mech **overloads**: a pulse rolls out every few seconds, each one stronger, so the fight has a clock.
   - Varn teleports the engine in short bursts and fires everything at once.

**When it falls:** the necromancer reaches into the broken core and finds the one thing the Empire forgot to delete:
Varn's soul. The banner reads **"Nothing is deathless. Everything is mine."** The founder rises as the necromancer's
servant, and his machines go dark across the realm.

**Ending and epilogue:** a third epilogue part, "The Machines Go Dark" (illustrated like Acts I and II), opened by
the Act III achievement, plus a new closing card for whatever comes after. (Owner, wave 2 art review: the existing
Act II closing card `epilogue/close` should be redone with "electronic empire vibes" once the Act III art exists.)

## Rewards

Act III follows Act II's pattern: each boss unlocks a spell that is then offered on every stage, each spell brings
its playable character, the act's counter-passives are offered only in Act III, and the finale grants a summon
class. Everything new stays useful in every act; nothing depends on machines being present.

**Spells** (each with an evolution and a paired passive, like the other twelve)

| Spell | Unlocked by | What it does | Evolution + paired passive |
| --- | --- | --- | --- |
| **Death Ray** | Kestrel, the Dead Pixel | A soul laser fires from the necromancer and sweeps a full circle around you every few seconds, cutting everything in its line out to about 420 px, so it reaches the shooters at range. It moves with you: nothing to stand in (owner: no stand-in-place area spell). Each kill on the beam sparks lightning to one nearby enemy. | **Event Horizon** (two beams sweeping opposite each other; each kill sets off wild chain lightning through up to 4 enemies) + **Conductive Marrow** (a longer, wider beam) |
| **Hollow Puppet** | The Motherboard | Curses the strongest nearby non-boss enemy: for 8 s it fights for you, then dies | **Puppet King** (two puppets, and a puppet that dies explodes) + **Strings of the Dead** |
| **Scrap Swarm** | Deus Ex Machina | A cloud of bone-and-scrap drones orbits **outside the Bone Ring** (about 40 px past its outer edge, so the orbit widens as the army grows; owner: inside the ring it would do nothing) and shoots enemies before they reach your army. | **Deathless Swarm** (more drones; each kill adds one for 10 s) + **Machine Soul** |

**Playable characters** (one innate passive each, a few stat modifiers, unlocked when their spell reaches Lv 5)

| Character | Spell | Innate |
| --- | --- | --- |
| **The Lightning Abbess** (figure-redesign style) | Death Ray | Beam kills spark lightning to one more enemy |
| **The Marionette** (figure-redesign style) | Hollow Puppet | Puppets last 25% longer and hit harder |
| **The Rust Prophet**, an Empire engineer who defected to death | Scrap Swarm | Every temporary Risen you raise fires a scrap bolt every few seconds |

**Summon classes** (offerable on every stage once unlocked; 15 → 17 classes)
- **Grave Drone** (unlocked by the Motherboard): a flying swarm of skull drones, three to a card, that hover over the
  army and fire bone darts. A ranged class that cannot be body-blocked. Evolution **Wraith Drone** + paired passive
  **Overclock**.
- **Iron Revenant** (the finale's reward, from Deus Ex Machina): a reanimated war walker, the army's heavy gunner. It
  holds a back post on the Bone Ring and lays down suppressive fire that slows what it hits. Evolution **Deus
  Revenant** (twin cannons, a missile salvo) + paired passive **Recoil Frame**.

**Counter-passives** (offered only in Act III, unlocked by its achievements)
- **Lead-Lined Bones:** ranged hits on your summons deal less damage.
- **Signal Ghost:** Lock-On lines take longer to paint on the necromancer.

**Achievements**

| Achievement | How you earn it | Reward |
| --- | --- | --- |
| **Static in the Wastes** | Clear the Scrap Wastes | Lead-Lined Bones |
| **Cold Assembly** | Destroy every fabricator in one Assembly Halls run | Signal Ghost |
| **Nothing Is Deathless** | Defeat Deus Ex Machina | The Act III epilogue + title "Breaker of Engines" |

## Art, audio and build plan

**Look.** Two new palette ramps join the game's palette: **chrome** (cold steel greys with a blue cast) for the
machines, and **signal** (hard amber to warning red) for their lights, lasers and screens. Soul-teal stays the
undead's colour and violet stays the player's, so a skeleton never blends into a robot.

**Art list** (true pixel art, reviewed by the owner on a review page at the end, as for Act II)

| Group | Count |
| --- | --- |
| Enemy kinds (still + walk strip) | 9 kinds, 18 images |
| Minibosses and bosses (stills, walk / glide, attack poses) | 6 units, about 20 images |
| Playable characters and their Hyper skins | 6 |
| Summon classes and evolutions (still + walk) | 8 |
| Structures (pylons, fabricators, turrets, shield generators, gates) | about 10 |
| Obstacles per stage, both orientations | about 24 |
| Zone floors (4 per stage) | 12 |
| Effects, projectiles, Lock-On lines | about 14 |
| Icons (spells, evolutions, passives, classes, synergy, achievements) | about 20 |
| Epilogue panels | 4 |

That is about 135 images (Act II's art cost about $2.25 for 104 images, so expect about $3). Since Act II, the
universal skins (Untouchable, Deathlord) exist for every character: the three new characters need those two skins
too (owner rule: drawn art, never a tint).

**Audio.** A new synthesized run loop, **"Iron Requiem"**: a pulsing low synth, metallic hits and a cold arpeggio,
made like "Below the Tide" (a score file, no sound files). New sound effects for rifle bursts, rail shots, servo
steps and orbital strikes, all synthesized.

**Performance.** Act III has many more enemy shots on screen than earlier acts. Shots are pooled data with a hard
cap, Line of Fire checks only the summons near each shot through the existing spatial hash, and phones on Effects:
Reduced draw fewer. Budgets are checked in the Web build on a phone-sized viewport before any stage is marked
playable.

**Build plan** (the way Act II was built):
1. **Foundation:** the faction data, the three shared rules (Line of Fire, Lock-On, Steel has no soul), stage stubs
   behind "Coming soon", the Act III tab on the stage select, palette ramps, the music and the Codex tab. Gate: every
   Act I and Act II stage keeps its same-seed results.
2. **The three stages in parallel**, each with its kinds, events, miniboss, boss, art and achievement; plus the two
   summon classes and the three spells with their characters.
3. **Integration:** merge, balance (each stage a step harder than Ul-Thalos; the army bot should still usually reach
   0:00), the art review page, then the owner playtests. Each stage turns playable only after its multi-seed check
   and the owner's playtest.

## The owner's answers (Oct 19, 2026)

| # | Question | Owner's answer |
| --- | --- | --- |
| 1 | Faction name | "How about this: The Electronic Empire" |
| 2 | Story: the faction answers the beacons? | "I think it's more that they saw them rather than they were directly called" |
| 3 | Three stages? | "Yep" |
| 4 | ~60% ranged enemies, Line of Fire makes the army cover? | "Yeah that works, our Volley system should stop them from being too difficult" |
| 5 | Lock-On telegraphs? | "Yes" |
| 6 | Steel has no soul / Grave Gunners? | "Yes. that's so hype" |
| 7 | Boss names | "Maybe make these names more puns on the machine stuff" (→ Kestrel the Dead Pixel, the Motherboard, Deus Ex Machina / Varn the Root User; minibosses Trojan Horse, Beta Build, Valkyrie 2.0) |
| 8 | Rewards | Fine, with changes: the stand-in-place area spell became Death Ray (a moving laser); Scrap Swarm orbits outside the Bone Ring |
| 9 | Female characters (Kestrel, Valkyrie Duelists, Lightning Abbess, Marionette) in the figure-redesign style | "Hell Yes" |
| 10 | Act III opens when Vhal'Neth falls | "Makes sense to me." |
| 11 | Build order: foundation, then the stages in parallel | "Yep, this works great." |
