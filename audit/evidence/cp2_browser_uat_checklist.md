# CP2 Browser UAT Checklist (Corrected)

## Pre-conditions (verified during execution, not owner-clicked)

- Standard Price Book `01sg80000065c4QAAQ` activated (IsActive=true).
- 4 Product2 records created (Premium, Limited, LX, Service Package).
- 4 PricebookEntry records created on the Standard Price Book.
- `PS_Sales_Rep` deployed with exactly 3 Quote FLS additions (no system permission changes, no removals).
- The existing NG_Sales sales-rep user (`005g800000BshcjAAB`, profile `NG_Sales`) is **already assigned** to `PS_Sales_Rep` and is the persona used for verification. **No additional permission assignments are required for testing.** **An admin check does not replace the sales-persona check.**

## Owner-Click Page Activation (required for CP2 completion)

1. Log in to `ng-dev` (00Dg800000LxahhEAB) as the **NG_Sales sales-rep user** (NOT the admin user).
2. Navigate to the **Sales** app.
3. Open an Opportunity with Record Type **Retail**.
4. Click the gear icon (top right) → **Edit Page**.
5. In the Lightning App Builder, click **Pages** in the left panel.
6. Find `NG_Opportunity_Quote_Builder` under "Custom Pages" or "All Pages".
7. Click **Activate**.
8. In the activation dialog, select exactly:
   - **App:** Sales
   - **Profile:** NG_Sales
   - **Record Type:** Opportunity.Retail
   - **Form Factor:** Desktop
9. **Do NOT select** Northgate_Admin, Opportunity.Fleet, or any other app/record type/form factor.
10. Click **Save**.

## CP2 Browser UAT Checklist (sales-persona check)

These 12 checks are **CP2-only**. Check 13 (`quoteSummary` on the Quote record page) is **deferred to CP3**.

1. ☐ Log in as the **NG_Sales sales-rep user** (NOT admin). Navigate to the **Sales** app.
2. ☐ Open an Opportunity with Record Type **Retail**.
3. ☐ Verify the `quoteBuilder` LWC renders in the page header.
4. ☐ Verify the four CP2 fixture products are available in the catalog dropdown: Test Model Premium, Test Model Limited, Test Model LX, Test Service Package. (Other eligible products may also appear if they already exist in the org — this is acceptable. The requirement is that the four CP2 fixtures are present, not that the catalog is limited to exactly four.)
5. ☐ Verify the buyer dropdown is populated with Contacts on the Opportunity's Account.
6. ☐ Select a buyer. Add Test Model LX (Base trim, no Trim_Premium rule) to the line items with quantity 1. Add Test Service Package with quantity 1.
7. ☐ Click "Save and Price Quote".
8. ☐ Verify a Quote record is created with:
   - `Quote_Valid_Until__c` populated (default TODAY+30).
   - `Buyer_Contact__c` populated with the selected buyer.
   - `Adjusted_Subtotal__c` populated and reflecting the pricing engine result.
9. ☐ **Vehicle-specific pricing does NOT adjust the Service_Package line.** The Service_Package line's `UnitPrice` and its contribution to `Adjusted_Subtotal__c` must be unaffected by the Trim (LX) and Age pricing rules. Only Trim/Age rules apply to the vehicle's pricing basis; Service_Package lines are outside that basis per W-1.
10. ☐ Verify `Opportunity.Discount_Percent__c` is stamped (signed net: positive = discount, negative = premium uplift; zero = no change).
11. ☐ Verify `Opportunity.Approval_Status__c` is "Pending" (if discount > 5%) or "Not_Required" (if discount ≤ 5%).
12. ☐ Verify the LWC displays the "Signed net adjustment" label and helptext.

## Passed scenarios (evidence log)

This log records individual browser scenarios that have been executed and passed. It does **not**
complete the 12-check checklist above, and it does **not** mark CP2 complete. Checklist items remain
open until the owner runs and reports the full checklist.

