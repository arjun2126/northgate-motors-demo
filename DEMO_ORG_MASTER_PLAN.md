# Demo Org Master Plan — Northgate Motors Dealership

**Status:** PLANNING ONLY. No build has started. No metadata, code, or data has been generated.
**Approval gate:** Do not create metadata until the owner approves this plan and the accompanying backlog.

| | |
|---|---|
| Target orgs | Two permanent Developer Edition orgs: `ng-dev` (build/UAT) and `ng-demo` (stable demos). **No scratch org, ever.** |
| Concept | Car dealership, full lead-to-sale + post-sale lifecycle |
| Source of truth | Git repository (this folder), private GitHub remote under `arjun2126`; deployed to `ng-dev`, validated into `ng-demo` |
| Research input | `/Users/arjunsubramanya/Documents/JobSearch/SALESFORCE_MARKET_SKILLS_RESEARCH.md` |
| Companion files | `DEMO_ORG_BACKLOG.md`, `DEMO_ORG_DATA_MODEL.md`, `DEMO_ORG_SYNTHETIC_DATA_PLAN.md`, `DEMO_ORG_SETUP_CHECKLIST.md` |
| Audience | The owner, plus a future executing agent |

---

## 1. Purpose and scope

Northgate Motors is a fictional four-rooftop dealership group used as an advanced Salesforce
demo. It is deliberately broad enough to demonstrate four skill domains in one org:

- **Admin** — security model, automation, data quality, reports and dashboards.
- **Developer** — Apex with tests, LWC, async patterns, callouts, events.
- **Analyst** — pipeline, inventory aging, service SLA, loyalty and data-quality reporting.
- **Support** — Case management, service scheduling, escalation, customer follow-up.
- **Light architect** — native-vs-simulated-vs-licensed decisions, naming governance, release
  process, reset strategy, documented trade-offs.

The demo is designed to survive long-term iterative building: features can be added, revised,
and reset without destroying the org or invalidating prior work.

### Explicit non-goals

- No scratch orgs and no short-lived-org patterns (scratch ID, `org create scratch`, snapshot promotion).
- No application packages, no AppExchange packaging, no unlocked-package versioning.
- No resume, cover letter, or job-application artifacts (this folder is build planning only).
- No paid cloud subscriptions. Where a licensed product is required, the plan says so and
  prescribes a simulation or a documentation-only treatment. Features that ship *included*
  with this Developer Edition within limits (Agentforce, Data Cloud — see §4.1) are not
  subscriptions and are built for real after Phase 0 verifies them.
- No real customer data, real VINs, or real people.

### 1.1 Agent roles

| Agent | Responsibility | Hard limits |
|---|---|---|
| **Workflow agent** (this one) | Plans; creates and maintains these five `.md` files only | No folders, no scaffold, no code, no scripts, no git, no org access, no `sf` commands, no metadata, no data |
| **Build agent** (separate session) | Executes backlog items in order, stops at each phase gate, attaches the evidence artifacts named in the backlog | Never proceeds past a gate without owner approval; works only against `ng-dev` / `ng-demo` |
| **Owner** | Approves every gate; creates all credentials, orgs, GitHub resources, and Settings clicks that require a human | Nothing is executed on the owner's behalf without explicit approval |

---

## 2. Fictional business profile

Anchor everything in this profile so that screenshots, reports, and demo scripts stay coherent.

| Attribute | Value |
|---|---|
| Company | Northgate Motors (fictional) |
| Brand short code | `NG` |
| Roof tops | 4 — Northgate Downtown, Northgate North, Northgate Airport, Northgate Service Centre |
| Markets | Canada (Ontario), currency CAD, locale `en_CA`, time zone `America/Toronto` |
| Staff | **Persona model (Stop B measured: 4 Salesforce licences [2 used, 2 free] + 6 Platform per org):** Salesforce users = **Admin** (`ngadmin`), **Sales Rep** (`ngrep`, real login), **Service Advisor** (`ngsvc`, real login), **Persona Switcher** (`ngpersona` — manager/finance demos via PSG swap by `scripts/persona.sh <manager\|finance>`); Platform users = **Inventory Coordinator** (`nginv`), **Service Technician** (`ngtech`); Integration = `dms.integration`. Login As does **not** lift licence limits (§6.1 of the data model). 14 fictional staff members modelled in `Staff__c` as the reporting dimension, so dashboards group by staff without needing 14 logins. |
| Customer mix | Household buyers (majority), small business/fleet buyers, independent dealer trade partners |
| Vehicle makes | Invented makes only — `Aurelia`, `Cascadia`, `Meridian`, `Vantage`, `Halcyon`, `Kestrel`. **Never use real manufacturer brands** (trademark exposure in screenshots and public repos). |
| Lifecycle | Web/walk-in lead → qualify → test drive → trade-in appraisal → quote → financing → approval → delivery → service → loyalty → repeat purchase |

---

## 3. Org strategy for a permanent environment

### 3.1 The one rule

Two persistent Developer Edition orgs. Source of truth is **Git**, not the orgs. The orgs are
deployment targets that are rebuilt and refreshed, never deleted.

| Alias | Role |
|---|---|
| `ng-dev` | Build and UAT target. Feature branches land here first; churn is allowed. |
| `ng-demo` | Stable demo target. Only ever receives validated, test-passing releases. |

Release flow: feature branch → deploy to `ng-dev` → UAT → **validate-only** deploy to `ng-demo`
(`--dry-run` with `RunLocalTests`) → quick deploy → `git tag`. Never a scratch org.

### 3.2 Guardrails (hard constraints)

1. Never run `sf org create scratch`, `sfdx force:org:create -f config/*.json -d`, or any
   `--duration-days` org creation. Scratch orgs are for promotion-based pipelines and do not
   apply here.
2. Never run `sf org delete` / `sf org delete scratch` against the demo org.
3. Never run destructive metadata deploys without explicit written approval in a higher-priority
   session. See §7.4.
4. Never store org credentials, tokens, or passwords in this repository.
5. Never edit the System Administrator **profile**, and never use profiles to grant access
   (object permissions, FLS, record types). **Narrow exception:** small custom profiles hold
   *only* the default app and tab visibility (seamless-UX rule, guardrail 6); all access
   stays in permission sets and permission set groups. Profiles are not safely revertible
   in a source-controlled permanent org, which is why they are restricted to these two
   presentation settings.
6. **Seamless user experience.** Each demo user lands directly in their own app on login,
   with only the tabs that persona needs. The default app is set on the per-type custom
   profile (guardrail 5). Each app has its own tab list and its own home page.
7. **No-workaround rule.** Anything the build agent cannot deploy from source it must not
   work around: it writes exact click-by-click Setup steps for the owner, waits for the
   owner's "done", then verifies the result read-only and logs it in
   `metadata-log/README.md`.

### 3.3 Why a permanent org changes the build pattern

A scratch-org workflow assumes: build → test → promote → discard. That is not available. The
substitutes are:

| Scratch-org habit | Permanent-org substitute |
|---|---|
| Scratch org as clean-room test | Deploy to a **staging branch first**, or validate with `--dry-run` against the target org |
| `project deploy start` then discard | `project deploy start --dry-run` (validate only) → review → real deploy |
| Data seeded per scratch ID | Seeded into the permanent org, tagged by seed batch, and **reset in place** |
| Setup metadata from `config/project-scratch-def.json` | Setup changes made once in the org, then **retrieved** into Git under `metadata-log/` |
| Destroy org to reset | Delete only `SEED-%` tagged records; keep all metadata |

The practical consequence: this project uses **trunk-based development against two target
orgs** — `ng-dev` absorbs the churn, `ng-demo` only ever sees validated states — with Git tags
as release markers.

### 3.4 Org identity and metadata

- Enable **My Domain** and set a memorable domain before building anything (required for
  predictable login URLs, LWC, and flow test URLs).
- Record the org's My Domain URL in the setup checklist, not in code.
- Pin one API version across the project (`sfdx-project.json` `sourceApiVersion`) so deployments
  are deterministic. Verify against the org with `sf org display --verbose`.
- Confirm **source tracking** works (`sf project retrieve start --metadata CustomObject:Vehicle__c`).
  If the org does not report changes, fall back to explicit retrieve + diff; note the outcome in
  `metadata-log/README.md`.

### 3.5 Org keep-alive (expiry is a real risk)

