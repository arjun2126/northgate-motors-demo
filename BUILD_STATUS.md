# Build Status — Northgate Motors demo org

Target org: **ng-dev only** (`arjun.ngdev@northgate.demo`). Never touch ng-demo or other orgs.
CLI: @salesforce/cli 2.153.5. sourceApiVersion 67.0, org API 68.0.

Working and escalation rules live in `AGENTS.md` at the repository root and apply to every agent in every session.

## Phase 1 — DONE (commit `dba455b`)

Phase 1 complete and exit report written (`evidence/P1/phase1_exit_report.md`).
CI green: `validate.yml` run 37718718354 PASS.
All blockers resolved. Users created; PSGs assigned; persona switch verified.

## Phase 2 — IN PROGRESS

End-to-end vertical slice: web lead → qualification → test drive → opportunity,
with automation, reports and tests. First demoable state.

| ID | Item | Status | Evidence |
|---|---|---|---|
| P2-01 | Lead intake assignment (FSA → rooftop, round-robin) | Owner-verified by real save; `LeadRoutingHandlerTest` 6/6 pass | `evidence/P2/blocked-metadata/flows/`, `docs/TECH_DEBT.md` |
| P2-02 | Lead conversion guidance + seed-tag behavior | Done (Apex guards); Flow nudge + screenshot pending | `evidence/P2/conversion.txt` |
| P2-03 | Test-drive screen flow | Skipped (Flow XML blocked); UX covered by P2-04 guard | `evidence/P2/conflict_tests.txt` |
| P2-04 | Conflict-check subflow + Apex | Apex guard done; subflow pending | `evidence/P2/conflict_tests.txt` |
| P2-05 | Opportunity stage model + stage-stamp | Apex stamp done; layout verify pending | `evidence/P2/stages_reserve_tests.txt` |
| P2-06 | Vehicle reservation logic | Apex guard done; screen verify pending | `evidence/P2/stages_reserve_tests.txt` |
| P2-07 | Task auto-creation | Done (Apex via TestDriveFollowUp); screenshot pending | `evidence/P2/tasks.txt` |
| P2-08 | Email alert | Wired (Apex; deliverability may suppress in DE); receipt pending | `evidence/P2/tasks.txt` |
| P2-09 | Report: pipeline by stage | Structural PASS (owner option b); source reconciled to org Matrix version; seeded rows tracked P5-03/P5-13 | `evidence/P2/p209_p210_data_scope.txt` |
| P2-10 | Report: lead source effectiveness | Validated; Display owner-confirmed, Created Date awaits inspection | `evidence/P2/p210_validation.txt` |
| P2-11 | Dashboard: sales snapshot (dynamic) | Built (3 widgets as specified, viewer mode LoggedInUser); dynamic evidence pending; source captured | `evidence/P2/p211_group_and_folder_verification.txt` |
| P2-12 | Flow-maintained counters v1 | Done (Apex; Flow XML blocked) | `evidence/P2/counters_test.txt` |
| P2-13 | Apex test suite v1 | Done (P2TestDataFactory + 200-row bulk) | `evidence/P2/tests.txt` |
| P2-14 | UAT script for slice | Done (template; to run after P2-01/09/10/11 land) | `evidence/UAT/UAT_P2.md` |
| P2-15 | Demo script v1 | Done (Lead → Test Drive → Opportunity) | `evidence/DEMO_SCRIPTS/01_lead_to_testdrive.md` |

**M1 gate:** dry-run clean, tests ≥90%, DQ 0 rows, UAT_P2 signed, screenshots, tag `demo/v0.1`.

