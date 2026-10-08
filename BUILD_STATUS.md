# Build Status — Northgate Motors demo org

Target org: **ng-dev only** (`arjun.ngdev@northgate.demo`). Never touch ng-demo or other orgs.
CLI: @salesforce/cli 2.153.5. sourceApiVersion 67.0, org API 68.0.

## Phase 1 — DONE (commit `dba455b`)

Phase 1 complete and exit report written (`evidence/P1/phase1_exit_report.md`).
CI green: `validate.yml` run 37718718354 PASS.
All blockers resolved. Users created; PSGs assigned; persona switch verified.

## Phase 2 — IN PROGRESS

End-to-end vertical slice: web lead → qualification → test drive → opportunity,
with automation, reports and tests. First demoable state.

| ID | Item | Status | Evidence |
|---|---|---|---|
| P2-01 | Lead intake assignment (FSA → rooftop, round-robin) | Flow retrieved (Draft); owner to activate after approval | `evidence/P2/blocked-metadata/flows/` |
| P2-02 | Lead conversion guidance | Pending | `evidence/P2/conversion.png` |
| P2-03 | Test-drive screen flow | Pending | `evidence/P2/testdrive_conflict.png` |
| P2-02 | Lead conversion guidance + seed-tag behavior | Done (Apex) | `evidence/P2/conversion.txt` |
| P2-03 | Test-drive screen flow | Skipped (Flow XML blocked; UX cover via P2-04 guard + P2-07/08 triggers) | `evidence/P2/conflict_tests.txt` |
| P2-04 | Conflict-check subflow + Apex | Apex guard done; subflow pending | `evidence/P2/conflict_tests.txt` |
| P2-05 | Opportunity stage model + stage-stamp | Apex stamp done; layout verify pending | `evidence/P2/stages_reserve_tests.txt` |
| P2-06 | Vehicle reservation logic | Apex guard done; screen verify pending | `evidence/P2/stages_reserve_tests.txt` |
| P2-07 | Task auto-creation | Done (Apex via TestDriveFollowUp) | `evidence/P2/tasks.txt` |
| P2-08 | Email alert | Wired (Apex; deliverability may suppress in DE) | `evidence/P2/tasks.txt` |
| P2-07 | Task auto-creation | Pending | `evidence/P2/tasks.png` |
| P2-08 | Email alert (TestDrive confirm) | Pending | `evidence/P2/confirm_email.png` |
| P2-09 | Report: pipeline by stage | Click steps issued | `evidence/P2/reports_blocked.txt` |
| P2-10 | Report: lead source effectiveness | Click steps issued | `evidence/P2/reports_blocked.txt` |
| P2-11 | Dashboard: sales snapshot (dynamic) | Click steps issued | `evidence/P2/reports_blocked.txt` |
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

## Blocked
- **P2-01 Lead Enrich Rooftop:** retrieved (Draft) and validated (commit `fb781f2`); owner to activate after approval, then end-to-end UAT. Design at `evidence/P2/blocked-metadata/flows/LEAD_ENRICH_ROOFTOP_design.md`; checklist `evidence/P2/OWNER_ACTION_LIST.md` §2.
- **P2-09 / P2-10 / P2-11 reports and dashboard:** corrected checklist in `evidence/P2/OWNER_ACTION_LIST.md` (3 widgets, viewer mode, conversion % via row-level flag + percent summary, staff grouping on `Opportunity.Sales_Staff__c`, one new group `PG_All_Sales`). Conversion-rate spec treated as unverified until validated in Report Builder.

## Click steps waiting (owner)
- **0.** Create public group `PG_All_Sales` (members: ngrep, arjun.ngdev@northgate.demo).
- **1.** Build the 3 reports + 1 dashboard and share folders per `evidence/P2/OWNER_ACTION_LIST.md` §1.
- **3.** Activation gate per MASTER_PLAN §7.5: approval line in `metadata-log/README.md`, then activate, then end-to-end UAT.
- **C.** CI validation: `gh workflow run validate.yml` after each step (current run `37810319248` PASS).
- **D.** P1-15 follow-up after OrgFarm EPIC deactivation: done.
- **E.** Phase 2 exit gate (M1): blocked on 0/1/3; agent will retrieve, validate, commit, and produce the M1 gate report once owner says done.
- Owner evidence screenshots (P1 roles/OWD/layouts/apps) and `evidence/P2/uat/` screenshots still pending; M1 gate sign-off.
- **No Phase 3 or ng-demo deployment without explicit approval.**
