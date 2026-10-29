@isTest
private class ServiceVisitCapacityGuardTest {
    private static Integer vehicleNumber = 1;
    private static Rooftop__c rooftop(Decimal capacity) {
        Rooftop__c row = new Rooftop__c(Name = 'Capacity Test Rooftop', Service_Capacity__c = capacity);
        insert row;
        return row;
    }

    private static Service_Visit__c visit(Id rooftopId, Datetime start, String status) {
        Account account = new Account(Name = 'Capacity Test Account');
        insert account;
        Contact contact = new Contact(LastName = 'Capacity Test Contact', AccountId = account.Id);
        insert contact;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Capacity Test Model');
        insert model;
        Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id,
            VIN__c = String.valueOf(10000000000000000L + vehicleNumber++));
        insert vehicle;
        return new Service_Visit__c(
            Rooftop__c = rooftopId, Contact__c = contact.Id, Vehicle__c = vehicle.Id,
            Scheduled_Start__c = start, Status__c = status, Service_Type__c = 'Inspection'
        );
    }

    @isTest
    static void competingNewVisitsAreBothRejectedWithoutCreatingCases() {
        Rooftop__c row = rooftop(1);
        Datetime start = Datetime.now().addDays(2);
        Service_Visit__c first = visit(row.Id, start, 'Requested');
        Service_Visit__c second = visit(row.Id, start, 'Requested');

        Database.SaveResult[] results = Database.insert(new List<Service_Visit__c>{first, second}, false);

        System.assert(!results[0].isSuccess());
        System.assert(!results[1].isSuccess());
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Subject = 'Service visit intake']);
    }

    @isTest
    static void terminalVisitReleasesCapacityAndNeutralUpdateDoesNotRecheck() {
        Rooftop__c row = rooftop(1);
        Service_Visit__c first = visit(row.Id, Datetime.now().addDays(2), 'Requested');
        insert first;
        first.Status__c = 'Completed';
        update first;

        Service_Visit__c replacement = visit(row.Id, first.Scheduled_Start__c, 'Requested');
        insert replacement;
        replacement.Work_Performed__c = 'Completed service';
        update replacement;
        System.assertEquals(1, [SELECT COUNT() FROM Service_Visit__c WHERE Rooftop__c = :row.Id AND Status__c = 'Requested']);
    }

    @isTest
    static void torontoDayRemainsStableAcrossDstAndBulkInsert() {
        System.assertEquals(Date.newInstance(2026, 11, 1),
            ServiceVisitCapacityGuard.localDay(Datetime.newInstanceGmt(2026, 11, 1, 4, 0, 0)));
        Rooftop__c row = rooftop(200);
        Account account = new Account(Name = 'Bulk Capacity Test Account');
        insert account;
        Contact contact = new Contact(LastName = 'Bulk Capacity Test Contact', AccountId = account.Id);
        insert contact;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Bulk Capacity Test Model');
        insert model;
        Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = 'CPTYBULK000000001');
        insert vehicle;
        List<Service_Visit__c> visits = new List<Service_Visit__c>();
        for (Integer index = 0; index < 200; index++) {
            visits.add(new Service_Visit__c(
                Rooftop__c = row.Id, Contact__c = contact.Id, Vehicle__c = vehicle.Id,
                Scheduled_Start__c = futureStart().addMinutes(index),
                Status__c = 'Requested', Service_Type__c = 'Inspection'
            ));
        }
        insert visits;
        System.assertEquals(200, [SELECT COUNT() FROM Service_Visit__c WHERE Rooftop__c = :row.Id]);
    }

    private static Datetime futureStart() {
        return ServiceVisitCapacityGuard.localMidnight(Date.today().addDays(3)).addHours(12);
    }

    private static List<Service_Visit__c> fixture(Id rooftopId, List<String> statuses) {
        Service_Visit__c template = visit(rooftopId, futureStart(), 'Completed');
        List<Service_Visit__c> rows = new List<Service_Visit__c>();
        for (String status : statuses) {
            Service_Visit__c row = template.clone(false, true, false, false);
            row.Status__c = status;
            rows.add(row);
        }
        insert rows;
        return rows;
    }

    private static void assertSwap(Boolean reservationFirst) {
        Rooftop__c roof = rooftop(1);
        List<Service_Visit__c> rows = fixture(roof.Id, new List<String>{'Requested', 'Cancelled'});
        rows[0].Status__c = 'Cancelled';
        rows[1].Status__c = 'Requested';
        List<Service_Visit__c> updates = reservationFirst
            ? new List<Service_Visit__c>{rows[1], rows[0]} : rows;
        Database.SaveResult[] results = Database.update(updates, false);
        System.assert(results[0].isSuccess(), JSON.serialize(results[0].getErrors()));
        System.assert(results[1].isSuccess(), JSON.serialize(results[1].getErrors()));
        Map<Id, Service_Visit__c> stored = new Map<Id, Service_Visit__c>([
            SELECT Status__c FROM Service_Visit__c WHERE Rooftop__c = :roof.Id
        ]);
        System.assertEquals('Cancelled', stored.get(rows[0].Id).Status__c);
        System.assertEquals('Requested', stored.get(rows[1].Id).Status__c);
    }

    @isTest static void cancellationReopeningSwapReleaseFirst() {
        assertSwap(false);
    }

    @isTest static void cancellationReopeningSwapReservationFirst() {
        assertSwap(true);
    }

    private static void assertMoves(Boolean reverseOrder) {
        Rooftop__c firstRoof = rooftop(1);
        Rooftop__c secondRoof = rooftop(1);
        List<Service_Visit__c> rows = fixture(firstRoof.Id, new List<String>{'Requested', 'Cancelled', 'Cancelled'});
        rows[1].Rooftop__c = secondRoof.Id;
        rows[1].Status__c = 'Requested';
        rows[2].Scheduled_Start__c = futureStart().addDays(1);
        rows[2].Status__c = 'Requested';
        update new List<Service_Visit__c>{rows[1], rows[2]};

        // Three full buckets rotate reservations across Rooftops and calendar days.
        rows[0].Rooftop__c = secondRoof.Id;
        rows[1].Rooftop__c = firstRoof.Id;
        rows[1].Scheduled_Start__c = futureStart().addDays(1);
        rows[2].Scheduled_Start__c = futureStart();
        List<Service_Visit__c> updates = reverseOrder
            ? new List<Service_Visit__c>{rows[2], rows[1], rows[0]} : rows;
        Database.SaveResult[] results = Database.update(updates, false);
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), JSON.serialize(result.getErrors()));
        }
        Set<Id> ids = new Map<Id, Service_Visit__c>(rows).keySet();
        Map<Id, Service_Visit__c> stored = new Map<Id, Service_Visit__c>([
            SELECT Rooftop__c, Scheduled_Start__c FROM Service_Visit__c WHERE Id IN :ids
        ]);
        for (Service_Visit__c row : rows) {
            System.assertEquals(row.Rooftop__c, stored.get(row.Id).Rooftop__c);
            System.assertEquals(row.Scheduled_Start__c, stored.get(row.Id).Scheduled_Start__c);
        }
    }

    @isTest static void rooftopAndDayMovesForwardOrder() {
        assertMoves(false);
    }

    @isTest static void rooftopAndDayMovesReverseOrder() {
        assertMoves(true);
    }

    @isTest static void simultaneousLifecycleReleasesAndReopeningsReachExactCapacity() {
        Rooftop__c roof = rooftop(3);
        List<Service_Visit__c> rows = fixture(roof.Id, new List<String>{
            'Requested', 'Checked_In', 'In_Progress', 'Completed', 'No_Show', 'Cancelled'
        });
        rows[0].Status__c = 'Completed';
        rows[1].Status__c = 'No_Show';
        rows[2].Status__c = 'Cancelled';
        rows[3].Status__c = 'Scheduled';
        rows[4].Status__c = 'Checked_In';
        rows[5].Status__c = 'In_Progress';
        update new List<Service_Visit__c>{rows[5], rows[4], rows[3], rows[2], rows[1], rows[0]};
        System.assertEquals(3, [SELECT COUNT() FROM Service_Visit__c
            WHERE Rooftop__c = :roof.Id AND Status__c IN ('Scheduled', 'Checked_In', 'In_Progress')]);
    }

    private static void assertRejectedMove(Boolean reverseOrder) {
        Rooftop__c firstRoof = rooftop(1);
        Rooftop__c secondRoof = rooftop(1);
        List<Service_Visit__c> rows = fixture(firstRoof.Id, new List<String>{'Requested', 'Cancelled', 'Completed'});
        Service_Visit__c blocker = visit(secondRoof.Id, futureStart(), 'Requested');
        insert blocker;
        rows[0].Rooftop__c = secondRoof.Id;
        rows[1].Status__c = 'Requested';
        rows[2].Work_Performed__c = 'Neutral update survives';
        List<Service_Visit__c> updates = reverseOrder
            ? new List<Service_Visit__c>{rows[1], rows[0], rows[2]} : rows;
        Database.SaveResult[] results = Database.update(updates, false);
        System.assert(!results[0].isSuccess());
        System.assert(!results[1].isSuccess(), 'Rejected move must not free its old reservation.');
        System.assert(results[2].isSuccess());
        System.assertEquals(firstRoof.Id, [SELECT Rooftop__c FROM Service_Visit__c WHERE Id = :rows[0].Id].Rooftop__c);
        System.assertEquals('Cancelled', [SELECT Status__c FROM Service_Visit__c WHERE Id = :rows[1].Id].Status__c);
    }

    @isTest static void rejectedMoveRetainsOldReservationForwardOrder() {
        assertRejectedMove(false);
    }

    @isTest static void rejectedMoveRetainsOldReservationReverseOrder() {
        assertRejectedMove(true);
    }

    private static void assertFailedRelease(Boolean reverseOrder) {
        System.assert(!FeatureManagement.checkPermission('Bypass_Automation'), 'Timing validation must run in this test.');
        System.assert(Schema.SObjectType.Service_Visit__c.isCreateable());
        System.assert(Schema.SObjectType.Service_Visit__c.isUpdateable());
        System.assert(Schema.SObjectType.Service_Visit__c.isAccessible());
        System.assert(Schema.SObjectType.Rooftop__c.isAccessible());
        System.assert(Schema.SObjectType.Service_Visit__c.fields.Rooftop__c.isUpdateable());
        System.assert(Schema.SObjectType.Service_Visit__c.fields.Status__c.isUpdateable());
        System.assert(Schema.SObjectType.Service_Visit__c.fields.Scheduled_Start__c.isUpdateable());
        System.assert(Schema.SObjectType.Rooftop__c.fields.Service_Capacity__c.isAccessible());
        Rooftop__c roof = rooftop(1);
        List<Service_Visit__c> rows = fixture(roof.Id, new List<String>{'Requested', 'Cancelled', 'Completed'});
        Datetime originalStart = rows[0].Scheduled_Start__c;
        // Before-trigger accounting permits the move, but the existing timing rule rejects it afterwards.
        rows[0].Status__c = 'Scheduled';
        rows[0].Scheduled_Start__c = Datetime.now().addDays(-2);
        rows[1].Status__c = 'Requested';
        rows[2].Work_Performed__c = 'Independent update survives retry';
        List<Service_Visit__c> updates = reverseOrder
            ? new List<Service_Visit__c>{rows[1], rows[0], rows[2]} : rows;
        Database.SaveResult[] results = Database.update(updates, false);
        Integer failedReleaseIndex = reverseOrder ? 1 : 0;
        Integer reservationIndex = reverseOrder ? 0 : 1;
        System.assert(!results[failedReleaseIndex].isSuccess());
        System.assert(results[failedReleaseIndex].getErrors()[0].getMessage().contains('Scheduled start must be in the future'));
        System.assert(!results[reservationIndex].isSuccess(), 'Retry must count the failed move in its original bucket.');
        System.assert(results[reservationIndex].getErrors()[0].getMessage().contains('Service capacity is unavailable'));
        System.assert(results[2].isSuccess());
        Service_Visit__c stored = [SELECT Status__c, Scheduled_Start__c FROM Service_Visit__c WHERE Id = :rows[0].Id];
        System.assertEquals('Requested', stored.Status__c);
        System.assertEquals(originalStart, stored.Scheduled_Start__c);
        System.assertEquals('Cancelled', [SELECT Status__c FROM Service_Visit__c WHERE Id = :rows[1].Id].Status__c);
        System.assertEquals('Independent update survives retry',
            [SELECT Work_Performed__c FROM Service_Visit__c WHERE Id = :rows[2].Id].Work_Performed__c);
    }

    private static User failedReleaseActor() {
        User actor = new User(
            Alias = 'capfail', LastName = 'Capacity Failed Release',
            Email = 'capacity.failed.release@northgate.example',
            Username = 'capacity.failed.release.' + UserInfo.getOrganizationId() + '@northgate.example',
            ProfileId = UserInfo.getProfileId(), TimeZoneSidKey = 'America/Toronto',
            LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8'
        );
        insert actor;
        insert new PermissionSetAssignment(AssigneeId = actor.Id,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Demo_Admin_No_Bypass' LIMIT 1].Id);
        return actor;
    }

    @isTest static void failedReleaseCannotAuthorizeReservationForwardOrder() {
        System.runAs(failedReleaseActor()) {
            assertFailedRelease(false);
        }
    }

    @isTest static void failedReleaseCannotAuthorizeReservationReverseOrder() {
        System.runAs(failedReleaseActor()) {
            assertFailedRelease(true);
        }
    }

    @isTest static void competingReopeningsRejectAllInEitherOrder() {
        Rooftop__c roof = rooftop(2);
        List<Service_Visit__c> rows = fixture(roof.Id, new List<String>{'Requested', 'Cancelled', 'No_Show'});
        rows[1].Status__c = 'Requested';
        rows[2].Status__c = 'Scheduled';
        for (Boolean reversed : new List<Boolean>{false, true}) {
            Database.SaveResult[] results = Database.update(reversed
                ? new List<Service_Visit__c>{rows[2], rows[1]} : new List<Service_Visit__c>{rows[1], rows[2]}, false);
            System.assert(!results[0].isSuccess());
            System.assert(!results[1].isSuccess());
        }
        System.assertEquals(1, [SELECT COUNT() FROM Service_Visit__c WHERE Rooftop__c = :roof.Id AND Status__c = 'Requested']);
    }

    @isTest static void invalidDestinationRetainsSourceAndNeutralEditsIgnoreCapacityDrift() {
        Rooftop__c roof = rooftop(1);
        Rooftop__c invalidRoof = rooftop(0);
        List<Service_Visit__c> rows = fixture(roof.Id, new List<String>{'Requested', 'Cancelled'});
        rows[0].Rooftop__c = invalidRoof.Id;
        rows[1].Status__c = 'Requested';
        Database.SaveResult[] results = Database.update(rows, false);
        System.assert(!results[0].isSuccess());
        System.assert(!results[1].isSuccess());
        roof.Service_Capacity__c = 0;
        update roof;
        Service_Visit__c neutral = [SELECT Id, Status__c, Case__c FROM Service_Visit__c WHERE Id = :rows[0].Id];
        neutral.Work_Performed__c = 'Feedback does not reserve capacity';
        update neutral;
        System.assertEquals('Requested', neutral.Status__c);
        System.assertNotEquals(null, neutral.Case__c);
    }

    @isTest
    static void runAsReadsConfiguredRooftopForScheduledReservation() {
        Rooftop__c row = rooftop(1);
        User actor = new User(
            Alias = 'caprun', LastName = 'Capacity RunAs',
            Email = 'capacity.runas@northgate.example',
            Username = 'capacity.runas.' + UserInfo.getOrganizationId() + '@northgate.example',
            ProfileId = UserInfo.getProfileId(), TimeZoneSidKey = 'America/Toronto',
            LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8'
        );
        insert actor;
        System.runAs(actor) {
            System.assertEquals(1,
                ServiceVisitCapacityGuard.loadRooftops(new Set<Id>{row.Id}).get(row.Id).Service_Capacity__c);
        }
    }
}