## Gates and rules
- **Source-first rule:** anything that can be Metadata API metadata is deployed from `force-app/`. Records are never created through the API for metadata. Only data (users, assignments, seed records) may be created via records, and each such case is listed in the phase evidence.
- **ng-demo gate:** Deactivate `OrgFarm EPIC` in ng-demo before creating users (reversible; needed to free Salesforce licences). Delete sample roles in ng-demo before deploying roles.
- **Org settings / Setup / user-admin settings:** one source-deploy attempt max. On failure: write numbered click steps, stop, wait for 'done', verify with one query.
- **Error diagnosis:** never retry unchanged. After 3 distinct failed fixes, mark blocked and continue independent work.
- **Known retrieve gap:** `sf project retrieve start --metadata <type>` returns "Nothing retrieved" for Role, CustomObject, StandardValueSet on ng-dev. Verify with SOQL/Tooling API until resolved.
- **Routing test persona:** UAT runs as `PS_Demo_Admin_No_Bypass` so field access stays complete while `Bypass_Automation` stays off. `PS_Demo_Admin` is unassigned while that set exists.

## P2-01 routing — verified state

- **`LeadRoutingHandlerTest`:** 6/6 methods pass after the manual correction.
- **Correction:** `PostalCode` was removed from the seed in `leadWithNoRooftopIsLeftAlone`. Both null assertions (`Rooftop__c` and `Assigned_Batch__c`) remain unchanged.
- **Real-save evidence:** `M5V2T6` → Rooftop `Northgate Downtown`, owner Sales Rep, `Assigned_Batch M-R1`.
- **Testing permissions:** `PS_Demo_Admin_No_Bypass` is assigned so field access stays complete while `Bypass_Automation` stays off; original `PS_Demo_Admin` is unassigned.

### Runnable test result
`sf apex run test` on ng-dev: **31 pass / 0 fail** across the whole suite (2026-10-08).
`P2UAT_RoutingTemp.uatRoutingAsSalesRep` passes individually.

### Permission change captured in source

`force-app/main/default/permissionsets/PS_Sales_Rep.permissionset-meta.xml` now carries:

```
<userPermissions>
    <enabled>true</enabled>
    <name>ViewRoles</name>
</userPermissions>
```

**Why it is needed:** `LeadRoutingHandler.resolveLane` resolves the lane table by querying
`SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = :spec[0]`.
Querying across a relationship path requires the running user to hold
**View Roles and Role Hierarchy**. When `ngrep` executed the routing UAT, `PS_Sales_Rep`
did not grant it, so the query threw:

```
System.QueryException: Didn't understand relationship 'UserRole' in field path.
```

`LeadRoutingTrigger` runs `resolveLane` on Lead after-insert, so the exception rolled the
whole insert back.

**Why it is safe:** the trigger query runs in system context in the real UI, so this grant
only widens `PS_Sales_Rep`'s ability to read role metadata. It grants no object access, no
record visibility, and no record-level data. Role existence is already visible through the
role hierarchy UI, so this exposes nothing new.

## Blocked
- **P2-01 cross-transaction round-robin:** open design decision, separate from the test fix. Routing and in-transaction rotation are verified; rotation across sequential saves is not. Recorded in `docs/TECH_DEBT.md`.
- **P2-09 / P2-10 / P2-11 reports and dashboard:** corrected checklist in `evidence/P2/OWNER_ACTION_LIST.md` (3 widgets, viewer mode, staff grouping on `Opportunity.Sales_Staff__c`, one new group `PG_All_Sales`). Conversion-rate spec is a proposed summary-only formula `Converted:SUM / RowCount` with Percent output, UNVALIDATED in Report Builder. The earlier row-level-flag wording was incorrect and has been removed. Validation is a required owner-click step for P2-10.
- **P2-10 validation note:** `evidence/P2/p210_validation.txt` records structure/formula as validated by metadata. Display is **owner-confirmed** (All summary levels; `Grand Summary Only` is **not** equivalent to `All summary levels`, and the `<aggregates>` element carries no `summaryElement`/`summaryLevel`, so visual confirmation was required). The `Created Date` range remains **unconfirmed** and awaits owner inspection (`timeFrameFilter` is `INTERVAL_CUSTOM` with no bounds in the XML). Row counts pass via `showDetails`/`showSubTotals`/`showGrandTotal`; no `Lead.Id` Count aggregate is required. Numerical validation is **untested** (tracked separately; 25.0% example not demonstrated).

