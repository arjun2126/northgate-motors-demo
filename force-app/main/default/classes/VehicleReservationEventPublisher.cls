public without sharing class VehicleReservationEventPublisher {
    public static void publish(List<Vehicle__c> rows, Map<Id, Vehicle__c> oldRows) {
        List<Vehicle_Reserved__e> events = eventsFor(rows, oldRows);
        if (!events.isEmpty()) reportResults(EventBus.publish(events));
    }
    @TestVisible private static List<Vehicle_Reserved__e> eventsFor(List<Vehicle__c> rows, Map<Id, Vehicle__c> oldRows) {
        List<Vehicle_Reserved__e> events = new List<Vehicle_Reserved__e>();
        for (Vehicle__c row : rows) {
            Vehicle__c old = oldRows.get(row.Id);
            if (row.Status__c == 'Reserved' && row.Reserved_By__c != null && row.Reserved_On__c != null
                && (old.Status__c != 'Reserved' || old.Reserved_By__c != row.Reserved_By__c)) {
                events.add(new Vehicle_Reserved__e(Vehicle_Id__c = row.Id, Reserved_At__c = row.Reserved_On__c));
            }
        }
        return events;
    }
    @TestVisible private static Integer reportResults(List<Database.SaveResult> results) {
        // ponytail: enqueue errors are log-only; add a durable outbox if refresh delivery becomes business-critical.
        Integer failures = 0;
        for (Database.SaveResult result : results) if (!result.isSuccess()) {
            failures++;
            // A refresh notification must not invalidate an otherwise authorized legacy reservation.
            System.debug(LoggingLevel.ERROR, 'Inventory refresh enqueue failed; use manual refresh.');
        }
        return failures;
    }
}
