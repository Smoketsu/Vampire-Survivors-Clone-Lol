# Act V art review, round 1: the redo brief

The owner's marks on the round 1 page (https://claude.ai/artifact/2HrHyAnJT9abqh9yBguxut, db collection
`act5_art_r1`) are 117 OK and 46 Redo. Every image not listed here is approved and must not change.

The notes are quoted as the owner wrote them. Where a note says "See above", it is resolved here from the page order:
it means the card shown just above it on the page.

## Common rules (every agent)

**Before starting:**
- Read `CLAUDE.md`.
- Read the ART_BIBLE sections "Act V: the Shogunate of the Rising Sun, the shared kinds" and each stage's Act V rows.
- Read the GDD §15.0 rows on the figure redesign, the "Idle breathing bounce", "Sideways bounce" and the Act IV art
  review rounds. Those rounds handled the same kinds of notes: bounce boxes moved in `tools/walk_cycle.py` rigs, the
  Amazon's "a bit scandalous" redo.
- Look at each sprite's source and prompt in `art_source/`.

**Making the art:**
- Use the same pipeline that made each sprite. For Act V that means `prepare_sprite.py` straight on the source with
  `--ramps lacquer,indigo,sakura,grey,gold,skin,brown --ink-l 0.22`, or the stage's own build script in
  `art_source/<stage or shogunate>/`.
- Generate images with `GEN_LEDGER=<your worktree>/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`,
  using an absolute path. Commit the ledger rows.
- Pass the old source as a reference image so a redo keeps the approved look. Change only what the note asks.
- **Never read, print, echo or search for any API key.**

**Figures:**
- Female figures are in the figure-redesign style: an exaggerated hourglass figure, fully clothed.
- The owner wants them a little scandalous, but never nudity, and no notch or gap that reads as anatomy.
- Name the figure's sex in every prompt.

**Bounce and strips:**
- A "bounce box" is the `bust` box of the sprite's rig in `tools/walk_cycle.py`. Move or extend it exactly as the note
  says, in art px, then rebuild both strips: `python3 tools/walk_cycle.py build <key>` and `... idle <key>`.
- When a still is regenerated, rebuild its walk and idle strips and re-fit its bust box to the new chest.
- A skin redo keeps that skin's colours and emblem; only the change the note asks for carries over.

**Checks and handover:**
- Run `tools/art_check.py` on every changed sprite and look at it at game size and zoomed.
- Make a before/after contact sheet in your scratch dir. Put animated strips side by side as GIFs too.
- Run one `--headless --import` and make sure it is clean. Use at most 1 Godot process.
- Add a GDD §15.0 row "Act V art review, round 1 (<your group>)" at the end of the table, plus ART_BIBLE notes.
- Commit in your worktree with these two trailer lines:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

  Do not push. Never mention model identifiers.
- Your final report covers:
  - the commits;
  - every changed key and what changed;
  - the cost;
  - the contact sheet paths.

