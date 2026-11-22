## StageRegistry — the campaign's stages and acts (GDD §8 "Stages and Wave
## Timelines", §9.3 "Graveyard -> Crimson March -> Sanctum"; the act order:
## GDD §15.0 "The last five acts and the act order" and "The reorder pass, part
## 1 (order and numbering)"). ACT_ORDER is the ONE ordered list of the fifteen
## acts and their stages: every act number, Part, stage number ("Chapter N"),
## the campaign ORDER, the unlock chain (each stage opens once the previous
## stage's boss falls) and each stage's Soul Ash multiplier (its position in
## its act, ASH_MULT_BY_POSITION) derive from it. Nothing else stores an act
## number: act-scoped rows (PassiveData "act", VictoryData.ACT_LINES, the Codex
## tabs, DemoData.ACTS) name an act by its ACT_ORDER id. One
## entry per stage, each
## the STAGE dictionary of its file under scripts/data/stages/. A run reads
## its stage through RunConfig.stage_def() as `Game.stage_def`; nothing else
## in the game hard-codes a stage.
##
## Keys of every STAGE dictionary:
##   id                 — registry id (save keys, --stage=, RunConfig).
##   display_name       — full name (stage select, end screen).
##   short_name         — short name (HUD, Soul Ash line).
##   (derived, not keys: the act, chapter, unlock and Soul Ash multiplier come
##   from ACT_ORDER through act_of(), chapter_of(), unlock_of() and
##   ash_mult_of(); Meta.is_stage_unlocked() and the stage select read them.)
##   description        — one-paragraph pitch (stage select; GDD theme/story).
##   boss               — {id, time, display_name, short_name, arrive_banner,
##                        defeat_banner, dead_objective}: which boss script
##                        ("alaric" / "vael" / "seraphine") arrives at `time` s.
##   segments           — trickle segments (GraveyardStage.SEGMENTS keys).
##   events             — timeline events (GraveyardStage.EVENTS keys, plus
##                        the Crimson March types in CrimsonMarchStage.EVENTS
##                        and the Sanctum types in SanctumStage.EVENTS).
##   reckoning          — Reckoning escalation and its banner (optional key
##                        "kind": the main wave's enemy kind, an Act II
##                        stage's own; absent = the Reckoning Inquisitor).
##   reckoning_objective — HUD objective after 0:00.
##   empowered_graves   — StageDirector empowered graves ({} = none).
##   consecration       — StageDirector desecration events ({} = none).
##   crypt_defender     — StageDirector Crypt Defender ({} = none).
##   arena              — obstacle layout at run start (Arena).
##   ground             — "graveyard" (Ground), "march" (MarchGround),
##                        "sanctum" (SanctumGround), the Act II floors
##                        ("harbour", "archive", "spire") or "empire"
##                        (EmpireGround, the Act III placeholder floor drawn
##                        from the STAGE's "floor" dictionary) or "pantheon"
##                        (PantheonGround, the Act IV placeholder floor, from
##                        the same "floor" dictionary).
##   enemy_hp_mult / enemy_damage_mult — stage multipliers on the shared
##                        enemy time scaling (1.0 = Graveyard baseline).
##   enemy_mult_from    — elapsed game seconds from which those two
##                        multipliers apply to regular enemies (0 = from the
##                        start; the stage boss always gets them).
##   march              — MarchDirector config ({} = no march mechanics; the
##                        Sanctum uses it for its battle zones only).
## Optional keys (absent = off):
##   playable           — false hides a registered stage from the stage select
##                        (shown as "Coming soon"); the autotest still runs it
##                        (absent = true). The Act II foundation stubs use it.
##   dread              — true: Dread on the necromancer (DreadMeter, Act II).
##   claims             — true: the Ancient Eye claims fallen summons as
##                        Drowned Thralls (EyeClaims, Act II).
##   music              — run loop id ("" / absent = the Act I loop; "tide" =
##                        "Below the Tide", "iron" = "Iron Requiem" (Act III);
##                        SoundData.SCORES, RunLoopSynth).
##   empire             — true: the Electronic Empire's shared rules (Act III,
##                        EmpireRules as Game.empire: Line of Fire, Lock-On,
##                        Steel has no soul, the Purge Protocol's orbital
##                        strikes when the RECKONING has an "orbital" key).
##   floor              — EmpireGround look of the "empire" ground (style,
##                        base, line, accent, trim; Act III placeholder).
##   sanctum            — SanctumDirector config (SanctumStage.SANCTUM:
##                        chambers, altars, corruption).
##   kind_aliases       — {alias: real kind}: short kind names the stage's
##                        timeline uses (EnemyDirector.resolve_kind()).
##   tide               — TideDirector config (HarbourStage.TIDE: the rising
##                        water, tide surges, High Water; Act II).
##   harbour            — HarbourDirector config (HarbourStage.HARBOUR: bell
##                        buoys, smugglers' caches, the Harbourmaster; Act II).
##   archive            — ArchiveDirector config (ArchiveStage.ARCHIVE: the
##                        Ink Wells, the Orrery, the forbidden tomes, rifts).
##   sinking            — SinkingDirector config (SpireStage.SINKING, Act II
##                        Ul-Thalos): the island shrinks with the zones (each
##                        zone's `shore` radius); the sea is the world's edge.
##   spire              — SpireDirector config (SpireStage.SPIRE: dream
##                        pillars, guest squads of the earlier Act II kinds).
##   assembly           — AssemblyDirector config (AssemblyStage.ASSEMBLY, Act
##                        III the Assembly Halls: fabricators, the furnace
##                        rhythm, guest aliases; its zones' "belts" /
##                        "channels"); with ground "assembly" (AssemblyGround).
##   citadel            — CitadelDirector config (CitadelStage.CITADEL, Act
##                        III, the Iron Citadel: Shield Gates, laser grids, the
##                        Citadel's guns, Sentry Turrets, Valkyrie 2.0, guest
##                        squads of the earlier Act III kinds); ground
##                        "citadel" is its CitadelGround (four zone floors).
## --- the Olympian Republic ---
##   pantheon           — true: the Olympian Republic's shared rules (Act IV,
##                        PantheonRules as Game.pantheon: Wrath of the Gods,
##                        Phalanx, Glory, and the Twilight of the Gods when the
##                        RECKONING has a "twilight" key).
##   wrath              — the stage's Wrath of the Gods (DivineWrath): {"kind":
##                        "waves" | "lightning" | "fissures", plus any key of
##                        PantheonRulesData.WRATH[kind] to override it}.
##   zones              — Act IV stubs: the planned zones ([{id, name, start}],
##                        names only until phase 2 builds them).
## --- the Shores of Ilion ---
##   ilion              — IlionDirector config (IlionStage.ILION, Act IV, the
##                        Shores of Ilion: the siege towers rolling for the
##                        walls, Polyphemus the Cyclops; its "siege_towers" /
##                        "polyphemus" events); ground "ilion" is its
##                        IlionGround (four zone floors).
## --- Mount Olympus ---
##   olympus            — OlympusDirector config (OlympusStage.OLYMPUS: the
##                        Pantheon Trial's gods, Artemis's groves); ground
##                        "olympus" is its OlympusGround (four zone floors).
## --- the Asphodel Underworld ---
##   underworld         — UnderworldDirector config (UnderworldStage.UNDERWORLD,
##                        Act IV, the Asphodel Underworld: the River Styx in the
##                        zones whose ZONES row has "styx": true, Cerberus, guest
##                        squads of the earlier Act IV kinds); ground
##                        "underworld" is its UnderworldGround (four zone floors
##                        and the Styx).
## --- the Shogunate of the Rising Sun ---
##   shogunate          — true: the Shogunate's shared rules (Act V,
##                        ShogunateRules as Game.shogunate: the Sun's Course, the
##                        Draw, From the Shadows, and the Endless Night when the
##                        RECKONING has an "endless_night" key); ground
##                        "shogunate" is the placeholder ShogunateGround (from
##                        the "floor" dictionary, styles paddy / castle / gravel).
##   sun                — the stage's Sun's Course (SunCourse): any key of
##                        ShogunateRulesData.SUN overrides it ({} = defaults:
##                        dusk at 13:00 left, night at 7:00).
##   zones              — Act V stubs too: the planned zones (names only).
## Act V segment keys (SEGMENTS rows): "night_weights" (kinds that join the
## trickle only at night, SunCourse.timeline_weights()) and "ambush"
## ({"every", "kind", "count", "elite"}: ShadowAmbush's trickle from dusk on);
## Act V event type "ambush" (its "groups" appear From the Shadows).
## --- the Burning Province ---
##   province           — ProvinceDirector config (ProvinceStage.PROVINCE, Act
##                        V, the Burning Province: the paddy water in the zones
##                        whose ground has a "paddy" share, the village fires in
##                        a zone with "fires", Shuten-doji (its "shuten_doji"
##                        event, night only), No Shadow Unlit); ground
##                        "province" is its ProvinceGround (four zone floors and
##                        the paddy water).
## --- the Road to the Sun ---
##   sun_road           — SunRoadDirector config (SunRoadStage.SUN_ROAD, Act V,
##                        the Road to the Sun: the Kirin's "kirin" event, guest
##                        squads of the other Act V stages' kinds); ground
##                        "sun_road" is its SunRoadGround (four zone floors).
## --- Castle Kurogane ---
##   kurogane           — KuroganeDirector config (KuroganeStage.KUROGANE, Act V,
##                        Castle Kurogane: the General of the Left, the HUD
##                        objective of the Shogun's army; its "general_left"
##                        event); ground "kurogane" is its KuroganeGround (four
##                        zone floors).
## --- the Inferno ---
##   inferno            — true: the Inferno's shared rules (Act VI, InfernoRules
##                        as Game.inferno: the Hell Pits, the demon portals,
##                        Temptation, and the Last Judgment when the RECKONING
##                        has a "last_judgment" key); ground "inferno" is the
##                        placeholder InfernoGround (from the "floor" dictionary,
##                        styles ash / velvet / obsidian).
##   pits               — the stage's Hell Pits (HellPits): any key of
##                        InfernoRulesData.PITS overrides it ({} = defaults);
##                        its fixed pits change with each of the "zones".
##   portals            — the stage's demon portals (DemonPortals): any key of
##                        InfernoRulesData.PORTALS ({} = defaults; "table" = the
##                        squads they pour).
##   zones              — Act VI stubs too: the planned zones (names and starts;
##                        the Hell Pits read the starts).
## Act VI event type "portal" ({count, banner, distance_min, distance_max,
## table, pour_every}: DemonPortals.start_event()).
## --- the Burning Gate ---
##   burning_gate       — BurningGateDirector config (BurningGateStage
##                        .BURNING_GATE, Act VI, the Burning Gate: the
##                        Gatekeeper's "gatekeeper" event, Gate Crashed); ground
##                        "burning_gate" is its BurningGateGround (four zone
##                        floors). Its "pits" also hold the River of Fire
##                        ("band": HellPits._add_band()).
## --- the Palace of Silk and Ash ---
##   silk_palace        — SilkPalaceDirector config (SilkPalaceStage.SILK_PALACE,
##                        Act VI, the Palace of Silk and Ash: the Hall of Mirrors'
##                        reflections, the Twin Succubi's "twins" event, guest
##                        squads of the Burning Gate's kinds); ground
##                        "silk_palace" is its SilkPalaceGround (four zone floors).
## --- Pandemonium ---
##   pandemonium        — PandemoniumDirector config (PandemoniumStage.PANDEMONIUM,
##                        Act VI, Pandemonium: the Fallen Seraph General's
##                        "seraph_general" event, guest squads of the other Act
##                        VI stages' kinds); ground "pandemonium" is its
##                        PandemoniumGround (four zone floors).
## --- the Sanguine Court ---
##   court              — true: the Sanguine Court's shared rules (Act VII,
##                        CourtRules as Game.court: Bloodfeast, Night Wings, the
##                        Blood Moon, and the Endless Feast when the RECKONING
##                        has an "endless_feast" key); ground "court" is the
##                        placeholder CourtGround (from the "floor" dictionary,
##                        styles moor / fen / castle).
##   moon               — the stage's Blood Moon (BloodMoon): any key of
##                        CourtRulesData.BLOOD_MOON overrides it ({} = defaults).
##   zones              — Act VII stubs too: the planned zones (names and starts).
## --- Ravensmoor ---
##   ravensmoor         — RavensmoorDirector config (RavensmoorStage
##                        .RAVENSMOOR, Act VII, Ravensmoor: the sleeping coffin
##                        waves and their bounty, Coffin Nails, the ghoul packs,
##                        Old Greymane's "greymane" event); ground "ravensmoor"
##                        is its RavensmoorGround (four zone floors).
## --- the Witchwood ---
##   witchwood          — WitchwoodDirector config (WitchwoodStage.WITCHWOOD, Act
##                        VII, the Witchwood: the Fen's pools ("fen"), the hex
##                        stones ("stones"), the Bog Mother's "bog_mother" event
##                        and the "coven" events); ground "witchwood" is its
##                        WitchwoodGround (four zone floors and the Fen's water).
## --- Castle Sanguis ---
##   castle_sanguis     — CastleSanguisDirector config (CastleSanguisStage
##                        .CASTLE_SANGUIS, Act VII, Castle Sanguis: the Banquet's
##                        blood fountains, the Chiropteran King's
##                        "chiropteran_king" event, guest squads of the other
##                        Act VII stages' kinds); ground "castle_sanguis" is its
##                        CastleSanguisGround (four zone floors).
## --- the Last Line ---
##   city               — true: the Last Line's shared rules (Act VIII,
##                        CityRules as Game.city: the escalation, Armour,
##                        Supers, Civilians, and Martial Law when the RECKONING
##                        has a "martial_law" key); ground "city" is the
##                        placeholder CityGround (from the "floor" dictionary,
##                        styles docks / base / downtown, drawn from the
##                        CityBlocks geometry).
##   blocks             — the CITY-BLOCK LAYOUT's grid (CityBlocks, owned by
##                        Arena): any key of CityBlockData.DEFAULTS overrides it
##                        ({} = defaults). It switches the layout on only
##                        together with an "arena" layout that carries its own
##                        "blocks" dictionary (that zone's looks: styles,
##                        open_share, open_styles; a zone never moves a street).
##   escalation         — the stage's escalation (Escalation): any key of
##                        CityRulesData.ESCALATION overrides it ({} = the full
##                        default ladder; phase 2 sets each stage's "last").
##   civilians          — the stage's civilians (Civilians): any key of
##                        CityRulesData.CIVILIANS overrides it ({} = defaults).
##   supers             — the Super ids the escalation sends here, in turn
##                        (absent = CityRulesData.SUPERS "roster").
##   zones              — Act VIII stubs too: the planned zones (names and starts).
## --- Skid Row ---
##   skid_row           — SkidRowDirector config (SkidRowStage.SKID_ROW, Act
##                        VIII, Skid Row: Big Sal and the Armoured Limo's
##                        "big_sal" event, the Bounty's doubled gangs while Don
##                        Marrow's board stands, No Witnesses); ground
##                        "skid_row" is its SkidRowGround (the four zone looks
##                        over the city blocks).
## --- Fort Kessler ---
##   fort_kessler       — FortKesslerDirector config (FortKesslerStage
##                        .FORT_KESSLER, Act VIII, Fort Kessler: the
##                        minefields' numbers, the Mammoth and Broken Arrow
##                        objectives; the "mammoth" event); ground
##                        "fort_kessler" is its FortKesslerGround (the four
##                        zone looks over CityGround).
## --- Liberty Heights ---
##   liberty_heights    — LibertyHeightsDirector config (LibertyHeightsStage
##                        .LIBERTY_HEIGHTS, Act VIII, Liberty Heights: the zone
##                        Supers in the roster's order, each promoted to its
##                        zone's miniboss; guest squads of Fort Kessler's army
##                        kinds; the cracks of Paragon's craters).
## --- the Concord of Stars ---
##   concord            — true: the Concord of Stars' shared rules (Act IX,
##                        ConcordRules as Game.concord: Beams, Abduction,
##                        Terraforming, and the Final Harvest when the
##                        RECKONING has a "final_harvest" key); ground
##                        "concord" is the placeholder ConcordGround (from the
##                        "floor" dictionary, styles ruins / moon / hull), on
##                        the normal scattered-obstacle arena (no "blocks").
##   terraforming       — the stage's Terraforming: any key of
##                        ConcordRulesData.TERRAFORMING overrides it ({} = the
##                        defaults; e.g. "boss_mult" lets a stage's boss heal on
##                        the turf).
##   gravity            — the Proving Moon's low gravity (owner-approved
##                        proposal: "knockback goes twice as far for everyone,
##                        both armies, and leaps are longer"; 2.0 there, absent
##                        = 1): read only through ConcordRules.gravity() (the
##                        enemy knockback decay is divided by it; the enemies'
##                        shoves on summons and the Proving Moon kits' leaps
##                        are multiplied by it).
##   zones              — Act IX stubs too: the planned zones (names and starts).
## --- the Crash Site ---
##   crash_site         — CrashSiteDirector config (CrashSiteStage.CRASH_SITE,
##                        Act IX, the Crash Site: the crater's seeded turf,
##                        Infestation's egg cap, Nothing Hatched, the Brood
##                        Matriarch's "matriarch" event); ground "crash_site" is
##                        its CrashSiteGround (the four zone floors).
## --- the Proving Moon ---
##   proving_moon       — ProvingMoonDirector config (ProvingMoonStage
##                        .PROVING_MOON, Act IX, the Proving Moon: the
##                        Warbeast and Last Trophy objectives; the "warbeast"
##                        event); ground "proving_moon" is its
##                        ProvingMoonGround (the four zone floors).
## --- the Ark ---
##   ark                — ArkDirector config (ArkStage.ARK, Act IX, the Ark of
##                        the Concord: the Specimen Vaults' tanks and the
##                        Reactor's vents as structure windows, the wrecks;
##                        the "luminous_archon" event); ground "ark" is its
##                        ArkGround (four zone floors).
## --- the Hall of Two Truths ---
##   two_truths         — TwoTruthsDirector config (TwoTruthsStage.TWO_TRUTHS:
##                        the Scales' Balance, the "crocodile_rise" and
##                        "devourers_whelp" events); ground "two_truths" is its
##                        TwoTruthsGround (four zone floors).
## --- the Black Tide ---
##   corsair            — true: the Black Tide's shared rules (Act X, CorsairRules
##                        as Game.corsair: Boarding, the Deck, Strikes from the
##                        Sea, and the Black Tide Reckoning when the RECKONING
##                        has a "black_tide" key); ground "corsair" is the
##                        placeholder CorsairGround (the sea and the deck, from
##                        the "floor" dictionary), on a FIXED furniture layout
##                        (the ARENA's "fixed" list, Arena).
##   deck               — the stage's deck (DeckBounds, Game.deck): any key of
##                        CorsairRulesData.DECK (length, beam, bow, ...).
##   boarding           — the stage's boarding (BoardingParty): any key of
##                        CorsairRulesData.BOARDING, plus "points" ([x, side]
##                        pairs on the straight rail), "whole_rail" and "boats"
##                        (the tier cap).
##   sea                — the stage's sea strikes (SeaStrikes): any key of
##                        CorsairRulesData.SEA ({} = the defaults).
## --- the Treasure Galleon ---
##   galleon            — GalleonDirector config (GalleonStage.GALLEON, Act X,
##                        the Treasure Galleon: the zones' banners and
##                        broadside rhythm from "zones", the broadsides, the
##                        deck cannons, the "hollow_eye" event, the HUD
##                        objectives); ground "galleon" is its GalleonGround
##                        (the deck and sea tiles under the zones' looks).
##   zones              — Act X stubs too: the planned zones (names and starts).
## --- the Smuggler's Cutter ---
##   cutter             — CutterDirector config (CutterStage.CUTTER, Act X, the
##                        Smuggler's Cutter: the powder barrels, the Fog Bank,
##                        Bosun Gorran's ram longboat ("gorran" event), the
##                        Fire Ship's patches, Not One Aboard); ground "cutter"
##                        is its CutterGround (the tiled sea and deck, a look
##                        per zone). Its boarding also sets "first_pour".
## --- the Hall of the Slain ---
##   norse              — true: the Hall of the Slain's shared rules
##                        (NorseRules as Game.norse: the Long Winter,
##                        Berserkergang, the Rune-Stones, and Ragnarök when the
##                        RECKONING has a "ragnarok" key); ground "norse" is the
##                        placeholder NorseGround (from the "floor" dictionary,
##                        styles snow / hall / ash), on the normal
##                        scattered-obstacle arena. Its timelines may use the
##                        event type "rune_stone" (RuneStones.start_event()).
##   long_winter        — the stage's Long Winter: any key of
##                        NorseRulesData.LONG_WINTER overrides it ({} = the
##                        defaults; "points": the braziers' offsets from the
##                        start).
##   rune_stones        — the stage's Rune-Stones: any key of
##                        NorseRulesData.RUNE_STONES overrides it ({} = the
##                        defaults; e.g. its horn "table").
## --- the Barrow Fields ---
##   barrow_fields      — BarrowFieldsDirector config (BarrowFieldsStage
##                        .BARROW_FIELDS: the braziers of each later zone, the
##                        open barrows' cap, the Fjord's drifts, Keep the
##                        Fires' banner, the "barrow" and "wight" events);
##                        ground "barrow_fields" is its BarrowFieldsGround (the
##                        zone floors).
## --- Valgard ---
##   valgard            — ValgardDirector config (ValgardStage.VALGARD: the
##                        Feast at the long tables, the hall's hearths on a
##                        lattice, the Einherjar Champion objective; the
##                        "einherjar_champion" event); ground "valgard" is its
##                        ValgardGround (the four zone floors).
## --- Vigrid ---
##   vigrid             — VigridDirector config (VigridStage.VIGRID, the Hall of
##                        the Slain's finale: the Fading Light's look and the
##                        dark taking a brazier per zone, the early dark's
##                        vanguard, the "muspel_giant" event); ground "vigrid"
##                        is its VigridGround (four zone floors).
## --- the Necropolis Dynasty ---
##   dynasty            — true: the Necropolis Dynasty's shared rules
##                        (DynastyRules as Game.dynasty: Rebirth, the Black
##                        Land, Heka, and the Devourer's Hour when the
##                        RECKONING has a "devourers_hour" key); ground
##                        "dynasty" is the placeholder DynastyGround (from the
##                        "floor" dictionary, styles sand / temple / hall), on
##                        the normal scattered-obstacle arena.
##   rebirth            — the stage's Rebirth: any key of
##                        DynastyRulesData.REBIRTH overrides it ({} = the
##                        defaults; e.g. "jars_required").
##   jars               — the stage's own Canopic Jar clock: any key of
##                        DynastyRulesData.JARS ({} = the stubs' clock; "every"
##                        0 = off, for a stage that places its jars with
##                        Rebirth.place_jar()).
##   quicksand          — any key of DynastyRulesData.QUICKSAND ({} = defaults;
##                        "chance" 0 = no fixed patches).
##   sandstorm          — any key of DynastyRulesData.SANDSTORM ({} = defaults).
##   heka               — any key of DynastyRulesData.HEKA ({} = defaults).
##   zones              — the Dynasty stubs too: the planned zones.
## --- the Necropolis of Sand ---
##   necropolis         — NecropolisDirector config (NecropolisStage
##                        .NECROPOLIS: the Canopic Jars beside the tombs, No
##                        Jars Left, the Sandstorm Pass's storm, the Sand
##                        Colossus's "colossus" event); ground "necropolis" is
##                        its NecropolisGround (the four zone floors).
## --- the Temple of the Lioness ---
##   lioness_temple     — LionessTempleDirector config (LionessTempleStage
##                        .LIONESS_TEMPLE: the Awakening Statues' wakes and
##                        rows, the Lion Warden's sealed hall; the
##                        "statues_wake" and "lion_warden" events); ground
##                        "lioness_temple" is its LionessTempleGround (the four
##                        zone floors).
## --- the Celestial Host ---
##   host               — true: the Celestial Host's shared rules (HostRules
##                        as Game.host: Judgment, Hallowed Light, Grace, and
##                        the Last Trumpet when the RECKONING has a
##                        "last_trumpet" key); ground "host" is the
##                        placeholder HostGround (from the "floor" dictionary,
##                        styles stair / wheel / rose), on the normal
##                        scattered-obstacle arena (each obstacle casts a
##                        pillar's shadow).
##   judgment           — any key of HostRulesData.JUDGMENT ({} = defaults).
##   light              — any key of HostRulesData.LIGHT ({} = defaults).
##   clouds             — any key of HostRulesData.CLOUDS ({} = defaults;
##                        "chance" 0 = no fixed cloud banks).
##   grace              — any key of HostRulesData.GRACE ({} = defaults).
##   zones              — the Host stubs too: the planned zones.
## --- the Silver Stair ---
##   silver_stair       — SilverStairDirector config (SilverStairStage.STAIR:
##                        the Stair's steps and low cloud banks, Without Sin,
##                        the "cherub_gate" event); ground "silver_stair" is
##                        its SilverStairGround (four zone floors).
## --- the Wheel of Thrones ---
##   wheel_of_thrones   — WheelOfThronesDirector config
##                        (WheelOfThronesStage.SPHERES: the turning spheres'
##                        crystal rings per zone, the "spheres_dominion" event,
##                        The Wheel Breaks); ground "wheel_of_thrones" is its
##                        WheelOfThronesGround (four zone floors).
## --- the Empyrean ---
##   empyrean           — EmpyreanDirector config (EmpyreanStage.EMPYREAN: the
##                        Choir's widening of the Light, the "seventh_herald"
##                        event, The Last Word); ground "empyrean" is its
##                        EmpyreanGround (four zone floors).
## --- the Age of Titans ---
##   primeval           — true: the Age of Titans' shared rules
##                        (PrimevalRules as Game.primeval: Packs, Herds,
##                        Scavengers, and the Stampede of Ash when the
##                        RECKONING has a "stampede_of_ash" key); ground
##                        "primeval" is the placeholder PrimevalGround (from
##                        the "floor" dictionary, styles fern / plain / ash),
##                        on the normal scattered-obstacle arena (every
##                        obstacle shelters from a stampede).
##   packs              — any key of PrimevalRulesData.PACKS ({} = defaults).
##   herds              — any key of PrimevalRulesData.HERDS ({} = defaults;
##                        "cap" 0 = no herd comes on its own).
##   scavengers         — any key of PrimevalRulesData.SCAVENGERS ({} =
##                        defaults).
##   zones              — the Titans stubs too: the planned zones.
## --- the Fern Basin ---
##   fern_basin         — FernBasinDirector config (FernBasinStage.FERN: the
##                        Tar Seeps, the Bog Crocs, the "nest_mother" event);
##                        ground "fern_basin" is its FernBasinGround (four
##                        zone floors and the tar pools, from each zone's
##                        "ground" "tar").
## --- the Great Plain ---
##   great_plain        — GreatPlainDirector config (GreatPlainStage.PLAIN:
##                        the Watering Hole, the Canyon's narrow front, the
##                        "herd_mother" event, Nothing Taken); ground
##                        "great_plain" is its GreatPlainGround (four zone
##                        floors); a zone's "canyon": true narrows the
##                        stampedes' front there.
## --- the Last Day ---
##   last_day           — LastDayDirector config (LastDayStage.LAST_DAY: Fire
##                        from the Sky, the growing meteor, the "sky_king"
##                        event); ground "last_day" is its LastDayGround (four
##                        zone floors); its RECKONING "extinction" is the
##                        Extinction (PrimevalRules), the meteor that ends the
##                        run in victory.
## --- the Turning Year ---
##   wild               — true: the Turning Year's shared rules (WildRules
##                        as Game.wild: the seasons, Bloom and Blight,
##                        Overgrowth, and Spring Returns when the RECKONING
##                        has a "spring_returns" key); ground "wild" is the
##                        placeholder WildGround (from the "floor" dictionary,
##                        styles greenwood / fae / tree), on the normal
##                        scattered-obstacle arena (the thickets grow into its
##                        empty cells, Arena.add_obstacle()).
##   seasons            — any key of WildRulesData.SEASONS ({} = defaults;
##                        "length" 150 = the World-Tree's year turning twice).
##   bloom              — any key of WildRulesData.BLOOM ({} = defaults).
##   thickets           — any key of WildRulesData.THICKETS ({} = defaults).
##   zones              — the Wild stubs too: the planned zones.
##   (segments)         — a segment's optional "season_weights" (season id ->
##                        {kind: weight}) join its weights in that season, and
##                        a row's "season" keeps its kind to that season
##                        (SeasonCycle.timeline_weights(), the one helper).
## --- the Greenwood ---
##   greenwood          — GreenwoodDirector config (GreenwoodStage.GREENWOOD:
##                        the sacred groves, Scorched Earth, the "huntsman"
##                        event); ground "greenwood" is its GreenwoodGround
##                        (four zone floors over the act's greenwood style).
## --- the Fae Court ---
##   fae_court          — FaeCourtDirector config (FaeCourtStage.FAE_COURT:
##                        the endless summer, the fairy rings, the
##                        "winter_prince" event); ground "fae_court" is its
##                        FaeCourtGround (four zone floors over the act's fae
##                        style). A STAGE "seasons" may carry "wildfire_every".
## --- the World-Tree ---
##   world_tree         — WorldTreeDirector config (WorldTreeStage.WORLD_TREE:
##                        the "gardener" event's objective); ground
##                        "world_tree" is its WorldTreeGround (four zone floors
##                        over the act's tree style). Its RECKONING may carry
##                        "first_spring" (FirstSpring: the ending once the Green
##                        Mother is beaten).
class_name StageRegistry
extends RefCounted

