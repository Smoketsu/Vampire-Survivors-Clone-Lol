# Act VI art review, round 2: the redo brief

The owner's marks on the round 2 page (https://claude.ai/artifact/2dtQ2LjCXPSEs7efjo4xgp, db collection `act6_art_r2`):
19 OK and 26 Redo. Everything not listed here is approved and must not change. The common rules of
`docs/act6/ART_REDO_R1.md` apply. Branch `act6-redo2`, made from `act7-redo1-rigs`, which holds the Act VII `flap`
rig key (wings turned about their shoulder pivots, the body bobbing) used below.

## The lesson of this round: a bust box covers the bust only
The owner's round 1 notes ("reduce the bounce box on the left of the bust") meant: **the arm next to the bust is
bouncing with it, take the arm out.** Round 1 shrank the box by whole columns and the arm still bounced. A bust box
must move only bust pixels. Fix it properly: give the `bust` rig an exclusion (an arm mask: exclude boxes or the arm's
colours, as the `flap` rig's `soft_exclude` does) so arm, hand and sleeve pixels inside the box stay still. Check every
frame of each strip at 4× before keeping it: nothing but the bust may move with the bounce.

## Redo list

| Key | Owner's note | What to do |
|---|---|---|
| `inferno/lilim_witch_idle`, `_walk` | "Nope, not what I meant, I meant the arm part next to the bust needed to be removed" | Restore the round-1 box width if that fits the bust better, and exclude the arm from it. |
| `inferno/succubus_idle`, `_walk` | "you're only needing to add the bounce box to the bust, but you've extended it onto her arm" | Exclude the arm. |
| `inferno/twin_agrat_idle`, `_walk`; `inferno/twin_naamah_idle`, `_walk` | The same | Exclude the arm on both twins. |
| `player/succubus_queen_hyper_walk` | "arm is bouncing, reduce bounce box on the left side" | Exclude the arm. |
| `player/succubus_queen_untouchable_idle`, `_walk` | "See above" | Exclude the arm (the same fix). |
| `summons/bound_succubus_idle`, `_walk`; `summons/lilim_matriarch_idle`, `_walk` | "Reduce the bounce box by about 4 pixels on the left side" | x0 + 4, and check no arm moves. |
| `player/succubus_queen_hyper` (+ `_idle`, `_walk`) | "can the wings be white?" | Recolour the feathered wings white (bone / ivory shades of the existing palette, light from the upper left, gold tips kept); no regeneration needed. Rebuild the strips. |
| `bosses/lilith_idle`, `_walk` | "Can we make the wings flap a bit?" | Add the `flap` rig to her wings (gentle, ±8–10°), keeping her bust rig. |
| `inferno/seraph_general_walk` | "Any way we can have those wings [flap] a little bit?" | A gentle `flap` on his wings; keep the raised greatsword fixed (`hold`). |
| `summons/prince_of_hell_walk` | "Maybe some flapping wings here too?" | `flap` on his wings; keep the cleaver `hold`. |
| `inferno/hell_knight` (+ `_walk`) | "we lost a lot of his charm in this pass. the older one was closer to what I was thinking" | **Restore the round 1 version** (`git show c110748:<path>` for the still, the walk strip and his rig line), unchanged. |
| `player/fallen_saint_deathlord` (+ `_idle`, `_walk`) | "Looks bad, all the colors are muddy and the details are invisible, the first try was better" | **Restore the round 1 version** of the still (c110748), then rebuild its idle and walk with the current rig (the base saint's box moved 4 px right in round 1, which the owner approved). |
