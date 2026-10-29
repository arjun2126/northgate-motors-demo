# Phase 5 — accelerated execution: consolidated release package

Date: 2026-10-20. Org: `ng-demo` (`00Daj00001Ae3iWEAR`) only. This package is a plan;
nothing here deploys, writes Salesforce data, grants permissions, resets, or commits without
owner approval. Read-only investigation, local code/report fixes, local checks and check-only
deployments were performed under the standing authorization for this run.

## 1. Root causes found and local fixes (implemented)

### R1 — loader dropped three relationship columns (root cause of the sales-staff report defect)

`data/scripts/resolve.ts` classified a `X__r.Seed_Tag__c` CSV column by resolving the value
against the *field* name instead of the *target object*. Only worked when field name == object
name (`Vehicle__r`→`Vehicle__c`, `Rooftop__r`→`Rooftop__c`, `Vehicle_Model__r`→`Vehicle_Model__c`).
Broken:

| CSV column | Loaded field | Dropped values (live canonical rows null) |
|---|---|---|
| `Sales_Staff__r.Seed_Tag__c` | Opportunity.Sales_Staff__c | 100 |
| `Preferred_Rooftop__r.Seed_Tag__c` | Account.Preferred_Rooftop__c | 150 |
| `Buyer_Contact__r.Seed_Tag__c` | Quote.Buyer_Contact__c | 60 |

Fix: added `CUSTOM_LOOKUP_TARGETS` (field→object) and use it in `classifyColumns`.
Regression tests `t19`/`t20` added to `data/scripts/tests/resolve.test.ts`.
Validation: `npx tsx data/scripts/tests/resolve.test.ts` — 20 checks PASS.

### R2 — generator wrote a rooftop *name* into a seed-tag column

`makeStaff` wrote `Rooftop__c: rooftop.Name` into the `Rooftop__r.Seed_Tag__c` column, so all 14
Staff__c rows loaded with null Rooftop__c. Fixed to write `rooftop['Seed_Tag__c']`.

### R3 — generator attributed Sales_Staff__c to any staff role

`makeOpportunities` used `staff[(i+1) % staff.length]` (all 14 staff incl. technicians). A field
named Sales_Staff__c feeding an "Open Opps by Sales Staff" report must point at a sales person.
Fixed to `salesStaff[i % salesStaff.length]` over `Sales_Rep`/`Sales_Manager`.

### R4 — generator never set Service_Visit__c.Rooftop__c

The SLA report groups by Service_Visit Rooftop but it was never written. Fixed to derive it from
the vehicle's rooftop.

### R5 — report metadata defects (three reports)

- `Open_Opps_by_Sales_Staff`: filter `Sales_Staff__c notEqual 'Blank'` compares to the literal
  string "Blank", which never excludes nulls. Correct idiom is empty value (matches the working
  `Service_CSI_Proxy` report). Fixed.
- `Aged_Inventory`: no `timeFrameFilter`, so the runtime defaulted the date column to
  THIS_FISCAL_QUARTER and returned 0 rows despite 120 aged vehicles. Added
  `timeFrameFilter INTERVAL_CUSTOM` on `Acquisition_Date__c`.
- `Revoked_Consents`: same defect — defaulted `Granted_On__c` to THIS_FISCAL_QUARTER, returning 0
  rows despite 38 revoked consents. Added `timeFrameFilter INTERVAL_CUSTOM`.

Check-only validation: `sf project deploy validate --manifest manifest/p5-report-fixes-check.xml`
→ `0Afaj00000oVYrpCAG`, 3/3 components, 173 tests, 0 errors. NOT deployed.

## 2. Generator now reproduces the plan's intended counts

Regenerated to a temp dir (`NG_GENERATOR_OUTPUT_DIR`), live counts compare:

