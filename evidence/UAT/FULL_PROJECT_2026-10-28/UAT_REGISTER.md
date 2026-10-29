# Northgate Motors — consolidated Phases 1–8 UAT register

## Decision and scope

**Overall: BLOCKED for full acceptance.** Target verified: ng-demo / 00Daj00001Ae3iWEAR.
**D16 CLOSED — owner visually accepted.** `PS_Executive_Service_Field_Read` was validated
(`0Afaj00000paL8bCAE`), deployed (`0Afaj00000paLbdCAE`, 1/1, zero errors) and assigned only to
`arjun.ngdemo@northgate.demo` (`0Paaj000018MIu2CAG`). Read-only verification found both source
reports now return the three stored fields and FORMULA1, all six org-wide FLS rows for those
fields are Edit=false, and the owner confirms both Executive components (Overdue Service Visits,
CSI Proxy) render correctly under that user. Evidence: `D16_SECURITY_VALIDATION/RESULT.md`,
`D16_DEPLOYMENT/RESULT.md`, `D16_ASSIGNMENT/RESULT.md`. The separate authenticated-describe
`createable/updateable=true` observation is not attributed to this Read-only set and remains an
open non-D16 note, not a reopened defect. No broader release acceptance.
**Latest regression-closure update:** Customer A login and separate A/B vehicle dashboards are
now OWNER-REPORTED scoped PASS; no password investigation repeated. D08 deployed 9/9 through
`0Afaj00000paG2TCAU`, still pending visual acceptance. D16 is now deployed, assigned and
owner-visually accepted (see above/closure section). D06 is server-validated (dry-run
`0Afaj00000paNYbCAM`, 1/1, zero errors) but not deployed and still unassigned/unverified
functionally. D07 remains blocked for actual submit/refresh response evidence. See
`REGRESSION_CLOSURE/RESULT.md` and the final section; earlier failed/readiness/no-deployment
entries retain their historical scope.
**Latest frontend update:** October 28 owner-reported browser results are consolidated in
“Owner frontend UAT consolidation — 2026-10-28” below. Navigation/display and the specifically
reported creates passed only their stated scope; presentation failures and unverified concerns
remain separate. Earlier NOT TESTED entries describe their original execution, not a withdrawal
of these later owner observations. No full workflow, security or project acceptance is implied.
**Later scoped local correction:** D08-a/b/c candidates and six additive contextual list views
are now locally prepared under separate owner authorization; see “D08 local correction package”
at the end. Nothing deployed or browser-verified; original owner failures remain open.
**D08 readiness unblock:** the owner-authorized packaging-only correction and full bundle
comparison now pass; corrected ZIP validated by `0Afaj00000paFMXCA2`, 9/9, checkOnly. READY
for exact-artifact deployment approval only; no deployment or browser-fix acceptance. Details
in `D08_UNBLOCK/RESULT.md`; the earlier failed readiness record remains historical.
**Latest triage:** counts reconciled; D01/D02 are S2 test-fixture/identity-expectation defects,
not demonstrated production authorization bypasses. No immediate security correction is
established. Initial execution classifications below remain scoped to that failed run; the
owner-authorized existing-run triage section supplies the updated causes/dispositions.
No ng-dev access, deployment, code/configuration/permission/record changes, persona switches,
live workflow submissions, schedules, or Git operations. Documentation/evidence only added here.
Apex tests create rollback-only fixtures and Salesforce test-result records; no live business
workflow was submitted. No retries or repairs after failed checks. Server restart did not cause
completed work to be repeated; existing receipts were copied byte-for-byte into raw/.

PASS means only the stated scope passed. A backend PASS is not browser acceptance. FAIL means
observed behavior/assertion failed, not that its production root cause is established. BLOCKED
means an unmet prerequisite or stopped investigation; NOT TESTED means no current execution.
Historical owner acceptance remains intact and is not silently upgraded to current UAT.

Inputs: latest NORTHGATE_PROJECT_HANDOFF.md §§16, 34, 47, 71–78; DEMO_ORG_BACKLOG.md;
actual pricing/controller/approval/LWC/relationship metadata; Phase 5 accepted exceptions;
evidence/P6/PHASE6_OWNER_ACCEPTANCE_2026-10-24.md; Phase 7 23-block final-status index.
Latest owner statements supersede stale planning headers: portal Live and dashboard, vehicles,
booking, service history and My Cases work. P3-DEF-01 is historically completed (§16), not reopened.
No architecture/design changes proposed. Product simulations remain explicitly simulations.

## Executed now — raw evidence index

All raw outputs are in raw/; execution_summary.json retains per-class rows and verbatim failures.

| Check | Current classification | Evidence |
|---|---|---|
| Full deployed local Apex suite | FAIL | raw/apex-test-run.json; run 707aj00001OOD4U |
| Seven local UI/state/static suites | PASS, 48/48; mocks, not browser | raw/local-ui-tests.tap |
| Seven independent zero-count DQ queries | PASS, all n=0 | raw/dq_*.json |
| Duplicate VIN query | PASS, zero duplicate groups | raw/dq_duplicateVin.json |
| Complete strict DQ verifier | BLOCKED, missing canonical CSV | raw/strict-dq.stderr.txt; no completed gate JSON |
| Ten returned core classes vs local source | PASS, normalized text parity | raw/source_parity.json; raw/core_live_source.json |
| Ten active price rules | PASS, inventory only | raw/price_rules.json |
| Three approval definitions | PASS, Active; not new routing UI evidence | raw/approval_definitions.json |
| Existing CP2 Quote 00000069 | PASS, arithmetic/data checkpoint only | raw/cp2_quote.json |
| Portal Live and existing B Visit/Case linkage | PASS, read-only inventory | raw/network.json; raw/b_case_visit_link.json |
| Native dashboard inventory | PASS, presence/type only; rendering NOT TESTED | raw/dashboards.json |
| Knowledge | PASS for ten Drafts; published/search acceptance BLOCKED | raw/knowledge_states.json |
| Territory model | PASS for Planning inventory; operational assignment BLOCKED | raw/territory_model.json |
| Licenses, schedules, storage-limit inventory | PASS, inventory only | raw/licenses.json; schedule_inventory.json; limits.json |
| Authenticated agent browser UAT | NOT TESTED | Browser tabs returned [] before restart |

CONFIRMED — raw Apex summary excerpt:
```json
{"outcome":"Failed","passing":360,"failing":10,"skipped":0,"testsRan":370,"testRunId":"707aj00001OOD4U","orgId":"00Daj00001Ae3iWEAR"}
```
REFUTED — full-suite acceptance. Initial CLI detailed tests array contains 338 ordinary-method
rows and nine Fail rows. Subsequent owner-authorized result-only triage reconciled all 370
ApexTestResult rows: 329 Pass + nine Fail ordinary methods, 31 Pass + one Fail TestSetup.
The additional failure is Batch3ReportingAccessTest.actors (@TestSetup), result
07Maj000008nUmjEAE. Original CLI output remains unchanged; see triage/results.json and
triage/reconciliation.json. No tests were rerun.

CONFIRMED — local UI output:
```text
# tests 48
# pass 48
# fail 0
```
These cover Finance launch context, Test Drive picker, gallery/calculator, photo header, and
portal B/C/broker states. Mocked success is not proof that the comments/loyalty live defects pass.

CONFIRMED — CP2 raw checkpoint excerpt:
```json
{"Id":"0Q0aj000003kVS5CAM","QuoteNumber":"00000069","OpportunityId":"006aj00000fbDI1AAM","Subtotal":50615,"Adjusted_Subtotal__c":43022.75,"Rule_Applied_Count__c":1,"Opportunity":{"Discount_Percent__c":15,"Approval_Status__c":"Pending"}}
```
50,615 − 43,022.75 = 7,592.25 = 15%. This does not repricing-test an aged record or prove a
current pending work item. Do not change its Pending stamp or reconcile history automatically.
Approval work-item output currently contains ten Knowledge targets; no action was taken on them.

Independent DQ probes: invalid VIN, won without delivery, finance rate/term, negative loyalty,
completed Visit zero cost, revoked consent missing date, nonpositive non-Prospecting Opportunity
all returned n=0. These eight probes including duplicate VIN do not replace the strict full gate,
seed identity/provenance reconciliation, legacy-fixture audit or complete relationship integrity.
API limits show DataStorageMB max=5/remaining=1, rounded; exact <=4.0 MB acceptance remains BLOCKED.

## Overall coverage by phase

| Phase | Historical baseline | Current UAT disposition |
|---|---|---|
| 1 Foundation/security | Recorded complete | Automated VIN/security subchecks PASS; actual-persona matrix NOT TESTED; full security gate BLOCKED |
| 2 Lead-to-opportunity | Earlier M1 evidence; connected walkthrough unverified | Automated subchecks retained; owner navigation and Sales Test Drive 74 positive booking PASS; conversion/Task save not executed; email test FAIL |
| 3 CP2/quotes/approvals | Owner-accepted; quote-overwrite repair completed | Automated checks retained; owner CP2 display and Trade-In 52 create/equity PASS; print presentation FAIL; approval submission not executed |
| 4 Finance/delivery | P4-01–09 accepted; later items retained | Automated checks retained; owner Finance 64 create/amount and Delivery navigation PASS; conflicting banners FAIL; departmental lifecycle/handoff untested |
| 5 Data/reporting | Owner-accepted with exceptions | Eight DQ probes PASS; owner report/dashboard visual review recorded, not metric reconciliation; strict gate/storage BLOCKED; Executive layout FAIL |
| 6 Post-sale | Owner-accepted with P6-E01–E14 | Automated checks retained; owner Service/Loyalty/Consent displays recorded; future-date/ledger/consent concerns UNVERIFIED; fixtures/operational gates unchanged |
| 7 Developer/governance/polish | Deployed, not fully owner-accepted | UI mocks and owner Inventory/Models/Rooftops navigation PASS; photo presentation FAIL; full regression FAIL; integrations/events/native gates remain |
| 8 Owner Portal | Owner-confirmed working paths | Existing smoke workflows PASS (owner evidence); loyalty/comments FAIL; negative-security certification BLOCKED; visual review NOT TESTED |

## Complete feature checklist (original backlog IDs retained)

Grouped IDs share the stated classification; browser and automated scope are separated. No item
is deemed fully accepted solely because its class passed. Original acceptance criteria still apply.

