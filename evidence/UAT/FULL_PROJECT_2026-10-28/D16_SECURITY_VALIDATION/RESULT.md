# D16 security validation — one component validated, not deployed or assigned

## Scope and target

Current owner authorization: read-only ng-demo inspection and one scoped deployment validation
only. No application/source edits, portal/D06 changes, deployment, assignment, Salesforce record/
configuration modification, Git writes or ng-dev access. Raw receipts are in this directory.

CONFIRMED — raw API identity body excerpts (`api_identity.json`):
```json
"user_id": "005aj00000feqbNAAQ",
"organization_id": "00Daj00001Ae3iWEAR",
"preferred_username": "arjun.ngdemo@northgate.demo",
"active": true,
"user_type": "STANDARD"
```
The initial Organization SELECT additionally returned `OrganizationType: Developer Edition`.

## Exact grants, component dependencies and metadata review

Object: **Executive_Service_Metrics__c**. Candidate contains exactly:

| Field | Read | Edit | Broken component / report dependency |
|---|---|---|---|
| Overdue_Count__c | true | false | Overdue Service Visits → NG_04_Service/Executive_Service_Overdue (00Oaj00000Ux9veEAB) → FORMULA1 stored-count sum |
| CSI_Score_Total__c | true | false | CSI Proxy (Recorded Scores) → NG_04_Service/Executive_Service_CSI (00Oaj00000Ux9vdEAB) → FORMULA1 numerator |
| CSI_Response_Count__c | true | false | Same CSI report → FORMULA1 denominator and positive-response guard |

`inspection.json` records full retrieved formulas and the one-to-one field dependency map.
Both formulas retain CDF1 capture age and 24-hour stale-to-blank behavior; CSI retains the
positive-response guard and NULL/N/A result. Captured_At__c is required and already available
to this reader. No additional date/Name/Metric_Key FLS is introduced or needed by the candidate.

CONFIRMED — raw local inspection output:
```json
"metadataReview": "PASS",
"manifestComponents": 1,
"objectCrudGrants": 0,
"classOrSystemGrants": 0,
"licenseBinding": null,
"candidateUnchanged": true
```

Manifest `manifest/uat-executive-field-read.xml` selects only
`PermissionSet:PS_Executive_Service_Field_Read`, API 68.0. Root entries are description, three
Read-only fieldPermissions, hasActivationRequired=false and label. There are no object/write,
class, system/custom permission, view-all, group, licence, sharing, report, dashboard, Apex or
destructive additions. No metadata was changed during this validation task.

## Actual dashboard identity model and relevant reader

CONFIRMED — raw `dashboard.json`:
```json
"Id": "01Zaj00000BVDIqEAP",
"DeveloperName": "DM_Exec_OperationsOverview",
"Type": "LoggedInUser",
"RunningUserId": "005aj00000feqbNAAQ",
"DashboardResultRunningUser": null,
"DashboardResultRefreshedDate": null
```

This is a **dynamic viewer-scoped dashboard**, not a fixed-user dashboard. The stored
RunningUserId/metadata runningUser does not make every viewer run as this administrator.
The effective identity is each logged-in viewer. Our actual authenticated reader is confirmed
above; there is no cached-result identity available to identify a different last browser viewer.
The owner has not supplied the failing browser session's username in this request. Therefore
we establish the defect/access gap for the named admin reader, not for every persona.

CONFIRMED — `reader.json` raw excerpts:
```json
"Id": "005aj00000feqbNAAQ",
"Username": "arjun.ngdemo@northgate.demo",
"IsActive": true,
"UserType": "Standard",
"Name": "System Administrator",
"Name": "Salesforce",
"UserRoleId": null
```
The two Name excerpts are respectively Profile.Name and Profile.UserLicense.Name.

## Existing effective-access sources

Current `assignments.json` returns 12 permission sets, including profile-owned
`0PSaj00000eq3ikGAA`, and no permission-set group assignments. The FLS query included **all**
12 assigned set IDs, not just custom sets, and the profile-owned baseline.

CONFIRMED — `effective_field_sources.json` raw result:
```json
"records": [],
"totalSize": 0,
"done": true
```
CONFIRMED — `effective_object_sources.json` raw profile-owned row excerpts:
```json
"SobjectType": "Executive_Service_Metrics__c",
"PermissionsRead": true,
"PermissionsViewAllRecords": true,
"PermissionsModifyAllRecords": true,
"PermissionsViewAllFields": false
```
Record-wide access is not field-wide access. The profile already has object Read, but neither
explicit field Read nor View All Fields supplies these three fields. The candidate adds no
object/record-wide rights and does not remove the administrator's existing rights.