## The campaign's acts in their final order (owner, Nov 2026: three Parts of
## five acts; docs/proposals/LAST_SIX_ACTS.md "The final order"). Act number =
## index + 1. Keys: id (the act's id: PassiveData "act", VictoryData.ACT_LINES,
## the Codex tab, DemoData.ACTS; the same as the act's Codex tab id), subtitle
## (the act's name on its tab), stages (its three stage ids, in play order).
const ACT_ORDER := [
	# --- Part One: the living ---
	{"id": "covenant", "subtitle": "The Crimson Covenant", "stages": ["graveyard", "crimson_march", "sanctum"]},
	{"id": "corsair", "subtitle": "The Black Tide", "stages": ["cutter", "galleon", "maelstrom"]},
	{"id": "court", "subtitle": "The Sanguine Court", "stages": ["ravensmoor", "witchwood", "castle_sanguis"]},
	{"id": "city", "subtitle": "The Last Line", "stages": ["skid_row", "fort_kessler", "liberty_heights"]},
	{"id": "shogunate", "subtitle": "The Shogunate of the Rising Sun", "stages": ["province", "kurogane", "sun_road"]},
	# --- Part Two: gods, hell and heaven ---
	{"id": "norse", "subtitle": "The Hall of the Slain", "stages": ["barrow_fields", "valgard", "vigrid"]},
	{"id": "dynasty", "subtitle": "The Necropolis Dynasty", "stages": ["necropolis", "lioness_temple", "two_truths"]},
	{"id": "pantheon", "subtitle": "The Olympian Republic", "stages": ["ilion", "olympus", "underworld"]},
	{"id": "inferno", "subtitle": "The Inferno", "stages": ["burning_gate", "silk_palace", "pandemonium"]},
	{"id": "host", "subtitle": "The Celestial Host", "stages": ["silver_stair", "wheel_of_thrones", "empyrean"]},
	# --- Part Three: beyond and before ---
	{"id": "eye", "subtitle": "The Ancient Eye", "stages": ["harbour", "archive", "spire"]},
	{"id": "empire", "subtitle": "The Electronic Empire", "stages": ["wastes", "assembly", "citadel"]},
	{"id": "concord", "subtitle": "The Concord of Stars", "stages": ["crash_site", "proving_moon", "ark"]},
	{"id": "primeval", "subtitle": "The Age of Titans", "stages": ["fern_basin", "great_plain", "last_day"]},
	{"id": "wild", "subtitle": "The Turning Year", "stages": ["greenwood", "fae_court", "world_tree"]},
]
## The three Parts of the act select, ACTS_PER_PART acts each in ACT_ORDER
## (owner, Nov 2026). Keys: name (the Part tab), subtitle (its tooltip).
const PARTS := [
	{"name": "Part One", "subtitle": "The living"},
	{"name": "Part Two", "subtitle": "Gods, hell and heaven"},
	{"name": "Part Three", "subtitle": "Beyond and before"},
]
## Boss kills on the previous stage (StageRegistry.unlock_of()) that open a
## stage (Meta.is_stage_unlocked()).
const UNLOCK_BOSS_KILLS: int = 1  # GDD §9.3 (slay the previous stage's boss)
## Acts per Part (ACT_ORDER is cut into PARTS in runs of this many).
const ACTS_PER_PART: int = 5
## Soul Ash multiplier of a run by the stage's position in its act (0, 1, 2):
## every act restarts at x1 / x1.25 / x1.5 (owner decision Oct 2026, GDD §15.0
## "Ossuary expansion: owner decisions"; kept by the reorder, owner Nov 2026).
const ASH_MULT_BY_POSITION: Array[float] = [1.0, 1.25, 1.5]  # TUNING (not in GDD)
## Stages in campaign order (stage select order, unlock chain), built once
## from ACT_ORDER.
static var ORDER: PackedStringArray = _build_order()
## Stage used when none (or an unknown id) is given.
const DEFAULT_ID: String = "graveyard"
## Stage id -> STAGE dictionary.
const STAGES := {
	"graveyard": GraveyardStage.STAGE,
	"crimson_march": CrimsonMarchStage.STAGE,
	"sanctum": SanctumStage.STAGE,
	"harbour": HarbourStage.STAGE,
	"archive": ArchiveStage.STAGE,
	"spire": SpireStage.STAGE,
	# --- the Electronic Empire ---
	"wastes": WastesStage.STAGE,
	"assembly": AssemblyStage.STAGE,
	"citadel": CitadelStage.STAGE,
	# --- the Olympian Republic ---
	"ilion": IlionStage.STAGE,
	"olympus": OlympusStage.STAGE,
	"underworld": UnderworldStage.STAGE,
	# --- the Shogunate of the Rising Sun ---
	"province": ProvinceStage.STAGE,
	"kurogane": KuroganeStage.STAGE,
	"sun_road": SunRoadStage.STAGE,
	# --- the Inferno ---
	"burning_gate": BurningGateStage.STAGE,
	"silk_palace": SilkPalaceStage.STAGE,
	"pandemonium": PandemoniumStage.STAGE,  # Act VI, stage 18
	# --- the Sanguine Court ---
	"ravensmoor": RavensmoorStage.STAGE,
	"witchwood": WitchwoodStage.STAGE,
	"castle_sanguis": CastleSanguisStage.STAGE,  # Act VII, stage 21
	# --- the Last Line ---
	"skid_row": SkidRowStage.STAGE,
	"fort_kessler": FortKesslerStage.STAGE,
	"liberty_heights": LibertyHeightsStage.STAGE,  # Act VIII, stage 24
	# --- the Concord of Stars ---
	"crash_site": CrashSiteStage.STAGE,
	"proving_moon": ProvingMoonStage.STAGE,
	"ark": ArkStage.STAGE,  # Act IX, stage 27
	# --- the Black Tide ---
	"cutter": CutterStage.STAGE,
	"galleon": GalleonStage.STAGE,
	"maelstrom": MaelstromStage.STAGE,
	# --- the Hall of the Slain ---
	"barrow_fields": BarrowFieldsStage.STAGE,
	"valgard": ValgardStage.STAGE,
	"vigrid": VigridStage.STAGE,  # The Hall of the Slain's finale
	# --- the Necropolis Dynasty ---
	"necropolis": NecropolisStage.STAGE,
	"lioness_temple": LionessTempleStage.STAGE,
	"two_truths": TwoTruthsStage.STAGE,  # Temporary Act XII, the finale
	# --- the Celestial Host ---
	"silver_stair": SilverStairStage.STAGE,
	"wheel_of_thrones": WheelOfThronesStage.STAGE,
	"empyrean": EmpyreanStage.STAGE,  # Temporary Act XIII, the finale (the end of Part One)
	# --- the Age of Titans ---
	"fern_basin": FernBasinStage.STAGE,
	"great_plain": GreatPlainStage.STAGE,
	"last_day": LastDayStage.STAGE,  # Temporary Act XIV, the finale
	# --- the Turning Year ---
	"greenwood": GreenwoodStage.STAGE,
	"fae_court": FaeCourtStage.STAGE,
	"world_tree": WorldTreeStage.STAGE,  # Temporary Act XV, the finale (the campaign finale)
}