New Developer Edition signups are "Developer Edition with Agentforce and Data Cloud" and are
deleted after **45 days without a login** (warning emails days 1–14; Salesforce Support can
reactivate days 15–44).

**The Connected-App exemption is not available to us (v2.1 correction).** Since Spring '26,
new orgs cannot create Connected Apps (UI or Metadata API) without Salesforce Support, and
DE orgs have no standard Support channel. Therefore:

1. **Human UI login to `ng-dev` and `ng-demo` at least every 30 days** — calendar reminder
   owned by the owner. Every login is appended to a login log table in
   `metadata-log/ORG_INFO.md` (date, org, who, why) so the cadence is auditable.
2. **Do not assume CI/API logins reset the inactivity timer.** Treat only an interactive
   human UI login as guaranteed keep-alive until Salesforce documents otherwise.
3. **CI auth is planned via an External Client App with JWT bearer**, created in **P1**
   (backlog P1-22) once users exist — not in Phase 0. It is a convenience for pipelines,
   not a keep-alive mechanism.
4. Record edition + expiry policy as stated by Salesforce in `metadata-log/ORG_INFO.md`,
   including the Spring '26 Connected App restriction with a citation.

Two orgs means two keep-alive obligations. If an org is lost, §3.6 rebuilds it from Git.

### 3.6 Org rebuild runbook (if an org expires anyway)

Target rebuild time: **≤ 4 hours** (signup + settings ≤ 1 h; metadata redeploy from Git
≤ 1 h; seed reload + verify ≤ 2 h). Metadata is always recoverable from Git; only the
seeded dataset must be regenerated, and the generator is deterministic.

1. **New DE signup** — owner signs up a fresh Developer Edition (real email, password
   manager), records org ID + signup date in `metadata-log/ORG_INFO.md`.
2. **Settings** — My Domain, `en_CA` / `America/Toronto` / CAD / calendar fiscal year /
   business hours / deliverability "System email only" (checklist 0-B/Stop C).
3. **Keep-alive clock starts** — first human UI login logged; 30-day reminder reset.
4. **Repo state wins** — clone/pull the repo; `git status` proves clean at the last
   release tag.
5. **Metadata redeploy** — `sf project deploy start --test-level RunLocalTests` from the
   last tag against the new org alias (aliases repointed: `sf org login web --alias ng-dev`
   or `ng-demo` as appropriate).
6. **Setup-only changes** — replay `metadata-log/README.md` entries in order (roles,
   picklists, anything not deployable from source).
7. **Seed reload** — `scripts/reset.sh full` path: regenerate CSVs for the stored
   `ANCHOR_DATE`, run the upsert loader, run `scripts/verify.sh` (data plan §8–§9), confirm
   Storage Usage ≤ 4.0 MB.
8. **Evidence spot-check** — one dashboard, one report, one UAT script re-signed; note the
   rebuild in the release notes with elapsed time against the 4-hour target.

---

## 4. Buildability ledger: native / simulate / verify / paid

This is the honesty section. Do not claim a feature exists in the free org unless it is in the
**BUILD NATIVE** bucket.

### 4.1 BUILD NATIVE (available in a standard Developer Edition org)

| Capability | Demo use |
|---|---|
| Lead, Account, Contact, Opportunity, Case, Task, Event, Campaign | Core lifecycle |
| Product2, Pricebook2, PricebookEntry, **standard Quote and QuoteLineItem** | Quoting and pricing |
| Record types, page layouts, list views, custom apps, tabs | UI and segmentation |
| Validation rules, duplicate rules, matching rules | Data quality gates |
| Assignment rules (Lead), escalation rules, auto-response rules | Intake and SLA |
| Flow — record-triggered, screen, scheduled, orchestrator-free | Primary automation |
| Approval processes | Discount and financing approvals |
| Apex, triggers, classes, test classes, Queueable, Batch, Scheduler, Platform Events | Developer surface |
| SOQL/SOSL, LWC, JS ES6 | Query and UI |
| Named Credentials + External Services + HTTP callouts | Integration simulation |
| Reports (summary, matrix, joined), dashboards, custom report types, folders | Analyst surface |
| Role hierarchy, OWD, sharing rules, queues, public groups, profiles, permission sets, permission set groups | Security model |
| Tasks, email templates, letterhead | Follow-up automation |
| Static resources (images) | `NG_VehicleImages` — ~30 AI-generated fictional vehicle photos (~50 KB webp each), displayed via formula field + LWC (data model §3.2/§3.3) |
| Agentforce — this edition includes ~150 LLM requests/hour | One service agent + one Prompt Builder template (backlog P7-15). **[VERIFY] in Phase 0** |
| Data Cloud — this edition includes 10 GB, 1 data space, manual refresh/publish only | One ingestion + identity-resolution demo (backlog P7-16). **[VERIFY] in Phase 0** |
| Lightning Knowledge (~10 articles) | Service answers and recall knowledge (backlog P6-15) |
| Entitlements + Milestones | Case SLA clocks (backlog P6-14) |
| Omni-Channel + Service Console | Routing + console demo (backlog P6-16) |
| Experience Cloud + 5 External Identity licences | One customer site with 1–2 external users (backlog P7-18). *React (Salesforce Multi-Framework) under evaluation for P7-18 only — conditional proposal, fallback authoritative: `docs/architecture/MF_REACT_P7-18.md`*. **Phase 8 (M4)** builds the full Customer Experience Portal on this surface (Experience Cloud + LWC only; `docs/architecture/EXPERIENCE_PORTAL.md`) — subject to licence verification and owner authorization (Digital Experiences not enabled yet). |
| Territory Management (Enterprise) | Rooftop territory design *(verify availability in Setup → Territory Management)* |
| Developer Edition org itself, My Domain, source tracking | Permanent-org mechanics |

### 4.2 SIMULATE (no license required — build with custom objects / Flow / Apex)

| Licensed product normally | Simulation approach |
|---|---|
| Vehicle / inventory module (none exists) | `Vehicle__c`, `Vehicle_Model__c`, `Rooftop__c` |
| Field Service scheduling | `Service_Visit__c`, `Test_Drive__c` custom objects + screen flows |
| CPQ / Revenue Cloud quote engine | Standard `Quote`/`QuoteLineItem` + `Price_Rule__mdt` + Apex price calculator + discount approval |
| Loyalty Management (tiers, accrual, redemption) | `Loyalty_Member__c`, `Loyalty_Transaction__c`, accrual Batch Apex, tier evaluation |
| Marketing Cloud / Account Journey Builder | Scheduled Flow + Email Alert + `Consent__c` + campaign membership |
| MuleSoft API-led integration | REST callout to a mock endpoint via Named Credential; contract stored as `docs/integration/API_CONTRACT.md` |
| Field marketing / journey consent | `Consent__c` object + Flow gates |

**Fallbacks** (reinstate only if Phase 0 verification fails, and label **SIMULATION** in every
artifact): Agentforce → Flow decision-table triage + invocable Apex with a prompt-shaped
template string (previous P7-15 design). Data Cloud → matching-rule documentation + custom
`Match_Candidate__c`-style logic via Flow. Experience Cloud → permission-set-restricted
Lightning app + self-service screen flow.

### 4.3 VERIFY (behaviour differs by org; confirm before designing around it)

These must be checked in the actual org during Phase 0. Record each result in
`DEMO_ORG_SETUP_CHECKLIST.md` § Verify-before-you-build.

