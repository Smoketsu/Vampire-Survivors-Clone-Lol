"""build_sfx.py: builds the sampled sound effects in assets/audio/sfx/ (audio overhaul, Nov 2026; GDD §15.0
"Audio overhaul: sampled sound effects and per-stage songs").

Usage (from the repo root; needs ffmpeg and numpy, and network access the first time):
    python3 tools/audio/build_sfx.py            # build every recipe
    python3 tools/audio/build_sfx.py bolt_cast  # build only the ids given

Sources: Kenney's CC0 sound packs (Impact Sounds, Sci-Fi Sounds, Interface Sounds, RPG Audio, Foley
Sounds, Digital Audio, Music Jingles; https://kenney.nl, licence CC0 1.0, see
assets/audio/LICENSES.md). They are downloaded once into tools/audio/.cache/ (gitignored) from the
public mirror MIRROR; only the built files are committed.

Each RECIPES entry is one game sound id (a SoundData.SOUNDS or pack key). Its value is one recipe or a
list of recipes (variants: written as <id>.ogg, <id>_2.ogg, ...; Sfx picks one at random per play).
A recipe is a dict:
    "layers": list of layer dicts, mixed together:
        "src":   "<pack>/<file stem>" (pack keys in PACKS; the stem without ".ogg");
        "gain":  layer gain in dB (default 0);
        "pitch": playback rate (tape-style: 0.5 = an octave lower and twice as long; default 1);
        "at":    start time in the output (s, default 0);
        "trim":  [start, length] of the source to use (s; default all of it);
        "lp" / "hp": lowpass / highpass corner (Hz, 0 = off);
        "rev":   true = play the source reversed (a swell into the sound).
    "verb": [wet 0..1, decay s, damp Hz] reverb (default none);
    "len":  maximum output length (s, default the layers' length);
    "fade": fade-out at the end (s, default 0.03);
    "gain": output gain in dB after peak normalisation to PEAK (default 0).
Every output is mono at 44.1 kHz, peak-normalised like the synth bank (Synth.PEAK), so the
SoundData volume_db of the id keeps its meaning.
"""

import os
import sys
import urllib.parse
import urllib.request

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audio_dsp as dsp  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # Repo root.
OUT_DIR = os.path.join(ROOT, "assets", "audio", "sfx")  # Where the built .ogg files go.
CACHE = os.path.join(ROOT, "tools", "audio", ".cache")  # Downloaded source packs (gitignored).
MIRROR = "https://media.githubusercontent.com/media/series-ai/jam-ready-assets/HEAD/"  # Public CC0 mirror of Kenney's packs.
PEAK = 0.89  # Peak level of every output (matches Synth.PEAK, 0..1 full scale).
QUALITY = 4  # Vorbis quality of the outputs (ffmpeg -q:a; ~64 kbps mono).
PACKS = {  # Pack key -> folder in the mirror.
    "impact": "kenney-impact-sounds/audio/Audio",
    "scifi": "kenney-sci-fi-sounds/audio/Audio",
    "ui": "kenney-interface-sounds/audio/Audio",
    "rpg": "kenney-rpg-audio/audio/Audio",
    "digital": "kenney-digital-audio/audio/Audio",
    "woosh": "kenney-foley-sounds/audio/Audio/Woosh",
    "plates": "kenney-foley-sounds/audio/Audio/Plating",
    "rocks": "kenney-foley-sounds/audio/Audio/Rocks",
    "swords": "kenney-foley-sounds/audio/Audio/Swords",
    "water": "kenney-foley-sounds/audio/Audio/Water",
    "helmet": "kenney-foley-sounds/audio/Audio/Swords",  # The helmet hits sit in the Swords folder.
    "jhit": "kenney-music-jingles/audio/Audio (Hit)",
    "jpizz": "kenney-music-jingles/audio/Audio (Pizzicato)",
    "jsteel": "kenney-music-jingles/audio/Audio (Steeldrum)",
}


def L(src: str, gain: float = 0.0, pitch: float = 1.0, at: float = 0.0, lp: float = 0.0, hp: float = 0.0,
      trim=None, rev: bool = False) -> dict:
    """Shorthand for one layer dict (keys as in the module header)."""
    return {"src": src, "gain": gain, "pitch": pitch, "at": at, "lp": lp, "hp": hp, "trim": trim, "rev": rev}


