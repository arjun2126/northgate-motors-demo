# Phase 5 cleanup & completion — execution-ready package

Date: 2026-10-20. Org: `ng-demo` only. Nothing here is executed until the consolidated
approval request is signed. Read-only inspection, local fixtures/manifests and check-only
validation only.

## 1. Storage cleanup — exact deletion manifest

### 1.1 What is safe to delete (verified dependencies)

The **167 pre-existing sample records** are the org's built-in Salesforce sample data (Edge
Communications, Bertha Boxer, Generator cases, etc.), created 2026-10-01T01:20:58Z, untagged.
They are referenced by **zero canonical (`SEED-%`) Northgate records** and by zero UAT workflow
records (verified across Opportunity/Contact/Case/OLI/QLI/CampaignMember/Task/Event). They carry
no ContentDocumentLink, FeedItem, or ProcessInstance.

Plus **2 pre-seed Financing records** (`a04aj0000087p4PAAQ`, `a04aj0000087p61AAA`, Draft, no
vehicle/quote) that reference sample Opportunity `006aj00000eebi5AAA` and sample Contacts —
they must be deleted first.

### 1.2 Manifest (child-first order)

`data/prepared/deletion_manifest_2026-10-20.json` (169 records):

| # | Object | Count |
|---|---|---|
| 1 | Financing__c (pre-seed test) | 2 |
| 2 | PricebookEntry (sample) | 34 |
| 3 | Case (sample) | 26 |
| 4 | Contact (sample) | 20 |
| 5 | Opportunity (sample) | 31 |
| 6 | Lead (sample) | 22 |
| 7 | Campaign (sample) | 4 |
| 8 | Product2 (sample) | 17 |
| 9 | Account (sample) | 13 |

**Expected storage recovery ≈ 362 KB (0.35 MB).** Current ~4.0 MB → ~3.65 MB, satisfying the
≤4.0 MB gate with headroom for fixtures below.

Recoverable snapshot: every field/record is either pre-existing sample data (recreate-by-Salesforce
sample or accept loss) or a Draft test Financing record. A pre-delete CSV snapshot of the 167
sample records is included for recovery if required.

**Do not delete:** canonical `SEED-%` records, UAT approval/pricing evidence (MANAGER 8PCT, VP
12PCT, FIN exception, REP quote and their quotes/QLIs), the 8 BAD-03 fixture Cases, or the
relationship backfills already applied.

## 2. Replacement fixtures (test scenarios) — prepared, not inserted

All prefer genuine workflows/automation. No CP2 results or audit timestamps are fabricated.

| Scenario | Fixture | Mechanism | Expected |
|---|---|---|---|
| BAD-02 stale open Leads | `data/prepared/bad02-stale-lead-tasks.csv` (35 Tasks) | 35 backdated Tasks (ActivityDate 2026-07-01) on Leads SEED-08-001..035; platform sets `LastActivityDate` | `Stale_Open_Leads` report = 35 (verify with 1 pilot Task first) |
| BAD-09 stacked-discount Quotes | none (no data patch) | 2 more quotes via Quote Builder on aged-premium-trim vehicles → real `Rule_Applied_Count__c` = 2 | 4 total stacked quotes (2 exist already) |

BAD-09 is reproducible from current data: **43 vehicles** (`SEED-05-%`) are aged ≥90 **and** `Premium`/`Limited` trim, so
`Trim_Premium_*` + `Aged_Inventory_Discount_90` both apply. All 11 `Quoting` opportunities have `Vehicle__c`
null, so the genuine flow is: attach one of the 43 vehicles to a Quoting opportunity, run Quote Builder/CP2.
Existing stacked evidence: `0Q0aj000003kJNhCAM` (MANAGER 8PCT, $307,997.95) and `0Q0aj000003kSijCAE`
(VP 12PCT, $322,422.10), both `Rule_Applied_Count__c=2`.
| BAD-10 No-show Test Drives w/o follow-up | `data/prepared/bad10-noshow-followup-tasks.csv` (6 Tasks) | follow-up Tasks on 6 of 12 No_Show drives; 6 remain without | 6 No_Show drives lacking follow-up |
| BAD-01 duplicate households | `data/prepared/bad01-households-20261020.csv` (16 Contacts, 8 pairs) | same surname+street+postal+email across 2 accounts → `DR_Contact_Email` fires | 8 duplicate-rule hits; Duplicate_Households/Audit show 8 pairs |
| SEED-98 malformed data | `data/prepared/seed98-mapped-20261020/` (24 Contacts + 6 Trade_Ins) | 10 malformed phones, 8 missing postal, 6 case-insensitive emails, 6 invalid VINs | 30 rows; SEED98 reports populated. **No bypass needed** (all fields are free text; no Contact phone/email VR exists) |

Net storage after cleanup + fixtures ≈ 3.79 MB (within gate).

## 3. Data corrections — review only, do not execute without separate approval