| Item | How to verify |
|---|---|
| Person Accounts | Setup → Account → Person Accounts. **Recommendation: do NOT enable.** It is a one-way-ish behavioural change to Account/Contact and complicates a permanent org. Use `Account.Type = 'Household'` instead. |
| Multi-currency | Setup → Manage Currencies. If unavailable, set corporate currency to CAD once before any currency data is loaded. Loading currency records before this makes a later change painful. |
| Change Data Capture | Setup → Change Data Capture (object enablement) |
| Territory Management | Setup → Territory Management |
| Experience Cloud licences (expect 5 External Identity) | Setup → Company Information → licences |
| Agentforce availability + quota (expect ~150 LLM requests/hour) | Setup → Agentforce. Absent → SIMULATION fallback (§4.2) |
| Data Cloud availability (expect 10 GB, 1 data space, manual refresh only) | Setup → Data Cloud. Absent → architecture-note fallback (§4.2) |
| Knowledge, Entitlements, Milestones, Omni-Channel, Service Console | Setup → feature settings. Expected **standard in DE** — plan to build (P6-14/15/16); if genuinely absent, mark paid and do not build |
| Dynamic dashboard limit (expect 3) | Attempt a 4th dynamic dashboard; record the rejection |
| Static resource / file storage limit (expect generous, but measure) | `sf org list limits` → `FileStorageMB`; record cap + headroom before `NG_VehicleImages` is committed (checklist §0-E #21) |
| Duplicate Rules enforcement limits | Setup → Duplicate Rules |
| Web-to-Lead | Setup → Web-to-Lead (daily cap applies; forward address must be valid) |
| Report/dashboard folder behaviour in this org | Create folders, confirm sharing model |

### 4.4 PAID — document only, do not attempt to build

Marketing Cloud / Account Engagement · Loyalty Management · Revenue Cloud/CPQ · Field Service ·
Financial Services Cloud · Health Cloud · B2B Commerce · Shield/Event Monitoring · MuleSoft
Anypoint · Tableau CRM/CRMA · **Automotive Cloud** · Agentforce beyond the included request
quota · Experience Cloud beyond the included External Identity licences.

**Removed from this list in v2:** Data Cloud and Agentforce ship *included* with this edition
within limits (§4.1) and move to BUILD NATIVE pending Phase 0 verification. Automotive Cloud
stays licensed: the deliverable is a one-page concept mapping in `docs/architecture/`
(backlog P7-19), never a build.

For each of these, the deliverable is an **architecture note** in `docs/` that states: what the
real product does, what was built instead, and where the seam is. That seam documentation is
itself an architect-level signal; do not paper over it.

---

## 5. Naming conventions

Enforced from the first commit. Inconsistent naming is the fastest way to make a demo look
junior. A future agent must follow this table exactly.

### 5.1 API names

| Type | Convention | Examples |
|---|---|---|
| Custom object (singular) | `PascalCase__c`, noun | `Vehicle__c`, `Trade_In__c`, `Test_Drive__c`, `Financing__c` |
| Junction / detail object | `Parent_Child__c` | `Loyalty_Transaction__c` |
| Custom metadata type | `Noun__mdt` | `Price_Rule__mdt`, `Rate_Table__mdt`, `Loyalty_Tier__mdt`, `Lead_Routing__mdt` |
| Custom setting | `Noun__c` (hierarchy) | `Automation_Settings__c` (bypass flags) |
| Custom field | `PascalCase__c`, descriptive noun/adjunct | `VIN__c`, `Status__c`, `Appraisal_Amount__c`, `Is_Stale__c` |
| Formula field | `Is_…__c` or `…_Days__c` / `…_Age__c` | `Is_VIN_Valid__c`, `Inventory_Age_Days__c` |
| Roll-up summary | `<ChildPlural>_<Aggregate>` | `Open_Test_Drives__c`, `Loyalty_Points__c` |
| Standard field override | Salesforce API name | `Status`, `Rating`, `LeadSource` |
| Picklist value API | `Title_Case_With_Underscores`, stable | `In_Appraisal`, `Declined`, `Not_Contacted` |
| Record type | `<Object>_<Segment>` (API), label plain | `Vehicle_New`, `Opportunity_Retail`, `Case_Service` |
| Tab | `<Object>` | `Vehicle__c` |

### 5.2 Automation

| Type | Convention | Example |
|---|---|---|
| Flow | `<Object>_<Purpose>` | `Lead_Assign_By_PostalCode`, `TestDrive_Book_Screen`, `Quote_Apply_PriceRules` |
| Flow (scheduled) | `<Object>_<Purpose>_Scheduled` | `Vehicle_Age_Recalc_Scheduled` |
| Flow (subflow) | `<Object>_<Purpose>_Sub` | `Vehicle_Reserve_Check_Sub` |
| Approval process | `<Object>_<Purpose>Approval` | `Opportunity_DiscountApproval` |
| Validation rule | `VR_<Object>_<Rule>` | `VR_Vehicle_VIN17`, `VR_Opportunity_ClosedWonNeedsDelivery` |
| Assignment rule | `AR_<Purpose>` | `AR_Lead_PostalCode_RoundRobin` |
| Duplicate rule | `DR_<Object>_<Rule>` | `DR_Contact_Email` |
| Escalation rule | `ER_<Purpose>` | `ER_Case_HighPriority_4h` |
| Email alert | `EA_<Purpose>` | `EA_TestDrive_Reminder` |
| Workflow/field update (legacy, avoid) | Do not create. Use Flow. | — |

### 5.3 Code

| Type | Convention | Examples |
|---|---|---|
| Apex class — service | `<Domain><Verb>Noun` or `<Noun>Service` | `VINDecoderService`, `PaymentCalculatorService`, `LoyaltyAccrualService` |
| Apex class — trigger handler | `<Object>TriggerHandler` | `VehicleTriggerHandler` |
| Apex class — invocable | `<Purpose>Invocable` | `ReserveVehicleInvocable`, `ScoreTradeInInvocable` |
| Apex class — batch/queueable | `<Purpose>Batch` / `<Purpose>Queueable` | `LoyaltyTierEvalBatch`, `InventoryAgeQueueable` |
| Apex class — REST resource | `<Purpose>Resource` | `VINLookupResource` |
| Apex class — mock | `Mock<Thing>` | `VINServiceMock` |
| Apex test class | `<ClassName>Test` | `PaymentCalculatorServiceTest` |
| Apex test data factory | `TestDataFactory` (+ variants) | `TestDataFactory`, `VehicleTestDataFactory` |
| Trigger | `<Object>Trigger` | `VehicleTrigger` |
| Custom label | `<Area>_<Purpose>` | `Finance_Payment_Calc_Help` |

Coverage floor: **75% is the org minimum, 90% is the project target.** Every async, callout,
and bulk path gets a dedicated test.

### 5.4 Permission and security artifacts

| Type | Convention | Example |
|---|---|---|
| Permission set | `PS_<Area>_<Level>` | `PS_Sales_Rep`, `PS_Finance_Officer`, `PS_Service_Advisor`, `PS_Sales_Manager` |
| Permission set group | `PSG_<Function>` | `PSG_Rep`, `PSG_Service` on their real users; `PSG_Manager`, `PSG_Finance` swapped one-at-a-time on the Persona Switcher |
| Queue | `Q_<Purpose>` | `Q_Internet_Leads`, `Q_Service_Intake`, `Q_Finance_Review` |
| Public group | `PG_<Function>` | `PG_All_Sales`, `PG_Rooftop_Downtown` |
| Role | `<Function> <Level>` label | `CEO`, `VP Sales`, `Sales Manager — Downtown`, `Sales Rep`, `Finance Manager`, `Service Advisor`, `Service Technician` |

### 5.5 Reports, dashboards, templates, users

| Type | Convention | Example |
|---|---|---|
| Report folder | `<NN>_<Area>` (numeric prefix for order) | `01_Pipeline`, `02_Inventory`, `03_Service`, `04_Loyalty`, `05_DataQuality`, `90_Admin` |
| Report | `<Area>: <Metric>` | `Pipeline: Open Opportunity by Stage` |
| Dashboard folder | `<NN>_<Area>` | `01_Executive`, `02_Sales`, `03_Service` |
| Dashboard | `DM_<Area>_<Title>` | `DM_Exec_OperationsOverview` |
| Email template folder | `<Area>_Emails` | `Sales_Emails`, `Service_Emails` |
| Email template | `ET_<Area>_<Purpose>` | `ET_Sales_TestDriveConfirm` |
| Document/screenshot folder | `<Area>/<Phase>` | `evidence/P2_CoreLifecycle/` |
| Demo user username | `ng<role>@northgate.demo` | `ngadmin@…`, `ngrep@…`, `ngsvc@…`, `ngpersona@…`, `nginv@…`, `ngtech@…`, `dms.integration@…` |
| Demo user email | plus-addressed real inbox | `you+ngpersona@yourdomain.com` |

**Username note:** Salesforce usernames must be globally unique. Using `<role>@northgate.demo`
for the username plus a plus-addressed real email for delivery keeps inbox noise at zero and
makes the org self-documenting. Confirm mail delivery during setup; if deliverability is off,
activation emails simply will not arrive (see checklist § Email deliverability).

### 5.6 Seed-data tagging

Every generated record carries **one** tagging field — `Seed_Tag__c` — with the format:

```
SEED-<BATCH>-<OBJECT>-<NNNN>     e.g. SEED-03-VEH-0472
```

- **One field name everywhere**: `Seed_Tag__c` on standard *and* custom objects. No second
  external-ID field exists.
- Field properties on every seeded object: Text(80), **External ID**, **Unique**, and
  "Map during conversion" = **off** (custom field conversion mapping must stay unchecked).
- `<BATCH>` is the load-order number from `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §4 (batch 03 =
  vehicles, batch 07 = converted-lead triples, batch 98 = legacy dirty-import data,
  batch 99 = deliberately business-bad data).
- Upserts key on `Seed_Tag__c`; resets filter on `Seed_Tag__c LIKE 'SEED-%'`. This is what
  makes in-place reset safe and loads re-runnable.

---

## 6. Folder strategy

### 6.1 Filesystem (this repository)

```
Dealership Demo Org/
├── DEMO_ORG_MASTER_PLAN.md            ← this file
├── DEMO_ORG_BACKLOG.md
├── DEMO_ORG_DATA_MODEL.md
├── DEMO_ORG_SYNTHETIC_DATA_PLAN.md
├── DEMO_ORG_SETUP_CHECKLIST.md
├── sfdx-project.json                  (created in Phase 0)
├── .forceignore
├── .github/workflows/validate.yml     CI skeleton, DISABLED until P1-22 External Client App (P0-04)
├── force-app/main/default/            source-tracked metadata
│   ├── objects/  classes/  triggers/  lwc/  flows/
│   ├── permissionsets/  permissionsetgroups/  layouts/  customsettings/
│   ├── profiles/   ← only for retrieval reference, never hand-edited
│   └── reports/  dashboards/  emailTemplates/  applications/
├── metadata-log/                      Setup-only changes (see §6.2)
│   ├── README.md                      ledger of every org-side change
│   ├── ORG_INFO.md                    org IDs, editions, expiry policy, keep-alive state
│   └── retrieved/                     XML retrieved from the org
├── data/
│   ├── csv/                           one CSV per object, upserted on Seed_Tag__c
│   ├── scripts/                       generate.ts, load.ts (+ their tests; no ID-resolution pass — v2.1)
│   ├── fixtures/                      invalid_vins.json (test-only), names.ts
│   ├── snapshots/                     pre-reset exports (gitignored)
│   └── SEED_VERSION.txt               seed version + ANCHOR_DATE (reproducibility key)
├── scripts/                           shell wrappers: deploy.sh, retrieve.sh, test.sh,
│                                     verify.sh (DQ gates), reset.sh (delete → purge → storage)
├── docs/
│   ├── integration/API_CONTRACT.md
│   ├── architecture/                  paid-product seam notes (SIMULATION labels)
│   └── security/                      permission matrix, sharing model
├── evidence/
│   ├── P0_.../P5_.../                 screenshots per phase
│   ├── UAT/                           UAT scripts + signed results
│   └── DEMO_SCRIPTS/                  walkthrough scripts for presenting
└── .gitignore                         (exclude .sf/, snapshots/, logs/, .sfdx/)
```

**Rules**

- One folder per concern. Never scatter CSVs across the repo root.
- `data/snapshots/`, `.sf/`, `.sfdx/`, `*.log`, and any export containing records are
  **gitignored** — they are org state, not source.
- `metadata-log/retrieved/` is committed: it is the only place Setup-made config is captured.
- Screenshots are committed at reduced resolution and named
  `<NN>_<page>_<what_it_shows>.png` so a future agent can find visual proof fast.

### 6.2 Org-side folder strategy

| Concern | Org location | Naming |
|---|---|---|
| Reports | Setup → Reports → folder | `01_Pipeline` … `90_Admin` |
| Dashboards | Setup → Dashboards → folder | `01_Executive`, `02_Sales`, `03_Service` |
| Email templates | Setup → Email Templates → folder | `Sales_Emails`, `Service_Emails` |
| Flows | Setup → Flows → folder | `01_LeadToQuote`, `02_Financing`, `03_Service`, `04_Loyalty`, `90_Deferred` |
| Documents/screenshots | Salesforce Files / Documents folder | optional mirror; primary store is repo `evidence/` |
| Record types | per object | see §5.1 |
| Custom apps | App Launcher | `Northgate Sales`, `Northgate Service`, `Northgate Inventory`, `Northgate Admin` — each with its own tab list and home page (seamless-UX rule, §3.2-6) |

**Metadata tracking rule:** every Setup-only change (record type, layout tweak, report folder,
queue, role, site config) must be logged the same day in `metadata-log/README.md` with date,
change, and why Git cannot hold it. Then attempt `sf project retrieve start --metadata <type>`
and commit the XML. If retrieval fails, the log entry is the fallback. This is what makes the
permanent org recoverable after a bad change.

**No-workaround flow (guardrail 7):** if the build agent cannot deploy something from
source, it does not improvise or skip — it writes exact click-by-click Setup steps for the
owner, waits for the owner's "done", verifies the result read-only, then logs it in
`metadata-log/README.md`.

---

## 7. Release strategy

### 7.1 Branching and versioning

- **Trunk-based.** `main` always deploys cleanly to `ng-dev`.
- Remote: **private** GitHub repository **`arjun2126/northgate-motors-demo`**, created by
  the **owner** with `gh` (or the GitHub UI) at P0-03 — never by an agent, never with a
  token an agent handles; the build agent only runs `git push` to the already-configured
  remote.
- Short-lived feature branches: `feat/<backlog-id>-<slug>`, e.g. `feat/P2-04-financing-wizard`.
- Release flow (fixed): feature branch → deploy to `ng-dev` → UAT → validate-only deploy to
  `ng-demo` (`--dry-run`, `RunLocalTests`) → quick deploy → `git tag`.
- Tag every demoable state: `demo/v0.1`, `demo/v0.2`, … `demo/v1.0`.
- The backlog is the work-item system; no external tracker required.

### 7.2 Release unit

A release = metadata (Git) + Setup changes (metadata-log checklist) + seed data version
(`data/SEED_VERSION.txt`) + evidence. All four are recorded together in the release note
`docs/releases/<tag>.md`.

### 7.3 Deploy pipeline (always this order)

```
# Build org (ng-dev)
1. sf project deploy start --dry-run -o ng-dev      # validate, write nothing
2. review the component manifest + errors
3. sf project deploy start -o ng-dev                 # real deploy to build org
4. sf apex run test --code-coverage --result-format human --wait 20 -o ng-dev
5. run the phase UAT script from evidence/UAT/ against ng-dev
6. sf project retrieve start -o ng-dev               # pull back anything the org mutated

# Demo org (ng-demo) — only after 1–5 are clean
7. sf project deploy start --dry-run --test-level RunLocalTests -o ng-demo   # validate-only
8. sf project deploy start --fast --test-level RunLocalTests -o ng-demo      # quick deploy
9. git tag demo/vX.Y
```

Never skip step 1. `--dry-run` is the only safe clean-room substitute in a permanent org.
`ng-demo` never receives an unvalidated state: step 7 is mandatory even for one-line changes.

### 7.4 Destructive changes (highest risk)

Deleting a field or object in a permanent org destroys dependent records and report references.
Policy:

1. Never issue destructive deploys casually.
2. Preferred path: **deprecate first** — rename the field to `ZZ_Deprecated_<name>__c`, remove it
   from layouts/permission sets, wait one release, then delete.
3. If a real destructive deploy is required, it needs explicit owner approval and a
   `data/snapshots/` export taken immediately before.
4. Record the decision in `metadata-log/README.md`.

### 7.5 Safe iteration principles

- **Additive by default.** New fields are added; existing fields are not retyped.
- **Picklist additions are safe; removals are not.** Never remove a picklist value that seeded
  data uses — rename the value instead.
- **Flows deploy as inactive first**, activate as an explicit final step, so a half-deployed
  change never fires production-shaped logic.
- **Validation rules are always active; automation has one bypass switch.** A hierarchy custom
  setting `Automation_Settings__c` (`Bypass_Validation__c`, `Bypass_Flows__c`,
  `Bypass_Triggers__c`) plus a custom permission `Bypass_Automation` is checked at the start of
  every validation-rule formula, every record-triggered flow's entry condition, and every
  trigger handler. The loader runs as an admin holding the bypass: on for the load, off
  immediately after — recorded in `metadata-log/README.md`. The bypass is never left on.
  Custom metadata is reserved for *business* rules (`Price_Rule__mdt`, `Rate_Table__mdt`,
  `Loyalty_Tier__mdt`, `Lead_Routing__mdt`), never for build flags.
- **Permission sets, not profiles**, so a bad change touches only the users who hold that set.
- **Additive report edits.** Never delete a report a screenshot references; clone and revise.

### 7.6 Rollback

| Failure | Rollback |
|---|---|
| Metadata deploy fails mid-way | Fix forward on branch; re-run `--dry-run`; deploy again |
| Flow activation breaks a process | Deactivate the flow version (Setup), keep prior version active |
| Bad seed data | `reset.sh` for the affected object only, re-import from CSV |
| Bad field type change | Restore from Git tag; re-deploy; if data was lost, restore from `data/snapshots/` |
| Org-wide surprise | No org reset. Recover metadata from Git, data from snapshot. |

---

## 8. Data reset and refresh strategy

Full detail lives in `DEMO_ORG_SYNTHETIC_DATA_PLAN.md`. The governing principles here:

1. **Metadata is sacred; data is disposable.** All seeded rows are tagged `Seed_Tag__c LIKE 'SEED-%'`.
2. **Reset in place.** Delete by tag, never by dropping objects or the org.
3. **Delete children before parents** (master-detail and lookups enforce referential order).
4. **Snapshot first.** `sf data export` into `data/snapshots/` before any reset (gitignored).
5. **Two reset granularities:**
   - *Soft reset* — recency-only: close stale opportunities, re-age leads, backdate service
     visits to produce "overdue" states. Preserves referential links.
   - *Hard reset* — delete all `SEED-%` rows in dependency order, then re-import by upsert.
6. **Purge the Recycle Bin after every delete.** Soft-deleted rows stay 15 days and still
   count against the 5 MB data allowance. `reset.sh` ends with an empty-Recycle-Bin step
   (hard delete) — without it, a second reset will hit the storage ceiling.
7. **Storage check after every load and reset.** Setup → Storage Usage (or the `/limits` REST
   resource) must show **≤ 4.0 MB of 5 MB** data storage before any demo
   (budget in `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §2).
