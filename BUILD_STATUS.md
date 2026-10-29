# Build Status — Northgate Motors demo org

**Current consolidated Phase 5 handoff (2026-10-20):**
`docs/planning/P5_CONSOLIDATED_COMPLETION_2026-10-20.md` reconciles every original P5 item
after the scoped release: 15 PARTIAL, 5 BLOCKED; no full Phase 5 acceptance. Live raw evidence
is in `evidence/P5/consolidated_completion_checks_2026-10-20.md`. Key open dependencies:
exact <=4.0 MB storage, missing canonical `data/csv/` artifacts, truthful per-batch ledger,
remaining expected-count report gaps, controlled management UAT and reset/burst acceptance.
The six Opportunity values are correct, but their report currently excludes them through
its default fiscal-quarter CloseDate filter. No new deployment, DML or permission change
occurred in this consolidated planning pass. Older status blocks below are historical.

**Latest preparation (2026-10-20):** `evidence/P5/continuation_2026-10-20.md` records eleven
passing offline checks, five-component manager-access/SLA check-only `0Afaj00000oSg4LCAS`,
37-job execution-count reconciliation covering 2,085 canonical IDs, exact SEED-98 parent
proposals and split/resolved burst files. This continuation made no real deployment, data
write or persona change. Live Contact duplicate-rule identity is blocked on owner confirmation.
All original P5 criteria remain open where data, storage, runtime or destructive execution
evidence is missing. Genuine Phase 2 browser procedure:
`docs/planning/P2_BROWSER_UAT_PROCEDURE_2026-10-20.md`.

**Controlled release (2026-10-20):** Phase 2 `0Afaj00000oQaj1CAC` and Phase 5
`0Afaj00000oQtVWCA0` deployed 4/4 and 15/15 with zero errors. Persona-scoped Phase 2 UAT
remains blocked on a rep browser session; baseline was restored. Governing allocation is
60 Product2 + 12 Delivery (2,115); original 2,123 preserved as historical. Runtime findings
and blockers: `evidence/P5/release_uat_2026-10-20.md`. Earlier check-only jobs
`0Afaj00000oQSwkCAG` / `0Afaj00000oQNXGCA4` and permission impact:
`evidence/P5/check_only_resolution_2026-10-20.md`.

**Earlier implementation package (2026-10-20):** all original P5-01…20 requirements and
P2-03 `TestDrive_Book_Screen` remain mandatory. Original eight-phase roadmap includes P8.
Local generator/evidence/legacy/snapshot work passes 7 focused checks. Phase 2 check-only
`0Afaj00000oPyx5CAC` and Phase 5 check-only `0Afaj00000oPzQ6CAK` failed; no deployment or
record write occurred. Exact failures, unimplemented reset/burst work, original eight-record
count conflict, and approval sequence: `docs/planning/P2_P5_IMPLEMENTATION_2026-10-20.md`.

Current target org: **ng-demo** (`arjun.ngdemo@northgate.demo`, `00Daj00001Ae3iWEAR`). Historical Phase 1-4 entries below reference `ng-dev`; do not access `ng-dev` or other orgs without explicit owner approval.
CLI: @salesforce/cli 2.153.5. sourceApiVersion 68.0, org API 68.0.

Working and escalation rules live in `AGENTS.md` at the repository root and apply to every agent in every session.

## Phase 1 — DONE (commit `dba455b`)

Phase 1 complete and exit report written (`evidence/P1/phase1_exit_report.md`).
CI green: `validate.yml` run 37718718354 PASS.
All blockers resolved. Users created; PSGs assigned; persona switch verified.

## Phase 2 — IMPLEMENTATION DONE; UAT SIGN-OFF UNVERIFIED

End-to-end vertical slice: web lead → qualification → test drive → opportunity,
with automation, reports and tests. First demoable state.

Implementation and tests are present, but the earlier "UAT_P2 signed" claim is not
supported by the repository. `evidence/UAT/UAT_P2.md` is an unsigned template, and tag
`demo/v0.1` points to `ccc7565` without UAT evidence. Treat Phase 2 UAT as open, not
passed. See `docs/planning/PHASE2_SIGNOFF_RECONCILIATION_2026-10-20.md`.