## Every stage id of ACT_ORDER, in order (builds ORDER).
static func _build_order() -> PackedStringArray:
	var out := PackedStringArray()
	for act: Dictionary in ACT_ORDER:
		for id: String in act["stages"]:
			out.append(id)
	return out


## Number of acts (ACT_ORDER).
static func act_count() -> int:
	return ACT_ORDER.size()


## Act number (1-based ACT_ORDER position) of stage `id`; 1 when unknown.
static func act_of(id: String) -> int:
	var i := ORDER.find(id)
	return 1 if i < 0 else 1 + int(i / 3.0)


## Act id (ACT_ORDER "id") of stage `id`; the first act's when unknown.
static func act_id_of(id: String) -> String:
	return String(ACT_ORDER[act_of(id) - 1]["id"])


## Act number of act id `act_id` (0 when unknown).
static func act_number(act_id: String) -> int:
	for i in ACT_ORDER.size():
		if String(ACT_ORDER[i]["id"]) == act_id:
			return i + 1
	return 0


## "Act IV" for act number `act`.
static func act_name(act: int) -> String:
	return "Act %s" % roman(act)


## The act's name ("The Olympian Republic") for act number `act`.
static func act_subtitle(act: int) -> String:
	return String(ACT_ORDER[clampi(act, 1, ACT_ORDER.size()) - 1]["subtitle"])


