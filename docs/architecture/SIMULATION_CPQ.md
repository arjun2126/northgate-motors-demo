# SIMULATION_CPQ

Demo note for the P3-04..P3-12 revenue-rules scope (M2/M3 workshop content).

## Scope seam

This package implements Northgate's **revenue rules** in Salesforce:

- `QuotePricingService`: age, trim, loyalty, volume discounts and trim premiums.
- `quoteBuilder` LWC: captures account, buyer, tier, and the primary vehicle in one flow.
- `quoteSummary` LWC: shows standard vs adjusted totals on the Quote record.
- `Opportunity_Discount_Approval` process + `DiscountApprovalTest`: >5% needs approval
  (manager <=10, VP >10).
- Reports/dashboard: `NG_05_DataQuality` (stale quotes), `NG_01_Pipeline`
  (`rpt_Discount_Leakage`, `rpt_Win_Loss_by_Reason`), `DM_QuoteHealth`.

## What is simulated, and how

| Domain | Real CPQ | This demo |
|---|---|---|
| Line-level pricing | CPQ pricing engine, guided selling, constraints | `QuotePricingService` on `Quote`, write-only `Adjusted_Subtotal__c` |
| Discount mgmt | CPQ discounts tied to approval + quote doc | Approval process on `Opportunity`, discount stamped as %, leak report |
| Quote document | CPQ quote PDF with adjustment lines | Standard Quote PDF; `quoteSummary` print view supplies adjustment narrative beside it |
| Primary vehicle | CPQ sync to `Vehicle__c` opportunity field | Bind `quoteBuilder` buyer+vehicle on one screen so the basis is unambiguous |

## Demo script (estimated 45-60 min)

1. Open pre-staged opportunity (Vehicle_Model imported, account has Loyalty_Member).
2. `quoteBuilder`: pick account, buyer, tier, vehicle; preview rules by adding 2017 Fleet vehicle with 90+ day age.
3. Save: discount %, rules count, Approval_Status (Pending when >5).
4. Approve via approval process; go to Quote record tab → quoteSummary shows standard list vs adjusted, W-3 note visible; Print / Quote PDF.
5. Backend: `QuotePricingService` test class run (`707...`), fake dashboard demo: `DM_QuoteHealth`, leak + win/loss reports; grid filters show only those data points.
6. Stack rules with existing M1/M2: `LeadEnrichRooftopService` (rooftop enrichment), TestDrive guards.

## Boundaries

- Quote, QuoteLineItem, Opportunity, Product2 and PricebookEntry are standard Salesforce objects.
  Vehicle__c and Loyalty_Member__c are custom objects; Price_Rule__mdt is custom metadata. This
  is custom revenue-rule behavior on Standard Quotes, not licensed Revenue Cloud/CPQ.
- CP2 identifies exactly one primary Vehicle_Trim line matching Opportunity.Vehicle__c's model;
  ambiguous/missing basis blocks authoritative pricing. Discounts and premiums, signed net
  discount and rounding remain in QuotePricingService; Quote Builder/Summary and trigger guards
  preserve accepted validation/identity boundaries. No broad repricing or approval bypass is
  introduced by Phase 7.
- The historical demo steps above describe an intended demo, not permission to create deals,
  approve discounts or claim fresh screenshots. The dashboard is native reporting, not a fake
  tile. Current browser/identity/deployment facts come from the latest handoff, not those examples.
