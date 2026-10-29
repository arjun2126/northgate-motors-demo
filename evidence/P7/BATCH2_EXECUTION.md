# Phase 7 Batch 2 — implementation and check-only evidence

**Subsequent P7-12 update:** the owner enabled Sales Territories. Read-only re-verification on
2026-10-26 confirms the feature and all four objects are accessible; the earlier capability
blocker below is historical. No territory configuration/assignments exist, and implementation/
activation remain unauthorized. See `P7_12_READ_ONLY_REVERIFICATION.md`, handoff §40. Existing
Batch 2 code, exact deployment scope and successful tests were not reopened or rerun.

## Status and authority

Owner authorized P7-07–P7-12 local implementation, read-only dependency checks, isolated tests
and scoped check-only validation against ng-demo `00Daj00001Ae3iWEAR`. No actual deployment,
persistent business-record/configuration changes, assignments, scheduling or Git staging/
commit/push occurred. No ng-dev access. UTC completion is October 26; Phase 6's formal
October 24 owner acceptance date is unchanged.

Current outcome: P7-07/P7-08 source is implemented and validated, P7-09/P7-10 documentation is
complete, P7-11 has a runnable administrative audit with native/browser reader acceptance still
open, and P7-12 is blocked at native capability. This is not six accepted/deployed blocks.

## Actual functionality by block

| Block | Implemented behavior | Acceptance limit |
|---|---|---|
| P7-07 | One local entry trigger each for Lead, Vehicle and Test_Drive routes through a dedicated handler. Lead conversion checks/seed cleanup, routing, Vehicle VIN/reservation/counters/event ordering and drive validation/follow-up/counters are preserved. Converted seed cleanup uses three bulk updates; lane resolution is reused per rooftop per invocation. | Local/check-only only; the live org still has the original seven entry points until an approved atomic replacement/removal deployment. |
| P7-08 | Explicitly invoked Queueable reconciles Vehicles_On_Hand for 1–200 selected rooftops through existing VehicleCounters semantics. Counts include every status; empty rooftops reset to zero. Age remains its existing formula. | Requires existing Bypass_Automation plus Vehicle Read and Rooftop/counter Edit. Sharing is retained; a maintenance operator must have complete inventory visibility for authoritative counts. No public controller, grant, automatic enqueue, scheduling, retry chain or live reconciliation. |
| P7-09 | Governance pack covers names, contexts/bypasses, review, persona checks, deployment/evidence boundaries and definition of done. Minimal root README and backlog reference it. | Full release/presentation README remains P7-20. |
| P7-10 | Existing debt ledger is extended/classified, including historical slot proposal versus accepted daily capacity, provenance, cache/throughput/history limits, events, access and release exceptions. | No accepted limitation is silently repaired or removed. |
| P7-11 | Read-only CLI/JSON audit of assignments, profiles/roles, groups and group members; honest unassigned candidates and observation limits. | Administrator report runs; native Report Builder/operational reader/browser screenshot are not verified. No permission is proven unused or automatically revoked. |
| P7-12 | Native capability checked before metadata design. | All four required native territory objects are absent from the current API inventory. No territory model/type/rule metadata or Account assignments; owner capability disposition required. |

The governance checklist was applied: callers and pre-existing diffs inspected, bypass/security
contracts reviewed, exact removal/replacement scope checked, focused and affected regressions
run, and actual acceptance limits recorded. In particular:

- Lead's hierarchy-setting bypass remains unchanged. Its existing inFlight guard resets in
  finally; handlers add no run-once flag that could suppress partial-save retries/later saves.
- Converted seed cleanup retains its former trigger-owned system sharing context. It is not
  Aura-enabled or a user-facing API; routing remains in its existing with-sharing service.
- Vehicle's existing custom-permission/Test.isRunningTest before-context bypass is preserved,
  separately from the hierarchy bypass on after-context counters/events. This distinction is
  intentional preservation, not a newly unified bypass policy.
- Test-drive future-date validation always runs before the hierarchy bypass. Existing task,
  restricted-contact email and derived-cache behavior is unchanged. Neutral saves do not create
  duplicate completion tasks; partial saves retain successful-row follow-ups.
