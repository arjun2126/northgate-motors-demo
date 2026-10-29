# Manager UAT UI Blockers — Root Cause (Read-Only, 2026-10-19)

State unchanged: `ngpersona` = `Sales_Manager_Airport`; `arjun.ManagerId` = `005aj00000gE0b3AAC`;
ProcessInstance `04gaj000001yDbJAAU` still `Pending`; `OpportunityShare` `00taj00000MwzpdAAB`
unchanged. No metadata, permission, record, or approval changes made.

## Blocker 1 — Approvals Home denies access

### Evidence (CONFIRMED)
- Approvals Lightning app: `AppMenuItem.IsAccessible = true` for the user; the failure is not app
  assignment.
- `NG_Sales` profile (profile-owned permission set `0PSaj00000gE0RPGA0`):
  - `PermissionsApprovalAdmin = false`, `PermissionsApprovalDesigner = false`.
  - `ObjectPermissions` for `ApprovalSubmission`, `ApprovalWorkItem`, `ApprovalSubmissionDetail`,
    `ApprovalSubmissionShare`, `ApprovalWorkItemShare`: **0 rows**.
- `Standard User` profile-owned permission set: also 0 rows for those objects.
- Only permission set in the org with `PermissionsApprovalAdmin = true` is
  `X00ex00000018ozh_128_09_04_12_1` (profile-owned by System Administrator), which also has
  `ModifyAllData`, `ViewSetup`, `ApiEnabled`. Assigned to admins only. Unusable as a narrow grant.
- Record-level access already resolved: Opportunity/Quote/ProcessInstance Read = true after share
  `00taj00000MwzpdAAB`. So this error is **not** record sharing.

### Root cause
The new Lightning Approvals app lists the `ApprovalSubmission` / `ApprovalWorkItem` objects. The
`NG_Sales` profile has no object access to either, and no Approval Admin permission. Work-item
read access alone is insufficient for this app.

### Minimum correction / supported alternative
- **Recommended: do not grant app permissions.** Use the classic approval path on the record:
  assigned approvers need Read on the target record (already true) and the record page must render.
  The standard Approve/Reject actions and Approval History are the supported classic UI. No new
  permission or deployment.
- If the Approvals *app* is required: a new permission set with Read on `ApprovalSubmission` and
  `ApprovalWorkItem` (plus share visibility) is the narrowest candidate, but this is unverified and
  may still require Approval Admin. Not recommended without a separate test.
- Do **not** assign the existing System Administrator-owned permission set; it carries
  `ModifyAllData`.

## Blocker 2 — Opportunity Details panel: no page layout assigned

### Evidence (CONFIRMED)
- Live `Profile:NG_Sales` metadata retrieve: **zero** `<layoutAssignments>` and zero
  `<recordTypeVisibilities>` entries.
- Opportunity record types active: `Fleet` (`012aj00000EtYfRAAV`), `Retail`
  (`012aj00000EtYfSAAV`).
- Existing deployed layouts: `Opportunity-Retail Layout`, `Opportunity-Fleet Layout`
  (also present in source).
- Salesforce Help: every record type must have a page layout assignment, even when it is not an
  assigned record type.
- Known Salesforce behavior (Knowledge 000382756): deploying a Profile without
  `<layoutAssignments>` clears all page-layout assignments. The source profile file has no
  assignments, so a prior profile deployment is the likely cause.

### Impact
All non-admin users use `NG_Sales` (all personas: rep, manager, VP, finance). The profile has no
layout assignments for **any** object, so other object detail pages may fail the same way; only
Opportunity was exercised so far.

### Exact minimum correction
Add to `NG_Sales` profile, using the existing layouts unchanged:

```
<layoutAssignments>
    <layout>Opportunity-Retail Layout</layout>
    <recordType>Opportunity.Retail</recordType>
</layoutAssignments>
<layoutAssignments>
    <layout>Opportunity-Fleet Layout</layout>
    <recordType>Opportunity.Fleet</recordType>
</layoutAssignments>
```

Deploy `Profile:NG_Sales` together with `RecordType`/`Layout` components (retrieve all three in one
transaction) to avoid clearing assignments. Can also be done in Setup: Profiles → NG_Sales →
Opportunity → Record Types and Page Layout Assignments. Either way it is a metadata configuration
change; no layout contents change.

## Notifications
No pending-approval notification was observed. Classic approvals notify the assigned approver by
email; this is secondary to the two blockers and should be re-checked after the record page renders.
No license limitation affects classic approval: `ngpersona` holds a Salesforce license.

## Consolidated approval request
1. Deploy the two Opportunity layout assignments to the `NG_Sales` profile (existing layouts;
   persistent; fixes all personas). Requires metadata deployment or equivalent Setup UI change.
2. Use the classic Opportunity record Approve/Reject path for this UAT instead of the new Approvals
   app (no permission change).
3. Optional/separate: approve and test a narrow permission set for the new Approvals app; do not
   assign the ModifyAllData system permission set.

## Pending browser step (after approval 1 is applied)
Login As `ngpersona` → open Opportunity `006aj00000faIjZAAU` → Details panel renders → use
Approve from the record (or Approval History) → confirm `Approval_Status__c = Approved`.
