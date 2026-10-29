@isTest
private class OwnerPortalVehicleBrokerTest {
    private static Integer sequence = 1;
    @TestSetup static void fixtureOwner() {
        UserRole role = new UserRole(Name = 'P8 broker fixture owner'); insert role;
        User owner = new User(ProfileId = UserInfo.getProfileId(), UserRoleId = role.Id,
            Username = 'p8broker.owner.' + EncodingUtil.convertToHex(Crypto.generateAesKey(128)) + '@example.invalid',
            Email = 'p8broker@example.invalid', Alias = 'p8broker', LastName = 'P8 Broker Fixture Owner',
            TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert owner;
        for (PermissionSet permission : [SELECT Id FROM PermissionSet WHERE Name IN ('PS_Demo_Admin_No_Bypass','PS_Owner_Portal_Entitlement_Reviewer')]) {
            insert new PermissionSetAssignment(AssigneeId = owner.Id, PermissionSetId = permission.Id);
        }
    }
    private static User owner() { return [SELECT Id FROM User WHERE Alias = 'p8broker' AND LastName = 'P8 Broker Fixture Owner' LIMIT 1]; }
    private class Fixture {
        User a; User b; User c; Vehicle_Model__c model;
        Vehicle__c own; Vehicle__c noConsent; Vehicle__c foreign; Vehicle__c otherAccount;
        Vehicle__c expired; Vehicle__c reserved;
        Id ownershipId; Rooftop__c roof; Rooftop__c inactive;
    }
    private static Vehicle__c vehicle(Fixture f) {
        Vehicle__c row = new Vehicle__c(Vehicle_Model__c = f.model.Id, VIN__c = String.valueOf(90000000000000000L + sequence++),
            Year__c = 2026, Colour__c = 'Blue'); insert row; return row;
    }
    private static Id entitlement(Id contactId, Id vehicleId, String kind, Datetime endAt) {
        Contact_Vehicle_Relationship__c row = new Contact_Vehicle_Relationship__c(Contact__c = contactId,
            Vehicle__c = vehicleId, Relationship_Type__c = kind, Status__c = 'Pending',
            Effective_From__c = Datetime.now().addDays(-2), Effective_To__c = endAt,
            Evidence_Type__c = 'Approved_Synthetic_Fixture', Evidence_Reference__c = 'TEST-ONLY-BROKER-EVIDENCE');
        insert row; OwnerPortalOwnershipService.verify(row.Id); return row.Id;
    }
    private static Fixture fixture() {
        Fixture f = new Fixture(); List<User> users = new List<User>();
        System.runAs(owner()) {
            Account household = new Account(Name = 'P8 Broker shared household');
            Account other = new Account(Name = 'P8 Broker other household'); insert new List<Account>{household, other};
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id;
            String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
            for (Integer i = 0; i < 3; i++) {
                Contact contact = new Contact(LastName = 'P8 Broker ' + i, AccountId = i == 2 ? other.Id : household.Id); insert contact;
                users.add(new User(ProfileId = profileId, ContactId = contact.Id, Username = 'p8broker.' + i + '.' + token + '@example.invalid',
                    CommunityNickname = 'p8br' + i + token, Alias = 'p8bcust', LastName = 'P8 Broker Customer ' + i,
                    Email = 'p8broker@example.invalid', TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA',
                    EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'));
            }
            insert users; f.a = users[0]; f.b = users[1]; f.c = users[2];
            f.model = new Vehicle_Model__c(Name = 'P8 approved illustrative model', Image_Path__c = '/resource/NG_VehicleImages/aurelia_ex.webp'); insert f.model;
            f.own = vehicle(f); f.noConsent = vehicle(f); f.foreign = vehicle(f);
            f.otherAccount = vehicle(f); f.expired = vehicle(f); f.reserved = vehicle(f);
            f.reserved.Reserved_By__c = f.a.ContactId; update f.reserved;
            f.ownershipId = entitlement(f.a.ContactId, f.own.Id, 'Ownership', null);
            entitlement(f.a.ContactId, f.own.Id, 'Service_Authorization', null);
            entitlement(f.a.ContactId, f.noConsent.Id, 'Ownership', null);
            entitlement(f.b.ContactId, f.foreign.Id, 'Ownership', null);
            entitlement(f.b.ContactId, f.foreign.Id, 'Service_Authorization', null);
            entitlement(f.c.ContactId, f.otherAccount.Id, 'Ownership', null);
            entitlement(f.a.ContactId, f.expired.Id, 'Ownership', Datetime.now().addHours(-1));
            f.roof = new Rooftop__c(Name = 'P8 approved service catalog', Type__c = 'Full_Service', Is_Active__c = true, Service_Capacity__c = 1);
            f.inactive = new Rooftop__c(Name = 'P8 inactive location', Type__c = 'Service_Center', Is_Active__c = false, Service_Capacity__c = 10);
            insert new List<Rooftop__c>{f.roof, f.inactive};
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet permission : [SELECT Id FROM PermissionSet WHERE Name IN ('PS_Owner_Portal_Foundation','PS_Owner_Portal_Batch_B')]) {
                for (User customer : users) assignments.add(new PermissionSetAssignment(AssigneeId = customer.Id, PermissionSetId = permission.Id));
            }
            insert assignments;
        }
        return f;
    }
    private static void cannotBook(Fixture f, Id vehicleId, Id roofId, Datetime start, String service, String key) {
        try { OwnerPortalVehicleBroker.bookFor(f.a.ContactId, vehicleId, roofId, start, service, key); System.assert(false, 'Unauthorized request accepted'); }
        catch (AuraHandledException expected) { System.assert(expected.getMessage().contains('unavailable')); }
    }

    @isTest static void ownedDtoPhotosAndNativeDenial() {
        Fixture f = fixture();
        Test.startTest();
        System.runAs(f.a) {
            System.assertEquals('PowerCustomerSuccess', UserInfo.getUserType());
            System.assertEquals(false, Schema.sObjectType.Vehicle__c.isAccessible());
            System.assertEquals(false, Schema.sObjectType.Contact_Vehicle_Relationship__c.isAccessible());
            System.assertEquals(false, Schema.sObjectType.Service_Visit__c.isCreateable());
            OwnerPortalVehicleBroker.VehiclePage page = OwnerPortalVehicleBroker.vehiclesFor(f.a.ContactId, null);
            System.assertEquals(2, page.rows.size());
            Map<Id, Boolean> permitted = new Map<Id, Boolean>();
            for (OwnerPortalVehicleBroker.VehicleDetail row : page.rows) {
                permitted.put(row.vehicleId, row.canRequestService);
                System.assertEquals('/resource/NG_VehicleImages/aurelia_ex.webp', row.photoUrl);
                System.assertEquals('Blue', row.colour);
            }
            System.assertEquals(true, permitted.get(f.own.Id)); System.assertEquals(false, permitted.get(f.noConsent.Id));
            String payload = JSON.serialize(page);
            System.assertEquals(false, payload.contains(String.valueOf(f.foreign.Id)));
            System.assertEquals(false, payload.contains('Invoice_Cost')); System.assertEquals(false, payload.contains('Reserved_By'));
            System.assertEquals(false, payload.contains('Evidence_Reference'));
            System.assertEquals(0, OwnerPortalVehicleBroker.vehiclesFor(f.a.ContactId, page.beforeId).rows.size());
            try { OwnerPortalVehicleBroker.vehiclesFor(f.b.ContactId, null); System.assert(false); }
            catch (AuraHandledException denied) { System.assert(denied.getMessage().contains('unavailable')); }
            try { OwnerPortalVehicleBroker.vehiclesFor(f.a.ContactId, f.a.ContactId); System.assert(false); }
            catch (AuraHandledException denied) { System.assertNotEquals(null, denied.getMessage()); }
            try { List<Vehicle__c> leak = [SELECT Id FROM Vehicle__c WHERE Id = :f.foreign.Id WITH USER_MODE]; System.assert(false); }
            catch (QueryException denied) { System.assertNotEquals(null, denied.getMessage()); }
            try {
                insert as user new Service_Visit__c(Contact__c = f.a.ContactId, Vehicle__c = f.own.Id,
                    Scheduled_Start__c = Datetime.now().addDays(3), Status__c = 'Requested'); System.assert(false);
            } catch (DmlException denied) { System.assertNotEquals(null, denied.getMessage()); }
              catch (TypeException denied) { System.assert(denied.getMessage().contains('not allowed')); }
        }
        System.runAs(f.b) {
            OwnerPortalVehicleBroker.VehiclePage page = OwnerPortalVehicleBroker.vehiclesFor(f.b.ContactId, null);
            System.assertEquals(1, page.rows.size()); System.assertEquals(f.foreign.Id, page.rows[0].vehicleId);
        }
        System.runAs(f.c) { System.assertEquals(f.otherAccount.Id, OwnerPortalVehicleBroker.vehiclesFor(f.c.ContactId, null).rows[0].vehicleId); }
        Test.stopTest();
    }

    @isTest static void bookingIsIdempotentAndReusesCapacityAndIntake() {
        Fixture f = fixture(); Datetime start = Datetime.now().addDays(3); Id receipt;
        Test.startTest();
        System.runAs(f.a) {
            OwnerPortalVehicleBroker.Options options = OwnerPortalVehicleBroker.optionsFor(f.a.ContactId, f.own.Id);
            System.assertEquals(1, options.rooftops.size()); System.assertEquals(String.valueOf(f.roof.Id), options.rooftops[0].value);
            System.assert(options.services.size() > 0);
            receipt = OwnerPortalVehicleBroker.bookFor(f.a.ContactId, f.own.Id, f.roof.Id, start, 'Inspection', 'broker-own-000001');
            System.assertEquals(Datetime.valueOfGmt(start.formatGmt('yyyy-MM-dd HH:mm:ss')),
                [SELECT Scheduled_Start__c FROM Service_Visit__c WHERE Id = :receipt WITH SYSTEM_MODE].Scheduled_Start__c);
            System.assertEquals(receipt, OwnerPortalVehicleBroker.bookFor(f.a.ContactId, f.own.Id, f.roof.Id, start, 'Inspection', 'broker-own-000001'));
            cannotBook(f, f.own.Id, f.roof.Id, start, 'Brakes', 'broker-own-000001');
            cannotBook(f, f.own.Id, f.roof.Id, start, 'Inspection', 'broker-other-0001');
        }
        System.runAs(owner()) {
            Service_Visit__c row = [SELECT Contact__c, Vehicle__c, Rooftop__c, Status__c, Case__c, Portal_Request_Key__c,
                Portal_Request_Fingerprint__c FROM Service_Visit__c WHERE Id = :receipt WITH SYSTEM_MODE];
            System.assertEquals(f.a.ContactId, row.Contact__c); System.assertEquals(f.own.Id, row.Vehicle__c);
            System.assertEquals('Requested', row.Status__c); System.assertEquals(64, row.Portal_Request_Key__c.length());
            Case intake = [SELECT ContactId, AccountId, OwnerId, RecordType.DeveloperName FROM Case WHERE Id = :row.Case__c WITH SYSTEM_MODE];
            System.assertEquals(f.a.ContactId, intake.ContactId); System.assertEquals('Service', intake.RecordType.DeveloperName);
            System.assertEquals([SELECT Id FROM Group WHERE DeveloperName = 'Q_Service_Intake' AND Type = 'Queue' WITH SYSTEM_MODE].Id, intake.OwnerId);
            entitlement(f.a.ContactId, f.noConsent.Id, 'Service_Authorization', null);
        }
        System.runAs(f.a) { cannotBook(f, f.noConsent.Id, f.roof.Id, start.addHours(1), 'Inspection', 'broker-capacity-01'); }
        System.assertEquals(1, [SELECT COUNT() FROM Service_Visit__c WHERE Contact__c = :f.a.ContactId WITH SYSTEM_MODE]);
        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE ContactId = :f.a.ContactId WITH SYSTEM_MODE], 'No orphan intake Case on capacity failure');
        Test.stopTest();
    }

