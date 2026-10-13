# Business Brain (RAG) · Operations SOP & Breakage Runbook (General Edition)

*A deployment-neutral manual for running a self-testing RAG knowledge base built in n8n with Postgres + pgvector and Gemini. No personal paths, IDs or credentials: placeholders in `{BRACES}` stand for your own values. Written from a real build; every breakage entry happened in production.*

---

## Part 1 · What it is

A private search engine over a folder of notes ("vault X"). It reads every Markdown and HTML file, splits each note into searchable pieces, stores their meaning as vectors in Postgres, and answers plain-language questions using only those notes, citing the exact source of every claim and replying "not in your vault" instead of guessing.

**Components**

| Piece | What to use |
|---|---|
| Orchestration | n8n (v1.x or 2.x) · one workflow, four numbered sections |
| Source notes | `{VAULT_ROOT}` (any folder; works well with an Obsidian vault) |
| Database | Postgres 15+ with the `pgvector` extension (Neon, Supabase, RDS, or self-hosted) · schema `kb` |
| Embeddings | Gemini `gemini-embedding-001`, trimmed to 768 dimensions |
| Answers | any Gemini text model (`{ANSWER_MODEL}`), temperature 0.2 |
| Alerts | Telegram `{ALERT_CHAT_ID}` · Slack `{#alerts-errors}` for problems, `{#alerts-updates}` for good news |
| Error handler | an instance-wide n8n Error Workflow `{ERROR_WORKFLOW_ID}` for anything unhandled |

**The four sections**

```
1 · INGEST (manual + nightly)
   Config → Log run start → Read vault files → Prepare files → Get known docs → Plan changes
   → Anything to embed?
        true  → One item per file → Loop Over Items (one file per lap)
                  loop: Reset file → Make embed batches → Embed → Attach + verify → Vectors valid?
                        → Save pieces → Mark file done ─┐
                        (any failure) → Mark file failed ┤
                        Pause (scales with file size) ◄──┘ → back to the loop
                  done ─┐
        false ──────────┴→ Remove deleted files → Close run log → Build run summary → Any failures? → alerts
2 · ASK (n8n chat)
   Chat → Ask config → Embed question → Search vault → Enough evidence? → Answerable?
        true → Write answer → Format reply (answer + numbered sources)   error → Reply: notes only
        false → Reply: not in vault                                     (embed/search error) → Reply: search unavailable
3 · SELF-TEST (weekly + on demand): nine checks, probe written twice, searched, cleaned up, reported
4 · HEALTH (daily): last run finished? anything stuck? anything failed? quiet heartbeat or alert
```

**Data model (schema `kb`)**

| Table | One row per | Key | Holds |
|---|---|---|---|
| `documents` | note | `path` | title, `content_hash`, `status` (pending / embedded / failed / deleted), `last_error`, `chunk_count` |
| `chunks` | piece | `(path, chunk_no)` | heading trail, text, `embedding vector(768)` + HNSW index |
| `ingest_runs` | run | `run_id` | start/finish, test mode, counts, notes |
| `v_status` | status | | files and pieces per status |

---

## Part 2 · Design rules

- **No duplicates:** upserts on stable keys; a self-test proves "saved twice, one copy."
- **AI reads, rules decide:** a similarity threshold decides whether to answer; below it the model never sees the question.
- **Errors handled, not avoided:** retries, a failure path on every section, failed files recorded with the reason and retried next run.
- **Verify before saving:** vector count and size checked per batch.
- **Live within quotas:** daily piece budget + size-scaled pacing.
- **Test before trust:** weekly self-test, daily health check.
- **No human gate:** nothing client-facing, paid, or irreversible happens here. Add one if you extend it to anything that is.

---

## Part 3 · Deployment options

| Where n8n runs | Notes |
|---|---|
| **Docker / Docker Compose** (most common) | Mount the notes folder read-only into the container (e.g. `- {VAULT_ROOT}:/data/vault:ro`) and set `vaultRoot` to `/data/vault`. In n8n 2.x set `N8N_RESTRICT_FILE_ACCESS_TO=/data/vault`. Set `GENERIC_TIMEZONE` to your timezone. |
| **VPS** (Docker or npm) | Same as above; the notes folder must exist on the server (sync it with git, rclone, Syncthing or similar). Always-on, so schedules never miss. |
| **n8n Cloud** | Cannot read local disks. Replace "Read vault files" with a cloud source (Google Drive, S3, GitHub) and keep everything after it unchanged. |
| **Local machine** (npm, PM2, or desktop) | Works fully, but schedules only run while the machine is on and awake. Allow the folder with `N8N_RESTRICT_FILE_ACCESS_TO` (n8n 2.x) and restart n8n so it picks up the variable. |

Database: any Postgres with `pgvector`. Load `01_kb_schema.sql` once; connect with SSL required. A managed host (Neon, Supabase) keeps the data independent of the n8n machine.

---

## Part 4 · Routine SOPs

**SOP-1 · Ask a question.** Open the workflow's chat, ask in plain words, read the answer and its numbered sources. "Not in your vault (closest 0.52)" means rephrase or the note isn't there.