8. **Version the seed.** `data/SEED_VERSION.txt` increments on each generator run and records
   the `ANCHOR_DATE` used; the current value is stamped into `Data_Load_Batch__c` so the org
   self-reports what data it holds.
9. **Never delete:** users, roles, profiles, permission sets, queues, public groups, report and
   dashboard folders, email templates, any registered client app (External Client App once
   P1 creates it), or any metadata.

---

## 9. Test strategy

### 9.1 Apex (code)

| Requirement | Target |
|---|---|
| Coverage | 75% org minimum; **90% project target** |
| Structure | `@TestSetup` + `TestDataFactory`; no hardcoded org IDs |
| Async | `Test.startTest()` / `stopTest()` around Queueable/Batch/Scheduler |
| Callouts | `HttpCalloutMock` (e.g. `VINServiceMock`); never call a real endpoint in tests |
| Bulk | Every trigger/invocable tested at 200 records |
| Negative | Invalid VIN, insufficient discount authority, missing appraisal, negative equity |
| Isolation | `@Isolated` (or org-safe data builder) so tests never depend on seed rows |
| DML discipline | Insert once in `@TestSetup`; assert governor-safe counts |

Run gate: `sf apex run test --code-coverage --result-format human --wait 20` — fail the release
if coverage drops or any test fails.

