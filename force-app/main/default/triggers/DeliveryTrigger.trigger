trigger DeliveryTrigger on Delivery__c (after insert, after update) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c == true) {
        return;
    }
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        DeliveryCloseService.handleCompleted(Trigger.new, Trigger.oldMap);
    }
}
