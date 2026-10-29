@isTest
private class VehicleServiceHistoryControllerTest {
    @TestSetup static void actors() {
        LoyaltyBatch2TestData.user('history', new List<String>{'PS_Service_Advisor','PS_Vehicle_Service_History'});
        LoyaltyBatch2TestData.user('nohistory', new List<String>());
    }
    @isTest static void vehicleHistoryPaginatesAndRetainsRecordedMileage() {
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 25, 0);
        Id vehicleId = visits[0].Vehicle__c;
        VehicleServiceHistoryController.VisitPage first = VehicleServiceHistoryController.getVisits(vehicleId, null, null);
        System.assertEquals(20, first.rows.size()); System.assert(first.hasMore);
        System.assertEquals(2400, first.rows[0].mileage);
        VehicleServiceHistoryController.VisitRow last = first.rows[19];
        VehicleServiceHistoryController.VisitPage second = VehicleServiceHistoryController.getVisits(vehicleId, last.scheduledStart, last.id);
        System.assertEquals(5, second.rows.size()); System.assert(!second.hasMore);
        Set<Id> firstIds = new Set<Id>(); for (VehicleServiceHistoryController.VisitRow row : first.rows) firstIds.add(row.id);
        for (VehicleServiceHistoryController.VisitRow row : second.rows) System.assert(!firstIds.contains(row.id));
        System.assertEquals(0, VehicleServiceHistoryController.getVisits(null, null, null).rows.size());
    }
    @isTest static void nonAdminSeesOwnVisitsAndCasesButNotHiddenRecords() {
        User actor = [SELECT Id FROM User WHERE LastName = 'Batch2 history' LIMIT 1];
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        List<Service_Visit__c> visits = LoyaltyBatch2TestData.sources(member, 2, 0);
        Case visible = new Case(Subject = 'Accessible visit case', Status = 'New', Origin = 'Web', OwnerId = actor.Id);
        Case hidden = new Case(Subject = 'Private vehicle case', Status = 'New', Origin = 'Web', Vehicle__c = visits[0].Vehicle__c);
        insert new List<Case>{visible, hidden};
        visits[0].OwnerId = actor.Id; visits[0].Case__c = visible.Id; update visits[0];
        System.runAs(actor) {
            System.assert(!FeatureManagement.checkPermission('Bypass_Automation'));
            VehicleServiceHistoryController.VisitPage page = VehicleServiceHistoryController.getVisits(visits[0].Vehicle__c, null, null);
            System.assertEquals(1, page.rows.size()); System.assertEquals(visits[0].Id, page.rows[0].id);
            VehicleServiceHistoryController.CasePage cases = VehicleServiceHistoryController.getCases(visits[0].Vehicle__c, null, null);
            System.assertEquals(1, cases.rows.size()); System.assertEquals(visible.Id, cases.rows[0].id);
        }
        User deniedActor = [SELECT Id FROM User WHERE LastName = 'Batch2 nohistory' LIMIT 1];
        System.runAs(deniedActor) {
            Boolean denied = false;
            try { VehicleServiceHistoryController.getVisits(visits[0].Vehicle__c, null, null); }
            catch (QueryException expected) { denied = true; }
            System.assert(denied);
        }
    }
    @isTest static void casesIncludeDirectVehicleMatchesAndStablePages() {
        Loyalty_Member__c member = LoyaltyBatch2TestData.member('Bronze', 0);
        Id vehicleId = LoyaltyBatch2TestData.sources(member, 1, 0)[0].Vehicle__c;
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 23; i++) cases.add(new Case(Subject = 'History ' + i, Status = 'New', Origin = 'Web', Vehicle__c = vehicleId));
        insert cases;
        VehicleServiceHistoryController.CasePage first = VehicleServiceHistoryController.getCases(vehicleId, null, null);
        System.assertEquals(20, first.rows.size()); System.assert(first.hasMore);
        VehicleServiceHistoryController.CaseRow last = first.rows[19];
        System.assertEquals(3, VehicleServiceHistoryController.getCases(vehicleId, last.createdAt, last.id).rows.size());
        System.assertEquals(0, VehicleServiceHistoryController.getCases(null, null, null).rows.size());
    }
}
