# Batch 2 — management UAT access resolution (read-only investigation)

**Status: PLANNING ONLY. Nothing executed.** No deployment, no Salesforce DML, no permission or
persona change, no sharing grant, no record creation, no Git commit or push. Org: `ng-demo`
(`00Daj00001Ae3iWEAR`) only. Raw evidence: `evidence/P5/consolidated_completion_checks_2026-10-20.md`.

## 0. Correction to the earlier access claim

The previous continuation and Batch 2 draft stated the persona had "no record-level access on
any checked object" and that dashboards would necessarily be empty. That was **wrong** and came
from probing only admin-owned records.

Corrected picture, all read-only evidence:

```text
Opportunity SEED-09-001 (persona-owned)  read=True  edit=True
Opportunity SEED-09-044 (persona-owned)  read=True  edit=True
Opportunity 006aj00000eebhlAAA (admin)   read=False edit=False
Account 001aj000045ZScRAAW (admin-owned) read=True   (104 AccountShare rows, RowCause=ImplicitParent)
Contact 003aj00002W3EfhAAF (admin-owned) read=False
Vehicle__c a0Daj00001D2FPZEA3           read=False
Loyalty_Member__c a05aj00000gECdpAAG     read=False
Quote 0Q0aj000003jGGbCAM (admin-owned)   read=False
Case 500aj00003icWCHAA2 (admin-owned)    read=False
```

Ownership census (`OwnerId = 005aj00000gE0b3AAC`):

| Object | Persona-owned | Canonical seed | Canonical owner |
|---|---:|---:|---|
| Opportunity | **101** | 100 (`SEED-09-*`) | persona |
| Task / Event | 200 / 50 | 250 | persona |
| Account / Contact / Quote | 1 / 1 / 1 | 150 / 185 / 60 | admin |
| Vehicle__c, Service_Visit__c, Loyalty_Member__c, Financing__c, Case, Trade_In__c, Delivery__c, Test_Drive__c, Staff__c, Lead | 0 | 120 / 140 / 70 / 60 / 60 / 45 / 12 / 70 / 14 / 130 | admin |

Persona object-level Read (profile-owned set `0PSaj00000gE0RPGA0`): Account, Contact, Lead,
Opportunity, ContractLineItem, Entitlement, EntitlementContact, QuickText, ServiceContract.
`NG_Lightning_Experience_Access` (`0PSaj00000gKc49GAC`) grants no object access.

Consequence: the persona's pipeline scope is **already meaningful**. It owns the entire
canonical Opportunity set, so Opportunity-based reports return real, persona-scoped values.
The limitation is limited to the objects it does not own.

## 1. Exact reports and dashboard components required for P5 management acceptance

Source objects, from live report metadata and source report-type XML:

### P5-14 `DM_Exec_OperationsOverview` (`01Zaj00000BVDIqEAP`, dashboardType `LoggedInUser`)

| Component | Report | Report type | Base object | Source object for the metric |
|---|---|---|---|---|
| Pipeline Amount | `NG_01_Pipeline/Pipeline_by_Stage` | Opportunity (standard) | Opportunity | Opportunity (Amount), Account (ACCOUNT_NAME), Staff__c (Opportunity.Sales_Staff__c lookup) |
| Inventory Aged Over 60 Days | `NG_03_Inventory/Inventory_Aging_60_120` | `VehicleList__c` | Vehicle__c | Vehicle__c (Inventory_Age_Days__c, Reporting_Make__c, Rooftop__c lookup, VIN, Status) |
| Overdue Service Visits | `NG_04_Service/Service_SLA_Overdue` | `ServiceVisitList__c` | Service_Visit__c | Service_Visit__c (Status, Scheduled_Start__c, Rooftop__c lookup) |
| Loyalty Members | `NG_06_Loyalty/Loyalty_Tier_Distribution` | `LoyaltyMemberList__c` | Loyalty_Member__c | Loyalty_Member__c (Tier__c, Points_Balance__c, Join_Date__c) |
| CSI Proxy (Recorded Scores) | `NG_04_Service/Service_CSI_Proxy` | `ServiceVisitList__c` | Service_Visit__c | Service_Visit__c (CSI_Score__c, Rooftop__c lookup) |

### P5-15 fixed-user manager dashboards (all `dashboardType=SpecifiedUser`, running user admin `005aj00000feqbNAAQ`)

