"""Config loader for recall pipeline. Reads retrieval settings from gates.json."""

import json
import os
from pathlib import Path

GATES_PATH = os.path.expanduser("~/.claude/gates.json")
DEFAULT_CONFIG = {
    "mode": "manual",
    "top_k": 5,
    "embedding_model": "all-MiniLM-L6-v2",
    "memory_path": "~/.claude-korus/projects/-Users-stm/memory",
    "index_path": "~/projects/stam-os/recall",
}


def _resolve(path: str) -> str:
    return os.path.expanduser(path)


def _load_gates() -> dict:
    path = _resolve(GATES_PATH)
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _save_gates(data: dict) -> None:
    path = _resolve(GATES_PATH)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def get_config() -> dict:
    gates = _load_gates()
    stored = gates.get("retrieval", {})
    cfg = {**DEFAULT_CONFIG, **stored}
    cfg["memory_path"] = _resolve(cfg["memory_path"])
    cfg["index_path"] = _resolve(cfg["index_path"])
    return cfg


def get_mode() -> str:
    return get_config()["mode"]


def set_mode(mode: str) -> None:
    if mode not in ("hybrid", "manual"):
        raise ValueError(f"Invalid mode: {mode}. Must be 'hybrid' or 'manual'.")
    gates = _load_gates()
    gates.setdefault("retrieval", {})
    gates["retrieval"]["mode"] = mode
    _save_gates(gates)


def ensure_gates_config() -> None:
    """Ensure gates.json has a retrieval key (create if missing)."""
    gates = _load_gates()
    if "retrieval" not in gates:
        gates["retrieval"] = {
            "mode": "manual",
            "top_k": 5,
            "embedding_model": "all-MiniLM-L6-v2",
            "memory_path": "~/.claude-korus/projects/-Users-stm/memory",
            "index_path": "~/projects/stam-os/recall",
        }
        _save_gates(gates)