    @isTest static void foreignMissingExpiredNoConsentAndMalformedRequestsAreDenied() {
        Fixture f = fixture(); Datetime future = Datetime.now().addDays(2);
        Test.startTest();
        System.runAs(f.a) {
            for (Id vehicleId : new List<Id>{f.foreign.Id, f.otherAccount.Id, f.expired.Id, f.reserved.Id, f.noConsent.Id}) {
                cannotBook(f, vehicleId, f.roof.Id, future, 'Inspection', 'broker-denial-0001');
            }
            cannotBook(f, f.a.ContactId, f.roof.Id, future, 'Inspection', 'broker-denial-0001');
            cannotBook(f, f.own.Id, f.inactive.Id, future, 'Inspection', 'broker-denial-0001');
            cannotBook(f, f.own.Id, f.own.Id, future, 'Inspection', 'broker-denial-0001');
            cannotBook(f, f.own.Id, f.roof.Id, Datetime.now().addMinutes(-1), 'Inspection', 'broker-denial-0001');
            cannotBook(f, f.own.Id, f.roof.Id, future, 'Tampered', 'broker-denial-0001');
            cannotBook(f, f.own.Id, f.roof.Id, future, 'Inspection', 'short');
            cannotBook(f, null, f.roof.Id, future, 'Inspection', 'broker-denial-0001');
            try { OwnerPortalVehicleBroker.optionsFor(f.a.ContactId, f.foreign.Id); System.assert(false); }
            catch (AuraHandledException expected) { System.assertNotEquals(null, expected.getMessage()); }
        }
        System.assertEquals(0, [SELECT COUNT() FROM Service_Visit__c WITH SYSTEM_MODE]);
        Test.stopTest();
    }

