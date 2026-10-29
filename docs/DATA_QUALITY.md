# Northgate data quality fixtures and acceptance

**Current handoff:** `docs/planning/P5_CONSOLIDATED_COMPLETION_2026-10-20.md` supersedes
the historical preparation/deployment assumptions below. Eight BAD-03 Cases and the separate
simulation report are deployed; the operational Ignored_Cases report retains LastModifiedDate
semantics. BAD-01/SEED-98 remain unloaded. `data/csv/` is currently absent, so do not run
helpers requiring those artifacts until trusted originals are restored. The installed bulk
insert command is `sf data import bulk`, not the obsolete `sf data create bulk` examples below.

All original P5-01 through P5-20 requirements remain mandatory. These procedures do not
authorize Salesforce writes. Preserve the 2,085 existing canonical records and every UAT
and historical record. No fixture has been inserted by the current implementation work.

## Canonical and legacy boundary

`python3 data/scripts/phase5.py counts` reconciles the CSVs without changing them. Current
canonical total is 2,085. Governing 2026-10-20 allocation is 60 Product2 + 12 Delivery:
1,835 clean + 30 legacy + 250 activities = 2,115. Historical 2,123 total is preserved as the
pre-revision figure; the eight-record difference was Product2 40→60 (+20) and Delivery 40→12
(−28), not an unidentified object allocation. Do not add dummy records or silently reduce
requirements. No fixture has been loaded under this allocation decision.

## SEED-98 — mandatory, intentionally malformed

Resolve candidate parents read-only, then generate a new, isolated preparation directory:

```sh
python3 data/scripts/phase5.py legacy-parents --output <new-parent-map.json>
python3 data/scripts/phase5.py legacy-plan --parent-map <new-parent-map.json> --output <new-directory>
```

Output is 24 Contact and 6 Trade-In rows, not Account defects:

| Tag prefix | Rows | Intentional defect |
|---|---:|---|
| SEED-98-PHONE | 10 | Short/malformed phone |
| SEED-98-POSTAL | 8 | Missing MailingPostalCode |
| SEED-98-VIN | 6 | 16-character Trade_VIN__c containing O |
| SEED-98-EMAIL | 6 | Three case-insensitive email pairs |

Names are fictional and email domains end in `.test`. `legacy-plan` never changes canonical
CSV files. The map must contain exactly six resolved Opportunity/Contact ID pairs. Current
read-only proposal is `evidence/P5/seed98_parents_2026-10-20.json`; prepared files are in
`data/prepared/seed98-mapped-20261020/`. The earlier `seed98-20261020` files lack parents
and are not load-ready. The six proposed Opportunities are Prospecting, have same-account
Contacts and had no Quote, Trade-In, Financing or Delivery at observation. Owner approval
is still false. New Requested Trade-Ins would block future quotes until Accepted; approve
these exact links and recheck their state immediately before any authorized insert.

These are intentional data-quality defects within writable field types, not proof that
Salesforce rejects the values. Retrieved Contact metadata contains no validation rules;
the live Trade-In equity rule applies only to Accepted status. Required Opportunity lookup
cannot be bypassed. The mandatory logged bypass/restoration requirement remains intact.

**Duplicate-rule verification is blocked.** Retrieve `09Saj00000lk3vuEAA` returned this
component error, despite top-level `Succeeded`:

```text
Entity of type 'DuplicateRule' named 'Contact.DR_Contact_Email' cannot be found
```

Local Allow/Alert metadata is not live evidence. Stop this line of investigation until the
owner opens Setup → Duplicate Rules, filters Contact and confirms the actual rule API name,
active state, create/edit actions and matching rule. No duplicate-rule correction or retry
was attempted. Do not load the duplicate-email fixtures based on the local rule alone.

### Exact authorized-data procedure (NOT EXECUTED)

1. Obtain separate approval for 24 Contact inserts, 6 Trade-In inserts, exact parent map,
   bypass grant/revoke, and duplicate-rule options. Verify zero pre-existing SEED-98 tags.
2. Capture current org ID, exact Storage Usage, current permission assignments and all
   Automation_Settings__c bypass flags. Stop if remaining storage cannot fit the batch.
3. Use the established loader wrapper's snapshot/restoration behavior. Grant PS_Bypass_Load
   only if absent, only for this approved window; record the new assignment ID. Duplicate
   rules may ignore custom bypass permissions;
   verify their exact behavior before creating the six email fixtures. Do not deactivate
   validation or duplicate rules without separate approval.
4. Recheck the approved resolved parent IDs in the isolated Trade_In__c.csv. Do not overwrite
   canonical CSVs. Submit Contact and Trade-In inserts separately with `sf data create bulk`,
   `--target-org ng-demo`, matching `--sobject` and `--file`, and `--wait 10`.
5. Capture each native Bulk API job's metadata, successful and failed result files; verify
   JobComplete and 24/24 + 6/6. Reconcile inserted versus updated with sf__Created evidence.
   Stop on any failure; do not repeat insert blindly.
6. In a guaranteed cleanup step, revoke only the newly created temporary grant and restore captured
   flags exactly. Verify restoration even when a load fails. Preserve pre-existing grants.
7. Verify actual phone/postal/VIN/email defects and exact 10/8/6/6 tag boundary, then run
   the two object-correct SEED98 reports. Save `evidence/P5/seed98.png`.
