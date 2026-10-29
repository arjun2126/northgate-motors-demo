@isTest
private class CaseServiceHistoryControllerTest {
    private static Service_Visit__c serviceVisit(Id contactId, Id vehicleId, Datetime start) {
        Rooftop__c rooftop = new Rooftop__c(Name = 'History Test Rooftop ' + start.getTime(), Service_Capacity__c = 20);
        insert rooftop;
        Service_Visit__c row = new Service_Visit__c(
            Rooftop__c = rooftop.Id, Contact__c = contactId, Vehicle__c = vehicleId,
            Scheduled_Start__c = start, Status__c = 'Completed', Service_Type__c = 'Inspection'
        );
        insert row;
        return row;
    }

    @isTest
    static void returnsVehicleHistoryInStableDescendingOrder() {
        Account account = new Account(Name = 'History Test Account');
        insert account;
        Contact contact = new Contact(LastName = 'History Test Contact', AccountId = account.Id);
        insert contact;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'History Test Model');
        insert model;
        Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = 'HISTORYTEST000000');
        insert vehicle;
        Service_Visit__c earlier = serviceVisit(contact.Id, vehicle.Id, Datetime.now().addDays(-4));
        Service_Visit__c later = serviceVisit(contact.Id, vehicle.Id, Datetime.now().addDays(-2));
        Case row = new Case(Subject = 'History case', Status = 'New', Origin = 'Web',
            ContactId = contact.Id, AccountId = account.Id, Vehicle__c = vehicle.Id);
        insert row;

        List<CaseServiceHistoryController.VisitDto> page = CaseServiceHistoryController.getHistory(row.Id, 1, 0);
        System.assertEquals(1, page.size());
        System.assertEquals(later.Id, page[0].id);
        System.assertEquals(earlier.Id,
            CaseServiceHistoryController.getHistory(row.Id, 1, 1)[0].id);
    }

    @isTest
    static void fallsBackToContactAndReturnsEmptyForMissingKeys() {
        Account account = new Account(Name = 'History Contact Account');
        insert account;
        Contact contact = new Contact(LastName = 'History Contact', AccountId = account.Id);
        insert contact;
        Vehicle_Model__c model = new Vehicle_Model__c(Name = 'History Contact Model');
        insert model;
        Vehicle__c vehicle = new Vehicle__c(Vehicle_Model__c = model.Id, VIN__c = 'HISTORYCONTACT000');
        insert vehicle;
        Service_Visit__c visit = serviceVisit(contact.Id, vehicle.Id, Datetime.now().addDays(-3));
        Case contactCase = new Case(Subject = 'Contact history', Status = 'New', Origin = 'Web',
            ContactId = contact.Id, AccountId = account.Id);
        Case emptyCase = new Case(Subject = 'No history', Status = 'New', Origin = 'Web');
        insert new List<Case>{contactCase, emptyCase};

        System.assertEquals(visit.Id, CaseServiceHistoryController.getHistory(contactCase.Id, 20, 0)[0].id);
        System.assertEquals(0, CaseServiceHistoryController.getHistory(emptyCase.Id, 20, 0).size());
    }
}
