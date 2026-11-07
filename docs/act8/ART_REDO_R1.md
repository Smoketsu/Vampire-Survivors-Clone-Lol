# Act VIII art review, round 1: the redo brief

The owner's marks on the round 1 page (https://claude.ai/artifact/NnvuAX9LjN7y1hrNf6XwT4, db collection `act8_art_r1`):
101 OK and 26 Redo. Everything not listed here is approved and must not change.

The common rules of `docs/act6/ART_REDO_R2.md` apply (and through it `docs/act5/ART_REDO_R1.md`): pipeline, ledger,
checks, 1 Godot process, a GDD §15.0 row "Act VIII art review, round 1 (<group>)", commit trailers, no push, never touch an
API key. **A bust box moves only bust pixels** (`bust_exclude` for arms). Rig keys available: `bust`, `swish`, `bust_exclude`,
`pendulums`, `hold`, `flap`, `wings`, `orbit`. Add new rig keys the same way (additive, documented in the header and
ART_BIBLE). Every effect frame uses only colours of the sprite's palette or the city ramps (`city_sodium`, `city_hazard`
for muzzle flashes). "Left" / "right" are as seen on screen. No fast strobes (the act's photosensitivity rule): a flash
lasts at least 2 of the 8 frames and never fills the whole sprite.

## Group A: animation rigs (branch `act8-redo1-rigs`)
No new images.

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/don_marrow_walk` | "Can we maybe get some animated cigar smoke coming off here?" | A new `smoke` rig key: 2–3 small grey puffs rising and drifting from the cigar tip over the 8 frames, fading out. |
| `city/armoured_limo_walk` | "Can we get some moving wheels?" | A new `wheels` rig key: wheel regions redrawn per frame so the hubs/treads turn (spokes or a highlight rotating); no bob. |
| `city/squad_car_walk` | "Can the wheels spin instead of a bob?" | The same `wheels` rig, bob removed. |
| `city/attack_helicopter_walk` | "Need the blade at the top to Spin. As well as the back" | A new `rotor` rig key: the main rotor as a blurred disc / blade pair rotating over the frames, the tail rotor spinning too. The body hovers gently. |
| `city/tank_walk` | "I don't know if this animation is right for a tank. Can we instead get a firing animation?" | Replace its strip with a firing cycle: the gun recoils back 2–3 px, a muzzle flash at the barrel tip, then returns; treads still. (The game plays this strip while it moves: say so in the GDD row.) |
| `city/gang_gunner_walk` | "Can the muzzles flash in an alternating pattern?" | A new `muzzle` rig key: flashes at each gun tip, alternating left/right over the cycle, on top of the walk. |
| `city/machine_gunner_walk` | "Would be cool to see some muzzle flashes" | The same `muzzle` rig: rapid flashes at the barrel tip on the walk. |
| `city/aurora_idle`, `_walk` | "Bounce box needs up 2 pixels and to the left 2 pixels" | Bust box y − 2, x − 2. |
| `city/civilian_woman_idle`, `_walk` | "Remove jiggle here. Doesn't look good on this model" | Remove her bust and swish boxes; she walks and idles with no bounce. |
| `city/field_medic_idle`, `_walk` | "Remove lower bounce box, bust bounce box needs to move up about 7 pixels" | Remove the swish box; bust box y − 7 (refit its height to the bust; exclude arms). |
| `player/revenant_heroine_idle`, `_walk`; `_untouchable_idle`, `_walk` | "Bounce box up 2 pixels and to the right 2 pixels" | Bust box y − 2, x + 2, for the base and the Untouchable skin. |
| `player/revenant_heroine_hyper_idle`, `_walk` | "Bounce box on the bust needs to be up and to the right." | The Hyper skin's own box: y − 2, x + 2 (check it sits on her bust). |

## Group B: regenerated figures (branch `act8-redo1-figures`)
New images, budget about $0.40. Rebuild each figure's strips and fit its rig.

| Key | Owner's note | What to do |
|---|---|---|
| `bosses/paragon` (+ `_walk`) | "Can he have 2 red eyes? And can his color scheme be red white and blue?" | Recolour or regenerate: two glowing red eyes (his heat vision), a red, white and blue costume scheme. Keep him an open parody nod: no emblem or logo, no exact real hero's costume layout (no chest shield-star, no "S"). |
| `city/mammoth` (+ `_walk`) | "Make this thing more awesome give a much bigger main gun and anti personnel turret" | Regenerate the super-heavy tank: a much bigger, longer main gun and a visible anti-personnel turret (a small secondary gun turret on top). Keep its size class (it is a miniboss); if the gun needs more canvas, widen it and say so. Its walk strip follows Group A's tank decision: build it as a firing cycle (main gun recoil + flash) the way Group A does for the tank, using Group A's `muzzle` description; coordinate by keeping the rig entry in your own lines. |
| `player/revenant_heroine_deathlord` (+ `_idle`, `_walk`) | "Can we make her more scantily clad?" | Regenerate from the approved base heroine, in the figure-redesign style pushed further: more skin (bare midriff, shoulders, thighs; a high-cut suit, torn cape), Deathlord colours and emblem. **Chest and hips always covered, no nudity**; name her sex in the prompt and use wording the image API accepts (see `docs/act6/BRIEF_PHASE2.md` "Art"). Refit her bust box with arm exclusion. |
