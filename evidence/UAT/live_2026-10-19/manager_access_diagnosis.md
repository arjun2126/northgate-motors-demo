# Manager Approval Record Access — Read-Only Diagnosis (2026-10-19)

Target: Opportunity `006aj00000faIjZAAU`, ProcessInstance `04gaj000001yDbJAAU`, work item
`04iaj000003jMc9AAE`, approver `005aj00000gE0b3AAC` (`ngpersona`, manager persona).
No changes made. `arjun.ManagerId` remains temporarily set.

## Findings (CONFIRMED)

| Check | Result |
|---|---|
| Opportunity owner | `005aj00000feqbNAAQ` (`arjun`), `UserRole = null` |
| Opportunity OWD | `Private` (live EntityDefinition) |
| OpportunityShare rows | only `005aj00000feqbNAAQ` / `Owner` / `All`; no approver share was created by submission |
| ngpersona Opportunity object rights | `NG_Sales` profile: Read/Create/Edit, `ViewAllRecords=false`, `ModifyAllRecords=false` |
| ngpersona Opportunity record access | `HasReadAccess=false`, `MaxAccessLevel=None` |
| ngpersona ProcessInstance access | `HasReadAccess=false` |
| ngpersona work-item access | `HasReadAccess=true`, `MaxAccessLevel=All` |
| arjun ProcessInstance access | `HasReadAccess=true`, `MaxAccessLevel=All` |
| Process* object permissions | 0 rows for `NG_Sales`; these objects are not profile-permissionable |

## Root cause

1. **Direct URL / no record access.** Opportunity is Private. The owner (`arjun`) has no role, so
   there is no role-hierarchy path to `ngpersona` (`Sales_Manager_Airport`). Object-level Read is
   present, but no record share exists. Approval submission does **not** create an
   `OpportunityShare` row (verified: only the Owner row exists).
2. **Approvals app.** Work-item access exists, but `ProcessInstance` access does not. Process*
   objects have no permissionable object rights, so approval visibility follows access to the
   target record. With no Opportunity read, the approval request is not visible.

So both symptoms have one cause: no record-level read for the assigned approver. There is no
existing approval share to reuse.

## Exact minimum fix (requires owner approval — YES)

Insert **one** manual share row, read-only, scoped to this UAT Opportunity:

```
OpportunityShare
  OpportunityId          = 006aj00000faIjZAAU
  UserOrGroupId          = 005aj00000gE0b3AAC
  OpportunityAccessLevel = Read
  RowCause               = Manual
```

- Same effect via owner UI: Opportunity → Sharing → Add → `ngpersona` → Read.
- No OWD, role, profile, permission-set, approval-process, or ownership change.
- Reversible: delete the `OpportunityShare` row after the manager test.
- This is the narrowest supported mechanism; it is a data/share change, so it needs owner approval.
- Quote access is ControlledByParent, so the same share also exposes Quote
  `0Q0aj000003kJNhCAM` to the manager for review.

## Verification after applying

Re-query `UserRecordAccess` for `ngpersona` on the Opportunity and ProcessInstance. Both should
read `HasReadAccess=true`. Then the owner can approve in the browser. If the Approvals app still
fails after the share, stop and escalate — there is no narrower lever left.

## State (unchanged)

- `ngpersona`: role `Sales_Manager_Airport`, profile `00eaj00000TnZaFAAV`, no persona PSGs beyond `PSG_Manager`.
- `arjun.ManagerId`: `005aj00000gE0b3AAC` (temporary, must be cleared after the manager test).
- Pending: `04gaj000001yDbJAAU`.
