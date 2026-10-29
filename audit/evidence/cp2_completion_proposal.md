# CP2 Completion Proposal — Final Corrections

## 1. Reconciled PS_Sales_Rep Permission Delta

**Field-by-field and permission-by-permission comparison** (retrieved from org via SOQL; local source from `git show HEAD` and working copy):

### Field permissions

| Source | Count | Detail |
|---|---|---|
| HEAD (`bc66a60`) | 83 | All field permissions in the committed source |
| Org (current) | 83 | Retrieved via `SELECT Field FROM FieldPermissions WHERE ParentId = '0PSg800000DIdNtGAL'` |
| Local (working copy) | 86 | HEAD 83 + 3 new Quote FLS |

**Deploy delta (field permissions):**
- **Additions:** +3 (exactly the approved Quote Read+Edit entries):
  1. `Quote.Quote_Valid_Until__c` (editable=true, readable=true)
  2. `Quote.Adjusted_Subtotal__c` (editable=true, readable=true)
  3. `Quote.Buyer_Contact__c` (editable=true, readable=true)
- **Removals:** 0
- **Net:** +3. Total in org after deploy: 86 (83 existing + 3 new).

### Object permissions

| Source | Count | Detail |
|---|---|---|
| HEAD | 10 | Account, Contact, Lead, Opportunity, Quote, Rooftop__c, Staff__c, Test_Drive__c, Trade_In__c, Vehicle__c |
| Org | 10 | Same 10 |
| Local | 10 | Same 10 |

**Deploy delta (object permissions):** 0 additions, 0 removals.

### System permissions

| Source | Count | Detail |
|---|---|---|
| HEAD | 2 | `ViewRoles`, `RunReports` |
| Org | 0 | `SetupEntityAccess` query returned 0 records for this PS |
| Local | 2 | Same 2 as HEAD (in correct metadata API position: before `<objectPermissions>`) |

**Deploy delta (system permissions):**
- **Additions:** +2 (`ViewRoles`, `RunReports`) — these are existing approved permissions from HEAD that the org is missing. This is a **pre-existing org gap**, not part of the CP2-approved change. The local source preserves them per HEAD.
- **Removals:** 0
- **Net:** +2. Total in org after deploy: 2 (0 existing + 2 from HEAD).

**Correction acknowledged:** The previous proposal stated "delta: 0" for system permissions, which was incorrect. The deploy will add 2 system permissions. This is a pre-existing gap between the approved source (HEAD) and the org's deployed state. The local source was corrected to match HEAD (adding back the 2 system permissions that were temporarily removed).

### Summary

| Permission type | HEAD | Org | Local | Deploy adds | Deploy removes |
|---|---|---|---|---|---|
| Field | 83 | 83 | 86 | 3 | 0 |
| Object | 10 | 10 | 10 | 0 | 0 |
| System | 2 | 0 | 2 | 2 | 0 |
| **Total** | **95** | **93** | **98** | **5** | **0** |

**The 3 CP2-approved Quote Read+Edit additions are exactly the field-permission delta.** The 2 system permission additions are a pre-existing gap fix bundled with the deploy. If the owner requires the deploy to be limited to ONLY the 3 Quote FLS, the 2 system permissions must be removed from the local source prior to deploy (this would be a divergence from HEAD). **Awaiting owner direction on whether the 2 system permissions are in-scope for CP2.**

## 2. Product Matching — Query by ProductCode

**Lookup key:** `ProductCode` (the four specified codes). ProductCode need not be an external ID or inherently unique; it is the query filter. **Stop on duplicate codes** (2+ matches = abort, do not modify).

**For each ProductCode:**

1. **Query:** `SELECT Id, Name, ProductCode, Category__c, IsActive, Description FROM Product2 WHERE ProductCode = '<code>' LIMIT 5`
2. **0 results:** insert new Product2.
3. **1 result:** verify `Name` = expected, `Category__c` = expected, `IsActive` = true. If all match, **reuse as-is** (do not update). If any field differs, **stop and report** (do not reuse an unrelated product).
4. **2+ results:** stop and report (duplicate codes found).