| Backlog feature(s) | Current status and scope | Remaining owner expectation |
|---|---|---|
| P1-01–06 objects/fields/relationships/picklists/record types/layouts | NOT TESTED as a complete live inventory | Correct required fields and layouts; no hidden finance leakage |
| P1-07–12 apps/roles/OWD/queues/sets/groups | NOT TESTED as complete persona UAT | Each actual persona sees its intended app/scope only |
| P1-13–14 bypass/sharing | NOT TESTED live; historical evidence retained | Bypass remains restricted; no unintended customer scope |
| P1-15 users/licenses | BLOCKED for missing operational-persona readiness; license inventory PASS | Four of four Salesforce licenses used; no admin reclamation or persona reassignment |
| P1-16–19 rules/duplicates/metadata/security matrix | NOT TESTED in full; individual suite checks not a complete matrix | Every original rule/negative FLS and matrix row needs evidence |
| P1-20 VIN validation | PASS, VinValidatorTest 5 returned methods | UI validation errors still need screenshots |
| P1-21 persona switch | NOT TESTED; prohibited in this read-only task | Separate approval for any role/group swap |
| P1-22 CI client/release authentication | NOT TESTED; historical only | Owner-controlled credentials and actual CI evidence |
| P2-01 routing | PASS automated: routing/enrichment/round-robin | Actual Lead intake UI NOT TESTED |
| P2-02 conversion | PASS automated: LeadConvertGuardTest 2 | Account/Contact/Opp creation and seed-tag hygiene UI NOT TESTED |
| P2-03–04 Test Drive/conflict | PASS automated: booking guard 9; picker mocks; owner Sales booking Test Drive 74 PASS | Overlap rejection/contention and admin search-error cause UNVERIFIED; positive booking is not the conflict gate |
| P2-05 stage stamps | PASS automated: 3; eight live stages inventoried | Connected stage progression UI NOT TESTED |
| P2-06 reservations | PASS automated: guard 2 | Competing reservations/live UI NOT TESTED |
| P2-07 Tasks | Owner Task creation form open PASS; save NOT TESTED; 10 follow-up methods pass but companion email method FAIL | Saved Task, automatic creation, correct owner/due date remain untested live |
| P2-08 confirmation email | FAIL automated restricted-email assertion | Exact error D04; delivery remains NOT TESTED |
| P2-09–11 reports/sales dashboard | NOT TESTED as actual readers | Report totals/drill-through and differing rep/manager scope |
| P2-12 counters | PASS automated reconciliation/trigger checks | No live maintenance/enqueue; operational UI NOT TESTED |
| P2-13 suite/bulk gate | FAIL for complete slice (email assertion); P2BulkTest 2 pass | No >=90% coverage claim from this run |
| P2-14–15 slice UAT/demo | NOT TESTED current end-to-end | Current persona-first script, no historical ng-dev instructions |
| P3-01 appraisal/equity | PASS automated: TradeIn_Calc_EquityTest 4; owner Trade-In 52 create/display PASS, equity $9,000 | Wizard path not specified; five-case/negative-equity browser coverage and accepted-appraisal gate not established |
| P3-02 appraisal-before-quote | PASS automated: trade-in guard 7/enforcement 6 | Rejected unaccepted appraisal UI NOT TESTED |
| P3-03 price rules | PASS current inventory: ten active | Preserve rules and actual winner/precedence semantics |
| P3-04–05 builder/pricing | PASS automated: builder 14/pricing 23; CP2 saved-data checkpoint and owner Quote 00000069 display PASS | Fresh UI save/pricing NOT TESTED; one-quote guard preserved |
| P3-06 approval routing | PASS automated: DiscountApprovalTest 6; both definitions Active | <=5 no approval, >5–10 manager, >10 VP; live cross-persona routing NOT TESTED |
| P3-07 Quote Summary/PDF | PASS automated summary 11; owner totals display PASS; print-preview presentation FAIL (D08-a) | Print/PDF layout acceptance outstanding; full line/signed-premium coverage not established |
| P3-08–10 validity/reports/Quote Health | NOT TESTED current UI | Expiry filter and source/report/tile reconciliation |
| P3-11 simulation seam | NOT TESTED current document acceptance; historical delivered | Custom CPQ simulation, not licensed CPQ |
| P3-12 pricing tests | PASS methods; coverage percentage NOT TESTED | No current >=90% coverage certification |
| P3-DEF-01 quote overwrite | PASS historical repair retained; builder tests pass now | Do not reopen or save another quote on the historical record |
| P4-01 calculator | PASS automated 5 | Cent-accurate payment at 0%, normal/high rates |
| P4-02 application | PASS automated 23; 4 launch-context mocks; owner Finance 64 create/$43,022.75 display PASS; reopening banners FAIL (D08-b) | Full applicant/rate/term/payment behavior, draft persistence/idempotency and compliant Finance-persona acceptance remain incomplete |
| P4-03 lifecycle | PASS automated 18 | Invalid funded transition UI NOT TESTED |
| P4-04 rates | PASS automated 5 | Table/manual exception source preserved |
| P4-05 finance approval | PASS automated 8; definition Active | Actual Finance identity/routing browser gate BLOCKED |
| P4-06–08 delivery/Closed Won/enrollment | PASS automated guards 4/close 9/enrollment 4; owner Delivery list/completed detail/New form open PASS | Lifecycle controls and connected completion/enrollment not functionally tested; no reenrollment/backfill |
| P4-09–10 reports/deal desk | Owner visual report/dashboard inspection recorded; Finance report result sets empty; accuracy UNVERIFIED | Reconcile exact filters/source population/reader scope; empty sets are not a demonstrated defect |
| P4-11 finance FLS | PASS automated 2 | Actual Sales session negative-field screenshot NOT TESTED |
| P4-12 finance seam | NOT TESTED current doc acceptance; historical delivered | Simulation limitation retained |
| P4-13 coverage gate | NOT TESTED >=90%; relevant methods PASS | Coverage run not requested/retried after failures |
| P5-01–02 generator/loader repeatability | NOT TESTED current; historical exceptions retained | Do not regenerate or reload missing seed assets |
| P5-03–07 volume/integrity/ledger/BAD/legacy | BLOCKED complete evidence; accepted exceptions retained | Canonical files, exact storage and historical provenance required |
| P5-08 release DQ | BLOCKED missing CSV; eight independent probes PASS | Full strict gate remains unmet |
| P5-09–16 findings/reports/dashboards/report types | Owner ten-priority-report/nine-dashboard visual review recorded; values below; Executive layout FAIL (D08-c); metric parity UNVERIFIED | Exact report IDs/filter dates/reader scopes/drill-through need reconciliation; do not force historical counts |
| P5-17–19 reset/snapshot/burst | NOT TESTED current; destructive rehearsals BLOCKED | Separate exact-record destructive authorization; never run here |
| P5-20 data-plan status | PASS historical acceptance documentation read | Does not certify current counts or exact storage |
| P6-01 capacity | PASS automated 15 | Multi-session contention/live capacity UI NOT TESTED |
| P6-02 intake Case | PASS automated 2; B existing link PASS current inventory/owner | No new booking required |
| P6-03 escalation | PASS automated 7; live native timer NOT TESTED | Four-hour event/notification/history evidence pending |
| P6-04–05 Case/Vehicle history | PASS automated 2/3; owner portal history PASS | Internal placement/mileage rendering NOT TESTED |
| P6-06–08 accrual/tier/redemption/expiry | PASS automated; live processing BLOCKED by inactive program/operational approval | Preserve historical balances; no jobs/activation |
| P6-09 service/loyalty dashboards | BLOCKED reporting-access test fixtures; owner visual review recorded; differing overdue metrics UNVERIFIED | D03 is not report access denial; reconcile definitions/as-of dates/reader scope before declaring metric defect |
| P6-10 loyalty seam | NOT TESTED current document acceptance; historical delivered | Inactive/custom engine and provenance limits retained |
| P6-11 repeat-purchase signal | PASS automated 1; current report UI NOT TESTED | Completed service plus explicit buyer/open Opportunity, not inferred chronology |
| P6-12 consent/nurture | PASS automated consent 5/audience 3; live positive flow NOT TESTED | Exact tuple, opt-out/deny precedence; no real sender/journeys |
| P6-13 nurture seam | NOT TESTED current document acceptance; historical delivered | No licensed Marketing Cloud claim |
| P6-14 SLA/milestones | PASS automated 4; live enrollment/clocks BLOCKED | 4/48 business hours, not elapsed hours; activation approval needed |
| P6-15 Knowledge | BLOCKED published/search/Case use; ten Drafts PASS inventory | Do not publish/attach or replay import |
| P6-16 dual-role consoles | NOT TESTED; actual operational identities BLOCKED | Correct app access and navigation as actual persona |
| P6-17 tests/coverage | BLOCKED complete gate; reporting test setup FAIL | Historical 181/181 and 34/34 remain historical |
| P7-01 gallery | PASS backend 5/state mocks; browser NOT TESTED | Photos/filtering/permission errors; reservation write separately gated |
| P7-02 calculator widget | PASS automated 2/state mocks; placement NOT TESTED | Correct payment/equity; existing services reused |
| P7-03 VIN transport | PASS mocked decoder 2; live transport BLOCKED | Endpoint/credential/principal acceptance, no real decoder claim |
| P7-04 API contract | NOT TESTED current acceptance; historical delivered | Contract/error/auth/no-write seams stay explicit |
| P7-05 reservation events | PASS automated 2; multi-session UI NOT TESTED | Delivery/refresh/reconnect acceptance needs controlled later write |
| P7-06 CDC/Pub-Sub seam | NOT TESTED current acceptance; documentation only | No external subscriber/CDC guarantee |
| P7-07 handlers/bulk/bypass | PASS architecture methods 8; full regression FAIL elsewhere | Do not alter established trigger structure |
| P7-08 reconciliation | PASS automated 4; live execution NOT TESTED | No live enqueue, repair or schedule |
| P7-09–10 governance/debt | PASS historical documents reviewed | Existing exceptions remain in this register by reference |
| P7-11 permission audit | NOT TESTED actual report/browser | No unused-permission or revocation inference |
| P7-12 territories | BLOCKED operational assignment/activation; Planning model PASS inventory | No identity/association/activation changes |
| P7-13–14 strategy/seams | NOT TESTED current document acceptance; historical delivered | No architecture redesign or new licensed products |
| P7-15 Agentforce/prompt | BLOCKED per retained capability/activation gates | Draft prompt is not a running agent; no activation |
| P7-16 Data Cloud | BLOCKED per retained feature/space/ingestion gates | No enabling/ingestion/identity experiment |
| P7-17 regression/release | FAIL Apex; BLOCKED strict DQ/clean release | No dry-run/deployment wrapper or Git actions executed |
| P7-18 portal capability | PASS owner login/live inventory (supersedes old disabled-site status) | Detailed acceptance governed by P8 rows |
| P7-19 Automotive mapping | NOT TESTED current acceptance; documentation-only scope | No Automotive Cloud build |
| P7-20–21 README/demo pack | NOT TESTED full five-persona live walkthrough | No clean-release or demo sign-off claim |
| P7-22 photos | Historical resource validation retained; owner vehicle identity/colour mismatch reported FAIL presentation (D08-d) | Verify specific record/image against amended stock-likeness criterion; no exact OEM/colour guarantee inferred |
| P7-23 photo header | PASS six state mocks; placement/mobile/browser NOT TESTED | With/without-photo fallback and label review |
| P8-01 site | PASS current Live inventory; owner reports both A and B login success | No reactivation/publication or password-reset investigation needed; not full portal/security acceptance |
| P8-02 access/isolation | BLOCKED complete certification by new negative-test failures | Prior sampled A/B denials retained as historical, not withdrawn or treated as exhaustive |
| P8-03 controller tests | FAIL current full suite; comments/loyalty known defects | Exact failures below; no speculative permissions |
| P8-04 dashboard | PASS owner-confirmed; state mocks PASS | New desktop/mobile visual review NOT TESTED |
| P8-05 vehicles | PASS owner-confirmed A/B separate vehicle/dashboard displays; broker tests partly FAIL; full UI review NOT TESTED | Positive separation is not foreign-ID/native/same-Account denial; labels/photos/fallback and ownership negatives still gates |
| P8-06 service history | PASS owner-confirmed and current existing Visit/Case inventory | Requested October 29 Visit/Case 00001102; do not reopen repair |
| P8-07 booking | PASS owner-confirmed positive workflow; FAIL current negative automated assertion | Both results retained; no further booking submissions |
| P8-08 Case tracking/status | PASS owner-confirmed My Cases | Keep Case native writes denied; separate native creation is intentionally unavailable |
| P8-08 published comments | FAIL owner observation; backend cause BLOCKED | Capture existing failed action response; no duplicate retries |
| P8-09 loyalty | FAIL confirmed transaction Read/FLS defect; fix deferred | Legitimate no-membership empty state; no fabricated records |
| P8-10 responsive/branding/accessibility | NOT TESTED actual browser; static/state mocks PASS | Mobile/desktop, keyboard/focus, labels/photos/contrast |
| P8-11 demo/UAT/seam | NOT TESTED full walkthrough/sign-off | This checklist is preparation, not acceptance |