- Existing counter definitions are not expanded: no nonexistent aged-rooftop field, no loyalty
  reconciliation, no TestDriveCounters definition rewrite and no formula write.

## Validation commands and results

Local exact-scope check:

```sh
python3 scripts/tests/check_p7_batch2.py
```

CONFIRMED — raw output excerpts:

```json
{"status":"PASS","replacementComponents":10,"sourceFileCount":20,"inventoryAge":"Existing native formula; no field write","automaticMaintenanceEnqueue":false}
```

The fixed check-only runner is `python3 scripts/tests/validate_p7_batch2.py`. It confirms the
Organization ID and executes this exact scope with 33 explicitly named test classes:

```sh
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-batch2-check.xml --pre-destructive-changes manifest/p7-batch2-destructive.xml --test-level RunSpecifiedTests --tests P7TriggerArchitectureTest InventoryReconciliationJobTest LeadRoutingHandlerTest LeadConvertGuardTest LeadEnrichRooftopServiceTest LeadRoundRobinTest VehicleReservationGuardTest VehicleReservationEventPublisherTest InventoryGalleryControllerTest TestDriveBookingGuardTest TestDriveFollowUpTest OpportunityCalculatorControllerTest VinDecoderServiceTest PaymentCalculatorServiceTest OpportunityStageStampTest QuotePricingServiceTest QuoteBuilderControllerTest QuoteSummaryControllerTest QuoteTradeInGuardTest QuoteTriggerEnforcementTest DiscountApprovalTest FinanceApplicationControllerTest FinancingStatusServiceTest FinancingApprovalTest FinancingFlsEnforcementTest DeliveryCompletionGuardTest DeliveryCloseServiceTest ServiceVisitCapacityGuardTest ServiceIntakeCaseServiceTest LoyaltyAccrualServiceTest RedemptionServiceTest ConsentGateServiceTest CaseMilestoneServiceTest --wait 10 --json
```

CONFIRMED — raw final result projection:

```json
{
  "exitCode": 0,
  "id": "0Afaj00000p7GCLCA2",
  "status": "Succeeded",
  "checkOnly": true,
  "numberComponentsDeployed": 14,
  "numberComponentsTotal": 14,
  "numberComponentErrors": 0,
  "numberTestsCompleted": 235,
  "numberTestsTotal": 235,
  "numberTestErrors": 0,
  "componentFailures": [],
  "testFailures": [],
  "warnings": []
}
```

Completed `2026-10-26T00:18:31.000Z`. Salesforce's 14 component successes comprise ten
replacement components plus four validated removals, not fourteen persisted changes.
All 235 methods passed: 12 new methods and 223 deployed regressions across 33 classes.
These are Apex tests executed within check-only, not a separate standalone test job.
Affected CP2 Quote Builder/Summary/pricing/trade-in/enforcement, payment/discount, finance
security/approval/status, delivery, Lead, booking, reservation/gallery/event/VIN and selected
Phase 6 capacity/intake/loyalty/redemption/consent/SLA regressions passed. This is not all
historical tests or fresh browser/operational acceptance of every Phase 1–6 workflow.

CONFIRMED — raw coverage projection:

```json
[
  {"name":"LeadTriggerHandler","covered":35,"total":35},
  {"name":"VehicleTriggerHandler","covered":20,"total":20},
  {"name":"TestDriveTriggerHandler","covered":11,"total":11},
  {"name":"InventoryReconciliationJob","covered":20,"total":20},
  {"name":"LeadRoutingHandler","covered":89,"total":97},
  {"name":"LeadRoutingTrigger","covered":1,"total":1},
  {"name":"VehicleTrigger","covered":1,"total":1},
  {"name":"TestDriveTrigger","covered":1,"total":1}
]
```

Evidence: `BATCH2_CHECK_ONLY.json`, job-specific JSON, `BATCH2_CHECK_ONLY_COMMAND.json`,
`BATCH2_LOCAL_SCOPE_CHECK.json`, `BATCH2_VALIDATION_SUMMARY.json`, `trigger_tests.txt` and
`queueable.txt`. CLI result fields are preserved except personal creator display name and
private absolute machine paths, which are omitted/normalized from generated evidence.

