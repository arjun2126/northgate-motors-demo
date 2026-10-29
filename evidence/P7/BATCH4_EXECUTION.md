# Phase 7 Batch 4 — local implementation and scoped validation

## Actual status and authority

Owner authorized only P7-19/P7-20/P7-21/P7-23 local implementation and relevant check-only against
ng-demo 00Daj00001Ae3iWEAR. No Batch 3/4 metadata was deployed, no page/feature activation,
permission/user/business-data change, Git staging/commit/push or ng-dev access occurred.
Plan: `docs/planning/P7_BATCH4_IMPLEMENTATION_PLAN.md`.

| Block | Delivered | Acceptance boundary |
|---|---|---|
| P7-19 | One-page Automotive Cloud concept mapping using actual standard/custom dealership entities and explicit licensed-product gaps | Documentation only; no Automotive Cloud build/license claim |
| P7-20 | README rewritten with actual deployment/source status, target-only two-org history, focused commands, separate deploy/reset-plan approvals and exception links | No clean tag, reset execution or accepted capability demo claimed |
| P7-21 | Five current persona-first Admin/Developer/Analyst/Support/Architect walkthroughs and gate/recording index; old P2 script retained with a historical do-not-execute notice | Prepared, not live end-to-end signed off; Support identity/access remains blocked; no admin substitution or role switching |
| P7-23 | Read-only UI API photo/model header plus new unassigned Vehicle page retaining native highlights/details and existing service history; exact 2-member manifest | Source/state/native compilation verified; actual page placement/persona/browser/screenshots remain due |

## Header behavior and preservation

The new LWC uses required Vehicle Name and optional Photo__c/model fields through native UI API.
It treats formula IMAGE markup as a presence contract, not an img URL or raw HTML. Only the
existing local NG_VehicleImages WebP pattern is accepted. Missing/omitted/unsafe/failed images,
read errors and navigation/stale responses have explicit states. The image is large/responsive,
uncropped and has model-based alternative text. No new Apex, pricing/approval, permission or
mutation path is added. Scope/accessibility/placement details:
`docs/verification/P7_VEHICLE_PHOTO_HEADER.md`.

The existing gallery, native Vehicle pages/mappings, CP2, approval and domain source remain
untouched. The local scope checker compares prior Batch 2 source hashes and Batch 3 draft prompt
hash; the pending Batch 3 prompt is not in Batch 4's manifest. No static resource/record path
was changed or rebuilt; prior photo license/archive verification is reused, not rerun.

## Focused local checks

```sh
node --test scripts/tests/vehicle_photo_header.test.mjs
python3 scripts/tests/check_p7_batch4.py
```

CONFIRMED — raw Node test totals:

```text
# tests 6
# pass 6
# fail 0
# skipped 0
```

Tests execute real component state with UI API bindings stubbed, covering the formula/path/model
contract, missing optional fields, unsafe URL rejection, failed-image fallback/navigation reset,
stale response/image-event suppression and error clearing. They are not DOM/browser tests or
actual-persona FLS evidence. Local structural/document/link/source preservation output is in
`BATCH4_LOCAL_CHECK.json`. No successful 235-test Apex rerun or full P7-17/DQ gate was needed.

## Scoped native validation and routine correction

Target ID/Developer Edition was confirmed read-only before execution. Command:

```sh
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-batch4-check.xml --test-level NoTestRun --wait 10 --json
```

Initial check-only `0Afaj00000pBWLmCAO` compiled the LWC but rejected the new page:

```text
We couldn't retrieve the design time component information for component force:recordDetail.
```

This was a bounded local component-name error. Under the owner's routine-correction authority,
the supported `force:detailPanel` identifier was verified in Salesforce's official source:
`https://github.com/trailheadapps/lwc-recipes/blob/main/force-app/main/default/flexipages/Contact_Record_Page.flexipage-meta.xml`.
Only the new page's component name was corrected; no native details were removed, no tests or
permissions weakened and no unrelated scope added. Failed receipt is retained as
`BATCH4_CHECK_ONLY_0Afaj00000pBWLmCAO.json`. One corrected exact-scope check then succeeded.

CONFIRMED — raw final Salesforce result excerpts:

```json
{"id":"0Afaj00000pBPvPCAW","status":"Succeeded","checkOnly":true,"completedDate":"2026-10-26T12:44:18.000Z","numberComponentsDeployed":2,"numberComponentsTotal":2,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0,"componentFailures":[],"warnings":[]}
```

Successes are exactly LightningComponentBundle vehiclePhotoHeader and FlexiPage
NG_Vehicle_Photo_Header. Developer Edition accepted NoTestRun; no Apex methods ran. Selected
raw output is preserved in BATCH4_CHECK_ONLY.json without personal creator names/private paths.
Check-only response IDs are transient, not proof of deployment or active placement.

CONFIRMED — targeted post-check Tooling queries for LightningComponentBundle vehiclePhotoHeader
and FlexiPage NG_Vehicle_Photo_Header each return:

```json
{"records":[],"totalSize":0,"done":true}
```

Neither new definition persisted. No page was activated or assigned.

## Genuine outstanding acceptance and exact approval scope

Future Batch 4 Salesforce deployment scope is exactly **two new components** from
`manifest/p7-batch4-check.xml`: vehiclePhotoHeader LWC and NG_Vehicle_Photo_Header FlexiPage.
No Profile, PermissionSet, CustomObject/action override, app, setting, Apex, Flow, asset or
destructive component is selected. Deployment and page placement/activation need separate owner
approval. The Batch 3 one-Draft-prompt scope remains separate and unapproved for deployment.

Actual with/without-photo record-page screenshots, desktop/mobile/visual checks and actual-reader
access remain unexecuted. The five walkthroughs are prepared, not certified as run end-to-end.
Current missing operational identities/permissions cannot be resolved with an admin or old
persona-switch script. No screenshot, native-feature demo or UAT sign-off is invented.

Agentforce agent/usage/persona, Data Cloud space/ingestion/identity, portal enablement/external
security and full regression/DQ/clean-checkout acceptance remain outstanding. Preserve Phase 6
P6-E01–E14 and Phase 5 exceptions, Planning territory/zero assignments and five unmapped Accounts.
Batch 1 browser/gallery/event/page/operational/VIN gates remain deferred; neither Batch 1 nor
Batch 2 is owner-accepted. Batch 4 local completion does not complete M3 or authorize a release tag.
