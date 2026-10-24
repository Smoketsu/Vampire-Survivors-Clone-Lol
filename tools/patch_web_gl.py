"""patch_web_gl.py: stop the Web build's WebGL object tables from growing for the whole run.

Usage (from the repo root, right after the Web export; tools/patch_web_audio.py runs it too, so
the one documented step `python3 tools/patch_web_audio.py build/web/index.js` applies both):
    python3 tools/patch_web_gl.py build/web/index.js

Why (mobile Web performance pass, Oct 2026; GDD §15.0 "Web GL id leak patch", docs/perf/MOBILE.md):
Godot 4.3's Web export is built with Emscripten, whose WebGL layer keeps a JavaScript table per
kind of GL object (buffers, vertex arrays, textures, syncs, ...) indexed by the integer id the
engine sees. A new id comes from ONE counter that only ever counts up (`GL.getNewId`), and the
table is padded with nulls up to that id; deleting an object only sets its slot to null. So
every GL object ever created leaves a slot behind in every table it touched. Godot's 2D renderer
creates and deletes a vertex array and two buffers for every polygon it draws when a canvas
item redraws (each draw_circle, draw_arc, thick draw_line, draw_colored_polygon), plus a fence
sync per frame; a busy fight redraws hundreds of them every frame (volley shots, effects,
telegraphs). The tables then grow by tens of thousands of slots a second, never shrink, and the
page's memory climbs with the time spent in busy fights until iOS kills the tab (the page reloads
to its Play screen: the owner's "crash at minute 7 with lots of projectiles", Oct 24).

The patch makes a deleted id reusable: each table keeps a free list, the delete functions put the
id on it and `getNewId` takes a free id first. Native GL drivers reuse names the same way, ids
stay unique among live objects (a slot is freed once, when its object is deleted), and nothing
else changes: same calls, same objects. The vertex-array delete gains the null check the others
already have, so deleting an unknown id twice cannot free it twice.

A plain text replacement in the exported `index.js`, idempotent (an already patched file is left
as it is, exit 0); if the expected text is missing (a different engine version) it exits 1 so
the build fails loudly instead of shipping the leak unnoticed.
"""

import sys

# The id allocator: one ever-growing counter, tables padded with nulls up to it.
GET_NEW_ID = "getNewId:table=>{var ret=GL.counter++;for(var i=table.length;i<ret;i++){table[i]=null}return ret}"
# The same, but a table's freed ids are handed out first (necroFree is the table's free list).
GET_NEW_ID_PATCHED = ("necroFree:(table,id)=>{if(id>0){(table.necroFree||(table.necroFree=[])).push(id)}},"
                      "getNewId:table=>{var f=table.necroFree;if(f&&f.length){return f.pop()}"
                      "var ret=GL.counter++;for(var i=table.length;i<ret;i++){table[i]=null}return ret}")
# The vertex-array delete has no null check (the other deletes skip an unknown id).
VAO_DELETE = "GLctx.deleteVertexArray(GL.vaos[id]);GL.vaos[id]=null"
VAO_DELETE_PATCHED = "if(!GL.vaos[id])continue;GLctx.deleteVertexArray(GL.vaos[id]);GL.vaos[id]=null;GL.necroFree(GL.vaos,id)"
# The other deletes: each nulls its slot once, after checking the object exists.
TABLES = ["buffers", "framebuffers", "programs", "queries", "renderbuffers", "shaders", "syncs", "textures"]


def patch(text: str) -> tuple:
    """Returns (new text, message, exit code) for the exported index.js contents `text`."""
    if GET_NEW_ID_PATCHED in text:
        return text, "already patched", 0
    if text.count(GET_NEW_ID) != 1 or text.count(VAO_DELETE) != 1:
        return text, ("ERROR: the Emscripten GL id allocator was not found as expected "
                      "(engine version changed?); check GL.getNewId by hand"), 1
    text = text.replace(GET_NEW_ID, GET_NEW_ID_PATCHED).replace(VAO_DELETE, VAO_DELETE_PATCHED)
    for t in TABLES:
        old = "GL.%s[id]=null" % t  # The slot is nulled once its object is deleted.
        if text.count(old) != 1:
            return text, "ERROR: %d deletes of GL.%s in the file, expected 1" % (text.count(old), t), 1
        text = text.replace(old, "%s;GL.necroFree(GL.%s,id)" % (old, t))
    return text, "patched (deleted WebGL ids are reused)", 0


def main() -> int:
    """Patches the index.js given as the only argument; returns the process exit code."""
    if len(sys.argv) != 2:
        print("usage: python3 tools/patch_web_gl.py build/web/index.js")
        return 2
    return patch_file(sys.argv[1])


def patch_file(path: str) -> int:
    """Patches the file at `path` in place; prints the result; returns the exit code."""
    with open(path, encoding="utf-8") as f:
        text = f.read()  # Whole file contents.
    new, message, code = patch(text)
    if code == 0 and new != text:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new)
    print("patch_web_gl: %s %s" % (path, message))
    return code


if __name__ == "__main__":
    sys.exit(main())
