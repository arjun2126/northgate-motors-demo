# P3-04 .. P3-12 Transfer to Northgate (owner-authorized, 2026-10-12)

Planning/workflow agent stopped implementation and org execution here. Northgate is the
implementation agent and takes ownership of the existing local work. Do not reopen
P3-01/P3-02/P3-03 decisions. Authoritative decisions: `P3_04-12_BUILD_HANDOFF.md` §4.4/W-1..W-4
(finalized), §4.1 catalog, §4.2 fixture split, §6 checkpoints.

## 1. Workspace

- Repo: `git@github.com:arjun2126/northgate-motors-demo.git` (origin remote configured).
- Local path: `/Users/arjunsubramanya/Documents/Coding Projects/Dealership Demo Org/`.
- Branch: `main`. HEAD `b2438bf` (`docs: lessons learned and Phase 3 handoff`). No commits,
  tags, or pushes made by the planning agent. No new branch created.
- Deploy target (CP): ng-dev only (`arjun.ngdev@northgate.demo`). Salesforce project:
  `sf-project.json` at repo root.

## 2. Implementation files touched (P3-04..P3-12 scope)

All untracked (new, never staged/committed) unless marked. Block = handoff §3.

**Block A**
- `force-app/main/default/objects/Quote/fields/Quote_Valid_Until__c.field-meta.xml` — untracked. Date, default TODAY()+30 set by builder.
- `force-app/main/default/objects/Quote/fields/Adjusted_Subtotal__c.field-meta.xml` — untracked. Currency 16,2. Engine write target.
- `force-app/main/default/objects/Quote/fields/Buyer_Contact__c.field-meta.xml` — untracked. Lookup(Contact), relationship `QuoteBuyer`.
- `force-app/main/default/classes/QuotePricingService.cls` — untracked. Pure engine; nested `VehicleContext`,`BuyerContext`,`AppliedRule`,`QuotePricingResult`,`QuotePricingException`; `BLOCKER_BASIS_AMBIGUOUS`.
- `force-app/main/default/classes/QuotePricingServiceTest.cls` — untracked. 17 tests.
- `force-app/main/default/classes/QuoteBuilderController.cls` — untracked. `getCatalog`/`getBuyerContacts` cacheable; `createQuote` writes Quote + QLIs, stamps `Adjusted_Subtotal__c`, `Rule_Applied_Count__c`, `Discount_Percent__c`, `Approval_Status__c`, `Quote_Valid_Until__c`.
- `force-app/main/default/classes/QuoteBuilderControllerTest.cls` — untracked. 5 tests.
- `force-app/main/default/lwc/quoteBuilder/` (`quoteBuilder.js`, `.html`, `.js-meta.xml`) — untracked. Records page target, Opportunity object; line picker + live totals + Save (handoff §3).

**Block B**
- `force-app/main/default/approvalProcesses/Opportunity_Discount_Approval.approvalProcess-meta.xml` — untracked. `active=false`; entry `Discount_Percent__c > 5`; Step1 `managerOfSubmitter` via `<= 10`; Step2 role `VP_Sales` via `> 10`; final actions set `Approval_Status__c` Approved/Rejected.
- `force-app/main/default/classes/DiscountApprovalTest.cls` — untracked. 4 tests; requires the process ACTIVE in org (runs only after CP3 activation). Uses `System.runAs` personas with roles Sales_Rep / Sales_Manager_Downtown / VP_Sales.
- `force-app/main/default/classes/QuoteSummaryController.cls` — untracked. Read-only summary DTO; needs an Apex test (none written) — pending item.
- `force-app/main/default/lwc/quoteSummary/` (`.js`, `.html`, `.js-meta.xml`) — untracked. Quote record page; adjusted-vs-standard narrative, Print/Quote-PDF, record navigation.

**Block C**
- `force-app/main/default/reports/NG_05_DataQuality/Quote_Expiring.report-meta.xml` — untracked. Stale open quotes; `reportType` guess **QuoteList** (see §5).
- `force-app/main/default/reports/NG_01_Pipeline/rpt_Discount_Leakage.report-meta.xml` — untracked.
- `force-app/main/default/reports/NG_01_Pipeline/rpt_Win_Loss_by_Reason.report-meta.xml` — untracked.
- `force-app/main/default/dashboards/NG_Sales/DM_QuoteHealth.dashboard-meta.xml` — untracked. `dashboardType SpecifiedUser`, owner + runningUser `arjun.ngdev@northgate.demo`.
- `docs/architecture/SIMULATION_CPQ.md` — untracked. Seam note (P3-11).

