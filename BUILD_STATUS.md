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
| P2-04 | Conflict-check subflow + Apex | Pending | `evidence/P2/conflict_tests.txt` |
| P2-05 | Opportunity stage model + stage-stamp flow | Pending | `evidence/P2/stages.png` |
| P2-06 | Vehicle reservation logic | Pending | `evidence/P2/reserve_block.png` |
| P2-07 | Task auto-creation | Pending | `evidence/P2/tasks.png` |
| P2-08 | Email alert (TestDrive confirm) | Pending | `evidence/P2/confirm_email.png` |
| P2-09 | Report: pipeline by stage | Pending | `evidence/P2/rpt_pipeline.png` |
| P2-10 | Report: lead source effectiveness | Pending | `evidence/P2/rpt_leadsource.png` |
| P2-11 | Dashboard: sales snapshot (dynamic) | Pending | `evidence/P2/dash_pipeline_*.png` |
| P2-12 | Flow-maintained counters v1 | Pending | `evidence/P2/counters_test.txt` |
| P2-13 | Apex test suite v1 | Pending | `evidence/P2/tests.txt` |
| P2-14 | UAT script for slice | Pending | `evidence/UAT/UAT_P2.md` |
| P2-15 | Demo script v1 | Pending | `evidence/DEMO_SCRIPTS/01_lead_to_testdrive.md` |

**M1 gate:** dry-run clean, tests ≥90%, DQ 0 rows, UAT_P2 signed, screenshots, tag `demo/v0.1`.

## Gates and rules
- **Source-first rule:** anything that can be Metadata API metadata is deployed from `force-app/`. Records are never created through the API for metadata. Only data (users, assignments, seed records) may be created via records, and each such case is listed in the phase evidence.
- **ng-demo gate:** Deactivate `OrgFarm EPIC` in ng-demo before creating users (reversible; needed to free Salesforce licences). Delete sample roles in ng-demo before deploying roles.
- **Org settings / Setup / user-admin settings:** one source-deploy attempt max. On failure: write numbered click steps, stop, wait for 'done', verify with one query.
- **Error diagnosis:** never retry unchanged. After 3 distinct failed fixes, mark blocked and continue independent work.
- **Known retrieve gap:** `sf project retrieve start --metadata <type>` returns "Nothing retrieved" for Role, CustomObject, StandardValueSet on ng-dev. Verify with SOQL/Tooling API until resolved.

## Blocked
- **P2-01 Flow:** hand-written `Lead_Enrich_Rooftop.flow-meta.xml` fails Metadata API schema validation after 3 fixes (start element, lookup element name/order, same-type grouping). Routing table records + `LeadRoundRobin` Apex action are valid and staged; the flow file is intentionally uncommitted. Build the flow in Flow Builder (or via a Flow-authoring skill), then commit. Evidence `evidence/P2/p201_blocked.txt`.

## Click steps waiting (owner)
- Screenshots for evidence (P1 roles/OWD/layouts/apps) and Phase 2 evidence files.
- M1 gate sign-off.
- **No Phase 3 or ng-demo deployment without explicit approval.**
