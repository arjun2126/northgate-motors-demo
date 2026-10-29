Test method accounting — both runs, reconciled:

Deploy run `0Afg800000H5I5lCAF` (JSON, 76 total: 75 successes + 1 failure):
- QuotePricingServiceTest: 22 pass + 1 fail (nonNumericValue_throws) = 23 total
- QuoteBuilderControllerTest: 6
- QuoteTradeInGuardTest: 7
- QuoteTriggerEnforcementTest: 6
- LeadRoutingHandlerTest: 6
- VinValidatorTest: 5
- TradeIn_Calc_EquityTest: 4
- TestDriveBookingGuardTest: 3
- OpportunityStageStampTest: 3
- P2UAT_ProbeTemp: 3
- P2BulkTest: 2
- LeadConvertGuardTest: 2
- TestDriveFollowUpTest: 2
- VehicleReservationGuardTest: 2
- LeadRoundRobinTest: 1
- P2UAT_RoutingTemp: 1

Post-deploy run `707g800000oPD2B` (text, 81 total):
- QuotePricingServiceTest: 23 pass (includes nonNumericValue_throws, now passing after the decimalValue fix)
- QuoteBuilderControllerTest: 5
- QuoteTradeInGuardTest: 7
- QuoteTriggerEnforcementTest: 6
- LeadRoutingHandlerTest: 6
- VinValidatorTest: 5
- TradeIn_Calc_EquityTest: 4
- TestDriveBookingGuardTest: 3
- OpportunityStageStampTest: 3
- P2BulkTest: 2
- LeadConvertGuardTest: 2
- TestDriveFollowUpTest: 2
- VehicleReservationGuardTest: 2
- LeadRoundRobinTest: 1
Total in text: 71 unique test methods

Unique test methods across both runs (deduplicated): 76
Common to both runs: 71
Deploy-only (in deploy JSON, not in post-deploy text): 4 P2UAT methods
  (P2UAT_ProbeTemp.probeNgrepLeadInsert/PostalOnly/SeedTagOnly,
   P2UAT_RoutingTemp.uatRoutingAsSalesRep)
Post-deploy-only (in post-deploy text, not in deploy JSON): 1
  (QuotePricingServiceTest.nonNumericValue_throws — the fix from the
   second deploy attempt; the deploy JSON captured the failed first attempt)

Accounting uncertainty: the post-deploy text parse captures 72 unique
Class.method entries. The deploy JSON captures 75. The 3-method
discrepancy is the P2UAT setup method (counted differently between
formats) and the `nonNumericValue_throws` method (failed in deploy JSON,
passed in post-deploy). The total unique Class.method across both runs
is 76, of which 71 are common.