## Stage ids of act number `act`, in campaign order.
static func stages_of_act(act: int) -> PackedStringArray:
	if act < 1 or act > ACT_ORDER.size():
		return PackedStringArray()
	return PackedStringArray(ACT_ORDER[act - 1]["stages"])


## Part index (0-based, PARTS) of act number `act`.
static func part_of_act(act: int) -> int:
	return clampi(int((act - 1) / float(ACTS_PER_PART)), 0, PARTS.size() - 1)


## "Chapter IX" for stage `id` (its 1-based campaign position).
static func chapter_of(id: String) -> String:
	return "Chapter %s" % roman(maxi(1, ORDER.find(id) + 1))


## The stage whose boss must fall to open stage `id` (the previous stage in
## ORDER; "" for the first stage, always open). One boss kill opens it
## (GDD §9.3; Meta.is_stage_unlocked()).
static func unlock_of(id: String) -> String:
	var i := ORDER.find(id)
	return "" if i <= 0 else ORDER[i - 1]


## Soul Ash multiplier of a run on stage `id` (its position in its act,
## ASH_MULT_BY_POSITION); 1.0 when unknown.
static func ash_mult_of(id: String) -> float:
	var i := ORDER.find(id)
	return 1.0 if i < 0 else ASH_MULT_BY_POSITION[i % 3]


