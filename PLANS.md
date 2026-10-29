# Engineering execution guide

This is an execution protocol, **not a replacement project plan**. Current authorization is
HARNESS-ONLY: local documentation/tooling, no application edits, org access, deployment or Git writes.

## Read in order

1. [Agent rules](AGENTS.md), then [project handoff](NORTHGATE_PROJECT_HANDOFF.md).
2. [Master plan](DEMO_ORG_MASTER_PLAN.md) for intent and [backlog](DEMO_ORG_BACKLOG.md) for IDs/order.
3. [Current UAT register](evidence/UAT/FULL_PROJECT_2026-10-28/UAT_REGISTER.md), including later
   appendices and raw receipts. Latest scoped evidence supersedes stale status headers, not original criteria.
4. [Governance](docs/GOVERNANCE.md), [technical debt](docs/TECH_DEBT.md),
   [architecture index](docs/architecture/OVERVIEW.md), [decision index](docs/decisions/STATUS.md).
5. [Baseline](harness/BASELINE.md), [regression matrix](harness/REGRESSION_MATRIX.md) and existing
   [UAT orchestration](docs/planning/UAT_ORCHESTRATION.md).

## Bounded work protocol

1. **Investigate read-only:** capture Git status including index/untracked files; read applicable
   decisions and the existing defect evidence. Identify the backlog ID and exact acceptance criteria.
2. **Plan local changes:** record allowed files, excluded behavior, baseline hashes/snapshot,
   dependencies, risk, focused tests and stop conditions in a copy of the
   [run template](harness/RUN_TEMPLATE.md). Obtain scope approval before application work.
3. **Edit locally:** smallest safe change, preserving pre-existing edits. Never use HEAD as the
   sole before-state in a dirty tree. Never repair data/configuration to satisfy a test.
4. **Validate locally:** fast first, then affected focused checks. Full local mode is optional;
    reuse unchanged, applicable receipts with date/scope instead of repeating expensive suites.
    `check.sh` fingerprints harness files and the selected checks' required inputs before/after
    execution. Unrelated concurrent drift is informational, not corruption; required-input drift
    invalidates the affected run. Do not pause other workstreams or infer writer attribution.
5. **Validate server-side:** separate approval for exact ng-demo identity, tests/manifest and test
   fixture/result effects; no ng-dev access. Dry-run is not deployment permission. No server action
   is implemented by `harness/check.sh`.
6. **Deploy/operate:** separate explicit owner approval for deployment, data, permissions,
   publication, activation, jobs or browser writes. Use reviewed `force-app/` source and scoped
   manifests, never blanket deployment of this tree. Out of scope for this retrofit.
7. **Git operations:** review task-only diff against captured baseline; explicit approval for
   staging/commit/tag and push. Never stage unrelated files. No Git writes in this retrofit.
8. **Close:** raw output, CONFIRMED/REFUTED claims, SKIPPED checks/reasons, assumptions, scoped diff,
    preserved work and unresolved acceptance. Stop/escalate unexpected failures without retry loops.
    For local edit preservation, compare a pre-edit content snapshot with reviewed, exact intended
    harness hashes using `harness/preservation.py edits`; do not assert whole-tree equality.

## Next work, not authorized here

Follow the current register's ordered owner decisions: bounded test-reliability work for D01/D02
and isolated D03 verification, with D04 notification-contract diagnosis separate. Obtain approval
before test edits/reruns; do not reopen completed CP2 behavior. D06/D07 portal functionality,
canonical D05 assets and D09 persona readiness remain gated. Vehicle Studio is only a future
proposal in the existing backlog; Staff Workspace planning needs its own owner scope.
