"""Indexing pipeline: scan memory files, chunk, embed, build BM25 IDF, build graph."""

import math
import os
import re
import time
from collections import Counter
from pathlib import Path

import numpy as np
import yaml

from .config import get_config
from .db import (
    clear_index,
    get_all_documents,
    get_chunks_by_doc,
    init_db,
    insert_chunk,
    insert_document,
    insert_graph_edge,
    insert_graph_entity,
    load_vectors,
    save_vectors,
    update_chunk_count,
)

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
HEADING_RE = re.compile(r"^##\s+(.+)$", re.MULTILINE)

# BM25 constants
BM25_K1 = 1.5
BM25_B = 0.75


def _parse_frontmatter(text: str) -> tuple[dict, str]:
    """Extract YAML frontmatter and body from markdown text."""
    match = FRONTMATTER_RE.match(text)
    if not match:
        return {}, text
    try:
        fm = yaml.safe_load(match.group(1)) or {}
    except yaml.YAMLError:
        fm = {}
    body = text[match.end():]
    return fm, body


def _chunk_document(body: str) -> list[dict]:
    """Split body at ## headings. Each chunk = {heading, content}."""
    parts = HEADING_RE.split(body)
    chunks = []
    # parts[0] = text before first heading
    if parts[0].strip():
        chunks.append({"heading": None, "content": parts[0].strip()})

    # parts[1], parts[2], ... = (heading, content) pairs
    for i in range(1, len(parts), 2):
        heading = parts[i].strip()
        content = parts[i + 1].strip() if i + 1 < len(parts) else ""
        if content:
            chunks.append({"heading": heading, "content": content})
    return chunks


def _build_search_text(fm: dict, heading: str | None, content: str) -> str:
    """Build a searchable text string from frontmatter + heading + content."""
    parts = []
    if fm.get("name"):
        parts.append(fm["name"])
    if fm.get("description"):
        parts.append(fm["description"])
    if heading:
        parts.append(heading)
    parts.append(content or "")
    return " | ".join(p for p in parts if p)


def scan_memory_files(path: str) -> list[dict]:
    """Scan all .md files, parse frontmatter, return document dicts."""
    docs = []
    for fp in sorted(Path(path).glob("*.md")):
        if fp.name == "MEMORY.md":
            continue
        text = fp.read_text(encoding="utf-8")
        fm, body = _parse_frontmatter(text)
        chunks = _chunk_document(body)
        if not chunks:
            chunks = [{"heading": None, "content": body.strip() or fm.get("description") or ""}]
        docs.append({
            "filename": fp.name,
            "filepath": str(fp),
            "frontmatter": fm,
            "body": body,
            "chunks": chunks,
            "mtime": fp.stat().st_mtime,
        })
    return docs


# --- BM25 IDF ---

def _tokenize(text: str) -> list[str]:
    return re.findall(r"[a-z]{2,}", text.lower())


def compute_bm25_idf(corpus: list[str]) -> dict[str, float]:
    """Compute BM25 IDF for a corpus of pre-tokenized strings."""
    N = len(corpus)
    doc_freq: Counter = Counter()
    for doc in corpus:
        unique = set(_tokenize(doc))
        doc_freq.update(unique)
    idf = {}
    for term, n in doc_freq.items():
        # BM25 IDF: log(1 + (N - n + 0.5) / (n + 0.5))
        idf[term] = math.log(1.0 + (N - n + 0.5) / (n + 0.5))
    return idf


# --- Embedding ---

_embedding_model = None


def _get_model():
    global _embedding_model
    if _embedding_model is None:
        from sentence_transformers import SentenceTransformer
        cfg = get_config()
        _embedding_model = SentenceTransformer(cfg["embedding_model"])
    return _embedding_model


def embed_texts(texts: list[str]) -> np.ndarray:
    """Embed a list of texts, returns (N, 384) float32 array."""
    if not texts:
        return np.empty((0, 384), dtype=np.float32)
    model = _get_model()
    embeddings = model.encode(texts, show_progress_bar=False, convert_to_numpy=True)
    return embeddings.astype(np.float32)


# --- Graph Construction ---

def _jaccard_chars(a: str, b: str) -> float:
    """Character trigram Jaccard similarity for quick doc comparison."""
    def _trigrams(s):
        return set(s[i:i+3] for i in range(len(s) - 2))
    ta, tb = _trigrams(a.lower()), _trigrams(b.lower())
    if not ta or not tb:
        return 0.0
    return len(ta & tb) / len(ta | tb)


