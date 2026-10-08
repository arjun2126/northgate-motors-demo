public with sharing class TestDriveCounters {
    public static void maintain(List<Test_Drive__c> scope, Map<Id, Test_Drive__c> oldById) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Set<Id> modelIds = new Set<Id>();
        Set<Id> vehicleIds = new Set<Id>();
        Map<Id, Id> vehicleToModel = new Map<Id, Id>();
        for (Test_Drive__c td : scope) {
            if (td.Vehicle__c != null) vehicleIds.add(td.Vehicle__c);
        }
        if (vehicleIds.isEmpty()) {
            return;
        }
        for (Vehicle__c v : [SELECT Id, Vehicle_Model__c FROM Vehicle__c WHERE Id IN :vehicleIds]) {
            if (v.Vehicle_Model__c != null) {
                modelIds.add(v.Vehicle_Model__c);
                vehicleToModel.put(v.Id, v.Vehicle_Model__c);
            }
        }
        if (modelIds.isEmpty()) {
            return;
        }
        Map<Id, Integer> completed = new Map<Id, Integer>();
        for (AggregateResult r : [
            SELECT Vehicle__r.Vehicle_Model__c m, COUNT(Id) c
            FROM Test_Drive__c
            WHERE Vehicle__c IN :vehicleIds AND Status__c = 'Completed'
            GROUP BY Vehicle__r.Vehicle_Model__c
        ]) {
            completed.put((Id) r.get('m'), (Integer) r.get('c'));
        }
        List<Vehicle_Model__c> updates = new List<Vehicle_Model__c>();
        for (Id mid : modelIds) {
            updates.add(new Vehicle_Model__c(Id = mid, Completed_Test_Drives__c = completed.containsKey(mid) ? completed.get(mid) : 0));
        }
        update updates;
    }
}
