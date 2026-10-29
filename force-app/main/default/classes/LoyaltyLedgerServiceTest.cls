@isTest
private class LoyaltyLedgerServiceTest {
    @isTest static void memberDmlFailureRollsBackInsertedCredit() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 999999999);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 1, 1);
        Boolean failed = false;
        try { LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(visits)); }
        catch (DmlException expected) { failed = true; }
        System.assert(failed, 'A real member numeric overflow must roll back its inserted credit.');
        System.assertEquals(0, [SELECT COUNT() FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id]);
        System.assertEquals(999999999, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
        System.assertEquals(null, LoyaltyBatch2TestData.stored(member.Id).Managed_From__c);
    }
    @isTest static void directManagedEditsFailWhileLegacyPartialSaveSurvives() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(LoyaltyBatch2TestData.sources(member, 1, 100)));
        Loyalty_Transaction__c managed = [SELECT Id, Points__c FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id];
        Loyalty_Transaction__c legacy = new Loyalty_Transaction__c(Loyalty_Member__c = member.Id, Type__c = 'Bonus',
            Reason__c = 'Promotion', Points__c = 5, Transaction_Date__c = Date.today()); insert legacy;
        Database.SaveResult[] results = Database.update(new List<Loyalty_Transaction__c>{
            new Loyalty_Transaction__c(Id = managed.Id, Points__c = 999),
            new Loyalty_Transaction__c(Id = legacy.Id, Points__c = 6)
        }, false);
        System.assert(!results[0].isSuccess(), 'Managed update must fail: ' + JSON.serialize(results));
        System.assert(results[1].isSuccess(), 'Legacy update must survive: ' + JSON.serialize(results));
        Loyalty_Member__c forged = new Loyalty_Member__c(Id = member.Id, Points_Balance__c = 999);
        System.assert(!Database.update(forged, false).isSuccess());
        System.assert(!Database.delete(managed, false).isSuccess());
        System.assert(!Database.delete(new Loyalty_Member__c(Id = member.Id), false).isSuccess());
        System.assertEquals(100, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
        System.assertEquals(100, [SELECT Points__c FROM Loyalty_Transaction__c WHERE Id = :managed.Id].Points__c);
        System.assertEquals(6, [SELECT Points__c FROM Loyalty_Transaction__c WHERE Id = :legacy.Id].Points__c);
        System.assertEquals(0, LoyaltyAccrualService.process('Service', new Set<Id>()));
    }
    @isTest static void rejectsForgedManagedCreationAndMalformedTiers() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        Database.SaveResult denied = Database.insert(new Loyalty_Transaction__c(Loyalty_Member__c = member.Id,
            Type__c = 'Accrual', Points__c = 100, Event_Key__c = 'forged', Transaction_Date__c = Date.today()), false);
        System.assert(!denied.isSuccess());
        member.Managed_From__c = Datetime.now();
        System.assert(!Database.update(member, false).isSuccess());
        LoyaltyLedgerService.tiersOverride[1].Threshold_Amount__c = 0;
        Boolean failed = false;
        try { new LoyaltyLedgerService.Rules(); } catch (LoyaltyLedgerService.LoyaltyException expected) { failed = true; }
        System.assert(failed);
    }
    @isTest static void torontoDatesRespectDstAndUtcMidnight() {
        System.assertEquals(Date.newInstance(2026, 11, 27), LoyaltyLedgerService.torontoDay(Datetime.newInstanceGmt(2026,11,28,4,59,59)));
        System.assertEquals(Date.newInstance(2026, 11, 28), LoyaltyLedgerService.torontoDay(Datetime.newInstanceGmt(2026,11,28,5,0,0)));
        System.assertEquals(Date.newInstance(2026, 7, 1), LoyaltyLedgerService.torontoDay(Datetime.newInstanceGmt(2026,7,1,4,0,0)));
        System.assertEquals(Date.newInstance(2026, 11, 1), LoyaltyLedgerService.torontoDay(Datetime.newInstanceGmt(2026,11,1,5,30,0)));
        System.assertEquals(Date.newInstance(2026, 11, 1), LoyaltyLedgerService.torontoDay(Datetime.newInstanceGmt(2026,11,1,6,30,0)));
    }
}
