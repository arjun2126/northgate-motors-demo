@isTest
private class LoyaltyAccrualServiceTest {
    @isTest static void roundsAndReplaysWithoutRepricingPostedEvents() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Silver', 0);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 1, 10.99);
        System.assertEquals(1, LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)));
        System.assertEquals(13, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
        Loyalty_Transaction__c lot = [SELECT Applied_Rate__c, Applied_Multiplier__c, Applied_Tier__c, Source_Spend__c,
            Expiry_Date__c FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id WITH SYSTEM_MODE];
        System.assertEquals(1.25, lot.Applied_Multiplier__c);
        System.assertEquals('Silver', lot.Applied_Tier__c);
        System.assertEquals(10.99, lot.Source_Spend__c);
        System.assertEquals(LoyaltyLedgerService.today().addDays(365), lot.Expiry_Date__c);
        Integer dml = Limits.getDmlStatements();
        System.assertEquals(0, LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)));
        System.assertEquals(dml, Limits.getDmlStatements());
        visits[0].Parts_Cost__c = 20; update visits;
        Boolean rejected = false;
        try { LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)); }
        catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = expected.getMessage().contains('Posted source changed'); }
        System.assert(rejected);
        System.assertEquals(13, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
    }
    @isTest static void accruesTwoHundredSourcesInBulk() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 200, 10);
        Test.startTest();
        Integer queries = Limits.getQueries();
        System.assertEquals(200, LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)));
        System.assert(Limits.getQueries() - queries < 20, 'Queries must not scale per source.');
        Test.stopTest();
        Loyalty_Member__c stored = LoyaltyBatch2TestData.stored(member.Id);
        System.assertEquals(2000, stored.Points_Balance__c);
        System.assertEquals(2000, stored.Lifetime_Points_Earned__c);
        System.assertEquals(2000, stored.Lifetime_Spend__c);
        System.assertEquals(200, [SELECT COUNT() FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id]);
    }
    @isTest static void excludesPreRolloutWarrantyUncompletedAndMissingMembership() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 4, 10);
        Test.setCreatedDate(visits[0].Id, Datetime.now().addDays(-3));
        visits[1].Service_Type__c = 'Warranty_Repair'; visits[2].Status__c = 'Cancelled';
        update new List<Service_Visit__c>{visits[1], visits[2]};
        delete member;
        System.assertEquals(0, LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)));
        System.assertEquals(0, [SELECT COUNT() FROM Loyalty_Transaction__c]);
    }
    @isTest static void zeroNegativeAndDisabledConfigurationFailSafely() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 1, 0);
        System.assertEquals(0, LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)));
        visits[0].Parts_Cost__c = -1; update visits;
        Boolean rejected = false;
        try { LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)); }
        catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = true; }
        System.assert(rejected);
        LoyaltyLedgerService.programOverride.Is_Active__c = false;
        rejected = false;
        try { LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)); }
        catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = true; }
        System.assert(rejected);
        System.assertEquals(0, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
    }
    @isTest static void vehicleSaleUsesOpportunityKeyNotDeliveryKey() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        Service_Visit__c visit = LoyaltyBatch2TestData.sources(member, 1, 0)[0];
        Id accountId = [SELECT AccountId FROM Contact WHERE Id = :member.Contact__c].AccountId;
        Opportunity opportunity = new Opportunity(Name = 'Batch2 sale', AccountId = accountId,
            StageName = 'Closed Won', Delivery_Completed__c = true, CloseDate = Date.today(), Amount = 30000);
        insert opportunity;
        List<Delivery__c> deliveries = new List<Delivery__c>();
        for (Integer i = 0; i < 2; i++) deliveries.add(new Delivery__c(Opportunity__c = opportunity.Id,
            Buyer__c = member.Contact__c, Vehicle__c = visit.Vehicle__c, Status__c = 'Scheduled'));
        insert deliveries;
        for (Delivery__c delivery : deliveries) {
            delivery.Status__c = 'Completed'; delivery.Checklist_Documents__c = true;
            delivery.Checklist_Inspection__c = true; delivery.Checklist_Signature__c = true; delivery.Checklist_Walkthrough__c = true;
        }
        // Complete separately to preserve the existing delivery service's one-Opportunity-per-DML contract.
        update deliveries[0]; update deliveries[1];
        Set<Id> ids = new Map<Id, Delivery__c>(deliveries).keySet();
        System.assertEquals(1, LoyaltyAccrualService.process('Sale', ids));
        System.assertEquals(0, LoyaltyAccrualService.process('Sale', ids));
        System.assertEquals(3000, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
    }
}
