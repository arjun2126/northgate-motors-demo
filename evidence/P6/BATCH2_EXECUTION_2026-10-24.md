# Phase 6 Batch 2 — local execution and check-only report

Status: locally implemented and check-only validated; **not deployed or owner-accepted**.
Target: `ng-demo`, `00Daj00001Ae3iWEAR`. No other org was accessed.

## Successful validation evidence

New-feature focused request: `0Afaj00000oyNGHCA2`.
```json
{"checkOnly":true,"numberComponentsDeployed":58,"numberComponentsTotal":58,"numberComponentErrors":0,"numberTestsCompleted":21,"numberTestsTotal":21,"numberTestErrors":0,"status":"Succeeded","success":true}
```
Final coordinated preservation request: **`0Afaj00000oyOkDCAU`**, completed
2026-10-24T10:54:12Z.
```json
{"checkOnly":true,"numberComponentsDeployed":58,"numberComponentsTotal":58,"numberComponentErrors":0,"numberTestsCompleted":108,"numberTestsTotal":108,"numberTestErrors":0,"status":"Succeeded","success":true}
```
Returned componentFailures, test failures, codeCoverageWarnings and warnings arrays were empty.
All intentionally selected local regression test sources were included in
`manifest/p6-batch2-check.xml`; Salesforce reported existing regression classes unchanged.
Component "Created" states in these check-only results are simulated, not live deployment evidence.

## Actual test scope

21 new tests: VehicleServiceHistoryControllerTest (3), LoyaltyLedgerServiceTest (4),
LoyaltyAccrualServiceTest (5), LoyaltyAccrualBatchTest (1), LoyaltyTierEvalBatchTest (3),
Loyalty_ExpiryBatchTest (2), RedemptionServiceTest (3).

87 preservation tests: existing Batch 1 suites (33); LoyaltyEnrolmentServiceTest (4),
DeliveryCloseServiceTest (9), DeliveryCompletionGuardTest (4), QuotePricingServiceTest (23),
QuoteBuilderControllerTest (14). ExecutiveServiceMetricsPublisherTest is included in the
33 Batch 1 tests, not counted again. All passed in the final request.

Behavior asserted: configured point math/flooring; 200 sources with bounded query count;
replay/no additional DML; posted-source mismatch; pre-cutoff/warranty/uncompleted/missing-member
exclusions; sale idempotency per Opportunity despite duplicate deliveries; real member numeric
failure rolls back credit; managed edit/deletion/creation denial; partial-success legacy update
survives managed-row rejection; tier boundaries, next tier, default grandfathering and configurable
downgrade; operator custom permission plus USER_MODE access; overdraft/changed-request denial;
multi-lot redemption and real rollback of both debit/lot writes; partial redemption followed by
expiry and rerun; historical ledger isolation; Toronto midnight, summer offset and both repeated
fall-back hours; current/prior Vehicle history, keyset pagination, private visits/Cases and
non-admin denied access. No SeeAllData or live source data was used.

## Actual new Apex coverage

Raw numLocations / numLocationsNotCovered pairs from the final response:

| Component | Locations | Not covered | Coverage |
|---|---:|---:|---:|
| LoyaltyLedgerService | 208 | 2 | 99.04% |
| LoyaltyAccrualService | 31 | 2 | 93.55% |
| LoyaltyAccrualBatch | 11 | 0 | 100% |
| LoyaltyTierEvalBatch | 7 | 0 | 100% |
| Loyalty_ExpiryBatch | 7 | 0 | 100% |
| RedemptionService | 11 | 0 | 100% |
| VehicleServiceHistoryController | 37 | 0 | 100% |
| LoyaltyMemberTrigger | 3 | 0 | 100% |
| LoyaltyTransactionTrigger | 3 | 0 | 100% |

Scheduler tests invoke delegates in test isolation, assert a BatchApex job was queued and no
CronTrigger created. Batch start/execute/finish paths are exercised directly. They do not prove
a scheduled production run or async propagation of test configuration: the real program stays
inactive. User-facing LWCs compiled in Salesforce; no Jest framework was installed. Browser,
keyboard/modal, refresh, crypto-token and activation acceptance remain pending.

