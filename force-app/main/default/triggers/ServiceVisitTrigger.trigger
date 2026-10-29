trigger ServiceVisitTrigger on Service_Visit__c (before insert, before update, after insert) {
    Automation_Settings__c settings = Automation_Settings__c.getOrgDefaults();
    if (settings != null && settings.Bypass_Triggers__c) {
        return;
    }

    if (Trigger.isBefore) {
        ServiceVisitCapacityGuard.validate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        ServiceIntakeCaseService.createForNewVisits(Trigger.new);
    }
}
