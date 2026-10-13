# Business Brain (RAG) · Technical Reference (General Edition)

*Node-by-node blueprint of the live workflow, generated from the n8n export by `tools/build_docs.py`. Every setting, query and line of code below is exactly what runs. Sanitized: no credentials, IDs, personal paths or channel names; placeholders in {BRACES}. Generated 2026-10-13.*

---

## How to keep this current

1. After any change in n8n, export the workflow (⋯ → Download) over the JSON in this project folder.
2. Run `py tools/build_docs.py`. It regenerates this reference (both editions), the Word docs, the sanitized `public/workflow.json` and the live canvas page.
3. Add a line to the change log at the end of the SOP, and re-upload the changed docs to Drive.
4. Run the self-test (SOP-4) before calling the change done.

---

## At a glance

- **62 working nodes** in 4 sections · 12 Code nodes · 15 Postgres queries · 4 Gemini calls · 11 alert nodes
- Workflow settings: execution order `v1` · timezone `UTC (set your own)`
- Database: Postgres + pgvector, schema `kb` (full SQL in the appendix)

## Node index

| # | Section | Node | Type |
|---|---|---|---|
| 1.1 | 1 · Ingest | Run ingest (manual) | Manual Trigger |
| 1.2 | 1 · Ingest | Nightly 2:00 | Schedule Trigger |
| 1.3 | 1 · Ingest | Config | Edit Fields (Set) |
| 1.4 | 1 · Ingest | Log run start | Postgres |
| 1.5 | 1 · Ingest | Read vault files | Read/Write Files from Disk |
| 1.6 | 1 · Ingest | Prepare files | Code (JavaScript) |
| 1.7 | 1 · Ingest | Explain read failure | Code (JavaScript) |
| 1.8 | 1 · Ingest | Get known docs | Postgres |
| 1.9 | 1 · Ingest | Slack: read failure | Slack |
| 1.10 | 1 · Ingest | Telegram: read failure | Telegram |
| 1.11 | 1 · Ingest | Plan changes | Code (JavaScript) |
| 1.12 | 1 · Ingest | Anything to embed? | IF |
| 1.13 | 1 · Ingest | One item per file | Split Out |
| 1.14 | 1 · Ingest | Remove deleted files | Postgres |
| 1.15 | 1 · Ingest | Loop Over Items | Loop Over Items |
| 1.16 | 1 · Ingest | Close run log | Postgres |
| 1.17 | 1 · Ingest | Reset file + clear old pieces | Postgres |
| 1.18 | 1 · Ingest | Build run summary | Code (JavaScript) |
| 1.19 | 1 · Ingest | Make embed batches | Code (JavaScript) |
| 1.20 | 1 · Ingest | Any failures? | IF |
| 1.21 | 1 · Ingest | Embed batch (Gemini) | HTTP Request |
| 1.22 | 1 · Ingest | Slack: ingest problem | Slack |
| 1.23 | 1 · Ingest | Telegram: ingest problem | Telegram |
| 1.24 | 1 · Ingest | Telegram: ingest summary | Telegram |
| 1.25 | 1 · Ingest | Attach + verify vectors | Code (JavaScript) |
| 1.26 | 1 · Ingest | Mark file failed | Postgres |
| 1.27 | 1 · Ingest | Vectors valid? | IF |
| 1.28 | 1 · Ingest | Pause | Wait |
| 1.29 | 1 · Ingest | Save pieces | Postgres |
| 1.30 | 1 · Ingest | Mark file done | Postgres |
| 2.1 | 2 · Ask | Ask the vault (chat) | Chat Trigger |
| 2.2 | 2 · Ask | Ask config | Edit Fields (Set) |
| 2.3 | 2 · Ask | Embed question | HTTP Request |
| 2.4 | 2 · Ask | Search vault | Postgres |
| 2.5 | 2 · Ask | Reply: search unavailable | Edit Fields (Set) |
| 2.6 | 2 · Ask | Enough evidence? | Code (JavaScript) |
| 2.7 | 2 · Ask | Answerable? | IF |
| 2.8 | 2 · Ask | Write answer (Gemini) | HTTP Request |
| 2.9 | 2 · Ask | Reply: not in vault | Edit Fields (Set) |
| 2.10 | 2 · Ask | Format reply | Code (JavaScript) |
| 2.11 | 2 · Ask | Reply: notes only | Code (JavaScript) |
| 3.1 | 3 · Self-test | Self-test (Mondays 7:00) | Schedule Trigger |
| 3.2 | 3 · Self-test | Self-test config | Edit Fields (Set) |
| 3.3 | 3 · Self-test | Check database | Postgres |
| 3.4 | 3 · Self-test | Embed probe | HTTP Request |
| 3.5 | 3 · Self-test | Self-test report | Code (JavaScript) |
| 3.6 | 3 · Self-test | Write probe (1st) | Postgres |
| 3.7 | 3 · Self-test | Telegram: self-test | Telegram |
| 3.8 | 3 · Self-test | All passed? | IF |
| 3.9 | 3 · Self-test | Write probe (2nd) | Postgres |
| 3.10 | 3 · Self-test | Clean up probe | Postgres |
| 3.11 | 3 · Self-test | Slack: self-test passed | Slack |
| 3.12 | 3 · Self-test | Slack: self-test FAILED | Slack |
| 3.13 | 3 · Self-test | Search for probe | Postgres |
| 4.1 | 4 · Health check | Every morning 8:00 | Schedule Trigger |
| 4.2 | 4 · Health check | Read health numbers | Postgres |
| 4.3 | 4 · Health check | Judge health | Code (JavaScript) |
| 4.4 | 4 · Health check | Neon unreachable | Code (JavaScript) |
| 4.5 | 4 · Health check | Healthy? | IF |
| 4.6 | 4 · Health check | Slack: health problem | Slack |
| 4.7 | 4 · Health check | Telegram: health problem | Telegram |
| 4.8 | 4 · Health check | Telegram: heartbeat | Telegram |

---

## Section 1 · Ingest

> ## 1 · Ingest Reads the vault every night at 2:00 (or whenever I hit run), skips any note that hasn't changed, and turns new or edited notes into searchable pieces in Neon. Anything that fails gets marked with the reason, so nothing slips by quietly.

### 1.1 · Run ingest (manual)

*Manual Trigger*

**Purpose.** Starts the ingest by hand (the only manual trigger n8n allows per workflow).

**Connects to:** → Config

### 1.2 · Nightly 2:00

*Schedule Trigger*

**Purpose.** Starts the ingest every night so new and edited notes are searchable by morning.

| Setting | Value |
|---|---|
| rule.interval[0].triggerAtHour | 14 |

**Connects to:** → Config

### 1.3 · Config

*Edit Fields (Set)*

**Purpose.** Every ingest setting in one place: where the vault is, what to skip, test mode, piece sizes, the daily Gemini budget, and the embedding model.

| Setting | Value |
|---|---|
| assignments.assignments › vaultRoot | /data/vault  (string) |
| assignments.assignments › testMode | False  (boolean) |
| assignments.assignments › testFileLimit | 5  (number) |
| assignments.assignments › embedModel | gemini-embedding-001  (string) |
| assignments.assignments › embedDims | 768  (number) |
| assignments.assignments › excludePaths | ["_archive/", "raw-exports/", ".obsidian/", ".claude/"]  (array) |
| assignments.assignments › chunkMaxChars | 1800  (number) |
| assignments.assignments › batchMaxChars | 20000  (number) |
| assignments.assignments › pieceBudget | 800  (number) |

