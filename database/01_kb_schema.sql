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
