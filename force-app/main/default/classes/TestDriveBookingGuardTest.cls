@isTest
private class TestDriveBookingGuardTest {
    @TestSetup
    static void setupBooker() {
        User booker = new User(
            Alias = 'tdtime', LastName = 'SchedulingValidation',
            Email = 'scheduling.validation@northgate.example',
            Username = 'scheduling.validation.' + UserInfo.getOrganizationId() + '@northgate.example',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'NG_Sales' LIMIT 1].Id,
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York'
        );
        insert booker;
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permission : [
            SELECT Id FROM PermissionSet WHERE Name IN ('PS_Quote_Workflows', 'PS_Test_Drive_Booking')
        ]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = booker.Id, PermissionSetId = permission.Id));
        }
        System.assertEquals(2, assignments.size(), 'Use the actual booking permission sets.');
        insert assignments;
    }

    private class Fixture {
        Account account;
        Contact driver;
        Vehicle_Model__c model;
        Vehicle__c vehicle;
    }

    private static Fixture createFixture(String seed) {
        Fixture f = new Fixture();
        f.account = new Account(Name = 'P2 Drive ' + seed);
        insert f.account;
        f.driver = new Contact(LastName = 'Driver ' + seed, AccountId = f.account.Id);
        insert f.driver;
        f.model = new Vehicle_Model__c(Name = 'P2 Model ' + seed);
        insert f.model;
        f.vehicle = new Vehicle__c(VIN__c = 'TESTVNM000000' + seed, Vehicle_Model__c = f.model.Id);
        insert f.vehicle;
        return f;
    }

    private static Test_Drive__c driveFor(Fixture f, Datetime start, String status) {
        return new Test_Drive__c(
            Vehicle__c = f.vehicle.Id,
            Contact__c = f.driver.Id,
            Scheduled_Start__c = start,
            Duration_Minutes__c = 60,
            Status__c = status
        );
    }

    @isTest
    static void overlappingDriveIsBlocked() {
        Fixture f = createFixture('0001');
        Datetime start = Datetime.now().addDays(2);
        insert driveFor(f, start, 'Scheduled');

        Test.startTest();
        try {
            insert driveFor(f, start.addMinutes(30), 'Scheduled');
            System.assert(false, 'Overlapping test drive should be blocked.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('already booked'), e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void adjacentDriveIsAllowed() {
        Fixture f = createFixture('0002');
        Datetime start = Datetime.now().addDays(2);
        insert driveFor(f, start, 'Scheduled');

        Test.startTest();
        Test_Drive__c next = driveFor(f, start.addHours(1), 'Scheduled');
        insert next;
        Test.stopTest();

        System.assertNotEquals(null, next.Id);
    }

    @isTest
    static void cancelledDriveDoesNotBlock() {
        Fixture f = createFixture('0003');
        Datetime start = Datetime.now().addDays(2);
        insert driveFor(f, start, 'Cancelled');

        Test.startTest();
        Test_Drive__c next = driveFor(f, start.addMinutes(30), 'Scheduled');
        insert next;
        Test.stopTest();

        System.assertNotEquals(null, next.Id);
    }

    @isTest
    static void personaCannotCreatePastDrivesInAnyStatus() {
        Fixture f = createFixture('0004');
        User booker = [SELECT Id FROM User WHERE LastName = 'SchedulingValidation' LIMIT 1];
        List<Test_Drive__c> drives = new List<Test_Drive__c>();
        for (String status : new List<String>{'Requested', 'Scheduled', 'Completed', 'Cancelled', 'No_Show', 'Declined'}) {
            drives.add(driveFor(f, Datetime.now().addDays(-1), status));
        }
        System.runAs(booker) {
            System.assert(Schema.SObjectType.Test_Drive__c.isCreateable(), 'Use an authorized booking persona.');
            System.assert(!FeatureManagement.checkPermission('Bypass_Automation'), 'Persona has no bypass.');
            List<Database.SaveResult> results = Database.insert(drives, false);
            for (Database.SaveResult result : results) assertFutureError(result);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Test_Drive__c WHERE Vehicle__c = :f.vehicle.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id], 'Rejected inserts leave no Tasks.');
    }

    private static void assertFutureError(Database.SaveResult result) {
        System.assert(!result.isSuccess(), 'A past scheduling action must fail.');
        Boolean found = false;
        for (Database.Error error : result.getErrors()) {
            if (error.getMessage().contains('Choose a future start time')) {
                found = true;
                System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, error.getStatusCode());
                System.assert(error.getFields().contains('Scheduled_Start__c'), 'Show the error on the start field.');
            }
        }
        System.assert(found, 'Failure must come from scheduling enforcement, not unrelated validation.');
    }

    @isTest
    static void reschedulingRejectsPastAndPreservesFutureDuration() {
        Fixture f = createFixture('0005');
        Datetime original = Datetime.now().addDays(2);
        Test_Drive__c drive = driveFor(f, original, 'Scheduled');
        insert drive;
        drive.Scheduled_Start__c = Datetime.now().addDays(-1);
        assertFutureError(Database.update(drive, false));
        System.assertEquals(original, [SELECT Scheduled_Start__c FROM Test_Drive__c WHERE Id = :drive.Id].Scheduled_Start__c);
        drive.Scheduled_Start__c = original.addDays(1);
        update drive;
        Test_Drive__c saved = [SELECT Scheduled_End__c FROM Test_Drive__c WHERE Id = :drive.Id];
        System.assertEquals(drive.Scheduled_Start__c.addMinutes(60), saved.Scheduled_End__c);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id], 'Rescheduling adds no creation/completion Task.');
    }

    @isTest
    static void historicalEditsAndTerminalStatusChangesAreAllowed() {
        Fixture f = createFixture('0006');
        Test_Drive__c persisted = driveFor(f, Datetime.now().addDays(2), 'Scheduled');
        insert persisted;
        // Model a booking after its start has elapsed without inserting or rewriting historical data.
        Test_Drive__c previous = persisted.clone(true, false, false, false);
        previous.Scheduled_Start__c = Datetime.now().addDays(-2);
        Map<Id, Test_Drive__c> oldById = new Map<Id, Test_Drive__c>{previous.Id => previous};
        for (String status : new List<String>{'Scheduled', 'Completed', 'No_Show', 'Cancelled', 'Declined'}) {
            Test_Drive__c edited = previous.clone(true, false, false, false);
            edited.Status__c = status;
            edited.Feedback__c = 'Historical follow-up';
            edited.Duration_Minutes__c = 45;
            TestDriveBookingGuard.validateSchedule(new List<Test_Drive__c>{edited}, oldById);
            System.assert(!edited.hasErrors(), 'Allow unchanged historical start and legitimate lifecycle updates: ' + status);
        }
        System.assertEquals(persisted.Scheduled_Start__c,
            [SELECT Scheduled_Start__c FROM Test_Drive__c WHERE Id = :persisted.Id].Scheduled_Start__c,
            'Historical scenarios are in memory; stored booking remains untouched.');
    }

    @isTest
    static void historicalReopeningAndRequestedToScheduledNeedFutureStart() {
        Fixture f = createFixture('0007');
        Test_Drive__c persisted = driveFor(f, Datetime.now().addDays(2), 'Cancelled');
        insert persisted;
        for (String oldStatus : new List<String>{'Cancelled', 'Completed', 'No_Show', 'Declined', 'Requested'}) {
            Test_Drive__c previous = persisted.clone(true, false, false, false);
            previous.Scheduled_Start__c = Datetime.now().addDays(-2);
            previous.Status__c = oldStatus;
            Test_Drive__c reopened = previous.clone(true, false, false, false);
            reopened.Status__c = 'Scheduled';
            Map<Id, Test_Drive__c> oldById = new Map<Id, Test_Drive__c>{previous.Id => previous};
            TestDriveBookingGuard.validateSchedule(new List<Test_Drive__c>{reopened}, oldById);
            System.assert(reopened.hasErrors(), 'Reject reopening/confirmation into a past appointment: ' + oldStatus);
            Test_Drive__c rescheduled = previous.clone(true, false, false, false);
            rescheduled.Scheduled_Start__c = Datetime.now().addDays(2);
            rescheduled.Status__c = 'Requested';
            TestDriveBookingGuard.validateSchedule(new List<Test_Drive__c>{rescheduled}, oldById);
            System.assert(!rescheduled.hasErrors(), 'Reopening with a future start is allowed.');
        }
    }

    @isTest
    static void mixedBulkInsertAndCurrentTimeBoundary() {
        Fixture f = createFixture('0008');
        List<Test_Drive__c> drives = new List<Test_Drive__c>{
            driveFor(f, Datetime.now().addDays(-1), 'Scheduled'),
            driveFor(f, Datetime.now(), 'Scheduled'),
            driveFor(f, Datetime.now().addDays(2), 'Scheduled')
        };
        List<Database.SaveResult> results = Database.insert(drives, false);
        assertFutureError(results[0]);
        assertFutureError(results[1]);
        System.assert(results[2].isSuccess(), 'Valid records in a partial-success batch still save.');
        System.assertEquals(1, [SELECT COUNT() FROM Test_Drive__c WHERE Vehicle__c = :f.vehicle.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id]);
    }

    @isTest
    static void triggerBypassDoesNotAllowPastScheduling() {
        Fixture f = createFixture('0009');
        upsert new Automation_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Bypass_Triggers__c = true);
        Test_Drive__c drive = driveFor(f, Datetime.now().addDays(-1), 'Scheduled');
        assertFutureError(Database.insert(drive, false));
    }
}