**Connects to:** → Log run start

### 1.4 · Log run start

*Postgres*

**Purpose.** Opens a row in kb.ingest_runs before any work happens, so a crashed run still leaves a trace (the health check looks for runs that never closed).

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $json.testMode ] }}` |

**SQL**

```sql
INSERT INTO kb.ingest_runs (test_mode, notes)
VALUES ($1, 'started')
RETURNING run_id;
```

**Connects to:** → Read vault files

### 1.5 · Read vault files

*Read/Write Files from Disk · On error: error output · Always output data*

**Purpose.** Reads every .md and .html file in the vault, including the business folder through the junction.

| Setting | Value |
|---|---|
| fileSelector | `={{ $('Config').first().json.vaultRoot }}/**/*.{md,html}` |

**Connects to:** Success → Prepare files · Error → Explain read failure

### 1.6 · Prepare files

*Code (JavaScript)*

**Purpose.** Builds each note's address relative to the vault (its permanent ID), applies the skip list, and reads each file as text. Unreadable files are counted, never hidden.

**Code**

```javascript
// Prepare files: turn the raw file reads into one clean list.
// Excluded folders are dropped here; unreadable files are counted, not hidden.
const cfg = $('Config').first().json;
const root = String(cfg.vaultRoot).replace(/\\/g, '/').replace(/\/+$/, '');
const excludes = (cfg.excludePaths || []).map(p => String(p).replace(/\\/g, '/').toLowerCase());

const items = $input.all();
const files = [];
const skipped = [];
let readErrors = 0;
let readCount = 0;

for (let i = 0; i < items.length; i++) {
  const bin = items[i].binary && items[i].binary.data;
  if (!bin) continue;
  readCount++;

  const dir = String(bin.directory || '').replace(/\\/g, '/').replace(/\/+$/, '');
  const full = dir ? dir + '/' + bin.fileName : bin.fileName;
  let rel = full;
  if (full.toLowerCase().startsWith(root.toLowerCase() + '/')) rel = full.slice(root.length + 1);

  const relLower = rel.toLowerCase();
  if (excludes.some(x => relLower.startsWith(x) || relLower.includes('/' + x))) {
    skipped.push(rel);
    continue;
  }

  let raw;
  try {
    raw = (await this.helpers.getBinaryDataBuffer(i, 'data')).toString('utf8');
  } catch (e) {
    readErrors++;
    skipped.push(rel + ' (unreadable: ' + e.message + ')');
    continue;
  }

  files.push({
    path: rel,
    ext: String(bin.fileExtension || rel.split('.').pop()).toLowerCase(),
    raw,
    hasDirectory: !!dir,
  });
}

return [{ json: { files, skipped, readErrors, readCount } }];
```

**Connects to:** → Get known docs

### 1.7 · Explain read failure

*Code (JavaScript)*

**Purpose.** If the vault cannot be read at all, turns the error into a message that says what to check.

**Code**

```javascript
// The vault couldn't be read at all: say exactly why and what to check.
const e = $input.first().json.error;
const err = e ? (e.message || JSON.stringify(e)) : 'unknown error';
const text = `Business Brain ingest could NOT read the vault.\nError: ${err}\nCheck: (1) vaultRoot in Config is right, (2) n8n is allowed to read it (N8N_RESTRICT_FILE_ACCESS_TO), (3) the business-docs junction still exists.`;
return [{ json: { failed: 1, telegram_text: text, slack_text: ':x: ' + text } }];
```

**Connects to:** → Slack: read failure · → Telegram: read failure

### 1.8 · Get known docs

*Postgres · Always output data · Execute once*

**Purpose.** Asks Neon what it already has (path, fingerprint, status) so unchanged notes can be skipped.

| Setting | Value |
|---|---|
| operation | executeQuery |

**SQL**

```sql
SELECT path, content_hash, status FROM kb.documents;
```

**Connects to:** → Plan changes

### 1.9 · Slack: read failure

*Slack*

**Purpose.** Posts a vault-read failure to the error channel.

| Setting | Value |
|---|---|
| select | channel |
| channelId | #alerts-errors |
| text | `={{ $json.slack_text }}` |

### 1.10 · Telegram: read failure

*Telegram · On error: continue*

**Purpose.** Sends a vault-read failure to Telegram.

| Setting | Value |
|---|---|
| chatId | {TELEGRAM_CHAT_ID} |
| text | `={{ $json.telegram_text }}` |
| additionalFields.appendAttribution | False |

### 1.11 · Plan changes

*Code (JavaScript)*

**Purpose.** The brain of the ingest, pure rules: cleans HTML/Markdown, fingerprints each note, decides new/changed/unchanged/deleted, splits notes into heading-based pieces, applies test mode and the daily piece budget.

**Code**

```javascript
// Plan changes: the brain of the ingest lane. Pure rules, no AI.
// Decides which files are new/changed (embed), gone (remove) or unchanged (skip),
// cleans HTML/Markdown into text, and splits each file into heading-based chunks.
const cfg = $('Config').first().json;
const runId = $('Log run start').first().json.run_id;
const prep = $('Prepare files').first().json;
const known = $('Get known docs').all().map(i => i.json).filter(r => r && r.path);

const MAX = Number(cfg.chunkMaxChars) || 1800;
const MIN_BODY = 40;

// ---- helpers ---------------------------------------------------------------
function hash(str) { // cyrb53: fast, stable change-detector (not for security)
  let h1 = 0xdeadbeef, h2 = 0x41c6ce57;
  for (let i = 0; i < str.length; i++) {
    const ch = str.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909);
  return (4294967296 * (2097151 & h2) + (h1 >>> 0)).toString(16) + '-' + str.length;
}

const ENTITIES = { nbsp: ' ', amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", rarr: '→', larr: '←',
  mdash: '—', ndash: '–', middot: '·', hellip: '…', rsquo: '’', lsquo: '‘', rdquo: '”', ldquo: '“',
  bull: '•', times: '×', check: '✓', copy: '©' };
function decode(s) {
  return s.replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
          .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCodePoint(parseInt(n, 16)))
          .replace(/&([a-z]+);/gi, (m, n) => ENTITIES[n.toLowerCase()] ?? m);
}

function htmlToText(html) {
  const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  let s = html
    .replace(/<(script|style|head|svg|noscript)[\s\S]*?<\/\1>/gi, ' ')
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/<h([1-4])[^>]*>/gi, (_, n) => '\n\n' + '#'.repeat(Number(n)) + ' ')
    .replace(/<\/h[1-4]>/gi, '\n\n')
    .replace(/<(br|hr)\s*\/?>/gi, '\n')
    .replace(/<\/(p|div|li|tr|section|article|table|ul|ol|blockquote|pre)>/gi, '\n')
    .replace(/<(td|th)[^>]*>/gi, ' | ')
    .replace(/<li[^>]*>/gi, '\n- ')
    .replace(/<[^>]+>/g, ' ');
  s = decode(s);
  return { text: tidy(s), title: titleMatch ? decode(titleMatch[1]).trim() : '' };
}

function tidy(s) {
  return s.replace(/\r/g, '')
          .split('\n').map(l => l.replace(/[ \t]+/g, ' ').trim()).join('\n')
          .replace(/\n{3,}/g, '\n\n').trim();
}

