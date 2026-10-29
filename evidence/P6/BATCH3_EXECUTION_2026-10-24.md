# Phase 6 Batch 3 — check-only execution

## Scope

Exact package: `manifest/p6-batch3-check.xml`. Target: approved ng-demo only.
Initial work was check-only. The owner subsequently authorized the exact Quick Deploy recorded
below. No live permission assignment, processing activation or record changes were performed.

## Dashboard correction

Added `<axisBinding>y</axisBinding>` to the RowCount chart summaries in:

- `force-app/main/default/dashboards/NG_Service_Operations/DM_Service_Operations.dashboard-meta.xml`
- `force-app/main/default/dashboards/NG_Loyalty_Operations/DM_Loyalty_Operations.dashboard-meta.xml`

This follows the existing manual chart selection pattern in the repository's Sales dashboards.

## Initial focused check (historical failure)

Command:

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p6-batch3-check.xml --test-level RunSpecifiedTests --tests ConsentGateServiceTest --tests NurtureAudienceServiceTest --tests RepeatPurchaseSignalServiceTest --tests Batch3ReportingAccessTest --wait 30 --json
```

CONFIRMED — raw command output excerpts:

```json
"checkOnly": true,
"id": "0Afaj00000p0tojCAA",
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestErrors": 3,
"numberTestsCompleted": 7,
"numberTestsTotal": 10,
"status": "Failed",
"success": false
```

The request completed at `2026-10-24T20:18:57.000Z`.

REFUTED — all focused tests pass. Raw failure output:

```text
ConsentGateServiceTest.emailOptOutAndConsentReparentRefreshBothContacts
System.DmlException: Operation failed due to fields being inaccessible on Sobject Contact, check errors on Exception or Result!
Class.ConsentGateServiceTest.emailOptOutAndConsentReparentRefreshBothContacts: line 67, column 1

NurtureAudienceServiceTest.previewRechecksConsentAndFiltersHiddenContactsWithoutSending
System.QueryException: No such column 'IsActive' on entity 'Campaign'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.
Class.NurtureAudienceService.preview: line 11, column 1
Class.NurtureAudienceServiceTest.previewRechecksConsentAndFiltersHiddenContactsWithoutSending: line 19, column 1

NurtureAudienceServiceTest.unauthorizedActorCannotPreviewAndUnmanagedCampaignIsEmpty
System.QueryException: No such column 'IsActive' on entity 'Campaign'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.
Class.NurtureAudienceService.preview: line 11, column 1
Class.NurtureAudienceServiceTest.unauthorizedActorCannotPreviewAndUnmanagedCampaignIsEmpty: line 38, column 1

NurtureAudienceService
Test coverage of selected Apex Class is 35%, at least 75% test coverage is required
```

## Initial escalation (superseded by owner authorization below)

Stopped corrective work after these new failures, as required by `AGENTS.md`.
No changes to the failing tests, audience implementation or permission metadata were made
after this request. Owner must inspect the request in Setup > Deployment Status and authorize
the next bounded investigation/correction of persona field access.

The check accepts both dashboard components but does not establish live rendering, refresh,
persona visibility or final deployment eligibility. Full regression validation, browser checks,
live folder/security readback and Batch 3 acceptance remain pending. Earlier deferred Batch 1/2
acceptance is not changed by this check.

## Authorized routine corrections

The owner explicitly authorized diagnosis, ordinary corrections, focused tests and the coordinated
regression check after request `0Afaj00000p0tojCAA`. No deployment or live security/data writes
were authorized.

- `ConsentGateServiceTest`: use explicit SYSTEM_MODE only for the two test-fixture Email opt-out
  updates, consistent with the other controlled fixtures. This preserves assertions proving
  suppression and restoration; production Contact permissions are unchanged.
- `PS_Nurture_Audience`: add read-only `Campaign.IsActive` FLS. The field exists; it is hidden
  from the reader's USER_MODE query without this permission. Keep USER_MODE and the active
  Campaign eligibility check rather than removing it or elevating the Campaign query.
- `NurtureAudienceService`: remove client caching so each preview invocation rechecks consent.
- `NurtureAudienceServiceTest`: add a 201-member pagination test, read-only Active-field access
  assertions, inactive Campaign exclusion and missing Campaign handling. Existing tests still
  verify hidden Contact exclusion, revocation, denied actors and no email invocation.

CONFIRMED — raw output excerpt from `sf sobject describe --sobject Campaign --target-org ng-demo --json`:

```json
"name": "IsActive",
"permissionable": true,
"type": "boolean"
```

CONFIRMED — filtered raw output from `sf sobject describe --sobject Contact --target-org ng-demo --json`
for `HasOptedOutOfEmail` under the connected user:

```json
{
  "status": 0,
  "fields": []
}
```

## Successful focused check

Reran the focused command above after the corrections.

CONFIRMED — raw output excerpts:

```json
"id": "0Afaj00000p15WXCAY",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-24T21:01:45.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestErrors": 0,
"numberTestsCompleted": 11,
"numberTestsTotal": 11
```

## Final coordinated scoped check

Command:

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p6-batch3-check.xml --test-level RunSpecifiedTests --tests ConsentGateServiceTest --tests NurtureAudienceServiceTest --tests RepeatPurchaseSignalServiceTest --tests Batch3ReportingAccessTest --tests LoyaltyLedgerServiceTest --tests LoyaltyAccrualServiceTest --tests LoyaltyAccrualBatchTest --tests LoyaltyTierEvalBatchTest --tests Loyalty_ExpiryBatchTest --tests RedemptionServiceTest --tests VehicleServiceHistoryControllerTest --tests LoyaltyEnrolmentServiceTest --tests DeliveryCloseServiceTest --tests DeliveryCompletionGuardTest --tests QuotePricingServiceTest --tests QuoteBuilderControllerTest --tests ExecutiveServiceMetricsPublisherTest --tests ServiceVisitCapacityGuardTest --tests ServiceIntakeCaseServiceTest --tests CaseEscalationStampBatchTest --tests CaseServiceHistoryControllerTest --wait 30 --json
```