| Dashboard | ID | Components | Source objects |
|---|---|---|---|
| `DM_Sales_Operations` | `01Zaj00000BVDIoEAP` | Pipeline Amount (`Pipeline_by_Stage`); Open Opportunities by Sales Staff (`Open_Opps_by_Sales_Staff`) | Opportunity, Account, Staff__c |
| `DM_Service_OperationsFixed` | `01Zaj00000BVDIpEAP` | Overdue Service Visits (`Service_SLA_Overdue`); CSI Proxy (`Service_CSI_Proxy`) | Service_Visit__c, Rooftop__c |
| `DM_Finance_Operations` | `01Zaj00000BVDInEAP` | Exception Candidates (`Financing_Approvals_Pending`); Decline Rate (`Financing_Decline_Rate`); Average Days to Fund (`Financing_Avg_Days_To_Fund`) | Financing__c, Opportunity, Contact, Application_Date |

Related P5-16 joined report types (not management-dashboard components, but the same
visibility question applies): `VehicleTestDriveList` (Vehicle__c → Test_Drive__c),
`ContactLoyaltyList` (Contact → Loyalty_Member__c), `ServiceCaseList` (Case → Service_Visit__c),
plus `ContactWithCampaignMembers` (Contact → CampaignMember) and `ConsentList`, `TradeInList`,
`FinancingList`, `VehicleList`, `ServiceVisitList`, `LoyaltyMemberList`, `QuoteList`.

### Persona-scoped expected values (read-only, current clock)

Admin context (org-wide) versus persona context (own records), all from SOQL:

| Metric | Admin (all records) | Persona (own records) |
|---|---:|---:|
| Pipeline by Stage rows (Stage != Closed Lost) | 113 | 78 |
| Pipeline by Stage Amount | 10,587,766 | 4,328,120 |
| Open opportunities (IsClosed=false) rows / Amount | 82 / 6,250,407 | 66 / 3,635,761 |
| Inventory > 60 days | 120 | 0 (no object read) |
| Loyalty members | 72 (canonical subset 70 = 39/18/9/4) | 0 (no object read) |
| Overdue Scheduled visits | 13 | 0 (no object read, no record access) |
| Service visits with CSI score | 0 | 0 |

Persona pipeline by stage (Stage != Closed Lost): Prospecting 11 / 598,747 · Qualification 12 /
693,703 · Test_Drive 12 / 656,712 · Appraisal 9 / 492,915 · Quoting 11 / 612,706 · Financing 11 /
580,978 · Closed Won 12 / 692,359.

## 2. Can the existing running-user configuration support a legitimate fixed-dashboard smoke test?

Yes, and it is the smallest safe path.

All three P5-15 dashboards are `SpecifiedUser` with running user admin `005aj00000feqbNAAQ`.
A specified-user dashboard computes its components in the **running user's** context, so a
manager viewer can see admin-computed metric values (113 pipeline rows / 10,587,766; 13
overdue visits; 120 aged vehicles; 72 loyalty members; financing counts) **without any
record-level access being extended to the persona**. The persona only needs to see the
dashboard folder and be able to run reports for drill-through.

The private sharing model is preserved exactly: the persona still cannot read canonical
Vehicles, Service Visits, Loyalty members, Financing rows, Cases, Quotes, or admin-owned
Contacts. It sees dashboard tiles, not records.

Two honest consequences, both to be captured as evidence rather than hidden:

- **Tile values are admin-computed; drill-through is viewer-scoped.** Clicking through to
  `Pipeline_by_Stage` runs as the persona and returns 78 rows / 4,328,120, not 113 /
  10,587,766. Acceptance must record both numbers, not one.
- **Fixed dashboards do not prove record-level visibility for a management persona.** They prove
  rendering, running-user semantics and value correctness against CLI-verified report output.

## 3. Can a purpose-built persona-owned dataset validate meaningful reporting?

Technically yes, but it is the **worst** option here, and the constraint list forbids it in this
investigation. Evidence against it:

- `VehicleCounterTrigger` / `VehicleCounters` and `TestDriveFollowupTrigger` / `TestDriveCounters`
  exist in source, so inserting Vehicles rewrites canonical `Vehicle_Model__c` counter fields
  and inserting Test Drives creates canonical Task rows.
- `Service_Visit__c` creation flows into capacity and task automation; `Loyalty_Member__c` is
  normally created by the delivery path, and a manual insert can collide with that flow.
- Every new row changes the P5-03 count contract and the P5-08 release gates, and adds storage
  while the org is already over the 4.0 MB gate.
