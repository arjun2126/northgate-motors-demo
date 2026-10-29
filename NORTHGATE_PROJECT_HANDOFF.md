# Northgate Motors — Master Project Handoff (Phases 1–3)

**Purpose:** allow a new ChatGPT conversation to continue Salesforce development without losing critical context.
**Scope of this document:** documentation only. Nothing here authorizes implementation.
**Latest operational handoff (§78):** My Cases Case.Subject Read=true/Edit=false correction
validated `0Afaj00000pTterCAC` (1 component, 22/22 tests), Quick Deployed
`0Afaj00000pTuFxCAK` (1/1). Existing grants, assignments and Case/Visit records unchanged;
native write denials and scoped A/B isolation retained. Customer B My Cases browser UAT
outstanding; Phase 8 NOT complete. Service history separately browser-confirmed by owner.
Evidence: `evidence/P8/MY_CASES_FLS_DEPLOYMENT/RESULT.md` and unchanged raw receipts.

**Historical deployment (§77):** service-history Read FLS for Visit Mileage_At_Checkin__c
and Case__c validated `0Afaj00000pTnZRCA0` (1 component, 22/22 tests), Quick Deployed
`0Afaj00000pSzJNCA0`. Exactly two Read=true/Edit=false additions; existing permissions,
assignments, profiles, memberships and B's working Visit/Case records unchanged. Per-user native
write denials and scoped A/B isolation confirmed. B history browser retest ready but NOT run;
no Phase 8 completion. Evidence: `evidence/P8/SERVICE_HISTORY_FLS_DEPLOYMENT/RESULT.md`.

**Historical deployment (§76):** dashboard runtime PermissionSet validated
0Afaj00000pTPCACA4 (1/1, 22/22 tests), Quick Deployed 0Afaj00000pT3OYCA0 (1/1) and assigned
only to A/B. Native Case/Visit writes and all Vehicle/Model/ledger CRUD denied in actual per-user
object checks; sampled foreign-record denial confirmed. Foundation/profiles/membership/ledger
unchanged; portal already Live. Security validation PARTIAL: UserFieldAccess internal exception
stopped without retry; no connected browser, A/B browser UAT outstanding. Phase 8 NOT complete.
Evidence: `evidence/P8/DASHBOARD_RUNTIME_DEPLOYMENT/RESULT.md`.

**Historical password setup (§75):** standard Salesforce resets accepted for A/B at
2026-10-27T23:32:56Z; both audited and LastPasswordChangeDate advanced. Latest live setup audit
records owner change to All email. No reset/site-status error; inbox delivery still unverified.
Site remains UnderConstruction, no access/ownership/publication changes. Evidence:
`evidence/P8/CUSTOMER_PASSWORD_SETUP/RESULT.md`.

**Customer provisioning (§74):** ARO-aware provisioning SUCCEEDED. A User
005aj00000guQE9AAM / B User 005aj00000guQEAAA2 linked to approved Contacts, hardened Plus
profile, Foundation assigned, existing site membership criterion reused. Both use the verified
native owner-scoped PersonAccount role. Per-user effective access: own Contact/Account Read,
foreign denied, no Edit/Delete. Four existing ledger rows/dates unchanged. Site UnderConstruction;
Builder Save, email receipt/password setup, actual logins/UAT and Batch B security gate remain.
Evidence: `evidence/P8/CUSTOMER_PORTAL_SETUP/ARO_PROVISIONING/RESULT.md`.

**Historical §73:** approved resume completed Reviewer assignment, four
Verified synthetic seven-day Ownership/Service_Authorization rows and Foundation membership
criterion. Email precondition corrected case-insensitively without changing email values. Exactly
one User attempt rolled back at role check: expected Worker, actual PersonAccount; no Users
persist, role mapping unresolved. No second attempt or role relaxation. Customer assignments/
native-access proof and Builder Home Save pending; portal remains UnderConstruction. Evidence:
`evidence/P8/CUSTOMER_PORTAL_SETUP/RESUME_RESULT.md` and `resume_verification.json`.

**Historical §72:** owner-authorized customer setup STOPPED pending owner.
Only two approved synthetic Contact.Email updates completed. User creation hit an exact-case
email precondition before DML; no Users/invitations/assignments/membership/ledger rows created.
Builder blocked by Browser MCP version mismatch; no page inspected/saved. Site remains
UnderConstruction; no publication/write-UAT/jobs/Git. Do not retry or relax the assertion without
owner direction. Evidence: `evidence/P8/CUSTOMER_PORTAL_SETUP/RESULT.md`.

**Latest development handoff:** §71 records exact final Phase 8 development Quick Deploy
`0Afaj00000pPottCAC` Succeeded, 34/34, zero errors; reused `0Afaj00000pPiV7CAK` 43/43 tests
and 98.039% broker coverage. Deployed source matches validation; existing customer permissions/
users/memberships/shares/business fingerprints/pages/navigation/scheduler configs unchanged.
New ledger empty, internal Reviewer set unassigned; no native customer Vehicle CRUD. Site remains
UnderConstruction/never activated. No operational or Git changes; no Phase 8/M4 acceptance.
Evidence/shortest next setup sequence: `evidence/P8/BROKER_DEPLOYMENT/RESULT.md`.

**Historical §70:** records approved broker P8-05/P8-07 LOCAL completion: owned
Vehicle/photo DTOs and independent-consent/idempotent service requests through existing capacity/
intake. Check-only `0Afaj00000pPiV7CAK` Succeeded (34 components, 43/43 tests, 0 errors); local
UI/state/source tests 25/25. Broker coverage 98.039%. Native Vehicle/Model/ledger CRUD and Visit
Create stay denied; validated ledger source unchanged. No deployment/live/Git operations. Actual
customer/accessibility UAT and operational setup remain gated; no M4/Phase 8 acceptance. Evidence:
`evidence/P8/BROKER_COMPLETION/RESULT.md`; exact scope `manifest/p8-broker-local.xml`.

**Historical §69:** records bounded recovery: API 68 USER_MODE default plus missing
VIN/Reserved_By FLS on the test-created reviewer was the measured fixture cause. Separate internal
no-bypass fixture builder and explicit gated infrastructure modes corrected it; no customer grants.
Final check-only `0Afaj00000pNyKhCAK` Succeeded: 24 components, 11/11 tests, 0 errors. Ledger/
remove-only reconciler validated; no deployment/jobs. P8-05/P8-07 remain disabled pending one
server-mediated/no-native-CRUD architecture decision for exact-expiry isolation. Evidence:
`evidence/P8/OWNERSHIP_RECOVERY/RESULT.md`.

**Historical §68:** records accepted metadata corrections (SetNull and sharing reason
fullNames), zero component errors in check-only `0Afaj00000pPMPlCAO`, but 1/6 tests succeeded;
five fail on Vehicle field access at the shared fixture insert. Failed test work stopped. Independent
remove-only Batchable/Schedulable reconciler source prepared, not Salesforce-validated or activated.
Native clock expiry remains eventual under scheduling, not immediate API enforcement. P8-05/07
still incomplete/fail-closed. Evidence: `evidence/P8/OWNERSHIP_COMPLETION/RESULT.md`.

**Historical §67:** records local partial ownership-ledger source (27 files), scoped
validation `0Afaj00000pOJ7PCAW` Failed (14 component errors, 0 tests), no deployment. User lookup
Restrict and two missing SharingReason fullNames rejected; stopped under repository escalation.
Native timed-access revocation remains an unresolved security gate. P8-05/P8-07 remain fail-closed,
NOT completed. Evidence: `evidence/P8/OWNERSHIP_IMPLEMENTATION/OWNERSHIP_LOCAL_RESULT.md`.

**Historical §66:** records focused read-only operational readiness and the complete
ownership/access/placement/UAT approval package. No new deployment/tests or live changes. Guest
object/custom Apex grants zero; profile denies intact/unassigned; Plus 5/0 used. Site remains
UnderConstruction/never activated. A/B have no users or positive data. Prior export review found
no meaningful regression demonstrated and was not reopened. Live Builder inspection/tool TLS
limitations remain explicit. Phase 8 NOT operationally accepted. Current register:
`docs/planning/P8_OPERATIONAL_COMPLETION_REGISTER.md`.

**Historical §65:** records Batch C standard deployment `0Afaj00000pOUsQCAW`
Succeeded (6/6, zero errors/tests), exact validated source retrieved and matched. Quick Deploy
ineligible because validation ran zero tests. Users/permissions/members/shares/business fingerprints
and 65 page/site XML files unchanged; binary SiteDotCom export differs, owner review required.
Portal remains UnderConstruction/never activated. No operational changes or full acceptance.

**Historical §64:** records successful exact Batch B Quick Deploy `0Afaj00000pIP10CAG`
(10/10, 0 errors; reused 9/9 Apex tests, 86.667%). Both email flags now false; all prior profile
denies effective, no users/assignments/memberships/shares/business-record changes. Portal remains
unpublished. Batch C local UI/docs delivered; six-bundle check-only `0Afaj00000pJzGvCAK` passes,
19 local tests pass. No Batch C deployment or real-customer UAT/acceptance. Ownership and all
customer provisioning/site gates remain unresolved. Next metadata approval: six LWC bundles only.

**Historical handoff index (superseded statuses):** §63 records changed Batch B local implementation validated by
`0Afaj00000pIGp0CAG`: 10 components, 9/9 tests, 0 errors, 86.667% coverage; UI-state tests 12/12.
Explicit metadata CAN disable both remaining email flags (effective candidate assertions pass).
Live true-flag Plus persona reports EmailTemplate Create=true; keep unassigned pending approved
two-entry correction. Vehicles/appointments remain ownership-blocked; no deployment/Batch C.
§62 records profile-only correction deployment `0Afaj00000pJTk5CAG`
Succeeded (1/1, 0 errors/tests). Live 33 object/483 field/23 system denies effective, Case Create/Edit
off, EnableNotifications on. EmailAdministration/EmailTemplateManagement remain true: stopped,
profile still unassigned pending capability disposition. No Batch B deployment. §61 records local explicit-deny profile remediation and diagnosed Case
fixture ownership. Profile-only check-only `0Afaj00000pJ0QMCA0` succeeded; combined 10-component
check-only `0Afaj00000pILVGCA4` passed 12/12 tests, Batch B coverage 78.761%. Final strengthened
current-source run `0Afaj00000pIz4VCAS` also Succeeded, 12/12, 0 errors, 78.761%; no corrections deployed. Live profile remains
unassigned and still has Case Edit until approved remediation deployment. §60 records five-component foundation Quick Deploy `0Afaj00000pGvwECAS`
Succeeded. Live profile least-privilege is REFUTED (Case Create/Edit/default grants); unassigned,
no site/user/share changes. Batch B local nine-component package compiles but is blocked on Case
isolation assertion expected1/actual2 and 69.027% coverage (`0Afaj00000pGPzbCAG`); UI-state tests
7/7. Ownership policy still blocks vehicle/appointment positives. No Batch B deployment.
§59 records successful five-component check-only `0Afaj00000pHlunCAC`:
7/7 tests, 0 component/test errors, controller coverage 89.19%. Minimal test-only exact denial
assertion correction; no controller/profile/permission/seam changes this turn. Nothing deployed.
§58 records test compilation repairs: check-only `0Afaj00000pGnaUCAS`
compiles all five components, controller coverage 81.08%, but 6/7 tests pass. Remaining runtime
TypeException is the denied Contact write escaping a DmlException catch; no production security
change needed. Stop pending test-only exception assertion correction. §57 records private environment-fact seam and real-permission/isolation
test proposal implementation. Single check-only `0Afaj00000pHga9CAC` fails compilation (10 test
class errors, no tests/coverage run). Stop pending test-only compiler corrections. Hardened profile
unchanged; no deployment. §56 records test-only SOQL correction and single five-component
check-only `0Afaj00000pG0cJCAS`: 6/6 tests pass, 0 component/test errors, still 37.5% coverage.
Real external runAs denial/null Network assertions now pass; protected endpoint paths remain
unreached. Controller/profile unchanged. §55 records the single five-component check-only: custom-profile
test-user creation and external runAs succeed, but the fixture User→Profile relationship query
fails. Validation `0Afaj00000pGXlqCAG`: 5 passing/1 failing test, 0 component errors, 37.5% coverage.
No production/profile changes or retry. §54 records real Plus-user test investigation blocked by standard
external-profile user-creation policy; check-only `0Afaj00000pHSowCAG` has 5 passing/1 failing test,
0 component errors, 37.5% controller coverage. Stop pending scope decision; controller/profile
unchanged. §53 records the authorized test-only repair: 5/5 tests pass, but
check-only `0Afaj00000pHKg5CAG` still fails 37.5% controller coverage. No production defect found;
production testability refactor requires explicit approval. Profile/controller unchanged.
§52 records hardened-profile local preparation, successful profile
check-only and foundation check-only blocked on 37.5% controller coverage (3/3 tests pass).
No deployment or access changes. §51 records authorized creation of the unpublished Northgate Owner Portal
site (Network `0DBaj000006bf3xGAA`) with guest-access verification. §50 records authorized
two-customer fixture creation and verification. §49 records enabled Digital Experiences
verification and local foundation/security preparation. §§46–47 retain final Phase 7
deployment/status. Current scope: `docs/planning/P8_FOUNDATION_LOCAL_PREPARATION.md`.
Phase 5 was owner-accepted with documented exceptions on October 23, 2026.
**Phase 6: OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026.**
Batches 1–4 and the Knowledge/report blocker repairs are deployed. Ten internal Knowledge
Drafts/ten selections and corrected administrator report/source totals are verified. Every
documented operational/browser/publication/activation exception remains outstanding, not passed.
Phase 7 Batch 1 is deployed through separately authorized standard recovery: photographs 1/1,
then application 21/21, zero deployment errors. Prior 163/163 validation is reused; Developer
Edition deployments used NoTestRun. Actual deployed archive verifies all thirty photo hashes and
existing model-path compatibility. Browser/gallery/event acceptance, permissions/placement and
VIN credentials remain deferred; Batch 1 is not owner-accepted. Batch 2 is deployed: combined
application/removals 14/14 and separate territories 6/6, no new tests beyond reused 235/235
validation. NG_Rooftops remains Planning with persisted Read/None/None/None and zero associations/
memberships. Batch 2 is not owner-accepted; operational/persona/territory activation gates remain.
Final Batch 3 Draft prompt is deployed/inactive (1/1); Batch 4 header/new page deployed without
assignment/activation (2/2). Vehicle/all-app assignments, six settings, permissions/user-role
mappings, triggers and 27 business-object fingerprints match before/after. No tests rerun.
Agent Platform/Data Cloud, native agent/portal demos, full regression/DQ/clean release,
page placement/screenshots and live persona walkthroughs remain blocked/deferred. Phase 7 is
not fully accepted and M3 is not passed. Digital Experiences is now owner-enabled. Four local
Phase 8 read-only context/security definitions are prepared, not deployed; scoped server validation
compiled all four and passed 3/3 tests but failed coverage (§52); no external users
or shares. Two synthetic Account/Contact pairs now exist under the approved VP owner (§50). The
login-only Customer Service (Aura) site Northgate Owner Portal / `owners` now exists unpublished
(Network `0DBaj000006bf3xGAA`, Under Construction, self-registration off, guest profile with zero
object permissions and no ApexClass access; standard page/FLS defaults remain, §51). A hardened
portal profile is prepared and check-only validated, not deployed. Coverage repair approval,
then deployment and separately users/membership/shares remain gated; P8-01 is not fully accepted.
The earlier §21 closure candidate is retained as historical evidence. Historical
persona-switcher instructions below do not authorize changing the current separate Sales
and Finance identity decision or reclaiming either administrator account.
**Source of truth:** this Git repository (`force-app/` for metadata). Target orgs: `ng-dev` (build/UAT, `arjun.ngdev@northgate.demo`) and `ng-demo` (stable demos — never touch without explicit owner approval). No scratch orgs, ever.

> Legend: **[V]** = verified against repository/org evidence this session. **[O]** = owner-reported fact, not independently verifiable from the repo.

---

## 1. Project Overview

Northgate Motors is a fictional four-rooftop dealership group used as an advanced Salesforce demo across Admin, Developer, Analyst, Support, and light-architecture skill domains. Phases build lead-to-sale plus post-sale lifecycle. Key standing rules (AGENTS.md): backlog order; deploy from `force-app/`; validate before claiming; never touch `ng-demo` or other orgs; smallest safe change; stop-and-escalate with exact error + diff + last-verified state on unexpected failures (no speculative debugging loops).

**Persona model (master plan §Staff):** Salesforce-license users `ngadmin` (admin), `ngrep` (Sales Rep, role `Sales_Rep`), `ngsvc` (Service Advisor), `ngpersona` (Persona Switcher — manager/finance demos via `scripts/persona.sh <manager|finance>`); Platform users `nginv`, `ngtech`; integration `dms.integration`. Only 4 Salesforce licenses exist. Reporting uses 14 fictional `Staff__c` rows so dashboards group by staff without 14 logins.

## 2. Current Verified Status

- **Phase 1: DONE** [V — `evidence/P1/phase1_exit_report.md`, commit `dba455b`]. Users, PSGs, persona switch verified.
- **Phase 2: DONE** [V — M1 gate passed, tag `demo/v0.1` pushed]. End-to-end slice: lead → qualification → test drive → opportunity.
- **Phase 3: ACCEPTED AND CLOSED** [O — owner acceptance; technical evidence below supports it].
  - Commit **`638524df`** on branch **`main`**, 46 reviewed files, +3125/−10 [V — `git log`, `git show --stat`].
  - `origin/main` is **one commit behind; no push authorized** [V — `git status -sb`].
  - **24/24 regression tests passed** [V — run `707g800000okvJoAAI` (3 approval/summary suites); full-org suite 96–97/97 at close, sole failure a stale assertion fixed and re-verified].
  - Discount approval routing + write-back verified incl. live-persona evidence [V — `DiscountApprovalTest` 6/6].
  - Quote Builder + Quote Summary implemented; Quote Summary owner-accepted after live test as `ngrep` [O for acceptance; implementation V].
  - Page activations verified: `NG_Opportunity_Quote_Builder` (Sales / Retail / NG_Sales / Desktop) [O]; `NG_Quote_Summary` previously activated + accepted [O].
  - Six reports + Quote Health dashboard verified [O for UI acceptance; org inventory V — see §4].
  - CP2 pricing behavior preserved [V — no edits to engine/rules/quoteBuilder pricing path; 24/24].
  - Historical CP2 UAT Quote discrepancy intentionally preserved [O decision; see §8].
  - Unrelated working-tree modifications remain uncommitted [V — `git status`].

## 3. Architecture and Existing Functionality (preserve all of this)

**Data model** (`objects/` + `DEMO_ORG_DATA_MODEL.md`): standard Lead/Account/Contact/Opportunity/Quote/QuoteLineItem/Product2/PricebookEntry plus custom `Vehicle__c` → `Vehicle_Model__c`, `Trade_In__c`, `Rooftop__c`, `Staff__c`, `Loyalty_Member__c`, `Test_Drive__c`, `Financing__c`, `Delivery__c`, `Service_Visit__c`, `Consent__c`; metadata types `Price_Rule__mdt` (10 active rules), `Lead_Routing__mdt`, `Loyalty_Tier__mdt`, `Rate_Table__mdt` (Phase 4). Key custom fields: `Opportunity.Discount_Percent__c`, `Opportunity.Approval_Status__c`, `Opportunity.Vehicle__c`, `Opportunity.Sales_Staff__c`; `Quote.Adjusted_Subtotal__c`, `Quote.Rule_Applied_Count__c`, `Quote.Quote_Valid_Until__c`, `Quote.Buyer_Contact__c`.

**Pricing (CP2, simulated CPQ — see `docs/architecture/SIMULATION_CPQ.md`):** `QuotePricingService.evaluate` applies metadata rules in priority order (age/trim/loyalty/volume; trim premiums as negative discount). Signed net: positive = discount, negative = premium uplift. `QuoteBuilderController.createQuote` is **create-only** (always inserts a new Quote; never updates in place) and stamps Quote + Opportunity together. Zero list price guard returns 0.

**Apex/tests:** `QuoteBuilderController` (+`submitForApproval` tier derivation), `QuoteSummaryController` (read-only DTO), `DiscountApprovalTest` (6 tests), `QuoteBuilderControllerTest`, `QuoteSummaryControllerTest`, `QuotePricingServiceTest`, `TradeIn_Calc_Equity(+Test)`, `OpportunityTrigger`→`OpportunityStageStamp`, `QuoteTrigger`→`QuoteTradeInGuard`, `LeadRoutingTrigger`, `VehicleCounterTrigger`. Out-of-Phase-3 pre-existing: `LeadEnrichRooftopService*`, `Test_Screen_Flow` — do not assume scope.

**LWC:** `quoteBuilder` (catalog, buyer, Save-and-Price, Submit-for-Approval w/ needsApproval gate) on Opportunity page; `quoteSummary` (responsive SLDS grid, formatted currency/percent/date, Print/PDF, Open Opportunity via `uiRecordApi` OpportunityId wire) in Quote page header.

**Flows/automation:** per `AUTOMATION_DIRECTION.md`, no new project-owned Flows; P3-01 appraisal flow, `Trade_In_Appraisal`, quote gate trigger + guard preserved untouched.

**Security/personas:** profiles NG_Sales/NG_Service/NG_Inventory/NG_Admin; `PS_Sales_Rep` (+`Quote.GrandTotal` Read — the smoke-test fix), `PS_Quote_Fields_P3_04` (test FLS), PSGs incl. `PSG_Manager`/`PSG_Finance` (persona swap), `PSG_Rep`. Roles: `Sales_Rep` → `Sales_Manager_Downtown` → `VP_Sales` (+Airport/North siblings). Live chain as left: `ngrep.ManagerId` → `ngpersona`; `ngpersona` role VP_Sales (see §8 — must be restored for normal demos).

**Approvals (the hard-won design — do not redesign without new evidence):**
- `Opportunity.Opportunity_Discount_Approval` (Active): entry `>5 AND ≤10`, single adhoc manager step. `Opportunity.VP_Discount_Approval` (Active): entry `>10`, single adhoc VP step.
- Why two processes: proven by runtime probe — a step whose entry criteria are missed **final-approves the record** (`ifCriteriaNotMet=ApproveRecord`), so a later step can never catch the >10% branch. Criteria-miss ≠ skip-to-next-step.
- `managerOfSubmitter`/`role` are NOT valid `NextOwnerType` enum values (deploy-proven); `userHierarchyField` requires `nextAutomatedApprover`; queue routing changes workitem ActorId to the queue Group (breaks individual-actor assertions). Submission derives approvers (`ManagerId` chain / oldest active `VP_Sales` user) with tier guards; test isolation does NOT hide live Users (observed behavior — doc assumption withdrawn).
- Final actions set `Approval_Status__c` Approved/Rejected via `Opportunity.workflow-meta.xml` field updates.
- Approval filename convention that unblocked deployment: `Object.Name.approvalProcess-meta.xml` (bare name caused server UNKNOWN_EXCEPTION).

**Reports/dashboards:** folders NG_01_Pipeline, NG_02_Leads, NG_05_DataQuality, NG_Sales (Public). Reports: Pipeline by Stage, Open Opps by Sales Staff, Discount Leakage, Win/Loss by Reason, Stale Open Quotes (owner-built `Stale_Open_Quotes_rpa`, TODAY filter verified). Dashboard `DM_QuoteHealth` (org DeveloperName `wmJfrbDSELUkweOHuzWNpCXeWLvZue`) with 4 widgets. Custom `QuoteList` ReportType deployed. Known quirk: report `<reportType>` for custom types uses `CustomEntity$Quote` form; report columns use `Quote$Field` form.

## 4. Phase 1–3 Completion Record

- **Phase 1** (commit `dba455b`): users, roles, PSGs, persona switch, CI green. Acceptance: phase exit report.
- **Phase 2** (`demo/v0.1`): vertical slice + M1 gate (dry-run clean, tests 100%, DQ 0 rows, signed UAT_P2).
- **Phase 3** (commit `638524df`): trade-in accepted scope (P3-01, 5 equity scenarios); price rules deployed (10 records); quote builder + pricing service + tests; two approval processes + 6/6 routing tests incl. live persona; Quote Summary LWC + page + smoke acceptance; submission service + tier-guard tests; 6 reports + dashboard + folders + custom ReportType; GrandTotal FLS fix. Deferred (explicit): P3-01 sales-manager screenshots, per-run record correlation, UI field-validation review.

## 5. Critical Architectural Decisions (do not revisit without evidence)

1. Two single-step approval processes (probe-proven; §3).
2. Submitter-derived approvers + tier guards in code; adhoc steps; assertions on individual ActorIds preserved.
3. `createQuote` is create-only; re-price creates a sibling Quote, never updates in place.
4. Signed net percent (negative = premium); no clamp-to-zero.
5. `System.runAs` persona testing (admin context masks FLS gaps); ownership transfer in fixtures for sharing.
6. Test-context User queries observe live users (observed, not assumed).
7. Page assignments are UI-only in this org (no metadata/API path — proven absent).

## 6. Validation and Deployment Evidence

- `DiscountApprovalTest` 6/6 (manager/VP approve, rejection, no-self-approve, 2 live-persona) with `Approval_Status__c` write-back.
- `QuoteBuilderControllerTest` incl. tier guards; `QuoteSummaryControllerTest` 3/3 incl. GrandTotal guard; combined runs 24/24, 100%.
- Deploy jobs all Succeeded (approval filename fix, field updates, code bundles, permission set, folders, ReportType, Win/Loss + Leakage reports).
- `NG_Quote_Summary` + `NG_Opportunity_Quote_Builder` activations owner-verified [O]. Report TODAY filter verified in retrieved XML [V]. Dashboard 4/4 refs resolve [V].

## 7. Git and Working-Tree Status

- HEAD `638524df` on `main`, 46 files, ahead of `origin/main` by 1 — **do not push without approval**.
- Staged in the commit: approval processes, workflow updates, all listed controllers/tests, both LWCs, both FlexiPages, VP queue, both permission sets, QuoteList type, 3 reports + Stale report, both folder files, live dashboard file, Quote fields, Price_Rule__mdt, PG_All_Sales group, persona.sh vp case, P3-06 backlog line.
- Still uncommitted (preserve): `BUILD_STATUS.md`, `DEMO_ORG_MASTER_PLAN.md`, backlog P7-18 hunk, out-of-scope sets (`LeadEnrich*`, `QuoteTradeInGuard*`, `TradeIn*`, `Test_Screen_Flow`, `backup_flows/`), `docs/`, `evidence/`, `audit/` drafts, `.DS_Store`. Removed (approved): superseded `Quote_Expiring` + draft dashboard sources.

## 8. Outstanding Issues and Deferred Work (genuine only)

1. **Live personas diverted for approval demo:** `ngpersona` is VP_Sales+PSG_Manager and `ngrep.ManagerId`→ngpersona. Restore via `scripts/persona.sh finance` + clear `ngrep.ManagerId` (was null) before normal demos.
2. **Stale CP2 UAT Quote `0Q0g80000022CS9CAM`** (Adjusted 28000/Rules 0 vs opp stamp −2.85%): pre-FLS-fix partial write; engine verified correct on sibling Quote. Owner decision: preserve untouched. Re-price creates a sibling; never updates in place.
3. **Dashboard cosmetics:** live Donut header has trailing "."; folder files carry env-specific shares (admin username) — harmless, note before fresh-org reuse.
4. **P3-01 deferred checks** (manager screenshots, record correlation, UI validation) — explicitly deferred, not passed.
5. **Report `sortColumn`/operator/autoFit local fixes** applied to deployed-or-superseded files; live dashboard/file state governs.

## 9. Phase 4 Scope and Prerequisites (from backlog — do not redesign)

Official scope (backlog Phase 4): P4-01 payment calculator → P4-02 finance wizard flow → P4-03 status lifecycle + VRs → P4-04 `Rate_Table__mdt` mapping → P4-05 finance-approval record path (Finance Manager) → P4-06 delivery checklist + VRs → P4-07 delivery closes opp (`Delivery_Completed__c`, VR-gated) → P4-08 loyalty enrolment → P4-09 finance reports. Gate: full retail deal lead→delivered with financing + approvals. Integrates with: Opportunity/Vehicle/Quote/approval foundations, `Financing__c`/`Delivery__c` objects (exist in source), `Rate_Table__mdt`, Finance roles/queues (`Q_Finance_Approvals`, `Finance_Manager` role), persona switcher (restore first). Open decisions: P4-05 approval mechanism (reuse two-process pattern), delivery/Closed-Won VR interplay. Suggested order: P4-01 → P4-04 → P4-03 → P4-02 → P4-05 → P4-06 → P4-07 → P4-08 → P4-09.

## 10. Recommended Next Actions

1. Owner declares Phase 3 complete (or lists deltas).
2. Restore personas (§8.1) unless approval demo continues.
3. Optional: push `main` (approval required).
4. Begin Phase 4 at P4-01 only after approval of this handoff.

## 11. Phase 4 Progress — ACCEPTED AND CLOSED (P4-01 through P4-09)

**Phase 4 status: ACCEPTED AND CLOSED** [O — owner sign-off after browser UAT for P4-02, P4-05, P4-06, P4-07, P4-08, P4-09]. CP2 pricing and Phase 3 approvals remain unchanged and verified intact. Phase 4 built so far (all deploy jobs Succeeded unless noted):

- **P4-01 Payment calculator:** `PaymentCalculatorService(+Test)` — deployed `0Afg800000HLNvtCAH`, 5/5 tests [V]. **ACCEPTED.**
- **P4-02 Finance wizard:** ACCEPTED. `FinanceApplicationController(+Test)`, LWC `financeApplication`, QuickAction `Opportunity.Finance_Application`, `Financing__c.Quote__c` lookup, `PS_Finance_Wizard_Access`. Business rules D-A…D-E as coded (selling price from `Quote.Adjusted_Subtotal__c`; `Amount_Financed__c = Adjusted_Subtotal__c − Down_Payment__c − signed Trade_Equity__c`; one Draft per Opportunity). Deployment set: class access `0Afg800000HTGlyCAH`, wizard PS `0Afg800000HT52YCAT`, CMT/preview `0Afg800000HTcCzCAL` (20/20).
   - **Applicant/buyer fix:** root cause = applicant control was a free-text `lightning-input` whose handler set `applicantContactId` to a raw string, passed to the Apex `Id applicantContactId` parameter → invalid Contact. Fixed by switching to `lightning-record-picker` (object `Contact`) and reading `event.detail.recordId || null`; +1 test `applicantRequired_whenNoApplicantAndQuoteBuyerNull_isRejected`. Deployed `0Afg800000HaFl7CAF` (validation `0Afg800000HZtf4CAD`, 16/16).
   - **Browser verification: PASSED** [O — owner-run in the Salesforce browser UI]. Financing record `a03g800000rzfMHAAY` displayed Quote "NG CP2 Browser UAT - Quote"; Status Draft; Applicant "P1-14Test"; Amount Financed $30,340; Monthly Payment $579.39; Total Interest $4,423.40. No Accepted `Trade_In__c` rows → trade equity 0; 30,340 − 0 − 0 = 30,340 reconciles.
