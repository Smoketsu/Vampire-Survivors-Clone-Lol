# daily_days.py: the daily TikTok clips, one add() per day, newest last (exec'd by make_specs2.py, which provides add()).
# add(date "YYYY-MM-DD", hook line (lowercase, no "!", about 50 characters at most), cuts (later shots the quick cut keeps),
#     [(stage id, seed, start game second, extra autotest args, what the frames were confirmed to show), ...])
# Rule from batch 1: every shot must show what the hook says. Do not repeat a hook from make_specs.py, batch2_days.py or here.
add("2026-11-28", "a t-rex showed up in my necromancer game", 3, [
    ("last_day", 6, 73, ["--spawn=tyrant@50x3"], "tyrants"),
    ("great_plain", 5, 74, ["--spawn=tyrant@50x3"], "tyrants"),
    ("last_day", 4, 73, ["--spawn=tyrant@50x3"], "tyrants"),
    ("fern_basin", 4, 74, ["--spawn=tyrant@50x3"], "tyrants")])