## Group A: the Burning Province (branch `act5-redo-province`)

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/kage` | "I'm thinking fishnets on the legs" | Fishnet stockings on her legs, readable at game size: a fine dark diamond grid over the skin tone, not grey noise. Keep everything else. |
| `bosses/kage_idle` | "Bounce box needs to move up and to the left" | Move her bust box up and left until it sits on her chest. Rebuild after the new still. |
| `bosses/kage_walk` | "See above" | The same bust box fix, plus the new still. |
| `player/grave_kunoichi` | "Do some fishnets to match Kage" | Fishnets on the legs, like Kage's. |
| `player/grave_kunoichi_idle` | "Bounce box extended 1 pixel to the right" | Widen the bust box 1 px to the right. |
| `player/grave_kunoichi_walk` | "See above" | The same. |
| `player/grave_kunoichi_deathlord` | "See above" | Fishnets, as on the base. |
| `player/grave_kunoichi_deathlord_idle`, `_walk` | "Bounce box extended to the right" | Widen its bust box to the right (1–2 px; match the chest). |
| `player/grave_kunoichi_hyper` | "See above" | Fishnets. |
| `player/grave_kunoichi_hyper_idle`, `_walk` | (no note) | Rebuild with the new still; bust box widened right like the base. |
| `player/grave_kunoichi_untouchable` (+ `_idle`, `_walk`) | (no note) | Fishnets and the bust box widened right, like the base. |
| `shogunate/kunoichi` | "Give her some fishnets!" | Fishnets on the legs. |
| `shogunate/kunoichi_idle` | "Bounce box should extend 2 pixels to the right" | Widen her bust box 2 px to the right. |
| `shogunate/kunoichi_walk` | (no note) | The same, with the new still. |
| `shogunate/kappa` (+ `_walk`) | "He's cool, but needs to be more visually understandable" | Make it read at once as a kappa at game size: a green turtle-like river yokai with a turtle shell on his back, a beak and the water-filled dish on top of his head. Simplify the silhouette and make each feature bigger. |
| `icons/hundred_shadows` | "Re do, this is unintelligible" | A clear badge: the necromancer's silhouette with two or three shadow copies fanned out behind it. Bold shapes, few colours. |
| `icons/ach_no_shadow_unlit` | "It's hard to see what this should be" | A clear badge: a lit stone lantern (tōrō) with its warm window glowing, and a dark shadow fleeing from it. |

## Group B: the Road to the Sun (branch `act5-redo-sun-road`)

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/amaterasu` | "She's gotta have a bit more mommy energy. Bigger breasts and thighs, but keep her regal." | Regenerate her from the current source as reference: a fuller, more mature figure (bigger bust and thighs), still a regal sun goddess with the same palette, crown and mirror. Fully clothed. |
| `bosses/amaterasu_idle` | "Bounce box needs to go up and to the right" | Fit the bust box to the new chest. The old one sat too low and too far left. |
| `bosses/amaterasu_walk`, `bosses/amaterasu_mirror` | (redo, no note) | Rebuild from the new still. The mirror pose is her attack pose: regenerate it to match the new figure. |
| `epilogue/act5_4` | "Amaterasu should use our new version as reference." | Regenerate the panel with the NEW Amaterasu still as the reference for her figure. Keep the composition (she falls as the sun goes dark over a sea of clouds, the army on the road below). Use `tools/epilogue_panel.py`. |
| `player/shrine_maiden_idle` | "Bounce box needs to extend two pixels to the right and go up two pixels" | Bust box 2 px wider to the right and 2 px higher. |
| `player/shrine_maiden_walk` | "See above" | The same. |
| `player/shrine_maiden_deathlord` | "Very busy visually, re generate" | Regenerate the Deathlord skin with fewer, bigger shapes. Keep the Deathlord skin's look (see the other characters' Deathlord skins). |
| `player/shrine_maiden_deathlord_idle`, `_walk` | (redo, no note) | Rebuild from the new still; fit the bust box. |
| `player/shrine_maiden_hyper_idle` | "Bounce box up 5 pixels and right 2 pixels" | Move the box up 5 px and widen it 2 px right. |
| `player/shrine_maiden_hyper_walk` | "See above" | The same. |
| `player/shrine_maiden_untouchable_idle`, `_walk` | "See above" | The card above is the Hyper walk, so up 5 px and right 2 px. Check it visually on this skin's chest: if that overshoots, use the base's up 2 / right 2 and say so in your report. The Untouchable still is approved. |
| `shogunate/kitsune` | "Make her bustier" | Regenerate or edit from the current source: a bigger bust, the same fox-spirit look. |
| `shogunate/kitsune_idle`, `_walk` | (redo, no note) | Rebuild from the new still; fit the bust box. |

## Group C: the oni and the samurai (branch `act5-redo-oni`)

| Key | Owner's note | What to do |
|---|---|---|
| `shogunate/oni` (+ `_walk`) | "Can the kanabo be over his shoulder? Would look better imo" | Regenerate with the iron kanabō resting over his shoulder. Rebuild the walk; the club rides rigid with the body. |
| `summons/oni_lord` (+ `_walk`) | "Put the kanabo over his shoulder" | The same pose for the Oni Lord. |
| `summons/bound_oni` (+ `_walk`) | "It's not clear that he's in chains here. Could you re do?" | Regenerate with bold, readable chains: heavy bone-and-iron shackles on the wrists and neck, with chain links big enough to read at game size, soul-teal eyes. Use the shoulder kanabō pose too, so he matches the Oni Lord. Keep his approved colours. |
| `shogunate/samurai` (+ `_walk`) | "Have his pose as ready to draw the sword" | Regenerate in an iai stance: crouched forward, his hand gripping the hilt at the hip, the scabbard angled. The same armour and crest. |

The approved icons `icons/bound_oni` and `icons/oni_lord` stay unless they no longer match the new sprites. If they
clash, say so in your report; don't redo them.
