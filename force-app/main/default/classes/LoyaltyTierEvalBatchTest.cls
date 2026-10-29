@isTest
private class LoyaltyTierEvalBatchTest {
    @isTest static void exactThresholdsChooseConfiguredTiersAndNextThresholds() {
        LoyaltyBatch2TestData.configure();
        List<Decimal> amounts = new List<Decimal>{1,4999,5000,24999,25000,49999,50000};
        List<String> expected = new List<String>{'Bronze','Bronze','Silver','Silver','Gold','Gold','Platinum'};
        List<Id> ids = new List<Id>();
        for (Decimal amount : amounts) {
            Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
            LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(LoyaltyBatch2TestData.sources(member, 1, amount)));
            ids.add(member.Id);
        }
        Test.startTest();
        LoyaltyLedgerService.evaluateTiers(new Set<Id>(ids));
        Test.stopTest();
        for (Integer i = 0; i < ids.size(); i++) {
            Loyalty_Member__c stored = LoyaltyBatch2TestData.stored(ids[i]);
            System.assertEquals(expected[i], stored.Tier__c);
            System.assertEquals(LoyaltyLedgerService.today(), stored.Tier_Evaluated_On__c);
            if (i == 6) System.assertEquals(null, stored.Next_Tier_Threshold__c);
            if (i == 2) { System.assertEquals('Bronze', stored.Previous_Tier__c); System.assertEquals(25000, stored.Next_Tier_Threshold__c); }
        }
    }
    @isTest static void downgradeRequiresConfigurationAndLeavesLegacyMembersAlone() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c managed = LoyaltyBatch2TestData.member('Platinum', 0);
        Loyalty_Member__c legacy = LoyaltyBatch2TestData.member('Gold', 50);
        LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(LoyaltyBatch2TestData.sources(managed, 1, 10)));
        Set<Id> ids = new Set<Id>{managed.Id, legacy.Id};
        LoyaltyLedgerService.evaluateTiers(ids);
        System.assertEquals('Platinum', LoyaltyBatch2TestData.stored(managed.Id).Tier__c);
        LoyaltyLedgerService.programOverride.Allow_Downgrades__c = true;
        LoyaltyLedgerService.evaluateTiers(ids);
        Loyalty_Member__c stored = LoyaltyBatch2TestData.stored(managed.Id);
        System.assertEquals('Bronze', stored.Tier__c); System.assertEquals('Platinum', stored.Previous_Tier__c);
        Datetime transition = stored.Tier_Changed_On__c;
        LoyaltyLedgerService.evaluateTiers(ids);
        System.assertEquals(transition, LoyaltyBatch2TestData.stored(managed.Id).Tier_Changed_On__c);
        System.assertEquals('Gold', LoyaltyBatch2TestData.stored(legacy.Id).Tier__c);
        System.assertEquals(50, LoyaltyBatch2TestData.stored(legacy.Id).Points_Balance__c);
        System.assertEquals(null, LoyaltyBatch2TestData.stored(legacy.Id).Tier_Evaluated_On__c);
    }
    @isTest static void batchEntryPointsUseManagedScopeAndSchedulerOnlyQueues() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(LoyaltyBatch2TestData.sources(member, 1, 5000)));
        LoyaltyTierEvalBatch batch = new LoyaltyTierEvalBatch();
        Database.QueryLocatorIterator cursor = batch.start(null).iterator();
        List<SObject> scope = new List<SObject>();
        while (cursor.hasNext()) scope.add(cursor.next());
        System.assertEquals(1, scope.size());
        batch.execute(null, scope); batch.finish(null);
        System.assertEquals('Silver', LoyaltyBatch2TestData.stored(member.Id).Tier__c);
        Integer schedules = [SELECT COUNT() FROM CronTrigger];
        // No Test.stopTest around the queued delegate: Default stays inactive in production and in the org.
        batch.execute((SchedulableContext) null);
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'LoyaltyTierEvalBatch' AND JobType = 'BatchApex']);
        System.assertEquals(schedules, [SELECT COUNT() FROM CronTrigger]);
    }
}
