# Content wave 2: common brief for every workstream

You are one of five parallel Opus agents building **content wave 2** of **Necropathy** (Godot 4.3,
GDScript). The lead (another Claude session) merges your branch on `integration` afterwards.

Read first, in this order:
1. `CLAUDE.md` in your worktree (conventions: document EVERY variable / constant with a comment and
   units; tunables in `scripts/data/*.gd` tagged `# TUNING (not in GDD)`; static typing; determinism
   per seed; one path per modifier; no physics engine; autotest-friendly; UI rules).
2. `docs/GDD.md` §15.0, the newest rows at the end of the table, especially **"Content wave 2
   (owner decisions, Oct 2026)"**: that row is your spec. Its rule "no act-specific summon mechanics"
   applies to everyone.
3. The owner-approved proposal text below (what each workstream builds).

## The five workstreams (yours is named in your task)

- **A. Victory screen** (Proposal 1).
- **B. Achievement rewards** (Proposal 2): titles, achievement-gated unlocks, five new achievements.
- **C. Ultimates** (Proposal 4): Sovereign's Decree, Eclipse, Grave Tide beside Dread Rally.
- **D. Bone Golem** (Proposal 5): the 15th summon class, its evolution, passive and synergy.
- **E. Illustrated epilogue** (Proposal 3).

## Shared contract (fixed ids and ownership; do not rename)

- Ultimate ids: `dread_rally` (exists, the default), `sovereigns_decree`, `eclipse`, `grave_tide`.
  **C** owns the ultimate system, `scripts/data/ultimate_data.gd`, the pre-run picker and the
  autotest `--ultimate=ID`; the choice is `RunConfig.ultimate_id` (default `"dread_rally"`) and is
  remembered in Meta `[prerun] ultimate`. C reads `Unlocks.is_open(id)` for the picker (an id absent
  from `UnlockData` is open, so C works before B's rows exist).
- Summon class `bone_golem`, evolution `ossuary_titan`, passive `grave_masonry`, synergy
  `charnel_house`: **D** owns them, AND the two `UnlockData` rows that lock `bone_golem` and
  `grave_masonry` behind the achievement `bone_legion` (so a fresh save never offers them and Act I
  same-seed summaries stay identical).
- Achievements: **B** owns `MetaData.ACHIEVEMENTS` (the existing 7 and the 5 new ones: `mass_grave`,
  `untouchable`, `full_ossuary`, `deathlords_due`, `swift_judgment`), the reward types "ultimate",
  "skin", "title" in `UnlockData` / `Unlocks`, the `UnlockData` rows for the three new ultimates and
  every title / skin reward, `TitleData` (titles) and the Meta save fields they need. B shows the
  selected title on the pre-run screen. The victory card (A) gets the title line at integration.
- **A** owns `scripts/data/victory_data.gd`, the victory path of `scripts/ui/end_screen.gd`, the last
  stand (visual only, after the death is counted) and a per-stage best "time past 0:00" record.
- **E** owns `scripts/data/epilogue_data.gd`, `scripts/ui/epilogue_screen.gd`, the 7 panels and the
  autoplay-once flow (Meta flag per part seen; played when the player returns to the main menu after
  a run that opened a part).

## Shared files: how to edit them

Five agents edit in parallel. Keep shared-file edits **small and additive**: new work in **new
files**; additions to shared tables at the **end** of the table under a comment line
`# --- Content wave 2: <your workstream> ---`; never reorder or reformat existing lines; never change
another workstream's files. A minimal, generic, documented engine hook is fine; list it in your report.
**Stages 1–6 must keep their same-seed autotest summaries** with default options (everything new is
inert unless chosen or unlocked). Check it: run your branch and the base (`e0a3eb5`) with the same
`--seed` on `graveyard` and `harbour` and diff the summary lines.

Docs: add your own GDD §15.0 row(s) at the END of the 15.0 table (just before
`### 15.1 Core Rules and Run Structure`), README sections / architecture lines / autotest options for
your parts, ART_BIBLE manifest rows for your art. Don't rewrite others' text; leave CLAUDE.md to the lead.

## CPU budget (4 cores shared by five agents)

- **Never run more than ONE Godot process at a time** in your worktree.
- Import check: `/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64 --headless --import` (a fresh
  worktree's first import takes a few minutes; it must print no errors).
- Autotest: `.../Godot_v4.3-stable_linux.x86_64 --headless --fixed-fps 60 --quit-after 15000 -- --autotest [options]`.
- Logs go under `/tmp/claude-0/-home-user-vampire-survivors-clone-lol/d5c098ec-bb2d-5b61-bfc3-6ed79c1e8fd5/scratchpad/wave2/<workstream>/`.
- "Done" for you: import clean; zero `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines; `stuck_units=0`;
  default, `--mortal` and `--policy=army` runs; the same-seed gate above; your own feature exercised by
  the autotest (add options / summary lines for it). Balance work only where your task says so.

## Art pipeline (true pixel art) — the owner reviews ALL new art at the end

- Read `docs/art/ART_BIBLE.md`. Generate with the API tool, ALWAYS with the ledger env var exactly:
  `GEN_LEDGER=/home/user/vampire-survivors-clone-lol/docs/art/generation_ledger.csv python3 tools/gen_image.py <prompt file> <out png> --ref <anchor> --key <sprite key>`
  (never read, print or set any API key; the proxy adds it).
- Convert with `tools/prepare_sprite.py` (small detailed figures through `tools/pixelate_source.py`
  first; `--no-prune` keeps a small ramp such as skin); walk strips with `tools/walk_cycle.py`; check
  with `tools/art_check.py`. Missing art falls back to code glyphs, so gameplay first.
- Owner art notes from the last review: details must be big enough to read at game size (no busy
  specks); a thin mesh or lattice does not survive conversion (draw it on the grid instead, as
  `tools/mesh_props.py` does); faces must read clearly. Keep your prompt files and sources in your
  scratch folder and list every new PNG in your report (the lead builds the owner's review page).

## Git

Work in your worktree on your own branch. Commit in sensible steps; end each commit message with
these two lines exactly:
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
`Claude-Session: https://claude.ai/code/session_01FLPv2RqRe5qVsRWxUhur7z`
Never mention model identifiers elsewhere. Push your branch as a backup (`git push -u origin <branch>`,
retry on network errors). Never push to `main` or `integration`. Use `git commit -F <file>` for messages.

## Final report (your last message)

Branch and commits; what you built (files); shared files touched and why; GDD rows added; test
results (numbers); every new PNG and the art cost; anything left open or decided on your own.
