# Business Brain (RAG)

A self-testing knowledge base built in n8n: it reads a folder of notes, stores their meaning in Postgres with pgvector, and answers plain-language questions using only those notes, citing the exact source of every claim and saying "not in your vault" instead of guessing.

**▶ Explore the live workflow (zoom, drag, click any node): https://arubia-dev.github.io/business-brain-rag/**

## What it does

```
 Notes folder (vault X)
        │
 [1 · Ingest · nightly]  read → clean → fingerprint → skip unchanged → split by heading
        │                → one file per lap: embed (Gemini) → verify → save → close the run log
        ▼
 Postgres + pgvector   (documents · searchable pieces with 768-number vectors · run log)
        ▲
 [2 · Ask · chat]  embed the question → closest pieces → a rule decides if the evidence is enough
        │          → the model answers only from those notes, citing [1], [2]… → or "not in your vault"
 [3 · Self-test · weekly]  nine checks, including "save the same note twice, still one copy"
 [4 · Health · daily]  did last night's run finish, anything stuck, anything failed
```

## Design rules

- **Rules decide, AI reads.** A similarity threshold, not the model, decides whether to answer.
- **No duplicates.** Upserts on stable keys, proven by the weekly self-test.
- **Errors are handled, not avoided.** Every failure is recorded with its reason and retried on the next run.
- **Lives inside free-tier quotas.** A daily budget and size-scaled pacing keep the embedding API under its limits.
- **Test before trust.** A nine-point self-test and a daily health check, alerting through Telegram and Slack.

## Repository

| Path | What it is |
|---|---|
| `index.html` | the live canvas page (GitHub Pages) |
| `workflow/business-brain-rag.json` | the n8n workflow, credentials and personal values removed (import it into n8n) |
| `database/01_kb_schema.sql` | the Postgres schema (`kb`): documents, pieces with vectors, run log |
| `docs/Case-Study.md` | the story: problem, design, two production problems solved by measuring |
| `docs/SOP.md` | operations manual: routine procedures, deployment options, breakage catalog |
| `docs/Technical-Reference.md` | every node: purpose, settings, SQL, code, connections |

## Quick start

1. Create a Postgres database with the `pgvector` extension and run `database/01_kb_schema.sql`.
2. In n8n, import `workflow/business-brain-rag.json`, then attach your own credentials (Postgres with SSL required, Gemini API key, Telegram, Slack).
3. Set `vaultRoot` in the **Config** node to your notes folder (Docker: mount it read-only and allow it with `N8N_RESTRICT_FILE_ACCESS_TO`).
4. Run the ingest once with `testMode` on, then the self-test. Nine ✅ means it's ready; set `testMode` off.

Full deployment notes (Docker, VPS, n8n Cloud, local) are in `docs/SOP.md`.

## Stack

n8n · Postgres + pgvector (Neon) · Gemini embeddings + Gemini Flash · Telegram · Slack · JavaScript (n8n Code nodes) · SQL

## How I work with AI

I treat AI the way Docker treats software: isolated and controlled. Claude Opus 5.5 was my guide and reviewer, but every fix was first proven in a controlled test run (test mode, one change at a time, checked against the run logs) before it touched the live system. The goal is to hand off dependable work, never half-finished work.

*Built by Angela Rubia, Systems & AI Automation Engineer.*