| Fixture | Plan | Regenerated (corrected) | Live (stale load) |
|---|---|---|---|
| Vehicles aged >120d | 12 | 12 | 120 |
| Vehicles aged 61-120d | ~3 | 3 | 0 |
| Vehicles ≤60d | ~105 | 105 | 0 |
| Service visits overdue (Scheduled, before anchor) | 12 | 12 | 13 |
| Opportunity Sales_Staff role | sales | Sales_Rep/Sales_Manager only | null (100) |
| Staff__c.Rooftop__c | set | 14 | 0 |

Live canonical data predates the current generator revision; the three DQ gaps (inventory age,
SLA 13-vs-12, staff attribution) all trace to a stale load + R1/R2, not to the reports themselves.

## 3. Prepared data operations (approval-gated — NOT executed)

All are canonical-record field writes that restore the generator's intended values. No pricing,
ownership, stage, CloseDate, or other business field is touched.

- `data/prepared/backfill-staff-rooftop.csv` — 14 rows (Staff__c.Rooftop__c)
- `data/prepared/backfill-account-rooftop.csv` — 150 rows (Account.Preferred_Rooftop__c)
- `data/prepared/backfill-opportunity-staff.csv` — 100 rows (Opportunity.Sales_Staff__c)
- `data/prepared/backfill-servicevisit-rooftop.csv` — 140 rows (Service_Visit__c.Rooftop__c)
- `data/prepared/backfill-quote-buyer.csv` — 60 rows (Quote.Buyer_Contact__c)
- `data/prepared/backfill-vehicle-acquisition.csv` — 120 rows (Acquisition_Date__c → 12/3/105)
- `data/prepared/backfill-servicevisit-schedule.csv` — 140 rows (Scheduled_Start__c → 12 overdue)

