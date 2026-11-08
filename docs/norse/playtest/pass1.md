# The Hall of the Slain: balance pass 1

Goal (`docs/last_acts/PLAN.md`): tune the act for its final slot VI, about the Shogunate's difficulty (yardstick
`docs/act5/playtest/pass3.md`: the Road to the Sun, 1 death in 15 non-naive runs, army min HP 92, newclasses 53). Targets:
non-naive builds ~1-2 deaths in 15 per stage (army and summon 0, army min HP 90+), naive ~1-2 of 3, the boss slain most
runs, the Barrow Fields the easiest.

All runs: meta none, `--mortal`, seeds 3 / 7 / 11, builds as `docs/act7/tools/playtest_round.sh`.

## Pass 1 (before the changes)

Table `pass1_report.md`, logs `pass1_logs/`. Cells: died / boss slain / mean min HP, 3 runs each.

| build | barrow_fields | valgard | vigrid |
|---|---|---|---|
| army | 0/2/110 | 1/2/94 | 0/2/89 |
| evolve | 0/2/90 | 1/2/64 | 0/3/96 |
| summon | 0/2/111 | 0/2/81 | 0/3/98 |
| newclasses | 0/1/53 | 2/1/28 | 3/0/25 |
| newspells | 0/2/113 | 0/3/88 | 2/1/73 |
| naive | 2/0/31 | 3/0/37 | 3/0/45 |

The deaths: the necromancer takes almost nothing before 7:00 (HP 120 at 8:00 in most death logs) and then bleeds 250-450 HP
in 3-5 minutes with little or no healing (the flanker build has no priest). The top sources are the shared warriors (raider,
shield-maiden, berserker), then the wolves' lunges, the valkyries' dives (Valgard) and the frost giants' stomps (Vigrid).

`valgard summon s11` ended with `stuck_units=1`: a shield-maiden 119 px from the player during Sigrun's **Holmgang**. The
duel square pushes every other enemy to its verge (`Holmgang.ENEMY_BAND`) for 15 s while her target, the duellist, stands
inside: longer than the stuck check's 10 s. Fix (autotest only, `scripts/core/autotest.gd` `_enemy_wants_move()`): an
enemy held at an open Holmgang's verge does not count as wanting to move, as the Act IX check ignores stunned summons.

## Changes (old -> new)

Iteration 1 (tested on valgard / vigrid newclasses + army and valgard summon s11):