## Narrow fixes identified during check-only execution

- `0Afaj00000oyLkjCAE`: metadata/compile failures, zero tests. Self-lookup Restrict is unsupported;
  use SetNull with managed-transaction deletion guarded in Apex. Corrected runAs User variables,
  added required action optionsCreateFeedItem. Dependent Apex errors then cleared.
- `0Afaj00000oyMGzCAM`: only optional native detail component failed. Removed it rather than
  continuing component-name guesses. New page is highlights plus history only, unactivated;
  existing Vehicle pages/photos/details remain untouched. Review composition before assignment.
- `0Afaj00000oyMP3CAM`: all 58 components compiled; 21 tests, 16 failed. Internal event-lookup
  generated-bind error and inaccessible new assertion fields. Materialized lookup and explicit
  SYSTEM_MODE on internal ledger/assertion queries; UI queries remain USER_MODE.
- `0Afaj00000oyBlPCAU`: 18/21 passed; two batch selectors required the same explicit internal
  system mode. The partial-save fixture then failed on non-editable Loyalty_Member master-detail
  field, not guard policy.
- `0Afaj00000oyN4zCAE`: targeted four-test diagnostic identified the exact master-detail error.
  Sparse Id/Points update fixed the fixture without bypassing security or changing assertions.
- `0Afaj00000oyNGHCA2`: 21/21 passed. `0Afaj00000oyOkDCAU`: 108/108 passed.

No failed validation was resubmitted without an identified source/fixture correction. No actual
deployment was attempted. No live balance, ledger, configuration or assignment was changed.

## Exact source boundary

Read-only local validator passed for 90 selected source files including the manifest. Captured
hashes are in `BATCH2_SOURCE_SNAPSHOT_2026-10-24.json`; converted metadata snapshot is in
`BATCH2_SOURCE_ARCHIVE_2026-10-24/`. No selected source edits followed final validation.
These were captured after the validation result in the same session, not independently extracted
from Salesforce's stored ZIP. Future Quick Deploy must use the approved stored request.
Package SHA-256: `752c88415acce4cfd65fb33711568bd0a987349a8f203617edeb997e65e6e49d`.

Paths are relative to `force-app/main/default/`. Every listed class/trigger has its matching
metadata companion. Existing regression source was included unchanged and is not an edit.

- New classes: LoyaltyLedgerService, LoyaltyAccrualService, LoyaltyAccrualBatch,
  LoyaltyTierEvalBatch, Loyalty_ExpiryBatch, RedemptionService, VehicleServiceHistoryController.
- New tests: each corresponding Test class above; shared isolated fixture LoyaltyBatch2TestData.
- New triggers: LoyaltyMemberTrigger, LoyaltyTransactionTrigger.
- New LWC bundles: `lwc/vehicleServiceHistory/vehicleServiceHistory.{js,html,js-meta.xml}` and
  `lwc/loyaltyRedemption/loyaltyRedemption.{js,html,js-meta.xml}`.
- New page: `flexipages/NG_Vehicle_Service_History.flexipage-meta.xml`.
- New action: `quickActions/Loyalty_Member__c.Redeem_Points.quickAction-meta.xml`.
- New permission metadata: `customPermissions/Redeem_Loyalty_Points.customPermission-meta.xml`,
  `permissionsets/PS_Loyalty_Operator.permissionset-meta.xml`,
  `permissionsets/PS_Vehicle_Service_History.permissionset-meta.xml`. No live assignment.
- New member fields: `objects/Loyalty_Member__c/fields/{Managed_From__c,Previous_Tier__c,Tier_Changed_On__c}.field-meta.xml`.
- New transaction fields: `objects/Loyalty_Transaction__c/fields/{Event_Key__c,Source_Spend__c,Remaining_Points__c,Source_Accrual__c,Request_Key__c,Applied_Rate__c,Applied_Multiplier__c,Applied_Tier__c}.field-meta.xml`.
- Only edited existing feature metadata: `objects/Loyalty_Transaction__c/fields/Reason__c.field-meta.xml`,
  adding Service_Redemption while preserving all existing values.
