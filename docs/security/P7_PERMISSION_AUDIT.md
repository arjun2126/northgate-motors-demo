# P7-11 — read-only permission assignment audit

## Reader, report and limits

The authenticated administrative CLI context successfully ran the assignment/group inventory
against ng-demo `00Daj00001Ae3iWEAR`. No identities were swapped and no permission was granted
or revoked. This runnable JSON/CLI report is not a verified native Report Builder report or an
operational-reader browser demonstration. `evidence/P7/perm_audit.png` remains unexecuted.

Run the fixed read-only report:

```sh
python3 scripts/tests/audit_p7_batch2.py
```

Raw rows: `evidence/P7/BATCH2_PERMISSION_TERRITORY_AUDIT.json`. Assignee IDs, active flags,
profile/role names, group assignments and group components are included; usernames, email
addresses and personal display names are not collected. Profile-derived permissions are not
misrepresented as separately assignable sets. Expiration, muting, session-based activation,
license-specific entitlements and per-record effective access are not fully evaluated here.

CONFIRMED — raw report excerpts:

```json
{"permissionSetCount":180,"assignmentCount":31,"groupCount":26}
```

The report records 18 project sets with no direct/generated PermissionSetId assignment rows.
Five are members of groups: PS_Finance_Officer, PS_Lead_Conversion, PS_Sales_Manager,
PS_Sales_Rep and PS_Service_Advisor. They must not be called unused because direct assignments
are absent. Group membership and actual group assignments require joint interpretation.

Remaining zero-assignment candidates include loader-only PS_Bypass_Load; alternate admin/
finance/quote access sets; and deliberately deferred gallery/calculator, loyalty, nurture,
console, service-reporting/SLA/history sets. Absence of assignments is not evidence that their
definitions are unnecessary. Batch 1 operational sets remain unassigned by design.

No permission is proven unused. Actual usage requires appropriate observation/telemetry and an
owner review. Removal or reassignment is outside this audit and outside Batch 2 authorization.
The Phase 6 report-FLS/lookup-target lessons remain applicable; an administrator's query does
not prove a restricted persona can read a report, its folder, fields or lookup target objects.

## Supporting read-only queries

```sql
SELECT Id, Name FROM PermissionSet WHERE IsOwnedByProfile = false ORDER BY Name
SELECT PermissionSetId, PermissionSetGroupId, AssigneeId, Assignee.IsActive,
       Assignee.Profile.Name, Assignee.UserRole.DeveloperName
FROM PermissionSetAssignment
SELECT Id, DeveloperName, Status FROM PermissionSetGroup
SELECT PermissionSetGroupId, PermissionSetId FROM PermissionSetGroupComponent
```

Operational reader selection, any native report-type availability/configuration and rendered
browser evidence remain explicit acceptance gates. Do not create a custom audit data model,
grant administrative permissions or fabricate a screenshot to close those gates.
