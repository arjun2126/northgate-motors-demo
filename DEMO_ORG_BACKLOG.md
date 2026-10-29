# Demo Org Backlog — Northgate Motors

**Current status (latest evidence October 26, 2026 UTC):** Phase 5 is owner-accepted with documented exceptions.
**Phase 6: OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026.**
All four batches and final blockers are repaired/deployed. Ten internal Knowledge Drafts/ten
selections and corrected administrator report/source totals are verified. All deferred
operational/browser/publication/activation requirements remain outstanding, not passed.
Phase 7 Batch 1 standard recovery is deployed: photos 1/1, then application 21/21, zero errors.
Developer Edition deployments used NoTestRun; prior 163/163 validation is reused, not rerun.
All thirty deployed photo hashes and existing model paths match. Credential, placement and
browser/gallery/event acceptance remain deferred; Batch 1 is not owner-accepted.
Batch 2 is deployed: atomic application/removals 14/14 and territories 6/6; prior 235/235 tests
reused, not rerun. Planning model persists Read/None/None/None, zero Account/User associations.
Batch 2 is not owner-accepted; identity/assignment/activation and native/browser acceptance remain.
Final Batch 3 prompt (1/1) and Batch 4 header/page (2/2) are deployed under separate owner approval.
Prompt remains Draft/inactive; page is unassigned/inactive. Existing Vehicle/all-app assignments,
settings, permissions/user-role state, triggers and 27 project business-record fingerprints match.
Agent/Data Cloud/portal/runtime/full-regression/DQ/clean-release and actual placement/screenshots/
live walkthrough acceptance remain open. Phase 7 is not fully owner-accepted. All 23 block states
are indexed in `docs/planning/PHASE7_FINAL_STATUS_2026-10-26.md`. Phase 8 is preparation only;
all eleven requirements and proposed gated sequence are in `docs/planning/PHASE8_HANDOFF_2026-10-26.md`.
Focused P8-01–03 read-only verification/proposal is in handoff §48 and
`docs/planning/PHASE8_FOUNDATION_DECISION_2026-10-26.md`; no Phase 8 implementation or setup changes.
Subsequent owner-enabled Digital Experiences is verified true (handoff §49); Customer Service
template is available and site list empty. Four local read-only context/security definitions are
packaged, not server-tested/deployed; no users/grants/site/record changes. Current scope/fixture-
owner decision: `docs/planning/P8_FOUNDATION_LOCAL_PREPARATION.md`.
No live business data, permissions, territory assignments or activation is authorized.
Earlier Quick Deploy was rejected; the owner subsequently authorized standard deployment of the
same manifests. That recovery succeeded without expanded scope or unrelated repairs.
**Source of truth for scope and sequencing.** Conventions and org rules live in
`DEMO_ORG_MASTER_PLAN.md`; field-level design in `DEMO_ORG_DATA_MODEL.md`; storage budget in
`DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §2.
Review checklist and definition of done: `docs/GOVERNANCE.md`; retained limitations: `docs/TECH_DEBT.md`.

## How to use this backlog

- Item IDs are stable: `P<phase>-<nn>`. Use the ID as the branch name slug:
  `feat/P2-04-financing-wizard`.
- Status values: `backlog` → `ready` → `in-progress` → `blocked` → `done`.
- An item is **done** only when its acceptance criteria are met *and* its validation step runs
  clean *and* the evidence artifact exists. Do not mark done on code written alone.
- **Dependencies** = items that must be done first. **Evidence** = the concrete artifact
  (test output, report run, screenshot path) proving completion; it lives under
  `evidence/` or `docs/`.
- Each milestone is independently demoable. Do not start a later milestone until the previous
  milestone's exit gate passes.
- **Execution requires owner approval per phase.** Phase 0 may be approved independently.

### Legend (skill tags)

`ADMIN` `FLOW` `APEX` `LWC` `DATA` `REPORT` `SECURITY` `INTEG` `DEVOPS` `ARCH` `TEST` `DOC`
Mapped to market demand in `DEMO_ORG_MASTER_PLAN.md` §11.

---

# Phase 0 — Org acquisition, settings, verification, repo (no metadata)

**Purpose:** make both permanent orgs build-ready and resolve every "verify" question before
any design depends on an answer. **Creates no metadata** (master plan §13): no users, roles,
permission sets, record types, picklists, layouts, VRs or sharing settings.
**Depends on:** owner supplying org credentials (never committed).

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P0-01 | Two permanent DE orgs + aliases | `ng-dev` (build/UAT) and `ng-demo` (stable demo) signed up; `sf org display` proves real (non-scratch) DE; aliases `ng-dev`/`ng-demo` work; credentials in password manager only | Owner approves Phase 0 | `sf org list` output → `evidence/P0/org_list.txt`; org IDs in `metadata-log/ORG_INFO.md` | DEVOPS, DOC |
| P0-02 | Project folder scaffold | `sfdx-project.json`, `.forceignore`, `.gitignore`, `force-app/main/default/`, `metadata-log/`, `data/csv/`, `scripts/`, `docs/`, `evidence/` present | P0-01 | Tree matches MASTER_PLAN §6.1 → `evidence/P0/tree.txt` | DEVOPS, DOC |
| P0-03 | Git + private GitHub repo | Local `git init`; **private repo `arjun2126/northgate-motors-demo` created by the OWNER with `gh` (never by an agent, never with agent-handled tokens)**; remote set by build agent; `.sf/`, `.sfdx/`, `node_modules/`, `data/snapshots/`, `*.log`, `.env`, `.key`, `**/secrets/**` ignored; first push clean | P0-02 | `git status` + repo URL in `metadata-log/README.md`; secret grep output → `evidence/P0/secret_grep.txt` | DEVOPS |
| P0-04 | CI validate workflow skeleton (**disabled**) | `.github/workflows/validate.yml` committed **with auth commented out**: PR/push → `sf project deploy start --dry-run --test-level RunLocalTests` vs `ng-dev`, activated in P1 once P1-22 External Client App credentials exist; **no scheduled CI login job** (CI/API logins are not assumed to reset the expiry timer, §3.5); no credential in logs | P0-01, P0-03 | Workflow file present but disabled → `evidence/P0/ci_skeleton.yml` | DEVOPS |
| P0-05 | Org settings, both orgs | My Domain set (login branding), locale `en_CA`/`America/Toronto`, corporate currency CAD (or multi-currency recorded), calendar fiscal year, business hours `Mon–Fri 08:00–18:00` — each with a [VERIFY] note | P0-01 | `docs/VERIFY_RESULTS.md` settings table + Setup screenshots → `evidence/P0/settings/` | ADMIN |
| P0-06 | Email deliverability policy | Deliverability = **"System email only"** (default kept); policy recorded: real plus-addressed emails for the 6 internal users (activation), `.test` domains for seed data; "All email" only during a scheduled test then reverted | P0-05 | Setting screenshot + `metadata-log/README.md` entry → `evidence/P0/email_policy.png` | ADMIN, DOC |
| P0-07 | Keep-alive protocol (no Connected App) | **Human UI login to `ng-dev` and `ng-demo` ≥ every 30 days** (calendar reminder scheduled); login log table started in `metadata-log/ORG_INFO.md` (date, org, who, why); 45-day expiry policy **and the Spring '26 Connected-App restriction** (new orgs cannot create Connected Apps without Support; DE has no standard Support) recorded with Help citation; §3.6 rebuild runbook referenced; CI auth deferred to P1-22 External Client App | P0-01 | Keep-alive section + first log entries in `ORG_INFO.md`; calendar reminder screenshot → `evidence/P0/keepalive.png` | DEVOPS, DOC |
| P0-08 | Licence count + persona matrix | Stop B measurements recorded: **4 Salesforce licences (2 used, 2 free) + 6 Platform** per org (integration + External Identity too); `docs/security/PERMISSION_MATRIX.md` written for the **7-account persona model**: Admin, Sales Rep, Service Advisor, Persona Switcher (Salesforce), Inventory Coordinator, Service Technician (Platform), `dms.integration` (Integration); `Staff__c` roster mapping (14 staff → 6 logins); role tree with *fixed user* / *persona-switcher* / *empty* marks; explicit rule **Login As does not lift licence limits** | P0-01 | Licence screenshot → `evidence/P0/licences.png`; matrix in `PERMISSION_MATRIX.md` | SECURITY, DOC |
| P0-09 | Verify-before-you-build matrix | Every row of checklist §0-E answered yes/no with date (Person Accounts, multi-currency, dup rules, Einstein, Field Service, Omni, Knowledge, Entitlements, Experience, **Agentforce**, **Data Cloud**, **dynamic dashboard limit = 3**, **static resource / FileStorageMB limit (before NG_VehicleImages)**, Territory, Quote/CPQ, Web-to-Lead, CDC, sandboxes, folders) | P0-01 | `docs/VERIFY_RESULTS.md` complete; MASTER_PLAN §4 bucket column updated | ARCH, DOC |
| P0-10 | API version pin + source tracking | `sourceApiVersion` chosen, matches org; retrieve of a known type succeeds or fallback recorded | P0-01 | `sf project retrieve start --metadata CustomObject:Account` output → `evidence/P0/retrieve.txt` | DEVOPS |
| P0-11 | Seed tag decision recorded | Unified **`Seed_Tag__c`** (Text 80, External ID, Unique, conversion mapping off) confirmed as the single seed key for custom + standard objects; recorded in DATA_MODEL §4 | P0-09 | DATA_MODEL §4 marked "decided — v2" | DATA, DOC |
| P0-12 | Baseline snapshot + storage baseline | First full metadata retrieval stored; Storage Usage reading recorded (expect ~0.3 MB baseline) in `SEED_VERSION.txt` | P0-02, P0-10 | `metadata-log/baseline/` exists; storage line in `data/SEED_VERSION.txt` | DEVOPS, DOC |

**Exit gate:** P0-01 … P0-12 done, checklist complete, **owner confirms exit criteria**,
nothing built yet.

---

# Phase 1 — Data model and security foundation

**Purpose:** objects, fields, relationships, users and the security model — everything that
can live in source deploys from source. No automation yet (deliberate layering).

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P1-01 | Core custom objects | 13 objects from source: `Rooftop__c`, `Vehicle_Model__c`, `Vehicle__c`, `Test_Drive__c`, `Trade_In__c`, `Financing__c`, `Service_Visit__c`, `Loyalty_Member__c`, `Loyalty_Transaction__c`, `Delivery__c`, `Consent__c`, **`Staff__c`**, `Data_Load_Batch__c` | P0 exit | `sf project deploy start --dry-run` output → `evidence/P1/deploy_dryrun.txt`; count matches DATA_MODEL §2 | ADMIN, DOC |
| P1-02 | Field set per data model | All fields with correct type, scale, requiredness, help text; `Seed_Tag__c` External ID + Unique on all seeded standard objects | P1-01 | Field inventory vs DATA_MODEL §3 diff → `evidence/P1/field_diff.txt` | ADMIN, DOC |
| P1-03 | Relationships | **Only custom MD:** `Loyalty_Transaction__c → Loyalty_Member__c`; `Vehicle__c → Vehicle_Model__c` is a **required lookup**; `Staff__c` lookups (`Sales_Staff__c`, `Advisor_Staff__c`, `Technician_Staff__c`) | P1-02 | `sf org list sobject describe` output → `evidence/P1/relationships.txt` | ADMIN |
| P1-04 | Picklists, stable API values | Controlled picklists use `Title_Case_With_Underscores` API values; `Term_Months__c` is a **Number** (+ allowed-values VR, P1-16) | P1-02 | API-name audit output → `evidence/P1/picklists.txt` | ADMIN |
| P1-05 | Record types | Lead ×2 (Retail, Fleet), Account ×3 (Household, Business, Dealer_Partner), Opportunity ×2 (Retail, Fleet), Case ×3 (Service, Complaint, Warranty), `Vehicle__c` ×2 (New, Used), `Service_Visit__c` ×1 | P1-04 | Setup screenshot per object → `evidence/P1/record_types/` | ADMIN |
| P1-06 | Page layouts | ≥1 layout per record type; finance-only fields hidden from sales layouts (FLS) | P1-05 | Layout previews → `evidence/P1/layouts/` | ADMIN |
| P1-07 | Apps, tabs, default app, home pages (**seamless UX**) | 13 object tabs; 4 apps — `Northgate Sales`, `Northgate Service`, `Northgate Inventory`, `Northgate Admin` — each with its **own tab list and own home page**; 4 small custom profiles (`NG_Admin`, `NG_Sales`, `NG_Service`, `NG_Inventory`) holding **only default app + tab visibility** (no access grants — DATA_MODEL §6.5); every persona lands in their app with only their tabs | P1-01, P1-15 | Login as each persona → lands in own app, right tabs, home page renders → `evidence/P1/app_landing.png` | ADMIN |
| P1-08 | Role hierarchy | Tree per DATA_MODEL §6.1: fixed users (Admin, Sales Rep, Service Advisor, Inventory Coordinator, Service Technician) + persona-switcher roles (Sales Manager, Finance Manager); empty roles deliberate | P0-08 | Setup → Roles tree screenshot → `evidence/P1/roles.png` | SECURITY |
| P1-09 | OWD posture | Per DATA_MODEL §6.3 set **before any data loads** (Private on Account/Contact/Opp/Case/Lead; `Vehicle__c` Public Read/Write) | P1-01 | OWD table in `PERMISSION_MATRIX.md` + screenshot → `evidence/P1/owd.png` | SECURITY |
| P1-10 | Queues | `Q_Inbound_Leads`, `Q_Service_Intake`, `Q_Finance_Approvals` | P1-01 | Queues selectable as owner in test record → `evidence/P1/queues.png` | SECURITY |
| P1-11 | Permission sets | 6 sets: `PS_Sales_Rep`, `PS_Sales_Manager`, `PS_Finance_Officer`, `PS_Service_Advisor`, `PS_Demo_Admin`, **`PS_Bypass_Load`** (carries custom permission only) | P1-02, P1-13 | FLS matrix: rep cannot see `Financing__c.Annual_Rate__c` → `evidence/P1/fls_matrix.txt` | SECURITY |
| P1-12 | Permission set groups | `PSG_Rep`, `PSG_Manager`, `PSG_Finance`, `PSG_Service` composed of the sets (exactly one active group on the Persona Switcher at a time) | P1-11 | Group assignment on a test user → `evidence/P1/psg.png` | SECURITY |
| P1-13 | Bypass mechanism | Custom permission **`Bypass_Automation`** + hierarchy custom setting **`Automation_Settings__c`** (`Bypass_Validation__c`, `Bypass_Flows__c`, `Bypass_Triggers__c`) created; bypass demo works from Setup | P0-11 | Setting flip changes behaviour in a manual test → `evidence/P1/bypass.png` | ADMIN, ARCH |
| P1-14 | Sharing rules | Cross-rooftop vehicle visibility (native OWD) + service sees vehicles for service accounts | P1-09 | Sharing inspector output → `evidence/P1/sharing.png` | SECURITY |
| P1-15 | Users created | **7 accounts (Stop B: 4 Salesforce + 6 Platform available):** Salesforce — `ngadmin`, `ngrep` (Sales Rep), `ngsvc` (Service Advisor), `ngpersona` (Persona Switcher); Platform — `nginv` (Inventory Coordinator), `ngtech` (Service Technician); Integration — `dms.integration`; real plus-addressed emails; roles + PSGs assigned (`PSG_Rep`/`PSG_Service` permanent, `PSG_Manager`/`PSG_Finance` on `ngpersona`); **never above measured licence count** | P0-08, P1-08, P1-12 | User list screenshot → `evidence/P1/users.png`; activation email received (note only) | ADMIN, SECURITY |
| P1-16 | Validation rules | All **17** rules from DATA_MODEL §9, **always active**, each formula guarded by `AND(NOT($Permission.Bypass_Automation), …)` | P1-13 | Negative test per rule (block + bypass) → `evidence/P1/vr_tests.md` | ADMIN, TEST |
| P1-17 | Duplicate rules + matching | `DR_Contact_Email`, `DR_Lead_EmailPhone`; matching rule on email + lastname; warn mode first | P1-02 | Duplicate flagged on seeded twin records → `evidence/P1/dup_rule.png` | DATA, ADMIN |
| P1-18 | Custom metadata types | 4 types: `Price_Rule__mdt`, `Rate_Table__mdt`, `Loyalty_Tier__mdt`, `Lead_Routing__mdt` (business rules only — bypass lives in P1-13) | P1-01 | Types visible in Setup; deploy output → `evidence/P1/mdt.txt` | ARCH, ADMIN |
| P1-19 | Security matrix finalised | `PERMISSION_MATRIX.md`: object × PS × FLS × roles × personas, matching what was actually built | P1-01…P1-17 | Matrix reviewed against org → `evidence/P1/matrix_review.md` | SECURITY, DOC |
| P1-20 | **`VinValidator` Apex** | Check-digit validator (ISO 3779 mod-11) writes `Is_VIN_Valid__c`; before-save wiring; VR keeps only length/charset (formula size limit) | P1-02, P1-16 | Tests: valid VINs true, 10 fixture VINs false → `evidence/P1/vin_tests.txt` | APEX, TEST |
| P1-21 | **Persona switch script** | `scripts/persona.sh <manager\|finance>` swaps `ngpersona`'s role and assigns exactly one of `PSG_Manager`/`PSG_Finance`; prints active persona; touches no users, licences or profiles; idempotent | P1-08, P1-12, P1-15 | Script output per persona + matching view-as screenshot → `evidence/P1/persona_switch.txt` | SECURITY, DEVOPS |
| P1-22 | **External Client App for CI** | External Client App with JWT bearer flow (owner creates the app or signs off on creation; consumer key stored as GitHub secret only); CI validate workflow (P0-04) enabled; **documented: CI logins not assumed to reset expiry timer** | P0-04, P1-15 | Green CI run → `evidence/P1/ci_run.txt`; key appears only as a secret | DEVOPS |

**Exit gate:** deploy clean, P1-16 + P1-20 negative tests pass, P1-19 matrix matches reality, P1-21 persona switch verified for all four personas.

---

# Phase 2 — First end-to-end vertical slice

**Purpose:** one thin but complete path — web lead → qualification → test drive → opportunity —
with automation, reports and tests. First demoable state.

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P2-01 | Lead intake assignment | `Lead_Enrich_Rooftop` flow routes by Ontario **FSA prefix** (`Lead_Routing__mdt`: `M*`/`L4H*`/`L5V*`/`L1G*`), round-robin within rooftop | P1-18 | 10 test leads distribute ≈80/20 → `evidence/P2/lead_routing.png` | FLOW, ADMIN |
| P2-02 | Lead conversion guidance | Layout + Flow nudge conversion hygiene (account, contact, opp); `Seed_Tag__c` not mapped during conversion | P1-05, P1-06 | Converting a lead produces Account+Contact+Opp, seed tag absent on children → `evidence/P2/conversion.png` | FLOW, ADMIN |
| P2-03 | Test-drive screen flow | `TestDrive_Book_Screen`: select vehicle, contact, date/time; conflict check blocks double-booking | P2-04 | Booking an occupied slot rejected with clear message → `evidence/P2/testdrive_conflict.png` | FLOW, APEX |
| P2-04 | Conflict-check subflow + Apex | Overlap query subflow (fast path) + before-save guard; documented limitation in `TECH_DEBT.md` if race remains | P1-13 | Test class covers conflict + free-slot cases → `evidence/P2/conflict_tests.txt` | APEX, TEST |
| P2-05 | Opportunity stage model | 8 stages exactly as DATA_MODEL §7; `Opportunity_Stage_Stamp` updates `Stage_Last_Changed__c`/`Previous_Stage__c` | P1-04, P1-06 | Stage picklist matches data model; field updates on change → `evidence/P2/stages.png` | FLOW, ADMIN |
| P2-06 | Vehicle reservation logic | Reserving sets `Status__c = Reserved`; duplicate reservation blocked (flow) | P1-01 | Second reserve attempt fails → `evidence/P2/reserve_block.png` | FLOW, APEX, TEST |
| P2-07 | Task auto-creation | Follow-up Task on lead assignment and on opp stage → `Test_Drive` | P2-01, P2-05 | Task appears with correct owner/due date → `evidence/P2/tasks.png` | FLOW, ADMIN |
| P2-08 | Email alert | `ET_Sales_TestDriveConfirm` on test-drive confirmation | P2-03, P0-06 | Email received at plus-addressed inbox → `evidence/P2/confirm_email.png` | ADMIN, FLOW |
| P2-09 | Report: pipeline by stage | Summary report in `01_Pipeline`, grouped by stage and owner-staff | P2-05 | Report run returns seeded rows → `evidence/P2/rpt_pipeline.png` | REPORT |
| P2-10 | Report: lead source effectiveness | By `LeadSource` with conversion rate | P2-01 | Report renders source breakdown → `evidence/P2/rpt_leadsource.png` | REPORT |
| P2-11 | Dashboard: sales snapshot (**dynamic #1 of 3**) | `DM_Sales_PipelineSnapshot`, 3 components, **dynamic by role** | P2-09, P2-10 | Rep vs manager views differ → `evidence/P2/dash_pipeline_*.png` | REPORT, SECURITY |
| P2-12 | Flow-maintained counters v1 | `Vehicle_Counter_Flow` (rooftop + model counts) and `TestDrive_Counter_Flow` — pattern proven per DATA_MODEL §5.3 | P1-01, P1-13 | Counter updates on insert/status change; unit test asserts recompute → `evidence/P2/counters_test.txt` | FLOW, TEST |
| P2-13 | Apex test suite v1 | `TestDataFactory` + tests for P2-04, P2-06 at ≥90% incl. 200-row bulk test | P2-04, P2-06 | `sf apex run test` output → `evidence/P2/tests.txt` | APEX, TEST |
| P2-14 | UAT script for slice | `evidence/UAT/UAT_P2.md`, numbered steps + screenshot slots | P2-01…P2-13 | Completed UAT with screenshots → `evidence/P2/uat/` | DOC, TEST |
| P2-15 | Demo script v1 | `evidence/DEMO_SCRIPTS/01_lead_to_testdrive.md` — opens with **"Activate persona"** step (log in as `ngrep`, or `scripts/persona.sh <manager>` for manager views) | P2-14, P1-21 | Script runs <5 min, no dead ends → `evidence/P2/demo_run.png` | DOC |

**Exit gate:** the whole slice can be performed live by a stranger following the demo script.

---

# Milestone M1 gate (Foundation)

Deploy `--dry-run` clean → tests ≥90% → release-gate DQ checks 0 rows → regression checklist
green → UAT_P2 signed → screenshots in `evidence/P2_CoreLifecycle/` → tag `demo/v0.1`.

---

# Phase 3 — Trade-in, quoting and pricing (simulated CPQ)

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P3-01 | Trade-in appraisal screen flow | Wizard captures vehicle, odometer, condition, payoff; `TradeIn_Calc_Equity` computes equity | P1-01 | Equity correct on 5 cases incl. negative → `evidence/P3/equity_test.md` | FLOW, APEX |
| P3-02 | Appraisal-before-quote gate | **`Quote_Before_Create_Flow`** queries child trade-in status and blocks quote while ≠ `Accepted` (a VR cannot query — DATA_MODEL §9) | P3-01, P3-04 | Quote attempt without appraisal rejected → `evidence/P3/appraisal_gate.png` | FLOW, ADMIN |
| P3-03 | `Price_Rule__mdt` records | ≥10 rules: trim premium, aged-inventory discount, loyalty discount, fleet threshold, holiday promo | P1-18 | Metadata deploys from source; visible in Setup → `evidence/P3/pricerules.png` | ARCH, ADMIN |
| P3-04 | Quote from opportunity | Standard `Quote` via Flow with lines from `PricebookEntry` | P1-06, P2-05 | Quote + line items populate; totals reconcile → `evidence/P3/quote.png` | FLOW, ADMIN |
| P3-05 | Price rule application (Apex) | `QuotePricingService` applies metadata rules in precedence order | P3-03, P3-04 | Unit tests: 10 scenarios + precedence + boundary → `evidence/P3/pricing_tests.txt` | APEX, TEST |
| P3-06 | Discount approval process | `Opportunity_Discount_Approval` (>5–10% manager) + `Opportunity.VP_Discount_Approval` (>10% VP): criteria-miss final-approves, so each tier has its own process | P1-12 | Manager cannot self-approve >10%; denial captured → `evidence/P3/approval.png` | FLOW, SECURITY |
| P3-07 | Quote document generation | Printable quote summary (LWC + standard Quote PDF per DATA_MODEL §11-3) | P3-05 | PDF renders line items, discount, totals → `evidence/P3/quote_pdf.png` | APEX, ADMIN |
| P3-08 | Quote validity + stale-quote report | `Quote_Valid_Until__c` drives data-quality report | P3-04 | Expired open quotes appear in `05_DataQuality` → `evidence/P3/rpt_stale_quotes.png` | REPORT, DATA |
| P3-09 | Reports: discount leakage, win/loss | Two reports in `01_Pipeline` | P2-09 | Correct aggregates → `evidence/P3/rpt_discount_winloss.png` | REPORT |
| P3-10 | Dashboard: quote health | Win rate, avg discount %, quote ageing (**fixed user**) | P3-09 | Components tie to report values → `evidence/P3/dash_quote.png` | REPORT |
| P3-11 | Seam note for CPQ | `docs/architecture/SIMULATION_CPQ.md`: real CPQ vs built, honest seam label | P3-05 | Doc exists, referenced from MASTER_PLAN §4.4 → `docs/architecture/SIMULATION_CPQ.md` | ARCH, DOC |
| P3-12 | Tests for pricing | ≥90% on `QuotePricingService`, bulk + negative paths | P3-05 | Test gate output → `evidence/P3/pricing_gate.txt` | APEX, TEST |

### Defect register

| ID | Defect | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P3-DEF-01 | `QuoteBuilderController.createQuote` overwrites `Opportunity.Discount_Percent__c` and `Opportunity.Approval_Status__c` on every save, including when a pending approval or another quote already exists. Incident: 2026-10-20 second quote at 1.00% replaced the pending 8.92% approval's displayed values. | `createQuote` cannot create a quote or stamp the Opportunity when the Opportunity already has a quote; a blocked pricing result cannot stamp; regression test proves the pending 8.92% approval remains unchanged after a second save attempt. **Status: backlog. Not approved for deployment.** | P3-05, P3-06 | `evidence/UAT/live_2026-10-19/manager_record_correction_2026-10-20.md`; proposed diff `docs/planning/P3-DEF-01_QUOTE_OVERWRITE_FIX.md` | APEX, TEST, SECURITY |

**Exit gate:** a deal can be appraised, quoted, priced by rule, approved, and reported on.

---

# Phase 4 — Financing, approval and delivery

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P4-01 | Payment calculator service | Amortisation: principal, `Annual_Rate__c`, term → monthly payment, correct to the cent | P1-01 | Tests assert known-good values (0%, standard, high rate) → `evidence/P4/calc_tests.txt` | APEX, TEST |
| P4-02 | Finance application screen flow | Captures amount, term (Number, allowed values), rate, credit tier, co-signer; live payment | P4-01 | Payment updates as inputs change → `evidence/P4/finance_wizard.png` | FLOW, APEX |
| P4-03 | Financing status lifecycle | `Financing_Status_Flow` enforces `Draft → Submitted → Conditional → Approved → Declined → Funded`, writes `Previous_Status__c`; `VR_Financing_FundedRequiresApproved` blocks invalid jumps | P1-16, P1-13 | Invalid transition blocked in test → `evidence/P4/status_block.png` | FLOW, ADMIN |
| P4-04 | Credit tier → rate mapping | `Rate_Table__mdt` drives rate selection (`Rate_Source__c = Rate_Table` vs `Manual_Exception`) | P1-18, P4-01 | Mapping respected; test covers each tier → `evidence/P4/rate_tests.txt` | ARCH, APEX |
| P4-05 | Finance approval record path | Approval for exceptions (sub-prime > threshold) routes to Finance Manager | P4-03, P1-12 | Exception routes correctly → `evidence/P4/finance_approval.png` | FLOW, SECURITY |
| P4-06 | Delivery / handoff checklist | `Delivery__c` document/inspection/signature checkpoints; `VR_Delivery_ChecklistBeforeCompleted` enforces | P1-16 | Cannot complete with open checkpoint → `evidence/P4/checklist_block.png` | FLOW, ADMIN |
| P4-07 | Delivery closes the opportunity | `Delivery_Close_Flow` sets Closed Won, stamps `Delivery_Date__c`, sets **`Delivery_Completed__c = TRUE`**; `VR_Opportunity_ClosedWonNeedsDelivery` checks the flag | P4-06, P2-05 | Opp reflects delivery; VR blocks Closed Won without flag → `evidence/P4/closedwon_gate.png` | FLOW, TEST |
| P4-08 | Loyalty enrolment on delivery | `Loyalty_Member__c` auto-created at delivery (0 balance, correct contact) | P4-07 | Member exists with correct links → `evidence/P4/loyalty_enrol.png` | FLOW, APEX |
| P4-09 | Reports: financing mix, funding lag | Reports in `01_Pipeline` / `05_DataQuality` | P4-03 | Aggregates correct → `evidence/P4/rpt_finance.png` | REPORT |
| P4-10 | Dashboard: deal desk | Approvals pending, avg days to fund, declined % (**fixed user**) | P4-09 | Components tie to reports → `evidence/P4/dash_dealdesk.png` | REPORT |
| P4-11 | Finance FLS enforcement test | Negative test: sales rep cannot read `Financing__c.Annual_Rate__c` | P1-11 | Access denied captured → `evidence/P4/fls_denied.png` | SECURITY, TEST |
| P4-12 | Seam note for finance/billing | `docs/architecture/SIMULATION_FINANCE.md` labels what a paid billing product would add | P4-05 | Doc exists → `docs/architecture/SIMULATION_FINANCE.md` | ARCH, DOC |
| P4-13 | Tests | ≥90% across calculator, delivery, enrolment | P4-01, P4-07, P4-08 | Test gate output → `evidence/P4/tests.txt` | APEX, TEST |

**Status (Phase 4 closure — 2026-10-16):** **P4-01..P4-09 DONE** (accepted and closed). Evidence recorded in `NORTHGATE_PROJECT_HANDOFF.md` §11 and §12. Deploy jobs in `ng-dev` only: P4-01 (`0Afg800000HLNvtCAH`, 5/5), P4-03 (`0Afg800000HPct7CAD`, 18/18), P4-04 (`0Afg800000HPAATCA5`, 5/5), P4-02 + applicant fix (`0Afg800000HTcCzCAL` + `0Afg800000HTGlyCAH` + `0Afg800000HT52YCAT`, 20/20 then 16/16; browser-verified by owner — financing record `a03g800000rzfMHAAY`, Amount $30,340, Monthly $579.39, Total Interest $4,423.40), P4-05 field rename (`0Afg800000Hcdt4CAB`, 1/1), P4-05 Workflow + ApprovalProcess (`0Afg800000HdzWTCAZ`, 5/5, 156/156 tests, approval ACTIVE in `ng-dev`, owner browser-verified approval + workflow write-back), P4-08 late-Buyer fix (`0Afg800000HeoZ0CAJ`, 2/2, 160/160 tests), P4-08 one-time loyalty backfill (Loyalty Member `a04g8000002slf7AAA`, Member Number `NG-7904-0782`, Contact P1-14Test, Active/Bronze/0, single membership). **P4-10, P4-11, P4-12, P4-13** are NOT done (still backlog). The M2 exit gate ("full retail deal runs from lead to delivered vehicle with financing, approvals and loyalty enrolment") is **met** by P4-01..P4-09 in `ng-dev`. CP2 pricing and Phase 3 approvals remain unchanged and verified intact. The P4-04 LTV eligibility is still Draft-only (true LTV source and valuation tool remain a Phase 5+ decision).

**Exit gate:** a full retail deal runs from lead to delivered vehicle with financing, approvals
and loyalty enrolment. **GATE MET** (see closure record above).

---

# Milestone M2 gate (Core lifecycle)

Deploy clean → tests ≥90% → release-gate DQ checks 0 rows → regression green → UAT_P3+P4
signed → screenshots → synthetic data loaded (Phase 5) → tag `demo/v0.2`.

---

# Phase 5 — Synthetic data load and reporting depth

**Storage rule:** the envelope in `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §2.1 is binding —
**3.93 MB total, ≤4.0 MB after every load**, burst set only per §2.7.

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P5-01 | Generator built | `data/scripts/generate.ts` deterministic; **`ANCHOR_DATE` parameter stored in `SEED_VERSION.txt`**; writes `data/csv/*.csv` | P0-11 | Two runs, same anchor → byte-identical CSVs (checksum) → `evidence/P5/determinism.txt` | DATA, TEST |
| P5-02 | Loader built | `data/scripts/load.ts`: `sf data upsert bulk --external-id Seed_Tag__c` in §4 dependency order using **external-ID relationship columns** (no ID-resolution pass; owner refs mapped by username); bypass grant/revoke handled; **re-runnable (idempotent)** | P5-01, P1-13, P1-15 | Load twice → identical counts → `evidence/P5/idempotency.txt` | DATA, DEVOPS |
| P5-03 | Seed data loaded | All volumes from data plan §2.1 (governing 1,835 clean + 30 legacy + 250 activities = 2,115; historical 2,123 = prior Product2 40 / Delivery 40 allocations, superseded 2026-10-20) | P5-02 | Counts match table exactly; Storage Usage ≤4.0 MB → `evidence/P5/storage.png`, `evidence/P5/counts.txt` | DATA |
| P5-04 | Referential integrity verified | Zero orphan records across lookups/MD | P5-03 | Integrity query returns 0 → `evidence/P5/integrity.txt` | DATA, TEST |
| P5-05 | `Data_Load_Batch__c` ledger + `SEED_VERSION.txt` | One row per batch: version, counts, timestamps, status, anchor date, storage reading | P5-03 | Ledger matches `SEED_VERSION.txt` → `evidence/P5/ledger.png` | DATA, DOC |
| P5-06 | Edge-case records (`SEED-99`) | All BAD-01…10 present at scaled counts (data plan §7.1), separably resettable | P5-03 | §9b demo-finding counts match expected → `evidence/P5/bad_counts.txt` | DATA |
| P5-07 | **Legacy DQ batch (`SEED-98`)** | 30 schema-invalid rows (10 phones, 8 postal, 6 VINs, 6 emails) loaded with bypass on, then bypass revoked; labelled fixture in `docs/DATA_QUALITY.md` | P5-02, P5-03 | Bypass grant/revoke logged; 30 rows verified → `evidence/P5/seed98.png` | DATA, DOC |
| P5-08 | Release-gate DQ checks | Data plan §9a (14 checks, must be 0) automated in `scripts/verify.sh` | P5-03 | `verify.sh` PASS output → `evidence/P5/verify_gates.txt` | DATA, DEVOPS |
| P5-09 | Demo-finding DQ reports | Data plan §9b (8 checks at **expected counts**) as reports in `05_DataQuality` | P5-06, P5-07 | Counts drift-test (delete one row → report alarms) → `evidence/P5/demo_findings.png` | DATA, REPORT |
| P5-10 | Report: inventory aging >60/120 days | Grouped by rooftop and make | P5-03 | Counts match distribution → `evidence/P5/rpt_aging.png` | REPORT |
| P5-11 | Report: service SLA / overdue visits | Overdue = scheduled in past, not completed | P5-06 | Overdue count = 12 (BAD-04) → `evidence/P5/rpt_sla.png` | REPORT |
| P5-12 | Report: loyalty tier distribution | Members by tier with balances; grouped by **Staff__c** where relevant | P5-03 | Distribution matches plan (39/18/9/4) → `evidence/P5/rpt_loyalty.png` | REPORT |
| P5-13 | Report: duplicate audit | Duplicate contacts + malformed-email findings (BAD-01 + SEED-98) | P5-06, P5-07 | Counts match 8 pairs / 6 emails → `evidence/P5/rpt_dupes.png` | REPORT |
| P5-14 | Executive dashboard (**dynamic #2 of 3**) | `DM_Exec_OperationsOverview`: pipeline, aging, service SLA, loyalty, CSI proxy; **dynamic by role** | P5-10…P5-13 | Two personas see different scope → `evidence/P5/dash_exec_*.png` | REPORT, SECURITY |
| P5-15 | Manager dashboards (fixed user) | `DM_Sales_*`, `DM_Service_*`, `DM_Finance_*` as **fixed-user** dashboards (dynamic cap = 3) | P5-14 | Each renders correctly as fixed user → `evidence/P5/dash_managers.png` | REPORT |
| P5-16 | Custom report types | ≥3 (Vehicle + Test Drive, Contact + Loyalty, Service Visit + Case) | P5-03 | Report types usable in builder → `evidence/P5/crts.png` | REPORT, ADMIN |
| P5-17 | Reset script | `scripts/reset.sh`: delete `Seed_Tag__c LIKE 'SEED-%'` child-first → **empty Recycle Bin** → reload → **Storage Usage check (≤4.0 MB)** | P5-02 | Dry-run order correct; full reset + reload on ng-dev → `evidence/P5/reset_run.txt` | DATA, DEVOPS |
| P5-18 | Snapshot-before-reset enforced | Script refuses without a fresh snapshot | P5-17 | Forced refusal test → `evidence/P5/reset_refusal.png` | DATA, TEST |
| P5-19 | Burst set protocol | `SEED-77-BURST-*` load → volume screenshot → delete → **Recycle Bin purge** → storage back to 3.93 MB | P5-03, P5-17 | Before/after storage screenshots → `evidence/P5/burst_*.png` | DATA, DOC |
| P5-20 | Data plan doc marked loaded | `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` status updated with version + date | P5-08, P5-09 | Doc reflects actual state → git diff | DOC |

**Exit gate:** org holds a full, consistent, edge-case-rich dataset under 4.0 MB and every
dashboard tells a true story.

## Expedited Phase 5 closure — owner accepted with documented exceptions, 2026-10-23

**Status: ACCEPTED WITH DOCUMENTED EXCEPTIONS by the owner on October 23, 2026.**
The owner separately authorized Phase 6 planning, not feature implementation. All original
P5-01 through P5-20 criteria above remain intact. Acceptance of the limitations below is
not evidence that deferred tests or corrections were performed. The earlier closure candidate
required a VP browser checkpoint; the owner's acceptance now supersedes that exit hold while
retaining the known CSI display discrepancy and remaining persona/browser evidence limitations.
There was no reload, reset, drift deletion, burst, historical correction, or new broad audit.

Activation and preservation evidence, security decisions, and the next-phase boundary are in
`docs/planning/P5_TO_P6_HANDOFF_2026-10-23.md`. Earlier execution results remain historical
evidence; the new entry does not rewrite them or reopen completed CP2, Quote, Test Drive, or
Financing functionality.

| ID | Closure classification | Evidence or precise exception | Follow-up owner | Impact and recommended future phase |
|---|---|---|---|---|
| P5-01 | COMPLETE | Existing `evidence/P5/local_preparation_2026-10-20.md` records two same-anchor runs and comparison of all 30 CSV hashes. No new run is claimed. | Data owner | Preserve the recorded seed/anchor; archive reproducible source with P7 governance. |
| P5-02 | ACCEPT WITH EXCEPTION | Loader and live seed exist; a clean second-load/idempotency acceptance run is not established by the latest execution report. | Data owner | Repeatability is not fully certified; defer rehearsal to P7 DevOps, not an unapproved live reload. |
| P5-03 | ACCEPT WITH EXCEPTION | Seed and supplemental fixtures are present. Exact original volumes and precise <=4.0 MB storage are not newly certified; approved UAT rows and one operational metrics row are separate from canonical seed counts. | Owner and data owner | Defer extra screenshots/count corrections. Check actual headroom before any future P6 data expansion. |
| P5-04 | ACCEPT WITH EXCEPTION | Existing dependency-clean operations and functional tests are evidence, but a complete lookup/master-detail/polymorphic orphan artifact is still missing. No new orphan defect was demonstrated. | Data/test owner | Complete read-only integrity evidence with P7 regression and before P8 external access. |
| P5-05 | ACCEPT WITH EXCEPTION | Historical per-batch storage/timestamps and 37-job/20-placeholder reconciliation remain incomplete. Do not fabricate timestamps or change historical ledger rows to imply verification. | Data owner | Keep the provenance limitation explicit; record genuine evidence for future batches under P7 governance. |
| P5-06 | ACCEPT WITH EXCEPTION | BAD fixtures are partially evidenced; exact expected counts, including stacked-quote examples, are not all reconciled. | Data/demo owner | Defer optional fixture/count corrections to an approved P6/P7 data-maintenance window; preserve Quotes and history. |
| P5-07 | ACCEPT WITH EXCEPTION | The 2026-10-21 report verifies 24 legacy Contacts and 6 Trade-Ins. That import required no bypass, so the original bypass-on/off loading procedure is not claimed as executed. | Data owner | Accept the loaded fixture evidence with this method difference; no reimport solely to manufacture evidence. |
| P5-08 | ACCEPT WITH EXCEPTION | Historical 14-gate PASS evidence exists, but latest post-cleanup full-gate acceptance is not re-established. Recent focused deployment suites are not substitutes for all data gates. | Test owner | Defer nonessential repeat testing; integrate a current gate artifact into P7-17 before release packaging. |
| P5-09 | ACCEPT WITH EXCEPTION | Finding reports and offline drift-alarm tests exist; live delete-one-row drift acceptance was not performed. | Data/test owner | Defer destructive drift rehearsal to a separately approved P7 test window. |
| P5-10 | ACCEPT WITH EXCEPTION | Inventory dashboard observation is 120 aged vehicles, not the original targeted distribution. No acquisition dates were rewritten. | Data/demo owner | Preserve truthful time-dependent results; optional date/count normalization belongs to a later approved data refresh. |
| P5-11 | ACCEPT WITH EXCEPTION | Exact operational filter is Scheduled and start before TODAY. Read-only reconciliation proves 13 at the 2026-10-21 Toronto cutoff and 14 at the 2026-10-22 cutoff; original target 12 is not forced. Initial aggregate capture stores 14. | Data/demo owner | Treat calendar drift as documented, not a defect; refresh metrics only on separate publication authorization. |
| P5-12 | ACCEPT WITH EXCEPTION | Canonical tier distribution has prior evidence; live total 72 includes approved UAT members. Full live/canonical comparison and additional screenshots are deferred. | Data/report owner | No member/balance correction now; distinguish UAT population from canonical counts in P6/P7 reporting. |
| P5-13 | ACCEPT WITH EXCEPTION | Household report detects 8 pairs and legacy malformed-email fixtures are loaded; native DuplicateRecordSet evidence was zero in the execution report. | Data owner | Accept report-based detection as an explicit exception; do not add more duplicates to force rule-hit evidence. |
| P5-14 | ACCEPT WITH EXCEPTION | Deployment, 7/7 tests, VP assignment and initial source-matched capture are verified. Owner reports CSI displays 0 rather than N/A with zero responses; this discrepancy is explicitly accepted, not fixed. Earlier agent browser attempt reached login; remaining comparative/persona evidence is not claimed complete. | Reporting owner; owner for future browser acceptance | Follow up on CSI/null display and remaining evidence in a separately approved reporting/polish window (P7). No display or publisher change is part of P6-01. |
| P5-15 | ACCEPT WITH EXCEPTION | Existing controlled UAT records Sales rendering PASS and Service/Finance drill-through gaps. These are not claimed repaired by the executive-only permission set. | Owner and reporting/security owner | Defer targeted acceptance to authorized Service/Finance contexts in P6/P7; no operational or Finance permissions added to VP as a workaround. |
| P5-16 | ACCEPT WITH EXCEPTION | Joined report types have deployment evidence; report-builder usability/screenshots are not newly demonstrated. | Report owner | Defer the additional builder proof to P7 documentation; do not claim an unperformed browser test. |
| P5-17 | ACCEPT WITH EXCEPTION | Reset planning exists; full delete/purge/reload executor and original reset rehearsal remain unimplemented/unverified. The original ng-dev test target is outside current authorization. | Owner and DevOps owner | P7 DevOps work requires a separate destructive-operation plan and target authorization. No reset now. |
| P5-18 | COMPLETE | Existing offline `test_snapshot_refusals` evidence passes. This completes the refusal check, not the full reset executor or rehearsal covered by P5-17. | DevOps owner | Preserve the guard and repeat integration coverage when P5-17 is implemented. |
| P5-19 | ACCEPT WITH EXCEPTION | Burst planner exists; load/purge and precise return to 3.93 MB are not demonstrated. | Owner and DevOps owner | Defer capacity rehearsal to P7; no optional burst against constrained live storage now. |
| P5-20 | COMPLETE | Data-plan status records seed version, load dates, explicit exceptions and the October 23 owner acceptance. It does not certify exact counts/storage or repair historical markers. | Documentation/data owner | Keep documentation truthful as future approved loads occur. |

### Cross-cutting exceptions and transition gate

- CSI displays 0 rather than the intended N/A when there are no scored responses. The
  stored zero response count does not establish a zero satisfaction score. This owner-reported
  UI discrepancy is accepted with exception; its rendering cause was not diagnosed or repaired.
  Ownership: reporting owner. Follow-up: separately approved P7 reporting/polish work.
- Dedicated Finance-user acceptance remains blocked by full Salesforce license capacity.
  Sales and Finance remain separate. The primary and Backup Admin accounts must be preserved;
  reclaiming either is not authorized. Ownership: owner/licensing administrator. Impact:
  dedicated Finance-session acceptance is deferred, not financing-calculation functionality.
  Revisit with P6 persona readiness/P7 security governance when compliant capacity is available.
- Publisher scheduling is not approved. The single successful capture is dated
  `2026-10-23T16:16:17Z`; reports intentionally suppress metric values after 24 hours.
  A dashboard refresh does not publish new Service data. Ownership: owner/operations.
  Consider a separately approved refresh policy during P6 operational readiness; do not
  create a job automatically or treat stale metrics as current.
- The remaining sample Account/Entitlement cleanup decision is retained as a data-hygiene
  exception. Ownership: data owner. Impact: nonessential sample residue, not a new functional
  blocker. Any later deletion requires exact-record approval.
- Missing source provenance, extra screenshots, cosmetic polish, historical reconciliation,
  optional count corrections, reset enhancements, and burst tests remain deferred obligations,
  not silently deleted requirements or passing evidence.
- Finance and Service operational-persona acceptance remains pending. Do not use the VP's
  metrics-only access as evidence of Service Advisor or Finance Officer acceptance. Ownership:
  owner/licensing and test owners; follow-up: P6 persona readiness/P7 security governance.
- Phase 5 owner acceptance is recorded. The owner authorizes focused P6-01 planning with
  P6-02 next; no Phase 6 feature implementation, deployment, data write, permission assignment
  or scheduling is authorized yet. P5 exceptions remain tracked and are not prerequisites
  to repeat completed functionality. Obtain a separate bounded implementation approval.

---

# Phase 6 — Service, cases and post-sale

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P6-01 | Service capacity enforcement (Apex) | Before-save `ServiceVisitTrigger` → `ServiceVisitCapacityGuard` enforces the approved daily capacity policy against `Rooftop__c.Service_Capacity__c`; existing `VR_ServiceVisit_FutureForNew` remains unchanged | P1-16; capacity-policy confirmation | Over-capacity booking rejected → `evidence/P6/capacity_block.png`; focused bulk/security/boundary tests | APEX, TEST |
| P6-02 | Service intake Case creation/routing (Apex) | After-insert service creates the linked Case and routes to `Q_Service_Intake`, reusing the Service trigger; no new Flow | P6-01, P1-10 | Case owner is the queue → `evidence/P6/case_queue.png` | APEX, ADMIN, TEST |
| P6-03 | Escalation rules | `ER_Case_HighPriority_4h` escalates unanswered high-priority cases; stamps `Escalated_On__c` | P6-02 | Escalation fires in controlled test → `evidence/P6/escalation.png` | FLOW, ADMIN |
| P6-04 | Case → service history linkage | Case links vehicle, contact, prior visits | P6-02 | Timeline shows complete history → `evidence/P6/case_timeline.png` | ADMIN |
| P6-05 | Service history on vehicle | Vehicle shows visits + cases + mileage over time | P6-04 | Related lists populated from seed → `evidence/P6/vehicle_history.png` | ADMIN, REPORT |
| P6-06 | Loyalty accrual engine | Points on service spend + vehicle sale, rules from `Loyalty_Tier__mdt`/config | P4-08 | Accrual test asserts point maths per rule → `evidence/P6/accrual_tests.txt` | APEX, TEST |
| P6-07 | Tier evaluation batch | `LoyaltyTierEvalBatch` re-evaluates tiers nightly | P6-06 | `Test.stopTest()` asserts tier moves → `evidence/P6/tier_batch.txt` | APEX, TEST |
| P6-08 | Redemption + expiry | Redemption decrements balance; `Loyalty_ExpiryBatch` removes expired points; `VR_Loyalty_NonNegativeBalance` holds | P6-06, P1-16 | Negative balance prevented → `evidence/P6/redemption_test.txt` | APEX, FLOW, TEST |
| P6-09 | Dashboards: loyalty + service ops (**dynamic #3 of 3**) | Loyalty tier mix/liability (fixed); `DM_Service_Operations` **dynamic by role** — this is the third and last dynamic dashboard | P6-05…P6-08 | Advisor vs manager scope differs → `evidence/P6/dash_service_*.png` | REPORT, SECURITY |
| P6-10 | Seam note for Loyalty Management | `docs/architecture/SIMULATION_LOYALTY.md` | P6-06 | Labels simulation vs licensed product → `docs/architecture/SIMULATION_LOYALTY.md` | ARCH, DOC |
| P6-11 | Repeat-purchase signal | Report: contacts with service + new opportunity | P5-12 | Report returns seed repeat buyers → `evidence/P6/rpt_repeat.png` | REPORT |
| P6-12 | Consent + nurture simulation | `Consent__c` + `Consent_Gate_Flow` gates campaign membership | P6-06, P1-17 | Non-consented contact excluded → `evidence/P6/consent_gate.png` | FLOW, ADMIN |
| P6-13 | Seam note for Marketing Cloud | `docs/architecture/SIMULATION_NURTURE.md` | P6-12 | Labels simulation → doc exists | ARCH, DOC |
| P6-14 | **Entitlements + Milestones** | Entitlement on Cases (e.g. "Platinum Care: first response 4h, resolution 48h"); milestone process visible on case layout; SLA breach report | P0-09 (verify row), P6-02 | Milestone timer runs; breach report → `evidence/P6/milestones.png` | ADMIN, REPORT |
| P6-15 | **Knowledge** | ~10 articles (service FAQs, buying guides, financing explainer) in a Knowledge category, linked to cases | P6-02 | Articles searchable + attached to a case → `evidence/P6/knowledge.png` | ADMIN, DOC |
| P6-16 | Service + sales console coexistence | Service Console app (if verified) + sales app usable by a dual-role persona | P1-07, P0-09 | Console navigation verified → `evidence/P6/console.png` | ADMIN |
| P6-17 | Tests | ≥90% on accrual, tier batch, redemption, capacity flow | P6-01, P6-06…P6-08 | Test gate output → `evidence/P6/tests.txt` | APEX, TEST |

**Batch 1 deployment (P6-01–P6-04):** Quick Deploy `0Afaj00000owPUHCA2` succeeded at
2026-10-24T02:42:00Z, 14/14 components. Stored validation `0Afaj00000ovK6sCAE` passed 33/33
tests; Quick Deploy did not rerun tests. Original acceptance rows remain intact and are not
marked done. Owner live acceptance is deferred: Service persona/browser and capacity contention,
four-hour native escalation/notification/history, separately approved timestamp reconciliation,
and page activation/history evidence remain pending. Missing-event/same-owner/no-rule-attribution
limits apply; no atomic timestamp or live timer acceptance is claimed. Existing eight Standard
entries remain preserved. The rejected Case related-list layout addition was not deployed.

**Batch 2 local execution (P6-05–P6-08):** one consolidated plan is in
`docs/planning/P6_BATCH2_IMPLEMENTATION_PLAN_2026-10-24.md`; recommended implementation order
is P6-05, P6-06, P6-07, P6-08, with shared ledger/locking foundations and one release package.
Existing loyalty schema/enrollment is present, but the live tier metadata table is empty and
historical stored balances do not reconcile to the ledger without source links or expiry dates. No historical
balance correction/backfill is authorized. The subsequent autonomous local/check-only authorization selected configurable
provisional D1–D6 defaults and completed local work; final check-only `0Afaj00000oyOkDCAU` passed
58/58 components and 108/108 tests. Subsequently, owner-approved Quick Deploy
`0Afaj00000oya5SCAQ` succeeded at 2026-10-24T12:05:50Z. Live owner acceptance remains pending.
Program remains inactive; no historical balance repair, live processing, assignment, job or page activation occurred.
Actual source scope/results are in `evidence/P6/BATCH2_EXECUTION_2026-10-24.md` and handoff §26.
The no-new-project-owned-Flows direction remains authoritative; historical FLOW labels above
do not require new Flows. Batch 1 design history remains in its existing October 23 plans and
latest deployment/acceptance obligations in `NORTHGATE_PROJECT_HANDOFF.md` §25.

**Batch 3 validation and deployment (P6-09–P6-12):** exact stored scope corresponds to
`manifest/p6-batch3-check.xml`; Quick Deploy did not rebuild this package.
CONFIRMED — final raw check-only output excerpts:

```json
"id": "0Afaj00000p15t7CAA",
"status": "Succeeded",
"checkOnly": true,
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestErrors": 0,
"numberTestsCompleted": 119,
"numberTestsTotal": 119,
"codeCoverageWarnings": []
```

Focused validation passed 11/11 new methods; the final coordinated check includes 108 existing
regression methods. All new production Apex has zero uncovered executable lines. Evidence:
`evidence/P6/BATCH3_EXECUTION_2026-10-24.md`; latest handoff §28. These rows remain pending
live acceptance, not done solely from validation or deployment success:

- P6-09: new viewer-scoped Service and fixed-user Loyalty dashboards/reports/folders validate.
  The historical "dynamic #3 of 3" assumption is superseded by four pre-existing dynamic
  dashboards in the recorded inventory; this check accepts the additional Service dashboard
  without a quota error. Live advisor/manager screenshots, refresh and security readback remain pending.
- P6-10: `docs/architecture/SIMULATION_LOYALTY.md` exists and distinguishes custom engines,
  inactive processing, historical limitations and licensed Loyalty Management.
- P6-11: native Contact report uses Completed Service plus an explicit Quote buyer linked to an
  open Opportunity. It establishes coexistence, not household inference or purchase chronology.
  Seed report/browser acceptance remains pending.
- P6-12: Apex consent service and thin triggers replace the historical proposed Flow, consistent
  with the no-new-Flow direction. Exact tuple consent, deny precedence, opt-out, retained
  suppression, USER_MODE audience access and 201-member pagination pass isolated tests.
  Audience preview is uncached; no messages or schedules exist. Live persona/browser acceptance remains pending.

Owner authorized Quick Deploy of validation `0Afaj00000p15t7CAA` to confirmed ng-demo
`00Daj00001Ae3iWEAR`. CONFIRMED — raw deployment output excerpts:

```json
"id": "0Afaj00000p19YXCAY",
"status": "Succeeded",
"checkOnly": false,
"completedDate": "2026-10-24T21:15:46.000Z",
"numberComponentErrors": 0,
"numberComponentsDeployed": 56,
"numberComponentsTotal": 56,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": []
```

Quick Deploy reused the exact validated payload; tests were not rerun. All component results
succeeded: 39 created, 17 unchanged. Live dashboard, reporting and persona acceptance is
deferred, not passed. No live records, permission assignments, processing activation, jobs,
page activations or Git publication were performed. Batch 1/2 deferred acceptance and Phase 5
exceptions remain tracked. At Batch 3 deployment close, P6-13 and later Batch 4 scope had not
started; the subsequent local execution is recorded below. Batch 4 deployment requires separate authorization.

**Batch 4 local execution (P6-13–P6-17):** implemented in one owner-authorized continuous run,
then separately deployed through the exact Quick Deploy recorded below. Final exact manifest is
`manifest/p6-batch4-check.xml`; evidence and component inventory are in
`evidence/P6/BATCH4_EXECUTION_2026-10-24.md`, latest handoff §30.

CONFIRMED — raw final check-only output excerpts:

```json
"id": "0Afaj00000p1hwnCAA",
"status": "Succeeded",
"checkOnly": true,
"completedDate": "2026-10-24T23:29:21.000Z",
"numberComponentsDeployed": 41,
"numberComponentsTotal": 41,
"numberComponentErrors": 0,
"numberTestsCompleted": 181,
"numberTestsTotal": 181,
"numberTestErrors": 0,
"codeCoverageWarnings": []
```

- P6-13: local architecture seam complete at `docs/architecture/SIMULATION_NURTURE.md`, covering
  actual consent/audience behavior and explicit absence of licensed journeys, sender and scheduler.
- P6-14: native named 4/48-business-hour Platinum Care milestones, explicit response evidence,
  completion trigger/service, native breach report and new unassigned layout/page validate.
  Native target creation, completion, bulk and persona restrictions pass tests. Live timer,
  breach UI, enrollment and page/layout placement remain deferred, not passed.
- P6-15: ten internal local drafts and category/import/Case-use instructions prepared under
  `docs/knowledge/`. The disabled-feature finding from Batch 4 is superseded by the read-only
  continuation below: Knowledge and Lightning Knowledge are enabled, with native article,
  category-selection and CaseArticle objects available. Remaining configuration/import and
  separately approved publication/attachment acceptance are pending, not passed.
- P6-16: new Sales and Service Console apps plus unassigned app-only permission metadata validate.
  Existing apps and security remain unchanged; accepted Sales page references are preserved.
  Dual-role navigation, app availability and browser/security acceptance remain deferred.
- P6-17: four new SLA methods and coordinated 181-method regression suite pass. Separate existing
  implementation coverage run `707aj00001NdWTm` passes 34/34: accrual 29/31 (94% rounded),
  accrual batch 11/11, tier batch 7/7, redemption 11/11 and capacity 87/89 (98% rounded).
  New service/trigger coverage is 19/19 and 3/3. The focused 90% gate is met, not an org-wide claim.

Final scope: 16 new components plus 25 unchanged test/fixture classes; no existing production
components modified. Unrelated dirty DiscountApprovalTest is not packaged; its deployed six
methods run. Earlier 42-component validation `0Afaj00000p0rLXCAY` is superseded. Knowledge
content is local data/documentation, not metadata or part of the deployment. Owner separately
approved deployment of final validation `0Afaj00000p1hwnCAA`; assignments, record enrollment,
pages, Knowledge and scheduling remain separate. Phase 6 remains open;
previous Phase 5 exceptions and Batch 1–3 live acceptance are preserved.

**Batch 4 deployment:** exact stored validation `0Afaj00000p1hwnCAA`, target confirmed as
ng-demo / `00Daj00001Ae3iWEAR`. CONFIRMED — raw Quick Deploy output excerpts:

```json
"id": "0Afaj00000p1MVmCAM",
"status": "Succeeded",
"checkOnly": false,
"completedDate": "2026-10-25T00:38:45.000Z",
"numberComponentsDeployed": 41,
"numberComponentsTotal": 41,
"numberComponentErrors": 0,
"numberTestsCompleted": 0,
"numberTestsTotal": 0,
"componentFailures": []
```

All 41 components succeeded: 16 created, 25 unchanged, no existing components modified.
Quick Deploy did not rerun tests or rebuild the package. No Knowledge enablement, live records,
permission assignments, page activation, scheduling or Git commit/push. Live SLA, reporting,
console/persona/browser acceptance is deferred, not passed. The Knowledge enablement prerequisite
was subsequently confirmed resolved in the focused continuation below.
**Phase 6 is not accepted or closed.**

**P6-15 read-only continuation (2026-10-25 UTC):** owner browser verification plus metadata
retrieval `09Saj00000mhMEYEA2` confirms the current state. CONFIRMED — retrieved output:

```xml
<enableKnowledge>true</enableKnowledge>
<enableLightningKnowledge>true</enableLightningKnowledge>
<enableKnowledgeCaseRL>false</enableKnowledgeCaseRL>
```

No current body field or category group exists. Prepared locally: `Knowledge__kav.Body__c`,
`Northgate_Knowledge` category group and new unassigned internal article layout; exact proposed
three-component scope is `manifest/p6-15-knowledge-prepare.xml`. No deployment, org validation,
permission metadata or assignment. Local request builder prepares ten Draft creates plus ten
category selections without sending them, publication or Case links. Native selection uses
version IDs; CaseArticle uses master KnowledgeArticleId. All ten planned URLs currently have
zero matches in Draft/Online/Archived, but collision checks must repeat before approved import.

Focused offline payload/XML checks pass. Existing Batch 4 implementation/tests were not repeated.
No new architectural blocker; configuration deployment, author/reader readiness, Draft creation,
publication and Case/UI acceptance require their corresponding approvals. No live article,
permission, setting or Case-link changes; no Git operations. Current instructions:
`docs/knowledge/README.md`; evidence:
`evidence/P6/P6_15_KNOWLEDGE_CONTINUATION_2026-10-25.md`; handoff §31.

**Initial consolidated closure review (2026-10-25 UTC): historical BLOCKED state.**
The final blocker repair below supersedes these initial observations; the status matrix is current.
Owner subsequently authorized the three-component Knowledge deployment and exact ten-Draft/
ten-category-selection creation. Validation `0Afaj00000p27o1CAA` passed three/three; deployment
`0Afaj00000p27rFCAQ` succeeded three/three at 2026-10-25T00:59:27Z. No Apex tests were repeated
for this non-Apex package. All three metadata components are now present; the prior preparation-
only state above is historical. The approved importer generated the request but did not submit
it: connected author cannot access Body__c and no field grants exist. Zero articles and zero
category selections were created. Security changes are explicitly outside authorization.

| Block | Current implemented/deployed/acceptance status |
|---|---|
| P6-01 | Implemented/deployed; prior capacity tests and current eight-at-capacity readback verified; live persona/contention deferred |
| P6-02 | Implemented/deployed; eight linked queue-owned Service/New/Medium/Web Cases read back; persona/browser deferred |
| P6-03 | Implemented/deployed; active 240-minute native entry verified; live timer/notification/event-derived timestamp acceptance deferred |
| P6-04 | Implemented/deployed; controller tests and existing Service app Case/history mapping verified; actual timeline browser deferred |
| P6-05 | Implemented/deployed/tested; Vehicle history page placement and browser acceptance deferred |
| P6-06 | Implemented/deployed/tested/configuration verified; program inactive, no live accrual or reconciliation |
| P6-07 | Implemented/deployed/tested/tier configuration verified; nightly schedule and real tier movement inactive |
| P6-08 | Implemented/deployed/tested; operator assignment/action and live redemption/expiry deferred; balances preserved |
| P6-09 | Implemented/deployed; types/folders and source-matching liability totals verified for approved administrator; dashboard/persona rendering deferred |
| P6-10 | Loyalty seam documentation implemented and verified; no licensed product/accounting claim |
| P6-11 | Implemented/deployed and repaired; effective open criterion present; native/source totals 31/31, no unexplained difference |
| P6-12 | Gate/preview implemented/deployed/tested; audit repaired with managed-only filter and report/source 0/0; all 60 legacy memberships retained unmanaged; positive live suppression/browser deferred |
| P6-13 | Nurture seam documentation implemented and verified; sender/journeys/schedules absent by design |
| P6-14 | Implemented/deployed/tested/native process verified; zero enrolled entitlements; native live timer/UI and placement deferred |
| P6-15 | Feature/metadata/minimum author access deployed; ten internal Drafts and ten category selections created and verified; publication/Case search/attachment deferred |
| P6-16 | Console apps implemented/deployed/configuration verified; permission assignment and actual dual-role browser acceptance deferred |
| P6-17 | Existing 181/181 coordinated and 34/34 focused tests reused; required engines above 90%; no unnecessary rerun or org-wide coverage claim |

Initial read-only runs found Service open=69, overdue=14, CSI responses=0; Loyalty members=72,
stored points=0, historical transactions=110/net 17,370. Program remains inactive, downgrades
false, no relevant jobs or new Platinum Care entitlements. Existing data was not repaired.
The initial report describe had Quote criteria=[] and audit reportFilters=[] because intended
report/access configuration was not effective. Those failures were subsequently corrected under
explicit authorization; current effective filters and totals are recorded below. Report existence
or isolated semantic tests alone were not treated as acceptance.

Initial closure and blocked-import evidence remains in `evidence/P6/PHASE6_CLOSURE_REVIEW_2026-10-25.md`
and `evidence/P6/P6_15_KNOWLEDGE_EXECUTION_2026-10-25.md`. The subsequent owner-approved field
grant, completed import and separately approved report repair below resolve those blockers;
latest handoff is §33. Publication, Case links, page activation, schedules, additional permissions
and loyalty changes remain separate. The ten-plus-ten creation approval is consumed, not permission
to replay the import. No additional test records, reconciliation, Git staging/commit/push or Phase 7
implementation. Do not mark Phase 6 accepted or close its exit gate without an explicit owner decision.

**Final blocker repair (2026-10-25 UTC): all three blockers resolved.** Owner authorized the
minimum Knowledge author grant/import; the four-component report deployment and administrator-
only report Read grant received separate explicit approval before execution.

| Scope | Validation | Deployment | Result |
|---|---|---|---|
| Body-only PS_Knowledge_Draft_Author | 0Afaj00000p2Gg1CAE | 0Afaj00000p2EfqCAE | 1/1, zero errors |
| Exact three reports + PS_Phase6_Report_Field_Read | 0Afaj00000p2HtpCAE | 0Afaj00000p1htbCAA | 4/4, zero errors |

Both permission sets are assigned only to the existing administrator `005aj00000feqbNAAQ`.
Knowledge grants Body__c Read/Edit only; reporting grants exactly six fields Read-only, with
no object CRUD, audience-preview, write, identity/profile or record-sharing changes.

CONFIRMED — live Knowledge verifier output:

```json
"status": "PASS",
"verifiedArticles": 10,
"verifiedCategorySelections": 10,
"exactTitleSummaryLanguageMatches": 10,
"htmlContentMatches": 10,
"draftInternalOnly": 10,
"onlineOrArchivedMatchingVersions": 0
```

All twenty creates succeeded HTTP 201. Native rich-text entity normalization is handled by
semantic HTML verification, not edits to stored data. Do not replay the import. Publication,
Case links and external visibility remain unchanged/prohibited.

CONFIRMED — repaired native report/source comparisons:

- Repeat purchase: required Completed-service/open-Opportunity filters present; 31/31 Contacts.
- Nurture audit: Consent_Managed__c=True filter present; 0/0 memberships. All sixty existing
  memberships remain unmanaged and preserved, rather than being counted as managed audience.
- Loyalty: liability aggregate visible; report/source both 72 members, stored points zero,
  CAD 0.00 liability. No historical reconciliation or program activation.

The changes are non-Apex metadata and the twenty explicitly approved creates. Scoped NoTestRun
validations, offline report/security contracts and live content/filter/source checks passed;
the successful 181/181 and 34/34 Apex suites were reused without unnecessary reruns.

The final repair recommendation was **ACCEPT WITH DOCUMENTED EXCEPTIONS**; the owner has now
explicitly accepted with that disposition, dated October 24, 2026. Retain
publication/search/Case attachment, actual operational persona/browser/dashboard rendering,
page/action placement, live contention/escalation/SLA clocks, loyalty processing/jobs and empty
CSI limitations. No remaining critical defect was found in the repaired scope. No unrelated
data/security changes, Git staging/commit/push, ng-dev access or Phase 7 implementation.

Current evidence: `evidence/P6/PHASE6_FINAL_BLOCKER_REPAIR_2026-10-25.md`; receipt and full
readback JSON are adjacent. Handoff §33 and the updated 17-block closure matrix supersede the
historical blocked findings. The formal owner decision below supersedes the recommendation-only status.

**Phase 6: OWNER-ACCEPTED WITH DOCUMENTED EXCEPTIONS — October 24, 2026.**

Owner decision: YES. Preserve every detailed exception and operational requirement in
`evidence/P6/PHASE6_OWNER_ACCEPTANCE_2026-10-24.md` (P6-E01–P6-E14), the 17-block matrix and
underlying batch/runbook/seam evidence. Publication/Case integration, actual persona/browser,
dashboard/CSI, live contention/escalation/SLA clocks, history/page/action placement, inactive
loyalty/jobs/historical mismatch, positive live consent, timezone and release/Phase 5 limitations
remain outstanding, not passed. Formal acceptance does not authorize activation or record changes.
API execution timestamps retain their original UTC dates; acceptance date is October 24.

**Exit gate:** post-sale lifecycle works; SLA (entitlements) and Knowledge demoable; all paid
seams documented.

---

# Phase 7 — Developer depth, AI, governance and polish

**Status: Batches 1/2 deployed, neither owner-accepted. Batch 2 atomic application/removals 14/14
and territories 6/6 verified, model Planning with no assignments. Batch 3 local implementation/
one-prompt and Batch 4 two-component scopes are now deployed. Prompt Draft/inactive, page not
assigned/activated; native capability/runtime, full release, persona/browser and owner acceptance
gates remain. Phase 7 is not fully accepted.**
Consolidated plan: `docs/planning/PHASE7_IMPLEMENTATION_PLAN_2026-10-24.md`; latest handoff §§46–47.

**Final Phase 7 deployment/status inventory:** exact 23-row state/evidence/acceptance table is
`docs/planning/PHASE7_FINAL_STATUS_2026-10-26.md`; original acceptance rows below are unchanged.
Actual final deployment receipt: `evidence/P7/P7_FINAL_DEPLOYMENT.md`.

CONFIRMED — raw final deployment projections:

```json
{"id":"0Afaj00000pCUHtCAO","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
{"id":"0Afaj00000pCURZCA4","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":2,"numberComponentsTotal":2,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
```

Explicit Quick Deploy unavailability used the owner-authorized standard scoped fallback. No
actual deployment failure, scope expansion, test rerun, prompt/page activation or data/permission
change. Native readback confirms Draft/no active version and both header/page definitions;
before/after assignment/settings/security/trigger/data fingerprints match. Planning territory
and zero Account/User associations are preserved. No browser/UAT acceptance is inferred.

All 23 IDs are dispositioned, not blanket accepted: P7-01/02/03/05/07/08/12/15/22/23 have deployed
runtime/metadata with the detailed operational/runtime gates retained; P7-04/06/09/10/13/14/19/20
have delivered documents; P7-11 audit-reader/usage, P7-16 Data Cloud, P7-17 full release,
P7-18 portal and P7-21 live walkthrough acceptance remain partial/blocked. See the per-ID table
for exact distinctions. Batch 1/2 are not owner-accepted; Phase 5/6 exception registers remain.
Git is dirty/unstaged; HEAD/live origin main match 0423863794b70bb13c3c59128f7b57a0313aa0f4, cached
ahead/behind 0/0. Exact counts: `evidence/P7/P7_FINAL_GIT_STATUS.json`; no fetch/stage/commit/push/tag.
Final read-only snapshot records 72 tracked changes (including eight deletions), 3,062 untracked
files and zero staged entries. New closeout coverage check passes 23/23 unique P7 and 11/11
unique P8 rows plus 30 current local links, without Salesforce calls or prior-test reruns.

**Historical Quick Deploy attempt (subsequently recovered below):** owner approved exact Quick Deploys of `0Afaj00000p2bfeCAA` and
`0Afaj00000p4yTFCAY`, stopping if either is unavailable. Target confirmed ng-demo
`00Daj00001Ae3iWEAR`. Photo Quick Deploy was checked first; CONFIRMED — raw error:

```json
"status": 1,
"name": "CannotQuickDeployError",
"message": "Job ID can't be used for quick deployment. Possible reasons include the deployment hasn't been validated, has already been deployed, or the validation expired because you ran it more than 10 days ago."
```

No deployment ID returned; application Quick Deploy was not issued. Neither package was deployed
by this execution. No rebuild, new validation or alternate method. Live resource path checks and
browser/gallery/event acceptance remain unverified/deferred, not passed. No records/paths,
permissions, pages, credentials, jobs or Git staging/commit/push changed. Owner must inspect asset
validation Quick Deploy availability or provide explicit revised authorization. Evidence:
`evidence/P7/BATCH1_DEPLOYMENT_ATTEMPT_2026-10-25.md`. Phase 6 acceptance/exceptions are preserved.

**Authorized standard recovery:** both current manifest member sets/source layouts match the
previously validated one/21 components. Asset hash matches recorded package; 70 selected source
hashes remain unchanged. Target confirmed ng-demo `00Daj00001Ae3iWEAR`, Developer Edition.

CONFIRMED — raw ordered deployment results:

```json
{"id":"0Afaj00000p7373CAA","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-25T23:13:52.000Z","numberComponentsDeployed":1,"numberComponentsTotal":1,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
{"id":"0Afaj00000p738fCAA","status":"Succeeded","checkOnly":false,"completedDate":"2026-10-25T23:14:29.000Z","numberComponentsDeployed":21,"numberComponentsTotal":21,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
```

NoTestRun is supported/accepted for this Developer Edition target; no additional Apex tests were
run beyond deployment requirements. The prior 163/163 baseline is preserved, not a new run.
Resource exists and its authenticated REST archive contains all thirty exact approved photo
bytes/root names and the complete license JSON. All thirty existing model paths/body types
match unchanged. Optional attribution Markdown is excluded by the existing *.md ignore rule;
no source/ignore repair or scope expansion. Native archive 31 files/1,807,209 bytes; local
deliverable ZIP still 32 files. No photo is missing.

Direct API-host image probe returned no usable image, so front-end rendering is not claimed;
canonical archive and path compatibility are verified. Permissions/page placement, live gallery/
reservation/event and VIN credential acceptance remain deferred, not passed. New operational
permission sets are unassigned. No record/path/VIN changes, assignments, activation, credentials,
jobs or Git staging/commit/push; ng-dev untouched. Evidence:
`evidence/P7/BATCH1_STANDARD_DEPLOYMENT_2026-10-25.md`. Do not mark Batch 1 owner-accepted.

| Implementation batch | Final block allocation | Count |
|---|---|---:|
| Batch 1 — Inventory/integration/events | P7-22, P7-01–P7-06 | 7 |
| Batch 2 — Trigger/maintenance/governance | P7-07–P7-12 | 6 |
| Batch 3 — Architecture/capabilities/regression | P7-13–P7-18 | 6 |
| Batch 4 — Presentation/release evidence | P7-19–P7-21, P7-23 | 4 |

**Latest Batch 2 deployment:** `evidence/P7/BATCH2_DEPLOYMENT.md`, handoff §43. The saved combined
235/235 validation covered ten application components and four native pre-destructive removals.
Supported --pre-destructive-changes packages them in the same transaction; no separate removal
or application-only deployment occurred. CONFIRMED — raw deployment projections:

```json
{"id":"0Afaj00000p84KRCAY","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":14,"numberComponentsTotal":14,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
{"id":"0Afaj00000p8GtRCAU","status":"Succeeded","checkOnly":false,"numberComponentsDeployed":6,"numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}
```

Live code/entry points match source, obsolete triggers are absent and twelve unrelated trigger
hashes are unchanged. Territory model remains Planning, four siblings/shared type exist and
Read/None/None/None persists with zero Account/User associations. No tests rerun, data/permission/
activation/settings changes or release actions. Batch 2 deployed is not Batch 2 owner-accepted.

**Latest Batch 3 local work:** `evidence/P7/BATCH3_EXECUTION.md`, handoff §44; original rows below
are not weakened or marked done from source alone. P7-13 strategy note and P7-14 five-seam index
are implemented. P7-15 has one native Draft Case triage template, 1/1 check-only
`0Afaj00000p8MduCAE`, zero Apex tests, not deployed/activated. Agent Platform/Copilot/Bots disabled;
actual agent/usage/internal persona acceptance remains open. P7-16 Data Cloud disabled, zero
streams/no exposed DataSpace; ingestion/identity requires enablement/data approval. P7-18 Networks
disabled/no Site; Community licenses exist but identity/license/per-object sharing decisions and
actual external-user acceptance remain open. No paid/custom/Flow/React fallback is fabricated.
P7-17 safe plan/full-run wrapper and local fail-closed tests pass; full native/DQ/clean-checkout
gate not run and 235 tests not repeated. Only future Batch 3 deployment scope is one Draft
GenAiPromptTemplate NG_Case_Triage in manifest/p7-batch3-check.xml; no settings or activation scope.
Batch 1 deferred browser/gallery/event/placement/operational/VIN gates and Phase 6 exceptions remain.

**Latest Batch 4 local implementation:** `evidence/P7/BATCH4_EXECUTION.md`, handoff §45; original
acceptance rows remain unchanged. P7-19 Automotive mapping is documentation only. P7-20 README
reflects actual deployed/local/gated state, explicit target/manifests and safe reset-plan guidance.
P7-21 has five persona-first walkthroughs/index, not actual signed-off end-to-end runs; old P2
script is marked historical. P7-23 has a read-only UI API photo/model LWC plus a new unassigned
Vehicle page retaining native highlights/details/history; no existing page/mapping or Apex edit.

CONFIRMED — raw final Batch 4 check-only:

```json
{"id":"0Afaj00000pBPvPCAW","status":"Succeeded","checkOnly":true,"numberComponentsDeployed":2,"numberComponentsTotal":2,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0,"numberTestErrors":0}
```

Initial unsupported native detail-component identifier was corrected using Salesforce's official
source reference under routine-local authority; the exact failure and correction are preserved.
Six focused Node state checks and local scope/link/source-preservation checks pass. Twenty-six
prior Batch 2 source hashes and the Batch 3 draft are unchanged; successful Apex suites were not
repeated. Post-check Tooling queries find neither new definition persisted.

Exact future Batch 4 deployment scope is two new members in manifest/p7-batch4-check.xml:
vehiclePhotoHeader LightningComponentBundle and NG_Vehicle_Photo_Header FlexiPage. No activation,
assignment, permission, app/object/setting, Apex, Flow, asset or destructive metadata. Batch 3
Draft prompt remains separate/unapproved for deployment. Page placement, actual with/without-photo
screenshots, actual-reader/visual checks and all five live walkthroughs remain NOT RUN/BLOCKED;
no UAT or M3/clean tag sign-off is claimed. Preserve Agentforce/Data Cloud/portal/full-regression,
Phase 5/6, Batch 1 browser/gallery/event/page/operational/VIN and Batch 2 owner-review exceptions.

P7-22 moves ahead of P7-01 to satisfy its explicit image dependency. Focused ng-demo queries
found no NG_VehicleImages resource and 30 models with 30 existing nonblank image paths; do not
mistake existing paths for completed static-resource/photo acceptance or overwrite them now.
Other provisional batch ranges remain intact. IDs/dependencies/acceptance rows below are not
renumbered or weakened. Within Batch 4, complete P7-23 before final README/demo script evidence;
P7-21's “all phases” covers delivered Phase 0–7, with the Phase 8 extension owned by P8-11.

Owner subsequently authorized Batch 1 local implementation/test/scoped check-only. Execution
followed the image/path contract, then gallery, calculator, VIN mock/contract and events/seam.
Live deployment, image-path writes, credentials, assignments and activation remain separate.
Phase 8's eleven blocks remain unchanged; no portal/site/external-user enablement is authorized.

**Historical Batch 1 local execution (deployment superseded above):** `evidence/P7/BATCH1_EXECUTION_2026-10-25.md`.
CONFIRMED — final exact check-only output excerpts:

```json
"id": "0Afaj00000p2bfeCAA",
"status": "Succeeded",
"checkOnly": true,
"numberComponentsDeployed": 21,
"numberComponentsTotal": 21,
"numberComponentErrors": 0,
"numberTestsCompleted": 163,
"numberTestsTotal": 163,
"numberTestErrors": 0,
"codeCoverageWarnings": []
```

P7-01–P7-06 source is present locally: gallery/reservation, read-only calculator, simulation VIN
client plus loopback provider/API contract, native after-commit event/subscription and CDC/Pub-Sub
seam. Selected scope includes four new production classes, four test classes plus a fixture, two LWCs, event/
fields, two capabilities, two unassigned permission sets and a tab. Existing cache writer/trigger
have only the necessary internal-DML/publisher edits. No old regression source is included.
Coverage is gallery/calculator/publisher 100%, VIN 23/24, VehicleCounters 16/17 and trigger 15/16.
Four client state checks and offline mock provider contract pass; no browser render is claimed.

The initial P7-22 AI-photo/tool blocker was resolved by the owner's later licensed real-stock
sourcing amendment below. Existing thirty paths and gallery fallback are preserved; the complete
resource now validates separately and is not silently added to the prior application payload.
NG_VIN_Mock credential/host/principal configuration is absent and intentionally not created;
positive named-credential wire/actual timeout and operational/browser use remain unverified.
These block full Batch 1 acceptance, not the successful 21-component source validation.
No deployment, live records/image/VIN changes, credential or permission assignment, activation,
Git staging/commit/push or ng-dev access. Phase 6 acceptance/exceptions are unchanged; no Batch 2 work.

**P7-22 stock-photo completion:** owner authorized appropriately licensed real automotive stock
photography instead of planned AI-generated photos. Thirty distinct Commons photographs with
explicit CC0 1.0 records are downloaded, visually reviewed, full-frame optimized to genuine WebP
and packaged as NG_VehicleImages. No prominent billboards/company-door branding were edited out;
unsuitable candidates were replaced, and incidental badges remain. Exact filenames/body/model
mapping is preserved; all thirty live paths match the finished resource without record updates.

Inventory/rights: `docs/assets/P7_VEHICLE_PHOTO_INVENTORY.md` and
`docs/assets/P7_VEHICLE_PHOTO_SOURCES.json`. Package `evidence/P7/NG_VehicleImages.zip`:
1,808,049 bytes; thirty 800×600 WebPs plus attribution/license register; median 54,114 bytes per
image, range 45,640–118,278. Local encoding/rights/distinctness/ZIP/live-path checks pass.

CONFIRMED — final raw asset-only check-only output:

```json
"id": "0Afaj00000p4yTFCAY",
"status": "Succeeded",
"checkOnly": true,
"numberComponentsDeployed": 1,
"numberComponentsTotal": 1,
"numberComponentErrors": 0,
"numberTestsCompleted": 0,
"numberTestsTotal": 0
```

Manifest `manifest/p7-22-images-check.xml` includes StaticResource NG_VehicleImages only.
No Apex was changed/rerun; previous 163/163 application tests are reused. No actual deployment,
image/VIN/inventory changes, permissions, gallery redesign or Git staging/commit/push. P7-22 is
locally complete under the amended sourcing criterion; deployment/rendering/owner acceptance
remain deferred, not passed. No genuine sourcing/license gap remains. Full evidence:
`evidence/P7/P7_22_STOCK_PHOTOS_2026-10-25.md`.

**Batch 2 authorized local implementation/check-only:** `evidence/P7/BATCH2_EXECUTION.md` and
`docs/planning/P7_BATCH2_IMPLEMENTATION_PLAN.md`. Original acceptance rows below remain unchanged.

- P7-07 implemented/validated: one local entry trigger per affected object, dedicated handlers,
  preserved context-specific bypasses and domain services, bulk conversion cleanup/lane queries,
  200-row, partial-save and re-entry tests. Live original triggers remain unchanged.
- P7-08 implemented/validated: explicit bounded rooftop-counter Queueable, native age formula,
  Test.stopTest/idempotence/move/delete/undelete/zeroing and denied-persona evidence. No live job.
- P7-09/P7-10 documentation complete: governance checklist linked here/README; existing debt ledger
  updated with evidence, owner/disposition and revisit triggers. No completed component redesign.
- P7-11 administrative CLI/JSON report runs; actual native/browser operational-reader evidence is
  deferred. Eighteen zero-assignment candidates include five group members; none is proven unused.
- P7-12 capability gate cleared after owner Setup enablement: enabled setting and all four native
  objects verified read-only. No models/types/territories or Account/User associations exist.
  Mapping/access/membership, implementation and later activation/assignment approvals remain
  outstanding. Current evidence/actions: `evidence/P7/P7_12_READ_ONLY_REVERIFICATION.md`, handoff §40.

  Subsequent local design: `docs/planning/P7_12_TERRITORY_DESIGN.md`, receipt
  `evidence/P7/P7_12_DESIGN_RECEIPT.md`, handoff §41. Separate territory manifest contains exactly
  one model/type and four siblings with Account Read / Contact None / Opportunity None / Case None.
  Offline scope/source-conversion checks pass; no server check-only/deployment. Native manual
  association is the recommended point-in-time approach; direct lookup-rule eligibility is not
  assumed. Preserve all five unmapped Accounts. All Staff user/rooftop manager links are blank;
  only operational-profile user holds VP_Sales with preserved metrics-only boundary. Recommend
  zero memberships until owner identity decision; four/four Salesforce licenses are used.
  Contact-default/override behavior requires scoped validation and explicit approval before
  deployment/data/activation. Existing Batch 2 source/manifest scope and 235-test baseline remain intact.

  Subsequent owner-authorized unchanged six-component check-only succeeded; no metadata edits/retry.
  CONFIRMED — raw result excerpt:
  `{"id":"0Afaj00000p7zkYCAQ","status":"Succeeded","checkOnly":true,"numberComponentsDeployed":6,"numberComponentsTotal":6,"numberComponentErrors":0,"numberTestsCompleted":0,"numberTestsTotal":0}`.
  All four submitted access values are accepted; only the exact type/model/four territories
  appear in component successes. Targeted post-check queries find none persisted. No Apex rerun,
  actual deployment, assignments, activation or settings/data change. Effective sharing and
  identity/assignment/activation decisions remain open. Evidence:
  `evidence/P7/P7_12_SCOPED_VALIDATION.md`, handoff §42.

CONFIRMED — raw final check-only projection:

```json
{"id":"0Afaj00000p7GCLCA2","status":"Succeeded","checkOnly":true,"completedDate":"2026-10-26T00:18:31.000Z","numberComponentsDeployed":14,"numberComponentsTotal":14,"numberComponentErrors":0,"numberTestsCompleted":235,"numberTestsTotal":235,"numberTestErrors":0}
```

Twelve new tests plus 223 affected regressions pass across 33 classes, including CP2 and selected
Phase 1–6 lifecycle/security tests. Initial unique-tag fixture failure was escalated and corrected
only after owner approval/source proof; original failed receipt retained. No weakened assertions.
Local exact-scope and post-validation source/readback checks pass; twenty source hashes match.
Full evidence, limits and historical failure: `evidence/P7/BATCH2_EXECUTION.md`.

Exact future approval scope: ten replacements in `manifest/p7-batch2-check.xml` (six new classes,
modified LeadRoutingHandler and three entry triggers), atomically with four trigger removals in
`manifest/p7-batch2-destructive.xml`: LeadBeforeConvertGuard, LeadAfterConvertSeedBlock,
VehicleCounterTrigger and TestDriveFollowupTrigger. No actual deployment, persistent records/
configuration, assignments, scheduling or Git staging/commit/push occurred. Do not mark Batch 2
accepted. Batch 1 browser/gallery/event acceptance, operational access and VIN credentials remain
deferred; Batch 1 is not owner-accepted. All Phase 6 exceptions remain unchanged.

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P7-01 | Inventory gallery LWC | **Photo card gallery** with filters (make, body style, price, status) + **Reserve** action, driven by `Vehicle__c.Photo__c`; loading + error states | P2-06, P7-22 | Reserve updates without reload; photos render; error path visible → `evidence/P7/inventory_lwc.png` | LWC, APEX |
| P7-02 | Trade-in or payment LWC widget | Interactive calculator on the opportunity page | P4-01, P3-01 | Correct maths; no hardcoded values → `evidence/P7/widget.png` | LWC, APEX |
| P7-03 | VIN decoder callout | REST callout via Named Credential to mock endpoint, JSON parse, timeout + error handling | P1-02 | Mock test passes; failure path handled → `evidence/P7/vin_callout.txt` | INTEG, APEX, TEST |
| P7-04 | API contract | `docs/integration/API_CONTRACT.md` with request/response examples + error codes | P7-03 | Contract matches implementation → doc diff | INTEG, DOC |
| P7-05 | Platform event | `Vehicle_Reserved__e` published on reservation; LWC subscribes | P7-01 | Event flows end to end in test → `evidence/P7/platform_event.txt` | INTEG, APEX, LWC |
| P7-06 | CDC / Pub-Sub pattern doc | How the design maps to CDC + Pub/Sub; simulated vs native stated honestly | P7-05 | Doc states seams → `docs/architecture/` | ARCH, DOC |
| P7-07 | Trigger architecture | One trigger per object → `<Object>TriggerHandler`; recursion guarded; bulk-safe; **`Bypass_Triggers__c` honoured** | P1-13 | 200-row bulk test passes; bypass test passes → `evidence/P7/trigger_tests.txt` | APEX, TEST |
| P7-08 | Queueable reconciliation | Async job reconciles inventory age + maintained counters (safety net per DATA_MODEL §5.3) | P2-12 | `Test.stopTest()` asserts outcome → `evidence/P7/queueable.txt` | APEX, TEST |
| P7-09 | Governance pack | `docs/GOVERNANCE.md`: naming rules, review checklist, definition of done | P0-09 | Pack referenced by backlog + README → doc exists | ARCH, DOC |
| P7-10 | Tech-debt register | `docs/TECH_DEBT.md` with every deliberate simplification (slot-conflict race, `Source_Reference__c`, etc.) | P2-04 | Register non-empty and honest → `docs/TECH_DEBT.md` | ARCH, DOC |
| P7-11 | Permission audit report | Report of assigned permission sets + unused permissions | P1-19 | Report runs → `evidence/P7/perm_audit.png` | SECURITY, REPORT |
| P7-12 | Territory management | 4 territories aligned to rooftops with account assignment (**only if verified present**, checklist §0-E #14) | P0-09 | Territory tree renders; accounts assigned → `evidence/P7/territories.png` | ARCH, ADMIN |
| P7-13 | Org-strategy note | `docs/architecture/ORG_STRATEGY.md`: two-org model (ng-dev/ng-demo), release flow, LDV, archiving | P0-01 | Note specific to this build → doc exists | ARCH, DOC |
| P7-14 | Simulation seam notes complete | CPQ, Loyalty, Marketing, Field Service, Integration documented; ledger §4 cross-referenced | P3-11, P4-12, P6-10, P6-13 | MASTER_PLAN §4.4 rows link to notes → doc index | ARCH, DOC |
| P7-15 | **Agentforce service agent + Prompt Builder** | One small agent (case triage or service-visit summary) + one Prompt Builder template; usage within DE limits (≈150 LLM req/hr); **fallback = simulated triage flow, kept and labelled** | P0-09 (verify), P6-02, P6-15 | Agent answers a test prompt; screenshot → `evidence/P7/agentforce.png` | INTEG, ARCH, DOC |
| P7-16 | **Data Cloud demo** | One ingestion (e.g. service-visit events) + identity-resolution demo in the single DE data space (10 GB, manual refresh) | P0-09 (verify), P6-05 | Data space shows resolved profiles → `evidence/P7/datacloud.png` | INTEG, ARCH, DOC |
| P7-17 | Regression checklist automated | `scripts/test.sh`: deploy dry-run + Apex tests + `verify.sh` DQ gates — one command | P5-08, P0-04 | One command green from clean checkout → `evidence/P7/regression.txt` | DEVOPS, TEST |
| P7-18 | **Experience Cloud site (real)** | Small customer site ("Northgate Owner Portal": service history, appointments) using 1–2 of the 5 External Identity licences | P0-08, P6-05 | Login as external user works → `evidence/P7/portal.png` | SECURITY, ARCH |
> **P7-18 React evaluation (conditional — not approved):** Salesforce Multi-Framework React is
> under evaluation for this item only; existing Experience Cloud/Lightning fallback remains
> authoritative until eligibility, licensing, security, and cost are confirmed. Pre-adoption
> conditions and status in `docs/architecture/MF_REACT_P7-18.md`.
>
> **Phase 8 (M4):** the full Customer Experience Portal extends this item — see
> `# Phase 8 — Customer Experience Portal` below. P7-18 requirements are unchanged.
| P7-19 | **Automotive Cloud concept mapping** | One-pager: which licensed Automotive Cloud objects/concepts our model maps to (documented only — never built) | P0-09 | `docs/architecture/AUTOMOTIVE_CLOUD_MAPPING.md` → doc exists | ARCH, DOC |
| P7-20 | README rewrite | Repo README reflects the actual org: what exists, how to deploy, how to reset, two-org flow | P7-17 | README matches reality → doc review | DOC |
| P7-21 | Full demo script pack | `evidence/DEMO_SCRIPTS/` for admin, developer, analyst, support, architect walkthroughs; **every script opens with an "Activate persona" step** (master plan §10) | All phases | Each script runs end to end → `evidence/DEMO_SCRIPTS/` | DOC |
| P7-22 | **Vehicle images** | Owner-amended: 30 distinct appropriately licensed real automotive stock photographs, matched by body/approximate year/appearance, optimized genuine WebP (~50 KB where practical), exact mapped filenames; avoid prominent branding where practical without deceptive removal/endorsement; source/photographer/license register; **`NG_VehicleImages`** deployed and existing paths/formula render | P1-02, P0-09 (storage limit) | Thirty-image rights/encoding/package validation plus static resource visible and `Vehicle__c.Photo__c` rendering → `evidence/P7/vehicle_images.png`; local evidence `evidence/P7/P7_22_STOCK_PHOTOS_2026-10-25.md` | ADMIN, DOC |
| P7-23 | **Vehicle record-page photo header LWC** | Header component on the Vehicle record page showing `Photo__c` large + model line; degrades gracefully when image missing | P7-22, P1-06 | Record-page screenshot with and without photo → `evidence/P7/vehicle_header.png` | LWC, ADMIN |

**Exit gate:** all 4 skill domains demonstrable from a clean tag, with honest labelling
throughout.

---

# Milestone M3 gate (Post-sale + advanced)

Deploy clean → tests ≥90% → release-gate DQ checks 0 rows → regression green → all UAT signed
→ all seam notes present → governance pack + tech-debt register written → all demo scripts
run → tag `demo/v1.0`.

---

# Phase 8 — Customer Experience Portal (Experience Cloud + LWC only)

**Purpose:** extend the demo past post-sale into a real customer-facing self-service portal
("Northgate Owner Portal", grown from P7-18). **Milestone M4.** Built with **Experience Cloud +
custom LWC only** — Salesforce Multi-Framework / React is **explicitly excluded**
(`docs/architecture/MF_REACT_P7-18.md` stays P7-18-only).

**Hard pre-conditions (owner decisions D3–D5):** Digital Experiences enablement is **not
authorized**; the external-user licence model is **not chosen** (verify first, never assume); the
SIMULATION fallback is documented but **not implemented or activated** without approval. External
access uses a **relationship-anchored** security model with CRUD/FLS checks and cross-customer
negative tests — not `with sharing` alone (see `docs/architecture/EXPERIENCE_PORTAL.md`;
DATA_MODEL §6.6).

**Depends on:** P7-18 (seed), P5 (seed data), P6 (service/loyalty/cases), P1-11 (permission sets).
**Preserves:** no existing Phase 0–7 item, ID, or acceptance criterion is changed.

**Current preparation-only handoff:** `docs/planning/PHASE8_HANDOFF_2026-10-26.md`. P7-18 is not
an existing seed: Networks remains disabled and no portal/approved external-user sharing model
exists. Begin with owner D3–D6 license/identity/enablement/domain/per-object relationship/security
decisions and an explicit missing-seed alignment, not code. Vehicle reservation is not ownership;
approve the own-vehicle relationship before P8-05/07. Then propose Block A P8-01–03, Block B
P8-04–09 vertical slices and Block C P8-10–11. All eleven rows below remain intact. No Phase 8
implementation/deployment or automatic fallback/Flow/React is authorized by this handoff.

**Focused foundation proposal (not an approved implementation):** Customer Service (Aura) site,
Customer Community Plus and Contact-specific native sharing/LWC/Apex. Read-only verification
confirms Networks disabled, existing Experience domain provisioned, five unused Plus licenses and
Private external OWD. No global sharing change is needed. Current ownership/provisioning gaps:
seven completed deliveries/six Buyers missing/one complete Buyer–Vehicle candidate; 154 of 155
Accounts have roleless owners. No two test identities are provisioning-ready by evidence. Preserve
all records; do not infer ownership from reservation/history or repair missing Buyers. Smallest
next approval is existing-domain Digital Experiences enablement only, not site/user/grant/code.
Exact decisions/access/tests: `docs/planning/PHASE8_FOUNDATION_DECISION_2026-10-26.md`; native facts:
`evidence/P8/FOUNDATION_PREREQUISITES_2026-10-26.md`. All eleven requirement rows remain unchanged.

**Enabled-org continuation:** owner enabled Digital Experiences; read-only settings confirm true,
and the Customer Service template is available. **P8-01 site scaffold now exists, unpublished:**
login-only Customer Service (Aura) Northgate Owner Portal / `owners`, Network `0DBaj000006bf3xGAA`,
`UnderConstruction`, `FirstActivationDate=null`, self-registration off, guest profile
`00eaj00000UB3CcAAL` with zero object permissions and no ApexClass access (standard page/FLS
defaults remain); login page and standard registration form are reachable. P8-01 is not fully accepted until the hardened profile, users/membership, narrow shares
and negative tests exist. P8-02 Contact-specific/private policy is retained, no permissions/shares/
users changed. P8-03 has local default-deny own-Contact context controller/test, custom permission
and unassigned read-only permission set: four definitions in manifest/p8-foundation-preparation.xml.
Local conversion/XML/scope checks pass. P8-02/03 update: hardened Plus profile locally prepared,
profile check-only `0Afaj00000pFlPSCA0` succeeded (1 component, 0 errors, 0 tests). Foundation
check-only `0Afaj00000pGEeLCAW` compiled all four definitions with 3/3 tests passing and 0 component
errors, but **failed at 37.5% controller coverage (75% required)**. No deployment or external-persona
security pass. Coverage repair requires owner approval; no controller/test changes made.
Evidence: `evidence/P8/PROFILE_PREP/P8_02_03_SECURITY_FOUNDATION_2026-10-26.md`, handoff §52.
The approved provisioning preserved existing records/roles: two new isolated Account/Contact pairs
owned from inception by the existing role-qualified user.
No old Account transfers, admin role swaps, Buyer repairs or presumed vehicle ownership. Executed
2026-10-26: the two approved synthetic Account/Contact pairs now exist under the VP owner; IDs and
receipts are in handoff §50 and evidence/P8/CUSTOMER_FIXTURES_CREATION_2026-10-26.md. Site creation
evidence: handoff §51 and evidence/P8/SITE_CREATION/P8_01_SITE_CREATION_2026-10-26.md. Hardened
profile deployment, coverage repair/revalidation, users/shares and publication remain separate approvals.
Current plan/evidence: docs/planning/P8_FOUNDATION_LOCAL_PREPARATION.md
and evidence/P8/ENABLED_FOUNDATION_PREPARATION.md, handoff §§49–51. No Phase 7 acceptance changed.

## Block A — Portal foundation

**Current operational preparation (§66, applies to P8-01–11):** Foundation, B and C deployed;
Batch C `0Afaj00000pOUsQCAW` 6/6. Live profile denials intact/unassigned; guest has zero object/
custom Apex grants; Plus 5 total/0 used; A/B exact Contact/Account/role-qualified owner verified,
but no customer users or own positive records. Site remains UnderConstruction/never activated.
Prior site-export review demonstrated no meaningful regression and was not reopened. Read-only
Builder visual review blocked by disconnected browser; anonymous check blocked by local TLS trust.
Concrete ownership ledger/service-consent design, one-Home composition plan, supported identity/
sharing/revocation procedure, native-write proof gates, executable customer UAT and consolidated
category-specific approval register are prepared. No force-app/source deployment or successful
tests repeated, no operational writes. Original criteria/Phase 1–7 exceptions remain intact; M4
NOT accepted. Current evidence: `evidence/P8/OPERATIONAL_PREPARATION/verification.json`.
All eleven statuses/approvals: `docs/planning/P8_OPERATIONAL_COMPLETION_REGISTER.md`.
Older dated release/local-only/email/profile/site statements below are historical, not current gates.

**Current live security (§64):** exact combined Batch B Quick Deploy `0Afaj00000pIP10CAG`
succeeded. EmailAdministration/EmailTemplateManagement now false; all prior 33 object/483 field/
23 system denies remain effective and base Case Create/Edit off. Profile still unassigned; no
customer grants/membership/sharing/publication changes. Earlier residual-email statements below
are historical. Evidence: `evidence/P8/BATCH_B_DEPLOYMENT/P8_BATCH_B_DEPLOYMENT_2026-10-27.md`.

**Latest profile-only deployment (§62, 2026-10-27 UTC):** `0Afaj00000pJTk5CAG` Succeeded,
1/1 component, 0 component/test errors, 0 tests (metadata-only). Live Case Create/Edit disabled;
33 object/483 field/23 supported system denials effective. EnableNotifications remains mandatory.
EmailAdministration and EmailTemplateManagement flags still true; profile unassigned, broader
changes stopped pending owner disposition. No Batch B deployment. Evidence:
`evidence/P8/PROFILE_SECURITY_DEPLOYMENT/P8_PROFILE_SECURITY_DEPLOYMENT_2026-10-27.md`.

**Latest remediation (§61, 2026-10-27 UTC):** explicit-deny profile correction prepared locally,
not deployed: 33 objects/483 fields/23 supported system denies; keep only base Account/Contact
Read plus Contact.AccountId and license-required EnableNotifications (Send Outbound Messages).
Profile-only `0Afaj00000pJ0QMCA0` succeeded. Combined `0Afaj00000pILVGCA4` passed 12/12 with
78.761% Batch B coverage; current-source strengthened run `0Afaj00000pIz4VCAS` also Succeeded,
12/12 tests, 0 errors, 78.761%. Live
profile still Case Edit/unassigned; residual unsupported metadata capabilities documented.

**Latest 2026-10-26 (§60):** exact five-component foundation Quick Deploy `0Afaj00000pGvwECAS`
succeeded (5/5, no errors; reused 7/7 validation tests and 89.19% controller coverage). Live
profile least privilege is **REFUTED**: 35 object grants incl. Case Create/Edit and 26 enabled
system permissions; no users assigned. Do not provision it. No external users/memberships/shares
or publication. Profile-only explicit-deny repair needs separate approval; internal permissions/
business records/OWD preserved except two platform System Admin Apex grants for the new classes.
Evidence: `evidence/P8/FOUNDATION_DEPLOYMENT/P8_FOUNDATION_DEPLOYMENT_2026-10-26.md`.

Demoable outcome: *one external user logs in and sees only their own data.*

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P8-01 | Experience Cloud site scaffold | Digital Experiences enabled **only after owner authorization** (logged in `metadata-log/`); site created; My Domain URL resolves; site metadata from source where deployable, otherwise click-steps + ledger | D4 owner authorization, P0-09 (V1) | Site created 2026-10-26 **unpublished** (not accepted): `evidence/P8/SITE_CREATION/P8_01_SITE_CREATION_2026-10-26.md`; live-site screenshot still pending | ADMIN, DOC |
| P8-02 | External access model | External user model selected **after licence verification** (`EXPERIENCE_PORTAL.md` V2–V5); relationship-anchored sharing (Sharing Set where supported, else Apex managed sharing); negative test: external user cannot read another Account's Case/Service_Visit/Vehicle/Loyalty | P8-01, P1-11 | `evidence/P8/ext_access_denied.png` | SECURITY |
| P8-03 | Portal Apex controllers + tests | Controllers `with sharing` **and** relationship-filtered **and** CRUD/FLS-checked; bulk-safe; tests include `System.runAs` cross-customer negative tests (per object) | P8-02 | `evidence/P8/portal_tests.txt` | APEX, TEST |

## Block B — Customer self-service components

**Latest §71 — final development deployment complete:** exact `manifest/p8-broker-local.xml`
Quick Deploy `0Afaj00000pPottCAC` Succeeded, 34/34, zero errors. Reused validation
`0Afaj00000pPiV7CAK` (43/43, broker 98.039%) and prior local UI 25/25; no tests rerun. P8-05
own Vehicle details/photos and P8-07 consent/ownership/idempotent booking now DEPLOYED, not
operationally accepted. All 54 component files match submitted source; existing customer security,
users/assignments/membership/sharing, 17 business-object fingerprints, 64 page/site XML files and
scheduler config preserved. No customer Vehicle/Model/ledger CRUD, no native Visit Create added.
Ledger empty; reviewer set unassigned; portal UnderConstruction/never activated; no scheduler/Git/
operational change. Actual ownership/service-consent data, two approved customers/access, page
placement, controlled publication and real A/B/security/accessibility UAT remain gated. No M4
acceptance. Evidence/shortest operational sequence: `evidence/P8/BROKER_DEPLOYMENT/RESULT.md`.
Earlier local-only deployment statements below are historical, not current release status.

**Latest §70 — P8-05/P8-07 local completion:** approved broker now provides whitelisted own
Vehicle details/photos and guarded/idempotent service requests with independent service consent,
current expiry/revocation/conflict checks and existing capacity/intake. Native Vehicle/Model/ledger
CRUD and Visit Create remain denied. Check-only `0Afaj00000pPiV7CAK` Succeeded: 34 components,
43/43 tests, zero errors; broker coverage 98.039%, facade 87.857%, capacity 97.753%, intake 100%.
Local UI/source/state tests 25/25. Ledger source unchanged. Exact separate deployment scope:
`manifest/p8-broker-local.xml`; evidence `evidence/P8/BROKER_COMPLETION/RESULT.md`.
NOT deployed or operationally accepted; approved ownership/service-consent data, identities/access,
placement/publication and actual customer/accessibility UAT remain gated. No Git operations or
live changes. Older ownership-blocked/local-failed statuses below are historical, not current code.

**Latest §69 recovery:** actual fixture cause measured: new reviewer lacked Vehicle VIN/Reserved_By
FLS that the running user receives through permission sets; API 68 defaults database operations
to USER_MODE. Test-only internal no-bypass fixture builder, evidence-query gating and explicit
privileged app-share/integrity maintenance modes corrected this without customer rights changes.
Check-only `0Afaj00000pNyKhCAK` Succeeded, 24 components, 11/11 tests, zero errors. Coverage:
guard 92.593%, service/reconciler/trigger 100%. Ledger/remove-only reconciler now validated, not
deployed or scheduled. P8-05/P8-07 remain safely disabled: exact-expiry native access cannot rely
on scheduled cleanup or sharing reasons. One concrete server-mediated/no-native-CRUD alternative
awaits the architecture decision in `docs/architecture/P8_NATIVE_VEHICLE_ACCESS_DECISION.md`.
Evidence/scope: `evidence/P8/OWNERSHIP_RECOVERY/RESULT.md`. Previous failures below historical.

**Latest §68:** corrected User lookup SetNull and sharing-reason fullNames accepted by actual
check-only `0Afaj00000pPMPlCAO` (zero component errors). Overall Failed: 1/6 tests succeeds;
five fail in OwnerPortalOwnershipTest.fixture line 26 on Vehicle field access. No speculative
permission/fixture patch/retry after failure. Independently prepared remove-only share reconciliation
Batchable/Schedulable and test source, NOT Salesforce-validated/activated. Managed sharing reason
and recalculation do not provide clock expiry; scheduler pruning is eventual, no hard deadline.
No external rights broadened; P8-05/P8-07 remain incomplete/fail-closed. Candidate manifest
`manifest/p8-ownership-reconciliation-local.xml` is NOT deploy-ready. Exact results, errors,
timing limits and owner action: `evidence/P8/OWNERSHIP_COMPLETION/RESULT.md`.

**Latest local ownership attempt (§67):** approved ledger implementation started, independent
27-file ledger/reviewer/trigger/test candidate prepared in `manifest/p8-ownership-ledger-local.xml`.
Check-only `0Afaj00000pOJ7PCAW` Failed: 14 component errors, zero tests. User lookup Restrict
unsupported; both SharingReason fullNames missing, causing dependent field/Apex errors. Stopped
per repository escalation; no repair/retry/deployment. Native timed-share revocation/hierarchy
proof gate remains unresolved. **P8-05/P8-07 NOT completed**; existing fail-closed UI/controller
unchanged and no external Vehicle extension. No live ownership/data/user/sharing/site changes.
Exact source, validation errors, limitations and owner actions:
`evidence/P8/OWNERSHIP_IMPLEMENTATION/OWNERSHIP_LOCAL_RESULT.md`. Original criteria remain intact.

**Current release (§64):** exact validated ten components deployed together as `0Afaj00000pIP10CAG`,
10/10, 0 errors, reused 9/9 tests and 86.667% coverage. All nine Batch B components live plus the
two-email-deny profile. Source parity and unchanged users/assignments/members/shares/business
fingerprints verified. No real customer operational acceptance; ownership still blocks P8-05/07.
Subsequent six-bundle UI polish is local Batch C, not a Batch B redeploy. Evidence:
`evidence/P8/BATCH_B_DEPLOYMENT/P8_BATCH_B_DEPLOYMENT_2026-10-27.md`.

**Latest local closeout (§63):** changed Batch B + two email-deny profile entries pass check-only
`0Afaj00000pIGp0CAG`: 10 components, 9/9 tests, 0 errors, controller coverage 86.667%; UI-state
tests 12/12. P8-04 dashboard, P8-06 chronological mileage/history, P8-08 Cases/public comments,
P8-09 read-only ledger are implemented/scoped-tested, not operationally accepted. P8-05 details/
photos and P8-07 appointment creation remain genuinely ownership-blocked with safe disabled states.
No ownership associations invented; no Batch C started. Previous `0Afaj00000pIz4VCAS` remains
historical evidence. Two email flags CAN be denied via explicit profile metadata; candidate
effective flags/CRUD assertions pass. Current live true-flag Plus user reports EmailTemplate
Create=true (separate failed harmlessness probe), so keep unassigned until approved correction.
Exact nine-component Batch B / ten-component combined scopes and final evidence:
`evidence/P8/BATCH_B_COMPLETION/P8_BATCH_B_COMPLETION_2026-10-27.md`. No deployment this turn.

**Latest bounded resolution (§61):** diagnostic proved the second Case had been rebound to A's
Contact because A's external user owned it. Corrected fixture owner to B and asserted persisted
Contacts; no production filtering change or relaxed negative. Isolation and new no-Case-Edit
Case-create/routing tests pass in combined `0Afaj00000pILVGCA4` (12/12 incl. foundation; Batch B
coverage 78.761%). Current-source final strengthening `0Afaj00000pIz4VCAS` also Succeeded,
12/12, 0 errors, 78.761%. Previous
failed assertion/69.027% below is historical. No Batch B deployment or block acceptance; vehicle
ownership remains untouched/unapproved. Current evidence:
`evidence/P8/BLOCKER_REMEDIATION/P8_BLOCKER_REMEDIATION_2026-10-27.md`.

**Authorized local implementation started after foundation deployment; no Batch B deployment.**
Nine components in `manifest/p8-batch-b-local.xml`: controller/test, unassigned Batch B permission
set and six LWCs. UI-state tests 7/7. Check-only `0Afaj00000pGPzbCAG`: 9 components compile,
2/3 tests pass, 69.027% coverage; Case isolation assertion expected1/actual2 blocks further work
pending diagnostic owner decision. No relaxed assertion/retry. P8-04 composition partial;
P8-05 owned details/photos and P8-07 wizard/create are deliberately blocked by unapproved
ownership; P8-06 history, P8-08 Cases/comments and P8-09 loyalty have local paths but lack complete
positive/security acceptance. None accepted. Preserve the original criteria/evidence paths below.
Exact per-block status, blocker and proposed nine-component scope requiring later approval:
`evidence/P8/BATCH_B/P8_BATCH_B_LOCAL_2026-10-26.md`; handoff §60.

Demoable outcome: *customer completes a service request end-to-end.*

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P8-04 | Portal dashboard home LWC | Login-state aware; authenticated widgets (next appointment, vehicle, points, open cases); no guest data exposure | P8-03 | `evidence/P8/dashboard.png` | LWC |
| P8-05 | My Vehicles LWC | Owned vehicles list + detail; `Vehicle__c.Photo__c` renders; missing-image fallback; access only via filtered Apex (Public R/W object not directly granted) | P8-03, P7-22 | `evidence/P8/my_vehicles.png` | LWC |
| P8-06 | Service history LWC | `Service_Visit__c` + linked Cases timeline, mileage over time | P8-03, P6-05 | `evidence/P8/service_history.png` | LWC |
| P8-07 | Service appointment request LWC | LWC wizard (per `AUTOMATION_DIRECTION.md`, **not** Flow) creates `Service_Visit__c` via Apex; reuses P6-01 capacity guard; write isolation enforced | P8-03, P6-01 | `evidence/P8/appt_request.png` | LWC, APEX |
| P8-08 | Case tracking LWC | List / create / view status; comment; owner routed per P6-02 (subject to V5) | P8-03, P6-02 | `evidence/P8/case_tracking.png` | LWC, APEX |
| P8-09 | Loyalty & rewards LWC | Points balance, tier, `Loyalty_Transaction__c` history (read-only); access only via filtered Apex | P8-03, P6-06 | `evidence/P8/loyalty.png` | LWC |

## Block C — Polish, evidence, governance

**Current §66:** Batch C is deployed; accessibility and actual-persona UAT NOT RUN. The prior
SiteDotCom investigation found no demonstrated meaningful regression; do not reopen absent new
evidence. Use `docs/planning/P8_OPERATIONAL_COMPLETION_REGISTER.md` and
`evidence/P8/uat/OPERATIONAL_CUSTOMER_UAT.md` for the current operational sequence. Only Home
is Builder-exposed; do not invent five standalone page placements. No new test/deploy/site save.

**Current deployment (§65):** Batch C deployed via standard exact six-bundle manifest, job
`0Afaj00000pOUsQCAW`, Succeeded, 6/6, zero errors/tests. Quick Deploy returned
`INVALID_ID_FIELD: Source validate did not run tests in the org`; authorized standard fallback used.
All 24 bundle files match validation; no tests rerun. Before/after users/permissions/memberships/
shares/business fingerprints and 65 page/site XML files compare equal. SiteDotCom binary export
hash differs: preservation exception escalated, cause unestablished; no further investigation or
corrective changes without owner response. Site remains UnderConstruction/FirstActivationDate null.
P8-10 code now deployed; P8-11 preparation delivered, actual UAT not passed. P8-05/07 remain
ownership-blocked; no operational changes or Phase 8 full acceptance. All eleven item statuses,
raw evidence, Git status and exact owner review action:
`evidence/P8/BATCH_C_DEPLOYMENT/P8_BATCH_C_DEPLOYMENT_2026-10-27.md`.
Earlier local-only statuses below are historical. Original acceptance criteria remain unchanged.

**Local implementation delivered, acceptance incomplete (§64):** six existing LWCs have responsive
native layouts, owned text branding, focus/form semantics and announced states. Check-only
`0Afaj00000pJzGvCAK` Succeeded, 6 components, 0 errors, 0 Apex tests; local state/source/contrast
tests 19/19. P8-11 Activate-persona demo, real-persona UAT matrix/evidence register and actual-versus-
blocked architecture seam prepared. **No Batch C deployment or real customer UAT pass**. P8-10
live responsive/keyboard/AT/screenshots and brand review remain pending. Preserve ownership,
users/memberships/sharing, page placement and publication gates; M4 not passed. Exact next metadata
scope: `manifest/p8-batch-c-local.xml`, six LWC bundles only. Evidence/exceptions:
`evidence/P8/BATCH_C/P8_BATCH_C_LOCAL_2026-10-27.md`,
`docs/planning/P8_BATCH_C_ACCEPTANCE_EXCEPTIONS.md`. Original criteria below remain intact.

Demoable outcome: *presentable, mobile-responsive, documented.*

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P8-10 | Responsive polish + branding + accessibility | Mobile/desktop layouts; brand colours/logo only (no third-party assets); keyboard/focus/contrast pass | P8-04…P8-09 | `evidence/P8/responsive_*.png` | LWC, ADMIN |
| P8-11 | Portal demo script + UAT + seam note | `evidence/DEMO_SCRIPTS/portal.md` opens with "Activate persona"; UAT steps; `docs/architecture/EXPERIENCE_PORTAL.md` states real vs simulated (incl. fallback) | Block B | doc diff + `evidence/P8/uat/` | DOC |

**Fallback (documented, not implemented without approval):** if Experience Cloud or the
external-user licence model is unavailable, the labelled **SIMULATION** path in
`DEMO_ORG_MASTER_PLAN.md` §4.2 (permission-set Lightning app + self-service screen flow) applies.
Portal LWCs P8-04..P8-09 can be re-hosted there.

**Exit gate (M4):** external access model verified against measured licences; cross-customer
negative tests pass for every exposed object; portal components render their own-account data only;
responsive pass captured; seam note written; **or** the labelled SIMULATION fallback is
demonstrated (owner D5) with the licensing gap documented. No build starts until D4 authorization.

---

## Post-Phase-8 / Future Enhancements

### Northgate Vehicle Studio — Interactive Car Configurator

**Status: future proposal registered; implementation is not authorized.** Schedule only after
Phase 8/M4 and a separate owner-approved scope. This proposal adds no Phase 7/8 acceptance
criteria, phase number, milestone or counted delivery task. Ongoing Phase 7 work continues
unchanged. The existing 145-task baseline remains intact.

**Purpose:** let a customer or authorized salesperson explore a proposed vehicle appearance,
then optionally save that proposal and associate it with existing sales workflows. Visual
customization is not a VIN-level availability check, reservation, factory order or price offer.

#### Proposed implementation stages and preliminary acceptance criteria

| Stage | Scope and simplest technical option | Dependencies | Preliminary acceptance criteria |
|---|---|---|---|
| 1 — Exterior colour preview (first release) | LWC with native labelled colour controls and prepared, consistent-view images per supported model/colour; switch the image source rather than recolouring arbitrary stock photos. No rendering library or server-side pricing call is needed for the preview. | Approved model/colour list; licensed prepared assets and rights register; static-resource budget; intended Lightning/Experience surface verified | Every supported colour displays the correct prepared asset and selected label; unsupported combinations are clearly marked, not fabricated; missing images show a useful fallback; keyboard/mobile use works; selecting a colour changes no inventory, reservation, Opportunity, Quote or CP2 price. |
| 2 — Interior and option exploration | Add interior colour, upholstery, trim, wheels and accessories using prepared views or aligned image layers where practical. Maintain an explicit supported-combination list. Optional pre-rendered multi-angle frames can provide rotation without a 3D engine. | Stage 1 accepted; additional asset coverage, compatibility rules, licensing and measured loading budget | Supported combinations render consistently; incompatible/unavailable visual combinations are explained; exterior/interior view switching retains selections; rotation, if included, has buttons as well as drag/touch controls. Appearance selections remain unpriced unless explicitly mapped and approved in Stage 3. |
| 3 — Save and sales-workflow handoff | Save a versioned proposed configuration for a permitted customer; reload it and optionally link it to an existing Opportunity/Quote. Evaluate a minimal dedicated proposal record with customer/transaction lookups and a validated option snapshot; schema is undecided, not metadata authorization. | Stages 1/2 as applicable; approved storage/retention and customer-access model; current Opportunity, Quote and CP2 contracts; separate approval for any catalogue/price mapping | Save/reload preserves model, option identifiers and asset version; unauthorized users cannot read, overwrite or link another customer's proposal; stale/unsupported options are flagged on reload. Linking a proposal alone does not create lines, reserve a VIN or reprice a Quote. Explicit approved priced selections use the existing quote/pricing entry point and pass CP2 regression checks. |
| Optional later stage — Interactive 3D | Evaluate a locally packaged WebGL renderer (for example Three.js) or a standards-based model viewer against LWC/LWS before choosing either. Use optimized, licensed models and textures; retain the image-based viewer. No library is selected now. | Separate owner approval; verified LWC/LWS/CSP compatibility; renderer/model rights; device, GPU, resource-size and maintenance budgets | Rotation and supported material/option changes work on the agreed device matrix; rendering stays within measured budgets; keyboard alternatives, reduced-motion behavior and context-loss/unsupported-device fallbacks work; image-based configuration and saving still work without 3D. |

#### Inventory and CP2 pricing boundaries

- A visual configuration expresses a preference for a model; it does not assert that a matching
  `Vehicle__c`/VIN exists. Check actual inventory separately and show unavailable/unverified
  status truthfully. An existing vehicle's recorded colour, trim or availability is not rewritten.
- Exterior/interior colours, upholstery, trim, wheels and accessories are **unpriced visual
  options by default**. Do not infer a premium from a colour/trim name or from the viewer.
- Any priced option requires an explicit approved mapping to the existing Product2/PricebookEntry
  catalogue and compatibility rules. A selected visual trim is not automatically a CP2 trim
  premium or a substitute for the actual primary-vehicle pricing basis.
- Preserve accepted CP2 rule selection, buyer/vehicle context, calculations, rounding, adjusted
  totals, approval thresholds and Quote behavior. Reuse the current supported pricing path;
  do not build another calculator in the configurator. Previewing or saving a proposal does not
  overwrite accepted Quote values. Future integration acceptance includes unchanged-price tests
  for visual-only options and regression of existing priced/approval paths.

#### Technical feasibility, dependencies and risks

- **LWC and Lightning Web Security:** prefer native LWC image rendering and controls first.
  If a later renderer needs direct DOM/canvas access, isolate its owned container (for example
  `lwc:dom="manual"` where required), load approved packaged scripts using Salesforce's resource
  loader, and test under actual LWS. Do not assume a browser library, custom element, module or
  worker works unchanged inside Salesforce; no disabling LWS or bypassing CSP is proposed.
- **Static resources and assets:** verify current per-resource, aggregate and transfer limits
  plus actual headroom before selecting asset counts/packaging. Reference versioned prepared
  assets through static-resource URLs, preserve existing `NG_VehicleImages` paths and licenses,
  and retain source/derivative rights. Current P7 stock photos do not imply matched colour/interior
  views or 3D rights. Asset production and combinations may be the largest cost.
- **Rendering performance:** load the initial image first, lazily load other views, bound
  preloading and image/texture sizes, and release listeners/GPU resources on component teardown.
  Establish measurable initial-load, interaction, payload and memory budgets on representative
  mobile/desktop devices before implementation; verify frame rate only for optional rotation/3D.
- **Accessibility:** provide text names and selected state, keyboard-operable controls, visible
  focus, useful image descriptions and adequate contrast. Never use colour alone to convey
  selection. No mandatory autoplay or drag-only interaction; respect reduced motion and provide
  a non-canvas alternative with the same configuration choices.
- **Saving and customer access:** resolve customer identity, record relationships, CRUD/FLS,
  sharing and explicit relationship checks before choosing persistence. Validate option IDs and
  linked customer/Opportunity/Quote IDs on the server; cross-customer negative tests are required.
  Do not assume external-user licensing, Sharing Sets or guest write access. Experience Cloud
  hosting depends on the approved Phase 8 access model and capability verification.
- **Risk controls:** combinatorial assets, licensing, LWS/CSP incompatibility, mobile GPU limits,
  stale saved options and misleading inventory/pricing claims remain open. Start with a small
  prepared exterior-colour set; expand only after its acceptance and measured need. No paid
  service, external hosting, new dependency, schema change or 3D purchase is approved here.

Future implementation needs a bounded owner-approved plan, targeted LWC/browser/accessibility
checks, save/reload and customer-isolation tests when persistence is added, and CP2 regression
evidence when the sales handoff is introduced. This registration creates no current release gate.

## Summary counts

| Phase | Items | Purpose |
|---|---|---|
| P0 | 12 | Org acquisition, settings, keep-alive, verification, repo/CI — **no metadata** |
| P1 | 22 | Data model, security, users (persona switcher model), bypass mechanism, VinValidator, persona script, CI External Client App |
| P2 | 15 | First vertical slice |
| P3 | 12 | Trade-in + simulated CPQ |
| P4 | 13 | Financing + delivery |
| P5 | 20 | Synthetic data (storage-budgeted) + reporting depth |
| P6 | 17 | Service, cases, entitlements, Knowledge, loyalty |
| P7 | 23 | Developer depth, Agentforce/Data Cloud, Experience, vehicle images, governance |
| P8 | 11 | Customer Experience Portal (Experience Cloud + LWC) — **M4** |
| **Total** | **145** | |

## Explicitly out of scope

- Scratch orgs, packaging, AppExchange, Dev Org promotion.
- Paid/licensed products **not** included in this DE edition: Marketing Cloud, Loyalty
  Management, Revenue Cloud/CPQ, Field Service, Financial Services Cloud, Health Cloud, B2B
  Commerce, Shield, MuleSoft, CRMA, **Automotive Cloud** (concept mapping only, P7-19).
  Each gets a seam note, never a build.
- **In scope because they are included in this edition (verified at P0-09):** small
  Agentforce build (P7-15), small Data Cloud build (P7-16), Knowledge (P6-15),
  Entitlements + Milestones (P6-14), Experience Cloud site (P7-18).
- Real trademarks in fictional record/app identities, real VINs, real people, real customer data.
  Narrow owner-approved P7-22 exception: appropriately licensed real automotive photographs may
  retain incidental OEM badges; no endorsement or deceptive branding removal. Fictional inventory
  identities and all other data restrictions remain unchanged.
- Resume, cover letter, application, or tracker artifacts.
- Multi-org topology beyond the two-org `ng-dev`/`ng-demo` model (documented in P7-13).
