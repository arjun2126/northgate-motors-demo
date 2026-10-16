# Demo Org Backlog — Northgate Motors

**Status:** PLANNING ONLY. No items are approved for execution.
**Source of truth for scope and sequencing.** Conventions and org rules live in
`DEMO_ORG_MASTER_PLAN.md`; field-level design in `DEMO_ORG_DATA_MODEL.md`; storage budget in
`DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §2.

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
| P5-03 | Seed data loaded | All volumes from data plan §2.1 (1,843 clean + 30 legacy + 250 activities) | P5-02 | Counts match table exactly; Storage Usage ≤4.0 MB → `evidence/P5/storage.png`, `evidence/P5/counts.txt` | DATA |
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

---

# Phase 6 — Service, cases and post-sale

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P6-01 | Service visit scheduling flow | Booking with **before-save capacity flow** (`ServiceVisit_EnforceCapacity` vs `Rooftop__c.Service_Capacity__c`); `VR_ServiceVisit_FutureForNew` for new-visit timing | P1-16 | Over-capacity booking rejected → `evidence/P6/capacity_block.png` | FLOW, APEX |
| P6-02 | Service intake case flow | Case created from visit; routed to `Q_Service_Intake` | P6-01, P1-10 | Case owner is the queue → `evidence/P6/case_queue.png` | FLOW, ADMIN |
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

**Exit gate:** post-sale lifecycle works; SLA (entitlements) and Knowledge demoable; all paid
seams documented.

---

# Phase 7 — Developer depth, AI, governance and polish

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
| P7-22 | **Vehicle images** | ~30 AI-generated fictional vehicle photos, no logos, ~50 KB `.webp` each, one per `Vehicle_Model__c`; static resource **`NG_VehicleImages`** deployed; `Image_Path__c` populated (P1-02 field); `Photo__c` formula renders for demo records | P1-02, P0-09 (storage limit) | Static resource visible; `Vehicle__c.Photo__c` renders on a record page → `evidence/P7/vehicle_images.png` | ADMIN, DOC |
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

## Block A — Portal foundation

Demoable outcome: *one external user logs in and sees only their own data.*

| ID | Item | Acceptance criteria | Dependencies | Evidence | Tags |
|---|---|---|---|---|---|
| P8-01 | Experience Cloud site scaffold | Digital Experiences enabled **only after owner authorization** (logged in `metadata-log/`); site created; My Domain URL resolves; site metadata from source where deployable, otherwise click-steps + ledger | D4 owner authorization, P0-09 (V1) | site live → `evidence/P8/site_live.png` | ADMIN, DOC |
| P8-02 | External access model | External user model selected **after licence verification** (`EXPERIENCE_PORTAL.md` V2–V5); relationship-anchored sharing (Sharing Set where supported, else Apex managed sharing); negative test: external user cannot read another Account's Case/Service_Visit/Vehicle/Loyalty | P8-01, P1-11 | `evidence/P8/ext_access_denied.png` | SECURITY |
| P8-03 | Portal Apex controllers + tests | Controllers `with sharing` **and** relationship-filtered **and** CRUD/FLS-checked; bulk-safe; tests include `System.runAs` cross-customer negative tests (per object) | P8-02 | `evidence/P8/portal_tests.txt` | APEX, TEST |

## Block B — Customer self-service components

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
- Real trademarks, real VINs, real people, real customer data.
- Resume, cover letter, application, or tracker artifacts.
- Multi-org topology beyond the two-org `ng-dev`/`ng-demo` model (documented in P7-13).
