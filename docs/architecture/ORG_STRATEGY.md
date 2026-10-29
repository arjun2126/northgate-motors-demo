# P7-13 — Northgate org and release strategy

## Actual execution model

The historical design describes a build/UAT org and a stable demo org. That history does not
authorize operating against the former. Current commands target only ng-demo
`00Daj00001Ae3iWEAR` (Developer Edition, IsSandbox=false). Never access ng-dev, create scratch
orgs, reclaim users or initialize another remote under this strategy.

Salesforce source lives in force-app; CSVs and import receipts describe data, not metadata.
There is no clean, reproducible release baseline yet: accepted work remains modified/untracked.
Preserve that tree and review exact selected files; do not infer remote freshness from cached
tracking refs or silently stage/commit/push it. Docs are not deployment authorization.

## Release transaction and validation

Use exact manifests and verify the actual org ID first. Validate intended member sets, source
hash continuity, affected tests and real acceptance criteria. Check-only and deployment are
separate actions. Developer Edition permits NoTestRun; reuse unchanged successful test evidence
when appropriate rather than describe an old run as new. Stop on unexpected failures.

Batch 2 is the concrete atomic-removal example: p7-batch2-check.xml selects ten application
components and p7-batch2-destructive.xml selects four obsolete triggers. The supported native
--pre-destructive-changes flag packages destructiveChangesPre.xml in the same transaction;
validation 0Afaj00000p7GCLCA2 covered both with 235/235 tests, and deployment 0Afaj00000p84KRCAY
installed/replaced ten components and removed four obsolete triggers atomically. Never deploy those replacements separately
while obsolete triggers still exist. Unrelated trigger bodies were verified unchanged.

Territory deployment 0Afaj00000p8GtRCAU is a separate six-component manifest. NG_Rooftops remains
Planning with zero Account/User associations and Read/None/None/None access. Deployment is not
activation, assignment or owner acceptance. Batch 3 has its own approval boundary and manifest.

## Data volume and archiving

This is a bounded dealership demo, not an LDV benchmark. Aggregates, keyset pagination and
bounded scopes already exist; governor/query-row and concurrency ceilings remain in TECH_DEBT
and the Phase 6 exception register. Preserve canonical/BAD fixtures, load-ledger receipts,
historical loyalty discrepancies and accepted report semantics. A strict DQ failure is evidence,
not permission to repair records or weaken the gate.

No archive/delete job exists or is activated. Future retention or LDV work must first specify
record ownership, relationships, legal/business retention, source-of-truth, restore testing and
actual measured limits; obtain approval before exports, storage/cost changes, deletes or jobs.
Do not add a second data model, index strategy or migration for speculative scale.

See GOVERNANCE.md, TECH_DEBT.md, the current handoff/backlog and scripts/test.sh. Batch 1 browser/
gallery/event acceptance, operational access/page placement and VIN credentials remain deferred.
Neither Batch 1 nor Batch 2 is owner-accepted by these deployment results.