### 3.1 Vehicle acquisition dates (`backfill-vehicle-acquisition.csv`, 120 rows)

- Changes `Inventory_Age_Days__c` (formula) → the `Aged_Inventory_Discount_60/90` CP2 rules would
  no longer apply to 108 vehicles. **Canonical quotes are unpriced** (`Adjusted_Subtotal__c` null,
  `Rule_Applied_Count__c=1`), so **no stored quote value changes**; impact is future quote pricing
  and the Inventory-Aging report only.
- `VehicleTrigger` re-runs VIN validation (VIN unchanged → no-op) and `VehicleCounterTrigger`
  re-maintains rooftop counters (rooftop unchanged → same totals). No net automation change.
- **Recommendation:** execute (reversible, automation-preserving) **with owner sign-off**, OR
  accept the 120-aged deviation via the waiver below.

### 3.2 Service Visit schedules (`backfill-servicevisit-schedule.csv`, 140 rows)

- Sets 12 Scheduled visits into the past (SLA 13→12). `VR_ServiceVisit_FutureForNew` would trip
  for a non-bypass user; admin holds `Bypass_Automation`, so it does not block. No other
  trigger/flow on `Service_Visit__c`.
- **Recommendation:** execute in admin context, OR accept 13 and record the anchor-dependent
  drift in the waiver. Do not pin the report to a fixed date (changes operational semantics).

## 4. Historical evidence — unrecoverable, documented

- **P5-05 ledger:** 37 native jobs reconciled in `evidence/P5/execution_ledger_2026-10-20.json`
  (2,085 distinct canonical insert IDs). Historical **per-batch storage readings** and true
  completion timestamps are **unavailable**; the 20 placeholder `Data_Load_Batch__c` rows cannot
  be honestly mapped 1:1 to 37 jobs.
- **P5-08 gate 9/13** (ledger match, storage ≤4.0 MB after every load): cannot be reconstructed
  retroactively.
- **Canonical `data/csv/` source is missing** — reload/idempotency (P5-02) and reset (P5-17)
  cannot run from clean source without regenerating, which produces different content than the
  loaded stale set.
- **Waiver requested:** accept the reconciled job evidence as the ledger; accept storage verified
  **now** (≤4.0 MB after cleanup) rather than per-batch; accept the SLA "12" and inventory "12"
  as anchor-date truths (or execute §3 corrections). No fabricated evidence.

## 5. Focused end-to-end regression plan (after approvals)

One pass, admin + Northgate Persona (temporary grants, captured-ID restore):

1. **CP2 pricing** — `QuotePricingService`/Quote Builder: create a quote on a premium-trim vehicle,
   verify `Adjusted_Subtotal__c` + `Rule_Applied_Count__c` are populated and match the engine.
2. **Approvals** — manager 5–10% and VP >10% routes; verify `Approval_Status__c` and write-back;
   confirm zero pending approvals at end.
3. **Financing** — Finance wizard live payment, `Rate_Table__mdt` mapping, exception route.
4. **Test Drives** — `TestDrive_Book_Screen`: success, overlap rejection, boundary slot; verify
   follow-up Task and counters.
5. **Delivery** — checklist completion → `Delivery_Completed__c=true`, Opportunity Closed Won.
6. **Loyalty** — enrolment on delivery, tier/balance correctness.
7. **Reporting** — re-run the fixed reports (Stalled 6, Aged 12/120, Revoked 38, Open Opps by
   Sales Staff 65/$3,585,146, SLA 12/13) and confirm values tie to SOQL.
8. **Apex** — `sf apex run test` (RunLocalTests) green; no regressions in the 173-test suite.

## 6. Minimum prerequisites for Phase 6

1. Storage cleanup (§1) executed and ≤4.0 MB confirmed.
2. Fixtures (§2) inserted and verified (P5-06, P5-13, P5-09 SEED-98).
3. Management dashboard UAT (P5-14/15) signed via Batch 2a window.
4. Historical-evidence waiver (§4) signed.
5. Data corrections (§3) resolved (execute or waive).

## 7. Consolidated approval request

Approve, in order:

1. **Delete the 169-record manifest** (`data/prepared/deletion_manifest_2026-10-20.json`) after a
   pre-delete snapshot export; verify storage ≤4.0 MB.
2. **Insert fixtures** (§2) — BAD-01 16 contacts, SEED-98 30 rows, 35 stale-lead tasks (pilot
   first), 6 no-show follow-up tasks; then create 2 more CP2 stacked quotes via the genuine Quote
   Builder workflow.
3. **Execute data corrections** (§3) — vehicle acquisition dates and service-visit schedules,
   with your explicit sign-off on the CP2/VR implications.
4. **Run the regression** (§5) and the Batch 2a management UAT window.

Do not yet: execute deletions/inserts/corrections, deploy metadata, change permissions/roles/
sharing/bypass, commit/push, or touch `ng-dev`.
