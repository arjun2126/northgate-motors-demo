# Phase 7 Batch 1 — local execution and exact check-only

**Asset status update:** the owner subsequently replaced the AI-photo requirement with licensed
real stock photography. Thirty complete CC0 photographs now package/validate separately as
NG_VehicleImages; the initial unavailable-photo blocker below is historical and resolved under
that amendment. See `P7_22_STOCK_PHOTOS_2026-10-25.md`. No application code or gallery redesign
was needed, and this original 21-component/163-test payload remains unchanged, not deployed.

## Status

Local P7-01–P7-06 implementations compile and pass focused/affected regression checks.
P7-22's existing path contract is confirmed, but the required thirty approved AI-generated
photos are unavailable; no image-generation tool is available in this environment. No fake,
stock, renamed or diagram substitute is labelled as the required photographs. No incomplete
static resource is in the validated package. **Batch 1 is not fully accepted or deployed.**

Owner authorizes local implementation, isolated tests, ordinary corrections and scoped check-only
against ng-demo `00Daj00001Ae3iWEAR` only. No deployment, persistent record/image/VIN changes,
credentials, assignments, pages, jobs or Git staging/commit/push. Phase 6 remains OWNER-ACCEPTED
WITH DOCUMENTED EXCEPTIONS — October 24, 2026. Its evidence/exceptions were not reopened.

## Results by block

| Block | Local result | Remaining gate |
|---|---|---|
| P7-22 | Confirmed all 30 existing paths already name `/resource/NG_VehicleImages/<make>_<trim>.webp`; documented exact filenames and body-style preservation | BLOCKED actual photographs/resource/visual acceptance. Resource excluded from package; no path writes needed if approved files match |
| P7-01 | Gallery LWC/tab and USER_MODE browse/filter/keyset paging; explicit image failure fallback; permission-gated locked reservation; accessible Contact check; private/Invoice fields excluded | Actual deployment, actor assignment, tab/page placement and browser/photo acceptance are deferred |
| P7-02 | Opportunity estimator LWC/controller reuses accepted equity, rate and payment services; no Quote/Trade/Financing writes or hardcoded rates | Actual placement/browser acceptance deferred; configured rates require the narrowly declared metadata read access |
| P7-03 | Permission-gated simulation-only client, request/response contract boundary, unavailable handler, loopback mock provider and tests | NG_VIN_Mock is not configured. Positive named-credential wire/principal/actual timeout acceptance needs separately approved reachable mock host/configuration; no credentials created |
| P7-04 | `docs/integration/API_CONTRACT.md` matches actual request, fictional provider, response validation, errors and no-mutation boundary | No manufacturer decoder or real provider claim |
| P7-05 | Native PublishAfterCommit event with minimal payload; existing Vehicle after-update hook; gallery subscription/refresh/cleanup | Real multi-session/browser delivery, reconnect-gap recovery and durable retry guarantees are not verified |
| P7-06 | `docs/architecture/EVENTS_CDC_PUBSUB.md` describes actual events and absent CDC/external consumers | No CDC enablement, external Pub/Sub client, credentials or replay checkpoint implemented |

## Exact package and source changes

Manifest: `manifest/p7-batch1-check.xml`. Exactly 21 Salesforce components:

| Type | Exact components |
|---|---|
| ApexClass (new production) | InventoryGalleryController; OpportunityCalculatorController; VinDecoderService; VehicleReservationEventPublisher |
| ApexClass (new tests/fixture) | InventoryGalleryControllerTest; OpportunityCalculatorControllerTest; VinDecoderServiceTest; VehicleReservationEventPublisherTest; P7Batch1TestData |
| ApexClass (existing, changed) | VehicleCounters |
| ApexTrigger (existing, changed) | VehicleCounterTrigger |
| CustomObject | Vehicle_Reserved__e |
| CustomField | Vehicle_Reserved__e.Vehicle_Id__c; Vehicle_Reserved__e.Reserved_At__c |
| CustomPermission | Reserve_Inventory_Vehicle; Decode_Inventory_VIN |
| PermissionSet | PS_Inventory_Gallery; PS_Opportunity_Calculator |
| LightningComponentBundle | inventoryGallery; opportunityCalculator |
| CustomTab | Inventory_Gallery |

Every Apex class has its metadata companion. No prior regression test source is packaged;
existing tests execute their deployed versions. No unrelated dirty test changes, existing Sales
application/page, CP2/finance/loyalty/consent source, Flow, static resource, Named Credential or
image/model data is included.

Two bounded existing runtime edits:

1. VehicleCounterTrigger retains its contexts, bypass and old/new rooftop counting, then calls
   the event publisher for updates. No additional Vehicle trigger.
