@isTest
private class TestDriveFollowUpTest {
    @TestSetup
    static void setupPersonas() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'NG_Sales' LIMIT 1].Id;
        Map<String, Id> permissionIds = new Map<String, Id>();
        for (PermissionSet permission : [
            SELECT Id, Name FROM PermissionSet WHERE Name IN ('PS_Quote_Workflows', 'PS_Test_Drive_Booking')
        ]) {
            permissionIds.put(permission.Name, permission.Id);
        }
        System.assertEquals(2, permissionIds.size(), 'the actual persona dependencies must exist');
        // Only the lifecycle test actor may edit drives. No actor receives Task or model writes.
        PermissionSet lifecycleAccess = new PermissionSet(Name = 'DriveLifecycleTest', Label = 'Drive Lifecycle Test');
        insert lifecycleAccess;
        insert new ObjectPermissions(
            ParentId = lifecycleAccess.Id, SobjectType = 'Test_Drive__c',
            PermissionsRead = true, PermissionsEdit = true
        );
        for (String mode : new List<String>{'booker', 'editor', 'unauthorized'}) {
            User rep = new User(
                Alias = 'tdsec' + mode.left(3), LastName = 'DriveSecurity' + mode,
                Email = 'drive.security.' + mode + '@northgate.example',
                Username = 'drive.security.' + mode + '.' + UserInfo.getOrganizationId() + '@northgate.example',
                ProfileId = profileId, EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York'
            );
            insert rep;
            insert new PermissionSetAssignment(AssigneeId = rep.Id, PermissionSetId = permissionIds.get('PS_Quote_Workflows'));
            if (mode != 'unauthorized') {
                insert new PermissionSetAssignment(AssigneeId = rep.Id, PermissionSetId = permissionIds.get('PS_Test_Drive_Booking'));
            }
            if (mode == 'editor') {
                insert new PermissionSetAssignment(AssigneeId = rep.Id, PermissionSetId = lifecycleAccess.Id);
            }
        }
    }

    @isTest
    static void insertCreatesTask() {
        Test_Drive__c td = createTestDrive();
        List<Task> tasks = [SELECT Subject, WhoId FROM Task WHERE WhoId = :td.Contact__c];
        System.assertEquals(1, tasks.size(), 'One Task should be created on insert');
        System.assert(tasks[0].Subject.contains('Created'), 'Task subject should reflect creation');
    }

    @isTest
    static void statusChangeCreatesAdditionalTask() {
        Test_Drive__c td = createTestDrive();
        td.Status__c = 'Completed';
        update td;
        List<Task> tasks = [SELECT Subject FROM Task WHERE WhoId = :td.Contact__c ORDER BY CreatedDate];
        System.assert(tasks.size() >= 2, 'Status change should create a follow-up task');
    }

    private class BookingFixture {
        Contact driver;
        Vehicle__c vehicle;
        Vehicle_Model__c model;
        Vehicle_Model__c unrelatedModel;
        Datetime startTime;
    }

    private static User persona(String mode) {
        String lastName = 'DriveSecurity' + mode;
        return [SELECT Id FROM User WHERE LastName = :lastName LIMIT 1];
    }

    private static BookingFixture fixture(User owner, Boolean withEmail) {
        BookingFixture f = new BookingFixture();
        Account account = new Account(Name = 'Drive Security Account', OwnerId = owner.Id);
        insert account;
        f.driver = new Contact(
            FirstName = 'Driver', LastName = 'Drive Security', AccountId = account.Id, OwnerId = owner.Id,
            Email = withEmail ? 'driver.booking@northgate.example' : null
        );
        insert f.driver;
        f.model = new Vehicle_Model__c(Name = 'Drive Security Model', Completed_Test_Drives__c = 7);
        f.unrelatedModel = new Vehicle_Model__c(Name = 'Unrelated Drive Model', Completed_Test_Drives__c = 17);
        insert new List<Vehicle_Model__c>{f.model, f.unrelatedModel};
        f.vehicle = new Vehicle__c(
            VIN__c = 'P2FUTST000000001A', Vehicle_Model__c = f.model.Id, Status__c = 'Available'
        );
        insert f.vehicle;
        f.startTime = Datetime.now().addDays(2);
        return f;
    }

    private static Test_Drive__c booking(BookingFixture f, Integer offsetMinutes) {
        return new Test_Drive__c(
            Vehicle__c = f.vehicle.Id, Contact__c = f.driver.Id,
            Scheduled_Start__c = f.startTime.addMinutes(offsetMinutes),
            Duration_Minutes__c = 45, Status__c = 'Scheduled'
        );
    }

    private static void assertRestrictedAutomationPermissions() {
        System.assert(!FeatureManagement.checkPermission('Bypass_Automation'), 'automation bypass remains absent');
        System.assert(!Schema.SObjectType.Task.isCreateable(), 'persona cannot create Tasks directly');
        System.assert(!Schema.SObjectType.Contact.fields.Email.isAccessible(), 'Contact.Email stays hidden');
        System.assert(!Schema.SObjectType.Vehicle_Model__c.isUpdateable(), 'persona cannot edit models');
        System.assert(!Schema.SObjectType.Vehicle_Model__c.fields.Completed_Test_Drives__c.isUpdateable(), 'counter stays read-only');
    }

    private static void assertCounters(BookingFixture f, Integer expected) {
        System.assertEquals(expected, [SELECT Completed_Test_Drives__c FROM Vehicle_Model__c WHERE Id = :f.model.Id].Completed_Test_Drives__c,
            'the original completed-drive calculation is maintained');
        System.assertEquals(17, [SELECT Completed_Test_Drives__c FROM Vehicle_Model__c WHERE Id = :f.unrelatedModel.Id].Completed_Test_Drives__c,
            'unrelated models are not written');
    }

    @isTest
    static void restrictedBookingCreatesOwnedTaskAndKeepsEmailHidden() {
        User rep = persona('booker');
        BookingFixture f = fixture(rep, true);
        Test_Drive__c drive = booking(f, 0);
        System.assertNotEquals(null, [SELECT Email FROM Contact WHERE Id = :f.driver.Id WITH SYSTEM_MODE].Email,
            'fixture includes a hidden Email, not the no-email path');
        System.runAs(rep) {
            assertRestrictedAutomationPermissions();
            System.assert(Schema.SObjectType.Test_Drive__c.isCreateable(), 'booking is authorized');
            System.assert(!Schema.SObjectType.Test_Drive__c.isUpdateable(), 'booking does not grant drive editing');
            System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Id = :f.driver.Id WITH USER_MODE],
                'booking Contact is visible to the restricted actor');
            Set<Id> permissionIds = new Set<Id>();
            for (PermissionSetAssignment assignment : [
                SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :rep.Id WITH SYSTEM_MODE
            ]) {
                permissionIds.add(assignment.PermissionSetId);
            }
            Id profileId = UserInfo.getProfileId();
            System.assertEquals(0, [
                SELECT COUNT() FROM PermissionSet
                WHERE PermissionsEmailSingle = true AND (Id IN :permissionIds OR ProfileId = :profileId)
                WITH SYSTEM_MODE
            ], 'restricted actor lacks Single Email permission');
            Test.startTest();
            insert as user drive;
            System.assertNotEquals(null, drive.Id, 'booking succeeds despite the rejected email attempt');
            System.assertEquals(0, Limits.getEmailInvocations(),
                'Single Email permission denial occurs before an email invocation is counted');
            System.assertEquals(1, [SELECT COUNT() FROM Test_Drive__c WHERE Id = :drive.Id WITH USER_MODE],
                'authorized booking remains saved after email rejection');
            Test.stopTest();
            assertRestrictedAutomationPermissions();
            try {
                List<Contact> hidden = [SELECT Email FROM Contact WHERE Id = :f.driver.Id WITH USER_MODE];
                System.assert(false, 'internal lookup must not grant user-facing Email access');
            } catch (QueryException expected) {
                System.assertNotEquals(null, expected.getMessage(), 'user-mode Email read is still denied');
            }
        }
        String expectedSubject = 'Test drive: Created ' + drive.Id;
        Task followup = [
            SELECT OwnerId, WhoId, Subject, ActivityDate, Status, Priority, Description
            FROM Task WHERE WhoId = :f.driver.Id AND Subject = :expectedSubject
        ];
        System.assertEquals(rep.Id, followup.OwnerId, 'Task owner remains the initiating user');
        System.assertEquals(f.driver.Id, followup.WhoId, 'Task stays related to the booking Contact');
        System.assertEquals('Test drive: Created ' + drive.Id, followup.Subject, 'Task subject is unchanged');
        System.assertEquals(Date.today().addDays(1), followup.ActivityDate, 'Task due date is unchanged');
        System.assertEquals('Not Started', followup.Status, 'Task status is unchanged');
        System.assertEquals('Normal', followup.Priority, 'Task priority is unchanged');
        System.assertEquals('Auto-created by TestDriveFollowUp on Created.', followup.Description, 'Task description contains no Email');
        assertCounters(f, 0);
    }

    @isTest
    static void restrictedBookingsRejectOverlapAndAllowAdjacent() {
        User rep = persona('booker');
        BookingFixture f = fixture(rep, false);
        System.runAs(rep) {
            Test_Drive__c first = booking(f, 0);
            insert as user first;
            try {
                Test_Drive__c overlapping = booking(f, 30);
                insert as user overlapping;
                System.assert(false, 'overlapping booking must fail');
            } catch (DmlException expected) {
                System.assert(expected.getMessage().contains('already booked'), expected.getMessage());
            }
            Test_Drive__c adjacent = booking(f, 45);
            insert as user adjacent;
            System.assertEquals(2, [SELECT COUNT() FROM Test_Drive__c WHERE Vehicle__c = :f.vehicle.Id WITH USER_MODE],
                'only the two non-overlapping bookings are saved');
        }
        System.assertEquals(2, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id], 'rejected booking leaves no follow-up Task');
        assertCounters(f, 0);
    }

    @isTest
    static void restrictedLifecycleCompletionMaintainsTasksAndCounters() {
        User rep = persona('editor');
        BookingFixture f = fixture(rep, false);
        Test_Drive__c drive = booking(f, 0);
        System.runAs(rep) {
            assertRestrictedAutomationPermissions();
            System.assert(Schema.SObjectType.Test_Drive__c.isUpdateable(), 'test-only lifecycle actor can complete drives');
            insert as user drive;
            drive.Status__c = 'Completed';
            update as user drive;
            assertRestrictedAutomationPermissions();
        }
        List<Task> tasks = [SELECT OwnerId, WhoId, Subject FROM Task WHERE WhoId = :f.driver.Id ORDER BY Subject];
        System.assertEquals(2, tasks.size(), 'creation and completion both create follow-up Tasks');
        System.assertEquals('Test drive: Completed ' + drive.Id, tasks[0].Subject, 'completion Task is preserved');
        System.assertEquals('Test drive: Created ' + drive.Id, tasks[1].Subject, 'creation Task is preserved');
        for (Task task : tasks) {
            System.assertEquals(rep.Id, task.OwnerId, 'both Tasks retain the initiating owner');
            System.assertEquals(f.driver.Id, task.WhoId, 'both Tasks retain the Contact relationship');
        }
        assertCounters(f, 1);
    }

    @isTest
    static void restrictedCancellationReleasesSlotAndUpdatesCounter() {
        User rep = persona('editor');
        BookingFixture f = fixture(rep, false);
        Test_Drive__c drive = booking(f, 0);
        System.runAs(rep) {
            insert as user drive;
            drive.Status__c = 'Completed';
            update as user drive;
        }
        assertCounters(f, 1);
        System.runAs(rep) {
            drive.Status__c = 'Cancelled';
            update as user drive;
            Test_Drive__c replacement = booking(f, 0);
            insert as user replacement;
            System.assertNotEquals(null, replacement.Id, 'cancelled booking does not block the slot');
        }
        System.assertEquals(3, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id], 'cancellation adds no extra Task');
        assertCounters(f, 0);
    }

    @isTest
    static void internalElevationDoesNotAllowDirectTaskOrCounterWrites() {
        User rep = persona('booker');
        BookingFixture f = fixture(rep, false);
        System.runAs(rep) {
            assertRestrictedAutomationPermissions();
            try {
                Task direct = new Task(Subject = 'Unauthorized direct Task', WhoId = f.driver.Id);
                insert as user direct;
                System.assert(false, 'direct Task creation must remain denied');
            } catch (TypeException expected) {
                System.assertEquals('DML operation INSERT not allowed on Task', expected.getMessage(), 'Task permission remains enforced');
            }
            try {
                Vehicle_Model__c direct = new Vehicle_Model__c(Id = f.model.Id, Completed_Test_Drives__c = 99);
                update as user direct;
                System.assert(false, 'direct model counter update must remain denied');
            } catch (TypeException expected) {
                System.assertEquals('DML operation UPDATE not allowed on Vehicle_Model__c',
                    expected.getMessage(), 'model permission remains enforced');
            }
        }
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id], 'no direct Task is created');
        assertCounters(f, 7);
    }

    @isTest
    static void unauthorizedUserCannotCreateBookingOrSideEffects() {
        User rep = persona('unauthorized');
        BookingFixture f = fixture(rep, false);
        System.runAs(rep) {
            System.assert(!Schema.SObjectType.Test_Drive__c.isCreateable(), 'user has no booking permission');
            try {
                Test_Drive__c drive = booking(f, 0);
                insert as user drive;
                System.assert(false, 'booking creation must be denied');
            } catch (SecurityException expected) {
                System.assert(expected.getMessage().contains('Test_Drive__c') && expected.getMessage().contains('denied'),
                    'booking access remains enforced: ' + expected.getMessage());
            }
        }
        System.assertEquals(0, [SELECT COUNT() FROM Test_Drive__c WHERE Vehicle__c = :f.vehicle.Id], 'no booking is created');
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id], 'no internal Task is created');
        assertCounters(f, 7);
    }

    private static Contact unrelatedContact() {
        Account privateAccount = new Account(Name = 'Private Drive Account');
        insert privateAccount;
        Contact hidden = new Contact(
            LastName = 'Private Driver', AccountId = privateAccount.Id, Email = 'private.driver@northgate.example'
        );
        insert hidden;
        return hidden;
    }

    @isTest
    static void restrictedBookingCannotReferenceUnsharedContact() {
        User rep = persona('booker');
        BookingFixture f = fixture(rep, false);
        Contact hidden = unrelatedContact();
        System.runAs(rep) {
            System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE Id = :hidden.Id WITH USER_MODE], 'Contact is genuinely unshared');
            try {
                Test_Drive__c drive = booking(f, 0);
                drive.Contact__c = hidden.Id;
                insert as user drive;
                System.assert(false, 'booking must not bypass Contact record access');
            } catch (DmlException expected) {
                System.assertNotEquals(null, expected.getMessage(), 'unshared reference is rejected');
            }
        }
        System.assertEquals(0, [SELECT COUNT() FROM Test_Drive__c WHERE Vehicle__c = :f.vehicle.Id], 'rejected booking leaves no record');
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :hidden.Id], 'rejected booking creates no Task against private Contact');
        assertCounters(f, 7);
    }

    @isTest
    static void confirmationLookupDoesNotUseUnsharedContacts() {
        User rep = persona('booker');
        BookingFixture f = fixture(rep, false);
        Contact hidden = unrelatedContact();
        Test_Drive__c drive = booking(f, 0);
        insert drive;
        Test_Drive__c previous = new Test_Drive__c(Id = drive.Id, Status__c = 'Requested');
        Test_Drive__c forged = new Test_Drive__c(
            Id = drive.Id, Contact__c = hidden.Id, Status__c = 'Scheduled', Scheduled_Start__c = f.startTime
        );
        System.runAs(rep) {
            System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE Id = :hidden.Id WITH USER_MODE], 'Contact is genuinely unshared');
            Test.startTest();
            TestDriveFollowUp.onStatusChange(new List<Test_Drive__c>{forged}, new Map<Id, Test_Drive__c>{drive.Id => previous});
            System.assertEquals(0, Limits.getEmailInvocations(), 'system field lookup never uses unshared Contact');
            Test.stopTest();
        }
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :hidden.Id], 'notification path creates no Task for private Contact');
    }

    @isTest
    static void restrictedBookingWithoutEmailSkipsConfirmation() {
        User rep = persona('booker');
        BookingFixture f = fixture(rep, false);
        System.runAs(rep) {
            Test.startTest();
            Test_Drive__c drive = booking(f, 0);
            insert as user drive;
            System.assertEquals(0, Limits.getEmailInvocations(), 'missing Email preserves no-send behavior');
            Test.stopTest();
        }
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhoId = :f.driver.Id], 'booking still creates its follow-up');
        assertCounters(f, 0);
    }

    private static Test_Drive__c createTestDrive() {
        Account a = new Account(Name = 'P2 FU A');
        insert a;
        Contact c = new Contact(LastName = 'Driver FU', AccountId = a.Id);
        insert c;
        Vehicle_Model__c m = new Vehicle_Model__c(Name = 'P2 FU M');
        insert m;
        Vehicle__c v = new Vehicle__c(VIN__c = 'P2FUTST000000001A', Vehicle_Model__c = m.Id, Status__c = 'Available');
        insert v;
        Test_Drive__c td = new Test_Drive__c(
            Vehicle__c = v.Id,
            Contact__c = c.Id,
            Scheduled_Start__c = Datetime.now().addDays(2),
            Duration_Minutes__c = 45,
            Status__c = 'Scheduled'
        );
        insert td;
        return td;
    }
}
