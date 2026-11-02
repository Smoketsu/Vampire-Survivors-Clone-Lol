# Necropathy: Marketing Plan

Prepared Nov 2, 2026 for the owner. Documentation only; no game code was touched.
Facts about the game come from CLAUDE.md, README.md, GDD §15.0 and `docs/proposals/NEW_ACTS_AND_ORDER.md`. Facts about
Steam, TikTok and prices come from web searches made today; each is marked **[verified]** (a source says it),
**[partly]** (third-party blogs only) or **[unverified]** (could not check; check before relying on it). Valve's
Steamworks documentation host was not reachable from this session, so every Steam rule below is second-hand until the
owner opens the Steamworks pages once.

---

## 0. The short version

1. **Hook:** "You are not the hero. You are the necromancer, and your dead army fights for you." A survivors-like where you
   command the horde. Plays in a phone browser. Online co-op.
2. **$4.99 is fair and matches the genre** (Vampire Survivors' list price is $4.99; Halls of Torment and 20 Minutes Till
   Dawn sit near $4.99 / 4.99 EUR). With this much content it is on the low side; the plan keeps $4.99 and tells the owner
   how to raise it later (section 2).
3. **Funnel:** free web demo on GitHub Pages (Act I) -> Steam wishlists -> Steam Next Fest -> launch. Steam is the paid home.
4. **Art:** recommend **option (d), staged**: a human pixel artist redraws the most-seen art (12 playable characters, the 15
   summon classes, Act I, the capsule / trailer assets) before launch, a short style-guide pass covers the rest, the remainder
   is redrawn after launch. Budget **roughly $12k-30k before launch** (estimate, section 3). Disclose AI use on Steam either way.
5. **Social:** 4 posts a week for 4 weeks, made in batches by Claude (clips, captions, calendar), uploaded by the owner or a
   scheduler. Start posting only clips that show assets that will survive the redraw (big-army moments, UI, effects, music).
6. **Launch target:** Steam page live in November; demo in the **June 2027 Next Fest**; launch 4-8 weeks later
   (about Aug-Sep 2027). A February 2027 Next Fest entry is possible but too early for the art plan (section 6).

---

## 1. Positioning and audience

**One-line hook (store tagline):** *Command an undead horde against a holy crusade. Survive twenty minutes, then face the Reckoning.*
(This is already the itch page tagline in `docs/itch/page.md`.)

**Tweet / TikTok version:** *"A Vampire Survivors-style game where YOU are the necromancer and the horde is your army."*

**What sets it apart (lead with these, in this order):**

| Pillar | Proof the player can see in 5 seconds |
|---|---|
| You command the army, you are not the hero | A ring of Warriors, Archers, Mages, priests around a tiny necromancer; evolutions (Death Knight, Lich) |
| A campaign, not one map | Many stages across themed acts (Covenant, Ancient Eye, Electronic Empire, Olympus, Shogunate, more coming); each stage has a 20:00 clock, a boss with 3:00 left, then the Reckoning |
| Build depth | 12 spells, 15 summon classes, evolutions from chests, 13+ synergies, 12 playable characters, Ossuary meta-progression |
| Online co-op | Two necromancers, one lobby code, one shared army field |
| Plays in a phone browser | One tap from a link; touch controls built in |
| It sounds like its own game | All sound and music are synthesized in-engine (a distinct selling point; no licensed or AI-voiced audio) |

**Caveat on counts:** the repo has 24 stage files in `scripts/data/stages/`, but CLAUDE.md lists 12 stages as live (Acts I-V)
and Acts VI-IX are in the pipeline (`docs/act6`-`act9`). Before any public copy says "24 stages", confirm the playable count
on the build that ships. Say what is playable, not what is registered.

**Audience:**
- Core: players of Vampire Survivors, Brotato, Halls of Torment, 20 Minutes Till Dawn, Soulstone Survivors. They are price-sensitive
  ($5 is the norm), review-driven, and already tired of clones, so the army-command angle must be visible in the first clip.
- Secondary: minion-commander / necromancer fans (Diablo necromancer, Dungeon Keeper, Overlord, Hades-style runs), co-op duos,
  Steam Deck players (a 20-minute run fits it; check Deck compatibility as a to-do).
- Phone-browser players: the free web demo reaches people with no Steam account. Treat them as top-of-funnel, not as buyers.

**Honest risk:** "Vampire Survivors-style" is a crowded tag. The clone problem is real; the army-command loop, the campaign
and the co-op are the answer, so every asset should show the horde acting without the player (autonomous fighting, blocking,
evolutions), not the player dodging.

---

## 2. Price and platforms

