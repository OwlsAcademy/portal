-- ================================================================
-- Owl's Academy — Supabase Database Migration
-- Safe to run multiple times (idempotent).
-- Run in: Supabase Dashboard → SQL Editor → New query
-- ================================================================

-- ── CREATE TABLES ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS students (
  id         UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  name       TEXT    NOT NULL,
  code       TEXT    NOT NULL UNIQUE,
  prefix     TEXT    NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Lessons are standalone content — not tied to any student.
-- ID is a UUID generated automatically (never entered manually).
CREATE TABLE IF NOT EXISTS lessons (
  id           UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  title        TEXT,
  subtitle     TEXT,
  level        TEXT,
  header_emoji TEXT,
  tabs         TEXT[],
  vocabulary   JSONB,
  grammar      JSONB,
  reading      JSONB,
  exercises    JSONB,
  flashcards   JSONB,
  homework     JSONB,
  speaking     JSONB,
  created_at   TIMESTAMPTZ DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- Many-to-many: which lessons a student has access to, in what order.
CREATE TABLE IF NOT EXISTS student_lessons (
  id           UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id   UUID    NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  lesson_id    UUID    NOT NULL REFERENCES lessons(id)  ON DELETE CASCADE,
  lesson_order INT     NOT NULL DEFAULT 1,
  assigned_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(student_id, lesson_id)
);

-- One progress record per student+lesson (upserted on activity).
CREATE TABLE IF NOT EXISTS lesson_progress (
  id          UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id  UUID    NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  lesson_id   UUID    NOT NULL REFERENCES lessons(id)  ON DELETE CASCADE,
  score       INT,
  exercises   JSONB,
  flashcards  JSONB,
  homework    JSONB,
  mywords     JSONB,
  notes       TEXT,
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(student_id, lesson_id)
);

CREATE TABLE IF NOT EXISTS config (
  id                  INT  PRIMARY KEY DEFAULT 1,
  emailjs_public_key  TEXT DEFAULT '',
  emailjs_service_id  TEXT DEFAULT '',
  emailjs_template_id TEXT DEFAULT '',
  emailjs_to_email    TEXT DEFAULT ''
);

INSERT INTO config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- ── ALTER EXISTING TABLES (safe to run on existing DB) ────────

-- lessons: drop old columns if they exist
ALTER TABLE lessons DROP COLUMN IF EXISTS lesson_number;
ALTER TABLE lessons DROP COLUMN IF EXISTS date;
ALTER TABLE lessons DROP COLUMN IF EXISTS student_code;
ALTER TABLE lessons DROP COLUMN IF EXISTS student_name;

-- student_lessons: add lesson_order if not present
ALTER TABLE student_lessons ADD COLUMN IF NOT EXISTS lesson_order INT NOT NULL DEFAULT 1;

-- lesson_progress: add mywords if not present
ALTER TABLE lesson_progress ADD COLUMN IF NOT EXISTS mywords JSONB;
ALTER TABLE lesson_progress ADD COLUMN IF NOT EXISTS notes   TEXT;

-- ── AUTO-UPDATE TRIGGERS ──────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lessons_updated_at        ON lessons;
DROP TRIGGER IF EXISTS lesson_progress_updated_at ON lesson_progress;

CREATE TRIGGER lessons_updated_at
  BEFORE UPDATE ON lessons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER lesson_progress_updated_at
  BEFORE UPDATE ON lesson_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── ROW LEVEL SECURITY ────────────────────────────────────────

ALTER TABLE students        ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons         ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE config          ENABLE ROW LEVEL SECURITY;

-- Drop all policies before recreating (prevents "already exists" errors)
DROP POLICY IF EXISTS "anon_read_students"        ON students;
DROP POLICY IF EXISTS "anon_read_lessons"         ON lessons;
DROP POLICY IF EXISTS "anon_read_student_lessons" ON student_lessons;
DROP POLICY IF EXISTS "anon_read_config"          ON config;
DROP POLICY IF EXISTS "anon_write_progress"       ON lesson_progress;
DROP POLICY IF EXISTS "auth_all_students"         ON students;
DROP POLICY IF EXISTS "auth_all_lessons"          ON lessons;
DROP POLICY IF EXISTS "auth_all_student_lessons"  ON student_lessons;
DROP POLICY IF EXISTS "auth_all_lesson_progress"  ON lesson_progress;
DROP POLICY IF EXISTS "auth_all_config"           ON config;

-- Anon (student portal) — read-only on most tables
CREATE POLICY "anon_read_students"        ON students        FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read_lessons"         ON lessons         FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read_student_lessons" ON student_lessons FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read_config"          ON config          FOR SELECT TO anon USING (true);

-- Anon — students can write their own progress
CREATE POLICY "anon_write_progress" ON lesson_progress
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- Authenticated (admin) — full CRUD on everything
CREATE POLICY "auth_all_students"        ON students        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_lessons"         ON lessons         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_student_lessons" ON student_lessons FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_lesson_progress" ON lesson_progress FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_config"          ON config          FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── TABLE-LEVEL GRANTS ────────────────────────────────────────

GRANT SELECT                         ON students        TO anon;
GRANT SELECT                         ON lessons         TO anon;
GRANT SELECT                         ON student_lessons TO anon;
GRANT SELECT                         ON config          TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON lesson_progress TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON students        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON lessons         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON student_lessons TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON lesson_progress TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON config          TO authenticated;