- It would still not exercise `Service_Visit__c` SLA rows for a manager persona in a way that
  differs from the fixed dashboard, because the fixed dashboard already shows the org value.

Rejected: it mutates canonical derived data, inflates counts and storage, and expands the
record set the owner asked to preserve.

## 4. Is a narrowly scoped read-only sharing mechanism necessary?

Not for the recommended path. It becomes necessary only if the owner requires the *dynamic*
executive dashboard to show non-zero Service Visit values for a management persona. That would
need, at minimum:

- Object Read on `Service_Visit__c` (and its FLS: Status__c, Scheduled_Start__c, CSI_Score__c,
  Rooftop__c, Name), which the persona lacks.
- Record-level access to the 13 overdue Scheduled visits plus their rooftop rows, because
  `Service_Visit__c` is **Private** OWD and admin-owned. Object Read alone yields zero rows.
  That means a new sharing rule on `Service_Visit__c` (narrow, e.g. `Status__c='Scheduled'`
  and `Scheduled_Start__c < TODAY`, shared to `PG_Northgate_Management`), or a manual
  `Service_Visit__c` share set, or reowning records (rejected).

Assessment: a new sharing rule is the one artifact in this plan that changes org-wide
visibility semantics, and it is not needed for P5-15. It is listed as an optional, separately
approved step (Batch 2c) rather than part of the recommended release.

Narrow, low-risk grants that need **no** sharing at all, because these objects are
**Public Read/Write** by design (`PERMISSION_MATRIX.md` §6.3) and the existing rep permission
set already treats them as broadly readable: `Vehicle__c`, `Vehicle_Model__c`, `Rooftop__c`,
`Staff__c`, `Loyalty_Member__c`. Granting the persona Read on these changes no OWD and no
record ownership; it only removes an artificial permission gap for the management persona.

## 5. Would a separate management test user be safer than modifying Northgate Persona?

Not safer, and not simpler. Evidence:

- A new user with the same `NG_Sales` profile and no owned records sees exactly what the
  persona sees today for the non-Opportunity objects: zero rows. It solves the visibility
  problem no better.
- Giving that user its own owned fixtures is the rejected option 3.
- It consumes a Salesforce licence (P0-08 recorded 4 licences with 2 free) and adds a user
  record plus a role/profile assignment to restore, for no acceptance gain.
- `Northgate Persona` is the single intended persona-switcher user (`scripts/persona.sh`,
  P1-21). Isolating management UAT in a second user would fork the persona model and the
  restoration story.

Rejected. The persona is reused, and its access is changed only by grants that are removed again.

## 6. Option comparison

| Option | Effort | Security impact | Cleanup | P5-14 coverage | P5-15 coverage |
|---|---|---|---|---|---|
| **A. Two existing purpose-built grants** (recommended) | 2 DML creates, no metadata | None beyond folder View + RunReports; no record visibility, no OWD, no ownership | 2 deletes by captured ID | Partial: pipeline scope differs (78 vs 113); inventory/loyalty/SLA/CSI tiles zero for persona | Full |
| **B. A + narrow read-only permission set** for public-OWD objects (Vehicle__c, Vehicle_Model__c, Rooftop__c, Staff__c, Loyalty_Member__c) | 1 metadata deploy + 1 assignment | Read-only on objects designed Public Read/Write; rep set already grants the same; no OWD/ownership change | 1 assignment delete; permission set may be retained as source | Better: pipeline scoped, inventory 120 and loyalty 72 truthful; SLA/CSI still zero | Full |
| **C. New narrow `Service_Visit__c` sharing rule** (optional, only if required) | 1 deploy + 1 grant | Changes record visibility org-wide for a private object; only option that makes SLA/CSI non-zero for a dynamic persona | Delete rule + revoke grant | Full, if approved | Full |
| **D. Purpose-built persona-owned UAT dataset** | High: record creation | Mutates canonical counter fields via triggers, inflates counts/storage, adds cleanup burden | Delete + purge, counters not cleanly restorable | High but not defensible | Unaffected |
| **E. Separate management test user** | Medium: user + role + profile + fixtures | No better visibility; consumes a licence; forks the persona model | Delete user, assignments, fixtures | Same as A | Same as A |

## 7. Recommended approach

**Option A now, with Option B as an explicitly separate, optional follow-up.**

Batch 2a (recommended, no new metadata, no records, no sharing):

1. Add `Northgate Persona` to `PG_Northgate_Management` (`00Gaj00000ZkluDEAR`) for
   dashboard-folder View.