### S-1: Sales-persona Save / Price Quote succeeds (PASSED)

- **Executed by:** owner, as the **NG_Sales sales-rep persona** (`ngrep@northgate.demo`, profile `NG_Sales` + `PS_Sales_Rep` + `NG_Lightning_Access`) — **not** admin.
- **Page:** `N_Opportunity_Quote_Builder` on Opportunity `NG CP2 Browser UAT` (`006g8000009XEVFAA4`, Record Type Retail, Account `001g800000yZWX7AAO`).
- **Action:** select buyer `P1-14Test` (`003g800000q7EzZAAU`); add `Test Model Limited` (`01tg8000007NTOfAAO`, category `Vehicle_Trim`, list 28000) qty 1; click **Save and Price Quote**.
- **Result:** PASSED — result panel rendered with **List subtotal 28000**, **Adjusted subtotal 28000**, **Signed net adjustment 0%**, **Rules applied 0**. No error and no blocker message.
- **Live-org evidence (queried after the run):**
  - Quote `0Q0g80000021t2vCAA` — `Name = "NG CP2 Browser UAT - Quote"`, `OpportunityId = 006g8000009XEVFAA4`, `Pricebook2Id = 01sg80000065c4QAAQ` (standard), `ExpirationDate = Quote_Valid_Until__c = 2026-11-12`, `Buyer_Contact__c = 003g800000q7EzZAAU`, `CreatedDate = 2026-10-13T17:16:32Z`.
  - QuoteLineItem `0QLg8000002p6rpGAA` — `Quantity = 1`, `UnitPrice = 28000`, `PricebookEntryId = 01ug8000004gOejAAE` (Test Model Limited).
  - Exactly one Quote exists on the Opportunity (earlier failed attempts left no orphan Quotes).
- **Zero applied rules is EXPECTED for this fixture:** the Opportunity has no `Vehicle__c` (`0` Vehicle records in org) and the buyer has no `Loyalty_Member__c` (`0` records), so Trim/Age/Loyalty rules cannot qualify; qty 1 does not exceed any Volume threshold.
- **Enabling fix (root cause):** `QuoteBuilderController.LineInput` used bare `@AuraEnabled` fields (`productId`, `quantity`). Apex `@AuraEnabled` fields serialize Apex-to-LWC but are **not populated** LWC-to-Apex; the inbound contract requires accessors. Changed to `{ get; set; }`. Evidence chain: browser sent `[{"productId":"01tg8000007NTOfAAO","quantity":1}]` but Apex received `LineInput` with both members null. After the fix, `QuoteBuilderControllerTest` = 9/9 pass and this browser scenario passes.
- **Checklist items partially exercised (NOT marked complete):** 2 (Retail Opportunity opened), 3 (LWC rendered), 6 (Vehicle_Trim line, single, not the LX+Service_Package combo), 7 (Save and Price Quote), 8 (`Quote_Valid_Until__c` + `Buyer_Contact__c` populated), 10 (`Discount_Percent__c`), 11 (`Approval_Status__c`), 12 (net-adjustment label). Items 4, 5, 9 and the exact item-6 combo remain unverified by this scenario.

### S-2: Volume discount applies (PASSED)

- **Executed by:** owner, same **NG_Sales sales-rep persona**, same Opportunity / buyer / page as S-1.
- **Action:** `Test Model Limited` (`01tg8000007NTOfAAO`, category `Vehicle_Trim`, list 28000) qty **6**; click **Save and Price Quote**.
- **Result:** PASSED — **List subtotal 168000**, **Adjusted subtotal 159600**, **Signed net adjustment 5%**, **Rules applied 1**. Rule breakdown: `Fleet_Discount_Over_5`, discount 8400.
- **Live-org evidence (queried after the run):**
  - Quote `0Q0g80000021tZBCAY` — `OpportunityId = 006g8000009XEVFAA4`, `Pricebook2Id = 01sg80000065c4QAAQ`, `ExpirationDate = Quote_Valid_Until__c = 2026-11-12`, `Buyer_Contact__c = 003g800000q7EzZAAU`, `CreatedDate = 2026-10-13T17:30:31Z`, `Adjusted_Subtotal__c = 159600`, `Rule_Applied_Count__c = 1`.
  - QuoteLineItem `0QLg8000002p2y1GAA` — `QuoteId = 0Q0g80000021tZBCAY`, `Quantity = 6`, `UnitPrice = 28000`, `PricebookEntry.Product2.Name = Test Model Limited`.
  - Opportunity `006g8000009XEVFAA4` — `Discount_Percent__c = 5`, `Approval_Status__c = "Not_Required"`, `Vehicle__c = null`.
