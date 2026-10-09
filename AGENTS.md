# AGENTS.md — Repository agent instructions

This file applies to **every agent working in this repository**, in every session.

## Working rules

- Do backlog items in order. Deploy from `force-app/` source; records are for data only.
- Validate before claiming success: dry-run, tests, and a check of the actual acceptance criteria.
- State what was verified and what was skipped. Do not describe unverified work as verified.
- Never touch `ng-demo`, other orgs, or Phase 3 work without explicit owner approval.
- Prefer the smallest safe change. Reuse existing patterns. Add no speculative abstraction.

## Escalation policy

**When blocked by an unexpected test failure, deployment failure, corrupted commands, mangled
identifiers, or an uncertain diagnosis: stop the affected work and ask the owner for help.**

Do **not** enter repeated speculative debugging loops or make unapproved corrective changes.
Do not patch a symptom, edit a test to force a pass, or work around an unclear failure.

When escalating, report:

1. **The exact error** — verbatim message, test/class/method name, and relevant IDs.
2. **Changes already made** — files touched and the diff intent.
3. **Last verified state** — the most recent known-good result and how it was verified.
4. **The specific manual action needed** — a concrete click or command for the owner.

Then wait for the owner's response before continuing that line of work. Independent,
non-blocked work may proceed.

## Rationale

A failed check is a signal to stop and understand, not to keep perturbing. Repeating attempts
against a corrupted or unclear signal wastes effort, risks unrelated damage, and hides the real
cause from the owner.
