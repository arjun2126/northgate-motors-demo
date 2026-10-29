# Phase 2 readiness and Phase 5 continuation — 2026-10-20

**Latest handoff:** `docs/planning/P5_CONSOLIDATED_COMPLETION_2026-10-20.md` supersedes
the historical next-release requests below. Fresh raw checks are in
`evidence/P5/consolidated_completion_checks_2026-10-20.md`.

The initial preparation sections used local work, read-only ng-demo requests and scoped
check-only deployments. Later real releases and data operations are recorded at the end
of this document and in `release_uat_2026-10-20.md`; do not read the initial no-write
statement as applying to those subsequent authorized releases.
All original P5-01…P5-20 requirements and the eight-phase roadmap remain mandatory.

## Owner findings — live duplicate rules

Owner inspected Setup → Duplicate Rules and confirmed:

- Only standard Account, Contact and Lead duplicate rules are active.
- No custom `DR_Contact_Email` exists.
- Standard Contact Duplicate Rule is Active, enforces sharing, and is configured
  Create = Allow / Alert / Report, Edit = Allow / Report.

Because the original `Contact.DR_Contact_Email` source did not exist in the org,
the local source was renamed to a new custom pair that does not touch the standard
rule:

- Matching rule `Contact.NG_Contact_Email_LastName`.
- Duplicate rule `Contact.DR_Contact_Email` referencing it.
- `manifest/p5-duplicate-rule-check.xml` deploys only those two components plus
  the unchanged `MatchingRules` composite.

This keeps the standard rule intact and gives the owner a clean decision point.

## CONFIRMED — focused offline validation

Command: `PYTHONDONTWRITEBYTECODE=1 python3 data/scripts/tests/test_phase5_preparation.py -v`
with NG_TEST_TMP set to the approved temporary directory.

Raw output from the final run:

```text
test_authoritative_ledger_partial_and_unknown_results (__main__.PreparationTest.test_authoritative_ledger_partial_and_unknown_results) ... ok
test_burst_composition_resolution_and_teardown_scope (__main__.PreparationTest.test_burst_composition_resolution_and_teardown_scope) ... ok
test_drift_alarm (__main__.PreparationTest.test_drift_alarm) ... ok
test_full_acceptance_cannot_pass_missing_legacy_or_ledger (__main__.PreparationTest.test_full_acceptance_cannot_pass_missing_legacy_or_ledger) ... ok
test_generator_determinism_without_touching_canonical (__main__.PreparationTest.test_generator_determinism_without_touching_canonical) ... ok
test_ledger_never_labels_updates_as_inserts (__main__.PreparationTest.test_ledger_never_labels_updates_as_inserts) ... ok
test_legacy_exact_parent_map_and_csv_isolation (__main__.PreparationTest.test_legacy_exact_parent_map_and_csv_isolation) ... ok
test_legacy_shape_and_isolation (__main__.PreparationTest.test_legacy_shape_and_isolation) ... ok
test_original_count_conflict_cannot_pass (__main__.PreparationTest.test_original_count_conflict_cannot_pass) ... ok
test_reset_scope_order_and_foreign_records (__main__.PreparationTest.test_reset_scope_order_and_foreign_records) ... ok
test_snapshot_refusals (__main__.PreparationTest.test_snapshot_refusals) ... ok

----------------------------------------------------------------------
Ran 11 tests in 0.858s

OK
```

The generator check compares all 30 files from two isolated same-anchor runs. It checks
12 Scheduled visits before the anchor, 15 vehicles older than 60 days, 12 older than
120 days, unchanged other fields in those two CSVs, and unchanged canonical CSV/version
hashes. These are offline anchor assertions, not live-clock or pricing acceptance.

Other checks cover exact legacy parent maps, create-only output, ledger partial/unknown
results, genuine insert/update classification, mandatory legacy/ledger gate failures,
snapshot refusals, selected child-before-parent ordering and non-burst teardown rejection.
ID checks here validate syntax and uniqueness; they do not prove live dependency safety.
No destructive executor or full external-reference discovery is verified by these tests.

## CONFIRMED — three-component duplicate-rule check-only

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p5-duplicate-rule-check.xml --test-level NoTestRun --wait 30 --json
```

Raw result excerpt:

```json
    "id": "0Afaj00000oRpMeCAK",
    "ignoreWarnings": false,
    "lastModifiedDate": "2026-10-20T21:35:48.000Z",
    "numberComponentErrors": 0,
    "numberComponentsDeployed": 3,
    "numberComponentsTotal": 3,
    "numberFiles": "3",
    "numberTestErrors": 0,
    "numberTestsCompleted": 0,
    "numberTestsTotal": 0,
    "rollbackOnError": true,
    "runTestsEnabled": false,
    "startDate": "2026-10-20T21:35:46.000Z",
    "status": "Succeeded",
    "success": true,
