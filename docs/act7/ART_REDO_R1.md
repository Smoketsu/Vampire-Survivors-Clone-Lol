# Act VII art review, round 1: the redo brief

The owner's marks on the round 1 page (https://claude.ai/artifact/RS4qMWzPW6ENrWgarVE1NM, db collection `act7_art_r1`):
130 OK and 34 Redo. Everything not listed here is approved and must not change.

The common rules of `docs/act5/ART_REDO_R1.md` apply unchanged, with Act VII names:
- the pipeline, the ledger, the prompts and the figure style;
- checks, contact sheets and import;
- at most 1 Godot process;
- a GDD §15.0 row "Act VII art review, round 1 (<group>)";
- commit trailers, no push;
- never touch an API key.

"See above" is resolved from the page order. "Bounce box" means a `bust` rig rectangle in `tools/walk_cycle.py`. "Lower
bounce box" means a second box below the bust, e.g. the hip `swish` or a second bust entry: remove it so only the bust
bounces. Left and right are as seen on screen. Act VI's round 1 added the rig keys `pendulums` (a masked region swung
about a pivot) and `hold` (a prop kept fixed to the body): reuse them, and add new rig keys the same way.

## Group A: rigs (branch `act7-redo1-rigs`)
Rig work only, no new images. Rebuild every strip you touch.

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/isolde_idle`, `_walk` | "Remove lower bounce box, extend upper bounce box 2 pixels to the right" | Remove the lower box; upper box x1 + 2. |
| `court/crimson_witch_idle`, `_walk` | "remove lower bounce box" | Remove it. |
| `court/vampire_noble_idle`, `_walk` | "Reduce bust bounce box by 2 pixels on the left" | x0 + 2. |
| `player/hedge_witch_idle`, `_walk` and the Hyper and Untouchable skins' idle and walk | "Remove lower bounce box" | Remove it on all three. |
| `player/hedge_witch_deathlord_idle`, `_walk` | "Remove lower bounce box, extend upper bounce box 2 pixels to the right" | Remove it; this skin gets its own upper box, x1 + 2. |
| `court/chiropteran_walk`, `court/chiropteran_king_walk` | "make the wings flap instead of normal walk" | A new `flap` rig key: the wings (masked regions) rise and fall about their shoulder pivots over the 8 frames, the body bobbing gently; no leg stride. |
| `bosses/elder_walk` | "Make his wings flap instead of normal" | The same `flap` rig. (Group B adds his first, human form; this strip is his second, bat-winged form.) |
| `player/dhampir_walk` and the Hyper and Untouchable skins' walks | "any way we can make his little spirit bats fly around?" | A new `orbit` rig key: each small bat (a masked region) moves on a small loop around the figure over the 8 frames. The Deathlord skin's walk is rebuilt by Group B; give its bats the same orbit in the rig so Group B's rebuild picks it up. |

## Group B: regenerated figures (branch `act7-redo1-figures`)
New images. Budget about $0.50. Rebuild each figure's strips and fit its rig. Keep every approved part.

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/vargr` (+ `_walk`) | "Face kinda looks like a rat, make him more canine" | A wolf's head: longer muzzle, heavier jaw, upright pointed ears, a big wolf skull, no rat snout. Keep the body. |
| `court/blood_knight` (+ `_walk`) | "Missing the gold trim on the armor from the concept art" | Add the concept's gold trim (`art_source/concepts/act7_lineup.png`) to his armour edges. |
| `court/ghoul` (+ `_walk`) | "Any chance we can add a longer tongue to this?" | A long, lolling tongue. |
| `player/dhampir_deathlord` (+ `_walk`) | "Can he get a bit more definition on his features?" | Regenerate from the approved base Dhampir: clearer face and features, Deathlord colours and emblem. |
| `player/moon_huntress_deathlord` (+ `_idle`, `_walk`) | "Colors too muddy, can't see any real definition here" | Regenerate from the approved base Huntress with a clear, contrasting Deathlord scheme (as the other characters' Deathlord skins), readable at game size. |
| `summons/nosferatu` (+ `_walk`) | "Can we give him a bit more definition, maybe make his coat black" | More defined features, a black coat. |
| **new** `bosses/elder_vampire` (+ `_walk`) | On `bosses/elder`: "Any way we can make this another multiform boss? Starts as a cool vampire guy, then becomes this?" | The Elder's first form: a tall, ancient, regal vampire lord (male), pale, dark clothes with blood-red lining, a high collar, in the Court's palette. The approved bat-winged `bosses/elder` stays as his second form. A walk strip for it. A code agent wires the two forms in `boss_carmilla.gd`. |
