# Audio sources and licences

Audio overhaul, Nov 2026 (GDD §15.0 "Audio overhaul: sampled sound effects and per-stage songs").

## `sfx/`: sampled sound effects

Built by `tools/audio/build_sfx.py` (layered, pitched, filtered and reverbed) from these packs by
**Kenney** (<https://kenney.nl>), all released under **Creative Commons Zero (CC0 1.0)**, public domain,
no attribution required (credited anyway on the Credits screen):

- Impact Sounds, Sci-Fi Sounds, Interface Sounds, RPG Audio, Foley Sounds, Digital Audio, Music Jingles.

The source files were taken from the public CC0 mirror `series-ai/jam-ready-assets` on GitHub, which keeps
each pack's original `License.txt`. Only the built files are in this repository.

## `music/`: the stage songs

Written by `tools/audio/compose.py` from the scores in `tools/audio/songs.py` (original music for this game)
and played on the **GeneralUser GS v1.471** soundfont by S. Christian Collins
(<http://www.schristiancollins.com>). Its licence: "You may use GeneralUser GS without restriction for your own
music creation, private or commercial", and the rendered recordings carry the samples' rights for full use in
music production. The soundfont itself is a build input only and is not shipped.