function mdTitle(text) {
  const m = text.match(/^#\s+(.+)$/m);
  return m ? m[1].replace(/[*_`]/g, '').trim() : '';
}

// Split a long section by paragraphs, then hard-split any giant paragraph.
function splitBody(body) {
  const out = [];
  let cur = '';
  for (const para of body.split(/\n{2,}/)) {
    const pieces = para.length > MAX ? para.match(new RegExp('[\\s\\S]{1,' + MAX + '}(?=\\s|$)|[\\s\\S]{1,' + MAX + '}', 'g')) : [para];
    for (const p of pieces) {
      if ((cur + '\n\n' + p).length > MAX && cur) { out.push(cur); cur = p; }
      else cur = cur ? cur + '\n\n' + p : p;
    }
  }
  if (cur) out.push(cur);
  return out;
}

function chunkFile(title, text) {
  const lines = text.split('\n');
  const sections = [];
  const trail = [];
  let buf = [];
  const flush = () => {
    const body = buf.join('\n').trim();
    // Drop a top heading that just repeats the file title.
    const parts = trail.filter(Boolean).filter((t, idx) => !(idx === 0 && t === title));
    if (body) sections.push({ heading: parts.join(' › '), body });
    buf = [];
  };
  for (const line of lines) {
    const h = line.match(/^(#{1,4})\s+(.*)$/);
    if (h) {
      flush();
      const level = h[1].length;
      trail.length = level - 1;
      trail[level - 1] = h[2].replace(/[*_`]/g, '').trim();
    } else buf.push(line);
  }
  flush();

  const chunks = [];
  for (const sec of sections) {
    for (const piece of splitBody(sec.body)) {
      if (piece.replace(/\s/g, '').length < MIN_BODY) continue;
      const header = sec.heading ? title + ' › ' + sec.heading : title;
      chunks.push({ chunk_no: chunks.length, heading: sec.heading || null, text: header + '\n\n' + piece });
    }
  }
  return chunks;
}

// ---- plan ------------------------------------------------------------------
const knownByPath = new Map(known.map(r => [r.path, r]));
const onDisk = new Set();
const toEmbedAll = [];
const notes = [];
let unchanged = 0, empty = 0, collisions = 0;

for (const f of prep.files) {
  if (onDisk.has(f.path)) { collisions++; notes.push('path collision: ' + f.path); continue; }
  onDisk.add(f.path);

  let text, title;
  if (f.ext === 'html' || f.ext === 'htm') {
    const h = htmlToText(f.raw);
    text = h.text; title = h.title || mdTitle(text);
  } else {
    text = tidy(f.raw.replace(/\r/g, '').replace(/^---\n[\s\S]*?\n---\n/, '')); // drop YAML frontmatter
    title = mdTitle(text);
  }
  title = title || f.path.split('/').pop().replace(/\.[^.]+$/, '');

  if (text.replace(/\s/g, '').length < MIN_BODY) { empty++; continue; }

  const content_hash = hash(text);
  const prev = knownByPath.get(f.path);
  if (prev && prev.content_hash === content_hash && prev.status === 'embedded') { unchanged++; continue; }

  const chunks = chunkFile(title, text);
  if (!chunks.length) { empty++; continue; }
  toEmbedAll.push({ path: f.path, title, content_hash, isNew: !prev, chunks });
}

const toDelete = known.filter(r => r.status !== 'deleted' && !onDisk.has(r.path)).map(r => r.path);
const testMode = cfg.testMode === true || cfg.testMode === 'true';
// Stay inside Gemini's free daily cap: take files until the piece budget is used,
// defer the rest to the next run (deferred, not failed).
const budget = Number(cfg.pieceBudget) || 800;
const candidates = testMode ? toEmbedAll.slice(0, Number(cfg.testFileLimit) || 5) : toEmbedAll;
const toEmbedFiles = [];
let used = 0, deferred = 0;
for (const f of candidates) {
  if (used + f.chunks.length > budget) { deferred++; continue; }
  toEmbedFiles.push(f);
  used += f.chunks.length;
}
if (deferred) notes.push(`${deferred} file(s) deferred to next run (daily Gemini budget: ${budget} pieces)`);

if (testMode) notes.push(`TEST MODE: embedding ${toEmbedFiles.length} of ${toEmbedAll.length} changed files; deletions skipped`);
if (prep.readErrors) notes.push(`${prep.readErrors} file(s) unreadable`);
if (prep.files.some(f => !f.hasDirectory)) notes.push('WARNING: file reader returned no folder info, paths are filenames only');
if (prep.readCount === 0) notes.push('WARNING: no files were read. Check vaultRoot and N8N_RESTRICT_FILE_ACCESS_TO');

return [{ json: {
  run_id: runId,
  testMode,
  filesSeen: prep.files.length,
  excluded: prep.skipped.length,
  unchanged, empty, collisions,
  changedTotal: toEmbedAll.length,
  toEmbedFiles,
  toDelete: testMode ? [] : toDelete,
  chunksPlanned: toEmbedFiles.reduce((n, f) => n + f.chunks.length, 0),
  notes: notes.join(' | ') || 'ok',
} }];
```

**Connects to:** → Anything to embed?

### 1.12 · Anything to embed?

*IF*

**Purpose.** Routes "nothing changed tonight" straight to the close-out.

| Setting | Value |
|---|---|
| conditions.options.caseSensitive | True |
| conditions.options.typeValidation | strict |
| conditions.options.version | 3 |
| conditions.conditions | `={{ $json.toEmbedFiles.length }}  number gt  0` |
| conditions.combinator | and |

**Connects to:** true → One item per file · false → Remove deleted files

### 1.13 · One item per file

*Split Out*

**Purpose.** Turns the plan's list of files into one item per file.

| Setting | Value |
|---|---|
| fieldToSplitOut | toEmbedFiles |

**Connects to:** → Loop Over Items

### 1.14 · Remove deleted files

*Postgres · Always output data · Execute once*

**Purpose.** Removes notes that no longer exist in the vault from search (skipped in test mode).

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ JSON.stringify($('Plan changes').first().json.toDelete) ] }}` |

**SQL**

```sql
WITH gone AS (SELECT jsonb_array_elements_text($1::jsonb) AS path),
cleared AS (DELETE FROM kb.chunks WHERE path IN (SELECT path FROM gone) RETURNING 1)
UPDATE kb.documents SET status = 'deleted', chunk_count = 0
WHERE path IN (SELECT path FROM gone)
RETURNING path;
```

**Connects to:** → Close run log

### 1.15 · Loop Over Items

*Loop Over Items*

**Purpose.** Processes one file per lap; its done output fires once after the last file, which is what makes the close-out run last.

**Connects to:** done → Remove deleted files · loop → Reset file + clear old pieces

### 1.16 · Close run log

*Postgres · Execute once*

**Purpose.** Closes the run row with counts and notes, and counts the files that failed during this run.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $('Plan changes').first().json.run_id, $('Plan changes').first().json.filesSeen, $('Plan changes').first().json.toEmbedFiles.length, $('Plan changes').first().json.notes ] }}` |

**SQL**

```sql
UPDATE kb.ingest_runs r
SET finished_at = now(), files_seen = $2, files_changed = $3, notes = $4,
    files_failed = (SELECT count(*) FROM kb.documents d WHERE d.status = 'failed' AND d.updated_at >= r.started_at)
