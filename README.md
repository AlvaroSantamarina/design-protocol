# design-protocol

Design a PostgreSQL schema with Claude Code **as a guided conversation**: one decision per message, options with their consequences, a recommendation that cites its rule, and an explicit OK before anything is recorded. The session ends with a numbered decision log, DDL per domain that was **loaded and exercised as the real roles** in a throwaway database, a flows script that walks the main business flows end to end, and two levels of review (per domain and the whole schema).

It came out of re-validating the schema of a real product (a CRM with a WhatsApp sales bot): 90 decisions, 28 tables, ten DDL files and a flows script, in one long session with one owner. This plugin packages the way that session worked so it can be repeated in other projects and other sessions — not automated, **standardized**.

> PostgreSQL-first. The protocol is general, but the conventions, the checklist and the pitfalls are PostgreSQL's (tested on 18).

## What it looks like

```
sources (notes, older design)          owner decides, one topic at a time
        │                                         │
   map of entities ──► conventions ──► domains, parents first ──► roles + purge ──► close
   (no columns)        (one by one)     per table: columns → cases → impact
                                        per domain: DDL → load + test → review → triage
                                                                                     │
                     design doc: inventory · conventions · checklist · decision log · glossary · pending
                     ddl/: bootstrap + one file per domain        tests/flows.sql (asserts, real roles)
```

A topic message looks like this:

```
**`settings`, case 1: default values**

The code catalog already has a default for each key. The question is what lives in the database.

| | A. Seed in migrations | B. Only overrides | C. App fills what is missing at startup |
|---|---|---|---|
| New key | Code + migration | Code only | Code only |
| A default changes in code | No effect | **Silently changes production** | No effect |

**I recommend C:** the database always shows the real value; a deploy never changes a stored value…

**Why:** query-patterns, "Insert-or-Ignore"… · your rule "explicit over implicit".

Shall we close the defaults with C?
```

## What is inside

| Piece | What it does |
|---|---|
| `skills/schema-design` | The walk: sources → map → conventions → domains → cross-cutting → close, with exit criteria. |
| `references/protocol.md` | The rules of the conversation: one topic per message, ≤3 options, always recommend and cite, explicit OK, **record before you announce**, provisional assumptions for what depends on others, delegation ("close these yourself and report"), objections to the premise, no downloads without asking. |
| `references/message-format.md` | The four messages: topic, close-and-continue, reviewer triage, delegation report. |
| `references/conventions.md` | The cross-cutting topics to decide before any table, each with options and the starting recommendation that held up (uuidv7, `timestamptz` vs `date`, money classes, currency in the column name, `RESTRICT` + composite FKs, lifecycle columns, immutability by privileges, fail-closed actor, lock order…). |
| `references/checklist.md` | The per-table checklist and **15 PostgreSQL pitfalls found by running the DDL** (triggers inheriting a definer's `search_path`, NULL in CHECK equalities, default privileges reaching views, generated columns in BEFORE triggers, deadlocks from inconsistent lock order…). |
| `references/testing.md` | How a domain is proven: throwaway database, load as the owner role, exercise as the real roles, negative cases, idempotency, the flows script. |
| `agents/schema-reviewer` | Reviews schema files (not a diff) in **domain** or **full** mode, reproduces findings in a local container, never pulls images, never re-litigates decisions. |
| `templates/` | The design document skeleton, a DDL file, the bootstrap, the flows script and `run-schema.sh` (start a container, bootstrap, load every file as the owner, run the flows, stop). |

## Install

```bash
claude plugin marketplace add AlvaroSantamarina/design-protocol
claude plugin install design-protocol@design-protocol
```

Or load it for one session: `claude --plugin-dir /path/to/design-protocol`.

Then ask for it: *"Let's design the database from these notes"*, or *"Let's review the schema table by table"*. A PostgreSQL best-practices skill, if you have one, is used as the source of the rules each recommendation cites.

## Principles

- **The owner decides; the model recommends.** Every question comes with options and a recommendation, and nothing is recorded without an OK.
- **Files, not chat.** Every decision lives in the log with its reason; a later session (or a compaction) loses nothing.
- **Prove it by running it.** The bugs that mattered were found by loading the DDL and exercising it as the real roles, not by reading it.
- **Verify, don't re-plan.** Reviews look for defects against the decisions, not for a different design.
- **Keep the whole picture.** The one-topic rhythm is anchored by the map at the start, the impact check per table, the look at each domain, and the full review at the end.

## Works with

[lanes](https://github.com/AlvaroSantamarina/lanes): its phase 0 (system design) says to design the data model decision by decision before any brief. This plugin is how.

## License

MIT