**SOP-2 · Add or change notes.** Edit the folder normally; the nightly run embeds only changed notes (by fingerprint) and removes deleted ones.

**SOP-3 · Run the ingest by hand.** Set `testMode` (false for real runs), run from the manual trigger, wait for the summary.

**SOP-4 · Before a demo or after any change.** Run the self-test; expect nine ✅. Any ❌ means don't demo yet.

**SOP-5 · Read the daily heartbeat.** "Healthy" means nothing to do; otherwise it names the problem (missed nightly, stuck runs, failed files).

**SOP-6 · Review failed files.**
```sql
SELECT path, last_error, updated_at FROM kb.documents WHERE status = 'failed' ORDER BY updated_at DESC;
```

**SOP-7 · Close stuck runs** (never touches a run in progress):
```sql
UPDATE kb.ingest_runs SET finished_at = now(), notes = 'closed manually'
WHERE finished_at IS NULL AND started_at < now() - interval '1 hour';
```

**SOP-8 · Change what gets searched.** Edit `excludePaths` and the file selector (`**/*.{md,html}` by default), then run SOP-3.

**SOP-9 · Change a model.** The answer model can change anytime. Changing the embedding model or size means re-embedding everything and matching the schema's vector size; plan it over several days on a free tier.

**SOP-10 · After an n8n restart.** Refresh any open editor tabs; confirm the file-access variable survived (Docker: it's in the compose file; local: it must be a persistent environment variable).

**SOP-11 · Backups.** Export the workflow JSON (exports contain credential names, never secrets). Keep `N8N_ENCRYPTION_KEY` backed up. The schema file plus the notes folder can always rebuild the database.

---

## Part 5 · Breakage catalog

**Gemini**
- **Embed step runs for minutes or hours.** Several large requests back to back; some never answer and a long timeout waits them out. Fix: one file per lap, pause between laps, timeout 30 s, 2 tries.
- **429 "too many requests."** Free-tier daily cap of 1,000 embeddings, counted per piece. Fix: a daily piece budget (e.g. 800) that defers the rest to the next run; check the provider's rate-limit page.
- **503 "service unavailable" on answers.** Transient overload. The notes-only fallback still returns sources; retry shortly.
- **Free-tier limits at time of writing:** embeddings 100/min · 30K tokens/min · 1,000/day per piece; Flash-class answer models roughly 5–15/min and 20–500/day depending on the model. Check your own dashboard.

**n8n**
- **"Referenced node doesn't exist."** Node names in code are case-sensitive; rename to match.
- **A report says a step returned nothing when it worked.** If a node's Error output is wired straight into the node reading it, `.first()` reads the empty error side; use `.first(0)`.
- **"Query Parameters must be … an array."** Wrap values: `{{ [ $json.value ] }}`.
- **"invalid input syntax for type bigint."** Wrong parameter list pasted into a node; compare against the spec.
- **"Workflow execution cannot start · node has issues."** n8n validates every node first; fix the one with the red marker (e.g. Slack Message Type set to Blocks).
- **A setting is ignored.** Duplicate field names in an Edit Fields node; the later one wins.
- **Only one manual trigger allowed.** Use Schedule triggers for other sections; they can still be run by hand.
- **Schedules at the wrong hour.** Set the workflow timezone (or `GENERIC_TIMEZONE`).
- **IF always goes false.** The condition still references a field from where it was copied (e.g. `allPass` instead of `healthy`), or holds a fixed value instead of an expression.
- **Editor stuck on "Running…".** Machine slept or the connection dropped; stop, refresh, check Executions.

**Files, network, database**
- **"Could not read the vault."** File access not allowed (n8n 2.x), wrong path, or the folder isn't mounted/synced.
- **Every service fails at the same moment.** The host lost internet; rerun when it's back. The daily health check catches nights when alerts couldn't be sent.
- **Slack "channel_not_found" on a real channel.** Private channel; invite the bot.
- **`pg_stat_ssl` shows `ssl = f` on a managed host.** Usually the provider's internal hop; the client connection is encrypted at the provider's front door. Keep SSL set to Require in the credential.

---

## Part 6 · Settings reference

| Setting | Default | Why |
|---|---|---|
| vaultRoot | `{VAULT_ROOT}` | the notes folder |
| excludePaths | `_archive/`, `.obsidian/`, raw exports | skip superseded/noise |
| testMode / testFileLimit | true / 5 | safe testing, no deletions |
| chunkMaxChars / batchMaxChars | 1800 / 20000 | piece size / request size |
| pieceBudget | 800 | stay under a 1,000/day embedding cap |
| embedModel / embedDims | gemini-embedding-001 / 768 | identical in all three config nodes |
| topK / minSimilarity | 6 / 0.6 | how many pieces, how much evidence |
| Embed timeout / retries | 30 s / 2 | fail fast, retry once |
| Pause | max(5, pieces × 0.7) s | ~85 pieces/min under a 100/min cap |
| Answer timeout / retries | 60 s / 3 | answers take longer; ride out 503s |

---

## Part 7 · The recurring lesson

Measure before you fix. Read the execution history, change one thing at a time in test mode, and let the system's own reports (run summary, self-test, health check) point to the cause.
