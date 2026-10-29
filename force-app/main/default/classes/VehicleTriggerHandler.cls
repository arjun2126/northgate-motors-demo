public with sharing class VehicleTriggerHandler {
    public static void run() {
        List<Vehicle__c> rows = (List<Vehicle__c>) Trigger.new;
        Map<Id, Vehicle__c> oldRows = (Map<Id, Vehicle__c>) Trigger.oldMap;
        if (Trigger.isBefore) {
            // Preserve the existing VIN/reservation bypass; hierarchy settings never bypassed it.
            if (!Test.isRunningTest() && FeatureManagement.checkPermission('Bypass_Automation')) return;
            for (Vehicle__c row : rows) {
                row.Is_VIN_Valid__c = !String.isBlank(row.VIN__c) && VinValidator.isValid(row.VIN__c);
            }
            VehicleReservationGuard.guard(rows, oldRows);
            return;
        }
        Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
        if (settings != null && settings.Bypass_Triggers__c == true) return;
        Set<Id> rooftopIds = new Set<Id>();
        if (rows != null) for (Vehicle__c row : rows) {
            if (row.Rooftop__c != null) rooftopIds.add(row.Rooftop__c);
        }
        if (Trigger.old != null) for (Vehicle__c row : (List<Vehicle__c>) Trigger.old) {
            if (row.Rooftop__c != null) rooftopIds.add(row.Rooftop__c);
        }
        List<Vehicle__c> scope = new List<Vehicle__c>();
        for (Id rooftopId : rooftopIds) scope.add(new Vehicle__c(Rooftop__c = rooftopId));
        VehicleCounters.maintain(scope, null);
        if (Trigger.isUpdate) VehicleReservationEventPublisher.publish(rows, oldRows);
    }
}