    @isTest static void revocationAndUnsafePhotoFailClosedWithoutMaintenance() {
        Fixture f = fixture();
        Test.startTest();
        System.runAs(owner()) {
            f.model.Image_Path__c = 'https://untrusted.example/image.webp'; update f.model;
        }
        System.runAs(f.a) {
            for (OwnerPortalVehicleBroker.VehicleDetail row : OwnerPortalVehicleBroker.vehiclesFor(f.a.ContactId, null).rows) System.assertEquals(null, row.photoUrl);
        }
        System.runAs(owner()) { OwnerPortalOwnershipService.revoke(f.ownershipId, 'Approved test transfer/revocation'); }
        System.runAs(f.a) {
            OwnerPortalVehicleBroker.VehiclePage page = OwnerPortalVehicleBroker.vehiclesFor(f.a.ContactId, null);
            System.assertEquals(1, page.rows.size()); System.assertEquals(f.noConsent.Id, page.rows[0].vehicleId);
            cannotBook(f, f.own.Id, f.roof.Id, Datetime.now().addDays(3), 'Inspection', 'broker-revoked-01');
        }
        System.runAs(owner()) { insert as system new Automation_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Bypass_Triggers__c = true); }
        System.runAs(f.b) {
            try { OwnerPortalVehicleBroker.bookFor(f.b.ContactId, f.foreign.Id, f.roof.Id, Datetime.now().addDays(3), 'Inspection', 'broker-bypass-001'); System.assert(false); }
            catch (AuraHandledException denied) { System.assertNotEquals(null, denied.getMessage()); }
        }
        Test.stopTest();
    }

    @isTest static void conflictingAndTimeBoundPoliciesDenyWithoutARecordEdit() {
        Fixture f = fixture(); Datetime instant = Datetime.now();
        Contact_Vehicle_Relationship__c own = [SELECT Id, Vehicle__c, Contact__c, Relationship_Type__c, Status__c,
            Verified_By__c, Verified_At__c, Evidence_Type__c, Evidence_Reference__c, Effective_From__c, Effective_To__c,
            Revoked_At__c FROM Contact_Vehicle_Relationship__c WHERE Id = :f.ownershipId WITH SYSTEM_MODE];
        System.assertEquals(true, OwnerPortalVehicleBroker.verified(own, instant));
        own.Effective_To__c = instant.addHours(1);
        System.assertEquals(false, OwnerPortalVehicleBroker.verified(own, own.Effective_To__c));
        Contact_Vehicle_Relationship__c foreign = own.clone(false, true, false, false); foreign.Contact__c = f.b.ContactId;
        System.assertEquals(0, OwnerPortalVehicleBroker.eligibility(f.a.ContactId, new List<Contact_Vehicle_Relationship__c>{own, foreign}, instant).size());
        own.Revoked_At__c = instant; System.assertEquals(false, OwnerPortalVehicleBroker.verified(own, instant));
        own.Revoked_At__c = null; own.Effective_From__c = instant.addSeconds(1); System.assertEquals(false, OwnerPortalVehicleBroker.verified(own, instant));
        own.Effective_From__c = instant.addDays(-1); own.Evidence_Reference__c = ' '; System.assertEquals(false, OwnerPortalVehicleBroker.verified(own, instant));
        System.assertEquals(0, OwnerPortalVehicleBroker.eligibility(f.a.ContactId, new List<Contact_Vehicle_Relationship__c>{own}, instant).size());
        System.assertEquals(0, OwnerPortalVehicleBroker.eligibility(f.a.ContactId, new List<Contact_Vehicle_Relationship__c>(), instant).size());
    }

    @isTest static void publicFacadeNeverBypassesLiveSiteOrIdentityGate() {
        try { OwnerPortalBatchBController.getVehiclePage(null); System.assert(false); } catch (AuraHandledException expected) { System.assertNotEquals(null, expected.getMessage()); }
        try { OwnerPortalBatchBController.getAppointmentOptions(null); System.assert(false); } catch (AuraHandledException expected) { System.assertNotEquals(null, expected.getMessage()); }
        try { OwnerPortalBatchBController.bookAppointment(null, null, null, null, null); System.assert(false); } catch (AuraHandledException expected) { System.assertNotEquals(null, expected.getMessage()); }
        Fixture f = fixture();
        System.runAs(f.a) {
            try { OwnerPortalVehicleBroker.vehicles(null); System.assert(false); } catch (AuraHandledException expected) { System.assertNotEquals(null, expected.getMessage()); }
            try { OwnerPortalVehicleBroker.options(f.own.Id); System.assert(false); } catch (AuraHandledException expected) { System.assertNotEquals(null, expected.getMessage()); }
            try { OwnerPortalVehicleBroker.book(f.own.Id, f.roof.Id, Datetime.now().addDays(2), 'Inspection', 'broker-network-01'); System.assert(false); } catch (AuraHandledException expected) { System.assertNotEquals(null, expected.getMessage()); }
        }
    }
}
