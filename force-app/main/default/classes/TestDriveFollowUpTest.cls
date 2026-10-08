@isTest
private class TestDriveFollowUpTest {
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
