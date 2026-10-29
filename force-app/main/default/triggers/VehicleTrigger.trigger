trigger VehicleTrigger on Vehicle__c (before insert, before update, after insert, after update, after delete, after undelete) {
    VehicleTriggerHandler.run();
}
