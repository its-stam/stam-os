"""Hybrid retrieval engine: BM25 + Vector Cosine + Graph Traversal → RRF fusion."""

import math
import re
from typing import Any

import numpy as np

from .config import get_config, get_mode
from .db import get_all_chunks_with_meta, get_graph_edges, get_graph_entities, load_vectors
from .index import _tokenize, embed_texts, load_bm25_meta

BM25_K1 = 1.5
BM25_B = 0.75
RRF_K = 60


# ─── BM25 ─────────────────────────────────────────────

def bm25_search(query: str, top_k: int = 10) -> list[dict]:
    """BM25Okapi over the indexed chunk corpus."""
    meta = load_bm25_meta()
    if not meta:
        return []

    chunks = get_all_chunks_with_meta()
    if not chunks:
        return []

    idf = meta["idf"]
    avgdl = meta["avgdl"]
    total_docs = meta["total_docs"]
    query_tokens = _tokenize(query)

    scores = []
    for i, ch in enumerate(chunks):
        doc_tokens = _tokenize(ch["content"])
        dl = len(doc_tokens)
        if dl == 0:
            continue

        score = 0.0
        for term in query_tokens:
            if term not in idf:
                continue
            tf = doc_tokens.count(term)
            numerator = tf * (BM25_K1 + 1)
            denominator = tf + BM25_K1 * (1 - BM25_B + BM25_B * dl / avgdl)
            score += idf[term] * numerator / denominator

        if score > 0:
            scores.append({
                "chunk_id": ch["chunk_id"],
                "doc_id": ch["doc_id"],
                "filename": ch["filename"],
                "name": ch["name"],
                "description": ch["description"],
                "heading": ch["heading"],
                "snippet": ch["content"][:200],
                "score": round(score, 4),
            })

    scores.sort(key=lambda x: x["score"], reverse=True)
    return _dedup_by_doc(scores[:top_k], "bm25")


# ─── Vector ────────────────────────────────────────────

def vector_search(query: str, top_k: int = 10) -> list[dict]:
    """Cosine similarity search over embedded chunks."""
    vectors = load_vectors()
    chunks = get_all_chunks_with_meta()

    if vectors.shape[0] == 0 or not chunks:
        return []

    # Adjust: chunks may have been indexed while vectors match. Align on count.
    n = min(vectors.shape[0], len(chunks))
    vecs = vectors[:n]
    chs = chunks[:n]

    query_vec = embed_texts([query])
    query_vec = query_vec / (np.linalg.norm(query_vec) + 1e-10)
    vecs_norm = vecs / (np.linalg.norm(vecs, axis=1, keepdims=True) + 1e-10)
    similarities = np.dot(vecs_norm, query_vec.T).flatten()

    top_indices = np.argsort(similarities)[::-1][:top_k]
    results = []
    for idx in top_indices:
        sim = float(similarities[idx])
        if sim < 0.05:
            continue
        ch = chs[idx]
        results.append({
            "chunk_id": ch["chunk_id"],
            "doc_id": ch["doc_id"],
            "filename": ch["filename"],
            "name": ch["name"],
            "description": ch["description"],
            "heading": ch["heading"],
            "snippet": ch["content"][:200],
            "score": round(sim, 4),
        })
    return _dedup_by_doc(results, "vector")


# ─── Graph ─────────────────────────────────────────────

