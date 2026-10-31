#!/usr/bin/env python3
"""Text review extractor: every piece of text a player might see, as docs/text_review/strings.json.

Usage (from the repo root):  python3 tools/text_review/extract_text.py [--audit] [--dropped]

It statically scans scripts/**/*.gd (through gd_lex.py, a small GDScript tokenizer) and
web/mobile_shell.html, classifies every string literal as player-facing text or not, and writes
docs/text_review/strings.json: a list of
    {id, category, group, context, file, line, text, kind, contexts}
sorted by category, group, then source order. `kind` is "text", "name" (a short capitalised name),
"template" (a format string with %s / %d / {x} placeholders) or "unsure" (kept because it might be
shown, but the scan could not tell). Exact duplicate texts inside one category are collapsed into
one entry whose `contexts` lists every place it appears.

Ids are stable across text edits: built from the file and the structural context (the data row
and field, or the enclosing function and an index), never from the text or the line number, and
safe as db doc ids ([A-Za-z0-9_-], at most 120 chars).

The scan drops: dictionary keys, ids (snake_case), paths, colours, numbers, pixel masks, anything in
print / push_error / push_warning / assert, the autotest and report and tool files, summary / report
functions, and one-word button / tab / chip labels (listed in docs/text_review/dropped.json with a
reason, so the choices can be audited).

Known blind spots: text assembled from several pieces at run time (a sentence built from a name, a
verb table and a number), strings loaded from files other than .gd / the web shell (the .tres
resources, the scenes and the Godot project settings hold no player text), and text in the art
(sprites with letters). Those are not visible to a static scan.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gd_lex  # noqa: E402

SHOW: set = set()  # Drop reasons whose multi-word drops are printed (--show), for auditing.
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.path.join(ROOT, "docs", "text_review")

# ----------------------------------------------------------------------------------------------
# Categories (in display order) and the file -> category / group mapping.
# ----------------------------------------------------------------------------------------------
CATEGORIES = [
    "Story & epilogue",
    "Stages & bosses",
    "Enemies & Codex",
    "Spells",
    "Summons & evolutions",
    "Passives & synergies",
    "Characters, skins & titles",
    "Achievements & unlocks",
    "Ossuary (trees, masteries, relics, offerings, caskets, recolours)",
    "Difficulty, modifiers, Pact, Oath, Hyper",
    "In-run HUD, banners & level-up",
    "Results & victory",
    "Menus & settings text",
    "Co-op",
    "Web page",
]
C_STORY, C_STAGES, C_ENEMIES, C_SPELLS, C_SUMMONS, C_PASSIVES, C_CHARS, C_ACH, C_OSS, C_DIFF, C_RUN, C_RES, C_MENU, C_COOP, C_WEB = CATEGORIES

# (regex on the repo-relative path, category). First match wins.
CATEGORY_BY_FILE = [
    (r"scripts/data/epilogue_data\.gd$", C_STORY),
    (r"scripts/ui/epilogue_screen\.gd$", C_STORY),
    (r"scripts/data/stages/", C_STAGES),
    (r"scripts/data/stage_registry\.gd$", C_STAGES),
    (r"scripts/data/(achilles|amaterasu|archivist|black_sun|call_drowned|deus|hades|hundred_shadows|kage|kestrel|merrow|motherboard|paris_arrow|puppet|river_styx|scrap_swarm|seraphine|shogun|stolen_thunder|undertow|verse|vhalneth|zeus|death_ray)_data\.gd$", C_STAGES),
    (r"scripts/data/(arena|wave)_data\.gd$", C_STAGES),
    (r"scripts/enemies/", C_STAGES),
    (r"scripts/data/(enemy|battle_sister|.*_enemy)_data\.gd$", C_ENEMIES),
    (r"scripts/data/codex_data\.gd$", C_ENEMIES),
    (r"scripts/ui/codex_", C_ENEMIES),
    (r"scripts/data/(ability|evolution|grave_spell)_data\.gd$", C_SPELLS),
    (r"scripts/abilities/", C_SPELLS),
    (r"scripts/data/(ultimate|player_ability)_data\.gd$", C_SPELLS),
    (r"scripts/player/", C_RUN),
    (r"scripts/data/(unit|summon_evolution)_data\.gd$", C_SUMMONS),
    (r"scripts/horde/", C_SUMMONS),
    (r"scripts/data/(passive|synergy)_data\.gd$", C_PASSIVES),
    (r"scripts/data/(character|skin|title)_data\.gd$", C_CHARS),
    (r"scripts/ui/(character_|prerun_title|title_frame|prerun_hyper_skins)", C_CHARS),
    (r"scripts/data/unlock_data\.gd$", C_ACH),
    (r"scripts/ui/codex_feat_row\.gd$", C_ACH),
    (r"scripts/data/(meta|relic|offering|mastery|casket|recolour)_data\.gd$", C_OSS),
    (r"scripts/data/(casket_ui|relic_ui|mastery_ui|ossuary_ui)_data\.gd$", C_OSS),
    (r"scripts/ui/(ossuary|relic_|mastery_|rite_picker|prerun_rites)", C_OSS),
    (r"scripts/core/(relic|casket)", C_OSS),
    (r"scripts/data/(difficulty|run_modifier|pact|hyper)_data\.gd$", C_DIFF),
    (r"scripts/core/difficulty_modifiers\.gd$", C_DIFF),
    (r"scripts/data/(victory|save_backup)_data\.gd$", None),  # decided below
    (r"scripts/ui/(end_screen|victory_card|last_stand|coop_results)\.gd$", C_RES),
    (r"scripts/core/(victory_results|last_stand)", C_RES),
    (r"scripts/data/(in_run_ui|level_up|chest|powerup|banner|dread|feedback)_data\.gd$", C_RUN),
    (r"scripts/ui/(hud|level_up_panel|chest_|pause_menu|recipe_icon_row|run_build|ui_fx)", C_RUN),
    (r"scripts/pickups/", C_RUN),
    (r"scripts/coop/", C_COOP),
    (r"scripts/data/coop_", C_COOP),
    (r"scripts/ui/coop_", C_COOP),
    (r"scripts/data/touch_data\.gd$", C_WEB),
    (r"scripts/ui/(rotate_overlay)", C_WEB),
    (r"scripts/", C_MENU),
]

# Prettified group names for files whose stem is not a good heading.
FILE_GROUPS = {
    "end_screen": "End screen", "victory_card": "Victory card", "victory_results": "Victory results",
    "last_stand": "Last stand", "hud": "HUD", "hud_abilities": "HUD abilities", "hud_banners": "HUD banners",
    "level_up_panel": "Level-up cards", "chest_panel": "Chest reveal", "pause_menu": "Pause menu",
    "pre_run_setup": "Pre-run screen", "stage_select": "Stage select", "main_menu": "Main menu",
    "settings_menu": "Settings", "settings": "Settings", "settings_ui_data": "Settings",
    "front_door_data": "Title and stage select", "confirm_data": "Confirm dialogs",
    "confirm_dialog": "Confirm dialogs", "credits_data": "Credits", "credits_screen": "Credits",
    "save_backup_data": "Save backup", "feedback_data": "Feedback button", "input_hints": "Input hints",
    "input_hint_data": "Input hints", "ossuary_menu": "Ossuary", "ossuary_ui_data": "Ossuary",
    "ability_manager": "Level-up and chest cards", "summon_evolutions": "Summon evolution cards",
    "necro_spell_book": "Spell cards", "summon_behaviors": "Summon card lines",
    "class_passives": "Summon class lines", "golem_texts": "Bone Golem lines", "seraph_texts": "Fallen Seraph lines",
    "character_innates": "Character innates", "grave_spell_lines": "Spell card lines",
    "coop_net_data": "Lobby and errors", "coop_hud_data": "Co-op HUD", "coop_lockstep_data": "Co-op run",
    "coop_data": "Co-op run", "coop_lobby": "Lobby", "coop_screen": "Co-op screen",
    "coop_player_card": "Lobby player card", "touch_data": "Rotate screen", "rotate_overlay": "Rotate screen",
    "difficulty_modifiers": "Difficulty parts", "game_state": "Game state", "meta_data": "Ossuary",
    "unlock_data": "Unlocks", "view_data": "Zoom", "effects_data": "Effects setting",
}

# ----------------------------------------------------------------------------------------------
# Exclusions.
# ----------------------------------------------------------------------------------------------
# Whole files that only the autotest, tools or developers see (repo-relative regexes).
EXCLUDE_FILES = [
    r"scripts/core/autotest", r"_report\.gd$", r"_probe\.gd$", r"scripts/coop/coop_net_test\.gd$",
    r"scripts/coop/coop_net_bot\.gd$", r"scripts/ui/coop_ui_test\.gd$", r"scripts/ui/debug_overlay\.gd$",
    r"scripts/core/game_state\.gd$", r"scripts/core/feedback_report\.gd$", r"scripts/core/perf_",
    r"scripts/data/(sound|sprite|anim|aoe_art|motion|ui_art|ui_motion|palette|decal|marker_art|environment_art|idle|walk|frame|boss_pose|menu_backdrop|menu_theme|volley|covenant_fx|empire_fx|mask_icon|input_hint|walk)_data\.gd$",
    r"scripts/data/palette\.gd$", r"scripts/ui/ui_theme\.gd$", r"scripts/ui/ui_motion\.gd$", r"scripts/ui/touch_support\.gd$",
    r"scripts/audio/", r"scripts/fx/", r"scripts/core/save_",
    r"scripts/core/meta_progress\.gd$", r"scripts/core/casket_ledger\.gd$", r"scripts/core/combat_resolver\.gd$",
]
# Function names whose literals are summaries, reports, logs or probes.
EXCLUDE_FUNCS = re.compile(r"summary|report|autotest|debug|dump|probe|_log$|^_log|test_|^_fail|selftest|record_|"
                           r"^(floor|purge|steel|lock_on|line_of_fire)_line$", re.I)
# Functions whose literals are player text (objective lines, HUD suffixes, card lines, banners ...).
PLAYER_FUNCS = re.compile(r"objective|hud_suffix|zone_label|card_line|passive_line|banner|describe|announce|title|"
                          r"_text$|^text|hint|label|caption|_name$|^name|format_|stats_line|tooltip|blurb|flavour|desc", re.I)
# Assignment targets that hold summary / log text, not player text.
EXCLUDE_LHS = re.compile(r"^(counters|extra|how|boss_line|boss_state|js|key|file|url|cmd|args|rel|id|name_id|probe|name)$")
# Top-level constants that are lists of match words, queries, alphabets or test data, not text.
NON_TEXT_CONST = re.compile(r"(_WORDS$|QUERY$|ALPHABET$|PREFIX$|^TEST_|SHADER|_JS$|^SEC_)")
# One-word strings assigned to `.text` that are buttons or hint-strip words (dropped); other one-word
# `.text` values are headings or status labels (kept).
BUTTON_WORDS = {"Back", "Claim", "Skip", "Cancel", "Copy", "Done", "Leave", "Select", "Move", "Begin", "Next", "Start",
                "Open", "Play", "Quit", "Resume", "Restart", "Settings", "Recipes", "Again", "Menu", "Buy", "Raise",
                "Join", "Host", "Delete", "Paste", "Share", "Setup", "Tab", "Page", "Scroll", "Step", "Choose",
                "Rebind", "Standard", "Feedback", "Refund", "Wear", "Worn", "Free", "OK", "Ok", "Close", "Confirm"}
# Exact texts that sit in player-looking code but only feed autotest summaries.
EXCLUDE_TEXTS = {"relics %s | offering %s"}
# Calls whose string arguments are never shown.
DEBUG_CALLS = {"print", "push_error", "push_warning", "assert", "printerr", "print_rich", "prints", "printt",
               "print_debug", "print_verbose", "push_error_once", "assert_true", "assert_eq"}
# Callees (the innermost call) whose arguments are lookups, ids, paths, selectors or code.
DENY_CALLEE = re.compile(
    r"^(get|get_\w+|has\w*|contains|begins_with|ends_with|replace|replacen|split|rsplit|hash|eval|_log|stat_add|_arg|"
    r"_cli_\w+|texture|_texture|set_\w+|add_theme_\w+|get_theme_\w+|add_task|add_group_task|load|preload|path_join|"
    r"connect|emit_signal|call|callv|call_deferred|_fail|_state|make_loadout|create_from_string|substr|find|"
    r"count|float|int|str|is_\w+|Color|StringName|NodePath|_count_stuck|float_at|_read_\w+|_write_\w+|"
    r"load_\w+|save_\w+|open|FileAccess|ConfigFile|add_to_group|add_user_signal|bind|tr_n|create_timer|"
    r"stat_\w+|_stat_add|key_label|action_\w+|joypad_\w+|play\w*|sound|play_ui|bus\w*|ui_sound|"
    r"_touch_first|_below_icon|has_method|has_signal|is_in_group|add_child|remove_child|"
    r"get_environment|is_class|instantiate|new|_hash|_key|hash_str|log\w*|_id|id_\w+|sprite\w*|draw\w*|"
    r"make_unique|_variant|String|format_\w+)$")
# Callees that are UI text sinks (their string arguments are shown).
UI_SINK_CALLEE = re.compile(
    r"(banner|announce|notify|toast|label|title|caption|tile|line|text|heading|header|hint|tip|tooltip|section|status|"
    r"message|msg|strip|row|stat|set_values|append|add_item|show|popup|_below|_build_line|_offer|_delta\w*|button|"
    r"push_front|_set_value|count_up|tier_label|chip|badge|kicker|entry|blurb|desc\w*)", re.I)
# Callees that build a button / tab / chip: their one-word labels are excluded by the owner.
BUTTON_CALLEE = re.compile(r"(button|btn|tab|chip|bottom_strip|strip|hint_chip|_make_button|_tab)", re.I)
# Constants whose one-word values are menu buttons / tabs / chips (dropped when one word).
BUTTON_CONST = re.compile(
    r"^(MENU_ITEMS|TABS|BACK|BACK_LABELS|OPEN|WEAR|WORN|BUY|CANCEL|LEAVE_WORD|HINT_\w+|COL_\w+|DONE_TEXT|REFUND_YES|"
    r"REFUND_NO|REFUND|BACKUP|RESTORE|BUTTON_\w+|\w+_BUTTON|BUTTON_TEXT|RAISE|FREE|LOWER|COPY|BEGIN\w*|NEXT|AGAIN|MENU|"
    r"GROUPS|SEC_\w+|ARROWS?|SKIP|CLOSE|OK)$")
# Dictionary fields that never hold text (even when they hold a string with letters).
NON_TEXT_FIELDS = {"color", "colour", "tint", "icon", "sprite", "sprite_key", "anim", "sound", "sfx", "music", "shader",
                   "script", "scene", "kit", "behavior", "behaviour", "formation", "shape", "slot", "orient", "mode", "type",
                   "tag_id", "pattern", "mask", "frames", "palette", "ramp", "font", "texture", "path", "file", "url",
                   "id", "kind", "key", "class", "classes", "role", "source", "stat", "format", "fmt", "category",
                   "act_id", "stage", "stage_id", "boss_id", "boss", "numeral", "tree", "unlock_id", "requires_id"}
# Text-bearing field names (a value under one of these is player text with certainty).
TEXT_FIELDS = {"name", "display_name", "short_name", "short", "plural", "title", "subtitle", "description", "desc",
               "text", "flavour", "flavor", "lore", "banner", "line", "lines", "hint", "tooltip", "tagline", "blurb",
               "objective", "improves", "unlock", "unlock_text", "unlock_short", "look", "label", "labels", "boss_line",
               "act", "heading", "chapter", "caption", "tag", "goal", "reward", "pick", "feat", "how", "note"}
# Prefix / suffix fields that are text: "*_banner", "*_objective", "*_text", "*_line", "*_name".
TEXT_FIELD_RE = re.compile(r"(_banner|_objective|_text|_line|_name|_title|_desc|_hint|_label)$|^(arrive|defeat|dead)_")

# Fields that hold a name (the kind of such a value is "name" when it is short).
NAME_FIELDS = {"name", "display_name", "short_name", "short", "plural", "title", "label", "look"}

IDLIKE = re.compile(r"^[a-z0-9_.:/\-|%$#@+*=~<>!?\[\](){}]+$")
HEX_COLOUR = re.compile(r"^#?[0-9A-Fa-f]{3,8}$")
PIXEL_MASK = re.compile(r"^[.A-Za-z]{5,}$")
PLACEHOLDER = re.compile(r"%[-+ 0#]*\d*(?:\.\d+)?[sdfxXcioeEgG]|%%|\{[A-Za-z_][A-Za-z0-9_]*\}")
ROMAN = re.compile(r"^[IVXLC]+$")
WORD = re.compile(r"[A-Za-z][A-Za-z'\u2019\-]*")
CODEISH = re.compile(r"(::|=>|==|!=|window\.|document\.|navigator\.|function\s*\(|\.png|\.ogg|\.wav|\.gd\b|\.tscn|res://|user://|"
                     r"https?://|--[a-z]|\bnull\b|\bvar\s|\bconst\s|\(\)|\bcolor\b.*[:=])")


def rel(path: str) -> str:
    """Repo-relative posix path."""
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def prettify(ident: str) -> str:
    """snake_case id -> Title Case words."""
    s = re.sub(r"[_\-]+", " ", ident).strip()
    return " ".join(w.capitalize() if (w.islower() or w.isupper()) else w for w in s.split())


def lhs_name(lhs: str) -> str:
    """The assigned name of a statement head like 'constTITLE:String' or 'label.text'."""
    s = re.sub(r"^(?:static)?(?:var|const)", "", lhs)
    s = s.split(":")[0]
    return s


def category_for(path: str) -> str | None:
    for pat, cat in CATEGORY_BY_FILE:
        if re.search(pat, path):
            return cat
    return C_MENU


def is_excluded_file(path: str) -> bool:
    return any(re.search(p, path) for p in EXCLUDE_FILES)


# ----------------------------------------------------------------------------------------------
# Context naming.
# ----------------------------------------------------------------------------------------------
def frame_label(fr: gd_lex.Frame) -> str | None:
    """A readable label of a dict row (its id / name field), if it has one."""
    for k in ("id", "kind", "key", "display_name", "name"):
        v = fr.meta.get(k)
        if v and re.match(r"^[A-Za-z0-9_]+$", v):
            return v
    return None


def render_path(class_name: str, lit: gd_lex.Literal) -> tuple[str, str]:
    """(context text, stable key text) for a literal."""
    root = class_name or os.path.splitext(os.path.basename(lit.file))[0]
    if lit.top:
        base = f"{root}.{lit.top}"
    elif lit.func:
        base = f"{root}.{lit.func}()"
    else:
        base = root
    parts = []
    first_key = True
    for el in lit.path:
        if el[0] == "key":
            k = el[1]
            if first_key or not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", k):
                parts.append(f'["{k}"]')
            else:
                parts.append(f".{k}")
            first_key = False
        elif el[0] == "idx":
            fr, i = el[1], el[2]
            parts.append(f"[{i}]")
        # call args are not part of the structural path
    return base + "".join(parts), base + "".join(parts)


def row_frame(lit: gd_lex.Literal) -> gd_lex.Frame | None:
    """The data row (outermost dict frame that names itself) that holds the literal."""
    for fr in lit.rows:
        if fr.meta:
            return fr
    return None


def file_label(stem: str) -> str:
    """Human label of a source file: the FILE_GROUPS entry, else the stem without its _data / _stage suffix."""
    if stem in FILE_GROUPS:
        return FILE_GROUPS[stem]
    return prettify(re.sub(r"_(data|stage)$", "", stem))


def group_for(lit: gd_lex.Literal, path: str, is_data: bool) -> str:
    """The human sub-heading: a data row's name, else 'File label · CONSTANT' / the function's file label."""
    stem = os.path.splitext(os.path.basename(path))[0]
    if is_data and not path.startswith("scripts/data/stages/"):
        fr = row_frame(lit)
        if fr:
            for k in ("display_name", "name", "title", "label", "heading"):
                v = fr.meta.get(k)
                if v and not re.search(r"[.!?]$", v) and len(v) < 48:
                    return v
            lab = frame_label(fr)
            if lab:
                return prettify(lab)
        keys = [el[1] for el in lit.path if el[0] == "key"]
        if keys and lit.top and len(keys) >= 2:
            return prettify(keys[0])
    base = file_label(stem)
    if is_data and lit.top:
        return f"{base} \u00b7 {prettify(lit.top)}"
    return base


# ----------------------------------------------------------------------------------------------
# Classification.
# ----------------------------------------------------------------------------------------------
def classify(lit: gd_lex.Literal, path: str, is_data: bool):
    """Return (keep, kind, reason). `reason` explains drops (and unsure keeps)."""
    t = lit.text
    s = t.strip()
    if lit.is_key:
        return False, "", "dict-key"
    if lit.prefix in ("&", "^"):
        return False, "", "stringname"
    if not s:
        return False, "", "empty"
    if s in EXCLUDE_TEXTS:
        return False, "", "autotest-text"
    if set(lit.calls) & DEBUG_CALLS or any(c.split(".")[-1] in DEBUG_CALLS for c in lit.chains):
        return False, "", "debug-call"
    if lit.func and EXCLUDE_FUNCS.search(lit.func):
        return False, "", "report-function"
    if lit.top and NON_TEXT_CONST.search(lit.top):
        return False, "", "non-text-const"
    lname = lhs_name(lit.lhs)
    base_lname = lname.split(".")[-1].split("[")[0]
    if lit.lhs and EXCLUDE_LHS.match(base_lname) and not is_data:
        return False, "", "excluded-target"
    inner = lit.calls[-1] if lit.calls else ""
    if inner == "get" and lit.arg_index >= 1:
        inner = ""  # dict.get(key, "default text"): the default is shown when the key is missing
    if inner and DENY_CALLEE.match(inner) and not UI_SINK_CALLEE.search(inner):
        return False, "", "lookup-call"
    # Shape drops.
    letters = re.sub(PLACEHOLDER, "", s)
    if not re.search(r"[A-Za-z]{2}", letters) and not re.fullmatch(r"[A-Za-z]", letters.strip() or "-"):
        return False, "", "no-words"
    if re.fullmatch(r"[A-Za-z]", letters.strip()):
        return False, "", "single-letter"
    if s.startswith(("res://", "user://", "http://", "https://")):
        return False, "", "path-or-url"
    if HEX_COLOUR.match(s) and re.search(r"\d", s) and len(s) in (3, 4, 6, 7, 8):
        return False, "", "colour"
    if " " not in s and "\n" not in s:
        # Single token.
        if IDLIKE.match(s) and not s.endswith(("!", "?", ".")):
            return False, "", "id-like"
        if "_" in s and not re.search(r"[A-Z]{2,}\b", s):
            return False, "", "id-like"
        if PIXEL_MASK.match(s) and "." in s:
            return False, "", "pixel-mask"
        if re.search(r"[/\\]", s) or CODEISH.search(s) or s.startswith(("--", "-")):
            return False, "", "code-ish"
        if ROMAN.match(s):
            return False, "", "roman-numeral"
        # CamelCase class / node names (Button, Label, MainMenu) are not text unless in a text sink.
        return _one_word(lit, s, lname, base_lname, inner, is_data)
    # Multi-word.
    if CODEISH.search(s) and (not is_data or (lit.fkey or "").lower() not in TEXT_FIELDS):
        return False, "", "code-ish"
    if re.search(r"\b[a-z]+_[a-z_]+\b", s) and not re.search(r"[.!?:,]", s) and len(s.split()) <= 3:
        return False, "", "id-like"
    fkey = (lit.fkey or "").lower()
    if fkey in NON_TEXT_FIELDS and lit.direct and not re.search(r"[A-Z][a-z]+ [a-z]+", s):
        return False, "", "non-text-field"
    strong = bool(
        (fkey in TEXT_FIELDS or TEXT_FIELD_RE.search(fkey) or (is_data and not lit.calls))
        or re.search(r"(^|\.)(text|tooltip_text|placeholder_text|title|subtitle|caption|hint|desc|description|label|tip|"
                     r"message|msg|banner|line|note|prompt)$", base_lname)
        or (inner and UI_SINK_CALLEE.search(inner))
        or (lit.func and PLAYER_FUNCS.search(lit.func))
        or re.search(r"(TEXT|LINE|TITLE|HINT|LABEL|NAME|TIP|BANNER|HEADER|HEADING|INFO|PROMPT|ASK|CONFIRM|TAGLINE|BLURB|DESC)", lit.top or "")
    )
    kind = "template" if PLACEHOLDER.search(s) else "text"
    if kind == "text" and fkey in NAME_FIELDS and len(s.split()) <= 5 and not re.search(r"[.!?]$", s):
        kind = "name"
    if strong:
        return True, kind, ""
    return True, "unsure", "prose-in-code"


def _one_word(lit, s, lname, base_lname, inner, is_data):
    """Decide a single-word string. Names are kept; button / tab / chip labels are dropped."""
    top = lit.top or ""
    if BUTTON_CONST.match(top) or BUTTON_CONST.match(base_lname.upper()):
        return False, "", "button-label"
    if inner and BUTTON_CALLEE.search(inner):
        return False, "", "button-label"
    if base_lname == "text" and not is_data and s in BUTTON_WORDS:
        return False, "", "ui-text-one-word"
    if s in BUTTON_WORDS and not is_data:
        return False, "", "button-label"
    if not re.match(r"^[A-Z0-9\u00C0-\u024F]", s):
        return False, "", "lowercase-word"
    if lit.fkey and lit.fkey.lower() in NON_TEXT_FIELDS and lit.direct:
        return False, "", "non-text-field"
    if is_data:
        return True, "name", ""
    # Logic file: only in a clear sink.
    if inner and UI_SINK_CALLEE.search(inner):
        return True, "name", ""
    if re.search(r"(^|\.)(title|subtitle|caption|label|display_name|name|banner)$", base_lname):
        return True, "name", ""
    if base_lname == "text":
        return True, "name", ""
    if lit.stmt_head in ("return",) and re.match(r"^[A-Z][a-z]{3,}", s):
        return True, "unsure", "one-word-return"
    if lit.file.startswith("scripts/ui/") and re.match(r"^[A-Z][a-z]{2,}$", s) and (lit.in_array or lit.stmt_head == "for"):
        return True, "unsure", "one-word-in-ui-array"
    return False, "", "one-word-in-code"


# ----------------------------------------------------------------------------------------------
# Ids.
# ----------------------------------------------------------------------------------------------
def make_id(stem: str, key: str, used: dict) -> str:
    """A db-safe, stable id from file stem + context key; unique via a counter suffix."""
    base = re.sub(r"[^A-Za-z0-9]+", "_", f"{stem}__{key}").strip("_")
    if len(base) > 112:
        h = hashlib.sha1(base.encode()).hexdigest()[:8]
        base = base[:100].rstrip("_") + "_" + h
    n = used.get(base, 0)
    used[base] = n + 1
    return base if n == 0 else f"{base}_{n + 1}"


# ----------------------------------------------------------------------------------------------
# Scan.
# ----------------------------------------------------------------------------------------------
def scan_gd(dropped: list, audit: collections.Counter, per_file: collections.Counter) -> list[dict]:
    entries: list[dict] = []
    used: dict = {}
    files = []
    for dp, _, fns in os.walk(os.path.join(ROOT, "scripts")):
        for fn in fns:
            if fn.endswith(".gd"):
                files.append(os.path.join(dp, fn))
    files.sort()
    for f in files:
        rp = rel(f)
        if is_excluded_file(rp):
            audit["excluded-file"] += 1
            continue
        cat0 = category_for(rp)
        is_data = rp.startswith("scripts/data/")
        src = open(f, encoding="utf-8").read()
        lits, class_name = gd_lex.walk(rp, src)
        stem = os.path.splitext(os.path.basename(f))[0]
        func_idx: dict = collections.Counter()
        for lit in lits:
            keep, kind, reason = classify(lit, rp, is_data)
            if not keep:
                audit[reason] += 1
                if SHOW and reason in SHOW and re.search(r"[A-Za-z]+ [A-Za-z]+", lit.text):
                    print(f"DROP[{reason}] {rp}:{lit.line} {lit.text[:90]!r} calls={lit.calls} fkey={lit.fkey} lhs={lit.lhs[:25]} fn={lit.func}")
                if reason in ("button-label", "ui-text-one-word", "one-word-in-code", "lowercase-word", "single-letter"):
                    dropped.append({"file": rp, "line": lit.line, "text": lit.text, "reason": reason})
                continue
            cat = cat0
            if cat is None:
                cat = C_RES if re.search(r"victory", rp) else C_MENU
            # Per-constant category overrides inside shared data files.
            if rp.endswith("meta_data.gd") and re.search(r"ACHIEVEMENT", lit.top or ""):
                cat = C_ACH
            if rp.endswith("codex_data.gd") and re.search(r"ACHIEVE|FEAT|EARNED", lit.top or ""):
                cat = C_ACH
            if rp.endswith("codex_data.gd") and re.search(r"^(SPELL|SUMMON)|SPELL_EVOL|SUMMON_EVOL|EVOLUTION", lit.top or "") and False:
                pass
            if rp.endswith("meta_data.gd") and re.search(r"^(ASH|PACT|OATH)", lit.top or ""):
                cat = C_DIFF
            ctx, key = render_path(class_name, lit)
            if lit.top:
                id_key = key
            else:
                func_idx[lit.func] += 1
                id_key = f"{lit.func or 'top'}_{func_idx[lit.func]}"
            group = group_for(lit, rp, is_data)
            e = {
                "id": make_id(stem, id_key, used),
                "category": cat,
                "group": group,
                "context": ctx,
                "file": rp,
                "line": lit.line,
                "text": lit.text.strip("\n") if kind != "unsure" else lit.text.strip("\n"),
                "kind": kind,
            }
            if reason:
                e["why"] = reason
            entries.append(e)
            per_file[rp] += 1
    return entries


# ----------------------------------------------------------------------------------------------
# Web page.
# ----------------------------------------------------------------------------------------------
def scan_web() -> list[dict]:
    path = os.path.join(ROOT, "web", "mobile_shell.html")
    rp = rel(path)
    src = open(path, encoding="utf-8").read()
    out: list[dict] = []
    used: dict = {}

    def add(text, ctx, line, kind="text", group="Play screen"):
        out.append({"id": make_id("mobile_shell", ctx, used), "category": C_WEB, "group": group, "context": ctx,
                    "file": rp, "line": line, "text": text, "kind": kind})

    # HTML body text nodes and visible button labels.
    body = src[src.index("<body>"):]
    body_off = src[: src.index("<body>")].count("\n")
    for m in re.finditer(r"<(canvas|noscript|button|div)[^>]*>\s*([^<>]{3,}?)\s*</\1>", body):
        text = " ".join(m.group(2).split())
        if not text or "$GODOT" in text:
            continue
        line = body_off + body[: m.start(2)].count("\n") + 1
        tag = m.group(1)
        idm = re.search(r'id="([^"]+)"', m.group(0))
        ctx = f"<{tag}{'#' + idm.group(1) if idm else ''}>"
        if " " not in text:
            continue  # one-word buttons (Play, OK) are excluded by the owner
        add(text, ctx, line, group="Fallback messages")
    # JS string constants: join `'a' + 'b'` chains, keep prose.
    scripts = re.findall(r"<script>(.*?)</script>", src, re.S)
    for sc in scripts:
        sc_off = src[: src.index(sc)].count("\n")
        # strip comments
        clean = re.sub(r"/\*.*?\*/", lambda m: re.sub(r"[^\n]", " ", m.group(0)), sc, flags=re.S)
        clean = re.sub(r"(?m)(?<![:'\"\\])//.*$", "", clean)
        for m in re.finditer(r"((?:'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\")(?:\s*\+\s*(?:'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\"))*)", clean):
            parts = re.findall(r"'((?:[^'\\\n]|\\.)*)'|\"((?:[^\"\\\n]|\\.)*)\"", m.group(1))
            text = "".join(a or b for a, b in parts)
            text = text.replace("\\n", "\n").replace("\\'", "'").replace('\\"', '"')
            words = re.findall(r"[A-Za-z]{2,}", text)
            if len(words) < 3 or " " not in text or re.search(r"[{};=]|\.(js|wasm|pck)|https?:|\bpx\b", text):
                continue
            line_start = clean.rfind("\n", 0, m.start()) + 1
            if re.search(r"console\.\w+\(|new Error\(", clean[line_start: m.start()]):
                continue  # console messages are for developers, not the player
            line = sc_off + clean[: m.start()].count("\n") + 1
            ctx = f"line{line}"
            nm = re.search(r"(\w+)\s*=\s*$", clean[max(0, m.start() - 60): m.start()])
            if nm:
                ctx = nm.group(1)
            add(text, ctx, line, group="Messages")
    return out


# ----------------------------------------------------------------------------------------------
# Dedupe and write.
# ----------------------------------------------------------------------------------------------
def dedupe(entries: list[dict]) -> list[dict]:
    """Collapse identical texts inside one category into one entry with all contexts."""
    seen: dict = {}
    out: list[dict] = []
    for e in entries:
        k = (e["category"], e["text"])
        if k in seen:
            first = seen[k]
            first.setdefault("contexts", [{"context": first["context"], "file": first["file"], "line": first["line"]}])
            first["contexts"].append({"context": e["context"], "file": e["file"], "line": e["line"]})
            if first["kind"] == "unsure" and e["kind"] != "unsure":
                first["kind"] = e["kind"]
                first.pop("why", None)
            continue
        seen[k] = e
        out.append(e)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit", action="store_true", help="print drop reasons and silent files")
    ap.add_argument("--dropped", action="store_true", help="also write docs/text_review/dropped.json")
    ap.add_argument("--show", default="", help="comma list of drop reasons to print (multi-word drops)")
    args = ap.parse_args()
    SHOW.update(x for x in args.show.split(",") if x)
    dropped: list = []
    audit: collections.Counter = collections.Counter()
    per_file: collections.Counter = collections.Counter()
    entries = scan_gd(dropped, audit, per_file)
    web = scan_web()
    for w in web:
        per_file[w["file"]] += 1
    entries += web
    entries = dedupe(entries)
    order = {c: i for i, c in enumerate(CATEGORIES)}
    # Stable: category, then group in first-seen order, then source order.
    group_rank: dict = {}
    for e in entries:
        group_rank.setdefault((e["category"], e["group"]), len(group_rank))
    entries.sort(key=lambda e: (order[e["category"]], group_rank[(e["category"], e["group"])]))
    ids = [e["id"] for e in entries]
    assert len(ids) == len(set(ids)), "duplicate ids"
    assert all(re.fullmatch(r"[A-Za-z0-9_-]{1,120}", i) for i in ids), "bad id"
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, "strings.json"), "w", encoding="utf-8") as fh:
        json.dump(entries, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    if args.dropped:
        dropped.sort(key=lambda d: (d["file"], d["line"]))
        with open(os.path.join(OUT_DIR, "dropped.json"), "w", encoding="utf-8") as fh:
            json.dump(dropped, fh, ensure_ascii=False, indent=1)
            fh.write("\n")
    # Summary.
    print(f"entries: {len(entries)}")
    per_cat = collections.Counter(e["category"] for e in entries)
    for c in CATEGORIES:
        print(f"  {per_cat[c]:5d}  {c}")
    print(f"unsure: {sum(1 for e in entries if e['kind'] == 'unsure')}   "
          f"templates: {sum(1 for e in entries if e['kind'] == 'template')}   "
          f"names: {sum(1 for e in entries if e['kind'] == 'name')}")
    silent = []
    for dp, _, fns in os.walk(os.path.join(ROOT, "scripts")):
        for fn in sorted(fns):
            if fn.endswith(".gd"):
                p = rel(os.path.join(dp, fn))
                if per_file[p] == 0 and not is_excluded_file(p):
                    silent.append(p)
    print(f"files that contributed nothing ({len(silent)} of the non-excluded scripts):")
    if args.audit:
        for p in silent:
            print("   ", p)
        print("drop reasons:")
        for k, v in audit.most_common():
            print(f"   {v:6d} {k}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
