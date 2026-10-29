# Phase 8 service-history FLS deployment — 2026-10-28 UTC

Only ng-demo 00Daj00001Ae3iWEAR accessed. Exact reviewed one-PermissionSet package validated,
Quick Deployed and read back. No permission assignments or persistent business-data changes.
Customer B authenticated service-history browser retest remains outstanding; Phase 8 NOT complete.

## CONFIRMED — candidate and validation

Reviewed PermissionSet/validator and one-component manifest. Frozen source under submitted_source/;
submitted_hashes.json matches the approved two-field candidate. Before-deploy live readback
confirmed the exact original six FLS entries, three object Reads, one class grant and unchanged
label/description/system flags; candidate differs only by the two approved Read-only additions.

Local validator command: `python3 scripts/tests/validate_p8_dashboard_runtime_permission.py`.
Raw local_validator.stdout.txt / .stderr.txt:
```text
Ran 12 tests
OK
```
The validator's fixed historical "not authorized/not performed" skip strings are not the current
deployment status; actual Salesforce receipts below supersede those local-only labels.

Command:
```sh
sf project deploy validate --target-org ng-demo --manifest manifest/p8-dashboard-runtime-permission.xml --test-level RunSpecifiedTests --tests OwnerPortalFoundationControllerTest --tests OwnerPortalBatchBControllerTest --tests OwnerPortalVehicleBrokerTest --wait 10 --json
```
Raw operations/salesforce_validation.json:
```json
{"id":"0Afaj00000pTnZRCA0","status":"Succeeded","checkOnly":true,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":22,"numberTestsCompleted":22,"numberTestErrors":0}
```
Existing targeted tests cover Foundation/Contact isolation, history/dashboard foreign-row
exclusion/linked-Case masking and broker authorization/capacity/idempotency. Per-method results
in targeted_tests.json. Test-created temporary fixtures roll back; no persistent fixture created.
Their fixture permission sets are historical full-Batch-B combinations, not the new minimal set;
do not claim a new-combination actual A/B runAs or authenticated runtime pass.

## CONFIRMED — exact deployment

Command:
```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000pTnZRCA0 --wait 10 --json
```
Raw operations/deployment.json:
```json
{"id":"0Afaj00000pSzJNCA0","status":"Succeeded","checkOnly":false,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":0,"numberTestsCompleted":0,"numberTestErrors":0}
```
Actual componentSuccesses contains only PermissionSet:PS_Owner_Portal_Dashboard_Runtime.
Quick Deploy reused the successful 22-test validation, no redundant test rerun or extra deployment.
No Apex/LWC/profile/sharing/other metadata included. Source/manifest hashes still match submission.

## CONFIRMED — exact deployed permission delta

Live permission set Id remains 0PSaj00000hHfZ7GAK. FieldPermissions count 6→8:
```json
[{"Field":"Service_Visit__c.Mileage_At_Checkin__c","PermissionsRead":true,"PermissionsEdit":false},{"Field":"Service_Visit__c.Case__c","PermissionsRead":true,"PermissionsEdit":false}]
```
Existing six field-permission values unchanged; zero fields removed. Before/after object CRUD,
class/custom setup access, PermissionSet label/description/activation/system flags identical.
No native Case/Visit write or Vehicle/Model/ledger CRUD/ViewAll/ModifyAll added. No additional
permission assignment: all 39 assignment records compare equal, including A/B's existing runtime
and Foundation rows. User profiles/roles/Contact links, Network criteria/members and Live state
unchanged. No full Batch B or Reviewer assignment to a customer.

## CONFIRMED — scoped security and booking preservation

UserEntityAccess queries target the actual UserIds A=005aj00000guQE9AAM and B=005aj00000guQEAAA2:
```text
Case and Service_Visit__c: Read=true; Create/Edit/Update/Delete=false
Vehicle__c, Vehicle_Model__c, Contact_Vehicle_Relationship__c:
  Read/Create/Edit/Update/Delete=false
```
UserRecordAccess queries cover 14 actual protected records per User, not admin's own record rights:
```text
A: own Contact/Account Read=true; B Contact/Account/Visit/Case Read=false
B: own Contact/Account/Visit a08aj00001UbaiFAAR/Case 500aj00003rhFEbAAM Read=true;
   A Contact/Account Read=false
Both: native Read=false for both Vehicles/Models/all four ledger rows
All sampled records: Edit/Delete/All=false
```
Scope is 28 record checks, not an exhaustive all-record/native-surface audit. The unchanged server
history guard derives the real Contact, uses USER_MODE and masks foreign/inaccessible linked Cases.
Field read on an already readable Visit does not create a record share or allow native writes.

Before/after snapshots compare equal for B's existing Service Visit and Case, including
SystemModstamp, status, customer, vehicle, service, rooftop and datetime. The working booking and
Case 00001102 were not resubmitted, rescheduled, recreated or edited. All four ledger rows and
validity dates unchanged; five scheduler configurations unchanged. Existing 55 development source/
manifest hashes match, including unchanged broker/booking infrastructure. No CP2 metadata deployed
or edited; no full CP2/runtime regression claim.

Selected raw verification.json:
```json
{"claim":"CONFIRMED","checks":{"exact_two_read_only_fls_additions":"CONFIRMED","assignments_otherwise_unchanged":"CONFIRMED","booking_otherwise_unchanged":"CONFIRMED","case_otherwise_unchanged":"CONFIRMED","ledger_otherwise_unchanged":"CONFIRMED","A/protected_record_isolation":"CONFIRMED","B/protected_record_isolation":"CONFIRMED"},"assignmentsAdded":0,"browserRetest":"READY_NOT_PERFORMED","phase8Complete":false}
```

## Errors, limitations and browser retest

No local validation, Salesforce validation, deployment or completed scoped security check failed.
No unexpected permission delta detected. Previously reported UserFieldAccess internal errors were
not retried: deployed FLS and assignment inheritance verified via live FieldPermissions/assignments;
effective native CRUD and record access via per-user UserEntityAccess/UserRecordAccess. This does
not replace a real authenticated history response or every native FLS surface test.

**Customer B's service-history browser retest is ready.** Log in normally as B, refresh Service
history and check that existing Requested Visit a08aj00001UbaiFAAR appears, with blank mileage
until check-in and its own linked Case. History has no status/past-date filter; do not change
Requested to Completed or submit another booking to make it appear. Authenticated browser test
NOT PERFORMED here; no browser UAT pass or Phase 8 completion claim.

No Git commands, unrelated cleanup, ng-dev access, profile/sharing/record modification, permission
assignment, scheduler activation or extra metadata deployment. Documentation/evidence only updated
outside the exact deployed PermissionSet; unrelated working-tree modifications preserved.