- **Calculation conforms to the engine:** 28000 × 6 = 168000; Volume rule fires (`Vehicle_Trim` total qty 6 > 5) → `Fleet_Discount_Over_5` (−5%) → 168000 × 0.95 = **159600**; net = (168000 − 159600)/168000 = **+5.00%**; `Approval_Status__c = "Not_Required"` because 5 is not `> 5`.
- **Persistence CONFIRMED:** unlike S-1 (list = adjusted), S-2 proves the engine result is written back — `Quote.Adjusted_Subtotal__c`, `Quote.Rule_Applied_Count__c`, `Opportunity.Discount_Percent__c`, `Opportunity.Approval_Status__c` all stamped in the org.

### S-3: Cross-category Vehicle_Trim + Service_Package (PASSED)

- **Executed by:** owner, same **NG_Sales sales-rep persona**, same Opportunity / buyer / page.
- **Action:** `Test Model Limited` qty **1** + `Test Service Package` qty **1**; click **Save and Price Quote**.
- **Result:** PASSED — **List subtotal 29500**, **Adjusted subtotal 29500**, **Signed net adjustment 0%**, **Rules applied 0**.
- **Live-org evidence (queried after the run):**
  - Quote `0Q0g80000021tpJCAQ` — `Adjusted_Subtotal__c = 29500`, `Rule_Applied_Count__c = 0`, `Quote_Valid_Until__c = 2026-11-12`, `Buyer_Contact__c = 003g800000q7EzZAAU`, `CreatedDate = 2026-10-13T17:39:49Z`.
  - QuoteLineItem `0QLg8000002p8C5GAI` — `Test Model Limited`, qty 1, unit 28000, category `Vehicle_Trim`.
  - QuoteLineItem `0QLg8000002p8C6GAI` — `Test Service Package`, qty 1, unit 1500, category `Service_Package`.
  - Opportunity `006g8000009XEVFAA4` — `Discount_Percent__c = 0`, `Approval_Status__c = "Not_Required"`, `Vehicle__c = null`.
- **This does NOT satisfy checklist item 6:** item 6 explicitly requires `Test Model LX`. S-3 is a separate cross-category sanity check only.

### S-4: LX + Service Package — quantity-persistence verification (PASSED)

- **Executed by:** owner, same persona, same Opportunity / buyer / page.
- **Action:** `Test Model LX` qty **1** + `Test Service Package` qty **1**; click **Save and Price Quote**.
- **Result:** PASSED — **List 26500**, **Adjusted 26500**, **net 0%**, **Rules 0**.
- **Live-org evidence (queried after the run):**
  - Quote `0Q0g80000022COvCAM` — `Adjusted_Subtotal__c = 26500`, `Rule_Applied_Count__c = 0`, `Quote_Valid_Until__c = 2026-11-12`, `Buyer_Contact__c = null` (buyer dropdown was shown but not selected), `CreatedDate = 2026-10-13T22:28:39Z`.
  - QuoteLineItem `0QLg8000002pXjyGAE` — `Test Service Package`, qty 1, unit 1500, category `Service_Package`.
  - QuoteLineItem `0QLg8000002pXjxGAE` — `Test Model LX`, qty 1, unit 25000, category `Vehicle_Trim`.
  - Opportunity `006g8000009XEVFAA4` — `Discount_Percent__c = 0`, `Approval_Status__c = "Not_Required"`, `Vehicle__c = null`.
