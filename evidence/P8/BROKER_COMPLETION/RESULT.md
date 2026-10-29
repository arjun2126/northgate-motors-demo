# P8-05/P8-07 broker completion — local validated candidate, NOT deployed

Owner approved the server-mediated model in P8_NATIVE_VEHICLE_ACCESS_DECISION.md. All work is
local source/tests or check-only against ng-demo `00Daj00001Ae3iWEAR`. No Git commands, actual
deployment, live customer/ownership/user/share/permission changes, publication or job activation.

## CONFIRMED — final scoped validation

Command:
```sh
sf project deploy validate --target-org ng-demo --manifest manifest/p8-broker-local.xml --test-level RunSpecifiedTests --tests OwnerPortalVehicleBrokerTest --tests OwnerPortalOwnershipTest --tests OwnerPortalShareReconcilerTest --tests OwnerPortalBatchBControllerTest --tests ServiceVisitCapacityGuardTest --tests ServiceIntakeCaseServiceTest --wait 10 --json
```
Raw `validate.json` fields:
```json
{"id":"0Afaj00000pPiV7CAK","status":"Succeeded","checkOnly":true,"numberComponentsTotal":34,"numberComponentErrors":0,"numberTestsTotal":43,"numberTestsCompleted":43,"numberTestErrors":0}
```
Raw coverage counts/derived percentages from `verification.json`:
```json
[{"name":"OwnerPortalVehicleBroker","covered":150,"locations":153,"percent":98.039},{"name":"ServiceIntakeCaseService","covered":33,"locations":33,"percent":100.0},{"name":"OwnerPortalBatchBController","covered":123,"locations":140,"percent":87.857},{"name":"ContactVehicleRelationshipTrigger","covered":5,"locations":5,"percent":100.0},{"name":"ServiceVisitCapacityGuard","covered":87,"locations":89,"percent":97.753},{"name":"OwnerPortalOwnershipService","covered":18,"locations":18,"percent":100.0},{"name":"OwnerPortalShareReconciler","covered":57,"locations":57,"percent":100.0},{"name":"OwnerPortalOwnershipGuard","covered":100,"locations":108,"percent":92.593}]
```
Why these tests: new broker behavior; changed existing facade; authoritative capacity/intake SQL
mode changes; and undeployed ledger/trigger/reconciler dependencies included in this one candidate.
No full-project/CP2 test rerun. Existing pricing/approvals/inventory/reservation/service-history/
loyalty code was not changed. Ownership ledger's 31 previously validated source/hash entries are
all unchanged (`ledger_preservation.json`), including its old scoped manifest.

## CONFIRMED — targeted local UI/state/source tests

```sh
node --test scripts/tests/p8_batch_b_ui.test.mjs scripts/tests/p8_batch_c_ui.test.mjs scripts/tests/p8_broker_ui.test.mjs
```
Raw `ui_tests.tap`:
```text
# tests 25
# pass 25
# fail 0
```
Includes guest/no-ownership no-write, read-failure state clearing, cursor-only pagination, selected
details/photo failure, service-consent filtering/catalog, review/validation, stable retry token,
input-change token reset, duplicate-click/success guards, field allowlists and source accessibility
semantics. These are component-method/markup tests, NOT real-browser/screen-reader/keyboard UAT.
One historical test asserting submit did not exist was replaced with a no-write assertion for
missing eligibility; no security assertion relaxed. No new tests run after these UI sources froze.

## Implemented capability and security boundary

- `OwnerPortalVehicleBroker`: every public method resolves real Foundation caller (active exact
  Plus license/custom permission/own Contact/Account/exact Live Network). Private test seams still
  compare their Contact to the real caller; no public caller-selected identity or site override.
- Global internal ledger policy checks ALL current owner rows for conflicts, exact Contact,
  reviewed evidence/stamps, From inclusive/To exclusive/revocation dates. Missing, unverified,
  expired, revoked, foreign, Account-only or reservation-only authority fails closed. Service
  consent is a distinct reviewed row, required independently for options and booking.
- Vehicle DTO list is bounded/paged (20 at a time, max 1000 pilot ownership candidates), returns
  only own vehicle identifier/label/model/year/colour/condition/validated photo URL and service
  eligibility. No raw SObjects, VIN, cost/pricing/finance/reservation/customer/evidence fields.
- Photo__c is evaluated but its IMAGE markup is never injected. Only the existing exact local
  `/resource/NG_VehicleImages/[a-z0-9_]+.webp` contract is returned with native image alt/fallback.
  Stock-photo limitations are labelled; no asset or inventory colour data altered.
- No customer Vehicle/Model/ledger CRUD, native Visit Create/Edit/Delete, API Enabled or new
  customer class permission set added. Native foreign reads/writes remain denied even while the
  broker delivers own DTOs/guarded writes. A clock cleanup job is NOT the authorization boundary.
- Non-cacheable facade endpoints: getVehicles/getVehiclePage, getAppointmentOptions and
  bookAppointment. Legacy requestAppointment without a durable token remains no-write.
