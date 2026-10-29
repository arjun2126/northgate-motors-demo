# Bounded ownership recovery — validated ledger/reconciler, customer features remain gated

## Actual fixture cause, measured before correction

The test-created reviewer copied only the running user's ProfileId, not the running user's
permission-set assignments. Its only assigned capability was the new ledger reviewer set.
At API 68, database operations default to USER_MODE (versioned change at API 67), so an
Administrator profile name does not bypass absent custom-field FLS.

CONFIRMED — diagnostic `0Afaj00000pPPkDCAW`, preserved in `diagnostic_validate.json`:
```text
FIXTURE_DIAGNOSTIC user=005aj00000gsbLlAAI profile=00eaj00000T6Z8rAAF type=Standard objectCreate=true fieldCreate={"Reserved_By__c":false,"VIN__c":false,"Vehicle_Model__c":true} dmlCount=1 dmlFields=["VIN__c","Reserved_By__c"] status=CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY message=Operation failed due to fields being inaccessible on Sobject Vehicle__c, check errors on Exception or Result!
```
`execution_actor.json` identifies that Profile as System Administrator. `actor_assignments.json`
shows the actual runner has additional permission sets; the new reviewer did not inherit those.
`inventory_test_permissions.json` confirms the existing INTERNAL PS_Demo_Admin_No_Bypass grants
editable VIN/Reserved_By. Live VehicleTriggerHandler, ReservationGuard, Counters and VinValidator
match local source apart from terminal newline (`vehicle_automation.json`). Vehicle before-trigger
sets VIN validity and reservation fields; counters return on null Rooftop in this fixture. Those
production paths were not changed. This was missing test-persona inventory authority, not a
demonstrated inventory/security defect.

Salesforce authoritative versioned behavior:
https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_enforce_usermode.htm
"In API version 67.0 and later, Apex runs in user context by default, meaning that the current
user's permissions and field-level security (FLS) are enforced during code execution."

## Corrections, no permission expansion

- Test-only builder user receives the existing INTERNAL PS_Demo_Admin_No_Bypass; construction
  and reservation-preservation snapshots run under that actor with explicit assertions that
  existing inventory FLS is present. The real reviewer retains only its narrow reviewer set;
  all ledger operations/assertions still run as reviewer and customer denial assertions as Plus.
  No external permission metadata or live user assignment changed. All test records roll back.
- Added missing `OwnerPortalShareReconcilerTest.cls-meta.xml`; fixed a new test nickname prefix
  to fit the platform's 40-character limit. No production limit or test assertion relaxed.
- A subsequent reviewer query failed on Delivery.Buyer__c even for an empty source-Delivery
  set (`0Afaj00000pPRR3CAO`). Evidence lookup now runs ONLY when a source Delivery is present
  and remains WITH USER_MODE; unavailable evidence still fails closed. No Delivery FLS granted.
- Made database modes explicit in the already approved privileged integrity/revocation
  infrastructure. Parent locks and cross-reviewer ledger conflict checks, self-contained share
  reconciliation and app-reason share deletes use SYSTEM_MODE only AFTER the existing internal
  Standard-user/custom-permission gate. Otherwise API 68's USER_MODE default overrides the
  without-sharing declaration and can hide conflicts or prevent managed revocation. No customer
  endpoint, Vehicle read capability or generic privileged service was added. Public reviewer
  verify/revoke operations remain USER_MODE, Delivery evidence review remains USER_MODE.
- Added lifecycle tests for unchanged-ledger expiry evaluation, stale and misaddressed app
  shares, preservation of unrelated Manual shares, service-only/missing owner denial, actual
  same-Account foreign-ID native denial, and scheduler/batch execution in rolled-back tests.
  Test async execution is not live cron activation. No production schedule was created.

Intermediate failures are retained, not overwritten: diagnostic_validate.json, recovery_validate.json
(missing test metadata), focused_validate.json (Delivery FLS), mode_explicit_validate.json
(reservation snapshot FLS), final_validate.json (nickname length). validate.json is the first
successful 10-test result; accepted_validate.json is the final 11-test scope after adding the
explicit foreign-ID criterion. No unrelated tests or full-project audit performed.

## CONFIRMED — final scoped Salesforce validation