### 9.2 Configuration (no coverage metric)

Configuration is the larger half of this build, so it needs its own discipline:

1. **Flow tests** — use the Flow test framework (Setup → Flows → Test) for record-triggered
   flows where supported: create a record, assert field outcome.
2. **UAT scripts** — every backlog item carries an acceptance criterion that maps to a numbered
   step in `evidence/UAT/UAT_<phase>.md`, with pass/fail and screenshot reference.
3. **Negative UAT** — deliberately attempt the disallowed action (rep approves own >10% discount;
   finance user edits MSRP; service user views finance fields) and capture the denial.
4. **Regression checklist** — a short, always-run list of ~15 core flows (lead→convert,
   quote→approve, book service, escalate case, accrue loyalty). Run it before every tag.
5. **Data-quality reports — two families, never mixed:**
   - *Release gates* — must return **0 rows** before a release: invalid VIN, opportunity
     missing account, financing with no opportunity, contact with no account, service visit
     still `Scheduled` in the past, missing seed tag, non-`.test` seed email.
   - *Demo findings* — expected **> 0 rows** with documented expected counts: the BAD-01…10
     scenarios plus the SEED-98 legacy import batch (malformed phone, missing postal code,
     invalid VIN in the free-text `Trade_VIN__c`, mixed-case duplicate email).
   The data-quality dashboard shows both families, clearly separated — a DQ demo with
   everything at zero has nothing to display.

### 9.3 What "done" means for a release

`--dry-run` clean → deploy clean → tests pass at ≥90% → zero **release-gate** data-quality
report rows (demo-findings reports may be > 0 at their documented counts) → regression
checklist green → UAT script signed → screenshots filed → tag applied.

---

## 10. Documentation strategy

| Document | Location | Audience | Update trigger |
|---|---|---|---|
| This master plan | repo root | owner + agent | any scope or convention change |
| Backlog | `DEMO_ORG_BACKLOG.md` | owner + agent | every status change |
| Data model | `DEMO_ORG_DATA_MODEL.md` | agent | every field/object change |
| Synthetic data plan | `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` | agent | every generator run |
| Setup checklist | `DEMO_ORG_SETUP_CHECKLIST.md` | owner | Phase 0 + org changes |
| Org-side change ledger | `metadata-log/README.md` | agent | **same day** as any Setup change |
| Integration contract | `docs/integration/API_CONTRACT.md` | agent | any callout change |
| Simulation seam notes | `docs/architecture/*.md` | owner + reviewers | when a paid product is simulated |
| Security matrix | `docs/security/PERMISSION_MATRIX.md` | owner | permission set change |
| Release notes | `docs/releases/<tag>.md` | owner | every tag |
| Demo walkthrough | `evidence/DEMO_SCRIPTS/*.md` | presenters | every user-visible change |
| README | repo root | anyone | every release |

**Rule for a future agent:** every artifact states what is real, what is simulated, and what is
documentation-only. Overclaiming a simulation as native is the single largest credibility risk
in this demo.

**Demo-script rule:** every script in `evidence/DEMO_SCRIPTS/` opens with a
**"Activate persona"** step — log in as the persona's own user for Admin, Sales Rep
(`ngrep`) and Service Advisor (`ngsvc`), run `scripts/persona.sh <manager|finance>` for
manager/finance demos, or log in as `ngadmin` for pure Setup demonstrations — so a
presenter never shows the wrong permission context mid-demo. On login every persona lands
in their own app with only their tabs (§3.2-6).

---

## 11. Feature-to-skill mapping

Derived from `SALESFORCE_MARKET_SKILLS_RESEARCH.md` (§3 frequency matrix, §2 role inventory).
Legend: **P** pervasive · **C** common · **E** emerging · **A** rare/advanced.

### 11.1 Foundation — must-have signal (every posting expects this)

| # | Demo feature | Skill exercised | Freq | Evidence from research |
|---|---|---|---|---|
| F1 | Lead intake, assignment rules, round-robin by postal code | Assignment rules, Flow, data quality | P | Finning, Bell, Immigrant Services Calgary |
| F2 | Lead → Account/Contact/Opportunity conversion with duplicate rules | Matching + duplicate rules, dedupe | P | Data-quality demand across nearly all admin roles |
| F3 | Record types + page layouts for household vs business buyers | Data modelling, UI design | P | Universal admin expectation |
| F4 | Validation rules (VIN 17-char, price floor, appraisal-before-quote) | Validation rules | P | Finning (advanced Flow + validation), all admin roles |
| F5 | Role hierarchy + OWD private + sharing rules across 4 rooftops | Security model | P | Every posting; sharing/visibility architect track |
| F6 | Permission sets + permission set groups for sales/finance/service | Least-privilege design | P | Adebra (permissions/optimization), governance roles |
| F7 | Opportunity stages New → Test Drive → Appraisal → Quoting → Financing → Won/Lost | Sales Cloud pipeline | P | Sales + Service pervasive pair |
| F8 | Record-triggered Flows with fault paths (reserve vehicle, accrue points) | Flow, error handling | P | Finning (advanced Flow), TD, PwC |
| F9 | Screen Flows (test-drive booking with conflict check, trade-in wizard) | Screen Flow | P | Universal Flow demand |
| F10 | Approval process: discount >5% manager, >10% director | Approvals | P | Admin baseline |
| F11 | Reports + dynamic dashboards (pipeline, inventory aging, SLA, data quality) | Reports/dashboards, CRMA-adjacent storytelling | P | Bell (CRMA), Duha, Trusscore, all admin roles |
| F12 | Data Loader / `sf data` round-trip + dedupe audit | Data import/export, quality | P | Data-quality cluster |
| F13 | Case creation, assignment, escalation rules, email alerts | Service Cloud basics | P | Sales+Service pair |
| F14 | Apex unit tests ≥90% with mocks | Testing culture | C→P | PwC, CGI, RBC, TD |
| F15 | Git + SFDX deploy with `--dry-run`, release checklist | Release hygiene | P | Wawanesa (DevOps Center), Copado/Gearset cluster |

