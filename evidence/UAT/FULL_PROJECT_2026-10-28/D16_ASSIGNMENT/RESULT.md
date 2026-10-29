# D16 exact-user assignment — completed; browser acceptance pending

Owner explicitly confirmed the affected browser session is arjun.ngdemo@northgate.demo and
authorized assignment of the already-deployed set to that user only. No redeployment.

## Identity and preconditions

Organization SELECT returned ng-demo `00Daj00001Ae3iWEAR`. User SELECT returned active Standard
User `005aj00000feqbNAAQ`, Username `arjun.ngdemo@northgate.demo`, System Administrator profile.
`api_identity.json` additionally confirms the authenticated API principal has the same user ID,
username and organization ID; post-assignment schema inspection is not an admin proxy for another
persona. PermissionSet lookup returned `0PSaj00000hKcDFGA0`, PS_Executive_Service_Field_Read.

CONFIRMED — `assignment_before.json` raw result:
```json
"records": [],
"totalSize": 0,
"done": true
```

The deployed set's `field_grants.json` contains exactly the three approved fields with
PermissionsRead=true/PermissionsEdit=false. `object_grants.json` returns no object grants.
No metadata/profile change was made or needed to create the assignment.

## Exactly one assignment created

Executed once, after identity/set/scope checks:
```sh
sf data create record --target-org ng-demo --sobject PermissionSetAssignment --values "AssigneeId=005aj00000feqbNAAQ PermissionSetId=0PSaj00000hKcDFGA0" --json
```
CONFIRMED — raw `assignment_create.json`:
```json
{"status":0,"result":{"id":"0Paaj000018MIu2CAG","success":true,"errors":[]},"warnings":[]}
```

`assignment_after.json` returns exactly one assignment for this permission set, with the approved
AssigneeId `005aj00000feqbNAAQ` and PermissionSetId `0PSaj00000hKcDFGA0`. No other user was assigned.
No retry, extra assignment, removal, password/user/profile edit or business-record mutation.

## Effective Read verification and important limit

After assignment, `sf sobject describe --target-org ng-demo --sobject Executive_Service_Metrics__c
--json` succeeded under the confirmed target user's API principal. All three requested fields
are present in the user's returned schema and the object is queryable. Together with the exact
persisted assignment and Read grants, this establishes the requested field visibility/Read access.

CONFIRMED — `field_grants.json`, for each of the three approved fields:
```json
"PermissionsRead": true,
"PermissionsEdit": false
```

CONFIRMED — selected post-assignment raw field-describe flags in `effective_schema_after.json`:
```json
"name": "Overdue_Count__c",
"createable": true,
"updateable": true
```
```json
"name": "CSI_Score_Total__c",
"createable": true,
"updateable": true
```
```json
"name": "CSI_Response_Count__c",
"createable": true,
"updateable": true
```

**Do not claim the administrator's overall effective access is Read-only.** The newly assigned
set explicitly has Edit=false, but the authenticated API describe reports the flags above.
These flags do not establish which existing capability supplies them or prove successful DML.
No before-assignment descriptor with these visible fields was captured for a causal write-access
comparison. No write probe, further speculative diagnosis, grant/revocation or automatic rollback
was performed. The prior security-validation receipt already documents this administrator's
existing object-level Modify All Records access; that alone is not asserted as the explanation.

If owner requires an overall effective Read-only guarantee for this administrator, review its
User Access Summary for these fields and separately authorize a bounded diagnosis. Do not alter
the shared Admin/profile/persona architecture on this observation. Work stopped after verification.

## Post-assignment read-only follow-up — no Salesforce writes

Continuation was limited to reads (SOQL, Metadata/Analytics describe, `sf sobject describe`).
No deployment, assignment, record/field write, permission change, report run or dashboard
refresh occurred. Raw receipts: `*_describe_after.json`, `fls_all_sources.json`,
`fls_all_fields_object.json`, `assignments_after.json`, `followup_verification.json`.

**Functional effect on the two source reports — CONFIRMED at report-engine level.** The same
report-describe calls that previously returned only `CDF1` and `RowCount` now return the
previously missing stored fields and both formulas:

```json
"Executive_Service_CSI": [
  "s!Executive_Service_Metrics__c.CSI_Score_Total__c",
  "s!Executive_Service_Metrics__c.CSI_Response_Count__c",
  "s!CDF1", "FORMULA1", "RowCount"
]
```
```json
"Executive_Service_Overdue": [
  "s!Executive_Service_Metrics__c.Overdue_Count__c",
  "s!CDF1", "FORMULA1", "RowCount"
]
```
Before-assignment values for both were `["s!CDF1","RowCount"]` (D16_SECURITY_VALIDATION
receipts). The retrieved formulas are unchanged and retain the 24-hour capture-age guard and,
for CSI, the positive-response guard. This is evidence that field availability for these reports
is restored; it is **not** a tile rendering or print acceptance.

**Grant inventory — CONFIRMED.** The org contains exactly **6** FieldPermissions rows for these
three fields: three in `PS_VP_Executive_Reporting` (assigned to `ngpersona.ngdemo@northgate.demo`,
not this user) and three in `PS_Executive_Service_Field_Read`. All six are `PermissionsEdit=false`.
The System Administrator profile-owned set holds 1002 FLS rows overall but **zero** on
`Executive_Service_Metrics__c`, which confirms the D16 gap was targeted to this object rather
than a broad profile regression.

**`createable`/`updateable` anomaly — unresolved attribution.** The flags remain `true` for all
three fields. Because no `Edit=true` FLS row for these fields exists anywhere in the org, and the
assigned set's rows are Read-only, the flag is **not attributable to this correction**. The
administrator already held object-level `PermissionsViewAllRecords=true` and
`PermissionsModifyAllRecords=true` before deployment (D16_SECURITY_VALIDATION receipt). No causal
explanation is claimed absent a write probe, and none was performed. Two limits therefore stand:
do not read the flag as the new set granting edit, and do not claim this administrator has an
overall Read-only field posture.

**Still not verified:** actual write denial/acceptance, dashboard tile rendering, print output.
`followup_verification.json` records `salesforceWritesPerformed: 0` and
`visualAcceptance: "PENDING"`. No browser tabs were available (`tabs: []`). Remaining owner
action: open the Executive dashboard as `arjun.ngdemo@northgate.demo` and confirm both tiles
render values (or the intended N/A/stale state) without field-permission errors. D16 stays OPEN.

## Remaining acceptance and preserved scope

Browser/dashboard visual acceptance remains **PENDING OWNER CHECK**. No dashboard/report refresh,
rendering test, Apex run or full regression was performed. D16 is not closed. No source, permission
metadata, dashboard/report/LWC, D06, other user, Salesforce business data, deployment, Git staging/
commit/push or ng-dev operation. Only the one explicitly authorized PermissionSetAssignment was
created. Raw receipts and `verification.json` remain alongside this report.
