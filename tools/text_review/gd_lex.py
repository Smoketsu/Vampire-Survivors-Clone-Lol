"""Minimal GDScript lexer and structure walker for the text review extractor.

It is not a full parser. It tokenizes a .gd file (strings with their decoded text, identifiers,
numbers, operators; comments dropped), walks the bracket structure and yields one `Literal` per
string literal with the context needed to decide whether a player sees it:

  - the dictionary key path and array indices around it (so a data table value can be named as
    `SpellData.SPELLS["shadow_bolt"].description`);
  - the enclosing call chain (`print(...)`, `make_button(...)`) and the assignment target
    (`label.text = "..."`);
  - the enclosing function name or top-level const / var name;
  - whether the string is itself a dictionary key (those are never text).

Used only by tools/text_review/extract_text.py. Static analysis only, no Godot needed.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

IDENT_START = re.compile(r"[A-Za-z_]")
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
NUMBER = re.compile(r"0[xX][0-9A-Fa-f_]+|0[bB][01_]+|\d[\d_]*\.?\d*(?:[eE][+-]?\d+)?|\.\d[\d_]*")
OPS3 = ("<<=", ">>=", "**=")
OPS2 = ("==", "!=", "<=", ">=", ":=", "+=", "-=", "*=", "/=", "%=", "->", "&&", "||", "<<", ">>", "**", "|=", "&=", "^=")
ESCAPES = {"n": "\n", "t": "\t", "\\": "\\", '"': '"', "'": "'", "r": "", "u": "u"}


@dataclass
class Tok:
    """One token: kind is STR / ID / NUM / OP / NL; `col` is the 0-based column of its first char."""
    kind: str
    val: str
    line: int
    col: int
    prefix: str = ""  # For STR: "" plain, "&" StringName, "^" NodePath, "r" raw.


@dataclass
class Frame:
    """One open bracket while walking: '{' dict, '[' array / index, '(' call or grouping."""
    kind: str
    callee: str = ""          # For '(': the identifier (or dotted chain tail) before the bracket.
    callee_chain: str = ""    # For '(': the full dotted chain before the bracket.
    key: str | None = None    # For '{': the key of the value being parsed.
    expect_key: bool = True   # For '{': the next token starts a key.
    idx: int = 0              # For '[' and '(': element / argument index.
    meta: dict = field(default_factory=dict)  # For '{': the row's own id / display_name / name / title strings, filled as seen (post-pass naming).
    parent: "Frame | None" = None
    elem: int = -1            # Index of this frame inside its parent array (or -1).
    pkey: str | None = None   # Key of this frame inside its parent dict (or None).
    line: int = 0


@dataclass
class Literal:
    """A string literal with its structural context."""
    text: str
    line: int
    file: str
    is_key: bool
    prefix: str
    path: list              # Path elements: ("key", str) / ("idx", Frame, int) / ("arg", int)
    calls: list             # Callee names of every enclosing '(' frame, innermost last.
    chains: list            # Full dotted callee chains of every enclosing '(' frame.
    lhs: str                # Assignment target text ("" if none), e.g. "label.text".
    func: str               # Enclosing function name ("" at top level).
    top: str                # Top-level const / var name the literal sits in ("" inside functions).
    rows: list              # The enclosing dict frames, outermost first (for row naming).
    arg_index: int          # Argument index in the innermost '(' frame, or -1.
    col: int = 0
    stmt_head: str = ""     # First tokens of the statement (e.g. "return", "const X").
    in_array: bool = False  # True when the innermost frame is an array.
    fkey: str | None = None  # Nearest enclosing dictionary key (snapshot at the literal).
    direct: bool = False    # True when the innermost frame is a dictionary (the value is the field's own).
    stmt_toks: list = field(default_factory=list)  # (kind, val) of the statement tokens before this string.
    after: str = ""         # The next non-NL token value after the string (for "% [", ":" detection).
    prev: str = ""          # The previous token value before the string.


def decode(raw: str, is_raw: bool) -> str:
    """Decode GDScript escapes in a string body."""
    if is_raw or "\\" not in raw:
        return raw
    out = []
    i = 0
    while i < len(raw):
        c = raw[i]
        if c == "\\" and i + 1 < len(raw):
            n = raw[i + 1]
            if n == "u" and i + 5 < len(raw) + 0 and re.fullmatch(r"[0-9A-Fa-f]{4}", raw[i + 2:i + 6] or ""):
                out.append(chr(int(raw[i + 2:i + 6], 16)))
                i += 6
                continue
            if n == "\n":  # Line continuation inside a string.
                i += 2
                continue
            out.append(ESCAPES.get(n, n))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def tokenize(src: str) -> list[Tok]:
    """Turn a GDScript source into tokens. Comments are dropped; newlines are NL tokens."""
    toks: list[Tok] = []
    i, n, line, col0 = 0, len(src), 1, 0
    while i < n:
        c = src[i]
        if c == "\n":
            toks.append(Tok("NL", "\n", line, i - col0))
            line += 1
            i += 1
            col0 = i
            continue
        if c in " \t\r":
            i += 1
            continue
        if c == "#":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if c == "\\" and i + 1 < n and src[i + 1] == "\n":  # Explicit line continuation.
            line += 1
            i += 2
            col0 = i
            continue
        # String (with optional & ^ r prefix).
        pre = ""
        j = i
        if c in "&^" and j + 1 < n and src[j + 1] in "\"'":
            pre = c
            j += 1
        elif c == "r" and j + 1 < n and src[j + 1] in "\"'":
            pre = "r"
            j += 1
        if src[j] in "\"'" if j < n else False:
            q = src[j]
            start_line, start_col = line, i - col0
            if src.startswith(q * 3, j):
                k = j + 3
                while k < n:
                    if src[k] == "\\" and pre != "r":
                        k += 2
                        continue
                    if src.startswith(q * 3, k):
                        break
                    k += 1
                body = src[j + 3:k]
                i = k + 3
            else:
                k = j + 1
                while k < n and src[k] != q:
                    if src[k] == "\\" and pre != "r":
                        k += 2
                        continue
                    if src[k] == "\n":
                        break
                    k += 1
                body = src[j + 1:k]
                i = k + 1
            toks.append(Tok("STR", decode(body, pre == "r"), start_line, start_col, pre))
            nl = body.count("\n")
            if nl:
                line += nl
                col0 = src.rfind("\n", 0, i) + 1
            continue
        m = IDENT.match(src, i)
        if m and IDENT_START.match(c):
            toks.append(Tok("ID", m.group(0), line, i - col0))
            i = m.end()
            continue
        m = NUMBER.match(src, i)
        if m and (c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit())):
            toks.append(Tok("NUM", m.group(0), line, i - col0))
            i = m.end()
            continue
        for op in OPS3:
            if src.startswith(op, i):
                toks.append(Tok("OP", op, line, i - col0))
                i += 3
                break
        else:
            for op in OPS2:
                if src.startswith(op, i):
                    toks.append(Tok("OP", op, line, i - col0))
                    i += 2
                    break
            else:
                toks.append(Tok("OP", c, line, i - col0))
                i += 1
    return toks


# Dictionary fields that name a row: used to label a row in the context and the group heading.
ROW_META_KEYS = ("id", "kind", "key", "display_name", "name", "title", "label", "heading")

ASSIGN_OPS = {"=", ":=", "+=", "-=", "*=", "/=", "%=", "|=", "&=", "^="}


def walk(path: str, src: str) -> tuple[list[Literal], str]:
    """Walk the token stream and return every string literal with context, plus the class_name."""
    toks = tokenize(src)
    lits: list[Literal] = []
    stack: list[Frame] = []
    class_name = ""
    func = ""
    top = ""
    stmt: list[Tok] = []          # Tokens of the current statement (outside nested brackets' own lines).
    lhs = ""                       # Assignment target of the current statement.
    stmt_head = ""
    first_on_line = True
    stmt_depth0 = 0
    i = 0
    nt = len(toks)

    def start_statement(t: Tok):
        nonlocal func, top
        # Called on the first token of a statement when the stack is empty.
        if t.kind == "ID" and t.val == "func" and not stack:
            nxt = toks[i + 1] if i + 1 < nt else None
            func = nxt.val if nxt and nxt.kind == "ID" else ""
            top = ""
        elif t.col == 0 and t.kind == "ID" and t.val in ("const", "var", "static", "enum", "signal"):
            func = ""
            j = i + 1
            while j < nt and toks[j].kind == "ID" and toks[j].val in ("var", "const"):
                j += 1
            if t.val == "static" and j < nt and toks[j].kind == "ID" and toks[j].val == "func":
                func = toks[j + 1].val if j + 1 < nt and toks[j + 1].kind == "ID" else ""
                top = ""
            else:
                top = toks[j].val if j < nt and toks[j].kind in ("ID", "STR") else ""
        elif t.col == 0 and t.kind == "ID" and t.val == "class_name":
            pass
        elif t.col == 0 and t.kind == "ID" and t.val == "class":
            func = ""
            top = ""
        elif t.col == 0 and t.kind == "ID" and t.val in ("@export", "@onready"):
            func = ""
        elif t.col == 0 and t.kind == "OP" and t.val == "@":
            func = ""

    while i < nt:
        t = toks[i]
        if t.kind == "NL":
            if not stack:
                stmt = []
                lhs = ""
                stmt_head = ""
            first_on_line = True
            i += 1
            continue
        if not stack and not stmt:
            start_statement(t)
            if t.kind == "ID" and t.val == "class_name" and i + 1 < nt:
                class_name = toks[i + 1].val
            stmt_head = t.val
        first_on_line = False
        top_frame = stack[-1] if stack else None

        if t.kind == "OP" and t.val in "{[(":
            fr = Frame(t.val, parent=top_frame, line=t.line)
            if t.val == "(":
                # Callee = identifier chain just before.
                chain = []
                j = i - 1
                while j >= 0 and (toks[j].kind == "ID" or (toks[j].kind == "OP" and toks[j].val == ".")):
                    chain.append(toks[j].val)
                    j -= 1
                chain.reverse()
                fr.callee_chain = "".join(chain)
                fr.callee = chain[-1] if chain and chain[-1] != "." else ""
            if top_frame is not None:
                if top_frame.kind == "[":
                    fr.elem = top_frame.idx
                elif top_frame.kind == "{":
                    fr.pkey = top_frame.key
                elif top_frame.kind == "(":
                    fr.elem = top_frame.idx
            stack.append(fr)
            stmt.append(t)
            i += 1
            continue
        if t.kind == "OP" and t.val in "}])":
            if stack:
                stack.pop()
            stmt.append(t)
            i += 1
            continue
        if t.kind == "OP" and t.val == "," and top_frame is not None:
            if top_frame.kind == "{":
                top_frame.expect_key = True
                top_frame.key = None
            else:
                top_frame.idx += 1
            stmt.append(t)
            i += 1
            continue
        if t.kind == "OP" and t.val in ASSIGN_OPS and not stack and not lhs:
            lhs = "".join(x.val if x.kind != "STR" else '"' for x in stmt)
            stmt.append(t)
            i += 1
            continue

        # Dictionary key position?
        if top_frame is not None and top_frame.kind == "{" and top_frame.expect_key:
            nxt = toks[i + 1] if i + 1 < nt else None
            # Skip NL between key and colon (rare); assume the same line.
            if nxt is not None and nxt.kind == "OP" and nxt.val in (":", "=") and t.kind in ("STR", "ID", "NUM"):
                top_frame.key = t.val
                top_frame.expect_key = False
                if t.kind == "STR":
                    lits.append(_make(path, t, True, stack, lhs, func, top, nxt, stmt, stmt_head, toks, i))
                stmt.append(t)
                stmt.append(nxt)
                i += 2
                continue
            # An expression key like Vector2i(1, 2): treat the whole key as non-text; keep scanning.
        if t.kind == "STR":
            lits.append(_make(path, t, False, stack, lhs, func, top, None, stmt, stmt_head, toks, i))
            # Row names for post-pass naming.
            if top_frame is not None and top_frame.kind == "{" and top_frame.key in ROW_META_KEYS:
                top_frame.meta.setdefault(top_frame.key, t.val)
        stmt.append(t)
        i += 1
    return lits, class_name


def _make(path, t, is_key, stack, lhs, func, top, nxt, stmt, stmt_head, toks, i) -> Literal:
    """Build the Literal for the string token at index i."""
    elems: list = []
    calls: list = []
    chains: list = []
    rows: list = []
    arg_index = -1
    for fr in stack:
        if fr.kind == "{":
            rows.append(fr)
            if fr.key is not None:
                elems.append(("key", fr.key))
        elif fr.kind == "[":
            elems.append(("idx", fr, fr.idx))
        else:  # '('
            calls.append(fr.callee)
            chains.append(fr.callee_chain)
            elems.append(("arg", fr.idx))
            arg_index = fr.idx
    inner = stack[-1] if stack else None
    field_key = None  # Nearest enclosing dictionary key at this moment (snapshot: frames mutate later).
    for fr in reversed(stack):
        if fr.kind == "{" and fr.key is not None:
            field_key = fr.key
            break
    after = ""
    j = i + 1
    while j < len(toks) and toks[j].kind == "NL":
        j += 1
    if j < len(toks):
        after = toks[j].val
    prev = toks[i - 1].val if i > 0 else ""
    return Literal(
        text=t.val, line=t.line, file=path, is_key=is_key, prefix=t.prefix, path=elems, calls=calls,
        chains=chains, lhs=lhs, func=func, top=top, rows=rows,
        arg_index=arg_index if inner is not None and inner.kind == "(" else -1,
        col=t.col, stmt_head=stmt_head, fkey=field_key, direct=inner is not None and inner.kind == "{", in_array=inner is not None and inner.kind == "[",
        stmt_toks=[(x.kind, x.val) for x in stmt[-12:]], after=after, prev=prev)