WHERE r.run_id = $1
RETURNING r.run_id, r.files_failed,
  (SELECT string_agg(d.path || ': ' || coalesce(d.last_error, '?'), E'\n') FROM kb.documents d WHERE d.status = 'failed') AS failed_list;
```

**Connects to:** → Build run summary

### 1.17 · Reset file + clear old pieces

*Postgres*

**Purpose.** Upserts the note as pending and clears its old pieces in one atomic statement, so an edited note never leaves stale pieces behind.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $json.path, $json.title, $json.content_hash ] }}` |

**SQL**

```sql
WITH up AS (
  INSERT INTO kb.documents (path, title, content_hash, status, last_error, chunk_count)
  VALUES ($1, $2, $3, 'pending', NULL, 0)
  ON CONFLICT (path) DO UPDATE
    SET title = EXCLUDED.title, content_hash = EXCLUDED.content_hash,
        status = 'pending', last_error = NULL, chunk_count = 0
  RETURNING path
), cleared AS (
  DELETE FROM kb.chunks WHERE path IN (SELECT path FROM up) RETURNING 1
)
SELECT (SELECT path FROM up) AS path, (SELECT count(*) FROM cleared) AS old_pieces_cleared;
```

**Connects to:** → Make embed batches

### 1.18 · Build run summary

*Code (JavaScript)*

**Purpose.** Turns the numbers into a short report for Telegram and Slack (first 10 failures plus a count).

**Code**

```javascript
// Build run summary: one readable report for Telegram/Slack.
const r = $input.first().json;
const p = $('Plan changes').first().json;
const failed = Number(r.files_failed) || 0;
const lines = [
  `Business Brain ingest ${p.testMode ? '(TEST MODE) ' : ''}finished, run #${p.run_id}`,
  `Files seen: ${p.filesSeen} · changed: ${p.changedTotal} · embedded this run: ${p.toEmbedFiles.length} · unchanged: ${p.unchanged}`,
  `Chunks: ${p.chunksPlanned} · removed files: ${p.toDelete.length} · excluded: ${p.excluded} · failed: ${failed}`,
  `Notes: ${p.notes}`,
];
if (failed && r.failed_list) {
  const list = r.failed_list.split('\n');
  lines.push('Failed files:\n' + list.slice(0, 10).join('\n') +
    (list.length > 10 ? `\n…and ${list.length - 10} more (they retry automatically next run)` : ''));
}
const text = lines.join('\n');
return [{ json: { failed, telegram_text: text, slack_text: (failed ? ':warning: ' : ':white_check_mark: ') + text } }];
```

**Connects to:** → Any failures?

### 1.19 · Make embed batches

*Code (JavaScript)*

**Purpose.** Packs the current file's pieces into Gemini-sized requests (max 100 pieces, about batchMaxChars characters).

**Code**

```javascript
// Make embed batches: group each file's chunks into requests Gemini accepts
// (max 100 pieces and ~batchMaxChars per request), so free-tier limits hold.
const cfg = $('Config').first().json;
const MAXC = Number(cfg.batchMaxChars) || 20000;
const out = [];
$input.all().forEach((item, i) => {
  const file = $('Loop Over Items').first().json;
  let batch = [], size = 0, n = 0;
  const push = () => {
    if (!batch.length) return;
    out.push({ json: { path: file.path, title: file.title, batch_no: n++, chunks: batch }, pairedItem: { item: i } });
    batch = []; size = 0;
  };
  for (const c of file.chunks) {
    if (batch.length && (size + c.text.length > MAXC || batch.length >= 100)) push();
    batch.push(c); size += c.text.length;
  }
  push();
});
return out;
```

**Connects to:** → Embed batch (Gemini)

### 1.20 · Any failures?

*IF*

**Purpose.** Problems go loud (Slack + Telegram); clean runs get one quiet Telegram summary.

| Setting | Value |
|---|---|
| conditions.options.caseSensitive | True |
| conditions.options.typeValidation | strict |
| conditions.options.version | 3 |
| conditions.conditions | `={{ $json.failed }}  number gt  0` |
| conditions.combinator | and |

**Connects to:** true → Slack: ingest problem · true → Telegram: ingest problem · false → Telegram: ingest summary

### 1.21 · Embed batch (Gemini)

*HTTP Request · On error: error output · Retry: 2 tries, 5000 ms*

**Purpose.** Turns each piece into 768 numbers (its meaning) with gemini-embedding-001, task type RETRIEVAL_DOCUMENT.

| Setting | Value |
|---|---|
| method | POST |
| url | `=https://generativelanguage.googleapis.com/v1beta/models/{{ $('Config').first().json.embedModel }}:batchEmbedContents` |
| authentication | predefinedCredentialType |
| nodeCredentialType | googlePalmApi |
| sendBody | True |
| specifyBody | json |
| options.batching.batch.batchSize | 1 |
| options.batching.batch.batchInterval | 10000 |
| options.timeout | 30000 |

**Request body**

```javascript
{{ JSON.stringify({ requests: $json.chunks.map(c => ({ model: 'models/' + $('Config').first().json.embedModel, content: { parts: [{ text: c.text }] }, taskType: 'RETRIEVAL_DOCUMENT', title: $json.title, outputDimensionality: $('Config').first().json.embedDims })) }) }}
```

**Connects to:** Success → Attach + verify vectors · Error → Mark file failed

### 1.22 · Slack: ingest problem

*Slack*

**Purpose.** Posts ingest problems to the error channel.

| Setting | Value |
|---|---|
| select | channel |
| channelId | #alerts-errors |
| text | `={{ $json.slack_text }}` |

### 1.23 · Telegram: ingest problem

*Telegram · On error: continue*

**Purpose.** Sends ingest problems to Telegram.

| Setting | Value |
|---|---|
| chatId | {TELEGRAM_CHAT_ID} |
| text | `={{ $json.telegram_text }}` |
| additionalFields.appendAttribution | False |

### 1.24 · Telegram: ingest summary

*Telegram · On error: continue*

**Purpose.** Quiet summary of a clean run.

| Setting | Value |
|---|---|
| chatId | {TELEGRAM_CHAT_ID} |
| text | `={{ $json.telegram_text }}` |
| additionalFields.appendAttribution | False |

### 1.25 · Attach + verify vectors

*Code (JavaScript)*

**Purpose.** Pairs each vector with its piece and verifies count and size before anything is saved.

**Code**

```javascript
// Attach + verify vectors: pair each vector with its chunk and VERIFY before saving.
// Wrong count or wrong size = the file is marked failed, never half-saved.
const dims = Number($('Config').first().json.embedDims);
return $input.all().map((item, i) => {
  const b = $('Make embed batches').itemMatching(i).json;
  const emb = item.json.embeddings || [];
  let problem = null;
  if (emb.length !== b.chunks.length) problem = `expected ${b.chunks.length} vectors, got ${emb.length}`;
  else if (emb.some(e => !e.values || e.values.length !== dims)) problem = `a vector is not ${dims} numbers long`;
  return {
    json: {
      path: b.path,
      batch_no: b.batch_no,
      valid: !problem,
      problem,
      rows: problem ? [] : b.chunks.map((c, k) => ({
        chunk_no: c.chunk_no, heading: c.heading, content: c.text, embedding: JSON.stringify(emb[k].values),
      })),
    },
    pairedItem: { item: i },
  };
});
```