def build_document_graph(documents: list[dict], doc_id_map: dict[str, int]) -> tuple[int, int]:
    """Build entity-relationship graph from frontmatter metadata. Returns (entities, edges)."""
    entity_map = {}  # (name, doc_id) → entity_id
    n_entities = 0
    n_edges = 0

    # Create document entities
    for doc in documents:
        fm = doc["frontmatter"]
        doc_id = doc_id_map[doc["filename"]]
        name = fm.get("name", doc["filename"].replace(".md", ""))
        eid = insert_graph_entity(name, doc_id, fm.get("type", "unknown"), {
            "filename": doc["filename"],
        })
        entity_map[(name, doc_id)] = eid
        n_entities += 1

    # Create edges between related documents
    doc_names = [(d["filename"], d["frontmatter"].get("name", ""), d["frontmatter"].get("type", ""),
                  d["frontmatter"].get("description", ""))
                 for d in documents]

    for i, (fn_a, name_a, type_a, desc_a) in enumerate(doc_names):
        for j, (fn_b, name_b, type_b, desc_b) in enumerate(doc_names):
            if i >= j:
                continue
            eid_a = entity_map.get((name_a or fn_a.replace(".md", ""), doc_id_map[fn_a]))
            eid_b = entity_map.get((name_b or fn_b.replace(".md", ""), doc_id_map[fn_b]))
            if not eid_a or not eid_b:
                continue

            # Same type
            if type_a and type_b and type_a == type_b:
                insert_graph_edge(eid_a, eid_b, "same_type", 0.3)
                n_edges += 1

            # Shared keyword in name
            tokens_a = set(_tokenize(name_a or fn_a))
            tokens_b = set(_tokenize(name_b or fn_b))
            shared = tokens_a & tokens_b - {"the", "and", "for", "von", "und", "mit"}
            if shared:
                insert_graph_edge(eid_a, eid_b, "shared_keyword", 0.6)
                n_edges += 1

            # Description Jaccard similarity
            if desc_a and desc_b:
                sim = _jaccard_chars(desc_a, desc_b)
                if sim > 0.15:
                    insert_graph_edge(eid_a, eid_b, "content_similar", min(sim, 1.0))
                    n_edges += 1

    return n_entities, n_edges


# --- Main Index Pipeline ---

def index_all(force_rebuild: bool = False) -> dict:
    """Full indexing pipeline. Idempotent (re-indexes all files)."""
    t0 = time.time()
    cfg = get_config()
    memory_path = cfg["memory_path"]

    clear_index()  # Always start fresh to prevent orphan accumulation

    # 1. Scan
    docs = scan_memory_files(memory_path)
    if not docs:
        return {"docs_indexed": 0, "chunks_indexed": 0, "entities": 0, "edges": 0,
                "duration_s": round(time.time() - t0, 2), "warning": "No .md files found"}

    # 2. Index documents and chunks
    all_search_texts = []
    chunk_meta = []
    doc_id_map = {}
    total_chunks = 0

    for doc in docs:
        fm = doc["frontmatter"]
        doc_id = insert_document(doc["filename"], fm, doc["filepath"], doc["mtime"])
        doc_id_map[doc["filename"]] = doc_id

        for idx, ch in enumerate(doc["chunks"]):
            insert_chunk(doc_id, idx, ch["heading"], ch["content"])
            search_text = _build_search_text(fm, ch["heading"], ch["content"])
            all_search_texts.append(search_text)
            chunk_meta.append({
                "doc_id": doc_id,
                "filename": doc["filename"],
                "heading": ch["heading"],
                "chunk_idx": idx,
            })
            total_chunks += 1

        update_chunk_count(doc_id, len(doc["chunks"]))

    # 3. Embed
    vectors = embed_texts(all_search_texts)
    save_vectors(vectors)

    # 4. BM25 IDF (store computed IDF dictionary in memory for search.py)
    bm25_idf = compute_bm25_idf(all_search_texts)
    _save_bm25_meta(all_search_texts, bm25_idf)

    # 5. Build document graph
    n_entities, n_edges = build_document_graph(docs, doc_id_map)

    duration = round(time.time() - t0, 2)
    return {
        "docs_indexed": len(docs),
        "chunks_indexed": total_chunks,
        "entities": n_entities,
        "edges": n_edges,
        "duration_s": duration,
    }


def incremental_index() -> dict:
    """Check file mtimes, re-index only changed files. Cheap for 49 files."""
    cfg = get_config()
    memory_path = cfg["memory_path"]
    docs = scan_memory_files(memory_path)
    existing = {d["filename"]: d["mtime"] for d in get_all_documents()}

    changed = [d for d in docs if d["filename"] not in existing
               or d["mtime"] > existing[d["filename"]] + 1.0]

    if changed:
        return index_all(force_rebuild=True)
    return {"docs_indexed": len(docs), "chunks_indexed": sum(d["chunk_count"] for d in get_all_documents()),
            "changed": False, "message": "No changes detected"}


def _save_bm25_meta(corpus: list[str], idf: dict[str, float]) -> None:
    """Store BM25 corpus metadata alongside vectors for search.py to use."""
    import json
    cfg = get_config()
    meta_path = os.path.join(cfg["index_path"], "bm25_meta.json")
    os.makedirs(os.path.dirname(meta_path), exist_ok=True)
    # Store only what's needed: avgdl, total_docs, idf
    avgdl = sum(len(_tokenize(d)) for d in corpus) / max(len(corpus), 1)
    with open(meta_path, "w") as f:
        json.dump({
            "avgdl": avgdl,
            "total_docs": len(corpus),
            "idf": idf,
        }, f)


def load_bm25_meta() -> dict | None:
    """Load stored BM25 metadata."""
    import json
    cfg = get_config()
    meta_path = os.path.join(cfg["index_path"], "bm25_meta.json")
    if not os.path.exists(meta_path):
        return None
    with open(meta_path) as f:
        return json.load(f)