2. Assign `PS_Management_Reports` (`0PSaj00000gUOW9GAO`), which grants `RunReports` only, for
   report run and drill-through.
3. Owner browser session: open the three fixed dashboards in the Northgate Management folder,
   capture running user, tiles and drill-through; open `DM_Exec_OperationsOverview` in NG_Sales
   and capture the persona-scoped pipeline difference.
4. Restore both grants by captured ID, then re-verify the baseline.

Batch 2b (optional, needs separate approval): deploy a new read-only permission set
`PS_Management_Read` (Object Read on `Vehicle__c`, `Vehicle_Model__c`, `Rooftop__c`,
`Staff__c`, `Loyalty_Member__c` plus the FLS the four reports use) and assign it temporarily,
so the dynamic executive dashboard shows truthful inventory and loyalty values instead of
artificial zeros. No View All, no Modify All, no Create/Edit/Delete, no sharing, no ownership
change.

Batch 2c (optional, needs separate approval): a narrow `Service_Visit__c` sharing rule if the
owner wants non-zero SLA and CSI values for a dynamic management persona. Not required for
P5-15.

## 8. Exact reports, components and expected results for the recommended window

Fixed dashboards (tiles are admin-computed; verify against CLI report values):

| Dashboard / tile | Expected value | CLI cross-check |
|---|---|---|
| `DM_Sales_Operations` Pipeline Amount | 113 rows, 10,587,766 | `Pipeline_by_Stage` admin GET |
| `DM_Sales_Operations` Open Opps by Sales Staff | Amount 6,250,407 | `Open_Opps_by_Sales_Staff` admin GET |
| `DM_Service_OperationsFixed` Overdue Service Visits | 13 | `Service_SLA_Overdue` admin GET (requirement is 12: open gap) |
| `DM_Service_OperationsFixed` CSI Proxy | 0 scored rows | `Service_CSI_Proxy` admin GET (empty state, not accuracy proof) |
| `DM_Finance_Operations` Exception Candidates / Decline Rate / Avg Days to Fund | 0 rows / empty denominator / 0 | three `NG_05_DataQuality` financing reports; N/A not 0% |

Dynamic executive dashboard, persona context:

| Component | Expected persona value | Meaning |
|---|---:|---|
| Pipeline Amount | 78 rows, 4,328,120 | genuine persona scope, 41% of org pipeline |
| Inventory Aged Over 60 Days | 0 without Batch 2b | permission artifact, not a business finding |
| Overdue Service Visits | 0 | service data is Private OWD and admin-owned |
| Loyalty Members | 0 without Batch 2b | permission artifact |
| CSI Proxy | 0 | no scored rows org-wide either |

**Report defect found during this investigation.** `Open_Opps_by_Sales_Staff` filters
`Opportunity.Sales_Staff__c notEqual 'Blank'`, but **all 100 canonical Opportunities have
`Sales_Staff__c = null`**, and the report still returned the full open-opportunity Amount
(6,250,407 = all 82 open opps). The filter is not excluding nulls, and the component label
"Open Opportunities by Sales Staff" therefore describes a grouping that has no data. The
persona has the same nulls. This is a P5-15 acceptance risk: the tile renders, but it is not
"by Sales Staff" and it is not a distinct metric from Pipeline Amount. Fixing it needs either
populated `Sales_Staff__c` on canonical Opportunities (a canonical data change, not authorized)
or a corrected report filter/label (metadata change, separate approval). Flagged, not fixed.

## 9. Required temporary access, setup, verification and restoration

Pre-flight baseline (already captured, re-verify immediately before the window):

| Item | Expected pre-state | Preserve |
|---|---|---|
| GroupMember | only `011aj000006D0ErAAK` → `PG_All_Sales` (`00Gaj00000ZYYhUEAX`) | yes |
| PermissionSetAssignment | `0Paaj000016Ty3HCAS` (profile set), `0Paaj000016dBqzCAE` (`NG_Lightning_Experience_Access`) | yes |
| `PG_Northgate_Management` membership | none | n/a |
| `PS_Management_Reports` assignment | none | n/a |
| Role / profile / ManagerId | `VP_Sales` / `NG_Sales` / null | yes |
| Automation_Settings__c | all three flags false | yes |
| Pending approvals / work items for persona | zero | verify, do not modify |

Setup (two creates, capture returned IDs):

