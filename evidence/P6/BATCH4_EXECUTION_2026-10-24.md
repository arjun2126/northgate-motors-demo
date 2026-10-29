# Phase 6 Batch 4 — local implementation and scoped validation

## Authorization and target

Owner authorized continuous local P6-13–P6-17 implementation, routine corrections, isolated
tests and exact check-only. No deployment, persistent records, assignments, Knowledge enablement
or publication, page activation, scheduling, destructive operations or Git publication.

CONFIRMED — raw target query output, `SELECT Id FROM Organization` on ng-demo:

```json
"Id": "00Daj00001Ae3iWEAR"
```

Read-only baseline retrieval: `09Saj00000mh1MzEAI`, with additional Case page/layout retrievals
`09Saj00000mgNz5EAE` and `09Saj00000mh29NEAQ`. Retrieved files are isolated under
`retrieved/p6_batch4_baseline/`, not merged into production source or the deployment package.
The initial external output-directory attempt was rejected before retrieval with
`OutputDirOutsideProjectError`; using an isolated directory inside the project resolved it.

## Implemented blocks and genuine prerequisite blocker

- P6-13: `docs/architecture/SIMULATION_NURTURE.md` documents actual consent/audience behavior,
  retained suppression, cursor semantics, access boundaries, absent sender/scheduler and the
  licensed Marketing Cloud seam. It does not claim messaging or live acceptance.
- P6-14: native named Platinum Care process and two non-recurring milestone types, new explicit
  response field, timestamp validation, bulk completion service/thin Case trigger, native breach
  report, new unassigned layout/page and native Visualforce milestone tracker. Four/48 **business**
  hours use the existing Default calendar. No default process replacement, auto-enrollment,
  entitlement data creation or business-hours edits. Closure never fabricates first response.
- P6-15: ten complete original internal local drafts and explicit category/import/Case-use mapping
  in `docs/knowledge/P6_ARTICLE_DRAFTS.json` and `docs/knowledge/README.md`. Native Knowledge
  remains blocked by disabled feature state, not silently replaced or marked complete.
- P6-16: additive Sales and Service Console apps, full workspace mappings and an app-only
  unassigned permission set. Existing apps and users remain untouched; Sales references retain
  accepted quote/finance entry points. Console access grants no object/FLS access.
- P6-17: new native SLA lifecycle, 200-Case bulk, response-vs-closure, reopen/idempotency, bypass,
  invalid timestamp, denied actor and hidden-Case tests. Actual Service persona runs prove
  read/edit boundaries; tests do not substitute for console/browser acceptance. Existing
  accrual/tier/redemption/capacity coverage meets the focused 90% gate.

CONFIRMED — fresh target settings excerpts:

```xml
<enableEntitlements>true</enableEntitlements>
<enableKnowledge>false</enableKnowledge>
```

CONFIRMED — Knowledge__kav describe failure:

```text
The requested resource does not exist
```

The EntityDefinition query for Knowledge__kav, KnowledgeArticleVersion, CaseArticle,
CaseMilestone, Entitlement and SlaProcess returned only CaseMilestone, Entitlement and SlaProcess.
Knowledge activation is outside this task's persistent-change boundary. Owner must decide
whether to enable it in Setup > Knowledge Settings, then re-verify schema/licenses and approve
native category metadata, Draft import, publication and Case attachment separately. No Knowledge
settings, speculative body field or article records are included in the validated package.

## Exact deployment approval scope — no deployment authorized

Manifest: `manifest/p6-batch4-check.xml`. Final stored validation: `0Afaj00000p1hwnCAA`.
It contains exactly 41 components: 16 new metadata components and 25 unchanged test/fixture
classes. No existing production implementations, existing apps/pages/layouts, profiles, permission
set groups, folders, global settings, Flows or loyalty configuration are packaged.

New components, by metadata type:

| Type | Exact member |
|---|---|
| ApexClass | CaseMilestoneService |
| ApexClass | CaseMilestoneServiceTest |
| ApexTrigger | CaseMilestoneTrigger |
| CustomField | Case.First_Response_On__c |
| ValidationRule | Case.VR_FirstResponse_ValidTime |
| MilestoneType | NG First Response |
| MilestoneType | NG Resolution |
| EntitlementProcess | NG Platinum Care |
| Layout | Case-NG Service SLA Layout |
| FlexiPage | NG_Service_SLA_Case_Page |
| ApexPage | NG_Case_Milestones |
| Report | NG_Service_Operations/Native_SLA_Breaches |
| CustomApplication | Northgate_Sales_Console |
| CustomApplication | Northgate_Service_Console |
| PermissionSet | PS_Service_SLA |
| PermissionSet | PS_Northgate_Consoles |

Unchanged packaged classes (25): Batch3ReportingAccessTest, Batch3TestData,
CaseEscalationStampBatchTest, CaseServiceHistoryControllerTest, ConsentGateServiceTest,
DeliveryCloseServiceTest, DeliveryCompletionGuardTest, ExecutiveServiceMetricsPublisherTest,
FinanceApplicationControllerTest, FinancingStatusServiceTest, LoyaltyAccrualBatchTest,
LoyaltyAccrualServiceTest, LoyaltyEnrolmentServiceTest, LoyaltyLedgerServiceTest,
LoyaltyTierEvalBatchTest, Loyalty_ExpiryBatchTest, NurtureAudienceServiceTest,
QuoteBuilderControllerTest, QuotePricingServiceTest, QuoteSummaryControllerTest,
RedemptionServiceTest, RepeatPurchaseSignalServiceTest, ServiceIntakeCaseServiceTest,
ServiceVisitCapacityGuardTest, VehicleServiceHistoryControllerTest.

The pre-existing dirty DiscountApprovalTest source is deliberately excluded. The final validation
runs the six methods in its deployed version. A previous wider check included its local seven-
method version; that stored request is superseded and must not be used for deployment.

The process is active metadata but requires explicit entitlement/Case opt-in; no records are
enrolled. New SLA layout/page remain unassigned. The new Sales Console references already-
accepted Sales record pages; it does not change existing applications' overrides. New permission
sets are metadata only. A later metadata deployment approval must not be treated as approval
for assignments, data enrollment, activation, Knowledge or scheduling.

## Routine correction history

- `0Afaj00000p1CcrCAE`: failed before tests, ten metadata errors. Native milestone recurrence is
  `none`, not `NoRecurrence`; required Case layout fields include Description and SuppliedEmail;
  every Console tab needs a workspace mapping; Entitlement Read requires Account Read.
  CaseMilestones is a SOQL child relationship but not a supported custom report-type join.
  Reused the actual native CaseMilestone report type instead of adding a custom reporting layer.
  The guessed Lightning milestone component was unavailable; used the documented native
  `apex:milestoneTracker` with the standard Case controller instead.
- `0Afaj00000p19rvCAA`: two remaining metadata errors, required SuppliedEmail layout item and
  incorrect Visualforce namespace. Corrected to `apex:milestoneTracker`, documented at
  `https://developer.salesforce.com/docs/platform/salesforce-pages-developers-guide/guide/pages-compref-milestonetracker.html`.
- `0Afaj00000p1D7WCAU`: focused check succeeded, 42/42 components, four/four new tests,
  no coverage warnings. This was before removing unrelated dirty DiscountApprovalTest source.
- `0Afaj00000p0rLXCAY`: broader check succeeded, 42/42 components, 182/182 methods. The CLI
  waiter timed out; read-only deployment report recovered the completed successful result.
  Component review found one pre-existing changed test source, DiscountApprovalTest. Removed
  only its manifest membership, preserving that file and rerunning against its deployed version.
  This request is superseded by the narrower final request below.

No tests were weakened and no existing production code was patched to make validation pass.

## Final exact scoped validation