def graph_search(query: str, top_k: int = 10) -> list[dict]:
    """Entity-aware graph traversal. Match query tokens to entity names, score neighbors."""
    entities = get_graph_entities()
    edges = get_graph_edges()

    if not entities:
        return []

    query_tokens = set(_tokenize(query))
    if not query_tokens:
        return []

    # Build adjacency
    adjacency: dict[int, list[tuple[int, str, float]]] = {}
    for e in edges:
        adjacency.setdefault(e["source_id"], []).append((e["target_id"], e["relation"], e["weight"]))
        adjacency.setdefault(e["target_id"], []).append((e["source_id"], e["relation"], e["weight"]))

    # Score entities by token match
    doc_scores: dict[int, dict[str, float]] = {}
    for ent in entities:
        if not ent["doc_id"]:
            continue
        ent_tokens = set(_tokenize(ent["name"]))
        match_ratio = len(query_tokens & ent_tokens) / max(len(query_tokens), 1)
        if match_ratio > 0:
            doc_scores.setdefault(ent["doc_id"], {})
            doc_scores[ent["doc_id"]]["direct"] = max(
                doc_scores[ent["doc_id"]].get("direct", 0), match_ratio * 0.8
            )

    # Propagate to neighbors (depth 1)
    for ent in entities:
        if not ent["doc_id"] or ent["doc_id"] not in doc_scores:
            continue
        base_score = doc_scores[ent["doc_id"]].get("direct", 0)
        for neighbor_id, relation, weight in adjacency.get(ent["id"], []):
            neighbor_ent = next((e for e in entities if e["id"] == neighbor_id), None)
            if not neighbor_ent or not neighbor_ent["doc_id"]:
                continue
            doc_scores.setdefault(neighbor_ent["doc_id"], {})
            doc_scores[neighbor_ent["doc_id"]]["neighbor"] = max(
                doc_scores[neighbor_ent["doc_id"]].get("neighbor", 0),
                base_score * weight * 0.5,
            )

    # Resolve to filenames
    entity_map = {e["id"]: e for e in entities}
    doc_map: dict[int, dict] = {}
    for ent in entities:
        if ent["doc_id"] and ent["doc_id"] in doc_scores:
            doc_map.setdefault(ent["doc_id"], {
                "doc_id": ent["doc_id"],
                "filename": "", "name": ent["name"], "description": "",
                "score": doc_scores[ent["doc_id"]].get("direct", 0)
                       + doc_scores[ent["doc_id"]].get("neighbor", 0),
            })

    results = sorted(doc_map.values(), key=lambda x: x["score"], reverse=True)
    return [{"doc_id": r["doc_id"], "filename": r["filename"], "name": r["name"],
             "description": r["description"], "heading": None, "snippet": "",
             "score": round(r["score"], 4)} for r in results[:top_k]]


# ─── RRF Fusion ────────────────────────────────────────

def rrf_fuse(bm25: list[dict], vector: list[dict], graph: list[dict],
             k: int = RRF_K, top_k: int = 5) -> list[dict]:
    """Reciprocal Rank Fusion: RRF(d) = Σ 1/(k + rank_i(d))."""
    doc_map: dict[str, dict] = {}  # key = doc_id only — graph_search returns empty filenames

    def _key(r):
        return str(r.get("doc_id", ""))

    def _blank():
        return {"bm25": None, "vector": None, "graph": None}

    for name, results in [("bm25", bm25), ("vector", vector), ("graph", graph)]:
        for rank, r in enumerate(results, start=1):
            dkey = _key(r)
            doc_map.setdefault(dkey, {"doc_id": r.get("doc_id"),
                                   "filename": r.get("filename", ""),
                                   "name": r.get("name", ""),
                                   "description": r.get("description", ""),
                                   "heading": r.get("heading"),
                                   "snippet": r.get("snippet", ""),
                                   "breakdown": _blank()})
            doc_map[dkey]["breakdown"][name] = {"rank": rank, "score": r["score"]}

    # Compute RRF
    for doc_key, doc in doc_map.items():
        rrf = 0.0
        for system in ["bm25", "vector", "graph"]:
            bd = doc["breakdown"].get(system)
            if bd:
                rrf += 1.0 / (RRF_K + bd["rank"])
        doc["score"] = round(rrf, 4)

    ranked = sorted(doc_map.values(), key=lambda x: x["score"], reverse=True)
    return ranked[:top_k]


# ─── Main ──────────────────────────────────────────────

def hybrid_search(query: str, top_k: int = 5) -> list[dict]:
    """Run all three retrieval systems and fuse via RRF."""
    bm25 = bm25_search(query, top_k=60)
    vector = vector_search(query, top_k=60)
    graph = graph_search(query, top_k=60)
    return rrf_fuse(bm25, vector, graph, top_k=top_k)


def search(query: str, top_k: int = 5) -> list[dict]:
    """Public entry point. Returns [] if mode is manual."""
    mode = get_mode()
    if mode != "hybrid":
        return []
    return hybrid_search(query, top_k)


def _dedup_by_doc(results: list[dict], source: str) -> list[dict]:
    """Keep highest-scoring result per document."""
    seen = {}
    for r in results:
        key = r["doc_id"]
        if key not in seen or r["score"] > seen[key]["score"]:
            seen[key] = r
    deduped = list(seen.values())
    deduped.sort(key=lambda x: x["score"], reverse=True)
    for r in deduped:
        r["source"] = source
    return deduped
