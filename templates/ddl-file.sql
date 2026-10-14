-- Domain <Name>. DDL of the tables closed in <design document> §12 (decisions <from> to <to>).
-- Not a migration: the input for the domain review and the flows script.
-- Depends on <previous files>. <Anything another file adds to these tables, and where.>

-- ─── <table> (decisions <n>, <m>) ─────────────────────────────────────────────

CREATE TABLE <table> (
  id         uuid        NOT NULL DEFAULT uuidv7(),
  -- columns…
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT <table>_pkey PRIMARY KEY (id),
  CONSTRAINT <table>_<column>_fkey FOREIGN KEY (<column>) REFERENCES <parent> (id) ON DELETE RESTRICT,
  -- Decision <n>: <the rule in one line>.
  CONSTRAINT <table>_<column>_check CHECK (<column> IN ('a', 'b'))
);

-- Decision <n>: <the query this index serves>.
CREATE INDEX <table>_<column>_idx ON <table> (<column>);

-- Trigger functions pin search_path (every definer and every trigger function).
CREATE FUNCTION <table>_<what>() RETURNS trigger
  LANGUAGE plpgsql
  SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN NEW;
END $$;

-- BEFORE triggers run in alphabetical order: name them so the order is the intended one.
CREATE TRIGGER <table>_set_updated_at
  BEFORE UPDATE ON <table>
  FOR EACH ROW WHEN (OLD IS DISTINCT FROM NEW)   -- drop the WHEN if the table has generated columns
  EXECUTE FUNCTION set_updated_at();

-- ─── App role privileges beyond the default SELECT, INSERT ───────────────────
-- Immutable tables: no extra grant. Trigger-written tables: REVOKE INSERT. Views: REVOKE INSERT.

GRANT UPDATE (<editable columns>) ON <table> TO <app_role>;
