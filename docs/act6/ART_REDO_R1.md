# Act VI art review, round 1: the redo brief

The owner's marks on the round 1 page (https://claude.ai/artifact/E29ZPfQSPyGCLAiuz2W5Gj, db collection `act6_art_r1`):
118 OK and 45 Redo. Everything not listed here is approved and must not change.

The common rules of `docs/act5/ART_REDO_R1.md` apply unchanged, with Act VI names:
- the pipeline, the ledger, the prompts and the figure style;
- checks, contact sheets and import;
- at most 1 Godot process;
- a GDD §15.0 row "Act VI art review, round 1 (<group>)";
- commit trailers, no push;
- never touch an API key.

The Act VI style rules of `docs/act6/BRIEF_PHASE2.md` ("Art") hold: chest and hips always covered, no nudity, and wording
that the image API accepts.

"See above" is resolved from the page order. A bust box ("bounce box") is the `bust` rig rectangle in `tools/walk_cycle.py`.
"Left" and "right" are as seen on screen.

## Group A: bust boxes and swinging props (branch `act6-redo1-rigs`)
Rig work only: no new images unless a fix truly needs one. Rebuild every strip you touch.

| Key | Owner's note | What to do |
|---|---|---|
| `inferno/fallen_angel_idle`, `_walk` | "Bounce box needs to be shifted about 4 pixels to the right" | Bust box x + 4. |
| `inferno/lilim_witch_idle`, `_walk` | "reduce 2 pixels on the left of the bust" | Bust box x0 + 2 (right edge kept). |
| `inferno/succubus_idle`, `_walk` | "reduce the bounce box by 1 pixel on the left side of the bust" | x0 + 1. |
| `inferno/twin_agrat_idle`, `_walk` | "reduce bounce box by 2 pixels to the left of the bust" | x0 + 2. (Her still is marked Redo with no note; Group B looks at it.) |
| `inferno/twin_naamah_idle`, `_walk` | "Reduce bounce box on the left side of the bust by about 2 pixels" | x0 + 2. |
| `player/fallen_saint_idle`, `_walk`, `_untouchable_idle`, `_untouchable_walk` | "Bounce box needs shifted 4 pixels to the right" | x + 4 for the base and the Untouchable skin. |
| `player/fallen_saint_hyper_idle`, `_walk` | "Bounce box shifted 3 pixels to the right" | The Hyper skin gets its own box: x + 3. |
| `summons/bound_succubus_idle`, `_walk`; `summons/lilim_matriarch_idle`, `_walk` | "bust box needs to come down 2 pixels and move to the right 2 pixels" | y + 2, x + 2 on both. |
| `summons/archfiend_walk`, `summons/prince_of_hell_walk` | "His cleaver moves and it's not supposed to" | Keep the cleaver (and the hand holding it) fixed relative to the body in the walk; only legs, tail and wings move. |
| `inferno/gatekeeper_walk` | "Can we make the chains swing back and forth?" | Add a pendulum swing to the hanging chains (a new rig part, as the bust and swish are: a masked region rotated about its top point on game time). Keep it slow and readable. |
| `bosses/morning_star_beast_walk` | "Make the chains sway if you can" | The same chain swing, gentler. |
| `player/furnace_priest_walk` (and his three skins' walks, for consistency) | "Any way to make the censer swing back and forth?" | The same swing on the censer, about its chain's top. |
| `player/succubus_queen_untouchable_idle`, `_walk` | "See above" (after the Hyper skin's wing note; her still is OK) | Rebuild them from the approved still and check that they match it frame for frame. If the strips already match, leave them and say so: the lead will ask the owner. |

Build the swing once in `walk_cycle.py` (one rig key, e.g. `swing: [{box, pivot, degrees, period}]`) and use it for
all three; document it in ART_BIBLE.

## Group B: regenerated figures and the throne tile (branch `act6-redo1-figures`)
New images. Budget about $0.60. Rebuild each figure's strips and fit its bust box. Keep every approved part as it is.

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/lilith` (+ `_demon`, `_idle`, `_walk`) | "She's gotta be sexy to an exaggerated degree. Bigger bust and thighs, plunging neckline" | Regenerate Lilith at the height of the Act VI style: the most exaggerated hourglass in the game, a bigger bust and thighs, a plunging neckline, still fully covered. The demon form gets the same figure. Use the approved Succubus Queen and Succubus as the reference for the level the owner likes. Rebuild her strips. |
| `inferno/hell_knight` (+ `_walk`) | "Put him in a pose where he looks like he's about to swing" | Regenerate him with the weapon raised, ready to swing. The walk keeps the pose. |
| `inferno/lava_hound` (+ `_walk`) | "Can his head be redone? It needs more definition" | A clearer head: readable jaw, eyes and horns at game size. |
| `inferno/seraph_general` (+ `_walk`) | "He's awesome, except for his face, can you put him as having the greatsword ready to swing?" | Keep the body and wings. Redo the face (clear, noble, fallen) and pose the greatsword raised, ready to swing. |
| `inferno/twin_agrat` | (Redo, no note) | Compare her with her approved sister Naamah: match Naamah's level of finish and figure, so the twins read as a pair. |
| `player/fallen_saint_deathlord` (+ `_idle`, `_walk`) | "Just a bit too far from the original" | Regenerate from the approved base Fallen Saint: same figure, face and pose, with only the Deathlord skin's colour scheme and emblem (see the other characters' Deathlord skins). |
| `player/succubus_queen_hyper` (+ `_idle`, `_walk`) | "any way we can remake the wings as angel wings?" | Keep her; replace the bat wings with feathered angel wings (dark or burnt feathers suit the Hyper skin). |
| `tiles/pandemonium_throne` | "Add some cracks with lava in them? Could be cool" | Add a few lava-filled cracks; keep it seamless and quiet enough that units read on it. |
