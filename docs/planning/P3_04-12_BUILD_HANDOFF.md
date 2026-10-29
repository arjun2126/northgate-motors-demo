# Phase 3 Build Handoff — P3-04 .. P3-12 coordinated package (reconciled)

**Status:** For owner approval. Planning only — no execution. Once approved, the build agent
runs the whole package from this file as the single handoff, not nine separate cycles.
Routine local implementation and testing proceed without repeated prompts; the agent stops
only at the defined checkpoints (§6) or genuine blockers (§7).

**Current role split (owner, 2026-10-12):** the workflow agent that produced the local
Blocks A/B/C source is **planning/documentation only** and has stopped implementation and
org execution. **Northgate is the implementation agent** and will review and take ownership
of the existing local work from `docs/planning/P3_04-12_NORTHGATE_TRANSFER.md`.

**Owner instructions binding here:**
- Follow `docs/architecture/AUTOMATION_DIRECTION.md` — no new project-owned Flows;
  LWC + Apex for the quote builder; native features preserved; P3-01/P3-02 unchanged.
- Blocks: A = P3-04/P3-05/P3-12; B = P3-06/P3-07; C = P3-08..P3-11.
- Only genuinely unresolved decisions are listed (§4); approved values and category-selection
  come from `evidence/P3/p3_03_source_mappings.md` (§1-3) and are not reopened.
- No deployments, org changes, commits, pushes, tags, or work outside Phase 3 without approval.

## 1. Current Phase 3 state (reconciled baseline)

| Item | State | Source |
|---|---|---|
| P3-01 Trade-in appraisal | ACCEPTED for demo scope; flow + `TradeIn_Calc_Equity` untouched | `BUILD_STATUS.md` |
| P3-02 Quote gate | **Deployed + DML-enforcement verified in ng-dev** (50/50 tests). `QuoteTrigger` + `QuoteTradeInGuard` unchanged | `evidence/P3/p3_03_source_mappings.md` §10; owner baseline |
| P3-03 `Price_Rule__mdt` | **DEPLOYED + VERIFIED.** 10 records live in `ng-dev` (deploy id `0Afg800000H1av1CAB`); post-deploy test run `707g800000oKXoQ` 50/50 pass. `Percent_Adjustment__c` stored positive; `Rule_Type__c` carries direction. Financing_Tier_B_Rate removed; Segment rules removed; trim values corrected | `evidence/P3/p3_03_source_mappings.md` §7-10; owner baseline |
| Approvals / report folders | 4 loyalty rules, 2 age, 2 trim, 2 volume — all source-backed per mappings §1 | `DEMO_ORG_DATA_MODEL.md`; mappings §1 |
| Quote fields | `Prepared_By__c`, `Rule_Applied_Count__c`, `Seed_Tag__c`; VR `VR_Quote_NoQuoteWithoutOpp` | `objects/Quote/` |
| Opportunity fields | `Discount_Percent__c`, `Approval_Status__c`, `Vehicle__c`, `Sales_Staff__c`, `Has_Trade_In__c` — present today | `DEMO_ORG_DATA_MODEL.md` §7 |
| Approval infrastructure | No Approval Process in source yet; roles `Sales_Manager_*`, `VP_Sales`, PSG_Manager exist | `roles/`, `permissionsetgroups/` |
| Pricebook data | Plan seeds 40 Product2 + 60 PricebookEntry (Phase 5 loader). See §4.2 fixture split | `DEMO_ORG_SYNTHETIC_DATA_PLAN.md` §2.1 |

**Document hierarchy (do not blur):**
- `evidence/P3/p3_03_pricerules.md` — **historical proposal** (v3), superseded as the
  decision record; its values are now settled via owner baseline + mappings.
- `evidence/P3/p3_03_source_mappings.md` — **current decision record**: per-rule sources (§1),
  per-quote scope (§2), category-selection policy (§3), calc assumptions (§4), open conflicts (§5).
- `force-app/.../customMetadata/Price_Rule__mdt/` — **current deployable catalog** (§4.1).
- **Obsolete records in source:** none. Verified: 10 files only; no Segment rules, no
  `Financing_Tier_B_Rate`, no `Sedan`/`SUV` trim values. No cleanup proposed. Do not delete.

## 2. Range and boundary