## Roman numeral of `n` (1..3999).
static func roman(n: int) -> String:
	var out := ""
	var left := n
	for pair: Array in [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while left >= int(pair[0]):
			out += String(pair[1])
			left -= int(pair[0])
	return out


## False for a registered stage hidden from the stage select (STAGE "playable").
static func is_playable(id: String) -> bool:
	return STAGES.has(id) and bool((STAGES[id] as Dictionary).get("playable", true))

## Boss script id -> that boss's arrival dictionary (the STAGE "boss" keys).
## The autotest option --boss=ID puts one of them in the run's stage slot
## (keeping the stage's own arrival time), so a boss can be tested on any
## stage (Game._ready()).
const BOSS_ARRIVALS := {
	"alaric": GraveyardStage.BOSS,
	"vael": CrimsonMarchStage.BOSS,
	"seraphine": SeraphineData.ARRIVAL,
	# --- Gullhaven Harbour ---
	"merrow": MerrowData.ARRIVAL,
	# --- the Hollow Archive ---
	"archivist": ArchivistData.ARRIVAL,
	# --- Ul-Thalos, the Risen Spire ---
	"vhalneth": VhalnethData.ARRIVAL,
	# --- the Electronic Empire (stubs: each stage's BOSS until phase 2
	# gives the boss its own data file) ---
	"kestrel": WastesStage.BOSS,
	"motherboard": MotherboardData.ARRIVAL,  # Act III: the Assembly Halls (its own data file)
	# --- the Iron Citadel --- (its own data file, Act III phase 2)
	"deus_ex_machina": DeusData.ARRIVAL,
	# --- the Olympian Republic (stubs: each stage's BOSS until phase 2
	# gives the boss its own data file) ---
	"achilles": IlionStage.BOSS,
	"zeus": OlympusStage.BOSS,
	"hades": UnderworldStage.BOSS,
	# --- the Shogunate of the Rising Sun (stubs: each stage's BOSS until
	# phase 2 gives the boss its own data file) ---
	"kage": ProvinceStage.BOSS,
	"shogun": KuroganeStage.BOSS,
	"amaterasu": SunRoadStage.BOSS,
	# --- the Inferno (stubs: each stage's BOSS until phase 2 gives the
	# boss its own data file) ---
	"moloch": BurningGateStage.BOSS,
	"lilith": SilkPalaceStage.BOSS,
	"morning_star": PandemoniumStage.BOSS,  # Act VI, the finale's boss
	# --- the Sanguine Court (stubs: each stage's BOSS until phase 2
	# gives the boss its own data file) ---
	"vargr": RavensmoorStage.BOSS,
	"isolde": WitchwoodStage.BOSS,
	"carmilla": CastleSanguisStage.BOSS,  # Act VII, the finale's boss
	# --- the Last Line (stubs: each stage's BOSS until phase 2 gives
	# the boss its own data file) ---
	"don_marrow": SkidRowStage.BOSS,
	"harrow": FortKesslerStage.BOSS,
	"paragon": LibertyHeightsStage.BOSS,  # Act VIII, the finale's boss
	# --- the Concord of Stars (stubs: each stage's BOSS until phase 2
	# gives the boss its own data file) ---
	"hive_mother": CrashSiteStage.BOSS,
	"vrask_tal": ProvingMoonStage.BOSS,
	"harvester": ArkStage.BOSS,  # Act IX, the finale's boss
	# --- the Black Tide (stubs: each stage's BOSS until phase 2 gives the
	# boss its own data file) ---
	"crow": CutterStage.BOSS,
	"marrec": GalleonStage.BOSS,
	"vandermere": MaelstromStage.BOSS,  # Act X, the finale's boss
	# --- the Hall of the Slain (stubs: each stage's BOSS
	# until phase 2 gives the boss its own data file) ---
	"hrimgar": BarrowFieldsStage.BOSS,
	"sigrun": ValgardStage.BOSS,
	"odin": VigridStage.BOSS,  # The Hall of the Slain's finale boss
	# --- the Necropolis Dynasty (stubs: each
	# stage's BOSS until phase 2 gives the boss its own data file) ---
	"anubis": NecropolisStage.BOSS,
	"sekhmet": LionessTempleStage.BOSS,
	"osiris": TwoTruthsStage.BOSS,  # The act's finale boss
	# --- the Celestial Host (stubs: each stage's
	# BOSS until phase 2 gives the boss its own data file) ---
	"seraiel": SilverStairStage.BOSS,
	"throne": WheelOfThronesStage.BOSS,
	"voice": EmpyreanStage.BOSS,  # The act's finale boss
	# --- the Age of Titans (stubs: each stage's
	# BOSS until phase 2 gives the boss its own data file) ---
	"scarmaw": FernBasinStage.BOSS,
	"ironbrow": GreatPlainStage.BOSS,
	"gravejaw": LastDayStage.BOSS,  # The act's finale boss
	# --- the Turning Year (stubs: each stage's
	# BOSS until phase 2 gives the boss its own data file) ---
	"stag_king": GreenwoodStage.BOSS,
	"summer_queen": FaeCourtStage.BOSS,
	"green_mother": WorldTreeStage.BOSS,  # The act's finale boss (the campaign's)
}
