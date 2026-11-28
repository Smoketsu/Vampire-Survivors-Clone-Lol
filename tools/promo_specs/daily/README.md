# Daily TikTok clip (one a day, delivered by 5:30 pm US Eastern)

Run by a scheduled task every day. One clip, 7-10 s, 1080 x 1920, in the owner-approved style (`make_specs.py` header:
a solo dev's voice, ONE lowercase hook line for 2.2 s, clean gameplay, hard cuts, the quiet end card).

## Steps

1. **Already done?** If `captions.txt` here has a line for today's date (US Eastern), stop and say so.
2. **Setup** (fresh container): the Godot 4.3-stable Linux binary at `/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64`
   (download the official zip from the Godot GitHub release if missing). `tools/promo_daily.sh` imports the project itself.
3. **Pick an idea not used before**: read the hooks in `../make_specs.py` (HOOKS), `../batch2_days.py` and
   `../daily_days.py`. One subject per clip (an enemy kind, a boss, a summon class or evolution, a spell, a character,
   a stage rule). The 45 stages, their kinds and `--spawn=` / `--boss=` / `--classes=` / `--spells=` / `--character=`
   ids are listed in `CLAUDE.md` and the README autotest table.
4. **Add the clip**: append one `add("YYYY-MM-DD", hook, cuts, [4 shots])` to `../daily_days.py` (format in its header).
5. **Render**: `tools/promo_daily.sh YYYY-MM-DD` (about 5 minutes; at most 3 Godot processes, the tool's default).
   Output in `build/promo/daily/`: `DATE_tiktok.mp4` (post this one), `DATE.mp4` (long cut), `storyboard.png`.
6. **Check by eye**: read `storyboard.png`. Every shot must clearly show what the hook says, near the middle of the
   frame, with no drawing glitch. If not, change the start second / seed / spawn count and render again (a shot's
   subject usually reaches the necromancer 20-25 s after a `--spawn=`). Two or three passes are normal.
7. **Caption**: append `DATE: caption` to `captions.txt` (style of `../batch2/captions.txt`: one lowercase line, one
   emoji, the same five hashtags).
8. **Commit and push** `daily_days.py`, `daily/DATE.json` and `captions.txt` (never the video: `build/` is ignored).
9. **Deliver**: send `DATE_tiktok.mp4` to the owner with the caption text, ready to paste.

## The two spin-offs (about twice a week, e.g. Wednesday and Saturday; the main game otherwise)

No span recorder there: record the whole run with Godot's Movie Maker and cut with ffmpeg. Both commands were
checked on Nov 28, 2026 (run `$G --headless --import` in the repo first; `$G` = the Godot binary).

- **Gravewatch** (`/home/user/Tower-Defence-Necropathy`, landscape 1280 x 720). The bot plays at x8 and drops to x1 from
  wave N; each `PERF t=` log line is one game second at x1, so the x1 part starts where they begin (about 32 s into
  the movie for wave 14 on the Sanctum):
  `xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 --write-movie out.avi --quit-after 2400 -- --autotest --map=<map id> --speed=8 --perf-wave=<N> --seed=1`
  (about 3 minutes). For 9:16, stack it: the 1280 x 720 picture scaled x1.5 with `flags=neighbor` and cropped to
  1080 wide around the action, on a dark violet 1080 x 1920 canvas, the hook line above it.
- **Ossuary Tactics** (`/home/user/Necropathy-Auto-Battler-`, has a real portrait layout, so it fills 9:16):
  `xvfb-run -a -s "-screen 0 1080x1920x24" $G --rendering-driver opengl3 --resolution 1080x1920 --fixed-fps 30 --write-movie out.avi --quit-after 900 -- --layout=portrait --screen-bot --screen-speed=1 --seed=3`
  The first waves are sparse; for a big fight use the battle view flags (`--view-board=full --view-wave=N --view-act=ID`).
- Hook text for these: ffmpeg `drawtext` with `assets/fonts/Jersey10-Regular.ttf`, white, 76 px, black outline, top
  at y 250, inside x 80..918, shown for the first 2.2 s. Encode like `tools/promo_quickcut.py` (H.264 high, yuv420p,
  CRF 14, AAC), end on the same two lines as the end card with that game's name. Keep the caption style; swap the
  first hashtag for `#towerdefense` or `#autobattler`.
- If a spin-off clip does not look good after two passes, make a main-game clip that day instead.
