# My Cases Subject Read FLS — deployment receipt

Documentation-only receipt, reconstructed from existing raw results. No deployment, tests,
security checks or Salesforce operations rerun during this documentation repair.
Target of the recorded deployment: ng-demo, 00Daj00001Ae3iWEAR.

## CONFIRMED — recorded validation and deployment

Raw output excerpts from operations/salesforce_validation.json:
```json
{"id":"0Afaj00000pTterCAC","status":"Succeeded","checkOnly":true,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":22,"numberTestsCompleted":22,"numberTestErrors":0}
```
Targeted classes: OwnerPortalFoundationControllerTest, OwnerPortalBatchBControllerTest,
OwnerPortalVehicleBrokerTest. Local validator: 12 tests passed; retained stdout/stderr here.

Raw output excerpts from operations/deployment.json:
```json
{"id":"0Afaj00000pTuFxCAK","status":"Succeeded","checkOnly":false,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":0,"numberTestErrors":0}
```
Quick Deploy reused the successful validation. Only component:
PermissionSet PS_Owner_Portal_Dashboard_Runtime, using manifest/p8-dashboard-runtime-permission.xml.

## CONFIRMED — deployed delta and preservation

Raw verification.json excerpts:
```json
{"addedFieldPermission":{"Field":"Case.Subject","PermissionsRead":true,"PermissionsEdit":false},"assignmentsAdded":0,"deployedComponents":1}
```
```json
{"exact_subject_read_only_delta":"CONFIRMED","assignments_unchanged":"CONFIRMED","A_existing_assignments_retained":"CONFIRMED","B_existing_assignments_retained":"CONFIRMED","objects_unchanged":"CONFIRMED","setup_unchanged":"CONFIRMED","definition_unchanged":"CONFIRMED","users_unchanged":"CONFIRMED","case_unchanged":"CONFIRMED","visit_unchanged":"CONFIRMED","55_existing_implementation_hashes_unchanged":"CONFIRMED"}
```
Eight prior field grants unchanged; now nine. All 39 assignments unchanged. Existing A/B
profile-owned, Foundation and runtime assignments retained. Case 00001102 and Visit
a08aj00001UbaiFAAR, including SystemModstamp, unchanged.

## CONFIRMED — recorded per-user security

Raw UserEntityAccess excerpts for Case:
```json
{"UserId":"005aj00000guQE9AAM","EntityDefinitionId":"Case","IsReadable":true,"IsCreatable":false,"IsEditable":false,"IsUpdatable":false,"IsDeletable":false}
```
```json
{"UserId":"005aj00000guQEAAA2","EntityDefinitionId":"Case","IsReadable":true,"IsCreatable":false,"IsEditable":false,"IsUpdatable":false,"IsDeletable":false}
```
For both customers, Vehicle/Model/ownership-ledger access flag excerpts:
```json
{"IsReadable":false,"IsCreatable":false,"IsEditable":false,"IsUpdatable":false,"IsDeletable":false}
```
For both customers, Service Visit access flag excerpts:
```json
{"IsReadable":true,"IsCreatable":false,"IsEditable":false,"IsUpdatable":false,"IsDeletable":false}
```
A record-access rows:
```json
[{"RecordId":"a08aj00001UbaiFAAR","HasReadAccess":false,"HasEditAccess":false,"HasDeleteAccess":false,"HasAllAccess":false},{"RecordId":"500aj00003rhFEbAAM","HasReadAccess":false,"HasEditAccess":false,"HasDeleteAccess":false,"HasAllAccess":false}]
```
B record-access rows:
```json
[{"RecordId":"a08aj00001UbaiFAAR","HasReadAccess":true,"HasEditAccess":false,"HasDeleteAccess":false,"HasAllAccess":false},{"RecordId":"500aj00003rhFEbAAM","HasReadAccess":true,"HasEditAccess":false,"HasDeleteAccess":false,"HasAllAccess":false}]
```
All match pre-deployment snapshots. Full raw responses remain unchanged in operations/;
verification.json and submitted_hashes.json remain unchanged.

## Outstanding acceptance and limitations

Customer B authenticated My Cases browser UAT NOT RUN. Owner should refresh My Cases as B
and confirm Case 00001102 appears. Phase 8 NOT complete. Service history was separately
browser-confirmed by the owner before this correction; no new history or booking UAT claimed.

Existing targeted Apex tests use historical permission fixtures, not the minimal runtime
combination. Per-user record checks cover the known B Case and Visit, not an exhaustive audit.
No full CP2/booking/history browser regression. Effective FLS established by deployed grants
and retained assignments; previously failing UserFieldAccess API not retried.

Recorded deployment changed no Apex, LWC, profiles, sharing, records or assignments and used
no Git operations. This repair changes only this receipt and NORTHGATE_PROJECT_HANDOFF.md.