**Connects to:** → Vectors valid?

### 1.26 · Mark file failed

*Postgres*

**Purpose.** The review queue: marks the note failed with the exact reason; the next run retries it automatically.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $json.path \|\| $('Make embed batches').item.json.path, String($json.problem \|\| ($json.error && ($json.error.message \|\| JSON.stringify($json.error))) \|\| 'unknown error') ] }}` |

**SQL**

```sql
UPDATE kb.documents SET status = 'failed', last_error = left($2, 500)
WHERE path = $1
RETURNING path, last_error;
```

**Connects to:** → Pause

### 1.27 · Vectors valid?

*IF*

**Purpose.** Sends verified batches to be saved and invalid ones to the failure path.

| Setting | Value |
|---|---|
| conditions.options.caseSensitive | True |
| conditions.options.typeValidation | strict |
| conditions.options.version | 3 |
| conditions.conditions | `={{ $json.valid }}  boolean true` |
| conditions.combinator | and |

**Connects to:** true → Save pieces · false → Mark file failed

### 1.28 · Pause

*Wait*

**Purpose.** Waits between files, scaled to the file's size, to stay under Gemini's per-minute limit.

| Setting | Value |
|---|---|
| amount | `={{ Math.max(5, Math.ceil($('Loop Over Items').first().json.chunks.length * 0.7)) }}` |

**Connects to:** → Loop Over Items

### 1.29 · Save pieces

*Postgres · On error: error output*

**Purpose.** Upserts every piece of the batch in one round trip, keyed on (path, chunk_no), so a re-save can never duplicate.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $json.path, JSON.stringify($json.rows) ] }}` |

**SQL**

```sql
WITH ins AS (
  INSERT INTO kb.chunks (path, chunk_no, heading, content, embedding)
  SELECT $1::text, (c->>'chunk_no')::int, c->>'heading', c->>'content', (c->>'embedding')::vector
  FROM jsonb_array_elements($2::jsonb) AS c
  ON CONFLICT (path, chunk_no) DO UPDATE
    SET heading = EXCLUDED.heading, content = EXCLUDED.content,
        embedding = EXCLUDED.embedding, created_at = now()
  RETURNING 1
)
SELECT $1::text AS path, count(*) AS saved FROM ins;
```

**Connects to:** Success → Mark file done · Error → Mark file failed

### 1.30 · Mark file done

*Postgres*

**Purpose.** Marks the note embedded, counting the pieces actually stored rather than trusting what was expected.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $json.path ] }}` |

**SQL**

```sql
UPDATE kb.documents d
SET status = 'embedded',
    chunk_count = (SELECT count(*) FROM kb.chunks c WHERE c.path = d.path),
    embedded_at = now()
WHERE d.path = $1 AND d.status <> 'failed'
RETURNING d.path, d.chunk_count;
```

**Connects to:** → Pause

---

## Section 2 · Ask

> Ask a question in plain words. It finds the closest notes; if the evidence is too weak it says so instead of guessing; otherwise Gemini answers ONLY from those notes and lists its sources.

### 2.1 · Ask the vault (chat)

*Chat Trigger*

**Purpose.** The chat box inside n8n; whatever the last node outputs as `output` becomes the reply.

| Setting | Value |
|---|---|
| options.responseMode | lastNode |

**Connects to:** → Ask config

### 2.2 · Ask config

*Edit Fields (Set)*

**Purpose.** Ask settings: the question, models, how many pieces to fetch, the evidence bar, and the answer rules.

| Setting | Value |
|---|---|
| assignments.assignments › question | `={{ $json.chatInput }}  (string)` |
| assignments.assignments › embedModel | gemini-embedding-001  (string) |
| assignments.assignments › embedDims | 768  (number) |
| assignments.assignments › answerModel | gemini-3.8-flash  (string) |
| assignments.assignments › topK | 6  (number) |
| assignments.assignments › minSimilarity | 0.6  (number) |
| assignments.assignments › answerRules | You answer questions about the owner's business using ONLY the numbered notes provided. Rules: (1) If the notes do not contain the answer, say so plainly. Never guess and never use outside knowledge. (2) Cite the note numbe… |

**Connects to:** → Embed question

### 2.3 · Embed question

*HTTP Request · On error: error output · Retry: 2 tries, 1000 ms*

**Purpose.** Turns the question into 768 numbers the same way the notes were embedded (task type RETRIEVAL_QUERY).

| Setting | Value |
|---|---|
| method | POST |
| url | `=https://generativelanguage.googleapis.com/v1beta/models/{{ $json.embedModel }}:embedContent` |
| authentication | predefinedCredentialType |
| nodeCredentialType | googlePalmApi |
| sendBody | True |
| specifyBody | json |
| options.timeout | 30000 |

**Request body**

```javascript
{{ JSON.stringify({ model: 'models/' + $json.embedModel, content: { parts: [{ text: $json.question }] }, taskType: 'RETRIEVAL_QUERY', outputDimensionality: $json.embedDims }) }}
```

**Connects to:** Success → Search vault · Error → Reply: search unavailable

### 2.4 · Search vault

*Postgres · On error: error output · Always output data*

**Purpose.** pgvector search: the closest embedded pieces, with a 0 to 1 similarity score.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ JSON.stringify($json.embedding.values), $('Ask config').first().json.topK ] }}` |

**SQL**

```sql
SELECT c.path, c.heading, c.content,
       round((1 - (c.embedding <=> $1::vector))::numeric, 3) AS similarity
FROM kb.chunks c
JOIN kb.documents d ON d.path = c.path AND d.status = 'embedded'
ORDER BY c.embedding <=> $1::vector
LIMIT $2::int;
```

**Connects to:** Success → Enough evidence? · Error → Reply: search unavailable

### 2.5 · Reply: search unavailable

*Edit Fields (Set)*

**Purpose.** Plain reply when Neon or Gemini did not answer.

| Setting | Value |
|---|---|
| assignments.assignments › output | Search is unavailable right now: Neon or Gemini didn't answer. Run the self-test to see which.  (string) |

### 2.6 · Enough evidence?

*Code (JavaScript)*

**Purpose.** Rules decide, AI reads: below the similarity bar it answers "not in your vault" and the model never sees the question; otherwise it numbers the sources.

**Code**

```javascript
// Enough evidence? A RULE decides whether to answer, not the AI.
// Below the similarity bar we say "not in the vault" instead of letting the model guess.
const cfg = $('Ask config').first().json;
const min = Number(cfg.minSimilarity);
const rows = $input.all().map(i => i.json).filter(r => r && r.path);
const best = rows.length ? Math.max(...rows.map(r => Number(r.similarity))) : 0;
if (!rows.length || best < min) {
  return [{ json: { answerable: false, output:
    `I couldn't find that in your vault (closest match ${best.toFixed(2)}, the bar is ${min}). ` +
    `Try other words, or check the note exists and the ingest has run since you wrote it.` } }];
}
const used = rows.filter(r => Number(r.similarity) >= min);
const context = used.map((r, k) => `[${k + 1}] ${r.path}${r.heading ? ' › ' + r.heading : ''}\n${r.content}`).join('\n\n---\n\n');
const sources = used.map((r, k) => `[${k + 1}] ${r.path}${r.heading ? ' › ' + r.heading : ''} (${Number(r.similarity).toFixed(2)})`);
return [{ json: { answerable: true, question: cfg.question, context, sources, best } }];
```

**Connects to:** → Answerable?

### 2.7 · Answerable?

*IF*

**Purpose.** Routes to the answer writer or the not-in-vault reply.

| Setting | Value |
|---|---|
| conditions.options.caseSensitive | True |
| conditions.options.typeValidation | strict |
| conditions.options.version | 3 |
| conditions.conditions | `={{ $json.answerable }}  boolean true` |
| conditions.combinator | and |

**Connects to:** true → Write answer (Gemini) · false → Reply: not in vault

### 2.8 · Write answer (Gemini)

*HTTP Request · On error: error output · Retry: 2 tries, 1000 ms*

**Purpose.** Writes the answer only from the numbered notes, citing them and preferring the newest decision when notes disagree.

| Setting | Value |
|---|---|
| method | POST |
| url | `=https://generativelanguage.googleapis.com/v1beta/models/{{ $('Ask config').first().json.answerModel }}:generateContent` |
| authentication | predefinedCredentialType |
| nodeCredentialType | googlePalmApi |
| sendBody | True |
| specifyBody | json |
| options.timeout | 60000 |

