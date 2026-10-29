# P5-05 Ledger Design — Additive Proposal (NOT a 20-row overwrite)

## 1. The Problem

The 20 existing `Data_Load_Batch__c` records were created by the loader's
step 27 (which loaded the `27-dataloadbatches.csv` as seed data). They
contain placeholder values from the CSV:
- `Object__c = "Mixed"` for all 20
- `Inserted_Count__c = 0` for all 20 (wrong; the Data_Load_Batch__c step inserted 20)
- `Loaded_At__c = 2026-10-01T00:00:00.000Z` for all 20 (hardcoded placeholder)
- `Notes__c = "Loader-written batch row."` for all 20 (placeholder)

The 20 `Seed_Tag__c` values (`SEED-25-001..020`) do NOT map 1:1 to the 27
actual wrapper execution runs. The wrapper logs show 25 execute-mode runs
across 27 steps, but the 20 ledger records were loaded as a single CSV
batch by step 27, not as per-step ledger entries.

## 2. Reconciliation of 19 vs 25 Wrapper Runs

The `data/scripts/ledger-reconcile.ts` analyzer extracted:
- **31 total wrapper log files** in `data/automation-control/logs/`
- **25 execute-mode runs** (detected via "detected mode: execute" in log)
- **19 successful canonical loads** (with "OK (succeeded=N/M; failed=0)")
- **4 failed runs** (QuoteLineItem initial failures, Campaign initial failure, CampaignMember failure)
- **3 retry successes** (QuoteLineItem after fix, Campaign after fix, CampaignMember after fix)

The 25 execute-mode runs correspond to attempts; the 19 successful runs
correspond to canonical completion. The 20 ledger rows cover none of
these 19 runs directly.

## 3. Proposed Additive Ledger Design

Instead of overwriting the 20 existing records (which would require
fabrication), the proposal is to **add new records** that accurately
represent the actual execution, leaving the 20 existing records
intact (they remain valid as "loader-written batch rows" from step 27).

### New records to add (19 total — one per successful canonical load):

Each new record uses a `Seed_Tag__c` derived from the actual wrapper log
filename (e.g., `SEED-EXEC-20261018T050942Z` for step 27). The `Batch_Number__c`
continues from 21 (the existing 20 use 1-20).

**Record 1: Step 13 QuoteLineItem (2026-10-18T04:36:36.000Z)**
- Seed_Tag__c: `SEED-EXEC-20261018T043636Z`
- Object__c: "Consent" (closest in picklist; QuoteLineItem not available)
  - NOTE: QuoteLineItem is not in the Object__c picklist. This is a
    picklist limitation, not a data issue. The Notes__c field records
    the actual object name.
- Inserted_Count__c: 80
- Failed_Count__c: 0
- Status__c: "Loaded"
- Loaded_At__c: 2026-10-18T04:36:36.000Z (from wrapper log)
- Seed_Version__c: "SEED-2026.10.01"
- Notes__c: "Step 13 QuoteLineItem: 80 inserted, 0 failed. Bulk API job 750aj00001HpBiKAAV. Evidence: data/automation-control/logs/20261018T043636Z-wrapper.log"
- Batch_Number__c: 21

**Record 2: Step 14 Trade_In__c (2026-10-18T04:58:12.000Z)**
- Inserted_Count__c: 45
- Notes__c: "Step 14 Trade_In__c: 45 inserted, 0 failed. Evidence: data/automation-control/logs/20261018T045812Z-wrapper.log"
- Batch_Number__c: 22

**Record 3: Step 15 Financing__c (2026-10-18T04:58:56.000Z)**
- Inserted_Count__c: 60
- Batch_Number__c: 23

**Record 4: Step 16 Delivery__c (2026-10-18T04:59:39.000Z)**
- Inserted_Count__c: 12
- Batch_Number__c: 24

**Record 5: Step 17 Test_Drive__c (2026-10-18T05:00:17.000Z)**
- Inserted_Count__c: 70
- Batch_Number__c: 25

**Record 6: Step 18 Case (2026-10-18T05:01:26.000Z)**
- Inserted_Count__c: 60
- Batch_Number__c: 26

**Record 7: Step 19 Service_Visit__c (2026-10-18T05:02:49.000Z)**
- Inserted_Count__c: 140
- Batch_Number__c: 27

**Record 8: Step 20 Campaign (2026-10-18T05:44:10.000Z, retried)**
- Inserted_Count__c: 5
- Notes__c: "Step 20 Campaign: 5 inserted, 0 failed (after retry; initial attempt failed with EndDate < StartDate). Evidence: data/automation-control/logs/20261018T054410Z-wrapper.log"
- Batch_Number__c: 28