### 2.1 Is $5 right? [verified / partly]

- Vampire Survivors: launched in Early Access on **Dec 17, 2021 at $2.99**, raised to **$4.99 on Sept 21, 2022** before 1.0, and
  its MSRP is $4.99 [verified: PCGamesN, SteamDB, Deku Deals links in section 8].
- Halls of Torment is listed around 4.99 EUR with periodic 25% sales; 20 Minutes Till Dawn around 4.99 EUR [partly: tracker and
  news sites; the Steam page itself was not checked]. Brotato's current price was not found [unverified].
- So **$4.99 is the genre norm and the safe choice.** The cost is that the game's content (many stages, 12 characters,
  co-op, meta-progression) is larger than most $5 survivors-likes. Underpricing signals "small clone".

**Recommendation:** launch at **$4.99** (the owner's call stands), with a **10-15% launch discount for the first week**
(Steam's launch discount; check the current maximum length in Steamworks). Plan an explicit **price rise** (e.g. to $6.99-$7.99)
when Acts VI+ ship, announced in advance, as Poncle did. Never sell below $4.99 at launch; the only lower price is a sale later.
Re-check this once the Steam page has a wishlist count: if wishlists are strong, $6.99 is defensible.

Fees to budget [verified]: the **Steam Direct fee is $100 per app**, non-refundable but **recouped once the app has $1,000 of
adjusted gross Steam revenue** (Steamworks "App Fee" page). Steam's revenue share (commonly 30% at the base tier) is from
memory here and **[unverified]** today.

### 2.2 Platform roles

| Place | Role | Notes |
|---|---|---|
| **Steam** | The paid home; wishlists, reviews, Next Fest, Deck | PC (Windows/Linux builds already exported by CI). Needs capsule art, trailer, screenshots, store text, AI-disclosure form. |
| **Web build (GitHub Pages)** | Free demo and funnel | https://smoketsu.github.io/NecropathyPlay/ . Also the thing nobody else in the genre offers: tap a link on a phone and play. |
| **itch.io** | Not in the plan | Owner dropped itch publishing earlier (CLAUDE.md, GDD §15.0 "GitHub Pages is the web home"). A `docs/itch/` kit exists and could be reused cheaply if the owner changes their mind; a free-demo page there would add discovery on a second storefront. Recommend: **skip** until after Steam launch. |
| Mobile app stores | Not now | Native apps are deferred in the GDD; the browser build covers phones. |

### 2.3 What to keep free vs paid

The web build today is the whole game. Before a public demo, add a **demo flag** (a code task for a later agent, not done here):

| Free (web demo, and Steam demo) | Paid (Steam) |
|---|---|
| Act I (three stages: Graveyard, Crimson March, Sanctum) with a few characters | All other acts as they ship; all characters and skins |
| The core loop, Dread Rally, Grave Step, synergies, evolutions | Online co-op (the strongest "pay" reason; also the hardest to give away because it costs relay traffic) |
| The first Ossuary tier (Soul Ash carries inside the demo) | Full Ossuary, Hyper mode, Relics, Caskets, Codex completion |

Why: Act I is the most polished and shows the whole mechanic; it lets someone judge the game in one 20-minute run (run length
is the tax on a demo; offer a "short run" option or show the Reckoning at a sped-up clock only if the owner wants, but do not
change the real rules). The demo must end on a clear "wishlist on Steam" screen and link.

**Saves:** the demo's saves do not need to carry over to Steam; say so on the page to avoid support mail.

### 2.4 Steam page and wishlist timeline

- **Wishlists drive launch visibility.** Rules of thumb [partly, tool-vendor blogs]: median first-week conversion about 10-15%
  of wishlists; 7,000-10,000 wishlists is a "modest indie launch" benchmark; about 20,000 is "healthy". These are soft; treat
  them as targets, not promises. Setting up the page early is the consistent advice.
- A "Coming Soon" page needs the $100 fee, a Steamworks account with tax and bank set-up, a capsule image set, a short
  description, screenshots and a trailer (a trailer can come later). Valve reviews the page before it is public (usually a few
  days; **[unverified]** today). A separate review is needed for the build, and the release-date announcement should be made
  early because Steam shows it to the wishlisters.
- **Next Fest:** Eligibility [partly]: a Steamworks account in good standing, a **public store page**, and a **publicly playable
  demo by the time the fest starts**; a game can appear in Next Fest only once. The October 2026 fest ran Oct 19-26 and its
  registration closed Aug 31. The next edition's documentation gives a **registration deadline of Jan 10, 2027** (February 2027
  fest) and says the one after is **June 2027** [partly; sources disagree on exact fest dates, check Steamworks]. One source
  advises picking the fest that ends more than a week before launch but as close to launch as possible [partly].
  **Because a game can enter Next Fest once, enter it when the demo is at its best, with the redrawn Tier-1 art.**
- No data on how many wishlists Next Fest typically adds was found [unverified]; do not promise a number.

---

## 3. The art question

### 3.1 The facts

- Art is pixel art made with an image-generation API (`tools/gen_image.py`, ledger `docs/art/generation_ledger.csv`), then
  converted and cleaned by tools (`prepare_sprite.py`, `pixelate_source.py`, palette ramps, walk cycles). The owner feels
  uneasy about it and expects a consistency pass or full redraw at the end.
- **Asset count** (counted today; `.png` files under `assets/sprites`, excluding `.import` sidecars; **2,042 PNGs in all**, 2,103
  with `ui/` and `fonts`). "Base" excludes walk / idle / glide / pose strips, so it approximates the number of distinct designs:

| Folder (what it is) | Total PNGs | Base designs (approx.) | Animated strips |
|---|---|---|---|
| `player/` (12 characters, their default / Hyper / achievement / casket skins) | 301 | 122 | 122 walk, 57 idle |
| `summons/` (15 classes + evolutions) | 99 | 47 | ~50 |
| `bosses/` (stage bosses, minibosses, attack poses) | 89 | 57 | ~30 poses |
| Act enemy folders: `enemies` (Act I) 16, `holy` 36, `eye` 21, `empire` 19, `pantheon` 19, `shogunate` 16, `city` 11, `court` 13, `inferno` 13 | 257 | ~164 | walk strips |
| `obstacles/` (both orientations) | 478 | n/a | none |
| `tiles/` + `decals/` (floors, ground marks) | 111 + 76 | n/a | none |
| `icons/` (spells, passives, UI badges, synergies) | 281 | n/a | none |
| `effects/`, `aoe/`, `empire_fx/`, `projectiles/`, `volleys/`, `telegraphs/`, `markers/`, `overlays/`, `pickups/` | ~257 | n/a | strips |
| `structures/`, `menu/`, `epilogue/` (23 panels), `ui/` | ~77 | n/a | none |

  **Figures needing a human to draw and animate: about 390 distinct designs** (122 player + 47 summons + 57 bosses + ~164
  act enemies), most with a walk strip, 57 with an idle, some with attack poses. Plus about 480 obstacle props, 190 floor
  tiles / decals, 280 icons and 250 effect strips, which are far cheaper per item.

### 3.2 The rules and the perception [partly]

- **Steam** requires developers to disclose AI use through the Steamworks Content Survey. Valve separates **pre-generated**
  content (shipped in the game, which is the case here: sprites, art) from **live-generated**; the form was clarified to
  focus on content players see or hear, and not on behind-the-scenes efficiency tools (such as coding assistants). The
  pre-generated disclosure is shown on the store page. Valve judges pre-generated content by the same rules as any other
  content. Exact wording and enforcement (some outlets say inaccurate disclosure risks removal) are **[unverified]**
  because the Steamworks text was not reachable. Sources in section 8.
- **TikTok** requires labelling AI-generated content that shows **realistic** images, audio or video, using an AIGC toggle in
  the post options; it may auto-label. Stylised game footage with pixel sprites is not "realistic", so a label is probably not
  required, but the toggle costs nothing and a plain "AI-assisted pixel art" line in the bio or pinned post is cheaper than
  a comment-section fight [partly: third-party summaries; check TikTok's own Help Center].
- **Perception.** A visible segment of survivors-like players and indie-game communities avoids or review-bombs AI art, and
  the Steam AI tag is visible. This is the owner's own concern and it is reasonable. Honest disclosure plus a visible human
  art plan ("being redrawn by [artist]") turns a negative into a story; hiding it does not survive a Reddit thread.
- **Ownership (flag for a lawyer, not a conclusion):** my understanding is that purely AI-generated images may not be
  copyrightable in the US, which weakens the owner's control over the sprites. Hand-drawn replacements fix that too.
  **[unverified today]; one more reason to prefer human-drawn art for the core.**

### 3.3 The options

| Option | What | Cost (estimate) | Time | Pros | Cons |
|---|---|---|---|---|---|
| (a) Keep, disclose | Ship as is; Steam disclosure; honest bio | $0 | 0 | Fastest; art is already consistent enough in-engine (ART_BIBLE, shared ramps, tools) | Perception and review risk; ownership uncertainty; the owner is unhappy with it |
| (b) Human consistency pass | An art director / pixel artist paints over the AI sprites to one palette, outline and shading rule, plus a written style guide | **$4k-12k** (Tier-1 set ~65 designs at $60-180 each to overpaint; the rest by script) | 4-8 weeks | Cheaper; looks like one hand | Still AI-derived; the disclosure stays; the rest of the work is hidden |
| (c) Full redraw | A commissioned artist (or two) redraws every figure with walk / idle strips, then props, tiles, icons | Figures ~390 designs x **$130-400** each (animated) = **$50k-155k**; props / tiles / icons / effects +$10k-30k. **Total ~$60k-185k** | 8-18 months for one artist, 4-6 months for a team of three | Clean story, full ownership, no disclosure | Far beyond a $5-game budget |
| (d) **Staged** (recommended) | Redraw the most-seen assets first (below), consistency pass on the rest, redraw the rest after launch from revenue | **Phase 1 (before launch) $12k-30k**, Phase 2 (after) as sales allow | Phase 1 about 3-5 months | Fixes what players, the store page and the trailer show; honest roadmap; spreads cost | Mixed art for a while; needs a clear style guide so old and new sit together |

Per-item cost basis (all from price sheets and community posts, mostly small sellers' asking prices, so **treat as loose**
[partly]): hobbyist freelancers list roughly **$20-70 for a simple character with idle / walk / attack**, **$130-180 for a complete
character set** (4-direction walks, hits, attacks, deaths), studio price pages list **$100-300 per 2D animation cycle**, and
one blog says **$500-1,500 for an animated character with a walk**. The $130-400 per design used above sits inside that
spread, at the higher end of "experienced freelancer", because the game needs a consistent set; Necropathy's units are
mostly one-direction (side-on) with a walk strip, which keeps the real price at the cheaper end. Examples of whole solo-dev
redraw budgets were **not found**; the totals here are my arithmetic, not a benchmark. Get 2-3 quotes from pixel artists on
itch.io's "for hire" boards and Reddit r/PixelArt / r/gameDevClassifieds, with the same test sprite (a Warrior with idle + walk
+ one attack) before committing.

### 3.4 What "most-seen" means (the Tier list for option d)

| Tier | Assets | Designs | Why first | Cost range |
|---|---|---|---|---|
| **1: store page, trailer, thumbnail** | The necromancer + 12 playable characters (default look), the 15 summon classes (base) and their evolutions that appear in clips (Death Knight, Lich, Profane Bishop, Hellhound), Act I enemies (`enemies/`, 16), Sir Alaric, Vael, Seraphine, the NECROPATHY logo / capsule, the spell and passive icons shown in clips | ~65-80 | These fill every screenshot, clip and the capsule | **$9k-24k** |
| **2: demo coverage** | Act I props (`obstacles`, floors) and effects, the title / menu art, the Hyper skins of the 12 characters | ~40 designs + ~150 props | Anyone who plays the demo sees them | $3k-8k |
| **3: rest of acts** | Acts II-V (and VI+ as they land): ~300 enemies / bosses | ~300 | Seen only by paying players, after launch | $40k-120k, funded by sales |

Phase 1 = Tier 1 (+ a consistency pass on everything else via a written style guide and the existing tools). That is the **$12k-30k**.
If Tier 1 is out of budget, shrink it: the **12 characters + the first 6 summon classes + Act I** (about 45 designs, **$6k-18k**)
is the minimum that changes the store page and the first minutes of the demo.

### 3.5 Recommendation

1. **Do option (d).** Hire one pixel artist for Phase 1, commission a style guide first (palette, outline weight, light
   direction, sprite sizes), and have them redraw Tier 1 in that style. Claude can write the brief from `docs/art/ART_BIBLE.md`
   and generate before / after contact sheets, as already done for the figure redesign.
2. **Disclose honestly now** on Steam (AI used for pre-generated art, being replaced by human-drawn art in stages) and in the
   bio: it is the truth, it is required, and it stops the first comment thread from being a "gotcha".
3. **Do not build the marketing on assets that will be replaced.** Before the Tier-1 redraw lands, post clips that lean on
   the mechanics, effects, UI, music, bosses' scale and numbers; use sprites small and in motion; avoid hero-sprite close-ups,
   character reveals, "meet the necromancer" posts and the capsule art. After the redraw, a **before / after** post is itself
   a strong content pillar and a trust builder.
4. Put the AI-vs-human question in the Steam page text as a short, plain line, e.g. "Early art was made with AI tools and is being
   replaced by hand-drawn pixel art; all code, design, music and sound are made in-house." (The owner must confirm this is accurate
   before use; the synthesized audio and code claims follow CLAUDE.md, but code is written with Claude, which Valve treats as
   an efficiency tool for code, not content. Check the current form [unverified].)

