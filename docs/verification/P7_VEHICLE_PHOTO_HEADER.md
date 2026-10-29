# P7-23 — Vehicle photo header and placement boundary

**Final deployment update:** the two definitions are deployed as 0Afaj00000pCURZCA4. Native
readback confirms both exist; Vehicle object/all 37 application assignment snapshots are unchanged.
No page assignment/activation occurred. Earlier local/check-only history below remains valid;
placement, actual-reader/browser/with-without-photo evidence is still unexecuted. Current receipt:
`evidence/P7/P7_FINAL_DEPLOYMENT.md`.

## Delivered locally

vehiclePhotoHeader is a read-only record-page LWC. Lightning UI API getRecord supplies required
Vehicle.Name plus optional Photo__c, model Name and model Image_Path__c under the current record/
field access. Optional omissions produce a fallback, not a system-mode reread or a permission
grant. No Apex, financial fields, mutation, static-resource rebuild or gallery refactor is added.

Photo__c is IMAGE markup. The component requires a nonblank formula value and the same exact
local `/resource/NG_VehicleImages/<lowercase_name>.webp` path contract already used by the gallery.
It never inserts raw formula HTML or accepts remote/script/data URLs. Images use contain scaling,
not cropping. A model line, meaningful alt text, loading indicator, generic access-error alert and
Photo unavailable status cover optional/missing/failed images. Noninteractive content adds no
keyboard trap or unnecessary focus target. Navigation clears old content; stale record/image
responses are ignored. These source/state properties are not a full browser accessibility audit.

NG_Vehicle_Photo_Header is a new, unassigned Vehicle FlexiPage. It keeps native highlights and
details plus existing vehicleServiceHistory, placing the photo header first in the main region.
Existing NG_Vehicle_Service_History, Vehicle object/page mappings and app assignments are unchanged.
The new page does not become an active org/app/profile default merely by validating its metadata.

## Scope and checks

`manifest/p7-batch4-check.xml` contains exactly the new LWC bundle and new FlexiPage. Native
check-only `0Afaj00000pBPvPCAW` passes 2/2 with NoTestRun, zero errors/warnings; no Apex changed or
tests were needed. Six focused Node state tests pass with platform bindings stubbed. Actual
UI API/persona/FLS, DOM, visual accessibility and record-page screenshots are not verified.

The first scoped validation rejected the draft page's unsupported `force:recordDetail` identifier.
Salesforce's official lwc-recipes Contact_Record_Page source uses `force:detailPanel`; that exact
standard identifier was substituted, preserving native detail functionality. The same two-component
scope then passed. No existing component/page or access rule was changed to bypass the error.
Both job receipts and the exact error remain in evidence; no metadata was deployed.

## Future approvals and actual acceptance

1. Owner approves the two-component metadata deployment separately. Batch 3 NG_Case_Triage is not
   part of this manifest and must not be deployed implicitly with the header.
2. Owner chooses preview/placement and any eventual app/profile/record-type/form-factor assignment.
   No current page may be replaced or activated automatically. No permission change is implied.
3. Use an existing authorized Vehicle and actual approved reader. Verify photo/model line, native
   details/history and browser console/errors, on the intended desktop/mobile surface. Record
   actual actor/profile/time and screenshot evidence; admin context is not other-persona proof.
4. Capture `evidence/P7/vehicle_header.png` with a photo. For without-photo evidence, use an already
   missing/inaccessible image if available, or owner-approved browser-only image-request blocking
   clearly labeled as a simulated load failure, then unblock/reload. Do not change image paths,
   VINs, model records or business data to manufacture the case. Do not substitute a mock screenshot.
5. Record with/without-photo, missing optional-field and denied-record outcomes honestly. If the
   actual persona or required placement is unavailable, mark BLOCKED and obtain owner disposition.

Placement, actual rendering/screenshots and live persona acceptance remain unexecuted. Existing
Batch 1 photo/gallery/event/page/access/VIN gates and Batch 3 native/regression gates remain open.