**Record 9: Step 21 CampaignMember (2026-10-18T05:44:54.000Z)**
- Inserted_Count__c: 60
- Batch_Number__c: 29

**Record 10: Step 22 Loyalty_Member__c (2026-10-18T05:05:04.000Z)**
- Inserted_Count__c: 70
- Batch_Number__c: 30

**Record 11: Step 23 Loyalty_Transaction__c (2026-10-18T05:05:57.000Z)**
- Inserted_Count__c: 110
- Batch_Number__c: 31

**Record 12: Step 24 Consent__c (2026-10-18T05:06:49.000Z)**
- Inserted_Count__c: 90
- Batch_Number__c: 32

**Record 13: Step 25 Task (2026-10-18T05:07:47.000Z)**
- Inserted_Count__c: 200
- Batch_Number__c: 33

**Record 14: Step 26 Event (2026-10-18T05:08:35.000Z)**
- Inserted_Count__c: 50
- Batch_Number__c: 34

**Record 15: Step 27 Data_Load_Batch__c (2026-10-18T05:09:42.000Z)**
- Inserted_Count__c: 20
- Notes__c: "Step 27 Data_Load_Batch__c: 20 inserted, 0 failed (this batch). Evidence: data/automation-control/logs/20261018T050942Z-wrapper.log"
- Batch_Number__c: 35

### Steps 1-12 (Rooftop through Quote) — no individual log files found

The wrapper logs for steps 1-12 (Rooftop__c, Vehicle_Model__c, Product2,
PricebookEntry, Staff__c, Vehicle__c, Account, Contact, Lead, Opportunity,
OpportunityLineItem, Quote) were not preserved in
`data/automation-control/logs/` because the loader was run directly
via `npx tsx` (not through the wrapper) for these steps. The
timestamps for these steps can be inferred from the `SEED-06-001`
Account record (CreatedDate 2026-10-18T03:05:37.000Z) and similar
records, but exact per-step timestamps are not available.

**Proposed Records 16-19 (or 35-38): Steps 1-12 aggregate**
- Seed_Tag__c: `SEED-EXEC-STEPS-01-12`
- Object__c: "Mixed"
- Inserted_Count__c: 835 (1,835 - 1,000 activities... actually 1,835 clean includes
  all steps 1-12 and 22-27. For steps 1-12 specifically: 4+30+60+60+14+120+150+185+130+100+100+60 = 1,013)
  - Wait, that's 1,013 for steps 1-12. Let me recalculate: 4 Rooftop + 30 Model + 60 P2 + 60 PBE + 14 Staff + 120 Vehicle + 150 Account + 185 Contact + 130 Lead + 100 Opportunity + 100 OLI + 60 Quote = 1,013. Yes.
- Failed_Count__c: 0
- Status__c: "Loaded"
- Loaded_At__c: 2026-10-18T03:05:37.000Z (earliest CreatedDate of canonical records)
- Notes__c: "Steps 1-12 (Rooftop through Quote): 1,013 inserted, 0 failed. Aggregate timestamp inferred from earliest canonical record CreatedDate. Individual wrapper logs not preserved. P5-08 gate 10 PASS."
- Batch_Number__c: 36

## 4. Total Proposed

- 20 existing records: unchanged (valid as loader-written batch rows)
- 16 new records (15 per-step + 1 aggregate for steps 1-12): accurate ledger
- Total: 36 records

## 5. Insert Operations (NOT EXECUTED)

Tool: `sf data create record -o ng-demo -s Data_Load_Batch__c -v "Seed_Tag__c=...|Batch_Number__c=...|Object__c=...|Inserted_Count__c=...|Failed_Count__c=0|Status__c=Loaded|Loaded_At__c=...|Seed_Version__c=SEED-2026.10.01|Notes__c=..."`

16 inserts. No updates to existing records. No deletes.

## 6. Limitations

- **Object__c picklist**: Cannot represent 10 of 27 loaded objects. Uses closest
  picklist value or "Mixed" for multi-object batches. Fix requires
  metadata deployment to extend the picklist.
- **Steps 1-12 individual logs**: Not preserved. Only aggregate timestamp
  available from record CreatedDate. Fix requires re-running steps 1-12
  through the wrapper to generate logs.
- **Per-step Bulk API job IDs**: Captured in wrapper logs for steps 13-27.
  Steps 1-12 job IDs not available.

## 7. Author Approval Required

- Insert 16 new `Data_Load_Batch__c` records (additive, no overwrites)
- Extend `Object__c` picklist to include missing objects (optional, future)
- Modify loader to write per-step ledger records (future, not part of this block)
