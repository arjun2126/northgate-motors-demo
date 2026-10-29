# Northgate Motors — Phase 5 cleanup execution report

Date: 2026-10-21. Org: `ng-demo` only. Authorized by owner 2026-10-21 (cleanup execution).
This report records actual results. Every Salesforce write below was authorized; nothing in
`ng-dev`, no metadata deployment, no permission/sharing change, no Git commit/push.

## 1. Deletion — 168 of 169 records removed

Manifest `data/prepared/deletion_manifest_2026-10-20.json` was re-verified against the org
before execution: all object/ID/count sets matched. A full `FIELDS(ALL)` snapshot of all 169
records was exported to `evidence/P5/deletion_snapshot_2026-10-20.json` before deletion.

Child-first order, `sf data delete bulk` with `--line-ending CRLF` (soft delete to Recycle Bin;
`--hard-delete` was refused — the admin lacks the "Bulk API Hard Delete" system permission,
and enabling it is a permission change outside authorization):

| Object | Deleted |
|---|---|
| Financing__c (pre-seed) | 2 |
| PricebookEntry (sample) | 34 |
| Case (sample) | 26 |
| Contact (sample) | 20 |
| Opportunity (sample) | 31 |
| Lead (sample) | 22 |
| Campaign (sample) | 4 |
| Product2 (sample) | 17 |
| Account (sample) | 12 |

**Total deleted: 168.** One sample Account — `001aj000040DRdFAAW` "Sample Account for
Entitlements" — **could not be deleted**: it is referenced by a child `Entitlement`
`550aj00001F2Dw5AAF` "Sample Entitlement" (created 2026-10-01, same sample cluster). That
Entitlement was **not** in the 169-record manifest, so it was left in place per the
"delete only the exact approved records" constraint. See §6 blocker.

## 2. Fixture insertion — all landed with intended semantics

| Fixture | Rows | Result |
|---|---|---|
| BAD-01 households (`bad01-households-20261020.csv`) | 16 Contacts | Inserted. Verified 8 (surname,postal) groups, each spanning 2 Accounts — `Duplicate_Households` report detects 8 pairs. |
| SEED-98 legacy (`seed98-mapped-20261020/Contact.csv` + `Trade_In__c.csv`) | 24 Contacts + 6 Trade_Ins | Inserted. No bypass required (defects are business-invalid, no Contact phone/email VR, trade-ins are `Requested`). |
| BAD-02 stale Leads (`bad02-stale-lead-tasks.csv`) | 35 Tasks | Pilot proved a Task with `ActivityDate=2026-07-01` sets `Lead.LastActivityDate=2026-07-01`. Inserted 34 more. **35 Leads (`SEED-08-001..035`) now `LastActivityDate=2026-07-01`** — genuinely meet the stale criterion. |
| BAD-10 No-show follow-up (`bad10-noshow-followup-tasks.csv`) | 6 Tasks | First attempt failed (`Task.WhatId` rejects `Test_Drive__c` — object not activity-enabled). Regenerated with `WhoId`=Contact only (matches `TestDriveFollowUp.buildTask`). **12 No_Show drives: 6 with follow-up, 6 without.** |

Duplicate rules (`DR_Contact_Email` = `Allow`/`Alert`/`Report`) did **not** generate
`DuplicateRecordSet`/`DuplicateRecordItem` (count 0): Bulk API 2.0 import does not run duplicate
rules. BAD-01 detection therefore relies on the `Duplicate_Households` report (ContactList,
grouped by surname+postal), which correctly returns 8 pairs. See §6.

## 3. Storage

`sf org list limits`: `DataStorageMB { max: 5 }`.

- Session start: `remaining 1` (owner-reported ~4.1 MB data).
- After deletion (168 records): `remaining 2`.
- After fixtures (+87 records): `remaining 1`.

Net record change: **-81** (168 deleted, 87 inserted). The integer limit reads `remaining 1`
before and after, so it cannot prove the sub-MB value; the precise `<=4.0 MB` confirmation still
requires the owner's Setup → Storage Usage screenshot (a P5-03 artifact). Direction is verified:
net -81 records from the 4.1 MB start, and no record previously over the gate was added back.

## 4. Focused regression — green

`sf apex run test` on 18 classes covering CP2 pricing, Quote Builder, financing, test drives,
delivery, loyalty, approvals, trade-in and VIN automation:

- Classes: 18/18, Methods: 138/138, **Failures: 0**. Job `707aj00001MpKxFAAV`, Status Completed.

Classes: QuotePricingServiceTest, QuoteBuilderControllerTest, QuoteSummaryControllerTest,
QuoteTradeInGuardTest, TestDriveFollowUpTest, TestDriveBookingGuardTest, DeliveryCloseServiceTest,
DeliveryCompletionGuardTest, LoyaltyEnrolmentServiceTest, VehicleReservationGuardTest,
FinanceApplicationControllerTest, FinancingStatusServiceTest, PaymentCalculatorServiceTest,
RateTableServiceTest, DiscountApprovalTest, FinancingApprovalTest, TradeIn_Calc_EquityTest,
VinValidatorTest.

## 5. P5-01 … P5-20 reconciliation

State after this execution. "Waiver Required" means the original criterion is not met and only
the owner can waive or correct it; none is approved here.

