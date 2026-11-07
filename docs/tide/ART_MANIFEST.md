# The Black Tide: art and audio manifest

Stage key `corsair`, folder `docs/tide/`. Made by `art_source/corsair/make_art.py` (API sources in `art_source/corsair/raw/`, prompts in `prompts/`), `tools/corsair_tiles.py` (floors and sea) and `tools/walk_cycle.py` (rigs under "The Black Tide" in `RIGS`). Ramps in `tools/palette.json`, `prepare_sprite.py` folder `corsair`. Heights are the `SpriteData.HEIGHTS` entries (1 art px = 1 screen px). Image cost: 37 API images, about $0.73 (`docs/art/generation_ledger.csv`, keys `corsair/...`).

Sprite folders: roster, minibosses, bosses, boats and pieces in `assets/sprites/corsair/<id>.png` (as the brief asked); the three playable characters in `player/` and the finale summon class in `summons/` (where the engine already looks for characters and classes). Everything faces RIGHT; boats point their bow right and are rotated by the code. A "walk" strip is 8 frames side by side (`<id>_walk.png`, frame width = strip width / 8); an "idle" strip is 24 frames (`<id>_idle.png`, female bust rigs only). Hover stills (sea creatures, boats, Vandermere) carry 2 empty rows above and below the art (the bob), so their HEIGHTS are 4 more than the art.

## Palette ramps (`tools/palette.json`, constants `CORSAIR_*` for `palette.gd` in the same hexes)

| Ramp | Colours | Use |
|---|---|---|
| `oak` | `corsair_oak_dark` #2B1D14, `corsair_oak` #4A3220, `corsair_oak_light` #7A5632 | tarred oak: hulls, decks, barrels, boots, belts (the Black Tide) |
| `sail` | `corsair_sail_shade` #8F8466, `corsair_sail` #D6CBA4, `corsair_sail_light` #F0E9CE | sailcloth cream: shirts, sails, rope, canvas (the pirates' own cream, never the undead's bone) (the Black Tide) |
| `brass` | `corsair_brass_dark` #7A5A1C, `corsair_brass` #C4912A, `corsair_brass_light` #EBC85A | brass: buckles, cannon, lantern frames, hilts, coins (duller than the UI gold, which keeps its meaning) (the Black Tide) |
| `powder` | `corsair_powder_dark` #2E3239, `corsair_powder` #5E636C, `corsair_powder_light` #9498A0 | powder-smoke grey: iron, muskets, sharks, stone, smoke (the Black Tide) |
| `sash` | `corsair_sash_dark` #6A1620, `corsair_sash` #B02A30, `corsair_sash_light` #E2563F | sash red: bandanas, sashes, coats, crab shell (never the Covenant's crimson) (the Black Tide) |
| `lantern` | `corsair_lantern_dark` #B0661C, `corsair_lantern` #F2A63A, `corsair_lantern_light` #FFDF8A | lantern amber: every telegraph, fuses, lanterns, sigils (the Black Tide) |
| `sea` | `corsair_sea_dark` #0E1A33, `corsair_sea` #1B3560, `corsair_sea_light` #2F5F96 | navy sea and navy coats: the water, Marrec's coat, hull shadow (the Black Tide) |
| `foam` | `corsair_foam_shade` #8FB4D2, `corsair_foam` #D8E9F4, `corsair_foam_light` #F6FBFF | white foam: wave crests, splashes, gull feathers, shark bellies (the Black Tide) |
| `kraken` | `corsair_kraken_dark` #3A2150, `corsair_kraken` #6B3C86, `corsair_kraken_light` #A877BC | kraken purple: tentacles (the Black Tide) |
| `serpent` | `corsair_serpent_dark` #134744, `corsair_serpent` #26827E, `corsair_serpent_light` #66C3BA | sea serpent teal: scales, the crest (the Black Tide) |
| `spectre` | `corsair_spectre_dark` #1D4F4A, `corsair_spectre` #46A78F, `corsair_spectre_light` #B7F0DC | ghost green-white: Vandermere, the ghost crew, the ghost ship (the Black Tide) |
| `tan` | `corsair_tan_dark` #5C3824, `corsair_tan` #96623E, `corsair_tan_light` #C68B5E | weathered and dark skin of the Brotherhood: faces, hands, arms (the Black Tide) |

The act's ink is `corsair_ink` #0A0D18 (navy-black), the outline of every Black Tide sprite. Gold keeps its meaning (evolution, chest, victory) so the act's metal is the duller `brass`; crimson stays danger, so the pirates' red is `sash`.

## Units (`assets/sprites/<key>.png`)

