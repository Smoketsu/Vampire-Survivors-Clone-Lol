# Necropathy 0.6.0: the menus come alive, the bosses come down

![The title screen over the living graveyard](https://raw.githubusercontent.com/Smoketsu/vampire-survivors-clone-lol/v.0.6.0/docs/media/v0.6.0/title.gif)

v0.5.0 gave the game its name, its final stage and its pixel art. **0.6.0 rebuilds every screen around that art, and rebalances the boss fights.** It
adds:

- a title screen over a living graveyard, with a theme of its own;
- stage cards showing each boss mid-attack;
- a **Codex** that fills in as you play.

The level-up, chest, pause and end screens are redone too. Dread Rally now raises your whole army, every boss has
less HP, your spells hit harder, and the newer spells, summons and passives finally show up in your level-ups. Your save carries over
as always.

## Download and play

| Platform | File | How to run |
|---|---|---|
| Windows | `Necropathy-windows.zip` | Unzip and run `Necropathy.exe`. The build is unsigned, so SmartScreen may warn you: click **More info → Run anyway**. |
| Linux | `Necropathy-linux.zip` | Unzip, then `chmod +x Necropathy.x86_64` and run it. |

Keyboard and mouse or a controller both work. Every key can be rebound in **Settings**.

## A title screen worth idling on

- **A living graveyard.** The main menu sits over an animated night: moonlit cathedral, drifting fog and rising soul
  wisps. Lanterns flicker, bats cross the moon, and small bands of undead shuffle past on their way to war.
- **"Grave Lullaby", a menu theme of its own.** It's a slow, gothic piece of music box, choir, organ and a tolling bell,
  synthesized in-engine like every other sound. It fades through black into the battle music when you march.
- **Short buttons, clear choices:** Play, Codex, Ossuary, Settings, Credits, Quit. The logo's soul flames flicker, and
  your Soul Ash and lifetime stats sit under the buttons.

## Choose your battlefield

![Stage select: each chapter's boss mid-attack](https://raw.githubusercontent.com/Smoketsu/vampire-survivors-clone-lol/v.0.6.0/docs/media/v0.6.0/stages.gif)

- **Stage cards.** Each chapter's card is a small pixel scene: its ground, its ruins, and its boss mid-attack against
  your undead. Behind them the sky turns to night, dusk or dawn as you move between chapters. Locked chapters are
  dark silhouettes that name the boss you must slay.
- **Pre-run setup.** Your chosen necromancer walks large at the centre in the skin they'll wear. Difficulty takes
  one card per level, and run modifiers are compact toggles. One gold **Soul Ash** plaque rolls to your total reward.

![Prepare the Ritual](https://raw.githubusercontent.com/Smoketsu/vampire-survivors-clone-lol/v.0.6.0/docs/media/v0.6.0/prerun.jpg)

## The Codex (new)

![Codex: the Covenant and its bosses](https://raw.githubusercontent.com/Smoketsu/vampire-survivors-clone-lol/v.0.6.0/docs/media/v0.6.0/covenant.jpg)

An illustrated compendium of everything you've met: **spells, summons, the Covenant's soldiers, its champions and its
bosses**, each with its art, a line of lore and its numbers. Entries start as dark silhouettes and fill in as your runs
meet them, starting with this version.

- **Evolutions stay secret.** One appears in the Codex only after you have obtained it.
- **Achievements tab.** Every achievement shows your progress and the reward it unlocks.

## Every screen, rebuilt

![Level-up cards](https://raw.githubusercontent.com/Smoketsu/vampire-survivors-clone-lol/v.0.6.0/docs/media/v0.6.0/levelup.jpg)

- **Level-up:** cards rise in with level pips. Evolution cards are gold, with a burst and a sheen.
- **Treasure chests:** the chest rattles, bursts open on a beam of light, and your rewards rise one by one.
- **Pause:** your whole run at a glance (stage, time left, spells, passives and army) beside the menu.
- **Results card:** Victory in gold or Defeat in crimson. It shows your necromancer, your build and army, and your
  Soul Ash counting up line by line, with a gold plate for every unlock.
- **HUD:** banners arrive one at a time on a ribbon (gold for evolutions, crimson for the Covenant). They pause
  while a panel is open.
- **The Ossuary:** every upgrade is now an icon tile with level pips, and new pixel art for Soul Ash and every
  upgrade. One panel shows what the next tier does, and buying one chimes and flashes.
- **Settings:** tabs for Audio, Video and Controls. Keyboard and controller bindings are shown side by side, and there
  is a new **Reduce motion** option.
- **Recipes:** a grid of the evolutions you've discovered. Undiscovered ones give nothing away.

![The Ossuary](https://raw.githubusercontent.com/Smoketsu/vampire-survivors-clone-lol/v.0.6.0/docs/media/v0.6.0/ossuary.jpg)

## Feel and polish

- **One look everywhere.** Ornamented pixel frames have bone filigree and cut corners, and all text is in one crisp
  pixel font.
- **Short motion.** Panels slide in, cards lift when you focus them, and numbers count up. It's all brief and never
  in your way; turn it off with Reduce motion.
- **New sounds** for back, opening, buying and "can't".
- **On-screen controls match yours.** Key hints now show your actual bindings, and switch to controller buttons the
  moment you pick up a pad. (Fixes a known issue from v0.5.0.)
- **Asks before you lose a run.** Quit, Restart, Main Menu, Refund all and Reset keys now ask first, with Cancel
  selected.
- **Credits,** with the licences for Godot and the fonts.

## Balance

Playtesters could do everything right and still not bring Marshal Vael down. In test runs a strong army needed
2:29 of his 3:00 and often failed. This pass makes every boss a fight a good build wins, without thinning the
crowds you fight through:

- **Dread Rally raises your whole army.** Every fallen summon rises beside you at full HP when you unleash it,
  on top of the heal, the +40% damage and attack speed, and the knockback.
- **Boss HP:**

  | Boss | Before | Now |
  |---|---|---|
  | Sir Alaric | 42,000 | **27,300** (−35%) |
  | Marshal Vael (Crimson March) | 35,200 | **21,120** (−40%) |
  | Grand Inquisitor Seraphine (Sanctum) | 33,000 | **23,100** (−30%) |

  A strong army build now kills each of them in about BOSS_KILL_RANGE of their 3:00.
- **Spells deal 20% more damage.** All twelve spells and their evolutions; the level-up cards show the real numbers.
- **The newer additions show up.** The newer spells, summons and passives used to share a few fixed slots in
  the level-up draw, so each appeared in about 2% of hands. Each one now has its own weight and shows up about twice as often:
  three level-ups in four now offer at least one newer item (was one in two).
- The short-lived "+5% damage to everything" from the first playtest build is gone, replaced by the changes above.

## Fixes

- Switching Settings tabs while a slider was selected no longer logs an error.
- A rare error when a level-up or chest closed in the same frame it opened is gone.

## Known issues

- Weak builds on a fresh save still die early on the Crimson March and in the Sanctum; with a few Ossuary upgrades
  (the usual state by then) that mostly goes away.
- The Codex starts empty on existing saves and fills in from your next run.

![Results card](https://raw.githubusercontent.com/Smoketsu/vampire-survivors-clone-lol/v.0.6.0/docs/media/v0.6.0/results.jpg)

**New since v0.4?** v0.5.0 brought the third stage and Grand Inquisitor Seraphine, twelve necromancers to play, new
spells, summons and evolutions, Hyper mode, skins and the full pixel-art look. Its notes are
[here](https://github.com/Smoketsu/vampire-survivors-clone-lol/blob/v.0.6.0/docs/release_notes/v0.5.0.md).

Thank you for playing and for every bit of feedback. Tell us what your horde gets up to.
