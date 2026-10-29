# Phase 7 final Batch 3/4 deployments — actual evidence

## Scope, target and Quick Deploy fallback

Owner authorized exactly NG_Case_Triage in manifest/p7-batch3-check.xml, followed by
vehiclePhotoHeader/NG_Vehicle_Photo_Header in manifest/p7-batch4-check.xml. Target query confirms
ng-demo 00Daj00001Ae3iWEAR / Developer Edition. Saved validations and source hashes matched before
execution. No manifest/source, feature, setting, permission, page assignment or data scope expanded.

Both named Quick Deploys were attempted once. Each returned CannotQuickDeployError without an
actual deployment job; the owner-authorized standard scoped fallback was used. Exact reasons:

```text
INVALID_ID_FIELD: Source validate did not run tests in the org
INVALID_ID_FIELD: There have been deploys in the org since the source validate happened
```

These are Quick Deploy availability failures, not failed actual deployments. Raw error fields are
retained in BATCH3_FINAL_QUICK_ATTEMPT.json and BATCH4_FINAL_QUICK_ATTEMPT.json; private stack paths
are omitted. No repeated attempts, new validation, test rerun or unrelated repair was needed.

Commands actually deployed, in this order:

```sh
sf project deploy start --target-org ng-demo --manifest manifest/p7-batch3-check.xml --test-level NoTestRun --wait 10 --json
sf project deploy start --target-org ng-demo --manifest manifest/p7-batch4-check.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw result projections:

```json
{"id":"0Afaj00000pCUHtCAO","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T13:58:55.000Z","numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
{"id":"0Afaj00000pCURZCA4","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T13:59:05.000Z","numberComponentsDeployed":2,"numberComponentsTotal":2,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
```

Component successes are exactly the one GenAiPromptTemplate, one LightningComponentBundle and
one FlexiPage named above; package.xml container success is not an extra component. No deletions,
failures or warnings. Developer Edition accepted NoTestRun; zero Apex methods ran. Previous
successful Apex/local/header/prompt validations were reused, not described as new runs.

## Deployed definition readback

Metadata retrieve 09Saj00000mqJ4XEAU reads the three deployed definitions into evidence only.
Native retrieved prompt XML has status Draft and no activeVersionIdentifier; the header JS and
new page definition are present. It is not an agent, active prompt, published Knowledge or an
active Vehicle-page assignment. No prompt was executed or LLM credit consumed by a demo call.

CONFIRMED — raw verification projection:

```json
{
  "status":"PASS",
  "batch3Deployment":"0Afaj00000pCUHtCAO",
  "batch4Deployment":"0Afaj00000pCURZCA4",
  "promptInactive":true,
  "promptVersionStatuses":["Draft"],
  "headerAndPageExist":true,
  "unchangedComparisons":{
    "vehicleAndApplicationAssignmentSha256":true,
    "settingsSha256":true,
    "securityFingerprints":true,
    "businessRecordFingerprints":true,
    "triggerFingerprints":true
  },
  "territoryModelState":"Planning",
  "accountAssociations":0,
  "userMemberships":0,
  "newTestsRun":0,
  "phase8Implemented":false,
  "pageActivatedOrAssigned":false
}
```

## Before/after preservation evidence and limits

Pre-retrieve 09Saj00000mqItFEAU and post-retrieve 09Saj00000mqJ7lEAE independently read the live
Vehicle object action overrides and all action/profile overrides from 37 application definitions.
Combined semantic assignment hash matches exactly:

```text
5aea945dbb16ed50f3c69d20d32aeb0d6a561939b7f5e90f1bac2743ef9d727d
```

Both snapshots also match six relevant settings, 31 PermissionSetAssignment rows, 23 permission-
group components, 13,370 object-permission rows, 26,333 field-permission rows, ten User active/
profile/role mappings and every live trigger body/status. No settings or permission metadata
was selected by either deployment. The existing territory model remains Planning with no
Account/User associations; no activation or assignment command was issued.

For 27 project business objects, sorted visible non-deleted IDs/LastModifiedDate fingerprints
and counts are identical before/after. No business fields or personal customer values were
exported into the fingerprint receipts. This establishes stability of that bounded record
inventory, not an exhaustive field/history/deleted-row/background-event audit. No data-changing
command was issued. Do not turn this bounded check into a claim about all records in all orgs.

Artifacts: FINAL_BEFORE_BASELINE.json / FINAL_AFTER_BASELINE.json and assignment snapshots;
FINAL_BEFORE_METADATA / FINAL_AFTER_METADATA; FINAL_DEPLOYED_DEFINITIONS;
P7_FINAL_DEPLOYMENT_VERIFICATION.json; sanitized BATCH3_FINAL/BATCH4_FINAL command/deployment JSON.
No content was retrieved over force-app source and selected source hashes remained unchanged.

## Closeout boundary

Only three authorized definitions changed. No page/prompt/feature activation, permission/user/
sharing-default change, Account/User/territory association, CRM mutation, Git stage/commit/push
or ng-dev access. Phase 8 is planning only. Phase 7 status, all 23 blocks and remaining acceptance
exceptions are in docs/planning/PHASE7_FINAL_STATUS_2026-10-26.md; it is not owner acceptance.
