# Schema design: <project>

Starting point for reviewing the database decision by decision. Sources: <notes, notebook, older design, decisions file>, read on <date>.

## Session rules (for Claude)

This is a **guided review**, not a delivery. The goal is that <owner> understands and decides each point.

1. Do not design the whole schema at once. No complete DDL before a domain closes.
2. One topic per message: the topic, up to 3 options with their consequences, the recommendation and why. Then stop and wait.
3. No step without an explicit OK. A topic closes when <owner> confirms it; only then is it recorded in §12.
4. Short messages; split a topic that does not fit one screen.
5. SQL only for what is being discussed, in small fragments.
6. If something depends on <business side / vendor>, say so, propose a provisional assumption and continue.
7. Before recommending, consult <the best-practices skill> and cite the rule that applies.

To keep the whole picture: the map first (§0 and a diagram); on closing each table, check the impact on the tables that reference it; on closing each domain, look for duplicated facts and alternative paths; at the end, walk the full flows and review the whole DDL.

## How to use this document

- **Source precedence:** <decisions file> > this document > older notes.
- **Order:** cross-cutting conventions (§1) first, then domain by domain.
- **Per table:** confirm columns → resolve the ⚠ and the cases → validate with the checklist (§11) → record in §12.
- **Status legend:** ✅ no known changes · 🔁 changes because of a decision · ⏳ depends on someone else · ❌ out of this version · 🆕 new table · ⚠ problem found in the source design.

---

## 0. Inventory

<N> tables. <What the sources say versus what the decisions changed.>

| Domain | Table | Status |
|---|---|---|
| | | |

---

## 1. Cross-cutting conventions (decide before any table)

| Topic | Source design | To decide / validate |
|---|---|---|
| PK | | |
| Names and language | | |
| Enums | | |
| Time | | |
| Money | | |
| Currency | | |
| FKs | | |
| Soft delete | | |
| Append-only | | |
| Extensions | | |
| Queue and events | | |

---

## 2… Domains

One section per domain. For each table:

### `<table>` <status>
**Source:** columns, indexes, rules as the source describes them.

**Cases to review:** one bullet per open question, ⚠ for problems found.

---

## 10. Cross-cutting security and personal data

Roles · purge (what is deleted, anonymised, kept, and what lives outside the database).

---

## 11. Per-table checklist

Filled when the conventions close; each line cites its decision. See the plugin's checklist.

---

## 12. Decision log

Filled as topics close. Record the row **before** announcing it.

| # | Table / topic | Decision | Reason |
|---|---|---|---|
| 1 | §1 PK | <the decision first, then the rules that go with it> | <the rule cited, quoted; the trade-off> |

When a later decision changes an earlier one: keep the old row, mark the changed text (~~struck~~ or "corrected by decision N"), and say so in the new row.

---

## 13. Glossary (business language → database)

| Business term | In the database | Note |
|---|---|---|

---

## 14. Pending for future sessions

| # | Topic | What is left | How it gets in without breaking what was decided |
|---|---|---|---|