| ProductCode | Name (expected) | Category__c (expected) | IsActive (expected) | Reuse criteria |
|---|---|---|---|---|
| `NG-CP2-TRIM-PREMIUM` | Test Model Premium | Vehicle_Trim | true | All three must match |
| `NG-CP2-TRIM-LIMITED` | Test Model Limited | Vehicle_Trim | true | All three must match |
| `NG-CP2-TRIM-LX` | Test Model LX | Vehicle_Trim | true | All three must match |
| `NG-CP2-SVC-PKG` | Test Service Package | Service_Package | true | All three must match |

## 3. Existing PricebookEntries — Query Before Reuse

**For each (Pricebook2Id, Product2Id) pair, query all fields including UnitPrice, IsActive, UseStandardPrice:**

`SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice FROM PricebookEntry WHERE Pricebook2Id = '01sg80000065c4QAAQ' AND Product2Id IN (<4 Product2Ids>)`

**Reuse logic:**
- **0 results:** insert new PBE with the values from §1 of the resolved proposal.
- **1 result:** report the exact record. If `UnitPrice` or `IsActive` differs from the proposed value, **report the diff and request confirmation before modifying.** If all match, reuse as-is.
- **2+ results:** stop and report (duplicate PBE found).

**Proposed PBE values (from previous correction):**

| Product2 | Pricebook2Id | UnitPrice | IsActive | UseStandardPrice |
|---|---|---|---|---|
| Test Model Premium | 01sg80000065c4QAAQ | 30000.00 | true | false |
| Test Model Limited | 01sg80000065c4QAAQ | 28000.00 | true | false |
| Test Model LX | 01sg80000065c4QAAQ | 25000.00 | true | false |
| Test Service Package | 01sg80000065c4QAAQ | 1500.00 | true | false |

**Current org state:** 0 PBEs match these 4 products (query returned 0 results). All 4 PBEs will be inserts (not reuses). **No existing records require changes.** If the query returns non-zero results, the proposal pauses and reports the exact records before any modification.

## 4. Page Assignment — Activation Selection

**FlexiPage:** `NG_Opportunity_Quote_Builder` (deployed, ID `0M0g8000006NJjGCAW`).

**Activation selection (exact):**
- **App:** Standard `Sales` (not `Northgate_Admin`, not org default).
- **Profile:** `NG_Sales` (ID `00eg80000082iEtAAI`). **NG_Sales is explicitly included** in the activation selection, not a broader app default.
- **Record type:** `Opportunity.Retail` (ID `012g8000004qUCkAAM`).
- **Form factor:** Desktop.

**Method:** Owner-click via Lightning App Builder.
1. Open an Opportunity (Retail record type) in the Sales app on desktop.
2. Click the gear icon → "Edit Page".
3. Select `NG_Opportunity_Quote_Builder` from available pages.
4. Click "Activate" → select the **Sales** app, the **NG_Sales** profile, the **Opportunity.Retail** record type, and **Desktop** form factor.
5. Save.

**No broader app default or org default is applied.** The `Northgate_Admin` app and the `Opportunity.Fleet` record type are not affected.

## 5. Final Scoped CP2 Execution Plan