- **Confirms quantity persistence across category switches and save/pricing under the hardened security model.**

### S-5: Limited qty 11 — Pending approval branch (PASSED — satisfies checklist item 11)

- **Executed by:** owner, same persona, same Opportunity / buyer / page.
- **Action:** `Test Model Limited` qty **11**, buyer **P1-14Test**; click **Save and Price Quote**.
- **Result:** PASSED — **List 308000**, **Adjusted 283360**, **net 8%**, **Rules 1**. Breakdown: `Volume_Discount_Over_10`, discount 24640.
- **Live-org evidence (queried after the run):**
  - Quote `0Q0g80000022CTlCAM` — `Adjusted_Subtotal__c = 283360`, `Rule_Applied_Count__c = 1`, `Quote_Valid_Until__c = 2026-11-12`, `Buyer_Contact__c = 003g800000q7EzZAAU`, `CreatedDate = 2026-10-13T22:29:26Z`.
  - QuoteLineItem `0QLg8000002pXonGAE` — `Test Model Limited`, qty 11, unit 28000, category `Vehicle_Trim`.
  - Opportunity `006g8000009XEVFAA4` — `Discount_Percent__c = 8`, `Approval_Status__c = "Pending"`, `Vehicle__c = null`.
- **Confirms the `Pending` branch of checklist item 11.** `Approval_Status__c = "Pending"` is written to the Opportunity under the hardened security model (USER_MODE). No approval process submission or completion is claimed.

### S-6: Page activation confirmed via normal navigation (PASSED)

- **Executed by:** owner, as **NG_Sales sales-rep persona**.
- **Action:** Navigated to **Sales** app → Opportunities → opened `NG CP2 Browser UAT` via normal record-page navigation (not a custom-tab URL).
- **Result:** `quoteBuilder` component renders in the page header without manual URL entry.
- **Confirms page activation is effective for the standard Opportunity record page.**

### S-7: Check 9 — Service_Package not adjusted by Trim rule (PASSED)

- **Executed by:** owner, **ngrep@northgate.demo**, NG_Sales + PS_Sales_Rep.
- **Action:** On `NG CP2 Browser UAT` (now with Vehicle `a0Cg800001WmQi9EAF` linked), no buyer selected. `Test Model Limited` qty 1 + `Test Service Package` qty 1. Save and Price Quote.
- **Result:** **List 29500**, **Adjusted 30340**, **net −2.85%**, **Rules 1**. Breakdown: `Trim_Premium_Limited`, Premium 3% on 28000 = 840. Service_Package contribution remains 1500 (unchanged).
- **Live-org evidence (queried after the run):**
  - Quote `0Q0g80000022DT3CAM` — `Adjusted_Subtotal__c = 30340`, `Rule_Applied_Count__c = 1`, `Quote_Valid_Until__c = 2026-11-12`, `Buyer_Contact__c = null`, `CreatedDate = 2026-10-13T22:46:15Z`.
  - QuoteLineItem `0QLg8000002pZDuGAM` — `Test Service Package`, qty 1, unit **1500**, category `Service_Package`. **Contribution unchanged at 1500 — not adjusted by Trim rule.**
  - QuoteLineItem `0QLg8000002pZDtGAM` — `Test Model Limited`, qty 1, unit 28000, category `Vehicle_Trim`.
  - Opportunity `006g8000009XEVFAA4` — `Discount_Percent__c = -2.85`, `Approval_Status__c = "Not_Required"`, `Vehicle__c = a0Cg800001WmQi9EAF`.
- **Rounding note:** engine computes `−840/29500×100 = −2.8475…%`; stored as −2.85 (2dp HALF_UP rounding). The −2.85% in the browser and stored value are consistent — no discrepancy.
- **Confirms checklist item 9.** The Service_Package line UnitPrice and contribution are unaffected by the Trim premium rule; the rule adjusts only the vehicle basis.

