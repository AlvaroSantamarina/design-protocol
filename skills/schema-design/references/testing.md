# Testing the schema

A design is not closed until it has been **loaded and exercised**. In practice the tests found the bugs the reviewers missed (a trigger that could not see its tables, a generated-column rule, an `INSERT` that skipped a state machine).

## The throwaway database

- Use a disposable PostgreSQL of the **same major version** as production, for example `docker run -d --rm -e POSTGRES_PASSWORD=x postgres:18-alpine`, with no published ports, stopped at the end of each run.
- **Ask before pulling an image** if it is not on the machine. If Docker is not available, say so and ask how the owner wants to test (a local server, a CI job).
- `templates/run-schema.sh` does the whole cycle: start, bootstrap, load every DDL file as the owner role, run the flows, stop.

## Load like production

1. Run the bootstrap as superuser (roles, database settings, extensions, default privileges).
2. Load each DDL file **as the owner role** (`SET ROLE <owner>;` prepended). Loading as superuser hides privilege bugs: default privileges only apply to objects the owner creates.
3. Exercise everything **as the role that would really do it** (the app, the webhook receiver, the read-only role). Test what must be **denied** too (`permission denied`, a CHECK violation, a trigger error).

## What to exercise per domain

- The happy path of each case decided in the domain.
- Every negative case a decision promised: the transition that must fail, the duplicate that must not insert, the field the automated actor must not overwrite, the row a role must not see.
- Idempotency: run the same write twice (a webhook, a job retry, a re-emitted event) and assert one row.
- Out-of-order input where the domain has it (statuses arriving late, events replayed).
- Writes from inside `SECURITY DEFINER` functions (purge, history writers): they run triggers with the definer's `search_path`.

## The flows script

`templates/flows.sql` is the closing test: the main business flows on a clean database, each step as the right role, with `ASSERT` blocks on the invariants. It is a file in the repo, run again after **every** schema change. Keep it readable: one `\echo` per flow, `ASSERT … , 'message in plain words'`.

Things a stub has to simulate (a queue's `add_job`, an external callback) get the **real signature** of the thing they replace, so the DDL that calls them does not change between the test and production. Say in the report what the stub cannot prove (for example, how the real queue behaves with a running job).

## Reviews

- **Domain mode**, when a domain closes: the `schema-reviewer` agent on that domain's file, with the previous files as context.
- **Full mode**, at the end: the reviewer on all files together, in parallel with the flows script.
- Give the reviewer the path of the decision log and tell it not to re-litigate decisions, only find defects. Tell it it may use a local image and must not pull one.
- Spot-check every surprising finding before passing it to the owner. Reviewers are usually right and sometimes confidently wrong.