| Step | Action | Command | Prerequisites |
|---|---|---|---|
| 1 | Query 4 Product2 by ProductCode | `sf data query --query "SELECT Id, Name, ProductCode, Category__c, IsActive, Description FROM Product2 WHERE ProductCode IN ('NG-CP2-TRIM-PREMIUM','NG-CP2-TRIM-LIMITED','NG-CP2-TRIM-LX','NG-CP2-SVC-PKG') LIMIT 5" -o ng-dev` | None |
| 2 | Verify matches | For each result, verify `Name`, `Category__c`, `IsActive` match expected. Stop if any field differs. | Step 1 |
| 3 | Insert missing Product2 | `sf data create record --sobject Product2 --values "Name='<expected>' ProductCode='<code>' Category__c='<expected>' IsActive=true" -o ng-dev` (per missing) | Step 2 |
| 4 | Query Product2Ids | `sf data query --query "SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN (...) LIMIT 4" -o ng-dev` | Step 3 |
| 5 | Query existing PBEs | `sf data query --query "SELECT Id, Pricebook2Id, Product2Id, UnitPrice, IsActive, UseStandardPrice FROM PricebookEntry WHERE Pricebook2Id = '01sg80000065c4QAAQ' AND Product2Id IN (<4 ids>)" -o ng-dev` | Step 4 |
| 6 | Verify or report PBEs | 0 results → proceed to Step 7. 1 result → verify fields, report diff if any. 2+ results → stop. | Step 5 |
| 7 | Insert or skip PBEs | For each product with 0 existing PBEs: `sf data create record --sobject PricebookEntry --values "Pricebook2Id='01sg80000065c4QAAQ' Product2Id='<id>' UnitPrice=<value> IsActive=true UseStandardPrice=false" -o ng-dev` | Step 6 |
| 8 | Activate Standard Price Book | `sf data update --sobject Pricebook2 --record-id 01sg80000065c4QAAQ --values "IsActive=true" -o ng-dev` | None (parallel with Steps 1–7) |
| 9 | Deploy PS_Sales_Rep (3 Quote FLS) | `sf project deploy start --manifest audit/evidence/cp2_final_ps_sales_rep_manifest.xml --target-org ng-dev --test-level RunLocalTests --wait 180` | Step 8 (Price Book active for PBE queries) |
| 10 | Post-deploy UAT (automated) | `sf apex run test --test-level RunLocalTests --target-org ng-dev --wait 180 --code-coverage` | Step 9 |
| 11 | Owner-click FlexiPage activation | Lightning App Builder: activate `NG_Opportunity_Quote_Builder` for **Sales** + **NG_Sales** + **Opportunity.Retail** + **Desktop** | Step 10 |
| 12 | Browser UAT (manual, sales-persona) | Owner logs in as NG_Sales sales-rep user, opens Opportunity (Retail) in Sales app, verifies LWC renders, exercises Save flow, verifies Service_Package line is not adjusted by vehicle-specific pricing. See `audit/evidence/cp2_browser_uat_checklist.md`. | Step 11 |

**Step 9 expected outcome:** Deploy succeeds. `DiscountApprovalTest` is not deployed (CP3 scope). `QuotePricingService` coverage ≥ 90%. All deployed tests pass.

**No CP3 work in this plan.** CP3 is a separate approval.

## Explicit Exclusions

- No `PS_Sales_Rep` assignment to any user.
- No new `PricebookEntry.Seed_Tag__c` field.
- No `sf data upsert bulk` for Product2 or PricebookEntry.
- No new price book or currency.
- No approval process activation (CP3).
- No Block C reports/dashboard (CP4).
- No P3-02 changes.
- No commits, pushes, tags, or ng-demo changes.
- No broader permission grants.

**No org commands will be executed until this CP2 completion proposal is approved.**

## Outstanding Question (resolved)

**Resolved with Option 2 (exclude the 2 system permission additions).** The deploy added exactly 3 Quote field FLS entries with 0 removals and 0 system permission changes. The isolated deployment artifact at `audit/evidence/cp2-deploy-isolated/permissionsets/PS_Sales_Rep.permissionset-meta.xml` contains exactly 86 field permissions (83 existing + 3 new), 10 object permissions, and 0 system permissions. The 2 pre-existing system permissions in HEAD (`ViewRoles`, `RunReports`) remain a pre-existing org gap, addressed separately.

## CP2 completion criteria (corrected)

CP2 is **NOT complete** until the owner performs:
1. Page activation (Lightning App Builder, Sales + NG_Sales + Opportunity.Retail + Desktop).
2. All 12 browser UAT checks in `audit/evidence/cp2_browser_uat_checklist.md` (sales-persona, not admin).
3. Reports the results.

**Check 13 (`quoteSummary` on Quote page) is deferred to CP3.** The `NG_Quote_Summary` FlexiPage and `quoteSummary` LWC are Block B / CP3 scope and are not yet deployed.
