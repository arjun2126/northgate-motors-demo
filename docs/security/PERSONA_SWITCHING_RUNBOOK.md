# Persona Switching Runbook (ng-demo)

Runbook for `scripts/persona.sh`. This script temporarily switches
`ngpersona.ngdemo@northgate.demo` between the Sales Rep, Sales Manager, Finance
Officer, and VP Sales personas for UAT. It is restricted to the `ng-demo` org.

Live execution requires explicit owner authorization. Local preparation, dry
runs, and baseline capture do not change Salesforce.

## Guardrails

- Org alias must be `ng-demo`; org ID must be `00Daj00001Ae3iWEAR`.
- Target user must be `ngpersona.ngdemo@northgate.demo` (`005aj00000gE0b3AAC`).
- `ng-dev` is never accessed.
- A switch is blocked while ngpersona has a pending approval as submitter or
  approver.
- The script never changes `ManagerId`, profile, Lightning access, approval
  routing, organization-wide defaults, or business data.
- `PSG_Service` is never deleted by the switch or the restore.
- The baseline snapshot is captured once and never overwritten.

## Commands

```bash
# Read-only plan. No Salesforce DML, no snapshot write.
scripts/persona.sh --dry-run rep
scripts/persona.sh --dry-run manager
scripts/persona.sh --dry-run finance
scripts/persona.sh --dry-run vp

# Capture the original baseline once (read-only on Salesforce; writes a local file).
scripts/persona.sh capture-baseline

# Live switch. Requires owner authorization. Captures the baseline on first run.
scripts/persona.sh rep
scripts/persona.sh manager
scripts/persona.sh finance
scripts/persona.sh vp

# Complete rollback to the captured baseline.
scripts/persona.sh --dry-run restore
scripts/persona.sh restore
```

Persona mapping:

| Persona | Role | Permission set group |
|---|---|---|
| `rep` | `Sales_Rep` | `PSG_Rep` |
| `manager` | `Sales_Manager_Airport` | `PSG_Manager` |
| `finance` | `Finance_Manager` | `PSG_Finance` |
| `vp` | `VP_Sales` | `PSG_Manager` |

`vp` is not a rollback. Only `restore` returns ngpersona to the captured
baseline.

## Required preconditions

1. `jq` and the Salesforce CLI are installed.
2. `PERSONA_BASELINE_DIR` defaults to `evidence/UAT/`.
3. A baseline snapshot exists at `evidence/UAT/persona_baseline.json`, or the
   current live state matches the documented baseline: role `VP_Sales`,
   `ManagerId` null, and no managed persona PSG assignments
   (`PSG_Rep`, `PSG_Manager`, `PSG_Finance`).
4. The target permission set group status is `Updated`.
5. ngpersona has no pending approval as submitter or approver.

## Switch behavior

1. Validate org, user, role, permission set group, and pending approvals.
2. Capture the baseline on first live switch if absent.
3. Add the target permission set group if missing.
4. Update `UserRoleId`.
5. Delete managed persona assignments that are not the target.
6. Verify role, target assignment, preserved `PSG_Service`, `ManagerId`, and
   profile.
7. Append a line to `evidence/UAT/persona_history.log`.

Repeating a switch to the same persona is a no-op and performs no DML.

## Partial failure recovery

Salesforce DML is not transactional, so a failure between the role update and
the permission set assignment changes is possible. On failure the script
attempts an automatic `restore` from the baseline.

- If the automatic restore succeeds, the baseline is re-verified and the
  script exits non-zero.
- If it fails, the script prints `AUTOMATIC RESTORE FAILED` and the manual
  commands below.
- Do not retry the switch before the state is restored.
- If connectivity dropped mid-DML, wait for connectivity, then run
  `scripts/persona.sh --dry-run restore`, then `scripts/persona.sh restore`.
- If a pending approval appeared, resolve it before restoring.

Manual fallback when the baseline file is unavailable:

```bash
# Inspect current state first.
sf data query --target-org ng-demo --query \
  "SELECT Username, UserRole.DeveloperName, ManagerId FROM User WHERE Id='005aj00000gE0b3AAC'"
sf data query --target-org ng-demo --use-tooling-api --query \
  "SELECT Id, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment \
   WHERE AssigneeId='005aj00000gE0b3AAC' AND PermissionSetGroupId != null"

# Restore role.
sf data update record --target-org ng-demo --sobject User \
  --record-id 005aj00000gE0b3AAC --values "UserRoleId=00Eaj00000QCxlLEAT"

# Remove managed persona assignments that were added. Do not delete PSG_Service.
sf data delete record --target-org ng-demo --sobject PermissionSetAssignment \
  --record-id <assignmentId>
```

Documented baseline: role `VP_Sales` (`00Eaj00000QCxlLEAT`), `ManagerId` null,
profile `NG_Sales` (`00eaj00000TnZaFAAV`), no persona permission set group
assignments.

## Verify the VP approver after restoration

`QuoteBuilderController.submitForApproval` selects the oldest active user with
role `VP_Sales` ordered by `CreatedDate`, `Id`, and fails closed with
`No VP approver available.` when none exist. After `restore`, confirm:

```bash
sf data query --target-org ng-demo --query \
  "SELECT Id, Username, UserRole.DeveloperName FROM User \
   WHERE UserRole.DeveloperName='VP_Sales' AND IsActive=true \
   ORDER BY CreatedDate, Id"
```

Expected: exactly one active VP, `ngpersona.ngdemo@northgate.demo`. If the
result is empty, VP discount approval fails closed; do not submit a >10%
approval until the VP persona is active again.

## Limitations

- Role updates and permission set assignment changes are separate DML calls.
  The script cannot make them atomic; it mitigates with ordered changes and
  automatic restore.
- The baseline is written once. The script refuses to capture a baseline when
  the current state is not the documented baseline.
- `PSG_Service` is observation-only: it is preserved but never added or removed
  by this process.
- The script does not set `ManagerId`. The manager path in
  `QuoteBuilderController.submitForApproval` still requires a non-null
  `ManagerId`, so manager-approval UAT uses the UI ad hoc approver unless the
  owner separately authorizes a `ManagerId` change.
- Pending approval detection queries `ProcessInstance` (submitter) and
  `ProcessInstanceWorkitem` (approver). Approvals that are not represented by
  those records are out of scope.
- Any external change to `ManagerId` or profile blocks switching and restore
  until reconciled.