---

## 4. Short-form video: TikTok / YouTube Shorts / Instagram Reels

### 4.1 Ground rules

- **Claude cannot create or post to social accounts.** The owner creates and owns the account, and posts or uses a scheduler
  (TikTok's own scheduler, Later, Buffer...). Claude produces clips, captions, hashtags and the calendar in **batches of 8-12**
  so the owner uploads once a week.
- Post the same vertical clip on TikTok, Shorts and Reels (strip the watermark; each platform down-ranks watermarked reposts).
- AI-art label: see 3.2. Footage is stylised, not realistic.
- Music: use the game's own synthesized soundtrack ("Grave Lullaby", "Below the Tide", "Iron Requiem", "Hymn of Bronze"):
  no licensing risk and it doubles as a brand sound.

### 4.2 Content pillars

| Pillar | What the clip shows | Example hook (first 1.5 s) |
|---|---|---|
| **1. Big army moments** | The Bone Ring in motion, 200 enemies, a volley wall, Dread Rally | "I don't even attack. My dead do it." |
| **2. Boss fights** | Alaric, Seraphine, Kurogane, Hades; the telegraphs; a last stand | "This boss has a second health bar: his army." |
| **3. Evolutions / chest openings** | Warrior -> Death Knight; Mender + Warder -> Profane Bishop | "Two priests. One bishop. Watch." |
| **4. Rate my build** | A screenshot of a pause screen build; comments vote; a follow-up clip plays it | "Rate this build 1-10. Then I play it." |
| **5. Devlog** | New acts (pirates, dinosaurs, Egypt), how a stage rule works (Phalanx, Lock-On) | "Act VI: what happens when pirates board your boat." |
| **6. Phone browser** | Tapping a link and playing on a phone | "A survivors-like you can play from a link." |
| **7. Art before / after** | Only after the Tier-1 redraw | "From AI sketch to hand-drawn pixel art." |
| **8. Numbers / meta** | Soul Ash, Ossuary, the 20-minute run in 20 seconds | "20 minutes in 20 seconds." |

### 4.3 Four-week starter calendar (4 posts / week; add a fifth as a re-cut if one works)

Posting times are a **starting guess** [unverified; test, then follow the account's own analytics]: weekdays 6-9 pm and
Sat/Sun 11 am-2 pm in the owner's time zone, always the same slots so the algorithm learns them.
Hashtags: 4-6 per post, mix: `#vampiresurvivors #survivorslike #indiegame #gamedev #pixelart #roguelike` + one per clip
(`#necromancer`, `#bossfight`, `#godotengine`, `#playtest`). Pin a comment with the demo link; the link in bio is the web demo
(until the Steam page exists, then the Steam page).

| Wk | Day | Pillar | Clip (15-35 s) | Hook | Caption |
|---|---|---|---|---|---|
| 1 | Mon | 1 army | 25 s run to minute 8, wall of enemies, ring holds | "I'm the weakest unit on screen." | "You're a necromancer. Your army does the fighting. Free browser demo in bio." |
| 1 | Wed | 3 evolution | Chest -> Death Knight | "Watch a Warrior become a Death Knight." | "Evolutions come only from chests, and only if your passive is maxed." |
| 1 | Fri | 6 phone | Phone screen: tap link, play | "A survivors-like. In a phone browser." | "No download. Landscape. Free demo." |
| 1 | Sun | 2 boss | Sir Alaric entrance + fall | "3:00 left. The boss arrives." | "Every stage has a boss and then the Reckoning." |
| 2 | Mon | 4 rate my build | Pause-screen build card | "Rate this build 1-10." | "I'll play the top comment's build next." |
| 2 | Wed | 8 numbers | 20 min in 20 s time-lapse | "20 minutes in 20 seconds." | "Survive the clock. Then the Reckoning ends it." |
| 2 | Fri | 1 army | Rally Barrage, volleys | "Bullet heaven, but I'm the bullets." | "Dread Rally raises the whole army." |
| 2 | Sun | 5 devlog | Phalanx / Lock-On rule explained in 20 s | "Act IV: shields you can't hit from the front." | "Each act adds one rule. This is Olympus." |
| 3 | Mon | 4 build play | Plays week-2's winner | "You voted. I played it." | "Comment the next build." |
| 3 | Wed | 2 boss | Seraphine's collapsing arena | "Phase 3: the floor is gone." | "Grand Inquisitor Seraphine, Sanctum of Judgment." |
| 3 | Fri | 3 chest | Hellhound evolution + fire trail | "Dogs, but evolved." | "Bone Hounds + Blood Scent." |
| 3 | Sun | 5 devlog | New act teaser (only if shipped) | "Pirates board your ship in Act VI." | "Coming to the demo's wishlist." |
| 4 | Mon | 6 phone | Co-op on two phones (when tested) | "Two necromancers. One link." | "Online co-op. Lobby codes." |
| 4 | Wed | 1 army | Biggest horde, slow zoom | "How many undead is too many?" | "Alive cap is high. Mine is higher." |
| 4 | Fri | 4 build | Rate-my-build part 3 | "This build can't lose, right?" | "Naive vs army bots, human edition." |
| 4 | Sun | 8 numbers | Ossuary unlock reveal | "Buying the game's menu with my dead." | "Soul Ash is kept on death." |

Week-1 to -3 clips should avoid close-ups of hero sprites (3.5). Clips that win (watch time, shares) get a re-cut the next
week; clips that don't get dropped. Reply to comments for the first hour.

### 4.4 Clip pipeline Claude can run (propose; not built)

Existing tools in the repo [from README / CLAUDE.md]: the autotest bot plays whole runs (`--autotest --policy=army --speed=N`),
`--seed`, `--stage`, `--character`, `--boss`, `--spawn=kind@T`, `--victory-preview`, screenshots under xvfb (`--shot=PATH [--phone]`,
`--shot-what=`, `--coop-shots=`), and the Node/Playwright tools `tools/coop_hud_shots.mjs` for the Web build. `docs/media/v0.5.0`-
`v0.7.0` hold GIFs and stills (hero, stages, walks, before / after). There is **no recorded video tool** yet.

**Proposed `tools/capture_clip.sh` (follow-up, not written):**
1. Run the game **windowed under Xvfb** (headless has no renderer): `xvfb-run -s "-screen 0 1280x720x24" godot --path . --fixed-fps 60 --write-movie out.avi -- --autotest --policy=army --seed=N --stage=graveyard --speed=1 --clip-start=T --clip-len=S`.
   Godot 4.3's Movie Maker mode (`--write-movie`) renders at a fixed frame rate and records the game's audio (the synthesized
   music and effects) [from memory; verify in the Godot 4.3 docs]. Runs at `--speed=1` so the capture is real time.
2. A tiny GDScript or CLI option `--clip-start` / `--clip-len` (or just cut with ffmpeg) to start the recording at a chosen
   game time; seeds chosen by a "highlight finder" that scans an autotest log for peak enemy count, evolution events, boss
   phases (the summaries already print them). Deterministic seeds make the same clip repeatable.
3. ffmpeg to **1080 x 1920**: scale the 1280 x 720 capture to width 1080 with `neighbor` scaling (keeps pixel art crisp),
   place it in the middle of a blurred copy of itself (or a dark violet background), add a title card, a caption band top and
   bottom (`drawtext`, Jersey 10 font from `assets/fonts`), loudness-normalise audio. Or capture with `--phone` for a native
   touch layout where it fits 9:16 better.
4. Output per clip: `clip.mp4` (H.264, AAC, 30 fps, under 60 s), a `clip.json` with caption / hashtags / pillar, and a
   contact sheet, written to `docs/marketing/out/` (git-ignored).
5. Batches of 8-12 per run, 4 parallel Godot processes at most (CLAUDE.md rule), roughly 1x real time per clip, so a batch of
   ten 30-second clips is minutes plus run-up to the highlight (use `--speed=8` to reach the moment, then switch to 1x;
   the capture needs a small hook for that, or a `--clip-start`).

Open points to settle in that follow-up: whether Movie Maker captures at the fixed fps with the autotest's large time scale;
whether the Web build shows the same frame rate; how to hide the debug HUD lines. Claude can prototype it in a day.

---

## 5. Other channels

| Channel | Fit | How |
|---|---|---|
| **r/roguelites**, r/roguelikes | Good (runs, builds, meta-progression) | Post once with a real discussion, not a link drop. Read each subreddit's self-promotion rule first [unverified here]. |
| **r/survivorslikes** (if active) | Best niche fit | Same; hold it for the demo launch. Check it exists and its rules. |
| **r/incremental_games** | Poor fit (the game is action, not an incremental); skip unless the Ossuary grind is the angle | |
| **r/godot**, r/godot "showcase" | Good for devlogs, tech (Web export on phones, synthesized audio, lockstep co-op) | Technical posts do well; add the demo link last. |
| **r/IndieDev, r/gamedev** (feedback days) | Good for feedback, not buyers | Use for the art-direction question and the trailer draft. |
| **r/WebGames, r/playmygame, r/indiegames** | Good for the free demo | One post each, spaced out. |
| **Discord** | Needed from the demo on | One server: #announcements, #bugs, #build-sharing, #co-op-lobby (people need partners). Owner moderates; Claude can draft the rules and pinned posts. Link it from the Steam page and the demo's end screen. |
| **YouTube creators** | High leverage, hard | Survivors-like channels (kinds below). **Claude does no outreach on the owner's behalf**; the owner sends the emails. |
| **Steam Next Fest** | Highest-value single event | Section 2.4 and 6. |
| **Press / newsletters** | Low priority | A few indie-roundup writers cover browser-playable and "tiny dev" stories; the phone-browser angle is the pitch. |

**YouTube creators, the kinds to approach (no names promised):**
1. *Survivors-like roundup channels* (weekly "new survivors-likes" lists).
2. *Demo / Next Fest preview* channels (publish playthrough videos during the fest).
3. *Small and mid-size indie* channels that play Steam keys (50k-500k subs reply more often than big ones).
4. *Challenge / "can I beat..."* streamers (the Reckoning is a natural challenge).
5. *Steam Deck and "cozy short sessions"* channels.
6. *Necromancer / minion-build* fans.

How to approach: a short email (under 120 words): one-line hook, the demo link first (no key needed), one GIF, and "a Steam key
is available if you want one". Send **about 3 weeks before Next Fest** with the key, follow up once. Don't send keys to
accounts that look like key farms. Keep a list in a sheet (channel, date, answer).

---

## 6. Timeline from now to launch

Assumes the art decision in 3.5. Dates are targets; the owner's content schedule moves them.

| When | Milestone | Owner | Claude |
|---|---|---|---|
| **Nov 2026** | Content finishing (Acts VI+); art decision made; Steamworks account + $100 app fee + tax / bank info | Pay, sign up, decide budget, post a call for pixel artists | Brief for the artist (ART_BIBLE-based), trailer shot list, store text draft, Steam capsule *layout* (final art later) |
| **Nov-Dec** | Hire artist; style guide; Steam "Coming Soon" page live (capsule, text, 5-8 screenshots, AI disclosure, price $4.99) | Approve the page, submit for review | Write page text, pick screenshots from the running build (mechanics-forward), prepare the AI-disclosure wording |
| **Dec-Jan** | Demo build (flag: Act I only, web + Steam); Discord server open; TikTok / Shorts account created; start posting (calendar in 4.3) | Create accounts, post or schedule weekly | 8-12 clips a week + captions; the capture script (4.4) |
| **Jan 10, 2027** | Last day to register for the Feb 2027 Next Fest [partly] | Decide: Feb or June | Recommend **June** |
| **Feb-Mar** | Tier-1 art delivered (about 8-12 weeks of artist time); QA of the redraw; trailer v1 | Review sprites weekly | Integrate sprites (tools exist), before / after posts |
| **Apr-May** | Demo polished; wishlist push; press / creator list; trailer v2 (with redrawn art) | Email creators | Draft emails, make GIFs, track wishlist numbers |
| **June 2027** | **Steam Next Fest** (the demo is live and the page has 5-8k wishlists as the target) | Run the fest; answer players | Daily clip; bug triage |
| **Jul-Aug** | Launch fixes; release date announced; launch trailer; review keys out | Set the date; send keys | Final captions, FAQ, patch notes |
| **Aug-Sep 2027** | **Launch at $4.99**, 10-15% launch discount for the first week; Discord and social burst | Press the button | Launch-week clips; community posts |
| **After** | Tier-3 art as revenue allows; price rise with Acts VI+; update posts | | Roadmap posts, art before / afters |

**Risk to the schedule:** wishlist numbers are the thing to watch. If the page has under about 2,000 wishlists by April
(a soft threshold), move the launch later rather than launching cold.

---

## 7. Open decisions for the owner (each with a recommendation)

| # | Decision | Recommendation |
|---|---|---|
| 1 | Art path (a / b / c / d) | **(d) staged**; hire for Tier 1 now; disclose |
| 2 | Art budget | **$12k-30k** pre-launch (floor $6k-18k for a minimal Tier 1); ask for 2-3 quotes with the same test sprite |
| 3 | Price | **$4.99** at launch, 10-15% launch discount, a planned rise to $6.99-$7.99 with later acts |
| 4 | Launch fest | **June 2027 Next Fest**; skip February |
| 5 | What the demo includes | Act I, a few characters, no co-op; ends on a Steam wishlist screen |
| 6 | Steam page timing | **Now**; wishlists accumulate with the page |
| 7 | itch.io | **Skip** until after Steam; the kit exists |
| 8 | Who posts | Owner creates and owns the TikTok / Shorts / Reels accounts; Claude supplies weekly batches; use a scheduler |
| 9 | AI disclosure wording | Plain and short, stating the redraw plan (3.5) |
| 10 | Steam Deck | Test and aim for Verified; mention it if achieved |
| 11 | Press kit and a trailer | A 60-90 s trailer after Tier 1 art lands; a 20 s teaser now using effects, UI and music, not hero sprites |
| 12 | Copyright check | Ask a lawyer once about AI-made assets before spending on a store page built on them |

---

## 8. Sources (web, searched Nov 2, 2026)

- Steam AI disclosure: [TechRadar](https://www.techradar.com/gaming/steam-softens-its-stance-on-ai-generated-content-opening-the-floodgates-to-the-vast-majority-of-games-that-use-it),
  [GamesRadar](https://gamesradar.com/valves-new-steam-policy-will-allow-the-vast-majority-of-ai-games-to-release),
  [PC Gamer](https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/),
  [Tbreak](https://tbreak.com/steam-ai-disclosure-policy-update-developers/),
  [LegalMoves (third-party commentary)](https://legalmoveslawfirm.com/steam-ai-policy/). Valve's own page was not reachable.
- TikTok AI labelling: [Storrito summary](https://storrito.com/resources/tiktoks-2026-ai-labeling-rules-and-what-they-signal-for-platform-governance),
  [NBC New York](https://www.nbcnewyork.com/news/national-international/tiktok-to-start-labeling-ai-generated-content-technology-becomes-more-universal/5399109),
  [MediaPost](https://www.mediapost.com/publications/article/389387/tiktok-provides-creators-with-new-labels-for-ai-ge.html). TikTok's Help Center was not read.
- Steam Direct fee: [Steamworks App Fee](https://partner.steamgames.com/doc/gettingstarted/appfee) (surfaced in search; not fetched),
  [PC Gamer](https://www.pcgamer.com/valve-reveals-steam-direct-fee-upcoming-changes-to-the-store),
  [Steam Page Analyzer](https://www.steampageanalyzer.com/blog/steam-direct-fee-explained).
- Next Fest: [Steamworks Oct 2026](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/2026october?language=english),
  [Steamworks Feb 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027) (search snippet),
  [God is a Geek](https://godisageek.com/2026/10/steam-next-fest-october-2026/),
  [Steam Page Analyzer fest dates](https://www.steampageanalyzer.com/blog/steam-next-fest-2026-dates).
- Genre prices: [PCGamesN, Vampire Survivors price rise](https://www.pcgamesn.com/vampire-survivors/price-increase-steam),
  [SteamDB](https://steamdb.info/app/1794680), [Deku Deals](https://dekudeals.com/items/vampire-survivors),
  [Halls of Torment listing](https://www.wasdland.com/game/halls-of-torment-2218750),
  [20 Minutes Till Dawn (Multiplayer.it)](https://multiplayer.it/notizie/20-minutes-till-dawn-rivaleggia-vampire-survivors-oltre-20000-recensioni-positive-steam.html).
- Wishlists: [Presskit.gg](https://presskit.gg/field-guides/how-many-wishlists-to-launch),
  [Steam Page Analyzer](https://www.steampageanalyzer.com/blog/steam-wishlist-conversion-rates),
  [Game World Observer (Ancient Enemy)](https://gameworldobserver.com/2021/04/19/indie-developer-jake-birkett-ancient-enemys-early-wishlists-converted-best).
- Pixel-art pricing: [RocketBrush](https://rocketbrush.com/blog/game-art-outsourcing-prices-complete-pricing-breakdown),
  [Pixune](https://pixune.com/blog/game-art-outsourcing-price/), [Whimsy Games](https://whimsygames.co/blog/the-complete-guide-to-game-art-outsourcing-costs-timelines-and-how-to-choose-a-studio/),
  [itch.io artist posts](https://itch.io/post/11820134), freelancer Carrd price sheets (tigerhorse-pixel-commissions.carrd.co and others).
  These are sellers' own asking prices, not neutral data.

**Not verified:** Valve's exact current AI-form wording and enforcement; Steam's revenue share and launch-discount limits;
TikTok's own help text; Brotato's price; the exact Feb / June 2027 fest dates; Next Fest wishlist gains; copyright status of
AI art; Godot `--write-movie` audio behaviour; subreddit rules; any whole-game pixel redraw budget from a solo dev.
