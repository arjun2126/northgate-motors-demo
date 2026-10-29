@isTest
private class Loyalty_ExpiryBatchTest {
    @isTest static void partialRedemptionExpiresOnlyUnspentPointsOnFollowingDay() {
        LoyaltyBatch2TestData.configure();
        LoyaltyLedgerService.dateOverride = Date.newInstance(2026, 11, 1);
        LoyaltyLedgerService.tiersOverride[0].Expiry_Days__c = 1;
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(LoyaltyBatch2TestData.sources(member, 1, 100)));
        System.assertEquals(60, LoyaltyLedgerService.redeem(member.Id, 40, 'expiry-split'));
        LoyaltyLedgerService.dateOverride = Date.newInstance(2026, 11, 2);
        System.assertEquals(0, LoyaltyLedgerService.expire(new Set<Id>{member.Id}), 'Valid throughout the expiry date.');
        LoyaltyLedgerService.dateOverride = Date.newInstance(2026, 11, 3);
        System.assertEquals(1, LoyaltyLedgerService.expire(new Set<Id>{member.Id}));
        System.assertEquals(0, LoyaltyLedgerService.expire(new Set<Id>{member.Id}));
        Loyalty_Member__c stored = LoyaltyBatch2TestData.stored(member.Id);
        System.assertEquals(0, stored.Points_Balance__c); System.assertEquals(40, stored.Lifetime_Points_Redeemed__c);
        System.assertEquals(-60, [SELECT Points__c FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id AND Type__c = 'Expiry'].Points__c);
    }
    @isTest static void historicUndatedTransactionsRemainUntouchedAndBatchDelegates() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c legacy = LoyaltyBatch2TestData.member('Gold', 30);
        Loyalty_Transaction__c historical = new Loyalty_Transaction__c(Loyalty_Member__c = legacy.Id,
            Type__c = 'Accrual', Points__c = 100, Transaction_Date__c = Date.today().addYears(-3)); insert historical;
        System.assertEquals(0, LoyaltyLedgerService.expire(new Set<Id>{legacy.Id}));
        System.assertEquals(30, LoyaltyBatch2TestData.stored(legacy.Id).Points_Balance__c);
        System.assertEquals(100, [SELECT Points__c FROM Loyalty_Transaction__c WHERE Id = :historical.Id].Points__c);
        Loyalty_ExpiryBatch batch = new Loyalty_ExpiryBatch();
        System.assert(!batch.start(null).iterator().hasNext()); batch.execute(null, new List<SObject>()); batch.finish(null);
        Integer schedules = [SELECT COUNT() FROM CronTrigger]; batch.execute((SchedulableContext) null);
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'Loyalty_ExpiryBatch' AND JobType = 'BatchApex']);
        System.assertEquals(schedules, [SELECT COUNT() FROM CronTrigger]);
    }
}
