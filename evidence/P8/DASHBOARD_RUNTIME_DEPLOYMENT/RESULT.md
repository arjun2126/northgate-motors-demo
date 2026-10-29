# Phase 8 dashboard runtime permission deployment — 2026-10-28 UTC

**Deployment and exactly two assignments succeeded. Security validation is PARTIAL; owner browser
UAT has not run. Phase 8 is NOT complete.** Only ng-demo 00Daj00001Ae3iWEAR accessed.

## CONFIRMED — preflight, validation and exact deployment

Reviewed the five owner-specified source/manifest/validator/result/assignment-plan files. Manifest
has exactly one PermissionSet. Source and manifest SHA-256 match the reviewed candidate; frozen
inputs in submitted_source/, submitted_hashes.json. Existing 55 deployment source/manifest hashes
still match. No unrelated working-tree cleanup or Git operation.

Existing local validator rerun, raw local_validator.stdout.txt / .stderr.txt:
```text
Ran 10 tests
OK
```
Its fixed "skipped/not authorized" strings are historical local-validator output, not current owner
authority; actual Salesforce execution receipts below supersede them. Validator/source unchanged.

Command:
```sh
sf project deploy validate --target-org ng-demo --manifest manifest/p8-dashboard-runtime-permission.xml --test-level RunSpecifiedTests --tests OwnerPortalFoundationControllerTest --tests OwnerPortalBatchBControllerTest --tests OwnerPortalVehicleBrokerTest --wait 10 --json
```
Raw operations/salesforce_validation.json:
```json
{"id":"0Afaj00000pTPCACA4","status":"Succeeded","checkOnly":true,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":22,"numberTestsCompleted":22,"numberTestErrors":0}
```
Existing targeted tests use temporary test-transaction fixtures, rolled back by Salesforce; no
persistent business/test fixture was created. Their runAs actors use existing fixture permission
sets, not the new minimal set. Do not describe this as a new-combination/live-A/B runtime pass.
Per-method successes preserved in targeted_test_results.json.

Command:
```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000pTPCACA4 --wait 10 --json
```
Raw operations/deployment.json:
```json
{"id":"0Afaj00000pT3OYCA0","status":"Succeeded","checkOnly":false,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":0,"numberTestsCompleted":0,"numberTestErrors":0}
```
Quick Deploy reused the successful 22-test validation; tests were not rerun at deployment.
Actual componentSuccesses verifies only PermissionSet:PS_Owner_Portal_Dashboard_Runtime.
No Apex/LWC/profile/other metadata deployed, no fallback or additional deployment.

## CONFIRMED — exact live permission set and assignments

PermissionSet Id=0PSaj00000hHfZ7GAK, Name=PS_Owner_Portal_Dashboard_Runtime.
Live ObjectPermissions/FieldPermissions/SetupEntityAccess queries match the reviewed delta:
```text
1 Apex class: OwnerPortalBatchBController (01paj00000c9U5pAAE)
3 object Read grants: Case, Service_Visit__c, Loyalty_Member__c
6 field Read grants:
  Case.ContactId
  Service_Visit__c.Status__c
  Service_Visit__c.Service_Type__c
  Loyalty_Member__c.Points_Balance__c
  Loyalty_Member__c.Status__c
  Loyalty_Member__c.Tier__c
All native Create/Edit/Delete/ViewAll/ModifyAll and FLS Edit flags false.
```
Exact live schema/field names verified; nonpermissionable required fields inherit object Read.
No Vehicle/Model/ledger/Rooftop/financial object grant or native Case/Visit write added. Existing
Foundation and profile definitions were not edited. Full Batch B and Reviewer not assigned.

Fresh target-identity/Contact/profile/license and existing-pair checks preceded one all-or-none
Composite REST request. Only missing pairs inserted. Raw operations/assign_runtime.json:
```text
A 005aj00000guQE9AAM → 0PSaj00000hHfZ7GAK via 0Paaj000018ByQMCA0 — HTTP 201 success=true
B 005aj00000guQEAAA2 → 0PSaj00000hHfZ7GAK via 0Paaj000018ByQNCA0 — HTTP 201 success=true
```
Before/after global assignments: 37→39, exactly those two additions; no removal/edit. Existing
13 User profiles/roles/Contact links/activity unchanged. Existing Foundation assignments retained.
Membership criteria remain 2, NetworkMembers remain 5 including both A/B; Network stays Live.

## CONFIRMED — scoped per-user security evidence