Backfill method: upsert/update by Id. No new records. Storage impact ~0.
Quote.Buyer_Contact__c derivation is a fallback (primary contact of the opportunity's account),
because the original `contacts[(i*3)%185]` mapping cannot be reconstructed without the missing
`data/csv/` source — flagged for owner confirmation.

## 4. Remaining DQ fixtures — mechanisms and blockers

| Finding | Expected | Live | Supported fix | Blocker |
|---|---|---|---|---|
| BAD-02 stale open Leads | 35 | 0 | Lead.LastActivityDate and CreatedDate are **not writable**; only activity records move LastActivityDate | Owner decision: add 130 activity records (35 old + 95 recent, +130 activities/storage), or revise criterion, or a clearly-labelled simulated-aging field |
| BAD-09 stacked-discount Quotes | 4 | 2 (UAT) | Real stacking is produced by CP2 pricing, not a field patch; canonical quotes have Rule_Applied_Count__c=1 and Adjusted_Subtotal__c=null | Owner decision: price 4 quotes via the Quote Builder/CP2 path (UI/owner action), or accept 2 |
| BAD-10 No_Show drives without follow-up task | 6 | 12 | 6 follow-up Tasks on 6 of the 12 No_Show drives → 6 remain without | +6 activities (200→206) vs gate-10 activities ±2; owner decision |
| BAD-01 duplicate households | 8 pairs | 0 | 16-contact fixture in `data/prepared/bad01-households-20261020.csv` | +16 contacts, +32KB; duplicate-rule behavior + storage |

BAD-03 operational aging remains time-dependent (8 fixtures become stale ~2026-11-04 if
untouched); the separate simulated report already shows them.

## 5. Blocked on owner decision / unavailable evidence

- **Storage ≤4.0 MB**: live ~4.1 MB. Disposable project-owned UAT records total ~24 records
  (~48KB) — insufficient. The only sizeable lever is the 167 pre-existing 2026-10-01 org sample
  records (~334KB) which are unrelated historical data; deleting them is an owner decision.
  BAD-01/SEED-98 fixtures would push usage up, not down.
- **Canonical `data/csv/` source is missing.** The loader/reload/idempotency and reset paths
  (`P5-02`, `P5-17`) cannot run from a clean source. Regeneration is reproducible with the
  corrected generator but produces *different* content than the loaded stale set — so a reload is
  a canonical data change, not a no-op.
- **P5-05 ledger**: 37 native jobs reconciled (2,085 distinct canonical insert IDs). Historical
  per-batch storage readings and true completion timestamps are unavailable; 20 placeholder rows
  cannot be honestly mapped 1:1 to 37 jobs. No fabrication.
- **P5-17/P5-19 reset/burst**: planner-only today; missing `data/csv/`, external-reference
  discovery and a full executor. Original ng-dev execution criterion conflicts with the
  ng-demo-only boundary.
- **P5-14 dynamic two-persona scope**: only one management persona exists; no persona-readable
  data for Vehicle__c/Service_Visit__c/Loyalty_Member__c (Private OWD, admin-owned). Two-persona
  evidence requires owner approval of either a purpose-built persona-owned dataset or a narrow
  read-only viewer grant.

## 6. Batch 2a management UAT (prepared, not executed)

Corrected access model (read-only, verified):

- Northgate Persona `005aj00000gE0b3AAC` owns **100 canonical Opportunities** + 1 UAT (101),
  reads them (`UserRecordAccess` read/edit true), and holds 104 AccountShare rows
  (`ImplicitParent`). Pipeline scope: 78 rows / 4,328,120 (Stage != Closed Lost) vs admin
  113 / 10,587,766.
- Persona has no object Read on Vehicle__c, Service_Visit__c, Loyalty_Member__c, Staff__c, Case,
  Quote, Financing__c, and owns none of those rows.

Two temporary grants (folder View + RunReports), no records, no sharing:

```bash
sf data create record --target-org ng-demo --sobject GroupMember \
  --values "GroupId=00Gaj00000ZkluDEAR UserOrGroupId=005aj00000gE0b3AAC" --json   # capture GM_ID
sf data create record --target-org ng-demo --sobject PermissionSetAssignment \
  --values "AssigneeId=005aj00000gE0b3AAC PermissionSetId=0PSaj00000gUOW9GAO" --json  # capture PSA_ID
```

Owner browser window: three `SpecifiedUser` dashboards render admin-computed values
(DM_Sales_Operations 113/10,587,766 · DM_Service_OperationsFixed 13 overdue · DM_Finance_Operations
zeros/N-A) without extending any record access. `DM_Exec_OperationsOverview` is LoggedInUser, so
the persona sees only its own 78/$4.33M pipeline; the other four components are empty for it
(no read on those objects). Capture both numbers as evidence.

Restoration (success, partial, failure, interruption or cancellation):

```bash
sf data delete record --target-org ng-demo --sobject GroupMember --record-id <GM_ID> --json
sf data delete record --target-org ng-demo --sobject PermissionSetAssignment --record-id <PSA_ID> --json
```

Preserve baseline: `011aj000006D0ErAAK` (PG_All_Sales), `0Paaj000016Ty3HCAS`,
`0Paaj000016dBqzCAE`; role VP_Sales, NG_Sales profile, ManagerId null, bypass flags all false.
Admin `PS_Case_Data_Quality_Fields` assignment `0Paaj000016wctoCAA` is untouched and not copied to
the persona.

## 7. One consolidated approval request

Approve, in this order:

1. **Deploy 3 report fixes** — `manifest/p5-report-fixes-check.xml` (already check-only clean,
   `0Afaj00000oVYrpCAG`). Batch 1 remains closed; this is new scope.
2. **Run the 7 relationship/date backfills** (section 3) as data operations by Id, read-only
   verify counts after (100/150/60/140/14/120/140). Confirms P5-15 staff grouping and P5-10/11.
3. **Authorize Batch 2a management UAT** (section 6) with exact-ID restoration.
4. **Decide** BAD-02/BAD-09/BAD-10 mechanisms (section 4) and storage disposition (section 5).

Do not yet: create fixtures, run resets, grant persona object read, or change acceptance criteria.