## Consolidated defect and acceptance-gap register

Severity: S1 release/security gate; S2 material functional/acceptance blocker; S3 polish/provenance.
Severity indicates priority, not proof of a production exploit. Known historical exceptions remain
accepted exceptions, not silently repaired defects. Full original P5 exceptions and P6-E01–E14
remain incorporated; this register is their consolidated current index, not a replacement waiver.

| ID | Severity / phase / status | Evidence | Proposed resolution after testing |
|---|---|---|---|
| D01 | S2 / P8 / FAIL test; clock-dependent fixture expectation, not demonstrated authorization exposure | OwnerPortalVehicleBrokerTest.bookingIsIdempotentAndReusesCapacityAndIntake: `System.AssertException: Assertion Failed: Unauthorized request accepted`; helper 73/caller 143. The capacity probe uses now()+3 days and +1 hour, crossing Toronto midnight in this run | Future approved test-only correction: deterministic same-Toronto-day capacity fixture plus explicit cross-day acceptance case. Preserve bookFor and daily-capacity implementation |
| D02 | S2 / P8 / FAIL tests; incorrect invoking-user assumptions, not demonstrated authorization exposure | Ownership test line 199 expects isReviewer=false outside runAs; reconciler test line 24 expects denial as the test-running user. User 005aj00000feqbNAAQ is Standard and has approved Reviewer assignment 0Paaj000018BQuvCAG in pre-UAT baseline and current grants | Future approved test-only correction: explicit restricted internal runAs identity without reviewer permission and an explicit reviewer positive case. Do not revoke legitimate assignment or weaken guard |
| D03 | S2 / P6/P8 / BLOCKED by test-infrastructure contention | Five ordinary method failures plus one @TestSetup failure return the same UNABLE_TO_LOCK_ROW on 0D1aj000002LZpdCAG. Live fixture lines all insert UserRole; two reporting methods inherit the failed actors setup | Likely shared role/setup-lock contention, not a failed production assertion. Later authorize isolated/serial verification; no rerun now and no guarantee of serial success |
| D04 | S2 / P2 / FAIL test; over-specific email-counter expectation | TestDriveFollowUpTest.restrictedBookingCreatesOwnedTaskAndKeepsEmailHidden line 140: `System.AssertException: Assertion Failed: Single Email permission denial occurs before an email invocation is counted: Expected: 0, Actual: 1`. Earlier absence-of-Single-Email/authorized-booking assertions passed | Counter proves a Messaging.sendEmail attempt, not delivery or FLS exposure. Future approved test diagnosis should assert an observable send outcome and independent booking/field-visibility contract; no permission broadening or simple forced-pass expectation change |
| D05 | S2 / P5/P7 / BLOCKED; canonical directory absent, resolved derivative cannot substitute | `FileNotFoundError: [Errno 2] .../data/csv/01-rooftops.csv` in phase5.py verify line 448/read_csv line 62. New read-only inventory: `data/csv` absent/untracked, but `data/csv-resolved` matches the 27-object envelope exactly (2,085 records; 26/27 seed-tag columns; OLI handled via parent query). Resolved bundle is a downstream `--resolve` derivative with substituted IDs, so not canonical. No snapshot digest manifest present. `D05_CANONICAL_INPUTS/RESULT.md` | Restore canonical `data/csv/` bytes for the 27 expected files (plus snapshot manifest if retained); do not substitute `csv-resolved`, regenerate or reload live data to force parity |
| D06 | S2 / P8 / **DEPLOYED 2026-10-29; permission verification PASS; functional/browser acceptance outstanding** | Deployment `0Afaj00000pafVVCAY` Succeeded 1/1, zero errors; exact delta is `Loyalty_Transaction__c` Read + `Points__c`/`Type__c` Read=true/Edit=false only; all prior grants, Apex class access and both assignments unchanged. Guest `/owners/s/` redirected to login with no customer data. A/B authenticated browser tests SKIPPED (no sessions). Controller `with sharing` + `USER_MODE`, caller contact from `User.ContactId`, member and transaction filters contact-scoped. Transaction OWD `ControlledByParent`, member external OWD `Private`, zero share rows/SharingSets, no View All/Modify All on A/B. A/B on different Accounts and neither has a loyalty member. `D06_DEPLOYMENT/RESULT.md` | Remaining: A/B empty-state browser check; own-member positive; foreign direct-ID denial; same-Account sibling; write denial; pagination. Positive/tile acceptance needs a member-bearing contact or approved test-only fixture. D06 is not fully closed |
| D07 | S2 / P8 / FAIL, actual backend cause BLOCKED | Prior zero rows/duplicates and effective permission evidence retained. Three new local diagnostic mocks confirm submit rejection and successful-submit/failed-refresh share the current generic error; no LWC/source fix | Obtain original addComment/getComments action responses, returned ID, Case/persona/time; no duplicate submit, broad Case permission or speculative fix. Coordinate any later UI correction with Expansion |
| D08 | S3 / P3–5/P7/P8 / PARTIAL FAIL presentation, owner-reported; remaining review NOT TESTED | Oct 28 owner browser observations: a Quote print-preview layout; b existing/new-draft conflicting banners; c Executive dashboard overlap/unreadability; d photo identity/colour mismatch. Details and limits below; model-year/numeric-name concerns not yet proven defects | One consolidated presentation backlog, D08-a–d; capture exact screenshot/viewport/record/asset and approve narrow fixes separately. Preserve CP2, draft/approval state and stock-likeness scope; mobile/focus/P8 review remains open |
| D09 | S2 / P1/P4/P6 / BLOCKED | Current licenses Salesforce 4/4 used; retained operational Service/Finance/dual-role identity gaps | Owner designate existing compliant actual persona sessions; do not reclaim Admin, create users or swap roles/groups here |
| D10 | S2 / P5/P6 / BLOCKED or NOT TESTED by exception | P5 closure exceptions; P6-E01–E14; Draft Knowledge/Planning territory confirmed now | Explicit disposition for live loyalty/jobs, SLA/escalation timers, Knowledge publication, consent positive scenario, timezone and concurrency; no activation implied |
| D11 | S2 / P5–7 / BLOCKED full reporting/data release gates | Rounded storage only, missing canonical bundle, historical ledger/balance provenance; remaining report/tile/persona parity not tested | Supply exact Storage Usage evidence and canonical bundle; run separately approved complete read-only reconciliation; no historical backfill |
| D12 | S3 / P5/P6 / FAIL historical accepted display exception | CSI shows zero rather than N/A with zero responses; stale publisher metrics suppress after 24h; remaining drill-through gaps | Reproduce actual-reader display, then batch validated reporting-only fixes; do not fabricate responses or schedule publisher |
| D13 | S2 / P7 / BLOCKED | Retained VIN credential/transport, Agentforce, Data Cloud, territory and page-placement gates | Owner capability/placement decisions separate from safe code/FLS batch; no enabling/reconfiguration here |
| D14 | S2 / P7/all / NOT TESTED release/demo acceptance | No current full persona walkthrough, clean-source/release gate; no fresh deployment validation or coverage collected | Finish UAT, review narrowly scoped fixes, then separately approve validation/release; no Git operation here |
| D15 | S3 / test evidence / PASS reconciliation, CLOSED | Result-only Tooling API query returns 370 rows: ordinary 329 Pass/9 Fail; @TestSetup 31 Pass/1 Fail. Missing CLI detailed failure is Batch3ReportingAccessTest.actors, 07Maj000008nUmjEAE | No correction needed. Preserve original raw output and triage/results.json; no test rerun |
| D16 | S2 / P5/P6 Executive reporting / **CLOSED — owner visually accepted 2026-10-28** | Validated `0Afaj00000paL8bCAE`; deployed `0Afaj00000paLbdCAE` 1/1 zero errors; assigned `0Paaj000018MIu2CAG` to `005aj00000feqbNAAQ` only. Read-only follow-up: both report describes now return the three stored fields + FORMULA1 (previously `CDF1`/`RowCount` only); six org-wide FLS rows, all Edit=false. Owner confirms Overdue Service Visits and CSI Proxy render correctly. `D16_ASSIGNMENT/RESULT.md` | No further D16 action. Preserve deployed set and exact-user assignment. The unrelated `createable/updateable=true` describe observation is not attributed to this Read-only set and is not a D16 blocker or overall Read-only claim |

D03 exact methods: OwnerPortalFoundationControllerTest.permittedCustomersReadOnlyTheirOwnContactInUserMode
(fixture line 14/caller 51); realPlusUserWithoutPermissionOrSiteFailsClosed (108);
Batch3ReportingAccessTest.liabilityUsesStoredBalanceAndDoesNotReconstructHistoricalLedger and
viewerScopedServiceReadDiffersBetweenAdvisorAndManager (actors line 4);
OwnerPortalBatchBControllerTest.contactScopeCannotBeSubstitutedAndEmptyIsSafe (fixture 6/caller 48).
Verbatim messages, stack traces, result IDs and AsyncApexJobId 707aj00001OOD4UAAX are retained in
execution_summary.json and raw/apex-test-run.json. Later result-only triage adds the missing
@TestSetup result without editing original evidence. Diagnoses and limits follow.

## Owner-authorized existing-run triage — no tests rerun

Scope: only run 707aj00001OOD4U and the named failure paths; no CP2 or accepted-workflow
investigation. Twelve relevant deployed test/production class bodies match local source after
terminal-whitespace normalization (triage/live_sources.json). New files are read-only query
receipts/derived documentation only; no code, fixture, assignment or record changes.

### Counts — CONFIRMED

Tooling ApexTestResult query for AsyncApexJobId 707aj00001OOD4U returns:
```json
{"total":370,"outcomes":{"Pass":360,"Fail":10},"ordinaryMethods":{"Pass":329,"Fail":9},"testSetup":{"Pass":31,"Fail":1}}
```
Missing detailed CLI failure:
```json
{"Id":"07Maj000008nUmjEAE","class":"Batch3ReportingAccessTest","method":"actors","IsTestSetup":true}
```
CLI filtered setup results from its tests array, not from its summary totals. Five ordinary lock
failure rows represent three direct fixture failures plus two reporting methods blocked by one
failed setup. Counting the setup yields six lock-error result rows, not six independent defects.
ApexTestRunResult's stored summary fields differ from final result-row totals; final per-result
rows reconcile the original CLI summary exactly. No stale summary was rewritten or rerun.

