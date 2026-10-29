# Phase 7 Batch 1 — authorized standard deployment recovery

## Final status

Both exact approved manifests deployed successfully to ng-demo `00Daj00001Ae3iWEAR`, in the
required order: photos first, then application. No deployment failed or required a repair/retry.
No manifest expansion or unrelated source change. Browser/gallery/actual event delivery and
VIN credential acceptance remain deferred, not passed. Batch 1 is deployed, not owner-accepted.

The previous Quick Deploy rejection remains historical. This run uses the owner's subsequent
explicit standard-deployment authorization; it is not an unauthorized fallback from that run.

## Target, scope and source preflight

CONFIRMED — raw Organization query excerpts:

```json
"Id": "00Daj00001Ae3iWEAR",
"IsSandbox": false,
"OrganizationType": "Developer Edition"
```

The current manifest member sets were compared programmatically with component successes in
stored validations `0Afaj00000p4yTFCAY` and `0Afaj00000p2bfeCAA`. Both match exactly, one and
21 components respectively. The event object has only its two approved fields; LWC bundles have
only their original approved files; the resource source folder has only the thirty approved
WebPs, licenses.json and optional ATTRIBUTION.md. No profile/settings/credential/other component
was added. The two existing runtime diffs are exactly the recorded VehicleCounters cache-DML
mode and VehicleCounterTrigger publisher call, with no unrelated alteration.

Command: `python3 scripts/tests/check_p7_deployment_recovery.py`.

CONFIRMED — raw output:

```json
{
  "status": "PASS",
  "componentCounts": [1, 21],
  "sourceFileCounts": [33, 37],
  "scopeMatchesStoredValidations": true,
  "unexpectedSelectedSourceChanges": [],
  "assetArchiveMatchesRecordedHash": true
}
```

Current source hashes are recorded in `DEPLOYMENT_RECOVERY_PREFLIGHT_2026-10-25.json`. Application
source modification times are before the successful validation's completion; no later selected
source edit was found. The original stored Salesforce ZIP cannot be independently extracted for
sealed application byte parity, so that stronger claim is not made. Scope, file layout, reviewed
diffs and source continuity were checked. After deployment all 70 captured source hashes still match.

The local photo verifier also passed thirty files/CC0/dimensions/encoding/ZIP integrity and
live path compatibility; local deliverable ZIP SHA-256 remains
`67f1710386db658283f2d0649110128407c39bef9e28573ceccff805c0dffd7d`.

## Ordered deployment commands

The target is Developer Edition, where NoTestRun is supported. It was explicitly used for both
standard deployments and accepted by Salesforce. No extra Apex testing was performed beyond
deployment requirements; prior 163/163 successful tests remain reused validation evidence.
Do not describe the deploy as rerunning 163 tests.

Photos, first:

```sh
sf project deploy start --target-org ng-demo --manifest manifest/p7-22-images-check.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw result excerpts:

```json
"id": "0Afaj00000p7373CAA",
"status": "Succeeded",
"success": true,
"checkOnly": false,
"completedDate": "2026-10-25T23:13:52.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 1,
"numberComponentsTotal": 1,
"numberTestErrors": 0,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": [],
"warnings": []
```

StaticResource NG_VehicleImages returned created=true, changed=true, success=true.

Application, issued only after the photo result succeeded:

```sh
sf project deploy start --target-org ng-demo --manifest manifest/p7-batch1-check.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw result excerpts:

```json
"id": "0Afaj00000p738fCAA",
"status": "Succeeded",
"success": true,
"checkOnly": false,
"completedDate": "2026-10-25T23:14:29.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 21,
"numberComponentsTotal": 21,
"numberTestErrors": 0,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": [],
"warnings": []
```

CONFIRMED — application component projection:

```json
"componentCounts": {"ApexClass":10,"ApexTrigger":1,"CustomField":2,"CustomObject":1,"CustomPermission":2,"CustomTab":1,"LightningComponentBundle":2,"PermissionSet":2},
"createdComponents": 19,
"modifiedExistingComponents": ["VehicleCounters","VehicleCounterTrigger"],
"allComponentsSuccessful": true
```