The final report command `python3 scripts/tests/report_p7_batch2.py` verifies the exact
component set, saved passing tests and all twenty selected source hashes, then reads back the
seven original live trigger entries as Active. Thus no removal/replacement was deployed.
Scoped `git diff --check` returned no output. The local checker additionally checks whitespace
in new/untracked source/docs/scripts and confirms the README/backlog governance references.

CONFIRMED — raw summary excerpts:

```json
{"status":"PASS","testsPassed":235,"testClasses":33,"newTestsPassed":12,"selectedSourceHashesUnchanged":20,"actualDeploymentPerformed":false}
```

## Failure and owner-approved correction history

1. The new audit script initially failed locally with `SyntaxError: '[' was never closed`.
   Owner approved the one-bracket correction. Its subsequent read-only audit succeeded.
2. Initial check-only `0Afaj00000p77aUCAQ` compiled all fourteen metadata changes but failed
   `P7TriggerArchitectureTest.convertedSeedCleanupIsBulkAndTransitionOnly`, line 63, during
   fixture insertion. Exact error:

   ```text
   System.DmlException: Insert failed. First exception on row 1; first error: DUPLICATE_VALUE, duplicate value found: <unknown> duplicates value on record with id: <unknown>: []
   ```

   Owner explicitly approved bounded source-constraint inspection and fixture correction if
   confirmed. Account, Contact and Opportunity Seed_Tag metadata each has `<unique>true</unique>`.
   The new fixture mistakenly repeated one tag for 200 records of each type. Tags now have the
   row index suffix. Assertions and production implementation were not weakened/changed.
   The same exact scope/tests then passed 235/235. Original failure is retained in
   `BATCH2_CHECK_ONLY_0Afaj00000p77aUCAQ.json`; no speculative retry loop occurred.

## Permission audit and territory gate

Run: `python3 scripts/tests/audit_p7_batch2.py`.

CONFIRMED — raw audit excerpts:

```json
{"permissionSetCount":180,"assignmentCount":31,"groupCount":26}
```

Eighteen project sets have no direct/generated assignment rows; five are group components.
This is not usage telemetry and does not establish unused effective permissions. No new access
or native report was deployed. Reader and reporting limits: `docs/security/P7_PERMISSION_AUDIT.md`.

CONFIRMED — raw territory excerpt:

```json
{"exposedObjects":[],"missingObjects":["ObjectTerritory2Association","Territory2","Territory2Model","Territory2Type"],"configurationChanges":0,"accountAssignments":0,"renderedTreeAcceptance":"NOT VERIFIED"}
```

Owner action: inspect ng-demo Setup > Territory Settings, confirm availability/enablement and
disposition P7-12 as deferred/unavailable or separately authorize the capability decision.
Do not enable territories, simulate a native tree or assign Accounts under this authorization.
See `BATCH2_TERRITORY_CAPABILITY.md` and the raw audit JSON.

## Exact future deployment scope requiring separate approval

`manifest/p7-batch2-check.xml` — ten components:

- Six new Apex classes: LeadTriggerHandler, VehicleTriggerHandler, TestDriveTriggerHandler,
  InventoryReconciliationJob, P7TriggerArchitectureTest and InventoryReconciliationJobTest.
- One modified Apex class: LeadRoutingHandler (per-invocation lane-query reuse).
- Three modified triggers: LeadRoutingTrigger, VehicleTrigger and TestDriveTrigger.

`manifest/p7-batch2-destructive.xml` — four ApexTrigger removals:

- LeadBeforeConvertGuard
- LeadAfterConvertSeedBlock
- VehicleCounterTrigger
- TestDriveFollowupTrigger

Approve replacements and removals together, atomically; deploying replacements alone would
duplicate side effects while old triggers remain. No Quote/finance/delivery/loyalty/service
component, permission/report/territory metadata, static resource, page or setting is selected.
Documentation, audit/check scripts and evidence are local deliverables, not Salesforce deployment
components. No grant or production enqueue is requested/implied by metadata approval.

Batch 1 browser/gallery/event acceptance, operational access/page placement and VIN credentials
remain deferred. Batch 1 is not owner-accepted. Phase 6 acceptance and all P6-E01–E14 exceptions
remain intact. No later Phase 7 batch or Phase 8 implementation is included.