### 11.2 Differentiators — separates mid-level from junior

| # | Demo feature | Skill exercised | Freq | Evidence |
|---|---|---|---|---|
| D1 | Inventory LWC: searchable/filterable table with reserve action + optimistic locking note | LWC, JS ES6, UI patterns | C→P | RBC, TD, CGI, BCAA |
| D2 | VIN decoder REST callout via Named Credential to a mock API, JSON parse, error handling | REST integration | C | Medcan (ETL), RB Global, CGI (REST/SOAP) |
| D3 | Payment calculator Apex (amortisation) + batch interest update | Apex, async, math correctness | C | Finning, TD |
| D4 | Scheduled Batch Apex: inventory aging + loyalty tier evaluation | Batch/Schedulable | C | Common mid-level requirement |
| D5 | Platform Event `Vehicle_Reserved__e` decoupled UI refresh | Events | C→E | PwC (Platform Events), CGI |
| D6 | Sales + Service consoles coexisting in one org | Multi-cloud in one org | P | Wawanesa, BCAA, CGI (Sales+Service) |
| D7 | Change-set-free release runbook via Git + `sf` (pipeline simulated without Copado) | DevOps/CI concepts | C | CloudKettle (Provar/Copado), RB Global |
| D8 | Data migration wave plan with reconciliation counts | Migration + reconciliation | C | ETL/migration cluster (Medcan, RB Global) |
| D9 | Permission audit report (who sees what, unused perms) | Security review ritual | C | Governance/least-privilege roles |

### 11.3 Architect-level — rare, well-paid signals

| # | Demo feature | Skill exercised | Freq | Evidence |
|---|---|---|---|---|
| A1 | Simulated CPQ: price rules, discount approvals, quote document generation | Quote-to-cash reasoning | A | Genesys (CPQ + Zuora), Moneris (Revenue Cloud) |
| A2 | Simulated Loyalty: tiers, accrual, redemption, expiry batch | Loyalty Management | A | MLSE (Loyalty Cloud, $100–120k) |
| A3 | Data Cloud (included quota): ingestion + identity-resolution demo; architecture note on unified profile | Data Cloud thinking | E→C | Conquest (ingestion/harmonization/unification/activation), PwC |
| A4 | Agentforce (included quota): service agent + Prompt Builder template with human-in-the-loop; Flow-decision-table fallback labelled SIMULATION | Agentforce/AI structure + human-in-the-loop | E | TD (human-in-the-loop controls), PwC (Agentforce), Bell (Agentforce asset) |
| A5 | Platform Events + CDC + Pub/Sub pattern doc | Event-driven architecture | A | Conquest (Pub/Sub + CDC + Streaming), PwC |
| A6 | API-led contract (`API_CONTRACT.md`) + mock service behind Named Credential | MuleSoft-style design | A | Wawanesa (MuleSoft), StorageVault, PwC |
| A7 | Territory Management across 4 rooftops + forecast rollup | Territory/forecast design | A | Research §4 advanced list |
| A8 | Org-strategy note (single vs multi-org, LDV, archiving) | Enterprise strategy | A | Wawanesa, Salesforce architect postings |
| A9 | Governance pack: naming conventions, review checklist, tech-debt register | CoE / governance | A | CGI (governance/standards), PwC |
| A10 | Experience Cloud customer site (included External Identity licences); permission-set Lightning app as fallback | Experience Cloud thinking | C | BCAA (Experience), Wawanesa (Experience) |
| A11 | Scheduled/consent-based nurture simulation (Marketing Cloud substitute) | Journey/consent reasoning | A | RB Global (Marketing Cloud), research §4 |
| A12 | Field Service substitute: appointment scheduling + capacity constraints | Field Service thinking | A | BCAA (Field Service), research §4 |
| A13 | Test strategy + CI gates documented and executable | Automated testing / CI | C | CloudKettle (QA lead), CI cluster |

### 11.4 Coverage check against the research's own backlog

Research §4 lists "must-have foundation", "strong differentiators", and "architect-level
challenges". Every one of those items maps to a feature above:

| Research item | Covered by |
|---|---|
| lead/account/contact/opportunity/case model | F1–F7, F13 |
| role hierarchy + profiles + PS + sharing | F5, F6, D9 |
| validation + duplicate rules | F2, F4 |
| record-triggered + screen + scheduled Flow with fault paths | F1, F8, F9, D4 |
| approval process | F10 |
| assignment rules | F1 |
| reports + dashboards (pipeline, SLA, data quality) | F11 |
| Data Loader round-trip | F12 |
| sandbox workflow → **adapted to permanent-org deploy workflow** | F15, §7 |
| 75%+ Apex tests with mocks | F14, A13 |
| release checklist + documentation | F15, §9.3, §10 |
| stakeholder demo script | `evidence/DEMO_SCRIPTS/` |
| LWC data table + form | D1 |
| REST callout with Named Credentials | D2, A6 |
| Platform Events | D5, A5 |
| scheduled Batch Apex with stateful reconciliation | D4, D8 |
| Experience-adjacent self-service | A10 |
| Sales + Service consoles | D6 |
| Copado/Gearset-style pipeline via GitHub + SFDX | D7 |
| security review ritual | D9 |
| Data Cloud unified-profile simulation | A3 |
| agent triage simulation | A4 |
| CPQ-style quoting engine | A1 |
| Loyalty program | A2 |
| CDC + Platform Events + Pub/Sub pattern doc | A5 |
| MuleSoft-style API-led spec | A6 |
| territory + forecast | A7 |
| org-strategy document | A8 |
| governance pack | A9 |

**No research item is uncovered.** Items outside the edition's included quota are simulations
or documents, never claims of native availability. Agentforce and Data Cloud ship *included*
with this edition within limits (§4.1) and are built for real after Phase 0 verification;
their simulation forms survive only as labelled fallbacks.

---

## 12. Milestone structure

The backlog is grouped into **three independently demoable milestones**, so each stands alone as
a presentable state (per the global rule that work splits into three independently testable
blocks). Full detail in `DEMO_ORG_BACKLOG.md`.

| Milestone | Phases | Independently demoable outcome |
|---|---|---|
| **M1 — Foundation** | P0, P1, P2 | Permanent org configured + secure data model + first vertical slice: web lead → qualify → test drive → opportunity, with reports and a passing test suite |
| **M2 — Core lifecycle** | P3, P4 | Complete lead-to-sale: trade-in → quote → discount approval → financing → delivery, with sales dashboards and synthetic data loaded |
| **M3 — Post-sale + advanced** | P5, P6, P7 | Service, cases, entitlements, knowledge, loyalty, LWC, events, verified Agentforce/Data Cloud builds, an Experience site, full governance and demo scripts |
| **M4 — Customer experience** | P8 | Customer-facing self-service portal (Experience Cloud + custom LWC): dashboard, My Vehicles, service history, appointment request, loyalty, case tracking — the customer sees only their own data. Gated on licence verification; labelled SIMULATION fallback if licensing is unavailable |

Each milestone ends with: deploy clean, tests ≥90%, zero data-quality rows, regression green,
UAT signed, screenshots filed, tag applied.

---

## 13. Approval gate and next step

**Nothing is built yet.** The next step requires explicit owner approval.

Recommended approval sequence:

