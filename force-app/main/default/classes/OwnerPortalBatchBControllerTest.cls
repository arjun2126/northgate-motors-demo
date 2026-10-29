@isTest
private class OwnerPortalBatchBControllerTest {
    private static List<User> customers() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id;
        UserRole role = new UserRole(Name = 'P8 Batch B test owner');
        insert role;
        String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        User owner = new User(ProfileId = UserInfo.getProfileId(), UserRoleId = role.Id,
            Username = 'p8b.owner.' + token + '@example.invalid', Email = 'p8b@example.invalid',
            Alias = 'p8bown', LastName = 'P8 B Owner', TimeZoneSidKey = 'America/Toronto',
            LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert owner;
        List<User> result = new List<User>();
        System.runAs(owner) {
            for (Integer i = 0; i < 2; i++) {
                Account account = new Account(Name = 'P8 B Test ' + i, OwnerId = owner.Id);
                insert account;
                Contact contact = new Contact(LastName = 'P8 B Contact ' + i, AccountId = account.Id);
                insert contact;
                result.add(new User(ProfileId = profileId, ContactId = contact.Id,
                    Username = 'p8b.' + i + '.' + token + '@example.invalid', Email = 'p8b@example.invalid',
                    CommunityNickname = 'p8b' + i + token, Alias = 'p8bcust', LastName = 'P8 B Customer',
                    TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'));
            }
            insert result;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet permission : [SELECT Id FROM PermissionSet WHERE Name IN ('PS_Owner_Portal_Foundation','PS_Owner_Portal_Batch_B')]) {
                for (User customer : result) assignments.add(new PermissionSetAssignment(AssigneeId = customer.Id, PermissionSetId = permission.Id));
            }
            insert assignments;
        }
        return result;
    }
    @isTest static void internalAndPublicEndpointsFailClosed() {
        try { OwnerPortalBatchBController.getDashboard(); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.getHistory(null); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.getCases(null); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.getLoyalty(null); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.getVehicles(); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.requestAppointment(null, null, null, null); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.createCase('Test', null); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.addComment(null, 'Test'); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        try { OwnerPortalBatchBController.getComments(null); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
    }
    @isTest static void contactScopeCannotBeSubstitutedAndEmptyIsSafe() {
        List<User> users = customers();
        System.runAs(users[0]) {
            System.assertEquals(true, FeatureManagement.checkPermission('Access_Northgate_Owner_Portal'));
            System.assertEquals(0, OwnerPortalBatchBController.casesFor(users[0].ContactId, null).rows.size());
            System.assertEquals(0, OwnerPortalBatchBController.history(users[0].ContactId, null).visits.size());
            System.assertEquals(0, OwnerPortalBatchBController.loyalty(users[0].ContactId, null).members.size());
            try { OwnerPortalBatchBController.casesFor(users[1].ContactId, null); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.history(users[1].ContactId, null); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.loyalty(users[1].ContactId, null); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.createOwnCase(users[1].ContactId, 'Forged Contact', null); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.comment(users[0].ContactId, null, 'Comment'); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.comments(users[0].ContactId, null); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.createOwnCase(users[0].ContactId, ' ', null); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.comment(users[0].ContactId, null, ' '); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.getCases(null); System.assert(false); } catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
        }
    }
    @isTest static void caseFilterSurvivesBroaderRecordVisibility() {
        List<User> users = customers();
        // A Case owned by an external user is Contact-bound by Salesforce to that owner.
        // Give B's Case to B so the foreign fixture remains foreign after platform processing.
        // No sharing or permission expansion is introduced to manufacture broader visibility.
        Case own = new Case(Subject = 'Own case', Status = 'New', Origin = 'Web', ContactId = users[0].ContactId, OwnerId = users[0].Id);
        Case foreign = new Case(Subject = 'Foreign case', Status = 'New', Origin = 'Web', ContactId = users[1].ContactId, OwnerId = users[1].Id);
        System.runAs(new User(Id = UserInfo.getUserId())) { insert new List<Case>{own, foreign}; }
        Set<Id> persistedIds = new Set<Id>{own.Id, foreign.Id};
        List<Case> persisted = [SELECT Id, Subject, ContactId, AccountId, OwnerId FROM Case WHERE Id IN :persistedIds ORDER BY Id];
        Map<Id, Case> persistedById = new Map<Id, Case>(persisted);
        System.assertNotEquals(users[0].ContactId, users[1].ContactId);
        System.assertEquals(users[0].ContactId, persistedById.get(own.Id).ContactId, 'Own fixture must remain Contact-bound');
        System.assertEquals(users[1].ContactId, persistedById.get(foreign.Id).ContactId, 'Foreign fixture must remain foreign after platform automation');
        String diagnostic = 'A=' + users[0].ContactId + ' B=' + users[1].ContactId;
        for (Case row : persisted) diagnostic += ' [' + row.Subject + ':' + row.Id + ',Contact=' + row.ContactId + ',Owner=' + row.OwnerId + ']';
        System.runAs(users[0]) {
            OwnerPortalBatchBController.CasePage page = OwnerPortalBatchBController.casesFor(users[0].ContactId, null);
            diagnostic += ' returned=' + new Map<Id, Case>(page.rows).keySet();
            System.assertEquals(1, page.rows.size(), diagnostic);
            System.assertEquals(own.Id, page.rows[0].Id);
            System.assertEquals(false, page.hasMore);
            System.assertEquals(0, OwnerPortalBatchBController.casesFor(users[0].ContactId, own.Id).rows.size());
            try { OwnerPortalBatchBController.comment(users[0].ContactId, foreign.Id, 'Forbidden'); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.comments(users[0].ContactId, foreign.Id); System.assert(false); } catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
        }
    }
    @isTest static void createdCaseIsContactBoundAndRoutedWithoutEdit() {
        List<User> users = customers();
        Id createdId;
        System.runAs(users[0]) {
            System.assertEquals(true, Schema.sObjectType.Case.isCreateable(), 'Reviewed permission set permits only Case create/read');
            System.assertEquals(false, Schema.sObjectType.Case.isUpdateable(), 'Profile repair must remove Case Edit');
            createdId = OwnerPortalBatchBController.createOwnCase(users[0].ContactId, '  Customer service question  ', 'Local test only');
            System.assertNotEquals(null, createdId);
        }
        Case persisted = [SELECT ContactId, AccountId, OwnerId, Subject, Origin, Status, RecordType.DeveloperName FROM Case WHERE Id = :createdId];
        Contact caller = [SELECT AccountId FROM Contact WHERE Id = :users[0].ContactId];
        System.assertEquals(users[0].ContactId, persisted.ContactId);
        System.assertNotEquals(users[1].ContactId, persisted.ContactId);
        System.assertEquals(caller.AccountId, persisted.AccountId);
        System.assertEquals('Customer service question', persisted.Subject);
        System.assertEquals('Web', persisted.Origin);
        System.assertEquals('New', persisted.Status);
        System.assertEquals('Service', persisted.RecordType.DeveloperName);
        System.assertEquals([SELECT Id FROM Group WHERE DeveloperName = 'Q_Service_Intake' AND Type = 'Queue'].Id, persisted.OwnerId);
    }
    @isTest static void explicitProfileDeniesAreEffective() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id;
        PermissionSet base = [SELECT Id, PermissionsApexRestServices, PermissionsRunFlow, PermissionsFieldServiceAccess,
                             PermissionsAllowUniversalSearch, PermissionsEnableNotifications
                             FROM PermissionSet WHERE ProfileId = :profileId];
        System.assertEquals(false, base.PermissionsApexRestServices);
        System.assertEquals(false, base.PermissionsRunFlow);
        System.assertEquals(false, base.PermissionsFieldServiceAccess);
        System.assertEquals(false, base.PermissionsAllowUniversalSearch);
        System.assertEquals(true, base.PermissionsEnableNotifications, 'License-mandatory Send Outbound Messages cannot be disabled');
        List<String> deniedSystemPermissions = new List<String>{
            'AccessOrchestrationObjects', 'ActivitiesAccess', 'AddDirectMessageMembers', 'AllowUniversalSearch',
            'ApexRestServices', 'AssignTopics', 'ChatterOwnGroups', 'ContentWorkspaces', 'CreateTopics',
            'EditTask', 'EditTopics', 'EnableCommunityAppLauncher', 'FieldServiceAccess', 'RemoveDirectMessageMembers',
            'RunFlow', 'RunGlobalOptimization', 'RunInDayOptimization', 'SelectFilesFromSalesforce',
            'SetAdvancedOptimizationFilters', 'ShareFilesWithNetworks', 'ShowCompanyNameAsUserBadge', 'UseWebLink', 'WorkDotComUserPerm'};
        List<String> permissionFields = new List<String>();
        for (String name : deniedSystemPermissions) permissionFields.add('Permissions' + name);
        Id baseId = base.Id;
        PermissionSet effectiveSystem = (PermissionSet) Database.query(
            'SELECT ' + String.join(permissionFields, ',') + ' FROM PermissionSet WHERE Id = :baseId');
        for (String field : permissionFields) System.assertEquals(false, effectiveSystem.get(field), 'Explicit system deny must be effective: ' + field);
        // ObjectPermissions also contains dormant industry-feature rows whose objects do not
        // exist in this org's schema (e.g. ActionPlan REST describe returns NOT_FOUND).
        // Validate every available object, not inaccessible license-template metadata.
        Set<String> availableObjects = Schema.getGlobalDescribe().keySet();
        List<ObjectPermissions> effectiveObjects = [SELECT SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit,
                                                   PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
                                                   FROM ObjectPermissions WHERE ParentId = :base.Id AND SobjectType IN :availableObjects];
        String unexpected = '';
        for (ObjectPermissions permission : effectiveObjects) {
            if (!new Set<String>{'Account', 'Contact'}.contains(permission.SobjectType) &&
                (permission.PermissionsRead || permission.PermissionsCreate || permission.PermissionsEdit || permission.PermissionsDelete)) {
                unexpected += permission.SobjectType + ':' + (permission.PermissionsRead ? 'R' : '') +
                              (permission.PermissionsCreate ? 'C' : '') + (permission.PermissionsEdit ? 'E' : '') +
                              (permission.PermissionsDelete ? 'D' : '') + ',';
            }
        }
        for (ObjectPermissions permission : effectiveObjects) {
            System.assertEquals(new Set<String>{'Account', 'Contact'}.contains(permission.SobjectType), permission.PermissionsRead,
                                'Only Account/Contact Read is allowed on the base profile; unexpected=' + unexpected);
            System.assertEquals(false, permission.PermissionsCreate);
            System.assertEquals(false, permission.PermissionsEdit);
            System.assertEquals(false, permission.PermissionsDelete);
            System.assertEquals(false, permission.PermissionsViewAllRecords);
            System.assertEquals(false, permission.PermissionsModifyAllRecords);
        }
    }
    @isTest static void historyAndDashboardExcludeReadableForeignVisits() {
        List<User> users = customers();
        Service_Visit__c ownPast;
        Service_Visit__c ownFuture;
        Service_Visit__c foreign;
        Case foreignCase;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Vehicle_Model__c model = new Vehicle_Model__c(Name = 'P8 isolated history model'); insert model;
            Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = '80000000000000001'); insert vehicle;
            Rooftop__c rooftop = new Rooftop__c(Name = 'P8 isolated capacity', Service_Capacity__c = 10); insert rooftop;
            foreignCase = new Case(Subject = 'Foreign linked case', Status = 'New', Origin = 'Web', ContactId = users[1].ContactId, OwnerId = users[1].Id); insert foreignCase;
            ownPast = new Service_Visit__c(Contact__c = users[0].ContactId, Vehicle__c = vehicle.Id,
                Scheduled_Start__c = Datetime.now().addDays(-2), Status__c = 'Completed', Service_Type__c = 'Inspection',
                Mileage_At_Checkin__c = 12000, Case__c = foreignCase.Id, OwnerId = users[0].Id);
            ownFuture = new Service_Visit__c(Contact__c = users[0].ContactId, Vehicle__c = vehicle.Id, Rooftop__c = rooftop.Id,
                Scheduled_Start__c = Datetime.now().addDays(3), Status__c = 'Scheduled', Service_Type__c = 'Inspection', OwnerId = users[0].Id);
            foreign = new Service_Visit__c(Contact__c = users[1].ContactId, Vehicle__c = vehicle.Id, Rooftop__c = rooftop.Id,
                Scheduled_Start__c = Datetime.now().addDays(1), Status__c = 'Scheduled', Service_Type__c = 'Inspection', OwnerId = users[0].Id);
            insert new List<Service_Visit__c>{ownPast, ownFuture, foreign};
        }
        System.runAs(users[0]) {
            System.assertEquals(1, [SELECT COUNT() FROM Service_Visit__c WHERE Id = :foreign.Id WITH USER_MODE], 'Adversarial fixture must be natively readable without a share');
            OwnerPortalBatchBController.HistoryPage page = OwnerPortalBatchBController.history(users[0].ContactId, null);
            System.assertEquals(new Set<Id>{ownPast.Id, ownFuture.Id}, new Map<Id, Service_Visit__c>(page.visits).keySet());
            Service_Visit__c pastResult = new Map<Id, Service_Visit__c>(page.visits).get(ownPast.Id);
            System.assertEquals(12000, pastResult.Mileage_At_Checkin__c);
            System.assertEquals(null, pastResult.Case__c, 'Foreign linked Case identity must not escape through an own visit');
            System.assertEquals(false, new Map<Id, Case>(page.cases).containsKey(foreignCase.Id), 'Linked Case list must exclude the foreign Case');
            System.assertEquals(1, OwnerPortalBatchBController.history(users[0].ContactId, ownFuture.Id).visits.size());
            OwnerPortalBatchBController.Dashboard summary = OwnerPortalBatchBController.dashboard(users[0].ContactId);
            System.assertEquals(ownFuture.Id, summary.nextAppointment[0].Id, 'Earlier readable foreign appointment must not win');
            System.assertEquals(null, summary.appointmentError);
            System.assertEquals(null, summary.caseError);
            System.assertEquals(0, summary.membership.size());
            System.assert(summary.vehicleMessage.contains('ownership'));
            System.assertEquals(false, Schema.sObjectType.Service_Visit__c.isCreateable(), 'No appointment writes while ownership is unconfigured');
        }
    }
    @isTest static void loyaltyPagesPreserveStoredBalancesAndContactIsolation() {
        List<User> users = customers();
        Loyalty_Member__c own;
        Loyalty_Member__c foreign;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            own = new Loyalty_Member__c(Contact__c = users[0].ContactId, OwnerId = users[0].Id,
                Member_Number__c = 'P8C000000001', Tier__c = 'Silver', Status__c = 'Active', Points_Balance__c = 150);
            foreign = new Loyalty_Member__c(Contact__c = users[1].ContactId, OwnerId = users[0].Id,
                Member_Number__c = 'P8C000000002', Tier__c = 'Gold', Status__c = 'Active', Points_Balance__c = 900);
            insert new List<Loyalty_Member__c>{own, foreign};
            List<Loyalty_Transaction__c> entries = new List<Loyalty_Transaction__c>();
            for (Integer i = 0; i < 22; i++) entries.add(new Loyalty_Transaction__c(Loyalty_Member__c = own.Id,
                Type__c = 'Bonus', Reason__c = 'Promotion', Points__c = 5, Transaction_Date__c = Date.today().addDays(-i)));
            entries.add(new Loyalty_Transaction__c(Loyalty_Member__c = foreign.Id,
                Type__c = 'Bonus', Reason__c = 'Promotion', Points__c = 900, Transaction_Date__c = Date.today()));
            insert entries;
        }
        System.runAs(users[0]) {
            System.assertEquals(1, [SELECT COUNT() FROM Loyalty_Member__c WHERE Id = :foreign.Id WITH USER_MODE]);
            OwnerPortalBatchBController.LoyaltyPage first = OwnerPortalBatchBController.loyalty(users[0].ContactId, null);
            System.assertEquals(1, first.members.size()); System.assertEquals(own.Id, first.members[0].Id);
            System.assertEquals(150, first.members[0].Points_Balance__c, 'Do not recompute balance from ledger');
            System.assertEquals(20, first.transactions.size()); System.assertEquals(true, first.hasMore);
            for (Loyalty_Transaction__c row : first.transactions) System.assertEquals(5, row.Points__c, 'Foreign ledger must not appear');
            OwnerPortalBatchBController.LoyaltyPage second = OwnerPortalBatchBController.loyalty(users[0].ContactId, first.transactions[19].Id);
            System.assertEquals(2, second.transactions.size()); System.assertEquals(false, second.hasMore);
            System.assertEquals(false, Schema.sObjectType.Loyalty_Member__c.isUpdateable());
            System.assertEquals(false, Schema.sObjectType.Loyalty_Transaction__c.isCreateable());
            System.assertEquals(150, OwnerPortalBatchBController.dashboard(users[0].ContactId).membership[0].Points_Balance__c);
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new Loyalty_Member__c(Contact__c = users[0].ContactId, OwnerId = users[0].Id,
                Member_Number__c = 'P8C000000003', Tier__c = 'Bronze', Status__c = 'Active', Points_Balance__c = 0);
        }
        System.runAs(users[0]) {
            try { OwnerPortalBatchBController.loyalty(users[0].ContactId, null); System.assert(false); }
            catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            OwnerPortalBatchBController.Dashboard summary = OwnerPortalBatchBController.dashboard(users[0].ContactId);
            System.assertNotEquals(null, summary.loyaltyError); System.assertEquals(null, summary.membership);
        }
    }
    @isTest static void commentsRequireOwnCaseAndHideInternalNotes() {
        List<User> users = customers();
        Case own = new Case(Subject = 'Own comments', Status = 'New', Origin = 'Web', ContactId = users[0].ContactId, OwnerId = users[0].Id);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert own;
            insert new List<CaseComment>{new CaseComment(ParentId = own.Id, CommentBody = 'Public response', IsPublished = true),
                new CaseComment(ParentId = own.Id, CommentBody = 'Private internal note', IsPublished = false)};
        }
        Id commentId;
        System.runAs(users[0]) {
            System.assertEquals(false, Schema.sObjectType.Case.isUpdateable());
            List<CaseComment> visible = OwnerPortalBatchBController.comments(users[0].ContactId, own.Id);
            System.assertEquals(1, visible.size()); System.assertEquals('Public response', visible[0].CommentBody);
            commentId = OwnerPortalBatchBController.comment(users[0].ContactId, own.Id, '  Customer reply  ');
            System.assertEquals(2, OwnerPortalBatchBController.comments(users[0].ContactId, own.Id).size());
        }
        CaseComment persisted = [SELECT ParentId, CommentBody, IsPublished FROM CaseComment WHERE Id = :commentId];
        System.assertEquals(own.Id, persisted.ParentId); System.assertEquals('Customer reply', persisted.CommentBody); System.assertEquals(true, persisted.IsPublished);
        System.runAs(users[1]) {
            try { OwnerPortalBatchBController.comments(users[1].ContactId, own.Id); System.assert(false); }
            catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
            try { OwnerPortalBatchBController.comment(users[1].ContactId, own.Id, 'Foreign reply'); System.assert(false); }
            catch (AuraHandledException expected) { System.assertEquals('This portal request is unavailable. Check access and try again.', expected.getMessage()); }
        }
    }
    @isTest static void backendEmailFlagsDoNotGrantTemplateOrAdminCrud() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id;
        PermissionSet base = [SELECT PermissionsEmailAdministration, PermissionsEmailTemplateManagement, PermissionsEmailSingle,
                             PermissionsViewSetup, PermissionsApiEnabled FROM PermissionSet WHERE ProfileId = :profileId];
        System.assertEquals(false, base.PermissionsEmailAdministration, 'Explicit candidate metadata must disable this backend flag');
        System.assertEquals(false, base.PermissionsEmailTemplateManagement, 'Explicit candidate metadata must disable this backend flag');
        System.assertEquals(false, base.PermissionsEmailSingle);
        System.assertEquals(false, base.PermissionsViewSetup);
        System.assertEquals(false, base.PermissionsApiEnabled);
        List<User> users = customers();
        System.runAs(users[0]) {
            System.assertEquals('PowerCustomerSuccess', UserInfo.getUserType());
            System.assertEquals(false, Schema.sObjectType.EmailTemplate.isCreateable(), 'Email template backend flag must not confer effective Create');
            System.assertEquals(false, Schema.sObjectType.EmailTemplate.isUpdateable(), 'Email template backend flag must not confer effective Edit');
            System.assertEquals(false, Schema.sObjectType.OrgWideEmailAddress.isCreateable(), 'Email admin backend flag must not confer org-wide email configuration');
            System.assertEquals(false, Schema.sObjectType.OrgWideEmailAddress.isUpdateable());
        }
    }
}
