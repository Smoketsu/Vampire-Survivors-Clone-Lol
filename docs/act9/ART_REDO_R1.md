# Act IX art review, round 1: the redo brief

The owner's marks on the round 1 page (https://claude.ai/artifact/SyqRn6F4zNf3ifxHQKXW8L, db collection `act9_art_r1`):
128 OK and 34 Redo. Everything not listed here is approved and must not change.

The common rules of `docs/act8/ART_REDO_R1.md` apply (and through it `docs/act6/ART_REDO_R2.md` and
`docs/act5/ART_REDO_R1.md`): the pipeline, the ledger, the checks, at most 1 Godot process (check `pgrep -c Godot`), a
GDD §15.0 row "Act IX art review, round 1 (<group>)", commit trailers, no push, never touch an API key. **A bust box moves
only bust pixels** (`bust_exclude` for arms). Rig keys: `bust`, `swish`, `bust_exclude`, `pendulums`, `hold`, `flap`,
`wings`, `orbit`, `smoke`, `wheels`, `rotor`, `tail`, `recoil`, `muzzle`, `breath`, and the robe / hover / glide modes.
Concord units never use the necromancer's violet + bone. Every prompt names the figure's sex; female figures in the
figure-redesign style, chest and hips covered.

## Group A: rigs and a recolour (branch `act9-redo1-rigs`)
No new images.

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/harvester_walk` | "another floater" | Replace the leg stride with a hover / glide strip (the robe-glide or hover mode other floating figures use: body bobs, robe hem sways, no steps). |
| `concord/grey_overseer_walk` | "make him float instead of walk" | The same hover strip. |
| `concord/luminous_archon_walk` | "another to make float" | The same hover strip (keep her bust rig if she has one). |
| `player/blooded_idle`, `_walk`, and the `_hyper`, `_untouchable`, `_deathlord` idle and walk | "extend bounce box 4 pixels to the right" | Bust box x1 + 4 on the base and every skin (skins that derive the box follow; skins with their own box get it too). Keep any arm exclusion so only bust pixels move. |
| `effects/acid_pool` | "Should be green since it's acid" | Recolour the acid puddle mask / tint to an acid green (the Concord plasma green ramp); if the code tints it, change the tint constant in the data instead and say where. |

## Group B: figures (branch `act9-redo1-figures`)
New images, budget about $0.45. Rebuild each figure's strips and fit its rig.

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/hive_mother` (+ `_cast`, `_strike`, `_flight`, `_flight_walk`, `_idle`, `_walk`) | "Wider hips and bigger bust" | Regenerate the Hive Mother (female, insectoid queen, figure-redesign style pushed further: wider hips, bigger bust, chest and hips covered by chitin plates) from her approved concept and the current sprite; keep her colours and silhouette type. Then rebuild every pose sprite and strip from the new still (the attack poses `_cast`, `_strike` and the `_flight` form too), and refit her bust box and arm exclusion. |
| `player/broodbound` (+ every skin: `_hyper`, `_untouchable`, `_deathlord`, all idle and walk strips) | "It's hard to see the details here. Can we redesign this? Make her look more like an alien or a bug" | Redesign her as a clearly alien, insect-like woman (female): chitin plating, antennae or mandible-like crest, compound-eye sheen, insect limbs or wing-cases, in strong readable colours that separate from dark floors (not near-black). Figure style, covered. Then remake the three skins from the new base (each skin's own colour scheme and emblem, as other characters' skins), rebuild all strips, refit the bust box. |
| `player/starborn_deathlord` (+ `_idle`, `_walk`) | "Maybe give some kind of black mask on this one? Just doesn't look right" | Regenerate (or edit) the Deathlord skin with a black mask over the face (a sleek visor or half-mask), keeping the approved base Starborn's figure and pose and the Deathlord colours. Rebuild strips, refit the box. |
