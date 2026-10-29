@isTest
private class OpportunityCalculatorControllerTest {
    @TestSetup static void actors() {
        P7Batch1TestData.actor('Calculator allowed', false, true, true);
        P7Batch1TestData.actor('Calculator denied', false, false, false);
    }
    private static Opportunity opportunity() {
        Opportunity row = new Opportunity(Name = 'P7 isolated estimate', StageName = 'Quoting', CloseDate = Date.today().addDays(30), Amount = 30000);
        insert as system row; return row;
    }
    @isTest static void negativeEquityZeroRateAndConfiguredRatesReuseAcceptedMathWithoutWrites() {
        Opportunity row = opportunity(); User actor = [SELECT Id FROM User WHERE LastName = 'Calculator allowed' LIMIT 1];
        row.OwnerId = actor.Id; update as system row;
        System.runAs(actor) {
            System.assertEquals(30000, OpportunityCalculatorController.amount(row.Id));
            Integer writes = Limits.getDmlStatements();
            OpportunityCalculatorController.Estimate zero = OpportunityCalculatorController.preview(row.Id, 30000, 5000, 10000, 15000, 'A', 60, 0, 'Illustrative zero rate');
            System.assertEquals(-5000, zero.equity); System.assertEquals(30000, zero.principal); System.assertEquals(500, zero.monthlyPayment); System.assertEquals(0, zero.totalInterest);
            OpportunityCalculatorController.Estimate configured = OpportunityCalculatorController.preview(row.Id, 30000, 0, 0, 0, 'A', 60, null, null);
            System.assertEquals(RateTableService.resolve('A', 60).baseRate, configured.annualRate);
            System.assertEquals(PaymentCalculatorService.monthlyPayment(30000, configured.annualRate, 60), configured.monthlyPayment);
            System.assertEquals(writes, Limits.getDmlStatements());
            System.assert(!Schema.SObjectType.Financing__c.isAccessible());
        }
    }
    @isTest static void deniedRecordAndInvalidMoneyAreRejected() {
        Opportunity row = opportunity(); User denied = [SELECT Id FROM User WHERE LastName = 'Calculator denied' LIMIT 1];
        System.runAs(denied) {
            Boolean rejected = false;
            try { OpportunityCalculatorController.amount(row.Id); } catch (Exception expected) { rejected = true; }
            System.assert(rejected);
        }
        Boolean rejected = false;
        try { OpportunityCalculatorController.preview(row.Id, -1, 0, 0, 0, 'A', 60, 0, 'test'); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected); rejected = false;
        try { OpportunityCalculatorController.preview(row.Id, 1, 100, 0, 0, 'A', 60, 0, 'test'); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected); rejected = false;
        try { OpportunityCalculatorController.amount(null); } catch (AuraHandledException expected) { rejected = true; }
        System.assert(rejected);
    }
}
