# Cross-cutting conventions

Decide these before any table, one topic per message, in roughly this order (each one is used by the next). Each entry gives the question, the options worth showing, and the **starting recommendation** that held up in practice. It is a recommendation, not a default to impose: present the options and let the owner decide.

## 1. Primary keys

- Options: `uuid` with `uuidv7()` · `bigint GENERATED ALWAYS AS IDENTITY` · mixed.
- Start with **uuidv7 everywhere** (PG18+ native; older versions need an extension), generated **by the database**, never the app (one clock; ordering ties broken by id is coherent). Natural keys only where the domain has one (a settings key).
- Rules that go with it: **no id is ever a public token** (uuidv7 exposes its creation time; links that leave the system carry a separate random token); a human-readable number (quotes, invoices) is a separate column, added when something needs it.

## 2. Names and language

- One language for tables, columns **and enum values** (usually English), with a **glossary** for business terms (it catches collisions: "deposit" as down payment versus bank deposit).
- `snake_case`, unquoted.
- **One actor vocabulary** across tables (for example `client` / `bot` / `user` / `system`), and every column that points to users ends in `_user_id` so the name says the target.

## 3. Enumerations

- Options: `text` + CHECK · native ENUM · lookup table.
- Start with **`text` + CHECK**, the values coming from **one constant** in code that feeds the ORM type, the CHECK and the API schema. Explicit constraint names (`<table>_<column>_check`) so a later migration knows what to replace.
- Lookup table only when the owner must edit the set without a deploy or the values carry data.
- ORM trap to check: some ORMs type an enum column but do not create the CHECK.
- Open namespaces defined by code (event types, notification types) are an exception: a format CHECK plus a catalog in code, because a value list would force a migration per new flow.

## 4. Time

- **4a. Business dates.** `timestamptz` for instants of the system; `date` for days a person enters (payment date, due date, arrival). A `date` column never ends in `_at`. Dates are interpreted in the business time zone, and "today" is defined in one function (`business_today()`), used by every cron and report. Test that the driver returns `date` as a string, not a midnight `Date`.
- **4b. `updated_at` and the database time zone.** A `BEFORE UPDATE` trigger with `WHEN (OLD IS DISTINCT FROM NEW)` (not the ORM's hook: it misses raw SQL, cache triggers and upserts). The database runs in UTC; the business zone is always asked for explicitly. Note: a whole-row `WHEN` is not allowed on tables with generated columns — drop the `WHEN` there.

## 5. Money

- `numeric(p,s)` per class of amount (for example amounts `numeric(14,2)`, exchange rates `numeric(12,4)`, model costs `numeric(12,6)`), never float, never unscaled `numeric` (sums stop adding up).
- An explicit sign CHECK on every money column; the sign never carries meaning (a refund is a kind, with a positive amount).
- Rounding happens explicitly in code (the database rounds silently on insert).
- Money never goes through a JavaScript `number`: strings end to end, arithmetic in SQL or a decimal library.

## 6. Currency

- If the business sells in one currency: put it **in the column name** (`total_ars`) and give a `currency` column only to the place where two currencies are real (payments). The cross-currency rule is then checked **in the row** (`(currency = 'ARS') = (fx_rate IS NULL)`), and the converted amount is a **generated column**.
- Currency codes as ISO 4217 (an accepted exception to lowercase values).

## 7. Foreign keys

- `ON DELETE RESTRICT` by default, always written. `CASCADE` only for true composition (the child means nothing without the parent and has no value of its own). `SET NULL` for optional links, possibly per column (`ON DELETE SET NULL (col)` on a composite FK, PG15+).
- An index on every FK unless another index already starts with those columns.
- **Two paths to the same parent → composite FK** that forces them to agree (sale → conversation → client and sale → client).
- Explicit names `<table>_<column>_fkey`.

## 8. Soft delete

- Avoid a generic `deleted_at` filtered everywhere. Each table that needs a lifecycle gets **one column with a business name** (`deactivated_at`, `archived_at`, `purged_at`), filtered only in the selectors that need it. Never `is_active` and `deleted_at` together.
- Things without history to preserve (a note) are deleted physically.

## 9. Append-only tables

- **9a. Which are immutable.** Separate "never updated" (ledgers, histories, audit, versioned prompts) from "has no `updated_at`". Immutable tables get only `created_at`; errors are corrected with a new row (a reversal), never an edit.
- **9b. How it is enforced.** By privileges, **closed by default**: tables belong to an owner role used by migrations; the app role gets `SELECT, INSERT` through default privileges, and each mutable table asks for its `UPDATE`/`DELETE` (preferably per column) in its own migration. Tables written only by triggers get `REVOKE INSERT` from the app and a `SECURITY DEFINER` writer. The purge is a single `SECURITY DEFINER` function, the only door into immutable tables.

## 10. Extensions

- Only what a decision needs (for example `pg_trgm` and `unaccent` for search, `pg_stat_statements` for diagnosis). Prefer normalising on write over special types (lowercase emails with a CHECK instead of `citext`).
- `pg_stat_statements` needs `shared_preload_libraries` and a superuser in the bootstrap.

## 11. Queue and events (if the project uses them)

- A Postgres-backed queue (Graphile Worker or similar) keeps its own schema; migrate it in the deploy as the owner role, not at app start; the ORM's schema filter must ignore it.
- `LISTEN/NOTIFY`: emitted by triggers (every writer is covered), payload with **ids only** (8000-byte limit), the listener on a dedicated connection (not through a transaction pooler), and the UI treats it as a hint: re-fetch on reconnect.

## Also decide early, if they apply

- **Who the actor is.** Transaction-local settings (`set_config('app.actor_kind', …, true)`, `app.actor_user_id`) read by triggers; **fail closed**: a write that does not declare its actor raises.
- **Where configuration lives.** Business settings in a table with a code catalog (schema, safe default, description), seeded at startup with `ON CONFLICT DO NOTHING`, history written by a trigger; technical parameters in environment variables; no magic constants.
- **The global lock order** (for example parent → child: conversation → client → sale), written down before the first trigger that locks anything.