### Failure matrix (all ten result rows)

| # | Test/result | Assertion/failure location | Affected production boundary | Classification / likely cause |
|---|---|---|---|---|
| 1 | OwnerPortalVehicleBrokerTest.bookingIsIdempotentAndReusesCapacityAndIntake | cannotBook helper 73, caller 143: Unauthorized request accepted | OwnerPortalVehicleBroker.bookFor → ServiceVisitCapacityGuard.validate/localDay | S2 test fixture. Failure is a capacity probe after ownership+independent service authorization were verified, not a foreign/no-consent request. now()+3d then +1h straddle Toronto dates |
| 2 | OwnerPortalOwnershipTest.bulkPendingDoesNotGrantOwnershipAndUnapprovedInternalCannotReview | line 199: Expected false, Actual true | OwnerPortalOwnershipService.isReviewer; verify(null) is not reached | S2 invoking-user expectation. runAs(actor()) has ended; approved Standard Reviewer run user correctly returns true |
| 3 | OwnerPortalShareReconcilerTest.unapprovedInternalCannotStartMaintenanceOrScheduleWork | line 24: generic assertion after reconcileNow(empty set) returns | OwnerPortalShareReconciler.reconcileNow → requireReviewer → isReviewer | S2 invoking-user expectation. Authorized Reviewer passes guard and empty-set prune returns. Later start/schedulable negative assertions are not reached; no maintenance job is launched by this failed method |
| 4 | OwnerPortalFoundationControllerTest.permittedCustomersReadOnlyTheirOwnContactInUserMode | isolatedCustomers fixture 14/caller 51: UNABLE_TO_LOCK_ROW | contextForSite/own-Contact USER_MODE assertions not reached | S2 infrastructure BLOCKED: insert UserRole, common setup-lock ID |
| 5 | OwnerPortalFoundationControllerTest.realPlusUserWithoutPermissionOrSiteFailsClosed | fixture 108: UNABLE_TO_LOCK_ROW | getContext authorization assertions not reached | Same contention class, before external-user construction/controller invocation |
| 6 | OwnerPortalBatchBControllerTest.contactScopeCannotBeSubstitutedAndEmptyIsSafe | customers fixture 6/caller 48: UNABLE_TO_LOCK_ROW | Batch B requireCaller/contact-filtered dashboard/history/cases boundaries not reached | Same contention class, insert UserRole |
| 7 | Batch3ReportingAccessTest.actors (@TestSetup; omitted CLI detailed row) | line 4: UNABLE_TO_LOCK_ROW | Reporting actor setup; no production report/member visibility assertion | Same contention class, insert manager UserRole |
| 8 | Batch3ReportingAccessTest.liabilityUsesStoredBalanceAndDoesNotReconstructHistoricalLedger | inherited actors line 4 failure; no method assertion executed | USER_MODE stored-balance/liability query, no production controller call | Consequence of #7, not a distinct liability-calculation defect |
| 9 | Batch3ReportingAccessTest.viewerScopedServiceReadDiffersBetweenAdvisorAndManager | inherited actors line 4 failure; no method assertion executed | USER_MODE Service Visit visibility query, no production controller call | Consequence of #7, not proof of sharing/reporting exposure |
| 10 | TestDriveFollowUpTest.restrictedBookingCreatesOwnedTaskAndKeepsEmailHidden | line 140: EmailInvocations Expected 0, Actual 1 | TestDriveFollowUp.onCreate → sendConfirmation → Messaging.sendEmail | S2 over-specific platform telemetry expectation; one attempt does not establish email delivery or hidden-field disclosure |

### Booking evidence — CONFIRMED source/date mismatch, not a security bypass

The failing line 143 uses f.noConsent only after line 141 has verified its Service_Authorization;
its Ownership was already verified by fixture line 54. It is therefore an authorized vehicle at
the time of the capacity check. The earlier conflicting-idempotency/same-time probes did not fail.

Run failure timestamp 2026-10-28T03:05:22Z corresponds approximately to fixture start+3d at
2026-10-30 23:05 Toronto; start+1h is 2026-10-31 00:05 Toronto. Exact Datetime.now was not logged;
the method duration is 5.586 seconds, far from the remaining midnight boundary margin. See
triage/reconciliation.json for timezone calculation and explicit timestamp-proxy limitation.
ServiceVisitCapacityGuard.localDay groups by America/Toronto day, not rolling 24 hours or hour
slots. One booking on each date with capacity=1 is allowed. The helper message is misleading:
this particular probe should not describe acceptance as unauthorized. No production capacity,
ownership, consent or Contact-scope correction is supported by this failure.

### Reviewer evidence — CONFIRMED incorrect unapproved-user assumption

Run user 005aj00000feqbNAAQ is Standard. Assignment 0Paaj000018BQuvCAG grants permission set
0PSaj00000hErrhGAC (PS_Owner_Portal_Entitlement_Reviewer). It is already present in the saved
pre-UAT assignment snapshot, not merely discovered as a later grant. SetupEntityAccess connects
that set to custom permission 0CPaj000000tf8zGAA, Manage_Northgate_Vehicle_Entitlements.
OwnershipService.isReviewer explicitly requires Standard AND that permission. The tests use the
ambient approved user where an unapproved identity is required. Current scoped query found this
Reviewer assignment only on the internal run user, not A or B; external user type also fails the
Standard predicate. This is not evidence of an external or unapproved caller gaining Reviewer.
No reviewer privilege was removed or production endpoint executed during triage.

### Row locks — CONFIRMED fixture failure; contention mechanism likely

All direct stacks stop at UserRole insertion; the same 0D1aj000002LZpdCAG lock occurs across
classes in the same run. Reporting @TestSetup waited 5.058 seconds and failed; its two ordinary
methods have null runtime in Tooling results and inherit that setup error. Other direct fixture
failures took about five seconds. This supports test role/setup-resource contention, not a
functional business assertion. Exact lock holder/internal resource is not recorded; no serial
rerun or lock-holder proof was obtained. Tests remain BLOCKED for their unexecuted assertions,
not PASS. Do not attribute the internal lock to a customer record or edit business data.

### Restricted email — CONFIRMED counted attempt; delivery outcome unobserved

Before line 140, the test proved the restricted user lacks Single Email permission, authorized
booking succeeds, and the Contact is visible. Production intentionally checks Contact record
Read using USER_MODE before reading notification-only fields with SYSTEM_MODE, then calls
Messaging.sendEmail and catches exceptions to preserve the booking. Limits.getEmailInvocations
counts the attempt in this run; the test assumes denial must happen before counting. That
counter is not a send-success result, inbox receipt, user-facing FLS grant or returned Contact
Email. Later hidden-Email and Task assertions are skipped by this assertion failure and cannot
be counted as passing in this method. ApexLogId is null for the failed results, so no original
Messaging error/result trace is available. No live email was sent by triage and no separate
email-FLS/security correction is established. Correct future tests must preserve the actual
notification contract, not simply change Expected 0 to Expected 1 to manufacture a pass.

### Immediate security correction decision

**None established by this run's failures.** D01/D02 are downgraded from presumed S1 investigation
priorities to S2 test-reliability defects with specific source/effective-grant evidence. This is
not blanket security acceptance: the unexecuted negative paths still need deterministic fixtures
and future separately authorized verification. D03 is test infrastructure; D04 is a counter-contract
failure with send outcome unknown. Existing unrelated Loyalty/comments defects stay deferred and
are not classified as newly proven security exposure. No CP2 investigation or repair is reopened.

## Ordered owner UAT — expected results

**Read-only steps can proceed.** Use the actual already-provisioned persona, not Admin as a
substitute; do not run persona.sh. Record username/persona, timestamp, record ID, expected/actual
and screenshot for each step. Do not edit canonical/history/CP2 records or click Save/Submit.

1. **FIRST: Sales persona, existing CP2 Quote 00000069.** Open
   `https://orgfarm-25065ad46a-dev-ed.develop.lightning.force.com/lightning/r/Quote/0Q0aj000003kVS5CAM/view`.
   Expected Quote Summary: subtotal CAD 50,615.00; adjusted CAD 43,022.75; one rule; net discount
   15%; linked Opportunity 006aj00000fbDI1AAM. Compare line totals and browser print preview.
   Do not save, re-price, submit, approve or change the existing Pending stamp. If actual Sales
   access is unavailable, record BLOCKED; do not grant access or use Admin to claim Sales PASS.
2. **Sales connected read-only trail.** Follow existing Lead/Contact/Opportunity/Test Drive/Vehicle
   links, stage history, related Tasks, Quote and approval history. Expected real relationships,
   appropriate app/tabs and no finance-only fields. Eight stages must match the implemented model.
3. **Approval review as the existing legitimate approver.** Read approval history/available inbox,
   identify actual ActorId/submitter, compare displayed amount/discount/status. Expected existing
   manager/VP ownership, no self-approval. Lack of a suitable existing example = NOT TESTED, not
   permission failure. Do not click Approve/Reject/Recall or alter any pending Knowledge work item.
4. **Finance → delivery trail, with actual authorized sessions.** Read an existing Financing record
   and its Quote, principal/rate/term/payment, then Delivery checklist, Closed Won flag/date and
   linked Loyalty Member. Expected cent-accurate displayed payment, links and departmental FLS.
   If no compliant Finance session exists, mark BLOCKED; do not switch users' roles or assignments.
5. **Service existing Visit/Case.** Use B's existing Visit/Case 00001102 to inspect queue, Contact,
   Vehicle, Requested status and history. Internal Advisor views require that actual persona.
   Expected own links and no unauthorized fields; do not complete/reschedule the Visit.
6. **Reports/dashboards.** Open Sales, Finance, Service, executive and loyalty reports as the
   intended readers; compare report rows/totals to tiles and drill-through visibility. Distinguish
   stale/absent metric data from true zero; no-response CSI should not imply zero satisfaction.
   Do not click a publisher action, enqueue a job or change a running user/folder share.
7. **Portal B existing positive paths (retain prior PASS).** Read dashboard, vehicles, existing
   booking/history and My Cases. Expected existing October 29 Requested Visit and Case 00001102;
   no new booking, Case or comment submission. Loyalty remains known FAIL; do not create a member.
8. **Portal A/guest negative viewing.** In separate already-authorized sessions, attempt read-only
   access to B's known Case/Visit URLs and portal panels. Expected denial/no B data and no guest
   customer data. Native Case writes must remain unavailable. Do not attempt actual DML.
   This supplies browser evidence but does not waive D01/D02's unresolved automated failures.
9. **UI/UX sweep.** At desktop and mobile widths, inspect gallery/portal/header photos and text,
   licensed stock likeness, loading/empty/error states, missing-image fallback, keyboard order,
   focus, accessible labels/contrast, and October 29 Toronto date rendering. Record actual defects;
   no page activation/layout change or new third-party assets.
10. **Documentation-only demo review.** Read current persona-first scripts and simulation seam
    labels; mark unavailable native demonstrations BLOCKED rather than representing them as live.