def R(*layers, verb=None, length: float = 0.0, fade: float = 0.03, gain: float = 0.0) -> dict:
    """Shorthand for one recipe dict (keys as in the module header)."""
    return {"layers": list(layers), "verb": verb, "len": length, "fade": fade, "gain": gain}


def variants(make, stems) -> list:
    """One recipe per source stem: make(stem) -> recipe (the frequent sounds get several takes)."""
    return [make(s) for s in stems]


# The dark, low register of the game (GDD §12: "low and unsettling") comes from pitching most sources
# down and adding a short room; UI sounds stay close to their sources (crisp, quiet).
RECIPES = {
    # --- Player necromancy -------------------------------------------------------------------------
    "bolt_cast": variants(lambda s: R(L("woosh/" + s, pitch=0.72, lp=2600), L("scifi/forceField_001", -14, 1.6, trim=[0, 0.25]),
                                      verb=[0.18, 0.5, 2500], length=0.4), ["woosh4", "woosh6", "woosh1"]),
    "bolt_hit": variants(lambda s: R(L("impact/" + s, pitch=0.7, lp=2500), L("impact/impactPunch_medium_000", -8, 0.6), length=0.35),
                         ["impactSoft_medium_000", "impactSoft_medium_002", "impactSoft_medium_004"]),
    "orb_hit": variants(lambda s: R(L("impact/" + s, pitch=0.75, lp=4000), verb=[0.15, 0.4, 4000], length=0.4),
                        ["impactGlass_light_000", "impactGlass_light_002", "impactGlass_light_004"]),
    "orb_block": R(L("scifi/forceField_002", 0, 1.5, trim=[0, 0.4], hp=200), L("impact/impactMetal_light_001", -6, 0.9), verb=[0.2, 0.6, 5000], length=0.5),
    "shadow_blast": R(L("scifi/lowFrequency_explosion_001", 0, 0.9), L("scifi/explosionCrunch_000", -6, 0.6, lp=1800), L("woosh/woosh3", -8, 0.5, rev=True),
                      verb=[0.25, 1.2, 1500], length=1.4),
    "mage_burst": variants(lambda s: R(L("scifi/" + s, 0, 1.25, lp=3500, trim=[0, 0.5]), L("impact/impactSoft_heavy_001", -6, 0.8), length=0.55),
                           ["explosionCrunch_002", "explosionCrunch_003"]),
    "spear_cast": variants(lambda s: R(L("woosh/" + s, 0, 0.9), L("swords/swordSlide1", -9, 1.2, trim=[0, 0.3]), length=0.5),
                           ["woosh2", "woosh5"]),
    "lance_cast": R(L("woosh/woosh7", 0, 0.75), L("swords/swordMetal3", -6, 0.8), L("scifi/forceField_000", -10, 1.2, trim=[0, 0.4]),
                    verb=[0.2, 0.8, 3000], length=0.9),
    "spear_hit": variants(lambda s: R(L("impact/" + s, 0, 0.8), L("plates/platesHit2", -10, 0.55), length=0.4),
                          ["impactWood_medium_000", "impactWood_medium_002", "impactWood_medium_004"]),
    "siphon_hit": variants(lambda s: R(L("digital/" + s, -2, 0.55, lp=1800), L("scifi/forceField_003", -8, 1.3, trim=[0, 0.25]), verb=[0.2, 0.5, 2000], length=0.45),
                           ["phaserDown1", "phaserDown2"]),
    "rapture_burst": R(L("scifi/forceField_004", 0, 0.8), L("digital/powerUp5", -8, 0.6, lp=2500), L("impact/impactBell_heavy_002", -10, 0.7),
                       verb=[0.3, 1.2, 2500], length=1.3),
    "corpse_burst": variants(lambda s: R(L("impact/" + s, 0, 0.75), L("scifi/slime_000", -3, 0.6), L("plates/platesHit5", -9, 0.6), verb=[0.12, 0.5, 2000], length=0.7),
                             ["impactSoft_heavy_000", "impactSoft_heavy_003"]),
    "eruption": R(L("scifi/lowFrequency_explosion_000", 0, 1.0), L("rocks/stonesHit1", -4, 0.8), L("scifi/explosionCrunch_004", -8, 0.7, lp=2000),
                  verb=[0.25, 1.4, 1500], length=1.8),
    "plague_cast": R(L("scifi/slime_001", 0, 0.7, trim=[0, 0.6]), L("woosh/woosh8", -6, 0.6), verb=[0.2, 0.8, 1500], length=0.8),
    "plague_tick": variants(lambda s: R(L("water/" + s, 0, 0.6, lp=1500), verb=[0.2, 0.4, 1200], length=0.35, gain=-3),
                            ["drip1", "drip3"]),
    "death_nova": R(L("scifi/lowFrequency_explosion_000", 0, 0.85), L("scifi/forceField_000", -4, 0.6), L("woosh/woosh7", -6, 0.5, rev=True),
                    verb=[0.35, 2.0, 1500], length=2.4),
    # --- The army ----------------------------------------------------------------------------------
    "summon_rise": variants(lambda s: R(L("rocks/" + s, 0, 0.75, trim=[0, 0.8]), L("scifi/forceField_001", -10, 0.7, trim=[0, 0.5]), verb=[0.2, 0.8, 2000], length=0.9),
                            ["stoneDrag2", "stoneDrag4"]),
    "summon_death": variants(lambda s: R(L("plates/" + s, 0, 0.62), verb=[0.1, 0.4, 3000], length=0.6),
                             ["platesHit1", "platesHit3", "platesHit9"]),
    "warrior_bash": variants(lambda s: R(L("impact/" + s, 0, 0.85), L("impact/impactPunch_medium_002", -6, 0.8), length=0.45),
                             ["impactMetal_medium_000", "impactMetal_medium_003"]),
    "priest_ward": R(L("ui/glass_004", -2, 0.8), L("scifi/forceField_002", -6, 1.4, trim=[0, 0.5]), verb=[0.35, 1.2, 5000], length=1.0),
    "abom_stomp": variants(lambda s: R(L("impact/" + s, 0, 0.6), L("scifi/lowFrequency_explosion_001", -8, 1.4, trim=[0, 0.4]), length=0.6),
                           ["impactPunch_heavy_000", "impactPunch_heavy_003"]),
    "rogue_dash": variants(lambda s: R(L("woosh/" + s, 0, 1.15), length=0.4), ["woosh4", "woosh6"]),
    "gargoyle_takeoff": R(L("woosh/woosh7", 0, 0.6), L("rocks/stoneDragHit1", -8, 0.9, trim=[0, 0.4]), length=0.9),
    "gargoyle_dive": R(L("woosh/woosh3", 0, 0.55, rev=True), L("rocks/stoneHit2", -4, 0.8, at=0.5), length=1.0),
    "frost_bolt": variants(lambda s: R(L("impact/" + s, -2, 1.2), L("woosh/woosh1", -6, 1.3, lp=6000), verb=[0.2, 0.5, 6000], length=0.4),
                           ["impactGlass_light_001", "impactGlass_light_003"]),
    "deep_freeze": R(L("impact/impactGlass_heavy_002", 0, 0.8), L("impact/impactGlass_medium_001", -4, 1.1, at=0.08), L("scifi/forceField_003", -8, 2.0, trim=[0, 0.4]),
                     verb=[0.3, 1.2, 6000], length=1.2),
    # banshee_wail stays synthesized (no CC0 source fits a wail).
    "catapult_launch": R(L("rpg/creak1", 0, 0.8), L("woosh/woosh2", -3, 0.6, at=0.1), length=0.9),
    "catapult_impact": variants(lambda s: R(L("impact/" + s, 0, 0.7), L("rocks/stonesHit2", -3, 0.8), verb=[0.12, 0.6, 2000], length=0.8),
                                ["impactWood_heavy_000", "impactWood_heavy_003"]),
    # --- Enemies and bosses ------------------------------------------------------------------------
    "enemy_hit": variants(lambda s: R(L("impact/" + s, 0, 0.8, lp=3000), length=0.25, gain=-2),
                          ["impactPunch_medium_000", "impactPunch_medium_001", "impactPunch_medium_003", "impactPunch_medium_004"]),
    "enemy_death": variants(lambda s: R(L("helmet/" + s, 0, 0.75), L("impact/impactSoft_medium_001", -6, 0.7), length=0.5),
                            ["hitHelmet1", "hitHelmet2", "hitHelmet3", "hitHelmet4"]),
    "boss_arrive": R(L("impact/impactBell_heavy_001", 0, 0.5), L("scifi/lowFrequency_explosion_000", -4, 0.8), L("impact/impactBell_heavy_000", -6, 0.38, at=0.05),
                     verb=[0.45, 3.0, 1200], length=3.5),
    "boss_telegraph": R(L("swords/swordSlide2", 0, 0.7), L("digital/phaserUp3", -10, 0.5, lp=1500), verb=[0.2, 0.6, 2500], length=0.7),
    "boss_impact": R(L("impact/impactPunch_heavy_002", 0, 0.55), L("scifi/explosionCrunch_001", -4, 0.6, lp=2200), L("scifi/lowFrequency_explosion_001", -6),
                     verb=[0.25, 1.0, 1500], length=1.2),
    "reckoning": R(L("impact/impactBell_heavy_001", 0, 0.42), L("impact/impactBell_heavy_001", -3, 0.42, at=1.1), L("impact/impactBell_heavy_001", 0, 0.38, at=2.2),
                   L("scifi/lowFrequency_explosion_000", -6, 0.7, at=2.2), verb=[0.5, 3.5, 1000], length=5.0),
    # --- The necromancer ---------------------------------------------------------------------------
    "player_hurt": variants(lambda s: R(L("impact/" + s, 0, 0.85), L("woosh/woosh6", -10, 0.8), length=0.4),
                            ["impactSoft_heavy_001", "impactSoft_heavy_002"]),
    "player_death": R(L("impact/impactBell_heavy_000", 0, 0.45), L("scifi/lowFrequency_explosion_000", -3, 0.6), L("woosh/woosh7", -6, 0.4, rev=True),
                      verb=[0.5, 3.5, 1000], length=4.0),
    "xp_pickup": variants(lambda s: R(L("ui/" + s, 0, 1.25, hp=600), length=0.2, gain=-2), ["glass_002", "glass_003", "glass_006"]),
    "level_up": R(L("jpizz/jingles-pizzicato_04", 0, 0.9), L("ui/glass_004", -8, 1.0), verb=[0.25, 1.0, 5000], length=2.0),
    "card_select": R(L("ui/select_002", 0), L("ui/glass_001", -8, 0.9), length=0.4),
    # --- Menus (stay close to their sources: crisp and quiet) --------------------------------------
    "ui_hover": R(L("ui/tick_001", 0, 1.1), length=0.12, gain=-4),
    "ui_confirm": R(L("ui/click_002", 0), length=0.25),
    "ui_back": R(L("ui/back_001", 0), length=0.35),
    "panel_open": R(L("ui/maximize_006", 0, 0.9), verb=[0.12, 0.4, 5000], length=0.5),
    "panel_close": R(L("ui/minimize_006", 0, 0.9), verb=[0.12, 0.4, 5000], length=0.5),
    "purchase": R(L("rpg/handleCoins", 0), L("ui/confirmation_002", -6), length=0.8),
    "denied": R(L("ui/error_004", 0, 0.9), length=0.45),
    "ui_tick": R(L("ui/scroll_002", 0), length=0.15, gain=-3),
    # --- Power-ups, chests and ultimates -----------------------------------------------------------
    "pu_magnet": R(L("digital/phaserUp1", 0, 0.7, lp=3500), L("scifi/forceField_001", -6, 1.2, trim=[0, 0.5]), verb=[0.25, 0.8, 3000], length=1.0),
    "pu_feast": R(L("digital/powerUp2", 0, 0.75, lp=4000), L("water/sinkWater1", -10, 0.8, trim=[0, 0.5]), verb=[0.25, 0.8, 3000], length=1.0),
    "pu_hyper": R(L("digital/powerUp7", 0, 0.8), L("scifi/forceField_004", -6, 1.4, trim=[0, 0.5]), verb=[0.25, 0.8, 4000], length=1.0),
    "pu_stasis": R(L("impact/impactGlass_heavy_000", 0, 0.7), L("digital/phaserDown3", -6, 0.6), verb=[0.35, 1.2, 4000], length=1.2),
    "pu_frenzy": R(L("digital/zapThreeToneUp", 0, 0.8, lp=4000), L("impact/impactPunch_heavy_001", -6, 0.8), verb=[0.2, 0.6, 3000], length=0.9),
    "pu_nova": R(L("scifi/lowFrequency_explosion_001", 0, 1.0), L("digital/powerUp9", -6, 0.7), verb=[0.3, 1.0, 2500], length=1.3),
    "chest_open": R(L("rpg/metalLatch", 0, 0.9), L("rpg/creak2", -3, 0.85, at=0.08), L("jsteel/jingles-steel_02", -4, 0.8, at=0.35),
                    verb=[0.25, 1.0, 4000], length=2.0),
    "ult_decree": R(L("impact/impactBell_heavy_000", 0, 0.6), L("scifi/forceField_000", -4, 0.7), L("jhit/jingles-hit_02", -8, 0.7),
                    verb=[0.45, 2.5, 2000], length=2.8),
    "ult_eclipse": R(L("scifi/lowFrequency_explosion_000", 0, 0.7), L("digital/phaserDown1", -4, 0.45, lp=1500), L("woosh/woosh7", -6, 0.4, rev=True),
                     verb=[0.45, 2.5, 1200], length=2.8),
    "ult_tide": R(L("water/sinkWater2", 0, 0.6), L("woosh/woosh3", -2, 0.45), L("scifi/lowFrequency_explosion_001", -6, 0.8, at=0.3),
                  verb=[0.4, 2.0, 1500], length=2.4),
}


