@isTest
private class CaseMilestoneServiceTest {
    @TestSetup static void actors() {
        Batch3TestData.actor('SLA advisor', new List<String>{'PS_Service_Advisor','PS_Service_SLA','PS_Northgate_Consoles'}, null);
        Batch3TestData.actor('SLA denied', new List<String>{'PS_Service_Advisor'}, null);
    }
    private static List<Case> cases(Integer count, Boolean entitled) {
        Account account = new Account(Name = 'Isolated SLA account'); insert as system account;
        Id entitlementId;
        if (entitled) {
            SlaProcess process = [SELECT Id FROM SlaProcess WHERE Name = 'NG Platinum Care' AND IsActive = true LIMIT 1];
            Entitlement entitlement = new Entitlement(Name = 'Isolated Platinum Care', AccountId = account.Id,
                StartDate = Date.today().addDays(-1), EndDate = Date.today().addYears(1), SlaProcessId = process.Id);
            insert as system entitlement; entitlementId = entitlement.Id;
        }
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        List<Case> rows = new List<Case>();
        for (Integer i = 0; i < count; i++) rows.add(new Case(Subject = 'Isolated SLA ' + i, Status = 'New', Origin = 'Web',
            Priority = 'Medium', RecordTypeId = recordTypeId, AccountId = account.Id, EntitlementId = entitlementId,
            SlaStartDate = entitled ? Datetime.now() : null));
        insert as system rows; return rows;
    }
    private static List<CaseMilestone> milestones(Set<Id> ids) {
        return [SELECT Id, CaseId, MilestoneType.Name, StartDate, TargetDate, CompletionDate, TargetResponseInMins
            FROM CaseMilestone WHERE CaseId IN :ids WITH SYSTEM_MODE];
    }
    @isTest static void nativeTimersAndAdvisorCompletionAreIdempotent() {
        User advisor = [SELECT Id FROM User WHERE LastName = 'SLA advisor' LIMIT 1];
        Case row = cases(1, true)[0];
        row.OwnerId = advisor.Id; update as system row;
        List<CaseMilestone> initial = milestones(new Set<Id>{row.Id});
        System.assertEquals(2, initial.size(), 'Native entitlement processing must create both milestones.');
        for (CaseMilestone milestone : initial) {
            System.assertEquals(milestone.MilestoneType.Name == 'NG First Response' ? 240 : 2880, milestone.TargetResponseInMins);
            System.assert(milestone.TargetDate > milestone.StartDate);
        }
        Datetime responded = Datetime.now();
        System.runAs(advisor) {
            System.assert(!FeatureManagement.checkPermission('Bypass_Automation'));
            update as user new Case(Id = row.Id, First_Response_On__c = responded);
        }
        for (CaseMilestone milestone : milestones(new Set<Id>{row.Id})) {
            System.assertEquals(milestone.MilestoneType.Name == 'NG First Response' ? responded : null, milestone.CompletionDate);
        }
        System.runAs(advisor) { update as user new Case(Id = row.Id, Status = 'Closed'); }
        Map<Id, Datetime> completed = new Map<Id, Datetime>();
        for (CaseMilestone milestone : milestones(new Set<Id>{row.Id})) {
            System.assertNotEquals(null, milestone.CompletionDate); completed.put(milestone.Id, milestone.CompletionDate);
        }
        System.runAs(advisor) {
            update as user new Case(Id = row.Id, Status = 'Working');
            update as user new Case(Id = row.Id, Status = 'Closed');
        }
        for (CaseMilestone milestone : milestones(new Set<Id>{row.Id})) System.assertEquals(completed.get(milestone.Id), milestone.CompletionDate);
    }
    @isTest static void bulkCompletionDoesNotInventFirstResponseOnClosure() {
        List<Case> rows = cases(200, true);
        Set<Id> ids = new Map<Id, Case>(rows).keySet();
        System.assertEquals(400, milestones(ids).size());
        for (Case row : rows) row.Status = 'Closed';
        Test.startTest();
        Integer queries = Limits.getQueries(); update as system rows;
        System.assert(Limits.getQueries() - queries < 10, 'No query per Case.');
        Test.stopTest();
        for (CaseMilestone milestone : milestones(ids)) {
            if (milestone.MilestoneType.Name == 'NG Resolution') System.assertNotEquals(null, milestone.CompletionDate);
            else System.assertEquals(null, milestone.CompletionDate, 'Closure is not first response evidence.');
        }
    }
    @isTest static void unentitledBypassAndInvalidEvidenceRemainIsolated() {
        Case plain = cases(1, false)[0];
        plain.Status = 'Closed'; update as system plain;
        System.assertEquals(0, milestones(new Set<Id>{plain.Id}).size());
        Case row = cases(1, true)[0];
        Automation_Settings__c settings = new Automation_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Bypass_Triggers__c = true);
        insert as system settings;
        row.First_Response_On__c = Datetime.now(); update as system row;
        for (CaseMilestone milestone : milestones(new Set<Id>{row.Id})) System.assertEquals(null, milestone.CompletionDate);
        settings.Bypass_Triggers__c = false; update as system settings;
        Database.SaveResult future = Database.update(new Case(Id = row.Id, First_Response_On__c = Datetime.now().addDays(1)), false, AccessLevel.SYSTEM_MODE);
        System.assert(!future.isSuccess());
        System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', String.valueOf(future.getErrors()[0].getStatusCode()));
    }
    @isTest static void deniedAdvisorCannotForgeResponseOrReadHiddenCases() {
        User denied = [SELECT Id FROM User WHERE LastName = 'SLA denied' LIMIT 1];
        Case row = cases(1, true)[0];
        row.OwnerId = denied.Id; update as system row;
        System.runAs(denied) {
            System.assert(!Schema.SObjectType.Case.fields.First_Response_On__c.isUpdateable());
            Boolean rejected = false;
            try { update as user new Case(Id = row.Id, First_Response_On__c = Datetime.now()); }
            catch (DmlException expected) { rejected = true; }
            System.assert(rejected);
        }
        User advisor = [SELECT Id FROM User WHERE LastName = 'SLA advisor' LIMIT 1];
        System.runAs(advisor) {
            System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Id = :row.Id WITH USER_MODE]);
            System.assert(!Schema.SObjectType.Opportunity.isAccessible(), 'Console access must not grant Sales records to Service.');
            System.assert(!Schema.SObjectType.Financing__c.isAccessible(), 'Console access must not grant finance data.');
        }
    }
}
