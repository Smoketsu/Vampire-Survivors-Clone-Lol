# itch.io page kit for Necropathy

Everything for the project page at itch.io, ready to paste. itch.io has no API for page content
(butler only uploads builds), so the page is filled in by hand from this kit, once, in
**Dashboard → Necropathy → Edit game** and **Edit theme**. The images are in this folder.

| File | Where it goes |
|---|---|
| `cover.png` (630 × 500) | Edit game → **Cover image** |
| `banner.png` (960 × 260) | Edit theme → **Banner** (header image) |
| `screenshots/*` | Edit game → **Screenshots** (in this order; itch shows the first ones beside the game) |

## Edit game

| Field | Value |
|---|---|
| Title | Necropathy |
| Short description or tagline | Command an undead horde against a holy crusade. Survive twenty minutes, then face the Reckoning. |
| Classification | Games |
| Kind of project | HTML |
| Release status | In development |
| Pricing | No payments (or "Name your own price" with $0 minimum, if you want tips) |
| Uploads | the `html5` upload from CI: tick **This file will be played in the browser** |
| Embed options | Viewport **1280 × 720**, **Fullscreen button** on, **Automatically start on page load** off (the click unlocks audio), **Mobile friendly** on with orientation **Landscape** once the mobile update is live |
| Genre | Action |
| Tags | `survivors-like`, `roguelite`, `pixel-art`, `horde`, `necromancer`, `undead`, `top-down`, `dark-fantasy`, `singleplayer`, `controller-support` |
| App store links | none |
| Custom noun | none |
| Community | Comments (playtesters can leave feedback under the game) |
| Visibility | **Restricted** with a password for playtesters, or **Public** when ready |

## Description (paste into the description editor)

> **Begin as the hunted. Raise the fallen. Become the army.**
>
> The Crimson Covenant has found your graveyard. You are a necromancer with no sword and no aim to
> worry about: your spells cast themselves and your undead fight on their own. Your job is to
> survive, choose what to raise, and keep the horde alive long enough to break a crusade.
>
> **How a run goes**
>
> - Every stage is a **20:00 countdown**. With three minutes left the stage's boss arrives.
> - At 0:00 the **Reckoning** begins: the Covenant's last waves, built to end you. Fall after 0:00
>   and it's a victory.
> - Level up from the souls of the dead and pick from three cards: new spells, new summon classes,
>   passives, and upgrades to what you own.
> - Open treasure chests to **evolve** spells and summons once their recipe is complete. Recipes
>   are never spelled out: you discover them.
>
> **Your horde**
>
> - **12 summon classes**: Skeleton Warriors that hold the line, Archers, Mages, Menders and
>   Warders, hulking Abominations, Grave Rogues, Crypt Gargoyles, Frost Wraiths, Bone Hound packs,
>   wailing Banshees and Corpse Catapults.
> - **Evolutions** like the Death Knight, the Lich, the Bone Colossus and the Keening Lady.
> - **13 army synergies**: pair a stomping Abomination with Warriors, or let Gargoyles mark prey
>   for your Rogues and Bone Hounds.
> - **Army stances**: Escort, Onslaught, Spearhead and Bone Ring.
> - **Grave Step** dashes you out of trouble; **Dread Rally** raises your whole fallen army.
>
> **The crusade**
>
> - **Three stages**: the Desecrated Graveyard, the Crimson March with its outposts and ward
>   generators, and the Sanctum of Judgment.
> - **Three bosses**: Sir Alaric, Marshal Vael and Grand Inquisitor Seraphine.
> - Templars, Purifiers, Sun Paladins, High Confessors who raise their dead, and the whip-cracking
>   Sisters of the Scourge.
>
> **Between runs**
>
> - **12 playable necromancers**, one per spell, each with its own starting spell and innate.
> - **Soul Ash** you keep on death, spent in the **Ossuary** on permanent upgrades.
> - **Four difficulty levels**, eight run modifiers, the **Profane Pact** and **Oath** for more
>   risk and more reward, **Hyper mode** and unlockable skins.
> - A **Codex** that fills in as you meet spells, summons and Covenant soldiers.
>
> **Controls:** keyboard and mouse, or a controller. Move with WASD / the left stick; Shift / RB
> to dash, Space / LB for the ultimate, 1-4 / right-stick flicks for stances, Esc / Start to
> pause. Every key can be rebound in Settings.
>
> *Early build, actively playtested: your feedback shapes the next update. Leave a comment
> below.*

## Edit theme

The game's own palette (`tools/palette.json`).

| Theme field | Colour | Palette name |
|---|---|---|
| Background | `#160A21` | ink_violet |
| Second background (description box) | `#2A1640` | between ink_violet and violet_deep |
| Text | `#E8E1C8` | bone |
| Link | `#3DCC94` | soul |
| Button | `#7A42AD` | violet |
| Button text | `#E8E1C8` | bone |
| Border | `#4A2569` | violet_deep |

- **Layout:** banner on top, "Game embed" first, screenshots in the right column.
- **Fonts:** a gothic or serif font for headers if the picker offers one, a plain sans font for
  the body.
- **Background image:** none; the dark violet keeps the embed the focus.
