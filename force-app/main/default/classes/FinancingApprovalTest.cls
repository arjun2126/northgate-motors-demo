@isTest
private class FinancingApprovalTest {
    private static final Id STD_PB = Test.getStandardPricebookId();
    private static final String FINANCE_OFFICER_USERNAME =
        'ngfinofficer.' + UserInfo.getOrganizationId() + '@ngtest.northgate.invalid';

    @TestSetup
    static void setup() {
        insert new Rooftop__c(Name = 'Northgate Downtown');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile financeProfile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
            User officer = new User(
                Alias = 'finoffic',
                Email = FINANCE_OFFICER_USERNAME,
                EmailEncodingKey = 'UTF-8',
                FirstName = 'Finance',
                LastName = 'Officer',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = financeProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                UserName = FINANCE_OFFICER_USERNAME
            );
            insert officer;
            List<PermissionSet> permissionSets = [
                SELECT Id FROM PermissionSet WHERE Name = 'PS_Finance_Officer'
            ];
            System.assert(permissionSets.size() == 1, 'PS_Finance_Officer must exist.');
            insert new PermissionSetAssignment(
                AssigneeId = officer.Id, PermissionSetId = permissionSets[0].Id
            );
        }
    }

    private static User financeUser() {
        return [SELECT Id FROM User WHERE Username = :FINANCE_OFFICER_USERNAME LIMIT 1];
    }

    private static Financing__c makeFinancing(String seed, String tier, String rateSource) {
        Account acc = P2TestDataFactory.makeAccount('FinApp' + seed);
        Contact applicant = P2TestDataFactory.makeContact(acc.Id, 'FinApp' + seed);
        Opportunity opp = new Opportunity(
            Name = 'FinOpp' + seed,
            StageName = 'Financing',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        return new Financing__c(
            Opportunity__c = opp.Id,
            Applicant__c = applicant.Id,
            Status__c = 'Draft',
            Amount_Financed__c = 10000,
            Term_Months__c = 60,
            Annual_Rate__c = 5.49,
            Credit_Tier__c = tier,
            Rate_Source__c = rateSource,
            Lender__c = 'Northgate Financial'
        );
    }

    @isTest
    static void requiresApproval_manualException_isTrue() {
        Financing__c f = makeFinancing('A', 'A', 'Manual_Exception');
        System.assert(
            FinancingApprovalService.requiresExceptionApproval(f),
            'Manual_Exception rate requires approval'
        );
    }

    @isTest
    static void requiresApproval_subPrime_isTrue() {
        Financing__c f = makeFinancing('B', 'Sub_Prime', 'Rate_Table');
        System.assert(
            FinancingApprovalService.requiresExceptionApproval(f),
            'Sub_Prime tier requires approval even with Rate_Table rate'
        );
    }

    @isTest
    static void requiresApproval_rateTablePrimeTier_isFalse() {
        Financing__c f = makeFinancing('C', 'A', 'Rate_Table');
        System.assert(
            !FinancingApprovalService.requiresExceptionApproval(f),
            'A-tier Rate_Table does not require exception approval'
        );
    }

    @isTest
    static void submit_createsPendingProcessInstanceWithQueueActor() {
        List<ProcessDefinition> defs = [
            SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Financing_Exception_Approval'
        ];
        System.assert(
            !defs.isEmpty() && defs[0].State == 'Active',
            'Activate Financing_Exception_Approval before this test runs.'
        );
        Financing__c f;
        System.runAs(financeUser()) {
            f = makeFinancing('D', 'Sub_Prime', 'Rate_Table');
            insert f;
            FinancingApprovalService.ApprovalOutcome outcome =
                FinancingApprovalService.submitForExceptionApproval(f.Id);
            System.assertEquals(0, outcome.errors.size(), 'no errors: ' + String.join(outcome.errors, ' | '));
            System.assertNotEquals(null, outcome.processInstanceId, 'process instance created');
            System.assertEquals(true, outcome.requiresApproval);
            System.assertEquals(false, outcome.alreadySubmitted, 'first submit is not a duplicate');
        }
        ProcessInstance pi = [
            SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = :f.Id ORDER BY CreatedDate DESC LIMIT 1
        ];
        System.assertEquals('Pending', pi.Status, 'process instance is Pending');
        ProcessInstanceWorkitem workitem = [
            SELECT ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :pi.Id LIMIT 1
        ];
        Group queue = [SELECT Id, Type FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Q_Finance_Approvals' LIMIT 1];
        System.assertEquals(queue.Id, workitem.ActorId, 'actor is Q_Finance_Approvals queue');
    }

    @isTest
    static void submit_isIdempotent_secondCallReportsAlreadySubmitted() {
        List<ProcessDefinition> defs = [
            SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Financing_Exception_Approval'
        ];
        System.assert(
            !defs.isEmpty() && defs[0].State == 'Active',
            'Activate Financing_Exception_Approval before this test runs.'
        );
        Financing__c f;
        System.runAs(financeUser()) {
            f = makeFinancing('E', 'A', 'Manual_Exception');
            insert f;
            FinancingApprovalService.ApprovalOutcome first =
                FinancingApprovalService.submitForExceptionApproval(f.Id);
            System.assertEquals(0, first.errors.size(), String.join(first.errors, ' | '));
            FinancingApprovalService.ApprovalOutcome second =
                FinancingApprovalService.submitForExceptionApproval(f.Id);
            System.assertEquals(true, second.alreadySubmitted, 'second submit is a no-op');
            System.assertEquals(first.processInstanceId, second.processInstanceId, 'same process instance');
        }
    }

    @isTest
    static void submit_rateTablePrime_rejectsWithNoSubmission() {
        Financing__c f;
        System.runAs(financeUser()) {
            f = makeFinancing('F', 'B', 'Rate_Table');
            insert f;
            FinancingApprovalService.ApprovalOutcome outcome =
                FinancingApprovalService.submitForExceptionApproval(f.Id);
            System.assertEquals(false, outcome.requiresApproval, 'prime tier Rate_Table is not an exception');
            System.assertEquals(null, outcome.processInstanceId, 'no process created');
            System.assertEquals(1, outcome.errors.size(), 'exactly one explanatory error');
        }
    }

    @isTest
    static void approve_writesExceptionApprovedAndDecisionDate() {
        List<ProcessDefinition> defs = [
            SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Financing_Exception_Approval'
        ];
        System.assert(
            !defs.isEmpty() && defs[0].State == 'Active',
            'Activate Financing_Exception_Approval before this test runs.'
        );
        Financing__c f;
        Id processInstanceId;
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Q_Finance_Approvals' LIMIT 1];
        System.runAs(financeUser()) {
            f = makeFinancing('G', 'Sub_Prime', 'Rate_Table');
            insert f;
            FinancingApprovalService.ApprovalOutcome outcome =
                FinancingApprovalService.submitForExceptionApproval(f.Id);
            processInstanceId = outcome.processInstanceId;
        }
        Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
        request.setAction('Approve');
        request.setComments('Approved sub-prime exception.');
        Id workitemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstanceId LIMIT 1].Id;
        request.setWorkitemId(workitemId);
        request.setNextApproverIds(new List<Id>{ queue.Id });
        Approval.ProcessResult result = Approval.process(request);
        System.assert(result.isSuccess(), 'Approve must succeed: ' + result.getErrors());
        Financing__c finalFinancing = [
            SELECT Finance_Exception_Approved__c, Decision_Date__c FROM Financing__c WHERE Id = :f.Id
        ];
        System.assertEquals(true, finalFinancing.Finance_Exception_Approved__c, 'Finance_Exception_Approved__c set to true');
        System.assertEquals(Date.today(), finalFinancing.Decision_Date__c, 'Decision_Date__c stamped today');
    }

    @isTest
    static void reject_writesExceptionApprovedFalse() {
        List<ProcessDefinition> defs = [
            SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Financing_Exception_Approval'
        ];
        System.assert(
            !defs.isEmpty() && defs[0].State == 'Active',
            'Activate Financing_Exception_Approval before this test runs.'
        );
        Financing__c f;
        Id processInstanceId;
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Q_Finance_Approvals' LIMIT 1];
        System.runAs(financeUser()) {
            f = makeFinancing('H', 'A', 'Manual_Exception');
            insert f;
            FinancingApprovalService.ApprovalOutcome outcome =
                FinancingApprovalService.submitForExceptionApproval(f.Id);
            processInstanceId = outcome.processInstanceId;
        }
        Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
        request.setAction('Reject');
        request.setComments('Denied sub-prime exception.');
        Id workitemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstanceId LIMIT 1].Id;
        request.setWorkitemId(workitemId);
        request.setNextApproverIds(new List<Id>{ queue.Id });
        Approval.ProcessResult result = Approval.process(request);
        System.assert(result.isSuccess(), 'Reject must succeed: ' + result.getErrors());
        Financing__c finalFinancing = [
            SELECT Finance_Exception_Approved__c FROM Financing__c WHERE Id = :f.Id
        ];
        System.assertEquals(false, finalFinancing.Finance_Exception_Approved__c, 'Finance_Exception_Approved__c remains false on rejection');
    }
}
