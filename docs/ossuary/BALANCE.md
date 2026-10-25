# Ossuary expansion: balance batch (Oct 25, 2026)

Branch `ossuary/balance`, from `integration` 7ce7e4d (all five Ossuary parts merged). Tool: `tools/ossuary_balance.py`
(parses the autotest summaries; resumable; `--parse-only` rebuilds the tables). Every run is a headless `--autotest --mortal`
(no `--meta-save`, so no save was touched). Per-run data: `docs/ossuary/balance_runs.csv` (324 runs, column `set`).
`--meta=max` means everything bought: all levels 1-10, the ten new options and the Dominion tree, 51 Mastery levels, and the
fixed relic set Black Banner + Bone Abacus + Mourner's Bell.

## 1. The plain batch (seeds 1-8 at meta none, seeds 1-4 at meta max; trimmed data)

Meta none is unchanged by the expansion and by the trims (the trims only touch deep levels, Masteries and Bone Reserve, none
of which exist at meta none): the seed-7 Graveyard army run was re-run after the trims and its summary is **IDENTICAL**
(`same_seed_gate.py`, 187 lines). `ossuary_check.tscn` PASS, `--import` clean, 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:` and
`stuck_units=0` in every run but one (round 0, forced spells A, Citadel Deathlord seed 8: one stuck Empire `enemy_spotter`, an enemy, unrelated to the Ossuary).

| Config | Runs | Deaths before 0:00 | Boss kills | Lowest HP before 0:00 (median / min) | Build complete (median) | Past 0:00 s (median, range) | Soul Ash (median) |
|---|---|---|---|---|---|---|---|
| Graveyard, meta none, army | 8 | 0 | 8 | 107 / 94 | 15:36 | 18 (12-23) | 495 |
| Harbour, meta none, army | 8 | 0 | 8 | 107 / 94 | 16:28 | 9 (7-11) | 458 |
| Citadel, meta none, army | 8 | 0 | 8 | 73 / 24 | 15:26 | 34 (24-37) | 1,368 |
| Graveyard, meta none, naive | 8 | 2 | 6 | 97 / 2 | 15:18 | 16 (10-19) | 481 |
| Harbour, meta none, naive | 8 | 2 | 3 | 26 / 1 | 15:09 | 8 (6-11) | 265 |
| Citadel, meta none, naive | 8 | 7 | 1 | 2 / 0 | 15:09 (1 run) | 28 | 275 |
| Graveyard, meta max, army | 4 | 0 | 4 | 168 / 168 | 14:16 | 41 (35-65) | 711 |
| Harbour, meta max, army | 4 | 0 | 4 | 177 / 177 | 14:15 | 30 (26-37) | 633 |
| Citadel, meta max, army | 4 | 0 | 4 | 153 / 144 | 13:53 | 56 (54-57) | 2,172 |
| Graveyard, meta max, naive | 4 | 0 | 4 | 165 / 163 | 13:52 | 42 (24-75) | 724 |
| Harbour, meta max, naive | 4 | 0 | 4 | 173 / 142 | 14:31 | 26 (21-28) | 619 |
| Citadel, meta max, naive | 4 | 0 | 4 | 135 / 127 | 12:49 | 43 (40-46) | 2,123 |
| Citadel, meta max, army, Deathlord | 4 | 0 | 4 | 144 / 132 | 13:11 | 48 (45-52) | 3,953 |

(Max HP is 120 at meta none, 177 at meta max after the trims.)

New systems fired at meta max in every run: Bone Reserve (barrier on re-risen summons: 365-660 HP absorbed in an army run
after the trim, 11,000 before it in a Deathlord run), Commander's Presence (+15%, 5 classes), Echo Weaving (echoes from Lv 2),
Dark Tithe (+100-400 meter), Grave Ward (2 blows), Head Start (+2 levels), Chosen Vanguard, Patient Grave (2 rerolls), Elite
Bounty / Gilded Chests (Soul Ash and chest picks, no power), all 51 Mastery levels (3 x 17 classes), relics Black Banner
(meter starts 50%), Bone Abacus (13-20 rerolls a run) and Mourner's Bell (6-80 Grave Feasts, most on the Citadel). Last Rites
fires in the runs that fall below a quarter of their HP.

**Verdict, meta none:** matches every target (army 0 deaths, Alaric / Vael / Deus Ex Machina 8 of 8, min HP 94+ on the Graveyard
and Harbour; naive dies 2 of 8 on the Graveyard and Harbour, 7 of 8 on the Citadel, the known hard stage).
**Meta max:** clearly easier (every army and naive run reaches 0:00 and kills the boss, min HP 80-100% of max) and the Reckoning
ends every run 21-75 s past 0:00 (median 26-56; four runs are 21-29 s, i.e. just under the 30 s floor, none outlasts 90 s).
Builds complete at 12:49-14:31, earlier than the 16-18 min of meta none but above the 12:00 flag line.

## 2. The key test (the owner's definition of "too strong")

`--meta=max --hyper --oath=5 --pact` (everything bought, Hyper mode, the full Profane Oath, the Profane Pact taken first;
`--pact` makes every bot take the Pact, so `--policy=pact` is the same run as `--policy=naive --pact` and is not counted twice).
Pass criterion: **at least one third of the runs die before 0:00**. Nine build families of 8 runs, spread over four settings
(seeds 1, 5 Graveyard; 2, 6 Harbour; 3, 7 Citadel; 4, 8 Citadel on Deathlord): army, summon, evolve, naive, forced classes A
(`abomination,rogue,gargoyle,frost_wraith`), forced classes B (`bone_hound,banshee,corpse_catapult`), forced spells A
(`bone_spear,soul_siphon,corpse_explosion,plague_cloud`), forced spells B (`death_mark,bone_wall,soul_chains`), characters
(army bot as bone_oracle, wither_witch, tide_widow, rust_prophet, two runs each). 72 runs per round.

| Family | Round 0 (full expansion) | Round 1 (trim A) | Round 2 (trim B, final) | Meta none (reference) |
|---|---|---|---|---|
| army | 0 / 8 | 1 / 8 | 2 / 8 | 7 / 8 |
| summon | 0 / 8 | 0 / 8 | 0 / 8 | 7 / 8 |
| evolve | 1 / 8 | 3 / 8 | 2 / 8 | 7 / 8 |
| naive (= pact policy) | 5 / 8 | 3 / 8 | 4 / 8 | 8 / 8 |
| classes A | 2 / 8 | 2 / 8 | 3 / 8 | |
| classes B | 3 / 8 | 1 / 8 | 3 / 8 | |
| spells A | 3 / 8 | 3 / 8 | 4 / 8 | |
| spells B | 3 / 8 | 2 / 8 | 4 / 8 | |
| characters | 0 / 8 | 1 / 8 | 1 / 8 | |
| **Overall** | **17 / 72 (24%)** | **16 / 72 (22%)** | **23 / 72 (32%)** | 29 / 32 (91%, four families) |

Final round by setting: Graveyard 0 / 18 died, Harbour 1 / 18, Citadel 7 / 18, Citadel on Deathlord 15 / 18. Deaths came at
10:36 to 19:24 (median about 17:10); survivors ended 6-115 s past 0:00 (median about 25 s) with a median lowest HP of 58-141 in the
army / summon / evolve families and single digits for naive. Soul Ash for these runs: 1,900-3,600 a run (median about 3,100).

Reading it: without any Ossuary the setup is deadly (91% die), so Hyper + Oath 5 + Pact is a real challenge on its own; the
full Ossuary brought it to a quarter failures, and the trims to 32%, one run short of the third (24 of 72), inside the noise
of a 72-run sample (about +-5 points; the same data moved 24% -> 22% -> 32% across rounds with the Round-1 trim barely
visible). The strong builds (army, summon, evolve) on the Graveyard and Harbour stay far from death (lowest HP 100-177 of
177): the stage, not the meta, decides there; every failure is concentrated on the Citadel.

## 3. Changes made (data only, all marked `# TUNING (not in GDD)`; Hyper / Oath / Pact and meta none untouched)