CONFIRMED — raw output excerpts:

```json
"id": "0Afaj00000p15t7CAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-24T21:06:28.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestErrors": 0,
"numberTestsCompleted": 119,
"numberTestsTotal": 119,
"componentFailures": [],
"numTestsRun": 119,
"numFailures": 0,
"failures": [],
"codeCoverageWarnings": [],
"warnings": []
```

CONFIRMED — raw coverage excerpts for all new production Apex, from the final request:

```json
[
  {"name":"CampaignMemberConsentTrigger","numLocations":3,"numLocationsNotCovered":0},
  {"name":"ConsentTrigger","numLocations":5,"numLocationsNotCovered":0},
  {"name":"CampaignConsentTrigger","numLocations":9,"numLocationsNotCovered":0},
  {"name":"ContactConsentTrigger","numLocations":5,"numLocationsNotCovered":0},
  {"name":"ConsentGateService","numLocations":72,"numLocationsNotCovered":0},
  {"name":"RepeatPurchaseSignalService","numLocations":2,"numLocationsNotCovered":0},
  {"name":"NurtureAudienceService","numLocations":20,"numLocationsNotCovered":0}
]
```

All 21 selected test classes ran: 11 Batch 3 methods plus 108 existing regression methods.
No selected source changes followed the successful final validation; subsequent edits update
documentation only. Salesforce's `numberComponentsDeployed` key above is check-only output,
not a persistent deployment.

## Predeployment status and remaining acceptance gates (historical)

No implementation/check-only blocker remains. Both dashboards pass metadata validation;
the old dynamic-dashboard quota assumption did not cause a validation error. This does not
prove live dashboard rendering or refresh. Batch 3 remains local and undeployed.

Skipped: live deployment, permissions/folder readback for undeployed metadata, report seed/browser
acceptance, advisor-versus-manager dashboard screenshots, fixed-user dashboard refresh, live
campaign opt-in, permission assignments, message delivery, scheduling and Git publication.
Batch 1/2 deferred live acceptance remains pending. Batch 2 processing remains inactive.
No Batch 4 work began.

## Owner-authorized exact Quick Deploy

The owner authorized only Quick Deploy of stored validation `0Afaj00000p15t7CAA` to
ng-demo / `00Daj00001Ae3iWEAR`. No package rebuild or scope expansion occurred.

Target verification command:

```sh
sf data query --target-org ng-demo --query "SELECT Id FROM Organization" --json
```

CONFIRMED — raw target output excerpt:

```json
"Id": "00Daj00001Ae3iWEAR"
```

Preflight command:

```sh
sf project deploy report --target-org ng-demo --job-id 0Afaj00000p15t7CAA --json
```

CONFIRMED — stored validation output excerpts:

```json
"id": "0Afaj00000p15t7CAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-24T21:06:28.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestErrors": 0,
"numberTestsCompleted": 119,
"numberTestsTotal": 119
```

The stored validation was successful and within the documented 10-day validity window.
The report did not expose an explicit eligibility flag. Server acceptance of the exact Quick
Deploy below established eligibility; no fallback deployment or new validation was attempted.

Deployment command:

```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000p15t7CAA --wait 30 --json
```

Final readback command:

```sh
sf project deploy report --target-org ng-demo --job-id 0Afaj00000p19YXCAY --json
```

CONFIRMED — raw command output, filtered to status and component results (counts grouped by
`componentType`; the package.xml acknowledgement is excluded from component counts):

```json
{
  "status": 0,
  "result": {
    "id": "0Afaj00000p19YXCAY",
    "status": "Succeeded",
    "success": true,
    "checkOnly": false,
    "completedDate": "2026-10-24T21:15:46.000Z",
    "numberComponentErrors": 0,
    "numberComponentsDeployed": 56,
    "numberComponentsTotal": 56,
    "numberTestsCompleted": 0,
    "numberTestsTotal": 0
  },
  "componentCounts": {
    "ApexClass": 25,
    "ApexTrigger": 4,
    "CustomField": 7,
    "CustomPermission": 1,
    "Dashboard": 2,
    "DashboardFolder": 2,
    "PermissionSet": 3,
    "Report": 6,
    "ReportFolder": 3,
    "ReportType": 3
  },
  "createdComponents": 39,
  "unchangedComponents": 17,
  "allComponentsSuccessful": true,
  "componentFailures": [],
  "warnings": []
}
```

Quick Deploy did not rerun tests; it reused the validation's 119/119 result. Unchanged components
are the 17 existing regression test classes in the validated package. All 39 new metadata
components succeeded, including both dashboards and all four consent triggers.

## Postdeployment acceptance status

Batch 3 deployment is complete. Live dashboard, reporting and persona acceptance is deferred,
not passed. No dashboard refresh, report-result acceptance, folder/security readback, Campaign
opt-in, permission assignment, live record changes, job scheduling or page activation was run.
Batch 1/2 deferred acceptance remains pending; loyalty processing remains inactive.
No ng-dev access, Git staging/commit/push or Batch 4 work occurred. Batch 4 deployment requires
separate owner authorization.