def fetch(src: str) -> str:
    """Local path of source "<pack>/<stem>", downloaded from MIRROR into CACHE the first time."""
    pack, stem = src.split("/", 1)
    rel = PACKS[pack] + "/" + stem + ".ogg"  # Path inside the mirror.
    path = os.path.join(CACHE, rel)
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        urllib.request.urlretrieve(MIRROR + urllib.parse.quote(rel), path)
    return path


def render(recipe: dict) -> np.ndarray:
    """Mixes one recipe into a mono float buffer at dsp.RATE, peak-normalised to PEAK."""
    parts = []  # (start sample, buffer) per layer.
    for layer in recipe["layers"]:
        a = dsp.decode(fetch(layer["src"]))
        if layer["trim"]:
            s, ln = layer["trim"]
            a = a[int(s * dsp.RATE): int((s + ln) * dsp.RATE)].copy()
            a[-int(0.01 * dsp.RATE):] *= np.linspace(1.0, 0.0, int(0.01 * dsp.RATE))  # No click at the cut.
        if layer["rev"]:
            a = a[::-1].copy()
        a = dsp.resample(a, layer["pitch"])
        a = dsp.spectral_filter(a, layer["lp"], layer["hp"])
        parts.append((int(layer["at"] * dsp.RATE), a / max(1e-6, np.abs(a).max()) * dsp.db(layer["gain"])))
    n = max(s + len(a) for s, a in parts)
    out = np.zeros(n, np.float32)
    for s, a in parts:
        out[s: s + len(a)] += a
    if recipe["verb"]:
        wet, decay, damp = recipe["verb"]
        out = np.concatenate([out, np.zeros(int(decay * dsp.RATE), np.float32)])
        out = out * (1.0 - wet) + dsp.convolve(out, dsp.reverb_ir(decay, damp, 7, False))[: len(out)] * wet * 1.5
    if recipe["len"] > 0.0:
        out = out[: int(recipe["len"] * dsp.RATE)]
    lead = np.argmax(np.abs(out) > 0.002)  # Trim leading silence so every sound starts on its hit.
    out = out[lead:].copy()
    fade = int(recipe["fade"] * dsp.RATE)
    if 0 < fade < len(out):
        out[-fade:] *= np.linspace(1.0, 0.0, fade)
    return (out / max(1e-6, np.abs(out).max()) * PEAK * dsp.db(recipe["gain"])).astype(np.float32)


def main() -> int:
    """Builds the ids given on the command line (all when none); returns the exit code."""
    os.makedirs(OUT_DIR, exist_ok=True)
    ids = sys.argv[1:] or list(RECIPES)
    for sid in ids:
        recipes = RECIPES[sid] if isinstance(RECIPES[sid], list) else [RECIPES[sid]]
        for k, recipe in enumerate(recipes):
            name = sid if k == 0 else "%s_%d" % (sid, k + 1)  # <id>.ogg, <id>_2.ogg, ...
            dsp.encode_ogg(render(recipe), os.path.join(OUT_DIR, name + ".ogg"), QUALITY)
        print("built %s (%d take%s)" % (sid, len(recipes), "s" if len(recipes) > 1 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