Command:

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p6-batch4-check.xml --test-level RunSpecifiedTests --tests CaseMilestoneServiceTest --tests ConsentGateServiceTest --tests NurtureAudienceServiceTest --tests RepeatPurchaseSignalServiceTest --tests Batch3ReportingAccessTest --tests LoyaltyLedgerServiceTest --tests LoyaltyAccrualServiceTest --tests LoyaltyAccrualBatchTest --tests LoyaltyTierEvalBatchTest --tests Loyalty_ExpiryBatchTest --tests RedemptionServiceTest --tests VehicleServiceHistoryControllerTest --tests LoyaltyEnrolmentServiceTest --tests DeliveryCloseServiceTest --tests DeliveryCompletionGuardTest --tests QuotePricingServiceTest --tests QuoteBuilderControllerTest --tests ExecutiveServiceMetricsPublisherTest --tests ServiceVisitCapacityGuardTest --tests ServiceIntakeCaseServiceTest --tests CaseEscalationStampBatchTest --tests CaseServiceHistoryControllerTest --tests DiscountApprovalTest --tests FinanceApplicationControllerTest --tests FinancingStatusServiceTest --tests QuoteSummaryControllerTest --async --json
sf project deploy report --target-org ng-demo --job-id 0Afaj00000p1hwnCAA --json
```

CONFIRMED — raw final output excerpts:

```json
"id": "0Afaj00000p1hwnCAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-24T23:29:21.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 41,
"numberComponentsTotal": 41,
"numberTestErrors": 0,
"numberTestsCompleted": 181,
"numberTestsTotal": 181,
"componentFailures": [],
"numTestsRun": 181,
"numFailures": 0,
"failures": [],
"codeCoverageWarnings": [],
"warnings": []
```

CONFIRMED — final component result projection:

```json
"createdComponents": 16,
"unchangedComponents": 25,
"modifiedExistingComponents": [],
"allComponentsSuccessful": true
```

CONFIRMED — new production coverage output:

```json
[
  {"name":"CaseMilestoneService","numLocations":19,"numLocationsNotCovered":0},
  {"name":"CaseMilestoneTrigger","numLocations":3,"numLocationsNotCovered":0}
]
```

The 26 test classes cover four new SLA methods, 119 previous Batch 1–3 methods and 58
deployed approval/finance/summary methods. Both new production Apex components have 100%
executable-line coverage. No selected metadata/source edits followed the final validation.

## P6-17 existing implementation coverage

Commands:

```sh
sf apex run test --target-org ng-demo --tests LoyaltyAccrualServiceTest --tests LoyaltyAccrualBatchTest --tests LoyaltyTierEvalBatchTest --tests RedemptionServiceTest --tests ServiceVisitCapacityGuardTest --tests LoyaltyLedgerServiceTest --tests Loyalty_ExpiryBatchTest --code-coverage --result-format json --wait 30
sf apex get test --target-org ng-demo --test-run-id 707aj00001NdWTm --code-coverage --result-format json
```

CONFIRMED — raw output projection:

```json
{
  "summary": {"outcome":"Passed","passing":34,"failing":0,"testsRan":34,"testRunId":"707aj00001NdWTm"},
  "coverage": [
    {"name":"ServiceVisitCapacityGuard","totalLines":89,"totalCovered":87,"coveredPercent":98},
    {"name":"LoyaltyAccrualBatch","totalLines":11,"totalCovered":11,"coveredPercent":100},
    {"name":"LoyaltyLedgerService","totalLines":208,"totalCovered":206,"coveredPercent":99},
    {"name":"LoyaltyAccrualService","totalLines":31,"totalCovered":29,"coveredPercent":94},
    {"name":"Loyalty_ExpiryBatch","totalLines":7,"totalCovered":7,"coveredPercent":100},
    {"name":"LoyaltyTierEvalBatch","totalLines":7,"totalCovered":7,"coveredPercent":100},
    {"name":"RedemptionService","totalLines":11,"totalCovered":11,"coveredPercent":100}
  ]
}
```

These are named-class coverage results from the focused run, not an org-wide coverage claim.

## Local integrity and preservation

Command: `python3 scripts/tests/check_p6_batch4.py`.

CONFIRMED — raw output:

```json
{
  "status": "PASS",
  "articleDrafts": 10,
  "metadataMembers": 41,
  "checks": [
    "unique draft URLs",
    "content/category mapping",
    "exact manifest boundary",
    "console workspace mappings",
    "no console object/FLS expansion",
    "accepted Sales page references"
  ]
}
```

Earlier CP2, approvals, financing, delivery, loyalty, Cases, consent and reporting implementations
were not edited. The scoped regressions passed; this is not live browser acceptance. Unrelated
dirty files were preserved. Only new Batch 4 metadata, docs/content/checker/manifest and current
handoff/backlog documentation were authored. Test fixture DML rolls back; no persistent Salesforce
record write or permission assignment command was run. No ng-dev access, jobs, page activation,
Knowledge enablement/publication, deployment or Git staging/commit/push occurred.

## Remaining gates

Knowledge activation/schema/license readiness is a genuine P6-15 prerequisite blocker; native
Knowledge configuration/import/search/Case attachment is not complete. All authorized independent
work proceeded. Live SLA timer/breach UI, console dual-role navigation and security, report results,
SLA page/layout placement and all prior Batch 1–3 browser/live acceptance remain deferred, not
passed. Use `docs/planning/P6_BATCH4_ACCEPTANCE_RUNBOOK_2026-10-24.md` for separately approved
steps. Phase 6 is not accepted or closed by this local validation. No Batch 4 deployment is authorized.

## Subsequent owner-authorized exact Quick Deploy

The owner separately authorized only stored validation `0Afaj00000p1hwnCAA` and its exact
41-component payload. This section supersedes the predeployment authorization status above.

Preflight commands:

```sh
sf data query --target-org ng-demo --query "SELECT Id FROM Organization" --json
sf project deploy report --target-org ng-demo --job-id 0Afaj00000p1hwnCAA --json
```

CONFIRMED — raw target output:

```json
"Id": "00Daj00001Ae3iWEAR"
```

CONFIRMED — stored validation output excerpts:

```json
"id": "0Afaj00000p1hwnCAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-24T23:29:21.000Z",
"numberComponentsDeployed": 41,
"numberComponentsTotal": 41,
"numberComponentErrors": 0,
"numberTestsCompleted": 181,
"numberTestsTotal": 181,
"numberTestErrors": 0,
"codeCoverageWarnings": []
```

The stored validation was within the documented 10-day validity window. No separate eligibility
flag was exposed. The exact Quick Deploy succeeded, confirming eligibility on the server.

Command:

```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000p1hwnCAA --wait 30 --json
```

CONFIRMED — raw final command output projection, component counts grouped by metadata type:

```json
{
  "status": 0,
  "result": {
    "id": "0Afaj00000p1MVmCAM",
    "status": "Succeeded",
    "success": true,
    "checkOnly": false,
    "completedDate": "2026-10-25T00:38:45.000Z",
    "numberComponentErrors": 0,
    "numberComponentsDeployed": 41,
    "numberComponentsTotal": 41,
    "numberTestErrors": 0,
    "numberTestsCompleted": 0,
    "numberTestsTotal": 0
  },
  "componentFailures": [],
  "componentCounts": {
    "ApexClass": 27,
    "ApexPage": 1,
    "ApexTrigger": 1,
    "CustomApplication": 2,
    "CustomField": 1,
    "EntitlementProcess": 1,
    "FlexiPage": 1,
    "Layout": 1,
    "MilestoneType": 2,
    "PermissionSet": 2,
    "Report": 1,
    "ValidationRule": 1
  },
  "createdComponents": 16,
  "unchangedComponents": 25,
  "modifiedExistingComponents": [],
  "allComponentsSuccessful": true,
  "warnings": [],
  "message": null
}
```

Quick Deploy reused the exact approved validation; no package rebuild, scope expansion or other
deployment method was attempted. Tests were not rerun: the 181/181 stored validation result is
the test evidence. The UTC completion corresponds to October 24 in America/Toronto.

No Knowledge enablement, records, entitlement enrollment, permission assignments, page/layout
activation, scheduling or Git commit/push was performed. New metadata is deployed; existing
record data and user assignments were not changed by this execution. No ng-dev access.
Live SLA, dashboard/reporting and console/persona/browser acceptance remains deferred, not
passed. Native Knowledge remains blocked; ten local drafts remain local. Phase 6 is not accepted
or closed. Further activation/data work requires separate authorization.