## Phase 3 — DONE (commit `638524df`, M2 gate, 24/24 tests)

Discount approval routing + write-back verified incl. live-persona evidence [V — `DiscountApprovalTest` 6/6].
Quote Builder + Quote Summary implemented; Quote Summary owner-accepted after live test as `ngrep` [O].
Page activations verified: `NG_Opportunity_Quote_Builder` (Sales / Retail / NG_Sales / Desktop) [O]; `NG_Quote_Summary` previously activated + accepted [O].
Six reports + Quote Health dashboard verified [O for UI acceptance; org inventory V — see `NORTHGATE_PROJECT_HANDOFF.md` §4].
CP2 pricing behavior preserved [V — no edits to engine/rules/quoteBuilder pricing path; 24/24].
Historical CP2 UAT Quote discrepancy intentionally preserved [O decision; see handoff §8].
Unrelated working-tree modifications remain uncommitted [V — `git status`].
Head: `638524df06db2652236a2693d8b2191054116a8b`. Local `main` is **1 commit ahead of `origin/main`**; the commit has not been pushed.

## Phase 4 — DONE (P4-01 through P4-09 ACCEPTED AND CLOSED, M2 gate met)

Phase 4 complete end-to-end in `ng-dev`. Full evidence in `NORTHGATE_PROJECT_HANDOFF.md` §11 and §12. The M2 gate ("full retail deal runs from lead to delivered vehicle with financing, approvals and loyalty enrolment") is **met**.

