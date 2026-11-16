# Reorder pass part 3: slot tuning, pass 1 (Nov 15, 2026)

Meta none, `--mortal`, builds army / summon / evolve / newclasses / newspells, seeds 3 and 7 (10 runs a stage).
Columns: deaths before 0:00 out of 10, mean `min_hp_before_0` (taken from each log's `[metric]` line, so runs that died count
correctly). Before = `reorder_logs/`; round 1 = `reorder_pass1_logs/`; round 2 = `reorder_pass1_r2_logs/` (finished; the lead filled the column. Originally written while it was still running, when this
was written; fill it in from `python3 docs/act4/tools/playtest_report.py docs/last_acts/playtest/reorder_pass1_r2_logs`).

## Neighbour bands (non-naive builds, latest bot pass per stage)

| slot | act | deaths | mean min HP |
|---|---|---|---|
| II | Black Tide | 2/8, 0/10, 0/10 | 67 / 92 / 83 |
| V | Shogunate | 0/15, 4/15, 1/15 | 92 / 85 / 85 |
| VI | Hall of the Slain | 0/8, 1/8, 3/8 | 74 / 56 / 49 |
| VII | Necropolis Dynasty | 0/10, 0/10, 0/10 | 86 / 88 / 79 |
| X | Celestial Host | 3/8, 0/4, 0/4 | 52 / 64 / 82 |
| XIV | Age of Titans | 0/6, 0/6, 0/6 | 74 / 68 / 65 |
| XV | Turning Year | 0/6, 2/8, 1/6 | 52 / 37 / 47 |

Targets taken from these: slots III-IV ~1/10 and ~80; VIII-IX ~70; XI-XIII ~60-65 with the army bot never dying.

## Results

| stage (slot) | change | before | round 1 | round 2 |
|---|---|---|---|---|
| ravensmoor (III) | damage 1.5 -> 1.3 -> 1.2 | 2/10, 62 | 2/10, 73 | 2/10, 68 |
| witchwood (III) | damage 1.5 -> 1.3 -> 1.2 | 3/10, 60 | 2/10, 56 | 2/10, 63 |
| castle_sanguis (III) | HP 1.85 -> 1.7, damage 1.5 -> 1.3 -> 1.15 | 3/10, 38 | 1/10, 46 | 1/10, 57 |
| skid_row (IV) | HP 2.0 -> 1.85, damage 1.3 -> 1.15 (r2) | 1/10, 62 | 1/10, 53 | 0/10, 83 |
| fort_kessler (IV) | HP 2.0 -> 1.7, damage 1.3 -> 1.15 -> 1.1 | 5/10, 30 | 2/10, 54 | 1/10, 50 (stuck_units=8, see below) |
| liberty_heights (IV) | HP 2.0 -> 1.8, damage 1.3 -> 1.2 -> 1.05 | 2/10, 38 | 1/10, 45 | 2/10, 44 (both newspells at 7:36 / 8:02; stuck_units=1, see below) |
| ilion / olympus / underworld (VIII) | none | 1/10 66, 2/10 53, 4/10 54 | - | - |
| burning_gate / silk_palace / pandemonium (IX) | none | 1/10 57, 1/10 54, 4/10 39 | - | - |
| harbour (XI) | HP 1.15 -> 1.4, damage 1.22 -> 1.7 | 0/10, 106 | 0/10, 66 | - |
| archive (XI) | none | 2/10, 82 | - | - |
| spire (XI) | HP 1.2 -> 1.45 -> 1.35, damage 1.2 -> 1.65 -> 1.5 | 0/10, 93 | 3/10, 49 (all in the boss fight, army 1) | 1/10, 66 |
| wastes (XII) | HP 1.3 -> 1.4, damage 1.0 -> 1.1 | 1/10, 73 | 1/10, 57 | - |
| assembly / citadel (XII) | none | 0/10 51, 1/10 51 | - | - |
| crash_site (XIII) | damage 1.5 -> 1.7 | 1/10, 69 | 2/10, 57 | - |
| proving_moon (XIII) | damage 1.5 -> 1.8 | 0/10, 80 | 1/10, 68 | - |
| ark (XIII) | none | 3/10, 60 | - | - |

## Why

- Only the stage step-ups (`ENEMY_HP_MULT` / `ENEMY_DAMAGE_MULT` in `scripts/data/stages/<stage>_stage.gd`) changed; no kit, no
  shared table, no Soul Ash rule. The boss always gets the step, so a damage step also hardens the boss fight (the Spire's first
  round died there).
- The Olympian Republic and the Inferno were left alone: their same-seed rows match the old Act IV / VI passes exactly and they are
  already at or above the VIII-IX band (Underworld and Pandemonium 4/10). The Archive (2/10, both at the Archivist), the Assembly,
  the Citadel and the Ark are already in the XI-XIII band.
- The newspells build still dies at 7:30-9:00 on the Court and Last Line stages, just after the 7:00 step; the same happens on the
  Black Tide (slot II). It is the known spell-only weakness.
- Skid Row summon seed 7 had `stuck_units=1` in round 1 (a riot cop pressed against a building, 262 px from the player).
  Zero `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines in every log.

## Round 2 result (lead)

Round 2 values are kept: every army run reached 0:00 (14/14), no errors or warnings. The Court sits a hair above its
slot-III band (1-2 deaths, min HP 57-68) and the Last Line inside slot IV's (Skid Row 0/10 83). Two seeds per build: one
death either way is noise.

**Stuck units (gate failure, not tuning):** after the tuning, the city maps show stuck units that the pre-tuning pass
never had: `skid_row_summon_s7` round 1 (a riot cop against a building), `fort_kessler_summon_s7` round 2
(`{"enemy_boss": 8}`, the boss alive at 0:00 with 990 HP), `liberty_heights_army_s7` round 2 (one Warrior against an
obstacle). The lower numbers change the run's path, so these look like city-map pathing edge cases exposed by it;
they must be fixed before `main` moves.