```

`checkOnly: true` is set. Validation scope:

- `Contact.DR_Contact_Email` Created.
- `Contact.NG_Contact_Email_LastName` Created.
- `Contact MatchingRules` Unchanged.

The standard Contact Duplicate Rule is not modified. No live deployment, rule
activation change, or data insert was performed.

## CONFIRMED — five-component check-only

```sh
sf project deploy start --target-org ng-demo --dry-run --manifest manifest/p5-access-sla-check.xml --test-level NoTestRun --wait 30 --json
```

Raw result excerpt:

```json
    "id": "0Afaj00000oSg4LCAS",
    "ignoreWarnings": false,
    "lastModifiedDate": "2026-10-20T17:42:39.000Z",
    "numberComponentErrors": 0,
    "numberComponentsDeployed": 5,
    "numberComponentsTotal": 5,
    "numberFiles": "12",
    "numberTestErrors": 0,
    "numberTestsCompleted": 0,
    "numberTestsTotal": 0,
    "rollbackOnError": true,
    "runTestsEnabled": false,
    "startDate": "2026-10-20T17:42:36.000Z",
    "status": "Succeeded",
    "success": true,
```

The same response has `checkOnly: true`. Validation scope:

- Group `PG_Northgate_Management`, no members, no boss inclusion.
- PermissionSet `PS_Management_Reports`, RunReports only.
- PSG_Manager adds that supplement and retains PS_Sales_Manager.
- DashboardFolder NG_Management grants View only to the dedicated group.
- Service_SLA_Overdue retains start < TODAY and narrows Status to Scheduled.

No object/FLS/sharing permission grants, PS_Sales_Manager replacement, existing rep
PermissionSet deployment, dashboard running-user change or group membership DML is included.
The existing fixed-user dashboards run as admin; group members would see that aggregate
scope. Exact membership and actual deployment require separate owner approval. An empty
group and a check-only result do not establish manager or executive runtime access.

Scoped `xmllint --noout` and `git diff --check` returned no output with exit code 0.
`git diff --cached --stat` returned no output. No Apex tests ran in check-only (NoTestRun).

## CONFIRMED — genuine execution-count reconciliation

```sh
PYTHONDONTWRITEBYTECODE=1 python3 data/scripts/ledger-reconcile.py --output evidence/P5/execution_ledger_2026-10-20.json
```

Raw command output:

```json
{
  "orgId": "00Daj00001Ae3iWEAR",
  "capturedAt": "2026-10-20T17:41:06.588044+00:00",
  "seedVersion": "SEED-2026.10.01",
  "anchorDate": "2026-10-01",
  "loadWindowStart": "2026-10-18T03:00:00",
  "loadWindowEnd": "2026-10-18T06:00:00",
  "jobsReconciled": 37,
  "objectsCovered": 27,
  "distinctCanonicalIdsCovered": 2085,
  "distinctCanonicalInsertIds": 2085,
  "canonicalExpected": 2085,
  "executionCountsReconciled": true,
  "attemptTotals": {
    "processed": 2630,
    "failed": 142,
    "inserted": 2085,
    "updated": 403
  },
  "storageAcceptanceComplete": false,
  "orgLedgerWriteReady": false,
  "timestampSemantics": "systemModstamp is the final recorded job modification, not an invented completion timestamp."
}
```

The JSON file retains all 37 job records with individual counts, canonical ID coverage,
timestamps and metadata/result hashes. Native list pagination uses `records`, not `jobs`.
Every selected job's direct metadata and successfulResults were read. Successful retry IDs
are deduplicated; failed attempts are preserved. No older-org result files were used.

### REFUTED — P5-05 is fully accepted or ready for ledger DML

The raw output above explicitly reports storageAcceptanceComplete=false and
orgLedgerWriteReady=false. Historical per-batch storage remains unknown. Twenty canonical
Mixed placeholders have no evidenced one-to-one mapping to 37 attempts/27 object steps.
No placeholder updates, merged job histories, new ledger rows or SEED-EXEC tags were written.
The native count recovery does not remove the original storage/timestamp/write-model gaps.

## CONFIRMED — local legacy and burst preparation

Read-only parent proposal: `seed98_parents_2026-10-20.json`, mappingReady=true,
ownerApproved=false. It records all six exact Opportunity/Contact IDs, canonical tags,
same-account relationship and observed Prospecting stage. At observation, none of the six
Opportunities had Quote, Trade-In, Financing or Delivery children. New Requested Trade-Ins
would affect future quote eligibility; links still require explicit approval and live recheck.

Raw `legacy-plan` output excerpt:

```json
  "prepared": {
    "Contact": 24,
    "Trade_In__c": 6
  },
  "executed": false,
