@isTest
private class TestDriveBookingGuardTest {
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
        insert driveFor(f, Datetime.newInstance(2026, 10, 20, 10, 0, 0), 'Scheduled');

        Test.startTest();
        try {
            insert driveFor(f, Datetime.newInstance(2026, 10, 20, 10, 30, 0), 'Scheduled');
            System.assert(false, 'Overlapping test drive should be blocked.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('already booked'), e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void adjacentDriveIsAllowed() {
        Fixture f = createFixture('0002');
        insert driveFor(f, Datetime.newInstance(2026, 10, 20, 10, 0, 0), 'Scheduled');

        Test.startTest();
        Test_Drive__c next = driveFor(f, Datetime.newInstance(2026, 10, 20, 11, 0, 0), 'Scheduled');
        insert next;
        Test.stopTest();

        System.assertNotEquals(null, next.Id);
    }

    @isTest
    static void cancelledDriveDoesNotBlock() {
        Fixture f = createFixture('0003');
        insert driveFor(f, Datetime.newInstance(2026, 10, 20, 10, 0, 0), 'Cancelled');

        Test.startTest();
        Test_Drive__c next = driveFor(f, Datetime.newInstance(2026, 10, 20, 10, 30, 0), 'Scheduled');
        insert next;
        Test.stopTest();

        System.assertNotEquals(null, next.Id);
    }
}