## Click steps waiting (owner)
- **PG_All_Sales membership is 1 of 3, not 3 of 3.** `GroupMember` for `00Gg800000A5GXpEAN` returns exactly one row: ngrep (`005g800000Bsi49AAB`, GroupMember `011g8000003PyaLAAS`). **ngpersona (`005g800000Bso7xAAB`) and arjun.ngdev (`005g800000BroZpAAJ`) are NOT members.** ngrep opening reports is explained by folder sharing, not by membership. `doesIncludeBosses` re-retrieved from the org: still `false`, matching source. The only diff between the org copy and the local file is XML element order, which is semantically irrelevant - no semantic drift.
- **Run Reports metadata drift (source vs org) — working tree updated, uncommitted.** ngrep gains `Run Reports` via PSG_Rep -> PS_Sales_Rep. In the org `PS_Sales_Rep` has the RunReports userPermissions block enabled. The committed source (HEAD) does **not** contain it - HEAD's only userPermission is `ViewRoles`. The working tree now carries the +4-line RunReports block as an **unstaged** addition (verified by `git diff`: +4/-0, RunReports block only); no other permission changed. So `Run Reports` was enabled out-of-band in Setup and never captured; the working tree now matches the org - no deploy needed or performed.
- **Amount correction:** total is **$5,760,000**, Closed Won $3,645,000 (18), Open $2,115,000 (13), Closed Lost 0. An earlier evidence draft recorded $5,750,000 / $2,105,000 from a manual hand-sum; both were wrong. Re-verified with Python sum and SOQL `SUM`. The owner's $5.76M reconciles exactly.

- **Report data-scope finding (P2-09/P2-10):** the 31 opportunities in ng-dev are pre-existing OrgFarm sample data owned by `epic.3623e0cffa54@orgfarm.salesforce.com` (provision-time generator deals, sum $5,760,000), not Northgate seed data. `Sales_Staff__c` is null on 31 of 31. Northgate opportunity seed data loads at P5-03 in Phase 5. Opportunity OWD is Private (`sharingModel` in `Opportunity.object-meta.xml`), the OrgFarm owner has no UserRole, and no sharing rule grants Opportunity access to role Sales Rep. So ngrep seeing zero rows is the expected Phase 2 outcome, not a defect. Report `<scope>org</scope>` is correct and is not the limiting factor; org-wide scope never overrides OWD. Detail: `evidence/P2/p209_p210_data_scope.txt`. **Backlog P2-09 criterion resolved by owner (option b):** the acceptance criterion is now structural validation only ("report runs and grouping/aggregate structure confirmed"), with the seeded-row check explicitly tracked at P5-03 (seed data loaded) and P5-13 (duplicate-audit report). Owner approved; the "Report run returns seeded rows" wording is superseded for P2-09. Detail in `evidence/P2/p209_p210_data_scope.txt`.

- **0.** Create public group `PG_All_Sales` (members: ngrep, arjun.ngdev@northgate.demo).
- **1.** Build the 3 reports + 1 dashboard and share folders per `evidence/P2/OWNER_ACTION_LIST.md` §1.
- **3.** Activation gate per MASTER_PLAN §7.5: approval line in `metadata-log/README.md`, then activate, then end-to-end UAT.
- **C.** CI validation: `gh workflow run validate.yml` after each step (current run `37810319248` PASS).
- **D.** P1-15 follow-up after OrgFarm EPIC deactivation: done.
- **E.** Phase 2 exit gate (M1): group created, reports + dashboard built and retrieved this batch; remaining blockers: group membership 2 of 3, folder-share verification/removal, dynamic-by-role evidence, UAT run + screenshots, tag. No commit/push/tag until approved.
- Owner evidence screenshots (P1 roles/OWD/layouts/apps) and `evidence/P2/uat/` screenshots still pending; M1 gate sign-off.
- **No Phase 3 or ng-demo deployment without explicit approval.**