```

Output: `data/prepared/seed98-mapped-20261020/Contact.csv` and `Trade_In__c.csv`.
The earlier unmapped preparation and original mixed 98-legacy.csv remain preserved.
No bypass grant/revoke or duplicate-rule action has occurred in this continuation.

Raw `burst-plan` output:

```json
{
  "prepared": {
    "Lead": 200,
    "Service_Visit__c": 60,
    "Task": 40
  },
  "executed": false,
  "parentResolutionRequired": true,
  "leadStatusLiveValidationRequired": true
}
```

Raw `resolve-specials` output:

```json
{
  "resolved": {
    "Lead": 200,
    "Service_Visit__c": 60,
    "Task": 40
  },
  "executed": false
}
```

Output directories: `data/prepared/burst-20261020/` and
`data/prepared/burst-resolved-20261020/`, each containing Lead.csv, Service_Visit__c.csv and
Task.csv. Service parents and Task WhoId/WhatId are resolved Salesforce IDs. A read-only
LeadStatus query includes `MasterLabel: Open - Not Contacted`, `IsConverted: false`.
Record-type availability and actual insert/automation behavior are not verified by that query.
Burst teardown remains a strict exact-ID planner. No delete/purge/reload executor or volume/
storage execution evidence exists. P5-17/P5-19 remain incomplete, including the original
ng-dev reset criterion and 3.93 MB burst storage-return criterion.

## REFUTED — the local SLA filter alone establishes the required 12

Read-only query on 2026-10-20:

```sql
SELECT COUNT(Id) n FROM Service_Visit__c
WHERE Seed_Tag__c LIKE 'SEED-%' AND Status__c='Scheduled'
AND Scheduled_Start__c < TODAY
```

Raw result excerpt:

```json
    "records": [
      {
        "attributes": {
          "type": "AggregateResult"
        },
        "n": 13
      }
    ],
    "totalSize": 1,
    "done": true