UserEntityAccess queries explicitly target each real A/B UserId (not admin's own access):
```text
Case, Service_Visit__c, Loyalty_Member__c:
  IsReadable=true; IsCreatable/IsEditable/IsUpdatable/IsDeletable=false
Vehicle__c, Vehicle_Model__c, Contact_Vehicle_Relationship__c:
  IsReadable/IsCreatable/IsEditable/IsUpdatable/IsDeletable=false
```
Twelve effective object results saved as A_effective_*.json / B_effective_*.json. These confirm
the native CRUD boundary; no native DML attempt or direct API mutation was needed.

UserRecordAccess queries target 15 actual records per User: A/B Contacts/Accounts, both Vehicles,
both Models, all four ledger records, plus an unrelated Case/Visit/Member sample:
```text
Own Contact/Account: HasReadAccess=true
Other customer's Contact/Account: HasReadAccess=false
All queried Vehicles/Models/ledger rows and unrelated Case/Visit/Member samples: HasReadAccess=false
Every sampled record: HasEditAccess=false HasDeleteAccess=false HasAllAccess=false
```
This is 30 scoped record checks, not an exhaustive all-record/native-surface audit. Both Users'
assigned parents include the deployed runtime class grant and existing Foundation class/custom
permission. Current object/system rows have no View/Modify All, API Enabled, Author Apex,
Manage Users or Manage Sharing grant among the checked flags.

Ledger before/after records including SystemModstamp/dates/evidence identical. A and B each still
have exactly their own current, separately evidenced Ownership and Service_Authorization pair;
no competing owner/duplicate consent in the snapshot. Guarded current-owner/consent/foreign-ID
checks covered by existing targeted broker tests; no actual A/B Live-Network broker invocation
was performed. Vehicle shares remain zero; four ledger shares remain internal-owner-only.
No explicit share writes, ledger reverify/date extension, persistent booking/Case/fixture writes.
Five existing scheduler configurations unchanged. No scheduler activation or full CP2 regression
claim; no CP2 metadata included or edited.

## PARTIAL — effective-field API failure; stopped without repair/retry

The separate UserFieldAccess verification line returned Salesforce UNKNOWN_EXCEPTION, not a
denial result. First surfaced query: UserId=005aj00000guQE9AAM,
EntityDefinitionId=01Iaj00000Fq37j, FieldDefinitionId=01Iaj00000Fq37j.00Naj000062JKY6
(Loyalty_Member__c.Points_Balance__c).
Exact error:
```text
UNKNOWN_EXCEPTION
An unexpected error occurred. Please include this ErrorId if you contact support: 518776881-741325 (1686693879)
```
Seven already-started parallel checks returned the same internal-error family; five remaining
checks were not executed. No retry, alternate query workaround, permission broadening, speculative
fix or extra deployment. All individual ErrorIds/raw results are in field_api_errors.json and
operations/A_field_*.json / B_field_*.json. None of these failures is labelled a passed field check.

Six deployed read-only FieldPermissions are confirmed separately. That metadata evidence does
not replace the failed effective-field API proof or actual authenticated USER_MODE calls. This
query failure is not established as a portal runtime exception or a demonstrated access leak.
No completed security check was REFUTED; security validation overall remains PARTIAL.

Specific owner escalation: provide Salesforce Support org 00Daj00001Ae3iWEAR, UserIds above,
the exact UserFieldAccess query/first ErrorId and field_api_errors.json. Ask for the internal
exception/validity of the computed per-user field-access query, without requesting permission
expansion. No further work on that query line until owner/Support direction.

## Browser UAT status and next manual action

In-app browser tabs list returned empty. Browser MCP snapshot returned verbatim:
```text
No connection to browser extension. In order to proceed, you must first connect a tab by clicking the Browser MCP extension icon in the browser toolbar and clicking the 'Connect' button.
```
No retry, login-as/session-token workaround or browser change. Actual A/B dashboard/vehicle/
options responses, rendered UX and foreign-ID browser denial NOT RUN. No write-UAT.

**A/B owner browser UAT is ready to begin, not passed or security-accepted.** The approved
configuration is deployed and both assignments exist. Owner can sign in normally as A/B, connect
that tab via the extension, then read-only refresh dashboard/vehicles and inspect options without
submitting a booking or Case. Capture any exact server error rather than expanding permissions.
Other child-panel history/Case-detail/loyalty-transaction grants remain intentionally outside this
minimal dashboard package; do not infer full Phase 8 readiness from this deployment.

Raw comparison summary: verification.json; executable saved-evidence comparator:
scripts/tests/verify_p8_dashboard_runtime_deployment.py. All completed assertions CONFIRMED,
securityValidationStatus=PARTIAL, phase8Complete=false. No ng-dev access, Git commands, unrelated
cleanup, extra deployment, profile/membership/source alteration or owner-acceptance claim.
