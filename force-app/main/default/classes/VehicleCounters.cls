public with sharing class VehicleCounters {
    public static void maintain(List<Vehicle__c> scope, Map<Id, Vehicle__c> oldById) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Set<Id> rooftopIds = new Set<Id>();
        for (Vehicle__c v : scope) {
            if (v.Rooftop__c != null) rooftopIds.add(v.Rooftop__c);
        }
        if (rooftopIds.isEmpty()) {
            return;
        }
        Map<Id, Integer> counts = new Map<Id, Integer>();
        for (AggregateResult r : [
            SELECT Rooftop__c r, COUNT(Id) c
            FROM Vehicle__c
            WHERE Rooftop__c IN :rooftopIds
            GROUP BY Rooftop__c
        ]) {
            counts.put((Id) r.get('r'), (Integer) r.get('c'));
        }
        List<Rooftop__c> updates = new List<Rooftop__c>();
        for (Id rid : rooftopIds) {
            updates.add(new Rooftop__c(Id = rid, Vehicles_On_Hand__c = counts.containsKey(rid) ? counts.get(rid) : 0));
        }
        // Trigger-owned derived cache, not an authorization to edit Rooftops through the caller's UI.
        update as system updates;
    }
}