```

The same TODAY predicate grouped by Status returned Requested 3, Scheduled 13,
No_Show 1, In_Progress 3 and Completed 26. On 2026-10-19 the Scheduled count was 12.
The generator fix produces exactly 12 Scheduled visits before the anchor and starts
remaining Scheduled visits at anchor+20..60 days, so on 2026-10-20 the count is 12.
Canonical CSVs have not been regenerated; the live report still uses TODAY and still
returns 13. Applying acquisition-date changes also needs age-based pricing review.

## REFUTED — several expected data-quality findings with current canonical source

These are read-only org findings against the canonical CSVs as loaded. None are
remediated; they block acceptance until the owner approves fixture changes or
explicitly revises the acceptance criteria.

### Vehicle aging (P5-12)

```sql
SELECT COUNT(Id) n FROM Vehicle__c
WHERE Seed_Tag__c LIKE 'SEED-%' AND Inventory_Age_Days__c > 120
```

Result: `120`.

```sql
SELECT COUNT(Id) n FROM Vehicle__c
WHERE Seed_Tag__c LIKE 'SEED-%' AND Inventory_Age_Days__c BETWEEN 61 AND 120
```

Result: `0`.

Plan expects roughly fifteen vehicles older than 60 days, including twelve older
than 120 days. Canonical `Acquisition_Date__c` values are all in 2024-05, so every
vehicle is >120 days old. The generator fix now produces 12 >120 and 3 in 61-120
at `ANCHOR_DATE=2026-10-01`, but canonical CSVs are unchanged.

### Household duplicates (BAD-01)

Expected: 8 Contact pairs across Accounts with same LastName, MailingStreet and
MailingPostalCode.

Canonical fact: `Contact.MailingStreet` is blank for all 185 seed Contacts. No
`LastName + MailingPostalCode` pair spans two Accounts. Therefore the expected 8
household duplicates cannot be produced without adding/editing contacts or loading
additional `SEED-99-DUP-*` household fixtures.

### Stalled quoting opportunities (BAD-02)

Expected: 6 seed Opportunities in Quoting stage for more than 45 days.

Live query on 2026-10-20:

```sql
SELECT COUNT(Id) n FROM Opportunity
WHERE StageName='Quoting' AND Seed_Tag__c LIKE 'SEED-%' AND CloseDate < 2026-08-17
```

Result: `3`.

```sql
SELECT COUNT(Id) n FROM Opportunity
WHERE StageName='Quoting' AND Seed_Tag__c LIKE 'SEED-%' AND CloseDate < 2026-08-06
```

Result: `1`.

There are 11 seed Quoting opportunities total. To reach 6 stalled more than 45 days
before the anchor, 3 more CloseDates must move to before 2026-08-17. `Stage_Last_Changed__c`
is not populated in the source and CloseDate drives forecast/pricing; any change needs
owner approval.

### Open cases without recent comment (BAD-03)

Expected: 8 open Cases older than 14 days with zero CaseComments.

Live query:

```sql
SELECT COUNT(Id) n FROM Case
WHERE IsClosed=false AND CreatedDate < LAST_N_DAYS:14
```

Result: `3`.

```sql
SELECT COUNT(Id) n FROM CaseComment
```

Result: `0`.

All Cases were inserted on load day, so only cases created before 2026-10-06 qualify.
`CreatedDate` cannot be backdated through standard insert. The requirement cannot be
met without data deletion/reload with a bypass or acceptance of a lower count.

### Revoked consent on active campaigns (BAD-04)

Expected: 6 Contacts with revoked consent who are also CampaignMembers.

Live query:

```sql
SELECT COUNT(Id) n FROM CampaignMember
WHERE ContactId IN (SELECT Contact__c FROM Consent__c WHERE Status__c='Revoked')
```

Result: `28`.

Canonical CSV cross-check: 38 revoked consent rows; 28 distinct revoked Contacts
appear in `CampaignMember.csv`. The first 6 forced revoked Contacts are all on
campaigns, but the random pool also produced additional matches. To hit exactly 6,
the fixture must restrict campaign-member Contacts to the forced revoked set.

## Owner escalation — live Contact duplicate rule

Retrieve `09Saj00000lk3vuEAA` returned top-level Succeeded but the requested component failed:

```text
Entity of type 'DuplicateRule' named 'Contact.DR_Contact_Email' cannot be found
```

Owner later confirmed the standard Contact Duplicate Rule is the only Contact rule.
Local source now provides a new custom rule pair (`Contact.NG_Contact_Email_LastName`
and `Contact.DR_Contact_Email`) that passed 3/3 check-only validation without touching
the standard rule. Affected work stopped on any live rule change or data insert pending
owner decision.

## Active package files

- `data/scripts/generate.ts`: anchor-based vehicle/service date fixes; no canonical rewrite.
- `data/scripts/phase5.py`: exact parent-map preparation, split burst/resolution, scoped
  snapshot/reset/teardown plans, explicit object map and qualified ledger timestamps.
- `data/scripts/ledger-reconcile.py`: native per-job count/result reconciliation.
- `data/scripts/tests/test_phase5_preparation.py`: 11 focused offline checks.
- `force-app/main/default/groups/PG_Northgate_Management.group-meta.xml`.
- `force-app/main/default/permissionsets/PS_Management_Reports.permissionset-meta.xml`.
- `force-app/main/default/permissionsetgroups/PSG_Manager.permissionsetgroup-meta.xml`.
- `force-app/main/default/dashboards/NG_Management.dashboardFolder-meta.xml`.
- `force-app/main/default/reports/NG_04_Service/Service_SLA_Overdue.report-meta.xml`.
- `manifest/p5-access-sla-check.xml`.
- `manifest/p5-duplicate-rule-check.xml`.
- `force-app/main/default/matchingRules/Contact.matchingRule-meta.xml`.
- `force-app/main/default/duplicateRules/Contact.DR_Contact_Email.duplicateRule-meta.xml`.
- `docs/DATA_QUALITY.md` and `docs/planning/P2_P5_IMPLEMENTATION_2026-10-20.md`.
- `docs/planning/P2_BROWSER_UAT_PROCEDURE_2026-10-20.md`: prepared owner browser procedure.
- `BUILD_STATUS.md`, this report, the two new evidence JSON files and the eight new
  prepared CSVs listed above. Unrelated pre-existing working-tree changes remain preserved.

## Live seed vs non-seed object counts

These counts were taken on 2026-10-20 for storage and scope context. They include
both canonical seed records and non-seed records already present in the org.

| Object | Seed count | Non-seed count | Notes |
|--------|-----------:|---------------:|-------|
| Account | 153 | 14 | — |
| Contact | 186 | 23 | — |
| Lead | 130 | 22 | 130 seed loaded; 22 non-seed remain |
| Opportunity | 103 | 33 | 19 non-seed Closed Won, financing gaps below |
| Vehicle__c | 120 | 0 | all >120 days old |
| Vehicle_Model__c | 30 | 0 | — |
| Product2 | 60 | 0 | — |
| Quote | 60 | 5 | — |
| QuoteLineItem | 80 | 5 | — |
| Trade_In__c | 45 | 1 | — |
| Test_Drive__c | 70 | 1 | — |
| Financing__c | 60 | 2 | both non-seed have null Rate/Term |
| Delivery__c | 13 | 1 | — |
| Service_Visit__c | 140 | 0 | 13 overdue Scheduled vs required 12 |
| Case | 34 | 26 | only 3 open >14 days |
| CaseComment | 0 | 0 | — |
| Campaign | 5 | 4 | — |
| CampaignMember | 60 | 0 | 28 revoked-consent matches vs required 6 |
| Task | 200 | 1 | — |
| Event | 50 | 0 | — |
| Loyalty_Member__c | 78 | 2 | — |
| Loyalty_Transaction__c | 110 | 0 | — |
| Consent__c | 85 | 0 | — |
| Data_Load_Batch__c | 20 | 0 | 20 placeholders, no per-batch storage evidence |

Owner-provided Storage Usage: 4.1 MB data of 5.0 MB limit (81%), 17 KB file storage.

## Consolidated next-release approval request

The full P5-01…20 implementation/evidence matrix is maintained in
`docs/planning/P2_P5_IMPLEMENTATION_2026-10-20.md`. No local test substitutes for browser,
persona, data, storage, idempotency, drift-delete or reset/burst execution evidence.

Please approve or reject each item explicitly. I will not deploy, load, modify org data,
change persona/bypass, or start browser UAT without your written go-ahead on the exact item.

1. **Contact duplicate rule:** deploy the validated 3-component custom rule
   (`Contact.DR_Contact_Email` + `Contact.NG_Contact_Email_LastName`), leaving the
   standard rule unchanged. If you prefer to rely on the standard rule only, confirm
   that and I will drop the custom rule work.
2. **Management access package:** deploy the 5-component check-only package and tell
   me the exact users to add to `PG_Northgate_Management`. I will not add membership
   without a named list.
3. **Dated fixture corrections:** regenerate canonical CSVs from the fixed generator
   (Service SLA = 12 at anchor, vehicle ages 12 >120 + 3 61-120, quoting dates). This
   affects forecasts/pricing; confirm you accept the impact before I regenerate.
4. **BAD-01 household duplicates:** choose one:
   - add `MailingStreet` to selected canonical Contacts, or
   - load extra `SEED-99-DUP-*` household fixtures, or
   - accept fewer than 8 duplicate pairs and adjust the acceptance criterion.
5. **BAD-02 stalled quoting:** choose using `CloseDate` (need 3 more CloseDate changes)
   or use `Stage_Last_Changed__c` if verified populated; otherwise adjust criterion.
6. **BAD-03 open cases:** accept that `CreatedDate` cannot be backdated through
   standard insert. Choose deletion/reload with bypass, or accept a lower count.
7. **BAD-04 revoked consent on campaigns:** restrict campaign-member revoked Contacts
   to the forced 6, or accept 28 and revise criterion.
8. **SEED-98 load:** approve the 6-parent map in `seed98_parents_2026-10-20.json`,
   bypass/restoration sequence, and duplicate-rule behavior check. I will recheck parent
   state immediately before insert.
9. **Burst/reset operations:** approve the prepared burst/resolution CSVs and teardown
   scope, or tell me to discard them.
10. **Ledger write model:** approve the honest per-batch model (37 jobs mapped to 27
    objects, 20 placeholder batches left as-is) and the acceptance that historical
    per-batch storage is unavailable.
11. **Phase 2 browser UAT:** start the window and follow
    `docs/planning/P2_BROWSER_UAT_PROCEDURE_2026-10-20.md`. I will not rerun
    `p2_setup.apex` or disable its bypass guard.
12. **Storage acceptance:** provide an exact Storage Usage screenshot showing ≤4.0 MB
    data before any further load, or confirm 4.1 MB/5.0 MB is acceptable.

Skipped until approved: full live release gate, second data load, drift deletion,
metadata deployment, group membership/persona changes, browser UAT, dashboard refresh,
SEED-98/burst loads and all destructive operations. Phase 5 is not accepted or complete.

## Scoped preflight results 2026-10-20

Metadata-only changes prepared and check-only validated:

- BAD-02 report filter: `Opportunity.Days_In_Stage__c > 45`.
  Manifest: `manifest/p5-bad02-report-check.xml`.
  Validation: `0Afaj00000oUM37CAG` succeeded (1 component).
- BAD-03 operational report preserved + simulated-aging demonstration:
  `Ignored_Cases` retains original filter `LAST_UPDATE < LAST_N_DAYS:14`.
  Added `Case.Backdated_Opened_Date__c` (Date) and `Case.Days_Since_Last_Update__c` (Number formula).
  Added separate report `Ignored_Cases_Simulated_Aging` using `Case.Days_Since_Last_Update__c > 14`.
  Manifest: `manifest/p5-scoped-release.xml`.
  Validation: `0Afaj00000oUWdZCAW` succeeded (6 components, 173 tests passed).
- BAD-04 custom report type + fixture-specific report:
  `ContactWithCampaignMembers` report type,
  `Revoked_Consent_Campaign_Members` report filtering on the six canonical `Seed_Tag__c` values.
  Manifest: `manifest/p5-bad04-report-check.xml`.
  Validation: `0Afaj00000oUPDtCAO` succeeded (2 components).

LastModifiedDate audit-field support: **not available**.
Org setting `SecuritySettings.IsAuditFieldsInactiveOwnerEnabled` = `false`.
Therefore BAD-03 operational report keeps true last-update semantics; fixtures are demonstrated in the clearly labeled simulated-aging report.

Management UAT permission requirements verified:

- `NG_Sales` profile lacks `RunReports`.
- `PS_Management_Reports` (`0PSaj00000gUOW9GAO`) grants `RunReports`.
- `Northgate Persona` (`005aj00000gE0b3AAC`) already in `PG_All_Sales` (`00Gaj00000ZYYhUEAX`).
- `NG_Management` dashboard folder shared to `PG_Northgate_Management` (`00Gaj00000ZkluDEAR`).
- Temporary UAT setup: add user to `PG_Northgate_Management` and assign `PS_Management_Reports`; remove after session.

Disposable project-owned temporary records identified:

- 4 Accounts tagged `UAT-2026-10-19-*`, `UAT-2026-10-20-VP-12PCT`, `UAT-2026-10-20-REP-QUOTE`, `UAT-2026-10-19-FIN-EXCEPTION`.
- 4 Contacts: `UAT Buyer`, `VP UAT Buyer`, `FIN UAT Buyer`, `REP UAT Buyer`.
- 4 Opportunities linked to those accounts.
- 5 Quotes + 5 QuoteLineItems, 1 Trade_In__c, 1 Test_Drive__c, 1 Task, 2 FeedItems.
- Total ~21 primary records plus child records.
- Estimated storage impact: ~0.04 MB. Deleting them will **not** bring org usage below 4.0 MB.
- No broader cleanup is proposed.

## Scoped release execution 2026-10-20

Authorized operations completed in `ng-demo`:

- Metadata deployment: `0Afaj00000oTmEACA0` succeeded (6 components, 173 tests passed).
- Additional field-access permission set deployment: `0Afaj00000oUgbJCAS` (`PS_Case_Data_Quality_Fields`) assigned to admin user `005aj00000feqbNAAQ` as `0Paaj000016wctoCAA`.
- BAD-02 updates: 6 Opportunities updated via REST; all show `Stage_Last_Changed__c = 2026-08-01T00:00:00Z` and `Days_In_Stage__c = 81`.
- BAD-03 inserts: 8 Cases created via REST with `Seed_Tag__c = BAD-03-001..008`, `Backdated_Opened_Date__c = 2026-08-01`, `Days_Since_Last_Update__c = 80`.
- Operational `Ignored_Cases` report unchanged; live count remains 3 open cases with no update in last 14 days.
- Simulated-aging report count: 11 open cases with `Days_Since_Last_Update__c > 14` (8 fixtures + 3 pre-existing aged cases).
- Management UAT temporary assignments **not** created; deferred to separate browser-UAT step.

## Consolidated completion handoff — after the scoped release

The current investigation made only read-only ng-demo requests and local planning changes.
No deployment, check-only, Apex test execution, Salesforce DML, permission/persona change,
bypass, reset, deletion, staging, commit or push occurred.

Current matrix and coordinated authorization/dependency plan:
`docs/planning/P5_CONSOLIDATED_COMPLETION_2026-10-20.md` (all 20 original items;
15 PARTIAL, 5 BLOCKED). Raw evidence:
`consolidated_completion_checks_2026-10-20.md`.

Important corrections to earlier completion assumptions:

- Existing deployment statuses were re-read, not repeated: six-component scoped deployment
  `0Afaj00000oTmEACA0` and extra field-access deployment `0Afaj00000oUgbJCAS` both succeeded
  with 173 tests and zero errors. The extra admin grant remains an explicit scope-review item.
- Six stage-aged Opportunities are correct, but the actual stalled-Quoting report returns
  zero because its implicit CloseDate filter is THIS_FISCAL_QUARTER. Prepare one report-only
  all-date correction; do not change CloseDate or repeat the six data updates.
- Service SLA report=13. Additional clock-crossing row is `SEED-18-040`,
  `a08aj00001Snsk0AAB`, scheduled 2026-10-19T00:00Z. The TODAY predicate is correct.
- Operational Ignored_Cases=3; separate simulation=11. Waiting for the eight new fixtures
  does not guarantee a whole-org count of eight. Preserve operational semantics/history.
- Original BAD-02 is stale Leads (currently 0/35); original BAD-08 is stalled Opportunities.
  Original BAD-04 is overdue Visits; original BAD-07 is revoked campaign consent. Earlier
  conversational aliases must not cause an original scenario to disappear from acceptance.
- Canonical loyalty query confirms 39/18/9/4; report includes 72 total members. Inventory
  >120=120, stacked-rule canonical Quotes=0, negative-equity Trade-Ins=8. No_Show=12 is not
  a verified six-row no-follow-up subset. CSI remains empty.
- `data/csv/` is absent; resolved files remain. Do not regenerate canonical files or execute
  snapshot/count/reset/reload helpers that assume this directory. Obtain trusted originals.
- New local BAD-01 candidate: `data/prepared/bad01-households-20261020.csv`, 16 Contacts / 8
  pairs on 16 confirmed existing Accounts. No Salesforce inserts. Legacy 24/6 preparation
  and six-parent map remain proposals. >=92 KB additional storage plus side effects is needed.
- No permitted sufficient storage reduction is evidenced; preserve the <=4.0 MB gate.
  Historical per-batch storage/true completion times and the 37-job/20-placeholder model
  remain P5-05 blockers. No made-up ledger rows or retrospective storage measurements.
- Persona remains VP_Sales/NG_Sales/ManagerId null, two original permission assignments,
  PG_All_Sales membership. No management temporary grants exist. Admin field-access grant
  `0Paaj000016wctoCAA` still exists; no removal is authorized.
- Fresh duplicate-rule and finance aggregate queries failed on schema/query errors; those
  checks stopped without retries. Exact errors and manual Setup/report actions are in raw
  evidence. No inference of fresh verification is made from the failed checks.
- Phase 2 browser UAT remains unsigned and scheduled separately. Preserve the owner's prior
  lifecycle walkthrough acceptance; cosmetic UI modernization is not part of Phase 5.

### CONFIRMED — local completion-plan validation

Raw output from focused CSV/matrix/source-preservation assertions:

```text
PASS: BAD-01 candidate has 16 unique tags, 16 distinct Account IDs, 8 surname/street/postal pairs and 8 within-pair duplicate emails.
PASS: Matrix covers P5-01 through P5-20 exactly once: 15 PARTIAL, 5 BLOCKED.
PASS: Missing canonical source remains unmodified; operational Ignored_Cases retains LAST_UPDATE.
PASS: Local planning, evidence and fixture files have final newlines and no trailing whitespace or NUL bytes.
```

Scoped `git diff --check` returned no output (exit 0). `git diff --cached --name-only`
returned no output. This session's local changes are the consolidated plan, raw evidence,
candidate BAD-01 CSV, this continuation, and current-handoff pointers in BUILD_STATUS.md
and docs/DATA_QUALITY.md. Pre-existing working-tree changes remain preserved.

Skipped: new deployments/check-only, Apex suites, full gate runs, source regeneration,
Salesforce DML, persona/access changes, bypass and all destructive execution. No original
acceptance gap is converted to PASS by this documentation or by the historical 173-test run.

## Batch 1 execution — Stalled_Quoting_Opportunities date filter

Owner authorized Batch 1 only: correct the report's date restriction, preserving all six
Opportunity records, their `CloseDate` and `Stage_Last_Changed__c` values, and the
`Quoting` and `Days_In_Stage__c > 45` criteria.

Diagnosis: the report had no `timeFrameFilter`, so it inherited the Opportunity report
type's default `THIS_FISCAL_QUARTER` Close Date range, which excluded the six qualifying
Opportunities whose CloseDates fall in July-September 2026. Sibling Opportunity reports in
source (`Pipeline_by_Stage`, `Open_Opps_by_Sales_Staff`) already use an explicit
`timeFrameFilter` with `CLOSE_DATE` + `INTERVAL_CUSTOM` and no date bounds.

Change: added to
`force-app/main/default/reports/NG_05_DataQuality/Stalled_Quoting_Opportunities.report-meta.xml`

```xml
    <timeFrameFilter>
        <dateColumn>CLOSE_DATE</dateColumn>
        <interval>INTERVAL_CUSTOM</interval>
    </timeFrameFilter>
