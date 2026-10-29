@isTest
private class Batch3ReportingAccessTest {
    @TestSetup static void actors() {
        UserRole manager = new UserRole(Name = 'Batch3 Test Manager'); insert manager;
        UserRole advisor = new UserRole(Name = 'Batch3 Test Advisor', ParentRoleId = manager.Id); insert advisor;
        Batch3TestData.actor('Report advisor one', new List<String>{'PS_Service_Operations_Reporting'}, advisor.Id);
        Batch3TestData.actor('Report advisor two', new List<String>{'PS_Service_Operations_Reporting'}, advisor.Id);
        Batch3TestData.actor('Report manager', new List<String>{'PS_Service_Operations_Reporting','PS_Loyalty_Reporting'}, manager.Id);
    }
    @isTest static void viewerScopedServiceReadDiffersBetweenAdvisorAndManager() {
        User first = [SELECT Id FROM User WHERE LastName = 'Report advisor one' LIMIT 1];
        User second = [SELECT Id FROM User WHERE LastName = 'Report advisor two' LIMIT 1];
        User manager = [SELECT Id FROM User WHERE LastName = 'Report manager' LIMIT 1];
        Contact contact = Batch3TestData.contacts(1)[0];
        Loyalty_Member__c fixture = new Loyalty_Member__c(Contact__c = contact.Id);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(fixture, 2, 0);
        visits[0].OwnerId = first.Id; visits[1].OwnerId = second.Id; update visits;
        System.runAs(first) {
            System.assert(!FeatureManagement.checkPermission('Bypass_Automation'));
            System.assertEquals(1, [SELECT COUNT() FROM Service_Visit__c WITH USER_MODE]);
            System.assert(!Schema.SObjectType.Financing__c.isAccessible());
        }
        System.runAs(manager) {
            System.assertEquals(2, [SELECT COUNT() FROM Service_Visit__c WITH USER_MODE]);
            System.assert(!Schema.SObjectType.Financing__c.isAccessible());
        }
    }
    @isTest static void liabilityUsesStoredBalanceAndDoesNotReconstructHistoricalLedger() {
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Gold', 150);
        insert new Loyalty_Transaction__c(Loyalty_Member__c = member.Id, Type__c = 'Accrual', Reason__c = 'Service_Spend',
            Points__c = 999, Transaction_Date__c = Date.today());
        User manager = [SELECT Id FROM User WHERE LastName = 'Report manager' LIMIT 1];
        System.runAs(manager) {
            Loyalty_Member__c stored = [SELECT Points_Balance__c, Estimated_Liability_CAD__c FROM Loyalty_Member__c WHERE Id = :member.Id WITH USER_MODE];
            System.assertEquals(150, stored.Points_Balance__c); System.assertEquals(1.5, stored.Estimated_Liability_CAD__c);
            System.assert(!Schema.SObjectType.Loyalty_Member__c.isUpdateable());
        }
        System.assertEquals(false, Loyalty_Program__mdt.getInstance('Default').Is_Active__c);
    }
}
