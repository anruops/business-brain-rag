# Case Study · A Self-Testing Knowledge Base for My Own Business (RAG) · General Edition

*Portfolio piece · Systems & AI Automation Engineer · Public edition: no machine-specific paths, hosts or IDs. Every number comes from the system's own run logs; nothing is estimated or invented.*

---

## One line

I built a private search engine over my own business notes: it reads about a hundred documents from a notes vault, stores their meaning in Postgres, and answers questions in plain language with the exact source of every claim, while testing and monitoring itself so I never have to wonder whether it still works.

## The problem

Months of building had left my decisions scattered across nearly a hundred notes: pricing, architecture choices, standards, client playbooks, postmortems. Finding why I had decided something meant digging through files, and some older notes still described plans I had since replaced. I wanted to ask my own work a question and get the current answer, with the receipts attached.

## Constraints I designed around

- **Free tier only.** Gemini's free embedding quota allows 1,000 requests a day, counted per piece of text, and the answer model allows 20 answers a day. The vault alone needed about 1,000 pieces.
- **Portable by design.** n8n orchestrates and runs the same way in Docker, on a VPS or on a local machine; the data lives on managed Postgres (Neon) so it never depends on where n8n runs.
- **Honest answers or none.** The system must say "not in your vault" rather than let the model fill gaps.
- **It has to run unattended.** New notes should become searchable overnight, and any failure should reach me on its own.

## What I built

One n8n canvas with four clearly labelled sections, sharing nothing but the database.

```
 Notes folder (vault X)
        │
 [1 · Ingest · nightly]  read → clean HTML/Markdown → fingerprint each note → skip unchanged
        │                → split by heading → one file per lap: embed (Gemini) → verify → save
        │                → close the run log → summary to Telegram, problems to Slack
        ▼
 Neon Postgres + pgvector   (documents · searchable pieces with 768-number vectors · run log)
        ▲
 [2 · Ask · chat]  embed the question → find the closest pieces → a rule decides if the evidence is enough
        │          → Gemini answers only from those notes, citing [1], [2]… → or "not in your vault"
 [3 · Self-test · weekly + on demand]  nine checks, including "save the same note twice, still one copy"
 [4 · Health · daily]  did last night's run finish, anything stuck, anything failed
```

**Ingest** works like a careful librarian. It fingerprints every note and skips anything unchanged, so a quiet night costs nothing. Changed notes are split at their headings, each piece stamped with its title and section so it makes sense on its own, then embedded and verified before anything is saved. Notes deleted from the vault are removed from search.

**Ask** is where the rules matter most. The question is embedded the same way as the notes, Postgres returns the closest pieces with a similarity score, and a fixed threshold decides whether there is enough evidence. Only then does the model write an answer, constrained to those notes, told to cite them, and told to prefer the newest decision when notes disagree.

**Self-test and Health** make the system prove itself: a weekly nine-point check (database, model, vector size, duplicates, search accuracy, data integrity, stuck runs, cleanup, review queue), and a morning heartbeat that also notices when a nightly run never happened.

## Engineering decisions worth calling out

- **Rules decide, AI reads.** The model never decides whether to answer. A similarity threshold does, and below it the question never reaches the model, so it has nothing to hallucinate from. Every answer lists its sources with their scores.
- **Idempotent by design, and proven weekly.** Notes are keyed by path and pieces by (path, piece number); every write is an upsert, and the self-test writes the same probe note twice and fails loudly if two copies exist.
- **A loop with a real close-out.** My first design forked into three branches whose order depended on where nodes sat on the canvas, a hidden rule that was easy to break. I rebuilt it as one straight route: a labelled loop that processes one file per lap, with a single close-out that always runs last.
- **Living inside a hard quota.** A daily budget plans each run to stay under the free-tier cap and defers the remainder to the next night (deferred, not failed), and the pause between files scales with file size to respect the per-minute limit.
- **Failure is a status, not an accident.** Any failed file is marked with the exact reason and retried automatically on the next run; even when the answer model is down, the reply still returns the right notes and says why there is no summary.
- **Verify before writing.** Each batch of vectors is checked (one per piece, correct size) before it touches the database, so nothing half-right is ever stored.

## Two production problems, solved by measuring

**The 49-minute stall.** Test runs embedding several large notes appeared to freeze on the Gemini step. My first fix (a shorter timeout) looked like it worked, until the run records showed those "successful" tests had only processed one file because of a duplicated setting. Reading the execution history showed the real pattern: large requests sent back to back, some of which Google never answered, each waiting out a five-minute timeout. Rebuilding the flow as a one-file-per-lap loop with a pause and a 30-second timeout took five large files from a stalled run to **38 seconds, with each Gemini call answering in one to three seconds.**

**The free-tier wall.** The first full run embedded 15 of 76 changed files and failed 61 with "too many requests." The rate-limit dashboard showed why: the daily cap counts every piece, not every call, and the vault needed about as many pieces as the whole day allows. Because failures were already recorded and retried automatically, nothing was lost; I added the daily budget and size-scaled pacing, and the next run embedded **all 61 remaining files with zero failures.**

## Outcome

- **93 notes, about 1,080 searchable pieces**, kept current automatically every night.
- The acceptance question, "Why did we pick Neon over Supabase?", returns the correct reasoning in my own words, citing the decision runbook (similarity 0.73) and the project pre-flight doc.
- Self-test: **nine of nine checks passing**; it has already caught a real stuck run and correctly reported a brief internet outage instead of failing silently.
- Built end to end in under 72 hours, node by node by hand.

**How I work with AI.** I treat AI the way Docker treats software: isolated and controlled. Claude Opus 5.5 was my guide and reviewer, but every fix was first proven in a controlled test run (test mode, one change at a time, checked against the run logs) before it touched the live system. The goal is to hand off dependable work, never half-finished work.

*Results to add as they accrue (no placeholders faked here): weeks of unattended nightly runs, questions answered, any failure the monitoring caught before I noticed it.*

## What this demonstrates

- Retrieval-augmented generation (RAG) built from first principles: chunking, embeddings, vector search, grounded answering with citations
- PostgreSQL with pgvector: schema design, upserts on stable keys, HNSW vector search, integrity checks in SQL
- Designing within hard API quotas instead of paying past them
- Idempotent, self-healing pipelines with explicit status, retries and a review queue
- Observability: run logs, a self-test suite, a daily health check, multi-channel alerting (Telegram + Slack)
- Diagnosing production issues from execution data rather than guesswork

## Stack

n8n (self-hostable: Docker, VPS or local) · Postgres + pgvector (Neon) · Gemini embeddings + a Gemini Flash answer model · Markdown/Obsidian notes · Telegram + Slack · JavaScript (n8n Code nodes) · SQL