### Later workflow gates — NOT AUTHORIZED TO EXECUTE in this task

After exact test-record/identity approval, owner runs a controlled Lead → routing → conversion →
Test Drive/free-vs-overlap → reservation/competing reservation → appraisal/accepted gate → Quote
→ tiered approval → financing → delivery → loyalty-enrollment chain. Expected boundaries:

- CP2: metadata precedence/winners, unique primary Vehicle_Trim basis, signed premium/discount,
  correct rounding; blocked ambiguous basis makes no stamps; second Quote blocked without
  changing previous Opportunity/Quote approval data. Do not reuse historical CP2 exception rows.
- Approvals: <=5% does not require discount approval; >5 through exactly 10% manager; >10% VP;
  no self-approval, individual actor routing, approve/reject field write-back and locks consistent.
- Finance: table/manual rate source, valid term/rate, submitted/conditional/approved/funded guards;
  no funding without required approval; Sales cannot read Annual_Rate__c.
- Delivery: incomplete checklist cannot complete; complete delivery stamps Closed Won/date/flag
  and creates only the eligible membership; no invented loyalty balance.
- Service: allowed ownership plus separate unexpired authorization, capacity/boundaries,
  idempotent retry, linked queue Case; no foreign customer or native object writes.
- Separate explicit windows for contention, real email delivery, four-hour escalation,
  4/48-business-hour SLA, positive consent/revocation and reservation event multi-session delivery.
  Loyalty activation/accrual/redemption/expiry, Knowledge publication, VIN transport credentials,
  territories, Agentforce/Data Cloud and destructive reset/burst remain independent gated operations.

## Compatible future batching and remaining acceptance gates

1. **No fix authorized:** D01 same-day clock fixture and D02 explicit restricted-identity fixtures
   are now evidence-based test-only candidates. D03 needs separately approved contention
   verification; D04 needs observable email-contract testing rather than a forced counter pass.
   D05 canonical assets and D07 comments evidence remain outstanding. No production security
   correction is established by the triaged failures; full regression still has not passed.
2. **Candidate permission-only batch:** deferred Loyalty_Transaction__c Read, Points__c/Type__c
   Read=true/Edit=false in existing runtime set, exact allowlist/test update. No Case write,
   View All/Modify All or membership/balance creation; A/B transaction isolation required.
3. **Candidate presentation-only batch:** only reproduced photo/label/layout/accessibility,
   CSI/null display and comment feedback defects. Separate comment submit/refresh UI outcomes;
   no claim this alone repairs persistence. Must preserve booking/history/My Cases paths.
4. **Not compatible with that small batch:** CP2/pricing/approval changes, broad permission grants,
   historical ledger/backfill, data generation/reload, credentials, native feature activation,
   live jobs, user/license/role swaps, page activation, publication and Git/release actions.

Remaining gates: owner direction on stopped failures; exact canonical/storage evidence; complete
strict DQ/release tests and coverage as required; actual persona/browser business walkthrough;
security negative-case certification; visual/accessibility acceptance; explicit disposition of all
P5/P6/P7 operational exceptions; approved fixes only after testing; final owner sign-off. No phase
closure, full-release certification, authenticated agent UAT pass or full-project PASS is claimed.

## Escalation / next owner decision

Changes made: this register, execution_summary.json and copied raw receipts only; no implementation
diff. Last verified current checks: CP2 arithmetic/source parity and relevant passing methods,
48 local UI mocks, eight DQ probes, Live portal/link inventory. Historical P8 deployment validation
0Afaj00000pTterCAC passed 22/22; current full suite does not pass and does not erase owner smoke PASS.

Owner can perform read-only step 1 now. Result-only triage of run 707aj00001OOD4U was subsequently
authorized and completed above, with no test rerun. For follow-up, separately approve specific
test-only fixture corrections and isolated/serial verification, and provide the approved canonical
CSV archive/exact Storage Usage screenshot. No test edit, fixture change, rerun, deployment,
permission change or production correction was performed by this triage.

## Lightweight local orchestration — 2026-10-28

Plan/phase execution lanes and approval gates: `docs/planning/UAT_ORCHESTRATION.md`.
Reusable runner: `scripts/uat/orchestrate.py`; offline tests:
`scripts/tests/uat_orchestration_test.py`. No existing implementation/test/metadata changed.
The register checklist remains the per-criterion source; collection exports its 91 grouped rows
without changing their statuses. Existing D01–D14 remain open; D15 stays CLOSED. No new defect
or repeated diagnosis. Receipt reuse does not certify fresh source, browser behavior or closure.

CONFIRMED — raw offline harness validation excerpt
(`orchestration_validation.txt`; fake query responses, no Salesforce calls):
```text
Ran 12 tests in 0.004s

OK
```

CONFIRMED — raw browser access check:
```json
{"tabs":[],"focusedTabID":null}
```
Authenticated persona/browser acceptance remains BLOCKED until owner supplies the actual
already-authorized session; no new Browser MCP connection investigation. No live queries,
deployments/dry-runs, Apex reruns, workflow/permission/record changes or Git commit/push.
Optional local UI re-execution and live identity/inventory batch were planned, not run.

<!-- orchestration:20261028T161952706034Z -->
### Local orchestration receipt — 20261028T161952706034Z

- Batch: `reuse`; collection status: **PASS**.
- Evidence: `evidence/UAT/FULL_PROJECT_2026-10-28/orchestration/20261028T161952706034Z/results.json`; `evidence/UAT/FULL_PROJECT_2026-10-28/orchestration/20261028T161952706034Z/coverage.json`.
- Existing feature/defect statuses and historical acceptances are unchanged.
- A collection PASS is not a full UAT PASS. No defect is auto-closed.

## Owner frontend UAT consolidation — 2026-10-28

### Provenance and status boundaries

**Evidence source: OWNER-REPORTED browser observations supplied by the owner for October 28,
2026, ng-demo.** These are browser-observed by the owner, not independently browser-observed
by this agent and not new automated results. No screenshots, exact execution times, full report/
dashboard ID list or usernames were supplied with this update. Sales persona is explicit for
Test Drive 74; Administrator is explicit for the vehicle-search error. Other personas are not
inferred. PASS below means only the stated observed navigation/display/action. No raw browser
receipt is fabricated, and owner statements are not relabeled CONFIRMED automated verification.

Existing automated evidence, failures, accepted P5/P6 exceptions, historical phase decisions,
P3-DEF-01 closure, D01–D14 and CLOSED D15 are preserved. The earlier “Executed now” receipts,
triage and browser-disconnection entries remain historical, not claims that owner browser UAT
was unavailable. This documentation update performed no Salesforce access, mutations or tests.
Owner-reported record creation/completion describes the owner's earlier testing, not this agent's
actions or authorization to repeat it. Overall project acceptance remains **BLOCKED**.

### Supported navigation and scoped action results

Every result in this table is **OWNER-REPORTED / browser-observed by owner** unless stated otherwise.

| Observation / original criterion | Scoped result added | Not established / retained gap |
|---|---|---|
| Sales Lead list/details/Activity timeline/Lead Conversion dialog; P1-06/07, P2-01/02 | PASS opening/rendering these surfaces | Actual Lead creation/routing/conversion was not executed; no generated Account/Contact/Opp or Seed_Tag hygiene acceptance |
| Task creation form; P2-07 | PASS opening form | Save not tested; automatic Task creation, owner/due date not accepted |
| Account and Contact details; P1-03/06, P2-02 | PASS displaying related customer information | Complete relationship integrity, cross-persona scope/FLS and converted-record creation not proven |
| Quote 00000069; P3-04/05/07 | PASS displayed $50,615 standard subtotal, $43,022.75 adjusted subtotal, one pricing rule, 15% adjustment | Reuses existing CP2 checkpoint; no new repricing, approval submission, full line/PDF or signed-premium test. Print-preview presentation FAIL, D08-a |
| Finance Application 64; P4-02 | PASS owner-reported creation/display with $43,022.75 amount financed | Existing-draft message plus new-draft banner on reopening: presentation FAIL, D08-b. Not proof of a second insert, duplicate Draft or overwritten Quote. Approval submission not executed |
| Test Drive 74 (`a0Aaj00000GbtNhEAJ`); P2-03/04 | PASS Sales persona positive booking and vehicle selection | Admin vehicle-search permission error is recorded, not diagnosed. No overlap rejection, contention, confirmation-email delivery or Task acceptance; D04 remains |
| Trade-In 52; P3-01 | PASS create/display: appraisal $12,000; payoff $3,000; reconditioning $1,000; calculated equity $9,000 | Observed equity equals appraisal minus payoff; do not assume reconditioning must be subtracted or change accepted equity semantics. Wizard path, negative cases and appraisal-before-Quote gate not proven |
| Delivery; P4-06–08 | PASS list, existing Completed detail and New Delivery form opened | No functional checklist/lifecycle/Closed Won/enrollment test; viewing a completed fixture is not proof of its transition |
| Inventory/Vehicle Models/Rooftops; P1-01/03/06/07, P7-01/22/23 | PASS list and individual Vehicle records opened; Models/Rooftops accessible | Photo mismatch D08-d; model-year formatting/numeric-name review pending. Gallery filtering, Reserve/events, header fallback and full matrix not established |
| Reports/dashboard surfaces; P2-09–11, P3-08–10, P4-09/10, P5-09–16, P6-09 | PASS access/inspection scope: ten priority reports visually reviewed and all nine Northgate dashboards visually inspected | Not nine clean-render PASSes: Executive overlap/unreadability FAIL D08-c. Exact identities/personas/filters/source totals not supplied; no metric/parity or drill-through acceptance |
| Service Visit; P6-01–05 | PASS list, detail and New Service Visit form opened; Visit 111 reported marked Completed despite future scheduled date | Completion recorded as an observation, not lifecycle acceptance; chronology/policy concern UNVERIFIED (C01 below). No new-form save/capacity/Case routing test established |
| Loyalty Membership 10; P6-06–09 | PASS detail inspection: Active / Bronze / zero balance displayed | Stored balance/ledger reconciliation and live loyalty processing not tested; does not repair portal D06 |
| Loyalty Transaction 100; P6-06–08 | PASS detail inspection: 221 accrued points, dated May 2, 2027 | Future date/provenance/membership linkage and balance impact UNVERIFIED; no inference that it belongs to Membership 10 |
| Consent 11; P6-12 | PASS detail inspection: SMS / Recall Alerts / Revoked, Evidence blank | Blank evidence is observed, but requiredness/provenance and actual suppression/enforcement remain UNVERIFIED |

Finance 64 correlation is **PRIOR READ-ONLY CLI LOOKUP**, not a new browser/automated test run:
the preceding owner-requested ng-demo lookup in this conversation returned one `Financing__c`
record `a04aj000008HsozAAC`, Name `64`, Status `Draft`, Applicant `REP UAT Buyer`
(`003aj00002WTKmHAAX`), Quote `0Q0aj000003kVS5CAM` / `00000069`, Amount_Financed__c
`43022.75`, Opportunity `006aj00000fbDI1AAM` / `UAT-2026-10-20 REP Quote`.
The command output was returned in the conversation, not saved as a new raw receipt here.
It corroborates existing record/link/amount at lookup time, not the creation path, exact creator,
draft-banner cause, duplicate prevention or Finance-persona access. Do not create another record
to reproduce this finding.

