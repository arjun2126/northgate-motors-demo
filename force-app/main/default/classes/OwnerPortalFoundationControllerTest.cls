@isTest
private class OwnerPortalFoundationControllerTest {
    // Read-only platform fields are supplied as in-memory environmental observations only.
    // No Network DML or production context override is involved.
    private static Network siteFacts(String status) {
        return (Network) JSON.deserialize(JSON.serialize(new Map<String, Object>{
            'Name' => 'Northgate Owner Portal', 'UrlPathPrefix' => 'owners', 'Status' => status
        }), Network.class);
    }

    private static List<User> isolatedCustomers() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id;
        UserRole role = new UserRole(Name = 'P8 positive test owner');
        insert role;
        String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        User owner = new User(ProfileId = UserInfo.getProfileId(), UserRoleId = role.Id,
            Username = 'p8.positive.owner.' + token + '@example.invalid',
            Email = 'p8.owner@example.invalid', LastName = 'P8 Owner', Alias = 'p8own',
            TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert owner;
        List<User> customers = new List<User>();
        System.runAs(owner) {
            for (Integer i = 0; i < 2; i++) {
                Account account = new Account(Name = 'P8 isolated ' + i, OwnerId = owner.Id);
                insert account;
                Contact contact = new Contact(LastName = 'P8 Customer ' + i, AccountId = account.Id);
                insert contact;
                customers.add(new User(ProfileId = profileId, ContactId = contact.Id,
                    Username = 'p8.positive.' + i + '.' + token + '@example.invalid',
                    Email = 'p8.customer@example.invalid', LastName = 'P8 Customer ' + i,
                    Alias = 'p8cust', CommunityNickname = 'p8' + i + token,
                    TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA',
                    EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'));
            }
            insert customers;
        }
        return customers;
    }

    private static void assertSiteDenied(String networkId, List<Network> sites) {
        try {
            OwnerPortalFoundationController.contextForSite(networkId, sites);
            System.assert(false, 'Invalid site facts must deny access');
        } catch (AuraHandledException expected) {
            System.assertEquals('Portal access is unavailable for this identity or site.', expected.getMessage());
        }
    }

    @isTest static void permittedCustomersReadOnlyTheirOwnContactInUserMode() {
        List<User> customers = isolatedCustomers();
        Set<Id> contactIds = new Set<Id>{customers[0].ContactId, customers[1].ContactId};
        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]);
        Id permissionId = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Owner_Portal_Foundation'].Id;
        // Assignment exists only in this rolled-back test transaction, not in the org.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new List<PermissionSetAssignment>{
                new PermissionSetAssignment(AssigneeId = customers[0].Id, PermissionSetId = permissionId),
                new PermissionSetAssignment(AssigneeId = customers[1].Id, PermissionSetId = permissionId)};
        }
        List<Network> liveSite = new List<Network>{siteFacts('Live')};
        for (Integer i = 0; i < customers.size(); i++) {
            User customer = customers[i];
            Id foreignContact = customers[1 - i].ContactId;
            Id foreignAccount = contacts.get(foreignContact).AccountId;
            System.runAs(customer) {
                System.assertEquals('PowerCustomerSuccess', UserInfo.getUserType());
                System.assertEquals(true, FeatureManagement.checkPermission('Access_Northgate_Owner_Portal'));
                System.assertEquals(null, Network.getNetworkId());
                OwnerPortalFoundationController.CustomerContext result =
                    OwnerPortalFoundationController.contextForSite('0DB000000000001', liveSite);
                System.assertEquals(customer.ContactId, result.contactId, 'Context must resolve the actual caller, not the other customer');
                System.assertEquals(contacts.get(customer.ContactId).AccountId, result.accountId);
                System.assertNotEquals(foreignContact, result.contactId);
                System.assertNotEquals(foreignAccount, result.accountId);
                System.assertEquals(0, [SELECT Id FROM Contact WHERE Id = :foreignContact WITH USER_MODE].size(), 'Foreign Contact must not be visible');
                System.assertEquals(0, [SELECT Id FROM Account WHERE Id = :foreignAccount WITH USER_MODE].size(), 'Foreign Account must not be visible');
                System.assertEquals(false, Schema.sObjectType.Contact.isUpdateable(), 'Profile and permission set must remain read-only');
                try {
                    update as user new Contact(Id = customer.ContactId, LastName = 'Forbidden write');
                    System.assert(false, 'Read-only customer must not edit its own Contact');
                } catch (DmlException expected) {
                    System.assertEquals('INSUFFICIENT_ACCESS_OR_READONLY', expected.getDmlStatusCode(0));
                } catch (TypeException expected) {
                    System.assertEquals('DML operation UPDATE not allowed on Contact', expected.getMessage());
                }
                assertSiteDenied(null, liveSite);
                assertSiteDenied('0DB000000000001', new List<Network>());
                assertSiteDenied('0DB000000000001', new List<Network>{siteFacts('UnderConstruction')});
                try {
                    OwnerPortalFoundationController.getContext();
                    System.assert(false, 'Even a permission-bearing caller must fail in the real null Network context');
                } catch (AuraHandledException expected) {
                    System.assertEquals('Portal access is unavailable for this identity or site.', expected.getMessage());
                }
            }
        }
    }

    @isTest static void realPlusUserWithoutPermissionOrSiteFailsClosed() {
        Profile plusProfile = [SELECT Id, UserLicense.Name FROM Profile
                               WHERE Name = 'NG_Owner_Portal_User'
                               AND UserLicense.Name = 'Customer Community Plus'
                               AND UserType = 'PowerCustomerSuccess' LIMIT 1];
        System.assertEquals('Customer Community Plus', plusProfile.UserLicense.Name, 'Fixture profile must use the Plus license');
        UserRole ownerRole = new UserRole(Name = 'P8 isolated test owner');
        insert ownerRole;
        String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        User owner = new User(
            ProfileId = UserInfo.getProfileId(), UserRoleId = ownerRole.Id,
            Username = 'p8.owner.' + token + '@example.invalid',
            Email = 'p8.owner@example.invalid', LastName = 'P8 Test Owner', Alias = 'p8owner',
            TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert owner;
        User customer;
        // Test-only runAs boundary permits fixture setup/non-setup DML separation.
        // All rows roll back; no permission assignment, share or membership is inserted.
        System.runAs(owner) {
            Account account = new Account(Name = 'P8 isolated test customer', OwnerId = owner.Id);
            insert account;
            Contact contact = new Contact(LastName = 'P8 Test Customer', AccountId = account.Id);
            insert contact;
            customer = new User(
                ProfileId = plusProfile.Id, ContactId = contact.Id,
                Username = 'p8.customer.' + token + '@example.invalid',
                Email = 'p8.customer@example.invalid', LastName = 'P8 Test Customer',
                Alias = 'p8cust', CommunityNickname = 'p8' + token,
                TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
            insert customer;
        }
        System.runAs(customer) {
            User actor = [SELECT ContactId, IsActive
                          FROM User WHERE Id = :UserInfo.getUserId()];
            System.assertEquals('PowerCustomerSuccess', UserInfo.getUserType(), 'Use a real Plus identity');
            System.assertNotEquals(null, actor.ContactId, 'External fixture must be Contact-bound');
            System.assertEquals(true, actor.IsActive);
            System.assertEquals(false, FeatureManagement.checkPermission('Access_Northgate_Owner_Portal'), 'No portal permission was assigned');
            assertSiteDenied('0DB000000000001', new List<Network>{siteFacts('Live')});
            System.assertEquals(null, Network.getNetworkId(), 'runAs does not establish an Experience request context');
            // Isolate the network policy constraint without bypassing the actual endpoint.
            System.assertEquals(false, OwnerPortalFoundationController.eligible(
                UserInfo.getUserType(), plusProfile.UserLicense.Name,
                actor.IsActive, actor.ContactId, true, Network.getNetworkId()),
                'Even a permission-bearing identity must fail without a network');
            Integer queriesBefore = Limits.getQueries();
            try {
                OwnerPortalFoundationController.getContext();
                System.assert(false, 'A real external user without permission/site context must be denied');
            } catch (AuraHandledException expected) {
                System.assertEquals('Portal access is unavailable for this identity or site.', expected.getMessage());
            }
            System.assertEquals(queriesBefore, Limits.getQueries(), 'Permission denial must precede customer queries');
        }
    }

    @isTest static void identityPolicyRequiresEveryCustomerBoundary() {
        Id contactId = '003000000000001';
        String networkId = '0DB000000000001';
        System.assert(OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', true, contactId, true, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('Standard', 'Customer Community Plus', true, contactId, true, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('Guest', 'Customer Community Plus', true, contactId, true, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('PowerPartner', 'Partner Community', true, contactId, true, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'External Identity', true, contactId, true, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', false, contactId, true, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', true, null, true, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', true, contactId, false, networkId));
        System.assert(!OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', true, contactId, true, null));
        System.assert(!OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', true, contactId, true, ' '));
    }

    @isTest static void onlyExactLivePortalIsEligible() {
        System.assert(OwnerPortalFoundationController.allowedSite('Northgate Owner Portal', 'owners', 'Live'));
        System.assert(!OwnerPortalFoundationController.allowedSite('Another Portal', 'owners', 'Live'));
        System.assert(!OwnerPortalFoundationController.allowedSite('Northgate Owner Portal', 'another', 'Live'));
        System.assert(!OwnerPortalFoundationController.allowedSite('Northgate Owner Portal', 'owners', 'UnderConstruction'));
        System.assert(!OwnerPortalFoundationController.allowedSite('Northgate Owner Portal', 'owners', 'DownForMaintenance'));
    }

    @isTest static void missingIdentityFactsFailClosed() {
        Id contactId = '003000000000001';
        String networkId = '0DB000000000001';
        System.assertEquals(false, OwnerPortalFoundationController.eligible(null, 'Customer Community Plus', true, contactId, true, networkId), 'Missing user type must deny access');
        System.assertEquals(false, OwnerPortalFoundationController.eligible('PowerCustomerSuccess', null, true, contactId, true, networkId), 'Missing license must deny access');
        System.assertEquals(false, OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', null, contactId, true, networkId), 'Unknown active state must deny access');
        System.assertEquals(false, OwnerPortalFoundationController.eligible('PowerCustomerSuccess', 'Customer Community Plus', true, contactId, null, networkId), 'Unknown permission must deny access');
        System.assertEquals(false, OwnerPortalFoundationController.eligible('Guest', null, true, null, false, networkId), 'Guest without a Contact must remain denied at the correct site');
        System.assertEquals(false, OwnerPortalFoundationController.eligible(null, null, null, null, null, null), 'Missing identity context must deny access');
    }

    @isTest static void missingSiteFactsFailClosed() {
        System.assertEquals(false, OwnerPortalFoundationController.allowedSite(null, 'owners', 'Live'), 'Missing site name must deny access');
        System.assertEquals(false, OwnerPortalFoundationController.allowedSite('Northgate Owner Portal', null, 'Live'), 'Missing path must deny access');
        System.assertEquals(false, OwnerPortalFoundationController.allowedSite('Northgate Owner Portal', 'owners', null), 'Missing status must deny access');
        System.assertEquals(false, OwnerPortalFoundationController.allowedSite(null, null, null), 'Missing site context must deny access');
    }

    @isTest static void internalContextCannotUseCustomerEndpoint() {
        User current = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(current) {
            Integer queriesBefore = Limits.getQueries();
            try {
                OwnerPortalFoundationController.getContext();
                System.assert(false, 'Internal/admin context must not become a portal customer');
            } catch (AuraHandledException expected) {
                System.assertEquals('Portal access is unavailable for this identity or site.', expected.getMessage());
            }
            System.assertEquals(queriesBefore, Limits.getQueries(), 'Internal identity must be rejected before identity, site or customer queries');
        }
    }
}