- **P4-03 Status lifecycle:** ACCEPTED. `FinancingStatusService(+Test)` + `FinancingTrigger` + `VR_Financing_TermRequired` — deployed `0Afg800000HPct7CAD`, 18/18 tests [V].
- **P4-04 Rate table:** ACCEPTED. `RateTableService(+Test)` + `Rate_Table__mdt` (30 active + 1 inactive records) — deployed `0Afg800000HPAATCA5`, 5/5 tests [V]. CMT read required explicit Custom Metadata Type Access in the permission set (org restricts CMT access by default).
- **P4-05 Finance Manager approval:** ACCEPTED [O]. `Financing__c.Financing_Exception_Approval` approval process + `Financing.workflow-meta.xml` field updates (Approved → `Finance_Exception_Approved__c=true` + `Decision_Date__c=TODAY()`; Rejected → `false`) + `FinancingApprovalService` (idempotent submitForExceptionApproval) + LWC `submitFinancingApproval` + QuickAction + `FinanceApplicationController` extended. Deployed `0Afg800000HdzWTCAZ` (Workflow + ApprovalProcess, 5/5 components, 0 errors, 156/156 tests). Approval process is ACTIVE in ng-dev; routing verified: `Q_Finance_Approvals` → role `Finance_Manager`. Field rename `Exception_Approved__c` → `Finance_Exception_Approved__c` (see §12) was required to clear an orphaned-metadata state. **Finance Manager queue membership prerequisite (NOT a defect, documentation only):** the `Q_Finance_Approvals` queue routes to the `Finance_Manager` role. For a workitem to be approvable, at least one active user must hold `Finance_Manager`. `ngpersona` cannot be modified (preserves `VP_Sales` + `PSG_Manager`). Owner temporarily assigned `Finance_Manager` to `ngadmin` for the UAT window, then reverted. For future UAT cycles, the same temporary assignment is required.
- **P4-06 Delivery checklist + VR:** ACCEPTED [O]. `VR_Delivery_ChecklistBeforeCompleted` is ACTIVE in ng-dev (verified by Tooling: `Active=true`, formula `AND(NOT($Permission.Bypass_Automation), ISPICKVAL(Status__c, "Completed"), OR(NOT(Checklist_Documents__c), NOT(Checklist_Inspection__c), NOT(Checklist_Signature__c), NOT(Checklist_Walkthrough__c)))`, error message "All four checklist items must be completed before marking delivery Completed."). Browser UAT [O]: **Delivery completion blocked when checklist items were incomplete** (the VR fired with the error message displayed on `Status__c`); **Delivery completed successfully after all four checklist items were checked** (save succeeded, `Completed_Date__c` auto-stamped to today by the trigger). All 4 `Delivery__c` checklist fields (`Checklist_Documents__c`, `Checklist_Inspection__c`, `Checklist_Walkthrough__c`, `Checklist_Signature__c`) and the `Checklist_Complete__c` formula are deployed and queryable.
- **P4-07 Delivery closes opportunity:** ACCEPTED [O]. `DeliveryTrigger` (after insert/update) + `DeliveryCloseService.handleCompleted`. Browser UAT [O]: **Associated Opportunity automatically transitioned to Closed Won** (and `Opportunity.Delivery_Completed__c = true`) when Delivery Status was set to Completed with all four checklist items ticked. `Delivery.Completed_Date__c` auto-stamped to today. Verified in `DeliveryCloseServiceTest` (5 tests, all pass).
- **P4-08 Loyalty enrollment:** ACCEPTED. Two deploy jobs:
   - **P4-08 main deploy:** Job `0Afg800000HeoZ0CAJ` (`checkOnly: False`). **2 of 2 components deployed** (`ApexClass: DeliveryCloseService`, `ApexClass: DeliveryCloseServiceTest`). **Apex tests: 160 of 160 passed** (156 pre-existing + 4 new late-buyer tests in `DeliveryCloseServiceTest`: `completedDeliveryWithBuyerAtCompletion_enrols`, `buyerAddedAfterCompletion_enrolsOnLateAssignment`, `repeatedUpdatesAfterCompletion_doNotDuplicateEnrolment`, `buyerReplacement_doesNotAutoEnrolNewBuyer`). 0 component failures, 0 test failures. The deploy addressed a defect identified in local validation: the original `DeliveryCloseService` only acted on the Status→Completed transition, so a Buyer populated AFTER delivery completion did not trigger loyalty enrollment. The fix adds an `enrolLateBuyers` pass that detects a null→value `Buyer__c` transition on an already-Completed delivery and calls `LoyaltyEnrolmentService.enrolOnDelivery`. Buyer-replacement (non-null → different non-null) does NOT auto-enroll, per the intended business rule. Idempotency preserved (repeated updates do not create duplicates). P4-07 close behavior unchanged.
   - **One-time approved loyalty backfill:** owner authorized backfill of Delivery 0 (`a02g800000EjTXFAA3`, Buyer = P1-14Test `003g800000q7EzZAAU`, Status = Completed, Completed_Date = 2026-10-15, Opportunity `006g8000009XEVFAA4` Closed Won). Invoked `LoyaltyEnrolmentService.enrolOnDelivery` via `sf apex run` (anonymous Apex). **Loyalty Member Id `a04g8000002slf7AAA`**, Member Number `NG-7904-0782`, Contact P1-14Test, Status Active, Tier Bronze, Points 0. Delivery remained Completed. Opportunity remained Closed Won. No duplicate membership (org-wide Loyalty_Member__c count = 1). **Observation, NOT an automatically authorized repair:** `Contact.Lifetime_Vehicles_Owned__c` remained `null` after the backfill. This is expected: the backfill invoked the *service* directly, which does not touch `Contact.Lifetime_Vehicles_Owned__c` (the trigger path does). The lifetime increment is the trigger's responsibility, and the trigger was not fired by the direct service call. The original Delivery 0 completion was performed with `Buyer__c` blank, so the trigger's first loop `toProcess` filter (which increments lifetime) did not increment lifetime. Whether lifetime should be incremented to 1 for Delivery 0 is a business decision and is NOT automatically authorized here. The late-Buyer path has automated test coverage (`buyerAddedAfterCompletion_enrolsOnLateAssignment`); do not misrepresent the one-time backfill as browser verification of the trigger's late-buyer enrollment path — the backfill was a direct service invocation, not a UI trigger fire.
