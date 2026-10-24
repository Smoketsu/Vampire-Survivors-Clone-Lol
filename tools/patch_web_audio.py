"""patch_web_audio.py: stop the Web build from copying a sound's whole audio buffer on every play.

Usage (from the repo root, right after the Web export):
    python3 tools/patch_web_audio.py build/web/index.js

Why (mobile reset fix, Oct 2026; GDD §15.0 "Web audio buffer patch"): Godot 4.3's Web export
plays sounds as Web Audio "samples". Its JavaScript `GodotAudio.Sample.getAudioBuffer()` returns
`_duplicateAudioBuffer()`, so every play (and every loop restart) copies the sound's whole
stereo float buffer twice (a Float32Array per channel, then a new AudioBuffer). Necropathy plays
around 8-15 sounds a second in a run, which makes roughly 1-2 MB of short-lived audio memory
a second. Desktop browsers collect it, but on phones (iOS Safari first) the garbage builds up
faster than the browser frees it. The tab is then killed for memory and the page reloads: the
"game resets after a while" bug. One AudioBuffer may feed any number of AudioBufferSourceNodes
at once (Web Audio spec), and Godot never writes to a sample's buffer after it registers it (no
reversed playback, no `copyToChannel` outside the copy itself), so the patch returns the shared
buffer instead. Sound is unchanged; only the copy goes.

This script also applies tools/patch_web_gl.py (the WebGL id leak patch, GDD §15.0 "Web GL id
leak patch"), so the one documented step after a Web export covers both; its exit code is the
worse of the two.

The patch is a plain text replacement in the exported `index.js`, run by CI after the Web export
and by hand after a local one. It is idempotent: a file that is already patched is left as it is
(exit 0). If neither the original nor the patched text is found (a different engine version),
it exits 1 so the build fails loudly instead of shipping the leak unnoticed.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import patch_web_gl  # noqa: E402  (the second patch, same file)

ORIGINAL = "getAudioBuffer(){return this._duplicateAudioBuffer()}"  # Godot 4.3's minified accessor: a full copy per play.
PATCHED = "getAudioBuffer(){return this._audioBuffer}"  # The shared, never-written buffer instead.


def main() -> int:
    """Patches the index.js given as the only argument; returns the process exit code."""
    if len(sys.argv) != 2:
        print("usage: python3 tools/patch_web_audio.py build/web/index.js")
        return 2
    path = sys.argv[1]  # The exported engine script (build/web/index.js).
    with open(path, encoding="utf-8") as f:
        text = f.read()  # Whole file contents.
    count = text.count(ORIGINAL)  # Occurrences of the copying accessor (1 in Godot 4.3).
    if count == 0:
        if PATCHED in text:
            print("patch_web_audio: %s is already patched" % path)
            return patch_web_gl.patch_file(path)
        print("patch_web_audio: ERROR: the sample buffer accessor was not found in %s "
              "(engine version changed?); check GodotAudio.Sample.getAudioBuffer by hand" % path)
        return 1
    if count != 1:
        print("patch_web_audio: ERROR: %d copies of the accessor in %s, expected 1" % (count, path))
        return 1
    with open(path, "w", encoding="utf-8") as f:
        f.write(text.replace(ORIGINAL, PATCHED))
    print("patch_web_audio: %s patched (sounds share one buffer per sample)" % path)
    return patch_web_gl.patch_file(path)


if __name__ == "__main__":
    sys.exit(main())