```

No Opportunity, CloseDate, `Stage_Last_Changed__c`, permission, pricing, seed or other
metadata was touched. Manifest: `manifest/p5-bad08-report-check.xml` (one Report member).

- Check-only: `0Afaj00000oUyI5CAK` succeeded, 1/1 component, 173 tests, 0 errors.
- Deployment: `0Afaj00000oUOg2CAG` succeeded, 1/1 component, 173 tests, 0 errors.

Deployed report GET (`00Oaj00000UjuL5EAJ`):

```json
{"reportFilters":[{"column":"STAGE_NAME","operator":"equals","value":"Quoting"},{"column":"Opportunity.Days_In_Stage__c","operator":"greaterThan","value":"45.0"}],"standardDateFilter":{"column":"CLOSE_DATE","durationValue":"CUSTOM","endDate":null,"startDate":null},"scope":"organization","rowCount":6,"aggregates":[{"label":"6","value":6}]}
```

Report row record ids, in order: `006aj00000fUItQAAW`, `006aj00000fUItRAAW`,
`006aj00000fUItSAAW`, `006aj00000fUItTAAW`, `006aj00000fUItUAAW`, `006aj00000fUItVAAW`.
Direct SOQL `StageName='Quoting' AND Days_In_Stage__c > 45` returned the same six ids with
the same CloseDate values (2026-08-10, 2026-08-16, 2026-09-21, 2026-08-28, 2026-09-11,
2026-07-29) and `Stage_Last_Changed__c = 2026-08-01T00:00:00Z`, `Days_In_Stage__c = 81`.
Report count 6 equals SOQL count 6; id sets match exactly.

`UserRecordAccess` probe for Northgate Persona `005aj00000gE0b3AAC` returned
`read=False edit=False delete=False` for Opportunity, Vehicle__c, Service_Visit__c,
Loyalty_Member__c, Staff__c, Case, Quote and Financing__c **on admin-owned records only**.
A later, corrected probe established that the persona **owns all 100 canonical
Opportunities** (plus 1 UAT Opportunity, 200 Tasks, 50 Events, 1 Account, 1 Contact, 1 Quote)
and reads them with `read=True edit=True`, and that 104 `AccountShare` rows
(`RowCause=ImplicitParent`) give it Account read. The earlier "no record-level access"
conclusion was wrong; see `evidence/P5/consolidated_completion_checks_2026-10-20.md` and
`docs/planning/P5_BATCH2_ACCESS_RESOLUTION_2026-10-20.md`. Persona pipeline scope is
78 rows / 4,328,120 versus admin 113 / 10,587,766, which is exactly the P5-14 scope
difference.

New finding: all 100 canonical Opportunities have `Sales_Staff__c = null`, and the
`Open_Opps_by_Sales_Staff` filter does not exclude nulls, so its tile is not a distinct staff
metric. Open P5-15 acceptance risk; no fix applied.

Management UAT temporary grants still **not** created. Batch 2a (two existing purpose-built
grants only) is prepared in `docs/planning/P5_BATCH2_ACCESS_RESOLUTION_2026-10-20.md` and
awaits owner approval. Batch 2b (read-only permission set for public-OWD objects) and Batch 2c
(narrow `Service_Visit__c` sharing rule) remain unapproved options. The earlier draft
`docs/planning/P5_BATCH2_MANAGEMENT_UAT_2026-10-20.md` contains the superseded
"no record-level access" premise and must not be executed as written.

## Accelerated execution 2026-10-20 — root causes and local fixes

Read-only investigation + local code/report fixes. No deploy/DML/commit.

Root causes (all traced to a stale canonical load + loader/generator bugs):

- `resolve.ts` dropped 3 relationship columns (Opportunity.Sales_Staff__c 100, Account.Preferred_Rooftop__c 150, Quote.Buyer_Contact__c 60) because `X__r.Seed_Tag__c` resolved against the field name, not the target object. Fixed with `CUSTOM_LOOKUP_TARGETS` + tests t19/t20. `resolve.test.ts` = 20 PASS.
- `makeStaff` wrote a rooftop NAME into `Rooftop__r.Seed_Tag__c` (14 Staff null). Fixed to seed tag.
- `makeOpportunities` attributed Sales_Staff__c to any staff role; fixed to Sales_Rep/Sales_Manager.
- `makeServiceVisits` never set Rooftop__c; fixed (from vehicle rooftop).
- Reports `Aged_Inventory`/`Revoked_Consents` defaulted date to THIS_FISCAL_QUARTER (0 rows); `Open_Opps_by_Sales_Staff` used literal 'Blank'. All three fixed; check-only `0Afaj00000oVYrpCAG` 3/3 clean.

Regenerated-to-temp proof: 12 aged>120, 3 in 61-120, 105 ≤60; 12 overdue visits; staff rooftop 14;
Sales_Staff sales-role only — all matching plan, confirming live data is stale, not the generator.

Prepared (not executed) approval-gated backfills in data/prepared/: staff/account/opportunity/
servicevisit rooftop+staff, quote buyer, vehicle acquisition (120), service visit schedule (140).

Blocked: storage 4.1MB (only ~24 disposable UAT records ≈48KB; 167 pre-existing org sample records
≈334KB are the only sizeable lever, owner decision); missing data/csv/; P5-05 historical storage;
BAD-02 (LastActivityDate/CreatedDate not writable); BAD-09 (needs CP2 pricing); BAD-10 (+6 activities
vs gate ±2); P5-14 two-persona (persona has no read on Vehicle/Service_Visit/Loyalty).

Full package: docs/planning/P5_ACCELERATED_RELEASE_2026-10-20.md.

## Batch A execution 2026-10-20 (owner-approved)

Deployment: `0Afaj00000oVd9xCAC`, 3/3 report fixes, 173 tests, 0 errors, checkOnly=false.

Preflight (all verified read-only):
- 5 relationship CSVs: exact Id counts (14/150/100/140/60), unique Ids, object-prefix match,
  100% live overlap, no empty values, correct target prefixes. Snapshot before-values captured
  in `evidence/P5/backfill_snapshot_before_2026-10-20.json` (all fields null pre-backfill).
- Automation: QuoteTrigger is before-insert only (no update trigger). OpportunityTrigger is
  before-insert/update but OpportunityStageStamp only writes when StageName changes.
  Service_Visit VR_ServiceVisit_FutureForNew gates on Status+Scheduled_Start (admin has
  Bypass_Automation via PS_Demo_Admin, so no trip). No flows/VRs reference the backfilled fields.

Executed relationship backfills (bulk update, --line-ending CRLF):

| Object field | Rows | Job ID |
|---|---|---|
| Staff__c.Rooftop__c | 14 | 750aj00001IKepfAAD |
| Account.Preferred_Rooftop__c | 150 | 750aj00001IKoSPAA1 |
| Opportunity.Sales_Staff__c | 100 | 750aj00001IKeCxAAL |
| Service_Visit__c.Rooftop__c | 140 | 750aj00001IKoU1AAL |
| Quote.Buyer_Contact__c | 60 | 750aj00001IKX2hAAH |

After verification: all five fields 0 null. Opportunity staff = 80 Sales_Rep + 20 Sales_Manager.
Quote pricing unchanged (Adjusted_Subtotal__c null 60, Rule_Applied_Count__c=1 60 — no CP2 recalc).
6 backfilled quoting opps Stage_Last_Changed__c still 2026-08-01. Storage unchanged (5/1).

Reports: Aged_Inventory 0→120; Revoked_Consents 0→38; Open_Opps_by_Sales_Staff now 65 open
opps / $3,585,146 grouped 5 sales staff (13/13/13/13/13), excluding 17 unattributed open opps;
Stalled_Quoting_Opportunities 6 (unchanged); Service_SLA_Overdue 13 with rooftop grouping now
populated.

Deferred (owner requires explicit automation review before execution):
- backfill-vehicle-acquisition.csv (120): changes Inventory_Age_Days__c formula → future CP2
  aged-inventory discount changes; VehicleTrigger re-runs VIN validation + VehicleCounterTrigger
  re-maintains rooftop counters on every update.
- backfill-servicevisit-schedule.csv (140): sets 12 visits to Scheduled-in-past → would trip
  VR_ServiceVisit_FutureForNew for non-bypass users; moves SLA count 13→12.
