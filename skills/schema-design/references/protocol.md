# The protocol

The rules of the conversation. They hold for the whole session, including after a compaction (copy them into the design document's "Session rules" so a resumed session follows them too).

## The core loop

1. **One topic per message.** State the topic, give the context in a few lines, offer the options, recommend one, explain why, ask. Then **stop and wait**.
2. **At most three options**, each with its consequences in the same rows (how it works, what it costs, what breaks if a path forgets something). A table is usually the clearest way. Two options are fine; one option is not a choice — then say "here is the rule I propose" and ask for the OK.
3. **Always recommend.** "I recommend B" comes first, then the details that make it work (the rules that go with it, the edge cases it covers), then **Why**: cite the rule that applies — a section of the best-practices skill, the PostgreSQL docs, a decision already closed, or one of the owner's own rules (quote it). When no rule applies, say so and give the judgement.
4. **No step without an explicit OK.** A topic closes when the owner confirms it. Only then is it recorded.
5. **Record before you announce.** Write the decision row to the log first, then say "Recorded as decision N". Never say something is recorded, applied or tested unless the tool call that did it already ran in this turn. If you notice you claimed it earlier without doing it, say so plainly in the next message and fix it.
6. **Short messages.** If a topic needs more than one screen, split it (4a, 4b) and say what the next part will cover.
7. **SQL only for what is being discussed**, in small fragments. The complete DDL of a table is written when its domain closes, not before.

## Things that depend on other people

When a decision depends on the business side (the client, the owner's partner) or on a vendor, do not block:

- propose a **provisional assumption** that is cheap to change later (a CHECK list, a setting), mark it as provisional in the log;
- add the question to the project's question list for that person (numbered, plain language, one question per line, in the language and style they prefer);
- continue with the next topic.

## Owner behaviours to honour

- **Silence means agreement** — only if the owner set that rule. Then a proposal they did not object to is recorded as decided, and the rule itself is recorded as a decision.
- **Delegation.** When the owner says "close these yourself and give me the report", pick the best option for each, apply it, and report in the delegation format (what you chose and why, per item) so they can object to any of them.
- **Objections to the premise.** When the owner challenges an assumption (with evidence: fixtures, logs, a test), verify the evidence yourself, say what it changes, record the reopened decision explicitly (mark the old text, do not delete it), and replan the affected topics. Do not defend a decision because it was already made.
- **"Just do it" overrides.** If the owner chooses an option you did not recommend, or accepts a risk you flagged (privacy, cost), record their decision and the risk they accepted, without arguing again.
- **Out-of-band requests.** A requirement from another session or person mid-session ("can the enqueue use a job key?") is handled the same way: options, recommendation, OK, record, then apply and re-test.

## Integral view

The one-topic rhythm must not lose the whole picture:

- **Before the details:** the map of entities and relationships (no columns), and the order of topics, each announced before it starts.
- **Closing a table:** check the impact on the tables that reference it and on the ones already closed; reopen explicitly when needed.
- **Closing a domain:** look for a fact stored twice, two paths to the same parent, two tables that say the same thing.
- **At the end:** the flows walked over the whole schema, and a full-schema review.

## Hard limits

- **No downloads or installs without asking**: container images, extensions, packages. Using what is already on the machine is fine. Say it if a subagent did it anyway.
- **Never touch a real database.** Every test runs on a throwaway one (see `testing.md`).
- **Never publish, push or share** anything unless the owner asks.
- Personal data in examples and fixtures is fake.
