"""songs.py: the written music of every stage (audio overhaul, Nov 2026). Read by compose.py (its header explains how
a song is built from these tables). Everything here is TUNING (not in GDD).

Notation
  scale     a compose.SCALES name; root = the tonic as a MIDI note (the act's key before a stage's "shift").
  meter     beats per bar: 4 (4/4), 3 (3/4) or 6 (6/8, where one beat is an eighth note and bpm counts eighths).
  motif     the act's two-bar leitmotif: "degree:beats" tokens, degrees relative to the note it starts on (0), "r" =
            rest, "|" = bar line (ignored). Every stage of the act develops this motif.
  prog_a/b  chord progressions, one chord per bar (repeated to 8 bars): scale degrees 1-7, suffix M / m / d / s / 7
            (major / minor / diminished / sus4 / add the 7th), "b" prefix = a semitone lower root.
  bass      bass pattern: hold, halves, pulse, drive, walk, waltz (3/4), six (6/8).
  drums     a DRUMS style; perc_pat = [(beat, velocity 0..1)] for the melodic percussion voice (taiko, timpani).
  ens       role -> General MIDI program (0-127; drums -> a drum kit preset of bank 128), or a dict with
            "prog" / "kit", "vol" (0-127), "pan" (0-127, 64 = centre), "oct" (octave shift), "vel" (velocity scale).
            Roles: pad, bass, lead, counter, arp, double (doubles the lead an octave down in A''), perc, bells, drone,
            drums. A role left out is silent.
  energy    1 sparse, 2 full, 3 the act finale (doubling, 16th hats, percussion in the intro).
  verb      (wet 0..1, decay seconds) of the shared reverb.
"""

