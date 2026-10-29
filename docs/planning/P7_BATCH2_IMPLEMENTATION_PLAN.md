# Phase 7 Batch 2 — authorized local implementation and check-only plan

## Authorization and preserved baseline

Implement P7-07–P7-12 using the existing consolidated plan and backlog. Read-only queries,
isolated Apex tests and scoped check-only validation target ng-demo `00Daj00001Ae3iWEAR` only.
No actual deployment, business-record/configuration changes, grants, scheduling or Git release
actions are authorized. Preserve the pre-existing dirty tree and CP2/Phase 1–6 behavior.

Handoff §38 is the deployment baseline. Batch 1 browser/gallery/event acceptance, operational
access/page placement and VIN credentials remain deferred; Batch 1 is not owner-accepted.
Phase 6 acceptance and P6-E01–P6-E14 remain unchanged.

## Focused sequence and file scope

1. P7-09/P7-10: write `docs/GOVERNANCE.md`; update the existing `docs/TECH_DEBT.md` from actual
   services and accepted exception evidence. Reference governance from the backlog and a minimal
   root README; the full release/presentation README remains P7-20.
2. P7-07: retain LeadRoutingTrigger, VehicleTrigger and TestDriveTrigger as the single entry
   points for their objects. Route through LeadTriggerHandler, VehicleTriggerHandler and
   TestDriveTriggerHandler; remove the four redundant triggers through an explicit destructive
   manifest, atomically validated with the replacements. Preserve each existing bypass contract,
   including always-on test-drive future-date validation and Vehicle's distinct permission bypass.
   Bulkify converted seed-tag clearing and repeated Lead lane resolution where the 200-row path
   requires it. Keep existing recursion protection and transition predicates; no static run-once
   flag that suppresses partial-save retries or later valid saves.
3. P7-08: add a bounded, explicitly invoked inventory reconciliation Queueable and isolated tests.
   Reuse VehicleCounters' existing all-status rooftop count semantics; inventory age remains its
   native formula. Do not enqueue from a trigger, schedule, repair loyalty or run maintenance live.
4. P7-11/P7-12: collect read-only permission/group assignment inventory and native territory
   capability evidence. Distinguish unassigned candidates from proven unused permissions.
   Do not fabricate screenshots, enable territory settings, assign Accounts or widen sharing.
   Build territory metadata only when capability and the existing plan justify it; explicitly
   record any owner-dependent acceptance gate.
5. Add focused 200-row/bypass/partial-save/re-entry and Queueable tests. Validate the exact
   replacement/destructive scope with targeted Apex tests plus affected Lead, Vehicle, test-drive,
   gallery/event and CP2 regressions. Record raw results and any failure without speculative retries.

## Deliverables and approval boundary

An exact Batch 2 manifest plus destructive manifest, selected source inventory, local checks,
check-only/test receipts, permission audit and capability disposition belong in `evidence/P7/`.
Update the handoff/backlog with implemented versus verified versus deferred acceptance.
Any future actual deployment must receive separate approval for both replacement and removal
components. No unrelated Quote, finance, delivery, service, loyalty or consent rewrite is included.
