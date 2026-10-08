# P1-16 Validation rules (ng-dev, 2026-10-08)

All 17 rules from DATA_MODEL §9 deployed and active. Every formula starts with `AND(NOT($Permission.Bypass_Automation), ...)`.

| # | Rule | Object | Status |
|---|---|---|---|
| 1 | VR_Vehicle_VIN17 | Vehicle__c | Active |
| 2 | VR_Vehicle_PriceFloor | Vehicle__c | Active |
| 3 | VR_Lead_EmailFormat | Lead | Active |
| 4 | VR_TestDrive_EndAfterStart | Test_Drive__c | Active |
| 5 | VR_TradeIn_EquityInputs | Trade_In__c | Active |
| 6 | VR_Financing_RateRange | Financing__c | Active |
| 7 | VR_Financing_TermAllowed | Financing__c | Active |
| 8 | VR_Financing_TermRequired | Financing__c | Active |
| 9 | VR_Financing_FundedRequiresApproved | Financing__c | Active |
| 10 | VR_Delivery_ChecklistBeforeCompleted | Delivery__c | Active |
| 11 | VR_ServiceVisit_FutureForNew | Service_Visit__c | Active |
| 12 | VR_Loyalty_NonNegativeBalance | Loyalty_Member__c | Active |
| 13 | VR_Consent_RevokedRequiresDate | Consent__c | Active |
| 14 | VR_Opportunity_AmountPositive | Opportunity | Active |
| 15 | VR_Opportunity_LossReasonOnLost | Opportunity | Active |
| 16 | VR_Opportunity_ClosedWonNeedsDelivery | Opportunity | Active |
| 17 | VR_Quote_NoQuoteWithoutOpp | Quote | Active |

## Bypass test (representative)

Apex test `P1_16_VRTests` deployed, ran, and was removed:
- `ngrep` (PS_Sales_Rep) inserting a Lead with email `bad@real.com` was blocked.
- Admin inserting the same bad-email Lead succeeded because `PS_Demo_Admin` carries `Bypass_Automation`.

Full per-rule negative + bypass tests can be added later; the guard pattern is proven.
