# Act V art review, round 2: the redo brief

The owner's marks on the round 2 page (https://claude.ai/artifact/JkiuqT1bqxSuVqbL6qu4cp, db collection
`act5_art_r2`): 32 OK and 15 Redo. Everything not listed here is approved and must not change.

The common rules of `docs/act5/ART_REDO_R1.md` apply unchanged:
- pipeline, ledger, prompts, figure style;
- checks, contact sheets, import;
- 1 Godot process;
- GDD row "Act V art review, round 2 (<group>)";
- commit trailers, no push;
- never touch an API key.

"See above" is resolved from the page order.

## Group A: the Burning Province (branch `act5-redo2-province`)

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/kage` (+ `_idle`, `_walk`) | "Have them re do the fishnets again. They don't look great here." | Redo her fishnets so they read as stockings at game size. Read the approved Kunoichi's and Grave Kunoichi's nets: the owner OK'd those in round 2, so match their look (scale, contrast, coverage) on Kage's legs, and cover only the legs. Rebuild the strips. Her bust box was approved: keep it. |
| `player/grave_kunoichi_deathlord_walk` | "Bounce box needs to be reduced like 1 pixel on the bottom" | Give the Deathlord skin **its own** bust box: the shared box minus 1 px at the bottom. The base and the Untouchable skin keep the approved shared box. |
| `player/grave_kunoichi_deathlord_idle` | (redo, no note) | The same box. |
| `player/grave_kunoichi_hyper_idle` | "See above" (the Deathlord walk's note) | Give the Hyper skin its own box too: 1 px shorter at the bottom. |
| `player/grave_kunoichi_hyper_walk` | (redo, no note) | The same. |
| `player/grave_kunoichi_untouchable` (+ `_idle`, `_walk`) | "Needs to be re done. Doesn't look good" | Regenerate the Untouchable skin from the base Grave Kunoichi, which the owner OK'd, as the reference. Keep the Untouchable skin's colour scheme and emblem (look at the other characters' Untouchable skins), and keep the fishnets clean on the legs only, never over the skirt. Then rebuild the strips and fit the box. |

## Group B: the Road to the Sun (branch `act5-redo2-sun-road`)

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/amaterasu_idle` | "Extend the bounce box 1 pixel to the left and 2 pixels up" | Bust box x0 − 1, y0 − 2. Rebuild. |
| `bosses/amaterasu_walk` | "See above" | The same. |
| `shogunate/kitsune_idle` | "Bounce box need extended 4 pixels to the left and 2 up" | Bust box x0 − 4, y0 − 2. Rebuild. |
| `shogunate/kitsune_walk` | (redo, no note) | The same. |
| `epilogue/act5_4` | "Looks like mess. Re do it" | Regenerate the panel with a clean, readable composition: one clear focal point. Amaterasu, her approved new figure, falls from the sky as the sun goes dark above a sea of clouds; a few big shapes; the army small on the road below. Compare it with the approved panels `act5_1`–`act5_3` for style and clarity, and look at it at game size before keeping it. Use the R1 version only to see what not to do. |
