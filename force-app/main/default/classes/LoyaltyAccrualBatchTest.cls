@isTest
private class LoyaltyAccrualBatchTest {
    @isTest static void batchSelectsAndProcessesOnlyPostRolloutSources() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        LoyaltyBatch2TestData.sources(member, 1, 20);
        LoyaltyAccrualBatch batch = new LoyaltyAccrualBatch('Service');
        Database.QueryLocatorIterator cursor = batch.start(null).iterator();
        List<SObject> scope = new List<SObject>(); while (cursor.hasNext()) scope.add(cursor.next());
        System.assertEquals(1, scope.size()); batch.execute(null, scope); batch.finish(null);
        System.assertEquals(20, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
        System.assert(!new LoyaltyAccrualBatch('Sale').start(null).iterator().hasNext());
        Boolean rejected = false;
        try { new LoyaltyAccrualBatch('Unknown').start(null); }
        catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = true; }
        System.assert(rejected);
    }
}
