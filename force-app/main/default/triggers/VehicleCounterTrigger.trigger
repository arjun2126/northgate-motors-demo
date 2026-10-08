trigger VehicleCounterTrigger on Vehicle__c (after insert, after update, after delete, after undelete) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    Set<Id> rooftopIds = new Set<Id>();
    if (Trigger.new != null) {
        for (Vehicle__c v : Trigger.new) {
            if (v.Rooftop__c != null) rooftopIds.add(v.Rooftop__c);
        }
    }
    if (Trigger.old != null) {
        for (Vehicle__c v : Trigger.old) {
            if (v.Rooftop__c != null) rooftopIds.add(v.Rooftop__c);
        }
    }
    List<Vehicle__c> scope = new List<Vehicle__c>();
    for (Id rid : rooftopIds) {
        scope.add(new Vehicle__c(Rooftop__c = rid));
    }
    VehicleCounters.maintain(scope, null);
}
