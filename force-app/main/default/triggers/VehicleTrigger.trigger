trigger VehicleTrigger on Vehicle__c (before insert, before update) {
    if (!Test.isRunningTest() && FeatureManagement.checkPermission('Bypass_Automation')) return;
    for (Vehicle__c v : Trigger.new) {
        if (String.isBlank(v.VIN__c)) {
            v.Is_VIN_Valid__c = false;
        } else {
            v.Is_VIN_Valid__c = VinValidator.isValid(v.VIN__c);
        }
    }
    VehicleReservationGuard.guard(Trigger.new, Trigger.oldMap);
}
