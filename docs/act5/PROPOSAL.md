# Necropathy: Act V Proposal (The Shogunate of the Rising Sun)

Owner-approved. This is a copy of the Act V part of the Claude Docs proposal "Necropathy: Acts IV–IX Proposal"
(https://claude.ai/artifact/R4bwVB2JHPiDELgtfCTGBg), kept in the repo so any session can build from it, plus the
owner's answers that bear on Act V. The campaign rules every act keeps, the closing-card chain and the Act IV
precedent are in `docs/act4/PROPOSAL.md`. Concept art: `art_source/concepts/act5_*.png` (prompts beside them).

**Start:** after Act IV went live (Oct 25, 2026), the owner: "I want you to use a similar plan to tackle act 5"
(the Act IV plan: foundation, then three stages in parallel, an art review, bot playtest passes, ship).

## The owner's answers that bear on Act V (Oct 20, 2026)
- **Act V mechanic:** "I really like sun's course, maybe we can do seasons next?" (Seasons became the Act X concept.)
- **The Shogun:** a health bar of soldiers, fighting in person only below 10%: "Yeah that's perfect, give him Iai
  style slashes and stuff."
- **Soldiers' sex:** resolved in the Act IV art review: the **mixed lineup** of the second concept lineups (male
  soldiers; the female kinds in the figure-redesign style). For Act V: `act5_lineup.png`.
