@isTest
private class ServiceIntakeCaseServiceTest {
    private static Integer vehicleNumber = 1;
    private static Service_Visit__c newVisit(String status, Id caseId) {
        Rooftop__c rooftop = new Rooftop__c(Name = 'Intake Test Rooftop', Service_Capacity__c = 20);
        insert rooftop;
        Account account = new Account(Name = 'Intake Test Account');
        insert account;
        Contact contact = new Contact(LastName = 'Intake Test Contact', AccountId = account.Id);
        insert contact;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'Intake Test Model');
        insert model;
        Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id,
            VIN__c = String.valueOf(20000000000000000L + vehicleNumber++));
        insert vehicle;
        return new Service_Visit__c(
            Rooftop__c = rooftop.Id, Contact__c = contact.Id, Vehicle__c = vehicle.Id,
            Scheduled_Start__c = Datetime.now().addDays(2), Status__c = status,
            Service_Type__c = 'Inspection', Case__c = caseId
        );
    }

    @isTest
    static void consumingVisitGetsServiceCaseAndQueueOwner() {
        Service_Visit__c visit = newVisit('Requested', null);
        insert visit;

        Service_Visit__c stored = [SELECT Case__c FROM Service_Visit__c WHERE Id = :visit.Id];
        Case intake = [SELECT RecordType.DeveloperName, OwnerId, Status, Priority, Origin, ContactId,
            AccountId, Vehicle__c, Service_Type__c FROM Case WHERE Id = :stored.Case__c];
        System.assertEquals('Service', intake.RecordType.DeveloperName);
        System.assertEquals([SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Q_Service_Intake' LIMIT 1].Id, intake.OwnerId);
        System.assertEquals('New', intake.Status);
        System.assertEquals('Medium', intake.Priority);
        System.assertEquals('Web', intake.Origin);
    }

    @isTest
    static void prelinkedAndTerminalVisitsDoNotCreateCases() {
        Case existing = new Case(Subject = 'Existing service case', Status = 'New', Origin = 'Web');
        insert existing;
        Service_Visit__c prelinked = newVisit('Requested', existing.Id);
        Service_Visit__c terminal = newVisit('Completed', null);
        insert new List<Service_Visit__c>{prelinked, terminal};

        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Id = :existing.Id]);
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Subject = 'Service visit intake']);
        System.assertEquals(null, [SELECT Case__c FROM Service_Visit__c WHERE Id = :terminal.Id].Case__c);
    }
}