```bash
sf data create record --target-org ng-demo --sobject GroupMember --values "GroupId=00Gaj00000ZkluDEAR UserOrGroupId=005aj00000gE0b3AAC" --json
sf data create record --target-org ng-demo --sobject PermissionSetAssignment --values "AssigneeId=005aj00000gE0b3AAC PermissionSetId=0PSaj00000gUOW9GAO" --json
```

Verification (read-only) and owner browser steps: see §8 for expected values; capture running
user, tile values, drill-through row counts, and the persona's own pipeline totals; save
screenshots under `evidence/P5/`.

Restoration (guaranteed, on success, partial success, failure, interruption or cancellation):

```bash
sf data delete record --target-org ng-demo --sobject GroupMember --record-id <GM_ID> --json
sf data delete record --target-org ng-demo --sobject PermissionSetAssignment --record-id <PSA_ID> --json
```

Rules: delete only the IDs captured from this window's create responses; never delete by tuple
alone; if a create response is lost, resolve attribution against the pre-state with the owner
before deleting; if a delete fails, stop and escalate with the record ID; re-run the §9
baseline queries afterwards and compare field by field.

**Admin `PS_Case_Data_Quality_Fields` assignment.** `0Paaj00000gV45ZGAS` is assigned to admin
`005aj00000feqbNAAQ` as `0Paaj000016wctoCAA` and grants Case Create/Edit/Read plus the two
BAD-03 fields. It is **not** part of the management persona's access, is not copied to the
persona, and is **not** touched by Batch 2. It exists because the new Case fields default to
no field-level security and the BAD-03 fixture insert failed with `INVALID_FIELD` without it.
Retention or removal stays a separate owner decision, and removal must be validated against
the simulated-aging report first, since that report filters on
`Case.Days_Since_Last_Update__c`.

## 10. Acceptance criteria that remain untestable under this approach

| Criterion | Status | Why |
|---|---|---|
| P5-15 fixed dashboards render for a management persona with correct values | testable | fixed running user (admin) + folder View + RunReports |
| P5-14 "two personas see different scope" on pipeline | testable | persona owns all 100 canonical Opportunities: 78 / 4,328,120 vs admin 113 / 10,587,766 |
| P5-14 inventory / loyalty components show values for a management persona | untestable without Batch 2b | persona lacks object Read on Vehicle__c and Loyalty_Member__c |
| P5-14 service SLA / CSI components show values for a management persona | untestable without Batch 2c | `Service_Visit__c` is Private OWD and admin-owned; needs a sharing decision |
| Role-scoped inventory/SLA/loyalty views (a true manager slice rather than "all vs own") | untestable | needs a data model where records are attributed to a manager, or new role-filtered report definitions; out of Phase 5 scope |
| "Open Opportunities by Sales Staff" is a distinct staff metric | untestable as specified | `Sales_Staff__c` is null on all 100 canonical Opportunities; report filter does not exclude nulls; needs a canonical data change or a report fix, both separate approvals |
| P5-16 joined report type builder usability for a management persona | partially testable | Vehicle + Test Drive needs Vehicle__c read; Contact + Loyalty needs Contact read on admin-owned contacts; Service + Case needs Case read |
| Batch 2 must not change OWD, roles, ownership or canonical data | enforceable | this plan changes no OWD, no role, no owner, no canonical field, creates no records |

## 11. One consolidated owner approval request

Approve **Batch 2a only**: two temporary grants for `Northgate Persona` — membership of
`PG_Northgate_Management` and assignment of `PS_Management_Reports` — plus the owner browser
window on the three fixed dashboards and the dynamic executive dashboard, with guaranteed
restoration by captured ID. This grants no record-level access, no sharing, no object
permissions, and no new metadata, so it cannot change canonical data, OWD, roles or ownership.

Do **not** approve Batch 2b (new read-only `PS_Management_Read` permission set) or Batch 2c
(new `Service_Visit__c` sharing rule) in this request. Batch 2b is the minimum change that
makes the dynamic executive dashboard's inventory and loyalty tiles truthful rather than
artificially zero; Batch 2c is the only route to non-zero SLA and CSI values for a dynamic
management persona and is the single item in this plan that alters record-visibility semantics.
Both need their own approval after Batch 2a results are known.

Also confirm, for the record: the `Open_Opps_by_Sales_Staff` null-`Sales_Staff__c` defect (§8)
is recorded as an open P5-15 risk with no fix in this window, and the admin
`PS_Case_Data_Quality_Fields` assignment is untouched and still awaiting its own retention
decision.