Deployment jobs in `ng-dev` (owner-authorized, all `checkOnly: False`):
- P4-01 `PaymentCalculatorService` — `0Afg800000HLNvtCAH`, 5/5 tests.
- P4-03 `FinancingStatusService` + `FinancingTrigger` + `VR_Financing_TermRequired` — `0Afg800000HPct7CAD`, 18/18 tests.
- P4-04 `RateTableService` + `Rate_Table__mdt` (30 active + 1 inactive) — `0Afg800000HPAATCA5`, 5/5 tests. CMT read required explicit Custom Metadata Type Access in the permission set.
- P4-02 `FinanceApplicationController` + LWC `financeApplication` + QuickAction `Opportunity.Finance_Application` + `Financing__c.Quote__c` + `PS_Finance_Wizard_Access` — class access `0Afg800000HTGlyCAH`, wizard PS `0Afg800000HT52YCAT`, CMT/preview `0Afg800000HTcCzCAL` (20/20). Applicant/buyer fix deployed `0Afg800000HaFl7CAF` (validation `0Afg800000HZtf4CAD`, 16/16). **Owner browser-verified**: financing record `a03g800000rzfMHAAY`, Quote "NG CP2 Browser UAT - Quote", Status Draft, Applicant P1-14Test, Amount $30,340, Monthly $579.39, Total Interest $4,423.40.
- P4-05 `Financing__c.Finance_Exception_Approval` approval process (ACTIVE) + `Financing__c.workflow` field updates + `FinancingApprovalService` + LWC `submitFinancingApproval` + QuickAction. Field rename `Exception_Approved__c` → `Finance_Exception_Approved__c` cleared an orphaned-metadata state. Workflow + Approval Process deploy `0Afg800000HdzWTCAZ` (5/5, 156/156 tests). Field rename prerequisite deploy `0Afg800000Hcdt4CAB` (1/1). **Owner browser-verified**: approval routed to `Q_Finance_Approvals`, approved by `ngadmin` (temporarily holding `Finance_Manager`); Approval History shows Approved; `Finance_Exception_Approved__c` automatically changed to TRUE; `Decision_Date__c` populated to 2026-10-15. `ngadmin` role reverted to None.
- P4-06 + P4-07: `VR_Delivery_ChecklistBeforeCompleted` ACTIVE in `ng-dev` (formula + error message verified via Tooling). `DeliveryTrigger` + `DeliveryCloseService` deployed. **Owner browser-verified**: delivery completion blocked when checklist items were incomplete (VR fired with the documented error); delivery completed successfully after all four checklist items were checked (save succeeded, `Completed_Date__c` auto-stamped); associated Opportunity automatically transitioned to Closed Won (`Delivery_Completed__c = true`).
- P4-08: `LoyaltyEnrolmentService` + late-Buyer enrollment defect correction. **Late-Buyer fix deploy** `0Afg800000HeoZ0CAJ` (2/2 components, **160 of 160 Apex tests passed**, 0 component failures, 0 test failures). **One-time approved loyalty backfill**: invoked `LoyaltyEnrolmentService.enrolOnDelivery` once via `sf apex run` on Delivery `a02g800000EjTXFAA3` (Buyer = P1-14Test `003g800000q7EzZAAU`, Status = Completed). **Loyalty Member Id `a04g8000002slf7AAA`**, Member Number **`NG-7904-0782`**, Status **Active**, Tier **Bronze**, Points **0**. Delivery remained Completed. Opportunity remained Closed Won. No duplicate membership (org-wide Loyalty_Member__c count = 1). **Observation, not an automatically authorized repair:** `Contact.Lifetime_Vehicles_Owned__c` remained `null` after the backfill (the backfill invoked the service directly, not the trigger; the service does not touch Contact lifetime; the original Delivery 0 completion was performed with `Buyer__c` blank, so the trigger's first-loop lifetime increment did not fire). The late-Buyer path has automated test coverage (`DeliveryCloseServiceTest.buyerAddedAfterCompletion_enrolsOnLateAssignment`).
- P4-09: `Financing_Mix_by_Status` (NG_01_Pipeline) + `Funding_Lag` (NG_05_DataQuality) + `FinancingList` report type. **Owner browser-verified**: report opened successfully; Funded-only filter confirmed; both existing Financing records were Draft (explaining original zero results); temporary filter adjustment displayed 2 records; Total Amount Financed $60,680; Total Monthly Payment $579.39; Credit Tier A and Rate Source Manual Exception displayed; owner restored the Funded-only filter.

Outstanding prerequisites and manual steps (not defects; not resolved by code):
- **Finance Manager queue membership**: `Q_Finance_Approvals` routes to `Finance_Manager` role. For future P4-05 UAT cycles, owner must temporarily assign `Finance_Manager` to `ngadmin` and revert. `ngpersona` cannot be modified.
- **QuickAction on Financing page layout highlights panel**: `Submit_For_Exception_Approval` QuickAction is deployed as a new record action; one Setup click adds it to the page layout's "Salesforce Mobile and Lightning Experience Actions" list to surface in the highlights panel. (The `Layout` metadata schema does not support a quick-action list element.)
- **`Contact.Lifetime_Vehicles_Owned__c` for Delivery 0**: observation only. Whether to increment to 1 is a business decision and is not automatically authorized.
- **P4-10..P4-13** have source and partial evidence but are not closed here. P4-10 `DM_DealDesk` exists in `ng-demo` with the three required metrics; P4-11 `FinancingFlsEnforcementTest` passed in the `ng-demo` full suite `707aj00001MTeI1` (189/189); P4-12 `docs/architecture/SIMULATION_FINANCE.md` exists; P4-13 target classes meet 90% in `evidence/P4/tests.txt`. Missing acceptance evidence is the P4-10 dashboard screenshot and explicit closure sign-off. They are not Phase 5 data-load blockers.
- **P4-04 LTV eligibility** is still Draft-only (true LTV source and valuation tool remain a Phase 5+ decision).

**P3-01 Trade-In Appraisal — ACCEPTED for this demo scope**

Saved-record verification confirmed all five equity scenarios returned expected values:

| Scenario | Appraisal | Payoff | Equity | Status |
|---|---|---|---|---|
| Positive | 21,212 | 1,212 | 20,000 | ✅ PASS |
| Negative | 15,000 | 25,000 | -10,000 | ✅ PASS |
| Equal | 20,000 | 20,000 | 0 | ✅ PASS |
| No payoff | 25,000 | 0 | 25,000 | ✅ PASS |
| Decimal | 12,345.67 | 10,000.12 | 2,345.55 | ✅ PASS |

All records: Status = Appraised, Appraised_By/Appraisal_Date populated, Opportunity linked.

**Deferred checks (not passed, not failed — explicitly deferred):**

- Sales Manager persona verification (ngrep/ngpersona access to saved records)
- Review-screen screenshots (Dashboard/Report widgets for Sales Manager view)
- Per-run record-count correlation (tie saved records to specific test runs)
- Vehicle input/required-field validation review (UI field-level validation)

**Do not label deferred checks as passed. Do not sign UAT_P2.**

---

**P3-03 Price_Rule__mdt Records — DEPLOYED**

10 metadata records deployed to `ng-dev` (deploy id `0Afg800000H1av1CAB`):
`Trim_Premium_Premium`, `Trim_Premium_Limited`, `Aged_Inventory_Discount_60`,
`Aged_Inventory_Discount_90`, `Loyalty_Bronze_Discount`, `Loyalty_Silver_Discount`,
`Loyalty_Gold_Member_Discount`, `Loyalty_Platinum_Discount`, `Volume_Discount_Over_10`,
`Fleet_Discount_Over_5`. All percentage-only (`Fixed_Adjustment__c = 0.00`).

**Stored value convention (verified):** `Percent_Adjustment__c` is stored as a
**positive** number for all 10 records; direction is conveyed by `Rule_Type__c`
(`Premium` = +, `Discount` = −). Verified by query
`SELECT DeveloperName FROM Price_Rule__mdt WHERE Rule_Type__c = 'Discount' AND Percent_Adjustment__c < 0` → 0 rows.
**P3-05 must use `Rule_Type__c` to determine sign**, not the percent value.

**Metadata deployment does not establish pricing-engine correctness.** P3-05
(`QuotePricingService`) and P3-12 (tests) are not yet built. Source mappings
and open scope conflicts recorded in `evidence/P3/p3_03_source_mappings.md`.

**Apex suite post-deploy:** `RunLocalTests` → 50/50 pass, 0 failures
(test run id `707g800000oKXoQ`).

---

**P3-02 — DONE (deployed as part of Phase 3 commit `638524df`)**

`Quote_Before_Create_Flow` (Record-Triggered, Before Create on Quote) blocks quote creation when a related `Trade_In__c` exists and its `Status__c != 'Accepted'`. `VR_Quote_TradeIn_Accepted` on Quote provides the backup guard. Implemented and deployed in `ng-dev`. Acceptance: quote attempt without an Accepted appraisal is rejected with the documented error. Quote attempts with no related trade-in or with `Status__c = 'Accepted'` are allowed. (Detailed acceptance evidence in the `DiscountApprovalTest` run and the `evidence/P3/` artifacts.)

---

## Phase 3 Exit Criteria (M2 Gate) — MET

- Dry-run clean: yes (P3 deploys succeeded).
- Tests ≥90%: **24/24 pass** at Phase 3 close (recorded in the `## Phase 3 — DONE` block above).
- DQ 0 rows: yes.
- UAT_P3+P4 signed: **P4** is signed (P4-01..P4-09 ACCEPTED AND CLOSED, this document §Phase 4 and `NORTHGATE_PROJECT_HANDOFF.md` §11/§12). P3 is signed (this §Phase 3 — DONE).
- Screenshots: not produced by this session (out of closure scope; no deployment, no data changes).
- Tag `demo/v0.2`: **not pushed** during this session (no commits/pushes authorized). The `main` branch remains 1 commit ahead of `origin/main` (the pre-existing Phase 3 commit `638524df`; not pushed).

---

## Phase 4 — Financing, approval and delivery — DONE (P4-01 through P4-09 ACCEPTED AND CLOSED)

See the "## Phase 4 — DONE" block at the top of this document for the full closure record (deploy jobs, deploy IDs, owner browser evidence, backfill evidence, outstanding prerequisites). **The M2 exit gate ("full retail deal runs from lead to delivered vehicle with financing, approvals and loyalty enrolment") is MET** for `ng-dev`. The Phase 4 implementation, tests, layouts, reports, permission sets, queue, approval process, workflow, triggers, and LWCs are present in the working tree as untracked files (see `NORTHGATE_PROJECT_HANDOFF.md` §14). No commits, no pushes were authorized. P4-10..P4-13 remain open for acceptance evidence/sign-off, not data-load blockers.

## Phase 5 — Data load complete; acceptance evidence open

**2026-10-20 readiness clarification:** Phase 5 development is not complete. Executive and
manager dashboards, ledger reconciliation, reset/snapshot safeguards, expected-count report
verification and other backlog criteria remain open. See
`docs/planning/REMAINING_ACCEPTANCE_2026-10-20.md` for the scoped investigation and plan.

Canonical seed load is preserved in `ng-demo`: the 2026-10-19 verification records 2,085
records, 14/14 canonical-scope gates, and 3.00 MB storage. Current `/limits` returns Max 5 MB /
Remaining 1 MB; exact current usage still needs the owner screenshot. `SEED-98` (30 records)
is deferred. The 20 live
ledger rows are placeholders (`Object__c=Mixed`, `Inserted_Count__c=0`); additive
reconciliation proposal is not executed. P5-03 storage evidence is also missing. Do not
run a new canonical load. See `docs/planning/PRE_PHASE5_READINESS_2026-10-20.md` and
`evidence/P5/ledger_design_additive.md`.

Owner Sales Rep browser UAT completed 2026-10-20; evidence: `evidence/UAT/live_2026-10-19/REP_UAT_COMPLETED_2026-10-20.md`. Loyalty and Delivery lists, reports, and dashboard access passed owner checks. Dashboard metric values displayed zero; accuracy remains unverified. Loyalty report description is outdated, nonblocking.

`P3-DEF-01` deployed as exactly `QuoteBuilderController` and `QuoteBuilderControllerTest`.
Check-only `0Afaj00000oNfTyCAK` passed 14/14. Deploy `0Afaj00000oON8LCAW` succeeded
with 14/14 tests. Focused test run `707aj00001McoRy` passed 15/15 results (14 methods plus
`setup`). `scripts/uat/rep_verify.apex` returned `PASS`; one Quote and one QLI remain.
Initial check-only `0Afaj00000oOEWUCA4` failed before baseline restore because no active
`VP_Sales` user existed. After owner UAT and restore, `ngpersona` supplied test precondition.
No PermissionSet or other metadata deployed. Loyalty/Delivery ListViews were deployed
separately as two ListView components (`0Afaj00000oOKSDCA4`). Owner screenshot confirms
Delivery tab already visible; do not deploy a tab change without new evidence.

## Phase 6 — Service, cases and post-sale (Backlog)

## Phase 7 — Developer depth, AI, governance and polish (Backlog)

## Phase 8 — Customer Experience Portal (Backlog, milestone M4)

Experience Cloud + custom LWC only. **React / Salesforce Multi-Framework is excluded** from
Phase 8 (P7-18-only conditional proposal). Depends on P7-18, Phase 5 data and Phase 6
service/loyalty/case builds. **Digital Experiences enablement is NOT authorized and no external
licence model is assumed** — verify before selecting the model. External access is
relationship-anchored with CRUD/FLS checks and cross-customer negative tests (not `with sharing`
alone). Items P8-01..P8-11; architecture in `docs/architecture/EXPERIENCE_PORTAL.md`. No portal
component is implemented. Keep Phase 5 as the next active implementation phase (per the approved backlog).

---

**No ng-demo deployment, Salesforce data changes, role/permission changes, or Setup changes without explicit owner approval.** Phase 4 closure in `ng-dev` is complete. Phase 5 data load is complete, but acceptance evidence and the pre-Phase-5 remediation deploy remain open. No live action is authorized until the owner approves the consolidated request.