| Key | Size (art px) | Sex / kind | Strips | What it is |
|---|---|---|---|---|
| `corsair/deckhand` | 32x40 | male | `_walk` (256x40) | a DECKHAND, a MALE pirate fodder soldier mid-charge with a curved cutlass raised: a red bandana, a navy-and-cream striped shirt, a red sash, dark trou |
| `corsair/musketeer` | 44x42 | male | `_walk` (352x42) | a MUSKETEER, a MALE pirate marksman aiming a long musket forward: a black tricorn hat, a navy coat with brass buttons, cream shirt, dark trousers, bro |
| `corsair/powder_runner` | 36x40 | male | `_walk` (288x40) | a POWDER RUNNER, a MALE pirate sprinting hunched forward carrying a small barrel (a powder keg) under one arm with a short LIT FUSE spitting an amber  |
| `corsair/swashbuckler` | 48x44 | female | `_walk` (384x44), `_idle` (1152x44) | a SWASHBUCKLER, a FEMALE pirate duellist in the game's figure-redesign style (an extremely exaggerated hourglass figure: a very full bust, a tiny cinc |
| `corsair/grappler` | 34x42 | male | `_walk` (272x42) | a GRAPPLER, a MALE pirate hauling a coil of rope and swinging a four-pronged iron grappling hook on a line over his head: a white-grey cap, a cream sl |
| `corsair/gunnery_mate` | 32x42 | female | `_walk` (256x42), `_idle` (768x42) | a GUNNERY MATE, a FEMALE pirate artillerist in the game's figure-redesign style (an extremely exaggerated hourglass figure, a very full bust, a tiny w |
| `corsair/boatswain` | 30x42 | male | `_walk` (240x42) | a BOATSWAIN, a MALE pirate officer with a broad chest bellowing orders, one hand to his open mouth and a small brass whistle on a chain: a dark navy c |
| `corsair/voodoo_navigator` | 32x44 | female | `_walk` (256x44), `_idle` (768x44) | a VOODOO NAVIGATOR, a FEMALE dark-skinned sea-witch navigator in the game's figure-redesign style (an extremely exaggerated hourglass figure, a very f |
| `corsair/boarding_bruiser` | 48x56 | male | `_walk` (384x56) | a BOARDING BRUISER, a huge MALE pirate heavyweight, bald, bearded, enormous arms, gripping a big boarding axe: a bare chest with two crossed leather s |
| `corsair/reef_shark` | 32x48 | creature, no sex | `_walk` (256x48) | a REEF SHARK, a creature, seen from above-front leaping out of the water with its toothy jaws open: powder-grey back and fin, a cream belly, red gums  |
| `corsair/hull_crab` | 56x44 | creature, no sex | `_walk` (448x44) | a GIANT HULL CRAB, a creature, seen from above-front, a wide barnacled shell, two huge claws raised, eight legs and two stalk eyes: an armoured shell  |
| `corsair/kraken_arm` | 44x60 | creature, no sex | `_walk` (352x60) | a KRAKEN ARM, a creature: a single huge purple tentacle rising from a ring of white FOAM, curled at the tip, two rows of cream-pink suckers down its i |
| `corsair/sea_serpent` | 46x56 | creature, no sex | `_walk` (368x56) | a SEA SERPENT, a creature: a long teal scaled serpent in an S-shaped coil rising from white FOAM, a spined crest and finned head with open jaws, amber |
| `corsair/skiff` | 56x34 | an object (a boat) | `_walk` (448x34) | a small SKIFF rowing boat seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), its pointed bow to the RIGHT, plain tarred-oak planks  |
| `corsair/longboat` | 92x42 | an object (a boat) | `_walk` (736x42) | a LONGBOAT seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), bow to the RIGHT, tarred-oak planks, six oars along each side, a shor |
| `corsair/raider_ship` | 126x64 | an object (a boat) | `_walk` (1008x64) | a RAIDER SHIP, a two-masted pirate sloop seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), bow to the RIGHT, tarred-oak deck and r |
| `corsair/gunboat` | 88x50 | an object (a boat) | `_walk` (704x50) | a GUNBOAT, a squat heavy gun barge seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), bow to the RIGHT, grey-black iron-plated oak, |
| `corsair/ram_longboat` | 96x48 | an object (a boat) | `_walk` (768x48) | a RAM LONGBOAT, a heavy battering longboat seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), bow to the RIGHT with a big iron-capp |
| `corsair/ghost_longboat` | 74x42 | an object (a boat) | `_walk` (592x42) | a GHOST LONGBOAT seen from nearly directly ABOVE (a plan view with a slight 3/4 tilt), bow to the RIGHT, rotting grey-green planks, a ragged pale sail |
| `corsair/grapple_hook` | 28x16 | an object | - | a GRAPPLING HOOK: a four-pronged iron grapnel with a short length of cream rope tied to its ring, pointing right, hooked over a short piece of oak rai |
| `corsair/boarding_plank` | 60x16 | an object | - | a BOARDING PLANK: a long, narrow wooden gangplank seen from above lying horizontally, tarred oak with cross cleats and rope handrails on both edges, i |
| `corsair/bosun_gorran` | 62x64 | male | `_walk` (496x64) | BOSUN GORRAN, a MALE miniboss pirate bosun, enormous, broad and scarred, bellowing, one fist raised and the other holding a big ship's iron chain-hook |
| `corsair/old_hollow_eye` | 72x76 | creature, no sex | `_walk` (432x76) | OLD HOLLOW-EYE, a miniboss creature: a gigantic kraken arm, thick and scarred, rising from a ring of white FOAM, with a pale blind HOLLOW EYE socket s |
| `corsair/ghost_bosun` | 34x48 | male | `_walk` (272x48) | THE GHOST BOSUN, a MALE spectral miniboss: a translucent-looking drowned bosun, hollow glowing eyes, raising a small whistle to his lips, a tattered c |
| `corsair/crow` | 98x88 | male | `_walk` (784x88) | CAPTAIN EZEKIEL CROW, THE GULL KING, a lean MALE pirate captain boss, a cutlass in one hand and a flintlock pistol raised in the other, a heavy cloak  |
| `corsair/marrec` | 56x92 | female | `_walk` (448x92), `_idle` (1344x92) | ADMIRAL ISABEAU MARREC, THE SEA WOLF, a FEMALE admiral boss in the game's figure-redesign style (an extremely exaggerated hourglass figure, a very ful |
| `corsair/vandermere` | 60x100 | male | `_walk` (480x100) | CAPTAIN CORNELIUS VANDERMERE, a ghostly MALE captain boss lashed to a ship's wheel: he stands gripping a big wooden ship's WHEEL in front of him (rope |
| `player/marooned_quartermaster` | 44x56 | male | `_walk` (496x56) | THE MAROONED QUARTERMASTER, a MALE playable necromancer, a lean castaway ship's quartermaster with a rusted shackle and a short chain on one wrist, wh |
| `player/corsair_queen` | 32x56 | female | `_walk` (480x56), `_idle` (1440x56) | THE CORSAIR QUEEN, a FEMALE playable necromancer in the game's figure-redesign style (an extremely exaggerated hourglass figure, a very full bust, a t |
| `player/ghost_helmsman` | 52x56 | male | `_walk` (352x56) | THE GHOST HELMSMAN, a MALE playable necromancer, a broad drowned ship's helmsman holding a huge rusted iron ANCHOR on his shoulder with a chain, pale  |
| `summons/powder_wraith` | 36x44 | undead skeleton, no sex | `_walk` (288x44) | a POWDER WRAITH, an undead SKELETON (a summoned ally) marching forward carrying a lit powder keg on its shoulder with a short fuse spitting an amber s |
| `summons/magazine_lord` | 32x52 | undead skeleton, no sex | `_walk` (256x52) | a MAGAZINE LORD, a large armoured undead SKELETON (a summoned ally, the evolved Powder Wraith) wearing a captain's dark coat and a tricorn with a burn |

Roles: deckhand, musketeer, powder_runner, swashbuckler, grappler, gunnery_mate, boatswain, voodoo_navigator, boarding_bruiser, reef_shark, hull_crab, kraken_arm, sea_serpent are the roster of `docs/proposals/NEW_ACTS_AND_ORDER.md` Part 1; `gunboat`, `skiff`, `longboat`, `raider_ship` are the boats; `ram_longboat` (Bosun Gorran's ram) and `ghost_longboat` (the Ghost Bosun's spectral longboat) go with their minibosses; `grapple_hook` is the hook structure (the rope is the code's) and `boarding_plank` the raider ship's plank; minibosses `bosun_gorran`, `old_hollow_eye`, `ghost_bosun`; bosses `crow`, `marrec`, `vandermere` (at his wheel); characters `marooned_quartermaster`, `corsair_queen`, `ghost_helmsman`; summons `powder_wraith` and its evolution `magazine_lord`. No ghost-crew variants were drawn: the Maelstrom's ghost crew can tint the roster (`SpriteBank.draw()` tint) or ask for a phase 2 batch. Hyper / Untouchable / Deathlord skins of the three characters are not made.

## Deck furniture (`assets/sprites/obstacles/`)

| Key | Size | What it is |
|---|---|---|
| `obstacles/deck_mast_l` | 38x51 | a round mast stub with coiled rope and a furled sail (circle obstacle) |
| `obstacles/deck_hatch_l` | 44x35 | a grating hatch, horizontal |
| `obstacles/deck_hatch_l_v` | 35x44 | the hatch turned 90 degrees |
| `obstacles/deck_barrels_s` | 30x21 | two powder barrels |
| `obstacles/deck_barrels_l` | 40x48 | four lashed powder barrels |
| `obstacles/deck_cannon_l` | 42x22 | a deck cannon on its carriage, pointing right |
| `obstacles/deck_cannon_l_v` | 22x42 | the cannon turned 90 degrees |

## Floors and sea (`assets/sprites/tiles/`, seamless, `tools/corsair_tiles.py`)

| Key | Size | What it is |
|---|---|---|
| `tiles/corsair_cutter` | 128x128 | night deck of the Smuggler's Cutter: dark tarred planks, bronze nails |
| `tiles/corsair_galleon` | 128x128 | the Treasure Galleon at dawn: lighter scrubbed oak, brass nails |
| `tiles/corsair_maelstrom` | 128x128 | the Hollow Queen: rotting grey-green boards, ghost-green mould |
| `tiles/corsair_water` | 128x128 | the navy sea with white foam dashes (frame 0 of the strip) |
| `tiles/corsair_water_strip` | 512x128 | 4 frames of 128 x 128 side by side; the foam drifts 32 px a frame and the strip loops |

## Icons (`assets/sprites/icons/`, 32 x 32 on the violet / gold frames of the Act IX badges)

| Key | Frame | What it is |
|---|---|---|
| `icons/chain_shot` | violet | Two spiked iron balls joined by a short chain, spinning, trailing pale green spectral light |
| `icons/cannonade` | violet | Three black cannonballs falling with amber fire trails and a brass cannon muzzle flash below |
| `icons/anchor_drop` | violet | A big rusted iron anchor plunging down, pale green spectral glow, a shock ring on the ground |
| `icons/powder_wraith` | violet | A bone-white skull wearing a torn red bandana with a lit powder keg fuse sparking amber beside it |
| `icons/keelhauler` | gold | A long barnacled chain with a heavy hook swinging through a ring of white foam, pale green glow |
| `icons/dead_mens_broadside` | gold | A row of five ghostly cannonballs in a fan, amber and pale green fire |
| `icons/abyssal_mooring` | gold | A huge anchor with a chain wound round it sinking into dark whirlpool water, pale green glow |
| `icons/magazine_lord` | gold | A tower of three powder kegs with burning amber fuses under a black tricorn hat |
| `icons/bosuns_whistle` | violet | A brass bosun's whistle on a chain with three small sound waves |
| `icons/black_powder` | violet | An open powder horn spilling black grains and an amber spark |
| `icons/dead_reckoning` | violet | A brass compass with a skull on its face and a pale green needle |
| `icons/sea_legs` | violet | A sturdy brown sea boot planted on a tilted wooden deck, foam at the edge |
| `icons/barnacle_bones` | gold | A bone-white ribcage encrusted with grey-white barnacles and a bit of seaweed |
| `icons/ach_not_one_aboard` | gold | A small rowboat with a grapple rope cut, a cutlass slashing the rope |
| `icons/ach_walked_the_plank` | gold | A wooden plank over foam water with a splash at its end |
| `icons/ach_dead_men_tell_tales` | gold | A pale green ghost skull wearing a tricorn, a rolled scroll beside it |

Spells: `chain_shot`, `cannonade`, `anchor_drop`; evolutions (gold): `keelhauler`, `dead_mens_broadside`, `abyssal_mooring`, `magazine_lord` (the class evolution); passives `bosuns_whistle`, `black_powder`, `dead_reckoning`; counter-passives `sea_legs`, `barnacle_bones`; the class `powder_wraith`; achievements `ach_not_one_aboard`, `ach_walked_the_plank`, `ach_dead_men_tell_tales`. The ids are snake_case of the names in the proposal; rename in `make_art.py` (`ICONSETS`) if the code agent chose others.

## Audio

**Music** "Dead Men's Shanty": `SoundData.SHANTY_SCORE`, `SoundData.SCORES["shanty"]`, `SoundData.SCORE_PACKS["shanty"] = "corsair"`, `Sfx.MUSIC_SHANTY`, seed `Sfx.SCORE_SEEDS["shanty"] = SYNTH_SEED - 10`; set the stages' `"music": "shanty"`. D minor (Dm, Bb, Gm, A) 4/4 at 120 bpm, a 16 s loop, only existing jobs (drums, waltz, organ, flute, hits, horn), rendered lazily; earlier loops and the startup bank are untouched.

**Sound pack** `SoundData.CORSAIR_SOUNDS` (lazy with the music, `Sfx.PACK_SEED_OFFSETS["corsair"] = 7000`, `prepare_pack("corsair")`):

| Id | Use |
|---|---|
| `cannon_fire` | a deck cannon or broadside fires |
| `cannon_hit` | a cannonball lands |
| `musket_shot` | a musketeer fires |
| `hook_throw` | a grapple is thrown (Grappler, boats) |
| `hook_bite` | a hook bites the rail |
| `hook_cut` | a hook line is cut |
| `splash` | a small splash |
| `overboard` | an enemy or summon goes overboard |
| `shark_leap` | a shark leaps and lands |
| `kraken_rise` | the kraken surfaces (Reckoning, Old Hollow-Eye) |
| `tentacle_grab` | a tentacle seizes a summon |
| `powder_blast` | a keg or Powder Wraith bursts |
| `fuse_hiss` | a lit fuse (Powder Runner, Wraith) |
| `cutlass_clash` | steel on steel |
| `cutlass_slash` | a cutlass swing |
| `bosun_whistle` | the boatswain's bellow / the Ghost Bosun's whistle |
| `hull_creak` | the Heave telegraph, the deck tilting |
| `plank_drop` | a boarding plank lands or falls |
| `wave_crash` | the Reckoning's great wave |
| `coin_chime` | Marrec's cursed coins |
| `ghost_moan` | the Oath breaks, ghost crew |

Nothing plays them until the stage code wires its sound map.

## Needs the owner's eye
- `ghost_bosun` converted mostly navy-blue with green rim light rather than the ghost green; `ghost_helmsman`, `powder_wraith` and `magazine_lord` are small and dark (converted with the level stretch).
- Female figures (swashbuckler, gunnery_mate, voodoo_navigator, marrec, corsair_queen) wear blouses with a cream neckline (covered, as `battle_sister`); rigs were fitted from a grid check, not yet seen in motion in the engine.
- Hand-rolled sea water (no AI source): a plain navy with foam dashes; no shore / rail art was made (the code draws rails and the hull edge).

## Round 1 (the owner's marks)

- **Playable characters redone as purple necromancers** (`player/marooned_quartermaster`, `player/corsair_queen`, `player/ghost_helmsman`; 56 px tall, 32 to 52 wide): the necromancer's violet, bone white and soul-teal on pale undead skin, the act's theme only in cut and props (quartermaster: tricorn, peg leg, shackle, a ship's-lantern staff; queen: plumed tricorn, long coat, a glowing cutlass focus, figure-redesign style, covered; helmsman: hooded oilskin, a wheel-topped lantern staff, anchor charm). Walk strips are robe glides; the queen has her bust rig (box widened 2 px to the right) and idle strip. Prompts and refs: `art_source/corsair/make_art.py` (`CHAR_COL`, `CHAR_RAMPS`; references `player/necromancer`, `ferrywoman`, `shrine_maiden`).
- `bosun_gorran_walk`: the hanging chain-hook swings (pendulum rig). `grappler_walk`: the hook line swings round in the air (pendulum).
- `gunnery_mate` bust box up 2 px, `marrec` up 4 px, `swashbuckler` refit to rows 14-19 (idle and walk rebuilt).
- `hull_crab` regenerated: a speckled, coloured crab (orange-red shell, cream speckles), no grey. `old_hollow_eye` regenerated as a whole kraken (bulbous head, hollow eye, eight tentacles, 72x72 art, 76 with the hover rows).
- `kraken_arm_walk` and `old_hollow_eye_walk`: the tentacles wave (rows sheared by a sine growing toward the tips, foam fixed; `wave_strip()` in `make_art.py`). `vandermere_walk`: the wheel turns (`rotor` disc rig, 11.25 degrees a frame, loops every 8 frames). `powder_wraith_walk`: a small amber flash at the keg's fuse on frames 1, 2, 5 and 6 (`flash_strip()`).

## Round 2 of the owner's art review (Nov 7, 2026)
- `swashbuckler` bust box moved onto the white blouse (cols 20-28, rows 14-18; it sat on the red sleeve), idle and walk rebuilt. `grappler_walk` rebuilt: only the rope loop and the hook swing, about his hand (`pendulums` entry with the new `exclude` field: the old box also took his head); the head stays still and the line stays attached. Check sheets: `docs/last_acts/bust_check/`.
