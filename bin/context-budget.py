#!/usr/bin/env python3
"""context-budget.py <config-dir> [--json]

Measures what a session loads at start (L0 identity + L1 routing + L2
reference loaded by default) versus what stays available on demand (L2/L3
material a session only reads when it needs it). Stdlib only.

Layout expected under <config-dir>:
  CLAUDE.md            L0, plus any @import lines resolved recursively
  primer.md            L1 (loaded at start)
  rules/*.md           L2, loaded at start
  MEMORY.md            L2, loaded at start (counted up to 24576 bytes --
                        that is what the host actually loads). Checked
                        at <config-dir>/MEMORY.md AND at every
                        <config-dir>/projects/<slug>/memory/MEMORY.md
  memory/*.md          L2, available on demand
  knowledge/**         L2, available on demand
  coordination/**      L3, available on demand
"""

import json
import os
import sys

MEMORY_CAP_BYTES = 24576
PRIMER_LINE_CAP = 110
CLAUDE_LINE_CAP = 200
RULE_LINE_CAP = 150


def read_file(path):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    lines = content.count("\n") + (1 if content and not content.endswith("\n") else 0)
    return lines, len(content.encode("utf-8"))


def resolve_import(raw_path, from_dir, config_dir):
    if raw_path.startswith("~/"):
        candidate = os.path.expanduser(raw_path)
        if os.path.isfile(candidate):
            return candidate
        return None
    candidate = os.path.normpath(os.path.join(from_dir, raw_path))
    if os.path.isfile(candidate):
        return candidate
    candidate = os.path.normpath(os.path.join(config_dir, raw_path))
    if os.path.isfile(candidate):
        return candidate
    return None


def find_imports(path):
    imports = []
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                stripped = line.strip()
                if stripped.startswith("@") and len(stripped) > 1:
                    imports.append(stripped[1:])
    except OSError:
        pass
    return imports


def collect_claude_chain(claude_path, config_dir):
    """Returns a list of (path, layer) for CLAUDE.md and every @import,
    resolved recursively. primer.md gets layer L1, everything else L0."""
    entries = []
    visited = set()
    queue = [claude_path]
    while queue:
        current = queue.pop(0)
        real = os.path.realpath(current)
        if real in visited or not os.path.isfile(current):
            continue
        visited.add(real)
        layer = "L1" if os.path.basename(current) == "primer.md" else "L0"
        entries.append((current, layer))
        from_dir = os.path.dirname(current)
        for raw in find_imports(current):
            resolved = resolve_import(raw, from_dir, config_dir)
            if resolved and os.path.realpath(resolved) not in visited:
                queue.append(resolved)
    return entries


def find_memory_indexes(config_dir):
    """MEMORY.md can live at <config>/MEMORY.md, or nested under
    <config>/projects/<slug>/memory/MEMORY.md (how Claude Code lays out a
    per-project memory index). Both count, each capped separately."""
    found = []
    root_candidate = os.path.join(config_dir, "MEMORY.md")
    if os.path.isfile(root_candidate):
        found.append(root_candidate)
    projects_dir = os.path.join(config_dir, "projects")
    if os.path.isdir(projects_dir):
        for dirpath, _dirs, files in os.walk(projects_dir):
            if os.path.basename(dirpath) == "memory" and "MEMORY.md" in files:
                found.append(os.path.join(dirpath, "MEMORY.md"))
    return sorted(found)


def walk_md(root):
    found = []
    if not os.path.isdir(root):
        return found
    for dirpath, _dirs, files in os.walk(root):
        for name in sorted(files):
            if name.endswith(".md"):
                found.append(os.path.join(dirpath, name))
    return sorted(found)


def walk_all(root):
    found = []
    if not os.path.isdir(root):
        return found
    for dirpath, _dirs, files in os.walk(root):
        for name in sorted(files):
            found.append(os.path.join(dirpath, name))
    return sorted(found)


