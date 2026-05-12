"""SQLite schema and numpy vector I/O for the recall pipeline. Zero external DBs."""

import json
import os
import sqlite3
from pathlib import Path

import numpy as np

from .config import get_config

SCHEMA = """
CREATE TABLE IF NOT EXISTS documents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT UNIQUE NOT NULL,
    name TEXT,
    description TEXT,
    doc_type TEXT,
    filepath TEXT,
    mtime REAL,
    chunk_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS chunks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    doc_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_idx INTEGER NOT NULL,
    heading TEXT,
    content TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS graph_entities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    doc_id INTEGER REFERENCES documents(id) ON DELETE SET NULL,
    entity_type TEXT,
    metadata_json TEXT
);

CREATE TABLE IF NOT EXISTS graph_edges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id INTEGER NOT NULL REFERENCES graph_entities(id) ON DELETE CASCADE,
    target_id INTEGER NOT NULL REFERENCES graph_entities(id) ON DELETE CASCADE,
    relation TEXT NOT NULL,
    weight REAL DEFAULT 0.5
);

CREATE INDEX IF NOT EXISTS idx_chunks_doc_id ON chunks(doc_id);
CREATE INDEX IF NOT EXISTS idx_entities_doc_id ON graph_entities(doc_id);
CREATE INDEX IF NOT EXISTS idx_edges_source ON graph_edges(source_id);
CREATE INDEX IF NOT EXISTS idx_edges_target ON graph_edges(target_id);
CREATE INDEX IF NOT EXISTS idx_edges_relation ON graph_edges(relation);
"""


def get_db_path() -> str:
    cfg = get_config()
    return os.path.join(cfg["index_path"], "recall.db")


def get_vectors_path() -> str:
    cfg = get_config()
    return os.path.join(cfg["index_path"], "vectors.npy")


def _connect() -> sqlite3.Connection:
    db_path = get_db_path()
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    return conn


def init_db() -> None:
    conn = _connect()
    try:
        conn.executescript(SCHEMA)
        conn.commit()
    finally:
        conn.close()


def clear_index() -> None:
    """Remove all indexed data (drop and recreate tables)."""
    conn = _connect()
    try:
        conn.execute("DROP TABLE IF EXISTS graph_edges")
        conn.execute("DROP TABLE IF EXISTS graph_entities")
        conn.execute("DROP TABLE IF EXISTS chunks")
        conn.execute("DROP TABLE IF EXISTS documents")
        conn.executescript(SCHEMA)
        conn.commit()
    finally:
        conn.close()
    vec_path = get_vectors_path()
    if os.path.exists(vec_path):
        os.remove(vec_path)


def insert_document(filename: str, frontmatter: dict, filepath: str, mtime: float) -> int:
    conn = _connect()
    try:
        conn.execute(
            "INSERT OR REPLACE INTO documents (filename, name, description, doc_type, filepath, mtime) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (
                filename,
                frontmatter.get("name"),
                frontmatter.get("description"),
                frontmatter.get("type"),
                filepath,
                mtime,
            ),
        )
        conn.commit()
        return conn.execute(
            "SELECT id FROM documents WHERE filename = ?", (filename,)
        ).fetchone()[0]
    finally:
        conn.close()


def insert_chunk(doc_id: int, chunk_idx: int, heading: str | None, content: str) -> int:
    conn = _connect()
    try:
        conn.execute(
            "INSERT INTO chunks (doc_id, chunk_idx, heading, content) VALUES (?, ?, ?, ?)",
            (doc_id, chunk_idx, heading, content),
        )
        conn.commit()
        return conn.execute("SELECT last_insert_rowid()").fetchone()[0]
    finally:
        conn.close()


def update_chunk_count(doc_id: int, count: int) -> None:
    conn = _connect()
    try:
        conn.execute("UPDATE documents SET chunk_count = ? WHERE id = ?", (count, doc_id))
        conn.commit()
    finally:
        conn.close()


def load_vectors() -> np.ndarray:
    """Load the chunk embedding matrix (N, 384) from disk."""
    path = get_vectors_path()
    if not os.path.exists(path):
        return np.empty((0, 384), dtype=np.float32)
    return np.load(path)


