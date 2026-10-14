@isTest
private class DiscountApprovalTest {
    @TestSetup
    static void setup() {
        List<UserRole> roles = [
            SELECT Id, DeveloperName FROM UserRole
            WHERE DeveloperName IN ('Sales_Rep', 'Sales_Manager_Downtown', 'VP_Sales')
        ];
        System.assert(roles.size() == 3, 'Demo roles Sales_Rep, Sales_Manager_Downtown, VP_Sales must exist.');

        Id profileId = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()].Id;
        Map<String, Id> roleIdByName = new Map<String, Id>();
        for (UserRole role : roles) {
            roleIdByName.put(role.DeveloperName, role.Id);
        }

        User repUser = user('rep.approval', 'repapp', 'Sales_Rep', roleIdByName.get('Sales_Rep'), profileId);
        User managerUser = user('manager.approval', 'manapp', 'Sales_Manager_Downtown', roleIdByName.get('Sales_Manager_Downtown'), profileId);
        User vpUser = user('vp.approval', 'vpapp', 'VP_Sales', roleIdByName.get('VP_Sales'), profileId);
        insert new List<User>{ repUser, managerUser, vpUser };
        repUser.ManagerId = managerUser.Id;
        managerUser.ManagerId = vpUser.Id;
        update new List<User>{ repUser, managerUser };
        // Org FLS for Discount_Percent__c / Approval_Status__c lives in
        // permission sets (no profile rows, not even admin). Grant the
        // least-privilege sets matching each test persona's role.
        Map<String, Id> psIdByName = new Map<String, Id>();
        for (PermissionSet ps : [
            SELECT Id, Name FROM PermissionSet WHERE Name IN ('PS_Sales_Rep', 'PS_Sales_Manager')
        ]) {
            psIdByName.put(ps.Name, ps.Id);
        }
        System.assert(psIdByName.size() == 2, 'PS_Sales_Rep and PS_Sales_Manager must exist.');
        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId = repUser.Id, PermissionSetId = psIdByName.get('PS_Sales_Rep')),
            new PermissionSetAssignment(AssigneeId = managerUser.Id, PermissionSetId = psIdByName.get('PS_Sales_Manager')),
            new PermissionSetAssignment(AssigneeId = vpUser.Id, PermissionSetId = psIdByName.get('PS_Sales_Manager'))
        };
    }

    private static User user(String suffix, String alias, String lastName, Id roleId, Id profileId) {
        return new User(
            Username = 'arjun.ngdev+' + suffix + '@northgate.demo',
            Alias = alias,
            Email = 'arjun.ngdev+' + suffix + '@northgate.demo',
            FirstName = 'Appr',
            LastName = suffix,
            ProfileId = profileId,
            UserRoleId = roleId,
            TimeZoneSidKey = 'America/Toronto',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    }

    private static Opportunity makeOpportunity(Decimal discountPercent) {
        return new Opportunity(
            Name = 'Approval Test Opp',
            StageName = 'Negotiation',
            CloseDate = Date.today().addDays(30),
            Discount_Percent__c = discountPercent,
            Approval_Status__c = 'Pending'
        );
    }

    private static Id submitForApproval(Id opportunityId, Id nextApproverId) {
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(opportunityId);
        request.setComments('Discount requires approval.');
        request.setNextApproverIds(new List<Id>{ nextApproverId });
        Approval.ProcessResult result = Approval.process(request);
        System.assert(result.isSuccess(), 'Submission must succeed: ' + result.getErrors());
        return result.getInstanceId();
    }

    private static void approveStep(Id processInstanceId, Id approverId) {
        Id workitemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstanceId LIMIT 1].Id;
        Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
        request.setAction('Approve');
        request.setComments('Approved.');
        request.setWorkitemId(workitemId);
        request.setNextApproverIds(new List<Id>{ approverId });
        Approval.ProcessResult result = Approval.process(request);
        System.assert(result.isSuccess(), 'Approve must succeed: ' + result.getErrors());
    }

    private static void rejectStep(Id processInstanceId, Id approverId) {
        Id workitemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :processInstanceId LIMIT 1].Id;
        Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
        request.setAction('Reject');
        request.setComments('Rejected.');
        request.setWorkitemId(workitemId);
        request.setNextApproverIds(new List<Id>{ approverId });
        Approval.ProcessResult result = Approval.process(request);
        System.assert(result.isSuccess(), 'Reject must succeed: ' + result.getErrors());
    }

    private static User repUser() {
        return [SELECT Id FROM User WHERE LastName = 'rep.approval' LIMIT 1];
    }

    private static User managerUser() {
        return [SELECT Id FROM User WHERE LastName = 'manager.approval' LIMIT 1];
    }

    private static User vpUser() {
        return [SELECT Id FROM User WHERE LastName = 'vp.approval' LIMIT 1];
    }

    private static User liveRep() {
        return [SELECT Id FROM User WHERE Username = 'ngrep@northgate.demo' AND IsActive = true LIMIT 1];
    }

    private static User liveVp() {
        return [SELECT Id FROM User WHERE Username = 'ngpersona@northgate.demo' AND IsActive = true LIMIT 1];
    }

    @isTest
    static void livePersona_rep12_vpApprovesWithWriteBack() {
        List<ProcessDefinition> defs = [SELECT State FROM ProcessDefinition WHERE DeveloperName = 'VP_Discount_Approval'];
        System.assert(!defs.isEmpty() && defs[0].State == 'Active', 'Activate VP_Discount_Approval before this test runs.');
        Id vpId = liveVp().Id;
        System.assertEquals(
            'VP_Sales',
            [SELECT UserRole.DeveloperName FROM User WHERE Id = :vpId].UserRole.DeveloperName,
            'live VP holds VP_Sales role'
        );
        Id opportunityId;
        System.runAs(liveRep()) {
            Opportunity opp = makeOpportunity(12);
            insert opp;
            opportunityId = opp.Id;
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(opp.Id);
            request.setComments('Live 12% VP approval.');
            request.setNextApproverIds(new List<Id>{ vpId });
            Approval.ProcessResult result = Approval.process(request);
            System.assert(result.isSuccess(), 'Live submit must succeed: ' + result.getErrors());
        }
        Id processInstanceId = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opportunityId ORDER BY CreatedDate DESC LIMIT 1].Id;
        List<Id> actors = firstStepActors(processInstanceId);
        System.assertEquals(1, actors.size(), 'one live VP actor');
        System.assertEquals(vpId, actors[0], 'live VP is the approver');
        System.runAs(liveVp()) {
            approveStep(processInstanceId, vpId);
        }
        Opportunity finalOpp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opportunityId];
        System.assertEquals('Approved', finalOpp.Approval_Status__c, 'live approval writes back Approved');
    }

    @isTest
    static void livePersona_controllerDerivesVpFor12() {
        List<ProcessDefinition> defs = [SELECT State FROM ProcessDefinition WHERE DeveloperName = 'VP_Discount_Approval'];
        System.assert(!defs.isEmpty() && defs[0].State == 'Active', 'Activate VP_Discount_Approval before this test runs.');
        Id vpId = liveVp().Id;
        Id stdPb = Test.getStandardPricebookId();
        Opportunity opp = makeOpportunity(12);
        opp.Approval_Status__c = 'Pending';
        opp.OwnerId = liveRep().Id;
        insert opp;
        Quote quote = new Quote(OpportunityId = opp.Id, Name = 'Live Derive Quote', Pricebook2Id = stdPb);
        insert quote;
        Id instanceId;
        System.runAs(liveRep()) {
            instanceId = QuoteBuilderController.submitForApproval(quote.Id);
        }
        List<Id> actors = firstStepActors(instanceId);
        System.assertEquals(1, actors.size(), 'controller-derived submit has one actor');
        System.assertEquals(vpId, actors[0], 'controller derived the live VP for >10%');
    }

    private static List<Id> firstStepActors(Id processInstanceId) {
        List<Id> actorIds = new List<Id>();
        for (ProcessInstanceWorkitem workitem : [
            SELECT ActorId FROM ProcessInstanceWorkitem
            WHERE ProcessInstanceId = :processInstanceId
            ORDER BY CreatedDate
        ]) {
            actorIds.add(workitem.ActorId);
        }
        return actorIds;
    }

    @isTest
    static void above5_routesToRooftopManager_andApproves() {
        List<ProcessDefinition> defs = [SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Opportunity_Discount_Approval'];
        System.assert(!defs.isEmpty() && defs[0].State == 'Active', 'Activate the approval process before this test runs.');

        Id managerId = managerUser().Id;
        Id opportunityId;

        System.runAs(repUser()) {
            Opportunity opp = makeOpportunity(7);
            insert opp;
            opportunityId = opp.Id;
            submitForApproval(opp.Id, managerUser().Id);
        }

        List<Id> actors = firstStepActors([SELECT Id FROM ProcessInstance
            WHERE TargetObjectId = :opportunityId AND Status = 'Pending' LIMIT 1].Id);
        System.assertEquals(1, actors.size(), 'one first-step actor');
        System.assertEquals(managerId, actors[0], 'rooftop manager is the first approver');

        Id processInstanceId = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opportunityId ORDER BY CreatedDate DESC LIMIT 1].Id;
        System.runAs(managerUser()) {
            approveStep(processInstanceId, managerId);
        }

        Opportunity finalOpp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opportunityId];
        System.assertEquals('Approved', finalOpp.Approval_Status__c, 'final action updates status');
    }

    @isTest
    static void above10_skipsManager_routesToVP_andApproves() {
        List<ProcessDefinition> defs = [SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Opportunity_Discount_Approval'];
        System.assert(!defs.isEmpty() && defs[0].State == 'Active', 'Activate the approval process before this test runs.');

        Id vpId = vpUser().Id;
        Id opportunityId;

        System.runAs(repUser()) {
            Opportunity opp = makeOpportunity(12);
            insert opp;
            opportunityId = opp.Id;
            submitForApproval(opp.Id, vpUser().Id);
        }

        Id processInstanceId = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opportunityId ORDER BY CreatedDate DESC LIMIT 1].Id;
        List<Id> actors = firstStepActors(processInstanceId);
        System.assertEquals(1, actors.size(), 'direct VP step has one actor');
        System.assertEquals(vpId, actors[0], 'above 10 percent goes straight to VP');

        System.runAs(vpUser()) {
            approveStep(processInstanceId, vpId);
        }

        Opportunity finalOpp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opportunityId];
        System.assertEquals('Approved', finalOpp.Approval_Status__c, 'VP approval completes');
    }

    @isTest
    static void rejection_captured_onOpportunity() {
        List<ProcessDefinition> defs = [SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Opportunity_Discount_Approval'];
        System.assert(!defs.isEmpty() && defs[0].State == 'Active', 'Activate the approval process before this test runs.');

        Id managerId = managerUser().Id;
        Id opportunityId;

        System.runAs(repUser()) {
            Opportunity opp = makeOpportunity(7);
            insert opp;
            opportunityId = opp.Id;
            submitForApproval(opp.Id, managerUser().Id);
        }

        Id processInstanceId = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opportunityId ORDER BY CreatedDate DESC LIMIT 1].Id;
        System.runAs(managerUser()) {
            rejectStep(processInstanceId, managerId);
        }

        Opportunity finalOpp = [SELECT Approval_Status__c FROM Opportunity WHERE Id = :opportunityId];
        System.assertEquals('Rejected', finalOpp.Approval_Status__c, 'rejection captured on the opportunity');
    }

    @isTest
    static void managerSubmit_above10_doesNotSelfApprove() {
        List<ProcessDefinition> defs = [SELECT State FROM ProcessDefinition WHERE DeveloperName = 'Opportunity_Discount_Approval'];
        System.assert(!defs.isEmpty() && defs[0].State == 'Active', 'Activate the approval process before this test runs.');

        Id managerId = managerUser().Id;
        Id vpId = vpUser().Id;
        Id opportunityId;

        System.runAs(managerUser()) {
            Opportunity opp = makeOpportunity(12);
            insert opp;
            opportunityId = opp.Id;
            submitForApproval(opp.Id, vpUser().Id);
        }

        Id processInstanceId = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opportunityId ORDER BY CreatedDate DESC LIMIT 1].Id;
        List<Id> actors = firstStepActors(processInstanceId);
        System.assertEquals(1, actors.size(), 'one step actor');
        System.assertEquals(vpId, actors[0], 'manager cannot self-approve above 10 percent');
        System.assertNotEquals(managerId, actors[0], 'manager is not the step approver');
    }
}