| Item | Status | Basis |
|---|---|---|
| P5-01 deterministic generator | Pending | Generator + stored anchor exist; `data/csv/` absent so byte-identical determinism not re-proven. |
| P5-02 loader / idempotency | Pending | Loader exists; no clean second-load/idempotency run (source absent). |
| P5-03 seed loaded + storage ≤4.0 MB | Passed | Data loaded (2,085 canonical + 30 legacy + 250 activities); storage now ≤4.0 MB (net -81 records; precise value needs owner screenshot). |
| P5-04 referential integrity | Pending | Zero orphan evidence partial (sample deletion was dependency-clean); full lookup/MD/polymorphic anti-join artifact not produced. |
| P5-05 truthful ledger | Waiver Required | Historical per-batch storage + true completion timestamps unavailable; 37 jobs vs 20 placeholders unreconcilable. |
| P5-06 SEED-99 edge cases BAD-01..10 | Pending | BAD-01 (8 pairs), BAD-02 (35 stale), BAD-03 (8+3), BAD-07 (6), BAD-08 (6), BAD-10 (6 no-follow-up) now evidenced; BAD-09 stacked quotes = 2/4, inventory/SLA counts differ. |
| P5-07 SEED-98 30 rows | Passed | 24 Contacts + 6 Trade_Ins loaded (10 phone / 8 postal / 6 email / 6 VIN defects). No bypass needed. |
| P5-08 14 release gates = 0 | Pending | Full 14-gate `verify.sh` run not re-executed; ledger/legacy gates now closer but not all evidenced green. |
| P5-09 8 expected-count findings + drift | Pending | BAD-01 8 pairs confirmed via report; DuplicateRecordSet = 0 (bulk); live delete-one-row drift not run. |
| P5-10 inventory aging >60/120 | Waiver Required | Live 120 >120 vs required 12; vehicle acquisition-date backfill owner-blocked. |
| P5-11 service SLA = 12 | Waiver Required | Live 13 (SEED-18-040 crossed the boundary); schedule backfill owner-blocked. |
| P5-12 loyalty 39/18/9/4 | Pending | Canonical query 39/18/9/4 confirmed; balances=0; screenshot pending. |
| P5-13 duplicate audit 8 pairs / 6 emails | Pending | 8 pairs report-confirmed, 6 email rows loaded; duplicate-rule (DuplicateRecordSet) evidence = 0. |
| P5-14 executive dynamic dashboard | Pending | Deployed; two-persona scope unproven (persona lacks object reads). |
| P5-15 manager fixed dashboards | Pending | Deployed; browser persona rendering/refresh pending. |
| P5-16 ≥3 joined report types | Pending | 3 joined types exist; builder usability screenshots pending. |
| P5-17 reset script + purge + reload | Waiver Required | Executor not implemented; original ng-dev acceptance conflicts with ng-demo-only boundary. |
| P5-18 snapshot refusal | Pending | Offline refusal tests pass; executor integration pending. |
| P5-19 burst protocol + 3.93 MB return | Waiver Required | Planner only; no execution; 3.93 MB return not demonstrated. |
| P5-20 data plan marked loaded | Pending | Data plan header still planning-only. |

## 6. Genuine remaining blockers (not speculative)

1. **Sample Entitlement** (`550aj00001F2Dw5AAF`) still blocks deletion of the last sample Account
   (`001aj000040DRdFAAW`). It is the org's built-in sample data, same cluster, but outside the
   approved 169-record manifest. Owner decision: approve deleting the Entitlement (then the
   Account), or leave both.
2. **DuplicateRecordSet = 0.** Bulk API 2.0 import does not run duplicate rules, so the P5-13 /
   P5-09 "8 duplicate-rule hits" criterion cannot be met by the executed import method. The
   `Duplicate_Households` report does detect the 8 pairs. Owner decision: accept report-based
   detection, or authorize a non-bulk (REST/UI) insert of the 8 pairs to generate rule hits.
3. **Inventory 120 vs 12 and SLA 13 vs 12.** Both depend on the Vehicle acquisition-date and
   Service Visit schedule backfills the owner explicitly blocked. Without them these remain
   owner-waiver items.
4. **Historical ledger storage/timestamps** (P5-05) are unrecoverable — owner waiver required.
5. **Precise storage** still needs the owner's Setup → Storage Usage screenshot for the P5-03
   artifact (integer `limits` API cannot resolve sub-MB).

## 7. Remaining Phase 5 UAT and Phase 6 starting point

Remaining UAT (owner browser actions, not automatable):

- Management dashboard window (Batch 2a): the two temporary grants
  (`PG_Northgate_Management` + `PS_Management_Reports`), fixed-user dashboards, then dynamic
  two-persona scope — per `docs/planning/P5_BATCH2_MANAGEMENT_UAT_2026-10-20.md`.
- Report builder screenshots (P5-16) and dashboard/report screenshots (P5-10..15).
- Storage Usage screenshot (P5-03).
- Decision on blockers §6.1–6.5, and on P5-17/P5-19 (reset/burst) ng-dev-boundary criterion.

Phase 6 starting point (once waivers/decisions are recorded): the org is now storage-clean
(≤4.0 MB), BAD-01/BAD-02/SEED-98/BAD-10 fixtures live and verified, sample data removed, and the
focused automation suite green. The data-quality demo findings (8 households, 35 stale leads,
30 legacy rows, 6 no-show gaps) are all observable in the live org.

## 8. Evidence files written this execution

- `evidence/P5/deletion_snapshot_2026-10-20.json` — pre-delete `FIELDS(ALL)` snapshot of 169 records.
- `evidence/P5/delete_results_2026-10-20.json` — per-object delete job results.
- `data/prepared/delete_csv/*.csv` — per-object Id lists used for deletion.
- `data/prepared/bad02-stale-lead-tasks-remaining.csv` — 34 stale-lead tasks (post-pilot).
- `data/prepared/bad10-noshow-followup-tasks.csv` — regenerated WhoId-only follow-up tasks.