### Report values: observed displays, not certified source totals

All values below are **OWNER-REPORTED browser display observations**. The ten-report count is
the owner's aggregate; individual Finance report names/IDs and the nine dashboard IDs were not
provided. Do not invent a per-report execution list or run reports again to fill documentation.

| Report/group as reported | Display observed October 28 | Reconciliation disposition |
|---|---|---|
| Inventory Aging | 120 vehicles | Matches earlier owner observation; original age-distribution acceptance remains an exception |
| Pipeline by Stage | 82 opportunities; $4,827,766 | Preserve earlier 81-opportunity/$4,827,766 snapshot in handoff §16; different count alone is not a defect |
| Lead Source Effectiveness | 130 leads; 0 conversions | Conversion was not executed in this session; no conversion/routing failure inferred |
| Finance reports | Empty result sets | UNVERIFIED accuracy; check intended status/date filters, eligible population and reader scope before defect classification; no Funded data fabrication |
| Overdue Service Visits | 23 records | Current displayed snapshot, not historical 12/13/14 fixture target; compare definitions/refresh dates/timezone/persona first |
| Loyalty Tier Distribution | 72 members; zero points | Consistent with prior aggregate snapshot; not proof of transaction-to-balance reconciliation or tier allocation correctness |
| Stale Open Leads | 35 records | Date/filter-dependent count; source parity not tested |
| Duplicate Households | 207 candidate records | Candidates are not 207 proven duplicates or pairs; do not equate to original eight-pair fixture criterion |
| Revoked Consents | 38 records | Inventory of revoked rows is not the managed-campaign suppression test or revoked-missing-date DQ probe |

Differing overdue values across related service reports/dashboards are **UNVERIFIED**, not a
confirmed calculation defect. Retain D11 reconciliation and D12 stale/CSI/drill-through limits;
compare report filters/status definitions, scheduled cutoff/business timezone, dashboard source,
as-of/refresh dates and running-user/actual-reader scope without publishing or editing anything.
Empty Finance reports and candidate counts are likewise not new defects on display evidence alone.

### Consolidated confirmed presentation findings — existing D08, no duplicate defects

“Confirmed” here means **owner reported observing the presentation failure**, not independent
agent reproduction or verified implementation cause. D08 is expanded, not replaced. All four
items are S3 presentation findings; mobile/focus/portal review still remains NOT TESTED.

| Subitem | Owner-observed failure | Evidence still needed before an approved narrow fix |
|---|---|---|
| D08-a / P3-07 | Quote 00000069 print preview has a presentation/layout issue | Screenshot, browser/paper settings and exact clipping/spacing description; preserve figures, CP2 pricing, Quote/approval history |
| D08-b / P4-02 | Existing-draft message and new-draft banner both show when reopening Finance 64 | Exact banner text/context and screenshot; distinguish stale presentation from actual draft-state/persistence defect before changes |
| D08-c / P5-14 | Executive dashboard components overlap or are unreadable | Dashboard ID, reader, viewport and screenshot identifying affected tiles; not a claim of bad underlying totals |
| D08-d / P7-22/23; P8 only if demonstrated there | Vehicle photo does not match displayed identity/colour | Specific Vehicle/image mapping and screenshot; evaluate against owner-amended licensed stock/body/approximate-year/appearance criteria, not an invented exact OEM/colour promise. Asset/mapping cause unverified |

Model-year formatting and numeric record names are **presentation review requests**, not yet
confirmed defects: capture exact examples and intended formatting; numeric auto-number names may
be deliberate. Do not alter names or asset mappings on this observation alone. Existing D12's
accepted CSI-zero-versus-N/A issue is retained separately, not duplicated or marked repaired.

### Possible data-quality issues and functional risks — not confirmed defects

Concern IDs below index follow-up within existing gaps; they are not new proven defect IDs.

| Concern / existing gap | Observation | Unverified question / next bounded evidence |
|---|---|---|
| C01 / D10, P6-01–05 | Visit 111 Completed with a future scheduled date | Identify exact record/date, actual completion date, actor/bypass context and intended lifecycle policy. Do not infer the new-booking future-date rule is a completion prohibition or a bypass defect |
| C02 / D11/D10, P6-06–09 | Membership 10 zero balance; Transaction 100 accrued 221 points on May 2, 2027 | Establish transaction/member/source links, canonical/UAT provenance, date semantics, program state and permitted stored-balance rules before judging inconsistency; no balance/date repair or ledger reconstruction |
| C03 / D10, P6-12 | Consent 11 Revoked with Evidence blank | Check actual evidence-requiredness, revocation tuple/date/provenance and suppression contract; no demonstrated unlawful send or consent-enforcement failure |
| C04 / D09, P1/P2-03–04 | Admin search permission error while Sales vehicle picker works | Obtain exact error, username, component and intended access requirement; correct Sales behavior remains PASS. Admin error is not proof of Sales failure and does not justify blanket grants |
| C05 / D11/D12, reporting phases | Empty Finance sets, different overdue metrics, 207 duplicate candidates | Reconcile definitions/filter dates/reader scope and provenance; do not force historical counts or treat candidate rows as confirmed duplicates |
| C06 / D08-b, P4-02 | Conflicting draft banners | Presentation failure is established by owner observation; duplicate insertion/overwritten data and failed idempotency are not established |

### Prioritized consolidated improvement backlog and remaining acceptance gates

Order is a recommendation for owner decisions, not permission to execute. Reuse completed checks,
owner positives and existing triage; do not rerun broad regression or replay completed bookings.

| Priority | Existing IDs / scope | Next acceptance evidence or disposition needed |
|---|---|---|
| 1 — security/identity and blocking functionality | D01–D04, D06/D07, D09; P1/P2/P4/P6/P8 | Preserve known causes; owner decision on deterministic test-only fixtures/isolated verification, real notification contract, compliant Finance/Service identities, portal loyalty/comments corrections and cross-customer/guest negatives. Do not restart investigations, widen grants or auto-rerun |
| 2 — lifecycle/data questions before correction | C01–C06 via D10/D11/D12/D09/D08 | Obtain only missing exact record/policy/error/source/filter evidence; prioritize Visit chronology, transaction provenance, consent contract and draft-state ambiguity. None is permission for corrective data writes |
| 3 — demonstrated presentation fixes | D08-a/b/c/d, retained D12 | Capture missing screenshot/context; prioritize unreadable Executive components and contradictory draft messaging, then print layout/photo representation. Separate approved presentation-only scope from any newly demonstrated functional defect |
| 4 — presentation review, not fixes yet | D08 remaining scope | Model-year/numeric-name examples, responsive layouts, keyboard/focus/labels/contrast and photo fallback; preserve stock-image acceptance limits |
| 5 — remaining connected/release acceptance | D05/D10/D11/D13/D14 | Canonical archive/exact storage, report/source/persona parity, operational/capability dispositions, bounded workflow windows and final owner sign-off; no unapproved activation/release |

Remaining phase-specific tests (do not restart the completed navigation/display checks):

- **P1:** actual-persona matrix, negative FLS/sharing and operational identity readiness; sampled
  navigation is not full security acceptance. No role/PSG swap or Admin substitution.
- **P2:** actual conversion with resulting links/seed hygiene, saved/automatic Task ownership and
  due date, overlap/reservation contention, email receipt and connected stage progression. Sales
  Test Drive 74 positive booking is already recorded; do not replay it for evidence.
- **P3:** approval tiers/no-self-approval/write-back in a separately authorized window, printable
  layout/line fidelity, negative/appraisal gates and remaining equity cases. Saved CP2 display and
  Trade-In 52 positive action are recorded; no historical repricing or reopened P3-DEF-01.
- **P4:** actual Finance session/FLS, rate/term/payment/draft-state behavior, approval submission,
  lifecycle invalid transitions, checklist completion→Closed Won→eligible enrollment. Finance 64
  creation/amount and Delivery navigation are not acceptance of these transitions.
- **P5:** canonical/legacy/provenance/integrity/strict DQ and exact storage gates, report/source/
  tile/drill-through reconciliation as intended readers; accepted exceptions stay explicit. Ten
  report/nine dashboard visual inspections do not certify metric accuracy or all layouts.
- **P6:** C01–C03 evidence, real capacity/Case routing, escalation and 4/48-business-hour SLA clocks,
  consent positive/opt-out tests, loyalty operational reconciliation/activation decisions, Knowledge
  search/attachment/publication and dual-role scope. P6-E01–E14 remain outstanding as documented.
- **P7:** D08 context/fixes and missing-image/mobile/keyboard acceptance, controlled reservation
  events, live VIN credential/transport, territory/native-feature decisions and clean release/demo
  gates. Existing deployment and mocked passes are not live feature acceptance.
- **P8:** retain prior owner dashboard/vehicles/booking/history/My Cases positives. This update
  supplies no new portal persona evidence or fix: D06 loyalty and D07 comments remain FAIL;
  A/B/guest negative certification, responsive/accessibility and final sign-off remain open.

Documentation-only consolidation: no Salesforce record, permission, Apex, LWC, metadata or project
functionality changes; no CLI queries/browser execution, deployments, tests, Git operations or
repeated completed investigation. No full-project UAT acceptance is claimed.

## D08 local correction package — 2026-10-28

Separate subsequent owner authorization permits scoped local code/metadata and focused tests,
not deployment or Salesforce mutations. Earlier documentation-only consolidation remains an
accurate account of that earlier work; it does not describe this new local implementation.

Plan, exact files/metadata/UI corrections, risks and validation limits:
`docs/planning/D08_LOCAL_CORRECTIONS_2026-10-28.md`.
Exact candidate manifest: `manifest/d08-presentation-local.xml` (9 components: two LWC bundles,
Executive dashboard geometry and six additive `NG_Overview` list views). Source only, never data.

| Item | Current scoped status | Retained acceptance gap |
|---|---|---|
| D08-a Quote print | LOCAL PARTIAL correction: component wrap/print/table pagination CSS prepared; state/static tests PASS | No Salesforce/native-PDF/browser verification; whole-page shell clipping/pagination may remain |
| D08-b Finance banners | LOCAL correction: one state-aware notice, hidden during loading/errors; explicit existing/new/saved/ambiguous copy; mocked tests PASS | No browser reproduction/acceptance or functional draft-state fix claimed; server “opening it instead” copy/behavior unchanged |
| D08-c Executive layout | LOCAL metadata correction: wider tiles, taller service/footer rows, full-width CSI; geometry checks PASS | Native rendering/actual-reader UAT and live dashboard parity still unverified; no metric/source changes |
| Numeric-only lists / D08 review | LOCAL metadata candidates: six named Northgate Overview views with existing contextual fields, no Name/record changes | Not deployed/selected; FLS/native visibility behavior must be checked as existing actual readers; existing All/Recently Viewed untouched |
| D08-d photo mismatch | PENDING exact Vehicle/component/image evidence; no asset/data changes | Illustrative stock scope retained; no proven wrong-map repair selected |
| Empty Finance / C05 | Exact native Deal Desk footer proposal documented only, not packaged/applied | Empty sets are not defects without source/filter/reader evidence; no dummy records or false zero values |