- **P4-09 Finance reports:** ACCEPTED [O]. `Financing_Mix_by_Status` (NG_01_Pipeline) + `Funding_Lag` (NG_05_DataQuality) + new `FinancingList` report type. Browser UAT [O]: **Financing Mix by Status report opened successfully**. **Funded-only filter confirmed**. **Both existing Financing records were Draft, explaining the original zero results**. **Temporary filter adjustment displayed 2 records** (the test P4-02 financing record plus the new UAT financing record, both in Draft because the UAT flow did not progress the lifecycle to Funded). **Total Amount Financed: $60,680** (sum of the two Draft records' Amount_Financed__c). **Total Monthly Payment: $579.39**. **Credit Tier A and Rate Source Manual Exception displayed**. **Owner restored the Funded-only filter** after verification. Browser UAT accepted.

**Phase 4 M2 gate (per handoff §9 / backlog):** a full retail deal from lead to delivered with financing + approvals is now complete end-to-end. Gate met.
- **P4-03 Status lifecycle:** `FinancingStatusService(+Test)` + `FinancingTrigger` + `VR_Financing_TermRequired` — deployed `0Afg800000HPct7CAD`, 18/18 tests [V].
- **P4-04 Rate table:** `RateTableService(+Test)` + `Rate_Table__mdt` (30 active + 1 inactive records) — deployed `0Afg800000HPAATCA5`, 5/5 tests [V]. CMT read required explicit Custom Metadata Type Access in the permission set (org restricts CMT access by default).
- **P4-02 Finance wizard:** `FinanceApplicationController(+Test)`, LWC `financeApplication`, QuickAction `Opportunity.Finance_Application`, `Financing__c.Quote__c` lookup, `PS_Finance_Wizard_Access`. Business rules D-A…D-E as coded (selling price from `Quote.Adjusted_Subtotal__c`; `Amount_Financed__c = Adjusted_Subtotal__c − Down_Payment__c − signed Trade_Equity__c`; one Draft per Opportunity). Deployment set: class access `0Afg800000HTGlyCAH`, wizard PS `0Afg800000HT52YCAT`, CMT/preview `0Afg800000HTcCzCAL` (20/20).
  - **Applicant/buyer fix (this session):** root cause = applicant control was a free-text `lightning-input` whose handler set `applicantContactId` to a raw string, passed to the Apex `Id applicantContactId` parameter → invalid Contact. Fixed by switching to `lightning-record-picker` (object `Contact`) and reading `event.detail.recordId || null`; +1 test `applicantRequired_whenNoApplicantAndQuoteBuyerNull_isRejected`. Deployed `0Afg800000HaFl7CAF` (validation `0Afg800000HZtf4CAD`, 16/16).
  - **Browser verification: PASSED** [O — owner-run in the Salesforce browser UI]. Financing record `a03g800000rzfMHAAY` displayed Quote "NG CP2 Browser UAT - Quote"; Status Draft; Applicant "P1-14Test"; Amount Financed $30,340; Monthly Payment $579.39; Total Interest $4,423.40. No Accepted `Trade_In__c` rows → trade equity 0; 30,340 − 0 − 0 = 30,340 reconciles. **P4-02 accepted**; no additional SOQL verification required.
  - **Admin SOQL access limitation (known FLS restriction — NOT an acceptance blocker):** `arjun.ngdev` has no field-level security on `Financing__c.Quote__c`, so the org masks the field as `No such column 'Quote__c'` in SOQL/API responses. The Quote association is confirmed by the browser verification above; no temporary permission grant will be made.
- **UI metadata reconciliation:** the owner manually configured `ng-dev` (added Financing to the Northgate Sales app navigation; updated the Financing page layout) outside git. Both were retrieved via the Metadata SOAP API and reconciled into source: `applications/Northgate_Sales.app-meta.xml` and `layouts/Financing__c-Financing Layout.layout-meta.xml` [V — byte-identical to org retrieve]. Note: `sf project retrieve start` skips these because org-side source tracking does not track UI-created metadata; use the Metadata SOAP API to retrieve such components.

**Next: Phase 4 accepted and closed. Proceed to Phase 5 (synthetic data load + reporting depth) per the approved backlog.** Phase 4 met the M2 gate (lead→delivered with financing + approvals). Git: no commits made for Phase 4; the Phase 3 commit `638524df` remains the most recent committed change. Phase 4 implementation, tests, layouts, reports, permission sets, queue, approval process, workflow, triggers, and LWCs are all present in the working tree as untracked files (see §14 Git Status). No commits, no pushes were authorized.

## 12. Phase 4 — deployment and closure record

Phase 4 was built locally in `force-app/` against the existing P4-01..P4-04 + Phase 3 foundations. The deployment history (real deploys to `ng-dev` only, in deployment order):

- **P4-01..P4-04** (deployed earlier; recorded in §11): `0Afg800000HLNvtCAH` (5/5), `0Afg800000HPct7CAD` (18/18), `0Afg800000HPAATCA5` (5/5), `0Afg800000HTcCzCAL` + `0Afg800000HTGlyCAH` + `0Afg800000HT52YCAT` (P4-02 + applicant fix, 20/20 then 16/16).
- **Field rename deploy** `0Afg800000Hcdt4CAB` (P4-05 prerequisite): `CustomField Financing__c.Finance_Exception_Approved__c` Succeeded (1/1). The earlier `Exception_Approved__c` field was stuck in an orphaned-metadata state (Tooling record without DB column); the rename produced a clean field.
- **P4-05 Workflow + Approval Process** `0Afg800000HdzWTCAZ` (`checkOnly: False`, Succeeded, 5/5 components, 0 errors, 156/156 Apex tests). Workflow `Financing__c` and Approval Process `Financing__c.Financing_Exception_Approval` deployed; approval process is **ACTIVE** in `ng-dev`. Field updates `Financing_Exception_Approved` (LiteralValue = `true`) and `Financing_Exception_Rejected` (LiteralValue = `false`) confirmed via Tooling (`WorkflowFieldUpdate` query, both present, both target `Finance_Exception_Approved__c`).
- **P4-05 field / write-back validation (owner browser UAT)**: approval submitted by `ngpersona`, routed to `Q_Finance_Approvals`, approved by `ngadmin` (temporarily holding `Finance_Manager`). Approval History shows Approved. `Finance_Exception_Approved__c` automatically changed to `TRUE`. `Decision_Date__c` populated to `2026-10-15`. Owner corrected the existing workflow field update in Setup from False to True (consistent with the deployed source). `ngadmin` role reverted to None.
- **P4-08 late-Buyer fix deploy** `0Afg800000HeoZ0CAJ` (`checkOnly: False`, Succeeded, **2 of 2 components deployed**: `ApexClass: DeliveryCloseService`, `ApexClass: DeliveryCloseServiceTest`, **0 component failures**, **Apex tests: 160 of 160 passed**). The deploy addressed the late-Buyer enrollment defect identified in local validation. No `DeliveryTrigger` redeployed (unchanged), no unrelated metadata.
- **P4-08 one-time approved loyalty backfill** (owner-authorized, single Salesforce data change): invoked `LoyaltyEnrolmentService.enrolOnDelivery` once via `sf apex run` on Delivery `a02g800000EjTXFAA3` (Buyer = P1-14Test `003g800000q7EzZAAU`, Status = Completed). **Loyalty Member Id `a04g8000002slf7AAA`**, Member Number **`NG-7904-0782`**, Status **Active**, Tier **Bronze**, Points **0**, Join_Date 2026-10-15, Last_Activity_Date 2026-10-15. Delivery remained Completed. Opportunity remained Closed Won. No duplicate membership (org-wide Loyalty_Member__c count = 1). **Observation, not an automatically authorized repair:** `Contact.Lifetime_Vehicles_Owned__c` remained `null` (the backfill invoked the service directly, not the trigger; the service does not touch Contact lifetime; the original Delivery 0 completion was performed with `Buyer__c` blank, so the trigger's first-loop lifetime increment did not fire). Whether lifetime should be incremented to 1 for Delivery 0 is a business decision and is NOT automatically authorized. The late-Buyer path has automated test coverage (`DeliveryCloseServiceTest.buyerAddedAfterCompletion_enrolsOnLateAssignment`); do not misrepresent the one-time backfill as browser verification of the trigger's late-buyer enrollment path — the backfill was a direct service invocation, not a UI trigger fire.
- **P4-09 reports browser UAT (owner)**: `Financing Mix by Status` report opened successfully. Funded-only filter confirmed. Both existing Financing records were Draft, explaining the original zero results. Temporary filter adjustment displayed 2 records. Total Amount Financed $60,680. Total Monthly Payment $579.39. Credit Tier A and Rate Source Manual Exception displayed. Owner restored the Funded-only filter.

### Outstanding prerequisites and manual steps (not defects; not resolved by code)

- **Finance Manager queue membership prerequisite (P4-05 future UAT)**: the `Finance_Manager` role has zero active members. The `Q_Finance_Approvals` queue routes to this role. For a workitem to be approvable, at least one active user must hold `Finance_Manager`. `ngpersona` cannot be modified (preserves `VP_Sales` + `PSG_Manager`). For future UAT cycles, the owner must temporarily assign `Finance_Manager` to `ngadmin` and revert. This was performed for the prior P4-05 UAT and is documented as a recurring prerequisite, not a code/automation defect.
- **Approval process activation (P4-05)**: `Financing_Exception_Approval` is ACTIVE in `ng-dev` (verified). No activation action required.
- **QuickAction on Financing page layout highlights panel (P4-05)**: the `Submit_For_Exception_Approval` QuickAction was not added to the Financing__c page layout's "Salesforce Mobile and Lightning Experience Actions" list in Setup during this session. The QuickAction is deployed as a new record action but does not surface in the highlights panel until a Setup click adds it. This is a one-time, optional owner Setup step (not a code defect; the metadata `Layout` schema does not support a quick-action list element, confirmed by an earlier dry-run parse error).
- **Pre-existing source-format artifact (2 Phase 3 files)**: `workflowFieldUpdates/Approval_Status_{Approved,Rejected}.workflowFieldUpdate-meta.xml` are listed in the auto-generated `package.xml` but not zipped by the source format (source inlines field updates in the Workflow XML; the separate files are mdapi leftovers already deployed in Phase 3). Out of scope and not modified. The P4-05..P4-09 deploys used a manifest that excluded the `WorkflowFieldUpdate` type to avoid this artifact.
- **`Contact.Lifetime_Vehicles_Owned__c` for Delivery 0**: observation only. The trigger's first-loop lifetime increment did not fire when Delivery 0 was originally completed (Buyer was blank). The one-time backfill did not increment it. Not an automatically authorized repair.
- **P4-04 LTV eligibility** is still Draft-only; the true LTV source and the valuation tool remain a Phase 5+ decision.

### Design notes carried forward (do not redesign without evidence)

- CP2 pricing engine and Phase 3 approvals are untouched and verified intact.
- The `Financing_Exception_Approval` process does **not** modify `Opportunity.Approval_Status__c`; that field is owned by the two Phase 3 Opportunity processes. `Finance_Exception_Approved__c` is a Financing-side boolean that records the Finance Manager's exception decision; the Financing lifecycle (`Submitted → Conditional → Approved → Funded`) moves independently.

## 14. Git status (Phase 4 closure snapshot)

- **Branch:** `main`.
- **Local HEAD:** `638524df06db2652236a2693d8b2191054116a8b` (the existing Phase 3 commit `638524df` recorded in the handoff §2/§7).
- **Remote `origin/main`:** `b2438bf9864bbe39b6fb7298d804ca44911c294e`. Local is **1 commit ahead of `origin/main`** (same ahead-of-origin state recorded in the prior handoff §7; the Phase 3 commit was never pushed).
- **Tracked modified (`M`) — 11 files:** `BUILD_STATUS.md`, `DEMO_ORG_BACKLOG.md`, `DEMO_ORG_DATA_MODEL.md`, `DEMO_ORG_MASTER_PLAN.md`, `docs/security/PERMISSION_MATRIX.md`, `force-app/main/default/objects/Financing__c/Financing__c.object-meta.xml`, `force-app/main/default/objects/Financing__c/validationRules/VR_Financing_TermRequired.validationRule-meta.xml`, `force-app/main/default/permissionsets/PS_Finance_Officer.permissionset-meta.xml`, `force-app/main/default/permissionsets/PS_Sales_Rep.permissionset-meta.xml`, `force-app/main/default/queues/Q_Finance_Approvals.queue-meta.xml`, `sfdx-project.json`. None of these M files were modified by the Phase 4 closure session beyond what was already in the working tree at the start of the session (the pre-existing M set was preserved as-is). No new M files were introduced by this session.
- **Staged (`A` / staged) — 0 files.** Nothing has been staged for commit during this session.
- **Untracked (`??`) — Phase 4 implementation files present in the working tree** (all previously untracked, not part of any commit): `force-app/main/default/classes/DeliveryCloseService.cls`, `DeliveryCloseServiceTest.cls`, `DeliveryCompletionGuardTest.cls`, `FinanceApplicationController.cls`, `FinanceApplicationControllerTest.cls`, `FinancingApprovalService.cls`, `FinancingApprovalTest.cls`, `FinancingStatusService.cls`, `FinancingStatusServiceTest.cls`, `LoyaltyEnrolmentService.cls`, `LoyaltyEnrolmentServiceTest.cls`, `force-app/main/default/triggers/DeliveryTrigger.trigger`, `force-app/main/default/objects/Financing__c/fields/Finance_Exception_Approved__c.field-meta.xml`, `workflows/Financing__c.workflow-meta.xml`, `approvalProcesses/Financing__c.Financing_Exception_Approval.approvalProcess-meta.xml`, `queues/Q_Finance_Approvals.queue-meta.xml` (queue file exists in working tree; the prior handoff noted it was pre-existing), `permissionsets/PS_Finance_Officer.permissionset-meta.xml` (also pre-existing M), `permissionsets/PS_Sales_Rep.permissionset-meta.xml` (also pre-existing M), `layouts/Financing__c-Financing Layout.layout-meta.xml` (M), `layouts/Delivery__c-Delivery Layout.layout-meta.xml`, `layouts/Loyalty_Member__c-Loyalty Member Layout.layout-meta.xml`, `applications/Northgate_Sales.app-meta.xml`, `flexipages/Financing_Record_Page.flexipage-meta.xml`, `Delivery_Record_Page.flexipage-meta.xml`, `Loyalty_Member_Record_Page.flexipage-meta.xml`, `lwc/submitFinancingApproval/`, `quickActions/Financing__c.Submit_For_Exception_Approval.quickAction-meta.xml`, `reportTypes/FinancingList.reportType-meta.xml`, `reports/NG_01_Pipeline/Financing_Mix_by_Status.report-meta.xml`, `reports/NG_05_DataQuality/Funding_Lag.report-meta.xml`, `manifest/p4-05-09-manifest.xml`, `manifest/finance-exception-approved-only.xml`, `manifest/workflow-and-approval.xml`. The untracked `NORTHGATE_PROJECT_HANDOFF.md` is the file being authored by this session.
- **Commit and remote status:** **No commits made during the Phase 4 closure session.** The local `main` branch remains **1 commit ahead of `origin/main`** (the pre-existing Phase 3 commit, never pushed). **Do not mark Git synchronization complete** — there is no evidence of `git push` having been authorized or performed. The owner has not authorized a commit, push, or PR for the Phase 4 changes.
- **Other untracked items** (pre-existing, out of Phase 4 scope, not modified by this session): `.DS_Store` files throughout the tree, `audit/`, `backup_flows/`, `docs/.DS_Store`, `docs/architecture/`, `docs/planning/`, `docs/verification/`, `evidence/.DS_Store`, `evidence/P2/.DS_Store`, `evidence/P3/`, `evidence/P4/`. None of these are Phase 4 deliverables.

## 13. Resuming in a New ChatGPT Conversation

Paste this file's path plus: "Target org alias `ng-demo` only; never access `ng-dev`; read AGENTS.md and this handoff first; backlog order; validate before claiming; stop-and-escalate with exact error + diff + last-verified state; no commits or pushes; CP2 + Phase 3 + P4-01..P4-09 behavior above is closed — verify, don't redo; Phase 4 accepted and closed (see §11/§12); Phase 5 data load is complete, with P5-03/P5-05 evidence and SEED-98 deferred."

## 15. Planned end-to-end walkthrough (owner requirement)

After Sales Rep UAT and P3-DEF-01 remediation, ChatGPT will guide the owner through the entire
Northgate Motors dealership workflow, including which Salesforce user and app to use at each
stage. The walkthrough will validate the connected experience from Lead → Opportunity → Quote
→ Discount Approval → Financing → Delivery → Closed Won → Loyalty, including departmental
handoffs, navigation, permissions, and expected results. Use this walkthrough to validate
Phase 2 workflows; keep Phase 2 `UNVERIFIED` until evidence and owner sign-off exist.

Do not execute walkthrough until owner initiates it.

## 16. 2026-10-20 Sales Rep UAT and P3-DEF-01 completion

- Owner reports browser PASS for Loyalty Members → All (50+ rows), Deliveries → All
  (13 rows), Pipeline by Stage (81 Opportunities; `$4,827,766`), Loyalty Tier Distribution
  (12 members), and `DM_DealDesk` access/render (three metrics). Dashboard values displayed
  zero; metric accuracy remains unverified. Loyalty report description is outdated,
  nonblocking cleanup. Results: `evidence/UAT/live_2026-10-19/REP_UAT_COMPLETED_2026-10-20.md`.
- Owner confirms Delivery tab visible in latest Northgate Sales screenshot. Do not deploy
  another tab permission change without new evidence. Existing `PS_Sales_Rep` source/live
  permission differences remain undeployed and must not be swept into unrelated deployments.
- Before persona restore, pending approvals/work items submitted by or assigned to
  `ngpersona` both returned 0. `finance_pre_restore_guard.apex` returned `PASS`, with 0
  pending finance approvals and 0 queue work items.
- `scripts/persona.sh restore` completed. Live user verified: role `VP_Sales`, profile
  `NG_Sales`, `ManagerId=null`; no managed persona PSGs. Unrelated PermissionSet assignments
  `X00eaj00000TnZaFAAV` and `NG_Lightning_Experience_Access` remained unchanged.
- Initial check-only `0Afaj00000oOEWUCA4` failed 13/14 because no active `VP_Sales` user
  existed while persona was rep. After restore, exact two-class check-only `0Afaj00000oNfTyCAK`
  passed 14/14. Exact deploy `0Afaj00000oON8LCAW` succeeded with 14/14. Focused run
  `707aj00001McoRy` passed 15/15 results (14 test methods plus `setup`).
- `scripts/uat/rep_verify.apex` returned `PASS`: one Opportunity, one Quote, one QLI;
  Quote `00000069` retained CP2 subtotal `50615`, adjusted subtotal `43022.75`, and one rule.
- No approval was submitted, no historical record changed, no Phase 5 ledger rows inserted,
  and no canonical data reload/reset occurred. Phase 2 remains `UNVERIFIED`; P5-03/P5-05
  evidence and `SEED-98` remain deferred.

## 17. Remaining acceptance investigation — 2026-10-20

See `docs/planning/REMAINING_ACCEPTANCE_2026-10-20.md`. Read-only investigation confirms
empty Leads are caused by private ownership/sharing, not a `Mine` list-view scope; Lead
conversion permission is separately absent. DealDesk zeros match its current financing
filters and all-Draft data. The 16-row ledger proposal does not establish genuine per-batch
evidence. Phase 5 reporting/reset/ledger development remains open. Prepared conversion-only
permission set, rep-group membership and Loyalty report description are local only; no
deployment, data write, persona change, commit or push occurred in this investigation.

## 18. Original-requirements implementation package — 2026-10-20

Owner retained ALL P5-01…20 criteria, SEED-98 and P2-03 screen Flow. No native-form or
legacy-deferral exception is accepted. Northgate has eight implementation phases; future
planning includes Phase 8 (Customer Experience Portal), not just Phases 6–7.

See `docs/planning/P2_P5_IMPLEMENTATION_2026-10-20.md` for exact changed-source scope,
Phase 2/5 native check-only failures, 7 passing offline checks, strict verification/fixture
preparation, unresolved eight-record baseline conflict, safe data/UAT sequence and Phases
6–8 roadmap. Metadata work stopped on native failures. No deployment, Salesforce data
write, persona switch, deletion/reset, commit or push occurred. Prepared Flow/permissions
and Phase 5 dashboards are not deployable or accepted yet; reset/burst execution remains
unimplemented and original acceptance requirements remain open.

## 19. Phase 2/5 check-only failures resolved — 2026-10-20

Both existing manifests now pass: Phase 2 `0Afaj00000oQSwkCAG` (4/4), Phase 5
`0Afaj00000oQNXGCA4` (15/15), check-only; no actual deployment or record write. Conversion
set requires EditTask and self-contained CRUD dependencies already present for intended rep.
Flow navigation, legacy report grouping/date exposure, and metric dashboard metadata are fixed.
Existing Apex guards and CP2 source were not changed. Evidence and exact scope:
`evidence/P5/check_only_resolution_2026-10-20.md`.

The eight-record discrepancy is historical allocation drift: Product2 40→60 adds 20,
Delivery 40→12 removes 28. Original 2,123 and revised per-object 2,115 are different,
internally consistent plans. Neither target changed during correction; no eight-record
fixture is proposed. Original requirements, mandatory SEED-98 and all eight phases remain.

## 20. Controlled Phase 2/5 release — 2026-10-20

Phase 2 deployed `0Afaj00000oQaj1CAC` (4/4) and Phase 5 `0Afaj00000oQtVWCA0` (15/15).
Effective rep permission union (PSG_Rep) now includes EditTask, ConvertLeads, RunFlow and
booking Flow access. Persona-scoped Phase 2 UAT could not run from the admin CLI session
(`Bypass_Automation`; conversion and Flow need a rep session) and was aborted before any
record write; baseline restored to `VP_Sales` with no persona PSG and zero pending approvals.
Owner selected 60 Product2 + 12 Delivery as governing (2,115); 2,123 preserved as historical.
Phase 5 reports run with expected empty SEED-98/CSI populations and an open Service SLA
20-vs-12 mismatch. New dashboards resolve but need first refresh and a management-folder
access decision. Full record: `evidence/P5/release_uat_2026-10-20.md`.

## 21. Executive activation and expedited Phase 5 closure candidate — 2026-10-23

Target was only `ng-demo` (`00Daj00001Ae3iWEAR`). The owner approved one VP executive
reporting assignment and one initial metrics publication; no deployment, scheduling,
extra business-data change, broader permission, or sharing modification was authorized
in this activation window.

- Executive metadata deployment `0Afaj00000os2RSCAY`: 13/13 components, 7/7 tests,
  publisher 18/18 lines covered (100%). The five-component dashboard remains `LoggedInUser`;
  its Pipeline, Inventory and Loyalty components are preserved.
- New VP assignment: `0Paaj000017QDt9CAG`, user `005aj00000gE0b3AAC`, permission set
  `0PSaj00000gmhQfGAI` (`PS_VP_Executive_Reporting`). Existing Run Reports assignment
  `0Paaj000017HnvxCAC` remains. VP has summary Read only; Service Visit and Financing
  Read/Create/Edit/Delete remain false. No administrative permission was added.
- Exactly one initial call of the deployed publisher succeeded, with one DML statement.
  Metrics record `a0Eaj00000QMH9hEAH`, key `DEALERSHIP`: overdue 14, CSI total 0,
  scored responses 0, capture `2026-10-23T16:16:17Z`. Zero responses mean N/A, not an
  observed zero satisfaction score. A separate read-only inspection matched source aggregates.
- Business-record ID/modification fingerprints, Service/Opportunity sharing, user
  configuration, groups and the existing three schedules are unchanged. Only the approved
  permission assignment and one new deidentified metrics record were added. No job was scheduled.
- Browser navigation reached Salesforce login, so actual VP five-tile rendering is still
  unverified. Administrator output is not substituted for VP acceptance. Owner must log in
  as Northgate Persona and confirm Pipeline, 120 Inventory, 14 Overdue, CSI N/A and 72 Loyalty,
  with the capture timestamp/age available in the two new source reports. Metrics become
  stale after `2026-10-24T16:16:17Z`; another publication requires separate approval.
- Test Drive scheduling deployment `0Afaj00000ojnxTCAQ` passed 20/20 focused tests.
  Financing context deployment `0Afaj00000ojX6KCAU` passed 61/61. The owner confirms
  Financing browser acceptance from both record contexts, existing Draft selection, and
  Rate Table preview of 587.07 for the 30,742 Quote. Do not reopen these or completed
  CP2/Quote functionality without regression evidence.
- The complete proposed P5 classification, deferred-item owners, impacts and future phases
  are now in `DEMO_ORG_BACKLOG.md`, immediately after the original Phase 5 criteria.
  Exact storage/count ties, historical ledger, live drift, manager drill-through, extra
  screenshots, reset and burst limitations are not represented as passing tests.
- Sales/Finance separation and preservation of both primary and Backup Admin are owner
  decisions. Dedicated Finance acceptance is deferred for licensing; no user or profile
  was changed and no Finance Officer access was assigned to the VP.
- Git is on `main`, HEAD `0423863794b70bb13c3c59128f7b57a0313aa0f4`, with a dirty working
  tree and zero staged entries. Cached `origin/main` comparison is 0 ahead/0 behind;
  no fetch or remote refresh, commit, push or release tag was performed. Deployed changes
  still exist in uncommitted/untracked local source and must not be discarded.

**Transition:** complete the essential VP browser checkpoint, obtain owner sign-off on the
exception matrix, then obtain a separate bounded P6-01/P6-02 authorization. Phase 6 service,
case, loyalty and consent work, Phase 7 advanced/governance work, and Phase 8 Experience
Cloud/LWC portal work remain in scope. `docs/architecture/AUTOMATION_DIRECTION.md` remains
the owner-ratified backend baseline: no new project-owned Flows; use Apex services/guards
while preserving native features and accepted screens. No Phase 6 code was started.

## 22. Owner acceptance of Phase 5 and P6-01 kickoff planning — 2026-10-23

**Owner decision:** Phase 5 is ACCEPTED WITH DOCUMENTED EXCEPTIONS as of October 23, 2026.
This supersedes §21's pending-sign-off/VP-browser exit hold, not its evidence or limitations.
The owner explicitly preserves these exceptions:

- CSI dashboard displays 0 instead of intended N/A with zero responses. This is an
  owner-reported display discrepancy, not a verified zero satisfaction score or a completed fix.
- Executive Service metrics scheduler is not activated. Only the recorded initial publication
  occurred; no republish or scheduled job is authorized by Phase 6 planning.
- Data/count/ledger reconciliation, optional testing/screenshots, reset/burst work and
  remaining browser evidence are deferred, not retroactively marked passed.
- Dedicated Finance and Service persona acceptance remains pending. Keep Sales and Finance
  separate, retain VP metrics-only access, and preserve both administrator accounts.
- Existing dirty/untracked working-tree changes remain; no staging, commit, push or cleanup.

**Current authorization:** read-only investigation and local planning/documentation only in
`ng-demo` (`00Daj00001Ae3iWEAR`). No feature source, deployed metadata, records, permissions,
sharing, users or schedules were changed during kickoff planning.

P6-01 baseline: `Rooftop__c.Service_Capacity__c` exists (Number(4,0)); capacities are
Downtown 6, North 7, Airport 8 and Service Centre 6. Service Visits are Private; all 140
currently have a Rooftop. No Service Visit Apex trigger or planned capacity/intake class
exists live, and retrieved Flows contain no Service Visit/capacity references.

The active timing rule is `AND(NOT($Permission.Bypass_Automation),
ISPICKVAL(Status__c, "Scheduled"), Scheduled_Start__c <= NOW())`. Despite its name/message,
it has no ISNEW condition and applies to Scheduled updates too. P6-01 must not silently
change it or promise that historical Scheduled note edits will bypass it.

Plan before-save Apex enforcement, reusing existing bulk guard conventions, with parent
locking and internal cross-owner capacity counts; no new Flow, UI, permission expansion,
Case creation or metrics republish. Approval must settle rooftop/day versus advisor/day,
capacity-consuming statuses, dealer timezone, and missing/invalid capacity policy. The
recommended defaults and focused acceptance tests are in
`docs/planning/P6_01_CAPACITY_ENFORCEMENT_PLAN_2026-10-23.md`.

P6-02 follows P6-01: `Q_Service_Intake` (`00Gaj00000ZYeznEAD`) exists and supports Case;
`Service_Visit__c.Case__c` is already an optional lookup. Reuse the Service trigger for
after-insert intake, avoid duplicate Cases and make Case-link updates capacity-neutral.
No intake implementation or Case write is included in this planning approval.

The backlog now records owner acceptance and updates only P6-01/P6-02 implementation labels
to the already ratified Apex architecture. All 17 Phase 6, 23 Phase 7 and 11 Phase 8 items
remain. Next step is a separate approval for local P6-01 implementation/tests/check-only,
not a deployment or live scheduling/booking window.

## 23. Consolidated Phase 6 Batch 1 proposal — 2026-10-23

The owner requested one P6-01–P6-04 implementation plan rather than separate item approvals.
See `docs/planning/P6_BATCH1_IMPLEMENTATION_PLAN_2026-10-23.md`. It reuses the existing
capacity investigation and records the subsequently approved rooftop/day, Toronto timezone,
consuming-status, fail-closed and trigger-bypass policies. This supersedes §22's proposed
separate P6-01/P6-02 approval sequence, not the read-only authorization boundary.

The consolidated proposal covers one Service trigger, intake Case creation/queue routing,
native escalation and read-only Case history. P6-03 still needs an approved recipient and
a verified supported Escalated_On__c timestamp mechanism. Its native timed behavior is not
claimed tested. A direct Case related list alone does not show visits linked to other Cases;
the proposed inline history UI requires explicit inclusion in the batch approval.

Only planning documents changed in this continuation. No feature implementation, Apex tests,
check-only deployment, live writes, permissions, page activation or schedules were executed.
Phase 5 acceptance/exceptions and all remaining Phase 6–8 backlog items remain intact.

## 24. Focused P6-03 design resolution and Big Pickle specification — 2026-10-23

The owner authorized read-only recipient/timestamp investigation and local planning only.
The final recommendation and one execution task are in
`docs/planning/P6_BATCH1_FINAL_DESIGN_AND_EXECUTION_SPEC_2026-10-23.md`; supporting command
evidence is in `docs/planning/P6_03_FINAL_DESIGN_EVIDENCE_2026-10-23.md`. These supersede §23's
open design questions, subject to explicit acceptance of the documented timestamp limitations.

Use the existing primary administrator as a temporary escalation fallback: Service roles are
empty, no NG_Service user exists, and no managerial Case queue exists. Preserve intake queue
ownership until native escalation. Four elapsed hours is now the owner's fixed timing policy.
Extend Standard without changing its eight existing entries. Native actions cannot directly
update Escalated_On__c; propose one Batchable/Schedulable class and its test to copy documented
CaseHistory ownerEscalated CreatedDate values eventually. No fabricated due-time/poll-time
stamp, unsupported trigger bridge, new Flow, workflow or replacement Apex escalation engine.

The history event proves native reassignment, not which rule caused it. Missing-event and
same-owner cases remain explicit limitations. There are no current native escalation events
to prove timed behavior from existing records. Local approval must accept these semantics;
live timer evidence and any reconciliation execution/activation require a later approved window.

Fresh retrieval: 09Saj00000mZPWAEA4 under `retrieved/p6_03_final_design/`. A separate trigger
inventory query failed on the invalid Active column and stopped without retry; the evidence
file records the exact error and owner action. No feature implementation or org writes occurred.
The next request is one Batch 1 local implementation/tests/check-only approval for Big Pickle.

## 25. Phase 6 Batch 1 deployed; Batch 2 consolidated planning — 2026-10-24

Batch 1 P6-01–P6-04 was deployed to `ng-demo` (`00Daj00001Ae3iWEAR`) at
2026-10-24T02:42:00Z. Quick Deploy `0Afaj00000owPUHCA2` returned checkOnly=false,
done=true, status=Succeeded, 14/14 components and zero component errors. It used Salesforce's
stored validation payload `0Afaj00000ovK6sCAE` (33/33 tests, zero errors/coverage warnings).
Quick Deploy did not rerun tests. Owner explicitly accepted that local historical byte parity
could not be independently proven; no dirty-tree rebuild or upload was substituted.

Batch 1 includes capacity accounting/partial-save repair, Service intake, leading four-hour
Standard entry, best-effort timestamp batch and Case history UI. Existing eight Standard entries
were preserved. The rejected Case related-list layout addition is excluded. No page was activated,
job scheduled, live timestamp reconciliation executed, security assigned or Git operation performed.
This supersedes §§22–24's planning-only status for Batch 1, not their historical evidence.

**Batch 1 owner acceptance is DEFERRED, not passed.** Retain these obligations: licensed Service
booking/intake and browser checks; two-session capacity contention; native four-hour escalation,
notification and actual ownerEscalated history; cancellation/re-entry; separately authorized
reconciliation/rollout boundary and exact timestamp comparison; missing-event/same-owner and
rule-attribution limitations; Case history page activation/browser evidence. No live test data,
permission assignment, scheduler or reconciliation is authorized by this planning continuation.

Batch 2 P6-05–P6-08 is one proposed implementation/release unit. Plan:
`docs/planning/P6_BATCH2_IMPLEMENTATION_PLAN_2026-10-24.md`. Recommended order: Vehicle history,
accrual/ledger foundation, tier evaluation, redemption/expiry. Preserve delivery/enrollment and
Batch 1 source; propose unscheduled accrual batches rather than changing accepted triggers.

Read-only Batch 2 baseline: 72 Active members; stored points total 0; lifetime spend aggregate
null. Existing 110 transactions comprise accrual 22,788 and redemption -5,418; no source links,
Source_Reference or expiry dates are populated. There are zero Loyalty_Tier__mdt records and
no current duplicate-member Contact groups. New engines must not rebuild historical balances
or invent provenance. These results are planning inputs, not a repair authorization.

Owner must resolve the single D1–D6 policy set (numeric rates/tiers/expiry, monetary bases,
event/rollout semantics, historical treatment, redemption and managed-record/operator security)
with one consolidated local implementation approval. No Batch 2 feature source, test run,
check-only, deployment, records or configuration changes have occurred. One attempted live
ValidationRule formula query failed on unsupported ErrorConditionFormula; that inspection stopped.
Its exact error and owner read-only Setup follow-up are in the plan; live formula is not certified.
Phase 5 exceptions, separate Sales/Finance, both admins, VP metrics-only boundaries and all
remaining Phase 6–8 backlog requirements remain intact. Never access ng-dev.

## 26. Batch 2 autonomous local implementation and check-only — 2026-10-24

Owner authorized local work across P6-05–P6-08, configurable provisional defaults, ordinary
defect repair, focused regressions and scoped check-only. No live metadata/data/security
changes, deployment, jobs, reconciliation, page activation or Git publication were authorized.

All four blocks are present locally: USER_MODE Vehicle service/Case/mileage history and LWC;
guarded, locked and atomic managed loyalty ledger; post-cutoff unscheduled service/sale accrual;
configurable tier reevaluation and latest-transition evidence; idempotent operator redemption
and remaining-lot expiry. Existing Delivery/enrollment and Batch 1 production files were not edited.
Only existing loyalty feature metadata edited is the additive Service_Redemption reason.
The new program defaults to inactive; no historical balance/ledger reconstruction occurred.

Focused check `0Afaj00000oyNGHCA2`: 58/58 components, 21/21 new tests. Final exact manifest
`manifest/p6-batch2-check.xml`, request **`0Afaj00000oyOkDCAU`**: Succeeded, checkOnly=true,
58/58 components, 108/108 tests, zero errors/coverage warnings. Includes the 33 Batch 1 methods
and enrollment/delivery/CP2 regressions. No tests were weakened and existing regression source
was included unchanged. Development failures and their specific fixes are recorded, not omitted.

Evidence, exact source inventory, coverage and limitations:
`evidence/P6/BATCH2_EXECUTION_2026-10-24.md`. Source snapshot/hashes and converted metadata
archive are adjacent; read-only validator is `scripts/tests/check_p6_batch2_package.py`.
Hashes were captured after validation in the same session; no selected source edits followed.
They establish a local review baseline, not independent comparison with Salesforce's stored ZIP.
Use the approved stored request for any later eligible Quick Deploy, never the whole dirty tree.

Provisional demo defaults (not final owner-approved economics): service 1 point/CAD, sale
0.10/CAD, floor after tier multiplier; Bronze 0/1/365, Silver 5000/1.25/365, Gold
25000/1.5/540, Platinum 50000/2/730 (lifetime CAD / multiplier / expiry days); display-only
CAD 0.01/point. Default upgrades only; configurable downgrade is tested. Existing Active member,
post-source-created cutoff, no automatic service enrollment or reversals; managed lots only for
redemption/expiry. Intended operator is licensed Service Advisor with new narrow local permission
metadata; no assignment was made. Exact policies and pending decisions are in the plan.

Date-filter item: documented exact native Calendar owner steps and timezone limitations in
`docs/planning/SERVICE_VISIT_DATE_FILTER_PLAN_2026-10-24.md`; no saved Calendar/All-list changes,
helper fields, Flow, custom date-picker UI or backfill were made. Calendar configuration and
browser usability need owner action/acceptance; fixed-Toronto filtering for other timezones is
not claimed by the native viewer-timezone calendar.

Prior controlled P6-01/P6-02 live acceptance created eight tagged visits/eight queue-owned Service
Cases at Northgate Airport for 2026-11-28 and rejected the ninth; this was not repeated overnight.
That run is technical evidence, not overall Batch 1 owner acceptance. P6-03 live timing/history,
browser/persona, concurrency and other §25 obligations remain pending as applicable.

Next owner review: provisional policy + exact Batch 2 metadata-only deployment approval with
program inactive. Program activation, rollout cutoff, real processing/balance changes, schedules,
assignments, redemption action placement and page activation require separate approval.
Do not mark Batch 2 deployed/accepted. Preserve Phase 5 exceptions and every unrelated dirty file.

## 27. Batch 2 deployment recorded; Batch 3 scoped validation complete — 2026-10-24

This section supersedes the earlier predeployment status. Batch 2 deployment was previously
recorded as Quick Deploy `0Afaj00000oya5SCAQ`, succeeded at `2026-10-24T12:05:50Z`.
The owner approved D1–D6 demonstration defaults; the program remains inactive. Deployment is
not live owner acceptance, activation or authorization to reconstruct historical balances.

Batch 3 P6-09–P6-12 is implemented locally under owner authorization. Exact scope is
`manifest/p6-batch3-check.xml`: three production classes, four consent triggers, fixtures/tests,
seven additive fields, custom permission, three permission sets, three report types, six reports,
five folders and two dashboards. Existing reports/dashboards and Batch 1/2 production source
remain unchanged. `docs/architecture/SIMULATION_LOYALTY.md` documents the custom/licensed seam.
`docs/planning/P6_BATCH3_IMPLEMENTATION_PLAN_2026-10-24.md` records the design and boundaries.

Consent enforcement remains opt-in for managed Campaigns. Exact purpose/channel grant is
required; deny wins, Email opt-out suppresses, and revocation retains membership history.
Audience preview requires its custom permission and USER_MODE Campaign/member/Contact reads;
internal consent decisions remain narrow SYSTEM_MODE checks. No raw consent details or sender
are exposed. Preview is not client-cacheable. The Campaign Active field is permissionable;
read-only FLS fixes the reader query without elevating it or removing active eligibility.
Test-fixture Email opt-out writes explicitly use SYSTEM_MODE; no live permissions changed.

CONFIRMED — final raw command output excerpts, exact manifest check-only:

```json
"id": "0Afaj00000p15t7CAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestErrors": 0,
"numberTestsCompleted": 119,
"numberTestsTotal": 119,
"codeCoverageWarnings": [],
"warnings": []
```

Focused check `0Afaj00000p15WXCAY` passed 11/11 methods; coordinated check above passed
119/119 methods across 21 classes, including 108 existing Batch 1/2, enrollment, delivery,
executive metrics and CP2/Quote Builder regression methods. New production Apex has zero
uncovered executable lines. Full commands, historical failures, fixes and raw coverage are in
`evidence/P6/BATCH3_EXECUTION_2026-10-24.md`. No source edits followed final validation.

Both dashboards passed metadata validation without a quota error; live refresh/quota behavior
and persona/browser acceptance are not established. Repeat-purchase uses explicit Quote buyer
Contacts with Completed service and an open Opportunity; it does not infer household identity
or purchase chronology. Loyalty liability uses stored balance times the configured point value,
not a reconciliation of historical transactions.

Batch 3 is not deployed. Live report/browser acceptance, folder/security readback, dashboard
screenshots, runtime audience acceptance and previous Batch 1/2 live gates remain pending.
No live records, assignments, jobs, page activations, Git staging/commit/push or Batch 4 work.
No remaining implementation/check-only blocker. Obtain separate deployment/activation approval.

## 28. Batch 3 owner-authorized Quick Deploy — 2026-10-24

This section supersedes §27's predeployment status. The owner explicitly authorized Quick Deploy
of validation `0Afaj00000p15t7CAA` to ng-demo / `00Daj00001Ae3iWEAR` only.
The Organization query confirmed the target ID; the stored validation report confirmed success,
checkOnly=true, 56/56 components and 119/119 tests within the Quick Deploy validity window.
The report did not expose a separate eligibility flag; successful Quick Deploy confirmed server
acceptance of this exact validation. No package rebuild or scope expansion occurred.

Command:

```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000p15t7CAA --wait 30 --json
```

CONFIRMED — raw deployment output excerpts:

```json
"id": "0Afaj00000p19YXCAY",
"status": "Succeeded",
"success": true,
"checkOnly": false,
"completedDate": "2026-10-24T21:15:46.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": [],
"warnings": []
```

Quick Deploy reused the validated payload and did not rerun tests. Component result readback
records 39 created and 17 unchanged components, all successful. Exact counts by metadata type
and the target/readback evidence are in `evidence/P6/BATCH3_EXECUTION_2026-10-24.md`.
The stored package includes unchanged regression test sources, not a new release of earlier
production implementations. Permission metadata and consent triggers are deployed; no permission
sets were assigned and no Campaigns were opted in or records written by this execution.

Live dashboard rendering/refresh, reporting results, folder/security readback and persona
acceptance are deferred, not passed. Previous Batch 1/2 live acceptance remains pending.
No jobs, schedules or pages were activated; loyalty processing remains inactive. No live record
changes, permission assignments, Git staging/commit/push or access to ng-dev occurred.
Batch 4 deployment is not authorized and has not begun.

## 29. Batch 4 local execution and scoped validation — 2026-10-24

Owner authorized P6-13–P6-17 in one continuous local implementation/test/check-only run, including
routine corrections. Target Organization query confirmed ng-demo `00Daj00001Ae3iWEAR` only.
No deployment, persistent records, assignments, publication, page activation, jobs or Git
publication were authorized. All safe independent work proceeded despite the Knowledge blocker.

- P6-13: `docs/architecture/SIMULATION_NURTURE.md` documents the actual deployed consent/audience
  architecture, cursor and security semantics, retained suppression and missing Marketing Cloud
  sender/journey/scheduling features.
- P6-14: native `NG Platinum Care` process, `NG First Response` / `NG Resolution` milestones,
  explicit response evidence field/validation, narrow Case completion service/thin trigger,
  native breach report, new unassigned SLA layout/page and native `apex:milestoneTracker` page.
  Four/48 business hours use existing Default business hours, not elapsed time. No automatic
  entitlement assignment or replacement of existing processes. Advisor action records response;
  closure completes resolution without inventing response or rewriting completed milestones.
- P6-15: ten complete internal local article drafts plus category/import/Case-use mapping in
  `docs/knowledge/`. Fresh settings show Knowledge disabled; article and CaseArticle entities are
  absent. No feature enablement, fake native implementation, records or publication. Native
  configuration/search/attachment remains blocked pending an owner enablement decision.
- P6-16: new separate Sales and Service Console apps with full workspace mappings and app-only
  unassigned permission metadata. Existing apps, users and permissions are untouched. Sales
  Console preserves accepted quote/finance page references. Service gains no Sales/Finance data.
- P6-17: native SLA lifecycle/bulk/idempotency/bypass/persona tests and coverage gate on the
  existing accrual/tier/redemption/capacity implementations. Actual non-admin Service access is
  tested; browser/dual-role acceptance remains deferred.

CONFIRMED — final raw check-only output excerpts:

```json
"id": "0Afaj00000p1hwnCAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-24T23:29:21.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 41,
"numberComponentsTotal": 41,
"numberTestErrors": 0,
"numberTestsCompleted": 181,
"numberTestsTotal": 181,
"codeCoverageWarnings": [],
"warnings": []
```

Exact package: `manifest/p6-batch4-check.xml`, 16 new components and 25 unchanged test/fixture
classes, zero modified existing components. It includes only new Case SLA code/native metadata,
two new Console applications, two unassigned permission sets and one new native report.
Existing production implementations, profiles, existing apps/pages/layouts, settings, folders,
Flows and loyalty configuration are not packaged. The pre-existing dirty DiscountApprovalTest
source is excluded; six methods from its deployed version run in the final suite. The earlier
42-component/182-method request `0Afaj00000p0rLXCAY` is superseded and must not be deployed.

Focused native SLA check `0Afaj00000p1D7WCAU` passed four/four methods; final 26-class suite
passed 181/181. New service/trigger cover 19/19 and 3/3 executable lines. Separate focused run
`707aj00001NdWTm` passed 34/34 existing methods: accrual service 29/31 (94% rounded), accrual
batch 11/11, tier batch 7/7, redemption 11/11, capacity 87/89 (98% rounded), ledger 206/208
(99% rounded) and expiry 7/7. This is named-class coverage, not an org-wide coverage claim.
Local checker `python3 scripts/tests/check_p6_batch4.py` passes ten drafts, exact 41-member
scope, console mappings, no console object/FLS grants and accepted Sales page references.

Evidence and exact new/unchanged inventory: `evidence/P6/BATCH4_EXECUTION_2026-10-24.md`.
Design: `docs/planning/P6_BATCH4_IMPLEMENTATION_PLAN_2026-10-24.md`.
Deferred operations: `docs/planning/P6_BATCH4_ACCEPTANCE_RUNBOOK_2026-10-24.md`.
No selected source changes followed final validation; subsequent edits are documentation/checker.

Batch 4 is not deployed. A later metadata-only approval must name this exact stored validation
and 41-component scope; it excludes Knowledge enablement/import/publication, records, assignments,
SLA enrollment, page/layout activation and schedules. New SLA process metadata is active but has
no enrolled records; new SLA page/layout remain unassigned. Actual deployment needs separate
owner authorization. Knowledge requires a separate feature decision and schema/license review.

CP2, approvals, financing, delivery, loyalty, existing Cases, consent, reporting, users and dirty
work remain preserved. All earlier live/browser gates, native SLA timer/breach UI, Knowledge
search/Case attachment and dual-role console acceptance remain deferred or blocked, not passed.
Phase 6 is not owner-accepted or closed. No ng-dev access or Phase 7 implementation occurred.

## 30. Batch 4 owner-authorized Quick Deploy — 2026-10-25 UTC

This section supersedes §29's predeployment status. The owner authorized Quick Deploy of only
stored validation `0Afaj00000p1hwnCAA` to ng-demo / `00Daj00001Ae3iWEAR`.
Target query confirmed the exact Organization ID. The stored validation remained successful,
checkOnly=true, 41/41 components and 181/181 tests, within the Quick Deploy validity window.
No separate eligibility flag was returned; successful Quick Deploy confirmed server eligibility.
No package rebuild, expanded scope or fallback deployment method was used.

Command:

```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000p1hwnCAA --wait 30 --json
```

CONFIRMED — raw final output excerpts:

```json
"id": "0Afaj00000p1MVmCAM",
"status": "Succeeded",
"success": true,
"checkOnly": false,
"completedDate": "2026-10-25T00:38:45.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 41,
"numberComponentsTotal": 41,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": [],
"createdComponents": 16,
"unchangedComponents": 25,
"modifiedExistingComponents": [],
"allComponentsSuccessful": true,
"warnings": []
```

Completion was October 24 in America/Toronto. Quick Deploy reused the exact stored payload and
did not rerun tests; the validation's 181/181 result remains the test evidence. Component counts
and commands are recorded in `evidence/P6/BATCH4_EXECUTION_2026-10-24.md`.

No Knowledge enablement, article creation/publication, live record changes, entitlement enrollment,
permission assignments, page/layout activation, scheduling or Git commit/push occurred. SLA
process metadata is deployed, but no enrollment was performed; the new SLA page/layout remain
unassigned. No ng-dev access or Phase 7 implementation. Unrelated dirty work remains preserved.

Phase 6 is not accepted or closed. Native Knowledge remains blocked by its disabled feature
state; ten local drafts are prepared. Live SLA timer/breach, reporting, console/persona/browser
acceptance and earlier Batch 1–3 live gates remain deferred, not passed. Further activation,
data work or implementation requires appropriate separate owner authorization.

## 31. P6-15 current Knowledge state and preparation — 2026-10-25 UTC

Owner browser verification reported Enable Lightning Knowledge checked. Focused read-only
verification confirmed ng-demo `00Daj00001Ae3iWEAR` and supersedes the earlier disabled-feature
finding. No feature setting was changed by the agent. Batch 4 implementation, deployment and
successful tests were not repeated. No Git operations were run.

CONFIRMED — current retrieved settings, request `09Saj00000mhMEYEA2`:

```xml
<enableKnowledge>true</enableKnowledge>
<enableLightningKnowledge>true</enableLightningKnowledge>
<enableKnowledgeCaseRL>false</enableKnowledgeCaseRL>
```

EntityDefinition and REST describe now expose Knowledge__kav, KnowledgeArticle,
KnowledgeArticleVersion, Knowledge__DataCategorySelection and CaseArticle. The connected user
has createable/queryable article API access; this does not verify Service persona readiness.
Knowledge__kav has Title, UrlName, Summary and en_US Language, but zero custom fields and no
body field. No DataCategoryGroup exists. Existing Knowledge Layout contains Title and UrlName.
All ten prepared URLs currently have zero matches in en_US Draft, Online and Archived queries.

Remaining configuration is prepared locally, not deployed or Salesforce-validated:

- `Knowledge__kav.Body__c`, Html 32768/20 visible lines.
- `Northgate_Knowledge`, native All root plus five planned categories, with no visibility grants.
- `Knowledge__kav-NG Internal Article Layout`, new and unassigned; existing layout untouched.
- Exact proposed scope: `manifest/p6-15-knowledge-prepare.xml`, three components, no Settings,
  permission metadata, app/page assignment or existing layout replacement.

`scripts/knowledge/prepare_p6_15_import.py` builds a local-only REST Composite request for ten
Draft creates and ten category selections with allOrNone=true. It makes no requests or writes.
It omits non-createable PublishStatus/IsVisibleInApp and explicitly disables public/customer/
partner visibility. PublishStatus's described default is Draft; internal visibility must be
verified after any authorized creation. No prepared request was sent or runtime-smoke-tested.

Category selection ParentId uses the article version Id; CaseArticle.KnowledgeArticleId uses the
master ID, not the version. Native Case related-list presentation is currently disabled and is
a separately approved configuration step. No automatic Case linking or arbitrary Case IDs.

CONFIRMED — focused offline check output:

```json
"status": "PASS",
"articleCreatesPrepared": 10,
"categorySelectionsPrepared": 10,
"metadataMembers": 3,
"allOrNone": true,
"externalVisibility": false,
"publicationRequests": 0,
"networkRequests": 0
```

The three XML components and manifest also pass xmllint. No new Apex/Batch 4 test run or org
validation/deployment occurred. Exact mappings, import preflight/readback and publication/Case
steps are in `docs/knowledge/README.md`; raw verification and boundaries are in
`evidence/P6/P6_15_KNOWLEDGE_CONTINUATION_2026-10-25.md`.

Disabled-feature blocker is resolved; no new architectural blocker was found. Next approvals
are separate: scoped metadata validation/deployment, any required author/reader access, ten
Drafts plus ten category selections, publication, and approved Case/UI integration. No live
article creation, permission changes, Case links or publication occurred. Existing functionality,
users and dirty work are preserved; ng-dev untouched. P6-15 and Phase 6 acceptance remain pending.

## 32. Authorized Knowledge deployment and consolidated Phase 6 closure review — 2026-10-25 UTC

Owner authorized scoped Knowledge deployment and exactly ten internal Draft articles plus ten
category selections, read-only acceptance review and documentation. Publication, permissions,
page activation, jobs, loyalty activation/reconciliation/balances, extra records and Phase 7
implementation remain prohibited. Only ng-demo `00Daj00001Ae3iWEAR` was accessed.

CONFIRMED — raw three-component deployment output excerpts:

```json
"id": "0Afaj00000p27rFCAQ",
"status": "Succeeded",
"success": true,
"checkOnly": false,
"completedDate": "2026-10-25T00:59:27.000Z",
"numberComponentsDeployed": 3,
"numberComponentsTotal": 3,
"numberComponentErrors": 0,
"componentFailures": []
```

Validation `0Afaj00000p27o1CAA` also passed three/three. NoTestRun is appropriate to the
non-Apex package; previous successful Phase 6 tests were not rerun. Body__c, the active
Northgate_Knowledge category group and the new unassigned internal article layout are deployed.

Knowledge import is **blocked, not completed**. The connected System Administrator is a
Knowledge User with article Create access, but Body__c is absent from direct REST describe;
FieldPermissions returns zero grants. Tooling confirms the field exists as `00Naj000068IkpWEAS`.
All ten URLs remain collision-free across Draft/Online/Archived. The existing importer generated
the ten-plus-ten request (SHA-256 `63305e62d5cad1382bfdffcefbd1b4a78f5323d42e2f7e1ed72d0ab4fe33eae9`)
but no POST was submitted. Created counts: zero articles, zero selections. No bodyless records,
FLS bypass, permission changes or SYSTEM_MODE workaround. Owner must separately approve/grant
Body__c Read/Edit for the existing author, then recheck and resume only the approved import.

Fresh independent read-only review completed across all 17 blocks. Current readback
`09Saj00000mhSNBEA2` confirms eight Requested controlled-UAT visits, capacity eight and their
eight queue-owned Service/New/Medium/Web intake Cases; native escalation 240 elapsed minutes;
dynamic Service/fixed Loyalty dashboard types and restricted folder shares; both Console apps;
and the active 240/2880-business-minute native SLA process. Existing Northgate_Service already
maps Case to Case_Record_Page with caseServiceHistory; this was not a new activation.

Native reports were read without detail rows. Service open=69, overdue=14, CSI responses=0;
Loyalty members=72/stored points=0, but the liability aggregate is absent for the current author;
native SLA breach rows=0 and there are zero entitlements on the new process. Loyalty remains
inactive with the approved rates/tiers; 72 members/zero stored points/null spend and 110
transactions/net 17,370 match the preserved baseline. No relevant loyalty/escalation jobs found.
These results do not establish active accrual, redemption, scheduling or browser acceptance.

Additional accuracy/access blockers:

- Native repeat-purchase report returns 33, while the explicit Completed-service/open-Opportunity
  buyer semantic COUNT returns 31. Runtime report describe has an empty Quote criterion list;
  Quote.Repeat_Purchase_Open__c has no field Read grants. Current report correctness is not passed.
- Managed nurture audit returns 60 with reportFilters=[] and its managed/eligible columns absent.
  This is not proof of 60 managed members or working live suppression. Relevant access exists
  in unassigned PS_Nurture_Audience. Current author's managed-Campaign COUNT fails on inaccessible
  Nurture_Managed__c, so no managed-Campaign population is asserted.
- Liability reporting omits its required aggregate; proper intended-reader/running-user access
  and applied report filters must be verified before live dashboard/report acceptance.

No non-Knowledge report/security fix is authorized. It remains to verify whether intended
criteria reappear under correct approved FLS or require stored report correction. No guessing,
permission assignment or report rewrite was used. A supplemental source retrieval timed out;
fresh stored-report XML parity is not claimed. Native report describe/run evidence is recorded.

Full 17-row implemented/deployed/verified/deferred/blocked matrix, deployment ledger, raw report
outputs, activation register, Git status and Phase 7 dependencies:
`evidence/P6/PHASE6_CLOSURE_REVIEW_2026-10-25.md`. Exact Knowledge deployment/preflight blocker:
`evidence/P6/P6_15_KNOWLEDGE_EXECUTION_2026-10-25.md`.

Existing evidence reused: coordinated 181/181 tests and focused 34/34 with the required engines
above 90% coverage. No fresh browser/persona verification or screenshots were produced; prior
owner Knowledge-enabled confirmation is not broader browser acceptance. All timer, contention,
publication/search/Case attachment, page placement and actual persona gates remain explicit.

Git: main, HEAD `0423863794b70bb13c3c59128f7b57a0313aa0f4`, cached origin/main ahead/behind
0/0; dirty tree, 57 modified tracked entries and 415 untracked entries, zero staged. No fetch,
staging, commit, cleanup or push; remote freshness not claimed. Phase 6 is not a clean release tag.

**Closure recommendation: BLOCKED** until Knowledge author access/import and report accuracy
gaps are resolved or the owner explicitly dispositions them. Other inactive/live/UI limitations
are documented exceptions, not passes. Do not mark Phase 6 accepted or start Phase 7. After owner
disposition and separate authorization, P7-01 planning is next; P7-15 depends on working P6-15
Knowledge, and history-dependent P7-16/P7-18 retain their access/capability gates.

## 33. Phase 6 final blocker repair completed — 2026-10-25 UTC

This section supersedes §32's BLOCKED state. The owner authorized minimum Knowledge body access
for the existing administrator, the ten planned Draft articles/selections and local/scoped report
repair validation. Report deployment was held until the owner separately selected “Approve scoped
deployment” for the exact four-component package and administrator-only six-field Read set.
Only ng-demo `00Daj00001Ae3iWEAR`, administrator `005aj00000feqbNAAQ`, was targeted.

- Knowledge: deployed PS_Knowledge_Draft_Author with only Knowledge__kav.Body__c Read/Edit,
  assigned only to the existing author. Existing article CRUD and Knowledge User flag were
  retained; no profile, publication, external-channel or record-sharing grant.
- Import: fresh URL checks found zero collisions. Submitted the existing ten-plus-ten all-or-none
  request once; all twenty subresponses HTTP 201/success=true. Readback verifies all ten Drafts,
  internal visibility true, all three external flags false, full content, exact categories and
  receipt IDs. No publication or Case attachment. Do not replay the import.
- Reporting: deployed PS_Phase6_Report_Field_Read (six Read-only fields, no object CRUD, audience
  preview, write or sharing grants) plus the three exact Phase 6 reports, after separate approval.
  Assigned only to the same existing administrator/fixed Loyalty running user. No other personas.

CONFIRMED — raw request/deployment result projections:

```json
{"id":"0Afaj00000p2Gg1CAE","status":"Succeeded","checkOnly":true,"numberComponentsDeployed":1,"numberComponentsTotal":1}
{"id":"0Afaj00000p2EfqCAE","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":1,"numberComponentsTotal":1}
{"id":"0Afaj00000p2HtpCAE","status":"Succeeded","checkOnly":true,"numberComponentsDeployed":4,"numberComponentsTotal":4}
{"id":"0Afaj00000p1htbCAA","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":4,"numberComponentsTotal":4}
```

Zero component errors throughout; NoTestRun for non-Apex metadata. No Apex production source
changed, so the successful 181-method coordinated and 34-method focused suites were reused,
not repeated. The focused metadata contracts and actual live import/report parity checks passed.

CONFIRMED — Knowledge readback summary:

```json
"status": "PASS",
"verifiedArticles": 10,
"verifiedCategorySelections": 10,
"exactTitleSummaryLanguageMatches": 10,
"htmlContentMatches": 10,
"draftInternalOnly": 10,
"onlineOrArchivedMatchingVersions": 0
```

Salesforce normalizes apostrophe HTML entities from hex to decimal; the read-only verifier
compares decoded HTML while retaining exact text/markup and Title/Summary/Language comparisons.
No article body was edited to make verification pass. Receipts and master/version mappings:
`evidence/P6/P6_15_IMPORT_RECEIPT_2026-10-25.json` and
`evidence/P6/P6_15_IMPORT_VERIFICATION_2026-10-25.json`.

Fresh native reports now expose effective intended criteria and complete totals:

- Repeat purchase: Completed Service + explicit buyer + Repeat_Purchase_Open__c=True is present;
  report=31, equivalent open-Opportunity source COUNT=31. No unexplained difference.
- Managed nurture: Consent_Managed__c=True is present; report=0, source COUNT=0. All sixty
  existing memberships remain unmanaged; no deletion, opt-in or record manipulation.
- Loyalty: liability Sum is visible; report/source both show 72 members, stored points zero,
  liability CAD 0.00. Program remains inactive; no balance/history/configuration repair.

The reporting package changed two PostSale report definitions, created the six-field set and
left Loyalty report definition unchanged. No unrelated reports, dashboards, profiles or runtime
features changed. Exact components, raw filters, source queries and approval boundary:
`evidence/P6/PHASE6_FINAL_BLOCKER_REPAIR_2026-10-25.md`. Current 17-block matrix and activation
register: `evidence/P6/PHASE6_CLOSURE_REVIEW_2026-10-25.md`. Knowledge operator instructions:
`docs/knowledge/README.md`. Live verifier is read-only; do not regenerate and resubmit creates.

All three verified closure blockers are resolved. **Recommendation: ACCEPT WITH DOCUMENTED
EXCEPTIONS**, for the owner's decision; Phase 6 is not owner-accepted or closed. Retain deferred
publication/native Service search/Case attachment; actual Service/dual-role browser and dashboard
rendering; page/action placement and operational access decisions; live capacity contention,
escalation/notification/history and SLA clock/breach; loyalty activation/jobs and nonempty CSI.
These are not reported as passed. No other live test/business records, external visibility,
page activation, schedules, reconciliation, destructive actions or Git staging/commit/push.
No ng-dev access or Phase 7 implementation. Existing data and unrelated dirty work are preserved.

## 34. Phase 6 owner acceptance and Phase 7 planning — October 24, 2026

**Phase 6: OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026.**

The owner explicitly answered YES to the final recommendation. This is the formal acceptance
decision, not another test/deployment inference. Existing UTC evidence timestamps on October 25
remain unchanged. Historical BLOCKED/recommendation-only entries above are superseded, not erased.

Every documented exception and outstanding operational acceptance requirement is retained in
`evidence/P6/PHASE6_OWNER_ACCEPTANCE_2026-10-24.md` (P6-E01–P6-E14), the updated 17-block closure
matrix and the original batch/seam/runbook evidence. In particular: actual Service/manager/
dual-role browser access; concurrent capacity/intake; live escalation/notification/history and
best-effort timestamp limits; history/SLA page/action placement; inactive loyalty/tier/redemption/
expiry/jobs and historical mismatch; positive live consent suppression; Draft publication/search/
Case attachment; dashboard rendering/persona comparisons; empty CSI; SLA enrollment/clocks;
date-filter timezone limitations; throughput/release/Phase 5 exceptions. None is converted to PASS.
Acceptance authorizes no publication, data repair, balances, jobs, assignments or activation.

The owner authorizes read-only Phase 7 investigation and one consolidated plan, not feature
implementation. Plan: `docs/planning/PHASE7_IMPLEMENTATION_PLAN_2026-10-24.md`. All 23 IDs and
their acceptance criteria are retained; final dependency-correct batches are:

1. Batch 1: P7-22, P7-01–P7-06 (seven blocks).
2. Batch 2: P7-07–P7-12 (six blocks).
3. Batch 3: P7-13–P7-18 (six blocks).
4. Batch 4: P7-19–P7-21 and P7-23 (four blocks).

P7-22 is the only inter-batch move from the provisional ranges: P7-01 explicitly requires it.
Focused ng-demo readback found zero NG_VehicleImages static resources, 30 Vehicle Models and
30 nonblank existing image paths. Do not assume those paths satisfy the required image bundle
or overwrite them. P7-23 remains later because the Vehicle header does not block the gallery.

Plan records file-level reuse and gates: existing reservation/VIN/counter services; payment/
equity and finance preview; concrete duplicate trigger entry points; formula inventory age;
existing debt/verifier/data tooling; API/events before seam completion; the regression wrapper
before final README; demo scripts last. Capability-gated territories, Agentforce, Data Cloud and
Experience/externals need feature-specific decisions, not a broad new org audit or paid assumptions.
No new project-owned Flow; preserve the accepted appraisal screen Flow and native features.

Phase 8 remains eleven separate P8-01–P8-11 roadmap blocks, extending the P7-18 site seed on
Experience Cloud + LWC only. React remains an unapproved P7-18-only evaluation and is excluded
from Phase 8. External licenses, relationship isolation and Digital Experiences decisions remain
gated; no Phase 8 requirement is absorbed into Phase 7 or used as a circular P7-21 prerequisite.

Recommended next authorization: bounded Batch 1 local implementation, focused tests and scoped
check-only for seven blocks. Start with the image resource/path contract, then the secure gallery/
reserve path; keep deployment, image data writes, credentials, assignments and page placement
separate. Do not reopen accepted Phase 6 or enable its operations to start independent Batch 1 work.
No Phase 7 code, Salesforce deployments/records, assignments/activations or Git staging/commit/push
were performed in this planning run. Target remained ng-demo only; ng-dev was not accessed.

## 35. Phase 7 Batch 1 local execution and exact validation — 2026-10-25 UTC

Owner authorized P7-22 and P7-01–P7-06 local implementation, focused tests, routine fixes and exact
scoped check-only against ng-demo `00Daj00001Ae3iWEAR`. No actual deployment, records/image/VIN
changes, credential configuration, assignments, page activation or Git publication.

P7-22 readiness first confirmed all 30 existing paths already use the exact required resource/
filenames. No path update is needed for a matching bundle. There are no approved photos in the
repository or available image-generation tool, so the photo/resource deliverable is genuinely
blocked. `docs/assets/P7_VEHICLE_IMAGE_MAP.json` captures model/file/body-style mapping without
record IDs/VINs; `P7_IMAGE_ASSET_READINESS.md` records the blocker. No placeholder-only resource
was packaged or falsely accepted as vehicle photography.

P7-01–P7-06 local source includes:

- Gallery LWC/tab/controller: USER_MODE filtered keyset browse, safe image-path/fallback handling,
  accessible Contact selection and permission-gated Available/unreserved row-lock reservation.
  No direct Vehicle Edit or Invoice/Finance access; existing guard owns status/time.
- Calculator LWC/controller: reuses PaymentCalculatorService, TradeIn_Calc_Equity and
  RateTableService for read-only illustrative estimates; no financing/Quote/trade mutation.
- VIN client and loopback-only mock provider: checksum/permission gate, bounded request/response
  validation, no inventory writes. API contract in `docs/integration/API_CONTRACT.md`.
- Native PublishAfterCommit Vehicle_Reserved__e, minimal Vehicle Id/time payload, existing after-
  update hook, subscriber refresh/cleanup and explicit manual refresh. Notification enqueue
  failures log/count but do not invalidate authorized legacy reservations. Native event Read/
  Create is declared only in the local gallery set; no assignments were made.
- `docs/architecture/EVENTS_CDC_PUBSUB.md` distinguishes actual native events from absent CDC/
  external subscribers/credentials/replay checkpoints.

Only existing runtime edits are VehicleCounterTrigger's publisher call and VehicleCounters'
derived-cache `update as system`. The read-only Sales reservation test exposed the cache write's
caller CRUD failure; this fixes the internal aggregate write instead of granting Rooftop Edit.
No CP2, Finance, Delivery, loyalty, consent, existing VIN/image/guard behavior or other trigger
entry point was rewritten. No P7-07 consolidation or Batch 2 work started.

CONFIRMED — final raw check-only output excerpts:

```json
"id": "0Afaj00000p2bfeCAA",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-25T04:03:38.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 21,
"numberComponentsTotal": 21,
"numberTestErrors": 0,
"numberTestsCompleted": 163,
"numberTestsTotal": 163,
"codeCoverageWarnings": []
```

Exact manifest `manifest/p7-batch1-check.xml`: 19 simulated new components and the two named
existing runtime edits. No pre-existing regression test source or unrelated dirty changes are
packaged. Twenty selected classes ran: 11 new methods plus 152 deployed regressions. Coverage:
gallery/calculator/publisher 100%, VIN 23/24, cache helper 16/17, modified trigger 15/16.
Focused request `0Afaj00000p2MqJCAU` passed 11/11; Node state checks passed four/four; local mock
provider check passed. Source/failed-request history, exact commands, coverage and boundaries:
`evidence/P7/BATCH1_EXECUTION_2026-10-25.md`.

NG_VIN_Mock is absent in read-only metadata inventory. Actual positive named-credential wire,
principal access and real timeout are not verified or configured. Tests exercise request/parser
boundaries and generic unavailable handling without a test-mode endpoint bypass; a successful
browser/credentialed callout is not claimed. A future reachable mock host/credential decision,
deployment, actor/page placement and actual stream/photo browser evidence need separate approval.

No actual deployment, credential/record/path/VIN/security assignment/page/job changes or Git
staging/commit/push; ng-dev untouched. Phase 6 remains owner-accepted with every exception carried
forward. Batch 1 is not marked done/accepted while P7-22 photos and live acceptance are outstanding.

## 36. P7-22 licensed real-photo resource completed locally — 2026-10-25 UTC

Owner explicitly replaces the planned AI-generated photographs with appropriately licensed real
automotive stock photography. This is a narrow asset sourcing amendment: fictional Northgate
record identities, exact filenames, image paths and the existing gallery are unchanged. No actual
Salesforce deployment, record/path mutation, permissions or Git publication is authorized.

Thirty distinct real photographs were sourced from Wikimedia Commons with explicit CC0 1.0
records and named photographers. Pexels/Unsplash were researched; no restricted download was
bypassed and no photograph from either is included. Six unsuitable images were rejected rather
than removing branding or accepting weak composition. Incidental OEM badges remain unchanged;
the bundle and inventory label photographs as illustrative, not exact vehicles or endorsement.

Deliverables:

- `force-app/main/default/staticresources/NG_VehicleImages/`: all thirty exact root WebP filenames,
  ATTRIBUTION.md and licenses.json, plus adjacent resource metadata.
- `evidence/P7/NG_VehicleImages.zip`, 1,808,049 bytes, SHA-256
  `67f1710386db658283f2d0649110128407c39bef9e28573ceccff805c0dffd7d`.
- `docs/assets/P7_VEHICLE_PHOTO_INVENTORY.md`: full thirty-row inventory/credits/rights/size table.
- `docs/assets/P7_VEHICLE_PHOTO_SOURCES.json`: every original/download URL, photographer, source
  page, exact license URL, timestamp, hashes, model-year/body rationale and visual notes.
- Source rights snapshots and original/processed review sheets under `evidence/P7/photo_sources/`.

All outputs are real 800×600 WebP with full-frame proportional resize/letterbox, no logo removal
or crop. Median 54,114 bytes, minimum 45,640, maximum 118,278; complex scenes remain larger to
avoid excessive compression. Local verifier passes all encodings/dimensions, distinct source/
output hashes, licensing records, exact filenames/ZIP integrity and live thirty-model body/path
compatibility. All current paths already match; no data migration was needed or performed.

CONFIRMED — final raw asset-only check-only output excerpts:

```json
"id": "0Afaj00000p4yTFCAY",
"status": "Succeeded",
"success": true,
"checkOnly": true,
"completedDate": "2026-10-25T15:35:56.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 1,
"numberComponentsTotal": 1,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": [],
"warnings": []
```

Exact manifest `manifest/p7-22-images-check.xml`, NG_VehicleImages StaticResource only. This
successful NoTestRun validation is appropriate for a non-Apex asset. It supersedes the earlier
asset request before a final provenance-text clarification. Prior application validation
`0Afaj00000p2bfeCAA` (21/21 components, 163/163 tests) is unchanged/reused, not rerun. No combined
22-component validation/deployment is claimed. Current static-resource use is zero against
the documented 250 MB total; the new archive is below the separate 5 MB per-resource cap.

No local sourcing/license/package gap remains for P7-22 under the amended criterion. Resource
deployment and actual Salesforce/browser rendering remain deferred, not passed. Other Batch 1
credential/principal/placement/access gates remain unchanged; Batch 1 is not owner-accepted.
Full commands, rights basis, curation/size choices and raw validation:
`evidence/P7/P7_22_STOCK_PHOTOS_2026-10-25.md`. No gallery redesign, inventory/VIN/image-path
write, permission change, actual deployment, Git staging/commit/push or ng-dev access occurred.
Phase 6 acceptance/exceptions and the separate Phase 8 roadmap remain preserved.

## 37. Batch 1 exact Quick Deploy unavailable; execution stopped — 2026-10-25 UTC

Owner authorizes only exact stored Quick Deploys `0Afaj00000p2bfeCAA` (21/21, 163/163) and
`0Afaj00000p4yTFCAY` (NG_VehicleImages), with an explicit stop on unavailable Quick Deploy.
Target query reconfirmed ng-demo `00Daj00001Ae3iWEAR`. Both stored reports remain Succeeded,
checkOnly=true, zero component errors. Photo validation has zero tests/NoTestRun; no explicit
Quick Deploy eligibility flag was returned by either report.

The photo Quick Deploy was checked first to avoid a partially installed application when its
asset payload was ineligible. Exact command:

```sh
sf project deploy quick --target-org ng-demo --job-id 0Afaj00000p4yTFCAY --wait 10 --json
```

CONFIRMED — raw error fields:

```json
"status": 1,
"name": "CannotQuickDeployError",
"message": "Job ID can't be used for quick deployment. Possible reasons include the deployment hasn't been validated, has already been deployed, or the validation expired because you ran it more than 10 days ago."
```

No deployment job ID was returned. **No package was deployed by this execution**; application
Quick Deploy was not attempted after that rejection. No fallback, rebuilt package, broader
manifest or new validation was substituted. Do not infer the actual eligibility cause from the
generic possible-reasons message or mark either package deployed from check-only success.

New deployed resource path resolution was skipped because the resource did not deploy and the
owner required stopping. Prior local image/path/ZIP checks are preparation evidence, not a live
HTTP/browser proof. Browser/gallery/event acceptance remains deferred, not passed. No permissions,
pages, VIN credentials, records/image paths, jobs or Git staging/commit/push were changed; ng-dev
untouched. Local handoff/backlog/evidence updates are the only post-error changes.

Owner action: Setup > Deployment Status > validation `0Afaj00000p4yTFCAY`, inspect Quick Deploy
availability and resolve eligibility or explicitly authorize a revised deployment method.
Exact preflight/error/scope evidence: `evidence/P7/BATCH1_DEPLOYMENT_ATTEMPT_2026-10-25.md`.
Phase 6 remains owner-accepted with all exceptions; Batch 1 deployment/acceptance remains open.

## 38. Batch 1 standard deployment recovery succeeded — 2026-10-25 UTC

Owner separately authorized standard deployment of the same two manifests after Quick Deploy
was unavailable, with photos first and application only after success. Target query confirms
ng-demo `00Daj00001Ae3iWEAR`, OrganizationType=Developer Edition. No ng-dev access.

Preflight compared exact member sets to stored validation successes, verified expected source
layouts, reviewed the two recorded existing runtime diffs and captured 70 source hashes. Result:
one/21 components match exactly, no unexpected selected changes, and asset deliverable hash
matches the recorded package. No manifest expansion, unrelated repair or source update.
Snapshot: `evidence/P7/DEPLOYMENT_RECOVERY_PREFLIGHT_2026-10-25.json`. This verifies scope/source
continuity, not an independently extracted sealed application ZIP from Salesforce validation.

Commands, executed in this order:

```sh
sf project deploy start --target-org ng-demo --manifest manifest/p7-22-images-check.xml --test-level NoTestRun --wait 10 --json
sf project deploy start --target-org ng-demo --manifest manifest/p7-batch1-check.xml --test-level NoTestRun --wait 10 --json
```

CONFIRMED — raw deployment output excerpts:

```json
{"id":"0Afaj00000p7373CAA","status":"Succeeded","success":true,"checkOnly":false,"completedDate":"2026-10-25T23:13:52.000Z","numberComponentErrors":0,"numberComponentsDeployed":1,"numberComponentsTotal":1,"numberTestErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
{"id":"0Afaj00000p738fCAA","status":"Succeeded","success":true,"checkOnly":false,"completedDate":"2026-10-25T23:14:29.000Z","numberComponentErrors":0,"numberComponentsDeployed":21,"numberComponentsTotal":21,"numberTestErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
```

Both componentFailures/warnings arrays are empty. Application has 19 created components and only
the recorded VehicleCounters/VehicleCounterTrigger modifications; all 21 succeeded. Developer
Edition supports NoTestRun, accepted by Salesforce here; no unnecessary Apex rerun. Prior
validation `0Afaj00000p2bfeCAA` passed 163/163, but that is not a new deployment test result.

NG_VehicleImages is present as StaticResource `081aj00000LQd1dAAD`, application/zip, Public cache,
BodyLength=1,807,209. Its authenticated REST Body download verifies all thirty approved WebP
hashes/800×600 encodings and exact root names, complete photographer/license JSON and all thirty
current model/body/image-path matches. No path migration or record mutation. All seventy selected
source hashes still match preflight. Readback: `evidence/P7/DEPLOYED_RESOURCE_VERIFICATION_2026-10-25.json`.

Native archive has 31 files, not the local deliverable ZIP's 32: existing `.forceignore` excludes
`*.md`, so optional ATTRIBUTION.md was filtered by CLI packaging. All thirty photos and the full
license/photographer register remain; CC0 does not require the Markdown credit file. No ignore
rule, package or Salesforce content was repaired/redeployed. A direct API-host image stream
probe was empty and is not rendering evidence; canonical authenticated archive contents and
logical existing path compatibility passed. Browser/front-end image rendering remains unverified.

Both new operational permission sets remain unassigned (query count zero). No permission
assignments, page activation, VIN credentials, records, scheduling or Git staging/commit/push.
Browser/gallery/reservation/event delivery acceptance remains deferred, not passed. No new
live test reservation or streaming session was started. Phase 6 owner acceptance and exceptions
are preserved; Batch 1 is deployed, not owner-accepted. Full raw results and verification limits:
`evidence/P7/BATCH1_STANDARD_DEPLOYMENT_2026-10-25.md`.

## 39. Phase 7 Batch 2 implementation and check-only — 2026-10-26 UTC

Owner authorized local P7-07–P7-12 implementation, read-only checks and isolated/scoped check-only
tests against ng-demo only. Handoff §38 and the existing six requirements/dependencies were
inspected first. No actual deployment, persistent record/configuration writes, assignments,
scheduling, Git staging/commit/push or ng-dev access. Plan:
`docs/planning/P7_BATCH2_IMPLEMENTATION_PLAN.md`; full report: `evidence/P7/BATCH2_EXECUTION.md`.

P7-07: local LeadRoutingTrigger, VehicleTrigger and TestDriveTrigger each route to one dedicated
handler. Four duplicate triggers are removed locally and selected for atomic destructive
validation. Existing domain services, context-specific bypasses, booking date validation,
reservation/counter/event order and follow-up behavior are retained. Converted seed cleanup
is bulk DML and retains its former trigger-owned sharing context. Lead lane resolution is
reused per rooftop per invocation; existing recursion guard/transition checks remain intact.
No CP2 or accepted finance/delivery/service/loyalty component was rewritten.

P7-08: InventoryReconciliationJob reconciles only existing Vehicles_On_Hand for explicitly scoped
1–200 rooftops via VehicleCounters. All-status count semantics and native age formula remain;
no stored age/aged-count field, automatic enqueue, scheduling, retry chain or live reconciliation.
Existing administrative bypass permission plus object/counter access is required; sharing is
retained, so an authoritative operator needs complete inventory visibility. Tests prove async
completion, scoped drift repair after moves/deletes/undeletes, zeroing, idempotence and denial.

P7-09/P7-10: `docs/GOVERNANCE.md`, minimal README/backlog references and the existing debt ledger
cover actual conventions, review, evidence, provenance, historical slot versus daily capacity,
cache/history/throughput and accepted exception limits. Full P7-20 presentation remains future.
P7-11: runnable read-only administrative permission/group audit exists; native report/browser/
operational-reader evidence remains open. P7-12: no required Territory objects are exposed by
the API inventory. No territory metadata/substitute sharing or Account assignments were built;
owner capability disposition is required. These limits prevent claiming all six blocks accepted.

CONFIRMED — raw final scoped check-only projection:

```json
{"id":"0Afaj00000p7GCLCA2","status":"Succeeded","checkOnly":true,"completedDate":"2026-10-26T00:18:31.000Z","numberComponentsDeployed":14,"numberComponentsTotal":14,"numberComponentErrors":0,"numberTestsCompleted":235,"numberTestsTotal":235,"numberTestErrors":0}
```

Fourteen successes are ten replacement components plus four removals in validation only.
Twelve new tests and 223 deployed regressions passed across 33 classes, including CP2 pricing/
Builder/Summary, finance/approval/FLS, delivery, Lead, Vehicle, test-drive, gallery/event and
selected Phase 6 workflows. New handlers/Queueable and all three entry triggers have 100%
coverage; modified LeadRoutingHandler has 89/97 lines. No coverage warnings.

An initial fixture failed DUPLICATE_VALUE because 200 records repeated a unique Seed_Tag.
Work stopped; owner approved inspection and fixture-only correction after source uniqueness
was confirmed. Assertions/production logic were not changed to force a pass. The original
failed job `0Afaj00000p77aUCAQ` is preserved. A prior audit syntax error likewise received
explicit owner approval before its one-bracket correction. Details are in the execution report.

CONFIRMED — raw post-check report excerpt:

```json
{"status":"PASS","testsPassed":235,"testClasses":33,"newTestsPassed":12,"selectedSourceHashesUnchanged":20,"actualDeploymentPerformed":false}
```

Tooling readback confirms all seven original live Lead/Vehicle/Test_Drive trigger entries remain
Active. Local consolidation is not deployed. Permission audit found 180 non-profile sets,
31 assignment rows and 26 groups; zero-assignment candidates are not proven unused. All four
required Territory objects are absent from the current API inventory. Owner action: inspect
Setup > Territory Settings and disposition capability without enabling/configuring anything
under this authorization. Source/audit/test receipts are under `evidence/P7/BATCH2_*`.

**Exact approval scope:** `manifest/p7-batch2-check.xml` contains six new classes (three
handlers, InventoryReconciliationJob and two tests), modified LeadRoutingHandler and three
entry triggers. `manifest/p7-batch2-destructive.xml` removes LeadBeforeConvertGuard,
LeadAfterConvertSeedBlock, VehicleCounterTrigger and TestDriveFollowupTrigger. Approve both
manifests together; replacements alone would duplicate automation. No permission, page,
setting, territory, report, business-record or scheduler change is selected or authorized.

Batch 1 browser/gallery/event acceptance, operational access/page placement and VIN credentials
remain deferred; Batch 1 is not owner-accepted. Phase 6 OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS
— October 24, 2026 and P6-E01–P6-E14 are unchanged. Later batches remain planning only.

## 40. P7-12 owner-enabled Territory capability reverified — 2026-10-26 UTC

Owner enabled Sales Territories through Setup and authorized read-only verification only.
Organization query confirms ng-demo `00Daj00001Ae3iWEAR`. Native settings were retrieved into
`evidence/P7/P7_12_TERRITORY_SETTINGS_READBACK/`, not force-app. No deployment, model/type/
territory creation or activation, Account/User assignment, record/configuration write or
ng-dev access. Current evidence: `evidence/P7/P7_12_READ_ONLY_REVERIFICATION.md` and raw JSON.

CONFIRMED — raw verifier excerpts:

```json
{"settingsRetrieve":{"id":"09Saj00000mlFcfEAE","status":"Succeeded"},"salesTerritoryEnabled":true,"allFourRequiredObjectsQueryable":true}
```

CONFIRMED — retrieved setting:

```xml
<enableTerritoryManagement2>true</enableTerritoryManagement2>
```

All four required native objects are exposed and SOQL queries succeed: Territory2Model,
Territory2Type, Territory2 and ObjectTerritory2Association. The first three return records=[];
object association count is zero. UserTerritory2Association count is also zero. Thus the earlier
capability blocker is cleared, while the four-territory tree and assignments remain unimplemented.

Native default access is Account Read, Contact Edit, Opportunity None and Case None. Contact
Edit requires explicit owner access review before future membership/assignment/activation;
territory sharing is additive. Opportunity filter is disabled. No CP2/Opportunity/finance change
is proposed. Administrator API access is not actual-persona or rendered-tree acceptance.

Four Rooftop rows match the planned territories. Existing Account.Preferred_Rooftop__c grouping
gives Downtown 38, North 38, Airport 37, Service Centre 37 and five nulls. These are mapping
candidates only; no Account was selected/assigned/repaired. Native rule support for this lookup
criterion, approved inclusion/exclusion and treatment of unmapped Accounts remain decisions.

Next: owner approves the model/type/four-territory hierarchy, candidate mapping and explicit
access/membership design, then separately authorizes local native metadata/check-only work.
Future deployment/Planning-model creation, Account/User assignment and activation each require
explicit approval. Actual tree screenshot plus positive/negative persona access are acceptance
gates. Do not silently expand the existing ten-replacement/four-removal Batch 2 deployment scope.

Existing successful Batch 2 tests/check-only `0Afaj00000p7GCLCA2` (235/235) were not rerun and
completed blocks were not reopened. P7-11 native/browser reader evidence remains open. Phase 6
acceptance/exceptions are unchanged. Batch 1 browser/gallery/event acceptance, operational
access/page placement and VIN credentials remain deferred; Batch 1 is not owner-accepted.

## 41. P7-12 design and scoped local metadata prepared — 2026-10-26 UTC

Owner authorized focused design/read-only inspection and local metadata preparation only. No live
model/type/territory creation, activation, Account/User assignment, metadata deployment, OWD/config
change, Git staging/commit/push or ng-dev access. Design:
`docs/planning/P7_12_TERRITORY_DESIGN.md`; receipt: `evidence/P7/P7_12_DESIGN_RECEIPT.md`.

Native describes verify manual/rule association causes, createable Account/Territory references,
and per-territory access picklists. Recommend a one-time explicitly approved native manual
ObjectTerritory2Association load keyed by Account.Preferred_Rooftop__c; do not assume lookup
rule eligibility or add helper fields, rules, Apex/Flows or recurring sync. Object associations
are not updateable, so future execution requires duplicate/conflict prechecks and receipt-owned
insert IDs. Preserve the five null-rooftop Accounts. The 150 mapped Accounts remain candidates,
not an approved assignment delta. No Lead/Opportunity assignment or Account ownership update.

Live read-only inspection found fourteen Staff.User__c links and four Rooftop manager lookups
all null. Targeted operational-role/profile query, including inactive users, returns only
`005aj00000gE0b3AAC`, NG_Sales / VP_Sales. Preserve that identity's owner-directed metrics-only
boundary; recommend no territory memberships. Three active Salesforce users are administrators
without roles, not rooftop substitutes. Live license query is four total/four used. No existing
rooftop operational user can be assigned by evidence; all four recommended membership lists are
empty until explicit owner identity/responsibility disposition. No admin reclamation/role swap.

Local source is one model NG_Rooftops (Northgate Motors), one shared type NG_Rooftop (priority 1)
and Downtown/North/Airport/Service_Centre as siblings. Explicit access: Account Read, Contact None,
Opportunity None, Case None. All values are native describe options; four objects' live OWD is
Private internally/externally. Contact Edit remains the last retrieved native default. Scoped
server check-only must validate default/override constraints before deployment; do not silently
grant Edit or change settings on rejection. Effective persona access is not verified.

CONFIRMED — raw final local check projection:

```json
{"status":"PASS","localComponents":6,"model":"NG_Rooftops","sharedType":"NG_Rooftop","siblingTerritories":["Airport","Downtown","North","Service_Centre"],"assignmentRules":0,"userMemberships":0,"settingsComponents":0,"unchangedBatch2SourceFiles":20,"convertedComponentsChecked":6,"apexTestsRerun":0}
```

`sf project convert source` succeeded locally; exact converted/source XML/package scope matches.
These are structural/packaging checks, not Salesforce server validation. Twenty prior Batch 2
source hashes and exact ten-replacement/four-removal manifests are unchanged; successful 235 tests
were not repeated. Initial Python HTTPS reference fetch failed; owner approved system curl with
normal certificate verification, which succeeded. No TLS/configuration bypass was introduced.

**Exact separate approval sequence:** first six-component metadata-only check-only using
`manifest/p7-12-territories.xml`; then explicit six-component deployment and Planning-state/
access readback; then reviewed native Account association allowlist excluding the five unmapped
Accounts; then owner-dispositioned User memberships; then explicit model activation/sharing
recalculation and actual tree/persona acceptance. Current user delta is zero. No Settings or
destructive changes are in the territory manifest. Do not merge this unvalidated slice into
the existing independently validated Batch 2 code package by implication.

P7-12 is locally prepared, not server-validated/deployed/accepted. Batch 1 browser/gallery/event
acceptance, operational access/page placement and VIN credentials remain deferred; Batch 1 is
not owner-accepted. Phase 6 exceptions and P7-11 native/browser reader gate remain unchanged.

## 42. P7-12 six-component scoped check-only passed — 2026-10-26 UTC

Owner authorized check-only of the unchanged `manifest/p7-12-territories.xml` against ng-demo
`00Daj00001Ae3iWEAR`. Target ID/Developer Edition and exact six-member/local access scope were
verified before submission. No metadata or manifest was edited to force acceptance.

Command: `sf project deploy start --dry-run --target-org ng-demo --manifest manifest/p7-12-territories.xml --test-level NoTestRun --wait 10 --json`.

CONFIRMED — raw result excerpts:

```json
{"id":"0Afaj00000p7zkYCAQ","status":"Succeeded","checkOnly":true,"completedDate":"2026-10-26T03:24:10.000Z","numberComponentsDeployed":6,"numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0,"componentFailures":[],"warnings":[]}
```

Component successes are exactly NG_Rooftop type, NG_Rooftops model and its Airport/Downtown/
North/Service_Centre territories. Submitted Contact None, Account Read, Opportunity None and
Case None values were accepted. No unrelated metadata components or Apex tests were included;
Developer Edition accepted NoTestRun. Previous 235/235 code regression evidence was not rerun.

Post-check queries for the exact model, type and model-scoped territories each return
records=[] / totalSize=0 / done=true. Check-only persisted none of them; no actual deployment,
activation, Account/User associations, sharing settings, Salesforce data writes or Git release
actions occurred. No ng-dev access. Receipt: `evidence/P7/P7_12_SCOPED_VALIDATION.md` and selected
raw JSON fields. Do not reuse transient check-only component IDs for future assignment data.

No validation blocker remains. Actual six-component deployment requires separate approval and
Planning-state/access readback. Effective persona sharing, the existing user responsibility/
membership decision, Account allowlist/assignment, model activation and actual tree acceptance
remain outstanding. Preserve all five unmapped Accounts and existing Batch 2 code scope.
Batch 1 browser/gallery/event acceptance, operational access/page placement and VIN credentials
remain deferred; Batch 1 is not owner-accepted. Phase 6/P7-11 exceptions are unchanged.

## 43. Phase 7 Batch 2 deployed atomically; territory model remains Planning — 2026-10-26 UTC

Owner authorized both previously validated Batch 2 scopes. Preflight matched all 26 selected
source hashes and exact manifests to the successful validations. Existing 235/235 validation
already covered ten application members plus the four named trigger removals in one transaction.
CLI help confirms --pre-destructive-changes is the supported native destructiveChangesPre.xml
format within the same deployment; that exact validated phase/format was retained. No separate
application-only deployment, additional removal or combined test rerun was needed.

CONFIRMED — raw ordered deployment excerpts:

```json
{"id":"0Afaj00000p84KRCAY","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T03:33:42.000Z","numberComponentsDeployed":14,"numberComponentsTotal":14,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"rollbackOnError":true}
{"id":"0Afaj00000p8GtRCAU","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T03:33:49.000Z","numberComponentsDeployed":6,"numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"rollbackOnError":true}
```

NoTestRun is accepted for this Developer Edition target; prior 235/235 and territory 6/6
validation evidence is reused, not rerun. No failures, warnings, repairs or retries. Application
readback confirms only LeadRoutingTrigger/TestDriveTrigger/VehicleTrigger for those objects,
all four obsolete triggers absent, seven class bodies matching source and twelve unrelated
trigger hashes unchanged. Territory readback confirms NG_Rooftops Planning, shared type priority
1, four siblings, Account Read/Contact None/Opportunity None/Case None persisted, zero Account/
User associations. No sharing-default change or model activation was required/performed.

Evidence: `evidence/P7/BATCH2_DEPLOYMENT.md`, raw sanitized deployment command/results,
`BATCH2_DEPLOYMENT_PREFLIGHT.json`, `BATCH2_APPLICATION_READBACK.json` and
`BATCH2_TERRITORY_READBACK.json`. No CRM record writes, live test reservations, maintenance jobs,
permissions, credentials, territory assignments, Git release actions or ng-dev access.
Batch 2 is deployed, not owner-accepted. Preserve five unmapped Accounts and identity/access/
activation/browser gates. Existing code was not rewritten for Batch 3.

## 44. Phase 7 Batch 3 local implementation and native gates — 2026-10-26 UTC

Batch 3 began only after both Batch 2 deployments/readbacks succeeded. Existing six criteria
and dependencies were inspected; file-level sequence:
`docs/planning/P7_BATCH3_IMPLEMENTATION_PLAN.md`. Full actual results:
`evidence/P7/BATCH3_EXECUTION.md`; native gates: `docs/planning/P7_BATCH3_CAPABILITY_GATES.md`.

P7-13: actual ng-demo-only org strategy/release/LDV/archive note exists. P7-14: five real seams
are indexed in master-plan §4.4; CPQ standard/custom and CP2-basis facts corrected, missing Field
Service/Integration notes added, existing Loyalty/Nurture behavior preserved. No paid product build.

P7-15: one native NG_Case_Triage Flex prompt template is local, Draft-only with no active version
or activation metadata. Inputs are Case Subject/Status/Priority; no Knowledge, action, user grant
or automatic invocation. CONFIRMED — raw scoped check-only:

```json
{"id":"0Afaj00000p8MduCAE","status":"Succeeded","checkOnly":true,"numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
```

Subsequent prompt metadata inventory is empty: not deployed. Runtime model/usage/persona security
is unverified. Read-only settings retrieve 09Saj00000mm9AEEAY confirms Prompt platform enabled,
but Agent Platform/Copilot/Bots disabled. P7-15 remains partial; no working agent or prompt run.
Knowledge is ten Drafts only; no publication/grounding acceptance.

P7-16: CustomerDataPlatform is disabled, stream count zero and DataSpace not exposed; no native
ingestion/identity build or runtime match/negative-match proof. P7-18: Networks disabled, no Site/
Network. Community/Plus/Partner licenses each five total/zero used; External Identity nine/zero.
Those counts do not choose an external identity/security model. Site enablement, native spaces/
credits, actual external/internal users, object/relationship security and data/runtime actions
require owner decisions; no substitute Flow, React, custom duplicate data model or fake screenshot.

P7-17: scripts/test.sh + narrow runner implement plan-only default and explicit full-run org/
check-only/Apex/DQ sequence, reusing existing strict verify.sh. No obsolete destructive replay.
Local fake-executor tests, shell syntax, plan-only invocation and source/docs scope check pass;
26 prior Batch 2 source hashes remain unchanged. Zero additional Apex methods or DQ/full native
gate runs; unchanged 235/235 evidence reused. Dirty-tree/strict-DQ/clean-checkout release acceptance
remains open and is not mislabeled green. See docs/verification/P7_REGRESSION_GATE.md.

**Exact new Salesforce deployment approval scope:** one Draft GenAiPromptTemplate NG_Case_Triage
in manifest/p7-batch3-check.xml only. No agent, setting, permission, Data Cloud, site, user, data,
Flow, Apex, activation or destructive change is included. No Batch 3 deployment or persistent
data/configuration changes were issued. Native capability enablement/actual demos need separate
decisions/approvals; Batch 3 is not fully accepted. No Git staging/commit/push or ng-dev access.

Neither Batch 1 nor Batch 2 is owner-accepted. Batch 1 browser/gallery/event acceptance, page
placement, operational access and VIN credentials remain deferred. Territory model stays Planning
with zero associations/memberships. Phase 6 acceptance/exceptions remain intact; Phase 8 not started.

## 45. Phase 7 Batch 4 local implementation and two-component check-only — 2026-10-26 UTC

Owner authorized P7-19/P7-20/P7-21/P7-23 local implementation and scoped validation only.
Exact requirements, §44 and relevant photo/page/persona dependencies were inspected first;
file-level plan: `docs/planning/P7_BATCH4_IMPLEMENTATION_PLAN.md`. Actual receipt:
`evidence/P7/BATCH4_EXECUTION.md`. No Batch 3/4 deployment, feature/page activation, permissions,
users, business records, Git staging/commit/push or ng-dev access.

P7-19: one-page `docs/architecture/AUTOMOTIVE_CLOUD_MAPPING.md` maps current standard/custom
dealership entities to licensed concepts and gaps; no Automotive Cloud metadata/package build.
P7-20: README now states actual deployed/local/gated functionality, ng-demo-only historical two-org
strategy, source/toolchain/evidence, safe scoped deployment/regression and reset-plan boundaries.
No reset, release tag or clean-green gate is claimed.

P7-23: new vehiclePhotoHeader LWC uses native UI API required Name and optional Photo/model
fields, local WebP path validation and no raw formula HTML/Apex/write/financial-field access.
Missing/omitted/unsafe/failed images and read/navigation/stale states degrade gracefully.
New NG_Vehicle_Photo_Header FlexiPage retains native highlights/details and existing service
history, with the photo component first in main. Existing pages/mappings/gallery/domain source
remain untouched; no object/app/profile assignment is selected. Scope:
`manifest/p7-batch4-check.xml` contains only the new LWC bundle and new FlexiPage.

CONFIRMED — raw final check-only:

```json
{"id":"0Afaj00000pBPvPCAW","status":"Succeeded","checkOnly":true,"completedDate":"2026-10-26T12:44:18.000Z","numberComponentsDeployed":2,"numberComponentsTotal":2,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0,"componentFailures":[],"warnings":[]}
```

The first exact-scope check `0Afaj00000pBWLmCAO` compiled the LWC but rejected draft-page
force:recordDetail design-time information. Under the owner's routine-local-correction authority,
Salesforce's official lwc-recipes record-page source verified force:detailPanel as the native
identifier; only that new-page identifier was corrected. The same two-component scope then
passed. No speculative loop, removed details, access workaround or unrelated change. Initial
failure receipt is retained with the exact error. NoTestRun was accepted; no Apex methods ran.

CONFIRMED — raw Node totals and local preservation/scope excerpts:

```text
# tests 6
# pass 6
# fail 0
```

```json
{"status":"PASS","metadataComponents":2,"apexComponents":0,"currentPersonaScripts":5,"localLinksChecked":27,"priorBatch2SourceHashesPreserved":26,"batch3DraftPromptUnchangedAndExcluded":true,"apexTestsRerun":0,"pageAssignmentsIncluded":0,"actualScreenshotsAndWalkthroughs":"NOT VERIFIED"}
```

Six new state checks use real component logic/UI API stubs; no DOM/browser/persona-FLS pass is
claimed. Targeted live Tooling queries for the new LWC/page each return records=[]/totalSize=0:
neither persisted. Existing 235-test and photo/license/archive evidence was reused, not repeated.

P7-21: five current Admin/Developer/Analyst/Support/Architect walkthroughs and index exist under
evidence/DEMO_SCRIPTS. Every current script starts with Activate persona and requires an actual
approved identity; no role switch/admin substitute is used. Old P2 script is retained as explicitly
historical/non-executable. Each pack entry is NOT RUN/NOT SIGNED OFF; Support identity/access
remains BLOCKED. No native screenshot, business-write walkthrough or end-to-end sign-off invented.

**Exact future approval scope:** two new Salesforce components in manifest/p7-batch4-check.xml:
LightningComponentBundle vehiclePhotoHeader and FlexiPage NG_Vehicle_Photo_Header. Actual
deployment and intentional page placement/activation require separate owner approval; no grant,
user, setting, object/action override, app, Flow, Apex, asset or destructive scope. Batch 3's one
Draft prompt is separate and still not deployed. With/without-photo record-page screenshots,
actual-reader/mobile/visual checks and all five live walkthroughs remain acceptance gates.

P7-19/P7-20 documentation and P7-21/P7-23 source preparation do not complete M3. Keep Agentforce,
Data Cloud, portal and full regression/DQ/clean-checkout acceptance outstanding, Phase 5/6 exceptions
intact, and Batch 1 browser/gallery/event/page/operational/VIN gates deferred. Neither Batch 1 nor
Batch 2 is owner-accepted; Batch 3/4 acceptance is not inferred. No Phase 8 implementation started.

## 46. Final authorized Batch 3/4 deployments and preservation readback — 2026-10-26 UTC

Exact validated manifests/source hashes were verified against 0Afaj00000p8MduCAE and
0Afaj00000pBPvPCAW. Each Quick Deploy was explicitly unavailable; owner-authorized standard
scoped fallback deployed the same components. Exact availability reasons were "Source validate
did not run tests in the org" and "There have been deploys in the org since the source validate
happened". No actual deployment failed, no scope expansion/repair/new validation or test rerun.

CONFIRMED — raw actual deployment projections:

```json
{"id":"0Afaj00000pCUHtCAO","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T13:58:55.000Z","numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
{"id":"0Afaj00000pCURZCA4","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-26T13:59:05.000Z","numberComponentsDeployed":2,"numberComponentsTotal":2,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
```

Native retrieve 09Saj00000mqJ4XEAU confirms NG_Case_Triage exists with one Draft version and no
active version, vehiclePhotoHeader exists and NG_Vehicle_Photo_Header exists. No prompt/agent
execution, publication, page assignment/activation or extra feature/permission setup.

Before/after live retrievals 09Saj00000mqItFEAU / 09Saj00000mqJ7lEAE compare Vehicle action
overrides and all action/profile overrides in 37 application definitions. Semantic assignment
hash is identical. Six relevant settings, 31 permission assignments, 23 group-member mappings,
13,370 object-permission rows, 26,333 field-permission rows, ten User role/profile/active mappings
and all live trigger hashes/statuses also match. ID/LastModifiedDate fingerprints/counts for
27 visible non-deleted project business-object inventories match; no customer fields exported.
This bounded evidence is not an exhaustive field/history/deleted/background-event audit.

CONFIRMED — raw verification projection:

```json
{"status":"PASS","promptInactive":true,"promptVersionStatuses":["Draft"],"headerAndPageExist":true,"unchangedComparisons":{"vehicleAndApplicationAssignmentSha256":true,"settingsSha256":true,"securityFingerprints":true,"businessRecordFingerprints":true,"triggerFingerprints":true},"territoryModelState":"Planning","accountAssociations":0,"userMemberships":0,"newTestsRun":0,"phase8Implemented":false,"pageActivatedOrAssigned":false}
```

Only three authorized metadata definitions changed; exact component counts and commands are
in `evidence/P7/P7_FINAL_DEPLOYMENT.md` and sanitized BATCH3_FINAL/BATCH4_FINAL receipts. Draft/
inactive and unassigned-page states are verified, not browser rendering or persona acceptance.
No business-data mutation, feature/default/sharing/permission/user change, territory activation/
assignment, Git staging/commit/push or ng-dev access. Earlier tests were reused, not repeated.

## 47. Phase 7 23-block status, exceptions, Git and Phase 8 starting point — 2026-10-26 UTC

**Phase 7 is not fully accepted on the owner's behalf. M3 is not passed.** Detailed 23-row
inventory: `docs/planning/PHASE7_FINAL_STATUS_2026-10-26.md`. Every original ID is retained:

- P7-01/P7-02: deployed gallery/calculator; actual access, placement, photo/reservation/widget
  browser UAT pending. P7-03: deployed mock VIN client; credential/host/principal/live transport
  and real timeout pending. P7-05: deployed native event/subscription; actual browser delivery pending.
- P7-04/P7-06: contract and event/CDC seam delivered; no real decoder/CDC/external consumer implied.
- P7-07/P7-08: consolidated triggers and isolated-tested reconciliation deployed; no live repair/job
  or Batch 2 owner operational acceptance. P7-09/P7-10: governance and honest debt register delivered.
- P7-11: administrative assignment audit delivered; native/browser/actual-reader and usage proof
  pending. P7-12: Planning type/model/four territories deployed; no Account/User assignments or
  activation/tree/persona acceptance; five unmapped Accounts preserved.
- P7-13/P7-14: actual org strategy and all five seams delivered. P7-15: Draft prompt now deployed,
  not an agent; feature/Service identity/model/quota/runtime evidence pending. P7-16: Data Cloud
  disabled; native space/credits/ingestion/identity/negative-match proof pending. P7-17: wrapper
  implemented/local-tested, full native/DQ/clean-checkout release gate unexecuted. P7-18: no portal seed;
  Networks disabled and external license/identity/relationship/security/actual login unresolved.
- P7-19/P7-20: Automotive concept note and accurate README delivered. P7-21: five persona-first
  scripts prepared, none signed off end-to-end; Support identity blocked. P7-22: thirty licensed
  photo assets deployed/rights/archive verified, actual rendering screenshot pending. P7-23: photo
  header/page deployed unassigned, actual placement/reader/mobile/with-without-photo evidence pending.

Keep all Batch 1/2 browser/operational/page/access/VIN/event and owner-review exceptions. No
Agentforce/Data Cloud/portal acceptance is inferred from metadata. Formal Phase 6 OWNER-ACCEPTED
WITH DOCUMENTED EXCEPTIONS — October 24, 2026 and all P6-E01–P6-E14 remain unchanged, as do Phase 5
historical data/DQ/ledger/report/CSI/release exceptions. No Knowledge publication/import replay,
loyalty activation/reconciliation/jobs, portal user or additional runtime data is authorized.

Git remains main with modified/deleted/untracked source and no staged entries. HEAD and freshly
queried origin/main both equal 0423863794b70bb13c3c59128f7b57a0313aa0f4; cached ahead/behind is
0/0. git ls-remote read the live ref without fetch/update, commit, push or tag. Exact final counts/
timestamp are in `evidence/P7/P7_FINAL_GIT_STATUS.json`; no clean Phase 7 release is claimed.

CONFIRMED — raw Git snapshot excerpt, 2026-10-26T14:17:13.997989+00:00:

```json
{"branch":"main","trackedChanges":72,"trackedDeletions":8,"untrackedFiles":3062,"stagedEntries":0,"cleanWorkingTree":false,"headMatchesLiveRemoteMain":true,"cachedAheadBehind":["0","0"],"fetchStageCommitPushPerformed":false}
```

CONFIRMED — raw new document/coverage check:

```json
{"status":"PASS","phase7BlocksCovered":23,"uniquePhase7Blocks":23,"phase8RequirementsCovered":11,"uniquePhase8Requirements":11,"deploymentVerification":"PASS","newSalesforceCalls":0,"testsRerun":0,"currentLocalLinksChecked":30,"phase8Implementation":false}
```

**Exact Phase 8 start:** preparation only in `docs/planning/PHASE8_HANDOFF_2026-10-26.md`. All
eleven P8-01–P8-11 requirements and original acceptance/dependencies are preserved. Resolve D3–D6:
Digital Experiences/domain enablement, external license/per-object rights and approved Contact/
Account identities, own-vehicle/relationship/sharing policy and the missing P7-18 seed decision.
Vehicle has reservation links, not a direct current-owner relationship; completed Delivery buyer/
vehicle links are only candidates, not an automatic ownership/resale model. No broad inventory/
loyalty grant or system-mode license bypass. Preserve separate Sales/Finance/VP/admin identities.

Proposed three independently testable blocks: A = P8-01–03 secure foundation/own-data isolation;
B = P8-04–09 feature slices (history/vehicles, then appointment/Case writes, read-only loyalty,
dashboard composition); C = P8-10–11 mobile/accessibility/real-persona UAT/seam evidence. Every
read/write needs actual external-user cross-customer/guest negatives. Reuse existing capacity,
intake, photos and domain logic without touching CP2 or activating loyalty. No new Flow/React.
Do not implement or deploy Phase 8 until a bounded owner-approved plan/configuration/data scope.

## 48. Phase 8 foundation read-only prerequisites and one architecture — 2026-10-26 UTC

Owner authorized planning/read-only verification only, focused on P8-01–P8-03. Existing handoff
and all eleven backlog requirements were read. No application code/metadata, deployment,
enablement, site/user/share/permission/record modification, Git release action or ng-dev access.
Evidence: `evidence/P8/FOUNDATION_PREREQUISITES_2026-10-26.md`; concrete proposal and next action:
`docs/planning/PHASE8_FOUNDATION_DECISION_2026-10-26.md`.

CONFIRMED — native retrieved setting and license excerpts:

```xml
<enableNetworksEnabled>false</enableNetworksEnabled>
<myDomainName>orgfarm-25065ad46a-dev-ed</myDomainName>
```

```json
{"Name":"Customer Community Plus","TotalLicenses":5,"UsedLicenses":0}
```

Retrieve 09Saj00000mqaOjEAI reads Communities/MyDomain into evidence only. Domain records already
provision the existing my.site.com Experience hostname; Site count is zero. One unauthenticated
HTTPS HEAD timed out (curl 28/HTTP 000). Reachability is unverified, not diagnosed as an org defect;
owner must confirm domain status/browser access. No retry, TLS bypass or domain registration.

External OWD for Account/Contact/Case/Delivery/Vehicle/Vehicle Model/Rooftop/Service Visit/Loyalty
Member is Private; Loyalty Transaction is ControlledByParent. No OWD change is needed/proposed.
Standard Plus profile exists with Case Read/Create/Edit and no View All/Modify All; custom-object
grants and actual external-user FLS/sharing still require future verification. No users are linked
to Contacts. Internal permissions/roles/territory security remain unchanged.

Relevant read-only evidence: 229 Contacts, 205 linked to Account, 201 seeded with Account/email.
Seven completed deliveries have six missing Buyers and one complete Buyer/Vehicle candidate.
That UAT buyer's Account owner has no role. Across 155 Accounts, 154 have roleless owners; the one
role-bearing-owner Account is VP-owned with one Contact and is not that delivery Account. Two
seeded service-history candidates have roleless owners and .test emails; no two provisioning-
ready/ownership-verified customers were established. No names, email values, addresses, VINs or
notes were collected; no Buyer data, customer ownership or role was repaired.

**One recommendation, pending approval:** login-only Customer Service (Aura) Experience site,
two Customer Community Plus test identities, standard login, custom LWC and with-sharing/USER_MODE/
CRUD-FLS checked Apex. Strict current-Contact predicates plus exact per-user native Read shares
protect Vehicle/visit/Case/loyalty paths. Use owner-confirmed completed Delivery Buyer/Vehicle
evidence for pilot ownership; reservations, visits or Account membership are not title. Ambiguous
or unconfirmed ownership denies access. No new ownership schema proposed; old blanket roleless/
no-direct-object-grant text needs explicit owner clarification under verified external Private OWD.

The foundation is read-only. Later Create grants require authoritative external-customer write
guards, direct-API negatives, share grant/revocation and preserved capacity/intake/Case routing.
Standard Case shares need revalidation after owner/contact changes. No controller-only/native-API
bypass, broad customer-role/territory grant or system-mode license workaround is acceptable.

**Smallest next owner action:** approve Digital Experiences enablement only on the existing
domain. Setup > Digital Experiences > Settings; confirm domain/enablement notice and save only
after explicit approval. Stop before New Site, users, profiles/sharing, publish/activation.
Before code, owner also confirms Plus/template/contact policy, narrow object Read clarification,
current-ownership evidence and two pilot identities with supported Account-owner role eligibility.
No admin/VP role swap, Account transfer, new fixture or mailbox change is implicit.

Minimum future tests use actual external A/B users: own-read, foreign/same-Account denial,
guest/internal-no-Contact rejection, unverified/reservation-only ownership denial, field/internal-
comment suppression, no writes in foundation, direct API/foreign-ID tampering denial and stale-
share revocation. No test code/users were created now. Phase 7/6 exceptions and deferred browser/
operational/page/Agentforce/Data Cloud/portal/regression acceptance remain unchanged.

## 49. Enabled Digital Experiences and local foundation preparation — 2026-10-26 UTC

Owner permits P8-01–P8-03 continuation, read-only verification and feasible local security source,
not org writes/deployment. Retrieve 09Saj00000msYViEAM confirms enableNetworksEnabled=true;
Network query is empty and native template listing includes Salesforce / Customer Service.
Plus profile UserType is PowerCustomerSuccess; licenses remain Plus five/zero used, internal
Salesforce four/four used. The community-list CLI plugin installed locally on demand; no feature
was changed by the agent. Architecture: login-only Customer Service (Aura), Northgate Owner Portal
/ owners, Plus, standard login, Contact-specific private access and no guest business data.

**Safest proposed provisioning:** preserve all existing customers/owners/internal roles; two new
isolated synthetic Account/Contact pairs owned from creation by existing role-qualified VP_Sales
identity solely for native provisioning, only with explicit owner approval of that limited fixture
responsibility. No VP customer impersonation, role/profile changes, admin reclamation or Account
transfer. If the fixture-owner policy is not approved, stop there; no implicit fallback. Two Plus
users would later consume two free external slots, no new internal license. All creation/grants
and invitations remain unauthorized.

Existing SEED-07-054, SEED-07-116 and the single UAT delivery Buyer remain distinct roleless-owned
Contact/Account review candidates, not provisioning-ready users. One complete Buyer/Vehicle
delivery remains; missing Buyers were not repaired. New pilot Contacts start with no confirmed
cars/history; future positive ownership fixtures/evidence need separate approval. Do not reparent
old Contacts/deliveries or use reservation/service history as ownership.

Four local definitions in manifest/p8-foundation-preparation.xml: OwnerPortalFoundationController,
its test class, Access_Northgate_Owner_Portal and unassigned PS_Owner_Portal_Foundation. The
non-cacheable endpoint accepts no identity selectors, requires active Plus/Contact/permission/
exact live site, and returns own Contact/Account IDs through USER_MODE reads only. Own User/license
and current Network metadata are the only system-mode reads. No names/emails, Case/Vehicle/finance
data, CRUD writes, shares or other-customer endpoints. Wrong/internal/guest/unpublished contexts deny.

Permission source allows only controller/custom permission and Account/Contact Read plus
Contact.AccountId Read. No Create/Edit/Delete/View All/Modify All or other object rights. It is
not assigned and cannot remove the base Plus profile's Case Edit: hardened portal-only Profile
review remains mandatory. No invented Network/CustomSite/Experience/Profile/role/user/share metadata;
capture real native site definitions only after separately approved creation.

CONFIRMED — raw local check projection:

```json
{"status":"PASS","localMetadataComponents":4,"siteProfileUserSharingComponents":0,"contextCacheable":false,"permissionSetAssigned":false,"sourcePolicyTestsProvided":3,"apexTestsExecuted":0,"serverCompilation":"NOT RUN","positiveExternalUserSiteFlsProof":"NOT VERIFIED","orgWritesPerformed":0}
```

Native local conversion/XML/scope/guard checks pass. No Salesforce compilation/check-only/deploy
or Apex tests ran. Three source tests cover eligibility/site policy and internal-context denial
without user/record creation; unexecuted policy facts are not actual external-user/FLS/site proof.
No completed Phase 7 work/tests reopened. Evidence: evidence/P8/ENABLED_FOUNDATION_PREPARATION.md
and LOCAL_FOUNDATION_CHECK.json; exact plan: docs/planning/P8_FOUNDATION_LOCAL_PREPARATION.md.

**Next owner decision:** approve/reject limited fixture-account ownership by the existing role-
qualified user. Native site creation (including technical guest identity/profile with no business
rights), hardened profile, two pilot users/membership/shares, server validation/deployment and
publication/login each require bounded approval. No org data/ownership/sharing/permission/user/
site change, Git stage/commit/push or ng-dev access. Existing CP2/domain/territory security remains.

## 50. Authorized P8 two-customer fixture creation — 2026-10-26 UTC

Owner authorization was already granted; it was not requested again. The existing helper
`scripts/portal/create_customer_fixtures.py` was executed unchanged against ng-demo
`00Daj00001Ae3iWEAR` only. No site, external user, share, permission, role, deployment, metadata
operation or ng-dev access occurred.

Preflight CONFIRMED: owner `005aj00000gE0b3AAC` active, Standard/Salesforce, role `VP_Sales`,
effective Account Read; both `Seed_Tag__c` fields unique/external-ID/createable; fixtures absent.

CONFIRMED — one Composite REST request, `allOrNone=true`, four POSTs, all HTTP 201:

| Pair | Account | Contact |
|---|---|---|
| A | `001aj000049ZoXNAA0` — Northgate Portal Test Customer A / `P8-PORTAL-ACCOUNT-A` | `003aj00002Xl4IfAAJ` — Northgate Portal Test Customer A / `P8-PORTAL-CONTACT-A` |
| B | `001aj000049ZoXOAA0` — Northgate Portal Test Customer B / `P8-PORTAL-ACCOUNT-B` | `003aj00002Xl4IgAAJ` — Northgate Portal Test Customer B / `P8-PORTAL-CONTACT-B` |

All four records are owned by `005aj00000gE0b3AAC`; each Contact links only to its own new Account;
neither Account has a `ParentId`. Optional Account/Contact fields are null. Account rows
155 → 157 and Contact rows 229 → 231. Prior Account/Contact SHA-256 fingerprints are equal
before/after; User and role state hashes are unchanged; all 13 isolation scopes are zero.

Independent read-only verification CONFIRMED: only 2 Accounts and 2 Contacts created since
`2026-10-26T20:17:30Z`; zero prior Accounts/Contacts and zero rows in all 14 related business
objects modified since; zero external users; zero owner/parent/relationship deviations.

Idempotency CONFIRMED: rerun at `20261026T202542418699Z` returned `REUSED_NO_WRITES`,
`accountsCreated=0`, `contactsCreated=0`, Account rows `157/157`, Contact rows `231/231`, all
seven preservation checks true. No duplicate was created.

The unsupported `CustomPermission` SOQL query (`INVALID_TYPE`) is recorded separately and is not a
fixture-creation blocker. No foundation metadata was deployed; the two Apex classes and permission
set remain absent live, and CustomPermission live state is unverified. Git HEAD
remains `0423863794b70bb13c3c59128f7b57a0313aa0f4`; zero staged entries; no commit or push.
`QuoteBuilderController.cls` and `QuotePricingService.cls` hashes are unchanged.

Evidence: `evidence/P8/CUSTOMER_FIXTURES_CREATION_2026-10-26.md` and the raw
`CUSTOMER_FIXTURES_*` receipts in `evidence/P8/`.

**Next prerequisite:** owner approval for native Customer Service (Aura) site creation
(login-only `Northgate Owner Portal` / `owners`, no publication), including the technical guest
identity/profile with no business-data rights. Then hardened portal profile review, server
validation/deployment of the four foundation definitions, and two Customer Community Plus
users/membership/narrow shares. The new Contacts have no confirmed vehicle ownership or service
history; positive own-data fixtures remain separately gated.

## 51. Authorized P8-01 site creation — 2026-10-26 UTC

Owner authorization was already granted; it was not requested again. Only the site was created in
ng-demo `00Daj00001Ae3iWEAR`. No publish/activate, external user, site membership, share, profile/
permission/role/OWD change, deployment, Git stage/commit/push or ng-dev access occurred.

Preconditions CONFIRMED: `Settings:Communities` retrieves `enableNetworksEnabled=true`; pre-creation
Network/CustomSite/ExperienceBundle lists are empty; only the enablement workspace existed in
DigitalExperienceBundle; `sf community list template` includes Salesforce / Customer Service; the
existing domain `orgfarm-25065ad46a-dev-ed.develop.my.site.com` (`0I4aj00000G182LCAR`) was reused
and no My Domain/domain change was made.

CONFIRMED — supported mechanism `sf community create` (CLI community plugin, Connect API), which
creates the site under construction:

```json
{"status":0,"result":{"message":"Your Site is being created.","name":"Northgate Owner Portal","jobId":"08Paj00001CQFPWEA5"}}
{"Id":"08Paj00001CQFPWEA5","Status":"Complete","Error":null,"Type":"SiteTaskCreate"}
```

CONFIRMED — resulting IDs:

| Artifact | Name | ID |
|---|---|---|
| Network | Northgate Owner Portal | `0DBaj000006bf3xGAA` |
| CustomSite | Northgate_Owner_Portal | `0DMaj000006c7JZGAY` |
| ExperienceBundle | Northgate_Owner_Portal1 | `0DMaj000006c7JaGAI` |
| DomainSite `/owners` | — | `0Jfaj000004Z1tNCAS` |
| DomainSite `/owners/s` | — | `0Jfaj000004Z1tOCAS` |
| Domain | orgfarm-25065ad46a-dev-ed.develop.my.site.com | `0I4aj00000G182LCAR` |
| Site guest user | Northgate Owner Portal Site Guest User | `005aj00000gnLcbAAE` |
| Site guest profile | Northgate Owner Portal Profile (Guest User License) | `00eaj00000UB3CcAAL` |

CONFIRMED — site state: `Status=UnderConstruction`, `FirstActivationDate=null`,
`UrlPathPrefix=owners`, `OptionsSelfRegistrationEnabled=false`, `SelfRegProfileId=null`,
`OptionsAllowInternalUserLogin=false`, `OptionsInvitationsEnabled=false`,
`OptionsGuestMemberVisibility=false`. Retrieved Network XML confirms `<selfRegistration>false`,
`<enableGuestChatter>false`, `<enableGuestFileAccess>false`, `<status>UnderConstruction`.
CustomSite XML shows the standard generated `<active>true</active>` plus
`authorizationRequiredPage=CommunitiesLogin`; publication state is the Network under-construction
status, and no publish command was run. URL:
`https://orgfarm-25065ad46a-dev-ed.develop.my.site.com/owners` (app path `/owners/s/`).

CONFIRMED — login-only guest behaviour: `GET /owners` returns a 512-byte bootstrap page that only
redirects to `/owners/login`; `/owners/s/` and `/owners/s/aura` return `302` to
`/owners/login?ec=302&startURL=…`; `/owners/login` returns `200` titled `Login | Northgate Owner
Portal` with only the login form. No customer can authenticate: zero Customer Community Plus users
and zero customer/external site memberships. The only `NetworkMember` rows (3) are Salesforce-
generated internal admin/automation memberships: Arjun Subramanya `005aj00000feqbNAAQ`,
OrgFarm EPIC `005aj00000fH2LxAAK`, Northgate Backup Admin `005aj00000gBoPVAA0` (all Standard users).

CONFIRMED — guest profile has no business access. **Corrected 2026-10-26 (P8-02):** profile
permissions live under the profile-owned permission set `0PSaj00000h7bZyGAI`, not the Profile Id.
That set has **0 ObjectPermissions**, **988 FieldPermissions (930 editable, standard guest FLS
defaults, inert without object permission)**, **16 ApexPage + 1 TabSet and 0 ApexClass** access
(standard site pages incl. `CommunitiesSelfReg`/`SiteRegister`), and every checked system permission
false (`PermissionsApiEnabled`, `PermissionsViewSetup`, `PermissionsModifyAllData`,
`PermissionsViewAllData`, `PermissionsManageUsers`, `PermissionsAuthorApex`, `PermissionsDataExport`,
`PermissionsManageSharing`, `PermissionsRunReports`, `PermissionsManageCases`). Its only
permission-set assignment is its own profile-owned set. Public registration is disabled at the site
level and no self-registration profile is assigned.

Residual observation: the standard `CommunitiesSelfReg` page still renders a form to an
unauthenticated visitor (`GET /owners/CommunitiesSelfReg` → 200). The site setting is false and no
self-registration profile exists, so submission is expected to be rejected, but no submission was
attempted because that could create an external user. Close/verify this before any publish.

CONFIRMED — preservation: no external users created; licenses unchanged (Customer Community Plus
5/0, Customer Community 5/0, Partner Community 5/0, External Identity 9/0); fixtures
`001aj000049ZoXNAA0`/`003aj00002Xl4IfAAJ` and `001aj000049ZoXOAA0`/`003aj00002Xl4IgAAJ` unchanged
with OwnerId `005aj00000gE0b3AAC`; Account 157, Contact 231, Network 1; external OWD still Private
(Account/Contact/Case/Delivery__c/Vehicle__c/Service_Visit__c/Vehicle_Model__c) and
Loyalty_Transaction__c still ControlledByParent; the four foundation definitions remain absent live.
Git HEAD unchanged at `0423863794b70bb13c3c59128f7b57a0313aa0f4`; no commit/push.

**P8-01 is not fully accepted.** Site configuration is verified, but acceptance still requires the
hardened portal profile, external users/membership, narrow reviewed shares, deployed/validated
foundation Apex and negative access tests. Evidence:
`evidence/P8/SITE_CREATION/P8_01_SITE_CREATION_2026-10-26.md` plus raw artifacts in that folder.

## 52. P8-02/03 security foundation preparation/check-only — 2026-10-26

Scope: local preparation and check-only in ng-demo only. No deployment, configuration, user,
membership/share, internal-profile or CP2 changes; no Git staging/commit/push or ng-dev access.
Evidence and exact raw result extracts:
`evidence/P8/PROFILE_PREP/P8_02_03_SECURITY_FOUNDATION_2026-10-26.md`.

CONFIRMED — raw profile result (`validate_profile.json`):
```json
{"id":"0Afaj00000pFlPSCA0","checkOnly":true,"status":"Succeeded","numberComponentErrors":0,"numberComponentsTotal":1,"numberTestsCompleted":0}
```
Local profile `NG_Owner_Portal_User` uses Customer Community Plus with only Account/Contact Read
and Contact.AccountId Read. No Case, writes, View All/Modify All, system permissions or Apex.
Internal profiles remain untouched. Manifest: `manifest/p8-02-profile-preparation.xml`.

REFUTED — foundation validation passed (`validate_foundation_report.json`):
```json
{"id":"0Afaj00000pGEeLCAW","checkOnly":true,"status":"Failed","numberComponentErrors":0,"numberComponentsTotal":4,"numberTestErrors":0,"numberTestsCompleted":3,"numberTestsTotal":3}
```
```text
OwnerPortalFoundationController - Test coverage of selected Apex Class is 37.5%, at least 75% test coverage is required
```
All four definitions compile and custom-permission/permission-set references resolve in the
package. They and the new profile remain absent live. Tests passing is not a security acceptance:
the controller success path, actual licensed-persona CRUD/FLS and customer isolation remain unproven.
No controller/test repair was made. **Stop affected work pending owner approval** of a bounded
testability change and positive/negative tests, followed by scoped revalidation.

CONFIRMED — registration readback:
```json
{"OptionsSelfRegistrationEnabled":false,"SelfRegProfileId":null,"OptionsInvitationsEnabled":false}
```
`GET /owners/CommunitiesSelfReg` returns 200 because the standard guest-accessible page renders
unconditionally. Its standard controller sets `profileId = null` before `Site.createExternalUser`.
No form was submitted; rejection is not empirically verified. Review exposure before publication.

CONFIRMED — sole profile membership row:
```json
{"Id":"0DLaj000002SEDNGA4","ParentId":"00eaj00000T6Z8rAAF","NetworkId":"0DBaj000006bf3xGAA"}
```
System Administrator membership explains the notification; only the three existing internal
administrators are NetworkMembers. No customer profile membership or external users.
Earlier zero guest FLS/page-access claims are REFUTED: profile-owned set has 0 ObjectPermissions,
988 FLS rows (930 editable in saved row-level output), 16 ApexPages + 1 TabSet, 0 ApexClasses.

Smallest future deployment approval: profile + controller/test + custom permission + unassigned
permission set (five components), only after coverage repair approval and successful validation.
No site metadata, users, assignments, memberships/shares or publication included. Actual external
login/isolation, registration POST, full regression and CP2 runtime checks were skipped. Both
synthetic pairs and existing functionality were not modified, not newly runtime-tested.

## 53. P8-03 authorized test repair — 2026-10-26

Only `OwnerPortalFoundationControllerTest.cls` changed: two null-fact policy tests and an
early-denial query-count assertion; existing positive/negative assertions preserved. Production
controller and hardened profile unchanged. Exact evidence:
`evidence/P8/COVERAGE_REPAIR/P8_03_COVERAGE_REPAIR_2026-10-26.md`.

CONFIRMED — raw check-only report:
```json
{"id":"0Afaj00000pHKg5CAG","checkOnly":true,"status":"Failed","numberComponentErrors":0,"numberComponentsTotal":4,"numberTestErrors":0,"numberTestsCompleted":5,"numberTestsTotal":5}
```
REFUTED — coverage reaches 75%:
```text
OwnerPortalFoundationController - Test coverage of selected Apex Class is 37.5%, at least 75% test coverage is required
```
20/32 locations remain uncovered behind the actual external-user gate (lines 14–26, 28–34).
Focused tests ran inside validation, not against absent live classes. No production defect found;
no bypass/refactor made. Stop affected work pending explicit owner approval of a bounded production
testability refactor/security test plan or alternative actual-persona test authorization.
Last verified: four components compile, 5/5 tests pass, coverage blocks validation/deployment.
Profile validation `0Afaj00000pFlPSCA0` remains separate and unchanged. No deployments, users,
permissions, shares, data/configuration changes, publication or Git release actions; no ng-dev.
External-persona runtime security and full regression remain unverified.

## 54. P8-03 real external-user fixture investigation — 2026-10-26

Changes: added one transaction-local external-user fixture test to
`OwnerPortalFoundationControllerTest.cls`; updated local checker to permit authorized fixture
DML and count 6 tests. No controller/profile/permission metadata changes. Evidence:
`evidence/P8/EXTERNAL_USER_INVESTIGATION/P8_03_EXTERNAL_USER_INVESTIGATION_2026-10-26.md`.

CONFIRMED — raw check-only report:
```json
{"id":"0Afaj00000pHSowCAG","checkOnly":true,"status":"Failed","numberComponentErrors":0,"numberComponentsTotal":4,"numberTestErrors":1,"numberTestsCompleted":5,"numberTestsTotal":6}
```
REFUTED — controller coverage reaches 75%: measured 37.5%, 20/32 locations uncovered
(lines 14–26, 28–34). New test fails before external runAs assertions:
```text
OwnerPortalFoundationControllerTest.realPlusUserWithoutPermissionOrSiteFailsClosed
System.DmlException: Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION, To create or update users for this profile, go to Setup > Digital Experiences > Settings and select Allow using standard external profiles for self-registration, user creation, and login.: [ProfileId]
Class.OwnerPortalFoundationControllerTest.realPlusUserWithoutPermissionOrSiteFailsClosed: line 32, column 1
```
Stop; no setting changes or speculative retries. No production defect found. Network-context
assertions were not reached; do not treat them as verified. No permissions/memberships assigned.
Specific owner decision: approve a five-component check-only package including the unchanged
hardened custom profile, and use it instead of the standard external profile in the rolled-back
fixture. This avoids the observed standard-profile policy without changing org configuration;
it does not guarantee remaining permission/site-context tests or 75% coverage.
Last all-tests-passing state: `0Afaj00000pHKg5CAG` (5/5, 37.5%). Current local investigation test
remains failing, explicitly not deployment-ready. No persistent users/data, deployment, sharing,
publication, Git release actions or ng-dev access. Profile validation remains unchanged.

## 55. P8-03 single five-component check-only — 2026-10-26

Added `manifest/p8-five-component-validation.xml` and selected `NG_Owner_Portal_User` in the
fixture's Profile query; controller/profile and all assertions unchanged. CONFIRMED — raw result:
```json
{"id":"0Afaj00000pGXlqCAG","checkOnly":true,"status":"Failed","numberComponentErrors":0,"numberComponentsTotal":5,"numberTestErrors":1,"numberTestsCompleted":5,"numberTestsTotal":6}
```
REFUTED — coverage reaches 75%: measured 37.5%. CONFIRMED — custom-profile user insert succeeds
and `System.runAs(customer)` is reached; the first query inside fails:
```text
System.QueryException: No such relation 'Profile' on entity 'User'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.
Class.OwnerPortalFoundationControllerTest.realPlusUserWithoutPermissionOrSiteFailsClosed: line 36, column 1
```
Stop, no retry. Permission/network/endpoint assertions were not reached. Recommend owner approval
of a test-only query correction: query self ContactId/IsActive inside runAs, verify the explicitly
selected profile license before context switch, keep actual user-type/permission/site/endpoint
assertions inside runAs; then one five-component revalidation. This is a proposal, not a verified fix.
No production defect established or changes made. Last all-tests-passing state remains §53.
No deployment/persistent user/profile assignment, data/sharing/configuration changes, publication
or Git release actions; no ng-dev. Exact evidence:
`evidence/P8/FIVE_COMPONENT_VALIDATION/P8_03_FIVE_COMPONENT_VALIDATION_2026-10-26.md`.

## 56. P8-03 authorized test-only query correction — 2026-10-26

Moved license metadata verification to the selected hardened Profile query before external runAs;
external self-User query retains ContactId/IsActive, no Profile traversal. All actual user-type,
permission, Network, policy, endpoint denial and query-count assertions preserved.
Only test code changed; production/profile/permissions unchanged.

CONFIRMED — raw check-only report:
```json
{"id":"0Afaj00000pG0cJCAS","checkOnly":true,"status":"Failed","numberComponentErrors":0,"numberComponentsTotal":5,"numberTestErrors":0,"numberTestsCompleted":6,"numberTestsTotal":6}
```
External test now completes: test-created Plus user/runAs, absent permission, null Network and
early endpoint denial all asserted. REFUTED — protected endpoint paths reached/coverage passes:
```text
OwnerPortalFoundationController - Test coverage of selected Apex Class is 37.5%, at least 75% test coverage is required
```
Lines 14–26/28–34 still uncovered; actual endpoint denies at line 12. No independent test failure
remains. Positive-path coverage needs a reviewed permission/site-context testability plan beyond
this test-only SOQL correction; no bypass or production change made. No deployment, persistent
users/data/assignments, configuration/sharing changes, publication, Git release actions or ng-dev.
Evidence: `evidence/P8/TEST_QUERY_CORRECTION/P8_03_TEST_QUERY_CORRECTION_2026-10-26.md`.

## 57. P8-03 positive-path environmental seam — 2026-10-26

Controller now delegates Salesforce-resolved site facts to private `@TestVisible contextForSite`;
real permission/type/identity/license/site checks and USER_MODE Contact/Account reads remain
mandatory. Test additions create two rolled-back Plus users and attempt rolled-back foundation
permission assignments, own-ID/foreign-read isolation, denied writes and invalid-site denial.
Local checker updated for this authorized test-fixture scope. Profile/permission metadata unchanged.

CONFIRMED — raw single-validation report:
```json
{"id":"0Afaj00000pHga9CAC","checkOnly":true,"status":"Failed","numberComponentErrors":10,"numberComponentsTotal":14,"numberTestErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
```
Manifest remains five definitions; server error counters are raw, not scope expansion. Compiler
errors in OwnerPortalFoundationControllerTest:
```text
Field is not writeable: Network.Name
Field is not writeable: Network.UrlPathPrefix
Field is not writeable: Network.Status
Comparison arguments must be compatible types: System.StatusCode, String
```
Network constructor errors at 54:52, 81:71, 133:67; status comparison at 77:28. Tests did not run;
permission assignment/external positive path unverified, no new coverage. Last passing tests/coverage
remain `0Afaj00000pG0cJCAS`: 6/6, 37.5%. Stop, no retry. Specific owner action: authorize test-only
Network fact construction via JSON.deserialize (no DML) and string DML-status comparison, followed
by one five-component revalidation. Concrete proposed diff and security limitations:
`evidence/P8/POSITIVE_PATH_TESTABILITY/P8_03_POSITIVE_PATH_TESTABILITY_2026-10-26.md`.
Current local changes are not compilation/deployment-ready. No persistent users/assignments,
deployment, shares/data/configuration changes, publication or Git operations; no ng-dev access.

## 58. P8-03 compilation repair / coverage achieved — 2026-10-26

Only test code changed: read-only Network observations via JSON deserialization and string
DML-status comparison. Controller/profile/permission metadata unchanged this turn; private seam
review confirms no public site/identity input or bypass, actual checks and USER_MODE retained.

CONFIRMED — raw report:
```json
{"id":"0Afaj00000pGnaUCAS","checkOnly":true,"status":"Failed","numberComponentErrors":0,"numberComponentsTotal":5,"numberTestErrors":1,"numberTestsCompleted":6,"numberTestsTotal":7}
```
CONFIRMED — coverage 30/37 locations, 81.08108108108108%, no coverage warnings. Uncovered
lines 13–17 and 42–43. REFUTED — all tests pass:
```text
OwnerPortalFoundationControllerTest.permittedCustomersReadOnlyTheirOwnContactInUserMode
System.TypeException: DML operation UPDATE not allowed on Contact
Class.OwnerPortalFoundationControllerTest.permittedCustomersReadOnlyTheirOwnContactInUserMode: line 81, column 1
```
First customer's real permission, own Contact/Account IDs and foreign USER_MODE invisibility
assertions precede the failure; second iteration/later site checks not reached. Stop per escalation
policy. Concrete owner action: authorize additional TypeException catch asserting exact denial
message, keeping DmlException/status and failure-on-write-success assertions; then revalidate.
No production change or Edit grant required. No deployment/persistent records/assignments,
sharing/configuration changes, publication, Git release actions or ng-dev access; CP2 untouched.
Evidence: `evidence/P8/COMPILATION_REPAIR/P8_03_COMPILATION_REPAIR_2026-10-26.md`.

## 59. P8-03 final assertion correction / successful validation — 2026-10-26

Only test code changed: catch TypeException from prohibited Contact update and assert exact
message `DML operation UPDATE not allowed on Contact`. All other assertions retained; no
controller/profile/permission/private-seam change this turn.

CONFIRMED — raw result and coverage arithmetic:
```json
{"id":"0Afaj00000pHlunCAC","checkOnly":true,"status":"Succeeded","numberComponentsTotal":5,"numberComponentErrors":0,"numberTestsCompleted":7,"numberTestsTotal":7,"numberTestErrors":0,"controllerCoverage":{"coveredLocations":33,"totalLocations":37,"percent":89.1891891891892,"uncoveredLines":[15,16,42,43]}}
```
Both real Plus-customer iterations pass own-context, foreign USER_MODE read-denial, denied-write,
invalid-site and actual null-Network endpoint assertions. Private injected site facts do not
constitute live published-site acceptance. Real Network lookup and QueryException handler remain
uncovered; full regression/CP2 runtime checks skipped. Coverage blocker resolved for this package.
No deployment/persistent records/assignments, shares/configuration changes, publication or Git
operations; no ng-dev. Any deployment/live user/site actions require separate authorization.
Evidence: `evidence/P8/FINAL_ASSERTION_CORRECTION/P8_03_FINAL_ASSERTION_CORRECTION_2026-10-26.md`.

## 60. Foundation deployment and authorized local Batch B — 2026-10-26

Owner authorized exact five-component foundation deployment, then local P8-04–09 without a
separate start approval. Source parity established via recorded hash chain/final assertion diff,
profile hash and exact manifest; source snapshot retained. Quick Deploy reused stored payload.

CONFIRMED — raw deployment result (`evidence/P8/FOUNDATION_DEPLOYMENT/quick_deploy.json`):
```json
{"id":"0Afaj00000pGvwECAS","checkOnly":false,"status":"Succeeded","numberComponentsDeployed":5,"numberComponentsTotal":5,"numberComponentErrors":0,"numberTestErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
```
No tests rerun by Quick Deploy; reused `0Afaj00000pHlunCAC` 7/7 and 89.19%. Live Apex matches
local source except Salesforce's omitted final newline. Live IDs: controller `01paj00000c8EO6AAM`,
test `01paj00000c8EO7AAM`, profile `00eaj00000UBi7iAAD`, custom permission `0CPaj000000tVKwGAM`,
permission set `0PSaj00000h8ikiGAA`. Site UnderConstruction, FirstActivationDate null.

**REFUTED — the deployed profile is hardened.** Profile-owned PS `0PSaj00000h8ikhGAA` has:
```json
{"objectGrantCount":35,"fieldGrantCount":495,"editableFieldCount":460,"enabledSystemPermissions":26,"Case":{"PermissionsRead":true,"PermissionsCreate":true,"PermissionsEdit":true,"PermissionsViewAllRecords":false,"PermissionsModifyAllRecords":false}}
```
Source omission did not remove default Plus grants. No profile users/foundation assignments:
```json
{"newProfileAssignedUsers":0,"newFoundationAssignments":0}
```
Do not assign/provision this profile. Profile-only explicit-deny remediation requires owner review
and approval; no speculative live fix made. Prior “hardened” source-only claims are not live proof.

Before/after: existing User/profile-role assignments, permission assignments (32), all existing
object/FLS/system permissions, nine external OWDs, Network/groups/members and 17 business-object
Id/SystemModstamp fingerprints unchanged. Existing SetupEntityAccess has two added System Admin
Apex grants for the new classes: blanket “all permissions unchanged” is REFUTED, not concealed.
No business data/user/share/membership/activation writes. CP2 source untouched; runtime regression
not rerun. Full raw evidence:
`evidence/P8/FOUNDATION_DEPLOYMENT/P8_FOUNDATION_DEPLOYMENT_2026-10-26.md`.

Independent local Batch B implementation began after deployment. No foundation modification or
Batch B deployment. Original acceptance criteria remain intact:

| Block | Actual local status |
|---|---|
| P8-04 | Guest-aware dashboard/card composition; summary/next-appointment widgets and live proof incomplete |
| P8-05 | Ownership-unconfigured guard only; owned list/detail/photo/fallback blocked on approved relationship |
| P8-06 | Contact-only visits, recorded mileage and own linked Cases; positive per-object proof missing |
| P8-07 | Disabled eligibility step/server no-write denial; full wizard/capacity/intake path blocked on ownership |
| P8-08 | Local list/create/status/published comments with USER_MODE and P6 queue/type; isolation test fails |
| P8-09 | Local stored points/tier/transactions read-only; empty/missing access differentiated; positive proof missing |

CONFIRMED — local UI-state tests (`ui_tests.tap`):
```text
# tests 7
# pass 7
# fail 0
```
REFUTED — Batch B server validation passes:
```json
{"id":"0Afaj00000pGPzbCAG","checkOnly":true,"status":"Failed","numberComponentErrors":0,"numberComponentsTotal":9,"numberTestErrors":1,"numberTestsCompleted":2,"numberTestsTotal":3}
```
```text
OwnerPortalBatchBControllerTest.caseFilterSurvivesBroaderRecordVisibility
System.AssertException: Assertion Failed: Expected: 1, Actual: 2
Class.OwnerPortalBatchBControllerTest.caseFilterSurvivesBroaderRecordVisibility: line 72, column 1
OwnerPortalBatchBController - Test coverage of selected Apex Class is 69.027%, at least 75% test coverage is required
```
Initial compile correction run `0Afaj00000pH83rCAC` had 13 errors (catch identifier shadowing
constant and FLS on required fields); directly corrected locally under routine-error authorization.
Current nine components compile. Stop on unexpected isolation result; second returned row is not
identified by current report, so do not assert either a leak or an automation explanation. No test
relaxed or retry after that failure. Owner action: bounded diagnostic assertion output recording
persisted fixture ContactId/OwnerId and returned IDs, then scoped revalidation; retain isolation test.

Candidate future Batch B deployment scope (not ready/approved): two classes
OwnerPortalBatchBController(+Test), PS_Owner_Portal_Batch_B, six LWC bundles ownerPortalHome,
ownerPortalVehicles, ownerPortalHistory, ownerPortalAppointment, ownerPortalCases, ownerPortalLoyalty
(`manifest/p8-batch-b-local.xml`). Profile repair is separate. No Batch B classes/permission set live.
Still need owner-approved ownership relationship; per-object CRUD/FLS/license and sharing review;
safe profile, actual users/membership/login and separate publication/activation approval. Do not
backfill Deliveries or associate the two synthetic pairs to old vehicles/history. No record/share
creation to manufacture positives. No Git staging/commit/push/cleanup or ng-dev access.
Detailed status/evidence: `evidence/P8/BATCH_B/P8_BATCH_B_LOCAL_2026-10-26.md`.

## 61. Bounded profile and Case-isolation remediation — 2026-10-27 UTC

Local/check-only only; no ownership changes. All 35 live profile object rows and 24 retrieved
system-permission names match the standard Plus baseline: prior omission did not deny defaults.
Prepared explicit denies: 33 objects, 483 optional fields, 23 supported system permissions.
Retained Account/Contact Read, Contact.AccountId Read and license-required EnableNotifications
(label Send Outbound Messages). `0Afaj00000pJD93CAG` proved Salesforce forbids disabling that
license floor; profile-only correction then succeeded, `0Afaj00000pJ0QMCA0`, 1 component/0 errors,
0 tests. Eleven nonpermissionable/unqualified/undescribed field rows and two nonserialized email
capability flags are documented limitations, not silently claimed removed.

Case diagnosis (`0Afaj00000pJC3JCAW`): “Foreign case” `500aj00003rJFzPAAW` was owned by external
user A `005aj00000gp430AAA`; Salesforce persisted its Contact as A `003aj00002XoKFeAAN`, not B
`003aj00002XoKFfAAN`. Both returned rows correctly matched the Contact filter. Corrected only
the fixture owner to B and asserted persisted Contacts before the unchanged isolation/cursor/
foreign-comment assertions. No production query, auth logic, shares or permission expansion.
This demonstrates actual cross-customer denial, not broad readability of a foreign Case.

Added real no-Case-Edit persona Case-create/routing test. Explicit Case.Subject/Origin/Priority
FLS in the local Batch B permission set replaces defaults removed by base-profile hardening;
still no Case Edit. Effective-profile test covers all available-schema object CRUD, plus system
denies. Dormant industry rows not present in Schema (ActionPlan REST describe NOT_FOUND) are
not treated as effective grants; feature enablement requires a new permission review.

CONFIRMED — successful combined check-only:
```json
{"id":"0Afaj00000pILVGCA4","checkOnly":true,"status":"Succeeded","numberComponentsTotal":10,"numberComponentErrors":0,"numberTestsCompleted":12,"numberTestsTotal":12,"numberTestErrors":0,"controllerCoverage":{"covered":89,"total":113,"percent":78.76106194690266}}
```
Five Batch B/seven unchanged deployed foundation tests pass. Batch B coverage blocker resolved
for that validated source. Added final all-23-system-denies assertion and corrected description;
current-source validation `0Afaj00000pIz4VCAS` completed Succeeded after local command timeout:
10 components, 0 component/test errors, 12/12 tests, 89/113 locations covered (78.761%). No
duplicate request; `final_completed_report.json` records the successful final status. All 23
supported system-deny assertions pass. This supersedes the earlier pending status.

Live correction not deployed: Case Read/Create/Edit still true; profile assigned users 0.
Exact next independently approvable deployment: profile only (`manifest/p8-02-profile-preparation.xml`).
Combined staged manifest `manifest/p8-batch-b-remediation.xml` has 10 definitions (profile + prior
nine Batch B components), not automatic authorization to deploy incomplete Batch B features.
No ownership/schema implemented. Recommendation only: explicit Contact–Vehicle ownership ledger
with effective dates and owner-approved evidence, never reservation-derived ownership.

No persistent users/assignments/shares, deployment, publication, business-data changes, Git
staging/commit/push or ng-dev. Test rows roll back; controllers/CP2/unrelated dirty work unchanged.
Detailed current evidence:
`evidence/P8/BLOCKER_REMEDIATION/P8_BLOCKER_REMEDIATION_2026-10-27.md`.

## 62. Authorized profile-only security correction deployment — 2026-10-27 UTC

Profile source matches SHA-256 recorded for successful `0Afaj00000pIz4VCAS`:
`2febbf2a8f80aadf4e3517422fc620896633b338766f2f46f459be9a9ab3de87`.
Only `Profile:NG_Owner_Portal_User` (`00eaj00000UBi7iAAD`) selected by
`manifest/p8-02-profile-preparation.xml`; other nine Batch B definitions excluded.

CONFIRMED — raw scoped validation/deployment fields:
```json
{"id":"0Afaj00000pIzVvCAK","checkOnly":true,"status":"Succeeded","numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsTotal":0}
{"id":"0Afaj00000pJTk5CAG","checkOnly":false,"status":"Succeeded","numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestErrors":0,"numberTestsTotal":0}
```
Metadata-only RunRelevantTests revalidation selected zero tests; standard profile-only deployment
used Salesforce-accepted NoTestRun in Developer Edition. No unrelated tests rerun.

CONFIRMED — live profile-owned PS `0PSaj00000h8ikhGAA` comparison:
```json
{"objectDenials":{"intended":33,"effective":33},"fieldDenials":{"intended":483,"effective":483},"systemDenials":{"intended":23,"effective":23},"Case":{"Read":false,"Create":false,"Edit":false},"EnableNotifications":true,"PermissionsEmailAdministration":true,"PermissionsEmailTemplateManagement":true}
```
Only Account/Contact Read object grants remain; all writes/View All/Modify All false. Read-only
Contact.AccountId retained. Eleven documented unsupported/unqualified FLS rows remain, inert
without parent object rights. Exact rows in effective_comparison.json. No unwanted intended-deny
violation, but two email capabilities remain unresolved: **full security acceptance not granted**.
Stop broader changes, keep unassigned. Owner action: disposition of those exact email capabilities
via bounded read-only Setup/platform investigation or explicit risk/license-floor acceptance.

Profile users 0, assignments 32 unchanged, Network UnderConstruction/never activated, profile
membership group 1/admin members 3 unchanged. Batch B classes/permission set absent live. No
external-user creation/assignment, sharing/publication/business-data changes, Git release actions
or ng-dev. No CP2 changes/runtime rerun or full audit. Evidence:
`evidence/P8/PROFILE_SECURITY_DEPLOYMENT/P8_PROFILE_SECURITY_DEPLOYMENT_2026-10-27.md`.

## 63. Batch B independent local completion and email disposition — 2026-10-27 UTC

No prior deployment/correction repeated. Added own-data dashboard summary/widgets, chronological
loaded-visit mileage table, Case refresh/empty state and stale-comment protection; added positive
history/ledger/comment security tests. Foundation/CP2 untouched. Previous successful
`0Afaj00000pIz4VCAS` (12/12, 78.761%) preserved, not rerun.

CONFIRMED — final changed implementation check-only:
```json
{"id":"0Afaj00000pIGp0CAG","checkOnly":true,"status":"Succeeded","numberComponentsTotal":10,"numberComponentErrors":0,"numberTestsCompleted":9,"numberTestsTotal":9,"numberTestErrors":0,"controllerCoverage":{"covered":117,"total":135,"percent":86.66666666666667}}
```
Only changed Batch B tests run (9 methods), not unchanged foundation tests. UI-state tests 12/12;
six LWCs compile server-side, no DOM/browser/real-persona site proof.

| Block | Exact local closeout status (not operational acceptance) |
|---|---|
| P8-04 | Implemented/scoped-tested: visible open Cases, actual earliest own appointment, stored points/tier, ownership warning, partial-access states, guest guard and refresh |
| P8-05 | Ownership-blocked: safe explicit empty/disabled state; no owned detail/photo/fallback claim or inventory grant |
| P8-06 | Implemented/scoped-tested: own visits, linked own Cases, dated mileage, cursor pagination, readable-foreign-visit exclusion and foreign linked-ID masking |
| P8-07 | Ownership-blocked: no-write server gate and disabled first step; required Vehicle relationship prevents safe creation; no replacement capacity engine |
| P8-08 | Implemented/scoped-tested: list/create/status/refresh, queue/type routing, public comment create/read without Case Edit, private-note hiding and foreign parent denial |
| P8-09 | Implemented/scoped-tested: stored read-only points/tier/ledger, 20+2 pagination, readable foreign member/ledger exclusion, ambiguity denial and no recalculation |

Email investigation corrected the earlier unsupported inference that omitted retrieval entries
cannot be changed. One profile-only generated probe `0Afaj00000pIZtCCAW` Succeeded with:
```xml
<userPermissions><enabled>false</enabled><name>EmailAdministration</name></userPermissions>
<userPermissions><enabled>false</enabled><name>EmailTemplateManagement</name></userPermissions>
```
Only these two entries added to local profile; removing them byte-for-byte reproduces deployed
correction. Combined final tests assert both effective flags false and real Plus EmailTemplate/
OrgWideEmailAddress Create/Edit false. All completed 33/483/23 denies and mandatory notification
floor unchanged. No actual profile deploy/assignment or setting change.

REFUTED — live true flags are harmless. Separate one-test diagnostic `0Afaj00000pJaaHCAS` fails:
```text
OwnerPortalEmailCapabilityTest.currentBackendFlagsDoNotGrantTemplateOrOrgEmailWrites
System.AssertException: Assertion Failed: Expected: false, Actual: true
Class.OwnerPortalEmailCapabilityTest.currentBackendFlagsDoNotGrantTemplateOrOrgEmailWrites: line 33, column 1
```
Line 33 is actual Plus `EmailTemplate.isCreateable()`: true with no added permission sets. No
template DML/email delivery performed; later admin-surface assertions not reached in that probe.
Keep the failed harmlessness diagnostic excluded from deployment; no retry or relaxed assertion.
Exact remedy is the now-validated two-entry profile deny, not a broader license/settings change.

Exact Batch B scope remains nine definitions in `manifest/p8-batch-b-local.xml` (controller/test,
PS_Owner_Portal_Batch_B, six ownerPortal* LWCs). Verified combined candidate is those nine plus
the two-entry profile change: `manifest/p8-batch-b-remediation.xml`, 10 components. Diagnostic
class/manifest excluded. Approval options: profile-only correction first then nine-component
revalidation, or exact combined ten-component candidate. Do not deploy a subset via ten-component
Quick Deploy. No deployment approved/performed this turn.

Ownership recommendation unchanged: explicit Contact–Vehicle ledger with effective dates and
reviewed evidence. No schema, historical associations, live records, users, assignments, shares,
publication, Git operations or ng-dev access. Operational acceptance still needs corrected profile,
reviewed user/membership/record visibility, actual live login/feature UAT and separate publication
authorization. No Batch C begun. Current evidence:
`evidence/P8/BATCH_B_COMPLETION/P8_BATCH_B_COMPLETION_2026-10-27.md`.

## 64. Exact Batch B deployment and local Batch C — 2026-10-27 UTC

Owner authorized exact validated ten-component Batch B deployment, then local P8-10/11. All
submitted source-file hashes match `0Afaj00000pIGp0CAG`; frozen source and manifest prove scope.
CONFIRMED — raw Quick Deploy result:
```json
{"id":"0Afaj00000pIP10CAG","checkOnly":false,"status":"Succeeded","numberComponentsDeployed":10,"numberComponentsTotal":10,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
```
Stored combined payload used in one transaction, no subset or broader deployment. Quick Deploy
reused 9/9 Apex tests / 86.667% coverage; zero tests rerun during deployment. Prior 12/12 UI-state
receipt remains a local result, not browser/customer UAT.

CONFIRMED — effective live readback:
```json
{"objectDenials":{"intended":33,"effective":33},"fieldDenials":{"intended":483,"effective":483},"systemDenials":{"intended":23,"effective":23},"PermissionsEmailAdministration":false,"PermissionsEmailTemplateManagement":false,"PermissionsEnableNotifications":true,"CaseGrantRow":null}
```
Base profile Case Read/Create/Edit off; only Account/Contact Read object grants. All ten components
retrieved successfully; Apex bodies and all LWC JS/HTML match validated snapshot (newline-only
normalization). New Batch B permission set is unassigned. Users/profile-role fields, 32 permission
assignments, Network/group/member rows, seven available share tables and 17 business-object
Id/SystemModstamp fingerprints match before/after exactly. No implicit claim of a fresh runtime
CP2/full regression. Network remains UnderConstruction, FirstActivationDate null.
Evidence: `evidence/P8/BATCH_B_DEPLOYMENT/P8_BATCH_B_DEPLOYMENT_2026-10-27.md`.

Batch C began only after deployment outcome and readback were understood. Local changes limited
to six LWC bundles and tests/docs: responsive single-column/grid layout; owned Northgate text
wordmark/proposed palette; native mobile lists/table instead of datatables; skip/section navigation;
visible focus, validated input focus and announced busy/error/success states; native Case selection
and comment-panel semantics. No Apex/profile/permission/security/site/ownership change in Batch C.

CONFIRMED — targeted local tests:
```text
# tests 19
# pass 19
# fail 0
```
State/focus invocation/source/contrast arithmetic only; no DOM/browser/screen-reader claim.
CONFIRMED — six-bundle metadata check-only:
```json
{"id":"0Afaj00000pJzGvCAK","checkOnly":true,"status":"Succeeded","numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
```
RunRelevantTests selected zero Apex tests; only LWC changed. No new Apex coverage claimed.

P8-10 local implementation delivered/validated, **not accepted**: real viewport screenshots,
physical keyboard/focus, rendered contrast/zoom/AT and final brand review remain unexecuted.
P8-11 persona/demo/UAT/seam preparation delivered, **actual customer UAT not run/passed**.
`evidence/DEMO_SCRIPTS/portal.md` opens with Activate persona, rejects internal/admin substitution;
`evidence/P8/uat/PORTAL_UAT_MATRIX.md` leaves every actual-persona row BLOCKED. Screenshot
register has expected filenames only, no fabricated images. Architecture note distinguishes real
native/custom/blocked/test seams. Full exception/approval index:
`docs/planning/P8_BATCH_C_ACCEPTANCE_EXCEPTIONS.md`.

Exact next metadata candidate: six LightningComponentBundles in `manifest/p8-batch-c-local.xml`:
ownerPortalHome, ownerPortalVehicles, ownerPortalHistory, ownerPortalAppointment, ownerPortalCases,
ownerPortalLoyalty. Not deployed. Local UI now intentionally differs from deployed Batch B; use
the frozen release snapshot for parity, not a broad replay of the Batch B manifest.

Separate next decisions: Batch C six-bundle deployment; site page placement; approved two Plus
identities/mailboxes/assignments/membership/narrow record visibility; verified Contact–Vehicle
model and evidence before owned details/photos or appointment creation; controlled publication
and actual-customer UAT/write scope; owner acceptance/exception disposition. No user/share/history
creation, old Delivery repair or invented ownership. Live endpoint requires Live Network, so Builder
preview or UnderConstruction tests cannot be relabelled as successful real positive login UAT.
No Batch C deployment, role/OWD/business-data changes, Git operations or ng-dev access. CP2 and
existing functionality preserved; M4 not declared passed. Current Batch C evidence:
`evidence/P8/BATCH_C/P8_BATCH_C_LOCAL_2026-10-27.md`.

## 65. Batch C deployed; site-export preservation exception — 2026-10-27

CONFIRMED — raw `evidence/P8/BATCH_C_DEPLOYMENT/deploy.json` fields:
```json
{"id":"0Afaj00000pOUsQCAW","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":6,"numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsTotal":0}
```
Exact six bundles in `manifest/p8-batch-c-local.xml`; all 25 submitted hashes unchanged. Quick
Deploy was ineligible (`INVALID_ID_FIELD: Source validate did not run tests in the org`), so used
authorized standard scoped fallback with NoTestRun. No successful tests rerun. Retrieved all six;
24 files match validated source with newline/XML whitespace normalization only.

CONFIRMED — `verification.json` per-comparison results: user, permission, assignment, membership,
seven available sharing tables and seventeen business-object fingerprints equal. All 65 retrieved
page/application/navigation/Network/CustomSite/package XML files byte-identical. Network raw row:
```json
{"Id":"0DBaj000006bf3xGAA","Status":"UnderConstruction","FirstActivationDate":null}
```
REFUTED — complete site export byte parity. Sole difference:
```text
siteDotComSites/Northgate_Owner_Portal1.site
before 2159b67ca78d394ef22b467f0267b2c225b4508b9afca45f8bff230030f9cffb
after  751572a93972fe151f52a732270b0d49f3b1a12ecbdfb0a3347ee188800a98c6
```
Cause uncertain; no claim of harmless serialization or actual configuration change. Affected
diagnosis stopped; no corrective changes. Owner: inspect Builder pages/navigation read-only
(no Save/Publish), review Setup Audit Trail around this deployment, provide findings/authorization
for bounded export comparison. Last verified state is successful six-only deployment/source parity
and unchanged bounded XML/record snapshots; full site-content preservation unresolved.

All eleven development/acceptance statuses:

| Item | Delivery | Acceptance outstanding |
|---|---|---|
| P8-01 | Site scaffold deployed | Placement/publication/actual login |
| P8-02 | Hardened profile/access metadata deployed/tested | Actual customer licensing/minimum grants |
| P8-03 | Identity/security foundation deployed/tested | Actual-persona membership/sharing/isolation |
| P8-04 | Dashboard deployed | Customer/rendered acceptance |
| P8-05 | Safe disabled vehicle state deployed | Owned details/photos not implemented; ownership required |
| P8-06 | Contact-filtered history/mileage deployed | Real customer/history evidence |
| P8-07 | Safe disabled appointment state deployed | Creation incomplete; ownership/Vehicle/capacity-intake UAT |
| P8-08 | Cases/public comments deployed/tested | Real sharing/routing and approved write-UAT |
| P8-09 | Read-only loyalty deployed/tested | Actual member/ledger visibility |
| P8-10 | Responsive/accessibility polish deployed | Browser/screenshots/keyboard/AT/zoom/contrast/brand acceptance |
| P8-11 | Demo/UAT matrix/register/seam/exception docs delivered | Actual two-customer UAT and M4 not passed |

Local tests remain prior 19/19 evidence, not actual-persona/browser proof. No customer provisioning,
assignments, membership, sharing, ownership, business-data, page placement, publication or Git
release action performed. CP2 not deployed/edited; record fingerprints equal, runtime regression
not rerun. No ng-dev access. No full Phase 8 acceptance.

Recommended separately approved sequence: resolve binary preservation exception → approve
ownership/evidence and remaining vehicle/appointment implementation → approve two Plus identities,
minimum assignments/membership/narrow sharing → approve page placement/brand review → approve
controlled publication and actual A/B security/write/accessibility UAT → owner acceptance.

Git before: raw `git_before_summary.json`: 64 modified, 8 deleted, 3683 untracked, zero staged.
Final status: `git_after.txt` and `git_after_summary.json`; evidence additions increase untracked
count. Pre-existing dirty tree/deletions preserved; no staging/commit/push/cleanup.
Full evidence/status: `evidence/P8/BATCH_C_DEPLOYMENT/P8_BATCH_C_DEPLOYMENT_2026-10-27.md`.

## 66. Operational completion preparation — 2026-10-27

No repeated deployment, successful test rerun, full-project audit or SiteDotCom re-investigation.
Foundation `0Afaj00000pGvwECAS`, B `0Afaj00000pIP10CAG`, C `0Afaj00000pOUsQCAW` remain
deployed. Prior preservation findings: `evidence/P8/BATCH_C_PRESERVATION_CHECK/FINDINGS.md`:
no meaningful regression demonstrated; exact export mechanism unestablished. Do not relabel the
old byte comparison as a current publication blocker or claim decoded Builder-content parity.

CONFIRMED — selected raw outputs from `evidence/P8/OPERATIONAL_PREPARATION/verification.json`:
```json
{"orgId":"00Daj00001Ae3iWEAR","guest":{"objectGrants":0,"apexClassGrants":0,"enabledSystemPermissions":[]},"hardenedProfile":{"denials":{"objects":33,"fields":483,"system":23},"violations":{"objects":[],"fields":[],"system":[]},"enabledSystemPermissions":["PermissionsEnableNotifications"],"caseGrantRow":null,"users":0},"liveApexMatchesLocal":{"OwnerPortalBatchBController":true,"OwnerPortalFoundationController":true},"localBatchCStillMatchesValidatedHashes":true,"lwcCount":6,"fixtureDeliveryIds":[],"fixtureRows":{"visits":0,"cases":0,"loyalty":0},"testsRerun":false,"forceAppChanges":false}
```
Guest sole assignment is profile-owned set; zero custom permission/Apex classes or object grants.
Both email-management flags false (all system flags except mandatory EnableNotifications false).
Foundation and Batch B definitions remain unassigned to customers. Batch B includes Case Create;
do not mistake its historical LOCAL label or no-Case-Edit design for read-only capability.

CONFIRMED — live Network selected fields:
```json
{"Id":"0DBaj000006bf3xGAA","Status":"UnderConstruction","FirstActivationDate":null,"SelfRegProfileId":null,"OptionsSelfRegistrationEnabled":false,"OptionsAllowInternalUserLogin":false,"OptionsGuestMemberVisibility":false,"OptionsInvitationsEnabled":false}
```
Network/CustomSite/NavigationMenu retrieved read-only and equal saved after-state XML. Only
ownerPortalHome is Builder-exposed; five nested children are not standalone page components.
Plus 5 total/0 used. Exact A/B Contacts/Accounts and existing owner 005aj00000gE0b3AAC/VP Sales
role verified; no owner/role change needed. No A/B Delivery, Visit, Case or Member positive rows.

REFUTED — live Builder/anonymous endpoint/actual customer acceptance completed this execution.
Browser MCP exact error: `No connection to browser extension.` Anonymous GET stopped with
`[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1082)`.
No TLS bypass/retry loop; not diagnosed a Salesforce certificate defect. Owner action: connect
the ng-demo Builder browser for read-only page/login/nav/theme/logout review and verify public
routes with normal browser TLS validation. No Save/Publish. Full errors, last verified state and
change scope: `evidence/P8/OPERATIONAL_PREPARATION/ACCESS_LIMITATIONS.md`.

Prepared one concrete ledger design (not code/schema deployment): Contact_Vehicle_Relationship__c,
reviewed evidence, effective UTC intervals/revocation, distinct Ownership and Service_Authorization,
strict Contact boundaries, immutable transfer history, no Delivery backfill. Native shares have
no proven automatic time expiry here: scheduled cleanup alone cannot satisfy direct-API isolation;
mandatory fail-closed revocation proof before Vehicle permissions/grants. Appointment retains
required Vehicle and existing Toronto capacity locks/intake. Native Case/comment/appointment
write-path proof is required before write-capable assignment; portal guards alone are insufficient.
No live exploit claimed and no unapproved security/trigger architecture implementation performed.

Current deliverables:
- `docs/architecture/P8_CONTACT_VEHICLE_OWNERSHIP.md`: exact proposed fields/permissions/
  Apex/LWC/tests/migration and mandatory native revocation proof.
- `docs/planning/P8_PORTAL_PLACEMENT_PLAN.md`: one Home component, six logical sections,
  native login/logout, minimal branding; no guessed routes/Builder metadata.
- `docs/planning/P8_CUSTOMER_ACCESS_EXECUTION_PLAN.md`: supported A/B mailbox/user/profile/
  assignment/membership/per-record native grants and lifecycle procedure.
- `evidence/P8/uat/OPERATIONAL_CUSTOMER_UAT.md`: executable manual actual-customer script,
  own/foreign/native/API tampering/capacity/comments/loyalty/expiry/logout/mobile/AT tests.
- `docs/planning/P8_OPERATIONAL_COMPLETION_REGISTER.md`: all eleven items, deployment/test
  evidence, limitations, remaining work and one consolidated category-specific approval packet.
- `docs/planning/NORTHGATE_COMPREHENSIVE_TESTING_HANDOFF.md`: subsequent Phase 1–8 inventory,
  workflow/persona/regression/defect/UX/colour-photo/demo stage; not started now.
- `scripts/tests/capture_p8_operational_readiness.py`: executed read-only evidence capture.

All-eleven status: P8-01–04/06/08–10 implemented/deployed with operational acceptance pending;
P8-05/07 only safe disabled states, ownership/details/photo/booking implementation incomplete;
P8-11 planning/demo/UAT/seam preparation delivered, real-persona UAT and M4 not passed.
No app source changed, so no new tests/check-only justified. Prior 7/7, 9/9 (86.667%), local 19/19
and six-bundle `0Afaj00000pJzGvCAK` evidence reused, not relabelled fresh verification.

Consolidated separate decisions: G0 browser connection/read-only inventory; G1 approve ledger/
security design and bounded local implementation/check-only; G2 review actual frozen new package
before deployment (not ready yet); G3 exact two identities/mailboxes plus distinct assignment/
membership authority; G4 signed ownership/service/positive-data and narrow sharing row manifest;
G5 Home/native-menu Builder Save/brand review; G6 controlled publication plus signed write-UAT/
containment scope; G7 owner acceptance. No single category implies another. Recommended order
is G0 → G1 proof → G2 → G3/G4/G5 → G6 → G7. Ownership evidence/vehicle IDs and test mailboxes
must be owner-supplied/reviewed, never inferred from reservation/Account/old Delivery records.

No Salesforce writes or force-app/manifest edits; no staging/commit/push/cleanup or ng-dev access.
Read-only dirty Git snapshot: `evidence/P8/OPERATIONAL_PREPARATION/git_status*.{txt,json}`;
pre-existing modifications/deletions/untracked work preserved. Full Phase 1–7 exceptions, CP2,
Territory Planning/activation/assignment boundaries and all existing functionality retained. Vehicle
Studio stays post-Phase-8, not implemented. No Phase 8 acceptance or demo-readiness claim.

CONFIRMED — final raw `evidence/P8/OPERATIONAL_PREPARATION/git_final_summary.json` fields:
```json
{"porcelainCounts":{" M":64," D":8,"??":4081},"stagedEntries":0,"priorSnapshotEntriesPreserved":true}
```
`preparation_checks.json` records all 16 prepared/updated deliverable files, eleven-item register,
§66 and Activate-persona script presence, unchanged validated app hashes, and no new test/deploy run.

## 67. Local ownership ledger attempt; validation/security gates — 2026-10-27

Owner authorized local approved-ledger/P8-05/P8-07 implementation and targeted check-only, not
deployment, live data/ownership/grants/assignment/sharing/Builder/publication or Git release work.
Prepared only independent ledger metadata/services/reviewer permission/trigger/test source;
existing controller/LWC/ServiceVisitTrigger/CP2/Service/Loyalty code untouched. Exact 27-file hashes:
`evidence/P8/OWNERSHIP_IMPLEMENTATION/submitted_source_hashes.json`.
Candidate scope: `manifest/p8-ownership-ledger-local.xml`: one new CustomObject (13 fields and
sharing reason), Vehicle sharing reason only, one custom permission, one internal reviewer set,
three Apex classes (service/guard/test), one new-object trigger. No external Vehicle Read grants.

Ownership and Service_Authorization are distinct reviewed rows; reservation/Account/history never
creates entitlement. Draft source includes Pending-first/server review stamps, immutable evidence,
half-open interval conflicts under parent lock, explicit revocation/application-only share removal,
associated consent revocation and delete denial. These are NOT runtime-validated functionality.

CONFIRMED — raw local convert result status=0, `evidence/P8/OWNERSHIP_IMPLEMENTATION/convert.json`.
REFUTED — scoped check-only passes; raw `validate_report.json`:
```json
{"id":"0Afaj00000pOJ7PCAW","status":"Failed","checkOnly":true,"numberComponentsTotal":29,"numberComponentsDeployed":15,"numberComponentErrors":14,"numberTestsTotal":0,"numberTestsCompleted":0,"numberTestErrors":0}
```
No actual deployment or partial release; check-only progress counters are not deployed components.
No Apex coverage/test pass, no LWC changes/tests. Exact root errors:
```text
Contact_Vehicle_Relationship__c.Verified_By__c: Cannot add a lookup relationship child with cascade or restrict options to User
objects/Contact_Vehicle_Relationship__c.object: element fullName missing for a child of type SharingReason
objects/Vehicle__c.object: element fullName missing for a child of type SharingReason
```
Dependent Verified_By field/compiler/test/trigger/permission errors preserved verbatim in raw receipt.
Affected source work stopped per AGENTS.md after failed validation; no repair/retry loop. Owner
action: approve bounded correction (User lookup SetNull, explicit fullName on both sharing reasons)
and scoped revalidation, or make those three edits. No test relaxation or field rename.

Native temporal access still needs a security decision: live Vehicle__Share describe exposes
Id/ParentId/UserOrGroupId/AccessLevel/RowCause/modification/deletion fields, no expiry field. No
supported fail-closed automatic expiry mechanism established under existing USER_MODE/native-read
design. No claim that all Salesforce solutions are impossible, and no rearchitecture authorized.
Scheduled cleanup/portal predicate cannot be called native API revocation proof. External grants,
owned-detail/photo and appointment policy/wizard/write guards therefore not implemented/enabled.
Hierarchy-grant disabling also has no supported source setting established; Private OWD alone is
not that proof. No customer grant until these baseline gates resolved and tested.

Last verified state is prior deployed A/B/C plus this task's XML parse/source-conversion success;
new Salesforce compilation failed before tests. P8-05/P8-07 remain incomplete/fail-closed, all
actual-persona/accessibility/publication prerequisites and earlier phase exceptions retained.
No deployment/backfill/external user/assignment/record share/OWD/site save/publish, no staging/
commit/push/cleanup or ng-dev access. Current evidence and specific next actions:
`evidence/P8/OWNERSHIP_IMPLEMENTATION/OWNERSHIP_LOCAL_RESULT.md`.

## 68. Metadata fixed; test-access blocker and local reconciliation — 2026-10-27

Owner authorized metadata repairs, local expiry/revocation implementation, remaining features and
focused check-only; no deployment, live data/grants/jobs/site changes or Git release operations.
Changed Verified_By__c deleteConstraint to SetNull and added fullName=Portal_Entitlement__c in
both sharing reasons. Actual componentSuccesses prove those exact corrections accepted; no
previous missing-field/trigger/permission compiler errors remain in this candidate.

REFUTED — validation passes; raw `evidence/P8/OWNERSHIP_COMPLETION/ledger_report.json`:
```json
{"id":"0Afaj00000pPMPlCAO","status":"Failed","checkOnly":true,"numberComponentErrors":0,"numberTestsTotal":6,"numberTestsCompleted":1,"numberTestErrors":5}
```
Exact shared error and location:
```text
System.DmlException: Operation failed due to fields being inaccessible on Sobject Vehicle__c, check errors on Exception or Result!
Class.OwnerPortalOwnershipTest.fixture: line 26, column 1
```
Five affected methods: bulkPendingDoesNotGrantOwnershipAndUnapprovedInternalCannotReview,
evidenceAndServerStampsAreRequired, explicitRevocationRemovesOnlyApplicationSharesAndConsent,
sameAccountAndReservationCannotSubstituteOwnership, terminationRequiresReasonAndNeverExtendsVerifiedInterval.
All fail at fixture Vehicle insert; exact fields/trigger path not diagnosed or worked around.
Coverage warning: ownership trigger 0%, service 0%, guard 8.411%. Sole successful test is half-open
interval helper, not share lifecycle/native access proof. No fixture/permission patch or retry
after failure under AGENTS.md. Owner command to review:
`sf project deploy report --target-org ng-demo --job-id 0Afaj00000pPMPlCAO --json`, then bounded
fixture-access diagnosis/correction approval, retaining real personas and security assertions.

Independent local preparation completed after affected test work stopped: new
OwnerPortalShareReconciler (Batchable/Schedulable) and its two drafted test methods; no grant writer,
ownership DML, job activation, public endpoint or self-schedule. Prunes only Portal_Entitlement__c
Vehicle/ledger shares for missing/expired/revoked/future/conflicting/unverified ownership, wrong
Contact or inactive/non-Plus recipients. Servicing-only evidence does not authorize Vehicle access;
unrelated Manual/Owner/other-reason shares retained. Parent Vehicle lock and all-or-none scope
deletes; batch errors require operator monitoring. New classes NOT Salesforce-compiled/tested.

Custom sharing reasons establish provenance, not expiry; managed-sharing recalculation is not a
clock event. Source offers remove-only periodic maintenance. Proposed standard hourly cron
`0 0 * * * ?` after separate deployment/activation approval has nominal latency up to an hour
PLUS async delay, with no demonstrated hard deadline. No registration/schedule/manual run done.
Explicit termination's intended synchronous deletion is still unproven due failed fixture tests.
Cannot simultaneously remove unrelated-source access and preserve those grants; audit their
entitlements separately. Strict immediate native API expiry is NOT satisfied by eventual pruning.
Do not enable external Vehicle grants simply because a job can run; required timing/security
policy and lifecycle/native tests remain gates. No new external object permission extension.

P8-05/P8-07 feature paths remain unchanged/incomplete/fail-closed, not claimed delivered. No new
LWC test or affected capacity/intake regression run justified while prerequisites are blocked.
CP2, existing booking/intake/service/loyalty/reservation code and prior deployed bundles untouched.

CONFIRMED — raw `closeout.json` fields:
```json
{"candidateFiles":30,"localXmlAndConversion":"Succeeded","existingBatchCSourceUnchanged":true,"reconcilerValidatedInSalesforce":false,"p805Completed":false,"p807Completed":false,"jobsActivated":0,"actualDeployment":false}
```
Combined CANDIDATE ONLY: `manifest/p8-ownership-reconciliation-local.xml` (original ledger
scope plus new reconciler/test); exact files/hashes `candidate_source_hashes.json`. Earlier
ledger check-only does NOT validate these later classes. No deploy-ready/Quick Deploy approval.
Full results/errors/activation steps: `evidence/P8/OWNERSHIP_COMPLETION/RESULT.md`.
No live ownership/data/users/permission assignments/shares/OWD/job activation/Builder/publication,
no staging/commit/push/cleanup or ng-dev access. Phase 1–7 exceptions and M4 nonacceptance retained.

## 69. Ownership recovery validated; native access decision retained — 2026-10-27

Bounded diagnosis/corrections/check-only only; no full audit or live configuration/data changes.
CONFIRMED — diagnostic `0Afaj00000pPPkDCAW` selected raw output:
```text
profile=00eaj00000T6Z8rAAF type=Standard objectCreate=true fieldCreate={"Reserved_By__c":false,"VIN__c":false,"Vehicle_Model__c":true} dmlFields=["VIN__c","Reserved_By__c"]
```
Test reviewer inherited only the runner's Profile, NOT its permission sets. API 68 follows API
67+ USER_MODE default; even Administrator profile naming does not bypass missing field FLS.
Measured error fields, actual actor assignments, existing internal no-bypass inventory FLS and
live/local Vehicle automation parity captured in `evidence/P8/OWNERSHIP_RECOVERY/`.

Fixture-only correction: separate rolled-back internal builder with existing PS_Demo_Admin_No_Bypass
creates inventory/reservation data and reads reservation snapshots; reviewer keeps narrow ledger
set and customer assertions remain actual Plus runAs. No external rights or internal profile/set
metadata broadened. Added missing reconciler test metadata and corrected a test nickname length.
Production integrity/managed-share infrastructure now explicitly uses system-mode parent locks,
all-ledger conflict reads and app-reason-only maintenance behind the existing internal custom-
permission gate; without-sharing alone does not select database mode at API 68. Reviewer public
verify/revoke DML stays USER_MODE. Source Delivery queries run only for supplied IDs and stay
USER_MODE (no evidence FLS bypass). No generic customer/system-mode data endpoint added.

CONFIRMED — final raw check-only `accepted_validate.json`:
```json
{"id":"0Afaj00000pNyKhCAK","status":"Succeeded","checkOnly":true,"numberComponentErrors":0,"numberComponentsTotal":24,"numberTestsTotal":11,"numberTestsCompleted":11,"numberTestErrors":0}
```
CONFIRMED — raw coverage locations/derived percentages in `verification.json`:
```json
[{"name":"ContactVehicleRelationshipTrigger","covered":5,"locations":5,"percent":100.0},{"name":"OwnerPortalShareReconciler","covered":57,"locations":57,"percent":100.0},{"name":"OwnerPortalOwnershipGuard","covered":100,"locations":108,"percent":92.593},{"name":"OwnerPortalOwnershipService","covered":18,"locations":18,"percent":100.0}]
```
Focused suite verifies ledger evidence/stamps/immutability/delete/bulk/interval/conflict rules,
independent service consent, immediate termination and app-only revocation, unchanged reservation
and Manual grants, clock-expiry pruning with no ledger edit, stale grant batch recovery, service-
only/missing owner/group pruning and known foreign Vehicle native denial under actual same-
Account Plus A with a misaddressed share present. Native denial relies on no Vehicle object right,
not a demonstrated positive owned-Vehicle customer feature. No LWC edits/tests or browser UAT.

Ledger/reconciler candidate is now validated; prior metadata/fixture errors are historical, not
outstanding gates. Frozen candidate: `manifest/p8-ownership-reconciliation-local.xml`, 24 components,
31 source/manifest files in `submitted_source_hashes.json`. Separate deployment approval still
required. No customer rights/share creation/job or managed-recalculation activation implied.

P8-05/P8-07 remain incomplete and fail-closed. Managed share reasons/recalculation are provenance/
maintenance, not time-conditional native permissions. A scheduled batch has no hard clock deadline;
preserving unrelated grants cannot subtract access those sources authorize. Exact native expiry
is therefore NOT guaranteed if Vehicle rights are enabled under the current share model.

One concrete secure alternative is specified in
`docs/architecture/P8_NATIVE_VEHICLE_ACCESS_DECISION.md`: keep external Vehicle/ledger CRUD and
native Visit Create disabled, add a minimal privileged broker behind real Foundation identity,
check current exact-Contact ownership/conflicts/expiry and separate service consent on every
request, expose safe photo/detail DTOs only, and perform guarded/idempotent booking through the
existing capacity/intake trigger. This is an explicit amendment to USER_MODE Vehicle reads/write
architecture, NOT implemented without that security decision. No relaxed expiry/no-FLS workaround.

No metadata deployment, persistent record/ownership/user/permission/sharing/OWD/job/site change,
no staging/commit/push/cleanup, no ng-dev access; existing Batch C source hashes unchanged. All
earlier phase exceptions, CP2 and M4 nonacceptance retained. Full exact diagnosis, intermediate
receipts, final scope, tests/limits and next decision: `evidence/P8/OWNERSHIP_RECOVERY/RESULT.md`.

## 70. P8-05/P8-07 approved broker implemented/validated locally — 2026-10-27

Owner approved P8_NATIVE_VEHICLE_ACCESS_DECISION.md's server-mediated/no-native-CRUD model.
Implementation and tests only; no deployment, persistent data/users/grants/jobs/site change or
Git operations. Exact target organization verified in `evidence/P8/BROKER_COMPLETION/identity.json`.
The previous native-access architecture decision is resolved, not an additional approval request.

CONFIRMED — final raw `validate.json`:
```json
{"id":"0Afaj00000pPiV7CAK","status":"Succeeded","checkOnly":true,"numberComponentsTotal":34,"numberComponentErrors":0,"numberTestsTotal":43,"numberTestsCompleted":43,"numberTestErrors":0}
```
CONFIRMED — raw `ui_tests.tap`:
```text
# tests 25
# pass 25
# fail 0
```
CONFIRMED — coverage locations/derived percentages in `verification.json`:
```json
[{"name":"OwnerPortalVehicleBroker","covered":150,"locations":153,"percent":98.039},{"name":"ServiceIntakeCaseService","covered":33,"locations":33,"percent":100.0},{"name":"OwnerPortalBatchBController","covered":123,"locations":140,"percent":87.857},{"name":"ContactVehicleRelationshipTrigger","covered":5,"locations":5,"percent":100.0},{"name":"ServiceVisitCapacityGuard","covered":87,"locations":89,"percent":97.753},{"name":"OwnerPortalOwnershipService","covered":18,"locations":18,"percent":100.0},{"name":"OwnerPortalShareReconciler","covered":57,"locations":57,"percent":100.0},{"name":"OwnerPortalOwnershipGuard","covered":100,"locations":108,"percent":92.593}]
```
Selected tests: new broker; changed facade, authoritative capacity/intake; and undeployed ledger/
reconciler prerequisites included in the same package. No unrelated/full-project/CP2 rerun.
All 31 prior validated ledger hash entries remain unchanged (`ledger_preservation.json`).

P8-05: bounded/paged own Vehicle DTOs, identity/model/year/colour/condition, existing validated
static-resource Photo__c-derived image paths, alt/fallback and native detail selection. No raw
formula HTML/SObjects, VIN, financial/reservation/customer/evidence fields. Native Vehicle/Model/
ledger object access stays denied. Read failures clear state; empty/unverified/expired/revoked/
ambiguous/foreign rows do not display. Every public read resolves real Foundation Live-site caller.

P8-07: native LWC vehicle → server service catalog/date → review → requested Visit receipt.
Both current ownership and independent service consent rechecked; IDs/types/catalog/future time
validated, no Contact/Account/owner/status/Case selectors. Vehicle lock serializes with revocation;
authorization rechecked before and after insertion, with rollback on crossing expiry. Broker-only
system write derives own Contact/caller Owner/Requested status, no native Visit Create grant.
No new Flow/process: unchanged ServiceVisitTrigger calls existing Toronto capacity guard and
service-intake queue/Case/link service. Only required changes there are explicit SYSTEM_MODE
capacity count and intake Group/Contact queries, not a competing scheduler/route/capacity engine.
Broker rejects writes while existing service automation bypass is enabled.

Durable idempotency: new optional Visit Portal_Request_Key__c (unique SHA-256 of Contact+UUID)
and Portal_Request_Fingerprint__c bind canonical Vehicle/roof/second-precision start/service.
Same key/payload returns own receipt; altered payload or equivalent active request under a new
key denies. Unique-index race recovery only returns an exact authorized matching receipt. Client
retains token on transient error, resets on edited data, prevents concurrent/success resubmission.
No customer field/FLS/API grants and no sharing writer. Scheduler not needed for broker expiry.

Tests use actual Plus A/B same Account and C another Account; prove own DTOs, separate consent,
foreign/expired/reserved-only/missing/revoked denial, ID/identity/service/date/location/token tamper,
unsafe-image fallback, native Vehicle/ledger/Visit-create denial, public/internal/wrong-site denial,
own Visit + Service queue Case/link, replay/binding/duplicate denial and capacity rollback with no
orphan Case. Conflict/time-bound policy tested without weakening validated ledger constraints.
Unit tests are not live customer/browser/API session, real race/load or rendered accessibility UAT.

Exact candidate `manifest/p8-broker-local.xml`, 34 components: validated ledger/reconciler 24;
broker/test 2; Visit key/fingerprint fields 2; facade/capacity/intake classes 3; Home/Vehicles/
Appointment LWC bundles 3. Receipt `component_scope.json`; 55 source/manifest hashes in
`submitted_source_hashes.json`. Excludes customer permission/profile changes, other three portal
bundles, actual grants/data/users, Builder/navigation/publication, cron/recalculation activation
and destructive/unrelated metadata. Separate exact deployment approval still required.

P8-05/P8-07 source now implemented and scoped-validated LOCALLY, not deployed or operationally
accepted. Reviewed ownership AND service-consent records, approved Plus identities/access/catalog,
page placement, controlled publication and actual-persona/security/mobile/AT UAT still gated.
Existing queued Case visibility is subject to the reviewed native sharing plan; no implicit share
workaround added. No new implementation/security design blocker demonstrated. All Phase 1–7
exceptions/CP2 preserved; M4/Phase 8 not owner-accepted. Full source/seam/results/limits:
`evidence/P8/BROKER_COMPLETION/RESULT.md`.

## 71. Final Phase 8 development package deployed — 2026-10-27

Owner authorized exact validated manifest/p8-broker-local.xml deployment only. All 55 submitted
manifest/source hashes match validation; scoped directories contain no extras. Frozen preflight
source at evidence/P8/BROKER_DEPLOYMENT/validated_source/. Org identity verified ng-demo
00Daj00001Ae3iWEAR. No scope expansion or unrelated source edits.

CONFIRMED — raw Quick Deploy `quick_deploy.json`:
```json
{"id":"0Afaj00000pPottCAC","checkOnly":false,"status":"Succeeded","numberComponentsDeployed":34,"numberComponentsTotal":34,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
```
Eligible stored transaction reused validation `0Afaj00000pPiV7CAK`, 43/43 tests and broker
98.039% coverage; prior local UI/source/state tests 25/25 reused, not rerun. No fallback/subset,
full regression, real browser/customer/AT or new acceptance test claim.

CONFIRMED — selected raw `verification.json` fields:
```json
{"retrievedSourceFiles":54,"pageSiteXmlFilesUnchanged":64,"checks":{"all_existing_control_rows_unchanged":"CONFIRMED","no_guest_or_portal_vehicle_model_ledger_crud":"CONFIRMED","new_reviewer_unassigned":"CONFIRMED","scheduler_configuration_unchanged":"CONFIRMED","new_ledger_empty":"CONFIRMED","new_ledger_shares_empty":"CONFIRMED","portal_unpublished":"CONFIRMED","no_customer_users":"CONFIRMED","source_unchanged":"CONFIRMED","exact_34_component_transaction":"CONFIRMED"}}
```
All 34 deployed (type,name) pairs match validation; scoped retrieve verifies 54 component files:
text newline normalization only; submitted XML values equal with platform defaults permitted.
All 64 existing FlexiPage/app/Network/CustomSite/navigation files byte-identical. No SiteDotCom
binary re-investigation. Existing 11 Users, 32 assignments, profile/system/object/FLS/setup rows,
memberships and seven available share tables unchanged. Seventeen business-object Id/SystemModstamp
fingerprints equal, including CP2 Quote/lines/Financing, visits/Cases, inventory, history and loyalty.
Parent-controlled Loyalty_Transaction__Share unavailable, not falsely verified.

CONFIRMED — raw Network:
```json
{"Id":"0DBaj000006bf3xGAA","Status":"UnderConstruction","FirstActivationDate":null}
```
New ledger rows=0/shares=0. Native Vehicle/Model/ledger grants=0 on hardened portal profile,
Foundation, Batch B and guest; no customer Visit Create grant added. New internal Reviewer set
0PSaj00000hErrhGAC has zero assignments. All three existing CronTrigger configs identical; no
reconciliation activation. Broker expiry checks do not depend on activating a cleanup job.

Expected new-metadata additions explicitly captured, not described as zero permission changes:
one Reviewer definition, its one object/six FLS/two setup rows, seven platform Admin Apex ACLs,
and new-ledger default object rows for System Administrator/Analytics Cloud Integration User.
Those internal profiles already had Modify All Data/View All Data before deployment, unchanged
after (`platform_default_context.json`). All pre-existing rows unchanged; no customer/guest new
object grants, profile edit or assignment. No unexpected security change demonstrated.

Development status: all P8-01–11 addressed/delivered; P8-05 own detail/photo and P8-07 guarded,
independent-consent/idempotent requests are now DEPLOYED. Backend uses existing authoritative
capacity/intake paths; no competing booking Flow or native customer Vehicle CRUD. P8-10 browser/
AT and P8-11 actual-customer UAT remain unexecuted. Phase 8/M4 NOT owner-accepted.

Focused operational readback (`operational_inputs/`): Plus licenses 5 total/0 used; A/B exact
Contact/Account links and existing role-qualified owner 005aj00000gE0b3AAC retained. Active eligible
service catalog already contains Northgate Service Centre a07aj00001MCKYwAAP (capacity 6).
No development deployment blocker remains; actual identities/mailboxes/reviewer/ownership and
separate service-consent data/access/page placement/publication/UAT are still approval-gated.

Shortest separately approved sequence:
1. Approve exact pilot identities/mailboxes, internal reviewer assignment, A/B minimum permissions/
   membership, reviewed ownership AND separate servicing-consent rows/Vehicle IDs, positive UAT
   data and narrow own-record visibility. Existing A/B Accounts need no transfer/role swap. Keep
   native Vehicle/Model/ledger and native Visit Create denied; no Vehicle share is needed. Review
   native Case/comment write/other-source visibility before customer assignment; no blind grants.
2. Read Builder structure, then approved Save: one ownerPortalHome on authenticated Home, native
   My portal navigation/login/logout. Five child bundles already compose; no invented page routes.
   Record guest/access baseline, no publication implied by page-save approval.
3. Separately approve controlled publication/write-UAT/containment, then immediately run normal
   A/B own/foreign/expiry/revocation/native/API/guest/booking/capacity/idempotency/Case/loyalty tests.
   Foundation requires Live: UnderConstruction/admin preview is not a positive login pass.
4. Capture real mobile/keyboard/zoom/AT/logout evidence and request owner acceptance with retained
   Phase 1–7 exceptions. No extra users/reparenting/data changes without their explicit scope.

No operational change, customer user/ownership/share creation, Builder Save, publication, job
activation or Git command performed. CP2/source functionality protected; no ng-dev access.
Exact receipts, preservation exceptions/limits, scope and next steps:
`evidence/P8/BROKER_DEPLOYMENT/RESULT.md`.

## 72. Controlled customer setup — partial; stopped pending owner — 2026-10-27

Owner authorized A/B Plus login creation, the two Contact email updates, minimum Foundation/
membership, four synthetic ownership/service-consent rows and one authenticated Home Save.
Publication/activation, booking/Case write-UAT, unrelated data, scheduler and Git remain prohibited.
Target identity checked as ng-demo 00Daj00001Ae3iWEAR; ng-dev never accessed.

CONFIRMED — raw Composite response for the only successful Salesforce write:
```json
{"compositeResponse":[{"body":null,"httpHeaders":{},"httpStatusCode":204,"referenceId":"emailA"},{"body":null,"httpHeaders":{},"httpStatusCode":204,"referenceId":"emailB"}]}
```
Only Email PATCHed on Contacts 003aj00002Xl4IfAAJ and 003aj00002Xl4IgAAJ. Actual readback:
```text
003aj00002Xl4IfAAJ Email=arjun.subramanya230@gmail.com AccountId=001aj000049ZoXNAA0
003aj00002Xl4IgAAJ Email=arjun_major@icloud.com AccountId=001aj000049ZoXOAA0
```
Both retain OwnerId 005aj00000gE0b3AAC. Lowercase values returned; cause not diagnosed.

Provisioning command `sf apex run --file evidence/P8/CUSTOMER_PORTAL_SETUP/create_users.apex
--target-org ng-demo --json` STOPPED before any User insert:
```text
executeRuntimeFailure
System.AssertException: Assertion Failed: Expected: Arjun.subramanya230@gmail.com, Actual: arjun.subramanya230@gmail.com
AnonymousBlock: line 11, column 1
Number of DML statements: 0 out of 150
Number of Email Invocations: 0 out of 10
```
No patch/retry/workaround. Owner must confirm intended lowercase recipients and authorize only a
case-insensitive email precondition correction plus one controlled attempt. Do not replay writes
blindly. Planned usernames (NOT created):
```text
A ng.portal.a.00daj00001ae3iw.aadb68c436@northgate.demo
B ng.portal.b.00daj00001ae3iw.aadb68c436@northgate.demo
```
No passwords generated/disclosed by agent, no reset/invitation request sent; delivery unverified.

Builder browser snapshot failed verbatim:
```text
Browser MCP's extension is now 2.0. Update the MCP server: use @browsermcp/mcp@latest in your AI app's MCP config and restart the app
```
Owner must update/restart connection and connect authenticated ng-demo tab. No Builder inspection,
save, navigation change or publication; browser line stopped without alternate workaround.

CONFIRMED — selected raw post-stop verification fields:
```json
{"usersCreated":0,"emailsRequested":0,"permissionAssignmentsAdded":0,"membershipChanges":0,"ledgerRowsCreated":0,"builderSaved":false,"published":false}
```
```json
{"claims":{"only_approved_contact_fingerprints_changed":"CONFIRMED","profile/assignments":"CONFIRMED","profile/network_groups":"CONFIRMED","profile/network_members":"CONFIRMED","roles_unchanged":"CONFIRMED","scheduler_unchanged":"CONFIRMED","guest_assignments_unchanged":"CONFIRMED","permissions_unchanged":"CONFIRMED","guest_profile_permissions_unchanged":"CONFIRMED","no_customer_users":"CONFIRMED","ledger_still_empty":"CONFIRMED"}}
```
All 16 non-Contact business fingerprints, seven available share tables, 11 User fingerprints,
roles, hardened-profile/FLS/system/assignment/membership state compare equal. Only approved
Contact fingerprints differ. Guest boundary intact/no Vehicle CRUD or broad share introduced.
Network UnderConstruction/FirstActivationDate null, security options unchanged. CP2 untouched.

Foundation/membership, reviewer assignment, four distinct seven-day synthetic ledger rows and
Home Save NOT done. Approved mappings A→a0Daj00001D2FPaEAN, B→a0Daj00001D2FPbEAN and reviewer
005aj00000feqbNAAQ retained for resume after owner direction. Ledger IDs nonexistent. Batch B
withheld: existing Case Create requires native customer-boundary proof; no admin-context pass
or actual customer runAs/browser/write-UAT claim. No deployment/tests/Git/jobs. §71 development
delivery unchanged; Phase 8/M4 not accepted. Complete receipts, files touched, limits and specific
owner actions: `evidence/P8/CUSTOMER_PORTAL_SETUP/RESULT.md`.

## 73. Approved resume — independent pilot data/membership complete; User role check stopped — 2026-10-27

Owner approved lowercase recipients and case-insensitive preconditions, exactly one controlled
User attempt and continued independent setup. Only two assertions in create_users.apex changed;
all other security checks and exact saved email values retained. Contact email updates not repeated.
Fresh preflight found no linked Users, correct Accounts/owner role, five unused Plus licences,
empty ledger and unpublished site. No Git, development deployment, bookings/Cases or scheduler work.

REFUTED — User provisioning success. Raw resume_create_customer_users_once.json:
```text
System.AssertException: Assertion Failed: Expected: Worker, Actual: PersonAccount
AnonymousBlock: line 35, column 1
compiled: true
success: false
Number of DML statements: 1 out of 150
Number of DML rows: 2 out of 10000
```
Post-insert role invariant failed. No role relaxation, second attempt or permission workaround.
CONFIRMED — final linked User query records=[], totalSize=0; original 11 User/28 role snapshots
unchanged. Neither planned username is created/login-ready. Email delivery not verified.
Read-only diagnosis also returned INVALID_FIELD: No such column 'IsPersonAccount' on entity
'Account' (resume_account_types.json); stopped, no type/role cause inferred or query repair loop.
Owner manual action: inspect Contact A → Enable Customer User, lowest offered role without Save,
then confirm intended role mapping for review before another attempt. PersonAccount classification
is NOT itself established as elevated access or a Salesforce defect. Email approval is resolved.

CONFIRMED — exact successful independent changes:
```text
PSA 0Paaj000018BQuvCAG: 005aj00000feqbNAAQ → Reviewer 0PSaj00000hErrhGAC
NetworkMemberGroup 0DLaj000002StZtGAK: Network 0DBaj000006bf3xGAA → Foundation 0PSaj00000h8ikiGAA
A Ownership             a0Faj00000QaOsrEAF → Vehicle a0Daj00001D2FPaEAN
A Service_Authorization a0Faj00000QaOssEAF → Vehicle a0Daj00001D2FPaEAN
B Ownership             a0Faj00000QaOstEAF → Vehicle a0Daj00001D2FPbEAN
B Service_Authorization a0Faj00000QaOsuEAF → Vehicle a0Daj00001D2FPbEAN
```
Ledger created Pending AS USER, verified through existing service/guard as actual internal reviewer
Arjun; no verification stamps supplied. All four Verified, Approved_Synthetic_Fixture, distinct
P8-SYNTHETIC-DEMONSTRATION-A/B-Ownership/Service_Authorization-20261027 references, no source
Delivery. Exact half-open interval [2026-10-27T23:06:28Z, 2026-11-03T23:06:28Z). Synthetic portal
entitlements only, not legal title; previous-customer history remains private. Four implicit Owner
ledger-share rows for internal Arjun only; no Vehicle shares/external ledger grants.

Membership creation used supported createable NetworkMemberGroup sObject with PermissionSet
ParentId. Existing admin criterion and three NetworkMembers retained; Foundation assignments
still zero, so no additional user qualifies. No profile-wide membership. Customer Foundation/
Batch B assignments and Contact-specific access NOT done (no persisted Users). Batch B Case
Create remains gated by native customer-boundary proof, not asserted safe from admin context.

CONFIRMED — raw resume_verification.json selected command-output checks:
```json
{"evidenceComparison":"CONFIRMED","checks":{"only_internal_reviewer_assignment_added":"CONFIRMED","only_foundation_membership_criterion_added":"CONFIRMED","roles_rollback_confirmed":"CONFIRMED","contact_emails_and_links_preserved":"CONFIRMED","no_persisted_customer_users":"CONFIRMED","portal_security_and_unpublished_state_unchanged":"CONFIRMED","exact_four_separate_approved_relationships":"CONFIRMED","seven_day_validity":"CONFIRMED","ledger_shares_only_implicit_internal_owner":"CONFIRMED","deployed_source_and_manifest_unmodified":"CONFIRMED"}}
```
All 17 prior business fingerprints (including Contact/CP2), seven available share tables, profile/
FLS/system/guest rights and all three scheduler configs preserved; 55 deployment hashes match.
Network UnderConstruction, FirstActivationDate null, four security options false. No additional
customer/native Vehicle/Model/ledger rights, broad shares, Visit Create, historical/inventory writes.
Builder Home Save PENDING under prior Browser MCP blocker; not bypassed or retried. No actual
customer login/native/API/runAs/accessibility proof or publication/write-UAT. No Phase 8/M4 acceptance.
Full receipts, evidence references, remaining manual role action and limits:
`evidence/P8/CUSTOMER_PORTAL_SETUP/RESUME_RESULT.md`.

## 74. ARO-aware A/B customer provisioning succeeded — 2026-10-27

Owner approved the diagnosed role validation correction, exact two Plus identities, minimum
assignments and existing site membership. No ledger recreation/date changes, publication, Cases/
bookings, new broad shares, jobs or Git. Target identity ng-demo 00Daj00001Ae3iWEAR verified.

Applied role guard only in operational create_users.apex plus explicit identity postconditions:
CustomerPortal required; PersonAccount accepted only with current ARO=true readback and correct
PortalAccountOwnerId; Worker requires correct PortalAccountId; all other roles rejected. Existing
org/Contact/Account/owner/email/hardened Plus/UserType checks retained. No role or ARO setting
write. New provision_aro_users.py performs fresh live readback, duplicate/conflict detection,
freezes executed source, and reuses fully matching existing Users without reinsert/email replay.

CONFIRMED — raw successful create_users_once.json: compiled=true, success=true, exceptionMessage="".
Final User readback:
```text
A 005aj00000guQE9AAM ng.portal.a.00daj00001ae3iw.aadb68c436@northgate.demo
  Contact=003aj00002Xl4IfAAJ Account=001aj000049ZoXNAA0 Email=arjun.subramanya230@gmail.com
B 005aj00000guQEAAA2 ng.portal.b.00daj00001ae3iw.aadb68c436@northgate.demo
  Contact=003aj00002Xl4IgAAJ Account=001aj000049ZoXOAA0 Email=arjun_major@icloud.com
Both IsActive=true IsPortalEnabled=true UserType=PowerCustomerSuccess TimeZoneSidKey=America/Toronto
Both Profile=00eaj00000UBi7iAAD NG_Owner_Portal_User / Customer Community Plus
```
Plus licences now 5 total/2 used. Standard new-User email requested via triggerUserEmail=true;
inbox receipt/password setup/first login NOT verified. No password API/disclosure or email replay.

CONFIRMED — native shared role 00Eaj00000QVYJNEA5 for both, PortalRole=PersonAccount,
PortalType=CustomerPortal, PortalAccountOwnerId=005aj00000gE0b3AAC, PortalAccountId=null,
ParentRoleId=00Eaj00000QCxlLEAT. This is Salesforce's inherent ARO role creation; all previous
28 roles unchanged. No manual role creation, reassignment, elevated role or setting change.

CONFIRMED — explicit Foundation assignments:
```text
005aj00000guQE9AAM → Foundation 0PSaj00000h8ikiGAA via 0Paaj000018B714CAC
005aj00000guQEAAA2 → Foundation 0PSaj00000h8ikiGAA via 0Paaj000018B715CAC
```
Native profile-owned PSA rows 0Paaj000018BYR3CAO/0Paaj000018BYR4CAO also created for hardened
profile-owned set 0PSaj00000h8ikhGAA. Initial local check for no baseline PSA stopped before
assignment DML; live IsOwnedByProfile/ProfileId verification identified expected profile rights,
then Foundation assigned once. No extra capability or removal. No Batch B/Reviewer on customers;
no API Enabled, Vehicle/Model/ledger CRUD or native Case/Visit Create addition. Profile/FLS/system
snapshots unchanged, prior assignments retained. Existing Foundation membership criterion reused;
two A/B NetworkMembers added, previous three internal members retained.

CONFIRMED — UserRecordAccess queries explicitly targeting each actual UserId:
```text
A own Contact/Account Read=true; B Contact/Account Read=false
B own Contact/Account Read=true; A Contact/Account Read=false
All HasEditAccess=false and HasDeleteAccess=false
```
Implicit own access suffices; zero explicit share writes. This is scoped effective-record evidence,
not admin's own access, actual login/native API/session/runAs proof, or same-Account live UAT.

CONFIRMED — exact four ledger records/stamps/SystemModstamp and dates unchanged; original
half-open seven-day window [2026-10-27T23:06:28Z, 2026-11-03T23:06:28Z) retained. No recreate,
reverify or extension. Vehicle shares=0, four ledger shares remain internal-owner-only. All prior
11 User fingerprints/assignments retained, scheduler configs and 55 deployment hashes unchanged.
Raw scoped comparison: ARO_PROVISIONING/20261027T232312139576Z/verification.json, all checks
CONFIRMED. No repeat full Phase 8 audit or full-runtime CP2 regression claim.

Portal stays UnderConstruction/FirstActivationDate=null; self-registration/internal login/guest
member visibility/invitations flags false and unchanged. Builder Home Save PENDING under browser
blocker, no workaround. Remaining prerequisites: recipient email/password setup, supported Home
Save, separately authorized controlled publication and real A/B/native/accessibility UAT. Batch B
still withheld pending native Case boundary proof; no bookings/Cases. No Phase 8/M4 acceptance.
Full receipts and exact user/permission/membership details:
`evidence/P8/CUSTOMER_PORTAL_SETUP/ARO_PROVISIONING/RESULT.md`.

## 75. Standard A/B password-reset requests accepted — 2026-10-27

Owner authorized standard setup-email/password resets only after changing Deliverability.
Target ng-demo 00Daj00001Ae3iWEAR verified; no ng-dev access.

CONFIRMED — latest live SetupAuditTrail sendEmailAccessControl event:
```text
2026-10-27T23:29:48Z Changed Access to Send Email level from System email only to All email
```
No setting changed by agent. Direct Setup UI remains blocked by Browser MCP extension/server
version mismatch; no workaround. Audit proves the recorded owner change, not a UI screenshot.

CONFIRMED — existing active hardened-Plus identities checked, then standard System.resetPassword
(userId, true) invoked once for each approved User; returned password values ignored/not read.
Raw operation output:
```text
compiled=true success=true exceptionMessage=""
P8_STANDARD_RESET_ACCEPTED UserId=005aj00000guQE9AAM sendUserEmail=true
P8_STANDARD_RESET_ACCEPTED UserId=005aj00000guQEAAA2 sendUserEmail=true
```
CONFIRMED — audit resetpassword events for A and B at 2026-10-27T23:32:56Z; both User
LastPasswordChangeDate changed from null to that timestamp. Identity/profile/email/Contact fields
unchanged. No password chosen, getNewPassword/setPassword call, password/token storage or reset retry.

Delivery evidence: no reset exception or unpublished-site error. No EmailLog/EmailDeliveryLog
sObject exposed; scoped recipient EmailMessage header query returned zero (not evidence of failed
system-mail delivery). SMTP acceptance/inbox receipt/spam placement/password completion/login NOT
VERIFIED. No site-related delivery blocker demonstrated; UnderConstruction/FirstActivationDate=null
and site security options unchanged. No publication or activation to troubleshoot mail.

If mail is missing: owner checks inbox/spam, then Setup → Email Log Files for 23:32:56 UTC and
these exact two recipients. Transport-log inspection needs working browser access. No speculative
email resend/configuration change. No permission/sharing/ownership/deployment/scheduler/Git work.
Full raw receipts and verification: `evidence/P8/CUSTOMER_PASSWORD_SETUP/RESULT.md`.

## 76. Dashboard runtime permission deployed/assigned; security validation partial — 2026-10-28 UTC

Owner authorized exact one-PermissionSet manifest, exactly A/B assignments and targeted tests.
ng-demo 00Daj00001Ae3iWEAR identity verified. Reviewed candidate SHA-256s match; existing 55
deployment hashes unchanged. No Apex/LWC/profile or unrelated metadata/source modification,
Git or ng-dev access. Working tree preserved without inspection/cleanup through Git.

CONFIRMED — raw validation output:
```json
{"id":"0Afaj00000pTPCACA4","status":"Succeeded","checkOnly":true,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":22,"numberTestsCompleted":22,"numberTestErrors":0}
```
Existing local validator 10/10. Targeted classes: OwnerPortalFoundationControllerTest,
OwnerPortalBatchBControllerTest, OwnerPortalVehicleBrokerTest. Their rollback-only fixtures use
existing permission sets, not a new-minimal-set combination test. No persistent fixture write.

CONFIRMED — raw exact Quick Deploy:
```json
{"id":"0Afaj00000pT3OYCA0","status":"Succeeded","checkOnly":false,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":0,"numberTestsCompleted":0,"numberTestErrors":0}
```
Only PS_Owner_Portal_Dashboard_Runtime deployed. Reused validation; no tests rerun at deploy,
no fallback/additional deployment. Live set 0PSaj00000hHfZ7GAK has the approved one facade class,
three object Reads and six FLS Reads only. No native Case/Visit write, external Vehicle/Model/
ledger CRUD, View/Modify All or broader system privilege added. Full Batch B not assigned.

CONFIRMED — exact assignment receipts:
```text
005aj00000guQE9AAM → 0PSaj00000hHfZ7GAK via 0Paaj000018ByQMCA0
005aj00000guQEAAA2 → 0PSaj00000hHfZ7GAK via 0Paaj000018ByQNCA0
```
Idempotent missing-pair preflight then one all-or-none Composite. Global assignments 37→39,
only these additions. Existing User/profile/role/Contact links, Foundation, criteria/members,
Network settings, ledger records/stamps/dates and five scheduler configs unchanged.

CONFIRMED — effective UserEntityAccess checks targeting each real UserId:
```text
Case/Service_Visit__c/Loyalty_Member__c Read=true; Create/Edit/Update/Delete=false
Vehicle__c/Vehicle_Model__c/Contact_Vehicle_Relationship__c all Read/Create/Edit/Update/Delete=false
```
Facade access resolves through new assigned set for both. UserRecordAccess over 15 actual records
each: own Contact/Account Read only, other customer's Contact/Account denied, Vehicles/Models/
ledger and unrelated Case/Visit/Member samples denied, all Edit/Delete/All flags false. Scoped
sample, not exhaustive native-surface coverage. Current separate ownership/consent pairs still
eligible in ledger snapshot; broker isolation guard tests passed. No actual A/B DTO/options call.
Vehicle shares=0; four ledger shares internal-owner-only. No explicit sharing/business write.

PARTIAL — UserFieldAccess query line stopped on exact platform error:
```text
UNKNOWN_EXCEPTION
An unexpected error occurred. Please include this ErrorId if you contact support: 518776881-741325 (1686693879)
```
Seven already-started parallel checks errored, five not executed. No retry, broadening or repair.
Six live FieldPermissions match approved definition, but effective-field API proof incomplete.
Not a confirmed portal runtime exception or security regression. Owner Support action: attach
org/User IDs, exact query/ErrorIds and field_api_errors.json for internal exception diagnosis.

Browser MCP reports no connected extension tab. Actual owner A/B authenticated dashboard/vehicle/
eligibility/native/browser/accessibility UAT NOT RUN. Owner UAT ready to BEGIN (normal login,
connect tab, read-only refresh); not passed/security-accepted. No booking/Case submission.
Other child-panel read dependencies intentionally outside this package remain unchanged.
SecurityValidationStatus=PARTIAL; no completed check REFUTED. Phase 8/M4 NOT complete.
Receipts, targeted test methods, scope/limits and specific manual follow-up:
`evidence/P8/DASHBOARD_RUNTIME_DEPLOYMENT/RESULT.md` and verification.json.

## 77. Service-history two-field FLS deployed — 2026-10-28 UTC

Owner authorized exact correction only, existing one-PermissionSet manifest, targeted validation
and read-only security verification. ng-demo 00Daj00001Ae3iWEAR identity verified. No ng-dev/Git.
Reviewed candidate hashes preserved; live baseline had six FLS Reads and differed only by the
approved additions. Local validator 12/12. No Apex/LWC/profile/sharing or data changes.

CONFIRMED — raw Salesforce validation:
```json
{"id":"0Afaj00000pTnZRCA0","status":"Succeeded","checkOnly":true,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":22,"numberTestsCompleted":22,"numberTestErrors":0}
```
Targeted Foundation/BatchBController/VehicleBroker tests include Contact isolation, foreign
history-row/Case masking and broker guards. Rollback-only test fixtures, no persistent fixtures.
They do not prove this minimal permission combination in actual A/B sessions.

CONFIRMED — raw exact Quick Deploy, reused tests (no extra deployment or rerun):
```json
{"id":"0Afaj00000pSzJNCA0","status":"Succeeded","checkOnly":false,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0,"numberTestsTotal":0,"numberTestsCompleted":0,"numberTestErrors":0}
```
Only PS_Owner_Portal_Dashboard_Runtime updated, existing Id 0PSaj00000hHfZ7GAK. Live FLS 6→8:
Service_Visit__c.Mileage_At_Checkin__c and Service_Visit__c.Case__c Read=true/Edit=false. Every
previous field value, object CRUD/class access and set/system definition unchanged. All 39
assignment records compare equal: no assignment/reassignment operation. Existing A/B runtime
and Foundation assignments, profiles/roles/Contact links, Network membership/Live state retained.

CONFIRMED — per-user effective native Case/Visit Read only; Create/Edit/Update/Delete false.
Vehicle/Model/ledger Read/Create/Edit/Update/Delete false for both. Record checks over 14 known
records per User: B reads own Visit a08aj00001UbaiFAAR and Case 500aj00003rhFEbAAM, A cannot;
own Contact/Account Read only, other customer's denied; all native Vehicle/Model/ledger reads
denied; all sampled Edit/Delete/All false. Scoped evidence, not exhaustive all-record audit.

CONFIRMED — B Visit/Case 00001102 and SystemModstamp unchanged; no new booking, Case, status,
schedule, mileage or record mutation. Four ledger rows/dates and five scheduler configs unchanged.
Existing 55 development hashes match; no booking/broker/CP2 source change. No full CP2 runtime
regression or actual authenticated service-history response claimed.

No failures or unexpected permission changes in completed checks. Known UserFieldAccess API
internal error not retried; exact deployed FLS verified via FieldPermissions and actual assignments,
native CRUD/record rights via UserEntityAccess/UserRecordAccess. B browser retest READY, NOT RUN:
normal B login → refresh history → existing Requested Visit should appear; no status change or
new booking needed (history has no status filter). No browser UAT pass or Phase 8 completion.
Actual receipts/security limits: `evidence/P8/SERVICE_HISTORY_FLS_DEPLOYMENT/RESULT.md` and
verification.json. No additional metadata deployments, permission assignments, security broadening,
profile/sharing/data changes or Git operations.

## 78. My Cases Subject Read FLS deployed — browser UAT outstanding

Recorded target: ng-demo 00Daj00001Ae3iWEAR. Exact existing one-PermissionSet manifest;
only PS_Owner_Portal_Dashboard_Runtime updated. This section and the receipt were added
in an owner-authorized documentation-only repair; no deployment, tests or checks rerun.

CONFIRMED — raw recorded validation excerpt:
```json
{"id":"0Afaj00000pTterCAC","status":"Succeeded","checkOnly":true,"numberComponentsTotal":1,"numberTestsCompleted":22,"numberTestErrors":0}
```
CONFIRMED — raw recorded Quick Deploy excerpt (reused validation):
```json
{"id":"0Afaj00000pTuFxCAK","status":"Succeeded","checkOnly":false,"numberComponentsTotal":1,"numberComponentsDeployed":1,"numberComponentErrors":0}
```
CONFIRMED — raw verification.json excerpts:
```json
{"localTestsPassed":12,"apexTestsPassed":22,"addedFieldPermission":{"Field":"Case.Subject","PermissionsRead":true,"PermissionsEdit":false},"assignmentsAdded":0,"browserUAT":"NOT RUN","phase8Complete":false}
```
```json
{"exact_subject_read_only_delta":"CONFIRMED","assignments_unchanged":"CONFIRMED","A_existing_assignments_retained":"CONFIRMED","B_existing_assignments_retained":"CONFIRMED","objects_unchanged":"CONFIRMED","setup_unchanged":"CONFIRMED","case_unchanged":"CONFIRMED","visit_unchanged":"CONFIRMED","A_record_access_unchanged":"CONFIRMED","B_record_access_unchanged":"CONFIRMED","55_existing_implementation_hashes_unchanged":"CONFIRMED"}
```
Eight prior field grants and all 39 assignments retained. Actual per-user checks retained
Case/Visit native write denials and Vehicle/Model/ledger CRUD denials. A cannot read B's
Case 00001102 or Visit a08aj00001UbaiFAAR; B retains Read-only record access. No Apex/LWC,
profile, sharing, record or assignment changes; CP2/booking/history implementation unchanged.

Owner already browser-confirmed service history (Requested Visit and linked Case 00001102).
Outstanding: authenticate as B, refresh My Cases and confirm Case 00001102 appears.
No My Cases browser UAT pass or Phase 8 completion claimed. Existing Apex fixtures do not
prove the minimal runtime permission combination; record checks are scoped to the known B
Case/Visit. No full CP2/booking/history runtime regression. UserFieldAccess API not retried.

Original receipt-file patch failed with:
`patch verification failed: The first line of the patch must be '*** Begin Patch'`.
Owner approved this documentation-only retry and handoff update. Existing raw verification,
deployment/test/security receipts preserved without modification. Current receipt:
`evidence/P8/MY_CASES_FLS_DEPLOYMENT/RESULT.md`; raw verification: verification.json alongside it.
