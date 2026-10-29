# Service history two-field FLS correction — local preparation only

**Deployment update (§77):** approved candidate validated `0Afaj00000pTnZRCA0` (1/1 component,
22/22 targeted tests) and Quick Deployed `0Afaj00000pSzJNCA0` (1/1). Exact two Read-only field
grants confirmed live; no assignments or record changes. Customer B browser retest ready,
NOT performed. Current receipts: `evidence/P8/SERVICE_HISTORY_FLS_DEPLOYMENT/RESULT.md`.
The preparation-only state below is historical.

## Exact maintained-file changes

1. `force-app/main/default/permissionsets/PS_Owner_Portal_Dashboard_Runtime.permissionset-meta.xml`
   adds only:
   ```xml
   <fieldPermissions><editable>false</editable><field>Service_Visit__c.Mileage_At_Checkin__c</field><readable>true</readable></fieldPermissions>
   <fieldPermissions><editable>false</editable><field>Service_Visit__c.Case__c</field><readable>true</readable></fieldPermissions>
   ```
2. `scripts/tests/validate_p8_dashboard_runtime_permission.py` keeps the original six-field
   dashboard allowlist, adds the two-field history allowlist, checks all eight fields remain
   Read-only, and adds saved-schema and exact-deployed-snapshot delta checks.

No other source/metadata was edited. The existing manifest is byte-identical and still includes
only PermissionSet `PS_Owner_Portal_Dashboard_Runtime`, API 68.0. No object CRUD, Apex class
access, description, profile, sharing, user assignment, Apex/LWC or booking implementation delta.
The existing six FLS entries and every other permission-set element match the deployed snapshot
after excluding the two new fields. No Git command or working-tree cleanup used for inspection.

## CONFIRMED — local validation

Command output from `python3 scripts/tests/validate_p8_dashboard_runtime_permission.py`:
```text
Ran 12 tests
OK
```
Raw stdout/stderr and `local_validation.json` are retained here. Selected command-output fields:
```json
{"claim":"CONFIRMED","localTestsRun":12,"failures":0,"errors":0,"metadataComponents":1,"apexClassGrants":1,"fieldEditGrants":0,"nativeWriteGrants":0,"guardSourcesChanged":false,"orgWritesPerformed":0}
```
Checks retain the original three read-only objects/one facade class and 55 existing deployment
hashes; the added regression check compares every permission-set element against the frozen
deployed six-field version, allowing exactly these two additions. Saved ng-demo describes mark
both new fields permissionable=true. No fresh Salesforce schema call or broader audit.

Local Metadata API conversion command:
```sh
sf project convert source --manifest manifest/p8-dashboard-runtime-permission.xml --output-dir evidence/P8/SERVICE_HISTORY_FLS_CORRECTION/mdapi --json
```
Raw `conversion.json` status=0. Converted package contains the single PermissionSet, and its XML
matches the candidate source. Exact no-Git diff is in `scoped.diff`; before copies/hashes are
preserved in `before/` and `before_hashes.json`.

Raw `scoped_verification.json`:
```json
{"checks":{"exact_two_maintained_files_modified":"CONFIRMED","manifest_byte_identical":"CONFIRMED","converted_metadata_matches_source":"CONFIRMED","converted_manifest_exact_one_permission_set":"CONFIRMED"},"addedFieldEditGrants":0,"objectCrudDelta":0,"apexClassAccessDelta":0,"manifestComponents":1,"orgWrites":0,"salesforceValidation":"NOT RUN","deployment":"NOT RUN"}
```

Candidate PermissionSet SHA-256:
`7adae21fdc524e490c93de51dba40c49ee85622e24bc13f044ea1dbd87bcc262`.
Unchanged manifest SHA-256:
`d12c800cc6096ccf40561c95243e53fc5f0760bbf100248ab548b8d9c4a47140`.

## Security implications and next gate

The delta allows mileage and the linked-Case lookup to be read on Service Visits already
readable to the actor. It grants no field Edit, Case/Visit writes, Vehicle/Model/ledger CRUD,
View/Modify All, or record access. Existing Contact-filtered USER_MODE history queries and
foreign-linked-Case masking remain unchanged. Lookup Read exposes link values on already
readable Visits, so existing record-level isolation remains essential; this change does not
replace it or prove all native surfaces by itself.

Once separately approved and deployed, existing A/B runtime-set assignments inherit the two
fields; no new assignments are needed. Use the unchanged one-component manifest. Do not modify
the working booking flow or records, change status to make history appear, or grant full Batch B.

Deployment-ready locally, NOT Salesforce-validated or deployed. Salesforce validation, actual
A/B history response and new-field native/runtime isolation checks remain future owner-approved
work. No Salesforce org access or writes, permission assignments, deployment, user/booking/Case/
ledger changes, ng-dev access or Git operation occurred during this preparation. CP2 and the
existing completed implementation were not modified.

Running the existing validator regenerated its standard
`evidence/P8/PORTAL_PERMISSION_FIX/local_validation.json` output; the prior receipt was preserved
as `before/previous_local_validation.json`. Other added files under this evidence directory are
local snapshots, logs, diff, verification and the converted one-component package—not extra
deployment metadata or Salesforce changes.