CONFIRMED — fresh read-only Analytics describes for both source reports return:
```json
"aggregates": [
  "s!CDF1",
  "RowCount"
]
```
Their available categories omit all three stored metric fields and FORMULA1, while the fresh
Metadata API report retrievals retain the intended expressions. This corroborates actual field
unavailability under the identified reader, not only an administrative permission-table inference.
No report was saved, publisher run or dashboard refreshed to generate evidence.

The existing VP set **does** already grant exactly these three fields Read=true/Edit=false:
`existing_vp_field_grants.json`. It is assigned to `ngpersona.ngdemo@northgate.demo`
(`005aj00000gE0b3AAC`), not to the inspected admin (`existing_vp_assignments.json`). It therefore
does not provide effective access to the admin. Do not duplicate this new set on that VP identity
without a separate need; do not assign the broader VP set to admin merely to repair three fields.

## Assignment compatibility and persona architecture

For the identified active internal Standard/Salesforce/System Administrator identity, no metadata
or licence incompatibility is identified: object Read already exists; these are ordinary custom
fields; the set has no licence binding or extra capability. Assignment would add only deidentified
stored metric field Read, not raw Service/Finance/customer data access, writes, licence reclamation,
role/PSG swaps or portal access. This is consistent with preserving separate Sales/Finance and
existing Admin personas. It does not require or justify changing a profile or dashboard running user.

This is **read-only compatibility assessment**, not an actual assignment test. No assignment DML,
temporary grants, impersonation, runAs fixture or live write was performed. Candidate existence
query returned zero rows before validation. Any PermissionSet ID returned by check-only is not
evidence of a persisted set and must not be used as an assignment target.

If the affected browser reader is a different user, their own effective access must govern the
assignment decision. The existing VP grants specifically show why a universal “all dashboard
viewers lack these fields” conclusion would be incorrect. Never assign this set to portal users.

## Scoped Salesforce validation

Executed once:
```sh
sf project deploy start --dry-run --target-org ng-demo --manifest manifest/uat-executive-field-read.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw `validation.json` excerpts:
```json
"checkOnly": true,
"id": "0Afaj00000paL8bCAE",
"numberComponentErrors": 0,
"numberComponentsDeployed": 1,
"numberComponentsTotal": 1,
"numberTestsCompleted": 0,
"status": "Succeeded",
"success": true
```
```json
"componentType": "PermissionSet",
"fullName": "PS_Executive_Service_Field_Read",
"success": true
```
```json
"componentFailures": []
```
```json
"warnings": []
```

NoTestRun accepted for this non-Apex Developer Edition scope; no Apex suite or coverage run.
Postcheck `verification.json` confirms the exact one successful member and unchanged source/
manifest. `validation_input_preservation.json` uses the scoped preservation helper with hashes
and file identity for these two required inputs; no required-input conflict. Other workstreams
were not paused or checked for whole-tree equality. No D06/portal/harness source was edited.

Validated source SHA256:
```text
PS_Executive_Service_Field_Read.permissionset-meta.xml
d88bf0aa6bd4397dca7ac52dd66f19d5b392e7fbfe2055e804aa64c1b5d3b844
manifest/uat-executive-field-read.xml
31af36f307e21e8c33ebe78ec20719afe8ffb5b92dcf5add6b8b521bc2ba0265
```

## Recommendation and remaining blockers

**Sufficient for approval of the narrowly scoped one-PermissionSet deployment.** No further
server metadata compatibility blocker was observed. Deployment remains unauthorized and would
leave the set unassigned. It would not by itself repair a viewer's access.

**Assignment is justified only for the confirmed intended reader.** If the owner confirms the
failing/intended viewer is `arjun.ngdemo@northgate.demo` / `005aj00000feqbNAAQ`, a separate exact
assignment approval is supported by the measured missing access and internal-persona assessment.
If another browser identity failed, confirm/reconcile that identity first; do not blanket-assign.

Remaining limits: no post-assignment Analytics/browser rendering test, no direct assignment
eligibility DML (forbidden), no guarantee that restoring fields alone resolves every browser
error. After separately approved deployment/assignment, check report aggregate availability and
the two tiles as that viewer; retain stale/N/A behavior and stop on unexpected outcomes.
No D16 closure or full-project acceptance. Stop and await owner deployment/assignment decisions.
