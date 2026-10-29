# Pre-Phase-5 Readiness — 2026-10-20

## Decision

**No new Phase 5 initial load is required.** The canonical Phase 5 seed is already present
in `ng-demo` and the release gates pass. A re-load, reset, or burst load is **not**
authorized by this document.

**Phase 5 acceptance is not fully closed:** the `SEED-98` legacy batch is deferred, and the
P5-03/P5-05 evidence screenshots are missing. Those are closeout gaps, not reasons to run a
new canonical load.

## Verified state

| Item | Result | Evidence |
|---|---|---|
| Org | `ng-demo`, `00Daj00001Ae3iWEAR` | live CLI |
| Persona user | `ngpersona`, `005aj00000gE0b3AAC`, active, profile `NG_Sales` | live query |
| Persona baseline | `VP_Sales`, `ManagerId` null, no persona PSGs | live query |
| Finance UAT | PASS; exception flag true, decision `2026-10-20`, Quote unchanged | `evidence/UAT/live_2026-10-19/finance_uat_completed_2026-10-20.md` |
| Pending Finance approvals | 0 | `FIN_PRE_RESTORE_GUARD` |
| Persona state | restored to baseline `VP_Sales`, `NG_Sales`, `ManagerId=null`, no persona PSGs | `scripts/persona.sh restore`; post-restore live queries |
| Standard Price Book | active `01saj00000NvczOAAR` | live query |
| Canonical seed | 2,085 records loaded; 20 ledger rows all `Loaded`, but all have `Inserted_Count__c=0`, `Failed_Count__c=0`, and `Object__c=Mixed` | `data/SEED_VERSION.txt`; live query; `evidence/P5/ledger_design_additive.md` |
| Release gates | 14 PASS, 0 FAIL | `evidence/P5/verify_gates.txt` |
| Storage | `DataStorageMB` Max 5, Remaining 1; verify record reports 3.00 MB | live limits API; `verify_gates.txt` |
| Full Apex suite | 189/189 pass, 0 failures, 85% org-wide | `evidence/FINAL/full_suite` `707aj00001MTeI1` |
| `P3-DEF-01` | deployed; check-only 14/14; focused run 15/15 | check-only `0Afaj00000oNfTyCAK`; deploy `0Afaj00000oON8LCAW`; test run `707aj00001McoRy` |
| Rep UAT | owner browser checks passed; dashboard metric accuracy unverified | `evidence/UAT/live_2026-10-19/REP_UAT_COMPLETED_2026-10-20.md` |
| List-view fixes | deployed only `Delivery__c.All` and `Loyalty_Member__c.All`; verified `filterScope=Everything` | check-only `0Afaj00000oOKNNCA4`; deploy `0Afaj00000oOKSDCA4`; retrieve `09Saj00000lhh0DEAQ` |
| Delivery tab | owner screenshot confirms visible in Northgate Sales; no PermissionSet deploy made | owner UAT attestation; no further tab change authorized without new evidence |
| Report access | six report folders shared `View` to `PG_All_Sales`; dashboard folder `NG_Sales` shared `View` to `PG_All_Sales` | live Metadata API retrieve |
| Rep persona | session ended; baseline restored: `VP_Sales`, `NG_Sales`, `ManagerId=null`, no persona PSGs | `scripts/persona.sh restore`; live queries |
| Phase 2 UAT | **UNVERIFIED**; template unsigned, tag is not evidence | `docs/planning/PHASE2_SIGNOFF_RECONCILIATION_2026-10-20.md` |
| P4-10..P4-13 | source/evidence largely present; P4-10 screenshot and closure sign-off missing | `BUILD_STATUS.md`; `evidence/P4`; full suite |
| P3-01 deferred checks | not passed, not failed; not a Phase 5 blocker | `docs/planning/P3-01_DEFERRED_CHECKS_2026-10-20.md` |

## Rep UAT findings (2026-10-20)

