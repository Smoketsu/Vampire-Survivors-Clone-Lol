# The Turning Year: balance pass 1 (Nov 2026)

Meta none, `--mortal`, seeds 3 / 7 / 11. Tuned for the final slot XV, the campaign finale and the hardest act; within the
act the Greenwood must be the easiest stage and the World-Tree the hardest. Lowest HP below is each log's
`min_hp_before_0` line (the report script's `min_hp` column is wrong for runs that died).

## Pass 1 (before; `pass1_report.md`, `pass1_logs/`)

Died of 3 / boss slain / mean lowest HP:

| build | greenwood | fae_court | world_tree |
|---|---|---|---|
| army | 0/3/80 | 0/3/83 | 0/3/86 |
| summon | 0/3/92 | 1/1/56 | 0/3/93 |
| evolve | 0/3/47 | 0/3/53 | 1/2/31 |
| newclasses | 0/3/43 | 1/2/21 | 0/3/51 |
| newspells | 2/1/22 | 3/0/7 | 1/2/31 |
| naive | 3/0/7 | 3/0/14 | 3/0/6 |

Two problems: the Fae Court (the middle stage) was harder than the finale (5 non-naive deaths of 15 against 2 and 2),
and the thin-ring builds died early (newspells at 5:12 and 9:15 on the Greenwood, 10:29-12:08 on the Fae Court, 8:15 on
the World-Tree).

## Causes

- **The Treant** was the top damage to the necromancer in most early deaths (up to 345 a run). A spell-only build could
  not clear it (420 HP x 2.2, armour 0.3: ~1,300 effective HP), so 17-33 of them piled up by 8:00-10:00 and walked
  through the thin ring, 11 damage a branch.
- **The Fae Knight** (up to 222) blinks into the ring (it lands 90 px from the necromancer's edge) and hit for 8 every
  1.0 s: the highest damage per second of the shared kinds, and the worst summon killer of the Fae Court (9,400 on
  the summon bot that died).
- **The Fae Court** had the Greenwood's spawn ramp (2.7 / 72 from 10:00, 3.0 / 84 from 15:00) and its 7:00 step on top
  of its own rules (the densest hedges, the fairy rings, the Winter Prince's minute), where the World-Tree has a
  thinner ramp (2.5 / 66, 2.7 / 76) and its step at 8:00. Its deaths fell at 10:29-12:08, just after the 10:00 ramp
  and into the Winter Prince's minute (11:40).

## Changes (old -> new)

| file | value | old | new |
|---|---|---|---|
| `scripts/data/wild_enemy_data.gd` | Treant `damage` | 11 | 8.5 |
| `scripts/data/wild_enemy_data.gd` | Treant `max_hp` (iteration 2) | 420 | 340 |
| `scripts/data/wild_enemy_data.gd` | Fae Knight `damage` | 8 | 6.5 |
| `scripts/data/stages/fae_court_stage.gd` | `ENEMY_MULT_FROM` | 420 (7:00) | 480 (8:00, as the World-Tree) |
| `scripts/data/stages/fae_court_stage.gd` | segments 10:00 / 15:00 (rate / max alive) | 2.7 / 72, 3.0 / 84 | 2.5 / 66, 2.7 / 76 (as the World-Tree) |

Iteration 1 (the first, second and last two rows; `pass2_iter/`, newspells on every stage, the Fae Court's summon and
newclasses): the Fae Court's newspells 3/3 deaths -> 0/3, summon 0/3, newclasses 1/3 (17:28); still one early
newspells death on the Greenwood (8:22) and the World-Tree (9:42), the Treant again their top damage with 17-33 alive,
so iteration 2 cut its HP.

## Pass 2 (after; `pass2_report.md`, `pass2_logs/`)

Died of 3 / boss slain / mean lowest HP:

| build | greenwood | fae_court | world_tree |
|---|---|---|---|
| army | 0/3/69 | 0/3/72 | 0/3/95 |
| summon | - | 2/1/44 | - |
| newclasses | 0/3/48 | 0/3/27 | 0/3/56 |
| newspells | 0/3/47 | 2/1/15 | 1/1/8 |
| naive | 2/0/7 | 3/0/4 | 3/0/10 |

Deaths: no non-naive death before 11:28 (World-Tree newspells; then the Fae Court's newspells 12:33 and 17:56, summon
13:14 and 19:03 in the Queen's fight); naive from 9:49 (Fae Court), the others 11:41-19:52. Army 0 deaths and every
boss slain on all three stages. Every run: 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:`, `stuck_units=0`.

The same builds against pass 1 (army + newclasses + newspells, 9 runs a stage): the Greenwood 2 -> 0 deaths, the Fae
Court 4 -> 2, the World-Tree 1 -> 1.

## Open

- **The Fae Court's summon build** is noisy on these seeds (pass 1 1/3, iteration 1 0/3, pass 2 2/3 with only the
  Treant's HP changed); its deaths and the Fae Court's newspells death at 12:33 come in or just after **the Winter
  Prince's minute** (he dealt 74-159 to the necromancer there). He is the next Fae Court lever if the owner's runs
  agree (his `damage` 10, or the minute's `winter_fae` 0.15).
- The Greenwood now loses no non-naive run on these seeds, so it is clearly the easiest; the World-Tree's newspells
  build is the act's thinnest (one death, one boss).
