-- =============================================================
-- ARETE APP — SCHEMA
-- Safe to re-run: uses IF NOT EXISTS and DROP POLICY IF EXISTS
-- =============================================================

-- Users profile (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  streak_days INTEGER DEFAULT 0,
  last_active_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Topics (e.g. Python Programming)
CREATE TABLE IF NOT EXISTS topics (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  icon_name TEXT,
  order_index INTEGER
);

-- Lessons within topics
CREATE TABLE IF NOT EXISTS lessons (
  id SERIAL PRIMARY KEY,
  topic_id INTEGER REFERENCES topics(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  level_tier TEXT CHECK (level_tier IN ('foundations', 'data_handling', 'applied')),
  order_index INTEGER,
  xp_reward INTEGER DEFAULT 10
);

-- Quiz questions for each lesson
CREATE TABLE IF NOT EXISTS quiz_questions (
  id SERIAL PRIMARY KEY,
  lesson_id INTEGER REFERENCES lessons(id),
  question_text TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  option_c TEXT NOT NULL,
  option_d TEXT NOT NULL,
  correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('a','b','c','d')),
  explanation TEXT
);

-- Quiz attempts by users
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  lesson_id INTEGER REFERENCES lessons(id),
  score INTEGER NOT NULL,
  max_score INTEGER NOT NULL,
  started_at TIMESTAMPTZ,
  duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Keep existing databases compatible with the current application code.
ALTER TABLE quiz_attempts ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE quiz_attempts ADD COLUMN IF NOT EXISTS duration_seconds INTEGER;

-- Badges
CREATE TABLE IF NOT EXISTS badges (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon_name TEXT,
  criteria_type TEXT,
  criteria_value INTEGER
);

-- User badge achievements
CREATE TABLE IF NOT EXISTS user_badges (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  badge_id INTEGER REFERENCES badges(id),
  earned_at TIMESTAMPTZ DEFAULT NOW()
);

-- Open Student Model — skill mastery per topic area
CREATE TABLE IF NOT EXISTS skill_mastery (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  skill_name TEXT NOT NULL,
  mastery_score FLOAT DEFAULT 0.0 CHECK (mastery_score >= 0 AND mastery_score <= 1),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS skill_mastery_user_skill_idx
  ON skill_mastery (user_id, skill_name);

-- Learner-selected mastery goal shown in the open student model.
CREATE TABLE IF NOT EXISTS user_goals (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  skill_name TEXT NOT NULL,
  target_pct INTEGER NOT NULL DEFAULT 80 CHECK (target_pct BETWEEN 1 AND 100),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Learning sessions (analytics)
CREATE TABLE IF NOT EXISTS learning_sessions (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  lesson_id INTEGER REFERENCES lessons(id),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER
);

-- Feedback / survey responses
CREATE TABLE IF NOT EXISTS feedback_responses (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  sus_score FLOAT,
  imi_score FLOAT,
  open_feedback TEXT,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Intrinsic Motivation Inventory subscales. Kept separate from usability
-- feedback so motivation and knowledge outcomes cannot be confused.
CREATE TABLE IF NOT EXISTS imi_responses (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  interest_enjoyment FLOAT NOT NULL CHECK (interest_enjoyment BETWEEN 1 AND 7),
  perceived_competence FLOAT NOT NULL CHECK (perceived_competence BETWEEN 1 AND 7),
  perceived_choice FLOAT NOT NULL CHECK (perceived_choice BETWEEN 1 AND 7),
  relatedness FLOAT NOT NULL CHECK (relatedness BETWEEN 1 AND 7),
  responses JSONB NOT NULL DEFAULT '{}'::jsonb,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dedicated pre/post knowledge outcomes. Raw counts are retained so the
-- percentage can always be reproduced rather than parsed from free text.
CREATE TABLE IF NOT EXISTS knowledge_assessments (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  assessment_type TEXT NOT NULL CHECK (assessment_type IN ('pre', 'post')),
  score INTEGER NOT NULL CHECK (score >= 0),
  max_score INTEGER NOT NULL CHECK (max_score > 0 AND score <= max_score),
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, assessment_type)
);

-- Research access is assigned only by a database administrator/service role.
-- There is deliberately no client INSERT/UPDATE policy for this table.
CREATE TABLE IF NOT EXISTS researcher_roles (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
  granted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION is_researcher(check_user UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM researcher_roles WHERE user_id = check_user
  );
$$;

REVOKE ALL ON FUNCTION is_researcher(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_researcher(UUID) TO authenticated;

-- Public leaderboard data is returned through a narrow function instead of
-- granting access to every profile column.
CREATE OR REPLACE FUNCTION get_leaderboard(row_limit INTEGER DEFAULT 10)
RETURNS TABLE (
  username TEXT,
  display_name TEXT,
  xp INTEGER,
  level INTEGER,
  streak_days INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.username, p.display_name, p.xp, p.level, p.streak_days
  FROM profiles p
  ORDER BY p.xp DESC, p.created_at ASC
  LIMIT LEAST(GREATEST(row_limit, 1), 100);
$$;

REVOKE ALL ON FUNCTION get_leaderboard(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_leaderboard(INTEGER) TO authenticated;

-- ── ROW LEVEL SECURITY ────────────────────────────────────────
ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges       ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_mastery     ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_goals         ENABLE ROW LEVEL SECURITY;
ALTER TABLE imi_responses      ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE researcher_roles   ENABLE ROW LEVEL SECURITY;

-- Drop policies before recreating (safe to re-run)
DROP POLICY IF EXISTS "Users can view own profile"        ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile"      ON profiles;
DROP POLICY IF EXISTS "Users can update own profile"      ON profiles;
DROP POLICY IF EXISTS "Users can view own quiz attempts"  ON quiz_attempts;
DROP POLICY IF EXISTS "Users can manage own skill mastery" ON skill_mastery;
DROP POLICY IF EXISTS "Users can view own badges"         ON user_badges;
DROP POLICY IF EXISTS "Users can insert own badges"       ON user_badges;
DROP POLICY IF EXISTS "Users can manage own sessions"     ON learning_sessions;
DROP POLICY IF EXISTS "Users can submit own feedback"     ON feedback_responses;
DROP POLICY IF EXISTS "Users can manage own goals"         ON user_goals;
DROP POLICY IF EXISTS "Users can submit own IMI"           ON imi_responses;
DROP POLICY IF EXISTS "Users can manage own assessments"   ON knowledge_assessments;
DROP POLICY IF EXISTS "Researchers can view profiles"      ON profiles;
DROP POLICY IF EXISTS "Researchers can view attempts"      ON quiz_attempts;
DROP POLICY IF EXISTS "Researchers can view mastery"       ON skill_mastery;
DROP POLICY IF EXISTS "Researchers can view sessions"      ON learning_sessions;
DROP POLICY IF EXISTS "Researchers can view feedback"      ON feedback_responses;
DROP POLICY IF EXISTS "Researchers can view IMI"           ON imi_responses;
DROP POLICY IF EXISTS "Researchers can view assessments"   ON knowledge_assessments;
DROP POLICY IF EXISTS "Anyone can view topics"            ON topics;
DROP POLICY IF EXISTS "Anyone can view lessons"           ON lessons;
DROP POLICY IF EXISTS "Anyone can view quiz questions"    ON quiz_questions;
DROP POLICY IF EXISTS "Anyone can view badges"            ON badges;

-- Profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- Quiz attempts
CREATE POLICY "Users can view own quiz attempts"
  ON quiz_attempts FOR ALL USING (auth.uid() = user_id);

-- Skill mastery
CREATE POLICY "Users can manage own skill mastery"
  ON skill_mastery FOR ALL USING (auth.uid() = user_id);

-- Badges
CREATE POLICY "Users can view own badges"
  ON user_badges FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own badges"
  ON user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Learning sessions
CREATE POLICY "Users can manage own sessions"
  ON learning_sessions FOR ALL USING (auth.uid() = user_id);

-- Feedback
CREATE POLICY "Users can submit own feedback"
  ON feedback_responses FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own goals"
  ON user_goals FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can submit own IMI"
  ON imi_responses FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage own assessments"
  ON knowledge_assessments FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Read-only study-wide access for explicitly authorised researchers.
CREATE POLICY "Researchers can view profiles"
  ON profiles FOR SELECT USING (is_researcher());
CREATE POLICY "Researchers can view attempts"
  ON quiz_attempts FOR SELECT USING (is_researcher());
CREATE POLICY "Researchers can view mastery"
  ON skill_mastery FOR SELECT USING (is_researcher());
CREATE POLICY "Researchers can view sessions"
  ON learning_sessions FOR SELECT USING (is_researcher());
CREATE POLICY "Researchers can view feedback"
  ON feedback_responses FOR SELECT USING (is_researcher());
CREATE POLICY "Researchers can view IMI"
  ON imi_responses FOR SELECT USING (is_researcher());
CREATE POLICY "Researchers can view assessments"
  ON knowledge_assessments FOR SELECT USING (is_researcher());

-- Public read access for content tables
CREATE POLICY "Anyone can view topics"         ON topics          FOR SELECT USING (true);
CREATE POLICY "Anyone can view lessons"        ON lessons         FOR SELECT USING (true);
CREATE POLICY "Anyone can view quiz questions" ON quiz_questions  FOR SELECT USING (true);
CREATE POLICY "Anyone can view badges"         ON badges          FOR SELECT USING (true);