In scope: P3-04, P3-05, P3-06, P3-07, P3-08, P3-09, P3-10, P3-11, P3-12, plus metadata
prerequisites (§4.2, §5). Out of scope: P3-01, P3-02 (unchanged), Phase 4+ (seams only),
Phase 5+ data load (except the small fixture set in §4.2), ng-demo.

Deployment: `sf` vs **ng-dev only**, behind §6 gates. P3-03 catalog deploy is **already
authorized**; verify completion (10 records live) before engine org tests — not a new gate.

## 3. Components — reused and new

### Reused (no new work)
- `TestDriveBookingGuard` / `OpportunityStageStamp` patterns (guard + stamp shape).
- `P2TestDataFactory.cls` (Apex fixtures — also root of the isolated test data, §4.2).
- Trigger start/end bypass header (`Automation_Settings__c`, `Bypass_Triggers__c`) + `FeatureManagement.checkPermission('Bypass_Automation')`.
- `PS_Sales_Rep`/`PSG_Manager`/roles/layouts from Phase 1.
- Standard Quote, QuoteLineItem, Product2, PricebookEntry, Pricebook2 (CAD standard price book).
- `NG_01_Pipeline` report folder; `NG_Sales` dashboard folder.
- class meta convention apiVersion 68.0.

### New (built by this package)
| Component | Block | Purpose |
|---|---|---|
| `QuotePricingService.cls` (+test) | A | Applies the 10 approved rules per `p3_03_source_mappings.md` §2-4: per-quote, category selection (§3), discounts-then-premiums order, percent-multiplicative, 2dp rounding, $0 floor, no % cap. Pure service — no org writes. |
| `QuoteBuilderController.cls` (+test) | A | `@AuraEnabled`: queries standard pricebook by category; builds Quote; creates `QuoteLineItem`s; sets `Quote_Valid_Until__c`; calls `QuotePricingService`; writes engine result to `Quote.Adjusted_Subtotal__c` (W-3); stamps `Opportunity.Discount_Percent__c` + `Approval_Status__c`. |
| `quoteBuilder` LWC | A | Line picker (Product2 by category), live totals, Save + Submit-for-approval. Quote record page via flexipage. |
| `Opportunity_Discount_Approval.approvalProcess-meta.xml` | B | Native approval: entry `Discount_Percent__c > 5`; Step 1 Sales_Manager (rooftop role), Step 2 `VP_Sales`; `>10` auto-skips manager via step entry criteria; final step sets `Approval_Status__c`. |
| `DiscountApprovalTest.cls` | B | Submit/approve/reject incl. >10 direct-VP path and manager-self-approval edge. |
| `quoteSummary` LWC | B | Read-only print view (lines, rule breakdown, discount, totals, approval status) + standard "Print/Export → Quote PDF" (DATA_MODEL decision #3). |
| `Quote.Quote_Valid_Until__c` (Date) | A→C | Default `TODAY()+30` at creation; drives P3-08 stale report. |
| `Quote.Adjusted_Subtotal__c` (Currency, nullable) | A | Engine write target; **not** `Quote.GrandTotal` (would overwrite standard QLI rollup). W-3. |
| `NG_05_DataQuality` report folder | C | First report: stale open quotes (P3-08). |
| `rpt_Discount_Leakage`, `rpt_Win_Loss_by_Reason` | C | `01_Pipeline` (P3-09). |
| `DM_QuoteHealth` dashboard | C | Fixed-user: win rate, avg discount %, quote ageing (P3-10). |
| `docs/architecture/SIMULATION_CPQ.md` | C | Seam note, linked from MASTER_PLAN §4.4 (P3-11). |

**Explicitly NOT built (resolved by P3-03):** `Quote.Promotion_Segment__c` / buyer-segment
field — removed; Segment rules gone (Decision D). Per-line `QuoteLineItem.Vehicle__c` /
`Rule_Base_Price__c`/`Rule_Adjustment__c` — not built unless W-1 resolves to line-scoped
rules (recommended default: no).

## 4. Decisions

### 4.1 Price-rule catalog — APPROVED (10 deployable records, current source)
| DeveloperName | Type | Attribute | Value | Percent | Priority | Source (mappings §1) |
|---|---|---|---|---|---|---|
| `Trim_Premium_Premium` | Premium | Trim | Premium | +5.00 | 10 | `Opportunity.Vehicle__r.Vehicle_Model__r.Trim__c` |
| `Trim_Premium_Limited` | Premium | Trim | Limited | +3.00 | 10 | same |
| `Aged_Inventory_Discount_60` | Discount | Age_Days | 60 | −10.00 | 20 | `Opportunity.Vehicle__r.Inventory_Age_Days__c` |
| `Aged_Inventory_Discount_90` | Discount | Age_Days | 90 | −15.00 | 21 | same |
| `Loyalty_Bronze_Discount` | Discount | Loyalty_Tier | Bronze | −1.00 | 28 | Account → Contact → `Loyalty_Member__c.Tier__c` |
| `Loyalty_Silver_Discount` | Discount | Loyalty_Tier | Silver | −2.00 | 29 | same |
| `Loyalty_Gold_Member_Discount` | Discount | Loyalty_Tier | Gold | −3.00 | 30 | same |
| `Loyalty_Platinum_Discount` | Discount | Loyalty_Tier | Platinum | −5.00 | 31 | same |
| `Volume_Discount_Over_10` | Discount | Volume | 10 | −8.00 | 35 | `SUM(QLI.Quantity WHERE Product2.Category__c = 'Vehicle_Trim')` |
| `Fleet_Discount_Over_5` | Discount | Volume | 5 | −5.00 | 40 | same |

**Category selection (approved, mappings §3):** Trim — matching only; Age — largest % wins;
Loyalty — matching only; Volume — largest % wins (no within-category stacking). Cross-category:
each category yields ≤1 rule; combine Discounts then Premiums multiplicatively on running subtotal.

### 4.2 Product2/PricebookEntry — fixture split (revised)
- **Isolated automated-test fixtures:** created in-Apex only (`P2TestDataFactory`
  inserts Product2/PricebookEntry in `@testSetup`/test method). No org records, no deploy,
  no Phase 5 dependency. Local implementation and tests never block on data.
- **Persistent UI/demo data (smallest approved set, recommended):** scope the quote-builder
  demo to **4 Product2 + 5 PricebookEntry** rows: one `Trim_Premium`, one `Trim_Limited`,
  one base-trim vehicle line, one `Service_Package`, plus standard-pricebook entries for each.
  Deploy via a small tagged CSV + `sf data upsert` (SEED tags) in the existing loader pattern,
  running **immediately before Block A UAT** (CP2), not earlier.
- Full Phase 5 load is **not** a prerequisite for local build/tests.

### 4.3 APPROVED (settled; not reopened)
| # | Decision | Source |
|---|---|---|
| A1 | Catalog + values + selection policy as §4.1/mappings §1-3 | owner baseline + `p3_03_source_mappings.md` |
| A2 | Discount approval thresholds >5% manager, >10% director | Backlog P3-06 |
| A3 | Quote output = LWC summary + standard Quote PDF | DATA_MODEL decision #3 |
| A4 | Quote builder is LWC, not a Flow (this package approves the P3-04 scope change) | `AUTOMATION_DIRECTION.md` |
| A5 | P3-06 native Approval Process (preserved Salesforce feature) | `AUTOMATION_DIRECTION.md` |
| A6 | Bypass conventions unchanged (settings start-guard + Bypass_Automation) | existing triggers |
| A7 | P3-01/P3-02 unchanged; P3-02 already deployed + verified | owner baseline |
| A8 | Loyalty contact path = Account → Contact (`Opportunity.ContactId` is null in demo data) | mappings §1.2 |
| A9 | Volume sum restricted to `Product2.Category__c = 'Vehicle_Trim'` | mappings §4 |
| A10 | No %, stacking cap: apply every qualifying rule; never skip rules on a cap | mappings §5.4 |

### 4.4 APPROVED scope decisions — W-1..W-4 (owner, bound; finalized 2026-10-12)
| # | Approved decision (binding) |
|---|---|
| W-1 | `Opportunity.Vehicle__c` is the **primary vehicle context**. Age/trim adjustments apply **only to that primary vehicle's pricing basis** — never to unrelated accessories or additional vehicles. Do **not** claim support for multi-vehicle age/trim pricing. Vehicle-quantity **volume discounts stay separate** (their own category). If the existing line model cannot identify the primary-vehicle pricing basis, **flag that specific blocker once** in the handoff for Northgate to resolve; do not silently skip. |
| W-2 | `Quote.Buyer_Contact__c` is the **explicit buyer** for loyalty. No buyer selected, or no qualifying membership on that buyer → **no loyalty discount**. **Rejected: Account-level highest-tier fallback.** Validate the buyer/account association (buyer must belong to the Opportunity's Account). Multiple memberships on that buyer must resolve by a **deterministic policy** Northgate confirms (§5 of transfer doc). |
| W-3 | `Quote.Adjusted_Subtotal__c` is the **approved custom write target**. Never write `GrandTotal`. UI, quote output, and reports must **clearly distinguish adjusted subtotal from standard totals** and explain tax/shipping treatment. For the `Opportunity.Discount_Percent__c` write-back: **define a zero-list-price guard** (no division by zero) **and how premiums affect the result** — never silently report a premium as a positive discount. |
| W-4 | **Discounts first, then premiums**; multiplicative percentages; 2-decimal per-step and final rounding; **zero floor**; **no additive % cap** (cap does not override the one-rule-per-category selection). Percentages stored **positive**, `Rule_Type__c` determines direction (Discount −, Premium +). **Inactive rules do not apply.** **Missing buyer/vehicle context ⇒ rule does not qualify.** **Malformed active rules must be surfaced** — never silently skipped as successful pricing. Deterministic ordering uses **priority, then `DeveloperName`.** |

### 4.5 Approval status (updated 2026-10-12)
- **Approved:** coordinated LOCAL implementation sequence Blocks A → B → C; W-1..W-4 as §4.4
  (finalized); §4.2 fixture set approved **for planning**; routine local work proceeds without
  prompts **within Northgate's implementation**. This does **not** authorize any continued
  implementation by the planning-only workflow agent.
- **Not approved (stays gated):** any deployment, activation, persistent data creation,
  folder sharing, commit, push, tag, or ng-demo change.
- **CP1-CP4 are approval checkpoints, NOT pre-authorized org writes.** At each CP the handoff
  returns **one concise proposal**: exact components, fixture records, activation/security
  changes, and commands. Persistent fixture creation awaits the resolved CP2 proposal.
- **Sequencing:** local Blocks A → B → C approved. Deferred manual UAT (persona/screenshot)
  does **not** block local implementation; queued to
  `docs/verification/VERIFICATION_HANDOFF.md` (Cat B).

## 5. Dependency order

1. **Local implementation approved (§4.5).** P3-03 catalog live in `ng-dev` (deploy
   `0Afg800000H1av1CAB`, tests `707g800000oKXoQ` 50/50). Engine builds against that catalog,
   with in-Apex test fixtures only.
2. **Block A:** `QuotePricingService` (+ tests) → `QuoteBuilderController` → `quoteBuilder` LWC.
3. **Block B:** `Opportunity_Discount_Approval` config + `DiscountApprovalTest` → `quoteSummary` LWC.
4. **Block C:** stale-quote field wiring → reports → dashboard → seam doc.
5. **CP1-CP4:** at each stop, deliver one concise proposal (components, fixtures,
   activation/security changes, commands); org writes only after specific approval.

Routine local implementation/testing inside a block needs no owner prompt. Between CP1-CP4
stop and report.

## 6. Deployment and activation checkpoints (approval gates; no pre-authorized org writes)

| CP | Trigger (after local build passes) | Concise proposal the handoff returns | Org action only after approval |
|---|---|---|---|
| CP1 | Metadata fields/folder staged locally | Fields (`Quote_Valid_Until__c`, `Adjusted_Subtotal__c`, `Buyer_Contact__c`), `NG_05_DataQuality` folder, exact `--dry-run` command | Deploy metadata (if dry-run clean) |
| CP2 | Block A code + tests written (±org test run) | Components, command suite (org Apex test run), §4.2 fixture records (4 Product2/5 PBE as CSV+upsert), UAT steps | Deploy Block A; run tests; **create fixtures**; UAT |
| CP3 | Block B config + tests written | Approval Process toggles, persona run steps, security notes (submitters/approvers) | Deploy + activate; persona + approval runs |
| CP4 | Block C reports/dashboard/doc staged | Report + dashboard list, folder share to `PG_All_Sales`, fixed-user check | Deploy; folder-share changes |

Routine block-internal iteration (engine, unit tests, LWC layout, doc draft) continues
without prompts. Deployment, activation toggles, persona switches, UAT record inserts,
folder shares, commits stop at the owning CP.

## 7. Exception and stop conditions

- **Escalation (AGENTS.md):** unexpected failure/corrupted command/mangled identifier/uncertain
  diagnosis → stop that line; report exact error, last verified state, specific manual action; wait.
- **Preflight drift:** any `Bypass_Triggers__c`/`Bypass_Flows__c`/`Bypass_Validation__c` ON, or
  `PS_Bypass_Load` on the operation user → record state, stop, ask. Never silently change.
- **P3-01/P3-02 touched, renamed, or edited** → stop (forbidden; both deployed).
- **P3-03 catalog drift:** live `Price_Rule__mdt` ≠ the 10 §4.1 records → stop, reconcile;
  never modify catalog as part of engine work.
- **Approval Process conflicts** (existing process, unresolvable step role, self-approval edge
  failing) → stop before activation.
- **VR contradiction:** anything tripping `VR_Quote_NoQuoteWithoutOpp` or Closed-Won VR → stop, surface.
- **Outside Phase 3, or deploy target ≠ ng-dev** → stop.

## 8. Completion criteria

### Block A
- `QuotePricingServiceTest` green: all 10 rules mapped (§4.1), per-category selection (age/volume
  largest-% wins; trim/loyalty single-match), discounts-first order, 90+15 and 60+10 boundary,
  12-unit volume picks Over_10 not Fleet, loyalty per buyer (W-2), no-match quote unchanged,
  inactive rule skipped, $0 floor, batch ≥200 lines, negative path. **P3-05/P3-12**.
- `quoteBuilder` LWC creates Quote + QLI from pricebook, totals reconcile with engine,
  `Quote_Valid_Until__c` default. **P3-04** (evidence `evidence/P3/quote_builder.png`).

### Block B
- `DiscountApprovalTest` green: >5% → manager; >10% → VP_Sales direct; manager cannot
  self-approve >10%; rejection captured; `Approval_Status__c` transitions correct. **P3-06**.
- `quoteSummary` + standard Quote PDF render lines/discount/totals. **P3-07** → `evidence/P3/quote_pdf.png`.

### Block C
- Stale open quotes appear in `05_DataQuality`. **P3-08**. — Two pipeline reports correct. **P3-09**.
- `DM_QuoteHealth` ties to reports, fixed user. **P3-10**. — `SIMULATION_CPQ.md` exists + linked. **P3-11**.

### Phase 3 exit
All P3-01..P3-12 evidence in `evidence/P3/`, each check labelled
PASS/BLOCKED(blocker named)/DEFERRED(doc ref). P3-01 deferred checks stay deferred →
verification handoff Cat B, never re-labelled PASS. P3-04/P3-07 acceptance-wording change
approved here; `DEMO_ORG_BACKLOG.md` `FLOW` tags stay provisional until the separate approved
backlog-doc change (`AUTOMATION_DIRECTION.md` governance note, `BUILD_STATUS.md` P3-02 section
is likewise stale vs the deployed guard — flagged to build agent, not edited here).

## 9. Approval box — CLOSED for local build; transfer to Northgate

1. Local Blocks A/B/C implementation + tests: **approved** — executed locally by the
   planning agent (files listed in `docs/planning/P3_04-12_NORTHGATE_TRANSFER.md`), **not** to
   be continued by that agent.
2. W-1..W-4 approved as §4.4 (refined semantics bound; finalized 2026-10-12).
3. §4.2 fixture set approved for planning; **persistent creation only via resolved CP2 proposal**.
4. CP1-CP4 = checkpoint-for-approval, each returning one concise proposal (§6), raised by Northgate.
5. Deferred screenshots/persona UAT queued to `docs/verification/VERIFICATION_HANDOFF.md` (Cat B);
   they do not block local work.
6. No deployment/activation/persistent data/folder-share/commit/push/tag/ng-demo
   without specific approval.
7. **Transfer:** Northgate takes ownership of the existing local source from
   `docs/planning/P3_04-12_NORTHGATE_TRANSFER.md`; P3-01/P3-02/P3-03 decisions are not reopened.