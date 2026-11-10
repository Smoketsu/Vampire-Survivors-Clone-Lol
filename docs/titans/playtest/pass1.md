# The Age of Titans: balance pass 1 (Nov 2026)

Meta none, `--mortal`, seeds 3 / 7 / 11. Tuned for the final slot XIV, above the Concord (Act IX; yardstick
`docs/act9/playtest/pass2.md`: the Ark 4 deaths of 15 non-naive runs). Within the act the Fern Basin must be the easiest
stage and the Last Day the hardest. Lowest HP below is the autotest `min_hp_before_0` line (the report script's
`min_hp` column is wrong for runs that died).

## Pass 1 (before; `pass1_report.md`, `pass1_logs/`)

Died of 3 / boss slain:

| build | fern_basin | great_plain | last_day |
|---|---|---|---|
| army | 0/3 | 0/3 | 0/2 |
| evolve | 0/3 | 0/3 | 0/2 |
| summon | 0/3 | 0/2 | 0/1 |
| newclasses | 1/2 | 0/3 | 1/2 |
| newspells | 1/2 | 0/2 | 3/0 |
| naive | 2/0 | 1/0 | 2/0 |

The Fern Basin (meant to be the easiest) had more non-naive deaths than the Great Plain.

## Why the Frill-Spitter killed

The Frill-Spitter was the top damage source to the necromancer in 10 of the 11 deaths (up to 1,015 in one run). Its
bolt is the plain hostile shot: it stops on the first summon in its line, so it does not fly over the ring. With a
full army it was harmless (army / summon builds took 7-250 from it). Two things made it lethal where the ring was thin
(the spell-only and naive builds, the gaps a broken ring leaves):

- **Its row:** 5 damage every 2.6 s from 250 px (1.9 DPS before the time scaling and ×1.4), more than every other
  slot-VII+ trickle shooter (the Nile Archer 4.5 / 2.8 s, the plain Archer 4 / 2.6 s, the Concord's shooters deal their
  damage through beams).
- **The Fern Basin's timeline:** its spitter weight rose 4% → 7% by 10:00, where the Great Plain and the Last Day hold
  4.5%; so the Fern Basin spawned the most of them (mean 200 a run in the four builds below, against 175 and 126).

## Changes (old → new)

| file | value | old → new | why |
|---|---|---|---|
| `scripts/data/primeval_enemy_data.gd` | `frill_spitter` `damage` | 5 → 4 | the plain Archer's bolt |
| `scripts/data/primeval_enemy_data.gd` | `frill_spitter` `attack_interval` | 2.6 → 3.2 s | a lobbed glob, slower than an arrow (DPS −35% with the damage) |
| `scripts/data/stages/fern_basin_stage.gd` | `SEGMENTS` spitter weight | 0.04 / 0.05 / 0.06 / 0.06 / 0.07 / 0.07 / 0.06 → 0.04, then 0.045 flat | the Great Plain's; the share goes to the Scuttlers |
| `scripts/data/stages/fern_basin_stage.gd` | boss segment `rate` / `max_alive` | 2.0 / 56 → 1.7 / 48 | iteration 2: the army bot died in Scarmaw's fight on seed 7 |

Frill-Spitter damage to the necromancer, mean per run (army, newclasses, newspells, naive): the Fern Basin 321 → 241
(spawns 200 → 146), the Great Plain 275 → 213, the Last Day 181 → 105. It is no longer the top source in any pass 2
death (Scuttlers lead in every one).

## Pass 2 (after; `pass2_report.md`, `pass2_logs/`; iteration screen `pass2_iter/`)

Died of 3 / boss slain / lowest HP per seed (3, 7, 11):

| build | fern_basin | great_plain | last_day |
|---|---|---|---|
| army | 1/2 · 111, 34, 112 | 0/3 · 102, 77, 99 | 0/3 · 103, 102, 115 |
| newclasses | 0/3 · 69, 83, 87 | 0/3 · 43, 101, 23 | 1/2 · 24, 47, 10 |
| newspells | 1/2 · 66, 29, 28 | 0/2 · 69, 16, 5 | 1/0 · 60, 56, 12 |
| naive | 0/0 · 56, 44, 21 | 1/1 · 2, 109, 99 | 3/0 · 7, 0, 8 |

Every run: zero `SCRIPT ERROR` / `ERROR:` / `WARNING:`, `stuck_units=0`. Non-naive deaths: the Fern Basin 2 of 9, the
Great Plain 0 of 9, the Last Day 2 of 9. The Last Day's newspells reached the goal (3 → 1 of 3); the Fern Basin's naive
is easier than asked (0 of 3, lowest HP 21).

## Left open

- **The Fern Basin army death (seed 7, 18:29, in Scarmaw's fight) is not the Frill-Spitter.** Ironjaw's nest was never
  broken in that run and hatched 146 Scuttlers (8-22 in the runs that broke it; pass 1's seed 11, lowest HP 30, also
  hatched 148), so 60 Scuttlers were alive in the boss fight against a ring without Warders (army cap 37 against
  pass 1's 45: the card offers diverged). The thinner boss segment did not save it, because the nest hatches past the
  alive cap. The next lever is the nest (`PrimevalNestKit` / `fern_basin_enemy_data.gd`: its hatch rate, a hatch cap
  or a lifetime), left to the owner since it changes how the miniboss fight reads.
- The Fern Basin's newspells death (seed 11, 11:51) is early and spread over Scuttlers, a Tyrant and the spitters.
- Evolve / summon builds were not re-run (neither died in pass 1, and the Frill-Spitter barely touched them).