CONFIRMED — raw `D08_LOCAL/focused-ui.tap` excerpt:
```text
# tests 14
# pass 14
# fail 0
```
CONFIRMED — raw `D08_LOCAL/metadata-tests.txt` excerpt:
```text
Ran 4 tests in 0.007s

OK
```
`D08_LOCAL/before_hashes.json` captures pre-edit source bytes; focused preservation check passes
for captured Apex, permission sets and Quote Builder, including pre-existing user work. It is not
a HEAD/live-org comparison. Raw results are local/mock/static evidence only, not browser UAT.

No D08 subitem closed; D01–D15 dispositions, historical acceptance, CP2/discount/approval logic,
permissions/sharing/customer access, inactive loyalty and owner UAT records unchanged. No live
Salesforce query/write, deployment/dry-run, full regression, activation, Git commit or push.
Next: owner review of whole-bundle source (including earlier uncommitted work), separate approval
for server validation/deployment, then read-only actual-persona presentation UAT. Overall BLOCKED.

## D08 deployment readiness — stopped, BLOCKED

Owner separately authorized one scoped dry-run and read-only readiness investigation. Exact
nine-member manifest remains unchanged. Complete evidence/escalation:
`D08_READINESS/RESULT.md`; raw check-only receipt: `D08_READINESS/validation.json`.

CONFIRMED — raw validation excerpts:
```json
"checkOnly": true,
"id": "0Afaj00000paEa9CAE",
"numberComponentErrors": 1,
"numberComponentsDeployed": 9,
"numberComponentsTotal": 10,
"numberTestsCompleted": 0,
"status": "Failed"
```
CONFIRMED — raw failure/warning:
```text
Financing__c.Finance_Exception_Approved__c: Not in package.xml
CustomField, Financing__c.Finance_Exception_Approved__c, returned from org, but not found in the local project
```
Nine intended components individually reported check-only success, but overall readiness is
REFUTED by the extra CustomField error. No persistent deployment or retry. NoTestRun was
accepted; no Apex tests/coverage or full regression executed. Complete live bundles/dashboard
were retrieved separately without overwriting source; all six views' field dependencies exist
in current administrative describes and no existing NG_Overview views matched the scoped query.

Complete unrelated-change comparison remains BLOCKED after an offline path-collection command
failed with `TypeError: 'PosixPath' object is not iterable`; no correction/retry without owner
direction. Candidate source/manifest hashes stayed unchanged. Existing user work is preserved;
no blanket assertion that entire bundles contain only D08 changes. No code, permissions, data,
actual deployment or Git operations. All earlier defects/acceptance limits remain intact.

Owner next: inspect job `0Afaj00000paEa9CAE` in ng-demo Deployment Status and authorize bounded
serialization diagnosis plus offline comparison-command correction. Do not add field scope,
deploy or rerun validation automatically. D08 remains open; overall project acceptance BLOCKED.

## D08 readiness unblock — exact corrected artifact READY for approval

Separate owner authorization resolved the source-packaging and offline-comparison blockers.
Evidence/root cause/exact scope/complete file-by-file comparison:
`D08_UNBLOCK/RESULT.md`. No earlier failure, raw receipt or acceptance decision was overwritten.

Source conversion of the selected Financing list view copied an inline approval-field declaration
stub from its parent `Financing__c.object-meta.xml` into the parent carrier, despite package.xml
containing no CustomField. Offline conversion reproduced it. A generated child-only package
excludes that stray declaration and all unselected parent object settings. Original source,
manifest, field definition, Finance approvals/FLS and user work remain untouched; do not add the
field or reuse the original source-manifest deployment command.

The corrected path collector compared all seven deployable LWC files to the saved ng-demo
snapshot. Only reviewed D08 template/notice/CSS changes plus harmless final newlines differ;
no unrelated semantic bundle changes. Exact artifact: `D08_UNBLOCK/d08-corrected.zip`.

CONFIRMED — raw `D08_UNBLOCK/validation.json` excerpts:
```json
"checkOnly": true,
"id": "0Afaj00000paFMXCA2",
"numberComponentErrors": 0,
"numberComponentsDeployed": 9,
"numberComponentsTotal": 9,
"numberTestsCompleted": 0,
"status": "Succeeded"
```
CONFIRMED — raw artifact SHA256 from `D08_UNBLOCK/package_checks.json`:
```text
471ad0f5a72b1710ca1b6d192df8d8b8db78a1448e5a676874a47901d6c915c8
```

One newly authorized dry-run only, Developer Edition/NoTestRun; no Apex/full-suite rerun.
Nine intended members unchanged: quoteSummary, financeApplication, Executive Operations
dashboard and six NG_Overview list views. No field/Apex/permission/sharing/destructive additions.
Postchecks retain candidate source hashes and exact successful nine-member inventory.

**READY for owner approval of this exact ZIP/hash only.** No actual deployment, Salesforce data/
configuration modification, Git operation or browser-verified correction. Browser/print/dashboard/
persona field-access acceptance remains outstanding; D08 defects remain open and overall
project UAT remains BLOCKED. Any deployed-source drift after the retrieved snapshot requires
review before application. Stop and request approval; do not deploy automatically.

## Remaining defects / regression closure — local candidates only

Current scope, exact two separate approval candidates, ten-failure disposition and minimal
remaining security/workflow checks: `REGRESSION_CLOSURE/RESULT.md`. Before-state and execution
protocol: `REGRESSION_CLOSURE/RUN.md`. No full walkthrough or reset investigation repeated.

### Owner-reported A/B positives — not independent security verification

- **Customer A login: PASS, OWNER-REPORTED** in the current owner instruction. Earlier A reset/
  invalid-password findings remain historical, not current login blockers.
- **A/B vehicle/dashboard displays: PASS, OWNER-REPORTED** separate customer views. Preserve
  earlier B dashboard/booking/history/My Cases positives. No new screenshots/record lists or
  exact observation timestamps supplied here; actual foreign-ID, native API, guest and same-Account
  negatives are not proved by these positive displays. No Expansion redesign acceptance implied.

### Local fixes and limits

- **D16 Executive fields:** prepared new `PS_Executive_Service_Field_Read` with only three
  deidentified stored metric field Read grants. Existing formulas and D08 layout untouched.
  Reader-dependent FLS failure measured as `arjun.ngdemo@northgate.demo`; actual intended browser
  reader assignment still needs owner confirmation. One-component manifest
  `manifest/uat-executive-field-read.xml`. No set assigned or live permission changed.
- **D06:** updated only existing runtime set locally, adding Loyalty_Transaction__c Read and
  Points__c/Type__c Read-only FLS. Existing entries/Case write denials and source guards preserved.
  One-component manifest `manifest/uat-d06-loyalty-read.xml`. No new assignment; deployment would
  affect existing assignees, so explicit permission-effect approval and isolation tests remain.
- **D07:** diagnostic source/mocks only. No actual failed response available; no Case permission,
  Apex or portal LWC change. Submit persistence versus refresh failure is still unresolved.

CONFIRMED — raw `REGRESSION_CLOSURE/focused-metadata.txt`:
```text
Ran 7 tests in 0.028s

OK
```
CONFIRMED — raw `REGRESSION_CLOSURE/comment-diagnosis.tap`:
```text
# tests 3
# pass 3
# fail 0
```
CONFIRMED — raw `REGRESSION_CLOSURE/harness-fast.txt` excerpts (version executed):
```text
Receipt consistency: PASS; 8 receipts; 91 criterion groups
Historical Apex: 360 Pass / 10 Fail; NOT rerun
PASS: selected available LOCAL checks only; review SKIPPED lines. Full project acceptance remains BLOCKED.
```
Both candidate manifests converted locally to exactly one PermissionSet each. No server dry-run,
Apex execution, deployment, data/grant/assignment/sharing changes, activation or Git writes.
Concurrent portal CSS/HTML drift is informational; attribution unknown, no overwrite/revert.
Harness files are not modified by this task. Historical three-object/nine-field runtime checks
and D08-only preservation assumptions require a scoped successor from the Harness stream before
full local/release gating; no test baseline was silently refreshed to force a pass.

### Existing failures and minimum next acceptance

`REGRESSION_CLOSURE/failure_disposition.json` reuses all ten exact failure rows: D01=1 needs
deterministic Toronto-day test correction; D02=2 need explicit restricted runAs identities;
D03=6 are blocked setup-lock outcomes requiring one separately approved isolated/serial check,
not code/data repair or documentation-only PASS; D04=1 needs observable notification-contract
testing, not Expected 0→1. No production authorization defect established by those failures.
No Apex/test fixture corrected or rerun here; D15 remains CLOSED.

Minimum outstanding deltas: changed-runtime own/foreign/same-Account/native loyalty isolation,
empty/ambiguous/paged reads and write denials; guest/restricted/Contact-substitution and Reviewer
negatives; independent ownership/service-consent expiry/revocation/capacity/idempotency; comments
published-only own round-trip and foreign/internal-note denial once evidence/fix approved;
internal intended-reader field/report/tile parity without widening access. Missing workflow
segments remain conversion/Task/email, actual tiered approvals, Finance status/funding negatives
and checklist→Closed Won→eligible enrollment. Reuse completed positive slices/CP2 protections,
never replay historical Quote or owner bookings. D05/D11 canonical/storage/DQ and retained P5/P6/
P7 operational/native/visual exceptions still require evidence or explicit owner disposition.

**Next approval:** first the one-component Executive field-read server validation; deployment
and intended-reader assignment are separate approvals. D06 is an independent one-component
permission candidate with minimum-runtime isolation gates. Neither is server-validated or
deployment-ready. D07 has no deployment candidate. Overall release/project acceptance BLOCKED.

## D16 authorized deployment — assignment condition unmet

Subsequent owner approval authorized the exact validated one-PermissionSet package and
assignment only if the affected browser session was proven to be arjun.ngdemo@northgate.demo.
Current evidence: `D16_DEPLOYMENT/RESULT.md`; raw deployment: `D16_DEPLOYMENT/deployment.json`.
This supersedes earlier D16 local-only/validation-pending states, not their historical receipts.

CONFIRMED — raw deployment excerpts:
```json
"checkOnly": false,
"id": "0Afaj00000paLbdCAE",
"numberComponentErrors": 0,
"numberComponentsDeployed": 1,
"numberComponentsTotal": 1,
"numberTestsCompleted": 0,
"status": "Succeeded"
```
Both source/manifest hashes matched successful dry-run `0Afaj00000paL8bCAE` before/after
deployment. Exactly PS_Executive_Service_Field_Read deployed, with three metric Read=true/
Edit=false grants only. No errors/warnings, added object/system rights or other components.

CONFIRMED — current browser tool response:
```json
{"tabs":[],"focusedTabID":null}
```
**Assignment NOT PERFORMED.** Existing API identity and the dynamic dashboard's stored
RunningUserId do not establish affected browser identity. The explicit condition was unmet;
no inferred identity, additional user or permission assignment was substituted.

Post-assignment effective access NOT VERIFIED (no assignment). Source report/dashboard visual
acceptance remains PENDING; no refresh, report run, new login or UI PASS claimed. Stop after
deployment; owner must confirm affected browser session identity before the exact-user assignment
condition can be exercised. D16 remains OPEN and project acceptance BLOCKED. No D06/portal,
Apex/LWC/dashboard/report, business-data, role/PSG, unrelated permission or Git-write changes.