# Drum styles: "bar" = one normal bar, "fill" = the last bar of a section; (beat, GM drum note, velocity 0..1).
# Notes: 36 kick, 38 snare, 39 clap, 41-50 toms (timpani in the orchestral kit 48), 42 closed / 46 open hat,
# 49 crash, 51 ride, 54 tambourine, 62 / 63 / 64 congas, 70 maracas.
H8 = [(k * 0.5, 42, 0.38 if k % 2 else 0.5) for k in range(8)]  # Eighth-note closed hats over a 4/4 bar.
DRUMS = {
    "dirge": {"bar": [(0, 36, 0.9), (2, 41, 0.6), (3.5, 41, 0.45)],
              "fill": [(0, 36, 0.9), (2, 41, 0.7), (2.5, 43, 0.6), (3, 45, 0.7), (3.5, 47, 0.85)]},
    "march": {"bar": [(0, 36, 0.9), (1, 38, 0.75), (1.75, 38, 0.35), (2, 36, 0.85), (3, 38, 0.75), (3.5, 38, 0.4), (3.75, 38, 0.45)],
              "fill": [(0, 36, 0.9)] + [(1 + k * 0.25, 38, 0.4 + k * 0.05) for k in range(12)]},
    "rock": {"bar": [(0, 36, 1.0), (1, 38, 0.9), (2, 36, 0.9), (2.5, 36, 0.7), (3, 38, 0.9)] + H8,
             "fill": [(0, 36, 1.0), (1, 38, 0.9), (2, 50, 0.8), (2.5, 48, 0.8), (3, 45, 0.85), (3.5, 41, 0.9)]},
    "half": {"bar": [(0, 36, 1.0), (1.5, 36, 0.6), (2, 38, 0.9), (3.25, 36, 0.5)] + H8,
             "fill": [(0, 36, 1.0), (1.5, 36, 0.6), (2, 38, 0.9), (3, 38, 0.6), (3.25, 38, 0.7), (3.5, 38, 0.8), (3.75, 38, 0.9)]},
    "four": {"bar": [(0, 36, 1.0), (1, 36, 0.95), (2, 36, 1.0), (3, 36, 0.95), (1, 39, 0.8), (3, 39, 0.8),
                     (0.5, 46, 0.45), (1.5, 46, 0.45), (2.5, 46, 0.45), (3.5, 46, 0.45)],
             "fill": [(0, 36, 1.0), (1, 36, 0.95), (2, 36, 1.0), (3, 36, 0.95)] + [(2 + k * 0.25, 38, 0.5 + k * 0.06) for k in range(8)]},
    "breakbeat": {"bar": [(0, 36, 1.0), (1, 38, 0.9), (1.75, 36, 0.6), (2.5, 36, 0.8), (3, 38, 0.9), (3.75, 38, 0.4)] + H8,
                  "fill": [(0, 36, 1.0), (1, 38, 0.9), (1.75, 36, 0.6), (2.5, 38, 0.7), (2.75, 38, 0.7), (3, 45, 0.8), (3.5, 43, 0.85)]},
    "gallop": {"bar": [(0, 36, 1.0), (0.5, 36, 0.55), (0.75, 36, 0.65), (1, 38, 0.8), (2, 36, 1.0), (2.5, 36, 0.55), (2.75, 36, 0.65), (3, 38, 0.8)],
               "fill": [(0, 36, 1.0), (0.5, 36, 0.55), (0.75, 36, 0.65), (1, 38, 0.8), (2, 45, 0.8), (2.5, 43, 0.85), (3, 41, 0.9), (3.5, 41, 0.95)]},
    "tribal": {"bar": [(0, 41, 1.0), (0.75, 43, 0.6), (1.5, 45, 0.7), (2, 41, 0.9), (2.5, 47, 0.6), (3, 45, 0.8), (3.5, 43, 0.6)]
               + [(k * 0.5, 70, 0.35) for k in range(8)],
               "fill": [(0, 41, 1.0), (0.5, 43, 0.7), (1, 45, 0.75), (1.5, 47, 0.8), (2, 41, 0.9), (2.5, 43, 0.85), (3, 45, 0.9), (3.5, 47, 0.95)]},
    "darbuka": {"bar": [(0, 64, 0.9), (1, 62, 0.6), (1.5, 62, 0.45), (2, 64, 0.8), (3, 63, 0.7), (3.5, 62, 0.45)] + [(k, 54, 0.3) for k in range(4)],
                "fill": [(0, 64, 0.9), (1, 62, 0.6), (1.5, 62, 0.5), (2, 64, 0.8), (2.5, 63, 0.6), (3, 63, 0.7), (3.25, 62, 0.6), (3.5, 62, 0.7), (3.75, 63, 0.8)]},
    "waltz": {"bar": [(0, 36, 0.8), (1, 42, 0.4), (2, 42, 0.4), (1, 38, 0.25), (2, 38, 0.25)],
              "fill": [(0, 36, 0.8), (1, 38, 0.5), (1.5, 38, 0.5), (2, 38, 0.7), (2.5, 38, 0.8)]},
    "jig": {"bar": [(0, 36, 0.9), (2, 42, 0.4), (3, 38, 0.6), (5, 42, 0.4), (0, 54, 0.4), (3, 54, 0.45), (4, 54, 0.3)],
            "fill": [(0, 36, 0.9), (2, 38, 0.5), (3, 38, 0.6), (4, 38, 0.7), (5, 38, 0.8)]},
}

