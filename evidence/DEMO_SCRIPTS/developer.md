# Developer walkthrough — CP2 preservation, native boundaries and photo header

## 1. Activate persona

Use the owner-approved existing developer/administrator identity for read-only ng-demo inspection
and local source review. Confirm org ID and current role/profile; no automatic grants or identity
swaps. Administrative tooling is not proof of operational/browser access. Do not run deployment,
data, reset, scheduling or role-switch commands in this walkthrough.

## 2. Trace the preserved lifecycle

Follow LeadRoutingTrigger/LeadTriggerHandler and existing routing/conversion services. Then trace
VehicleTrigger/VehicleTriggerHandler to VIN validation, reservation guard, cache maintenance and
after-commit refresh publication. Show TestDriveTrigger's preserved future-date-before-bypass
contract and follow-up/counter services. Use the existing 235/235 receipt rather than rerun it.

Trace CP2's unique primary-vehicle basis in QuotePricingService, Quote Builder/Summary, trade-in
guards and native approvals. Confirm no Batch 4 Apex or pricing/finance edits. Show the actual
Batch 2 deployment/readback receipts and unchanged unrelated trigger/source evidence.

## 3. New read-only photo surface

Open vehiclePhotoHeader source. Explain required Name plus optional Photo/model fields through
UI API, not a new Apex/system-mode reader. Photo__c is IMAGE markup; only the existing local
NG_VehicleImages WebP path is used for img.src. Show fallback for absent/omitted/unsafe/broken
photos and record-navigation reset/stale-event guards in the focused Node test receipt.

Open the new unassigned NG_Vehicle_Photo_Header page: native highlights, new header, native
details and existing service history. Existing pages/app/object assignments are unchanged.
Local VM state tests are not DOM, screenshot or actual-persona FLS evidence.

Definitions are deployed; after separately approved placement, an actual reader can open an existing Vehicle
with a photo and capture the page. For a fallback screenshot use an already missing/inaccessible
photo if one exists, or an owner-approved browser-only image-request block clearly labeled as
simulated load failure. Unblock/reload afterward. Do not edit paths, VINs or business records.
Current with/without-photo browser screenshots remain unexecuted.

## 4. Regression/release evidence

Review the Batch 4 two-component check-only receipt and exact manifest. Show scripts/test.sh's
plan-only default and P7-17 documentation; a full run is separate and requires genuine storage
evidence. Do not repeat successful suites without a source/release reason or call the dirty
worktree a clean checkout/tag. Draft prompt validation is not a live agent test.

## 5. Close

Record which code/receipts were reviewed, any actual browser steps and outstanding gates. No
metadata/data/permissions change during this tour. Placement, screenshots and full regression UAT
need their own approval/results; retain all Phase 6 and Batch 1 exceptions.