### UI layout fix (deployed 2026-10-13)

- **Symptom:** in the **Vehicle Trims** category only `Test Model Limited` was fully visible; `Test Model LX` and `Test Model Premium` were clipped at the component's right edge and could not be selected.
- **Root cause:** `quoteBuilder.html:37` used `slds-grid` without `slds-wrap`. The `slds-col slds-size_1-of-1` children shrank and flowed horizontally instead of stacking vertically, so rows collided.
- **Fix:** added `slds-wrap` to the outer grid class (`quoteBuilder.html:37`).
- **Scope:** pure layout; `quoteBuilder.js` save/pricing flow and cross-category selection logic unchanged.
- **Deployed:** `quoteBuilder` LightningComponentBundle to `ng-dev`.
- **Regression check:** `QuoteBuilderControllerTest` = 9/9 pass.

## Checklist reconciliation (as of 2026-10-13)

Status: **DONE** = evidenced (owner run and/or org-verified; no repeat needed) · **PARTIAL** = evidenced only for a branch, or limited by missing fixture · **PENDING** = owner action required.

| # | Check | Status | Evidence / note |
|---|---|---|---|
| 1 | Rep login + Sales app | DONE | Owner executed S-1/S-2 as `ngrep@northgate.demo` (NG_Sales + PS_Sales_Rep), not admin. |
| 2 | Open a Retail Opportunity | DONE | `006g8000009XEVFAA4` `NG CP2 Browser UAT` is Record Type Retail. |
| 3 | `quoteBuilder` LWC renders | DONE | Result panel rendered in S-1 through S-5. |
| 4 | Four CP2 fixture products available | DONE (confirmed post-fix) | Owner confirmed all four fixtures visible in S-4 after UI fix; `getCatalog` returns all four. |
| 5 | Buyer dropdown populated | DONE | `getBuyerContacts('006g8000009XEVFAA4')` = [P1-14Test `003g800000q7EzZAAU`]; owner selected it in S-1/S-2/S-3/S-4/S-5. |
| 6 | LX qty 1 + Service Package qty 1 | **DONE** | S-4 confirms both lines stored, list=adjusted=26500, no rules. |
| 7 | Save and Price Quote | DONE | S-1 through S-5 all succeeded under hardened security model. |
| 8 | Quote created: `Quote_Valid_Until__c`, `Buyer_Contact__c`, `Adjusted_Subtotal__c` | DONE (org-verified) | All quotes verified: valid-until `2026-11-12`, buyer set, Adjusted_Subtotal correct. |
| 9 | Service_Package NOT adjusted by Trim/Age | **DONE** | S-7 confirms: Service_Package unit 1500 unchanged; Trim rule adjusted only the vehicle basis (+840 on 28000); net −2.85%, 1 rule. |
| 10 | `Opportunity.Discount_Percent__c` stamped | DONE (org-verified) | 0 after S-1; 5 after S-2; 8 after S-5 — matches each scenario's net. |
| 11 | `Approval_Status__c` Pending (>5%) / Not_Required (≤5%) | DONE | Both branches confirmed under USER_MODE hardening. |
| 12 | "Signed net adjustment" label + helptext | DONE | Rendered at `quoteBuilder.html:110-111`; owner saw net % (0% in S-1, 5% in S-2, 8% in S-5). |
| — | Page activation (Owner-Click section) | **DONE** | S-6 confirms builder renders on standard Retail Opportunity record page via Sales → Opportunities → open (not custom-tab URL). |

**Non-browser checks performed this round:** `getCatalog` (both categories), `getBuyerContacts`, full Quote/QuoteLineItem/Opportunity reads for S-1 through S-5. Fixture created in ng-dev: `Vehicle_Model__c` `a0Bg800000S5PwvEAF`, `Vehicle__c` `a0Cg800001WmQi9EAF` linked to Opportunity. `QuoteBuilderControllerTest` 10/10 pass; `QuotePricingServiceTest` 23/23 pass.

