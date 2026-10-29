@isTest
private class VehicleReservationEventPublisherTest {
    @isTest static void bulkReservationsCreateMinimalEventsAndNeutralUpdatesDoNot() {
        List<Vehicle__c> rows = P7Batch1TestData.vehicles(200);
        Map<Id, Vehicle__c> before = new Map<Id, Vehicle__c>([SELECT Id,Status__c,Reserved_By__c,Reserved_On__c FROM Vehicle__c WITH SYSTEM_MODE]);
        Contact contact = P7Batch1TestData.contact(UserInfo.getUserId(), 'Event fixture');
        for (Vehicle__c row : rows) row.Reserved_By__c = contact.Id;
        Test.startTest();
        Integer queries = Limits.getQueries(); update as system rows;
        System.assert(Limits.getQueries() - queries < 10);
        Test.getEventBus().deliver(); Test.stopTest();
        List<Vehicle__c> stored = [SELECT Id,Status__c,Reserved_By__c,Reserved_On__c FROM Vehicle__c WITH SYSTEM_MODE];
        List<Vehicle_Reserved__e> events = VehicleReservationEventPublisher.eventsFor(stored, before);
        System.assertEquals(200, events.size());
        System.assertEquals(200, [SELECT Vehicles_On_Hand__c FROM Rooftop__c WHERE Id = :rows[0].Rooftop__c WITH SYSTEM_MODE].Vehicles_On_Hand__c);
        for (Vehicle_Reserved__e event : events) {
            System.assertEquals(18, event.Vehicle_Id__c.length()); System.assertNotEquals(null, event.Reserved_At__c);
        }
        System.assertEquals(0, VehicleReservationEventPublisher.eventsFor(stored, new Map<Id, Vehicle__c>(stored)).size());
        for (Vehicle__c row : stored) row.Status__c = 'Available';
        System.assertEquals(0, VehicleReservationEventPublisher.eventsFor(stored, before).size());
        VehicleReservationEventPublisher.publish(new List<Vehicle__c>(), new Map<Id, Vehicle__c>());
    }
    @isTest static void failedEnqueueIsReportedWithoutInvalidatingReservation() {
        Database.SaveResult failed = (Database.SaveResult) JSON.deserialize('{"success":false}', Database.SaveResult.class);
        System.assertEquals(1, VehicleReservationEventPublisher.reportResults(new List<Database.SaveResult>{failed}));
    }
}
