# Phase 2/5 controlled release and UAT — 2026-10-20

## Deployments — CONFIRMED

Phase 2 real deploy: `0Afaj00000oQaj1CAC`, `Succeeded`, 4/4 components, 0 errors.

```text
Flow: TestDrive_Book_Screen (created)
PermissionSet: PS_Lead_Conversion (created)
PermissionSet: PS_Test_Drive_Booking (created)
PermissionSetGroup: PSG_Rep (updated)
```

Phase 5 real deploy: `0Afaj00000oQtVWCA0`, `Succeeded`, 15/15 components, 0 errors.

```text
CustomField: Vehicle__c.Reporting_Make__c (created)
ReportType: ServiceVisitList (updated), TradeInList (created), VehicleList (updated)
Report: Inventory_Aging_60_120, Service_SLA_Overdue, Service_CSI_Proxy,
       SEED98_Contacts, SEED98_TradeIns, Loyalty_Tier_Distribution
DashboardFolder: NG_Management (created)
Dashboard: DM_Exec_OperationsOverview, DM_Sales_Operations,
          DM_Service_OperationsFixed, DM_Finance_Operations
```

Pre-deploy gate: exactly the 19 validated source files (4 Phase 2 + 15 Phase 5) changed; no
unrelated or additional files. Manifests unchanged from the successful check-only jobs
`0Afaj00000oQSwkCAG` and `0Afaj00000oQNXGCA4`.

## Effective permission verification — CONFIRMED (declarative)

After deploy, live state:

```text
PermissionSetGroup PSG_Rep: Status=Updated
  PSG_Rep components: PS_Lead_Conversion, PS_Sales_Rep, PS_Test_Drive_Booking
FlowDefinition TestDrive_Book_Screen: ActiveVersionId=301aj000046ME8UAAW (active)
PS_Lead_Conversion: PermissionsEditTask=true, PermissionsConvertLeads=true
PS_Test_Drive_Booking: PermissionsRunFlow=true
```

Persona switch to rep assigned `PSG_Rep` and role `Sales_Rep`, profile `NG_Sales`,
`ManagerId=null`. Effective union for intended rep therefore includes EditTask, ConvertLeads,
RunFlow and the booking Flow access. No permission beyond the validated package was added.

## Controlled Phase 2 UAT — BLOCKED (persona-scoped)

`scripts/uat/p2_setup.apex` aborted before any insert:

```text
System.IllegalArgumentException: Disable bypass before Phase 2 UAT.
```

The guard correctly detected `Bypass_Automation` on the running admin context. The lead
intake flow (`Lead_Enrich_Rooftop`) and routing trigger are persona-scoped: an admin-context
CLI session has `Bypass_Automation`, so the flow would skip rooftop assignment and produce
false routing evidence. Conversion permission and the booking Flow likewise require a rep
session that the CLI cannot emulate (`System.runAs` is test-only).

Result: zero `UAT-P2-*` records were created; no conversion and no Test Drive writes occurred.
This step cannot be completed from the current admin CLI session. Owner must run the browser
Login-As-rep session, or provide a rep-context authenticated session.

## Baseline restoration — CONFIRMED

```text
Restored baseline: role=VP_Sales (00Eaj00000QCxlLEAT), ManagerId=null, PSGs=<none>.
```

Post-restore user: role `VP_Sales`, profile `NG_Sales`, `ManagerId=null`, active. Assignments
are exactly the two unrelated baseline sets (`NG_Lightning_Experience_Access`,
`X00eaj00000TnZaFAAV`). No `UAT-P2-*` leads exist. Pending approvals submitted by and work
items assigned to the persona both returned `totalSize: 0`.

## Phase 5 runtime validation — read-only

Reports return valid results (no errors):

| Report | Runtime result | Note |
|---|---|---|
| Inventory Aging >60 | 120 rows | All 120 canonical vehicles exceed 60 days under the anchor date; threshold not discriminating; >120 slice not separately surfaced |
| Service SLA Overdue | 20 rows | Expected BAD-04 is 12; report excludes Completed/Cancelled only, so it includes additional past-scheduled/No-Show rows; expected-count mismatch to reconcile |
| Service CSI Proxy | 0 rows | No CSI_Score__c populated in seed; empty population, not a rendering error |
| SEED98 Contacts / Trade Ins | 0 rows each | Correct: SEED-98 not loaded |
| Loyalty Tier Distribution | 72 members, 4 tiers | All-date (INTERVAL_CUSTOM, no dates); runs correctly |

Dashboards deployed and resolvable; all four report `componentDataStatus=NO_DATA` because they
have not yet been refreshed after first deployment. First browser view will populate components.

Accessibility findings (not changed): the new `NG_Management` dashboard folder has no folder
shares in source, so it is owner/admin-only until a manager-access decision is made. Executive
dashboard is `LoggedInUser`; two-persona scope still needs two authorized personas with
legitimate access to every referenced object. Fixed-user manager dashboards render as
`arjun.ngdemo@northgate.demo`.

## Governing allocation reconciliation — CONFIRMED

Owner selected 60 Product2 + 12 Delivery as governing. `phase5.py counts` now reports:

```json
{
  "canonicalRecords": 2085,
  "governingFullTotal": 2115,
  "historicalBacklogFullTotal": 2123,
  "allocationAdjustment": {"Product2": "+20", "Delivery__c": "-28", "net": -8},
  "status": "RECONCILED_GOVERNING_2026_10_20"
}
```

Updated: `data/SEED_VERSION.txt`, `DEMO_ORG_BACKLOG.md` P5-03, `DEMO_ORG_MASTER_PLAN.md`
change note, `docs/DATA_QUALITY.md`, `data/scripts/phase5.py` (counts + verify envelope 2,115),
and the offline test. Historical 2,123 and original canonical 2,085 are preserved and labelled.
Seven offline checks pass; no records fabricated, no target silently reduced.

## Remaining completion blockers

- Phase 2 UAT still requires a genuine rep browser session: routing, qualification,
  conversion into new records, Flow booking success/overlap, stage/task evidence.
- SEED-98 remains not loaded (parent mappings, bypass controls, exact data approval).
- Ledger remains 20 placeholder rows; genuine per-batch evidence still missing.
- Service SLA report expected-count mismatch (20 vs 12) needs a scoped filter decision.
- Inventory >60 report does not discriminate the >120 bucket; semantics to confirm.
- Management dashboard folder access and executive two-persona verification pending.
- Exact Storage Usage screenshot (P5-03) and reset/burst execution safeguards outstanding.

No SEED-98 load, reset/purge, historical ownership change, broad sharing change, commit, push,
or Phase 6–8 work occurred.