- **Names:** "the Shogunate of the Rising Sun", "Shogun Kurogane" and "Kage" kept.
- **Story hooks:** closing cards tie the acts together. Act IV's card "The Sun Still Rises" sets Act V up. Act V's
  epilogue part is **The Sun Goes Out**, and its card **The Pit Keeps Count** ("The sun is out, and the night has no
  end. Far below, the souls owed to the Pit have stopped arriving, and something down there has started counting.")
  sets up Act VI.
- Story line: with Olympus fallen, there is no more day for the dead to fear but one. Across the eastern sea a Shogun
  rules in the name of the sun goddess, and she has seen the night spreading west. His armies sail to burn it out.
- Engineering: the day-and-night lighting as an overlay rect (no shader may read the screen on the Web build), and a
  phone check of the night darkness, which must stay readable on a small screen.

## Act V: The Shogunate of the Rising Sun
A warrior nation ruled in the sun goddess's name: disciplined samurai and ashigaru by day, ninja in the shadows, and when night falls, the oni and yokai of the old stories. The look is lacquer red and black, steel, indigo and sakura pink, with gold for the sun.

### The mechanic you were stuck on: the Sun's Course (recommended)
Amaterasu's moving sun is the strongest idea in this act, so the act rule grows out of it. Every Act V run goes from dawn to night on the 20:00 clock, one SunCourse path reading the clock:
| Clock left | Time of day | What changes |
|---|---|---|
| 20:00–13:00 | Day | The Shogunate's soldiers: disciplined squads, samurai duelists, arquebus lines. Clear light. |
| 13:00–7:00 | Dusk | Long shadows; the light turns orange. Ninja ambushes begin. |
| 7:00–0:00 | Night | Darkness beyond a lantern radius; oni and yokai (kitsune, onryō, kappa) join the soldiers; stone lanterns on the map light pools you can fight in. |
| Reckoning | The Endless Night | The sun never rises: every yokai at once, faster each minute. |
It changes the feel of a run halfway through without any new button, it gives each stage two moods for the art, and Amaterasu's boss fight literally is the sun crossing the sky. The two other rules are kits that live inside it:
2. The Draw (iaijutsu). Samurai elites stop, hand on the hilt, and a thin white line flashes from them for 0.8 s; then one cut hits every body on the line (summons or the necromancer). It is the melee cousin of Act III's Lock-On: Grave Step out, or let a Warrior take it. At most 3 lines at once.
3. From the Shadows. Ninja squads do not walk in from the edge: they appear out of obstacle shadows near the necromancer, sometimes inside the Bone Ring, after a 1 s smoke puff. Lanterns and light (the necromancer's spells, lit lanterns at night) show the puff earlier. It is the one exception to "enemies walk in from the edge"; they still advance once they appear.
Alternatives if you want something else: Honour duels (a champion challenges and a ring closes around him and one summon until one falls) or Seasons (each stage is a season: blossom storms, rain, snow). Both are weaker fits with the Amaterasu fight.

### Roster
| Kind | Tier | What it does | How you beat it |
|---|---|---|---|
| Ashigaru | Fodder | Spear levies in wide ranks | Anything |
| Samurai | Soldier | Katana duelist; uses the Draw as an elite | Blockers, Grave Step |
| Teppo Gunner | Ranged | Arquebus volleys in a line every 6 s; a long reload while still advancing | Rush the reload |
| Ninja | Soldier | From the Shadows; shuriken, then dagger | Keep blockers inside the ring |
| Kunoichi | Elite (figure style) | Smoke bombs that blind summons 2 s, a lunge at the necromancer | Kill on appear; Sovereign's Decree |
| Oni | Heavy (night) | Iron kanabō: a smash that stuns summons; flat armour | Wither, Siegecraft |
| Kitsune | Support (night, figure style) | Fox-fire illusions: decoy enemies your summons waste attacks on | Area damage reveals them |
| Onryō | Fodder (night) | Vengeful ghosts that drift through walls and the ring | Mages, Banshees |
| Hatamoto | Elite | Banner guard; nearby soldiers fight harder while he stands | Kill the banner |

### Stage 13: The Burning Province
Rice terraces, bamboo groves, a village in flames; the war has reached the countryside.


Zones: the Paddies (water slows everyone), the Bamboo Grove (dense obstacles, ninja heaven), the Burning Village, the Mountain Shrine.

Miniboss, Shuten-dōji, the Oni King (night only): drunk, enormous, throws sake barrels that burst into fire.

Boss, Kage, Mistress of the Hidden Hand (figure style): the ninja grandmaster. Splits into shadow clones (only one is real, revealed by light), plants smoke fields, and throws chained kunai that pull a summon out of the ring.

### Stage 14: Castle Kurogane
The Shogun's fortress: stone walls, gates, courtyards and the keep.


Zones: the Outer Bailey, the Gatehouse, the Courtyards, the Keep.

Miniboss, the General of the Left: a mounted samurai who charges through the ring.

Boss, Shogun Kurogane: his army is his health bar (your idea). He never enters the fight at first: he stands on a command platform, signalling with a war fan. His bar is the number of soldiers he has left (for example 600 in six regiments, each with its own banner colour), and every Shogunate kill takes a point off it. Each regiment arrives with a different order (an arquebus line, a spear wall, a cavalry charge, a ninja ambush, a samurai duel squad). Killing a regiment's Hatamoto breaks it: the rest flee and count as lost. Under 10% he draws his own blade and comes down with his honour guard for a short final duel, fought with iai slashes (owner): every draw-cut is a white line flashed across the arena, they come faster as his guard falls, and his last move is a triple cut of three lines at once. His samurai use the same Draw all fight long, so the duel is the act's rule at its peak.

### Stage 15: The Road to the Sun
A pilgrim road of torii gates climbing to the sun goddess's shrine above the clouds.


Zones: the Torii Road, the Sacred Forest, the Shrine Steps, the High Plain of Heaven.

Miniboss, the Kirin (a holy beast of light).

Boss, Amaterasu (figure style). Her place in the sky is the phase, as you described:


East (dawn): she rises on the arena's east edge; slow sweeping beams from her mirror, sun-disc mines.

North (noon): directly overhead; the whole arena is bright and hot, beams fall straight down on marked circles, the shadows of obstacles are the only safe ground.

West (sunset): she sinks to the west edge; a wide setting-sun beam that crosses the arena, the light turns red, night closes in. When she falls, the sun goes out: the Reckoning is the Endless Night.

### Rewards
| Boss | Spell (paired passive) | Its character |
|---|---|---|
| Kage | Hundred Shadows: shadow clones of the necromancer that echo your next spell cast → Thousand Shadows (+ Hidden Hand) | The Grave Kunoichi (figure style) |
| Shogun Kurogane | Banner of the Dead: a war banner planted where you stand; summons near it attack faster → Hundred Banners (+ Warlord's Seal) | The Ronin Revenant |
| Amaterasu | Black Sun: a dark sun orbits the necromancer and fires a short beam at the nearest group → Eclipse of Heaven (+ Stolen Dawn) | The Shrine Maiden of Night (figure style) |


Finale summon class: the Oni, bound oni brutes with kanabō (a heavy blocker with a stun smash; evolution Oni Lord).

Counter-passives (Act V only): Paper Lanterns (a wider light radius; ambushes show earlier), Unbending (Draw cuts hit summons for less).

Achievements: No Shadow Unlit, Regiments Broken (beat the Shogun after breaking all six banners), The Sun Goes Out (beat Amaterasu; opens the Act V epilogue).



## Concept art notes (from the proposal)

The lineup: ashigaru, samurai, teppo gunner, ninja, kunoichi, oni, kitsune, banner bearer.

Both big bosses: the Shogun on his command platform with his regiments (his health bar), and Amaterasu on the torii gate, the sun's arc behind her.

Stage 13 in play: the Sun's Course split down the middle (dusk on the left, night and yokai on the right), a samurai's Draw line across the ring, and two ninjas appearing inside it.