| Value | Was | Now | File |
|---|---|---|---|
| `DEEP_VALUE_SHARE` (value of each level 6-10 as a share of the upgrade's per-level value) | 0.5 | 0.15 | `scripts/data/meta_data.gd` |
| Bone Reserve `per_tier` (barrier share of max HP per level; 3 levels) | 0.10 | 0.03 | `scripts/data/meta_data.gd` |
| Mastery `HP_PER_LEVEL` and `DAMAGE_PER_LEVEL` (3 levels) | 0.04 | 0.02 | `scripts/data/mastery_data.gd` |

Effect at meta max: max HP 195 -> 177 (levels 6-10 of Grave-Hardened Flesh now +1.5 each), damage reduction from deep Bone Mail
+9% -> +2.7%, deep minion / spell levels worth 30% of what they were, Masteries +6% HP and damage at level 3 (was 12%), Bone Reserve
barrier 9% of max HP (was 30%). Soul Ash prices are unchanged (the deep levels still cost what the economy needs; they are now a
modest sink, as intended by "levels 6-10 are smaller steps"). `tools/ossuary_check.gd` now reads these constants instead of
hard-coded numbers. README Masteries and Bone Reserve lines updated.

## 4. Verdict and what is left for the lead

* Meta none: unchanged, on target.
* Plain meta max: clearly easier, Reckoning ends every run (21-75 s past 0:00), builds complete 12:49-14:31.
* Key test: 32% (23 of 72) after the trims, from 24% before; short of the one-third bar by one run and well inside the noise, so
  it is not a clear pass. A further push would have to come from the remaining expansion levers, none of which is a pure number
  change: **Mourner's Bell** (every elite drops a Grave Feast: 80 hearts in a Citadel run; making it a chance needs a code
  change in `powerup_manager.gd`), **Black Banner** (`ult_start` 0.5, data), **Last Rites** / **Grave Ward** (survival, data),
  **Head Start** (+2 levels, data) and a further cut of `DEEP_VALUE_SHARE` (0.15 already leaves levels 6-10 nearly cosmetic).
  The owner may prefer to harden the Citadel itself or to accept 32% as "not easy": 8 of 9 families still lose a quarter to
  a half of their runs, only the summon bot is untouched.
* The naive and summon bots are the extremes (naive 4 of 8, summon 0 of 8 at every round).