2. VehicleCounters changes only its derived-cache DML to explicit SYSTEM_MODE. The Sales actor
   is intentionally Read-only on Vehicle/Rooftop; an otherwise authorized reserve exposed a
   USER_MODE Rooftop cache-write error. Internal recomputation must not require granting the
   UI actor general Rooftop Edit. All callers were located; the trigger is the existing caller.

The inventory writer validates its explicit custom permission, automation-not-bypassed state,
Contact visibility, Vehicle visibility/type and Available/unreserved state under a row lock.
Only the reserver field is changed through narrow system DML; the accepted guard stamps status/
time and the existing trigger maintains counters/events. Sold, stale, denied, hidden-Contact and
bypassed cases reject. Existing reservation guard/VIN/image paths are not rewritten.

Permissions remain local metadata only. The gallery set adds read fields/objects, the two
capabilities and native event Create/Read, not direct Vehicle Edit or Invoice/Finance access.
Calculator set adds class access and Rate_Table__mdt read only, no Financial-record access.
No actual assignment was performed. Platform Event Create is limited to the new notification
object; the event contains Vehicle Id/time, not customer-reserver/financial data.

## Event failure compatibility

Reservation source truth is the committed Vehicle. Refresh enqueue failure must not invalidate
accepted legacy writers merely because they lack a new event permission. The publisher counts/
logs enqueue failures and retains manual refresh; gallery actors have native event Create/Read.
No silent delivery guarantee, durable outbox or callback retry exists. The code's deliberate
ceiling is documented with a ponytail comment. Tests prove a legacy writer without the new event
permission can still reserve, rather than weakening the old reservation contract.

## Validation chronology and ordinary corrections

- `0Afaj00000p2ggvCAA`: compile/metadata errors before tests. HttpRequest has no getTimeout()
  accessor; test checks GET/Accept/endpoint while source uses setTimeout(5000). Removed invalid
  FLS for required Vehicle_Model__c lookup; parent object access remains declared.
- `0Afaj00000p2gozCAA`: 20 components compile; seven/ten tests pass. Found the internal Rooftop
  cache write, missing rate metadata read and unavailable VIN transport. Fixed the precise cache
  DML context, declared the minimum metadata access and split VIN tests at actual request/response
  boundary instead of configuring prohibited credentials or using Test.isRunningTest bypasses.
- `0Afaj00000p2hOTCAY`: 21 components compile; nine/ten tests pass. New notification permission
  exposed a reservation rollback risk. Added event Create to the local gallery set and made
  notification failure log/count-only to preserve legacy reservation behavior; added explicit
  legacy-writer regression rather than granting broad edit rights.
- `0Afaj00000p2MqJCAU`: focused check succeeds, 21/21 components, 11/11 methods.
- Final coordinated check below succeeds on the same exact 21-component source boundary.

No failed request was repeated without an identified correction. Production code was not given
a test-mode endpoint or static retry cache; no existing test was edited to force a pass.

## Final exact scoped check-only