- Customer history, Case/comment and loyalty USER_MODE read/write paths remain intact.

## Booking / capacity / idempotency

Native LWC wizard selects owned+service-authorized Vehicle, server-filtered active Service_Center/
Full_Service Rooftop with positive capacity, active native service type and future time, then reviews
and submits. No client Contact/Account/owner/status/Case selector is accepted. Input IDs/types,
catalog membership and eligibility are revalidated server-side; bypassed service automation denies
broker writes. Capacity full/invalid/unauthorized replies are generic and never assumed successful.

Broker locks Vehicle through authorization/commit (same parent lock as ledger revocation), rechecks
eligibility immediately before insert and after the trigger completes; expiry while waiting aborts
and rolls back Visit/intake effects. Writes use explicit system mode only inside this limited
capability. Visit derives own Contact, caller OwnerId, Requested status and approved fields.
The existing ServiceVisitTrigger remains unchanged, reusing ServiceVisitCapacityGuard's Toronto
day locks/counts and ServiceIntakeCaseService's Service/Q_Service_Intake Case creation/linking.

Only required infrastructure changes: capacity's authoritative count query explicitly SYSTEM_MODE;
intake's existing Group/Contact queries explicitly SYSTEM_MODE. API 68 otherwise applies caller
FLS/sharing to these trigger-owned operations. No replacement booking/capacity/Flow introduced.

Two new optional Visit fields (no customer FLS grants) implement durable request identity:
- Portal_Request_Key__c: unique case-sensitive 64-character SHA-256(Contact + client UUID).
- Portal_Request_Fingerprint__c: SHA-256 of the canonical Vehicle/Rooftop/start/service payload.

Dates normalize to stored second precision before persistence/hash/duplicate checks. Same-token
same-payload retries return the original own Visit; changed payload denies. A different token for
an equivalent active request also denies. Unique-index races roll back and only return an exact
authorized matching receipt. Frontend retains token on transient failure, changes it on edited
input, and suppresses double submit. No new persistence object or competing workflow.

## What was tested versus acceptance still pending

Actual Plus A/B share an Account; C has another Account. Tests prove own DTOs and independent
consent, same-/cross-Account foreign denial, expired/reserved-only/missing authority, forged caller
and IDs, unsafe photos, revocation without maintenance, native Vehicle/ledger/Visit-create denial,
safe public-site/internal denial, tampered token/date/service/location, one own Visit + routed
intake Case/link, durable replay/payload binding, duplicate request denial and global capacity
rollback without orphan Case. Additional policy tests use in-memory conflicting/time-bound rows
because the validated ledger prevents inserting conflicting verified data. Capacity/intake existing
regression suites and the unchanged ledger/reconciler suites also pass in this scoped candidate.

No real customer accounts/users/ownership were assigned or repaired. Test fixtures/async work
roll back inside check-only. No real customer-login, actual/native HTTP API session, responsive
screenshot, assistive-technology, live race/load test, publication or owner acceptance is claimed.
Positive actual endpoints still require approved identities/access, reviewed ownership AND service
consent, catalog/record visibility, page placement and controlled publication. Existing queued
Case visibility remains subject to the separately approved narrow sharing/access plan.

No remaining broker architecture/implementation blocker is demonstrated. P8-05 and P8-07 are
implemented and scoped-validated LOCALLY, not deployed/operationally accepted. Scheduler precision
is no longer a gate for broker Vehicle access because native CRUD stays denied and each request
checks current ledger authority. Prior downloaded data cannot be remotely erased.

## Exact separate deployment scope

`manifest/p8-broker-local.xml` — 34 components in one candidate:
- Unchanged validated ledger/reconciler prerequisites (24): ledger object + 13 fields, two app
  sharing reasons, internal custom permission/reviewer set, five Apex classes and ledger trigger.
- OwnerPortalVehicleBroker and OwnerPortalVehicleBrokerTest (2 classes).
- Service_Visit__c.Portal_Request_Key__c and Portal_Request_Fingerprint__c (2 fields).
- OwnerPortalBatchBController, ServiceVisitCapacityGuard, ServiceIntakeCaseService (3 classes).
- ownerPortalHome, ownerPortalVehicles, ownerPortalAppointment (3 existing bundles).

Exact receipt list `component_scope.json`; 55 source/manifest hashes `submitted_source_hashes.json`.
Not included: Foundation/profile/other customer permissions, other three portal bundles, users,
share records, ownership data, Native CRUD grants, cron/recalculation activation, Builder/site/page
navigation/publication, unrelated source or destructive changes. No deployment authorized/executed.

Intermediate clear errors preserved: validate_initial.json (status-code String comparison),
validate_compiled.json/compiled_report.json (native denial throws TypeException; DateTime payload
round-trip changed milliseconds). Corrected type-specific negative test and canonical time contract;
the final 43/43 result validates exact source. No swallowed security assertion or runtime bypass.
