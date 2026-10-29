@isTest
private class OwnerPortalOwnershipTest {
    @TestSetup static void reviewer() {
        UserRole role = new UserRole(Name = 'P8 ownership test owner'); insert role;
        User actor = new User(ProfileId = UserInfo.getProfileId(), UserRoleId = role.Id,
            Username = 'p8ledger.' + EncodingUtil.convertToHex(Crypto.generateAesKey(128)) + '@example.invalid',
            Email = 'p8ledger@example.invalid', Alias = 'p8rev', LastName = 'P8 Ownership Reviewer',
            TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert actor;
        insert new PermissionSetAssignment(AssigneeId = actor.Id,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Owner_Portal_Entitlement_Reviewer'].Id);
        // Fixture construction is inventory work, not an entitlement-reviewer capability.
        // Use the existing INTERNAL no-bypass permission set only for this rolled-back builder.
        User builder = actor.clone(false, true, false, false);
        builder.Username = 'p8builder.' + EncodingUtil.convertToHex(Crypto.generateAesKey(128)) + '@example.invalid';
        builder.Alias = 'p8build'; builder.LastName = 'P8 Ownership Fixture Builder';
        insert builder;
        insert new PermissionSetAssignment(AssigneeId = builder.Id,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Demo_Admin_No_Bypass'].Id);
    }
    private static User actor() { return [SELECT Id FROM User WHERE Alias = 'p8rev' AND LastName = 'P8 Ownership Reviewer' LIMIT 1]; }
    private static User builder() { return [SELECT Id FROM User WHERE Alias = 'p8build' AND LastName = 'P8 Ownership Fixture Builder' LIMIT 1]; }
    private static Id reservation(Fixture f) {
        Id result;
        System.runAs(builder()) {
            result = [SELECT Reserved_By__c FROM Vehicle__c WHERE Id = :f.vehicle.Id WITH USER_MODE].Reserved_By__c;
        }
        return result;
    }

    private class Fixture {
        Contact a; Contact b; Vehicle__c vehicle;
    }
    private static Fixture fixture() {
        Fixture result = new Fixture();
        Id reviewerId = UserInfo.getUserId();
        System.runAs(builder()) {
        System.assertEquals(true, Schema.sObjectType.Vehicle__c.fields.VIN__c.isCreateable(), 'Builder requires existing inventory FLS');
        System.assertEquals(true, Schema.sObjectType.Vehicle__c.fields.Reserved_By__c.isCreateable(), 'Builder requires existing reservation FLS');
        Account household = new Account(Name = 'P8 ledger isolated household', OwnerId = reviewerId); insert household;
        result.a = new Contact(LastName = 'P8 Ledger A', AccountId = household.Id);
        result.b = new Contact(LastName = 'P8 Ledger B', AccountId = household.Id);
        insert new List<Contact>{result.a, result.b};
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'P8 ledger isolated model'); insert model;
        result.vehicle = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = '80000000000000002', Reserved_By__c = result.b.Id);
        insert result.vehicle;
        }
        return result;
    }
    private static Contact_Vehicle_Relationship__c pending(Fixture f, Id contactId, String kind) {
        return new Contact_Vehicle_Relationship__c(Contact__c = contactId, Vehicle__c = f.vehicle.Id,
            Relationship_Type__c = kind, Status__c = 'Pending', Effective_From__c = Datetime.now().addDays(-1),
            Evidence_Type__c = 'Approved_Synthetic_Fixture', Evidence_Reference__c = 'TEST-ONLY-SIGNED-EVIDENCE');
    }
    private static Contact_Vehicle_Relationship__c verified(Fixture f, Id contactId, String kind) {
        Contact_Vehicle_Relationship__c row = pending(f, contactId, kind); insert row;
        OwnerPortalOwnershipService.verify(row.Id);
        return [SELECT Id, Contact__c, Vehicle__c, Relationship_Type__c, Status__c, Effective_From__c,
            Effective_To__c, Revoked_At__c, Verified_By__c, Verified_At__c FROM Contact_Vehicle_Relationship__c WHERE Id = :row.Id];
    }

    @isTest static void evidenceAndServerStampsAreRequired() {
        System.runAs(actor()) {
            Fixture f = fixture();
            Contact_Vehicle_Relationship__c row = pending(f, f.a.Id, 'Ownership');
            row.Status__c = 'Verified';
            System.assertEquals(false, Database.insert(row, false).isSuccess(), 'No approval on initial insert');
            row = pending(f, f.a.Id, 'Ownership'); row.Evidence_Reference__c = '   ';
            System.assertEquals(false, Database.insert(row, false).isSuccess());
            row = pending(f, f.a.Id, 'Ownership'); row.Effective_To__c = row.Effective_From__c;
            System.assertEquals(false, Database.insert(row, false).isSuccess());
            row = pending(f, f.a.Id, 'Ownership'); row.Evidence_Type__c = 'Reviewed_Service_Consent';
            System.assertEquals(false, Database.insert(row, false).isSuccess());
            row = pending(f, f.a.Id, 'Service_Authorization'); row.Evidence_Type__c = 'Reviewed_Purchase';
            System.assertEquals(false, Database.insert(row, false).isSuccess());
            row = verified(f, f.a.Id, 'Ownership');
            System.assertEquals(UserInfo.getUserId(), row.Verified_By__c);
            System.assertNotEquals(null, row.Verified_At__c);
            System.assertEquals(null, row.Revoked_At__c);
            row.Verified_By__c = null;
            System.assertEquals(false, Database.update(row, false).isSuccess());
            System.assertEquals(false, Database.delete(row, false).isSuccess(), 'History is never deleted');
        }
    }

    @isTest static void sameAccountAndReservationCannotSubstituteOwnership() {
        System.runAs(actor()) {
            Fixture f = fixture();
            Contact_Vehicle_Relationship__c own = verified(f, f.a.Id, 'Ownership');
            Contact_Vehicle_Relationship__c service = verified(f, f.a.Id, 'Service_Authorization');
            System.assertNotEquals(own.Id, service.Id, 'Service consent is independently reviewed');
            System.assertEquals(f.a.AccountId, f.b.AccountId);
            System.assertEquals(f.b.Id, reservation(f));
            Contact_Vehicle_Relationship__c foreign = pending(f, f.b.Id, 'Ownership'); insert foreign;
            foreign.Status__c = 'Verified';
            Database.SaveResult conflict = Database.update(foreign, false);
            System.assertEquals(false, conflict.isSuccess());
            System.assert(conflict.getErrors()[0].getMessage().contains('Conflicting'));
            own.Contact__c = f.b.Id;
            System.assertEquals(false, Database.update(own, false).isSuccess(), 'Verified owner cannot be substituted');
            service.Status__c = 'Pending';
            System.assertEquals(false, Database.update(service, false).isSuccess());
            System.assertEquals(1, [SELECT COUNT() FROM Contact_Vehicle_Relationship__c
                WHERE Vehicle__c = :f.vehicle.Id AND Relationship_Type__c = 'Ownership' AND Status__c = 'Verified']);
        }
    }

    @isTest static void intervalsAreHalfOpenAndRevocationClipsHistory() {
        User reviewer = actor();
        Datetime point = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
        Contact_Vehicle_Relationship__c a = new Contact_Vehicle_Relationship__c(Status__c = 'Verified',
            Effective_From__c = point, Effective_To__c = point.addDays(1), Verified_By__c = reviewer.Id, Verified_At__c = point);
        Contact_Vehicle_Relationship__c b = new Contact_Vehicle_Relationship__c(Status__c = 'Verified',
            Effective_From__c = point.addDays(1), Verified_By__c = reviewer.Id, Verified_At__c = point);
        System.assertEquals(false, OwnerPortalOwnershipGuard.overlaps(a, b));
        b.Effective_From__c = point.addHours(23);
        System.assertEquals(true, OwnerPortalOwnershipGuard.overlaps(a, b));
        a.Status__c = 'Revoked'; a.Revoked_At__c = point.addHours(12);
        System.assertEquals(false, OwnerPortalOwnershipGuard.overlaps(a, b));
        a.Effective_To__c = null;
        System.assertEquals(false, OwnerPortalOwnershipGuard.overlaps(a, b));
        a.Revoked_At__c = null;
        System.assertEquals(true, OwnerPortalOwnershipGuard.overlaps(a, b));
        b.Status__c = 'Pending';
        System.assertEquals(false, OwnerPortalOwnershipGuard.overlaps(a, b));
    }

    @isTest static void explicitRevocationRemovesOnlyApplicationSharesAndConsent() {
        User reviewer = actor();
        System.runAs(reviewer) {
            Fixture f = fixture();
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id;
            String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
            User customer = new User(ProfileId = profileId, ContactId = f.a.Id,
                Username = 'p8ledger.customer.' + token + '@example.invalid', Email = 'p8ledger@example.invalid',
                CommunityNickname = 'p8ledger' + token, Alias = 'p8lcust', LastName = 'P8 Ledger Customer',
                TimeZoneSidKey = 'America/Toronto', LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
            insert customer;
            Contact_Vehicle_Relationship__c own = verified(f, f.a.Id, 'Ownership');
            Contact_Vehicle_Relationship__c consent = verified(f, f.a.Id, 'Service_Authorization');
            insert new List<Vehicle__Share>{
                new Vehicle__Share(ParentId = f.vehicle.Id, UserOrGroupId = customer.Id, AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c'),
                new Vehicle__Share(ParentId = f.vehicle.Id, UserOrGroupId = customer.Id, AccessLevel = 'Read', RowCause = 'Manual')};
            insert new Contact_Vehicle_Relationship__Share(ParentId = own.Id, UserOrGroupId = customer.Id, AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c');
            Test.startTest();
            OwnerPortalOwnershipService.revoke(own.Id, 'Approved test ownership termination');
            Test.stopTest();
            System.assertEquals(0, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Portal_Entitlement__c']);
            System.assertEquals(1, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Manual']);
            System.assertEquals(0, [SELECT COUNT() FROM Contact_Vehicle_Relationship__Share WHERE ParentId = :own.Id AND RowCause = 'Portal_Entitlement__c']);
            Set<Id> endedIds = new Set<Id>{own.Id, consent.Id};
            Map<Id, Contact_Vehicle_Relationship__c> ended = new Map<Id, Contact_Vehicle_Relationship__c>([
                SELECT Id, Status__c, Revoked_At__c FROM Contact_Vehicle_Relationship__c WHERE Id IN :endedIds]);
            System.assertEquals('Revoked', ended.get(own.Id).Status__c);
            System.assertEquals('Revoked', ended.get(consent.Id).Status__c);
            System.assertNotEquals(null, ended.get(own.Id).Revoked_At__c);
            own.Status__c = 'Verified';
            System.assertEquals(false, Database.update(own, false).isSuccess(), 'Revoked evidence cannot be reactivated');
            System.assertEquals(f.b.Id, reservation(f), 'No reservation rewrite');
            System.runAs(customer) {
                System.assertEquals('PowerCustomerSuccess', UserInfo.getUserType());
                System.assertEquals(false, Schema.sObjectType.Vehicle__c.isAccessible(), 'No unapproved external Vehicle extension');
                try { OwnerPortalOwnershipService.revoke(consent.Id, 'Forged'); System.assert(false); }
                catch (SecurityException expected) { System.assert(expected.getMessage().contains('unavailable')); }
                Contact_Vehicle_Relationship__c forged = pending(f, f.b.Id, 'Ownership');
                System.assertEquals(false, Database.insert(forged, false).isSuccess(), 'Native DML under customer must be denied');
                try {
                    List<Contact_Vehicle_Relationship__c> leak = [SELECT Id FROM Contact_Vehicle_Relationship__c WITH USER_MODE];
                    System.assert(false, 'No customer ledger object grant');
                } catch (QueryException expected) { System.assertNotEquals(null, expected.getMessage()); }
            }
        }
    }

    @isTest static void terminationRequiresReasonAndNeverExtendsVerifiedInterval() {
        System.runAs(actor()) {
            Fixture f = fixture();
            Contact_Vehicle_Relationship__c row = verified(f, f.a.Id, 'Ownership');
            row.Effective_To__c = Datetime.now().addDays(2);
            System.assertEquals(false, Database.update(row, false).isSuccess());
            row.Revocation_Reason__c = 'Reviewed future termination'; update row;
            row.Effective_To__c = row.Effective_To__c.addDays(1);
            System.assertEquals(false, Database.update(row, false).isSuccess());
            row.Effective_To__c = Datetime.now().addSeconds(-1); update row;
            row.Status__c = 'Revoked'; row.Revocation_Reason__c = ' ';
            System.assertEquals(false, Database.update(row, false).isSuccess());
        }
    }

    @isTest static void bulkPendingDoesNotGrantOwnershipAndUnapprovedInternalCannotReview() {
        System.runAs(actor()) {
            Fixture f = fixture();
            List<Contact_Vehicle_Relationship__c> rows = new List<Contact_Vehicle_Relationship__c>();
            for (Integer i = 0; i < 200; i++) rows.add(pending(f, f.a.Id, 'Ownership'));
            Integer beforeQueries = Limits.getQueries(); insert rows;
            System.assert(Limits.getQueries() - beforeQueries <= 4, 'No per-row query');
            System.assertEquals(0, [SELECT COUNT() FROM Contact_Vehicle_Relationship__c WHERE Status__c = 'Verified']);
        }
        System.assertEquals(false, OwnerPortalOwnershipService.isReviewer());
        try { OwnerPortalOwnershipService.verify(null); System.assert(false); }
        catch (SecurityException expected) { System.assert(expected.getMessage().contains('unavailable')); }
    }

    @isTest static void reconcilerExpiresSharesWithoutEditingLedgerAndPreservesUnrelatedGrants() {
        System.runAs(actor()) {
            Fixture f = fixture();
            String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
            User customer = new User(ProfileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id,
                ContactId = f.a.Id, Username = 'p8expiry.' + token + '@example.invalid',
                Email = 'p8expiry@example.invalid', CommunityNickname = 'p8expiry' + token,
                Alias = 'p8expire', LastName = 'P8 Expiry Customer', TimeZoneSidKey = 'America/Toronto',
                LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
            insert customer;
            Contact_Vehicle_Relationship__c own = pending(f, f.a.Id, 'Ownership');
            own.Effective_To__c = Datetime.now().addHours(1); insert own;
            OwnerPortalOwnershipService.verify(own.Id);
            insert new List<Vehicle__Share>{
                new Vehicle__Share(ParentId = f.vehicle.Id, UserOrGroupId = customer.Id, AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c'),
                new Vehicle__Share(ParentId = f.vehicle.Id, UserOrGroupId = customer.Id, AccessLevel = 'Read', RowCause = 'Manual')};
            insert new Contact_Vehicle_Relationship__Share(ParentId = own.Id, UserOrGroupId = customer.Id,
                AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c');
            Set<Id> vehicleIds = new Set<Id>{f.vehicle.Id};
            OwnerPortalShareReconciler.reconcileNow(vehicleIds);
            System.assertEquals(1, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Portal_Entitlement__c']);
            // Advance only the maintenance evaluation clock; no ledger DML edits an expiry.
            OwnerPortalShareReconciler.prune(vehicleIds, own.Effective_To__c);
            System.assertEquals(0, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Portal_Entitlement__c']);
            System.assertEquals(0, [SELECT COUNT() FROM Contact_Vehicle_Relationship__Share WHERE ParentId = :own.Id AND RowCause = 'Portal_Entitlement__c']);
            System.assertEquals(1, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Manual']);
            System.assertEquals('Verified', [SELECT Status__c FROM Contact_Vehicle_Relationship__c WHERE Id = :own.Id].Status__c, 'Maintenance never rewrites evidence');
            OwnerPortalOwnershipService.revoke(own.Id, 'Approved stale-grant recovery test');
            // Deliberately inject a stale application grant in rolled-back test data only.
            insert new Vehicle__Share(ParentId = f.vehicle.Id, UserOrGroupId = customer.Id,
                AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c');
            Test.startTest();
            new OwnerPortalShareReconciler().execute((SchedulableContext) null);
            Test.stopTest();
            System.assertEquals(0, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Portal_Entitlement__c']);
            System.assertEquals(1, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Manual']);
            System.runAs(customer) {
                System.assertEquals(false, Schema.sObjectType.Vehicle__c.isAccessible(), 'Native access stays disabled pending architecture decision');
                try {
                    List<Vehicle__c> exposed = [SELECT Id FROM Vehicle__c WHERE Id = :f.vehicle.Id WITH USER_MODE];
                    System.assert(false, 'No native Vehicle permission may be inferred from a share');
                } catch (QueryException denied) { System.assertNotEquals(null, denied.getMessage()); }
            }
        }
    }

    @isTest static void missingOwnerAndServiceOnlyNeverRetainVehicleGrants() {
        System.runAs(actor()) {
            Fixture f = fixture();
            // A group is not the exact entitled Contact, regardless of any Account relationship.
            Group recipient = new Group(Name = 'P8 rolled-back stale share recipient'); insert recipient;
            Contact_Vehicle_Relationship__c consent = verified(f, f.b.Id, 'Service_Authorization');
            insert new Vehicle__Share(ParentId = f.vehicle.Id, UserOrGroupId = recipient.Id,
                AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c');
            insert new Contact_Vehicle_Relationship__Share(ParentId = consent.Id, UserOrGroupId = recipient.Id,
                AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c');
            OwnerPortalShareReconciler.reconcileNow(new Set<Id>{f.vehicle.Id});
            System.assertEquals(0, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :f.vehicle.Id AND RowCause = 'Portal_Entitlement__c']);
            System.assertEquals(0, [SELECT COUNT() FROM Contact_Vehicle_Relationship__Share WHERE ParentId = :consent.Id AND RowCause = 'Portal_Entitlement__c']);
        }
    }

    @isTest static void nativeForeignVehicleDeniedAndMisaddressedManagedShareRemoved() {
        System.runAs(actor()) {
            Fixture f = fixture();
            Vehicle__c foreign;
            System.runAs(builder()) {
                foreign = new Vehicle__c(Vehicle_Model__c = f.vehicle.Vehicle_Model__c, VIN__c = '80000000000000003');
                insert foreign;
            }
            Contact_Vehicle_Relationship__c bOwner = pending(f, f.b.Id, 'Ownership');
            bOwner.Vehicle__c = foreign.Id; insert bOwner;
            OwnerPortalOwnershipService.verify(bOwner.Id);
            String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
            User a = new User(ProfileId = [SELECT Id FROM Profile WHERE Name = 'NG_Owner_Portal_User'].Id,
                ContactId = f.a.Id, Username = 'p8foreign.' + token + '@example.invalid',
                Email = 'p8foreign@example.invalid', CommunityNickname = 'p8for' + token,
                Alias = 'p8forgn', LastName = 'P8 Foreign Vehicle Customer', TimeZoneSidKey = 'America/Toronto',
                LocaleSidKey = 'en_CA', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
            insert a;
            System.assertEquals(f.a.AccountId, f.b.AccountId, 'Same Account must not confer Vehicle entitlement');
            insert new Vehicle__Share(ParentId = foreign.Id, UserOrGroupId = a.Id,
                AccessLevel = 'Read', RowCause = 'Portal_Entitlement__c');
            System.runAs(a) {
                System.assertEquals('PowerCustomerSuccess', UserInfo.getUserType());
                try {
                    List<Vehicle__c> leak = [SELECT Id FROM Vehicle__c WHERE Id = :foreign.Id WITH USER_MODE];
                    System.assert(false, 'Foreign-ID native read denied even when a stale share exists');
                } catch (QueryException denied) { System.assertNotEquals(null, denied.getMessage()); }
            }
            OwnerPortalShareReconciler.reconcileNow(new Set<Id>{foreign.Id});
            System.assertEquals(0, [SELECT COUNT() FROM Vehicle__Share WHERE ParentId = :foreign.Id AND RowCause = 'Portal_Entitlement__c']);
        }
    }
}