8. Capture post-load Storage Usage and each job's real completion/count evidence. Do not
   create the old proposed 16 placeholder-replacement ledger rows.

## Execution ledger

```sh
python3 data/scripts/ledger-reconcile.py --output <new-execution-ledger.json>
```

This read-only command paginates native ingest jobs, retrieves each job's final metadata
and successfulResults CSV, validates processed = successful + failed, and uses sf__Created
to distinguish inserts from updates. It deduplicates canonical IDs across retries rather
than counting every upsert as another loaded record. Missing evidence stays null.

`evidence/P5/execution_ledger_2026-10-20.json` contains the observed 37 jobs across all
27 canonical objects: 2,630 attempted records = 2,085 inserts + 403 updates + 142 failures.
Successful retries cover all 2,085 distinct canonical IDs, including insert evidence for
each. JobComplete alone does not mean zero failed rows. The file preserves individual job
counts, IDs, timestamps and response hashes. It does not write Salesforce ledger records.

`systemModstamp` is labelled `jobFinalModifiedAt`, not an invented completion timestamp.
`phase5.py recover-job` additionally requires a genuine timestamped storage reading; missing
historical readings block ledger acceptance. Today's /limits cannot reconstruct per-batch
storage. The 20 existing ledger placeholders remain unchanged and have no evidenced
one-to-one mapping to 37 attempts. P5-05 stays open until original per-batch fields and an
exact write model are approved. Do not add SEED-EXEC rows or arbitrarily merge job histories
to force the 20-row envelope.

## Verification and drift

```sh
bash scripts/verify.sh --storage-mb <exact-owner-reading> --storage-evidence evidence/P5/storage.png
python3 data/scripts/phase5.py integrity
python3 data/scripts/phase5.py findings
```

All commands above are read-only. Strict release verification requires legacy records,
genuine ledger evidence and original total; missing requirements cannot return PASS merely
because canonical-only checks pass. `findings` asserts original expected counts; its tests
prove 12 passes and 11 fails for a 12-row expectation. Live delete-one-row drift evidence
still requires a separately approved, reversible fixture exercise; no canonical deletion
is authorized. API/report run and browser evidence are separate from local parser tests.

## Reset, snapshot and burst safeguards

`phase5.py snapshot --output <new-file.json>` exports canonical/special SEED records and
manifest hashes read-only, after verifying ng-demo identity. A snapshot plan older than one
hour, future-dated, wrong-org or incomplete is refused. `scripts/reset.sh --snapshot <file>`
prints an exact-ID child-first plan only. It rejects invalid/duplicate IDs, tags outside
the canonical manifest, unrelated OLI parents and declared external dependents. It cannot
delete, purge or reload. Snapshot export does not automatically inventory every external
reference; absence of an externalReferences entry is not evidence that deletion is safe.

The destructive executor for P5-17 remains **not implemented/accepted**; its requirements
are retained. Before executing a future reset: approve exact IDs, verify no historical/UAT
child references or pending approvals would be damaged, delete child-first, purge only those
IDs (never org-wide Recycle Bin), reload under restored bypass controls, reconcile records,
and prove storage <=4.0 MB. P5-17's original ng-dev execution evidence is blocked by current
ng-demo-only boundary; do not substitute a different org without an owner decision.

P5-19 burst likewise remains mandatory, not executed or accepted. The original `77-burst.csv`
projects mixed Lead/Service Visit/Task rows onto a Lead-only header; do not load it. Use:

```sh
python3 data/scripts/phase5.py burst-plan --output <new-burst-directory>
python3 data/scripts/phase5.py resolve-specials --directory <new-burst-directory> --output <new-resolved-directory>
```

Current local preparations are `data/prepared/burst-20261020/` and
`data/prepared/burst-resolved-20261020/`: 200 Leads, 60 Service Visits and 40 Tasks, with
per-object schemas and live-resolved parent IDs. The initial LeadStatus label
`Open - Not Contacted` exists live; record-type availability and all insert/automation
behavior still require preflight. Prepared future times must be regenerated for a later
window, not reused after they expire.

`burst_teardown(records)` accepts only the three expected objects, matching SEED-77-BURST
prefixes and syntactically valid unique IDs. It returns an exact-ID Task/Service Visit/Lead delete and
purge plan, not an executor. Before future execution, approve IDs, snapshot, check external
dependencies/cascades and pending approvals, approve the exact insert/delete/purge manifests,
capture volume/storage screenshots, then verify zero burst tags and the original storage
return criterion of 3.93 MB. No teardown, purge or reload entry point is implemented. Local preparation
does not satisfy P5-17/P5-19 execution acceptance.

## Clock-dependent fixture corrections — not applied to the org

The isolated generator now produces 12 past Scheduled visits at its supplied anchor,
15 vehicles older than 60 days and 12 older than 120 days. Regression checks retain every
other field in the affected CSVs and preserve canonical CSV/version hashes. These checks
do not prove the same counts against today's clock, nor authorize canonical regeneration.

The SLA metadata proposal retains start < TODAY and narrows Status to Scheduled. Live
read-only evidence on 2026-10-20 gives 13, not the required 12. The previous broader filter
also includes Requested, In_Progress and No_Show. No fixed anchor, selected tags or altered
expected count substitutes for the original criterion. Applying vehicle acquisition changes
can affect age-based CP2 pricing; any exact data correction needs approval and impact checks.