**Reads only (pre-existing, unchanged, tracked)** — `Quote.Rule_Applied_Count__c`, `Quote.Prepared_By__c`, `Quote.Seed_Tag__c` field metas, `roles/` (Sales_Manager_Airport/Downtown/North, VP_Sales), `groups/PG_All_Sales`, report folder `NG_01_Pipeline`, dashboard folder `NG_Sales`, `P2TestDataFactory.cls`, catalog in `customMetadata/Price_Rule__mdt/`.

**Docs updated by planning agent** — `docs/planning/P3_04-12_BUILD_HANDOFF.md` (§4.4/§4.5/§9 refined to owner-final wording; §1 role split). `BUILD_STATUS.md` shows pre-existing local modification (not from this session; do not overwrite without review).

## 3. Static checks performed (and their limits)

- XML well-formedness: `xmllint --noout` on 11 metadata files — passed (fields, LWC metas, approval process, 3 reports, dashboard).
- Apex brace balance on 6 classes — balanced (`{`=`)` counts equal). This is token-level only; **no Apex compile** was run (no org/tooling access authorized).
- LWC JS: `node --check` after stripping `@api`/`@track` decorator lines — parses as ESM. Limits: decorators not validated, no LWC lint/templates-check, HTML templates not built, handler references unverified.
- No PMD, no apex-compile, no `sf` run, no dry-run, no org query/test on this scope.

## 4. Intended component scope for validation (Northgate, at CP gates)

1. CP1 — Quote fields + `NG_05_DataQuality` folder + dry-run of the full metadata set (§2 list). 2. CP2 — deploy Block A; org Apex test run (`QuotePricingServiceTest`, `QuoteBuilderControllerTest`); §4.2 fixture set (4 Product2 / 5 PricebookEntry via CSV + upsert, SEED tags) only after explicit approval; builder UAT. 3. CP3 — deploy + activate approval process; `DiscountApprovalTest`; persona approval runs. 4. CP4 — deploy reports + dashboard; folder share `PG_All_Sales`; dashboard fixed-user check. Then FlexiPage/layout wiring (quoteBuilder/quoteSummary), M2/M3 tagging, verification handoff Cat B. Each CP returns ONE concise proposal; no pre-authorized org writes.

## 5. Known differences between local implementation and owner decisions (documented; NOT fixed)

| Owner decision | Local implementation | Gap |
|---|---|---|
| W-3 zero-list guard + premium effect on `Discount_Percent__c` | Guard present (`listSubtotal > 0 ? compute : 0`, QuotePricingService.cls ~L204). Percent = (list−adjusted)/list×100, signed. | Premiums flow into the write-back sign: premium-only quote yields **negative** `Discount_Percent__c` (never positive, but "positive-discount" semantics and premium separation undefined). Number not clamped at 0 when premiums dominate. |
| W-2 deterministic multi-membership policy | Local picks **highest tier** among buyer's active memberships via explicit tierRank (Bronze1..Platinum4). | Deterministic, but policy (highest-tier vs most-recent vs error) not owner-ratified; equal-tier duplicates resolve arbitrarily. |
| W-1 basis identification | `BLOCKER_BASIS_AMBIGUOUS` thrown when 0 or >1 matching `Product2.Name == Vehicle_Model.Name` trim lines; skipped cleanly when no vehicle on opp. | Conforms. Org catalog has 0 Vehicle_Model today, so path is fixture-only until data loads. |
| W-4 malformed active rules | Throws `QuotePricingException` on null/missing/negative percent, null type/attribute/required value. | Conforms. |
| W-2 no-Account fallback | No fallback implemented. | Conforms. |
| §4.2 fixture split | Fixture used in-Apex only; no persistent rows created. | Conforms (pending CP2). |

## 6. Unresolved details Northgate must define

1. **Discount write-back semantics (`Opportunity.Discount_Percent__c`):** when premiums exceed discounts (or premium-only), what should the field hold — clamp to 0, exclude premiums, or a signed result? Owner forbids dividing by zero and reporting a premium as a positive discount; everything else is Northgate's call.
2. **Same-buyer membership tie-break:** confirm highest-tier policy (current local behavior) or select another deterministic rule.
3. **QuoteSummaryController test:** add an Apex test (none exists).
4. **`reportType` for `Quote_Expiring`:** `QuoteList` is a guess — confirm the standard quote report-type API name against ng-dev before CP4.
5. **Dashboard grouping keys + `SpecifiedUser`:** `QUOTE_STATUS` grouping on a quote report and `Opportunity.*` groupings on the dashboard are unverified against the live org.
6. **quoteBuilder wiring + flexipage:** the Quote record-page layout (no flexipage exists in source yet) and the quoteBuilder/quoteSummary record-page placement need Northgate review; `quoteSummary` "Open Quote Record" navigation + print styling to confirm.
7. **Preflight guard:** confirm no bypass settings/personas during validation runs (handoff §7).

Boundaries preserved: no ng-demo changes; no commits/pushes/tags; no org execution; existing implementation files untouched by the planning agent.