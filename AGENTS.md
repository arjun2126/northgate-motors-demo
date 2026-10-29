# AGENTS.md — Repository agent instructions

This file applies to **every agent working in this repository**, in every session.

## Working rules

- Do backlog items in order. Deploy from `force-app/` source; records are for data only.
- Validate before claiming success: dry-run, tests, and a check of the actual acceptance criteria.
- State what was verified and what was skipped. Do not describe unverified work as verified.
- Never touch `ng-demo`, other orgs, or Phase 3 work without explicit owner approval.
- Prefer the smallest safe change. Reuse existing patterns. Add no speculative abstraction.

## Engineering harness (current operational rules)

- Start with `PLANS.md` and inspect `git status --short --branch` before edits. Never assume a
  clean tree: preserve existing tracked, deleted, untracked and staged work. Capture the scoped
  before-state; a diff against HEAD alone cannot distinguish this task from existing work.
- This working tree is intentionally shared by Harness Engineering, Owner Portal Expansion and
  UAT / Regression Closure. Do not require whole-tree equality or pause other workstreams.
  Use `harness/preservation.py` to separate exact intended harness edits, protected/required-input
  conflicts and informational unrelated drift. Writer attribution is unknown unless independently
  established. Required-input changes invalidate the affected result even when made legitimately;
  report that conflict without blaming a writer, silently ignoring it or auto-retrying tests.
- Preserve completed Phase 1–8 functionality without declaring all phases accepted. The current
  UAT register governs acceptance/defects; older planning headers and handoff snapshots can be stale.
- Protect CP2 pricing, one-Quote guard, signed premiums, primary-vehicle basis, rounding, approvals
  and historical records. Do not reopen closed P3-DEF-01 or reinterpret old create-only guidance
  as permission to create another Quote. See `docs/decisions/STATUS.md`.
- Never modify or access `ng-dev`, including via old CI instructions. Do not dispatch the existing
  ng-dev workflow. `ng-demo` access still requires explicit owner approval and verified org identity.
- Separate read-only investigation, local changes, local validation, server-side validation,
  deployment, operational/data changes and Git operations. Approval for one is not approval for another.
- Deployment and Git push always require explicit owner approval. Staging/commit/tag also require
  separate authorization; never stage unrelated files or use blanket staging on this dirty tree.
- Preserve CRUD/FLS, sharing, customer isolation and actual-persona negative tests. Never modify
  Salesforce records, configuration, permissions or fixtures merely to manufacture passing checks.
- Respect ratified architecture. Reconsider only with a demonstrated defect and a bounded owner
  decision; no speculative redesign, new application feature or abstraction in harness-only work.
- Run `bash harness/check.sh` for local checks; see `harness/REGRESSION_MATRIX.md` for focused/full
  local checks and separately gated Salesforce validation. PASS is scoped, SKIPPED is not PASS.
  Keep raw evidence and assumptions separate using `harness/RUN_TEMPLATE.md`; follow
  `harness/TRIAGE.md` on failure. The wrapper is a safety boundary, not a sandbox for other commands.

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

## Lessons learned

1. **Verify access as the actual persona** using `System.runAs` in Apex, never as admin. Admin context masks FLS/OWD gaps.
2. **Status, IsConverted and similar standard fields are not permissionable** — never add FLS for them; they inherit access from the parent object.
3. **A dashboard or report grouping by a lookup needs Read on the lookup's target object** (e.g., `Staff__c` for `Opportunity.Sales_Staff__c` groupings).
4. **Verify against the live org**, not just source, for sharing, folder, and dashboard settings. Source may not reflect live org state (e.g., folder shares, dashboard running user).
5. **Report only raw command output for verification**, and mark each claim `CONFIRMED` or `REFUTED`. No narrative summaries in place of evidence.