| file | value | old | new |
|---|---|---|---|
| `scripts/data/stages/barrow_fields_stage.gd` | `ENEMY_DAMAGE_MULT` | 1.4 | 1.25 |
| `scripts/data/stages/valgard_stage.gd` | `ENEMY_DAMAGE_MULT` | 1.45 | 1.3 |
| `scripts/data/stages/vigrid_stage.gd` | `ENEMY_DAMAGE_MULT` | 1.45 | 1.3 |
| `scripts/data/norse_enemy_data.gd` | raider `damage` | 3.0 | 2.5 (the Ashigaru's) |
| `scripts/data/norse_enemy_data.gd` | shield_maiden `damage` | 4.0 | 3.5 |

Result: valgard newclasses 0/3 died (min HP 12 / 26 / 14), army 0/3; vigrid army 0/3 (min 103), newclasses still 3/3 dead,
all at 12:30-12:54 (the Muspel giant's march: his escort's wolves and the 11:20 wolf ring). Valgard summon s11:
`stuck_units=0`.

Iteration 2 (final):

| file | value | old | new |
|---|---|---|---|
| `scripts/data/stages/barrow_fields_stage.gd` | `ENEMY_DAMAGE_MULT` | 1.25 | 1.2 |
| `scripts/data/stages/valgard_stage.gd` | `ENEMY_DAMAGE_MULT` | 1.3 | 1.25 |
| `scripts/data/stages/vigrid_stage.gd` | `ENEMY_DAMAGE_MULT` | 1.3 | 1.2 |
| `scripts/data/norse_enemy_data.gd` | wolf_of_the_wastes `lunge_damage` | 4.0 | 3.0 |

Net: the three stage multipliers 1.4 / 1.45 / 1.45 -> 1.2 / 1.25 / 1.2 (from 7:00), raider 3 -> 2.5, shield-maiden 4 -> 3.5,
wolf lunge 4 -> 3. Only Norse files; no other act's kind or data is touched (stages 1-30 unchanged).

## Pass 2 (after the changes)

Table `pass2_report.md`, logs `pass2_logs/` (36 runs: army, newclasses, newspells, naive). Cells: died / boss slain / mean
min HP.

| build | barrow_fields | valgard | vigrid |
|---|---|---|---|
| army | 0/1/117 | 0/3/83 | 0/3/90 |
| newclasses | 0/1/55 | 1/2/43 | 2/1/32 |
| newspells | 1/0/108 | 0/3/118 | 2/1/74 |
| naive | 3/0/62 | 2/0/56 | 3/0/45 |

Every run: 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines, `stuck_units=0`.

Non-naive deaths (army + newclasses + newspells): barrow 0 -> 1 of 9, valgard 3 -> 1, vigrid 5 -> 4. The army bot never dies
and Valgard and Vigrid's bosses fall in every army run.

## Open (for the owner / pass 2)

The deaths left are **bursts**, which the stage multiplier barely moves (vigrid newclasses s3 died at 12:42 with the
multiplier at 1.45, 1.3 and 1.2 alike):

- **Barrow Fields:** berserkers (206-266 of the dead bot's damage; always in the fury, a skald's song on top), e.g. HP 109 at
  13:00, dead at 13:32 (newspells s3). Hrimgar survives 2 of 3 army runs by a hair (57 and 2,546 of 19,200 HP left): a small
  Hrimgar HP cut would make him fall most runs. Naive dies 3 of 3 here (target 1-2).
- **Valgard:** the valkyries' dives on the necromancer (95-156 in the newclasses deaths).
- **Vigrid:** the frost giants' stomps and the Muspel giant's escort around 12:00-12:45 on the flanker build; the newspells
  build died at 9:43 far from the fires (nearest fire 1,207 px).

Suggested next levers, one each: berserker `damage` 5 -> 4, valkyrie `dive_damage` 7 -> 5 (on the necromancer), the
frost giant's stomp, Hrimgar's HP.

## Pass 3 (the burst levers, one iteration)

| file | value | old | new |
|---|---|---|---|
| `scripts/data/norse_enemy_data.gd` | berserker `damage` | 5.0 | 4.0 |
| `scripts/data/norse_enemy_data.gd` | valkyrie `dive_damage` (necromancer and summons) | 7.0 | 5.0 |
| `scripts/data/norse_enemy_data.gd` | frost_giant `stomp_damage` | 5.0 | 3.75 |
| `scripts/data/hrimgar_data.gd` | `MAX_HP` | 12,000 | 10,200 |

Table `pass3_report.md`, logs `pass3_logs/` (45 runs, five builds). Cells: died / boss slain / mean min HP.

| build | barrow_fields | valgard | vigrid |
|---|---|---|---|
| army | 0/2/114 | 0/3/88 | 0/3/105 |
| evolve | 0/0/116 | 0/3/80 | 1/2/78 |
| newclasses | 1/1/59 | 1/2/35 | 3/0/31 |
| newspells | 1/2/96 | 0/3/108 | 2/1/67 |
| naive | 2/1/70 | 3/0/53 | 3/0/26 |

Every run: 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines, `stuck_units=0`. Non-naive deaths 2 / 1 / 6 of 12. The army bot
never dies and Sigrun and Odin fall in every army run. The rest is left to the owner's own playtests: Vigrid's flanker
(newclasses) and spell builds, and Hrimgar on the evolve build (0 of 3).