def save_vectors(vectors: np.ndarray) -> None:
    path = get_vectors_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    np.save(path, vectors)


def get_all_documents() -> list[dict]:
    conn = _connect()
    try:
        rows = conn.execute(
            "SELECT id, filename, name, description, doc_type, filepath, mtime, chunk_count "
            "FROM documents ORDER BY id"
        ).fetchall()
        return [
            {
                "id": r[0],
                "filename": r[1],
                "name": r[2],
                "description": r[3],
                "doc_type": r[4],
                "filepath": r[5],
                "mtime": r[6],
                "chunk_count": r[7],
            }
            for r in rows
        ]
    finally:
        conn.close()


def get_chunks_by_doc(doc_id: int) -> list[dict]:
    conn = _connect()
    try:
        rows = conn.execute(
            "SELECT id, chunk_idx, heading, content FROM chunks WHERE doc_id = ? ORDER BY chunk_idx",
            (doc_id,),
        ).fetchall()
        return [
            {"id": r[0], "chunk_idx": r[1], "heading": r[2], "content": r[3]}
            for r in rows
        ]
    finally:
        conn.close()


def get_all_chunks_with_meta() -> list[dict]:
    """Return all chunks joined with document metadata, ordered by doc_id, chunk_idx."""
    conn = _connect()
    try:
        rows = conn.execute(
            "SELECT c.id, c.doc_id, c.chunk_idx, c.heading, c.content, "
            "d.filename, d.name, d.description, d.doc_type "
            "FROM chunks c JOIN documents d ON c.doc_id = d.id "
            "ORDER BY c.doc_id, c.chunk_idx"
        ).fetchall()
        return [
            {
                "chunk_id": r[0],
                "doc_id": r[1],
                "chunk_idx": r[2],
                "heading": r[3],
                "content": r[4],
                "filename": r[5],
                "name": r[6],
                "description": r[7],
                "doc_type": r[8],
            }
            for r in rows
        ]
    finally:
        conn.close()


def insert_graph_entity(name: str, doc_id: int, entity_type: str, metadata: dict | None = None) -> int:
    conn = _connect()
    try:
        meta_json = json.dumps(metadata) if metadata else None
        conn.execute(
            "INSERT INTO graph_entities (name, doc_id, entity_type, metadata_json) VALUES (?, ?, ?, ?)",
            (name, doc_id, entity_type, meta_json),
        )
        conn.commit()
        return conn.execute("SELECT last_insert_rowid()").fetchone()[0]
    finally:
        conn.close()


def insert_graph_edge(source_id: int, target_id: int, relation: str, weight: float = 0.5) -> None:
    conn = _connect()
    try:
        conn.execute(
            "INSERT OR IGNORE INTO graph_edges (source_id, target_id, relation, weight) "
            "VALUES (?, ?, ?, ?)",
            (source_id, target_id, relation, weight),
        )
        conn.commit()
    finally:
        conn.close()


def get_graph_entities() -> list[dict]:
    conn = _connect()
    try:
        rows = conn.execute(
            "SELECT id, name, doc_id, entity_type, metadata_json FROM graph_entities"
        ).fetchall()
        return [
            {"id": r[0], "name": r[1], "doc_id": r[2], "entity_type": r[3], "metadata_json": r[4]}
            for r in rows
        ]
    finally:
        conn.close()


def get_graph_edges() -> list[dict]:
    conn = _connect()
    try:
        rows = conn.execute(
            "SELECT e.id, e.source_id, src.name, e.target_id, tgt.name, e.relation, e.weight "
            "FROM graph_edges e "
            "JOIN graph_entities src ON e.source_id = src.id "
            "JOIN graph_entities tgt ON e.target_id = tgt.id"
        ).fetchall()
        return [
            {
                "id": r[0],
                "source_id": r[1],
                "source_name": r[2],
                "target_id": r[3],
                "target_name": r[4],
                "relation": r[5],
                "weight": r[6],
            }
            for r in rows
        ]
    finally:
        conn.close()