**Request body**

```javascript
{{ JSON.stringify({ systemInstruction: { parts: [{ text: $('Ask config').first().json.answerRules }] }, contents: [{ role: 'user', parts: [{ text: 'Question: ' + $json.question + '\n\nNotes:\n' + $json.context }] }], generationConfig: { temperature: 0.2 } }) }}
```

**Connects to:** Success → Format reply · Error → Reply: notes only

### 2.9 · Reply: not in vault

*Edit Fields (Set)*

**Purpose.** Passes the "not in your vault" message to the chat.

| Setting | Value |
|---|---|
| assignments.assignments › output | `={{ $json.output }}  (string)` |

### 2.10 · Format reply

*Code (JavaScript)*

**Purpose.** Answer plus the numbered source list.

**Code**

```javascript
// Format reply: the answer plus exactly which notes it came from.
const ev = $('Enough evidence?').first().json;
const r = $input.first().json;
const parts = (r.candidates && r.candidates[0] && r.candidates[0].content && r.candidates[0].content.parts) || [];
const text = parts.map(p => p.text || '').join('').trim();
const answer = text || 'The model returned an empty answer, so here are the closest notes instead.';
return [{ json: { output: answer + '\n\nSources:\n' + ev.sources.join('\n') } }];
```

### 2.11 · Reply: notes only

*Code (JavaScript)*

**Purpose.** If the answer model fails, still returns the right notes and says why there is no summary.

**Code**

```javascript
// Gemini couldn't write the answer: still hand back the notes we found.
const ev = $('Enough evidence?').first().json;
const e = $input.first().json.error;
const err = e ? (e.message || JSON.stringify(e)) : 'unknown error';
return [{ json: { output: `I found related notes but couldn't write a summary (Gemini: ${err}). Closest notes:\n` + ev.sources.join('\n') } }];
```

---

## Section 3 · Self-test

> One button, before every demo or after any change. Writes a probe note twice (must stay one copy), searches for it (must be the top hit), checks sizes, counts and stuck runs, cleans up, and reports ✅/❌ to Telegram + Slack.

### 3.1 · Self-test (Mondays 7:00)

*Schedule Trigger*

**Purpose.** Runs the self-test weekly; also runnable by hand from the Execute menu.

| Setting | Value |
|---|---|
| rule.interval[0].field | weeks |
| rule.interval[0].triggerAtDay[0] | 1 |
| rule.interval[0].triggerAtHour | 19 |

**Connects to:** → Self-test config

### 3.2 · Self-test config

*Edit Fields (Set)*

**Purpose.** The probe note's path and deliberately unusual text, plus the model settings to check.

| Setting | Value |
|---|---|
| assignments.assignments › embedModel | gemini-embedding-001  (string) |
| assignments.assignments › embedDims | 768  (number) |
| assignments.assignments › probePath | __selftest__/probe.md  (string) |
| assignments.assignments › probeText | Self-test probe: the zebra ledger reconciles at dawn.  (string) |

**Connects to:** → Check database

### 3.3 · Check database

*Postgres · On error: error output*

**Purpose.** Six health questions in one query: pgvector, tables, failed files, piece-count mismatches, stored vector size, stuck runs.

| Setting | Value |
|---|---|
| operation | executeQuery |

**SQL**

```sql
SELECT
  (SELECT count(*) FROM pg_extension WHERE extname = 'vector') AS has_vector,
  (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'kb'
     AND table_name IN ('documents', 'chunks', 'ingest_runs')) AS kb_tables,
  (SELECT count(*) FROM kb.documents WHERE status = 'failed') AS failed_docs,
  (SELECT count(*) FROM kb.documents d WHERE d.status = 'embedded'
     AND d.chunk_count <> (SELECT count(*) FROM kb.chunks c WHERE c.path = d.path)) AS count_mismatches,
  (SELECT coalesce(max(vector_dims(embedding)), 0) FROM kb.chunks) AS stored_dims,
  (SELECT count(*) FROM kb.ingest_runs WHERE finished_at IS NULL
     AND started_at < now() - interval '1 hour') AS stuck_runs;
```

**Connects to:** Success → Embed probe · Error → Self-test report

### 3.4 · Embed probe

*HTTP Request · On error: error output · Retry: 2 tries, 1000 ms*

**Purpose.** Embeds the probe text, proving the Gemini key, model and vector size.

| Setting | Value |
|---|---|
| method | POST |
| url | `=https://generativelanguage.googleapis.com/v1beta/models/{{ $('Self-test config').first().json.embedModel }}:embedContent` |
| authentication | predefinedCredentialType |
| nodeCredentialType | googlePalmApi |
| sendBody | True |
| specifyBody | json |
| options.timeout | 30000 |

**Request body**

```javascript
{{ JSON.stringify({ model: 'models/' + $('Self-test config').first().json.embedModel, content: { parts: [{ text: $('Self-test config').first().json.probeText }] }, taskType: 'RETRIEVAL_DOCUMENT', outputDimensionality: $('Self-test config').first().json.embedDims }) }}
```

**Connects to:** Success → Write probe (1st) · Error → Self-test report

### 3.5 · Self-test report

*Code (JavaScript)*

**Purpose.** Turns every result into ✅ / ⚠️ / ❌ in plain words; reads Success outputs explicitly with .first(0).

**Code**