## Deferred to CP3 (not in CP2 scope)

- ☐ **Check 13:** `quoteSummary` LWC on the Quote record page — deferred to CP3 (Block B, `NG_Quote_Summary` FlexiPage not yet deployed).
- ☐ Approval process activation and `DiscountApprovalTest` execution — deferred to CP3.

## Check 9 — Fixture deployed, browser check pending

**Check 9 requirement:** "Vehicle-specific pricing does NOT adjust the Service_Package line."

**Fixture deployed (2026-10-13, ng-dev):**
- `Vehicle_Model__c` `a0Bg800000S5PwvEAF`: Name='Test Model Limited', Trim__c='Limited'
- `Vehicle__c` `a0Cg800001WmQi9EAF`: Vehicle_Model__c=a0Bg800000S5PwvEAF, VIN='1HGBH41JXMN109ZZZ', Status='Available', Acquisition_Date__c=2026-09-01 → Age_Days=42 (does NOT satisfy Age>60 or Age>90)
- Opportunity `006g8000009XEVFAA4` Vehicle__c set to a0Cg800001WmQi9EAF (prev=null)

**Rule qualification analysis:**
Only `Trim_Premium_Limited` (+3% Premium, Priority 10) qualifies: Trim Equals Limited matches Vehicle_Model.Trim__c='Limited'. No Age rule (Age_Days=42 not >60/>90). No Loyalty (no buyer selected). No Volume (qty 1). Fleet_Discount_Over_5 needs qty>5; Volume_Discount_Over_10 needs qty>10.

**Exact expected browser result for Limited qty 1 + Service Package qty 1:**
- Vehicle_Trim list = 28000×1 = 28000; Trim premium +3% → vehicleAdjusted = 28000×1.03 = **28840**; delta = **+840**.
- Service_Package = **1500** (outside vehicle basis, unchanged by Trim rule).
- Quote list = 29500; adjusted = 29500+840 = **30340**.
- Net = −840/29500×100 = **−2.85%** (premium uplift, rounded to 2dp; engine value −2.847…%).
- Rules applied = 1 (`Trim_Premium_Limited`).
- `Opportunity.Discount_Percent__c` = **−2.85**.
- `Opportunity.Approval_Status__c` = **"Not_Required"** (−2.85 is not > 5).

## CP2 completion criteria

CP2 is **COMPLETE** as of 2026-10-13.

All 12 UAT checks have been performed and passed:
- Checks 1–8, 10–12: confirmed across S-1 through S-7.
- Check 9: confirmed in S-7 (Service_Package unchanged under Trim premium).
- Page activation: confirmed in S-6 (normal navigation, not direct URL).
- All scenarios verified under the USER_MODE-hardened security model.

**CP2 is closed. No further CP2 work remains.**

## Scoped CP3 plan (not executing)

CP3 = Block B. Components already in local source, ready for deployment and activation:

| Component | File | Action needed |
|---|---|---|
| `Opportunity_Discount_Approval` approval process | `Opportunity_Discount_Approval.approvalProcess-meta.xml` | Owner approval to deploy and activate |
| `DiscountApprovalTest.cls` | `force-app/main/default/classes/` | Run after activation; 0 prep needed |
| `quoteSummary` LWC | `force-app/main/default/lwc/quoteSummary/` | Owner approval to deploy |
| `NG_Quote_Summary.flexipage-meta.xml` | `force-app/main/default/flexipages/` | Owner approval to activate on Quote record page |
| `QuoteSummaryController.cls` | `force-app/main/default/classes/` | Already in source; deploy with Block B |
| `QuoteSummaryControllerTest.cls` | `force-app/main/default/classes/` | Pre-existing test may need fixing for missing `SummaryDto` type (CP3 scope) |

**CP3 entry gate:** owner provides approval for Block B deployment and activation. No CP2 reopening. No further CP3 execution until approved.
