-- End-to-end flows on a clean database: bootstrap as superuser, every DDL file as the owner role.
-- Each step runs as the role that would really do it. If an invariant breaks, an ASSERT stops it.
--   psql -v ON_ERROR_STOP=1 -f flows.sql
-- Run it again after every schema change.

\set ON_ERROR_STOP on
\set QUIET on
\pset footer off

-- ─── Setup (owner): stubs with the real signature, base data ─────────────────

SET ROLE <owner>;
-- Example: a queue's add_job, with the real signature so the DDL that calls it does not change.
-- CREATE FUNCTION <queue_schema>.add_job(identifier text, payload json DEFAULT NULL, …) RETURNS void
--   LANGUAGE sql AS $$ INSERT INTO <queue_schema>.jobs_stub … $$;

SET ROLE <app>;
BEGIN;
SELECT set_config('app.actor_kind', 'system', true) \g /dev/null
-- base rows (users, settings, catalog)…
COMMIT;
-- capture ids for later steps:
-- SELECT id AS some_user FROM users WHERE email = '…' \gset

-- ─── 1. <First flow> ─────────────────────────────────────────────────────────
\echo '1. <What this flow proves, in plain words>'

BEGIN;
-- the writes, as the real role, with its actor declared
COMMIT;

-- The negative case the decision promised: the same write twice must not duplicate.
-- INSERT … ON CONFLICT DO NOTHING;

DO $$ BEGIN
  ASSERT (SELECT count(*) FROM <table>) = 1, '<what went wrong, in plain words>';
END $$;

-- A write that must FAIL: catch the expected error, fail if it did not happen.
DO $$ BEGIN
  BEGIN
    -- the forbidden write…
    RAISE EXCEPTION 'the forbidden write went through';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

-- ─── 2. <Next flow> … ────────────────────────────────────────────────────────

\echo 'All flows passed.'
