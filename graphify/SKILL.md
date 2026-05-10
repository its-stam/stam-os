---
name: graphify
description: any input (code, docs, papers, images) → knowledge graph → clustered communities → HTML + JSON + audit report
mode: skill
---
# Graphify — Input → Knowledge Graph

## Trigger
/graphify

## Flow
1. Parse input (code, docs, papers, images)
2. Extract entities, relationships, clusters
3. Generate HTML visualization + JSON data + audit report
4. Save to Obsidian vault (if configured)

## Integration
Graphify output feeds directly into Layer 5a (Obsidian Knowledge Base).
Results persist across sessions via the vault.

## Usage
```
/graphify src/                    # Codebase → graph
/graphify docs/architecture.md   # Doc → graph
/graphify ~/Desktop/screenshot.png  # Image → graph
```
