# Message format

Write in the owner's language. Plain words, no internal jargon the owner did not use first. Tables for options, bullets for rules, small SQL fragments only for what is being decided. One screen per message.

There are four kinds of message. The examples are from a real session (a CRM with a WhatsApp bot), translated.

## 1. Topic

```
Recorded as decision 21.                              ← closing line of the previous topic, if any

---

**`settings`, case 1: default values**                ← table or area, case number, topic

The code catalog already has a default for each key.  ← context: 2 to 5 lines, only what the
The question is what lives in the database.              decision needs

| | A. Seed in migrations | B. Database holds only overrides | C. App fills what is missing at startup |
|---|---|---|---|
| How | … | … | … |
| New key | Code + migration | Code only | Code only |
| If a default changes in code | No effect on existing rows | **Silently changes production** | No effect on existing rows |

**I recommend C:**
- The database always shows the real value…            ← the details that make the option work
- A deploy never changes a stored value silently…

**Why**, according to the skill:                        ← the rule, quoted
- query-patterns, "Insert-or-Ignore": *"ON CONFLICT DO NOTHING"*…
- C versus B is not covered by the skill; it rests on your rule *"Explicit over implicit"*.

Shall we close the defaults with C?                     ← one closing question, naming the option
```

Rules for the topic message:

- The comparison rows are the consequences that matter for this decision, not a generic pros/cons list.
- Bold the consequence that decides it (the silent production change, the deadlock, the lost message).
- If the topic depends on someone else, the recommendation says "provisional" and names the question added to their list.
- If closing the topic reopens an earlier decision, say which one and how before asking.

## 2. Close and continue

When the owner says OK, the next message starts by confirming what was recorded, then moves on:

```
Recorded as decision 47. **`conversations` is closed.** The tables that reference it are
not closed yet, so the impact check happens when each of them closes.

---

**Next: `messages`** …
```

For a big table or a domain, the first message is the **agenda**: the list of cases in order, one line each, and "shall I start with the columns?".

## 3. Reviewer triage

After a test run and a reviewer pass:

```
I wrote the domain DDL in [ddl/03-conversations.sql](…) and loaded it in a throwaway
PostgreSQL 18: <what was exercised, as a short list with the results>.

The reviewer found no critical issues.

**Look at the domain as a whole:** <duplicated facts or alternative paths, or "none found">.

| # | Severity | Finding (reproduced) | Fix |
|---|---|---|---|
| 1 | High | A deadlock between … | … |
| 2 | Medium | … | … |

Shall I apply all of them? Then I close the domain and the next one is X.
```

- Separate **mechanical fixes** ("applied unless you object") from findings with **design weight** (presented as a normal topic, with options).
- Say what you dropped or disagree with, and why ("I leave this as is: …").
- Spot-check surprising findings before including them.
- If the reviewer did something outside the rules (downloaded an image), say it here.

## 4. Delegation report

When the owner delegated ("close 3, 6 and 8 yourself and give me the report"):

```
Applied in the DDL and recorded in §12 (decision 27). How I closed the three you delegated:

| # | Finding | How I closed it | Why |
|---|---|---|---|
| 3 | … | … | … |
```

Then continue with the next topic in the same message only if the report is short; otherwise ask.

## Small things that matter

- Number every decision; the owner refers to them later ("does this contradict 44?").
- When you correct a mistake of your own ("I said it was recorded and it was not"), say it in one line, fix it, move on.
- Links to files the owner may open: relative markdown links.
- No emojis unless the owner uses them; status markers in the document are fine (✅ 🔁 ⏳ ❌ 🆕 ⚠).