Command:

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p7-batch1-check.xml --test-level RunSpecifiedTests --tests InventoryGalleryControllerTest --tests OpportunityCalculatorControllerTest --tests VinDecoderServiceTest --tests VehicleReservationEventPublisherTest --tests VinValidatorTest --tests VehicleReservationGuardTest --tests PaymentCalculatorServiceTest --tests TradeIn_Calc_EquityTest --tests RateTableServiceTest --tests TestDriveBookingGuardTest --tests TestDriveFollowUpTest --tests QuotePricingServiceTest --tests QuoteBuilderControllerTest --tests FinanceApplicationControllerTest --tests FinancingStatusServiceTest --tests QuoteSummaryControllerTest --tests DeliveryCloseServiceTest --tests LoyaltyAccrualServiceTest --tests VehicleServiceHistoryControllerTest --tests ConsentGateServiceTest --async --json
sf project deploy report --target-org ng-demo --job-id 0Afaj00000p2bfeCAA --json
```

CONFIRMED — raw final result excerpts:

```json
"id": "0Afaj00000p2bfeCAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-25T04:03:38.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 21,
"numberComponentsTotal": 21,
"numberTestErrors": 0,
"numberTestsCompleted": 163,
"numberTestsTotal": 163,
"componentFailures": [],
"numTestsRun": 163,
"numFailures": 0,
"failures": [],
"codeCoverageWarnings": []
```

CONFIRMED — raw component projection:

```json
"simulatedCreatedComponents": 19,
"modifiedExistingComponents": ["VehicleCounters","VehicleCounterTrigger"],
"allComponentsSuccessful": true
```

Created states and numberComponentsDeployed in this output are check-only simulation, not a live
deployment. All 20 selected test classes ran: 11 new methods plus 152 deployed regression methods.
No selected Salesforce source changed after this final request; later edits update documentation.

CONFIRMED — raw scoped coverage:

```json
[
  {"name":"InventoryGalleryController","numLocations":40,"numLocationsNotCovered":0},
  {"name":"VehicleCounters","numLocations":17,"numLocationsNotCovered":1},
  {"name":"VehicleReservationEventPublisher","numLocations":16,"numLocationsNotCovered":0},
  {"name":"VinDecoderService","numLocations":24,"numLocationsNotCovered":1},
  {"name":"OpportunityCalculatorController","numLocations":20,"numLocationsNotCovered":0},
  {"name":"VehicleCounterTrigger","numLocations":16,"numLocationsNotCovered":1}
]
```

Coverage is 100% for gallery/calculator/publisher, 95.83% VIN, 94.12% cache helper and 93.75%
modified trigger. It is not org-wide coverage or proof of positive credentialed wire/browser use.

## Local client/provider checks

`node --test scripts/tests/p7_batch1_ui.test.mjs` runs real client state methods with native
platform bindings stubbed using Node's built-in VM/assert/test, not a new framework dependency.
It does not render templates or claim a browser session. CONFIRMED — raw TAP summary:

```text
# tests 4
# suites 0
# pass 4
# fail 0
# cancelled 0
# skipped 0
# todo 0
```

Checks cover stale filtered responses, unavailable image fallback, Contact-required reservation/
refresh, late subscription cleanup and stale estimator response/explicit zero-rate handling.

`PYTHONDONTWRITEBYTECODE=1 python3 scripts/tests/p7_vin_mock_test.py` checks the provider offline.
An initial Python year-property typo was corrected without changing the contract. CONFIRMED:

```text
PASS: VIN mock success, schema, invalid format/characters and missing route; no network requests.
```

No local provider server was started. HTTP tests/parser fixtures are simulated. A valid positive
Named Credential callout and a real timeout remain unverified; NG_VIN_Mock is absent. Reachable
endpoint, credentials/principals and actual gallery/browser deployment are separate gates.

## Asset/path readiness and measured limits

Read-only model inventory confirms exactly 30 existing paths, already matching the required
resource/filenames. No record edit or backfill is needed to add matching approved assets.
`docs/assets/P7_IMAGE_ASSET_READINESS.md` captures the contract and blocked photo delivery.

`python3 scripts/tests/check_p7_batch1_package.py` verifies the explicit member boundary, native
after-commit property, no credential/Flow/profile/static-resource packaging, no direct Vehicle
Edit and the exact 30-file model/path contract. It does not count placeholders as photos.
CONFIRMED — raw output:

```json
{"status":"PASS","scope":"package and path contract only","metadataMembers":21,"expectedPhotoFiles":30,"availablePhotoFiles":0,"photoAcceptance":"BLOCKED","eventPublishBehavior":"PublishAfterCommit","credentialMetadata":0,"vehicleEditGranted":false}
```

CONFIRMED — filtered raw live limits:

```json
[
  {"name":"DailyStandardVolumePlatformEvents","max":10000,"remaining":10000},
  {"name":"FileStorageMB","max":20,"remaining":20},
  {"name":"HourlyPublishedPlatformEvents","max":50000,"remaining":50000}
]
```

CONFIRMED — filtered Named Credential metadata inventory:

```json
{"status":0,"matchingNamedCredentials":[]}
```

Storage headroom is not evidence of missing assets being generated. An incomplete/fallback-only
resource would not satisfy P7-22 or gallery photo acceptance, so none was packaged.

## Preservation, deployment scope and remaining gates

Phase 1–6 runtime/domain services are reused; only the two necessary counter integration files
above are changed. The deployed versions of affected VIN/reservation/test-drive/rate/payment/
equity/CP2/Quote Builder/finance/summary/delivery/loyalty/history/consent tests pass. This does not
reopen Phase 6 acceptance or close its documented exceptions.

No actual deployment, credentials, record/VIN/image-path changes, assignments, page activation,
scheduling, Git staging/commit/push or ng-dev access occurred. Test fixtures/events/assignments
are isolated Apex test data and do not persist. No Batch 2/P7-07 consolidation was started.

Genuine outstanding deliverable: thirty approved AI-generated WebP photos are unavailable.
Supply/generate approved files, then create/validate the complete native resource before claiming
P7-22 or full Batch 1 image acceptance. Further operational gates: approved reachable mock host/
Named Credential/principal; deployment/permissions/placement; actual Sales browser, stream and
photo rendering. No source implementation blocker remains in the 21-component validated payload.

If a later metadata-only deployment is approved, name this exact 21-component scope/stored result
explicitly, recognizing that photos and credential setup are excluded and unverified. A later
complete photo resource changes the package and requires new scoped validation. No deployment
is authorized by this report. Batch 1 is not marked done or accepted solely from check-only success.