def main():
    args = [a for a in sys.argv[1:] if a != "--json"]
    as_json = "--json" in sys.argv[1:]
    if len(args) != 1:
        print("usage: context-budget.py <config-dir> [--json]", file=sys.stderr)
        return 2
    config_dir = os.path.abspath(args[0])
    if not os.path.isdir(config_dir):
        print(f"not a directory: {config_dir}", file=sys.stderr)
        return 2

    rows = []  # (relpath, lines, bytes, layer, loaded)
    flags = []

    claude_path = os.path.join(config_dir, "CLAUDE.md")
    claude_lines = 0
    if os.path.isfile(claude_path):
        for path, layer in collect_claude_chain(claude_path, config_dir):
            lines, size = read_file(path)
            rel = os.path.relpath(path, config_dir)
            rows.append([rel, lines, size, layer, True])
            if os.path.basename(path) == "CLAUDE.md":
                claude_lines = max(claude_lines, lines)
            if os.path.basename(path) == "primer.md" and lines > PRIMER_LINE_CAP:
                flags.append(f"primer.md > {PRIMER_LINE_CAP} lines ({lines})")

    if claude_lines > CLAUDE_LINE_CAP:
        flags.append(f"CLAUDE.md > {CLAUDE_LINE_CAP} lines ({claude_lines})")

    for path in walk_md(os.path.join(config_dir, "rules")):
        lines, size = read_file(path)
        rel = os.path.relpath(path, config_dir)
        rows.append([rel, lines, size, "L2", True])
        if lines > RULE_LINE_CAP:
            flags.append(f"{rel} > {RULE_LINE_CAP} lines ({lines})")

    for memory_index in find_memory_indexes(config_dir):
        lines, size = read_file(memory_index)
        rel = os.path.relpath(memory_index, config_dir)
        rows.append([rel, lines, size, "L2", True])
        if size > MEMORY_CAP_BYTES:
            flags.append(f"{rel} > {MEMORY_CAP_BYTES} bytes ({size})")

    for path in walk_md(os.path.join(config_dir, "memory")):
        if os.path.basename(path) == "MEMORY.md":
            continue
        lines, size = read_file(path)
        rel = os.path.relpath(path, config_dir)
        rows.append([rel, lines, size, "L2", False])

    for path in walk_all(os.path.join(config_dir, "knowledge")):
        lines, size = read_file(path)
        rel = os.path.relpath(path, config_dir)
        rows.append([rel, lines, size, "L2", False])

    for path in walk_all(os.path.join(config_dir, "coordination")):
        lines, size = read_file(path)
        rel = os.path.relpath(path, config_dir)
        rows.append([rel, lines, size, "L3", False])

    loaded_bytes = 0
    for row in rows:
        rel, lines, size, layer, loaded = row
        if not loaded:
            continue
        if os.path.basename(rel) == "MEMORY.md":
            loaded_bytes += min(size, MEMORY_CAP_BYTES)
        else:
            loaded_bytes += size
    ondemand_bytes = sum(r[2] for r in rows if not r[4])

    if as_json:
        out = {
            "config_dir": config_dir,
            "files": [
                {"file": r[0], "lines": r[1], "bytes": r[2], "layer": r[3], "loaded_at_start": r[4]}
                for r in rows
            ],
            "loaded_at_start_bytes": loaded_bytes,
            "available_on_demand_bytes": ondemand_bytes,
            "flags": flags,
        }
        print(json.dumps(out, indent=2))
    else:
        print(f"{'file':<40} {'lines':>6} {'bytes':>8} {'layer':<5} {'loaded'}")
        for rel, lines, size, layer, loaded in rows:
            print(f"{rel:<40} {lines:>6} {size:>8} {layer:<5} {'start' if loaded else 'on-demand'}")
        print()
        print(f"loaded at start:      {loaded_bytes} bytes")
        print(f"available on demand:  {ondemand_bytes} bytes")
        if flags:
            print()
            print("flags:")
            for f in flags:
                print(f"  - {f}")

    return 1 if flags else 0


if __name__ == "__main__":
    sys.exit(main())