```sh
sf project deploy validate --target-org ng-demo --manifest manifest/p8-ownership-reconciliation-local.xml --test-level RunSpecifiedTests --tests OwnerPortalOwnershipTest --tests OwnerPortalShareReconcilerTest --wait 10 --json
```
Raw fields (`accepted_validate.json`):
```json
{"id":"0Afaj00000pNyKhCAK","status":"Succeeded","checkOnly":true,"numberComponentErrors":0,"numberComponentsTotal":24,"numberTestsTotal":11,"numberTestsCompleted":11,"numberTestErrors":0}
```
Raw coverage counts, derived percentages (`verification.json`):
```json
[{"name":"ContactVehicleRelationshipTrigger","covered":5,"locations":5,"percent":100.0},{"name":"OwnerPortalShareReconciler","covered":57,"locations":57,"percent":100.0},{"name":"OwnerPortalOwnershipGuard","covered":100,"locations":108,"percent":92.593},{"name":"OwnerPortalOwnershipService","covered":18,"locations":18,"percent":100.0}]
```
No LWC source changed, so no LWC test rerun or rendered acceptance claim. No real portal login,
live/native API session or concurrency/load acceptance performed. Plus runAs native USER_MODE
denials are measured in isolated tests; positive owned-Vehicle customer display is not delivered.

## Scope of lifecycle proof / limits

Tests pass for ledger Pending/evidence/server-stamp/immutable/delete rules; same-Account conflicting
ownership; separate service consent; half-open intervals/revocation clipping; immediate termination
removing app-only shares and dependent consent; preserved reservation/Manual shares; bulk Pending;
customer/reviewer authorization; valid managed grant retained before expiry; app grant and ledger
share removed at simulated expiry without ledger edit; stale-grant batch recovery; missing-owner/
service-only/group recipient pruning; and a known foreign Vehicle denied to actual Plus A while
misaddressed share exists. Native denial relies on NO Vehicle object permission, intentionally.

Explicit revocation is transactional for application-owned grants. Clock expiry still needs
maintenance to execute before a stale native share is removed; scheduling/recalculation provides
no demonstrated exact deadline. No immediate native-access guarantee is claimed for a future
Vehicle CRUD grant. Unrelated grants remain untouched and can independently authorize access if
object permissions are later granted. There is no secure basis to enable native Vehicle reads on
the assumption that a scheduled job will run precisely at expiry.

## P8-05/P8-07 and one outstanding architecture decision

Both features remain fail-closed, NOT completed. The current native-sharing/USER_MODE approach
does not safely meet exact time-based native denial, so customer Vehicle rights and appointment
creation were not enabled. Existing source/controller/LWCs/capacity/intake/CP2 remain unchanged.

One concrete alternative: `docs/architecture/P8_NATIVE_VEHICLE_ACCESS_DECISION.md`.
Keep customer Vehicle/ledger CRUD and Visit native Create disabled; implement a minimal privileged
capability broker that resolves the caller, checks current Contact-specific ownership/conflicts/
expiry and separate service authority on every request, exposes only safe Vehicle/photo DTOs,
and performs guarded booking through existing capacity/intake. This requires explicit approval
of the system-mediated broker amendment to the prior USER_MODE data-access design, not routine
debugging approval. No such broker implemented without that decision.

## Deployment readiness and preservation

The LEDGER/REMOVE-ONLY RECONCILER candidate passes check-only: exact 24 components selected by
`manifest/p8-ownership-reconciliation-local.xml`, 31 source/manifest file hashes in
`submitted_source_hashes.json`. This is not the full Phase 8 feature package. Approval to deploy
is still separate; no live sharing, cron/recalculation activation or customer rights implied.
Maintainer assignment/activation/monitoring and hierarchy configuration remain later decisions;
starting an hourly job alone cannot resolve the strict expiry boundary.

CONFIRMED — selected `verification.json` fields:
```json
{"customerVehiclePermissionAdded":false,"existingBatchCSourceUnchanged":true,"p805Complete":false,"p807Complete":false,"deploymentOccurred":false,"jobsActivated":0,"sourceFiles":31}
```
No metadata deployment, live record/ownership changes, external-user creation or assignment,
sharing/OWD/site/publication/job activation, Git staging/commit/push/cleanup or ng-dev access.
Historical Phase 1–7 exceptions and M4 nonacceptance preserved. Read-only Git snapshot is retained
in git_status.txt/git_status_summary.json; unrelated dirty work was not reverted or overwritten.
