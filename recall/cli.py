"""CLI entry point for the recall hybrid retrieval pipeline."""

import sys
import time

from .config import ensure_gates_config, get_config, set_mode
from .db import get_all_documents, init_db
from .index import index_all, incremental_index
from .search import hybrid_search, search

SEP = "\033[90m" + "─" * 60 + "\033[0m"


def cmd_rebuild(force: bool = False) -> None:
    print("Rebuilding index...")
    stats = index_all(force_rebuild=force)
    print(f"  Documents: {stats['docs_indexed']}")
    print(f"  Chunks:    {stats['chunks_indexed']}")
    print(f"  Entities:  {stats.get('entities', 0)}")
    print(f"  Edges:     {stats.get('edges', 0)}")
    print(f"  Duration:  {stats['duration_s']}s")
    if stats.get("warning"):
        print(f"  \033[93m{stats['warning']}\033[0m")


def cmd_status() -> None:
    cfg = get_config()
    mode = cfg["mode"]
    docs = get_all_documents()
    total_chunks = sum(d["chunk_count"] for d in docs)
    print(f"Mode:     {mode}")
    print(f"Memory:   {cfg['memory_path']}")
    print(f"Index:    {cfg['index_path']}")
    print(f"Docs:     {len(docs)}")
    print(f"Chunks:   {total_chunks}")
    print(f"Model:    {cfg['embedding_model']}")


def cmd_search(query: str, top_k: int = 5) -> None:
    results = search(query, top_k)
    if not results:
        cfg = get_config()
        if cfg["mode"] != "hybrid":
            print(f"Mode is '{cfg['mode']}'. No hybrid retrieval. Use --mode hybrid to enable.")
        else:
            print("No results. Try --rebuild first?")
        return

    print(f"\n  Query: \033[1m{query}\033[0m\n")
    for i, r in enumerate(results, 1):
        filename = r.get("filename", "?")
        name = r.get("name") or ""
        score = r.get("score", 0)
        snippet = r.get("snippet", "")[:120]
        bd = r.get("breakdown", {})

        parts = [f"\033[1m{i}. {name}\033[0m \033[90m({filename})\033[0m"]
        parts.append(f"   Score: \033[1;36m{score:.4f}\033[0m  |  ",)

        b_parts = []
        for sys_name in ["bm25", "vector", "graph"]:
            if bd and bd.get(sys_name):
                b_parts.append(
                    f"{sys_name}: \033[33m#{bd[sys_name]['rank']}\033[0m ({bd[sys_name]['score']:.3f})"
                )
        parts.append("  ".join(b_parts))

        if snippet:
            parts.append(f"   \033[90m{snippet}\033[0m")

        print("\n".join(parts))
        print()


def cmd_watch() -> None:
    """Monitor queries in a loop (for demo)."""
    print("Recall watch mode — type queries, Ctrl+C to exit.\n")
    try:
        while True:
            q = input("recall> ").strip()
            if q in ("exit", "quit", "q"):
                break
            if q:
                cmd_search(q)
    except (KeyboardInterrupt, EOFError):
        print()


def main():
    ensure_gates_config()
    init_db()

    args = sys.argv[1:]

    if not args:
        print("Usage: recall <query> | --rebuild | --status | --mode hybrid|manual | --watch")
        return

    flag = args[0]

    if flag == "--rebuild":
        force = "--force" in args
        cmd_rebuild(force=force)
    elif flag == "--status":
        cmd_status()
    elif flag == "--mode":
        if len(args) > 1:
            mode = args[1]
            set_mode(mode)
            print(f"Mode set to: {mode}")
        else:
            print(f"Current mode: {get_config()['mode']}")
    elif flag == "--watch":
        cmd_watch()
    else:
        query = " ".join(args)
        cmd_search(query)


if __name__ == "__main__":
    main()
