-- Database bootstrap. Runs once, as superuser, before any migration. Not an ORM migration.
-- Passwords come from psql variables, never written here:
--   psql -v db=<db> -v owner_pw=… -v app_pw=… -f bootstrap.sql
-- Server settings (postgresql.conf or compose), if used:
--   shared_preload_libraries = 'pg_stat_statements'
--   password_encryption = 'scram-sha-256'   (pg_hba.conf: scram-sha-256; hostssl when not local)

-- ─── Roles: one per process, the minimum each needs ──────────────────────────

CREATE ROLE <owner> LOGIN PASSWORD :'owner_pw';   -- migrations; owns everything; SECURITY DEFINER runs as it
CREATE ROLE <app>   LOGIN PASSWORD :'app_pw';     -- api and worker
-- CREATE ROLE <ingest> …   -- e.g. a webhook receiver that only inserts
-- CREATE ROLE <reader> …   -- e.g. a read-only role for one view

-- ─── Database ────────────────────────────────────────────────────────────────

ALTER DATABASE :"db" SET timezone = 'UTC';
REVOKE ALL ON DATABASE :"db" FROM PUBLIC;
REVOKE TEMP ON DATABASE :"db" FROM PUBLIC;          -- temp tables can shadow real ones
GRANT CONNECT ON DATABASE :"db" TO <owner>, <app>;

-- Only the owner creates in public: this is what makes search_path = public, pg_temp safe.
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CREATE ON SCHEMA public TO <owner>;
GRANT USAGE ON SCHEMA public TO <app>;

-- ─── Extensions (only what a decision needs) ─────────────────────────────────

-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- ─── Default privileges: closed by default ───────────────────────────────────
-- Every new table is "read and insert" for the app. Each mutable table asks for its UPDATE/DELETE
-- in its own file; views and trigger-written tables revoke INSERT.

ALTER DEFAULT PRIVILEGES FOR ROLE <owner> IN SCHEMA public
  GRANT SELECT, INSERT ON TABLES TO <app>;

-- ─── Queue schema, if the project uses a Postgres-backed queue ───────────────

-- CREATE SCHEMA <queue_schema> AUTHORIZATION <owner>;
-- GRANT USAGE ON SCHEMA <queue_schema> TO <app>;
-- ALTER DEFAULT PRIVILEGES FOR ROLE <owner> IN SCHEMA <queue_schema>
--   GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO <app>;