Exact source/member inventory remains in `BATCH1_EXECUTION_2026-10-25.md`. Only the approved
one-plus-21 components were deployed; no new validation or unrelated repair was substituted.

## Deployed resource presence and content/path verification

Query: `SELECT Id,Name,ContentType,BodyLength,CacheControl FROM StaticResource WHERE Name = 'NG_VehicleImages'`.

CONFIRMED — raw field excerpts:

```json
"Id": "081aj00000LQd1dAAD",
"Name": "NG_VehicleImages",
"ContentType": "application/zip",
"BodyLength": 1807209,
"CacheControl": "Public"
```

The authenticated REST resource Body was downloaded read-only to
`evidence/P7/deployed-NG-VehicleImages.zip` using:

```sh
sf api request rest "/services/data/v68.0/sobjects/StaticResource/081aj00000LQd1dAAD/Body" --target-org ng-demo --method GET --header "Accept:application/zip" --stream-to-file "evidence/P7/deployed-NG-VehicleImages.zip" --json
```

`python3 scripts/tests/check_p7_deployed_resource.py` verifies the actual downloaded archive,
not only the local source: all thirty expected root filenames, exact photo SHA-256 values,
decoded WebP/800x600 dimensions, license/photographer register bytes, actual resource length and
all thirty live model/body/image-path matches. No Model or Vehicle record was updated.

CONFIRMED — raw output:

```json
{
  "status": "PASS",
  "resourceId": "081aj00000LQd1dAAD",
  "resourceName": "NG_VehicleImages",
  "deployedArchiveBytes": 1807209,
  "deployedPhotoContentMatches": 30,
  "deployedRootFiles": 31,
  "photographerAndLicenseRegisterMatches": true,
  "optionalAttributionMarkdown": "Excluded by existing .forceignore *.md; no ignore/source repair performed. CC0 credits remain in licenses.json.",
  "existingModelPathsCompatible": 30,
  "recordChanges": 0,
  "selectedSourceFilesUnchangedSincePreflight": 70,
  "browserGalleryEventAcceptance": "DEFERRED",
  "frontEndHttpImageRendering": "NOT VERIFIED: direct API-host resource stream was empty; authenticated REST archive contents verified."
}
```

The source/deliverable ZIP has 32 files; the deployed Salesforce archive has 31. Existing
`.forceignore` line `*.md` excludes optional ATTRIBUTION.md during Salesforce CLI packaging,
including the earlier validation. An initial readback checker incorrectly expected the local
32-entry archive; it was corrected to the actual existing ignore policy after inspecting the
deployed list. No Salesforce/resource/ignore rule was repaired or redeployed. All photographs and
the complete photographer/license/source register remain present; CC0 does not require the
optional Markdown credit file. The archive size differs because of this filter and CLI packing,
not missing photo content or changed image paths.

A direct API-host `/resource/NG_VehicleImages/aurelia_ex.webp` stream probe produced an empty
local response with no useful HTTP status. It is not accepted as image rendering evidence.
Canonical authenticated REST archive verification succeeded. Thus deployed file/path compatibility
is verified, but browser/front-end URL rendering and gallery presentation remain deferred.
No speculative authentication, URL, gallery or packaging repair was attempted.

## Boundaries and acceptance state

CONFIRMED — selected new operational assignment query result:

```json
"records": [],
"totalSize": 0
```

This query covers PS_Inventory_Gallery and PS_Opportunity_Calculator. Neither was assigned.
No page activation, VIN credential/principal change, new business record, image-path/VIN/inventory
write, job scheduling, Git staging/commit/push or ng-dev access. Source and all unrelated dirty
work were preserved. The only org changes issued were the two authorized metadata deployments.

Batch 1 deployment is complete, but browser/gallery/reservation/event delivery, operational
access/placement and live VIN endpoint acceptance are not passed or owner-accepted. Phase 6
OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026 remains unchanged; no later batch
or Phase 8 implementation is authorized by this recovery.
