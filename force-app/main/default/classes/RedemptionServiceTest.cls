@isTest
private class RedemptionServiceTest {
    @TestSetup static void actors() {
        LoyaltyBatch2TestData.user('operator', new List<String>{'PS_Loyalty_Operator'});
        LoyaltyBatch2TestData.user('denied', new List<String>());
    }
    @isTest static void operatorRedeemsOnceAndRejectsOverdraftOrChangedReplay() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 2, 100);
        LoyaltyLedgerService.tiersOverride[0].Expiry_Days__c = 1;
        LoyaltyAccrualService.process('Service', new Set<Id>{visits[0].Id});
        LoyaltyLedgerService.tiersOverride[0].Expiry_Days__c = 30;
        LoyaltyAccrualService.process('Service', new Set<Id>{visits[1].Id});
        User actor = [SELECT Id FROM User WHERE LastName = 'Batch2 operator' LIMIT 1];
        System.runAs(actor) {
            System.assert(FeatureManagement.checkPermission('Redeem_Loyalty_Points'));
            System.assert(!FeatureManagement.checkPermission('Bypass_Automation'));
            System.assert(!Schema.SObjectType.Loyalty_Member__c.isUpdateable());
            RedemptionService.Result result = RedemptionService.redeem(member.Id, 120, 'one-request');
            System.assertEquals(80, result.balance); System.assertEquals(1.2, result.valueCad);
            System.assertEquals(80, RedemptionService.redeem(member.Id, 120, 'one-request').balance);
            Boolean rejected = false;
            try { RedemptionService.redeem(member.Id, 121, 'one-request'); }
            catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = true; }
            System.assert(rejected);
            rejected = false;
            try { RedemptionService.redeem(member.Id, 81, 'overdraft'); }
            catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = true; }
            System.assert(rejected);
        }
        System.assertEquals(2, [SELECT COUNT() FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id AND Type__c = 'Redemption']);
        List<Loyalty_Transaction__c> lots = [SELECT Remaining_Points__c FROM Loyalty_Transaction__c
            WHERE Loyalty_Member__c = :member.Id AND Type__c = 'Accrual' WITH SYSTEM_MODE ORDER BY Expiry_Date__c];
        System.assertEquals(0, lots[0].Remaining_Points__c); System.assertEquals(80, lots[1].Remaining_Points__c);
    }
    @isTest static void deniedActorCannotUseElevatedWriterAndLegacyBalanceCannotBeSpent() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 100);
        User deniedActor = [SELECT Id FROM User WHERE LastName = 'Batch2 denied' LIMIT 1];
        System.runAs(deniedActor) {
            System.assert(!FeatureManagement.checkPermission('Redeem_Loyalty_Points'));
            Boolean denied = false;
            try { RedemptionService.redeem(member.Id, 1, 'denied'); } catch (AuraHandledException expected) { denied = true; }
            System.assert(denied);
        }
        Boolean rejected = false;
        try { LoyaltyLedgerService.redeem(member.Id, 1, 'historical'); }
        catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = true; }
        System.assert(rejected); System.assertEquals(100, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
        System.assertEquals(0, [SELECT COUNT() FROM Loyalty_Transaction__c]);
    }
    @isTest static void invalidPointsAndFailedMemberWriteRollBackLotsAndDebits() {
        LoyaltyBatch2TestData.configure();
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        member.Lifetime_Points_Redeemed__c = 999999999; update member;
        LoyaltyAccrualService.process('Service', LoyaltyBatch2TestData.ids(LoyaltyBatch2TestData.sources(member, 1, 100)));
        for (Decimal points : new List<Decimal>{0,-1,1.5}) {
            Boolean rejected = false;
            try { LoyaltyLedgerService.redeem(member.Id, points, 'invalid'); }
            catch (LoyaltyLedgerService.LoyaltyException expected) { rejected = true; }
            System.assert(rejected);
        }
        Boolean failed = false;
        try { LoyaltyLedgerService.redeem(member.Id, 1, 'numeric-failure'); } catch (DmlException expected) { failed = true; }
        System.assert(failed);
        System.assertEquals(0, [SELECT COUNT() FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id AND Type__c = 'Redemption']);
        System.assertEquals(100, [SELECT Remaining_Points__c FROM Loyalty_Transaction__c WHERE Loyalty_Member__c = :member.Id WITH SYSTEM_MODE].Remaining_Points__c);
        System.assertEquals(100, LoyaltyBatch2TestData.stored(member.Id).Points_Balance__c);
    }
}