## D16 exact-user assignment — completed; owner visual check pending

The owner subsequently confirmed the affected browser session belongs to
arjun.ngdemo@northgate.demo and explicitly authorized the one-user assignment. This supersedes
the earlier identity-blocked assignment state, not its historical receipts. No redeployment.

CONFIRMED — raw `D16_ASSIGNMENT/assignment_create.json`:
```json
{"status":0,"result":{"id":"0Paaj000018MIu2CAG","success":true,"errors":[]},"warnings":[]}
```
The precheck found no assignment. Postcheck found exactly one assignment for permission set
0PSaj00000hKcDFGA0, only to approved User 005aj00000feqbNAAQ. Authenticated API identity matches
that user and ng-demo / 00Daj00001Ae3iWEAR. No other assignments or metadata/profile changes.

Read access to Overdue_Count__c, CSI_Score_Total__c and CSI_Response_Count__c is verified through
the persisted assignment, deployed Read=true/Edit=false grants and field visibility in that
user's native API describe. **The same describe also returns createable=true/updateable=true
for all three fields.** Do not conflate the new set's Edit=false with an overall effective
Read-only guarantee for this administrator; cause not established and no write probe/correction
attempted. Exact raw flags, limitations and owner diagnosis request: `D16_ASSIGNMENT/RESULT.md`.

No dashboard/report/LWC/Apex change, business-record modification, deployment, broad regression,
Git write or ng-dev access. Stop after verification. Owner browser acceptance remains PENDING;
no D16 closure or full-project UAT acceptance claimed.

## D16 post-assignment read-only follow-up — report field availability confirmed

All operations were reads; `followup_verification.json` records `salesforceWritesPerformed: 0`.
Evidence: `D16_ASSIGNMENT/RESULT.md`, `followup_verification.json`.

CONFIRMED — report describe aggregates for the assigned user changed from only
`["s!CDF1","RowCount"]` before assignment to:
```json
"Executive_Service_CSI": ["s!Executive_Service_Metrics__c.CSI_Score_Total__c",
 "s!Executive_Service_Metrics__c.CSI_Response_Count__c", "s!CDF1", "FORMULA1", "RowCount"]
"Executive_Service_Overdue": ["s!Executive_Service_Metrics__c.Overdue_Count__c",
 "s!CDF1", "FORMULA1", "RowCount"]
```
Both retrieved formulas are unchanged (24-hour stale guard; CSI positive-response guard). This
confirms restored field availability for the two reports, **not** dashboard tile rendering.

CONFIRMED — exactly 6 FieldPermissions rows exist org-wide for the three fields: three in
`PS_VP_Executive_Reporting` (not this user) and three in the new set; **all Edit=false**. The
System Administrator profile-owned set has 1002 FLS rows overall but none on this object, so the
gap was targeted. The same authenticated describe still reports
`createable=true/updateable=true`; with no Edit=true FLS row anywhere, that flag is **not
attributable to this correction** (pre-existing object ModifyAllRecords documented before
deployment). No write probe, cause claim or overall Read-only assertion is made.

Owner visual/print check of the Executive dashboard as arjun.ngdemo@northgate.demo remains
PENDING; no browser tabs were available. D16 stays OPEN; project acceptance BLOCKED. No D06,
Apex/LWC/dashboard/report source, business data, role/PSG, unrelated permission, Git write or
ng-dev access occurred in this follow-up.

## D16 closure — owner visual acceptance, 2026-10-28

**Status: CLOSED — owner visually accepted.** Documentation-only closure; no test, Salesforce
operation, deployment, assignment, code/metadata change, staging, commit or push was performed
for this entry.

Evidence chain already recorded (no new evidence generated):
- Dry-run `0Afaj00000paL8bCAE` Succeeded 1/1, zero errors — `D16_SECURITY_VALIDATION/validation.json`.
- Deployment `0Afaj00000paLbdCAE` Succeeded 1/1, zero component errors, zero warnings —
  `D16_DEPLOYMENT/deployment.json`; three Read=true/Edit=false grants only.
- Exact-user assignment `0Paaj000018MIu2CAG` for `PS_Executive_Service_Field_Read`
  (`0PSaj00000hKcDFGA0`) to `arjun.ngdemo@northgate.demo` / `005aj00000feqbNAAQ` only —
  `D16_ASSIGNMENT/assignment_create.json`, `assignment_after.json`.
- Read-only post-assignment verification — both report describes returned the three stored fields
  and FORMULA1 (previously `CDF1`/`RowCount` only); six org-wide FLS rows for those fields, all
  Edit=false — `D16_ASSIGNMENT/followup_verification.json`.
- **Owner report:** after the above, Overdue Service Visits and CSI Proxy render correctly under
  `arjun.ngdemo@northgate.demo` (`D16_ASSIGNMENT/RESULT.md`).

CONFIRMED — owner statement received for this task; recorded as OWNER-REPORTED acceptance, not an
agent-captured screenshot or independent rendering test. No print-layout claim is included.

Scope limits retained: (1) the authenticated describe still reports `createable=true/updateable=true`
for these fields with no `Edit=true` FLS source; cause is not established, was not introduced by the
Read-only set, and no write probe or revoke was performed — this is a separate open note, not a
reopened D16 or an assertion that the admin is field-level Read-only; (2) D16 closure does not
certify other dashboards, other readers/personas, D12 CSI null-display behavior, D08-c layout, or
full project acceptance. Overall release remains **BLOCKED**.

## D05 canonical input inventory — blocker refined (documentation only)

Read-only local inventory; no Salesforce access, file copy/symlink/regeneration, script edit,
deployment, test rerun or Git write. Evidence: `D05_CANONICAL_INPUTS/RESULT.md`, `inventory.json`.

CONFIRMED — `phase5.py` requires `data/csv/01-rooftops.csv`, but `data/csv` does not exist, is not
tracked by Git and has no history in this checkout. A resolved derivative exists at
`data/csv-resolved` and its 27 per-object files match the preserved `TARGETS` envelope exactly
(2,085 records, consistent with `CANONICAL_LOADED_RECORDS=2085` and `GOVERNING_FULL_RECORDS=2115`
after the 30 SEED-98 records). 26/27 files carry `Seed_Tag__c`; `11-opptylineitems.csv` does not,
which is expected because `verify()` counts OLI through its parent Opportunity query.

That derivative is **not canonical**: `NEXT_SESSION_HANDOFF.md` documents `--resolve` writing
`data/csv-resolved` *from* the canonical inputs with live IDs substituted. No CSV digest snapshot
manifest exists in the tree. Substituting it would change verification semantics, so it is not
proposed. D05 and D11 remain BLOCKED pending the owner's canonical `data/csv/` bytes (and snapshot
manifest if retained); no parity claim is made.

## D06 Loyalty permission validation — dry-run succeeded, no deployment

Authorized scope: read-only inspection plus one check-only deployment of
`manifest/uat-d06-loyalty-read.xml`. No deployment, assignment, data/Apex/LWC/Experience change,
test rerun or Git write. Evidence: `D06_VALIDATION/RESULT.md`, `validation.json`,
`candidate_before.json`, `verification.json`.

CONFIRMED — target `00Daj00001Ae3iWEAR`; live permission set equals the reviewed local baseline
(no live drift), and the candidate adds exactly:
- object `Loyalty_Transaction__c`: `allowRead=true`, create/edit/delete/viewAll/modifyAll=false;
- `Loyalty_Transaction__c.Points__c`: Read=true, Edit=false;
- `Loyalty_Transaction__c.Type__c`: Read=true, Edit=false.
No removals or changes to the nine existing field grants, three existing object grants,
`OwnerPortalBatchBController` class access or activation state.

CONFIRMED — raw `validation.json`:
```json
"id": "0Afaj00000paNYbCAM",
"checkOnly": true,
"status": "Succeeded",
"numberComponentsTotal": 1,
"numberComponentsDeployed": 1,
"numberComponentErrors": 0,
"numberTestsCompleted": 0
```
Component: `PermissionSet / PS_Owner_Portal_Dashboard_Runtime / success=true`; no failures or
warnings. NoTestRun; no Apex suite or coverage run. Candidate/manifest hashes unchanged.

Isolation facts: controller is `with sharing` and uses `WITH USER_MODE`; caller contact comes from
`User.ContactId` via `getContext()`, `requireCaller` enforces `actor.ContactId == contactId`, and
the transaction query is constrained by both caller member IDs and
`Loyalty_Member__r.Contact__c`. `Loyalty_Transaction__c` is master-detail `ControlledByParent` on
`Loyalty_Member__c` (no OwnerId/share table); member external OWD is `Private` with zero share rows
and no SharingSet retrieved. Portal A/B hold no View All Data/Modify All Data and are on different
Accounts. Neither portal contact has a loyalty member (0 rows), so no transaction record is
currently reachable and the "transactions visible" outcome cannot be demonstrated with A/B data.

Not done/known limits: no deployment, assignment or browser test. Deployment would affect the two
existing assignees immediately. Functional acceptance needs a member-bearing contact or approved
test-only fixture, plus own-member positive, foreign direct-ID denial, same-Account sibling,
guest denial and write-denial checks. D06 is **not** closed; project acceptance remains BLOCKED.

## D06 Loyalty deployment — completed 2026-10-29

Owner-authorized scoped deployment of the unchanged validated candidate to
`ng-demo / 00Daj00001Ae3iWEAR`. No dry-run repeat because both hashes still matched
`0Afaj00000paNYbCAM`; no assignment, data, Apex/LWC, Experience Builder or Git operation.

CONFIRMED — raw `D06_DEPLOYMENT/deployment.json`:

```json
"id": "0Afaj00000pafVVCAY",
"checkOnly": false,
"status": "Succeeded",
"success": true,
"numberComponentsTotal": 1,
"numberComponentsDeployed": 1,
"numberComponentErrors": 0,
"numberTestsCompleted": 0
```

Component: `PermissionSet / PS_Owner_Portal_Dashboard_Runtime / success=true`; no failures or
warnings.

CONFIRMED — postcheck: field grants 9→11, adding only `Loyalty_Transaction__c.Points__c` and
`.Type__c` with `Read=true/Edit=false`; object grants 3→4, adding only
`Loyalty_Transaction__c` Read=true with create/edit/delete/view-all/modify-all false; no removals;
`OwnerPortalBatchBController` class access unchanged; assignments remain exactly
`0Paaj000018ByQMCA0` (Customer A) and `0Paaj000018ByQNCA0` (Customer B).

CONFIRMED — guest `/owners/s/` redirected to `/owners/s/login/?ec=302&startURL=%2Fowners%2Fs%2F`
with title `Login` and no customer data in the snapshot.

SKIPPED — authenticated Customer A/B browser checks: no authenticated tabs/sessions available.
A/B membership and transaction queries remain zero; `Loyalty_Member__Share` remains zero.
Actual A/B direct-record and write-denial tests remain outstanding. Permission-model review found
no View All/Modify All, transaction ControlledByParent and member external sharing Private; this
is not an actual-persona record test. D06 remains open, not fully closed. Full evidence:
`D06_DEPLOYMENT/RESULT.md`; overall project acceptance remains BLOCKED.