- New `objects/Loyalty_Program__mdt/Loyalty_Program__mdt.object-meta.xml` and its six field files:
  Is_Active, Eligible_From, Service_Points_Per_CAD, Sale_Points_Per_CAD, Redemption_Value,
  Allow_Downgrades (all API names have __c suffix).
- Five new records: `customMetadata/Loyalty_Program.Default.md-meta.xml` and
  `customMetadata/Loyalty_Tier.{Bronze,Silver,Gold,Platinum}.md-meta.xml`.
- Manifest `manifest/p6-batch2-check.xml`; read-only local package validator
  `scripts/tests/check_p6_batch2_package.py`; this report and scoped source archive.
- Documentation: `docs/planning/P6_BATCH2_IMPLEMENTATION_PLAN_2026-10-24.md`,
  `docs/planning/SERVICE_VISIT_DATE_FILTER_PLAN_2026-10-24.md`, project handoff and backlog.

## Provisional decisions and security boundary

See the plan's Overnight local execution policy. Defaults are a demonstration proposal, not
final owner monetary-policy acceptance. Service 1 point/CAD; sale 0.10 point/CAD; floor after
multiplier; CAD 0.01/point display-only. Tiers: Bronze 0/1/365, Silver 5000/1.25/365,
Gold 25000/1.5/540, Platinum 50000/2/730 (threshold/multiplier/days). Default allows upgrades
only; downgrade is metadata-controlled and tested. Cutoff is provisionally 2026-10-25T04:00:00Z.
Program Is_Active remains false. First posting marks only the affected membership managed.

Private write authorization exists only around validated all-or-none service DML, with savepoint
rollback and finally reset. SYSTEM_MODE is restricted to internal ledger/maintenance reads and
writes. The only remote writer requires Redeem_Loyalty_Points and USER_MODE-readable member
fields before elevated mutation; the non-admin operator test has no direct member Edit.
No public setter grants the internal authorization. Existing trusted trigger-bypass convention
is preserved, but custom validation bypass does not skip engine overdraft checks. Managed rows
cannot be directly modified/deleted/reparented through ordinary DML. Historical unmanaged
transactions remain editable under existing access and are not treated as redeemable lots.

## Remaining review / operating gates

- Owner reviews provisional economics, thresholds, cutover and operator choice before deployment
  or any later activation. Keep program inactive when first deploying unless separately approved.
- No existing loyalty balance/history was reconciled or assigned invented provenance. Historical
  null spend/zero balances and transaction mismatch are deliberately preserved.
- No live scheduler, batch, expiry, reconciliation, redemption, page/action placement or permission
  assignment was executed. Actual licensed Service browser and multi-session contention remain
  unverified. Tests assert locks/atomic outcomes, not universal concurrency safety.
- Vehicle linked-Case discovery reads accessible visit links without truncation; like lot loading,
  it is subject to Apex query-row limits at substantially larger data volumes. There is no silent
  completeness cutoff. New page does not replace/activate existing Vehicle record pages.
- Accrual is eventual, using current Completed state and source-created cutoff. It excludes older
  open sources completed after rollout, and does not infer payment or actual completion time.
- Date-filter item is configuration-only documentation, not a deployed picker: exact native
  Calendar owner steps and Toronto limitations are in the date-filter plan. No All-view changes.
- Batch 1 controlled capacity/intake run is prior evidence, not repeated overnight; P6-03 and
  overall Batch 1 live/browser acceptance remain pending. No Batch 3 work started.

Deployment approval scope, if granted later: only the reviewed Batch 2 manifest and stored
successful validation payload, with inactive program. Activation, assignments, schedules,
record/balance changes and browser/data acceptance are separate explicit approvals.
