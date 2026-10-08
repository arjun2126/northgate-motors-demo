public with sharing class VehicleReservationGuard {
    public static void guard(List<Vehicle__c> scope, Map<Id, Vehicle__c> oldById) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        for (Vehicle__c v : scope) {
            if (v.Reserved_By__c == null) {
                continue;
            }
            Vehicle__c old = (oldById == null) ? null : oldById.get(v.Id);
            Id oldReserver = (old == null) ? null : old.Reserved_By__c;
            if (oldReserver == v.Reserved_By__c) {
                continue;
            }
            if (old != null && old.Status__c == 'Reserved' && oldReserver != null) {
                v.addError('That vehicle is already reserved by another customer.');
                continue;
            }
            v.Status__c = 'Reserved';
            v.Reserved_On__c = System.now();
        }
    }
}
