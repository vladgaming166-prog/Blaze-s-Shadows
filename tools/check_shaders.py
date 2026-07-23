#!/usr/bin/env python3
"""
Lightweight structural checker for the shader pack. It is NOT a GLSL compiler; it:
  * resolves every #include (root-relative to shaders/) and detects missing files,
  * strips comments/strings, then verifies (){}[]  balance on the fully expanded file,
  * confirms each top-level program defines main(),
  * flags a few common mistakes (global vars initialised from uniforms).
Run:  python3 tools/check_shaders.py
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "shaders")
ROOT = os.path.abspath(ROOT)

INCLUDE_RE = re.compile(r'^\s*#include\s+"([^"]+)"', re.M)


def resolve_include(path):
    # Includes are root-relative (start with /), mapped under shaders/.
    p = path.lstrip("/")
    return os.path.join(ROOT, p)


def expand(file_path, seen, stack):
    if file_path in stack:
        return ""  # guard against include cycles (headers also have #ifndef guards)
    if not os.path.exists(file_path):
        raise FileNotFoundError(file_path)
    with open(file_path, "r", encoding="utf-8") as f:
        text = f.read()
    out = []
    for line in text.splitlines(keepends=True):
        m = INCLUDE_RE.match(line)
        if m:
            inc = resolve_include(m.group(1))
            if not os.path.exists(inc):
                raise FileNotFoundError(f"{m.group(1)} (from {file_path})")
            out.append(expand(inc, seen, stack | {file_path}))
        else:
            out.append(line)
    return "".join(out)


def strip_comments(src):
    src = re.sub(r"/\*.*?\*/", " ", src, flags=re.S)
    src = re.sub(r"//[^\n]*", " ", src)
    # crude string strip (shaders barely use strings apart from includes already gone)
    src = re.sub(r'"[^"]*"', " ", src)
    return src


def check_balance(src, name):
    pairs = {")": "(", "]": "[", "}": "{"}
    opens = set("([{")
    stack = []
    for ch in src:
        if ch in opens:
            stack.append(ch)
        elif ch in pairs:
            if not stack or stack[-1] != pairs[ch]:
                return f"unbalanced '{ch}'"
            stack.pop()
    if stack:
        return f"unclosed '{stack[-1]}'"
    return None


def find_programs():
    progs = []
    for dirpath, _, files in os.walk(ROOT):
        for fn in files:
            if fn.endswith((".vsh", ".fsh", ".gsh", ".csh")):
                progs.append(os.path.join(dirpath, fn))
    return sorted(progs)


def main():
    errors = 0
    programs = find_programs()
    print(f"Checking {len(programs)} programs under {ROOT}\n")
    for prog in programs:
        rel = os.path.relpath(prog, ROOT)
        try:
            expanded = expand(prog, set(), set())
        except FileNotFoundError as e:
            print(f"  [MISSING INCLUDE] {rel}: {e}")
            errors += 1
            continue
        code = strip_comments(expanded)

        bal = check_balance(code, rel)
        if bal:
            print(f"  [BRACE]  {rel}: {bal}")
            errors += 1

        if "main" not in code:
            print(f"  [NO MAIN] {rel}")
            errors += 1

        # Global (module-scope) var initialised from a uniform is illegal in GLSL.
        # Heuristic: a top-level line 'type name = ...uniformName...;' outside any block.
        depth = 0
        for line in code.splitlines():
            depth += line.count("{") - line.count("}")
            if depth == 0:
                m = re.match(r"\s*(vec2|vec3|vec4|float|int|mat3|mat4)\s+\w+\s*=", line)
                if m and re.search(r"\b(viewWidth|viewHeight|frameTimeCounter|"
                                   r"cameraPosition)\b", line):
                    print(f"  [GLOBAL-INIT] {rel}: {line.strip()}")
                    errors += 1

    print()
    if errors:
        print(f"FAILED with {errors} issue(s).")
        sys.exit(1)
    print("All structural checks passed.")


if __name__ == "__main__":
    main()