THEMES = {  # Act id (the final act order) -> its shared musical material.
    # Act I, the Covenant: gothic liturgy, D minor.
    "covenant": {"scale": "harmonic", "root": 50, "meter": 4, "motif": "0:1.5 1:.5 2:1 4:1 | 3:1.5 2:.5 1:2",
                 "prog_a": ["1", "6", "4", "5M"], "prog_b": ["4", "1", "6", "5M", "4", "6", "2d", "5M"], "bass": "halves", "drums": "dirge"},
    # Act II, the Black Tide: a sea shanty in 6/8, A dorian.
    "black_tide": {"scale": "dorian", "root": 57, "meter": 6, "motif": "0:2 2:1 4:2 4:1 | 5:2 4:1 2:3",
                   "prog_a": ["1", "7", "1", "5", "1", "7", "3", "5"], "prog_b": ["3", "7", "4", "1", "6", "7", "5M", "5M"], "bass": "six", "drums": "jig",
                   "arp_rate": 1.0},
    # Act III, the Sanguine Court: a vampire waltz in 3/4, C minor.
    "sanguine": {"scale": "harmonic", "root": 48, "meter": 3, "motif": "4:1.5 5:.5 4:1 | 2:2 0:1",
                 "prog_a": ["1", "4", "5M", "1", "6", "4", "5M", "5M"], "prog_b": ["6", "3", "4", "1", "2d", "5M", "1", "5M"], "bass": "waltz", "drums": "waltz",
                 "arp_rate": 0.5},
    # Act IV, the Last Line: the city at night, E minor.
    "last_line": {"scale": "aeolian", "root": 52, "meter": 4, "motif": "0:.5 0:.5 3:1 2:1 0:1 | -1:1 0:.5 2:1.5 0:1",
                  "prog_a": ["1", "6", "3", "7"], "prog_b": ["4", "6", "1", "5", "4", "6", "7", "7"], "bass": "pulse", "drums": "breakbeat"},
    # Act V, the Shogunate: the in scale (phrygian degrees 1 b2 4 5 b6), E.
    "shogunate": {"scale": "phrygian", "root": 52, "meter": 4, "motif": "4:1 5:.5 4:.5 3:1 1:1 | 0:1.5 1:.5 3:2",
                  "prog_a": ["1", "2", "4", "1"], "prog_b": ["6", "7", "2", "1", "6", "7", "2", "1s"], "bass": "hold", "drums": None},
    # Act VI, the Hall of the Slain: horn fifths, D dorian.
    "norse": {"scale": "dorian", "root": 50, "meter": 4, "motif": "0:1.5 4:.5 3:1 2:1 | 1:2 0:2",
              "prog_a": ["1", "7", "4", "1"], "prog_b": ["6", "7", "1", "1", "4", "5", "7", "1"], "bass": "halves", "drums": "gallop"},
    # Act VII, the Necropolis Dynasty: hijaz (phrygian dominant), D.
    "dynasty": {"scale": "hijaz", "root": 50, "meter": 4, "motif": "4:1 3:.5 2:.5 1:1 2:1 | 1:1.5 0:.5 0:2",
                "prog_a": ["1", "2", "1", "4"], "prog_b": ["4", "7", "2", "1", "4", "2", "1", "1"], "bass": "halves", "drums": "darbuka"},
    # Act VIII, the Olympian Republic: epic aeolian, A.
    "olympian": {"scale": "aeolian", "root": 57, "meter": 4, "motif": "0:1 4:1 3:.5 4:.5 5:1 | 4:2 r:1 2:1",
                 "prog_a": ["1", "6", "7", "1"], "prog_b": ["4", "5", "3", "6", "4", "7", "5M", "5M"], "bass": "drive", "drums": "march"},
    # Act IX, the Inferno: phrygian dominant metal, E.
    "inferno": {"scale": "hijaz", "root": 52, "meter": 4, "motif": "0:.5 1:.5 0:.5 -1:.5 0:1 2:1 | 1:.5 0:.5 1:.5 2:.5 4:2",
                "prog_a": ["1", "2", "1", "2"], "prog_b": ["7", "6M", "2", "1", "7", "2", "1", "1"], "bass": "drive", "drums": "rock"},
    # Act X, the Celestial Host: lydian light, C.
    "host": {"scale": "lydian", "root": 48, "meter": 4, "motif": "0:1 1:1 3:2 | 2:1 1:1 0:2",
             "prog_a": ["1", "2", "6", "2"], "prog_b": ["6", "5", "3", "2", "6", "5", "2", "2"], "bass": "hold", "drums": None,
             "verb": (0.4, 3.2)},
    # Act XI, the Ancient Eye: drowned phrygian, C#.
    "eye": {"scale": "phrygian", "root": 49, "meter": 4, "motif": "0:2 1:1 -1:1 | 0:1.5 -2:.5 -3:2",
            "prog_a": ["1", "2", "6", "1"], "prog_b": ["4", "2", "5", "1", "6", "2", "5", "1"], "bass": "hold", "drums": None,
            "verb": (0.4, 3.5)},
    # Act XII, the Electronic Empire: synthwave, A minor.
    "empire": {"scale": "aeolian", "root": 57, "meter": 4, "motif": "0:.5 2:.5 4:.5 2:.5 0:.5 2:.5 4:.5 5:.5 | 4:1 2:1 1:2",
               "prog_a": ["1", "6", "3", "7"], "prog_b": ["4", "5", "6", "6", "4", "5", "7", "7"], "bass": "pulse", "drums": "half",
               "arp_rate": 0.25},
    # Act XIII, the Concord of Stars: melodic minor (its lydian-augmented colour), D.
    "concord": {"scale": "melodic", "root": 50, "meter": 4, "motif": "0:1.5 4:.5 6:2 | 5:1 4:1 2:2",
                "prog_a": ["1", "4", "1", "3"], "prog_b": ["4", "5", "3", "1", "4", "5", "2", "5"], "bass": "halves", "drums": "half",
                "verb": (0.35, 3.0)},
    # Act XIV, the Age of Titans: primal mixolydian, F.
    "titans": {"scale": "mixolydian", "root": 53, "meter": 4, "motif": "0:1 2:.5 4:.5 5:1 4:1 | 2:1 4:1 0:2",
               "prog_a": ["1", "7", "4", "1"], "prog_b": ["6", "4", "5", "1", "6", "4", "7", "7"], "bass": "halves", "drums": "tribal"},
    # Act XV, the Turning Year: a fae jig in 6/8, D mixolydian.
    "year": {"scale": "mixolydian", "root": 50, "meter": 6, "motif": "0:1 1:1 2:1 4:2 2:1 | 3:2 2:1 1:2 0:1",
             "prog_a": ["1", "7", "1", "4"], "prog_b": ["5", "4", "1", "7", "2", "4", "5", "5"], "bass": "six", "drums": "jig",
             "arp_rate": 1.0},
}

