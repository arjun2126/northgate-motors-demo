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
| P2-01 | Lead intake assignment (FSA → rooftop, round-robin) | Blocked (Flow XML; routing table + Apex action staged) | `evidence/P2/p201_blocked.txt` |
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
- **P2-01 Lead Enrich Rooftop flow:** hand-written `flows/Lead_Enrich_Rooftop.flow-meta.xml` fails Metadata API schema validation after 3 fixes. Routing records + `LeadRoundRobin` Apex action are valid and staged; flow file quarantined as `.blocked`. Needs Flow Builder authoring or a Flow-authoring skill. Evidence `evidence/P2/p201_blocked.txt`.
- **P2-09 / P2-10 / P2-11 reports and dashboard:** click-by-click checklist issued (`evidence/P2/reports_blocked.txt`). Owner to author Pipeline by Stage, Lead Source Effectiveness, Sales Pipeline Snapshot in Setup. Folders `NG_01_Pipeline`, `NG_02_Leads`, `NG_Sales` already exist (Hidden access; set Public). After “done”, retrieve, validate, commit. Not marked complete until acceptance passes.

## Click steps waiting (owner)
- **A.** P2-09/10/11 reports + dashboard (full spec in `evidence/P2/blocked-metadata/REPORTS_DASHBOARDS_checklist.md`).
- **B.** P2-01 Lead Enrich Rooftop flow in Flow Builder (spec in `evidence/P2/p201_blocked.txt`).
- **C.** CI validation: `gh workflow run validate.yml` after each step (already green; current run 37779791983 PASS, head `9074a9e`).
- **D.** P1-15 follow-up after OrgFarm EPIC deactivation: done.
- **E.** Phase 2 exit gate (M1): blocked on A and B; agent will retrieve/validate/commit once owner says done.
- Owner evidence screenshots (P1 roles/OWD/layouts/apps) and `evidence/P2/uat/` screenshots still pending; M1 gate sign-off.