- Quote persisted for Opportunity `006aj00000fbDI1AAM`: Quote
  `0Q0aj000003kVS5CAM`, QLI `0QLaj000004f0JVGAY`, subtotal `50615`,
  adjusted subtotal `43022.75`, one pricing rule. Opportunity stamps are
  `Discount_Percent__c=15` and `Approval_Status__c=Pending`. No approval
  submission was made.
- Owner browser UAT: Loyalty Members → All displayed 50+ records; Deliveries → All
  displayed 13 records; Pipeline by Stage opened with 81 Opportunities / `$4,827,766`;
  Loyalty Tier Distribution opened with 12 members; `DM_DealDesk` rendered three metrics.
  Dashboard access passed; its three displayed zero values do not establish metric
  accuracy. Loyalty report description is outdated, nonblocking cleanup.
- `Loyalty_Member__c.All` and `Delivery__c.All` live list views use
  `filterScope=Mine`. All 72 loyalty records are owned by `arjun.ngdemo`;
  zero are owned by `ngpersona`. Record access and object permissions are
  otherwise correct. Local source changes both `All` views to `Everything`.
- Owner's latest screenshot confirms Delivery tab visible in Northgate Sales. Do not deploy
  another Delivery tab change without new evidence.
- `PG_All_Sales` currently has one member: `ngpersona`. Add other demo sales
  users if the walkthrough uses them.
- The `PS_Sales_Rep` local source and live metadata differ beyond the prepared tab
  setting: local enables edit on `Delivery__c.Checklist_Complete__c` (live edit is
  false); local grants read on `Vehicle_Model__c.Name` (no live FLS row); and local
  grants QuoteLineItem Create/Read/Edit (no live object-permission row). Owner confirms
  Delivery tab is already visible; no tab permission deployment is needed. Do not deploy
  this PermissionSet while unrelated differences remain.
- `Opportunity.AccountId` Read/Edit is already live and documented as an intended,
  previously deployed fix (`evidence/P5/REMEDIATION_REPORT.md`).

## Phase 5 load status

Live counts match the canonical envelope for the loaded objects:

| Object | Count |
|---|---|
| Account | 150 |
| Contact | 185 |
| Lead | 130 |
| Opportunity | 100 |
| Quote | 60 |
| Vehicle | 120 |
| Trade_In | 45 |
| Financing | 60 |
| Delivery | 12 |
| Loyalty Member | 70 |
| Service Visit | 140 |
| Task | 200 |
| Event | 50 |

`SEED-98` is 0 records (deferred). `data/SEED_VERSION.txt` records
`PHASE_5_STATUS=COMPLETE` and 2,085 loaded records. `verify_gates.txt` states the full
§2.1 envelope is not satisfied because the 30 `SEED-98` records are deferred.

## Remaining acceptance gaps

1. **Phase 5 closeout**: P5-03 storage artifact remains missing. P5-05 reconciliation and
   the 16-row additive proposal remain deferred by owner decision. `SEED-98` is also
   deferred. Do not insert ledger rows, overwrite records, or reload canonical data.
2. **Phase 2 UAT sign-off** remains open. This blocks a clean release narrative, not the
   already-loaded data.

## Non-blockers

- P3-01 Sales Manager persona checks and screenshots: deferred demo evidence only.
- P4-10 dashboard access screenshot is owner-reported; metric accuracy remains unverified.
  Explicit P4-10..P4-13 closure remains acceptance bookkeeping.
- `FolderShare` SOQL limitation: source metadata and `PG_All_Sales` membership are verified;
  live folder-share rows cannot be queried through SOQL.

## Owner decision progress

- Owner browser results recorded. Screenshot files were not archived in the repository;
  evidence record preserves owner attestation and values.
- Persona restore completed after both persona-specific pending approval queries returned
  zero and `finance_pre_restore_guard.apex` returned `PASS` with zero finance approvals and
  zero queue work items. Role, profile, ManagerId, persona PSGs, and unrelated assignments
  were verified.
- P3-DEF-01 exact two-class check-only, deployment, focused test, and `rep_verify.apex`
  completed successfully. No broader Apex suite ran.
- Phase 5 ledger remains unchanged by owner decision. Do not insert proposed rows or
  reload/reset seed. Phase 2 remains `UNVERIFIED`.
