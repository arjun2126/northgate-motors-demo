public without sharing class DeliveryCloseService {
    private static final String COMPLETED = 'Completed';
    private static final String CLOSED_WON = 'Closed Won';

    public static void handleCompleted(List<Delivery__c> newRecords, Map<Id, Delivery__c> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
        List<Delivery__c> toProcess = new List<Delivery__c>();
        for (Delivery__c record : newRecords) {
            Delivery__c prior = oldMap == null ? null : oldMap.get(record.Id);
            if (prior != null && prior.Status__c == COMPLETED) {
                continue;
            }
            if (record.Status__c != COMPLETED) {
                continue;
            }
            if (record.Opportunity__c == null) {
                continue;
            }
            toProcess.add(record);
        }
        enrolLateBuyers(newRecords, oldMap);
        if (toProcess.isEmpty()) {
            return;
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Delivery__c> deliveriesToUpdate = new List<Delivery__c>();
        Map<Id, Decimal> contactLifetimeIncrement = new Map<Id, Decimal>();
        for (Delivery__c record : toProcess) {
            if (record.Completed_Date__c == null) {
                Delivery__c copy = new Delivery__c(Id = record.Id, Completed_Date__c = Date.today());
                deliveriesToUpdate.add(copy);
            }
            oppsToUpdate.add(new Opportunity(
                Id = record.Opportunity__c,
                StageName = CLOSED_WON,
                Delivery_Completed__c = true
            ));
            if (record.Buyer__c != null) {
                contactLifetimeIncrement.put(record.Buyer__c,
                    (contactLifetimeIncrement.get(record.Buyer__c) == null ? 0 : contactLifetimeIncrement.get(record.Buyer__c)) + 1);
            }
        }
        if (!deliveriesToUpdate.isEmpty()) {
            update deliveriesToUpdate;
        }
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
        if (!contactLifetimeIncrement.isEmpty()) {
            incrementContactLifetime(contactLifetimeIncrement);
        }
        for (Delivery__c record : toProcess) {
            LoyaltyEnrolmentService.enrolOnDelivery(record);
        }
        enrolLateBuyers(newRecords, oldMap);
    }

    private static void enrolLateBuyers(List<Delivery__c> newRecords, Map<Id, Delivery__c> oldMap) {
        if (newRecords == null || oldMap == null) {
            return;
        }
        for (Delivery__c record : newRecords) {
            Delivery__c prior = oldMap.get(record.Id);
            if (prior == null) {
                continue;
            }
            if (record.Status__c != COMPLETED) {
                continue;
            }
            if (prior.Status__c != COMPLETED) {
                continue;
            }
            if (record.Buyer__c == null) {
                continue;
            }
            if (prior.Buyer__c == record.Buyer__c) {
                continue;
            }
            if (prior.Buyer__c != null) {
                continue;
            }
            LoyaltyEnrolmentService.enrolOnDelivery(record);
        }
    }

    private static void incrementContactLifetime(Map<Id, Decimal> increments) {
        List<Contact> contacts = [
            SELECT Id, Lifetime_Vehicles_Owned__c FROM Contact
            WHERE Id IN :increments.keySet()
            WITH USER_MODE
        ];
        List<Contact> updates = new List<Contact>();
        for (Contact c : contacts) {
            Decimal current = c.Lifetime_Vehicles_Owned__c == null ? 0 : c.Lifetime_Vehicles_Owned__c;
            c.Lifetime_Vehicles_Owned__c = current + increments.get(c.Id);
            updates.add(c);
        }
        if (!updates.isEmpty()) {
            update updates;
        }
    }
}
