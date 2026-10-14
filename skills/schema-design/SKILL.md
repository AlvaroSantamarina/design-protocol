---
name: schema-design
description: Design or review a PostgreSQL schema with the owner as a guided conversation — one decision per message, options with a recommendation, an explicit OK before anything is recorded — ending in a numbered decision log and DDL that is tested in a throwaway database and reviewed per domain and as a whole. Use when the owner wants to design a database from notes or requirements, re-validate an existing design table by table, or says "let's review the schema".
---

# Schema design

Goal: the owner **understands and decides** every part of the schema, and the session ends with three things in files, not in this conversation:

1. a design document with a numbered **decision log** (every decision, its reason and the rule it cites);
2. **DDL per domain** that loads cleanly and was exercised as the real roles;
3. a **flows script** that walks the main business flows end to end and fails loudly when an invariant breaks.

This is a conversation, not a delivery. Never design the whole schema in one go.

Read these before the first message, and follow them for the whole session:

- `references/protocol.md` — the rules of the conversation. **Non-negotiable.**
- `references/message-format.md` — what each kind of message looks like.
- `references/conventions.md` — the cross-cutting topics and their starting recommendations.
- `references/checklist.md` — the per-table checklist and the PostgreSQL pitfalls.
- `references/testing.md` — how the DDL is proven.

Templates live in `${CLAUDE_PLUGIN_ROOT}/templates/`.

If a PostgreSQL best-practices skill is available (for example `postgres-best-practices`), consult it before every recommendation and cite the section that applies. If none is available, cite the PostgreSQL documentation or the owner's own rules, and say when a recommendation rests on judgement rather than a rule.

## 0. Set up the document

- Find the sources: notes, notebooks, an older design, the decisions file, the owner's coding rules. **Sources are not truth**: decisions weeks old get re-validated. Precedence (state it in the document): the owner's decisions file > this design document > older notes.
- Create the design document from `templates/design-doc.md` next to the project's decisions (for example `docs/schema-design.md`), with the session rules at the top so a later session can resume with the same behaviour.
- Fill §0 (inventory) from the sources: every table, its domain and a status marker. Count them. Flag what the sources contradict.

## 1. First message: the map

Confirm what you read, then show **entities and relationships without columns**: a diagram (a mermaid `erDiagram` rendered as a widget if the client supports it; otherwise a compact text tree) with one-to-many, optional and soft references (no FK) drawn differently. Below it, list the structural observations the map reveals (two paths to the same parent, arrays of ids, references without FKs, data that belongs to the person versus the episode) — **flag them, do not decide them**. Wait for the OK.

## 2. Conventions, one topic at a time

Propose the order of the cross-cutting topics from `references/conventions.md` (each one is decided before any table), then start with the first. Each topic is one message in the topic format. Split a topic that does not fit one screen (4a, 4b…).

When all conventions are closed: look at them together for contradictions, then **turn them into the per-table checklist** (§11 of the document), each line citing its decision.

## 3. Domains, parents first

Propose the order of the domains so that a table is closed before the tables that reference it (identity → clients → conversations/orders → their children → cross-cutting). Then, for each table:

1. **Columns**: the source's list with the closed conventions already applied, what changes and why, and what you propose to remove (a duplicated fact, a column for a feature that is not in this version). Mark with 🔸 every column that has its own case.
2. **Cases**, one per message, in the order announced: lifecycle, who owns or writes what, idempotency, ordering, state combinations, guards, personal data and purge, indexes last.
3. **Impact**: when a table closes, check the tables that reference it and the ones already closed. If something has to reopen, reopen it explicitly and record the change on the old decision.

New requirements that appear mid-session (the owner brings one) are welcome: put them on the map, decide them with the same protocol, and say what they change.

## 4. Closing a domain

1. **Look at the domain as a whole**: a fact stored twice, two paths to the same parent, two tables saying the same thing.
2. **Write the DDL** for the closed tables (`templates/ddl-file.sql`), one file per domain, numbered in load order. Every constraint and trigger carries the decision number it implements.
3. **Prove it** (`references/testing.md`): load everything from scratch as the owner role, exercise the domain's cases as the application role, including the ones that must fail.
4. **Review it** with the `schema-reviewer` agent in domain mode, in the background if the client allows it.
5. **Triage** the findings (message format: reviewer triage): mechanical fixes listed to apply unless the owner objects; findings with design weight discussed one by one. Spot-check any surprising finding before passing it on.
6. Apply, reload, re-test, record the closing decision ("Domain X closed": the DDL file, the reviewer's numbers, each change).

## 5. Cross-cutting, after every domain

- **Roles and bootstrap**: one role per process with the minimum it needs; the bootstrap script (`templates/bootstrap.sql`) that creates roles, extensions, default privileges and the schema rules everything else relies on.
- **Purge** (personal-data deletion), if the product holds personal data: one function, one transaction, children first, the list of what is deleted, what is anonymised, what stays and why, and what lives outside the database (backups, third-party copies, local copies).

## 6. Close the session

1. **Flows script** (`templates/flows.sql`): the main business flows end to end on a clean database, each step as the role that would really run it, with `ASSERT`s on the invariants and the negative cases.
2. **Full-schema review** with `schema-reviewer` in full mode, in parallel with the flows script: what a per-domain review cannot see (cross-domain triggers and locks, deadlocks, purge coverage, privileges as a whole, the index set, conventions across files).
3. Triage, apply, run the flows again.
4. Update the project's decisions file and memory with where everything lives; list the open questions for other people and the pending items for future sessions, each with how it can be added later without breaking what was decided.

## Exit criteria

- Every table in the inventory is closed, out of this version with a reason, or pending with a provisional assumption.
- Every decision is in the log with its reason; nothing decided lives only in the conversation.
- The bootstrap and the DDL load from scratch with no errors, and the flows script passes as the real roles.
- The full-schema review has no open critical or high finding.