1. Review this plan (conventions §5, ledger §4, milestones §12).
2. Review `DEMO_ORG_BACKLOG.md` for scope and phasing.
3. Review `DEMO_ORG_DATA_MODEL.md` for object/field realism.
4. Review `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` for data volume and edge cases.
5. Review `DEMO_ORG_SETUP_CHECKLIST.md` for the org prerequisites.
6. Approve **Phase 0 only** — signup of both orgs, org settings, keep-alive protocol +
   rebuild runbook (§3.5–§3.6), licence count, verify matrix, local repo bootstrap with CI
   skeleton, `sf` aliases. Phase 0
   creates **no metadata**: roles, users, permission sets, queues, groups, record types,
   picklists, layouts, validation rules and sharing settings all deploy from source in
   Phase 1.
7. Then approve Phase 1 build.

Phase 0 is where every verify answer becomes concrete, and it is the only phase that can
start without metadata changes.

---

## 14. Assumptions and risks

| # | Assumption / risk | Mitigation |
|---|---|---|
| 1 | **Org expiry** — DE orgs are deleted after 45 days without a login; **no Connected-App exemption available** (Spring '26: new orgs cannot create Connected Apps without Support; DE has no standard Support) | Human UI login to both orgs ≤ 30 days (calendar + login log in `ORG_INFO.md`); CI/API logins **not assumed** to reset the timer; org rebuild runbook with a 4-hour target (§3.5–§3.6) |
| 2 | DE org feature set differs from Enterprise | Phase 0 § Verify-before-you-build resolves every uncertain item before design |
| 3 | Source tracking unavailable or lossy | Fallback: explicit retrieve + diff; ledger in `metadata-log/` |
| 4 | Currency misconfiguration before data load | Set corporate currency to CAD in Phase 0, before any import |
| 5 | Validation rules or flows block seed import mid-load | Bypass design: `Automation_Settings__c` + `Bypass_Automation` on during load, off immediately after (§7.5); validation rules themselves stay always-active |
| 6 | **Data storage ceiling** — 5 MB ≈ ~2,500 records at ~2 KB each | Budget ≤ 4.0 MB with arithmetic (`DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §2), legacy + burst sets purged, storage check after every load and reset |
| 7 | **Licence ceiling** — Stop B measured 4 Salesforce (2 used, 2 free) + 6 Platform + Integration per org | 4 real Salesforce logins (Admin, Sales Rep, Service Advisor, Persona Switcher) + 2 Platform logins; persona matrix records used/free at 0-D; shrink gate folds real logins into Persona Switcher coverage rather than exceeding counts |
| 8 | Platform-licence personas cannot use Opportunity, Lead, Case, Quote or Campaign — **Login As does not lift licence limits** | Inventory Coordinator and Service Technician stay on custom objects (`Vehicle__c`, `Vehicle_Model__c`, `Rooftop__c`, `Staff__c`, `Service_Visit__c`); Sales Rep and Service Advisor are real Salesforce-licence logins; manager/finance demos run on the Persona Switcher's Salesforce licence (role/PSG swapped by `scripts/persona.sh`) |
| 9 | Agent overclaims simulated features | §4 ledger is authoritative; every artifact labels native/simulate/verify/paid; Agentforce/Data Cloud fallbacks labelled SIMULATION |
| 10 | Two-org drift (`ng-dev` diverges from `ng-demo`) | Only validated states reach `ng-demo` (§7.3 steps 7–8); tags mark both; UAT evidence per release |
| 11 | Username collisions on signup | Namespaced `@northgate.demo` usernames with plus-addressed real emails |
| 12 | Real trademarks in screenshots | Invented makes only (§2); enforced in review |

---

## 15. Revision log v2

Every change made in the v1 → v2 revision, by file and section. Inputs: owner decisions
(two orgs, Git + GitHub, Agentforce/Data Cloud real builds) and Salesforce Help facts
verified 2026-10-07 (5 MB DE storage, ~2 KB/record, 45-day expiry — the Connected-App
exemption claimed here was later shown unavailable and is corrected in v2.1,
exemption, ~2 Salesforce + 3 Platform + 1 Integration + 5 External Identity licences,
3 dynamic dashboards, `sf data import tree` is insert-only, roll-ups need master-detail,
VRs cannot query).

### DEMO_ORG_MASTER_PLAN.md

| Section | Change |
|---|---|
| Header table | One org → two orgs (`ng-dev`, `ng-demo`); GitHub remote named |
| §1 non-goals | Clarified: included-quota Agentforce/Data Cloud are not subscriptions |
| §2 Staff | 12 users → 5 personas + 1 integration user; `Staff__c` reporting dimension |
| §3.1 | Two-org roles + fixed release flow |
| §3.3 | Trunk-based against two orgs |
| §3.5 *(new)* | Keep-alive: 45-day expiry, Connected App exemption, 30-day reminder, CI heartbeat |
| §4.1 | Added Agentforce, Data Cloud, Knowledge, Entitlements+Milestones, Omni-Channel/Console, Experience Cloud (all with limits/verification) |
| §4.2 | Removed Agentforce/Data Cloud/Experience simulation rows; added labelled fallback paragraph |
| §4.3 | Added Agentforce, Data Cloud, dynamic-dashboard-limit verify rows; Knowledge/Entitlements row now "expected standard, plan to build" |
| §4.4 | Data Cloud and Agentforce removed from paid list; Automotive Cloud added (docs only) |
| §5.1 | Custom metadata list → `Price_Rule`, `Rate_Table`, `Loyalty_Tier`, `Lead_Routing`; custom setting → `Automation_Settings__c` |
| §5.6 | Unified seed key: one field `Seed_Tag__c` (External ID, unique, not mapped on conversion); batches 98/99 |
| §6.1 | `sfdx-project.json` now Phase 0; added `.github/workflows/`; `data/seed`+`plans` → `data/csv` upsert model; `generate.py` → `generate.ts`; `metadata-log/ORG_INFO.md` |
| §7.1 | GitHub remote `arjun2126`; two-org release flow |
| §7.3 | Pipeline split into ng-dev steps 1–6 and ng-demo steps 7–9 (validate-only → quick deploy) |
| §7.5 | VRs now always-active with `Automation_Settings__c`/`Bypass_Automation` bypass (was `Demo_Config` disabled-VR design) |
| §8 | Added Recycle Bin purge (6), storage check ≤ 4.0 MB (7); `ANCHOR_DATE` in seed version (8) |
| §9.2, §9.3 | Data quality split into release gates (0 rows) vs demo findings (expected > 0) |
| §11 | A3/A4 rewritten as real included-quota builds; A10 real Experience site; closing note updated |
| §12 | M3 milestone wording updated |
| §13 | Phase 0 scope corrected: no metadata; roles/users/PS/RT/picklists/layouts/VRs/OWD move to P1 |
| §14 | Risks rewritten: expiry, storage ceiling, licence ceiling, Platform-licence limits, two-org drift |
| §15 | This log |

### DEMO_ORG_BACKLOG.md

Added **Dependencies** and **Evidence** columns to every phase table. Phase 0 re-scoped to
signup/settings/verification/repo/CI (no metadata). New items: second org (P0-01), CI
skeleton (P0-04), Connected App + keep-alive (P0-07), licence/persona matrix (P0-08),
users as P1 item (P1-15), `Staff__c` (P1-01), `Automation_Settings__c` + `Bypass_Automation`
(P1-13), `VinValidator` (P1-20), flow-maintained counters (P2-12), legacy DQ batch
(P5-07), release-gate vs demo-finding reports (P5-08/09), burst dataset (P5-19), Recycle
Bin purge + storage check in reset (P5-17), Entitlements + Milestones (P6-14), Knowledge
(P6-15), Agentforce agent + prompt template (P7-15), Data Cloud demo (P7-16), real
Experience site (P7-18), Automotive Cloud mapping (P7-19). Renumbered; summary counts
updated to **130 items**; out-of-scope list corrected.

### DEMO_ORG_DATA_MODEL.md

Renamed `Service_Appointment__c` → `Service_Visit__c` throughout. Added `Staff__c` (13
custom objects). `Vehicle__c → Vehicle_Model__c` master-detail → required **lookup**
(cascade-delete and Controlled-by-Parent problems); ERD redrawn (`Rooftop__c` is a lookup
from `Vehicle__c`). Master-detail now only `Loyalty_Transaction__c → Loyalty_Member__c`.
§5.3 split into native roll-ups (MD only) vs Flow-maintained counters (all lookup
roll-ups). §9 rewritten: removed `VR_Vehicle_UniqueVIN` (field Unique setting),
`VR_ServiceVisit_Capacity`, `VR_TradeIn_AppraisalBeforeQuote`, and
`VR_Contact_HouseholdRole` (moved to Flow/Apex — VRs cannot query other records); added
`VR_Financing_TermAllowed`; added bypass guard on every VR. New §5.6 **Automation map**
per object. `Is_VIN_Valid__c` computed by Apex `VinValidator`. `Term_Months__c` picklist →
Number with allowed-values VR. `Rate_Source__c` values de-API-named. Dropped
`Exterior_Colour__c`. Role hierarchy rewritten for 5 real users with Service branch fixed.
Opportunity/Service_Visit gain `*_Staff__c` lookups. Custom metadata types now 4
(`Demo_Config__mdt` removed). Seed tagging §4 unified on `Seed_Tag__c` as External ID.

### DEMO_ORG_SYNTHETIC_DATA_PLAN.md

Record plan 11,800 → **storage-budgeted**: new §2 per-object table with count × KB
arithmetic, target ≤ 4.0 MB of 5 MB, ~1,873 records + 250 activities, ~1 MB headroom,
plus an optional purged burst set. Loader switched from `sf data import tree` (insert-only,
duplicates on re-run) to `sf data upsert bulk --external-id Seed_Tag__c` in dependency
order with a `resolve.ts` parent-ID step; re-runnability is an acceptance criterion.
Added SEED-98 legacy dirty-import batch (~30 records) and split §9 into release gates
(0 rows) vs demo findings (expected counts). Reset gains Recycle Bin purge + storage
check. Lead routing by Ontario postal FSA prefixes (all rooftops in Ontario); phone
area codes 905/289/416 with the 555-01xx block. Generator is TypeScript with an
`ANCHOR_DATE` parameter recorded in `SEED_VERSION.txt`. Converted-lead reconciliation
applied (no `Converted` lead rows; conversion represented by tagged Account/Contact/
Opportunity triples).

### DEMO_ORG_SETUP_CHECKLIST.md

Phase 0-A rewritten: two orgs, "Developer Edition with Agentforce and Data Cloud" edition
name, 45-day expiry policy. New Phase 0-C Connected App + keep-alive. Users, roles,
permission sets, queues, groups, record types, picklists, layouts, validation rules and
OWD **moved out of Phase 0 into P1** (deployed from source). Licence verification now
drives a documented persona table (5 internal + 1 integration) rather than 12 users.
Email policy corrected: internal users get real plus-addressed emails for activation;
seed records use `.test`; deliverability "System email only", "All email" only during a
scheduled test window. Verification matrix gained Agentforce, Data Cloud, dynamic
dashboard limit, and feature rows updated to "expected standard, plan to build".
Repo bootstrap now includes Git init + private GitHub repo + CI workflow skeleton.

---

## 15.1 Revision log v2.1

Owner corrections applied in place (planning only — no scaffold, no org, no commands were
run). Inputs: (a) Spring '26 Connected-App restriction, (b) licence-corrected persona
model, (c) three closed decisions, (d) build-agent Phase 0 runbook, (e) agent-roles split.

### DEMO_ORG_MASTER_PLAN.md

| Section | Change |
|---|---|
| §1.1 *(new)* | **Agent roles**: workflow agent = these `.md` files only; build agent = executes backlog, stops at gates; owner = approvals + all credentials |
| §2 Staff | Persona model corrected: 2 Salesforce licences = Admin + **Persona Switcher** (`scripts/persona.sh`); 3 Platform = Inventory Coordinator, Service Technician, spare; Integration = `dms.integration`; Login As does not lift licence limits |
| §3.5 | Keep-alive rewritten: **no Connected-App exemption** (Spring '26 restriction); human UI login ≤ 30 days both orgs + login log in `ORG_INFO.md`; CI/API logins not assumed to reset timer; CI auth = External Client App planned in P1 |
| §3.6 *(new)* | **Org rebuild runbook**: new DE signup → settings → redeploy from Git → replay metadata-log → seed reload + verify; target ≤ 4 hours |
| §5.4 | PSG examples → `PSG_Rep`/`PSG_Manager`/`PSG_Finance`/`PSG_Service`; username/email examples → `ngpersona` persona set |
| §6.1 tree | `validate.yml` marked DISABLED until P1-22; `resolve.ts` removed from `data/scripts/` |
| §7.1 | Remote named `arjun2126/northgate-motors-demo`, **created by owner with `gh`** — never by an agent or agent-handled tokens |
| §8 | Never-delete row: Connected App → any registered client app |
| §10 | **Demo-script rule**: every script opens with an "Activate persona" step |
| §13 | Step 6: Connected App → keep-alive + rebuild runbook |
| §14 | Risks 1, 7, 8 rewritten (no exemption; Persona Switcher; licence limits are absolute) |
| §15.1 *(new)* | This log |

### DEMO_ORG_BACKLOG.md

P0-03 repo creation assigned to the owner with `gh`. P0-04 CI skeleton now **disabled**
(no scheduled login job). P0-07 rewritten: keep-alive protocol (human ≤ 30-day logins +
login log + rebuild-runbook reference; no Connected App). P0-08 matrix rewritten for the
persona-switcher model. P1-08/P1-11/P1-12/P1-15 corrected to the new roles, PSG names and
6-user roster. **New: P1-21 `scripts/persona.sh`, P1-22 External Client App for CI
(JWT)**; P1 exit gate includes persona-switch verification. P2-15 and P7-21 require the
"Activate persona" opening step. P5-02 loader wording → external-ID relationship columns,
no ID-resolution pass. Summary counts: P1 20 → **22**, total **130 → 132**.

### DEMO_ORG_DATA_MODEL.md

§6.1 rewritten: licence-corrected persona table (Admin, Persona Switcher, Inventory
Coordinator, Service Technician, spare, `dms.integration`), explicit "Login As does not
lift licence limits" rule, redrawn role tree with ~ marks, `scripts/persona.sh` contract.
§6.2 now assigns PSGs to the Persona Switcher one-at-a-time. §11 retitled **Decisions log**
with closed rows: #7 loader = native `sf data upsert bulk` + external-ID relationship
columns (SFDMU optional later), #8 dynamic dashboards = 3 confirmed, #9 GitHub =
`arjun2126/northgate-motors-demo` created by owner.

### DEMO_ORG_SYNTHETIC_DATA_PLAN.md

§4 parent-reference paragraph rewritten for closed decision #7: child CSVs carry parent
`Seed_Tag__c` in external-ID relationship columns; `resolve.ts` **retired** (owner refs
mapped by username in `load.ts`); SFDMU optional-only. §10 tree drops `resolve.ts`.

### DEMO_ORG_SETUP_CHECKLIST.md

0-A expiry facts corrected (no exemption; Spring '26 restriction). 0-C rewritten from
Connected App to **human-login keep-alive** (calendar + login log + "CI/API logins not
assumed" rule + rebuild-runbook reference). 0-D rewritten for the 6-user licence-corrected
persona model; shrink gate now shrinks coverage, never the licence rule. 0-E row 13 marked
confirmed (3 dynamic dashboards). 0-F: `.gitignore` exact contents, `sourceApiVersion` =
latest GA supported by installed CLI, owner-created private repo, **disabled** CI
skeleton. New **"Phase 0 execution runbook for the build agent"**: standing rules (only
`ng-dev`/`ng-demo`; never `portfolio-demo-2026`; never touch `DEMO ORG ARJUN` or
`JobSearch`; no metadata/data/users in Phase 0) and Stop A (local bootstrap + owner-run
`gh` commands) → Stop B (owner signup/My Domain, `sf org login web`, read-only
`org display`/SOQL/limits/`sobject list` checks into `VERIFY_RESULTS.md`) → Stop C
(Owner click-list, Organization re-query, logs, exit report). Exit criteria 1/3/4/6/7
updated; P1 range → P1-01..P1-22; must-NOT-do table gains four rows (other orgs,
out-of-scope folders, Phase 0 Connected App, assumed CI keep-alive).

**v2.1 validation:** backlog row counts match summary (12/22/15/12/13/20/17/21 = 132);
`ngrep1`/`ngfin`/`ngsvc`/`ngci`/`PSG_Sales`/`PSG_Management` stale tokens absent;
`resolve.ts` references removed outside this historical log; real-brand grep clean; no
files created or modified outside the five `.md` files.