# Taiko / timpani patterns reused below (beat, velocity).
TAIKO = [(0, 1.0), (1.5, 0.6), (2, 0.9), (3, 0.7)]  # A 4/4 taiko figure.
TIMP = [(0, 0.9), (2, 0.6)]  # Timpani on the strong beats of 4/4.

STAGES = {  # Stage id -> its song. Keys as in this file's header; "act" names its THEMES entry.
    # --- Act I, the Covenant ---
    "graveyard": {"act": "covenant", "title": "Where the Bells Rot", "bpm": 84, "seed": 101, "energy": 2,
                  "ens": {"pad": 49, "drone": {"prog": 19, "vol": 50}, "bass": 43, "lead": 68, "arp": 46, "counter": 42, "bells": 14,
                          "drums": 48}, "verb": (0.35, 2.8)},
    "crimson_march": {"act": "covenant", "title": "The Crimson March", "bpm": 112, "seed": 102, "energy": 2, "shift": 2, "scale": "aeolian",
                      "prog_a": ["1", "7", "6", "5M"], "prog_b": ["4", "5M", "1", "1", "6", "7", "5M", "5M"], "drums": "march", "bass": "drive",
                      "ens": {"pad": 48, "bass": 43, "lead": {"prog": 61, "vol": 105}, "counter": 60, "arp": 45, "perc": 47, "drums": 48},
                      "perc_pat": TIMP, "lead_center": 67},
    "sanctum": {"act": "covenant", "title": "Judgment Without End", "bpm": 100, "seed": 103, "energy": 3, "shift": -2,
                "prog_a": ["1", "4", "b2M", "5M"], "prog_b": ["6", "4", "1", "5M", "6", "7", "1", "5M"], "drums": "march",
                "ens": {"pad": 19, "bass": 43, "lead": 52, "double": 61, "counter": 48, "perc": 47, "bells": 14, "drums": 48},
                "perc_pat": TIMP, "lead_center": 67, "verb": (0.38, 3.2)},
    # --- Act II, the Black Tide ---
    "cutter": {"act": "black_tide", "title": "Fog on the Cutter", "bpm": 192, "seed": 201, "energy": 2,
               "ens": {"pad": {"prog": 49, "vol": 55}, "bass": 32, "lead": 21, "counter": 110, "arp": 24, "drums": 0}},
    "galleon": {"act": "black_tide", "title": "Broadside", "bpm": 216, "seed": 202, "energy": 2, "shift": 3,
                "ens": {"pad": 48, "bass": 58, "lead": 110, "counter": 61, "arp": 21, "perc": 47, "drums": 0}, "perc_pat": [(0, 0.8), (3, 0.6)]},
    "maelstrom": {"act": "black_tide", "title": "Dead Men's Oath", "bpm": 204, "seed": 203, "energy": 3, "shift": -2, "scale": "aeolian",
                  "prog_a": ["1", "6", "7", "5M", "1", "6", "4", "5M"],
                  "ens": {"pad": 44, "drone": {"prog": 19, "vol": 55}, "bass": 43, "lead": 110, "double": 52, "arp": 46, "perc": 47, "drums": 0},
                  "perc_pat": [(0, 0.9), (3, 0.7), (5, 0.5)], "verb": (0.35, 2.6)},
    # --- Act III, the Sanguine Court ---
    "ravensmoor": {"act": "sanguine", "title": "Moonfang Waltz", "bpm": 132, "seed": 301, "energy": 1,
                   "ens": {"pad": 49, "bass": 42, "lead": 40, "arp": 6, "drums": 48}},
    "witchwood": {"act": "sanguine", "title": "The Witch Circle Dances", "bpm": 144, "seed": 302, "energy": 2, "shift": 5,
                  "ens": {"pad": 53, "bass": 45, "lead": 71, "arp": 8, "counter": 68, "drums": 48}},
    "castle_sanguis": {"act": "sanguine", "title": "The Queen Is Thirsty", "bpm": 156, "seed": 303, "energy": 3, "shift": -3,
                       "ens": {"pad": 19, "bass": 43, "lead": 6, "double": 48, "counter": 52, "arp": 45, "perc": 47, "drums": 48},
                       "perc_pat": [(0, 0.9)], "verb": (0.35, 2.8)},
    # --- Act IV, the Last Line ---
    "skid_row": {"act": "last_line", "title": "Skid Row After Dark", "bpm": 92, "seed": 401, "energy": 2, "drums": "half",
                 "ens": {"pad": 89, "bass": 38, "lead": 66, "arp": 4, "drums": 25}, "lead_center": 67},
    "fort_kessler": {"act": "last_line", "title": "Hold Fort Kessler", "bpm": 120, "seed": 402, "energy": 2, "shift": 2, "drums": "march", "bass": "drive",
                     "ens": {"pad": 48, "bass": 34, "lead": 60, "counter": 61, "arp": 30, "perc": 47, "drums": 16}, "perc_pat": TIMP, "lead_center": 67},
    "liberty_heights": {"act": "last_line", "title": "No Heroes Left", "bpm": 140, "seed": 403, "energy": 3, "shift": -4, "drums": "rock", "bass": "drive",
                        "prog_a": ["6", "7", "1", "1"],
                        "ens": {"pad": 48, "bass": 33, "lead": 61, "double": 48, "arp": 30, "counter": 60, "drums": 16}, "lead_center": 67},
    # --- Act V, the Shogunate ---
    "province": {"act": "shogunate", "title": "Ash Over the Paddies", "bpm": 92, "seed": 501, "energy": 2,
                 "ens": {"pad": {"prog": 49, "vol": 55}, "bass": 43, "lead": 77, "arp": 107, "perc": 116}, "perc_pat": TAIKO},
    "kurogane": {"act": "shogunate", "title": "Six Regiments", "bpm": 120, "seed": 502, "energy": 2, "shift": 2, "arp_rate": 0.25, "drums": "tribal",
                 "ens": {"pad": 48, "bass": 43, "lead": 73, "counter": 106, "arp": 107, "perc": 116, "drums": 48},
                 "perc_pat": [(0, 1.0), (0.5, 0.5), (1, 0.7), (2, 1.0), (2.5, 0.5), (3, 0.8), (3.5, 0.6)]},
    "sun_road": {"act": "shogunate", "title": "The Sun Goes Out", "bpm": 108, "seed": 503, "energy": 3, "shift": -1,
                 "ens": {"pad": 52, "bass": 43, "lead": 77, "double": 48, "arp": 107, "perc": 116, "bells": 14}, "perc_pat": TAIKO,
                 "verb": (0.35, 3.0)},
    # --- Act VI, the Hall of the Slain ---
    "barrow_fields": {"act": "norse", "title": "Barrow Frost", "bpm": 76, "seed": 601, "energy": 1, "drums": None,
                      "ens": {"pad": 49, "bass": 43, "lead": 110, "counter": 60, "perc": 116, "drone": {"prog": 52, "vol": 45}},
                      "perc_pat": [(0, 0.9), (2, 0.6)], "verb": (0.38, 3.0)},
    "valgard": {"act": "norse", "title": "The Feast of Valgard", "bpm": 112, "seed": 602, "energy": 2, "shift": 2,
                "ens": {"pad": 48, "bass": 43, "lead": 60, "double": 52, "counter": 110, "perc": 47, "drums": 48}, "perc_pat": TIMP, "lead_center": 67},
    "vigrid": {"act": "norse", "title": "Twilight of the Wolf", "bpm": 132, "seed": 603, "energy": 3, "shift": -2, "scale": "aeolian", "bass": "drive",
               "ens": {"pad": 44, "bass": 43, "lead": 61, "double": 52, "counter": 60, "perc": 116, "drums": 48}, "perc_pat": TAIKO, "lead_center": 67},
    # --- Act VII, the Necropolis Dynasty ---
    "necropolis": {"act": "dynasty", "title": "Sand in the Canopic Jars", "bpm": 88, "seed": 701, "energy": 2,
                   "ens": {"pad": 49, "bass": 43, "lead": 104, "counter": 73, "drone": {"prog": 49, "vol": 50}, "drums": 0}, "lead_center": 67},
    "lioness_temple": {"act": "dynasty", "title": "Eye of the Lioness", "bpm": 104, "seed": 702, "energy": 2, "shift": 2,
                       "ens": {"pad": 52, "bass": 43, "lead": 111, "arp": 46, "perc": 116, "drums": 0}, "perc_pat": [(0, 0.9), (2, 0.7)]},
    "two_truths": {"act": "dynasty", "title": "The Weighing", "bpm": 96, "seed": 703, "energy": 3, "shift": -2,
                   "ens": {"pad": 48, "bass": 43, "lead": 104, "double": 61, "counter": 52, "perc": 47, "bells": 14, "drums": 0},
                   "perc_pat": TIMP, "lead_center": 67},
    # --- Act VIII, the Olympian Republic ---
    "ilion": {"act": "olympian", "title": "The Shores of Ilion", "bpm": 116, "seed": 801, "energy": 2,
              "ens": {"pad": 48, "bass": 43, "lead": 56, "counter": 60, "arp": 46, "perc": 47, "drums": 48}, "perc_pat": TIMP, "lead_center": 69},
    "olympus": {"act": "olympian", "title": "Trial of the Pantheon", "bpm": 104, "seed": 802, "energy": 2, "shift": 3, "scale": "lydian",
                "prog_a": ["1", "2", "1", "5"], "prog_b": ["6", "2", "7", "5", "1", "2", "5", "5"], "bass": "halves",
                "ens": {"pad": 48, "bass": 43, "lead": 73, "counter": 60, "arp": 46, "double": 52, "perc": 47, "drums": 48}, "perc_pat": TIMP},
    "underworld": {"act": "olympian", "title": "Asphodel", "bpm": 92, "seed": 803, "energy": 3, "shift": -5, "scale": "phrygian",
                   "prog_a": ["1", "2", "7", "1"], "prog_b": ["4", "2", "6", "1", "4", "7", "2", "2"],
                   "ens": {"pad": 19, "bass": 43, "lead": 61, "double": 52, "counter": 57, "perc": 47, "bells": 14, "drums": 48},
                   "perc_pat": TIMP, "lead_center": 62, "verb": (0.38, 3.2)},
    # --- Act IX, the Inferno ---
    "burning_gate": {"act": "inferno", "title": "Brimstone Gate", "bpm": 132, "seed": 901, "energy": 2,
                     "ens": {"pad": {"prog": 19, "vol": 60}, "bass": 34, "lead": 29, "counter": 52, "drums": 16}, "lead_center": 67},
    "silk_palace": {"act": "inferno", "title": "Silk and Ash", "bpm": 96, "seed": 902, "energy": 2, "shift": 3, "bass": "halves", "drums": "darbuka",
                    "ens": {"pad": 92, "bass": 35, "lead": 54, "arp": 104, "counter": 66, "drums": 0}},
    "pandemonium": {"act": "inferno", "title": "The Morning Star Falls", "bpm": 160, "seed": 903, "energy": 3, "shift": -2,
                    "ens": {"pad": 19, "bass": 34, "lead": 30, "double": 52, "counter": 61, "perc": 47, "drums": 16},
                    "perc_pat": TIMP, "lead_center": 67},
    # --- Act X, the Celestial Host ---
    "silver_stair": {"act": "host", "title": "The Silver Stair", "bpm": 80, "seed": 1001, "energy": 1,
                     "ens": {"pad": 94, "bass": 43, "lead": 52, "arp": 8, "counter": 46, "bells": 14}, "lead_center": 67},
    "wheel_of_thrones": {"act": "host", "title": "The Wheel Turns", "bpm": 96, "seed": 1002, "energy": 2, "shift": 2, "drums": "dirge",
                         "ens": {"pad": 48, "bass": 43, "lead": 40, "arp": 46, "counter": 52, "perc": 47, "drums": 48}, "perc_pat": TIMP},
    "empyrean": {"act": "host", "title": "Be Not Afraid", "bpm": 88, "seed": 1003, "energy": 3, "drums": "dirge",
                 "ens": {"pad": 19, "bass": 43, "lead": 52, "double": 61, "arp": 8, "bells": 14, "perc": 47, "drums": 48},
                 "perc_pat": TIMP, "lead_center": 67, "verb": (0.42, 3.8)},
    # --- Act XI, the Ancient Eye ---
    "harbour": {"act": "eye", "title": "Gullhaven Fog", "bpm": 72, "seed": 1101, "energy": 1,
                "ens": {"pad": 49, "bass": 43, "lead": 69, "arp": 46, "bells": 14, "drone": {"prog": 99, "vol": 55}}, "lead_center": 67},
    "archive": {"act": "eye", "title": "Nothing Unwritten", "bpm": 84, "seed": 1102, "energy": 2, "shift": 3, "bass": "walk",
                "ens": {"pad": 92, "bass": 45, "lead": 8, "arp": 6, "counter": 71}},
    "spire": {"act": "eye", "title": "The Dead God Dreams", "bpm": 76, "seed": 1103, "energy": 3, "shift": -1, "drums": "dirge",
              "ens": {"pad": 19, "bass": 43, "lead": 52, "double": 57, "perc": 47, "bells": 14, "drone": {"prog": 99, "vol": 50}, "drums": 48},
              "perc_pat": TIMP, "lead_center": 65},
    # --- Act XII, the Electronic Empire ---
    "wastes": {"act": "empire", "title": "Static in the Wastes", "bpm": 100, "seed": 1201, "energy": 2,
               "ens": {"pad": 90, "bass": 38, "lead": 81, "arp": 80, "drums": 24}},
    "assembly": {"act": "empire", "title": "Assembly Line", "bpm": 124, "seed": 1202, "energy": 2, "shift": 2, "drums": "four", "bass": "drive",
                 "ens": {"pad": 95, "bass": 39, "lead": 80, "arp": 87, "perc": 118, "drums": 25},
                 "perc_pat": [(0.5, 0.6), (1.5, 0.5), (2.5, 0.6), (3.5, 0.5)]},
    "citadel": {"act": "empire", "title": "Deus Ex Machina", "bpm": 140, "seed": 1203, "energy": 3, "shift": -2, "drums": "rock", "bass": "drive",
                "ens": {"pad": 50, "bass": 38, "lead": 81, "double": 62, "arp": 80, "perc": 47, "drums": 24}, "perc_pat": TIMP},
    # --- Act XIII, the Concord of Stars ---
    "crash_site": {"act": "concord", "title": "Something Fell", "bpm": 90, "seed": 1301, "energy": 1,
                   "ens": {"pad": 99, "bass": 38, "lead": 54, "arp": 98, "drums": 24}},
    "proving_moon": {"act": "concord", "title": "The Hunt-Lord's Moon", "bpm": 120, "seed": 1302, "energy": 2, "shift": 1, "drums": "breakbeat", "bass": "drive",
                     "arp_rate": 0.25, "ens": {"pad": 95, "bass": 38, "lead": 81, "arp": 98, "perc": 116, "drums": 25}, "perc_pat": TAIKO},
    "ark": {"act": "concord", "title": "The Final Harvest", "bpm": 108, "seed": 1303, "energy": 3, "shift": -3, "drums": "four", "bass": "pulse",
            "ens": {"pad": 50, "bass": 38, "lead": 54, "double": 52, "arp": 98, "bells": 112, "perc": 47, "drums": 24}, "perc_pat": TIMP},
    # --- Act XIV, the Age of Titans ---
    "fern_basin": {"act": "titans", "title": "Tar and Fern", "bpm": 96, "seed": 1401, "energy": 2,
                   "ens": {"pad": 49, "bass": 32, "lead": 75, "arp": 12, "drums": 0}},
    "great_plain": {"act": "titans", "title": "Stampede", "bpm": 132, "seed": 1402, "energy": 2, "shift": 2, "arp_rate": 0.25, "bass": "drive",
                    "ens": {"pad": 48, "bass": 43, "lead": 60, "counter": 75, "arp": 12, "perc": 116, "drums": 48}, "perc_pat": TAIKO, "lead_center": 67},
    "last_day": {"act": "titans", "title": "The Day the Sky Fell", "bpm": 112, "seed": 1403, "energy": 3, "shift": -2, "scale": "aeolian",
                 "prog_a": ["1", "7", "6", "7"],
                 "ens": {"pad": 44, "bass": 43, "lead": 61, "double": 52, "counter": 60, "perc": 47, "bells": 14, "drums": 48},
                 "perc_pat": TIMP, "lead_center": 67},
    # --- Act XV, the Turning Year ---
    "greenwood": {"act": "year", "title": "The Greenwood Hunt", "bpm": 180, "seed": 1501, "energy": 2,
                  "ens": {"pad": 49, "bass": 32, "lead": 73, "counter": 110, "arp": 24, "drums": 0}},
    "fae_court": {"act": "year", "title": "A Fair Bargain", "bpm": 168, "seed": 1502, "energy": 2, "shift": 2, "scale": "lydian",
                  "prog_a": ["1", "2", "1", "5"], "prog_b": ["6", "2", "7", "5", "1", "2", "5", "5"],
                  "ens": {"pad": 53, "bass": 45, "lead": 8, "arp": 46, "counter": 74, "drums": 0}},
    "world_tree": {"act": "year", "title": "The First Spring", "bpm": 192, "seed": 1503, "energy": 3, "shift": -2, "scale": "dorian",
                   "ens": {"pad": 48, "bass": 32, "lead": 110, "double": 52, "counter": 73, "arp": 46, "perc": 116, "bells": 14, "drums": 0},
                   "perc_pat": [(0, 0.9), (3, 0.7)]},
}

DEFAULT_VOL = {"pad": 72, "bass": 96, "lead": 108, "counter": 72, "arp": 66, "double": 84, "perc": 96, "bells": 58, "drone": 60, "drums": 100}  # CC7 per role.
DEFAULT_PAN = {"pad": 64, "bass": 64, "lead": 64, "counter": 40, "arp": 88, "double": 70, "perc": 64, "bells": 96, "drone": 64}  # CC10 per role.


def spec_for(stage_id: str) -> dict:
    """The full spec of a stage's song: its act's THEME overlaid with the STAGES entry, ensemble entries expanded."""
    st = STAGES[stage_id]
    spec = dict(THEMES[st["act"]])
    spec.update({k: v for k, v in st.items() if k != "ens"})
    ens = {}
    for role, v in st["ens"].items():
        d = dict(v) if isinstance(v, dict) else ({"kit": v} if role == "drums" else {"prog": v})
        d.setdefault("vol", DEFAULT_VOL[role])
        d.setdefault("pan", DEFAULT_PAN.get(role, 64))
        ens[role] = d
    spec["ens"] = ens
    return spec