```javascript
// Self-test report: pass/fail per check, in plain words.
const cfg = $('Self-test config').first().json;
// first(0) = read the SUCCESS output (output 0), even if the node's Error output is also wired to this node.
const get = n => { try { return $(n).isExecuted ? $(n).first(0).json : null; } catch (e) { return null; } };
const db = get('Check database');
const emb = get('Embed probe');
const s = get('Search for probe');
const clean = get('Clean up probe');
const checks = [];
const add = (name, pass, detail, level = 'fail') => checks.push({ name, pass, detail, level });
const dims = emb && emb.embedding && emb.embedding.values ? emb.embedding.values.length : 0;
const want = Number(cfg.embedDims);
const dbOk = !!db && db.kb_tables !== undefined;

add('Neon reachable, kb tables + pgvector present', dbOk && Number(db.kb_tables) === 3 && Number(db.has_vector) === 1,
  dbOk ? `tables ${db.kb_tables}/3, pgvector ${Number(db.has_vector) ? 'on' : 'off'}` : 'no answer from Neon');
add(`Gemini returns ${want}-number vectors`, dims === want, dims ? `got ${dims}` : 'no answer from Gemini');
add('Stored vectors match that size', dbOk && (Number(db.stored_dims) === 0 || Number(db.stored_dims) === want),
  dbOk ? `stored: ${Number(db.stored_dims) || 'none yet'}` : 'skipped');
add('Saving the same note twice leaves ONE copy', !!s && Number(s.probe_rows) === 1, s && s.path ? `${s.probe_rows} copy/copies` : 'skipped');
add('Search finds the probe note first', !!s && s.path === cfg.probePath && Number(s.similarity) > 0.99,
  s && s.path ? `top hit: ${s.path} (${s.similarity})` : 'skipped');
add('Every embedded file has the right piece count', dbOk && Number(db.count_mismatches) === 0, dbOk ? `${db.count_mismatches} mismatch(es)` : 'skipped');
add('No stuck ingest runs', dbOk && Number(db.stuck_runs) === 0, dbOk ? `${db.stuck_runs} stuck` : 'skipped');
const wrote = (() => { try { return $('Write probe (1st)').isExecuted; } catch (e) { return false; } })();
add('Probe cleaned up', !wrote || (!!clean && clean.path === cfg.probePath),
  !wrote ? 'no probe was written, nothing to clean' : (clean && clean.path ? 'removed' : `not removed: run DELETE FROM kb.documents WHERE path = '${cfg.probePath}'`), 'warn');
add('No failed files waiting for review', dbOk && Number(db.failed_docs) === 0, dbOk ? `${db.failed_docs} failed (see kb.documents)` : 'skipped', 'warn');

const hardFails = checks.filter(c => !c.pass && c.level === 'fail').length;
const warns = checks.filter(c => !c.pass && c.level === 'warn').length;
const head = `Business Brain self-test: ${hardFails ? hardFails + ' FAILED' : 'all core checks passed'}${warns ? `, ${warns} warning(s)` : ''}`;
const body = checks.map(c => `${c.pass ? '✅' : (c.level === 'warn' ? '⚠️' : '❌')} ${c.name}: ${c.detail}`).join('\n');
return [{ json: { allPass: hardFails === 0, hardFails, warns, checks, telegram_text: head + '\n' + body, slack_text: head + '\n' + body } }];
```

**Connects to:** → Telegram: self-test · → All passed?

### 3.6 · Write probe (1st)

*Postgres · On error: error output*

**Purpose.** Writes the probe note.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $('Self-test config').first().json.probePath, $('Self-test config').first().json.probeText, JSON.stringify($('Embed probe').first().json.embedding.values) ] }}` |

**SQL**

```sql
WITH doc AS (
  INSERT INTO kb.documents (path, title, content_hash, status, chunk_count)
  VALUES ($1, 'Self-test probe', 'probe', 'embedded', 1)
  ON CONFLICT (path) DO UPDATE SET status = 'embedded'
  RETURNING path
)
INSERT INTO kb.chunks (path, chunk_no, heading, content, embedding)
SELECT path, 0, 'probe', $2, $3::vector FROM doc
ON CONFLICT (path, chunk_no) DO UPDATE SET content = EXCLUDED.content, embedding = EXCLUDED.embedding
RETURNING path;
```

**Connects to:** Success → Write probe (2nd) · Error → Clean up probe

### 3.7 · Telegram: self-test

*Telegram · On error: continue*

**Purpose.** Sends the self-test report to Telegram.

| Setting | Value |
|---|---|
| chatId | {TELEGRAM_CHAT_ID} |
| text | `={{ $json.telegram_text }}` |
| additionalFields.appendAttribution | False |

### 3.8 · All passed?

*IF*

**Purpose.** Pass goes to the updates channel, fail to the error channel.

| Setting | Value |
|---|---|
| conditions.options.caseSensitive | True |
| conditions.options.typeValidation | strict |
| conditions.options.version | 3 |
| conditions.conditions | `={{ $json.allPass }}  boolean true` |
| conditions.combinator | and |

**Connects to:** true → Slack: self-test passed · false → Slack: self-test FAILED

### 3.9 · Write probe (2nd)

*Postgres · On error: error output*

**Purpose.** Writes the same probe again: the no-duplicates test (must still be one copy).

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $('Self-test config').first().json.probePath, $('Self-test config').first().json.probeText, JSON.stringify($('Embed probe').first().json.embedding.values) ] }}` |

**SQL**

```sql
WITH doc AS (
  INSERT INTO kb.documents (path, title, content_hash, status, chunk_count)
  VALUES ($1, 'Self-test probe', 'probe', 'embedded', 1)
  ON CONFLICT (path) DO UPDATE SET status = 'embedded'
  RETURNING path
)
INSERT INTO kb.chunks (path, chunk_no, heading, content, embedding)
SELECT path, 0, 'probe', $2, $3::vector FROM doc
ON CONFLICT (path, chunk_no) DO UPDATE SET content = EXCLUDED.content, embedding = EXCLUDED.embedding
RETURNING path;
```

**Connects to:** Success → Search for probe · Error → Clean up probe

### 3.10 · Clean up probe

*Postgres · On error: continue*

**Purpose.** Deletes the probe (its piece goes too, by cascade). Every probe failure routes here first so no test data is left behind.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ $('Self-test config').first().json.probePath ] }}` |

**SQL**

```sql
DELETE FROM kb.documents WHERE path = $1 RETURNING path;
```

**Connects to:** → Self-test report

### 3.11 · Slack: self-test passed

*Slack*

**Purpose.** Posts a passing report to the updates channel.

| Setting | Value |
|---|---|
| select | channel |
| channelId | #alerts-updates |
| text | `={{ $json.slack_text }}` |

### 3.12 · Slack: self-test FAILED

*Slack*

**Purpose.** Posts a failing report to the error channel.

| Setting | Value |
|---|---|
| select | channel |
| channelId | #alerts-errors |
| text | `={{ $json.slack_text }}` |

### 3.13 · Search for probe

*Postgres · On error: error output*

**Purpose.** Searches with the probe's own vector; it must be the top hit at about 1.0, with exactly one row.

| Setting | Value |
|---|---|
| operation | executeQuery |
| options.queryReplacement | `={{ [ JSON.stringify($('Embed probe').first().json.embedding.values), $('Self-test config').first().json.probePath ] }}` |

**SQL**

```sql
SELECT c.path,
       round((1 - (c.embedding <=> $1::vector))::numeric, 4) AS similarity,
       (SELECT count(*) FROM kb.chunks WHERE path = $2::text) AS probe_rows
