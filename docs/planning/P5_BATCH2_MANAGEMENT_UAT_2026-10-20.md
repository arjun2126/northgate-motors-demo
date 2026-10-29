# Batch 2 — management browser UAT: instructions and exact restoration

> **SUPERSEDED DRAFT — DO NOT EXECUTE AS WRITTEN.** The premise in §1 below ("the persona has
> no record-level access, so dashboards will be empty") was based on probing admin-owned
> records only and is **wrong**. A corrected probe shows the persona **owns all 100 canonical
> Opportunities** and reads them; its pipeline scope is 78 rows / 4,328,120 versus admin
> 113 / 10,587,766. The approved plan and exact expected values are in
> `docs/planning/P5_BATCH2_ACCESS_RESOLUTION_2026-10-20.md`. This file is retained only as the
> command-level reference (baseline, create, verify, restore); the access premise, expected
> values and approval request in §4 and §6 of this draft are obsolete.

**Status: PREPARED, NOT EXECUTED.** No temporary assignment, permission change, persona
switch, dashboard refresh, or Salesforce write has occurred for Batch 2. Batch 1 (report
date-filter correction) is complete and separate.

Org: `ng-demo` (`00Daj00001Ae3iWEAR`) only. Never `ng-dev`.
Actor: Northgate Persona `005aj00000gE0b3AAC` (profile `NG_Sales`, role `VP_Sales`
`00Eaj00000QCxlLEAT`, `ManagerId = null`).

## 1. What the evidence already proves about this window

`UserRecordAccess` probe for the persona (read-only, one record per object):

```text
Vehicle__c           read=False edit=False delete=False
Service_Visit__c     read=False edit=False delete=False
Loyalty_Member__c    read=False edit=False delete=False
Staff__c             read=False edit=False delete=False
Case                 read=False edit=False delete=False
Quote                read=False edit=False delete=False
Financing__c         read=False edit=False delete=False
Opportunity          read=False edit=False delete=False
```

Object-level Read is granted (profile-owned set `0PSaj00000gE0RPGA0` has Read on Account,
Contact, Opportunity with no View All / Modify All), but private OWD plus admin ownership
means **no rows are visible to the persona**. This is the same root cause recorded for
"Empty Leads" in `docs/planning/REMAINING_ACCEPTANCE_2026-10-20.md`.

Consequence: adding `RunReports` and dashboard-folder View lets the persona *open* the
dashboards, but the underlying rows stay invisible. Expect the fixed dashboards to render
with zero/empty components and the executive dashboard to show no data. That is the
expected outcome of this window, not a defect and not acceptance of report values.

A meaningful two-persona comparison (P5-14) therefore needs data the persona can legitimately
read. Options, **none authorized in Batch 2**: a purpose-built UAT dataset owned by the
persona, or a narrowly scoped sharing/ownership decision by the owner. Do not reown or
share canonical records to make both personas see everything.

## 2. Pre-flight: capture the baseline (read-only)

Run before any create. Save the full output as the session's restore reference.

```bash
sf data query --target-org ng-demo --query "SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember WHERE UserOrGroupId='005aj00000gE0b3AAC' OR GroupId='00Gaj00000ZkluDEAR'" --json
sf data query --target-org ng-demo --query "SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId='005aj00000gE0b3AAC'" --json
sf data query --target-org ng-demo --query "SELECT Id, UserRoleId, Profile.Name, ManagerId FROM User WHERE Id='005aj00000gE0b3AAC'" --json
sf data query --target-org ng-demo --query "SELECT Id, Bypass_Triggers__c, Bypass_Flows__c, Bypass_Validation__c FROM Automation_Settings__c" --json
```

Expected pre-state, already confirmed on 2026-10-20 and to be re-verified immediately before
the window:

| Item | Expected pre-state | Preserve? |
|---|---|---|
| GroupMember | only `011aj000006D0ErAAK` → `PG_All_Sales` (`00Gaj00000ZYYhUEAX`) | yes |
| PermissionSetAssignment | `0Paaj000016Ty3HCAS` (profile set `0PSaj00000gE0RPGA0`), `0Paaj000016dBqzCAE` (`NG_Lightning_Experience_Access`) | yes |
| `PG_Northgate_Management` (`00Gaj00000ZkluDEAR`) membership | none | n/a |
| `PS_Management_Reports` (`0PSaj00000gUOW9GAO`) assignment | none | n/a |
| Role / profile / ManagerId | `VP_Sales` / `NG_Sales` / `null` | yes |

If either target tuple already exists, treat it as **pre-existing**: record it, do not create
a duplicate, and do not delete it during cleanup.

Also confirm zero pending approvals and zero assigned work items for the persona before any
role change. Batch 2 needs no role change; if any step proposes one, stop.

## 3. Authorized temporary grants (exactly two)

```bash
# A. management dashboard folder view
sf data create record --target-org ng-demo --sobject GroupMember --values "GroupId=00Gaj00000ZkluDEAR UserOrGroupId=005aj00000gE0b3AAC" --json
# B. report running permission
sf data create record --target-org ng-demo --sobject PermissionSetAssignment --values "AssigneeId=005aj00000gE0b3AAC PermissionSetId=0PSaj00000gUOW9GAO" --json
```

Record the two returned record IDs immediately (for example `GM_ID`, `PSA_ID`). These IDs,
not the tuple, are what cleanup deletes.

Verify:

```bash
sf data query --target-org ng-demo --query "SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId='00Gaj00000ZkluDEAR' AND UserOrGroupId='005aj00000gE0b3AAC'" --json
sf data query --target-org ng-demo --query "SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId='005aj00000gE0b3AAC' AND PermissionSetId='0PSaj00000gUOW9GAO'" --json
```

No role switch, no `PSG_Manager` assignment, no profile edit, no `PS_Case_Data_Quality_Fields`
assignment, no object/FLS/sharing change, no record creation.

## 4. Owner browser steps (owner session, Northgate Persona)

1. Log in as the persona. Confirm identity and role in the session.
2. Open **Northgate Management** folder: `DM_Sales_Operations`, `DM_Service_OperationsFixed`,
   `DM_Finance_Operations`. Record running user (all three are `SpecifiedUser` = admin
   `005aj00000feqbNAAQ`), the filters shown, and the displayed values. Refresh in the browser
   so component data is current.
3. Open **NG_Sales** → `DM_Exec_OperationsOverview` (`LoggedInUser`). Record what the
   persona actually sees, including empty components and any access errors.
4. Open the five source reports as the persona: `Pipeline_by_Stage`,
   `Open_Opps_by_Sales_Staff`, `Inventory_Aging_60_120`, `Service_SLA_Overdue`,
   `Service_CSI_Proxy`, `Loyalty_Tier_Distribution`. Record row counts and any
   insufficient-access message.
5. Capture screenshots for P5-15 fixed-user evidence, and separately for P5-14 dynamic scope.

Expected values if the persona can see rows (for reconciliation; the persona cannot see
canonical rows today, so the fixed dashboards run as admin and show org-wide data):

| Source | Current org value (admin context) |
|---|---|
| `Pipeline_by_Stage` | 113 rows, Amount 10,587,766 (excludes Closed Lost) |
| `Open_Opps_by_Sales_Staff` | Amount 6,250,407; capture its RowCount separately |
| `Inventory_Aging_60_120` | 120 rows (>60 days; 120 are also >120 — open gap) |
| `Service_SLA_Overdue` | 13 rows (required 12 — open gap) |
| `Service_CSI_Proxy` | 0 scored rows (empty, not validated accuracy) |
| `Loyalty_Tier_Distribution` | 72 members (canonical subset 70 = 39/18/9/4) |
| `DM_Finance_Operations` sources | prior UI showed zero candidates and empty decided/funded denominators; N/A, not 0% business rate |

## 5. Restoration (guaranteed, including on failure)

Runs on success, partial completion, failure, interruption, or cancellation.

```bash
# D. remove only what this window created
sf data delete record --target-org ng-demo --sobject GroupMember --record-id <GM_ID> --json
sf data delete record --target-org ng-demo --sobject PermissionSetAssignment --record-id <PSA_ID> --json
```

Then re-run the §2 baseline queries and compare field by field. Required end state:

- `PG_Northgate_Management` membership: none.
- `PS_Management_Reports` assignment: none.
- GroupMember `011aj000006D0ErAAK` still present.
- PermissionSetAssignments `0Paaj000016Ty3HCAS` and `0Paaj000016dBqzCAE` still present.
- Role `VP_Sales`, profile `NG_Sales`, `ManagerId = null` unchanged.
- `Automation_Settings__c` flags unchanged (`false` / `false` / `false`).

Cleanup rules:

- Delete only the IDs captured from the §3 create responses. Never delete by tuple alone.
- If a create response is lost, do not guess ownership: compare against the §2 pre-state and
  resolve attribution with the owner before deleting anything.
- If a delete fails, stop and escalate with the record ID and error. Do not retry blindly and
  do not remove other access to compensate.
- If the owner adds any access beyond the two named grants, that access needs its own
  explicit approval and its own restoration step.

## 6. Known gaps this window does not close

- Persona record-level access is empty on every checked object; dashboard data stays
  invisible to the persona (see §1).
- Dynamic two-persona scope evidence (P5-14) needs persona-readable data.
- `Service_SLA_Overdue` = 13 vs required 12; `Inventory_Aging_60_120` = 120 with all rows also
  older than 120 days; CSI empty. These are acceptance gaps, not access gaps.
- Admin field-access assignment `0Paaj000016wctoCAA`
  (`PS_Case_Data_Quality_Fields`, Case Create/Edit/Read) is **not** part of this window and
  is not touched.
- Report folder membership for `NG_01_Pipeline`, `NG_03_Inventory`, `NG_04_Service`,
  `NG_06_Loyalty` is a separate check; `PG_All_Sales` already grants View to the report and
  dashboard folders used by the rep persona. Record what is actually visible rather than
  assuming folder access equals row access.