FROM kb.chunks c
ORDER BY c.embedding <=> $1::vector
LIMIT 1;
```

**Connects to:** Success → Clean up probe · Error → Clean up probe

---

## Section 4 · Health check

> Every morning at 8:00. No AI calls, just reads the numbers: did last night's ingest finish, anything stuck, anything failed. Healthy = one quiet Telegram line. Not healthy = Slack + Telegram.

### 4.1 · Every morning 8:00

*Schedule Trigger*

**Purpose.** Runs the health check daily.

| Setting | Value |
|---|---|
| rule.interval[0].triggerAtHour | 20 |

**Connects to:** → Read health numbers

### 4.2 · Read health numbers

*Postgres · On error: error output*

**Purpose.** Last finished run, stuck runs, failed files, embedded files and pieces. No AI calls, no cost.

| Setting | Value |
|---|---|
| operation | executeQuery |

**SQL**

```sql
SELECT
  (SELECT max(finished_at) FROM kb.ingest_runs) AS last_run,
  (SELECT count(*) FROM kb.ingest_runs WHERE finished_at IS NULL AND started_at < now() - interval '1 hour') AS stuck_runs,
  (SELECT count(*) FROM kb.documents WHERE status = 'failed') AS failed_docs,
  (SELECT count(*) FROM kb.documents WHERE status = 'embedded') AS embedded_docs,
  (SELECT coalesce(sum(chunk_count), 0) FROM kb.documents WHERE status = 'embedded') AS chunks;
```

**Connects to:** Success → Judge health · Error → Neon unreachable

### 4.3 · Judge health

*Code (JavaScript)*

**Purpose.** Rules turn the numbers into healthy or not (a nightly missed for 36+ hours, stuck runs, failed files).

**Code**

```javascript
// Judge health: rules turn the numbers into "fine" or "look at this".
const h = $input.first().json;
const issues = [];
const hoursSince = t => t ? (Date.now() - new Date(t).getTime()) / 36e5 : null;
const last = hoursSince(h.last_run);
if (last === null) issues.push('No ingest has finished yet.');
else if (last > 36) issues.push(`Last ingest finished ${Math.round(last)}h ago (nightly missed: PC off, n8n down, or the ingest broke).`);
if (Number(h.stuck_runs) > 0) issues.push(`${h.stuck_runs} ingest run(s) started but never finished.`);
if (Number(h.failed_docs) > 0) issues.push(`${h.failed_docs} file(s) failed and are waiting for review in kb.documents.`);
const stats = `${h.embedded_docs} files · ${h.chunks} chunks searchable`;
const healthy = issues.length === 0;
const text = healthy ? `Business Brain healthy: ${stats}.` : `Business Brain needs a look:\n- ${issues.join('\n- ')}\n(${stats})`;
return [{ json: { healthy, telegram_text: text, slack_text: (healthy ? ':white_check_mark: ' : ':warning: ') + text } }];
```

**Connects to:** → Healthy?

### 4.4 · Neon unreachable

*Code (JavaScript)*

**Purpose.** Message for when the database does not answer the health check.

**Code**

```javascript
// Neon didn't answer the health check at all.
const e = $input.first().json.error;
const err = e ? (e.message || JSON.stringify(e)) : 'unknown error';
const text = `Business Brain health check could not reach Neon.\nError: ${err}\nCheck the Neon project is active and the "Postgres credential" credential still tests green.`;
return [{ json: { healthy: false, telegram_text: text, slack_text: ':x: ' + text } }];
```

**Connects to:** → Slack: health problem · → Telegram: health problem

### 4.5 · Healthy?

*IF*

**Purpose.** Healthy goes to a quiet Telegram heartbeat; anything else to Slack + Telegram.

| Setting | Value |
|---|---|
| conditions.options.caseSensitive | True |
| conditions.options.typeValidation | strict |
| conditions.options.version | 3 |
| conditions.conditions | `={{ $json.healthy }}  boolean true` |
| conditions.combinator | and |

**Connects to:** true → Telegram: heartbeat · false → Slack: health problem · false → Telegram: health problem

### 4.6 · Slack: health problem

*Slack*

**Purpose.** Posts health problems to the error channel.

| Setting | Value |
|---|---|
| select | channel |
| channelId | #alerts-errors |
| text | `={{ $json.slack_text }}` |

### 4.7 · Telegram: health problem

*Telegram*

**Purpose.** Sends health problems to Telegram.

| Setting | Value |
|---|---|
| chatId | {TELEGRAM_CHAT_ID} |
| text | `={{ $json.telegram_text }}` |
| additionalFields.appendAttribution | False |

### 4.8 · Telegram: heartbeat

*Telegram*

**Purpose.** The quiet daily "healthy" line.

| Setting | Value |
|---|---|
| chatId | {TELEGRAM_CHAT_ID} |
| text | `={{ $json.telegram_text }}` |
| additionalFields.appendAttribution | False |

---

## Appendix · Database schema (`01_kb_schema.sql`)

```sql
-- ============================================================================
-- Business Brain (RAG) · knowledge-base schema
-- Lives in the same Neon project as RECON, in its own `kb` schema so it never
-- mixes with lead data. Safe to re-run (everything is IF NOT EXISTS / OR REPLACE).
--
-- Build Standard, applied:
--   * No duplicates   -> documents keyed on path; chunks keyed on (path, chunk_no);
--                        unchanged files are skipped by content_hash.
--   * Errors handled  -> a file that fails is marked 'failed' with the reason
--                        (the review queue for this system), never silently dropped.
--   * Test first      -> every ingest run is logged, incl. whether it was a test run.
-- Embeddings: 768 dimensions (Gemini embedding, output trimmed to 768) so the
-- HNSW index can be used (pgvector indexes cap at 2000 dimensions).
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA IF NOT EXISTS kb;

-- One row per file in the vault.
CREATE TABLE IF NOT EXISTS kb.documents (
  path             TEXT PRIMARY KEY,                -- path relative to the vault root
  title            TEXT,
  content_hash     TEXT NOT NULL,                   -- unchanged hash = skip re-embedding
  chunk_count      INT  NOT NULL DEFAULT 0,
  status           TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'embedded', 'failed', 'deleted')),
  last_error       TEXT,                            -- why it failed (review queue)
  file_modified_at TIMESTAMPTZ,
  embedded_at      TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One row per searchable piece of a file (split by heading).
CREATE TABLE IF NOT EXISTS kb.chunks (
  path         TEXT NOT NULL REFERENCES kb.documents(path) ON DELETE CASCADE,
  chunk_no     INT  NOT NULL,
  heading      TEXT,                                -- the section it came from
  content      TEXT NOT NULL,
  embedding    vector(768) NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (path, chunk_no)
);

CREATE INDEX IF NOT EXISTS idx_kb_chunks_embedding
  ON kb.chunks USING hnsw (embedding vector_cosine_ops);

-- One row per ingest run: the paper trail + the self-test record.
CREATE TABLE IF NOT EXISTS kb.ingest_runs (
  run_id        BIGSERIAL PRIMARY KEY,
  started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at   TIMESTAMPTZ,
  test_mode     BOOLEAN NOT NULL DEFAULT FALSE,
  files_seen    INT NOT NULL DEFAULT 0,
  files_changed INT NOT NULL DEFAULT 0,
  files_failed  INT NOT NULL DEFAULT 0,
  notes         TEXT
);

-- Keep updated_at honest on every change.
CREATE OR REPLACE FUNCTION kb.set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kb_documents_updated ON kb.documents;
CREATE TRIGGER trg_kb_documents_updated
  BEFORE UPDATE ON kb.documents
  FOR EACH ROW EXECUTE FUNCTION kb.set_updated_at();

-- The at-a-glance view (feeds the dashboard later).
CREATE OR REPLACE VIEW kb.v_status AS
SELECT status,
       count(*)              AS files,
       sum(chunk_count)      AS chunks,
       max(embedded_at)      AS last_embedded
FROM kb.documents
GROUP BY status;
```
